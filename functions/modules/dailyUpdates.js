const {onSchedule} = require('firebase-functions/v2/scheduler');
const {onCall, HttpsError} = require('firebase-functions/v2/https');
const admin = require('firebase-admin');
if (!admin.apps.length) {
  admin.initializeApp();
}
const { sanitizeForFirestore, formatDate, getCurrentGameDate, logAdminAction, toDateSafe } = require('./utils');

const db = admin.firestore();

const DAILY_UPDATE_STATUS_REF = db.collection('game_state').doc('dailyUpdateStatus');
const DAILY_UPDATE_BATCH_SIZE = Number(process.env.DAILY_UPDATE_BATCH_SIZE || 120);
const DAILY_UPDATE_MAX_BATCHES = Number(process.env.DAILY_UPDATE_MAX_BATCHES || 10);
const DAILY_UPDATE_LOCK_TIMEOUT_MS = Number(
  process.env.DAILY_UPDATE_LOCK_TIMEOUT_MS || 8 * 60 * 1000,
);

/**
 * Calculate daily stream growth with decay
 */
function calculateDailyStreamGrowth(song, playerData, gameDate) {
  if (!song || song.state !== 'released' || !song.releaseDate) {
    return 0;
  }

  const releaseDate = toDateSafe(song.releaseDate);
  if (!releaseDate || isNaN(releaseDate.getTime())) {
    return 0;
  }

  const daysSinceRelease = Math.floor((gameDate - releaseDate) / (1000 * 60 * 60 * 24));
  if (daysSinceRelease < 0) {
    return 0;
  }

  const baseStreams = song.quality || 50;
  const decayFactor = Math.max(0.1, 1 - (daysSinceRelease * 0.05));
  const fameBonus = 1 + ((playerData.fame || 0) / 1000);
  
  return Math.floor(baseStreams * decayFactor * fameBonus);
}

/**
 * Process daily streams and income for a single player
 */
async function processDailyStreamsForPlayer(playerId, playerData, batch) {
  try {
    const playerRef = db.collection('players').doc(playerId);
    const songs = playerData.songs || [];
    
    // Get current game date
    const gameDate = getCurrentGameDate(playerData);
    const gameDateString = formatDate(gameDate);
    
    // 🛡️ DUPLICATE PROTECTION: Check if already processed today
    const lastProcessed = playerData.lastProcessedDate?.toDate();
    if (lastProcessed) {
      const lastProcessedString = formatDate(lastProcessed);
      if (lastProcessedString === gameDateString) {
    console.log(`⏭️ Skipping ${playerData.artistName || playerId} - already processed for ${gameDateString}`);
    return { skipped: true, reason: 'duplicate', wroteBatch: false };
      }
    }

    const updatedSongs = [];
    let totalNewIncome = 0;
    let totalNewStreams = 0;

    // Process each song
    for (const song of songs) {
      // Keep non-released songs in the array
      if (song.state !== 'released' || !song.releaseDate) {
        updatedSongs.push(song);
        continue;
      }

      // Validate release date
      const releaseDate = toDateSafe(song.releaseDate);
      if (!releaseDate || isNaN(releaseDate.getTime())) {
        updatedSongs.push(song);
        continue;
      }

      // Calculate days since release
      const daysSinceRelease = Math.floor((gameDate - releaseDate) / (1000 * 60 * 60 * 24));
      if (daysSinceRelease < 0) {
        updatedSongs.push(song);
        continue;
      }

      // Calculate daily streams with decay
      let dailyStreams = calculateDailyStreamGrowth(song, playerData, gameDate);
      
      // 🌍 REALISTIC DAILY STREAM CAP
      // Even viral mega-hits don't get 100M+ streams per day
      // - Taylor Swift's biggest day: ~20M streams (Spotify record)
      // - Maximum realistic daily streams: 50M per song per day
      const MAX_DAILY_STREAMS = 50000000; // 50 million
      if (dailyStreams > MAX_DAILY_STREAMS) {
        dailyStreams = MAX_DAILY_STREAMS;
      }

      // Calculate income ($0.003 per stream)
      const dailyIncome = dailyStreams * 0.003;

      // Update song
      const updatedSong = {
        ...song,
        streams: (song.streams || 0) + dailyStreams,
        totalRevenue: (song.totalRevenue || 0) + dailyIncome,
      };

      updatedSongs.push(updatedSong);
      totalNewStreams += dailyStreams;
      totalNewIncome += dailyIncome;
    }

    // Calculate total streams
    const totalStreams = updatedSongs.reduce((sum, s) => sum + (s.streams || 0), 0);

    // Prepare update
    const updates = {
      songs: updatedSongs,
      totalStreams: totalStreams,
      currentMoney: (playerData.currentMoney || 0) + totalNewIncome,
      lastProcessedDate: admin.firestore.Timestamp.now(), // 🛡️ Mark as processed
    };

    // 💡 INSPIRATION RESTORATION - restore creative energy each game day
    try {
      const currentInspiration = Number(playerData.inspirationLevel || 0);
    const inspirationGain = 10; // +10 inspiration per game day (configurable)
    const newInspiration = Math.min(100, currentInspiration + inspirationGain);
      if (newInspiration !== currentInspiration) {
        updates.inspirationLevel = newInspiration;
        updates.creativity = newInspiration; // keep legacy field in sync
        console.log(`💡 ${playerData.artistName || playerId}: Inspiration ${currentInspiration} → ${newInspiration} (+${inspirationGain})`);
      }
    } catch (e) {
      console.warn('Failed to compute inspiration restoration for', playerId, e && e.message ? e.message : e);
    }

    // Apply sanitization
    const sanitizedUpdates = sanitizeForFirestore(updates);
    batch.update(playerRef, sanitizedUpdates);

    return {
      success: true,
      newStreams: totalNewStreams,
      newIncome: totalNewIncome,
      wroteBatch: true,
    };

  } catch (error) {
    console.error(`❌ Error processing player ${playerId}:`, error);
    console.error(`   Player: ${playerData.artistName || playerId}, Songs: ${(playerData.songs || []).length}`);
    
    // 🛡️ FALLBACK: Preserve original songs array even on error
    try {
      const fallbackUpdate = {
        songs: playerData.songs || [],
        lastProcessedDate: admin.firestore.Timestamp.now(),
      };
      batch.update(db.collection('players').doc(playerId), fallbackUpdate);
      console.log(`🛡️ Applied fallback update for ${playerData.artistName || playerId} - songs preserved (${(playerData.songs || []).length} songs)`);
      return {
        success: false,
        error: error.message,
        fallbackApplied: true,
        wroteBatch: true,
      };
    } catch (fallbackError) {
      console.error(`❌ Fallback also failed for ${playerId}:`, fallbackError);
      return {
        success: false,
        error: error.message,
        fallbackApplied: false,
        wroteBatch: false,
      };
    }
  }
}

async function claimDailyUpdateBatch({ forceRestart = false } = {}) {
  const now = new Date();
  const todayKey = formatDate(now);

  return db.runTransaction(async (tx) => {
    const snapshot = await tx.get(DAILY_UPDATE_STATUS_REF);
    let state = snapshot.exists ? snapshot.data() : null;

    const beginNewRun = () => {
      const runId = `${todayKey}-${now.getTime()}`;
      state = {
        runId,
        runDate: todayKey,
        lastPlayerId: null,
        processedCount: 0,
        skippedCount: 0,
        errorCount: 0,
        completed: false,
      };

      tx.set(DAILY_UPDATE_STATUS_REF, {
        ...state,
        processing: true,
        lockedAt: admin.firestore.FieldValue.serverTimestamp(),
        startedAt: admin.firestore.FieldValue.serverTimestamp(),
        lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
      });

      return { canProcess: true, state };
    };

    if (forceRestart || !state) {
      return beginNewRun();
    }

    if (state.runDate !== todayKey) {
      return beginNewRun();
    }

    if (state.completed && !forceRestart) {
      return { canProcess: false, reason: 'completed', state };
    }

    const lockedAtDate = toDateSafe(state.lockedAt);
    if (state.processing && lockedAtDate && now - lockedAtDate.getTime() < DAILY_UPDATE_LOCK_TIMEOUT_MS) {
      return { canProcess: false, reason: 'locked', state };
    }

    tx.set(
      DAILY_UPDATE_STATUS_REF,
      {
        runId: state.runId,
        runDate: state.runDate,
        processing: true,
        lockedAt: admin.firestore.FieldValue.serverTimestamp(),
        lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
        startedAt: state.startedAt || admin.firestore.FieldValue.serverTimestamp(),
        lastPlayerId: state.lastPlayerId || null,
        processedCount: typeof state.processedCount === 'number' ? state.processedCount : 0,
        skippedCount: typeof state.skippedCount === 'number' ? state.skippedCount : 0,
        errorCount: typeof state.errorCount === 'number' ? state.errorCount : 0,
        completed: false,
      },
      { merge: true },
    );

    state = {
      runId: state.runId,
      runDate: state.runDate,
      lastPlayerId: state.lastPlayerId || null,
      processedCount: Number(state.processedCount || 0),
      skippedCount: Number(state.skippedCount || 0),
      errorCount: Number(state.errorCount || 0),
    };

    return { canProcess: true, state };
  });
}

async function finalizeDailyUpdateBatch({
  state,
  lastPlayerId,
  processed = 0,
  skipped = 0,
  errors = 0,
  isComplete = false,
  trigger = 'manual',
}) {
  const update = {
    runId: state.runId,
    runDate: state.runDate,
    processing: false,
    lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
  };

  if (typeof lastPlayerId !== 'undefined') {
    update.lastPlayerId = lastPlayerId;
  }

  if (processed > 0) {
    update.processedCount = admin.firestore.FieldValue.increment(processed);
  }

  if (skipped > 0) {
    update.skippedCount = admin.firestore.FieldValue.increment(skipped);
  }

  if (errors > 0) {
    update.errorCount = admin.firestore.FieldValue.increment(errors);
  }

  update.lastBatch = sanitizeForFirestore({
    trigger,
    processed,
    skipped,
    errors,
    completed: isComplete,
    recordedAt: new Date().toISOString(),
  });

  if (isComplete) {
    update.completed = true;
    update.completedAt = admin.firestore.FieldValue.serverTimestamp();
    update.lastPlayerId = null;
  }

  await DAILY_UPDATE_STATUS_REF.set(update, { merge: true });
}

async function releaseDailyUpdateLock(state, errorMessage) {
  if (!state) return;

  const update = {
    runId: state.runId,
    runDate: state.runDate,
    processing: false,
    lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
  };

  if (errorMessage) {
    update.lastError = errorMessage;
    update.lastErrorAt = admin.firestore.FieldValue.serverTimestamp();
  }

  await DAILY_UPDATE_STATUS_REF.set(update, { merge: true });
}

async function runDailyUpdateBatch({
  trigger = 'manual',
  batchSize = DAILY_UPDATE_BATCH_SIZE,
  forceRestart = false,
} = {}) {
  const claim = await claimDailyUpdateBatch({ forceRestart });

  if (!claim.canProcess) {
    return {
      status: claim.reason === 'completed' ? 'idle' : 'locked',
      reason: claim.reason,
      runId: claim.state?.runId || null,
      runDate: claim.state?.runDate || null,
      processed: 0,
      skipped: 0,
      errors: 0,
    };
  }

  const state = claim.state;
  let query = db
    .collection('players')
    .orderBy(admin.firestore.FieldPath.documentId())
    .limit(batchSize);

  if (state.lastPlayerId) {
    query = query.startAfter(state.lastPlayerId);
  }

  let snapshot;

  try {
    snapshot = await query.get();
  } catch (error) {
    await releaseDailyUpdateLock(state, error.message);
    throw error;
  }

  if (snapshot.empty) {
    console.log('ℹ️ No players found for daily update batch; marking run as complete.');
    await finalizeDailyUpdateBatch({
      state,
      lastPlayerId: null,
      processed: 0,
      skipped: 0,
      errors: 0,
      isComplete: true,
      trigger,
    });

    return {
      status: 'complete',
      reason: 'no_players',
      processed: 0,
      skipped: 0,
      errors: 0,
      fetched: 0,
      runId: state.runId,
      runDate: state.runDate,
    };
  }

  const batch = db.batch();
  let processed = 0;
  let skipped = 0;
  let errors = 0;
  let writes = 0;

  for (const doc of snapshot.docs) {
    try {
      const result = await processDailyStreamsForPlayer(doc.id, doc.data(), batch);

      if (result?.skipped) {
        skipped += 1;
      } else if (result?.success) {
        processed += 1;
      } else {
        errors += 1;
      }

      if (result?.wroteBatch) {
        writes += 1;
      }
    } catch (playerError) {
      errors += 1;
      console.error(`❌ Error processing player ${doc.id}:`, playerError);
    }
  }

  try {
    if (writes > 0) {
      await batch.commit();
    } else {
      console.log('ℹ️ Daily update batch produced no writes; commit skipped.');
    }
  } catch (commitError) {
    await releaseDailyUpdateLock(state, commitError.message);
    throw commitError;
  }

  const lastDocId = snapshot.docs[snapshot.docs.length - 1].id;
  const isComplete = snapshot.size < batchSize;

  await finalizeDailyUpdateBatch({
    state,
    lastPlayerId: isComplete ? null : lastDocId,
    processed,
    skipped,
    errors,
    isComplete,
    trigger,
  });

  console.log(
    `🧮 Daily update batch (${trigger}) runId=${state.runId} processed=${processed} skipped=${skipped} errors=${errors} fetched=${snapshot.size} nextCursor=${isComplete ? 'DONE' : lastDocId}`,
  );

  return {
    status: isComplete ? 'complete' : 'partial',
    reason: isComplete ? 'processed_all' : 'pending_players',
    processed,
    skipped,
    errors,
    fetched: snapshot.size,
    runId: state.runId,
    runDate: state.runDate,
    lastPlayerId: isComplete ? null : lastDocId,
  };
}

/**
 * Scheduled function: runs every hour (1 real hour = 1 game day)
 */
exports.dailyGameUpdate = onSchedule({
  schedule: '0 * * * *', // Every hour
  timeZone: 'America/New_York',
  memory: '1GiB',
  timeoutSeconds: 540,
  region: 'us-central1',
}, async () => {
  console.log('⏰ Starting scheduled daily game update (paginated)...');
  const startTime = Date.now();
  const stats = { processed: 0, skipped: 0, errors: 0, batches: 0 };
  let lastResult = null;

  for (let i = 0; i < DAILY_UPDATE_MAX_BATCHES; i++) {
    lastResult = await runDailyUpdateBatch({ trigger: 'scheduled' });

    if (lastResult.status === 'locked') {
      console.log('🔒 Daily update is locked by another worker. Exiting.');
      break;
    }

    if (lastResult.status === 'idle') {
      console.log('✅ Daily update already completed for this game day.');
      break;
    }

    stats.processed += lastResult.processed || 0;
    stats.skipped += lastResult.skipped || 0;
    stats.errors += lastResult.errors || 0;
    if (lastResult.status === 'partial' || lastResult.status === 'complete') {
      stats.batches += 1;
    }

    if (lastResult.status === 'partial') {
      const elapsed = Date.now() - startTime;
      if (elapsed > 480_000) { // 8 minutes safety buffer
        console.log('⏳ Time budget nearly exhausted; remaining batches will continue on the next invocation.');
        break;
      }
      continue;
    }

    if (lastResult.status === 'complete') {
      console.log('✅ Daily update batches completed in this invocation.');
      break;
    }
  }

  const duration = Date.now() - startTime;

  await logAdminAction('daily_game_update_paginated', {
    trigger: 'scheduled',
    batchesExecuted: stats.batches,
    processedPlayers: stats.processed,
    skippedPlayers: stats.skipped,
    errorCount: stats.errors,
    finalStatus: lastResult ? lastResult.status : 'no-op',
    finalReason: lastResult ? lastResult.reason : 'none',
    durationMs: duration,
  });

  return {
    success: lastResult ? lastResult.status !== 'locked' : true,
    durationMs: duration,
    finalStatus: lastResult ? lastResult.status : 'no-op',
    finalReason: lastResult ? lastResult.reason : 'none',
    ...stats,
  };
});

/**
 * Manual trigger: admin can force additional batches
 */
exports.triggerDailyUpdate = onCall({
  region: 'us-central1',
  memory: '512MiB',
  timeoutSeconds: 540,
}, async (request) => {
  const triggerInfo = request.auth?.uid || 'unknown';
  console.log('🔧 Manual daily update triggered by:', triggerInfo);

  const startTime = Date.now();
  const payload = request.data || {};
  const requestedMax = Number(payload.maxBatches || 25);
  const maxBatches = Math.max(1, Math.min(requestedMax, 100));
  const batchSize = Math.max(25, Math.min(Number(payload.batchSize || DAILY_UPDATE_BATCH_SIZE), 500));
  let forceRestart = payload.reset === true;

  const stats = { processed: 0, skipped: 0, errors: 0, batches: 0 };
  let lastResult = null;

  for (let i = 0; i < maxBatches; i++) {
    lastResult = await runDailyUpdateBatch({
      trigger: 'manual',
      batchSize,
      forceRestart,
    });

    forceRestart = false;

    if (lastResult.status === 'locked') {
      console.log('🔒 Daily update is locked by another worker. Manual run stopping.');
      break;
    }

    if (lastResult.status === 'idle') {
      console.log('✅ Daily update already completed for this game day (manual trigger).');
      break;
    }

    stats.processed += lastResult.processed || 0;
    stats.skipped += lastResult.skipped || 0;
    stats.errors += lastResult.errors || 0;
    if (lastResult.status === 'partial' || lastResult.status === 'complete') {
      stats.batches += 1;
    }

    if (lastResult.status === 'partial') {
      continue;
    }

    if (lastResult.status === 'complete') {
      break;
    }
  }

  const duration = Date.now() - startTime;

  await logAdminAction('manual_daily_update_paginated', {
    trigger: triggerInfo,
    batchesExecuted: stats.batches,
    processedPlayers: stats.processed,
    skippedPlayers: stats.skipped,
    errorCount: stats.errors,
    finalStatus: lastResult ? lastResult.status : 'no-op',
    finalReason: lastResult ? lastResult.reason : 'none',
    durationMs: duration,
  });

  return {
    success: lastResult ? lastResult.status !== 'locked' : true,
    durationMs: duration,
    finalStatus: lastResult ? lastResult.status : 'no-op',
    finalReason: lastResult ? lastResult.reason : 'none',
    ...stats,
  };
});

module.exports = {
  dailyGameUpdate: exports.dailyGameUpdate,
  triggerDailyUpdate: exports.triggerDailyUpdate,
  processDailyStreamsForPlayer,
  calculateDailyStreamGrowth,
  runDailyUpdateBatch,
};
