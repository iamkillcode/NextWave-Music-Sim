// Manual trigger for weekly leaderboard update
// Run this after deploying fixed Cloud Functions to regenerate snapshots

const admin = require('firebase-admin');

// Initialize Firebase Admin (uses default project credentials)
admin.initializeApp();

const db = admin.firestore();

// Helper function to get week ID (YYYYWW format)
function getWeekId(date) {
  const year = date.getFullYear();
  const firstDayOfYear = new Date(year, 0, 1);
  const pastDaysOfYear = (date - firstDayOfYear) / 86400000;
  const weekNumber = Math.ceil((pastDaysOfYear + firstDayOfYear.getDay() + 1) / 7);
  return `${year}${String(weekNumber).padStart(2, '0')}`;
}

// Create song leaderboard snapshot
async function createSongLeaderboardSnapshot(weekId, timestamp) {
  console.log(`  📊 Creating song leaderboard snapshot for week ${weekId}...`);
  
  // Get top 100 songs by weekly streams
  const songsSnapshot = await db.collection('songs')
    .orderBy('weeklyStreams', 'desc')
    .limit(100)
    .get();
  
  const songs = [];
  let rank = 1;
  
  for (const doc of songsSnapshot.docs) {
    const songData = doc.data();
    
    // Get artist info
    const artistDoc = await db.collection('players').doc(songData.artistId).get();
    const artistData = artistDoc.data();
    
    songs.push({
      rank: rank++,
      songId: doc.id,
      songName: songData.title,
      artistId: songData.artistId,
      artistName: artistData?.displayName || artistData?.artistName || 'Unknown',
      weeklyStreams: songData.weeklyStreams || 0,
      totalStreams: songData.totalStreams || 0,
      region: songData.region || 'global',
    });
  }
  
  // Save to leaderboard_history
  await db.collection('leaderboard_history').doc(`songs_global_${weekId}`).set({
    type: 'songs',
    region: 'global',
    weekId,
    timestamp: admin.firestore.Timestamp.fromDate(timestamp),
    entries: songs,
  });
  
  console.log(`  ✅ Song snapshot created with ${songs.length} entries`);
}

// Create artist leaderboard snapshot
async function createArtistLeaderboardSnapshot(weekId, timestamp) {
  console.log(`  📊 Creating artist leaderboard snapshot for week ${weekId}...`);
  
  // Get all players with released songs
  const playersSnapshot = await db.collection('players').get();
  
  const artists = [];
  
  for (const doc of playersSnapshot.docs) {
    const playerData = doc.data();
    const releasedSongs = playerData.releasedSongs || 0;
    
    // Skip artists with no released songs
    if (releasedSongs === 0) continue;
    
    const weeklyStreams = playerData.weeklyStreams || 0;
    const fanbase = playerData.fanCount || playerData.fans || 0;
    
    artists.push({
      artistId: doc.id,
      artistName: playerData.displayName || playerData.artistName || 'Unknown',
      weeklyStreams,
      totalStreams: playerData.totalStreams || 0,
      fanbase,
      songCount: releasedSongs,
      region: playerData.region || 'global',
    });
  }
  
  // Sort by weekly streams and assign ranks
  artists.sort((a, b) => b.weeklyStreams - a.weeklyStreams);
  artists.forEach((artist, index) => {
    artist.rank = index + 1;
  });
  
  // Take top 100
  const top100 = artists.slice(0, 100);
  
  // Save to leaderboard_history
  await db.collection('leaderboard_history').doc(`artists_global_${weekId}`).set({
    type: 'artists',
    region: 'global',
    weekId,
    timestamp: admin.firestore.Timestamp.fromDate(timestamp),
    entries: top100,
  });
  
  console.log(`  ✅ Artist snapshot created with ${top100.length} entries`);
}

// Update chart statistics
async function updateChartStatistics(weekId) {
  console.log(`  📊 Updating chart statistics for week ${weekId}...`);
  
  const stats = {
    weekId,
    lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
    totalSongs: 0,
    totalArtists: 0,
    totalStreams: 0,
  };
  
  // Get song snapshot
  const songDoc = await db.collection('leaderboard_history').doc(`songs_global_${weekId}`).get();
  if (songDoc.exists) {
    const songData = songDoc.data();
    stats.totalSongs = songData.entries?.length || 0;
    stats.totalStreams = songData.entries?.reduce((sum, entry) => sum + (entry.weeklyStreams || 0), 0) || 0;
  }
  
  // Get artist snapshot
  const artistDoc = await db.collection('leaderboard_history').doc(`artists_global_${weekId}`).get();
  if (artistDoc.exists) {
    const artistData = artistDoc.data();
    stats.totalArtists = artistData.entries?.length || 0;
  }
  
  // Save stats
  await db.collection('chart_statistics').doc(weekId).set(stats);
  
  console.log(`  ✅ Chart statistics updated`);
}

async function triggerWeeklyUpdate(weeksAhead = 1) {
  console.log(`🔄 Manually triggering weekly leaderboard update for ${weeksAhead} week(s) ahead...`);
  try {
    const now = new Date();
    for (let i = 0; i < weeksAhead; i++) {
      // Advance the date by i weeks
      const futureDate = new Date(now.getTime() + i * 7 * 24 * 60 * 60 * 1000);
      const weekId = getWeekId(futureDate);
      console.log(`\n➡️  Week ${i + 1}/${weeksAhead}: ${weekId} (${futureDate.toISOString().slice(0,10)})`);
      
      await createSongLeaderboardSnapshot(weekId, futureDate);
      await createArtistLeaderboardSnapshot(weekId, futureDate);
      await updateChartStatistics(weekId);
    }
    console.log('\n✅ Weekly updates triggered!');
    console.log('📊 Check Firestore console for new leaderboard_history documents');
    console.log('🔍 Look for documents like: songs_global_YYYYWW, artists_global_YYYYWW');
  } catch (error) {
    console.error('❌ Error triggering weekly update:', error);
    console.error(error.stack);
  }
  process.exit(0);
}

// Alternative: Use PubSub trigger or callable function
const weeksAhead = process.argv[2] ? parseInt(process.argv[2], 10) : 2;
triggerWeeklyUpdate(weeksAhead);
