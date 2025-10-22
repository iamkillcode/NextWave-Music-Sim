const admin = require("firebase-admin");
const fs = require('fs');
const path = require('path');

function usage() {
  console.log('Usage: node reset_game.js [--player <playerId> | --all] [--commit] [--service-account /path/to/sa.json]');
  console.log('');
  console.log('⚠️  WARNING: This will RESET all game data to defaults!');
  console.log('');
  console.log('Options:');
  console.log('  --player <id>         Reset a specific player by ID');
  console.log('  --all                 Reset all players in the database');
  console.log('  --commit              Actually perform reset (default: dry-run)');
  console.log('  --service-account     Path to Firebase service account JSON');
  console.log('');
  console.log('What gets reset:');
  console.log('  ✅ Preserved: displayName, email, joinDate, gender, bio');
  console.log('  ❌ Cleared: songs, albums, stats, progress, side hustles');
  console.log('  🔄 Reset: money, energy, skills, fame, fanbase to defaults');
}

// Initialize Firebase Admin
let serviceAccountPath = process.env.SERVICE_ACCOUNT_PATH || null;
const rawArgs = process.argv.slice(2);

for (let i = 0; i < rawArgs.length; i++) {
  if (rawArgs[i] === '--service-account' && rawArgs[i+1]) {
    serviceAccountPath = rawArgs[i+1];
    i++;
  }
}

// Auto-detect service-account.json
if (!serviceAccountPath) {
  const defaultPath = path.resolve(process.cwd(), 'service-account.json');
  if (fs.existsSync(defaultPath)) {
    serviceAccountPath = defaultPath;
    console.log('Auto-detected service account at', defaultPath);
  }
}

if (serviceAccountPath) {
  try {
    const resolved = path.resolve(process.cwd(), serviceAccountPath);
    if (!fs.existsSync(resolved)) {
      console.error('Service account file not found at', resolved);
      process.exit(2);
    }
    const sa = require(resolved);
    admin.initializeApp({
      credential: admin.credential.cert(sa),
      databaseURL: "https://nextwave-music-sim-default-rtdb.firebaseio.com"
    });
    console.log('Initialized firebase-admin using service account:', resolved);
  } catch (e) {
    console.error('Failed to initialize firebase-admin with service account:', e);
    process.exit(3);
  }
} else {
  try {
    admin.initializeApp();
    console.log('Initialized firebase-admin using Application Default Credentials (ADC)');
  } catch (e) {
    console.error('Failed to initialize firebase-admin. Provide a service account with --service-account /path/to/sa.json');
    console.error(e);
    process.exit(4);
  }
}

const db = admin.firestore();

// Parse CLI flags
let playerIdArg = null;
let doCommit = false;
let resetAll = false;

for (let i = 0; i < rawArgs.length; i++) {
  if (rawArgs[i] === '--player' && rawArgs[i+1]) {
    playerIdArg = rawArgs[i+1];
    i++;
  } else if (rawArgs[i] === '--commit') {
    doCommit = true;
  } else if (rawArgs[i] === '--all') {
    resetAll = true;
  }
}

if (!playerIdArg && !resetAll) {
  usage();
  process.exit(1);
}

// Default starting stats
// Game starts on 2020-01-01 (in-game date), so careerStartDate should be set to that
const GAME_START_DATE = new Date('2020-01-01T00:00:00Z');

const DEFAULT_STATS = {
  currentMoney: 5000,
  energy: 100,
  currentFame: 0,
  fanbase: 100,
  loyalFanbase: 0,
  songwritingSkill: 10,
  lyricsSkill: 10,
  compositionSkill: 10,
  experience: 0,
  inspirationLevel: 50,
  creativity: 0,
  level: 1,
  totalStreams: 0,
  songsPublished: 0,
  albumsReleased: 0,
  concertsPerformed: 0,
  regionalFanbase: {
    usa: 0,
    europe: 0,
    asia: 0,
    africa: 0,
    latin_america: 0,
    oceania: 0,
    uk: 0
  },
  songs: [],
  albums: [],
  unlockedGenres: ['pop'],
  genreMastery: {
    pop: 0,
    hip_hop: 0,
    rock: 0,
    electronic: 0,
    country: 0,
    jazz: 0,
    classical: 0,
    reggae: 0,
    latin: 0,
    indie: 0
  },
  activeSideHustle: null,
  pendingPractices: [],
  careerStartDate: admin.firestore.Timestamp.fromDate(GAME_START_DATE),
  lastActivity: admin.firestore.FieldValue.serverTimestamp(),
  lastUpdated: admin.firestore.FieldValue.serverTimestamp()
};

async function resetPlayer(playerId, commit = false) {
  console.log(`\n🔄 Resetting player: ${playerId}`);
  
  try {
    const playerRef = db.collection('players').doc(playerId);
    const playerDoc = await playerRef.get();
    
    if (!playerDoc.exists) {
      console.log('❌ Player not found');
      return { success: false, error: 'not_found' };
    }

    const currentData = playerDoc.data();
    
    // Preserve identity fields
    const preservedFields = {
      id: currentData.id || playerId,
      displayName: currentData.displayName || `Artist ${playerId.substring(0, 6)}`,
      email: currentData.email || '',
      joinDate: currentData.joinDate || admin.firestore.FieldValue.serverTimestamp(),
      gender: currentData.gender || null,
      bio: currentData.bio || '',
      primaryGenre: currentData.primaryGenre || 'pop',
      homeRegion: currentData.homeRegion || 'usa',
      currentRegion: currentData.currentRegion || 'usa',
      age: currentData.age || 18,
      isOnline: currentData.isOnline || false,
      lastActive: admin.firestore.FieldValue.serverTimestamp(),
      notificationsEnabled: currentData.notificationsEnabled !== undefined ? currentData.notificationsEnabled : true,
    };

    // Merge with defaults
    const resetData = {
      ...DEFAULT_STATS,
      ...preservedFields
    };

    console.log('📊 Current stats:', {
      songs: Array.isArray(currentData.songs) ? currentData.songs.length : 0,
      albums: Array.isArray(currentData.albums) ? currentData.albums.length : 0,
      money: currentData.currentMoney,
      fame: currentData.currentFame,
      fanbase: currentData.fanbase,
      level: currentData.level
    });

    console.log('🔄 Will reset to:', {
      songs: 0,
      albums: 0,
      money: DEFAULT_STATS.currentMoney,
      fame: DEFAULT_STATS.currentFame,
      fanbase: DEFAULT_STATS.fanbase,
      level: DEFAULT_STATS.level
    });

    if (commit) {
      // Clear subcollections if they exist
      const songsSnapshot = await playerRef.collection('songs').get();
      const albumsSnapshot = await playerRef.collection('albums').get();
      
      if (!songsSnapshot.empty || !albumsSnapshot.empty) {
        console.log(`🗑️  Clearing subcollections: ${songsSnapshot.size} songs, ${albumsSnapshot.size} albums`);
        
        // Delete in batches
        let batch = db.batch();
        let count = 0;
        
        for (const doc of songsSnapshot.docs) {
          batch.delete(doc.ref);
          count++;
          if (count % 500 === 0) {
            await batch.commit();
            batch = db.batch();
          }
        }
        
        for (const doc of albumsSnapshot.docs) {
          batch.delete(doc.ref);
          count++;
          if (count % 500 === 0) {
            await batch.commit();
            batch = db.batch();
          }
        }
        
        if (count % 500 !== 0) {
          await batch.commit();
        }
      }

      // Reset player document
      await playerRef.set(resetData, { merge: false });
      console.log('✅ Player reset complete');
      return { success: true };
    } else {
      console.log('✅ Dry run complete (add --commit to actually reset)');
      return { success: true, dryRun: true };
    }

  } catch (error) {
    console.error('❌ Reset error:', error);
    return { success: false, error: error.message };
  }
}

async function resetAllPlayers(commit = false) {
  console.log('\n⚠️  🔄 RESETTING ALL PLAYERS...\n');
  
  if (!commit) {
    console.log('🟡 DRY RUN MODE - No changes will be made');
    console.log('   Add --commit to actually reset all players\n');
  } else {
    console.log('🔴 COMMIT MODE - All player data will be reset!\n');
  }
  
  try {
    const playersSnapshot = await db.collection('players').get();
    console.log(`Found ${playersSnapshot.size} players\n`);
    
    let successCount = 0;
    let errorCount = 0;
    
    for (const doc of playersSnapshot.docs) {
      const result = await resetPlayer(doc.id, commit);
      if (result.success) {
        successCount++;
      } else {
        errorCount++;
      }
    }
    
    console.log(`\n${'='.repeat(60)}`);
    console.log(`✅ Reset complete: ${successCount} succeeded, ${errorCount} failed`);
    console.log(`${'='.repeat(60)}\n`);
    
  } catch (error) {
    console.error('❌ Error fetching players:', error);
    throw error;
  }
}

async function main() {
  console.log('\n' + '='.repeat(60));
  console.log('🎮 NextWave Music Sim - Game Reset Tool');
  console.log('='.repeat(60) + '\n');

  if (resetAll) {
    await resetAllPlayers(doCommit);
  } else {
    await resetPlayer(playerIdArg, doCommit);
  }
  
  console.log('✅ Script completed\n');
  process.exit(0);
}

main().catch(err => {
  console.error('\n❌ Script failed:', err);
  process.exit(5);
});
