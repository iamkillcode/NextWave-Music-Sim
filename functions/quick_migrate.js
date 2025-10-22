const admin = require("firebase-admin");

// Initialize with explicit project ID
admin.initializeApp({
  projectId: "nextwave-music-sim", // Use your actual project ID here
  databaseURL: "https://nextwave-music-sim-default-rtdb.firebaseio.com"
});

const db = admin.firestore();

async function quickMigrate(playerId) {
  console.log(`🚀 Quick migration for: ${playerId}`);
  
  try {
    // Get player data
    const playerDoc = await db.collection('players').doc(playerId).get();
    
    if (!playerDoc.exists) {
      console.log('❌ Player not found');
      return;
    }

    const playerData = playerDoc.data();
    console.log('✅ Player found with keys:', Object.keys(playerData));
    
    // Check for problematic data structures
    const problemKeys = Object.keys(playerData).filter(key => {
      const val = playerData[key];
      return typeof val === 'object' && val !== null && !Array.isArray(val);
    });
    
    console.log('🔍 Object keys that might cause issues:', problemKeys);
    
    // Show sample of what's causing the autosave failure
    problemKeys.forEach(key => {
      console.log(`📋 ${key}:`, typeof playerData[key], Object.keys(playerData[key] || {}).slice(0, 3));
    });

  } catch (error) {
    console.error('❌ Migration failed:', error);
  }
}

// Run it
quickMigrate('xjJFuMCEKMZwkI8uIP34Jl2bfQA3');