const admin = require('firebase-admin');
const sa = require('./serviceAccountKey.json');
admin.initializeApp({credential: admin.credential.cert(sa)});
const db = admin.firestore();

async function checkSnapshot() {
  try {
    const doc = await db.collection('leaderboard_history').doc('songs_global_202546').get();
    
    if (!doc.exists) {
      console.log('❌ Document songs_global_202546 not found');
      console.log('📋 Trying to find latest snapshot...');
      
      // Try to find any songs document
      const snapshot = await db.collection('leaderboard_history').limit(5).get();
      console.log(`\nFound ${snapshot.size} documents:`);
      snapshot.forEach(d => {
        console.log(`  - ${d.id}`);
      });
      process.exit(1);
    }
    
    const data = doc.data();
    console.log('✅ Document:', doc.id);
    console.log('📊 Rankings count:', data.rankings?.length || 0);
    
    if (data.rankings && data.rankings.length > 0) {
      console.log('\n🎵 First 3 songs:\n');
      data.rankings.slice(0, 3).forEach((song, i) => {
        console.log(`${i+1}. "${song.title}" by ${song.artist}`);
        console.log(`   coverArtUrl: ${song.coverArtUrl || 'NULL'}`);
        
        if (song.coverArtUrl) {
          if (song.coverArtUrl.startsWith('http')) {
            console.log(`   ✅ HTTP URL (Good!)`);
          } else if (song.coverArtUrl.startsWith('data:')) {
            console.log(`   ❌ BASE64 (Should be filtered!)`);
          } else {
            console.log(`   ⚠️  OTHER type`);
          }
        } else {
          console.log(`   ❌ NULL (Missing cover art)`);
        }
        console.log('');
      });
    }
    
    process.exit(0);
  } catch (error) {
    console.error('Error:', error.message);
    process.exit(1);
  }
}

checkSnapshot();
