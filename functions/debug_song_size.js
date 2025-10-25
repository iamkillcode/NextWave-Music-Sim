// Debug script to check actual song object size from Firestore
const admin = require('firebase-admin');

const PROJECT_ID = 'nextwave-music-sim';
process.env.GCLOUD_PROJECT = PROJECT_ID;
process.env.GOOGLE_CLOUD_PROJECT = PROJECT_ID;

admin.initializeApp({ projectId: PROJECT_ID });
const db = admin.firestore();

async function checkSongSizes() {
  const playersSnapshot = await db.collection('players').limit(1).get();
  
  if (playersSnapshot.empty) {
    console.log('No players found');
    return;
  }
  
  const playerData = playersSnapshot.docs[0].data();
  const songs = playerData.songs || [];
  
  console.log(`Found ${songs.length} songs for player`);
  
  if (songs.length > 0) {
    const song = songs[0];
    console.log('\n=== Full song object ===');
    console.log(JSON.stringify(song, null, 2).slice(0, 5000));
    console.log('\n=== Song object size ===');
    console.log(`Size: ${JSON.stringify(song).length} bytes`);
    console.log(`Keys: ${Object.keys(song).join(', ')}`);
  }
  
  process.exit(0);
}

checkSongSizes().catch(console.error);
