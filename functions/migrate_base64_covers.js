// Utility to migrate base64 cover art to Firebase Storage
// This script finds all songs with base64 coverArtUrl and uploads them to Storage

const admin = require('firebase-admin');
const crypto = require('crypto');

const PROJECT_ID = process.env.PROJECT_ID || process.env.GOOGLE_CLOUD_PROJECT || 'nextwave-music-sim';
process.env.GCLOUD_PROJECT = PROJECT_ID;
process.env.GOOGLE_CLOUD_PROJECT = PROJECT_ID;

const DRY_RUN = process.argv.includes('--dry-run');

console.log(`ℹ️  Using project: ${PROJECT_ID}`);
console.log(`ℹ️  Mode: ${DRY_RUN ? 'DRY RUN (no changes)' : 'LIVE (will update database)'}`);

admin.initializeApp({ projectId: PROJECT_ID });
const db = admin.firestore();
const bucket = admin.storage().bucket(`${PROJECT_ID}.firebasestorage.app`);

// Helper to extract image data from base64 string
function parseBase64Image(dataUrl) {
  if (!dataUrl || !dataUrl.startsWith('data:')) {
    return null;
  }

  const matches = dataUrl.match(/^data:([A-Za-z-+\/]+);base64,(.+)$/);
  if (!matches || matches.length !== 3) {
    return null;
  }

  return {
    mimeType: matches[1],
    data: Buffer.from(matches[2], 'base64'),
    extension: matches[1].split('/')[1] || 'jpg',
  };
}

// Upload base64 image to Storage and return public URL
async function uploadToStorage(base64Data, songId, artistId) {
  const parsed = parseBase64Image(base64Data);
  if (!parsed) {
    throw new Error('Invalid base64 image data');
  }

  // Generate unique filename
  const hash = crypto.createHash('md5').update(parsed.data).digest('hex').slice(0, 8);
  const filename = `cover-art/${artistId}/${songId}_${hash}.${parsed.extension}`;

  console.log(`    📤 Uploading to Storage: ${filename} (${(parsed.data.length / 1024).toFixed(2)} KB)`);

  if (DRY_RUN) {
    return `https://storage.googleapis.com/${bucket.name}/${filename}`;
  }

  const file = bucket.file(filename);
  
  // Upload the file
  await file.save(parsed.data, {
    metadata: {
      contentType: parsed.mimeType,
      cacheControl: 'public, max-age=31536000', // Cache for 1 year
    },
  });

  // Make it publicly accessible
  await file.makePublic();

  // Return public URL
  return `https://storage.googleapis.com/${bucket.name}/${filename}`;
}

// Process a single player's songs
async function processPlayer(playerDoc) {
  const playerId = playerDoc.id;
  const playerData = playerDoc.data();
  const displayName = playerData.displayName || 'Unknown';
  
  console.log(`\n👤 Processing player: ${displayName} (${playerId})`);

  const songs = playerData.songs || [];
  let migratedCount = 0;
  let skippedCount = 0;
  const updatedSongs = [];

  for (const song of songs) {
    const songId = song.id || song.songId || 'unknown';
    const coverUrl = song.coverArtUrl;

    // Check if it's a base64 image
    if (coverUrl && coverUrl.startsWith('data:')) {
      console.log(`  🎵 Song: "${song.title || 'Untitled'}" (${songId})`);
      console.log(`    ⚠️  Has base64 cover (${(coverUrl.length / 1024).toFixed(2)} KB)`);

      try {
        // Upload to Storage
        const storageUrl = await uploadToStorage(coverUrl, songId, playerId);
        console.log(`    ✅ Migrated to: ${storageUrl}`);

        // Update song object
        updatedSongs.push({
          ...song,
          coverArtUrl: storageUrl,
        });
        migratedCount++;
      } catch (error) {
        console.error(`    ❌ Failed to migrate: ${error.message}`);
        updatedSongs.push(song); // Keep original
        skippedCount++;
      }
    } else {
      // Keep as-is (HTTP URL or null)
      updatedSongs.push(song);
      if (coverUrl && coverUrl.startsWith('http')) {
        skippedCount++;
      }
    }
  }

  // Update player document if any songs were migrated
  if (migratedCount > 0 && !DRY_RUN) {
    await playerDoc.ref.update({ songs: updatedSongs });
    console.log(`  💾 Updated player document (${migratedCount} migrated, ${skippedCount} skipped)`);
  } else if (migratedCount > 0) {
    console.log(`  🔍 DRY RUN: Would update ${migratedCount} songs`);
  }

  return { migrated: migratedCount, skipped: skippedCount };
}

// Process a single NPC's songs
async function processNPC(npcDoc) {
  const npcId = npcDoc.id;
  const npcData = npcDoc.data();
  const npcName = npcData.name || 'Unknown NPC';
  
  console.log(`\n🤖 Processing NPC: ${npcName} (${npcId})`);

  const songs = npcData.songs || [];
  let migratedCount = 0;
  let skippedCount = 0;
  const updatedSongs = [];

  for (const song of songs) {
    const songId = song.id || song.songId || 'unknown';
    const coverUrl = song.coverArtUrl;

    if (coverUrl && coverUrl.startsWith('data:')) {
      console.log(`  🎵 Song: "${song.title || 'Untitled'}" (${songId})`);
      console.log(`    ⚠️  Has base64 cover (${(coverUrl.length / 1024).toFixed(2)} KB)`);

      try {
        const storageUrl = await uploadToStorage(coverUrl, songId, npcId);
        console.log(`    ✅ Migrated to: ${storageUrl}`);

        updatedSongs.push({
          ...song,
          coverArtUrl: storageUrl,
        });
        migratedCount++;
      } catch (error) {
        console.error(`    ❌ Failed to migrate: ${error.message}`);
        updatedSongs.push(song);
        skippedCount++;
      }
    } else {
      updatedSongs.push(song);
      if (coverUrl && coverUrl.startsWith('http')) {
        skippedCount++;
      }
    }
  }

  if (migratedCount > 0 && !DRY_RUN) {
    await npcDoc.ref.update({ songs: updatedSongs });
    console.log(`  💾 Updated NPC document (${migratedCount} migrated, ${skippedCount} skipped)`);
  } else if (migratedCount > 0) {
    console.log(`  🔍 DRY RUN: Would update ${migratedCount} songs`);
  }

  return { migrated: migratedCount, skipped: skippedCount };
}

// Main migration function
async function migrateAllCovers() {
  console.log('\n🚀 Starting cover art migration...\n');
  console.log('═'.repeat(60));

  let totalMigrated = 0;
  let totalSkipped = 0;
  let totalErrors = 0;

  try {
    // Process all players
    console.log('\n📊 Processing Players...');
    const playersSnapshot = await db.collection('players').get();
    console.log(`Found ${playersSnapshot.size} players`);

    for (const playerDoc of playersSnapshot.docs) {
      try {
        const stats = await processPlayer(playerDoc);
        totalMigrated += stats.migrated;
        totalSkipped += stats.skipped;
      } catch (error) {
        console.error(`❌ Error processing player ${playerDoc.id}: ${error.message}`);
        totalErrors++;
      }
    }

    // Process all NPCs
    console.log('\n📊 Processing NPCs...');
    const npcsSnapshot = await db.collection('npcs').get();
    console.log(`Found ${npcsSnapshot.size} NPCs`);

    for (const npcDoc of npcsSnapshot.docs) {
      try {
        const stats = await processNPC(npcDoc);
        totalMigrated += stats.migrated;
        totalSkipped += stats.skipped;
      } catch (error) {
        console.error(`❌ Error processing NPC ${npcDoc.id}: ${error.message}`);
        totalErrors++;
      }
    }

    // Summary
    console.log('\n' + '═'.repeat(60));
    console.log('\n📈 Migration Summary:');
    console.log(`  ✅ Migrated: ${totalMigrated} covers`);
    console.log(`  ⏭️  Skipped: ${totalSkipped} covers (already HTTP URLs)`);
    console.log(`  ❌ Errors: ${totalErrors}`);

    if (DRY_RUN) {
      console.log('\n🔍 DRY RUN MODE: No changes were made to the database');
      console.log('   Run without --dry-run to apply changes');
    } else {
      console.log('\n✨ Migration complete! All base64 images uploaded to Firebase Storage.');
    }

  } catch (error) {
    console.error('\n❌ Migration failed:', error);
    throw error;
  }

  process.exit(0);
}

// Run migration
migrateAllCovers().catch(error => {
  console.error('Fatal error:', error);
  process.exit(1);
});
