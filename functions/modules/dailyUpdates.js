const {onSchedule} = require('firebase-functions/v2/scheduler');
const {onCall, HttpsError} = require('firebase-functions/v2/https');
const admin = require('firebase-admin');
const { sanitizeForFirestore, formatDate, getCurrentGameDate, logAdminAction, toDateSafe } = require('./utils');

const db = admin.firestore();

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
        return { skipped: true, reason: 'duplicate' };
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
      const dailyStreams = calculateDailyStreamGrowth(song, playerData, gameDate);

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

    // Apply sanitization
    const sanitizedUpdates = sanitizeForFirestore(updates);
    batch.update(playerRef, sanitizedUpdates);

    return {
      success: true,
      newStreams: totalNewStreams,
      newIncome: totalNewIncome,
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
      return { success: false, error: error.message, fallbackApplied: true };
    } catch (fallbackError) {
      console.error(`❌ Fallback also failed for ${playerId}:`, fallbackError);
      return { success: false, error: error.message, fallbackApplied: false };
    }
  }
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
}, async (event) => {
  console.log('⏰ Starting scheduled daily game update...');
  const startTime = Date.now();

  try {
    const playersSnapshot = await db.collection('players').get();
    const batch = db.batch();
    
    let processed = 0;
    let skipped = 0;
    let errors = 0;

    for (const doc of playersSnapshot.docs) {
      const result = await processDailyStreamsForPlayer(doc.id, doc.data(), batch);
      
      if (result.skipped) {
        skipped++;
      } else if (result.success) {
        processed++;
      } else {
        errors++;
      }
    }

    await batch.commit();
    
    const duration = Date.now() - startTime;
    const logDetails = {
      type: 'scheduled',
      playersProcessed: processed,
      playersSkipped: skipped,
      errorsEncountered: errors,
      duration: `${duration}ms`,
      timestamp: new Date().toISOString(),
    };

    await logAdminAction('daily_game_update', logDetails);
    
    console.log(`✅ Daily update complete: ${processed} processed, ${skipped} skipped, ${errors} errors (${duration}ms)`);
    return { success: true, ...logDetails };

  } catch (error) {
    console.error('❌ Daily game update failed:', error);
    await logAdminAction('daily_game_update_error', {
      error: error.message,
      stack: error.stack,
      timestamp: new Date().toISOString(),
    });
    throw error;
  }
});

/**
 * Manual trigger: admin can force a daily update
 */
exports.triggerDailyUpdate = onCall({
  region: 'us-central1',
  memory: '512MiB',
  timeoutSeconds: 540,
}, async (request) => {
  console.log('🔧 Manual daily update triggered by:', request.auth?.uid || 'unknown');
  const startTime = Date.now();

  try {
    const playersSnapshot = await db.collection('players').get();
    const batch = db.batch();
    
    let processed = 0;
    let skipped = 0;
    let errors = 0;

    for (const doc of playersSnapshot.docs) {
      const result = await processDailyStreamsForPlayer(doc.id, doc.data(), batch);
      
      if (result.skipped) {
        skipped++;
      } else if (result.success) {
        processed++;
      } else {
        errors++;
      }
    }

    await batch.commit();
    
    const duration = Date.now() - startTime;
    const logDetails = {
      type: 'manual',
      triggeredBy: request.auth?.uid || 'unknown',
      playersProcessed: processed,
      playersSkipped: skipped,
      errorsEncountered: errors,
      duration: `${duration}ms`,
      timestamp: new Date().toISOString(),
    };

    await logAdminAction('manual_daily_update', logDetails);
    
    console.log(`✅ Manual update complete: ${processed} processed, ${skipped} skipped, ${errors} errors (${duration}ms)`);
    return { success: true, ...logDetails };

  } catch (error) {
    console.error('❌ Manual daily update failed:', error);
    await logAdminAction('manual_daily_update_error', {
      triggeredBy: request.auth?.uid || 'unknown',
      error: error.message,
      stack: error.stack,
      timestamp: new Date().toISOString(),
    });
    throw new HttpsError('internal', error.message);
  }
});

module.exports = {
  dailyGameUpdate: exports.dailyGameUpdate,
  triggerDailyUpdate: exports.triggerDailyUpdate,
  processDailyStreamsForPlayer,
  calculateDailyStreamGrowth,
};
