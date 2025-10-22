const admin = require("firebase-admin");
const fs = require('fs');
const path = require('path');

function usage() {
  console.log('Usage: node migrate_fix.js [--player <playerId> | --all] [--commit] [--service-account /path/to/sa.json]');
  console.log('');
  console.log('Options:');
  console.log('  --player <id>         Migrate a specific player by ID');
  console.log('  --all                 Migrate all players in the database');
  console.log('  --commit              Actually perform migration writes (default: dry-run)');
  console.log('  --service-account     Path to Firebase service account JSON');
}

// Prefer explicit service account path via env or CLI; otherwise fall back to ADC
let serviceAccountPath = process.env.SERVICE_ACCOUNT_PATH || null;
// simple CLI parse for service-account
const rawArgs = process.argv.slice(2);
for (let i = 0; i < rawArgs.length; i++) {
  if (rawArgs[i] === '--service-account' && rawArgs[i+1]) {
    serviceAccountPath = rawArgs[i+1];
    i++;
  }
}

// If the caller didn't pass a service account path, check a convenient default
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
  // Attempt ADC
  try {
    admin.initializeApp();
    console.log('Initialized firebase-admin using Application Default Credentials (ADC)');
  } catch (e) {
    console.error('Failed to initialize firebase-admin. Provide a service account with --service-account /path/to/sa.json or set SERVICE_ACCOUNT_PATH env var');
    console.error(e);
    process.exit(4);
  }
}

const db = admin.firestore();

// Parse CLI flags: --player <id>, --all, and --commit
let playerIdArg = null;
let doCommit = false;
let migrateAll = false;
for (let i = 0; i < rawArgs.length; i++) {
  if (rawArgs[i] === '--player' && rawArgs[i+1]) {
    playerIdArg = rawArgs[i+1];
    i++;
  } else if (rawArgs[i] === '--commit') {
    doCommit = true;
  } else if (rawArgs[i] === '--all') {
    migrateAll = true;
  }
}

if (!playerIdArg && !migrateAll) {
  usage();
  process.exit(1);
}

async function migratePlayer(playerId, commit = false) {
  console.log(`Starting migration for player: ${playerId}`);
  
  try {
    // Get player document
    const playerDoc = await db.collection('players').doc(playerId).get();
    
    if (!playerDoc.exists) {
      console.log('❌ Player not found');
      return;
    }

    const playerData = playerDoc.data();
    console.log('📊 Player data found:', Object.keys(playerData));

    // Check for songs in the player document
    const songKeys = Object.keys(playerData).filter(key => 
      key.includes('song') || key.includes('Song')
    );
    
    console.log('🎵 Song-related keys:', songKeys);

    // This is a dry run unless commit=true
    console.log(`${commit ? '🔁 Committing migration' : '✅ Dry run completed. Would migrate:'}`, {
      playerId,
      songsFound: songKeys.length,
      sampleData: songKeys.slice(0, 3).map(key => ({ key, value: playerData[key] }))
    });

    if (commit) {
      // For now, simply mark player as migrated and preserve arrays (non-destructive)
      try {
        await db.collection('players').doc(playerId).update({
          migratedToSubcollections: true,
          migratedAt: admin.firestore.FieldValue.serverTimestamp(),
          songsCount: songKeys.length
        });
        console.log('✅ Migration marker written for player', playerId);
      } catch (uErr) {
        console.error('❌ Failed to write migration marker:', uErr);
      }
    }

  } catch (error) {
    console.error('❌ Migration error:', error);
  }
}

async function migrateAllPlayers(commit = false) {
  console.log('🔄 Migrating all players...');
  
  try {
    const playersSnapshot = await db.collection('players').get();
    console.log(`Found ${playersSnapshot.size} players`);
    
    let successCount = 0;
    let errorCount = 0;
    
    for (const doc of playersSnapshot.docs) {
      try {
        await migratePlayer(doc.id, commit);
        successCount++;
      } catch (err) {
        console.error(`Failed to migrate player ${doc.id}:`, err);
        errorCount++;
      }
    }
    
    console.log(`\n✅ Migration complete: ${successCount} succeeded, ${errorCount} failed`);
  } catch (error) {
    console.error('❌ Error fetching players:', error);
    throw error;
  }
}

// Run migration based on CLI flags
async function main() {
  if (migrateAll) {
    await migrateAllPlayers(doCommit);
  } else {
    await migratePlayer(playerIdArg, doCommit);
  }
  
  console.log('✅ Migration script completed');
  process.exit(0);
}

main().catch(err => {
  console.error('❌ Migration script failed:', err);
  process.exit(5);
});