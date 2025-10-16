// Firebase Cloud Functions for NextWave Music Sim
// Handles server-side daily updates for ALL players

const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

const db = admin.firestore();

/**
 * DAILY UPDATE CLOUD FUNCTION
 * 
 * Runs automatically every day at midnight UTC
 * Processes ALL players regardless of login status
 * Updates streams, income, and game state
 */
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
      
      // Update global game date
      await gameTimeRef.update({
        currentGameDate: admin.firestore.Timestamp.fromDate(newGameDate),
        lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
      });
      
      console.log(`📅 Game date updated: ${currentGameDate.toISOString()} → ${newGameDate.toISOString()}`);
      
      // 2. Get ALL players
      const playersSnapshot = await db.collection('players').get();
      console.log(`👥 Processing ${playersSnapshot.size} players...`);
      
      let processedCount = 0;
      let errorCount = 0;
      
      // 3. Process each player
      const batch = db.batch();
      const batchLimit = 500; // Firestore batch limit
      let batchCount = 0;
      
      for (const playerDoc of playersSnapshot.docs) {
        try {
          const playerId = playerDoc.id;
          const playerData = playerDoc.data();
          
          // Process this player's daily streams
          const updates = await processDailyStreamsForPlayer(
            playerId,
            playerData,
            newGameDate
          );
          
          if (updates) {
            batch.update(playerDoc.ref, updates);
            batchCount++;
            processedCount++;
            
            // Commit batch if we hit the limit
            if (batchCount >= batchLimit) {
              await batch.commit();
              batchCount = 0;
              console.log(`💾 Committed batch of ${batchLimit} players`);
            }
          }
        } catch (error) {
          console.error(`❌ Error processing player ${playerDoc.id}:`, error);
          errorCount++;
        }
      }
      
      // Commit remaining updates
      if (batchCount > 0) {
        await batch.commit();
        console.log(`💾 Committed final batch of ${batchCount} players`);
      }
      
      console.log(`✅ Daily update complete!`);
      console.log(`   Processed: ${processedCount} players`);
      console.log(`   Errors: ${errorCount} players`);
      console.log(`   New game date: ${newGameDate.toISOString()}`);
      
      return null;
    } catch (error) {
      console.error('❌ Fatal error in daily update:', error);
      throw error;
    }
  });

/**
 * Process daily stream growth for a single player
 */
async function processDailyStreamsForPlayer(playerId, playerData, currentGameDate) {
  try {
    const songs = playerData.songs || [];
    if (songs.length === 0) {
      return null; // No songs to process
    }
    
    let totalNewStreams = 0;
    let totalNewIncome = 0;
    const updatedSongs = [];
    
    // Process each song
    for (const song of songs) {
      // Skip unreleased songs
      if (song.state !== 'released' || !song.releasedDate) {
        updatedSongs.push(song);
        continue;
      }
      
      const releaseDate = song.releasedDate.toDate();
      if (releaseDate > currentGameDate) {
        updatedSongs.push(song);
        continue;
      }
      
      // Calculate daily stream growth
      const dailyStreams = calculateDailyStreamGrowth(
        song,
        playerData,
        currentGameDate
      );
      
      // Calculate income
      const songIncome = calculateSongIncome(song, dailyStreams);
      
      // Decay last 7 days streams (rolling window)
      const decayedLast7Days = Math.round(song.last7DaysStreams * 0.857);
      
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
      
      // Update the song
      const updatedSong = {
        ...song,
        streams: song.streams + dailyStreams,
        lastDayStreams: dailyStreams,
        last7DaysStreams: decayedLast7Days + dailyStreams,
        regionalStreams: updatedRegionalStreams,
        peakDailyStreams: Math.max(song.peakDailyStreams || 0, dailyStreams),
        daysOnChart: Math.floor((currentGameDate - releaseDate) / (1000 * 60 * 60 * 24)) + 1,
      };
      
      updatedSongs.push(updatedSong);
      totalNewStreams += dailyStreams;
      totalNewIncome += songIncome;
    }
    
    // Return update object
    if (totalNewStreams > 0) {
      return {
        songs: updatedSongs,
        currentMoney: (playerData.currentMoney || 0) + totalNewIncome,
        lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
      };
    }
    
    return null;
  } catch (error) {
    console.error(`Error processing player ${playerId}:`, error);
    return null;
  }
}

/**
 * Calculate daily stream growth for a song
 * Mirrors the client-side StreamGrowthService logic
 */
function calculateDailyStreamGrowth(song, playerData, currentGameDate) {
  const releaseDate = song.releasedDate.toDate();
  const daysSinceRelease = Math.floor((currentGameDate - releaseDate) / (1000 * 60 * 60 * 24));
  
  const loyalFanbase = playerData.loyalFanbase || 0;
  const totalFanbase = playerData.level || 1;
  const fame = playerData.currentFame || 0;
  const songQuality = song.quality || 50;
  const viralityScore = song.viralityScore || 0.5;
  
  // Loyal fan streams
  const loyalStreams = Math.round(loyalFanbase * (0.5 + Math.random() * 1.5));
  
  // Discovery streams (decrease over time)
  let discoveryStreams = 0;
  if (daysSinceRelease === 0) {
    discoveryStreams = Math.round(totalFanbase * 0.3 * (songQuality / 100) * (1.5 + Math.random()));
  } else if (daysSinceRelease <= 7) {
    const weekOneDiscovery = Math.round(totalFanbase * 0.2 * viralityScore);
    const dayDecay = 1.0 - (daysSinceRelease / 7.0 * 0.4);
    discoveryStreams = Math.round(weekOneDiscovery * dayDecay);
  } else if (daysSinceRelease <= 30) {
    const monthOneDiscovery = Math.round(totalFanbase * 0.1 * viralityScore);
    const weekDecay = 1.0 - ((daysSinceRelease - 7) / 23.0 * 0.5);
    discoveryStreams = Math.round(monthOneDiscovery * weekDecay);
  } else if (daysSinceRelease <= 90) {
    discoveryStreams = Math.round(totalFanbase * 0.05 * viralityScore * (0.5 + Math.random() * 0.5));
  } else {
    discoveryStreams = Math.round(totalFanbase * 0.02 * (songQuality / 100) * (0.3 + Math.random() * 0.4));
  }
  
  // Viral streams (random spikes)
  let viralStreams = 0;
  if (Math.random() < viralityScore * 0.1) {
    const spikeMultiplier = 2.0 + (Math.random() * 5.0);
    viralStreams = Math.round((song.streams || 0) * 0.05 * spikeMultiplier);
  }
  
  // Casual fan streams
  const casualFans = Math.max(0, totalFanbase - loyalFanbase);
  const engagementRate = (songQuality / 100.0) * 0.2;
  const activeListeners = Math.round(casualFans * engagementRate);
  const casualStreams = Math.round(activeListeners * (0.1 + Math.random() * 0.7));
  
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

/**
 * Calculate income from streams based on platforms
 */
function calculateSongIncome(song, dailyStreams) {
  let income = 0;
  const platforms = song.streamingPlatforms || [];
  
  for (const platform of platforms) {
    if (platform === 'tunify') {
      // Tunify: 85% reach, $0.003 per stream
      income += Math.round(dailyStreams * 0.85 * 0.003);
    } else if (platform === 'maple_music') {
      // Maple Music: 65% reach, $0.01 per stream
      income += Math.round(dailyStreams * 0.65 * 0.01);
    }
  }
  
  return income;
}

/**
 * Distribute streams across regions
 */
function distributeStreamsRegionally(totalStreams, currentRegion, regionalFanbase, genre) {
  const regions = ['usa', 'europe', 'uk', 'asia', 'africa', 'latin_america', 'oceania'];
  const distribution = {};
  
  // Calculate total fanbase
  const totalFanbase = Object.values(regionalFanbase).reduce((sum, fans) => sum + fans, 0);
  
  if (totalFanbase === 0) {
    // No fanbase yet - 70% current region, 30% global
    distribution[currentRegion] = Math.round(totalStreams * 0.7);
    const globalStreams = Math.round(totalStreams * 0.3);
    const perRegion = Math.round(globalStreams / (regions.length - 1));
    
    for (const region of regions) {
      if (region !== currentRegion) {
        distribution[region] = perRegion;
      }
    }
  } else {
    // Distribute based on regional fanbase and genre preferences
    const regionWeights = {};
    
    for (const region of regions) {
      let weight = 0;
      
      // Current region bonus (50%)
      if (region === currentRegion) {
        weight += 0.5;
      }
      
      // Fanbase proportion (30%)
      const regionFans = regionalFanbase[region] || 0;
      weight += (regionFans / totalFanbase) * 0.3;
      
      // Genre multiplier (20%)
      weight *= getGenreMultiplier(genre, region);
      
      regionWeights[region] = weight;
    }
    
    // Normalize and distribute
    const totalWeight = Object.values(regionWeights).reduce((sum, w) => sum + w, 0);
    let remaining = totalStreams;
    
    for (const region of regions) {
      const regionStreams = Math.round((regionWeights[region] / totalWeight) * totalStreams);
      distribution[region] = regionStreams;
      remaining -= regionStreams;
    }
    
    // Add remaining to current region
    if (remaining > 0) {
      distribution[currentRegion] = (distribution[currentRegion] || 0) + remaining;
    }
  }
  
  return distribution;
}

/**
 * Get genre preference multiplier for a region
 */
function getGenreMultiplier(genre, region) {
  const preferences = {
    usa: { 'Hip Hop': 1.5, 'Rap': 1.4, 'R&B': 1.3, 'Country': 1.3 },
    uk: { 'Drill': 1.5, 'Hip Hop': 1.2, 'Rap': 1.3 },
    africa: { 'Afrobeat': 1.5, 'Hip Hop': 1.1, 'Reggae': 1.3 },
  };
  
  return (preferences[region] && preferences[region][genre]) || 1.0;
}

/**
 * HTTP TRIGGER - Manual daily update (for testing)
 * Call this endpoint to trigger a daily update manually
 */
exports.triggerDailyUpdate = functions.https.onCall(async (data, context) => {
  // Require authentication
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'Must be authenticated to trigger updates'
    );
  }
  
  console.log('🔧 Manual daily update triggered by:', context.auth.uid);
  
  // Call the same function as scheduled
  const result = await exports.dailyGameUpdate.run();
  
  return { success: true, message: 'Daily update completed' };
});

/**
 * RETROACTIVE UPDATE - Catch up missed days
 * Runs when player logs in to catch up any missed daily updates
 */
exports.catchUpMissedDays = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Must be authenticated');
  }
  
  const playerId = context.auth.uid;
  console.log(`🔄 Catch-up requested for player: ${playerId}`);
  
  try {
    const playerRef = db.collection('players').doc(playerId);
    const playerDoc = await playerRef.get();
    
    if (!playerDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'Player not found');
    }
    
    const playerData = playerDoc.data();
    const lastActive = playerData.lastActive?.toDate() || new Date();
    const gameTimeDoc = await db.collection('game_state').doc('global_time').get();
    const currentGameDate = gameTimeDoc.data().currentGameDate.toDate();
    
    const daysMissed = Math.floor((currentGameDate - lastActive) / (1000 * 60 * 60 * 24));
    
    if (daysMissed <= 0) {
      return { daysMissed: 0, streamsEarned: 0, incomeEarned: 0 };
    }
    
    console.log(`   Player missed ${daysMissed} days, catching up...`);
    
    let totalStreams = 0;
    let totalIncome = 0;
    
    // Process each missed day
    for (let day = 1; day <= daysMissed; day++) {
      const simulatedDate = new Date(lastActive);
      simulatedDate.setDate(simulatedDate.getDate() + day);
      
      const updates = await processDailyStreamsForPlayer(
        playerId,
        playerData,
        simulatedDate
      );
      
      if (updates) {
        // Apply updates to player data for next iteration
        playerData.songs = updates.songs;
        playerData.currentMoney = updates.currentMoney;
        
        // Track totals (approximate)
        totalStreams += updates.songs.reduce((sum, s) => sum + (s.lastDayStreams || 0), 0);
        totalIncome = updates.currentMoney - (playerData.currentMoney || 0);
      }
    }
    
    // Save final state
    await playerRef.update({
      songs: playerData.songs,
      currentMoney: playerData.currentMoney,
      lastActive: admin.firestore.FieldValue.serverTimestamp(),
    });
    
    console.log(`✅ Catch-up complete: ${totalStreams} streams, $${totalIncome}`);
    
    return {
      daysMissed,
      streamsEarned: totalStreams,
      incomeEarned: totalIncome,
    };
  } catch (error) {
    console.error('Error in catch-up:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});
