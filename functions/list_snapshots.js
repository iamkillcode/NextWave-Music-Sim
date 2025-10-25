const admin = require('firebase-admin');
const sa = require('./serviceAccountKey.json');
admin.initializeApp({credential: admin.credential.cert(sa)});
const db = admin.firestore();

async function listSnapshots() {
  try {
    const snapshot = await db.collection('leaderboard_history').get();
    console.log(`📊 Found ${snapshot.size} total documents\n`);
    
    const songs = [];
    const artists = [];
    const albums = [];
    
    snapshot.forEach(doc => {
      const id = doc.id;
      if (id.startsWith('songs_')) songs.push(id);
      else if (id.startsWith('artists_')) artists.push(id);
      else if (id.startsWith('albums_')) albums.push(id);
    });
    
    console.log(`🎵 Songs snapshots (${songs.length}):`);
    songs.sort().reverse().slice(0, 10).forEach(id => console.log(`  ${id}`));
    
    console.log(`\n🎤 Artists snapshots (${artists.length}):`);
    artists.sort().reverse().slice(0, 10).forEach(id => console.log(`  ${id}`));
    
    console.log(`\n💿 Albums snapshots (${albums.length}):`);
    albums.sort().reverse().slice(0, 10).forEach(id => console.log(`  ${id}`));
    
    // Check the latest songs snapshot
    if (songs.length > 0) {
      const latestSong = songs.sort().reverse()[0];
      console.log(`\n🔍 Checking latest song snapshot: ${latestSong}`);
      const doc = await db.collection('leaderboard_history').doc(latestSong).get();
      const data = doc.data();
      
      if (data.rankings && data.rankings[0]) {
        console.log(`\n   First song: "${data.rankings[0].title}"`);
        console.log(`   Cover art: ${data.rankings[0].coverArtUrl ? data.rankings[0].coverArtUrl.substring(0, 60) + '...' : 'NULL'}`);
        console.log(`   Has HTTP URL: ${data.rankings[0].coverArtUrl?.startsWith('http') ? '✅ YES' : '❌ NO'}`);
      }
    }
    
    process.exit(0);
  } catch (error) {
    console.error('Error:', error.message);
    process.exit(1);
  }
}

listSnapshots();
