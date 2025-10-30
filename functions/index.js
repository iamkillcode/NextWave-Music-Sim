// Firebase Cloud Functions for NextWave Music Sim v2.0
// Enhanced with weekly charts, leaderboards, achievements, anti-cheat, and NPC artists

const {onSchedule} = require('firebase-functions/v2/scheduler');
const {onCall, HttpsError} = require('firebase-functions/v2/https');
const {onDocumentWritten} = require('firebase-functions/v2/firestore');
const {setGlobalOptions} = require('firebase-functions/v2');
const admin = require('firebase-admin');
admin.initializeApp();

const db = admin.firestore();

// Set global options for all v2 functions
setGlobalOptions({
  region: 'us-central1',
  maxInstances: 10,
  timeoutSeconds: 540,
  memory: '512MiB',
});

// ---------------------------------------------------------------------------
// Exportable helpers for unit tests
// (kept small and pure so they can be tested without initializing Firestore)
// ---------------------------------------------------------------------------

/**
 * Merge incoming song list with existing songs and preserve server-managed fields
 * unless performing an admin update.
 */
function mergeSongs(incomingValue, existingSongs, action) {
  const incomingSongs = Array.isArray(incomingValue) ? incomingValue : [];
  const existing = existingSongs || [];

  if (action === 'admin_stat_update') {
    return incomingSongs;
  }

  return incomingSongs.map((inc) => {
    if (!inc || !inc.id) return inc;
    const ex = existing.find((s) => s.id === inc.id) || {};

    return {
      ...ex,
      ...inc,
      streams: (ex.streams !== undefined && ex.streams !== null) ? ex.streams : inc.streams,
      lastDayStreams: (ex.lastDayStreams !== undefined && ex.lastDayStreams !== null) ? ex.lastDayStreams : inc.lastDayStreams,
      last7DaysStreams: (ex.last7DaysStreams !== undefined && ex.last7DaysStreams !== null) ? ex.last7DaysStreams : inc.last7DaysStreams,
      regionalStreams: (ex.regionalStreams !== undefined && ex.regionalStreams !== null) ? ex.regionalStreams : inc.regionalStreams,
      peakDailyStreams: (ex.peakDailyStreams !== undefined && ex.peakDailyStreams !== null) ? ex.peakDailyStreams : inc.peakDailyStreams,
      daysOnChart: (ex.daysOnChart !== undefined && ex.daysOnChart !== null) ? ex.daysOnChart : inc.daysOnChart,
    };
  });
}

// Export helpers for unit tests
module.exports.mergeSongs = mergeSongs;

// Utility: normalize various date shapes (Firestore Timestamp, JS Date, string, epoch)
function toDateSafe(value) {
  if (!value) return null;
  if (value instanceof Date) return value;
  if (typeof value.toDate === 'function') return value.toDate();
  if (typeof value === 'string' || typeof value === 'number') {
    const d = new Date(value);
    if (!isNaN(d.getTime())) return d;
  }
  return null;
}

// Compute the current in-game date based on game settings
async function getCurrentGameDateServer() {
  try {
    const gameSettingsRef = db.collection('gameSettings').doc('globalTime');
    const gameSettingsDoc = await gameSettingsRef.get();
    if (!gameSettingsDoc.exists) {
      // Default to Jan 1, 2020 if not initialized
      return new Date(2020, 0, 1);
    }

    const data = gameSettingsDoc.data();
    const realWorldStartDate = toDateSafe(data.realWorldStartDate);
    const gameWorldStartDate = toDateSafe(data.gameWorldStartDate);

    // Use server time to keep consistent across users
    const now = new Date();

    const realHoursElapsed = Math.floor((now - realWorldStartDate) / (1000 * 60 * 60));
    const gameDaysElapsed = realHoursElapsed; // 1 real hour = 1 game day
    const calculated = new Date(gameWorldStartDate.getTime());
    calculated.setDate(calculated.getDate() + gameDaysElapsed);
    // Normalize to midnight
    return new Date(calculated.getFullYear(), calculated.getMonth(), calculated.getDate());
  } catch (e) {
    console.error('❌ Error computing current game date on server:', e);
    return new Date(2020, 0, 1);
  }
}

// ============================================================================
// 1. DAILY UPDATE - Main game progression (EVERY HOUR)
// In-game: 1 day = 1 real-world hour
// ============================================================================

exports.dailyGameUpdate = onSchedule({
  schedule: '0 * * * *', // Every hour (1 in-game day)
  timeZone: 'UTC',
  timeoutSeconds: 540,
  memory: '1GiB',
}, async (event) => {
  console.log('🌅 Starting daily game update for all players...');
    
    try {
      // 1. Calculate current game date from game settings
      const gameSettingsRef = db.collection('gameSettings').doc('globalTime');
      const gameSettingsDoc = await gameSettingsRef.get();
      
      if (!gameSettingsDoc.exists) {
        console.error('❌ Game time not initialized in gameSettings/globalTime');
        // Try to initialize it
        const realWorldStartDate = new Date(2025, 9, 1, 0, 0); // Oct 1, 2025
        const gameWorldStartDate = new Date(2020, 0, 1); // Jan 1, 2020
        
        await gameSettingsRef.set({
          realWorldStartDate: admin.firestore.Timestamp.fromDate(realWorldStartDate),
          gameWorldStartDate: admin.firestore.Timestamp.fromDate(gameWorldStartDate),
          hoursPerDay: 1,
          description: '1 real world hour equals 1 in-game day',
          lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
        });
        
        console.log('✅ Initialized game time system');
      }
      
      // Calculate current game date
      const data = gameSettingsDoc.exists ? gameSettingsDoc.data() : {
        realWorldStartDate: admin.firestore.Timestamp.fromDate(new Date(2025, 9, 1, 0, 0)),
        gameWorldStartDate: admin.firestore.Timestamp.fromDate(new Date(2020, 0, 1)),
      };
      
      const realWorldStartDate = toDateSafe(data.realWorldStartDate);
      const gameWorldStartDate = toDateSafe(data.gameWorldStartDate);
      const now = new Date();
      
      const realHoursElapsed = Math.floor((now - realWorldStartDate) / (1000 * 60 * 60));
      const gameDaysElapsed = realHoursElapsed; // 1 hour = 1 day
      
      const calculatedDate = new Date(gameWorldStartDate);
      calculatedDate.setDate(calculatedDate.getDate() + gameDaysElapsed);
      const currentGameDate = new Date(
        calculatedDate.getFullYear(),
        calculatedDate.getMonth(),
        calculatedDate.getDate()
      );
      
      console.log(`📅 Current game date: ${currentGameDate.toISOString().split('T')[0]}`);

      // Load Remote Config parameters once for this run (with safe fallbacks)
      let rcParams = {};
      try {
        if (admin.remoteConfig) {
          const tmpl = await admin.remoteConfig().getTemplate();
          rcParams = (tmpl && tmpl.parameters) ? tmpl.parameters : {};
        }
      } catch (e) {
        console.warn('Remote Config unavailable for dailyGameUpdate, using defaults');
      }
      const numOr = (v, def) => {
        const n = Number(v);
        return Number.isFinite(n) ? n : def;
      };
      const boolOr = (v, def) => {
        if (typeof v === 'boolean') return v;
        if (v === 'true' || v === true) return true;
        if (v === 'false' || v === false) return false;
        return def;
      };
      const getParam = (key, def, type = 'number') => {
        try {
          const rcVal = rcParams && rcParams[key] && rcParams[key].defaultValue && rcParams[key].defaultValue.value;
          if (type === 'bool') return boolOr(rcVal ?? process.env[key], def);
          return numOr(rcVal ?? process.env[key], def);
        } catch (e) {
          return def;
        }
      };

      const certConfig = {
        enabled: getParam('certEnabled', true, 'bool'),
        streamsPerUnit: getParam('certStreamsPerUnit', 150),
        thresholds: {
          silver: getParam('certSilverUnits', 50000),
          gold: getParam('certGoldUnits', 100000),
          platinum: getParam('certPlatinumUnits', 250000),
          diamond: getParam('certDiamondUnits', 1000000),
          multiStep: getParam('certMultiPlatinumStepUnits', 250000),
        },
        rewards: {
          songMoney: getParam('certSongRewardMoney', 5000),
          albumMoney: getParam('certAlbumRewardMoney', 10000),
          songFame: getParam('certSongRewardFame', 5),
          albumFame: getParam('certAlbumRewardFame', 10),
        },
      };
      
      // 2. Get ALL players
      const playersSnapshot = await db.collection('players').get();
      console.log(`👥 Processing ${playersSnapshot.size} players...`);
      
      let processedCount = 0;
      let errorCount = 0;
      
      // 3. Process players in batches
      const batchLimit = 500;
      let batch = db.batch();
      let batchCount = 0;
      
      for (const playerDoc of playersSnapshot.docs) {
        try {
          const playerId = playerDoc.id;
          const playerData = playerDoc.data();
          
          // Process daily streams, decay, and fanbase growth
          const updates = await processDailyStreamsForPlayer(
            playerId,
            playerData,
            currentGameDate,
            certConfig
          );
          
          if (updates) {
            batch.update(playerDoc.ref, updates);
            batchCount++;
            processedCount++;
            
            if (batchCount >= batchLimit) {
              await batch.commit();
              batch = db.batch();
              batchCount = 0;
              console.log(`💾 Committed batch of ${batchLimit} players`);
            }
          }
        } catch (error) {
          console.error(`❌ Error processing player ${playerDoc.id}:`, error);
          errorCount++;
        }
      }
      
      // Commit remaining
      if (batchCount > 0) {
        await batch.commit();
        console.log(`💾 Committed final batch of ${batchCount} players`);
      }
      
      // ===================================================================
      // DAILY SIDE HUSTLE CONTRACT GENERATION
      // ===================================================================
      console.log('📋 Generating new side hustle contracts...');
      try {
        await generateDailySideHustleContracts();
        console.log('✅ Daily side hustle contracts generated');
      } catch (contractError) {
        console.error('❌ Error generating side hustle contracts:', contractError);
        // Don't fail entire daily update if contract generation fails
      }
      
      console.log(`✅ Daily update complete!`);
      console.log(`   Processed: ${processedCount} / ${playersSnapshot.size} players`);
      console.log(`   Errors: ${errorCount}`);
      
      return null;
    } catch (error) {
      console.error('❌ Fatal error in daily update:', error);
      throw error;
    }
  });

// ============================================================================
// 2. WEEKLY LEADERBOARD UPDATE - Snapshots & historical tracking (EVERY 7 HOURS)
// In-game: 1 week = 7 real-world hours
// ============================================================================

exports.weeklyLeaderboardUpdate = onSchedule({
  schedule: '0 */7 * * *', // Every 7 hours (1 in-game week)
  timeZone: 'UTC',
  timeoutSeconds: 540,
  memory: '512MiB',
}, async (event) => {
  console.log('📊 Starting weekly leaderboard snapshot...');
    
    try {
      const now = new Date();
      const weekId = getWeekId(now);
      
      // 1. Create snapshot for songs
      await createSongLeaderboardSnapshot(weekId, now);
      
      // 2. Create snapshot for artists
      await createArtistLeaderboardSnapshot(weekId, now);
      
      // 3. Update chart statistics
      await updateChartStatistics(weekId);
      
      console.log('✅ Weekly leaderboard snapshot complete!');
      return null;
    } catch (error) {
      console.error('❌ Error in weekly leaderboard update:', error);
      throw error;
    }
  });

// ============================================================================
// 3. ACHIEVEMENT DETECTION - Real-time on player updates
// ============================================================================

exports.checkAchievements = onDocumentWritten('players/{playerId}', async (event) => {
  const playerId = event.params.playerId;
  const before = event.data?.before?.data();
  const after = event.data?.after?.data();
  
  if (!before || !after) return null;
    
    try {
      const newAchievements = [];
      
      // Check for various achievements
      newAchievements.push(...checkStreamMilestones(before, after, playerId));
      newAchievements.push(...checkMoneyMilestones(before, after, playerId));
      newAchievements.push(...checkChartMilestones(before, after, playerId));
      newAchievements.push(...checkRegionalMilestones(before, after, playerId));
      newAchievements.push(...checkCareerMilestones(before, after, playerId));
      
      // Award new achievements
      if (newAchievements.length > 0) {
        await awardAchievements(playerId, newAchievements);
        console.log(`🏆 ${playerId} earned ${newAchievements.length} achievement(s)!`);
      }
      
      return null;
    } catch (error) {
      console.error(`❌ Error checking achievements for ${playerId}:`, error);
      return null;
    }
  });

// ============================================================================
// 4. ANTI-CHEAT VALIDATION - Validates critical actions
// ============================================================================

exports.validateSongRelease = onCall(async (request) => {
  // Require authentication
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'Must be authenticated');
  }
  
  const data = request.data;
  
  const playerId = request.auth.uid;
  const { song, productionCost } = data;
  // Validate numeric inputs
  if (typeof productionCost !== 'number' || !Number.isFinite(productionCost)) {
    throw new HttpsError('invalid-argument', 'Invalid productionCost');
  }
  // Validate nested numeric fields in the song payload
  try {
    validateNestedNumbers(song, 'song');
  } catch (err) {
    console.warn('Invalid numeric in song payload:', err.message || err);
    throw new HttpsError('invalid-argument', 'Invalid numeric value in song payload');
  }
  
  try {
    // Get player data
    const playerDoc = await db.collection('players').doc(playerId).get();
    if (!playerDoc.exists) {
      throw new HttpsError('not-found', 'Player not found');
    }
    
    const playerData = playerDoc.data();
    
    // Validation checks
    const validations = {
      hasEnoughMoney: playerData.currentMoney >= productionCost,
      qualityMatchesSkill: validateQuality(song, playerData),
      noDuplicateName: await checkNoDuplicateSongName(playerId, song.title),
      validGenre: validateGenre(song.genre),
      validPlatforms: validatePlatforms(song.streamingPlatforms),
    };
    
    const isValid = Object.values(validations).every(v => v === true);
    
    if (!isValid) {
      return {
        valid: false,
        reason: getValidationErrors(validations),
      };
    }
    
    return {
      valid: true,
      approvedBy: 'server',
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    };
  } catch (error) {
    console.error('❌ Error validating song release:', error);
    throw new HttpsError('internal', error.message);
  }
});

// ============================================================================
// 5. SPECIAL EVENTS SYSTEM - Dynamic game events (EVERY 7 HOURS)
// In-game: 1 week = 7 real-world hours
// ============================================================================

exports.triggerSpecialEvent = onSchedule({
  schedule: '0 */7 * * *', // Every 7 hours (1 in-game week)
  timeZone: 'UTC',
  timeoutSeconds: 540,
  memory: '512MiB',
}, async (event) => {
  console.log('🎪 Triggering weekly special event...');
    
    try {
      const events = [
        {
          id: 'viral_week',
          name: '🔥 Viral Week',
          description: 'All songs get 2x viral chance!',
          effect: { viralityMultiplier: 2.0 },
          duration: 7, // hours (1 in-game week)
        },
        {
          id: 'album_week',
          name: '💿 Album Week',
          description: 'Albums earn 50% more streams!',
          effect: { albumBonus: 1.5 },
          duration: 7, // hours (1 in-game week)
        },
        {
          id: 'regional_focus',
          name: '🌍 Regional Spotlight',
          description: 'Random region gets 2x streams!',
          effect: { 
            regionalBonus: 2.0,
            targetRegion: selectRandomRegion(),
          },
          duration: 7, // hours (1 in-game week)
        },
        {
          id: 'new_artist_boost',
          name: '⭐ Rising Stars Week',
          description: 'Artists under 10K fans get 3x discovery!',
          effect: { newArtistBonus: 3.0 },
          duration: 7, // hours (1 in-game week)
        },
        {
          id: 'chart_fever',
          name: '📊 Chart Fever',
          description: 'Top 10 songs get extra rewards!',
          effect: { chartBonusMultiplier: 1.5 },
          duration: 7, // hours (1 in-game week)
        },
      ];
      
      // Select random event
      const event = events[Math.floor(Math.random() * events.length)];
      
      // Set active event
      await db.collection('game_state').doc('active_event').set({
        ...event,
        startDate: admin.firestore.FieldValue.serverTimestamp(),
        endDate: admin.firestore.Timestamp.fromDate(
          new Date(Date.now() + event.duration * 60 * 60 * 1000) // 7 hours (1 in-game week)
        ),
        active: true,
      });
      
      console.log(`🎉 Special event activated: ${event.name}`);
      return null;
    } catch (error) {
      console.error('❌ Error triggering special event:', error);
      throw error;
    }
  });

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

async function processDailyStreamsForPlayer(playerId, playerData, currentGameDate, certConfig) {
  try {
    const songs = playerData.songs || [];
    
    // ✅ CHECK IF SIDE HUSTLE CONTRACT EXPIRED (even when player offline)
    let sideHustleExpired = false;
    let sideHustlePay = 0;
    let sideHustleEnergyCost = 0;
    
    if (playerData.activeSideHustle && playerData.activeSideHustle.endDate) {
      const endDate = toDateSafe(playerData.activeSideHustle.endDate);
      
      if (currentGameDate >= endDate) {
        console.log(`⏰ Side hustle "${playerData.activeSideHustle.type}" expired for ${playerData.displayName || playerId}`);
        sideHustleExpired = true;
      } else {
        // Contract still active - apply daily effects
        sideHustlePay = Math.min(200, Math.max(50, playerData.activeSideHustle.dailyPay || 100));
        sideHustleEnergyCost = Math.min(30, Math.max(5, playerData.activeSideHustle.dailyEnergyCost || 15));
        console.log(`💼 Side hustle active: +$${sideHustlePay}, -${sideHustleEnergyCost} energy for ${playerData.displayName || playerId}`);
      }
    }
    
    if (songs.length === 0) {
      // Even without songs, restore energy and apply side hustle
      const updates = {};
      
      // ✅ ENERGY RESTORATION - Always restore energy, even without songs
      const currentEnergy = playerData.energy || 100;
      const restoredEnergy = currentEnergy < 100 ? 100 : currentEnergy;
      const finalEnergy = Math.max(0, restoredEnergy - sideHustleEnergyCost);
      
      updates.energy = finalEnergy;
      console.log(`🔋 ${playerData.displayName || playerId}: Energy ${currentEnergy} → ${restoredEnergy} → ${finalEnergy} (no songs)`);
      
      // Apply side hustle payment
      if (sideHustlePay > 0) {
        const currentMoney = playerData.money || 0;
        updates.money = currentMoney + sideHustlePay;
        console.log(`💰 ${playerData.displayName || playerId}: Side hustle pay +$${sideHustlePay}`);
      }
      
      // Check side hustle expiration
      if (sideHustleExpired) {
        updates.activeSideHustle = null;
        console.log(`✅ Terminated expired side hustle for ${playerData.displayName || playerId} (no songs)`);
      }
      
      // REMOVE OLD FIELD if it exists
      if (playerData.currentSideHustle) {
        updates.currentSideHustle = null;
        updates.sideHustlePaymentPerDay = null;
      }
      
      // Only return updates if there's something to update
      if (Object.keys(updates).length > 0) {
        updates.lastUpdated = admin.firestore.FieldValue.serverTimestamp();
        return updates;
      }
      
      return null;
    }
    
    let totalNewStreams = 0;
    let totalNewIncome = 0;
    const updatedSongs = [];
    
    // Get active event bonuses
    const activeEvent = await getActiveEvent();
    
    // Helper: determine certification from units
    const determineCertification = (units, th) => {
      if (!Number.isFinite(units)) return { tier: 'none', level: 0 };
      if (units >= th.diamond) return { tier: 'diamond', level: 1 };
      if (units >= th.platinum) {
        const extra = Math.max(0, Math.floor((units - th.platinum) / Math.max(1, th.multiStep)));
        const level = 1 + extra;
        return level > 1 ? { tier: 'multi_platinum', level } : { tier: 'platinum', level: 1 };
      }
      if (units >= th.gold) return { tier: 'gold', level: 1 };
      if (units >= th.silver) return { tier: 'silver', level: 1 };
      return { tier: 'none', level: 0 };
    };

    const certAwards = [];

    // Process each song
    for (const song of songs) {
      if (song.state !== 'released' || !song.releasedDate) {
        updatedSongs.push(song);
        continue;
      }
      
        // Normalize release date regardless of type (Timestamp/Date/string/epoch)
        const releaseDate = toDateSafe(song.releasedDate);
        if (!releaseDate) {
          console.warn(`⚠️ Invalid releasedDate for song ${song.id || song.title || '(unknown)'}, skipping`);
          updatedSongs.push(song);
          continue;
        }
      // Clamp release date to not exceed current game date to ensure streaming starts on release day
      const effectiveReleaseDate = releaseDate > currentGameDate ? currentGameDate : releaseDate;
      
      // Calculate base streams
      let dailyStreams = calculateDailyStreamGrowth({ ...song, releasedDate: effectiveReleaseDate }, playerData, currentGameDate);

      // --- ViralWave Promo Buffer ---
      if (song.promoBuffer && song.promoEndDate) {
        const promoEnd = toDateSafe(song.promoEndDate);
        if (promoEnd && promoEnd >= currentGameDate) {
          dailyStreams += song.promoBuffer;
        }
      }

      // Apply event bonuses
      dailyStreams = applyEventBonuses(dailyStreams, song, playerData, activeEvent);
      
      // Calculate income
      const songIncome = calculateSongIncome(song, dailyStreams);
      
      // ✅ DECAY last 7 days streams (14.3% per day = 1/7th)
      const decayedLast7Days = Math.round((song.last7DaysStreams || 0) * 0.857);
      
      // Distribute streams regionally
      const regionalStreamDelta = distributeStreamsRegionally(
        dailyStreams,
        playerData.homeRegion || 'usa',
        playerData.regionalFanbase || {},
        song.genre
      );
      
      // Update regional streams
      const updatedRegionalStreams = { ...song.regionalStreams };
      for (const [region, delta] of Object.entries(regionalStreamDelta)) {
        updatedRegionalStreams[region] = (updatedRegionalStreams[region] || 0) + delta;
      }
      
      // Track song age for lifecycle effects
      const daysOnChart = Math.floor((currentGameDate - releaseDate) / (1000 * 60 * 60 * 24)) + 1;
      const ageCategory = getAgeCategory(daysOnChart);
      
      // Update the song
      const updatedSong = {
        ...song,
        streams: song.streams + dailyStreams,
        lastDayStreams: dailyStreams,
        last7DaysStreams: decayedLast7Days + dailyStreams, // ✅ DECAY + NEW
        regionalStreams: updatedRegionalStreams,
        peakDailyStreams: Math.max(song.peakDailyStreams || 0, dailyStreams),
        daysOnChart: daysOnChart,
        ageCategory: ageCategory, // NEW: 'new', 'peak', 'declining', 'catalog'
      };

      // 🔰 Update eligible units (streams/streamsPerUnit + sales) and check certification
      try {
        if (certConfig && certConfig.enabled) {
          const sales = Math.max(0, Number(song.totalSales || 0));
          const streamsAfter = Math.max(0, Number(updatedSong.streams || 0));
          const spu = Math.max(1, Number(certConfig.streamsPerUnit || 150));
          const units = Math.floor(streamsAfter / spu) + Math.floor(sales);
          updatedSong.eligibleUnits = units;

          const prevTier = String(song.highestCertification || 'none');
          const prevLevel = Number(song.certificationLevel || 0);
          const { tier, level } = determineCertification(units, certConfig.thresholds || {});
          updatedSong.highestCertification = tier;
          updatedSong.certificationLevel = level;

          const improved = (() => {
            // Compare previous tier/level with new
            const order = { none: 0, silver: 1, gold: 2, platinum: 3, multi_platinum: 4, diamond: 5 };
            const prevRank = (order[prevTier] ?? 0) * 100 + prevLevel;
            const newRank = (order[tier] ?? 0) * 100 + level;
            return newRank > prevRank;
          })();

          if (improved && tier !== 'none' && level > 0) {
            updatedSong.lastCertifiedAt = admin.firestore.Timestamp.now();
            certAwards.push({
              itemType: 'song',
              itemId: song.id || song.songId || '',
              title: song.title || 'Untitled',
              tier,
              level,
              units,
            });
          }
        }
      } catch (e) {
        console.warn('Certification compute failed for song', song.id || song.title || '', e && e.message ? e.message : e);
      }
      
      updatedSongs.push(updatedSong);
      totalNewStreams += dailyStreams;
      totalNewIncome += songIncome;
    }
    
    // ✅ UPDATE REGIONAL FANBASE based on today's streams
    const updatedRegionalFanbase = calculateRegionalFanbaseGrowth(
      playerData.regionalFanbase || {},
      updatedSongs,
      playerData.homeRegion || 'usa',
      playerData.fame || 0 // Pass fame for conversion bonus
    );
    
    // ✅ FAME DECAY - Fame decreases based on artist idleness
    let famePenalty = 0;
    const lastActivityDate = toDateSafe(playerData.lastActivityDate) || null;
    
    if (lastActivityDate) {
      const daysSinceActivity = Math.floor((currentGameDate - lastActivityDate) / (1000 * 60 * 60 * 24));
      
      // After 7 days of inactivity, start losing 1% fame per day
      if (daysSinceActivity > 7) {
        const inactiveDays = daysSinceActivity - 7;
        const currentFame = playerData.fame || 0;
        famePenalty = Math.floor(currentFame * 0.01 * inactiveDays);
        console.log(`⚠️ ${playerData.name}: ${inactiveDays} inactive days, -${famePenalty} fame`);
      }
    }
    
    if (totalNewStreams > 0 || famePenalty > 0 || sideHustleExpired) {
      
      // 🎯 CALCULATE FANBASE GROWTH from streams
      let fanbaseGrowth = 0;
      let fameGrowth = 0;
      let loyalFanGrowth = 0;
      
      if (totalNewStreams > 0) {
        const currentFanbase = playerData.fanbase || 0;
        const currentFame = playerData.fame || 0;
        const currentLoyalFans = playerData.loyalFanbase || 0;
        
        // Every 1,000 streams converts 1 casual listener to a fan
        // Apply diminishing returns for established artists
        const baseFanGrowth = Math.floor(totalNewStreams / 1000);
        const diminishingFactor = 1.0 / (1.0 + currentFanbase / 10000);
        fanbaseGrowth = Math.round(baseFanGrowth * diminishingFactor);
        fanbaseGrowth = Math.max(0, Math.min(50, fanbaseGrowth)); // Cap at 50 per day
        
        // Every 10,000 streams increases fame by 1 point
        // Also has diminishing returns for mega-celebrities
        const baseFameGrowth = Math.floor(totalNewStreams / 10000);
        const fameDiminishing = 1.0 / (1.0 + currentFame / 500);
        fameGrowth = Math.round(baseFameGrowth * fameDiminishing);
        fameGrowth = Math.max(0, Math.min(10, fameGrowth)); // Cap at 10 per day
        
        // Convert casual fans to loyal fans based on consistent streaming
        // Every 5,000 streams converts 1 casual fan to loyal
        const casualFans = Math.max(0, currentFanbase - currentLoyalFans);
        if (casualFans > 0) {
          const baseLoyalGrowth = Math.floor(totalNewStreams / 5000);
          const loyalDiminishing = 1.0 / (1.0 + currentLoyalFans / 5000);
          const maxConvertible = Math.round(casualFans * 0.05); // Max 5% of casual fans per day
          loyalFanGrowth = Math.round(baseLoyalGrowth * loyalDiminishing);
          loyalFanGrowth = Math.max(0, Math.min(maxConvertible, loyalFanGrowth));
        }
      }
      
      const updates = {
        songs: updatedSongs,
        currentMoney: (playerData.currentMoney || 0) + totalNewIncome,
        regionalFanbase: updatedRegionalFanbase, // ✅ UPDATE REGIONAL FANBASE
        lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
      };
      
      // Apply fanbase growth
      if (fanbaseGrowth > 0) {
        updates.fanbase = (playerData.fanbase || 0) + fanbaseGrowth;
        console.log(`📈 ${playerData.displayName || playerId}: +${fanbaseGrowth} fans (total: ${updates.fanbase})`);
      }
      
      // Apply loyal fanbase growth
      if (loyalFanGrowth > 0) {
        updates.loyalFanbase = (playerData.loyalFanbase || 0) + loyalFanGrowth;
        console.log(`💎 ${playerData.displayName || playerId}: +${loyalFanGrowth} loyal fans (total: ${updates.loyalFanbase})`);
      }
      
      // Apply fame growth and decay
      const currentFame = playerData.fame || 0;
      const netFameChange = fameGrowth - famePenalty;
      if (netFameChange !== 0) {
        updates.fame = Math.max(0, Math.min(999, currentFame + netFameChange));
        if (fameGrowth > 0) {
          console.log(`⭐ ${playerData.displayName || playerId}: +${fameGrowth} fame`);
        }
        if (famePenalty > 0) {
          console.log(`⚠️ ${playerData.displayName || playerId}: -${famePenalty} fame (inactivity)`);
        }
      }
      
      // ✅ ENERGY RESTORATION - Restore energy to 100 if below 100, then deduct side hustle cost
      const currentEnergy = playerData.energy || 100;
      const restoredEnergy = currentEnergy < 100 ? 100 : currentEnergy;
      const finalEnergy = Math.max(0, restoredEnergy - sideHustleEnergyCost);
      
      updates.energy = finalEnergy;
      console.log(`🔋 ${playerData.displayName || playerId}: Energy ${currentEnergy} → ${restoredEnergy} → ${finalEnergy}`);
      
      // Apply side hustle payment
      if (sideHustlePay > 0) {
        updates.currentMoney = (updates.currentMoney || 0) + sideHustlePay;
        console.log(`💰 ${playerData.displayName || playerId}: Side hustle pay +$${sideHustlePay}`);
      }
      
      // ✅ Terminate side hustle contract if expired
      if (sideHustleExpired) {
        updates.activeSideHustle = null;
        console.log(`✅ Terminated expired side hustle for ${playerData.displayName || playerId}`);
      }
      
      // REMOVE OLD FIELD if it exists
      if (playerData.currentSideHustle) {
        updates.currentSideHustle = null;
        updates.sideHustlePaymentPerDay = null;
      }
      
      // ✅ CREATE NOTIFICATION for daily royalties (only if earning money)
      if (totalNewIncome > 0) {
        try {
          await db.collection('players').doc(playerId).collection('notifications').add({
            type: 'royalty_payment',
            title: '💰 Daily Royalties',
            message: `You earned $${totalNewIncome.toLocaleString()} from ${totalNewStreams.toLocaleString()} streams!`,
            amount: totalNewIncome,
            streams: totalNewStreams,
            read: false,
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
          });
          console.log(`📬 Created royalty notification for ${playerData.displayName || playerId}: $${totalNewIncome}`);
        } catch (notifError) {
          console.error(`Failed to create notification for ${playerId}:`, notifError);
        }
      }

      // 🏅 Process any certification awards (songs only; albums via submit flow)
      if (certAwards.length > 0 && certConfig && certConfig.enabled) {
        try {
          const rewards = certConfig.rewards || {};
          let extraMoney = 0;
          let extraFame = 0;
          const notificationsRef = db.collection('players').doc(playerId).collection('notifications');
          const certsRef = db.collection('players').doc(playerId).collection('certifications');

          for (const award of certAwards) {
            extraMoney += Number(rewards.songMoney || 0);
            extraFame += Number(rewards.songFame || 0);
            await certsRef.add({
              itemType: award.itemType,
              itemId: String(award.itemId || ''),
              title: award.title,
              tier: award.tier,
              level: award.level,
              units: award.units,
              createdAt: admin.firestore.Timestamp.now(),
            });
            await notificationsRef.add({
              type: 'certification_awarded',
              title: '🏅 Certification Awarded',
              message: `${award.title} is now ${award.tier.replace('_', ' ')}${award.level > 1 ? ' x' + award.level : ''}!`,
              itemType: award.itemType,
              itemId: String(award.itemId || ''),
              tier: award.tier,
              level: award.level,
              units: award.units,
              read: false,
              timestamp: admin.firestore.FieldValue.serverTimestamp(),
            });
          }

          if (extraMoney > 0) {
            updates.currentMoney = (updates.currentMoney || 0) + extraMoney;
          }
          if (extraFame > 0) {
            updates.fame = Math.max(0, (updates.fame || playerData.fame || 0) + extraFame);
          }
          console.log(`🏅 Awarded ${certAwards.length} song certification(s) to ${playerData.displayName || playerId}`);
        } catch (certErr) {
          console.error('Failed to write certification awards', certErr);
        }
      }
      
      return updates;
    }
    
    return null;
  } catch (error) {
    console.error(`Error processing player ${playerId}:`, error);
    return null;
  }
}

function calculateDailyStreamGrowth(song, playerData, currentGameDate) {
  const releaseDate = toDateSafe(song.releasedDate);
  if (!releaseDate) return 0;
  const daysSinceRelease = Math.floor((currentGameDate - releaseDate) / (1000 * 60 * 60 * 24));
  
  const loyalFanbase = playerData.loyalFanbase || 0;
  const totalFanbase = playerData.fanbase || 1; // FIX: Use fanbase instead of level
  // Compute effective quality: average written and recording quality if available
  let songQuality = song.quality || 50;
  if (Number.isFinite(song.recordingQuality)) {
    const rq = Number(song.recordingQuality);
    if (Number.isFinite(rq)) {
      songQuality = Math.round(((Number(song.quality) || 50) + rq) / 2);
    }
  }
  const viralityScore = song.viralityScore || 0.5;
  const ageCategory = getAgeCategory(daysSinceRelease);
  
  // ✨ FAME BONUS: Higher fame = more streams from algorithm boost
  const fame = playerData.fame || 0;
  const fameStreamBonus = calculateFameStreamBonus(fame);
  
  // 🎯 QUALITY MULTIPLIER (RC/env tunable; default 0.01 per point from 50)
  const qCoefEnv = Number(process.env.qCoef);
  const qCoef = Number.isFinite(qCoefEnv) ? Math.max(0, Math.min(0.05, qCoefEnv)) : 0.01;
  const qualityMult = Math.max(0.5, Math.min(1.5, 1 + ((songQuality - 50) * qCoef)));
  
  // Age-based discovery modifier
  const discoveryModifier = getDiscoveryModifier(ageCategory, daysSinceRelease);
  
  // Loyal fan streams
  const loyalStreams = Math.round(loyalFanbase * (0.5 + Math.random() * 1.5));
  
  // Discovery streams (with age decay)
  let discoveryStreams = 0;
  if (daysSinceRelease === 0) {
    discoveryStreams = Math.round(totalFanbase * 0.3 * (songQuality / 100) * (1.5 + Math.random()) * qualityMult);
  } else if (daysSinceRelease <= 7) {
    discoveryStreams = Math.round(totalFanbase * 0.2 * viralityScore * (1.0 - daysSinceRelease / 7.0 * 0.4) * qualityMult);
  } else if (daysSinceRelease <= 30) {
    discoveryStreams = Math.round(totalFanbase * 0.1 * viralityScore * (1.0 - (daysSinceRelease - 7) / 23.0 * 0.5) * qualityMult);
  } else {
    discoveryStreams = Math.round(totalFanbase * 0.05 * viralityScore * discoveryModifier * qualityMult);
  }
  
  // Viral streams
  let viralStreams = 0;
  const viralChance = Math.max(0.005, Math.min(0.3, (viralityScore * 0.1) * (1 + ((songQuality - 50) * qCoef * 0.5))));
  if (Math.random() < viralChance) {
    viralStreams = Math.round((song.streams || 0) * 0.05 * (2.0 + Math.random() * 5.0));
  }
  
  // Casual fan streams
  const casualFans = Math.max(0, totalFanbase - loyalFanbase);
  const engagementRate = (songQuality / 100.0) * 0.2;
  const casualStreams = Math.round(casualFans * engagementRate * (0.1 + Math.random() * 0.7) * qualityMult);
  
  // Platform multipliers
  const platforms = song.streamingPlatforms || [];
  let platformMultiplier = 0;
  if (platforms.includes('tunify')) platformMultiplier += 0.85;
  if (platforms.includes('maple_music')) platformMultiplier += 0.65;
  if (platformMultiplier === 0) platformMultiplier = 0.5;
  
  const totalStreams = loyalStreams + discoveryStreams + viralStreams + casualStreams;
  
  // ✨ Apply fame bonus to total streams (famous artists get more algorithm promotion)
  const finalStreams = Math.round(totalStreams * platformMultiplier * fameStreamBonus * (0.8 + Math.random() * 0.4));
  
  return Math.max(0, finalStreams);
}

function calculateSongIncome(song, streams) {
  const platforms = song.streamingPlatforms || [];
  let income = 0;
  
  if (platforms.includes('tunify')) {
    income += Math.round(streams * 0.85 * 0.003);
  }
  if (platforms.includes('maple_music')) {
    income += Math.round(streams * 0.65 * 0.01);
  }
  
  return income;
}

function distributeStreamsRegionally(totalStreams, currentRegion, regionalFanbase, genre) {
  const regions = ['usa', 'europe', 'uk', 'asia', 'africa', 'latin_america', 'oceania'];
  const distribution = {};
  
  // Calculate total fanbase
  const totalRegionalFans = Object.values(regionalFanbase).reduce((sum, fans) => sum + fans, 0);
  
  if (totalRegionalFans === 0) {
    // No fanbase yet - 70% current region, 30% distributed
    distribution[currentRegion] = Math.round(totalStreams * 0.7);
    const remaining = totalStreams - distribution[currentRegion];
    const perOtherRegion = Math.floor(remaining / (regions.length - 1));
    
    regions.forEach(region => {
      if (region !== currentRegion) {
        distribution[region] = perOtherRegion;
      }
    });
  } else {
    // Distribute based on fanbase (70%) and genre preferences (30%)
    regions.forEach(region => {
      const fanbaseWeight = (regionalFanbase[region] || 0) / totalRegionalFans;
      const genreBonus = getGenreRegionalBonus(genre, region);
      const regionShare = fanbaseWeight * 0.7 + genreBonus * 0.3;
      distribution[region] = Math.round(totalStreams * regionShare);
    });
  }
  
  return distribution;
}

// ✅ NEW: Regional fanbase growth based on streams
function calculateRegionalFanbaseGrowth(currentFanbase, songs, homeRegion, playerFame = 0) {
  const updatedFanbase = { ...currentFanbase };
  
  // ✨ FAME BONUS: Higher fame = better stream-to-fan conversion
  const fameFanConversionBonus = calculateFameFanConversionBonus(playerFame);
  
  // Calculate streams per region from all songs
  const regionalStreams = {};
  songs.forEach(song => {
    if (song.state === 'released' && song.regionalStreams) {
      Object.entries(song.regionalStreams).forEach(([region, streams]) => {
        regionalStreams[region] = (regionalStreams[region] || 0) + streams;
      });
    }
  });
  
  // Convert streams to fanbase growth (with diminishing returns)
  Object.entries(regionalStreams).forEach(([region, streams]) => {
    const currentFans = updatedFanbase[region] || 0;
    
    // Growth rate: 1 fan per 1000 streams, with diminishing returns
    const baseGrowth = Math.floor(streams / 1000);
    const diminishingFactor = 1.0 / (1.0 + currentFans / 10000);
    
    // ✨ Apply fame bonus to conversion rate
    const growth = Math.round(baseGrowth * diminishingFactor * fameFanConversionBonus);
    
    // Home region gets 2x growth
    const finalGrowth = region === homeRegion ? growth * 2 : growth;
    
    updatedFanbase[region] = currentFans + finalGrowth;
  });
  
  return updatedFanbase;
}

module.exports.calculateRegionalFanbaseGrowth = calculateRegionalFanbaseGrowth;

// ✅ NEW: Song age categories for lifecycle management
function getAgeCategory(daysOld) {
  if (daysOld <= 7) return 'new';
  if (daysOld <= 30) return 'peak';
  if (daysOld <= 90) return 'declining';
  return 'catalog';
}

function getDiscoveryModifier(ageCategory, daysOld) {
  switch (ageCategory) {
    case 'new': return 1.0;
    case 'peak': return 0.8;
    case 'declining': return 0.5;
    case 'catalog': return 0.2;
    default: return 0.5;
  }
}

function getGenreRegionalBonus(genre, region) {
  const preferences = {
    'pop': { 'usa': 0.25, 'europe': 0.20, 'uk': 0.15, 'asia': 0.15, 'africa': 0.10, 'latin_america': 0.10, 'oceania': 0.05 },
    'hip_hop': { 'usa': 0.35, 'europe': 0.15, 'uk': 0.15, 'asia': 0.10, 'africa': 0.15, 'latin_america': 0.05, 'oceania': 0.05 },
    'rock': { 'usa': 0.25, 'europe': 0.25, 'uk': 0.20, 'asia': 0.10, 'africa': 0.05, 'latin_america': 0.10, 'oceania': 0.05 },
    'electronic': { 'usa': 0.20, 'europe': 0.30, 'uk': 0.20, 'asia': 0.15, 'africa': 0.05, 'latin_america': 0.05, 'oceania': 0.05 },
    'country': { 'usa': 0.50, 'europe': 0.10, 'uk': 0.10, 'asia': 0.05, 'africa': 0.05, 'latin_america': 0.10, 'oceania': 0.10 },
    'jazz': { 'usa': 0.30, 'europe': 0.25, 'uk': 0.15, 'asia': 0.10, 'africa': 0.10, 'latin_america': 0.05, 'oceania': 0.05 },
    'classical': { 'usa': 0.20, 'europe': 0.35, 'uk': 0.20, 'asia': 0.15, 'africa': 0.05, 'latin_america': 0.03, 'oceania': 0.02 },
    'reggae': { 'usa': 0.15, 'europe': 0.15, 'uk': 0.20, 'asia': 0.10, 'africa': 0.25, 'latin_america': 0.10, 'oceania': 0.05 },
    'latin': { 'usa': 0.20, 'europe': 0.15, 'uk': 0.10, 'asia': 0.10, 'africa': 0.10, 'latin_america': 0.30, 'oceania': 0.05 },
    'indie': { 'usa': 0.25, 'europe': 0.25, 'uk': 0.20, 'asia': 0.15, 'africa': 0.05, 'latin_america': 0.05, 'oceania': 0.05 },
  };
  
  return preferences[genre]?.[region] || 0.14; // Equal distribution fallback
}

// ============================================================================
// FAME BONUS CALCULATIONS - Match Dart model logic
// ============================================================================

/**
 * Calculate stream growth multiplier based on fame
 * Higher fame = more algorithmic promotion and discovery
 * @param {number} fame - Player's current fame level
 * @returns {number} Multiplier (1.0 = no bonus, 2.0 = double streams)
 */
function calculateFameStreamBonus(fame) {
  if (fame < 10) return 1.0;          // No bonus
  if (fame < 25) return 1.05;         // +5%
  if (fame < 50) return 1.10;         // +10%
  if (fame < 75) return 1.15;         // +15%
  if (fame < 100) return 1.20;        // +20%
  if (fame < 150) return 1.30;        // +30%
  if (fame < 200) return 1.40;        // +40%
  if (fame < 300) return 1.50;        // +50%
  if (fame < 400) return 1.65;        // +65%
  if (fame < 500) return 1.80;        // +80%
  return 2.0;                         // +100% (double streams!)
}

/**
 * Calculate fan conversion rate multiplier based on fame
 * Higher fame = more listeners convert to fans
 * @param {number} fame - Player's current fame level
 * @returns {number} Multiplier (1.0 = base 15% rate, 2.5 = 37.5% rate)
 */
function calculateFameFanConversionBonus(fame) {
  if (fame < 10) return 1.0;          // 15% base rate
  if (fame < 25) return 1.1;          // +10% conversion
  if (fame < 50) return 1.2;          // +20%
  if (fame < 100) return 1.35;        // +35%
  if (fame < 150) return 1.5;         // +50%
  if (fame < 200) return 1.7;         // +70%
  if (fame < 300) return 1.9;         // +90%
  if (fame < 400) return 2.1;         // +110%
  if (fame < 500) return 2.3;         // +130%
  return 2.5;                         // +150%
}

/**
 * Calculate concert ticket price multiplier based on fame
 * Higher fame = charge more per ticket
 * @param {number} fame - Player's current fame level
 * @returns {number} Multiplier (1.0 = $10 base, 8.0 = $80)
 */
function calculateFameTicketPriceMultiplier(fame) {
  if (fame < 10) return 1.0;          // $10 base
  if (fame < 25) return 1.2;          // $12
  if (fame < 50) return 1.5;          // $15
  if (fame < 75) return 1.8;          // $18
  if (fame < 100) return 2.0;         // $20
  if (fame < 150) return 2.5;         // $25
  if (fame < 200) return 3.0;         // $30
  if (fame < 300) return 4.0;         // $40
  if (fame < 400) return 5.0;         // $50
  if (fame < 500) return 6.0;         // $60
  return 8.0;                         // $80
}

// ============================================================================
// EVENT BONUSES
// ============================================================================

async function getActiveEvent() {
  try {
    const eventDoc = await db.collection('game_state').doc('active_event').get();
    if (!eventDoc.exists) return null;
    
    const event = eventDoc.data();
    const now = new Date();
    const endDate = toDateSafe(event.endDate);
    
    if (now > endDate) {
      // Event expired
      await db.collection('game_state').doc('active_event').update({ active: false });
      return null;
    }
    
    return event;
  } catch (error) {
    return null;
  }
}

function applyEventBonuses(baseStreams, song, playerData, event) {
  if (!event || !event.active) return baseStreams;
  
  let multiplier = 1.0;
  
  switch (event.id) {
    case 'viral_week':
      // All songs get higher viral chance (already applied in calculation)
      multiplier = 1.2;
      break;
    case 'album_week':
      if (song.isAlbum) multiplier = event.effect.albumBonus;
      break;
    case 'regional_focus':
      // Check if player is in target region
      if (playerData.homeRegion === event.effect.targetRegion) {
        multiplier = event.effect.regionalBonus;
      }
      break;
    case 'new_artist_boost':
      // Boost for artists with small fanbase (under 10k fans)
      if ((playerData.fanbase || 0) < 10000) {
        multiplier = event.effect.newArtistBonus;
      }
      break;
    case 'chart_fever':
      // Bonus applied separately in chart updates
      break;
  }
  
  return Math.round(baseStreams * multiplier);
}

// ============================================================================
// WEEKLY LEADERBOARD FUNCTIONS
// ============================================================================

async function createSongLeaderboardSnapshot(weekId, timestamp) {
  try {
    // Get PREVIOUS week's snapshot to calculate movement and weeks on chart
    const previousWeekId = getPreviousWeekId(weekId);
    const previousSnapshots = {};
    
    try {
      const prevGlobalDoc = await db.collection('leaderboard_history')
        .doc(`songs_global_${previousWeekId}`)
        .get();
      
      if (prevGlobalDoc.exists) {
        const prevData = prevGlobalDoc.data();
        prevData.rankings.forEach(entry => {
          previousSnapshots[`global_${entry.songId}`] = {
            position: entry.position,
            weeksOnChart: entry.weeksOnChart || 0,
            consecutiveWeeks: entry.consecutiveWeeks || 0,
          };
        });
      }
      
      // Get previous regional snapshots
      const regions = ['usa', 'europe', 'uk', 'asia', 'africa', 'latin_america', 'oceania'];
      for (const region of regions) {
        const prevRegionalDoc = await db.collection('leaderboard_history')
          .doc(`songs_${region}_${previousWeekId}`)
          .get();
        
        if (prevRegionalDoc.exists) {
          const prevData = prevRegionalDoc.data();
          prevData.rankings.forEach(entry => {
            previousSnapshots[`${region}_${entry.songId}`] = {
              position: entry.position,
              weeksOnChart: entry.weeksOnChart || 0,
              consecutiveWeeks: entry.consecutiveWeeks || 0,
            };
          });
        }
      }
    } catch (error) {
      console.log(`⚠️ No previous week data found for ${previousWeekId} - all entries will be "New Entry"`);
    }
    
    // Get top 100 songs by last7DaysStreams from BOTH players and NPCs
    const playersSnapshot = await db.collection('players').get();
    const allSongs = [];
    
    // Add player songs
    playersSnapshot.forEach(playerDoc => {
  const playerData = playerDoc.data();
  const migrated = !!playerData.migratedToSubcollections;
      const songs = playerData.songs || [];
      
      songs.forEach(song => {
        if (song.state === 'released') {
          allSongs.push({
            ...song,
            artistId: playerDoc.id,
            artistName: playerData.displayName || 'Unknown',
            last7DaysStreams: song.last7DaysStreams || 0,
            regionalStreams: song.regionalStreams || {},
            isNPC: false,
          });
        }
      });
    });

    // ALSO add NPC songs to charts
    const npcsSnapshot = await db.collection('npcs').get();
    
    npcsSnapshot.forEach(npcDoc => {
      const npcData = npcDoc.data();
      const songs = npcData.songs || [];
      
      songs.forEach(song => {
        if (song.state === 'released') {
          allSongs.push({
            ...song,
            artistId: npcDoc.id,
            artistName: npcData.name || 'Unknown NPC',
            last7DaysStreams: song.last7DaysStreams || 0,
            regionalStreams: song.regionalStreams || {},
            isNPC: true,
          });
        }
      });
    });
    
    // === GLOBAL CHART (by total last7DaysStreams) ===
    const globalSongs = [...allSongs];
    globalSongs.sort((a, b) => b.last7DaysStreams - a.last7DaysStreams);
    const globalTop100 = globalSongs.slice(0, 100);
    
    // Calculate movement, entry type, and weeks on chart
    const globalRankings = globalTop100.map((song, index) => {
      const position = index + 1;
      const songId = song.id || '';
      const prevKey = `global_${songId}`;
      const prevData = previousSnapshots[prevKey];
      
      let movement = 0;
      let lastWeekPosition = null;
      let weeksOnChart = 1;
      let consecutiveWeeks = 1;
      let entryType = 'new'; // 'new', 're-entry', or null
      
      if (prevData) {
        // Song was on chart last week
        lastWeekPosition = prevData.position;
        movement = lastWeekPosition - position; // Positive = moved up
        weeksOnChart = prevData.weeksOnChart + 1;
        consecutiveWeeks = prevData.consecutiveWeeks + 1;
        entryType = null; // Not a new or re-entry
      } else {
        // Song not on last week's chart - check if it's ever been on chart before
        // (This would require historical tracking, for now treat as 'new')
        // TODO: Add lifetime chart history tracking to distinguish 'new' from 're-entry'
        entryType = 'new'; // Assume new for now
      }
      
      return {
        position,
        rank: position,
        songId,
        title: song.title,
        artistId: song.artistId,
        artist: song.artistName,
        artistName: song.artistName,
        streams: song.last7DaysStreams,
        totalStreams: song.streams,
        genre: song.genre,
        coverArtUrl: song.coverArtUrl || null,
        isNPC: song.isNPC || false,
        // NEW: Trending data
        movement,
        lastWeekPosition,
        weeksOnChart,
        consecutiveWeeks,
        entryType,
      };
    });
    
    // Create global snapshot document
    await db.collection('leaderboard_history').doc(`songs_global_${weekId}`).set({
      weekId,
      timestamp: admin.firestore.Timestamp.fromDate(timestamp),
      type: 'songs',
      region: 'global',
      rankings: globalRankings,
    });
    
    console.log(`✅ Created GLOBAL song leaderboard snapshot for week ${weekId}`);
    
    // === REGIONAL CHARTS (by region-specific streams) ===
    const regions = ['usa', 'europe', 'uk', 'asia', 'africa', 'latin_america', 'oceania'];
    
    for (const region of regions) {
      const regionalSongs = allSongs.map(song => ({
        ...song,
        regionStreams: song.regionalStreams?.[region] || 0,
      }));
      
      // Sort by region-specific streams
      regionalSongs.sort((a, b) => b.regionStreams - a.regionStreams);
      const regionalTop100 = regionalSongs.slice(0, 100);
      
      // Calculate movement and weeks on chart for regional rankings
      const regionalRankings = regionalTop100.map((song, index) => {
        const position = index + 1;
        const songId = song.id || '';
        const prevKey = `${region}_${songId}`;
        const prevData = previousSnapshots[prevKey];
        
        let movement = 0;
        let lastWeekPosition = null;
        let weeksOnChart = 1;
        let consecutiveWeeks = 1;
        let entryType = 'new';
        
        if (prevData) {
          lastWeekPosition = prevData.position;
          movement = lastWeekPosition - position;
          weeksOnChart = prevData.weeksOnChart + 1;
          consecutiveWeeks = prevData.consecutiveWeeks + 1;
          entryType = null;
        }
        
        return {
          position,
          rank: position,
          songId,
          title: song.title,
          artistId: song.artistId,
          artist: song.artistName,
          artistName: song.artistName,
          streams: song.regionStreams,
          totalStreams: song.streams,
          genre: song.genre,
          coverArtUrl: song.coverArtUrl || null,
          isNPC: song.isNPC || false,
          // NEW: Trending data
          movement,
          lastWeekPosition,
          weeksOnChart,
          consecutiveWeeks,
          entryType,
        };
      });
      
      // Create regional snapshot
      await db.collection('leaderboard_history').doc(`songs_${region}_${weekId}`).set({
        weekId,
        timestamp: admin.firestore.Timestamp.fromDate(timestamp),
        type: 'songs',
        region,
        rankings: regionalRankings,
      });
      
      console.log(`✅ Created ${region.toUpperCase()} song leaderboard snapshot for week ${weekId}`);
    }
    
  } catch (error) {
    console.error('❌ Error creating song snapshot:', error);
  }
}

async function createArtistLeaderboardSnapshot(weekId, timestamp) {
  try {
    // Get all players and calculate total last7DaysStreams
    const playersSnapshot = await db.collection('players').get();
    const allArtists = [];
    
    // Add player artists
    playersSnapshot.forEach(playerDoc => {
      const playerData = playerDoc.data();
      const songs = playerData.songs || [];
      const releasedSongs = songs.filter(s => s.state === 'released');
      
      const totalWeeklyStreams = releasedSongs.reduce((sum, s) => sum + (s.last7DaysStreams || 0), 0);
      
      // Calculate regional streams for this artist
      const regionalStreams = {};
      const regions = ['usa', 'europe', 'uk', 'asia', 'africa', 'latin_america', 'oceania'];
      regions.forEach(region => {
        regionalStreams[region] = releasedSongs.reduce((sum, s) => sum + (s.regionalStreams?.[region] || 0), 0);
      });
      
      // Use displayName (which is what frontend uses)
      const artistName = playerData.displayName && playerData.displayName.trim() !== '' ? playerData.displayName : 'Unknown';
      
      if (totalWeeklyStreams > 0 && releasedSongs.length > 0) {
        allArtists.push({
          artistId: playerDoc.id,
          artistName: artistName,
          songCount: releasedSongs.length,
          weeklyStreams: totalWeeklyStreams,
          regionalStreams,
          totalStreams: playerData.totalStreams || 0,
          fanbase: playerData.fanbase || 0,
          isNPC: false,
        });
      }
    });

    // ALSO add NPC artists to leaderboard
    const npcsSnapshot = await db.collection('npcs').get();
    
    npcsSnapshot.forEach(npcDoc => {
      const npcData = npcDoc.data();
      const songs = npcData.songs || [];
      const releasedSongs = songs.filter(s => s.state === 'released');
      
      const totalWeeklyStreams = releasedSongs.reduce((sum, s) => sum + (s.last7DaysStreams || 0), 0);
      
      // Calculate regional streams for this NPC artist
      const regionalStreams = {};
      const regions = ['usa', 'europe', 'uk', 'asia', 'africa', 'latin_america', 'oceania'];
      regions.forEach(region => {
        regionalStreams[region] = releasedSongs.reduce((sum, s) => sum + (s.regionalStreams?.[region] || 0), 0);
      });
      
      // Use correct fanbase field and ensure name is set
      const artistName = npcData.name && npcData.name.trim() !== '' ? npcData.name : 'Unknown NPC';
      
      if (totalWeeklyStreams > 0 && releasedSongs.length > 0) {
        allArtists.push({
          artistId: npcDoc.id,
          artistName: artistName,
          songCount: releasedSongs.length,
          weeklyStreams: totalWeeklyStreams,
          regionalStreams,
          totalStreams: npcData.totalStreams || 0,
          fanbase: npcData.fanbase || 0,
          isNPC: true,
        });
      }
    });
    
    // === GLOBAL CHART (by total weekly streams) ===
    const globalArtists = [...allArtists];
    globalArtists.sort((a, b) => b.weeklyStreams - a.weeklyStreams);
    const globalTop50 = globalArtists.slice(0, 50);
    
    // Create global snapshot
    await db.collection('leaderboard_history').doc(`artists_global_${weekId}`).set({
      weekId,
      timestamp: admin.firestore.Timestamp.fromDate(timestamp),
      type: 'artists',
      region: 'global',
      rankings: globalTop50.map((artist, index) => ({
        position: index + 1,
        rank: index + 1,
        artistId: artist.artistId,
        artistName: artist.artistName,
        songCount: artist.songCount,
        streams: artist.weeklyStreams,
        weeklyStreams: artist.weeklyStreams,
        totalStreams: artist.totalStreams,
        fanbase: artist.fanbase,
        isNPC: artist.isNPC || false,
      })),
    });
    
    console.log(`✅ Created GLOBAL artist leaderboard snapshot for week ${weekId}`);
    
    // === REGIONAL CHARTS (by region-specific streams) ===
    const regions = ['usa', 'europe', 'uk', 'asia', 'africa', 'latin_america', 'oceania'];
    
    for (const region of regions) {
      const regionalArtists = allArtists.map(artist => ({
        ...artist,
        regionWeeklyStreams: artist.regionalStreams?.[region] || 0,
      }));
      
      // Sort by region-specific weekly streams
      regionalArtists.sort((a, b) => b.regionWeeklyStreams - a.regionWeeklyStreams);
      const regionalTop50 = regionalArtists.slice(0, 50);
      
      // Create regional snapshot
      await db.collection('leaderboard_history').doc(`artists_${region}_${weekId}`).set({
        weekId,
        timestamp: admin.firestore.Timestamp.fromDate(timestamp),
        type: 'artists',
        region,
        rankings: regionalTop50.map((artist, index) => ({
          position: index + 1,
          rank: index + 1,
          artistId: artist.artistId,
          artistName: artist.artistName,
          songCount: artist.songCount,
          streams: artist.regionWeeklyStreams, // Region-specific streams
          weeklyStreams: artist.regionWeeklyStreams, // Region-specific streams
          totalStreams: artist.totalStreams, // Global total
          fanbase: artist.fanbase,
          isNPC: artist.isNPC || false,
        })),
      });
      
      console.log(`✅ Created ${region.toUpperCase()} artist leaderboard snapshot for week ${weekId}`);
    }
    
  } catch (error) {
    console.error('❌ Error creating artist snapshot:', error);
  }
}

async function updateChartStatistics(weekId) {
  try {
    // Update statistics for GLOBAL and ALL REGIONAL charts
    const chartTypes = [
      'global',
      'usa',
      'europe',
      'uk',
      'asia',
      'africa',
      'latin_america',
      'oceania'
    ];
    
    for (const chartType of chartTypes) {
      // Get this week's and last week's snapshots
      const thisWeekSongs = await db.collection('leaderboard_history').doc(`songs_${chartType}_${weekId}`).get();
      const lastWeekSongs = await db.collection('leaderboard_history').doc(`songs_${chartType}_${weekId - 1}`).get();
      
      if (!thisWeekSongs.exists) continue;
      
      const thisWeekData = thisWeekSongs.data().rankings;
      const lastWeekData = lastWeekSongs.exists ? lastWeekSongs.data().rankings : [];
      
      // Calculate statistics for each song
      const statistics = thisWeekData.map(song => {
        const lastWeekRank = lastWeekData.findIndex(s => 
          s.title === song.title && s.artistId === song.artistId
        ) + 1;
        
        return {
          ...song,
          lastWeekRank: lastWeekRank || null,
          movement: lastWeekRank ? lastWeekRank - song.rank : null,
          isNew: !lastWeekRank,
        };
      });
      
      // Update snapshot with statistics
      await db.collection('leaderboard_history').doc(`songs_${chartType}_${weekId}`).update({
        rankingsWithStats: statistics,
        statsCalculated: true,
      });
      
      console.log(`✅ Updated ${chartType.toUpperCase()} chart statistics for week ${weekId}`);
    }
    
  } catch (error) {
    console.error('❌ Error updating chart statistics:', error);
  }
}

function getWeekId(date) {
  const startOfYear = new Date(date.getFullYear(), 0, 1);
  const days = Math.floor((date - startOfYear) / (24 * 60 * 60 * 1000));
  return date.getFullYear() * 100 + Math.ceil(days / 7);
}

function getPreviousWeekId(weekId) {
  const year = Math.floor(weekId / 100);
  const week = weekId % 100;
  
  if (week > 1) {
    // Same year, previous week
    return year * 100 + (week - 1);
  } else {
    // Previous year, last week (approximately week 52)
    return (year - 1) * 100 + 52;
  }
}

// ============================================================================
// ACHIEVEMENT CHECKING FUNCTIONS
// ============================================================================

function checkStreamMilestones(before, after, playerId) {
  const achievements = [];
  const milestones = [1000, 10000, 100000, 1000000, 10000000];
  
  const beforeSongs = before.songs || [];
  const afterSongs = after.songs || [];
  
  afterSongs.forEach((song, index) => {
    const beforeSong = beforeSongs[index];
    if (!beforeSong) return;
    
    milestones.forEach(milestone => {
      if (beforeSong.streams < milestone && song.streams >= milestone) {
        achievements.push({
          id: `streams_${milestone}_${song.title}`,
          type: 'stream_milestone',
          title: `${milestone.toLocaleString()} Streams`,
          description: `"${song.title}" reached ${milestone.toLocaleString()} streams!`,
          icon: '🎵',
          rarity: getRarity(milestone),
          unlockedAt: new Date(),
        });
      }
    });
  });
  
  return achievements;
}

function checkMoneyMilestones(before, after, playerId) {
  const achievements = [];
  const milestones = [1000, 10000, 50000, 100000, 500000, 1000000];
  
  const beforeMoney = before.currentMoney || 0;
  const afterMoney = after.currentMoney || 0;
  
  milestones.forEach(milestone => {
    if (beforeMoney < milestone && afterMoney >= milestone) {
      achievements.push({
        id: `money_${milestone}`,
        type: 'money_milestone',
        title: `$${milestone.toLocaleString()} Earned`,
        description: `Total career earnings reached $${milestone.toLocaleString()}!`,
        icon: '💰',
        rarity: getRarity(milestone / 1000),
        unlockedAt: new Date(),
      });
    }
  });
  
  return achievements;
}

function checkChartMilestones(before, after, playerId) {
  const achievements = [];
  
  const afterSongs = after.songs || [];
  
  // Check for first #1 hit
  const hasNumberOne = afterSongs.some(song => song.chartPosition === 1);
  const hadNumberOne = (before.songs || []).some(song => song.chartPosition === 1);
  
  if (hasNumberOne && !hadNumberOne) {
    achievements.push({
      id: 'first_number_one',
      type: 'chart_milestone',
      title: 'First #1 Hit!',
      description: 'You reached #1 on the charts!',
      icon: '🏆',
      rarity: 'legendary',
      unlockedAt: new Date(),
    });
  }
  
  return achievements;
}

function checkRegionalMilestones(before, after, playerId) {
  const achievements = [];
  const regions = ['usa', 'europe', 'uk', 'asia', 'africa', 'latin_america', 'oceania'];
  
  // Check if top 10 in all regions
  const afterSongs = after.songs || [];
  const topTenInAllRegions = regions.every(region => 
    afterSongs.some(song => {
      const regionalPosition = song.regionalChartPositions?.[region];
      return regionalPosition && regionalPosition <= 10;
    })
  );
  
  const wasTopTenInAllRegions = regions.every(region => 
    (before.songs || []).some(song => {
      const regionalPosition = song.regionalChartPositions?.[region];
      return regionalPosition && regionalPosition <= 10;
    })
  );
  
  if (topTenInAllRegions && !wasTopTenInAllRegions) {
    achievements.push({
      id: 'global_domination',
      type: 'regional_milestone',
      title: 'Global Domination',
      description: 'Top 10 in all regions simultaneously!',
      icon: '🌍',
      rarity: 'legendary',
      unlockedAt: new Date(),
    });
  }
  
  return achievements;
}

function checkCareerMilestones(before, after, playerId) {
  const achievements = [];
  
  const beforeSongCount = (before.songs || []).length;
  const afterSongCount = (after.songs || []).length;
  
  const songMilestones = [1, 5, 10, 25, 50, 100];
  songMilestones.forEach(milestone => {
    if (beforeSongCount < milestone && afterSongCount >= milestone) {
      achievements.push({
        id: `songs_released_${milestone}`,
        type: 'career_milestone',
        title: `${milestone} Songs Released`,
        description: `Released ${milestone} songs in your career!`,
        icon: '🎼',
        rarity: getRarity(milestone * 10),
        unlockedAt: new Date(),
      });
    }
  });
  
  return achievements;
}

async function awardAchievements(playerId, achievements) {
  try {
    const batch = db.batch();
    
    achievements.forEach(achievement => {
      const achievementRef = db.collection('players')
        .doc(playerId)
        .collection('achievements')
        .doc(achievement.id);
      
      batch.set(achievementRef, achievement);
    });
    
    await batch.commit();
    
    // TODO: Send push notification to player
    console.log(`🏆 Awarded ${achievements.length} achievements to ${playerId}`);
  } catch (error) {
    console.error('❌ Error awarding achievements:', error);
  }
}

function getRarity(value) {
  if (value >= 1000000) return 'legendary';
  if (value >= 100000) return 'epic';
  if (value >= 10000) return 'rare';
  if (value >= 1000) return 'uncommon';
  return 'common';
}

// ============================================================================
// ANTI-CHEAT VALIDATION FUNCTIONS - ENHANCED SECURITY
// ============================================================================

function validateQuality(song, playerData) {
  const maxQuality = Math.min(
    100,
    (playerData.songwritingSkill || 0) * 0.4 +
    (playerData.lyricsSkill || 0) * 0.3 +
    (playerData.compositionSkill || 0) * 0.3
  );
  
  return song.quality <= maxQuality + 10; // Allow 10% margin
}

// Enhanced validation functions for anti-cheat
function validateMoneyChange(oldMoney, newMoney, action, context = {}) {
  const maxGains = {
    'song_creation': 500,      // Max $500 per song
    'side_hustle': 200,        // Max $200 per day
    'stream_income': 10000,    // Max $10K per day from streams
    'album_release': 50000,    // Max $50K per album
    'admin_gift': 1000000,     // Admin gifts can be large
    'admin_stat_update': 1000000,  // ✅ Admin manual stat adjustments can be large
    'stat_update': 10000,      // ✅ Regular stat updates (for profile saves, etc.)
  };
  
  const gain = newMoney - oldMoney;
  const maxGain = maxGains[action] || 1000; // Default max $1K
  
  if (gain < 0) return true; // Spending money is always valid
  if (gain > maxGain) {
    console.warn(`🚨 Suspicious money gain: ${gain} for action ${action}, max allowed: ${maxGain}`);
    return false;
  }
  return true;
}

function validateStatChange(oldValue, newValue, statName, maxGainPerAction = 10) {
  const gain = newValue - oldValue;
  if (gain < 0) return true; // Stats can decrease
  if (gain > maxGainPerAction) {
    console.warn(`🚨 Suspicious ${statName} gain: ${gain}, max allowed: ${maxGainPerAction}`);
    return false;
  }
  return true;
}

function validateEnergyConsumption(energyUsed, action) {
  const maxEnergyPerAction = {
    'song_creation': 50,
    'side_hustle': 30,
    'practice': 20,
    'viral_campaign': 40,
  };
  
  const maxEnergy = maxEnergyPerAction[action] || 25;
  return energyUsed <= maxEnergy;
}

// Helper: ensure a value is a finite number
function isFiniteNumber(value) {
  return typeof value === 'number' && Number.isFinite(value);
}

// Recursively validate nested objects/arrays to ensure no non-finite numbers
function validateNestedNumbers(obj, path = '') {
  if (obj === null || obj === undefined) return;
  if (Array.isArray(obj)) {
    for (let i = 0; i < obj.length; i++) {
      validateNestedNumbers(obj[i], `${path}[${i}]`);
    }
  } else if (typeof obj === 'object') {
    for (const [k, v] of Object.entries(obj)) {
      validateNestedNumbers(v, path ? `${path}.${k}` : k);
    }
  } else if (typeof obj === 'number') {
    if (!Number.isFinite(obj)) {
      throw new HttpsError('invalid-argument', `Invalid numeric value at ${path}: ${obj}`);
    }
  }
}

function detectSuspiciousActivity(playerData, changes) {
  const flags = [];
  
  // Check for impossible stat combinations
  if (playerData.currentMoney > 10000000) flags.push('excessive_money');
  if (playerData.currentFame > 1000) flags.push('excessive_fame');
  
  // Check for rapid progression
  const totalSkills = (playerData.songwritingSkill || 0) + 
                     (playerData.lyricsSkill || 0) + 
                     (playerData.compositionSkill || 0);
  if (totalSkills > 250) flags.push('suspicious_skill_total');
  
  // Check for negative values
  if (playerData.currentMoney < 0) flags.push('negative_money');
  if (playerData.energy < 0 || playerData.energy > 100) flags.push('invalid_energy');
  
  return flags;
}

async function logSuspiciousActivity(playerId, activity, flags, additionalData = {}) {
  await db.collection('security_logs').add({
    playerId,
    activity,
    flags,
    additionalData,
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
    severity: flags.length > 2 ? 'high' : 'medium',
  });
  
  console.warn(`🚨 Suspicious activity logged for player ${playerId}: ${flags.join(', ')}`);
}

// ============================================================================
// SECURE GAME ACTIONS - Server-side validation for all critical operations
// ============================================================================

exports.secureSongCreation = onCall(async (request) => {
  const data = request.data;
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'Must be authenticated');
  }
  
  const playerId = request.auth.uid;
  const { title, genre, effort } = data;
  // Validate 'effort' is a finite number
  if (typeof effort !== 'number' || !Number.isFinite(effort)) {
    throw new HttpsError('invalid-argument', 'Invalid effort value');
  }
  
  try {
    return await db.runTransaction(async (transaction) => {
      const playerRef = db.collection('players').doc(playerId);
      const playerDoc = await transaction.get(playerRef);
      
      if (!playerDoc.exists) {
        throw new HttpsError('not-found', 'Player not found');
      }
      
      const playerData = playerDoc.data();
      
      // Validate effort level
      if (effort < 1 || effort > 4) {
        throw new HttpsError('invalid-argument', 'Invalid effort level');
      }
      
      // Calculate energy cost
      const energyCosts = { 1: 15, 2: 25, 3: 35, 4: 45 };
      const energyCost = energyCosts[effort];
      
      // Validate player has enough energy
      if ((playerData.energy || 100) < energyCost) {
        throw new HttpsError('failed-precondition', 'Insufficient energy');
      }
      
      // Calculate song quality server-side (prevents manipulation)
      const songwritingSkill = playerData.songwritingSkill || 10;
      const lyricsSkill = playerData.lyricsSkill || 10;
      const compositionSkill = playerData.compositionSkill || 10;
      
      let baseQuality = (songwritingSkill + lyricsSkill + compositionSkill) / 3.0;
      baseQuality *= (0.5 + (effort * 0.25)); // Effort multiplier
      baseQuality *= (0.8 + ((playerData.inspirationLevel || 0) / 100.0 * 0.4)); // Inspiration
      
      const songQuality = Math.min(100, Math.max(1, Math.round(baseQuality)));
      
      // Calculate rewards (server-side to prevent manipulation)
      const moneyGain = Math.round((songQuality / 100) * 100 * effort); // Max $400
      const fameGain = Math.round((songQuality / 100) * 2 * effort); // Max 8 fame
      const creativityGain = effort * 2;
      
      // Calculate skill gains
      const baseGain = effort;
      const bonusGain = songQuality > 70 ? 2 : songQuality > 50 ? 1 : 0;
      
      const skillGains = {
        songwritingSkill: baseGain + bonusGain,
        experience: (effort * 10) + Math.round(songQuality / 10),
        lyricsSkill: genre === 'Hip Hop' ? baseGain + bonusGain + 2 : baseGain / 2,
        compositionSkill: genre === 'Electronic' ? baseGain + bonusGain + 1 : baseGain / 2,
      };
      
      // Validate money change
      const oldMoney = playerData.currentMoney || 1000;
      const newMoney = oldMoney + moneyGain;
      if (!validateMoneyChange(oldMoney, newMoney, 'song_creation')) {
        throw new HttpsError('invalid-argument', 'Suspicious money gain detected');
      }
      
      // Create song object
      const songId = `song_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
      const newSong = {
        id: songId,
        title,
        genre,
        quality: songQuality,
        createdDate: admin.firestore.FieldValue.serverTimestamp(),
        state: 'written',
      };
      
      // Update player stats
      const updates = {
        energy: Math.max(0, (playerData.energy || 100) - energyCost),
        currentMoney: newMoney,
        currentFame: (playerData.currentFame || 0) + fameGain,
        inspirationLevel: Math.max(0, (playerData.inspirationLevel || 0) + creativityGain),
        songwritingSkill: Math.min(100, (playerData.songwritingSkill || 10) + skillGains.songwritingSkill),
        lyricsSkill: Math.min(100, (playerData.lyricsSkill || 10) + skillGains.lyricsSkill),
        compositionSkill: Math.min(100, (playerData.compositionSkill || 10) + skillGains.compositionSkill),
        experience: Math.min(10000, (playerData.experience || 0) + skillGains.experience),
        songs: admin.firestore.FieldValue.arrayUnion(newSong),
        lastActivity: admin.firestore.FieldValue.serverTimestamp(),
      };
      
      // Log suspicious activity if detected
      const flags = detectSuspiciousActivity({ ...playerData, ...updates }, updates);
      if (flags.length > 0) {
        await logSuspiciousActivity(playerId, 'song_creation', flags, { 
          songQuality, 
          moneyGain, 
          effort,
          title 
        });
      }
      
      transaction.update(playerRef, updates);
      
      return {
        success: true,
        song: newSong,
        gains: {
          money: moneyGain,
          fame: fameGain,
          creativity: creativityGain,
          skills: skillGains,
        },
        newStats: {
          energy: updates.energy,
          money: updates.currentMoney,
          fame: updates.currentFame,
        },
      };
    });
  } catch (error) {
    console.error('Error in secureSongCreation:', error);
    throw error;
  }
});

exports.secureStatUpdate = onCall(async (request) => {
  const data = request.data;
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'Must be authenticated');
  }
  
  const { updates, action, context: actionContext, playerId } = data;
  
  // Determine which player to update
  let targetPlayerId = request.auth.uid; // Default: update self
  
  // Admin can update other players
  if (playerId && playerId !== request.auth.uid) {
    await validateAdminAccess(request); // Throws if not admin
    targetPlayerId = playerId;
  }
  
  try {
    console.log('secureStatUpdate called for', targetPlayerId, 'action=', action);
    if (updates && typeof updates === 'object') {
      try {
        const keys = Object.keys(updates || {});
        console.log('secureStatUpdate payload keys:', keys.join(', '), 'songsLen=', Array.isArray(updates.songs) ? updates.songs.length : 0, 'albumsLen=', Array.isArray(updates.albums) ? updates.albums.length : 0);
      } catch (kErr) {
        console.warn('Failed to log payload summary', kErr);
      }
    }

    return await db.runTransaction(async (transaction) => {
      const playerRef = db.collection('players').doc(targetPlayerId);
      const playerDoc = await transaction.get(playerRef);
      
      if (!playerDoc.exists) {
        throw new HttpsError('not-found', 'Player not found');
      }
      
      const playerData = playerDoc.data();
      const validatedUpdates = {};
      
      // Validate each stat change
      for (const [stat, newValue] of Object.entries(updates)) {
        const oldValue = playerData[stat] || 0;
        console.log(`Processing stat: ${stat} (type=${typeof newValue})`);

        // Reject any direct non-finite numeric values immediately
        if (typeof newValue === 'number' && !Number.isFinite(newValue)) {
          throw new HttpsError('invalid-argument', `Invalid numeric value for ${stat}: ${newValue}`);
        }

        // For compound payloads (songs/albums/regionalFanbase) ensure nested numbers are finite
        if (['songs', 'albums', 'regionalFanbase'].includes(stat)) {
          try {
            validateNestedNumbers(newValue, stat);
          } catch (err) {
            console.warn('Payload validation failed for', stat, err.message || err);
            throw new HttpsError('invalid-argument', `Invalid numeric value inside ${stat}`);
          }
        }

        try {
          switch (stat) {
          case 'currentMoney':
            if (!validateMoneyChange(oldValue, newValue, action, actionContext)) {
              throw new HttpsError('invalid-argument', `Invalid money change: ${oldValue} -> ${newValue}`);
            }
            validatedUpdates[stat] = Math.max(0, newValue); // No negative money
            break;
            
          case 'energy':
            validatedUpdates[stat] = Math.max(0, Math.min(100, newValue)); // 0-100 range
            break;
            
          case 'currentFame':
            if (!validateStatChange(oldValue, newValue, stat, 50)) {
              throw new HttpsError('invalid-argument', `Invalid ${stat} change`);
            }
            validatedUpdates[stat] = Math.max(0, newValue);
            break;
            
          case 'fanbase':
            // Fanbase can grow more rapidly from daily streams (multiple songs × conversion rates)
            // Allow up to 2000 new fans per save (accounts for viral hits, multiple albums, campaigns)
            if (!validateStatChange(oldValue, newValue, stat, 2000)) {
              throw new HttpsError('invalid-argument', `Invalid ${stat} change`);
            }
            validatedUpdates[stat] = Math.max(0, newValue);
            break;
            
          case 'songwritingSkill':
          case 'lyricsSkill':
          case 'compositionSkill':
            // Allow up to 30 points per save (accounts for practice sessions, writing multiple songs, daily progression)
            if (!validateStatChange(oldValue, newValue, stat, 30)) {
              throw new HttpsError('invalid-argument', `Invalid skill change`);
            }
            validatedUpdates[stat] = Math.max(0, Math.min(100, newValue));
            break;
          
          case 'experience':
            // XP can grow rapidly from writing songs, performing, etc.
            if (!validateStatChange(oldValue, newValue, stat, 200)) {
              throw new HttpsError('invalid-argument', `Invalid experience change`);
            }
            validatedUpdates[stat] = Math.max(0, newValue); // No upper limit
            break;
          
          case 'creativity':
          case 'inspirationLevel':
            // 🎨 Creativity (Hype) and Inspiration - can grow significantly from activities
            if (!validateStatChange(oldValue, newValue, stat, 100)) {
              throw new HttpsError('invalid-argument', `Invalid ${stat} change`);
            }
            validatedUpdates[stat] = Math.max(0, newValue); // No upper limit
            break;
          
          // ✅ CRITICAL FIX: Allow songs, albums, and fanbase arrays to be saved
          case 'songs':
            // Merge incoming songs with existing songs to preserve server-managed fields
            // (streams, lastDayStreams, last7DaysStreams, regionalStreams, peakDailyStreams, daysOnChart)
            try {
              const incomingSongs = Array.isArray(newValue) ? newValue : [];
              // If the player has been migrated to subcollections, write each song as
              // its own document instead of storing the entire songs array on the player doc.
              if (migrated) {
                console.log('Player migrated -> writing songs to subcollection for', targetPlayerId, 'incomingSongs=', incomingSongs.length);
                let written = 0;
                for (const inc of incomingSongs) {
                  try {
                    if (!inc || !inc.id) continue;
                    const songId = String(inc.id);
                    const songRef = playerRef.collection('songs').doc(songId);
                    const existingSongSnap = await transaction.get(songRef);
                    const existing = existingSongSnap.exists ? existingSongSnap.data() : {};

                    // Merge policy: preserve server-managed numeric stats unless admin explicitly set them
                    const merged = Object.assign({}, existing, inc);
                    merged.streams = (existing.streams !== undefined && existing.streams !== null) ? existing.streams : (inc.streams !== undefined ? inc.streams : 0);
                    merged.lastDayStreams = (existing.lastDayStreams !== undefined && existing.lastDayStreams !== null) ? existing.lastDayStreams : (inc.lastDayStreams !== undefined ? inc.lastDayStreams : 0);
                    merged.last7DaysStreams = (existing.last7DaysStreams !== undefined && existing.last7DaysStreams !== null) ? existing.last7DaysStreams : (inc.last7DaysStreams !== undefined ? inc.last7DaysStreams : 0);
                    merged.regionalStreams = (existing.regionalStreams !== undefined && existing.regionalStreams !== null) ? existing.regionalStreams : (inc.regionalStreams !== undefined ? inc.regionalStreams : {});
                    merged.peakDailyStreams = (existing.peakDailyStreams !== undefined && existing.peakDailyStreams !== null) ? existing.peakDailyStreams : (inc.peakDailyStreams !== undefined ? inc.peakDailyStreams : 0);
                    merged.daysOnChart = (existing.daysOnChart !== undefined && existing.daysOnChart !== null) ? existing.daysOnChart : (inc.daysOnChart !== undefined ? inc.daysOnChart : 0);

                    // Normalize streaming platforms and union with existing ones
                    merged.streamingPlatforms = Array.isArray(merged.streamingPlatforms) ? merged.streamingPlatforms.map(String) : [];
                    if (Array.isArray(existing.streamingPlatforms)) {
                      const union = new Set([...(existing.streamingPlatforms || []).map(String), ...(merged.streamingPlatforms || [])].map(String));
                      merged.streamingPlatforms = Array.from(union);
                    }

                    // Convert date strings to Timestamps
                    if (merged.releasedDate && typeof merged.releasedDate === 'string') {
                      const d = new Date(merged.releasedDate);
                      if (!isNaN(d.getTime())) merged.releasedDate = admin.firestore.Timestamp.fromDate(d);
                    }
                    if (merged.promoEndDate && typeof merged.promoEndDate === 'string') {
                      const d2 = new Date(merged.promoEndDate);
                      if (!isNaN(d2.getTime())) merged.promoEndDate = admin.firestore.Timestamp.fromDate(d2);
                    }
                    merged.isAlbum = !!merged.albumId || merged.releaseType === 'ep' || merged.releaseType === 'album';

                    // Write the merged song doc
                    transaction.set(songRef, merged);
                    written++;
                  } catch (wErr) {
                    console.error('Failed to write song to subcollection for player', targetPlayerId, 'songId=', inc && inc.id, wErr && wErr.stack ? wErr.stack : wErr);
                    throw wErr;
                  }
                }
                // Instead of writing a large songs array to the player doc, keep a small count
                validatedUpdates['songsCount'] = written;
                break;
              }

              const existingSongs = playerData.songs || [];

              // Admin updates can overwrite everything
              if (action === 'admin_stat_update') {
                // Still sanitize dates/platforms for storage
                const adminSanitized = incomingSongs.map((s) => {
                  const song = { ...s };
                  song.streamingPlatforms = Array.isArray(song.streamingPlatforms)
                    ? song.streamingPlatforms.map(String)
                    : [];
                  // Default released tracks to both platforms if none provided
                  if (song.state === 'released' && song.streamingPlatforms.length === 0) {
                    song.streamingPlatforms.push('tunify', 'maple_music');
                  }
                  if (song.releasedDate && typeof song.releasedDate === 'string') {
                    const d = new Date(song.releasedDate);
                    if (!isNaN(d.getTime())) song.releasedDate = admin.firestore.Timestamp.fromDate(d);
                  }
                  if (song.promoEndDate && typeof song.promoEndDate === 'string') {
                    const d2 = new Date(song.promoEndDate);
                    if (!isNaN(d2.getTime())) song.promoEndDate = admin.firestore.Timestamp.fromDate(d2);
                  }
                  song.isAlbum = !!song.albumId || song.releaseType === 'ep' || song.releaseType === 'album';
                  return song;
                });
                validatedUpdates[stat] = adminSanitized;
                break;
              }

              const mergedSongs = incomingSongs.map((inc) => {
                if (!inc || !inc.id) return inc;
                const existing = existingSongs.find((s) => s.id === inc.id) || {};

                // Preserve server-managed stats unless the client explicitly provided them (admin only)
                return {
                  ...existing,
                  ...inc,
                  streams: (existing.streams !== undefined && existing.streams !== null) ? existing.streams : inc.streams,
                  lastDayStreams: (existing.lastDayStreams !== undefined && existing.lastDayStreams !== null) ? existing.lastDayStreams : inc.lastDayStreams,
                  last7DaysStreams: (existing.last7DaysStreams !== undefined && existing.last7DaysStreams !== null) ? existing.last7DaysStreams : inc.last7DaysStreams,
                  regionalStreams: (existing.regionalStreams !== undefined && existing.regionalStreams !== null) ? existing.regionalStreams : inc.regionalStreams,
                  peakDailyStreams: (existing.peakDailyStreams !== undefined && existing.peakDailyStreams !== null) ? existing.peakDailyStreams : inc.peakDailyStreams,
                  daysOnChart: (existing.daysOnChart !== undefined && existing.daysOnChart !== null) ? existing.daysOnChart : inc.daysOnChart,
                };
              });

              // Post-process merged songs: sanitize platforms and convert date strings to Timestamps
              const processedMerged = mergedSongs.map((song) => {
                const s = { ...song };
                s.streamingPlatforms = Array.isArray(s.streamingPlatforms) ? s.streamingPlatforms.map(String) : [];
                // If released, ensure both platforms are present by default
                if (s.state === 'released' && s.streamingPlatforms.length === 0) {
                  s.streamingPlatforms.push('tunify', 'maple_music');
                }
                // Also union with any existing server-side platforms to avoid accidental removal
                const existing = existingSongs.find((x) => x.id === s.id) || {};
                if (Array.isArray(existing.streamingPlatforms)) {
                  const union = new Set([...(existing.streamingPlatforms || []), ...(s.streamingPlatforms || [])].map(String));
                  s.streamingPlatforms = Array.from(union);
                }
                if (s.releasedDate && typeof s.releasedDate === 'string') {
                  const d = new Date(s.releasedDate);
                  if (!isNaN(d.getTime())) s.releasedDate = admin.firestore.Timestamp.fromDate(d);
                }
                if (s.promoEndDate && typeof s.promoEndDate === 'string') {
                  const d2 = new Date(s.promoEndDate);
                  if (!isNaN(d2.getTime())) s.promoEndDate = admin.firestore.Timestamp.fromDate(d2);
                }
                s.isAlbum = !!s.albumId || s.releaseType === 'ep' || s.releaseType === 'album';
                return s;
              });

              validatedUpdates[stat] = processedMerged;
            } catch (mergeError) {
              console.warn('Error merging songs, using incoming value directly', mergeError);
              validatedUpdates[stat] = newValue;
            }
            break;
          case 'albums':
            try {
              const incomingAlbums = Array.isArray(newValue) ? newValue : [];
              const existingAlbums = playerData.albums || [];

              // If player migrated to subcollections, write each album as its own document
              if (migrated) {
                console.log('Player migrated -> writing albums to subcollection for', targetPlayerId, 'incomingAlbums=', incomingAlbums.length);
                let awritten = 0;
                for (const alb of incomingAlbums) {
                  try {
                    if (!alb || !alb.id) continue;
                    const albumIdStr = String(alb.id);
                    const albumRef = playerRef.collection('albums').doc(albumIdStr);
                    const existingAlbumSnap = await transaction.get(albumRef);
                    const existingAlbum = existingAlbumSnap.exists ? existingAlbumSnap.data() : {};

                    const merged = Object.assign({}, existingAlbum, alb);
                    merged.streamingPlatforms = Array.isArray(merged.streamingPlatforms) ? merged.streamingPlatforms.map(String) : [];

                    // Aggregate platforms from songs in the subcollection belonging to this album
                    const albumSongIds = Array.isArray(merged.songIds) ? merged.songIds : [];
                    for (const sid of albumSongIds) {
                      try {
                        if (!sid) continue;
                        const songRef = playerRef.collection('songs').doc(String(sid));
                        const songSnap = await transaction.get(songRef);
                        if (!songSnap.exists) continue;
                        const sdoc = songSnap.data();
                        if (sdoc && Array.isArray(sdoc.streamingPlatforms)) {
                          for (const p of sdoc.streamingPlatforms) merged.streamingPlatforms.push(String(p));
                        }
                      } catch (e) {
                        // ignore per-song failures
                      }
                    }

                    // Deduplicate platforms and ensure defaults
                    const set = new Set((merged.streamingPlatforms || []).map(String));
                    if (set.size === 0) {
                      set.add('tunify');
                      set.add('maple_music');
                    }
                    merged.streamingPlatforms = Array.from(set);

                    // Normalize dates
                    if (merged.releasedDate && typeof merged.releasedDate === 'string') {
                      const d = new Date(merged.releasedDate);
                      if (!isNaN(d.getTime())) merged.releasedDate = admin.firestore.Timestamp.fromDate(d);
                    }
                    if (merged.scheduledDate && typeof merged.scheduledDate === 'string') {
                      const d2 = new Date(merged.scheduledDate);
                      if (!isNaN(d2.getTime())) merged.scheduledDate = admin.firestore.Timestamp.fromDate(d2);
                    }

                    transaction.set(albumRef, merged);
                    awritten++;
                  } catch (wErr) {
                    console.error('Failed to write album to subcollection for player', targetPlayerId, 'albumId=', alb && alb.id, wErr && wErr.stack ? wErr.stack : wErr);
                    throw wErr;
                  }
                }

                validatedUpdates['albumsCount'] = awritten;
                break;
              }

              const candidateSongs = Array.isArray(updates.songs) ? updates.songs : (playerData.songs || []);

              const processedAlbums = incomingAlbums.map((album) => {
                const a = { ...album };
                a.streamingPlatforms = Array.isArray(a.streamingPlatforms) ? a.streamingPlatforms.map(String) : [];

                // Collect platforms from candidate songs that belong to this album
                const albumSongIds = new Set(Array.isArray(a.songIds) ? a.songIds : []);
                for (const s of candidateSongs) {
                  try {
                    if (!s || !s.id) continue;
                    if (albumSongIds.has(s.id)) {
                      if (Array.isArray(s.streamingPlatforms)) {
                        for (const p of s.streamingPlatforms) a.streamingPlatforms.push(String(p));
                      }
                    }
                  } catch (e) {
                    // ignore malformed song entries
                  }
                }

                // Deduplicate platforms
                const set = new Set((a.streamingPlatforms || []).map(String));
                if (set.size === 0) {
                  set.add('tunify');
                  set.add('maple_music');
                }
                a.streamingPlatforms = Array.from(set);

                // Normalize dates
                if (a.releasedDate && typeof a.releasedDate === 'string') {
                  const d = new Date(a.releasedDate);
                  if (!isNaN(d.getTime())) a.releasedDate = admin.firestore.Timestamp.fromDate(d);
                }
                if (a.scheduledDate && typeof a.scheduledDate === 'string') {
                  const d2 = new Date(a.scheduledDate);
                  if (!isNaN(d2.getTime())) a.scheduledDate = admin.firestore.Timestamp.fromDate(d2);
                }

                return a;
              });

              validatedUpdates[stat] = processedAlbums;
            } catch (albumError) {
              console.warn('Error processing albums payload, saving incoming as-is', albumError);
              validatedUpdates[stat] = newValue;
            }
            break;
          case 'regionalFanbase':
            // Accept regional fanbase payload after numeric validation above
            validatedUpdates[stat] = newValue;
            break;
          
          case 'loyalFanbase':
          case 'currentRegion':
            // Accept simple values without strict validation
            validatedUpdates[stat] = newValue;
            break;
          
          case 'avatarUrl':
            // Accept avatar URL string (can be null)
            if (newValue === null || typeof newValue === 'string') {
              validatedUpdates[stat] = newValue;
            }
            break;
          
          case 'totalStreams':
          case 'songsPublished':
            // Accept computed values from client
            if (typeof newValue === 'number' && Number.isFinite(newValue)) {
              validatedUpdates[stat] = Math.max(0, newValue);
            }
            break;
            
          default:
            validatedUpdates[stat] = newValue;
          }
        } catch (statErr) {
          console.error(`Error processing stat ${stat}:`, statErr && statErr.stack ? statErr.stack : statErr);
          // Convert unexpected errors to an HttpsError so the client gets a controlled error code
          throw new HttpsError('internal', `Failed processing ${stat}: ${statErr && statErr.message ? statErr.message : String(statErr)}`);
        }
      }
      
      // Add timestamp
      validatedUpdates.lastActivity = admin.firestore.FieldValue.serverTimestamp();
      
      // Check for suspicious activity (skip for admin actions)
      let detectedFlags = [];
      if (action !== 'admin_stat_update') {
        detectedFlags = detectSuspiciousActivity({ ...playerData, ...validatedUpdates }, validatedUpdates);
        if (detectedFlags.length > 0) {
          await logSuspiciousActivity(targetPlayerId, action || 'stat_update', detectedFlags, { 
            originalUpdates: updates,
            validatedUpdates,
            actionContext 
          });
          
          // Block update if too many flags
          if (detectedFlags.length > 3) {
            throw new HttpsError('permission-denied', 'Suspicious activity detected');
          }
        }
      }
      
      try {
        transaction.update(playerRef, validatedUpdates);
      } catch (updateErr) {
        try {
          const keys = Object.keys(validatedUpdates || {});
          console.error('Failed to write player updates, keys:', keys.join(', '), 'songsLen=', Array.isArray(validatedUpdates.songs) ? validatedUpdates.songs.length : 0);
          if (Array.isArray(validatedUpdates.songs)) {
            console.error('Sample song ids:', validatedUpdates.songs.slice(0, 5).map(s => s && s.id).join(', '));
          }

          // Persist a sanitized summary to diagnostics collection for offline debugging
          const audit = summarizeUpdatesForAudit(validatedUpdates || {});
          await db.collection('diagnostics').add({
            type: 'failed_player_update',
            playerId: targetPlayerId,
            keys: audit.keys,
            songsCount: audit.songsCount,
            albumsCount: audit.albumsCount,
            sampleSongIds: audit.sampleSongIds,
            sampleAlbumIds: audit.sampleAlbumIds,
            error: (updateErr && updateErr.message) ? updateErr.message : String(updateErr),
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
          });
        } catch (auditErr) {
          console.error('Failed to persist diagnostics for failed update:', auditErr);
        }

        console.error('Transaction update error:', updateErr && updateErr.stack ? updateErr.stack : updateErr);
        throw new HttpsError('internal', 'Failed to persist player updates');
      }
      
      return {
        success: true,
        appliedUpdates: validatedUpdates,
        flags: action !== 'admin_stat_update' ? (detectedFlags.length > 0 ? detectedFlags : undefined) : undefined,
      };
    });
  } catch (error) {
    console.error('Error in secureStatUpdate:', error);
    throw error;
  }
});

exports.secureSideHustleReward = onCall(async (request) => {
  const data = request.data;
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'Must be authenticated');
  }
  
  const playerId = request.auth.uid;
  const { sideHustleId, currentGameDate } = data;
  
  try {
    return await db.runTransaction(async (transaction) => {
      const playerRef = db.collection('players').doc(playerId);
      const playerDoc = await transaction.get(playerRef);
      
      if (!playerDoc.exists) {
        throw new HttpsError('not-found', 'Player not found');
      }
      
      const playerData = playerDoc.data();
      const sideHustle = playerData.activeSideHustle;
      
      if (!sideHustle || sideHustle.id !== sideHustleId) {
        throw new HttpsError('not-found', 'No matching active side hustle');
      }
      
      // Validate the side hustle hasn't been exploited
      const lastRewardDate = sideHustle.lastRewardDate ? toDateSafe(sideHustle.lastRewardDate) : null;
      const gameDate = toDateSafe(currentGameDate);
      
      if (lastRewardDate && gameDate && gameDate <= lastRewardDate) {
        throw new HttpsError('failed-precondition', 'Side hustle already rewarded for this date');
      }
      
      // Validate reward amounts
      const dailyPay = Math.min(200, Math.max(50, sideHustle.dailyPay || 100)); // Cap at $200/day
      const energyCost = Math.min(30, Math.max(5, sideHustle.dailyEnergyCost || 15)); // Cap at 30 energy
      
      const oldMoney = playerData.currentMoney || 1000;
      const newMoney = oldMoney + dailyPay;
      const oldEnergy = playerData.energy || 100;
      const newEnergy = Math.max(0, oldEnergy - energyCost);
      
      // Validate money change
      if (!validateMoneyChange(oldMoney, newMoney, 'side_hustle')) {
        throw new HttpsError('invalid-argument', 'Invalid side hustle reward');
      }
      
      // Check if contract expired
      const endDate = toDateSafe(sideHustle.endDate);
      const isExpired = gameDate && endDate && gameDate > endDate;
      
      const updates = {
        currentMoney: newMoney,
        energy: newEnergy,
        lastActivity: admin.firestore.FieldValue.serverTimestamp(),
      };
      
      if (isExpired) {
        updates.activeSideHustle = admin.firestore.FieldValue.delete();
      } else {
        updates.activeSideHustle = {
          ...sideHustle,
          lastRewardDate: admin.firestore.Timestamp.fromDate(gameDate),
        };
      }
      
      transaction.update(playerRef, updates);
      
      return {
        success: true,
        rewards: {
          money: dailyPay,
          energyCost: energyCost,
        },
        contractExpired: isExpired,
        newStats: {
          money: newMoney,
          energy: newEnergy,
        },
      };
    });
  } catch (error) {
    console.error('Error in secureSideHustleReward:', error);
    throw error;
  }
});

/**
 * Securely release an album/EP for the calling player (or for a target player if admin).
 * This runs in a transaction and ensures songs and album objects are updated atomically
 * with platform availability, release dates, and stat gains.
 */
exports.secureReleaseAlbum = onCall(async (request) => {
  const data = request.data;
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'Must be authenticated');
  }

  const albumId = data.albumId;
  const overridePlatforms = Array.isArray(data.overridePlatforms) ? data.overridePlatforms.map(String) : null;
  const playerId = data.playerId; // optional, admin-only

  if (!albumId || typeof albumId !== 'string') {
    throw new HttpsError('invalid-argument', 'albumId is required');
  }

  let targetPlayerId = request.auth.uid;
  if (playerId && playerId !== request.auth.uid) {
    // Allow admins to release on behalf of other players
    await validateAdminAccess(request);
    targetPlayerId = playerId;
  }

  const debug = !!data?.debug;

  try {
    // Entry log (safe, non-PII): helps correlate invocation in logs
    if (debug) {
      console.log('secureReleaseAlbum invoked', {
        albumId: String(albumId),
        targetPlayerId,
        overridePlatformsCount: Array.isArray(overridePlatforms) ? overridePlatforms.length : 0,
      });
    }
    const result = await db.runTransaction(async (transaction) => {
      const playerRef = db.collection('players').doc(targetPlayerId);
      const playerDoc = await transaction.get(playerRef);
      if (!playerDoc.exists) {
        throw new HttpsError('not-found', 'Player not found');
      }

      const playerData = playerDoc.data();
      const migrated = !!playerData.migratedToSubcollections;

      // If the player has been migrated, operate on per-player subcollection docs
      if (migrated) {
        // Try to locate the album doc in the albums subcollection
        const albumRef = playerRef.collection('albums').doc(String(albumId));
        const albumDoc = await transaction.get(albumRef);
        if (!albumDoc.exists) {
          throw new HttpsError('not-found', 'Album not found (migrated)');
        }

        const album = albumDoc.data();
        if (album.state === 'released') {
          return { success: true, message: 'Album already released' };
        }

        const albumSongIds = new Set(Array.isArray(album.songIds) ? album.songIds : []);
        const nowTs = admin.firestore.Timestamp.fromDate(new Date());

        // Fetch and update each song doc that belongs to this album
        const updatedSongsForAlbum = [];
        for (const sid of albumSongIds) {
          try {
            const sidStr = String(sid);
            const sref = playerRef.collection('songs').doc(sidStr);
            const sdoc = await transaction.get(sref);
            if (!sdoc.exists) continue;
            const sdata = sdoc.data() || {};
            const updated = Object.assign({}, sdata);
            if (!updated.releasedDate) updated.releasedDate = nowTs;
            updated.state = 'released';
            // Apply override platforms or default to both
            const set = new Set(Array.isArray(updated.streamingPlatforms) ? updated.streamingPlatforms.map(String) : []);
            if (Array.isArray(overridePlatforms) && overridePlatforms.length > 0) {
              overridePlatforms.forEach((p) => set.add(String(p)));
            } else {
              set.add('tunify');
              set.add('maple_music');
            }
            updated.streamingPlatforms = Array.from(set);
            updated.isAlbum = true;
            updated.albumId = String(albumId);
            if (updated.promoEndDate && typeof updated.promoEndDate === 'string') {
              const d = new Date(updated.promoEndDate);
              if (!isNaN(d.getTime())) updated.promoEndDate = admin.firestore.Timestamp.fromDate(d);
            }

            transaction.set(sref, updated);
            updatedSongsForAlbum.push(updated);
          } catch (sErr) {
            console.error('Failed to update song in release transaction:', sErr);
            throw sErr;
          }
        }

        // Update album doc
        const albumPlatformsSet = new Set();
        for (const s of updatedSongsForAlbum) {
          if (Array.isArray(s.streamingPlatforms)) {
            for (const p of s.streamingPlatforms) albumPlatformsSet.add(String(p));
          }
        }
        if (albumPlatformsSet.size === 0) {
          albumPlatformsSet.add('tunify');
          albumPlatformsSet.add('maple_music');
        }

        const updatedAlbum = Object.assign({}, album, {
          state: 'released',
          releasedDate: nowTs,
          streamingPlatforms: Array.from(albumPlatformsSet),
        });
        transaction.set(albumRef, updatedAlbum);

        // Compute stat gains
        const albumSongsForQuality = updatedSongsForAlbum;
        const avgQuality = albumSongsForQuality.length === 0
          ? 50
          : Math.round(albumSongsForQuality.reduce((sum, s) => {
              const rq = (s.recordingQuality !== undefined && s.recordingQuality !== null) ? s.recordingQuality : s.quality || 50;
              return sum + (rq || 50);
            }, 0) / albumSongsForQuality.length);

        const fameGain = 5 + Math.floor(avgQuality / 20);
        const fanbaseGain = 100 + (fameGain * 20);

        const validatedUpdates = {
          currentFame: Math.max(0, (playerData.currentFame || 0) + fameGain),
          fanbase: Math.max(0, (playerData.fanbase || 0) + fanbaseGain),
          lastActivity: admin.firestore.FieldValue.serverTimestamp(),
        };

        // Increment albumsCount
        validatedUpdates.albumsCount = (playerData.albumsCount || 0) + 1;

        try {
          transaction.update(playerRef, validatedUpdates);
        } catch (uErr) {
          console.error('Failed to write player stats during migrated album release', uErr);
          throw new HttpsError('internal', 'Failed to persist release stats');
        }

        return {
          success: true,
          appliedUpdates: validatedUpdates,
          newStats: {
            currentFame: validatedUpdates.currentFame,
            fanbase: validatedUpdates.fanbase,
          },
        };
      }

      // Fallback: non-migrated players use array-based model
      const existingSongs = Array.isArray(playerData.songs) ? playerData.songs : [];
      const existingAlbums = Array.isArray(playerData.albums) ? playerData.albums : [];

      // Normalize ID comparison (string vs number) to avoid false negatives
      const albumIdStr = String(albumId);
      const albumIndex = existingAlbums.findIndex((a) => String(a?.id) === albumIdStr);
      if (albumIndex === -1) {
        throw new HttpsError('not-found', 'Album not found');
      }

      const album = { ...existingAlbums[albumIndex] };
      if (album.state === 'released') {
        // Already released — idempotent success
        return { success: true, message: 'Album already released' };
      }

      // Determine which songs belong to the album
      const albumSongIds = new Set(
        Array.isArray(album.songIds) ? album.songIds.map((sid) => String(sid)) : []
      );

      // Build incoming updated song objects
      const nowTs = admin.firestore.Timestamp.fromDate(new Date());
      const incomingSongs = existingSongs.map((s) => {
        if (!s || !s.id) return s;
        if (!albumSongIds.has(String(s.id))) return s;

        const updated = { ...s };
        // Respect existing release date for singles, otherwise set now
        if (!updated.releasedDate) updated.releasedDate = nowTs;
        updated.state = 'released';
        // Apply override platforms if provided, else ensure common platforms exist
        const set = new Set(Array.isArray(updated.streamingPlatforms) ? updated.streamingPlatforms.map(String) : []);
        if (Array.isArray(overridePlatforms) && overridePlatforms.length > 0) {
          overridePlatforms.forEach((p) => set.add(String(p)));
        } else {
          set.add('tunify');
          set.add('maple_music');
        }
        updated.streamingPlatforms = Array.from(set);
        updated.isAlbum = true;
        updated.albumId = albumId;
        // Ensure promo fields and timestamps are normalized
        if (updated.promoEndDate && typeof updated.promoEndDate === 'string') {
          const d = new Date(updated.promoEndDate);
          if (!isNaN(d.getTime())) updated.promoEndDate = admin.firestore.Timestamp.fromDate(d);
        }
        return updated;
      });

      // Determine album-level platforms from its updated songs
      const albumPlatformsSet = new Set();
      for (const s of incomingSongs) {
        if (s && albumSongIds.has(String(s.id)) && Array.isArray(s.streamingPlatforms)) {
          for (const p of s.streamingPlatforms) albumPlatformsSet.add(String(p));
        }
      }
      if (albumPlatformsSet.size === 0) {
        albumPlatformsSet.add('tunify');
        albumPlatformsSet.add('maple_music');
      }

      const updatedAlbum = { ...album };
      updatedAlbum.state = 'released';
      updatedAlbum.releasedDate = nowTs;
      updatedAlbum.streamingPlatforms = Array.from(albumPlatformsSet);

      // Compute stat gains (fame and fanbase) using a similar heuristic as client
      const albumSongsForQuality = existingSongs.filter((s) => albumSongIds.has(s.id));
      const avgQuality = albumSongsForQuality.length === 0
        ? 50
        : Math.round(albumSongsForQuality.reduce((sum, s) => {
            const rq = (s.recordingQuality !== undefined && s.recordingQuality !== null) ? s.recordingQuality : s.quality || 50;
            return sum + (rq || 50);
          }, 0) / albumSongsForQuality.length);

      const fameGain = 5 + Math.floor(avgQuality / 20);
      const fanbaseGain = 100 + (fameGain * 20);

      // Prepare validated updates
      const validatedUpdates = {
        songs: incomingSongs,
        albums: existingAlbums.map((a) => a.id === albumId ? updatedAlbum : a),
        currentFame: Math.max(0, (playerData.currentFame || 0) + fameGain),
        fanbase: Math.max(0, (playerData.fanbase || 0) + fanbaseGain),
        lastActivity: admin.firestore.FieldValue.serverTimestamp(),
      };

      // Check for suspicious activity
        const flags = detectSuspiciousActivity({ ...playerData, ...validatedUpdates }, validatedUpdates);
        if (flags.length > 0) {
          // Avoid logging inside the transaction; if needed, do best-effort logging after commit elsewhere
          if (flags.length > 3) {
            throw new HttpsError('permission-denied', 'Suspicious activity detected');
          }
        }

      // Commit transaction
      try {
        transaction.update(playerRef, validatedUpdates);
      } catch (updateErr) {
        console.error('Failed to commit release transaction for album', albumId, updateErr && updateErr.stack ? updateErr.stack : updateErr);
        throw new HttpsError('internal', 'Failed to write release updates');
      }

      return {
        success: true,
        appliedUpdates: validatedUpdates,
        newStats: {
          currentFame: validatedUpdates.currentFame,
          fanbase: validatedUpdates.fanbase,
        },
      };
    });
    // Best-effort: add debug signal
    if (debug) {
      console.log('secureReleaseAlbum completed successfully', { albumId, targetPlayerId });
    }
    return result;
  } catch (error) {
    const errMsg = error && error.message ? error.message : 'Internal error during album release';
    const errCode = error && error.code ? String(error.code) : 'unknown';
    const errName = error && error.name ? String(error.name) : 'Error';
    const details = {
      step: 'secureReleaseAlbum',
      code: errCode,
      name: errName,
      message: errMsg,
      stack: error && error.stack ? String(error.stack) : undefined,
      albumId: albumId,
      targetPlayerId: targetPlayerId,
    };
    console.error('Error in secureReleaseAlbum:', details);
    throw new HttpsError('internal', errMsg, details);
  }
});

/**
 * One-off migration function: move songs/albums from player document arrays
 * into per-player subcollections (players/{uid}/songs and players/{uid}/albums).
 * Call this for specific players (admin only) or run over the user collection in batches.
 */
exports.migratePlayerContentToSubcollections = onCall(async (request) => {
  const data = request.data;
  // Only admin may run this
  await validateAdminAccess(request);

  const playerId = data.playerId;
  if (!playerId) {
    throw new HttpsError('invalid-argument', 'playerId is required');
  }

  try {
    const playerRef = db.collection('players').doc(playerId);
    const doc = await playerRef.get();
    if (!doc.exists) return { success: false, message: 'Player not found' };

    const dataObj = doc.data();
    const songs = Array.isArray(dataObj.songs) ? dataObj.songs : [];
    const albums = Array.isArray(dataObj.albums) ? dataObj.albums : [];

    console.log(`Migrating player ${playerId}: songs=${songs.length}, albums=${albums.length}`);

    const batch = db.batch();
    let writes = 0;

    for (const s of songs) {
      if (!s || !s.id) continue;
      const ref = playerRef.collection('songs').doc(String(s.id));
      batch.set(ref, s);
      writes++;
      if (writes % 500 === 0) await batch.commit();
    }
    if (writes % 500 !== 0) await batch.commit();

    // Albums
    const batch2 = db.batch();
    let awrites = 0;
    for (const a of albums) {
      if (!a || !a.id) continue;
      const ref = playerRef.collection('albums').doc(String(a.id));
      batch2.set(ref, a);
      awrites++;
      if (awrites % 500 === 0) await batch2.commit();
    }
    if (awrites % 500 !== 0) await batch2.commit();

    console.log(`Migration complete for ${playerId}: songsWritten=${writes}, albumsWritten=${awrites}`);

    // Mark player as migrated and persist counts
    try {
      await playerRef.update({
        migratedToSubcollections: true,
        migratedAt: admin.firestore.FieldValue.serverTimestamp(),
        songsCount: writes,
        albumsCount: awrites,
      });
    } catch (uErr) {
      console.error('Failed to mark player as migrated for', playerId, uErr);
      // Not fatal for migration result, continue
    }

    return { success: true, songsWritten: writes, albumsWritten: awrites };
  } catch (migErr) {
    console.error('Migration error for player', playerId, migErr);
    throw new HttpsError('internal', 'Migration failed');
  }
});

async function checkNoDuplicateSongName(playerId, title) {
  const playerDoc = await db.collection('players').doc(playerId).get();
  if (!playerDoc.exists) return true;
  
  const songs = playerDoc.data().songs || [];
  return !songs.some(s => s.title.toLowerCase() === title.toLowerCase());
}

function validateGenre(genre) {
  const validGenres = ['pop', 'hip_hop', 'rock', 'electronic', 'country', 'jazz', 'classical', 'reggae', 'latin', 'indie'];
  return validGenres.includes(genre);
}

function validatePlatforms(platforms) {
  if (!platforms || platforms.length === 0) return false;
  const validPlatforms = ['tunify', 'maple_music'];
  return platforms.every(p => validPlatforms.includes(p));
}

function getValidationErrors(validations) {
  const errors = [];
  if (!validations.hasEnoughMoney) errors.push('Insufficient funds');
  if (!validations.qualityMatchesSkill) errors.push('Quality exceeds skill level');
  if (!validations.noDuplicateName) errors.push('Song name already exists');
  if (!validations.validGenre) errors.push('Invalid genre');
  if (!validations.validPlatforms) errors.push('Invalid platforms');
  return errors.join(', ');
}

/**
 * Create a small, safe summary of an incoming updates payload suitable for
 * persisting to a diagnostics collection without including full user content.
 */
function summarizeUpdatesForAudit(updates) {
  const summary = {
    keys: Array.isArray(Object.keys(updates || {})) ? Object.keys(updates || {}) : [],
    songsCount: Array.isArray(updates && updates.songs) ? updates.songs.length : 0,
    albumsCount: Array.isArray(updates && updates.albums) ? updates.albums.length : 0,
    sampleSongIds: [],
    sampleAlbumIds: [],
  };
  try {
    if (Array.isArray(updates && updates.songs)) {
      summary.sampleSongIds = updates.songs.slice(0, 5).map(s => s && s.id).filter(Boolean);
    }
    if (Array.isArray(updates && updates.albums)) {
      summary.sampleAlbumIds = updates.albums.slice(0, 5).map(a => a && a.id).filter(Boolean);
    }
  } catch (err) {
    // Best-effort only - don't throw during diagnostics summarization
  }
  return summary;
}

function selectRandomRegion() {
  const regions = ['usa', 'europe', 'uk', 'asia', 'africa', 'latin_america', 'oceania'];
  return regions[Math.floor(Math.random() * regions.length)];
}

// ============================================================================
// MANUAL TESTING FUNCTIONS (Keep from v1)
// ============================================================================

exports.triggerDailyUpdate = onCall(async (request) => {
  const data = request.data;
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'Must be authenticated');
  }
  
  console.log('🔧 Manual trigger: Daily update started');
  
  try {
    // Run the same logic as scheduled function
    const gameTimeRef = db.collection('game_state').doc('global_time');
    const gameTimeDoc = await gameTimeRef.get();
    
    // Initialize game time if it doesn't exist
    if (!gameTimeDoc.exists) {
      console.log('⚠️ Game time not found. Initializing...');
      const startDate = new Date('2020-01-01T00:00:00Z');
      await gameTimeRef.set({
        currentGameDate: admin.firestore.Timestamp.fromDate(startDate),
        lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
        realWorldStartDate: admin.firestore.Timestamp.fromDate(new Date('2025-10-01T00:00:00Z')),
        gameWorldStartDate: admin.firestore.Timestamp.fromDate(startDate),
      });
      console.log('✅ Game time initialized successfully');
    }
    
    // Fetch again after potential initialization
    const updatedGameTimeDoc = await gameTimeRef.get();
    const currentGameDate = updatedGameTimeDoc.data().currentGameDate.toDate();
    const newGameDate = new Date(currentGameDate);
    newGameDate.setDate(newGameDate.getDate() + 1);
    
    await gameTimeRef.update({
      currentGameDate: admin.firestore.Timestamp.fromDate(newGameDate),
      lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
    });
    
    const playersSnapshot = await db.collection('players').get();
    let processedCount = 0;
    
    const batch = db.batch();
    let batchCount = 0;
    
    for (const playerDoc of playersSnapshot.docs) {
      const updates = await processDailyStreamsForPlayer(
        playerDoc.id,
        playerDoc.data(),
        newGameDate
      );
      
      if (updates) {
        batch.update(playerDoc.ref, updates);
        batchCount++;
        processedCount++;
        
        if (batchCount >= 500) {
          await batch.commit();
          batchCount = 0;
        }
      }
    }
    
    if (batchCount > 0) {
      await batch.commit();
    }
    
    return {
      success: true,
      playersProcessed: processedCount,
      totalPlayers: playersSnapshot.size,
      newGameDate: newGameDate.toISOString(),
    };
  } catch (error) {
    console.error('❌ Error in manual trigger:', error);
    throw new HttpsError('internal', error.message);
  }
});

exports.catchUpMissedDays = onCall(async (request) => {
  const data = request.data;
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'Must be authenticated');
  }
  
  const { startDate, endDate } = data;
  
  console.log(`🔧 Manual catch-up: ${startDate} to ${endDate}`);
  
  try {
    const start = new Date(startDate);
    const end = new Date(endDate);
    if (isNaN(start.getTime()) || isNaN(end.getTime())) {
      throw new HttpsError('invalid-argument', 'Invalid start or end date');
    }
    const days = Math.ceil((end - start) / (1000 * 60 * 60 * 24));
    
    if (days > 30) {
      throw new HttpsError('invalid-argument', 'Maximum 30 days allowed');
    }
    
    let totalProcessed = 0;
    
    for (let i = 0; i <= days; i++) {
      const currentDate = new Date(start);
      currentDate.setDate(currentDate.getDate() + i);
      
      const playersSnapshot = await db.collection('players').get();
      const batch = db.batch();
      let batchCount = 0;
      
      for (const playerDoc of playersSnapshot.docs) {
        const updates = await processDailyStreamsForPlayer(
          playerDoc.id,
          playerDoc.data(),
          currentDate
        );
        
        if (updates) {
          batch.update(playerDoc.ref, updates);
          batchCount++;
          
          if (batchCount >= 500) {
            await batch.commit();
            batchCount = 0;
          }
        }
      }
      
      if (batchCount > 0) {
        await batch.commit();
      }
      
      totalProcessed += playersSnapshot.size;
    }
    
    return {
      success: true,
      daysProcessed: days + 1,
      totalUpdates: totalProcessed,
    };
  } catch (error) {
    console.error('❌ Error in catch-up:', error);
    throw new HttpsError('internal', error.message);
  }
});

// ============================================================================
// 8. NPC ARTIST SYSTEM - Populate game world with AI artists
// ============================================================================

// Signature NPC Artists (10 featured characters with storylines)
const SIGNATURE_NPCS = [
  {
    id: 'npc_jaylen_sky',
    name: 'Jaylen Sky',
    region: 'usa',
    primaryGenre: 'hip_hop',
    secondaryGenre: 'trap',
    tier: 'rising', // rising, established, star
    bio: 'Atlanta-born rapper who built his following through SoundCloud battles and freestyle videos. His hit single went viral—but now a ghostwriter claims ownership of the lyrics.',
    traits: ['Bold', 'Clever', 'Street-savvy'],
    avatar: '🎤',
    baseStreams: 150000, // Per week
    growthRate: 1.15, // 15% growth per week
    releaseFrequency: 14, // Days between releases
    socialActivity: 'high', // EchoX posting frequency
  },
  {
    id: 'npc_luna_grey',
    name: 'Luna Grey',
    region: 'uk',
    primaryGenre: 'pop',
    secondaryGenre: 'r&b',
    tier: 'established',
    bio: 'London-based singer-songwriter blending old-school soul with modern pop energy. Recently signed with a major label, torn between radio hits and staying artistic.',
    traits: ['Elegant', 'Authentic', 'Outspoken'],
    avatar: '🎵',
    baseStreams: 300000,
    growthRate: 1.10,
    releaseFrequency: 21,
    socialActivity: 'medium',
  },
  {
    id: 'npc_elodie_rain',
    name: 'Élodie Rain',
    region: 'europe',
    primaryGenre: 'electronic',
    secondaryGenre: 'indie',
    tier: 'rising',
    bio: 'Parisian electronic artist known for moody synth textures and poetic lyrics. Her latest album was inspired by an AI poet she secretly trained.',
    traits: ['Mysterious', 'Introspective', 'Experimental'],
    avatar: '🎹',
    baseStreams: 120000,
    growthRate: 1.12,
    releaseFrequency: 28,
    socialActivity: 'low',
  },
  {
    id: 'npc_santiago_vega',
    name: 'Santiago Vega',
    region: 'latin_america',
    primaryGenre: 'latin',
    secondaryGenre: 'reggaeton',
    tier: 'star',
    bio: 'Brazilian-Puerto Rican performer known for his electrifying dance style. His fiery rivalry with another Latin artist keeps him constantly in the tabloids.',
    traits: ['Flirty', 'Passionate', 'Competitive'],
    avatar: '💃',
    baseStreams: 500000,
    growthRate: 1.08,
    releaseFrequency: 14,
    socialActivity: 'high',
  },
  {
    id: 'npc_zyrah',
    name: 'Zyrah',
    region: 'africa',
    primaryGenre: 'afrobeat',
    secondaryGenre: 'r&b',
    tier: 'rising',
    bio: 'Lagos-based rising star who started from open mic nights before getting discovered online. Her debut album\'s massive success sparks rumors she\'s leaving her crew behind.',
    traits: ['Confident', 'Playful', 'Unstoppable'],
    avatar: '🌍',
    baseStreams: 180000,
    growthRate: 1.20, // Fastest growing
    releaseFrequency: 21,
    socialActivity: 'high',
  },
  {
    id: 'npc_kazuya_rin',
    name: 'Kazuya Rin',
    region: 'asia',
    primaryGenre: 'electronic',
    secondaryGenre: 'synthwave',
    tier: 'established',
    bio: 'Tokyo producer famous for futuristic visuals and anime-inspired soundscapes. His fans adore him, but he\'s secretly burned out and questioning his artistry.',
    traits: ['Calm', 'Visionary', 'Disciplined'],
    avatar: '🎧',
    baseStreams: 280000,
    growthRate: 1.05,
    releaseFrequency: 35,
    socialActivity: 'low',
  },
  {
    id: 'npc_nova_reign',
    name: 'Nova Reign',
    region: 'usa',
    primaryGenre: 'indie',
    secondaryGenre: 'r&b',
    tier: 'established',
    bio: 'Toronto-based artist blending melancholic pop with cinematic sound design. Her mysterious persona hides a secret identity as a ghost producer for big names.',
    traits: ['Dreamy', 'Articulate', 'Enigmatic'],
    avatar: '✨',
    baseStreams: 250000,
    growthRate: 1.07,
    releaseFrequency: 28,
    socialActivity: 'medium',
  },
  {
    id: 'npc_jax_carter',
    name: 'Jax Carter',
    region: 'oceania',
    primaryGenre: 'indie',
    secondaryGenre: 'rock',
    tier: 'rising',
    bio: 'Sydney-born multi-instrumentalist known for surf-inspired indie anthems. His "breakthrough album" leaked early—and it might have actually helped his fame.',
    traits: ['Chill', 'Loyal', 'Creative'],
    avatar: '🏄',
    baseStreams: 140000,
    growthRate: 1.13,
    releaseFrequency: 21,
    socialActivity: 'medium',
  },
  {
    id: 'npc_kofi_dray',
    name: 'Kofi Dray',
    region: 'africa',
    primaryGenre: 'afrobeat',
    secondaryGenre: 'highlife',
    tier: 'established',
    bio: 'Producer-turned-singer mixing old highlife grooves with modern amapiano elements. Leading a "Highlife Revival" movement—but global fame is testing his principles.',
    traits: ['Grounded', 'Visionary', 'Patient'],
    avatar: '🥁',
    baseStreams: 220000,
    growthRate: 1.11,
    releaseFrequency: 28,
    socialActivity: 'medium',
  },
  {
    id: 'npc_hana_seo',
    name: 'Hana Seo',
    region: 'asia',
    primaryGenre: 'kpop',
    secondaryGenre: 'r&b',
    tier: 'star',
    bio: 'Seoul-based idol turned independent artist, breaking free from strict management. Fans are divided over her "rebellious" shift from idol pop to mature R&B.',
    traits: ['Ambitious', 'Brave', 'Perfectionist'],
    avatar: '👑',
    baseStreams: 600000,
    growthRate: 1.09,
    releaseFrequency: 14,
    socialActivity: 'high',
  },
];

// Initialize NPC artists in database (ONE-TIME SETUP)
exports.initializeNPCArtists = onCall(async (request) => {
  const data = request.data;
  try {
    console.log('🤖 Initializing NPC artists...');
    
    // Check if already initialized
    const npcCheckDoc = await db.collection('npc_artists').doc('_initialized').get();
    if (npcCheckDoc.exists && npcCheckDoc.data().initialized === true) {
      return {
        success: false,
        message: 'NPC artists already initialized',
        count: npcCheckDoc.data().count || 0,
      };
    }
    
    // Use only signature NPCs (no background filler)
    const allNPCs = SIGNATURE_NPCS;
    
    console.log(`📊 Creating ${allNPCs.length} signature NPC artists...`);
    
    // Create all NPCs with initial songs
    const batch = db.batch();
    let batchCount = 0;
    
    for (const npc of allNPCs) {
      const npcRef = db.collection('npc_artists').doc(npc.id);
      
      // Generate 3-10 initial songs for each NPC
      const songCount = Math.floor(Math.random() * 8) + 3;
      const songs = [];
      
      for (let i = 0; i < songCount; i++) {
        const daysOld = Math.floor(Math.random() * 180); // Songs up to 6 months old
        const releasedDate = new Date();
        releasedDate.setDate(releasedDate.getDate() - daysOld);
        
        const songGenre = Math.random() > 0.7 ? npc.secondaryGenre : npc.primaryGenre;
        
        songs.push({
          id: `${npc.id}_song_${i + 1}`,
          title: generateNPCSongTitle(songGenre),
          genre: songGenre,
          quality: Math.floor(Math.random() * 30) + 60, // 60-90 quality
          totalStreams: Math.floor(npc.baseStreams * (1 - daysOld / 365) * (Math.random() * 0.5 + 0.75)),
          last7DaysStreams: Math.floor(npc.baseStreams / 7 * (Math.random() * 0.5 + 0.75)),
          releasedDate: admin.firestore.Timestamp.fromDate(releasedDate),
          daysOld,
          platforms: ['tunify', 'maple_music'],
        });
      }
      
      batch.set(npcRef, {
        ...npc,
        songs,
        totalCareerStreams: songs.reduce((sum, s) => sum + s.totalStreams, 0),
        fanbase: Math.floor(npc.baseStreams / 10),
        fame: Math.min(100, Math.floor(npc.baseStreams / 10000)),
        lastReleaseDate: admin.firestore.Timestamp.fromDate(new Date()),
        isNPC: true,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      
      batchCount++;
      
      if (batchCount >= 500) {
        await batch.commit();
        batchCount = 0;
      }
    }
    
    if (batchCount > 0) {
      await batch.commit();
    }
    
    // Mark as initialized
    await db.collection('npc_artists').doc('_initialized').set({
      initialized: true,
      count: allNPCs.length,
      signatureNPCs: allNPCs.length,
      initializedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    
    console.log(`✅ Successfully initialized ${allNPCs.length} signature NPC artists!`);
    
    return {
      success: true,
      message: `Created ${allNPCs.length} signature NPC artists`,
      count: allNPCs.length,
    };
  } catch (error) {
    console.error('❌ Error initializing NPCs:', error);
    throw new HttpsError('internal', error.message);
  }
});

// Simulate NPC activity (runs with hourly update)
exports.simulateNPCActivity = onSchedule({
  schedule: '0 * * * *', // Every hour with daily update
  timeZone: 'UTC',
  timeoutSeconds: 540,
  memory: '512MiB',
}, async (event) => {
  console.log('🤖 Simulating NPC artist activity...');
    
    try {
      const npcsSnapshot = await db.collection('npc_artists')
        .where('isNPC', '==', true)
        .get();
      
      if (npcsSnapshot.empty) {
        console.log('⚠️ No NPCs found. Run initializeNPCArtists first.');
        return null;
      }
      
      console.log(`🎵 Processing ${npcsSnapshot.size} NPC artists...`);
      
      const batch = db.batch();
      let batchCount = 0;
      let songsReleased = 0;
      let echoxPosts = 0;
      
      for (const npcDoc of npcsSnapshot.docs) {
        const npc = npcDoc.data();
        const songs = npc.songs || [];
        
        // 1. Update stream counts for existing songs
        const updatedSongs = songs.map(song => {
          const ageDecay = Math.max(0.3, 1 - (song.daysOld / 365) * 0.7);
          const randomVariance = Math.random() * 0.4 + 0.8; // 80-120%
          const dailyStreams = Math.floor(npc.baseStreams / 7 * ageDecay * randomVariance * npc.growthRate);
          
          // Decay last 7 days (14.3% per day)
          const decayedLast7Days = Math.round(song.last7DaysStreams * 0.857);
          const newLast7Days = decayedLast7Days + dailyStreams;
          
          return {
            ...song,
            totalStreams: song.totalStreams + dailyStreams,
            last7DaysStreams: newLast7Days,
            daysOld: song.daysOld + 1,
          };
        });
        
        // 2. Release new songs when release frequency threshold is met
        const daysSinceLastRelease = Math.floor(
          (Date.now() - npc.lastReleaseDate.toDate().getTime()) / (1000 * 60 * 60 * 24)
        );
        
        // Release if frequency threshold is met (with small random variance to feel natural)
        // Base threshold + random 0-2 days variance = releases happen reliably but not on exact same day
        const shouldRelease = daysSinceLastRelease >= (npc.releaseFrequency + Math.floor(Math.random() * 3));
        
        if (shouldRelease) {
          const newSong = {
            id: `${npc.id}_song_${Date.now()}`,
            title: generateNPCSongTitle(npc.primaryGenre),
            genre: Math.random() > 0.7 ? npc.secondaryGenre : npc.primaryGenre,
            quality: Math.floor(Math.random() * 25) + 65, // 65-90 quality
            totalStreams: Math.floor(npc.baseStreams * 0.1 * (Math.random() * 0.5 + 0.75)),
            last7DaysStreams: Math.floor(npc.baseStreams * 0.1 * (Math.random() * 0.5 + 0.75)),
            releasedDate: admin.firestore.Timestamp.fromDate(new Date()),
            daysOld: 0,
            platforms: ['tunify', 'maple_music'],
          };
          
          updatedSongs.push(newSong);
          songsReleased++;
          
          // Update last release date
          npc.lastReleaseDate = admin.firestore.Timestamp.fromDate(new Date());
          
          // Post announcement on EchoX about the new release
          await createNPCEchoXPost(npc, 'song_release', newSong.title);
        }
        
        // 3. Post on EchoX occasionally (not during song releases - those create their own posts)
        if (!shouldRelease && shouldNPCPostOnEchoX(npc.socialActivity)) {
          await createNPCEchoXPost(npc, 'general');
          echoxPosts++;
        }
        
        // 4. Update NPC document
        const totalCareerStreams = updatedSongs.reduce((sum, s) => sum + s.totalStreams, 0);
        
        batch.update(npcDoc.ref, {
          songs: updatedSongs,
          totalCareerStreams,
          fanbase: Math.floor(totalCareerStreams / 100),
          fame: Math.min(100, Math.floor(totalCareerStreams / 100000)),
          lastReleaseDate: npc.lastReleaseDate,
        });
        
        batchCount++;
        
        if (batchCount >= 500) {
          await batch.commit();
          batchCount = 0;
        }
      }
      
      if (batchCount > 0) {
        await batch.commit();
      }
      
      console.log(`✅ NPC simulation complete: ${songsReleased} songs released, ${echoxPosts} EchoX posts`);
      
      return null;
    } catch (error) {
      console.error('❌ Error simulating NPCs:', error);
      return null;
    }
  });

// Helper: Generate NPC song titles
function generateNPCSongTitle(genre) {
  const titleTemplates = {
    pop: ['Love', 'Heart', 'Dream', 'Night', 'Star', 'Summer', 'Shine', 'Forever'],
    hip_hop: ['Streets', 'Real', 'Money', 'Block', 'Ride', 'Game', 'City', 'Hustle'],
    'r&b': ['Soul', 'Feels', 'Vibe', 'Mood', 'Love', 'Nights', 'Baby', 'True'],
    rock: ['Fire', 'Storm', 'Wild', 'Breaking', 'Free', 'Run', 'Rebel', 'Edge'],
    electronic: ['Digital', 'Neon', 'Pulse', 'Wave', 'Synth', 'Electric', 'Future', 'Cyber'],
    indie: ['Quiet', 'Faded', 'Strange', 'Lost', 'Found', 'Home', 'Away', 'Simple'],
    afrobeat: ['Lagos', 'Vibe', 'Dance', 'Rhythm', 'Africa', 'Party', 'Move', 'Celebrate'],
    latin: ['Fuego', 'Bailar', 'Amor', 'Noche', 'Fiesta', 'Corazon', 'Vida', 'Caliente'],
    reggaeton: ['Perreo', 'Bellaca', 'Dembow', 'Party', 'Night', 'Dance', 'Vibes', 'Trap'],
    trap: ['Drip', 'Flex', 'Bands', 'Ice', 'Wave', 'Fire', 'Stack', 'Sauce'],
    kpop: ['Heart', 'Love', 'Dream', 'Star', 'Shine', 'Light', 'Forever', 'Beautiful'],
    highlife: ['Highlife', 'Joy', 'Celebration', 'Dance', 'Life', 'Happy', 'Good', 'Time'],
    synthwave: ['Retro', 'Neon', '80s', 'Drive', 'Night', 'City', 'Future', 'Past'],
    reggae: ['Peace', 'Love', 'Irie', 'Roots', 'Island', 'Sun', 'Vibes', 'One'],
  };
  
  const words = titleTemplates[genre] || titleTemplates.pop;
  const word1 = words[Math.floor(Math.random() * words.length)];
  const word2 = words[Math.floor(Math.random() * words.length)];
  
  const templates = [
    word1,
    `${word1} ${word2}`,
    `The ${word1}`,
    `${word1} Night`,
    `${word1} Dreams`,
    `No ${word1}`,
  ];
  
  return templates[Math.floor(Math.random() * templates.length)];
}

// Helper: Should NPC post on EchoX?
function shouldNPCPostOnEchoX(socialActivity) {
  const thresholds = {
    high: 0.15, // 15% chance per hour
    medium: 0.05, // 5% chance
    low: 0.02, // 2% chance
  };
  
  return Math.random() < (thresholds[socialActivity] || 0.05);
}

// Helper: Create NPC EchoX post
async function createNPCEchoXPost(npc, postType = 'general', songTitle = null) {
  try {
    let content = '';
    
    // Unique personality-based posts for each NPC
    const personalityPosts = {
      npc_jaylen_sky: {
        general: [
          'Real recognize real 💯',
          'Atlanta forever, this my city 🏙️',
          'Every bar I write, I own it. Period.',
          'Built this from the ground up, no handouts 📈',
          'They tried to take credit for my work... not happening 👊',
          'SoundCloud to stadium shows. That\'s the journey 🚀',
          'Pen game too strong, they can\'t fake this 📝',
          'Late nights in the studio, this is what dedication looks like 🎤',
        ],
        song_release: [
          `"${songTitle}" out now! Every word mine, every bar authentic 🔥`,
          `New track "${songTitle}" - wrote this one myself too 💯`,
          `Just dropped "${songTitle}" - real Hip Hop, no ghostwriters 🎤`,
          `"${songTitle}" live! Atlanta stand up! 🏙️`,
        ],
      },
      npc_luna_grey: {
        general: [
          'Sometimes staying true to yourself costs everything... worth it ✨',
          'Between the radio hits and my soul... choosing my soul 🎵',
          'London nights got me feeling inspired 🌙',
          'Major label pressure vs artistic integrity. We know which one wins 💪',
          'Thank you for loving the real me, not the industry version ❤️',
          'Writing sessions that feel like therapy 📝',
          'Pop music can still have depth. I\'m proving it every day ✨',
          'Staying authentic in a manufactured world 🎯',
        ],
        song_release: [
          `New single "${songTitle}" out now - this one\'s from the heart ❤️`,
          `"${songTitle}" is live! My truth, my sound, my rules ✨`,
          `Just released "${songTitle}" - raw, honest, unapologetic 🎵`,
          `"${songTitle}" available now. This is me, unfiltered 💫`,
        ],
      },
      npc_elodie_rain: {
        general: [
          'Dans l\'obscurité, on trouve la lumière... (In darkness, we find light) 🌙',
          'Creating soundscapes for the digital age 🎹',
          'My synths speak the language words cannot express ✨',
          'Art and technology, forever intertwined 🤖',
          'Midnight in Paris, where the music breathes 🌃',
          'The machine learns... but who teaches the machine? 🧠',
          'Experimental is just another word for fearless 💫',
          'Poetry in code, emotion in synthesis 🎵',
        ],
        song_release: [
          `Nouveau morceau: "${songTitle}" 🎹 Listen with headphones`,
          `"${songTitle}" - an exploration of sound and silence 🌌`,
          `New release: "${songTitle}" - where AI meets artistry ✨`,
          `"${songTitle}" est disponible maintenant. Close your eyes and feel it 🎧`,
        ],
      },
      npc_santiago_vega: {
        general: [
          '¡La vida es un baile! Life is a dance 💃',
          'They talk about rivalry... I talk about excellence 🔥',
          'Brazil + Puerto Rico = unstoppable energy 🇧🇷🇵🇷',
          'El fuego nunca duerme (The fire never sleeps) 🌟',
          'Dance like the world is watching... because it is 👀',
          'Controversy keeps my name trending. Free promo 📱',
          'Passion, rhythm, and a little bit of danger ⚡',
          'Making history one performance at a time 🎤',
        ],
        song_release: [
          `¡NUEVO! "${songTitle}" disponible ahora! 🔥💃`,
          `"${songTitle}" out now! Prepárense to move! 🎵`,
          `New track "${songTitle}" - Latino heat at maximum! 🌶️`,
          `"${songTitle}" is live! Dale play! 🚀`,
        ],
      },
      npc_zyrah: {
        general: [
          'From open mics to global stages - the journey continues 🌍',
          'Lagos raised me, the world will know me 🇳🇬',
          'They say success changes you... I say it reveals you 👑',
          'Afrobeat forever! This is our time! 🥁',
          'My crew been real since day one. Nothing changes that 💯',
          'Rising star? Nah, I\'m a whole constellation ✨',
          'African excellence in every note 🎵',
          'Confidence isn\'t arrogance when you can back it up 💪',
        ],
        song_release: [
          `"${songTitle}" out now! Afrobeat magic 🌍✨`,
          `New music: "${songTitle}" - this one\'s special! 🎵`,
          `Just dropped "${songTitle}"! Lagos to the world! 🇳🇬`,
          `"${songTitle}" available now - pure Afrobeat energy! 🔥`,
        ],
      },
      npc_kazuya_rin: {
        general: [
          'Tokyo nights inspire Tokyo sounds 🌃',
          '音楽は魂の言語 (Music is the language of the soul) 🎧',
          'Anime aesthetics meet electronic precision ⚡',
          'Creating visions, questioning everything 🤔',
          'The future sounds like this 🚀',
          'Discipline in chaos, order in creativity 🎹',
          'Sometimes the artist needs to rest... but the music doesn\'t stop 💫',
          'Neon lights and synthesized dreams ✨',
        ],
        song_release: [
          `New release: "${songTitle}" 🎧 Enter the soundscape`,
          `"${songTitle}" out now - a journey through sound 🌌`,
          `"${songTitle}" available. Visuals coming soon 👁️`,
          `Just released "${songTitle}" - the future is now ⚡`,
        ],
      },
      npc_nova_reign: {
        general: [
          'Melancholy is just beauty in disguise 🌙',
          'Toronto winters shape Toronto sounds ❄️',
          'The mystery is part of the art ✨',
          'Some secrets are meant to stay secrets 🤫',
          'Cinematic moments in everyday life 🎬',
          'Behind every hit song... never mind 👀',
          'Dreamscapes and soundscapes 💭',
          'Identity is fluid, art is eternal 🌊',
        ],
        song_release: [
          `"${songTitle}" - a new chapter begins 📖`,
          `New music: "${songTitle}" out now 🎵`,
          `Just released "${songTitle}" - dive in 🌊`,
          `"${songTitle}" available everywhere. Listen in the dark 🌙`,
        ],
      },
      npc_jax_carter: {
        general: [
          'Surf\'s up, music\'s loud 🏄',
          'Sydney sunsets hit different when the creativity flows 🌅',
          'That album leak? Best thing that ever happened to me 📈',
          'Indie music with island vibes 🌴',
          'Multi-instrumental chaos, perfectly orchestrated 🎸',
          'Good friends, good music, good life 🤙',
          'Sometimes accidents lead to success 🍀',
          'Creating freely, living fully ✨',
        ],
        song_release: [
          `New track "${songTitle}" riding the waves! 🌊`,
          `"${songTitle}" out now! Turn it up! 🔊`,
          `Just dropped "${songTitle}" - indie anthem vibes 🎸`,
          `"${songTitle}" is live! Surf rock meets indie dreams 🏄`,
        ],
      },
      npc_kofi_dray: {
        general: [
          'Highlife Revival isn\'t a trend, it\'s a movement 🥁',
          'Old grooves, new energy. That\'s the formula 🎵',
          'Amapiano meets Highlife - the future of African music 🌍',
          'Global fame won\'t change my principles 💯',
          'Producer mindset, singer\'s heart 🎤',
          'Patience is the key to greatness ⏳',
          'From the studio to the streets, music for the people 🙏',
          'Keeping our culture alive, one beat at a time 🇬🇭',
        ],
        song_release: [
          `New music: "${songTitle}" - Highlife Revival continues! 🥁`,
          `"${songTitle}" out now! Feel the groove 🎵`,
          `Just released "${songTitle}" - old soul, new sound 🌍`,
          `"${songTitle}" available everywhere. Africa rising! 🚀`,
        ],
      },
      npc_hana_seo: {
        general: [
          '자유 (Freedom) tastes sweeter than fame 👑',
          'From idol to artist - this is my evolution ✨',
          'Breaking free was the scariest and best decision 💪',
          'K-Pop trained me, R&B freed me 🎵',
          'Perfectionism isn\'t a flaw, it\'s a superpower ⚡',
          'Seoul nights, independent life 🌃',
          'My fans who grew with me - this journey is ours ❤️',
          'Rebellion looks like authenticity 🔥',
        ],
        song_release: [
          `"${songTitle}" out now! This is the real me 👑`,
          `New single "${songTitle}" - mature, bold, unapologetic 🎵`,
          `Just dropped "${songTitle}"! Independent and loving it! ✨`,
          `"${songTitle}" available now. The new era begins 🚀`,
        ],
      },
    };
    
    // Get posts for this NPC
    const npcPosts = personalityPosts[npc.id] || {
      general: ['New music coming soon! 🎵'],
      song_release: [`Just dropped "${songTitle}"! 🔥`],
    };
    
    // Select appropriate post type
    if (postType === 'song_release' && songTitle && npcPosts.song_release) {
      content = npcPosts.song_release[Math.floor(Math.random() * npcPosts.song_release.length)];
    } else {
      content = npcPosts.general[Math.floor(Math.random() * npcPosts.general.length)];
    }
    
    await db.collection('echox_posts').add({
      authorId: npc.id,
      authorName: npc.name,
      content,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      likes: 0,
      echos: 0,
      likedBy: [],
      isNPC: true, // Mark as NPC post
    });
    
    console.log(`📱 ${npc.name} posted on EchoX: "${content}"`);
  } catch (error) {
    console.error(`❌ Error creating EchoX post for ${npc.name}:`, error);
  }
}

// ============================================================================
// 9. ADMIN: Force NPC Release
// ============================================================================

/**
 * Admin endpoint to force a specific NPC to release a new song
 * Useful for testing and content management
 */
exports.forceNPCRelease = onCall(async (request) => {
  const data = request.data;
  // Verify admin authentication
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'Must be authenticated');
  }

  const { npcId } = data;

  if (!npcId) {
    throw new HttpsError('invalid-argument', 'npcId is required');
  }

  console.log(`🎵 Admin force release for NPC: ${npcId}`);

  try {
    // Find the NPC in the SIGNATURE_NPCS array
    const npc = SIGNATURE_NPCS.find(n => n.id === npcId);

    if (!npc) {
      throw new HttpsError('not-found', `NPC ${npcId} not found`);
    }

    // Get or create NPC document
    const npcRef = db.collection('npcs').doc(npcId);
    const npcDoc = await npcRef.get();

    let npcData;
    if (!npcDoc.exists) {
      // Create new NPC if doesn't exist
      npcData = {
        id: npc.id,
        name: npc.name,
        region: npc.region,
        primaryGenre: npc.primaryGenre,
        secondaryGenre: npc.secondaryGenre,
        tier: npc.tier,
        bio: npc.bio,
        traits: npc.traits,
        avatar: npc.avatar,
        baseStreams: npc.baseStreams,
        growthRate: npc.growthRate,
        releaseFrequency: npc.releaseFrequency,
        socialActivity: npc.socialActivity,
        songs: [],
        totalStreams: 0,
        fanbase: Math.floor(npc.baseStreams * 0.1), // 10% of weekly streams
        loyalFanbase: Math.floor(npc.baseStreams * 0.05), // 5% loyal fans
        regionalFanbase: {
          usa: Math.floor(npc.baseStreams * 0.03),
          europe: Math.floor(npc.baseStreams * 0.02),
          uk: Math.floor(npc.baseStreams * 0.02),
          asia: Math.floor(npc.baseStreams * 0.01),
          africa: Math.floor(npc.baseStreams * 0.01),
          latin_america: Math.floor(npc.baseStreams * 0.01),
          oceania: Math.floor(npc.baseStreams * 0.01)
        },
        fame: npc.tier === 'legend' ? 200 : npc.tier === 'star' ? 100 : 50,
        albumsSold: 0,
        songsWritten: 0,
        concertsPerformed: 0,
        songwritingSkill: 50,
        experience: 100,
        lyricsSkill: 50,
        compositionSkill: 50,
        inspirationLevel: 10,
        currentRegion: npc.region,
        age: 25,
        careerStartDate: admin.firestore.Timestamp.now(),
        avatarUrl: npc.avatar,
        lastActivityDate: admin.firestore.Timestamp.now(),
        primaryGenre: npc.primaryGenre,
        genreMastery: {[npc.primaryGenre]: 80, [npc.secondaryGenre]: 60},
        unlockedGenres: [npc.primaryGenre, npc.secondaryGenre],
        activeSideHustle: null,
      };
      await npcRef.set(npcData);
    } else {
      npcData = npcDoc.data();
    }

    // Generate a new song for the NPC
    const songTitles = [
      'Midnight Vibes', 'City Lights', 'Dreams & Nightmares', 'Rising Up',
      'On My Way', 'Lost in the Music', 'Summer Nights', 'Heart & Soul',
      'Chasing Stars', 'No Turning Back', 'Feel the Beat', 'Paradise Found',
      'Breaking Free', 'One More Time', 'Golden Hour', 'Never Give Up'
    ];

    const songTitle = songTitles[Math.floor(Math.random() * songTitles.length)];
    const quality = 70 + Math.floor(Math.random() * 25); // 70-95 quality
    const initialStreams = Math.floor(npc.baseStreams * (0.5 + Math.random() * 0.5));

    const newSong = {
      id: `${npcId}_${Date.now()}`,
      title: songTitle,
      genre: Math.random() > 0.5 ? npc.primaryGenre : npc.secondaryGenre,
      quality,
      createdDate: admin.firestore.Timestamp.now(),
      state: 'released',
      releasedDate: admin.firestore.Timestamp.now(),
      streams: initialStreams,
      likes: Math.floor(initialStreams * 0.05),
      viralityScore: 0.5 + Math.random() * 0.3,
      peakDailyStreams: Math.floor(initialStreams * 0.3),
      daysOnChart: 0,
      lastDayStreams: Math.floor(initialStreams * 0.3),
      last7DaysStreams: initialStreams,
      isAlbum: false,
      metadata: {
        npcGenerated: true,
        forcedRelease: true,
        releasedBy: request.auth.uid,
      }
    };

    // Update NPC with new song
    const updatedSongs = [...(npcData.songs || []), newSong];
    const updatedTotalStreams = (npcData.totalStreams || 0) + initialStreams;

    await npcRef.update({
      songs: updatedSongs,
      totalStreams: updatedTotalStreams,
      lastReleaseDate: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Create EchoX post announcing the release
    await db.collection('echox_posts').add({
      authorId: npc.id,
      authorName: npc.name,
      content: `Just dropped "${songTitle}"! 🎵 Stream it now! 🔥`,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      likes: Math.floor(Math.random() * 50),
      echos: 0,
      likedBy: [],
      isNPC: true,
    });

    console.log(`✅ ${npc.name} released "${songTitle}" (${initialStreams} initial streams)`);

    return {
      success: true,
      npcName: npc.name,
      songTitle,
      quality,
      initialStreams,
      totalSongs: updatedSongs.length,
    };

  } catch (error) {
    console.error('❌ Error forcing NPC release:', error);
    throw new HttpsError('internal', error.message);
  }
});

// =============================================================================
// ADMIN VALIDATION FUNCTIONS
// =============================================================================

/**
 * Server-side admin validation - centralizes all admin checks
 * Never trust client-side admin claims
 */
async function validateAdminAccess(request) {
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'Must be authenticated');
  }

  const userId = request.auth.uid;
  
  // Define admin user IDs server-side only
  const ADMIN_USER_IDS = [
    'xjJFuMCEKMZwkI8uIP34Jl2bfQA3', // Primary admin
    // Add additional admin IDs here as needed
  ];

  // Check hardcoded admin list first (fastest)
  if (ADMIN_USER_IDS.includes(userId)) {
    return true;
  }

  // Check dynamic admin collection
  try {
    const adminDoc = await db.collection('admins').doc(userId).get();
    if (adminDoc.exists && adminDoc.data().isAdmin === true) {
      return true;
    }
  } catch (error) {
    console.warn('Error checking admin collection:', error);
  }

  // Not an admin
  throw new HttpsError('permission-denied', 'Admin access required');
}

// =============================================================================
// ADMIN: Check Admin Status (Secure)
// =============================================================================
exports.checkAdminStatus = onCall(async (request) => {
  const data = request.data;
  try {
    await validateAdminAccess(request);
    return { isAdmin: true };
  } catch (error) {
    return { isAdmin: false };
  }
});

// =============================================================================
// ADMIN: Send Gift to Player (Secure)
// =============================================================================
exports.sendGiftToPlayer = onCall(async (request) => {
  const data = request.data;
  // Validate admin access server-side
  await validateAdminAccess(request);

  const { recipientId, giftType, amount, message } = data;

  if (!recipientId || !giftType) {
    throw new HttpsError('invalid-argument', 'recipientId and giftType are required');
  }

  console.log(`🎁 Admin gift: ${giftType} (${amount}) to player ${recipientId}`);

  try {
    // Get recipient player data
    const recipientRef = db.collection('players').doc(recipientId);
    const recipientDoc = await recipientRef.get();

    if (!recipientDoc.exists) {
      throw new HttpsError('not-found', 'Player not found');
    }

    const recipientData = recipientDoc.data();
    const updates = {};
    let giftDescription = '';

    // Apply gift based on type
    switch (giftType) {
      case 'money':
        const moneyAmount = amount || 1000;
        updates.currentMoney = (recipientData.currentMoney || 0) + moneyAmount;
        giftDescription = `$${moneyAmount.toLocaleString()}`;
        break;

      case 'fame':
        const fameAmount = amount || 10;
        updates.currentFame = (recipientData.currentFame || 0) + fameAmount;
        giftDescription = `${fameAmount} Fame Points`;
        break;

      case 'energy':
        const energyAmount = amount || 50;
        // Allow energy to go above 100 from gifts/purchases
        updates.energy = (recipientData.energy || 0) + energyAmount;
        giftDescription = `${energyAmount} Energy`;
        break;

      case 'fans':
        const fansAmount = amount || 1000;
        updates.fanbase = (recipientData.fanbase || 0) + fansAmount;
        giftDescription = `${fansAmount.toLocaleString()} Fans`;
        break;

      case 'streams':
        const streamsAmount = amount || 10000;
        updates.totalStreams = (recipientData.totalStreams || 0) + streamsAmount;
        giftDescription = `${streamsAmount.toLocaleString()} Streams`;
        break;

      case 'starter_pack':
        // Give a nice starter pack
        updates.currentMoney = (recipientData.currentMoney || 0) + 5000;
        updates.currentFame = (recipientData.currentFame || 0) + 25;
        updates.energy = 100;
        updates.fanbase = (recipientData.fanbase || 0) + 500;
        giftDescription = 'Starter Pack ($5,000, 25 Fame, 100 Energy, 500 Fans)';
        break;

      case 'boost_pack':
        // Give a boost pack
        updates.currentMoney = (recipientData.currentMoney || 0) + 15000;
        updates.currentFame = (recipientData.currentFame || 0) + 50;
        updates.fanbase = (recipientData.fanbase || 0) + 2000;
        updates.totalStreams = (recipientData.totalStreams || 0) + 50000;
        giftDescription = 'Boost Pack ($15,000, 50 Fame, 2,000 Fans, 50,000 Streams)';
        break;

      case 'premium_pack':
        // Give a premium pack
        updates.currentMoney = (recipientData.currentMoney || 0) + 50000;
        updates.currentFame = (recipientData.currentFame || 0) + 100;
        updates.fanbase = (recipientData.fanbase || 0) + 10000;
        updates.totalStreams = (recipientData.totalStreams || 0) + 250000;
        giftDescription = 'Premium Pack ($50,000, 100 Fame, 10,000 Fans, 250,000 Streams)';
        break;

      default:
        throw new HttpsError('invalid-argument', 'Invalid gift type');
    }

    // Update player data
    await recipientRef.update(updates);

    // Create notification for recipient
    const notificationRef = db.collection('players').doc(recipientId).collection('notifications').doc();
    await notificationRef.set({
      id: notificationRef.id,
      type: 'admin_gift',
      title: '🎁 Gift Received!',
      message: message || `You've received a gift from the admin: ${giftDescription}`,
      giftType: giftType,
      giftDescription: giftDescription,
      amount: amount,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      read: false,
      fromAdmin: true,
      adminId: request.auth.uid,
    });

    // Log the gift in a separate collection for audit
    await db.collection('admin_gifts').add({
      recipientId: recipientId,
      recipientName: recipientData.displayName || 'Unknown',
      giftType: giftType,
      amount: amount,
      giftDescription: giftDescription,
      message: message,
      adminId: request.auth.uid,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });

    console.log(`✅ Gift sent successfully to ${recipientData.displayName}`);

    return {
      success: true,
      recipientName: recipientData.displayName || 'Unknown',
      giftDescription: giftDescription,
      message: 'Gift sent and notification created',
    };

  } catch (error) {
    console.error('❌ Error sending gift:', error);
    throw new HttpsError('internal', error.message);
  }
});

// =============================================================================
// ADMIN: Manually Trigger Weekly Leaderboard Update
// =============================================================================
exports.triggerWeeklyLeaderboardUpdate = onCall(async (request) => {
  const data = request.data;
  // Verify admin authentication
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'Must be authenticated');
  }

  const { weeksAhead = 1 } = data;

  console.log(`🔄 Admin triggering weekly leaderboard update for ${weeksAhead} week(s)...`);

  try {
    const results = [];
    const now = new Date();

    for (let i = 0; i < weeksAhead; i++) {
      // Advance the date by i weeks
      const futureDate = new Date(now.getTime() + i * 7 * 24 * 60 * 60 * 1000);
      const weekId = getWeekId(futureDate);
      
      console.log(`➡️ Creating snapshots for week ${weekId} (${futureDate.toISOString().slice(0,10)})`);
      
      // Create snapshots
      await createSongLeaderboardSnapshot(weekId, futureDate);
      await createArtistLeaderboardSnapshot(weekId, futureDate);
      await updateChartStatistics(weekId);
      
      results.push({
        weekId,
        date: futureDate.toISOString().slice(0,10),
        success: true,
      });
    }

    console.log(`✅ Successfully created ${results.length} weekly snapshots`);

    return {
      success: true,
      message: `Created weekly leaderboard snapshots for ${results.length} week(s)`,
      results,
    };

  } catch (error) {
    console.error('❌ Error triggering weekly update:', error);
    throw new HttpsError('internal', error.message);
  }
});

// ============================================================================
// GLOBAL NOTIFICATION DISTRIBUTION
// ============================================================================

/**
 * Distribute a global notification to all players
 * This creates individual notification documents in each player's subcollection
 */
exports.sendGlobalNotificationToPlayers = onCall(async (request) => {
  const data = request.data;
  // Validate admin access
  await validateAdminAccess(request);

  const { title, message } = data;

  if (!title || !message) {
    throw new HttpsError('invalid-argument', 'Title and message are required');
  }

  console.log(`📢 Distributing global notification: "${title}"`);

  try {
    // Get all players
    const playersSnapshot = await db.collection('players').get();
    console.log(`👥 Found ${playersSnapshot.size} players`);

    // Create notifications in batches (Firestore limit: 500 writes per batch)
    const batchSize = 500;
    let batchCount = 0;
    let batch = db.batch();
    let totalNotifications = 0;

    for (const playerDoc of playersSnapshot.docs) {
      const notificationRef = db
        .collection('players')
        .doc(playerDoc.id)
        .collection('notifications')
        .doc(); // Auto-generate ID

      batch.set(notificationRef, {
        title: title,
        message: message,
        type: 'global',
        read: false,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        source: 'admin_broadcast',
      });

      batchCount++;
      totalNotifications++;

      // Commit batch when it reaches the limit
      if (batchCount >= batchSize) {
        await batch.commit();
        console.log(`✅ Committed batch of ${batchCount} notifications`);
        batch = db.batch();
        batchCount = 0;
      }
    }

    // Commit remaining notifications
    if (batchCount > 0) {
      await batch.commit();
      console.log(`✅ Committed final batch of ${batchCount} notifications`);
    }

    console.log(`🎉 Successfully distributed ${totalNotifications} notifications to ${playersSnapshot.size} players`);

    return {
      success: true,
      playersNotified: playersSnapshot.size,
      notificationsSent: totalNotifications,
    };
  } catch (error) {
    console.error('❌ Error distributing global notification:', error);
    throw new HttpsError('internal', error.message);
  }
});

// ============================================================================
// GANDALF THE BLACK - CONTROVERSIAL MUSIC CRITIC
// ============================================================================

/**
 * Gandalf The Black - A notorious music critic who posts controversial takes
 * Runs twice a day to stir up drama in The Scoop
 */
exports.gandalfTheBlackPosts = onSchedule({
  schedule: '0 */12 * * *', // Every 12 hours (twice a day)
  timeZone: 'UTC',
  timeoutSeconds: 540,
  memory: '512MiB',
}, async (event) => {
  console.log('🧙‍♂️ Gandalf The Black is stirring up controversy...');
    
    try {
      // Decide what type of post to create
      const postType = Math.random();
      
      if (postType < 0.4) {
        // 40% - Chart drama
        await createChartDramaPost();
      } else if (postType < 0.7) {
        // 30% - Artist beef
        await createArtistBeefPost();
      } else {
        // 30% - Controversial opinion
        await createControversialOpinionPost();
      }
      
      console.log('✅ Gandalf The Black has spoken!');
      return null;
    } catch (error) {
      console.error('❌ Error in Gandalf posts:', error);
      return null;
    }
  });

/**
 * Manual trigger for Gandalf posts (Admin only)
 */
exports.triggerGandalfPost = onCall(async (request) => {
  const data = request.data;
  await validateAdminAccess(request);
  
  console.log('🧙‍♂️ Manually triggering Gandalf The Black post...');
  
  try {
    // Handle null data or missing type property
    const postType = (data && data.type) ? data.type : 'random';
    
    if (postType === 'chart' || (postType === 'random' && Math.random() < 0.5)) {
      await createChartDramaPost();
    } else {
      await createArtistBeefPost();
    }
    
    return { success: true, message: 'Gandalf has stirred up drama!' };
  } catch (error) {
    console.error('❌ Error triggering Gandalf:', error);
    throw new HttpsError('internal', error.message);
  }
});

/**
 * Side Hustle Contract Generation - Runs daily at midnight
 * Maintains a pool of 15-20 available contracts
 */
exports.dailySideHustleGeneration = onSchedule({
  schedule: '0 0 * * *', // Every day at midnight UTC
  timeZone: 'UTC',
  timeoutSeconds: 540,
  memory: '512MiB',
}, async (event) => {
  console.log('💼 Daily side hustle contract generation triggered');
  try {
    await generateDailySideHustleContracts();
    return null;
  } catch (error) {
    console.error('❌ Error in daily side hustle generation:', error);
    return null;
  }
});

/**
 * Manual trigger for side hustle generation (Admin only)
 */
exports.triggerSideHustleGeneration = onCall(async (request) => {
  const data = request.data;
  await validateAdminAccess(request);
  
  console.log('💼 Manually triggering side hustle contract generation...');
  
  try {
    const result = await generateDailySideHustleContracts();
    return { 
      success: true, 
      message: `Generated ${result.generated} new contracts. Pool size: ${result.currentPool}`,
      ...result
    };
  } catch (error) {
    console.error('❌ Error triggering side hustle generation:', error);
    throw new HttpsError('internal', error.message);
  }
});

/**
 * Create a controversial post about chart movements
 */
async function createChartDramaPost() {
  try {
    // Get latest weekly chart
    const now = new Date();
    const weekId = getWeekId(now);
    const previousWeekId = getPreviousWeekId(weekId);
    
    // Get current and previous week charts
    const currentChartDoc = await db.collection('leaderboard_history')
      .doc(`songs_global_${weekId}`)
      .get();
    
    const previousChartDoc = await db.collection('leaderboard_history')
      .doc(`songs_global_${previousWeekId}`)
      .get();
    
    if (!currentChartDoc.exists || !previousChartDoc.exists) {
      console.log('⚠️ Chart data not available, creating opinion post instead');
      await createControversialOpinionPost();
      return;
    }
    
    const currentRankings = currentChartDoc.data().rankings;
    const previousRankings = previousChartDoc.data().rankings;
    
    // Find dramatic movements
    const biggestRiser = currentRankings
      .filter(song => song.movement > 10)
      .sort((a, b) => b.movement - a.movement)[0];
    
    const biggestFaller = currentRankings
      .filter(song => song.movement < -10)
      .sort((a, b) => a.movement - b.movement)[0];
    
    const newNumber1 = currentRankings[0];
    const oldNumber1 = previousRankings[0];
    
    let post = null;
    
    if (newNumber1.songId !== oldNumber1.songId) {
      // #1 spot changed - MAJOR drama
      post = {
        headline: '👑 NEW KING DETHRONED THE OLD GUARD',
        content: `🔥 ${oldNumber1.artist} just got KNOCKED OFF the #1 spot by ${newNumber1.artist}'s "${newNumber1.title}"! ` +
          `Is this the end of ${oldNumber1.artist}'s reign? The streets are saying they've lost their edge. ` +
          `Sources say ${oldNumber1.artist} is in the studio working on a "response track" but let's be honest - ` +
          `when you lose the crown, you rarely get it back. ${newNumber1.artist} is the future. Get used to it. 💀`,
        tags: ['beef', 'charts', '#1_spot'],
      };
    } else if (biggestFaller) {
      // Someone fell hard
      post = {
        headline: '📉 MASSIVE FLOP ALERT',
        content: `💀 ${biggestFaller.artist}'s "${biggestFaller.title}" just PLUMMETED ${Math.abs(biggestFaller.movement)} spots on the charts! ` +
          `From #${biggestFaller.lastWeekPosition} to #${biggestFaller.position}. That's not a drop, that's a CRASH. ` +
          `Fans are jumping ship FAST. Word on the street? The label is already looking for the next big thing. ` +
          `Maybe ${biggestFaller.artist} should've spent more time in the studio and less time on social media. ⚰️ #CareerOver`,
        tags: ['charts', 'flop'],
      };
    } else if (biggestRiser) {
      // Someone rose dramatically
      post = {
        headline: '⚠️ SUSPICIOUS CHART JUMP - BOT FARMS?',
        content: `🤔 ${biggestRiser.artist}'s "${biggestRiser.title}" jumped ${biggestRiser.movement} spots this week. ` +
          `That's... interesting. Real organic growth doesn't work like that. Industry insiders are whispering about ` +
          `"strategic playlist placements" and "algorithmic manipulation." Not saying they're buying streams, but when ` +
          `a song jumps that fast, you gotta wonder. True fans know what's up. 👀 #ExposedFraud #FakeStreams`,
        tags: ['charts', 'controversy'],
      };
    }
    
    if (post) {
      const gameDate = await getCurrentGameDateServer();
      await db.collection('news').add({
        category: 'drama',
        headline: post.headline,
        body: post.content,
        authorId: 'gandalf_the_black',
        authorName: 'Gandalf The Black',
        authorTitle: 'The Dark Lord of Music Criticism',
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        gameTimestamp: admin.firestore.Timestamp.fromDate(gameDate),
        isControversial: true,
        tags: post.tags,
        reactions: { fire: 0, shocked: 0, laughing: 0, angry: 0 },
      });
      
      console.log(`📰 Gandalf created chart drama post: ${post.headline}`);
    }
  } catch (error) {
    console.error('Error creating chart drama:', error);
  }
}

/**
 * Create controversial artist beef post
 */
async function createArtistBeefPost() {
  try {
    // Get random artists from current charts
    const now = new Date();
    const weekId = getWeekId(now);
    
    const chartDoc = await db.collection('leaderboard_history')
      .doc(`songs_global_${weekId}`)
      .get();
    
    if (!chartDoc.exists) {
      console.log('⚠️ No chart data, creating opinion instead');
      await createControversialOpinionPost();
      return;
    }
    
    const rankings = chartDoc.data().rankings;
    
    // Get two different artists
    const artist1 = rankings[Math.floor(Math.random() * Math.min(20, rankings.length))];
    let artist2;
    do {
      artist2 = rankings[Math.floor(Math.random() * Math.min(20, rankings.length))];
    } while (artist2.artistId === artist1.artistId);
    
    const beefTemplates = [
      {
        headline: '🥊 STUDIO BEEF: SHOTS FIRED',
        content: `👊 Sources close to ${artist1.artist} say they were TALKING TRASH about ${artist2.artist} in the studio last night. ` +
          `Apparently ${artist1.artist} called ${artist2.artist}'s music "basic" and "formulaic." ${artist2.artist}'s team is FURIOUS. ` +
          `Word is ${artist2.artist} is already working on a diss track. This is about to get MESSY. 🍿 ` +
          `Industry insiders say this beef has been brewing for months. Stay tuned.`,
      },
      {
        headline: '😤 COPYCAT SCANDAL EXPOSED',
        content: `🤔 Did ${artist2.artist} just COPY ${artist1.artist}'s sound? Both artists dropped ${artist1.genre} tracks recently ` +
          `and they sound SUSPICIOUSLY similar. ${artist1.artist} fans are calling out ${artist2.artist} for being a fraud. ` +
          `${artist2.artist}'s response? Silence. That's usually a guilty conscience talking. One of them is the real deal, ` +
          `the other is a cheap imitation. Fans know which is which. 👀 #FakeArtist`,
      },
      {
        headline: '💀 SOCIAL MEDIA WAR INCOMING',
        content: `⚠️ ${artist1.artist} just liked a tweet DISSING ${artist2.artist}. Then unliked it 5 minutes later. ` +
          `Too late, the internet saw everything. ${artist2.artist} fans are DEMANDING an apology. ${artist1.artist} fans are saying ` +
          `"they said what we were all thinking." This passive-aggressive behavior is about to turn into full-on war. ` +
          `My prediction? One of them drops a surprise track this week throwing shade. Mark my words. 🎯`,
      },
    ];
    
    const template = beefTemplates[Math.floor(Math.random() * beefTemplates.length)];
    
    const gameDate = await getCurrentGameDateServer();
    await db.collection('news').add({
      category: 'drama',
      headline: template.headline,
      body: template.content,
      authorId: 'gandalf_the_black',
      authorName: 'Gandalf The Black',
      authorTitle: 'The Dark Lord of Music Criticism',
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      gameTimestamp: admin.firestore.Timestamp.fromDate(gameDate),
      isControversial: true,
      relatedArtists: [artist1.artistId, artist2.artistId],
      tags: ['beef', 'drama', 'controversy'],
      reactions: { fire: 0, shocked: 0, laughing: 0, angry: 0 },
    });
    
    console.log(`📰 Gandalf created beef post between ${artist1.artist} and ${artist2.artist}`);
  } catch (error) {
    console.error('Error creating beef post:', error);
  }
}

/**
 * Create a controversial opinion post about music trends
 */
async function createControversialOpinionPost() {
  const opinionTemplates = [
    {
      headline: '🗑️ MODERN POP IS DEAD',
      content: `💀 Let's be real - pop music in 2020 is TRASH. Every song sounds the same. Same four chords, same generic ` +
        `lyrics about love and heartbreak, same auto-tuned vocals. Where's the creativity? Where's the risk-taking? ` +
        `Artists are too scared to be different because they're chasing streams instead of making art. ` +
        `The golden age of music is OVER. Fight me. 🎤`,
      tags: ['opinion', 'pop', 'hot_take'],
    },
    {
      headline: '📉 STREAMING KILLED MUSIC QUALITY',
      content: `⚠️ Unpopular opinion: Streaming services RUINED music. Artists are making 3-minute songs designed for TikTok ` +
        `instead of crafting albums. No one cares about artistry anymore, it's all about viral moments and playlist placements. ` +
        `The algorithms are destroying creativity. Real music died when everyone started chasing streams. ` +
        `Don't @ me, you know I'm right. 💯`,
      tags: ['opinion', 'streaming', 'industry'],
    },
    {
      headline: '🎸 ROCK IS THE ONLY REAL MUSIC',
      content: `😤 Controversial take: If it doesn't have guitars, is it even music? Hip-hop is just talking over beats. ` +
        `Electronic music is just pressing buttons. Pop is manufactured garbage. ROCK is the only genre that requires ` +
        `actual musical talent. You need to play instruments, write meaningful lyrics, and perform live. ` +
        `Everything else is fake music for fake fans. Change my mind. 🤘`,
      tags: ['opinion', 'rock', 'genre_war'],
    },
    {
      headline: '💸 BROKE ARTISTS = BAD ARTISTS',
      content: `👀 Real talk: If you're not making money from your music, you're not good enough. "Starving artist" is just ` +
        `code for "no talent." The best artists get recognized and PAID. If your music was actually good, people would stream it. ` +
        `Don't blame "the algorithm" or "lack of promotion" - blame your lack of skill. The cream rises to the top. ` +
        `Period. 💰`,
      tags: ['opinion', 'money', 'hot_take'],
    },
    {
      headline: '🚫 COLLABORATIONS ARE DESPERATE',
      content: `🤔 Why do artists collab so much now? Because they can't carry a song on their own. When you see "feat." ` +
        `on every track, that's a red flag. Real talent doesn't need features. You're either strong enough to stand alone ` +
        `or you're not. These "super collabs" are just label executives trying to double the marketing reach. ` +
        `Fans deserve solo artists with actual vision. 🎯`,
      tags: ['opinion', 'collaboration', 'controversy'],
    },
  ];
  
  const template = opinionTemplates[Math.floor(Math.random() * opinionTemplates.length)];
  
  const gameDate = await getCurrentGameDateServer();
  await db.collection('news').add({
    category: 'drama',
    headline: template.headline,
    body: template.content,
    authorId: 'gandalf_the_black',
    authorName: 'Gandalf The Black',
    authorTitle: 'The Dark Lord of Music Criticism',
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
    gameTimestamp: admin.firestore.Timestamp.fromDate(gameDate),
    isControversial: true,
    tags: template.tags,
    reactions: { fire: 0, shocked: 0, laughing: 0, angry: 0 },
  });
  
  console.log(`📰 Gandalf created opinion post: ${template.headline}`);
}

// ============================================================================
// SIDE HUSTLE CONTRACT GENERATION
// ============================================================================

/**
 * Generate new side hustle contracts daily
 * Removes old unavailable contracts and adds fresh ones to the pool
 */
async function generateDailySideHustleContracts() {
  console.log('💼 Starting daily side hustle contract generation...');
  
  try {
    const contractsRef = db.collection('side_hustle_contracts');
    
    // Count currently available contracts
    const availableSnapshot = await contractsRef
      .where('isAvailable', '==', true)
      .get();
    
    const currentAvailable = availableSnapshot.size;
    console.log(`📊 Current available contracts: ${currentAvailable}`);
    
    // Generate new contracts to maintain pool of 15-20
    const targetContracts = 18; // Target pool size
    const contractsToGenerate = Math.max(0, targetContracts - currentAvailable);
    
    if (contractsToGenerate > 0) {
      const newContractsBatch = db.batch();
      
      for (let i = 0; i < contractsToGenerate; i++) {
        const contract = generateRandomSideHustleContract();
        const docRef = contractsRef.doc(); // Auto-generate ID
        newContractsBatch.set(docRef, contract);
      }
      
      await newContractsBatch.commit();
      console.log(`✅ Generated ${contractsToGenerate} new side hustle contracts`);
    } else {
      console.log(`✅ Contract pool is healthy (${currentAvailable}/${targetContracts}), no new contracts needed`);
    }
    
    return { success: true, generated: contractsToGenerate, currentPool: currentAvailable + contractsToGenerate };
  } catch (error) {
    console.error('❌ Error in generateDailySideHustleContracts:', error);
    throw error;
  }
}

/**
 * Generate a random side hustle contract
 */
function generateRandomSideHustleContract() {
  // Match Dart enum names exactly
  const hustleTypes = [
    { type: 'security', name: 'Security Personnel', icon: '🛡️', basePayPerDay: 150, baseEnergyPerDay: 15 },
    { type: 'dogWalking', name: 'Dog Walking', icon: '🐕', basePayPerDay: 80, baseEnergyPerDay: 10 },
    { type: 'babysitting', name: 'Babysitting', icon: '👶', basePayPerDay: 120, baseEnergyPerDay: 20 },
    { type: 'foodDelivery', name: 'Food Delivery', icon: '🍔', basePayPerDay: 100, baseEnergyPerDay: 12 },
    { type: 'rideshare', name: 'Rideshare Driver', icon: '🚗', basePayPerDay: 130, baseEnergyPerDay: 12 },
    { type: 'retail', name: 'Retail Worker', icon: '🏪', basePayPerDay: 90, baseEnergyPerDay: 15 },
    { type: 'tutoring', name: 'Tutoring', icon: '📚', basePayPerDay: 140, baseEnergyPerDay: 8 },
    { type: 'bartending', name: 'Bartending', icon: '🍸', basePayPerDay: 110, baseEnergyPerDay: 18 },
    { type: 'cleaning', name: 'Cleaning Service', icon: '🧹', basePayPerDay: 95, baseEnergyPerDay: 25 },
    { type: 'waiter', name: 'Waiter/Waitress', icon: '🍽️', basePayPerDay: 105, baseEnergyPerDay: 18 },
  ];
  
  // Pick random hustle type
  const hustleType = hustleTypes[Math.floor(Math.random() * hustleTypes.length)];
  
  // Random contract length (5-25 days)
  const contractLength = 5 + Math.floor(Math.random() * 21);
  
  // Add variance to pay (±30%)
  const payVariance = Math.floor(hustleType.basePayPerDay * 0.3);
  const dailyPay = hustleType.basePayPerDay + Math.floor(Math.random() * payVariance * 2) - payVariance;
  
  // Add variance to energy (±20%)
  const energyVariance = Math.floor(hustleType.baseEnergyPerDay * 0.2);
  const dailyEnergy = Math.max(5, Math.min(40, 
    hustleType.baseEnergyPerDay + Math.floor(Math.random() * energyVariance * 2) - energyVariance
  ));
  
  // Generate unique ID
  const contractId = Date.now().toString() + Math.floor(Math.random() * 1000).toString();
  
  // Return format matching Dart SideHustle model
  return {
    id: contractId,
    type: hustleType.type, // Enum name like 'security', 'dogWalking', etc.
    dailyPay: dailyPay,
    dailyEnergyCost: dailyEnergy,
    contractLengthDays: contractLength,
    startDate: null,
    endDate: null,
    isAvailable: true,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  };
}

// ============================================================================
// PUSH NOTIFICATION SYSTEM
// ============================================================================

/**
 * Send push notification to a specific player
 * @param {string} playerId - Player's Firebase UID
 * @param {string} title - Notification title
 * @param {string} body - Notification body
 * @param {object} data - Additional data payload
 */
async function sendPushNotification(playerId, title, body, data = {}) {
  try {
    const playerDoc = await db.collection('players').doc(playerId).get();
    
    if (!playerDoc.exists) {
      console.log(`⚠️ Player ${playerId} not found`);
      return;
    }
    
    const playerData = playerDoc.data();
    const fcmToken = playerData.fcmToken;
    
    if (!fcmToken) {
      console.log(`⚠️ No FCM token for player ${playerId}`);
      return;
    }
    
    // Send notification
    const message = {
      notification: {
        title: title,
        body: body,
      },
      data: {
        ...data,
        timestamp: Date.now().toString(),
      },
      token: fcmToken,
    };
    
    await admin.messaging().send(message);
    console.log(`✅ Push notification sent to ${playerData.displayName || playerId}`);
    
    // Also create in-app notification
    await db.collection('players').doc(playerId).collection('notifications').add({
      title: title,
      message: body,
      type: data.type || 'info',
      read: false,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      data: data,
    });
    
  } catch (error) {
    console.error(`❌ Error sending push notification to ${playerId}:`, error);
  }
}

/**
 * Monitor EchoX posts for viral engagement
 * Triggered when a post document is updated
 */
exports.onPostEngagement = onDocumentWritten('echox_posts/{postId}', async (event) => {
  const change = { before: event.data?.before, after: event.data?.after };
  if (!change.before || !change.after) return null;
    const before = change.before.data();
    const after = change.after.data();
    const postId = event.params.postId;
    
    const authorId = after.authorId;
    const authorName = after.authorName;
    const content = after.content || '';
    
    // Get author's fanbase to calculate thresholds
    const authorDoc = await db.collection('players').doc(authorId).get();
    if (!authorDoc.exists) return;
    
    const fanbase = authorDoc.data().fanbase || 0;
    
    // Calculate engagement thresholds based on fanbase
    let likeThreshold, echoThreshold, commentThreshold;
    
    if (fanbase < 10000) {
      // Small artist
      likeThreshold = 100;
      echoThreshold = 20;
      commentThreshold = 50;
    } else if (fanbase < 100000) {
      // Medium artist
      likeThreshold = 1000;
      echoThreshold = 200;
      commentThreshold = 500;
    } else {
      // Big artist
      likeThreshold = 10000;
      echoThreshold = 2000;
      commentThreshold = 5000;
    }
    
    const likesGained = (after.likes || 0) - (before.likes || 0);
    const echoesGained = (after.echoes || 0) - (before.echoes || 0);
    const commentsGained = (after.comments || 0) - (before.comments || 0);
    
    // Check for milestone achievements
    if (after.likes >= likeThreshold && before.likes < likeThreshold) {
      await sendPushNotification(
        authorId,
        '🔥 Your post is blowing up!',
        `Your post reached ${after.likes.toLocaleString()} likes!`,
        {
          type: 'post_engagement',
          postId: postId,
          metric: 'likes',
          value: after.likes,
        }
      );
    }
    
    if (after.echoes >= echoThreshold && before.echoes < echoThreshold) {
      await sendPushNotification(
        authorId,
        '🎉 Viral Alert!',
        `Your post has been echoed ${after.echoes.toLocaleString()} times!`,
        {
          type: 'post_engagement',
          postId: postId,
          metric: 'echoes',
          value: after.echoes,
        }
      );
    }
    
    // Check for viral status (engagement rate > 2x expected)
    const totalEngagement = after.likes + (after.echoes * 2) + (after.comments * 1.5);
    const expectedEngagement = fanbase * 0.001; // 0.1% engagement is baseline
    
    if (totalEngagement > expectedEngagement * 2 && likesGained > 10) {
      await sendPushNotification(
        authorId,
        '🚀 You\'re going viral!',
        `Your post has ${totalEngagement.toFixed(0)} total engagements!`,
        {
          type: 'post_engagement',
          postId: postId,
          metric: 'viral',
          value: totalEngagement,
        }
      );
    }
    
    // Check for first milestone achievements
    if (after.likes >= 1000000 && before.likes < 1000000) {
      await sendPushNotification(
        authorId,
        '🏆 Milestone: First 1M Likes!',
        'Your post just hit 1 million likes! Legendary status achieved.',
        {
          type: 'post_engagement',
          postId: postId,
          metric: 'milestone',
          value: 1000000,
        }
      );
    }
  });

/**
 * Monitor chart positions and notify players
 * Runs after weekly chart updates
 */
exports.onChartUpdate = onDocumentWritten('leaderboard_history/{chartId}', async (event) => {
  const snapshot = event.data?.after;
  if (!snapshot || !snapshot.exists) return null;
  
  const chartData = snapshot.data();
  const chartId = event.params.chartId;
    
    // Parse chart type (e.g., "songs_global_2025W42")
    const chartParts = chartId.split('_');
    if (chartParts.length < 3) return;
    
    const chartType = chartParts[0]; // 'songs' or 'artists'
    const region = chartParts[1]; // 'global', 'usa', etc.
    
    const rankings = chartData.rankings || [];
    
    // Notify top 10 entries
    for (let i = 0; i < Math.min(10, rankings.length); i++) {
      const entry = rankings[i];
      const position = entry.position;
      const artistId = entry.artistId;
      
      if (!artistId) continue;
      
      // Check if this is a new chart entry or significant movement
      const movement = entry.movement || 0;
      const lastWeekPosition = entry.lastWeekPosition;
      
      // Notify if entering top 10, reaching #1, or big jump
      if (position <= 10 && (!lastWeekPosition || lastWeekPosition > 10)) {
        // Entered top 10
        const chartName = chartType === 'songs' ? 'Spotlight Charts' : 'Artist Charts';
        await sendPushNotification(
          artistId,
          `🎵 You made the ${chartName}!`,
          `Your ${chartType === 'songs' ? 'song' : 'artist profile'} "${entry.title || entry.name}" is now #${position}!`,
          {
            type: 'chart_achievement',
            chartType: chartType,
            region: region,
            position: position,
            entryId: entry.songId || entry.artistId,
          }
        );
      } else if (position === 1 && lastWeekPosition && lastWeekPosition !== 1) {
        // Reached #1
        await sendPushNotification(
          artistId,
          '👑 #1 on the Charts!',
          `"${entry.title || entry.name}" just hit #1! You're at the top!`,
          {
            type: 'chart_achievement',
            chartType: chartType,
            region: region,
            position: 1,
            entryId: entry.songId || entry.artistId,
          }
        );
      } else if (movement >= 5) {
        // Big jump up
        await sendPushNotification(
          artistId,
          `📈 Climbing the Charts!`,
          `"${entry.title || entry.name}" jumped ${movement} spots to #${position}!`,
          {
            type: 'chart_achievement',
            chartType: chartType,
            region: region,
            position: position,
            movement: movement,
            entryId: entry.songId || entry.artistId,
          }
        );
      }
    }
    
    console.log(`✅ Chart notifications sent for ${chartId}`);
  });

/**
 * Monitor chart positions for rivalry notifications
 * Runs daily to check if rivals have overtaken player
 */
exports.checkRivalChartPositions = onSchedule({
  schedule: '0 */6 * * *', // Every 6 hours
  timeZone: 'UTC',
  timeoutSeconds: 540,
  memory: '512MiB',
}, async (event) => {
  console.log('🔍 Checking for rival chart overtakes...');
    
    try {
      // Get latest global song chart
      const weekId = getWeekId(new Date());
      const chartDoc = await db.collection('leaderboard_history')
        .doc(`songs_global_${weekId}`)
        .get();
      
      if (!chartDoc.exists) {
        console.log('⚠️ No chart data available');
        return;
      }
      
      const rankings = chartDoc.data().rankings || [];
      
      // Build position map
      const positionMap = new Map();
      rankings.forEach(entry => {
        positionMap.set(entry.songId, {
          position: entry.position,
          lastWeekPosition: entry.lastWeekPosition,
          artistId: entry.artistId,
          title: entry.title,
        });
      });
      
      // Check each player's songs
      const playersSnapshot = await db.collection('players').limit(1000).get();
      
      for (const playerDoc of playersSnapshot.docs) {
        const playerData = playerDoc.data();
        const playerId = playerDoc.id;
        const songs = playerData.songs || [];
        
        // Find player's best charting song
        let playerBestPosition = null;
        let playerBestSong = null;
        
        for (const song of songs) {
          if (song.state !== 'released') continue;
          
          const chartData = positionMap.get(song.id);
          if (chartData && chartData.artistId === playerId) {
            if (!playerBestPosition || chartData.position < playerBestPosition) {
              playerBestPosition = chartData.position;
              playerBestSong = song;
            }
          }
        }
        
        if (!playerBestPosition || playerBestPosition > 20) continue;
        
        // Find rivals (artists ranked just above)
        const rivalPosition = playerBestPosition - 1;
        const rival = rankings.find(r => r.position === rivalPosition);
        
        if (rival && rival.artistId !== playerId) {
          // Check if rival overtook player this week
          const playerChartData = positionMap.get(playerBestSong.id);
          const rivalMovement = rival.movement || 0;
          
          if (rivalMovement > 0 && playerChartData.lastWeekPosition &&
              playerChartData.lastWeekPosition < rival.lastWeekPosition) {
            // Rival overtook player
            const rivalDoc = await db.collection('players').doc(rival.artistId).get();
            const rivalName = rivalDoc.exists ? rivalDoc.data().displayName : 'Another artist';
            
            await sendPushNotification(
              playerId,
              '⚠️ You\'ve Been Overtaken!',
              `${rivalName} just passed you on the charts! They're now at #${rivalPosition}.`,
              {
                type: 'rival_overtake',
                rivalId: rival.artistId,
                rivalName: rivalName,
                rivalPosition: rivalPosition,
                yourPosition: playerBestPosition,
                songTitle: playerBestSong.title,
              }
            );
          }
        }
      }
      
      console.log('✅ Rival chart checks complete');
    } catch (error) {
      console.error('❌ Error checking rival positions:', error);
    }
  });

/**
 * Sync player totalStreams from their artistStats
 * Call this to update all players' stream counts from their actual song data
 */
exports.syncAllPlayerStreams = onCall(async (request) => {
  const data = request.data;
  // Require admin access
  await validateAdminAccess(request);
  
  try {
    console.log('Starting player streams sync...');
    
    const playersSnapshot = await db.collection('players').get();
    let updated = 0;
    let errors = 0;
    
    for (const playerDoc of playersSnapshot.docs) {
      try {
        const playerId = playerDoc.id;
        const playerData = playerDoc.data();
        
        let totalStreams = 0;
        let songsPublished = 0;
        
        // Check if player has migrated to subcollections
        const migrated = playerData.migratedToSubcollections === true;
        
        if (migrated) {
          // Count streams from songs subcollection under players
          const songsSnapshot = await db.collection('players').doc(playerId).collection('songs').get();
          
          for (const songDoc of songsSnapshot.docs) {
            const song = songDoc.data();
            if (song.state === 'released') {
              totalStreams += song.streams || 0;
              songsPublished++;
            }
          }
        } else {
          // Count streams from songs array in player document
          const songs = playerData.songs || [];
          
          for (const song of songs) {
            if (song.state === 'released') {
              totalStreams += song.streams || 0;
              songsPublished++;
            }
          }
        }
        
        // Update player document
        await db.collection('players').doc(playerId).update({
          totalStreams: totalStreams,
          songsPublished: songsPublished,
          avatarUrl: playerData.avatarUrl || null,
          lastActivity: admin.firestore.FieldValue.serverTimestamp(),
        });
        
        updated++;
        console.log(`Updated ${playerId}: ${totalStreams} streams, ${songsPublished} songs`);
        
      } catch (err) {
        errors++;
        console.error(`Error updating player ${playerDoc.id}:`, err);
      }
    }
    
    console.log(`✅ Sync complete: ${updated} updated, ${errors} errors`);
    
    return {
      success: true,
      updated: updated,
      errors: errors,
      total: playersSnapshot.size,
    };
    
  } catch (error) {
    console.error('Error syncing player streams:', error);
    throw new HttpsError('internal', 'Failed to sync player streams');
  }
});

// ============================================================================
// NEXTUBE UPLOAD VALIDATION
// Server-side enforcement of upload rate limits and anti-abuse measures
// ============================================================================

/**
 * Server-side NexTube upload validation callable function
 * Enforces cooldown, daily limits, and duplicate title checks server-side
 * Returns {allowed: boolean, reason?: string}
 */
exports.validateNexTubeUpload = onCall(async (request) => {
  const data = request.data;
  // Authentication check
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'User must be authenticated');
  }

  const userId = request.auth.uid;
  const { title, songId, videoType } = data;

  // Validate required fields
  if (!title || !songId || !videoType) {
    throw new HttpsError('invalid-argument', 'Missing required fields');
  }

  // Get config from environment or use defaults
  const getEnvInt = (key, defaultValue) => {
    const val = process.env[key] || functions.config()[key];
    const parsed = parseInt(val, 10);
    return isFinite(parsed) ? parsed : defaultValue;
  };

  const getEnvDouble = (key, defaultValue) => {
    const val = process.env[key] || functions.config()[key];
    const parsed = parseFloat(val);
    return isFinite(parsed) ? parsed : defaultValue;
  };

  const COOLDOWN_MINUTES = getEnvInt('NEXTTUBE_COOLDOWN_MINUTES', 10);
  const DAILY_LIMIT = getEnvInt('NEXTTUBE_DAILY_LIMIT', 5);
  const DUPLICATE_WINDOW_DAYS = getEnvInt('NEXTTUBE_DUPLICATE_WINDOW_DAYS', 60);
  const SIMILARITY_THRESHOLD = getEnvDouble('NEXTTUBE_SIMILARITY_THRESHOLD', 0.92);

  try {
    const now = admin.firestore.Timestamp.now();
    const cooldownMs = COOLDOWN_MINUTES * 60 * 1000;
    const dailyMs = 24 * 60 * 60 * 1000;
    const duplicateMs = DUPLICATE_WINDOW_DAYS * 24 * 60 * 60 * 1000;

    const videosRef = db.collection('nexttube_videos');

    // Check cooldown
    const cooldownCutoff = admin.firestore.Timestamp.fromMillis(now.toMillis() - cooldownMs);
    const recentSnap = await videosRef
      .where('ownerId', '==', userId)
      .where('createdAt', '>=', cooldownCutoff)
      .limit(1)
      .get();

    if (!recentSnap.empty) {
      return {
        allowed: false,
        reason: `Please wait ${COOLDOWN_MINUTES} minutes between uploads`,
      };
    }

    // Check daily limit
    const dailyCutoff = admin.firestore.Timestamp.fromMillis(now.toMillis() - dailyMs);
    const dailySnap = await videosRef
      .where('ownerId', '==', userId)
      .where('createdAt', '>=', dailyCutoff)
      .limit(DAILY_LIMIT + 1)
      .get();

    if (dailySnap.size >= DAILY_LIMIT) {
      return {
        allowed: false,
        reason: `Daily upload limit reached (${DAILY_LIMIT} per day)`,
      };
    }

    // Check for official video duplicate (one per song)
    if (videoType === 'official') {
      const officialSnap = await videosRef
        .where('ownerId', '==', userId)
        .where('songId', '==', songId)
        .where('type', '==', 'official')
        .limit(1)
        .get();

      if (!officialSnap.empty) {
        return {
          allowed: false,
          reason: 'Song already has an official video',
        };
      }
    }

    // Check same song/type recently
    const duplicateCutoff = admin.firestore.Timestamp.fromMillis(now.toMillis() - duplicateMs);
    const songTypeSnap = await videosRef
      .where('ownerId', '==', userId)
      .where('songId', '==', songId)
      .where('type', '==', videoType)
      .where('createdAt', '>=', duplicateCutoff)
      .limit(1)
      .get();

    if (!songTypeSnap.empty) {
      return {
        allowed: false,
        reason: `You already uploaded a ${videoType} video for this song recently`,
      };
    }

    // Helper: normalize title
    const normalizeTitle = (str) => {
      return str
        .toLowerCase()
        .replace(/[^a-z0-9\s]/g, '')
        .replace(/\s+/g, ' ')
        .trim();
    };

    // Helper: Jaccard similarity
    const jaccardSimilarity = (a, b) => {
      const setA = new Set(a.split(' ').filter(w => w.length > 0));
      const setB = new Set(b.split(' ').filter(w => w.length > 0));
      if (setA.size === 0 && setB.size === 0) return 1.0;

      const intersection = new Set([...setA].filter(x => setB.has(x)));
      const union = new Set([...setA, ...setB]);

      return union.size === 0 ? 0.0 : intersection.size / union.size;
    };

    // Check title duplication
    const normalizedTitle = normalizeTitle(title);
    const titleSnap = await videosRef
      .where('ownerId', '==', userId)
      .where('normalizedTitle', '==', normalizedTitle)
      .where('createdAt', '>=', duplicateCutoff)
      .limit(1)
      .get();

    if (!titleSnap.empty) {
      return {
        allowed: false,
        reason: 'You already used a very similar title recently',
      };
    }

    // Check near-duplicate titles via similarity
    const recentTitlesSnap = await videosRef
      .where('ownerId', '==', userId)
      .where('createdAt', '>=', duplicateCutoff)
      .limit(100)
      .get();

    for (const doc of recentTitlesSnap.docs) {
      const existingTitle = doc.get('title') || '';
      const existingNorm = normalizeTitle(existingTitle);
      const similarity = jaccardSimilarity(normalizedTitle, existingNorm);
      if (similarity > SIMILARITY_THRESHOLD) {
        return {
          allowed: false,
          reason: 'Title looks like a near-duplicate of a recent upload',
        };
      }
    }

    // All checks passed
    return { allowed: true };

  } catch (error) {
    console.error('Error in validateNexTubeUpload:', error);
    throw new HttpsError('internal', 'Upload validation failed');
  }
});

// NEXTUBE SCHEDULED VIDEO RELEASE PROCESSING
// Runs every hour to check for scheduled videos that should be published
// Updates status from 'scheduled' to 'published' when releaseDate is reached
exports.processScheduledVideos = onSchedule({
  schedule: '50 * * * *', // Run at :50 every hour (10 mins before NexTube daily sim)
  timeZone: 'UTC',
  timeoutSeconds: 120,
  memory: '256MiB',
}, async (event) => {
  console.log('📅 Processing scheduled NexTube videos...');
  
  try {
    // Get current in-game date
    const currentGameDate = await getCurrentGameDateServer();
    console.log(`📅 Current game date: ${currentGameDate.toISOString().split('T')[0]}`);
    
    // Query for videos with status 'scheduled' and releaseDate <= currentGameDate
    const scheduledVideosSnapshot = await db.collection('nexttube_videos')
      .where('status', '==', 'scheduled')
      .get();
    
    if (scheduledVideosSnapshot.empty) {
      console.log('✅ No scheduled videos to process');
      return;
    }
    
    console.log(`📺 Found ${scheduledVideosSnapshot.size} scheduled videos to check`);
    
    let publishedCount = 0;
    const batch = db.batch();
    
    for (const doc of scheduledVideosSnapshot.docs) {
      const video = doc.data();
      const releaseDate = toDateSafe(video.releaseDate);
      
      if (!releaseDate) {
        console.warn(`⚠️ Scheduled video ${doc.id} missing releaseDate, publishing now`);
        batch.update(doc.ref, {
          status: 'published',
          releaseDate: admin.firestore.FieldValue.delete(),
        });
        publishedCount++;
        continue;
      }
      
      // Check if release date has passed (compare dates only, ignore time)
      const releaseDateOnly = new Date(releaseDate.getFullYear(), releaseDate.getMonth(), releaseDate.getDate());
      const currentDateOnly = new Date(currentGameDate.getFullYear(), currentGameDate.getMonth(), currentGameDate.getDate());
      
      if (currentDateOnly >= releaseDateOnly) {
        console.log(`✅ Publishing video: ${video.title} (scheduled for ${releaseDateOnly.toISOString().split('T')[0]})`);
        batch.update(doc.ref, {
          status: 'published',
        });
        publishedCount++;
      }
    }
    
    if (publishedCount > 0) {
      await batch.commit();
      console.log(`🎉 Published ${publishedCount} scheduled videos`);
    } else {
      console.log('✅ No videos ready to publish yet');
    }
    
  } catch (error) {
    console.error('❌ Error processing scheduled videos:', error);
    throw error;
  }
});

// NEXTUBE DAILY SIMULATION (v1 API)
// Runs every 60 minutes (1h == 1 in-game day).
// For each video, computes viewsToday based on owner stats, video type, novelty, and randomness.
// Updates dailyViews, totalViews, earningsTotal and credits player's money; also grows channel subscribers.
exports.updateNextTubeDaily = onSchedule({
  schedule: '55 * * * *', // Run at :55 every hour (5 minutes before dailyGameUpdate)
  timeZone: 'UTC',
  timeoutSeconds: 240,
  memory: '512MiB',
}, async (event) => {
  const db = admin.firestore();

    // Load Remote Config parameters if available; otherwise fall back to env or defaults
    let rc = {};
    try {
      if (admin.remoteConfig) {
        const tmpl = await admin.remoteConfig().getTemplate();
        rc = (tmpl && tmpl.parameters) ? tmpl.parameters : {};
      }
    } catch (e) {
      console.warn('Remote Config unavailable for updateNextTubeDaily, using defaults');
    }

    const numOr = (v, def) => {
      const n = Number(v);
      return Number.isFinite(n) ? n : def;
    };
    const getParam = (key, def) => {
      try {
        const rcVal = rc && rc[key] && rc[key].defaultValue && rc[key].defaultValue.value;
        return numOr(rcVal ?? process.env[key], def);
      } catch (e) {
        return def;
      }
    };

  const RPM_MIN = getParam('nexRPMMinCents', 60);
  const RPM_MAX = getParam('nexRPMMaxCents', 240);
    const FAME_MULT_CAP = getParam('nexFameMultCap', 2.0);
    const DAILY_VIEW_CAP = getParam('nexDailyViewCap', 200000);
    const SUBS_GAIN_CAP = getParam('nexSubsGainCap', 10000);
    const SUBS_MONETIZE_THRESHOLD = getParam('nexSubsMonetize', 1000);
    const TYPE_WEIGHT_OFFICIAL = getParam('nexWeightOfficial', 1.0);
    const TYPE_WEIGHT_LYRICS = getParam('nexWeightLyrics', 0.7);
    const TYPE_WEIGHT_LIVE = getParam('nexWeightLive', 0.5);
    const NOVELTY_HALF_LIFE_DAYS = getParam('nexNoveltyHalfLifeDays', 14);
  const NEX_QUALITY_COEF = getParam('nexQualityCoef', 0.01);
  const NEX_RPM_QUALITY_BIAS = getParam('nexRPMQualityBias', 0.002);
  const CERT_VIEWS_BOOST_PER_TIER = getParam('certNexViewsBoostPerTier', 0.03);
  const CERT_RPM_BOOST_PER_TIER = getParam('certNexRpmBoostPerTier', 0.005);

    const safeInt = (v, fb = 0) => {
      if (typeof v === 'number') return Math.floor(v);
      const p = parseInt(String(v ?? ''), 10);
      return Number.isFinite(p) ? p : fb;
    };
    const toDate = (v) => {
      if (!v) return new Date();
      if (v.toDate) return v.toDate();
      const d = new Date(String(v));
      return isNaN(d.getTime()) ? new Date() : d;
    };

    const pageSize = 250;
    let lastDoc = null;
    let processed = 0;

    while (true) {
      let query = db.collection('nexttube_videos')
        .where('status', '==', 'published') // Only process published videos
        .orderBy('createdAt')
        .limit(pageSize);
      if (lastDoc) query = query.startAfter(lastDoc);
      const snap = await query.get();
      if (snap.empty) break;

      const batch = db.batch();

      for (const doc of snap.docs) {
        const data = doc.data() || {};
        const ownerId = String(data.ownerId || '');
        if (!ownerId) continue;

        const playerRef = db.collection('players').doc(ownerId);
        const playerSnap = await playerRef.get();
        const player = playerSnap.exists ? (playerSnap.data() || {}) : {};

        const channelRef = playerRef.collection('nexTubeChannel').doc('main');
        const channelSnap = await channelRef.get();
        const channel = channelSnap.exists ? (channelSnap.data() || {}) : {};

        const fanbase = safeInt(player.fanbase, 100);
        const loyalFanbase = safeInt(player.loyalFanbase, 0);
        const fame = safeInt(player.currentFame, 0);
        const createdAt = toDate(data.createdAt);
        const type = String(data.type || 'official');

        const channelSubs = safeInt(channel.subscribers, 0);
        const channelMonetized = channel.isMonetized === true || channelSubs >= SUBS_MONETIZE_THRESHOLD;
        const channelRpm = safeInt(channel.rpmCents, 250);
        const isMonetized = channelMonetized || data.isMonetized === true;
        const rpmCentsRaw = channelMonetized ? channelRpm : safeInt(data.rpmCents, 200);
        // Apply small RPM quality bias based on song quality (if known)
        let rpmCents = rpmCentsRaw;
        try {
          const songs = Array.isArray(player.songs) ? player.songs : [];
          const songId = String(data.songId || '');
          if (songId) {
            const s = songs.find((x) => (x && (x.id || '').toString() === songId));
            if (s) {
              let q = Number(s.quality) || 50;
              if (Number.isFinite(s.recordingQuality)) {
                const rq = Number(s.recordingQuality);
                if (Number.isFinite(rq)) q = Math.round(((Number(s.quality) || 50) + rq) / 2);
              }
              const rpmBias = Math.max(0.8, Math.min(1.2, 1 + ((q - 50) * NEX_RPM_QUALITY_BIAS)));
              // Certification RPM boost (small)
              const certLevel = Math.max(0, Number(s.certificationLevel || 0));
              const certRpmMult = 1 + Math.max(0, Math.min(0.25, CERT_RPM_BOOST_PER_TIER * certLevel));
              rpmCents = Math.round(rpmCentsRaw * rpmBias * certRpmMult);
            }
          }
        } catch (e) {
          // ignore quality bias if anything goes wrong
        }
        rpmCents = Math.max(RPM_MIN, Math.min(RPM_MAX, rpmCents));

        const ageDays = Math.max(0, Math.floor((Date.now() - createdAt.getTime()) / 86400000));

        let base = fanbase * 0.5 + loyalFanbase * 2;
        const fameMult = 1 + Math.min(FAME_MULT_CAP, fame / 300);
        const typeWeight = type === 'official' ? TYPE_WEIGHT_OFFICIAL : (type === 'lyrics' ? TYPE_WEIGHT_LYRICS : TYPE_WEIGHT_LIVE);
        const novelty = Math.pow(0.5, ageDays / Math.max(1, NOVELTY_HALF_LIFE_DAYS));
        const rand = 0.8 + Math.random() * 0.4;
        const cap = Math.max(300, Math.min(DAILY_VIEW_CAP, Math.floor(fanbase * 3)));

        // Apply small views quality multiplier if we can resolve the song
        let qualityViewsMult = 1.0;
        try {
          const songs = Array.isArray(player.songs) ? player.songs : [];
          const songId = String(data.songId || '');
          if (songId) {
            const s = songs.find((x) => (x && (x.id || '').toString() === songId));
            if (s) {
              let q = Number(s.quality) || 50;
              if (Number.isFinite(s.recordingQuality)) {
                const rq = Number(s.recordingQuality);
                if (Number.isFinite(rq)) q = Math.round(((Number(s.quality) || 50) + rq) / 2);
              }
              const qualMult = Math.max(0.5, Math.min(1.5, 1 + ((q - 50) * NEX_QUALITY_COEF)));
              const certLevel = Math.max(0, Number(s.certificationLevel || 0));
              const certViewsMult = 1 + Math.max(0, Math.min(0.5, CERT_VIEWS_BOOST_PER_TIER * certLevel));
              qualityViewsMult = qualMult * certViewsMult;
            }
          }
        } catch (e) {
          // ignore quality multiplier on error
        }

        let viewsToday = Math.floor(base * fameMult * typeWeight * novelty * rand * qualityViewsMult);
        if (!Number.isFinite(viewsToday) || viewsToday < 0) viewsToday = 0;
        viewsToday = Math.max(0, Math.min(cap, viewsToday));

        const earningsCents = isMonetized ? Math.floor((rpmCents * viewsToday) / 1000) : 0;

        batch.update(doc.ref, {
          dailyViews: viewsToday,
          totalViews: admin.firestore.FieldValue.increment(viewsToday),
          earningsTotal: admin.firestore.FieldValue.increment(earningsCents),
          updatedAt: admin.firestore.Timestamp.now(),
        });

        if (earningsCents > 0) {
          const dollars = Math.floor(earningsCents / 100);
          if (dollars > 0) {
            batch.update(playerRef, {
              currentMoney: admin.firestore.FieldValue.increment(dollars),
            });
          }
        }

        const subBase = fanbase * 0.002 + loyalFanbase * 0.01;
        const subFameMult = 1 + Math.min(1.5, fame / 400);
        const subRand = 0.8 + Math.random() * 0.4;
        let subsGain = Math.floor(subBase * subFameMult * subRand);
        subsGain = Math.max(0, Math.min(SUBS_GAIN_CAP, subsGain));

        const channelUpdate = {
          ownerId,
          last28DaysViews: admin.firestore.FieldValue.increment(viewsToday),
          isMonetized: channelMonetized,
          rpmCents: channelRpm,
          updatedAt: admin.firestore.Timestamp.now(),
        };
        if (subsGain > 0) {
          channelUpdate.isMonetized = channelMonetized || (channelSubs + subsGain >= SUBS_MONETIZE_THRESHOLD);
          channelUpdate.subscribers = admin.firestore.FieldValue.increment(subsGain);
        }
        batch.set(channelRef, channelUpdate, { merge: true });

        processed++;
      }

      await batch.commit();
      lastDoc = snap.docs[snap.docs.length - 1];
      if (snap.size < pageSize) break;
    }

    console.log(`NexTube daily simulation finished. Processed videos=${processed}`);
    return null;
  });

// Manual test trigger: simulate one NexTube day for the authenticated user
// Usage (client): FirebaseFunctions.instance.httpsCallable('runNextTubeNow').call({})
exports.runNextTubeNow = onCall({
  timeoutSeconds: 120,
  memory: '512MiB',
}, async (request) => {
  const userId = request.auth && request.auth.uid;
  if (!userId) {
    throw new HttpsError('unauthenticated', 'User must be authenticated');
  }

  const db = admin.firestore();
    let rc = {};
    try {
      if (admin.remoteConfig) {
        const tmpl = await admin.remoteConfig().getTemplate();
        rc = (tmpl && tmpl.parameters) ? tmpl.parameters : {};
      }
    } catch (e) {
      console.warn('Remote Config unavailable for runNextTubeNow, using defaults');
    }

    const numOr = (v, def) => {
      const n = Number(v);
      return Number.isFinite(n) ? n : def;
    };
    const getParam = (key, def) => {
      try {
        const rcVal = rc && rc[key] && rc[key].defaultValue && rc[key].defaultValue.value;
        return numOr(rcVal ?? process.env[key], def);
      } catch (e) {
        return def;
      }
    };

  const RPM_MIN = getParam('nexRPMMinCents', 60);
  const RPM_MAX = getParam('nexRPMMaxCents', 240);
    const FAME_MULT_CAP = getParam('nexFameMultCap', 2.0);
    const DAILY_VIEW_CAP = getParam('nexDailyViewCap', 200000);
    const SUBS_GAIN_CAP = getParam('nexSubsGainCap', 10000);
    const SUBS_MONETIZE_THRESHOLD = getParam('nexSubsMonetize', 1000);
    const TYPE_WEIGHT_OFFICIAL = getParam('nexWeightOfficial', 1.0);
    const TYPE_WEIGHT_LYRICS = getParam('nexWeightLyrics', 0.7);
    const TYPE_WEIGHT_LIVE = getParam('nexWeightLive', 0.5);
    const NOVELTY_HALF_LIFE_DAYS = getParam('nexNoveltyHalfLifeDays', 14);
  const NEX_QUALITY_COEF = getParam('nexQualityCoef', 0.01);
  const NEX_RPM_QUALITY_BIAS = getParam('nexRPMQualityBias', 0.002);

    const safeInt = (v, fb = 0) => {
      if (typeof v === 'number') return Math.floor(v);
      const p = parseInt(String(v ?? ''), 10);
      return Number.isFinite(p) ? p : fb;
    };
    const toDate = (v) => {
      if (!v) return new Date();
      if (v.toDate) return v.toDate();
      const d = new Date(String(v));
      return isNaN(d.getTime()) ? new Date() : d;
    };

    // Fetch only this user's published videos
    const snap = await db
      .collection('nexttube_videos')
      .where('ownerId', '==', userId)
      .where('status', '==', 'published')
      .orderBy('createdAt')
      .limit(500)
      .get();

    if (snap.empty) {
      return { processed: 0, message: 'No published videos for this user' };
    }

    const batch = db.batch();
    let processed = 0;
    let totalViewsAdded = 0;
    let totalEarningsCents = 0;
    let totalSubs = 0;

    // Load player + channel once
    const playerRef = db.collection('players').doc(userId);
    const playerSnap = await playerRef.get();
    const player = playerSnap.exists ? (playerSnap.data() || {}) : {};

    const channelRef = playerRef.collection('nexTubeChannel').doc('main');
    const channelSnap = await channelRef.get();
    const channel = channelSnap.exists ? (channelSnap.data() || {}) : {};

    const fanbase = safeInt(player.fanbase, 100);
    const loyalFanbase = safeInt(player.loyalFanbase, 0);
    const fame = safeInt(player.currentFame, 0);

    const channelSubs = safeInt(channel.subscribers, 0);
    const channelMonetized = channel.isMonetized === true || channelSubs >= SUBS_MONETIZE_THRESHOLD;
    const channelRpm = safeInt(channel.rpmCents, 250);

    for (const doc of snap.docs) {
      const data = doc.data() || {};
      const createdAt = toDate(data.createdAt);
      const type = String(data.type || 'official');

      const isMonetized = channelMonetized || data.isMonetized === true;
      const rpmCentsRaw = channelMonetized ? channelRpm : safeInt(data.rpmCents, 200);
      let rpmCents = rpmCentsRaw;
      try {
        const songs = Array.isArray(player.songs) ? player.songs : [];
        const songId = String(data.songId || '');
        if (songId) {
          const s = songs.find((x) => (x && (x.id || '').toString() === songId));
          if (s) {
            let q = Number(s.quality) || 50;
            if (Number.isFinite(s.recordingQuality)) {
              const rq = Number(s.recordingQuality);
              if (Number.isFinite(rq)) q = Math.round(((Number(s.quality) || 50) + rq) / 2);
            }
            const rpmBias = Math.max(0.8, Math.min(1.2, 1 + ((q - 50) * NEX_RPM_QUALITY_BIAS)));
            const certLevel = Math.max(0, Number(s.certificationLevel || 0));
            const certRpmMult = 1 + Math.max(0, Math.min(0.25, CERT_RPM_BOOST_PER_TIER * certLevel));
            rpmCents = Math.round(rpmCentsRaw * rpmBias * certRpmMult);
          }
        }
      } catch (e) {}
      rpmCents = Math.max(RPM_MIN, Math.min(RPM_MAX, rpmCents));

      const ageDays = Math.max(0, Math.floor((Date.now() - createdAt.getTime()) / 86400000));

      let base = fanbase * 0.5 + loyalFanbase * 2;
      const fameMult = 1 + Math.min(FAME_MULT_CAP, fame / 300);
      const typeWeight = type === 'official' ? TYPE_WEIGHT_OFFICIAL : (type === 'lyrics' ? TYPE_WEIGHT_LYRICS : TYPE_WEIGHT_LIVE);
      const novelty = Math.pow(0.5, ageDays / Math.max(1, NOVELTY_HALF_LIFE_DAYS));
      const rand = 0.8 + Math.random() * 0.4;
      const cap = Math.max(300, Math.min(DAILY_VIEW_CAP, Math.floor(fanbase * 3)));

      let qualityViewsMult = 1.0;
      try {
        const songs = Array.isArray(player.songs) ? player.songs : [];
        const songId = String(data.songId || '');
        if (songId) {
          const s = songs.find((x) => (x && (x.id || '').toString() === songId));
          if (s) {
            let q = Number(s.quality) || 50;
            if (Number.isFinite(s.recordingQuality)) {
              const rq = Number(s.recordingQuality);
              if (Number.isFinite(rq)) q = Math.round(((Number(s.quality) || 50) + rq) / 2);
            }
            const qualMult = Math.max(0.5, Math.min(1.5, 1 + ((q - 50) * NEX_QUALITY_COEF)));
            const certLevel = Math.max(0, Number(s.certificationLevel || 0));
            const certViewsMult = 1 + Math.max(0, Math.min(0.5, CERT_VIEWS_BOOST_PER_TIER * certLevel));
            qualityViewsMult = qualMult * certViewsMult;
          }
        }
      } catch (e) {}
      let viewsToday = Math.floor(base * fameMult * typeWeight * novelty * rand * qualityViewsMult);
      if (!Number.isFinite(viewsToday) || viewsToday < 0) viewsToday = 0;
      viewsToday = Math.max(0, Math.min(cap, viewsToday));

      const earningsCents = isMonetized ? Math.floor((rpmCents * viewsToday) / 1000) : 0;

      batch.update(doc.ref, {
        dailyViews: viewsToday,
        totalViews: admin.firestore.FieldValue.increment(viewsToday),
        earningsTotal: admin.firestore.FieldValue.increment(earningsCents),
        updatedAt: admin.firestore.Timestamp.now(),
      });

      totalViewsAdded += viewsToday;
      totalEarningsCents += earningsCents;
      processed++;
    }

    // Subscriber growth for this owner (single update)
    const subBase = fanbase * 0.002 + loyalFanbase * 0.01;
    const subFameMult = 1 + Math.min(1.5, fame / 400);
    const subRand = 0.8 + Math.random() * 0.4;
    let subsGain = Math.floor(subBase * subFameMult * subRand);
    subsGain = Math.max(0, Math.min(SUBS_GAIN_CAP, subsGain));
    totalSubs = subsGain;

    const channelUpdate = {
      ownerId: userId,
      last28DaysViews: admin.firestore.FieldValue.increment(totalViewsAdded),
      isMonetized: channelMonetized,
      rpmCents: channelRpm,
      updatedAt: admin.firestore.Timestamp.now(),
    };
    if (subsGain > 0) {
      channelUpdate.isMonetized = channelMonetized || (channelSubs + subsGain >= SUBS_MONETIZE_THRESHOLD);
      channelUpdate.subscribers = admin.firestore.FieldValue.increment(subsGain);
    }
    batch.set(channelRef, channelUpdate, { merge: true });

    // Credit money if earnings
    const dollars = Math.floor(totalEarningsCents / 100);
    if (dollars > 0) {
      batch.update(playerRef, {
        currentMoney: admin.firestore.FieldValue.increment(dollars),
      });
    }

    await batch.commit();

    return {
      processed,
      totalViewsAdded,
      totalEarningsCents,
      subscribersAdded: totalSubs,
      message: 'NexTube day simulated for your account',
    };
  });

// ===== Certifications: Album eligibility listing (manual submit flow) =====
exports.listAlbumCertificationEligibility = onCall(async (request) => {
  const data = request.data;
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'Must be authenticated');
  }

  const playerId = request.auth.uid;
  // Load RC for thresholds
  let rc = {};
  try {
    if (admin.remoteConfig) {
      const tmpl = await admin.remoteConfig().getTemplate();
      rc = (tmpl && tmpl.parameters) ? tmpl.parameters : {};
    }
  } catch (e) { /* ignore */ }
  const numOr = (v, def) => { const n = Number(v); return Number.isFinite(n) ? n : def; };
  const getParam = (key, def) => {
    try { const rcVal = rc && rc[key] && rc[key].defaultValue && rc[key].defaultValue.value; return numOr(rcVal ?? process.env[key], def);} catch { return def; }
  };
  const enabled = (rc && rc['certEnabled'] && rc['certEnabled'].defaultValue && String(rc['certEnabled'].defaultValue.value) === 'true') || (process.env.certEnabled === 'true');
  const streamsPerUnit = getParam('certStreamsPerUnit', 150);
  const thresholds = {
    silver: getParam('certSilverUnits', 50000),
    gold: getParam('certGoldUnits', 100000),
    platinum: getParam('certPlatinumUnits', 250000),
    diamond: getParam('certDiamondUnits', 1000000),
    multiStep: getParam('certMultiPlatinumStepUnits', 250000),
  };
  if (!enabled) return { enabled: false, albums: [] };

  const playerRef = db.collection('players').doc(playerId);
  const snap = await playerRef.get();
  if (!snap.exists) throw new HttpsError('not-found', 'Player not found');
  const player = snap.data() || {};
  const albums = Array.isArray(player.albums) ? player.albums : [];

  const determine = (units) => {
    if (units >= thresholds.diamond) return { tier: 'diamond', level: 1 };
    if (units >= thresholds.platinum) {
      const extra = Math.max(0, Math.floor((units - thresholds.platinum) / Math.max(1, thresholds.multiStep)));
      const level = 1 + extra; return level > 1 ? { tier: 'multi_platinum', level } : { tier: 'platinum', level: 1 };
    }
    if (units >= thresholds.gold) return { tier: 'gold', level: 1 };
    if (units >= thresholds.silver) return { tier: 'silver', level: 1 };
    return { tier: 'none', level: 0 };
  };

  const results = [];
  for (const a of albums) {
    if (!a || a.state !== 'released') continue;
    const totalStreams = Number(a.totalStreams || 0);
    const sales = Number(a.totalSales || 0);
    const units = Math.floor(totalStreams / Math.max(1, streamsPerUnit)) + Math.floor(sales);
    const currentTier = String(a.highestCertification || 'none');
    const currentLevel = Number(a.certificationLevel || 0);
    const next = determine(units);
    const order = { none: 0, silver: 1, gold: 2, platinum: 3, multi_platinum: 4, diamond: 5 };
    const curRank = (order[currentTier] ?? 0) * 100 + currentLevel;
    const nextRank = (order[next.tier] ?? 0) * 100 + next.level;
    const eligibleNow = nextRank > curRank && next.tier !== 'none';
    results.push({
      id: a.id || a.albumId || '',
      title: a.title || 'Untitled',
      units,
      currentTier,
      currentLevel,
      nextTier: next.tier,
      nextLevel: next.level,
      eligibleNow,
    });
  }

  return { enabled: true, albums: results };
});

// ===== Certifications: Manual submit for Album certification =====
exports.submitAlbumForCertification = onCall(async (request) => {
  const data = request.data;
  if (!request.auth) throw new HttpsError('unauthenticated', 'Must be authenticated');
  const playerId = request.auth.uid;
  const albumId = String((data && data.albumId) || '');
  if (!albumId) throw new HttpsError('invalid-argument', 'albumId required');

  // RC
  let rc = {};
  try { if (admin.remoteConfig) { const tmpl = await admin.remoteConfig().getTemplate(); rc = (tmpl && tmpl.parameters) ? tmpl.parameters : {}; } } catch {}
  const numOr = (v, def) => { const n = Number(v); return Number.isFinite(n) ? n : def; };
  const boolOr = (v, def) => { if (typeof v === 'boolean') return v; if (v === 'true') return true; if (v === 'false') return false; return def; };
  const getParam = (key, def, type='number') => { try { const rcVal = rc && rc[key] && rc[key].defaultValue && rc[key].defaultValue.value; return type==='bool' ? boolOr(rcVal ?? process.env[key], def) : numOr(rcVal ?? process.env[key], def);} catch { return def; } };
  const enabled = getParam('certEnabled', true, 'bool');
  if (!enabled) throw new HttpsError('failed-precondition', 'Certifications disabled');
  const streamsPerUnit = getParam('certStreamsPerUnit', 150);
  const thresholds = { silver: getParam('certSilverUnits', 50000), gold: getParam('certGoldUnits', 100000), platinum: getParam('certPlatinumUnits', 250000), diamond: getParam('certDiamondUnits', 1000000), multiStep: getParam('certMultiPlatinumStepUnits', 250000) };
  const rewards = { money: getParam('certAlbumRewardMoney', 10000), fame: getParam('certAlbumRewardFame', 10) };

  const playerRef = db.collection('players').doc(playerId);
  const snap = await playerRef.get();
  if (!snap.exists) throw new HttpsError('not-found', 'Player not found');
  const player = snap.data() || {};
  const albums = Array.isArray(player.albums) ? player.albums : [];
  const idx = albums.findIndex((x) => x && (String(x.id || x.albumId || '') === albumId));
  if (idx < 0) throw new HttpsError('not-found', 'Album not found');
  const a = albums[idx];
  if (a.state !== 'released') throw new HttpsError('failed-precondition', 'Album not released');

  const totalStreams = Number(a.totalStreams || 0);
  const sales = Number(a.totalSales || 0);
  const units = Math.floor(totalStreams / Math.max(1, streamsPerUnit)) + Math.floor(sales);
  const determine = (u) => {
    if (u >= thresholds.diamond) return { tier: 'diamond', level: 1 };
    if (u >= thresholds.platinum) { const extra = Math.max(0, Math.floor((u - thresholds.platinum)/Math.max(1, thresholds.multiStep))); const level = 1 + extra; return level>1 ? { tier:'multi_platinum', level } : { tier:'platinum', level:1}; }
    if (u >= thresholds.gold) return { tier: 'gold', level: 1 };
    if (u >= thresholds.silver) return { tier: 'silver', level: 1 };
    return { tier: 'none', level: 0 };
  };
  const curTier = String(a.highestCertification || 'none');
  const curLevel = Number(a.certificationLevel || 0);
  const next = determine(units);
  const order = { none: 0, silver: 1, gold: 2, platinum: 3, multi_platinum: 4, diamond: 5 };
  const curRank = (order[curTier] ?? 0) * 100 + curLevel;
  const nextRank = (order[next.tier] ?? 0) * 100 + next.level;
  if (!(nextRank > curRank) || next.tier === 'none') {
    return { awarded: false, message: 'Not eligible for next certification tier yet', units, currentTier: curTier, currentLevel: curLevel };
  }

  // Apply updates
  albums[idx] = {
    ...a,
    eligibleUnits: units,
    highestCertification: next.tier,
    certificationLevel: next.level,
    lastCertifiedAt: admin.firestore.Timestamp.now(),
  };

  const batch = db.batch();
  batch.update(playerRef, {
    albums,
    currentMoney: admin.firestore.FieldValue.increment(Math.floor(rewards.money || 0)),
    fame: admin.firestore.FieldValue.increment(Math.floor(rewards.fame || 0)),
    lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
  });
  const certsRef = playerRef.collection('certifications').doc();
  batch.set(certsRef, {
    itemType: 'album',
    itemId: albumId,
    title: a.title || 'Untitled',
    tier: next.tier,
    level: next.level,
    units,
    createdAt: admin.firestore.Timestamp.now(),
  });
  const notificationsRef = playerRef.collection('notifications').doc();
  batch.set(notificationsRef, {
    type: 'certification_awarded',
    title: '🏅 Album Certified',
    message: `${a.title || 'Untitled'} is now ${next.tier.replace('_', ' ')}${next.level>1 ? ' x'+next.level : ''}!`,
    itemType: 'album',
    itemId: albumId,
    tier: next.tier,
    level: next.level,
    units,
    read: false,
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
  });

  await batch.commit();
  return { awarded: true, tier: next.tier, level: next.level, units };
});

// ===== Certifications: Admin migration for a single player (retroactive) =====
exports.runCertificationsMigrationAdmin = onCall(async (request) => {
  const data = request.data;
  await validateAdminAccess(request);
  const targetPlayerId = String((data && data.playerId) || '');
  if (!targetPlayerId) throw new HttpsError('invalid-argument', 'playerId required');

  // RC config
  let rc = {};
  try { if (admin.remoteConfig) { const tmpl = await admin.remoteConfig().getTemplate(); rc = (tmpl && tmpl.parameters) ? tmpl.parameters : {}; } } catch {}
  const numOr = (v, def) => { const n = Number(v); return Number.isFinite(n) ? n : def; };
  const boolOr = (v, def) => { if (typeof v === 'boolean') return v; if (v === 'true') return true; if (v === 'false') return false; return def; };
  const getParam = (key, def, type='number') => { try { const rcVal = rc && rc[key] && rc[key].defaultValue && rc[key].defaultValue.value; return type==='bool' ? boolOr(rcVal ?? process.env[key], def) : numOr(rcVal ?? process.env[key], def);} catch { return def; } };
  const enabled = getParam('certEnabled', true, 'bool');
  if (!enabled) throw new HttpsError('failed-precondition', 'Certifications disabled');
  const streamsPerUnit = getParam('certStreamsPerUnit', 150);
  const thresholds = { silver: getParam('certSilverUnits', 50000), gold: getParam('certGoldUnits', 100000), platinum: getParam('certPlatinumUnits', 250000), diamond: getParam('certDiamondUnits', 1000000), multiStep: getParam('certMultiPlatinumStepUnits', 250000) };
  const rewards = { songMoney: getParam('certSongRewardMoney', 5000), songFame: getParam('certSongRewardFame', 5) };

  const playerRef = db.collection('players').doc(targetPlayerId);
  const doc = await playerRef.get();
  if (!doc.exists) throw new HttpsError('not-found', 'Player not found');
  const player = doc.data() || {};
  const songs = Array.isArray(player.songs) ? player.songs : [];
  const determine = (u) => {
    if (u >= thresholds.diamond) return { tier: 'diamond', level: 1 };
    if (u >= thresholds.platinum) { const extra = Math.max(0, Math.floor((u - thresholds.platinum)/Math.max(1, thresholds.multiStep))); const level = 1 + extra; return level>1 ? { tier:'multi_platinum', level } : { tier:'platinum', level:1}; }
    if (u >= thresholds.gold) return { tier: 'gold', level: 1 };
    if (u >= thresholds.silver) return { tier: 'silver', level: 1 };
    return { tier: 'none', level: 0 };
  };

  let changed = 0; let awarded = 0; let extraMoney = 0; let extraFame = 0;
  const updatesSongs = [];
  const batch = db.batch();
  const certsRef = playerRef.collection('certifications');
  const notificationsRef = playerRef.collection('notifications');

  for (const s of songs) {
    if (!s || s.state !== 'released') { updatesSongs.push(s); continue; }
    const streams = Number(s.streams || 0);
    const sales = Number(s.totalSales || 0);
    const units = Math.floor(streams / Math.max(1, streamsPerUnit)) + Math.floor(sales);
    const next = determine(units);
    const prevTier = String(s.highestCertification || 'none');
    const prevLevel = Number(s.certificationLevel || 0);
    const order = { none: 0, silver: 1, gold: 2, platinum: 3, multi_platinum: 4, diamond: 5 };
    const prevRank = (order[prevTier] ?? 0) * 100 + prevLevel;
    const nextRank = (order[next.tier] ?? 0) * 100 + next.level;
    const improved = nextRank > prevRank && next.tier !== 'none';

    const updated = { ...s, eligibleUnits: units, highestCertification: next.tier, certificationLevel: next.level, lastCertifiedAt: admin.firestore.Timestamp.now() };
    updatesSongs.push(updated);
    if (improved) {
      awarded++;
      extraMoney += rewards.songMoney || 0;
      extraFame += rewards.songFame || 0;
      batch.set(certsRef.doc(), {
        itemType: 'song', itemId: String(s.id || s.songId || ''), title: s.title || 'Untitled', tier: next.tier, level: next.level, units,
        createdAt: admin.firestore.Timestamp.now(),
      });
      batch.set(notificationsRef.doc(), {
        type: 'certification_awarded', title: '🏅 Certification Awarded',
        message: `${s.title || 'Untitled'} is now ${next.tier.replace('_',' ')}${next.level>1 ? ' x'+next.level : ''}!`,
        itemType: 'song', itemId: String(s.id || s.songId || ''), tier: next.tier, level: next.level, units,
        read: false, timestamp: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
    changed++;
  }

  const playerUpdate = {
    songs: updatesSongs,
    lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
  };
  if (extraMoney > 0) playerUpdate.currentMoney = admin.firestore.FieldValue.increment(Math.floor(extraMoney));
  if (extraFame > 0) playerUpdate.fame = admin.firestore.FieldValue.increment(Math.floor(extraFame));

  batch.update(playerRef, playerUpdate);
  await batch.commit();

  // Summary notification
  try {
    await notificationsRef.add({
      type: 'system_info',
      title: 'Certifications Migration',
      message: `Updated ${changed} song(s), awarded ${awarded} certification(s).`,
      read: false,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });
  } catch {}

  return { migrated: true, changed, awarded };
});

// Admin-only: simulate one NexTube day for ALL players immediately
exports.runNextTubeForAllAdmin = onCall({
  timeoutSeconds: 300,
  memory: '1GiB',
}, async (request) => {
  await validateAdminAccess(request);

  const db = admin.firestore();
    let rc = {};
    try {
      if (admin.remoteConfig) {
        const tmpl = await admin.remoteConfig().getTemplate();
        rc = (tmpl && tmpl.parameters) ? tmpl.parameters : {};
      }
    } catch (e) {
      console.warn('Remote Config unavailable for runNextTubeForAllAdmin, using defaults');
    }

    const numOr = (v, def) => {
      const n = Number(v);
      return Number.isFinite(n) ? n : def;
    };
    const getParam = (key, def) => {
      try {
        const rcVal = rc && rc[key] && rc[key].defaultValue && rc[key].defaultValue.value;
        return numOr(rcVal ?? process.env[key], def);
      } catch (e) {
        return def;
      }
    };

    const RPM_MIN = getParam('nexRPMMinCents', 60);
    const RPM_MAX = getParam('nexRPMMaxCents', 240);
    const FAME_MULT_CAP = getParam('nexFameMultCap', 2.0);
    const DAILY_VIEW_CAP = getParam('nexDailyViewCap', 200000);
    const SUBS_GAIN_CAP = getParam('nexSubsGainCap', 10000);
    const SUBS_MONETIZE_THRESHOLD = getParam('nexSubsMonetize', 1000);
    const TYPE_WEIGHT_OFFICIAL = getParam('nexWeightOfficial', 1.0);
    const TYPE_WEIGHT_LYRICS = getParam('nexWeightLyrics', 0.7);
    const TYPE_WEIGHT_LIVE = getParam('nexWeightLive', 0.5);
    const NOVELTY_HALF_LIFE_DAYS = getParam('nexNoveltyHalfLifeDays', 14);

    const safeInt = (v, fb = 0) => {
      if (typeof v === 'number') return Math.floor(v);
      const p = parseInt(String(v ?? ''), 10);
      return Number.isFinite(p) ? p : fb;
    };
    const toDate = (v) => {
      if (!v) return new Date();
      if (v.toDate) return v.toDate();
      const d = new Date(String(v));
      return isNaN(d.getTime()) ? new Date() : d;
    };

    const pageSize = 250;
    let lastDoc = null;
    let processed = 0;
    let totalViewsAdded = 0;
    let totalEarningsCents = 0;
    let pages = 0;

    while (true) {
      let query = db.collection('nexttube_videos').orderBy('createdAt').limit(pageSize);
      if (lastDoc) query = query.startAfter(lastDoc);
      const snap = await query.get();
      if (snap.empty) break;

      const batch = db.batch();

      for (const doc of snap.docs) {
        const data = doc.data() || {};
        const ownerId = String(data.ownerId || '');
        if (!ownerId) continue;

        const playerRef = db.collection('players').doc(ownerId);
        const playerSnap = await playerRef.get();
        const player = playerSnap.exists ? (playerSnap.data() || {}) : {};

        const channelRef = playerRef.collection('nexTubeChannel').doc('main');
        const channelSnap = await channelRef.get();
        const channel = channelSnap.exists ? (channelSnap.data() || {}) : {};

        const fanbase = safeInt(player.fanbase, 100);
        const loyalFanbase = safeInt(player.loyalFanbase, 0);
        const fame = safeInt(player.currentFame, 0);
        const createdAt = toDate(data.createdAt);
        const type = String(data.type || 'official');

        const channelSubs = safeInt(channel.subscribers, 0);
        const channelMonetized = channel.isMonetized === true || channelSubs >= SUBS_MONETIZE_THRESHOLD;
        const channelRpm = safeInt(channel.rpmCents, 250);
        const isMonetized = channelMonetized || data.isMonetized === true;
        const rpmCentsRaw = channelMonetized ? channelRpm : safeInt(data.rpmCents, 200);
        let rpmCents = rpmCentsRaw;
        try {
          const songs = Array.isArray(player.songs) ? player.songs : [];
          const songId = String(data.songId || '');
          if (songId) {
            const s = songs.find((x) => (x && (x.id || '').toString() === songId));
            if (s) {
              let q = Number(s.quality) || 50;
              if (Number.isFinite(s.recordingQuality)) {
                const rq = Number(s.recordingQuality);
                if (Number.isFinite(rq)) q = Math.round(((Number(s.quality) || 50) + rq) / 2);
              }
              const rpmBias = Math.max(0.8, Math.min(1.2, 1 + ((q - 50) * NEX_RPM_QUALITY_BIAS)));
              rpmCents = Math.round(rpmCentsRaw * rpmBias);
            }
          }
        } catch (e) {}
        rpmCents = Math.max(RPM_MIN, Math.min(RPM_MAX, rpmCents));

        const ageDays = Math.max(0, Math.floor((Date.now() - createdAt.getTime()) / 86400000));

        let base = fanbase * 0.5 + loyalFanbase * 2;
        const fameMult = 1 + Math.min(FAME_MULT_CAP, fame / 300);
        const typeWeight = type === 'official' ? TYPE_WEIGHT_OFFICIAL : (type === 'lyrics' ? TYPE_WEIGHT_LYRICS : TYPE_WEIGHT_LIVE);
        const novelty = Math.pow(0.5, ageDays / Math.max(1, NOVELTY_HALF_LIFE_DAYS));
        const rand = 0.8 + Math.random() * 0.4;
        const cap = Math.max(300, Math.min(DAILY_VIEW_CAP, Math.floor(fanbase * 3)));

        let qualityViewsMult = 1.0;
        try {
          const songs = Array.isArray(player.songs) ? player.songs : [];
          const songId = String(data.songId || '');
          if (songId) {
            const s = songs.find((x) => (x && (x.id || '').toString() === songId));
            if (s) {
              let q = Number(s.quality) || 50;
              if (Number.isFinite(s.recordingQuality)) {
                const rq = Number(s.recordingQuality);
                if (Number.isFinite(rq)) q = Math.round(((Number(s.quality) || 50) + rq) / 2);
              }
              qualityViewsMult = Math.max(0.5, Math.min(1.5, 1 + ((q - 50) * NEX_QUALITY_COEF)));
            }
          }
        } catch (e) {}
        let viewsToday = Math.floor(base * fameMult * typeWeight * novelty * rand * qualityViewsMult);
        if (!Number.isFinite(viewsToday) || viewsToday < 0) viewsToday = 0;
        viewsToday = Math.max(0, Math.min(cap, viewsToday));

        const earningsCents = isMonetized ? Math.floor((rpmCents * viewsToday) / 1000) : 0;

        batch.update(doc.ref, {
          dailyViews: viewsToday,
          totalViews: admin.firestore.FieldValue.increment(viewsToday),
          earningsTotal: admin.firestore.FieldValue.increment(earningsCents),
          updatedAt: admin.firestore.Timestamp.now(),
        });

        // Credit dollars to player's balance if any
        const dollars = Math.floor(earningsCents / 100);
        if (dollars > 0) {
          batch.update(playerRef, {
            currentMoney: admin.firestore.FieldValue.increment(dollars),
          });
        }

        // Channel growth approximation per video iteration
        const subBase = fanbase * 0.002 + loyalFanbase * 0.01;
        const subFameMult = 1 + Math.min(1.5, fame / 400);
        const subRand = 0.8 + Math.random() * 0.4;
        let subsGain = Math.floor(subBase * subFameMult * subRand);
        subsGain = Math.max(0, Math.min(SUBS_GAIN_CAP, subsGain));

        const channelUpdate = {
          ownerId,
          last28DaysViews: admin.firestore.FieldValue.increment(viewsToday),
          isMonetized: channelMonetized,
          rpmCents: channelRpm,
          updatedAt: admin.firestore.Timestamp.now(),
        };
        if (subsGain > 0) {
          channelUpdate.isMonetized = channelMonetized || (channelSubs + subsGain >= SUBS_MONETIZE_THRESHOLD);
          channelUpdate.subscribers = admin.firestore.FieldValue.increment(subsGain);
        }
        batch.set(channelRef, channelUpdate, { merge: true });

        processed++;
        totalViewsAdded += viewsToday;
        totalEarningsCents += earningsCents;
      }

      await batch.commit();
      pages++;
      lastDoc = snap.docs[snap.docs.length - 1];
      if (snap.size < pageSize) break;
    }

    return {
      processed,
      totalViewsAdded,
      totalEarningsCents,
      pages,
      message: 'NexTube day simulated for all players (admin)'
    };
  });

