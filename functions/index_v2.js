// Firebase Cloud Functions for NextWave Music Sim v2.0
// Enhanced with weekly charts, leaderboards, achievements, and anti-cheat

const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

const db = admin.firestore();

// ============================================================================
// 1. DAILY UPDATE - Main game progression (Midnight UTC)
// ============================================================================

exports.dailyGameUpdate = functions.pubsub
  .schedule('0 0 * * *') // Every day at midnight UTC
  .timeZone('UTC')
  .onRun(async (context) => {
    console.log('🌅 Starting daily game update for all players...');
    
    try {
      // 1. Update global game date
      const gameTimeRef = db.collection('game_state').doc('global_time');
      const gameTimeDoc = await gameTimeRef.get();
      
      if (!gameTimeDoc.exists) {
        console.error('❌ Global game time not initialized');
        return null;
      }
      
      const currentGameDate = gameTimeDoc.data().currentGameDate.toDate();
      const newGameDate = new Date(currentGameDate);
      newGameDate.setDate(newGameDate.getDate() + 1);
      
      await gameTimeRef.update({
        currentGameDate: admin.firestore.Timestamp.fromDate(newGameDate),
        lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
      });
      
      console.log(`📅 Game date: ${currentGameDate.toISOString()} → ${newGameDate.toISOString()}`);
      
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
            newGameDate
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
// 2. WEEKLY LEADERBOARD UPDATE - Snapshots & historical tracking (Sunday 1 AM UTC)
// ============================================================================

exports.weeklyLeaderboardUpdate = functions.pubsub
  .schedule('0 1 * * 0') // Every Sunday at 1 AM UTC
  .timeZone('UTC')
  .onRun(async (context) => {
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

exports.checkAchievements = functions.firestore
  .document('players/{playerId}')
  .onUpdate(async (change, context) => {
    const playerId = context.params.playerId;
    const before = change.before.data();
    const after = change.after.data();
    
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

exports.validateSongRelease = functions.https.onCall(async (data, context) => {
  // Require authentication
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Must be authenticated');
  }
  
  const playerId = context.auth.uid;
  const { song, productionCost } = data;
  
  try {
    // Get player data
    const playerDoc = await db.collection('players').doc(playerId).get();
    if (!playerDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'Player not found');
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
    throw new functions.https.HttpsError('internal', error.message);
  }
});

// ============================================================================
// 5. SPECIAL EVENTS SYSTEM - Dynamic game events (Monday noon UTC)
// ============================================================================

exports.triggerSpecialEvent = functions.pubsub
  .schedule('0 12 * * 1') // Every Monday at noon UTC
  .timeZone('UTC')
  .onRun(async (context) => {
    console.log('🎪 Triggering weekly special event...');
    
    try {
      const events = [
        {
          id: 'viral_week',
          name: '🔥 Viral Week',
          description: 'All songs get 2x viral chance!',
          effect: { viralityMultiplier: 2.0 },
          duration: 7, // days
        },
        {
          id: 'album_week',
          name: '💿 Album Week',
          description: 'Albums earn 50% more streams!',
          effect: { albumBonus: 1.5 },
          duration: 7,
        },
        {
          id: 'regional_focus',
          name: '🌍 Regional Spotlight',
          description: 'Random region gets 2x streams!',
          effect: { 
            regionalBonus: 2.0,
            targetRegion: selectRandomRegion(),
          },
          duration: 7,
        },
        {
          id: 'new_artist_boost',
          name: '⭐ Rising Stars Week',
          description: 'Artists under 10K fans get 3x discovery!',
          effect: { newArtistBonus: 3.0 },
          duration: 7,
        },
        {
          id: 'chart_fever',
          name: '📊 Chart Fever',
          description: 'Top 10 songs get extra rewards!',
          effect: { chartBonusMultiplier: 1.5 },
          duration: 7,
        },
      ];
      
      // Select random event
      const event = events[Math.floor(Math.random() * events.length)];
      
      // Set active event
      await db.collection('game_state').doc('active_event').set({
        ...event,
        startDate: admin.firestore.FieldValue.serverTimestamp(),
        endDate: admin.firestore.Timestamp.fromDate(
          new Date(Date.now() + event.duration * 24 * 60 * 60 * 1000)
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

async function processDailyStreamsForPlayer(playerId, playerData, currentGameDate) {
  try {
    const songs = playerData.songs || [];
    if (songs.length === 0) return null;
    
    let totalNewStreams = 0;
    let totalNewIncome = 0;
    const updatedSongs = [];
    
    // Get active event bonuses
    const activeEvent = await getActiveEvent();
    
    // Process each song
    for (const song of songs) {
      if (song.state !== 'released' || !song.releasedDate) {
        updatedSongs.push(song);
        continue;
      }
      
      const releaseDate = song.releasedDate.toDate();
      if (releaseDate > currentGameDate) {
        updatedSongs.push(song);
        continue;
      }
      
      // Calculate base streams
      let dailyStreams = calculateDailyStreamGrowth(song, playerData, currentGameDate);
      
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
      
      updatedSongs.push(updatedSong);
      totalNewStreams += dailyStreams;
      totalNewIncome += songIncome;
    }
    
    // ✅ UPDATE REGIONAL FANBASE based on today's streams
    const updatedRegionalFanbase = calculateRegionalFanbaseGrowth(
      playerData.regionalFanbase || {},
      updatedSongs,
      playerData.homeRegion || 'usa'
    );
    
    if (totalNewStreams > 0) {
      return {
        songs: updatedSongs,
        currentMoney: (playerData.currentMoney || 0) + totalNewIncome,
        regionalFanbase: updatedRegionalFanbase, // ✅ UPDATE REGIONAL FANBASE
        lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
      };
    }
    
    return null;
  } catch (error) {
    console.error(`Error processing player ${playerId}:`, error);
    return null;
  }
}

function calculateDailyStreamGrowth(song, playerData, currentGameDate) {
  const releaseDate = song.releasedDate.toDate();
  const daysSinceRelease = Math.floor((currentGameDate - releaseDate) / (1000 * 60 * 60 * 24));
  
  const loyalFanbase = playerData.loyalFanbase || 0;
  const totalFanbase = playerData.level || 1;
  const songQuality = song.quality || 50;
  const viralityScore = song.viralityScore || 0.5;
  const ageCategory = getAgeCategory(daysSinceRelease);
  
  // Age-based discovery modifier
  const discoveryModifier = getDiscoveryModifier(ageCategory, daysSinceRelease);
  
  // Loyal fan streams
  const loyalStreams = Math.round(loyalFanbase * (0.5 + Math.random() * 1.5));
  
  // Discovery streams (with age decay)
  let discoveryStreams = 0;
  if (daysSinceRelease === 0) {
    discoveryStreams = Math.round(totalFanbase * 0.3 * (songQuality / 100) * (1.5 + Math.random()));
  } else if (daysSinceRelease <= 7) {
    discoveryStreams = Math.round(totalFanbase * 0.2 * viralityScore * (1.0 - daysSinceRelease / 7.0 * 0.4));
  } else if (daysSinceRelease <= 30) {
    discoveryStreams = Math.round(totalFanbase * 0.1 * viralityScore * (1.0 - (daysSinceRelease - 7) / 23.0 * 0.5));
  } else {
    discoveryStreams = Math.round(totalFanbase * 0.05 * viralityScore * discoveryModifier);
  }
  
  // Viral streams
  let viralStreams = 0;
  if (Math.random() < viralityScore * 0.1) {
    viralStreams = Math.round((song.streams || 0) * 0.05 * (2.0 + Math.random() * 5.0));
  }
  
  // Casual fan streams
  const casualFans = Math.max(0, totalFanbase - loyalFanbase);
  const engagementRate = (songQuality / 100.0) * 0.2;
  const casualStreams = Math.round(casualFans * engagementRate * (0.1 + Math.random() * 0.7));
  
  // Platform multipliers
  const platforms = song.streamingPlatforms || [];
  let platformMultiplier = 0;
  if (platforms.includes('tunify')) platformMultiplier += 0.85;
  if (platforms.includes('maple_music')) platformMultiplier += 0.65;
  if (platformMultiplier === 0) platformMultiplier = 0.5;
  
  const totalStreams = loyalStreams + discoveryStreams + viralStreams + casualStreams;
  const finalStreams = Math.round(totalStreams * platformMultiplier * (0.8 + Math.random() * 0.4));
  
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
function calculateRegionalFanbaseGrowth(currentFanbase, songs, homeRegion) {
  const updatedFanbase = { ...currentFanbase };
  
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
    const growth = Math.round(baseGrowth * diminishingFactor);
    
    // Home region gets 2x growth
    const finalGrowth = region === homeRegion ? growth * 2 : growth;
    
    updatedFanbase[region] = currentFans + finalGrowth;
  });
  
  return updatedFanbase;
}

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

// ✅ NEW: Apply event bonuses
async function getActiveEvent() {
  try {
    const eventDoc = await db.collection('game_state').doc('active_event').get();
    if (!eventDoc.exists) return null;
    
    const event = eventDoc.data();
    const now = new Date();
    const endDate = event.endDate.toDate();
    
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
      if ((playerData.level || 0) < 10000) {
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
    // Get top 100 songs by last7DaysStreams
    const songsSnapshot = await db.collection('players').get();
    const allSongs = [];
    
    songsSnapshot.forEach(playerDoc => {
      const playerData = playerDoc.data();
      const songs = playerData.songs || [];
      
      songs.forEach(song => {
        if (song.state === 'released') {
          allSongs.push({
            ...song,
            artistId: playerDoc.id,
            artistName: playerData.artistName || 'Unknown',
            last7DaysStreams: song.last7DaysStreams || 0,
          });
        }
      });
    });
    
    // Sort by last7DaysStreams
    allSongs.sort((a, b) => b.last7DaysStreams - a.last7DaysStreams);
    const top100 = allSongs.slice(0, 100);
    
    // Create snapshot document
    await db.collection('leaderboard_history').doc(`songs_${weekId}`).set({
      weekId,
      timestamp: admin.firestore.Timestamp.fromDate(timestamp),
      type: 'songs',
      rankings: top100.map((song, index) => ({
        rank: index + 1,
        title: song.title,
        artistId: song.artistId,
        artistName: song.artistName,
        streams: song.last7DaysStreams,
        totalStreams: song.streams,
        genre: song.genre,
      })),
    });
    
    console.log(`✅ Created song leaderboard snapshot for week ${weekId}`);
  } catch (error) {
    console.error('❌ Error creating song snapshot:', error);
  }
}

async function createArtistLeaderboardSnapshot(weekId, timestamp) {
  try {
    // Get all players and calculate total last7DaysStreams
    const playersSnapshot = await db.collection('players').get();
    const artists = [];
    
    playersSnapshot.forEach(playerDoc => {
      const playerData = playerDoc.data();
      const songs = playerData.songs || [];
      
      const totalWeeklyStreams = songs
        .filter(s => s.state === 'released')
        .reduce((sum, s) => sum + (s.last7DaysStreams || 0), 0);
      
      if (totalWeeklyStreams > 0) {
        artists.push({
          artistId: playerDoc.id,
          artistName: playerData.artistName || 'Unknown',
          weeklyStreams: totalWeeklyStreams,
          totalStreams: playerData.totalStreams || 0,
          fanbase: playerData.level || 0,
        });
      }
    });
    
    // Sort by weekly streams
    artists.sort((a, b) => b.weeklyStreams - a.weeklyStreams);
    const top50 = artists.slice(0, 50);
    
    // Create snapshot
    await db.collection('leaderboard_history').doc(`artists_${weekId}`).set({
      weekId,
      timestamp: admin.firestore.Timestamp.fromDate(timestamp),
      type: 'artists',
      rankings: top50.map((artist, index) => ({
        rank: index + 1,
        artistId: artist.artistId,
        artistName: artist.artistName,
        weeklyStreams: artist.weeklyStreams,
        totalStreams: artist.totalStreams,
        fanbase: artist.fanbase,
      })),
    });
    
    console.log(`✅ Created artist leaderboard snapshot for week ${weekId}`);
  } catch (error) {
    console.error('❌ Error creating artist snapshot:', error);
  }
}

async function updateChartStatistics(weekId) {
  try {
    // Get this week's and last week's snapshots
    const thisWeekSongs = await db.collection('leaderboard_history').doc(`songs_${weekId}`).get();
    const lastWeekSongs = await db.collection('leaderboard_history').doc(`songs_${weekId - 1}`).get();
    
    if (!thisWeekSongs.exists) return;
    
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
    await db.collection('leaderboard_history').doc(`songs_${weekId}`).update({
      rankingsWithStats: statistics,
      statsCalculated: true,
    });
    
    console.log(`✅ Updated chart statistics for week ${weekId}`);
  } catch (error) {
    console.error('❌ Error updating chart statistics:', error);
  }
}

function getWeekId(date) {
  const startOfYear = new Date(date.getFullYear(), 0, 1);
  const days = Math.floor((date - startOfYear) / (24 * 60 * 60 * 1000));
  return date.getFullYear() * 100 + Math.ceil(days / 7);
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
// ANTI-CHEAT VALIDATION FUNCTIONS
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

function selectRandomRegion() {
  const regions = ['usa', 'europe', 'uk', 'asia', 'africa', 'latin_america', 'oceania'];
  return regions[Math.floor(Math.random() * regions.length)];
}

// ============================================================================
// MANUAL TESTING FUNCTIONS (Keep from v1)
// ============================================================================

exports.triggerDailyUpdate = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Must be authenticated');
  }
  
  console.log('🔧 Manual trigger: Daily update started');
  
  try {
    // Run the same logic as scheduled function
    const gameTimeRef = db.collection('game_state').doc('global_time');
    const gameTimeDoc = await gameTimeRef.get();
    
    if (!gameTimeDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'Game time not initialized');
    }
    
    const currentGameDate = gameTimeDoc.data().currentGameDate.toDate();
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
    throw new functions.https.HttpsError('internal', error.message);
  }
});

exports.catchUpMissedDays = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Must be authenticated');
  }
  
  const { startDate, endDate } = data;
  
  console.log(`🔧 Manual catch-up: ${startDate} to ${endDate}`);
  
  try {
    const start = new Date(startDate);
    const end = new Date(endDate);
    const days = Math.ceil((end - start) / (1000 * 60 * 60 * 24));
    
    if (days > 30) {
      throw new functions.https.HttpsError('invalid-argument', 'Maximum 30 days allowed');
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
    throw new functions.https.HttpsError('internal', error.message);
  }
});
