// Quick script to seed initial news for testing The Scoop
// Run this from Firebase console or as a Cloud Function

const admin = require('firebase-admin');
const path = require('path');

// Get service account path from command line or use default
let serviceAccountPath = process.argv.find(arg => arg.includes('service-account'));
if (serviceAccountPath) {
  serviceAccountPath = process.argv[process.argv.indexOf(serviceAccountPath) + 1];
} else {
  serviceAccountPath = path.resolve(__dirname, 'nextwave-music-sim-firebase-adminsdk-fbsvc-78243c9956.json');
}

// Initialize Firebase Admin
if (!admin.apps.length) {
  const serviceAccount = require(serviceAccountPath);
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });
  console.log(`✅ Initialized with service account: ${path.basename(serviceAccountPath)}`);
}

const db = admin.firestore();

const sampleNews = [
  {
    headline: '🎵 Music Industry Enters New Era',
    body: 'Streaming platforms report record-breaking numbers as independent artists continue to rise. The music landscape is changing faster than ever before.',
    category: 'milestone',
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
  },
  {
    headline: '🔥 Underground Scene Explodes with Fresh Talent',
    body: 'Critics are buzzing about a wave of new artists bringing innovative sounds to the mainstream. The underground is where the magic happens right now.',
    category: 'drama',
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
  },
  {
    headline: '📊 Spotlight Charts See Major Shake-Up',
    body: 'This week\'s charts feature several surprise entries as emerging artists challenge established names. The competition has never been fiercer!',
    category: 'chartMovement',
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
  },
  {
    headline: '🎉 Virtual Concerts Break Attendance Records',
    body: 'Artists are reaching global audiences through innovative virtual performances. The future of live music is being redefined in real-time.',
    category: 'milestone',
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
  },
  {
    headline: '⚡ Social Media Buzz: Who\'s Really Making Waves?',
    body: 'Industry insiders reveal that social media engagement is now the #1 predictor of chart success. Your online presence matters more than ever.',
    category: 'drama',
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
  },
  {
    headline: '🤝 Collaboration Season: Artists Unite',
    body: 'Multiple high-profile collaborations are in the works as artists seek to expand their creative horizons and reach new audiences.',
    category: 'collaboration',
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
  },
  {
    headline: '💰 Streaming Royalties Reach All-Time High',
    body: 'Musicians celebrate as streaming platforms announce increased royalty payments. The music economy continues to grow and evolve.',
    category: 'milestone',
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
  },
  {
    headline: '🏆 Critics\' Choice: This Week\'s Must-Hear Tracks',
    body: 'Music critics compile their favorite releases of the week, featuring a diverse mix of genres and emerging talent worth your attention.',
    category: 'award',
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
  },
];

async function seedNews() {
  console.log('🌱 Seeding initial news items...');
  
  try {
    const batch = db.batch();
    
    for (const news of sampleNews) {
      const newsRef = db.collection('news').doc();
      batch.set(newsRef, news);
    }
    
    await batch.commit();
    console.log(`✅ Successfully seeded ${sampleNews.length} news items!`);
  } catch (error) {
    console.error('❌ Error seeding news:', error);
  }
}

// Run if executed directly
if (require.main === module) {
  seedNews().then(() => {
    console.log('🎉 News seeding complete!');
    process.exit(0);
  }).catch(err => {
    console.error('💥 Fatal error:', err);
    process.exit(1);
  });
}

module.exports = { seedNews, sampleNews };
