#!/usr/bin/env node
/**
 * Lightweight migration utility to copy songs/albums from a player's document
 * arrays into per-player subcollections (players/{uid}/songs and players/{uid}/albums).
 *
 * Usage (dry-run):
 *   node scripts/migrate_player.js --player <playerId>
 *
 * To perform writes:
 *   GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json node scripts/migrate_player.js --player <playerId> --commit
 */

const admin = require('firebase-admin');
const path = require('path');

function parseArgs() {
  const args = process.argv.slice(2);
  const out = {};
  for (let i = 0; i < args.length; i++) {
    const a = args[i];
    if (a === '--player' && args[i + 1]) {
      out.playerId = args[i + 1];
      i++;
    } else if (a === '--commit') {
      out.commit = true;
    } else if (a === '--service-account' && args[i + 1]) {
      out.serviceAccount = args[i + 1];
      i++;
    } else if (a === '--help' || a === '-h') {
      out.help = true;
    }
  }
  return out;
}

async function main() {
  const args = parseArgs();
  if (args.help || !args.playerId) {
    console.log('Usage: node scripts/migrate_player.js --player <playerId> [--commit] [--service-account /path/to/sa.json]');
    process.exit(1);
  }

  // Initialize admin SDK
  try {
    if (args.serviceAccount) {
      const saPath = path.resolve(process.cwd(), args.serviceAccount);
      const sa = require(saPath);
      admin.initializeApp({ credential: admin.credential.cert(sa) });
    } else {
      admin.initializeApp();
    }
  } catch (e) {
    console.error('Failed to initialize firebase-admin:', e);
    process.exit(2);
  }

  const db = admin.firestore();
  const playerId = String(args.playerId);
  console.log('Starting migration for player:', playerId, 'commit=', !!args.commit);

  const playerRef = db.collection('players').doc(playerId);
  const doc = await playerRef.get();
  if (!doc.exists) {
    console.error('Player not found:', playerId);
    process.exit(3);
  }

  const data = doc.data() || {};
  const songs = Array.isArray(data.songs) ? data.songs : [];
  const albums = Array.isArray(data.albums) ? data.albums : [];

  console.log(`Player ${playerId} has songs=${songs.length} albums=${albums.length}`);
  if (songs.length > 0) console.log('Sample song ids:', songs.slice(0, 5).map(s => s && s.id).filter(Boolean));
  if (albums.length > 0) console.log('Sample album ids:', albums.slice(0, 5).map(a => a && a.id).filter(Boolean));

  if (!args.commit) {
    console.log('Dry-run complete. Add --commit to perform the migration writes.');
    process.exit(0);
  }

  try {
    let batch = db.batch();
    let writes = 0;

    for (const s of songs) {
      if (!s || !s.id) continue;
      const docRef = playerRef.collection('songs').doc(String(s.id));
      batch.set(docRef, s);
      writes++;
      if (writes % 500 === 0) {
        await batch.commit();
        batch = db.batch();
        console.log('Committed 500 song writes...');
      }
    }
    if (writes % 500 !== 0) await batch.commit();
    console.log('Songs written:', writes);

    // Albums
    let ablBatch = db.batch();
    let awrites = 0;
    for (const a of albums) {
      if (!a || !a.id) continue;
      const docRef = playerRef.collection('albums').doc(String(a.id));
      ablBatch.set(docRef, a);
      awrites++;
      if (awrites % 500 === 0) {
        await ablBatch.commit();
        ablBatch = db.batch();
        console.log('Committed 500 album writes...');
      }
    }
    if (awrites % 500 !== 0) await ablBatch.commit();
    console.log('Albums written:', awrites);

    // Mark player as migrated (do not delete original arrays to keep fallback until fully verified)
    await playerRef.update({
      migratedToSubcollections: true,
      migratedAt: admin.firestore.FieldValue.serverTimestamp(),
      songsCount: writes,
      albumsCount: awrites,
    });

    console.log('Migration committed for player', playerId);
    process.exit(0);
  } catch (err) {
    console.error('Migration failed for player', playerId, err && err.stack ? err.stack : err);
    process.exit(4);
  }
}

main();
