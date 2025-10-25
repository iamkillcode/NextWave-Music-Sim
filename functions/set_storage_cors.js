// Set CORS configuration for Firebase Storage bucket
const admin = require('firebase-admin');

const PROJECT_ID = 'nextwave-music-sim';
admin.initializeApp({ projectId: PROJECT_ID });

const bucket = admin.storage().bucket(`${PROJECT_ID}.firebasestorage.app`);

async function setCors() {
  console.log('🔧 Setting CORS configuration for Storage bucket...');
  
  try {
    await bucket.setCorsConfiguration([
      {
        origin: ['*'],
        method: ['GET'],
        maxAgeSeconds: 3600,
      },
    ]);
    
    console.log('✅ CORS configuration applied successfully!');
    console.log('🌐 All origins can now access images via GET requests');
    console.log('📱 Refresh your app to see cover art loading properly');
  } catch (error) {
    console.error('❌ Failed to set CORS:', error.message);
  }
  
  process.exit(0);
}

setCors();
