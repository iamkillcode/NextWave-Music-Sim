// Backfill gameTimestamp for news documents based on real-world timestamp
// Usage:
//   node backfill_game_timestamp.js [--commit] [--force] [--service-account path/to/sa.json]
//
// - Without --commit, runs in DRY RUN mode (no writes)
// - --force updates all docs (even if gameTimestamp exists); otherwise only missing

const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// Parse CLI args
let doCommit = false;
let forceUpdate = false;
let serviceAccountPath = null;

const rawArgs = process.argv.slice(2);
for (let i = 0; i < rawArgs.length; i++) {
  const arg = rawArgs[i];
  if (arg === '--commit') doCommit = true;
  if (arg === '--force') forceUpdate = true;
  if (arg === '--service-account' && rawArgs[i + 1]) {
    serviceAccountPath = rawArgs[i + 1];
    i++;
  }
}

function logUsage() {
  console.log('Usage: node backfill_game_timestamp.js [--commit] [--force] [--service-account path/to/sa.json]');
}

async function initAdmin() {
  if (serviceAccountPath) {
    const resolved = path.resolve(process.cwd(), serviceAccountPath);
    if (!fs.existsSync(resolved)) {
      console.error('❌ Service account file not found at', resolved);
      process.exit(2);
    }
    const sa = require(resolved);
    admin.initializeApp({ credential: admin.credential.cert(sa) });
    console.log('✅ Initialized firebase-admin with service account');
  } else {
    try {
      admin.initializeApp();
      console.log('✅ Initialized firebase-admin using Application Default Credentials (ADC)');
    } catch (e) {
      console.error('❌ Failed to initialize firebase-admin. Pass --service-account /path/to/sa.json');
      console.error(e);
      process.exit(3);
    }
  }
}

function toDateSafe(value) {
  if (!value) return null;
  if (value instanceof Date) return value;
  if (typeof value.toDate === 'function') return value.toDate();
  if (typeof value === 'string' || typeof value === 'number') {
    const d = new Date(value);
    if (!isNaN(d.getTime())) return d;
  }
  return null;
}

async function getGameMapping(db) {
  const doc = await db.collection('gameSettings').doc('globalTime').get();
  if (!doc.exists) {
    throw new Error('gameSettings/globalTime not found');
  }
  const data = doc.data();
  const realWorldStartDate = toDateSafe(data.realWorldStartDate);
  const gameWorldStartDate = toDateSafe(data.gameWorldStartDate);
  if (!realWorldStartDate || !gameWorldStartDate) {
    throw new Error('Invalid game time settings');
  }
  return { realWorldStartDate, gameWorldStartDate };
}

function computeGameDateFor(realTimestamp, mapping) {
  const { realWorldStartDate, gameWorldStartDate } = mapping;
  const realHoursElapsed = Math.floor((realTimestamp - realWorldStartDate) / (1000 * 60 * 60));
  const gameDaysElapsed = realHoursElapsed; // 1 real hour = 1 game day
  const calculated = new Date(gameWorldStartDate.getTime());
  calculated.setDate(calculated.getDate() + gameDaysElapsed);
  return new Date(calculated.getFullYear(), calculated.getMonth(), calculated.getDate()); // midnight
}

async function run() {
  await initAdmin();
  const db = admin.firestore();
  const mapping = await getGameMapping(db);
  console.log('🕐 Game mapping loaded:', mapping);

  const pageSize = 400; // keep room for batched writes
  let lastDoc = null;
  let processed = 0;
  let updated = 0;

  while (true) {
    let query = db.collection('news').orderBy('timestamp').limit(pageSize);
    if (lastDoc) query = query.startAfter(lastDoc);

    const snap = await query.get();
    if (snap.empty) break;

    const batch = db.batch();

    for (const doc of snap.docs) {
      processed++;
      const data = doc.data();
      const hasGameTs = !!data.gameTimestamp;
      if (hasGameTs && !forceUpdate) continue;

      const ts = toDateSafe(data.timestamp);
      if (!ts) continue; // skip if no timestamp

      const gameDate = computeGameDateFor(ts, mapping);

      if (doCommit) {
        batch.update(doc.ref, { gameTimestamp: admin.firestore.Timestamp.fromDate(gameDate) });
      }
      updated++;
    }

    if (doCommit) {
      await batch.commit();
      console.log(`✅ Batch committed. Progress: processed=${processed}, updated=${updated}`);
    } else {
      console.log(`(dry-run) Would update ${updated} of ${processed} so far...`);
    }

    lastDoc = snap.docs[snap.docs.length - 1];
    if (snap.size < pageSize) break; // done
  }

  console.log('🎯 Backfill complete.');
  console.log(`Processed: ${processed}`);
  console.log(`Updated:   ${updated} ${doCommit ? '(committed)' : '(dry-run)'}\n`);
}

run().catch((e) => {
  console.error('❌ Backfill failed:', e);
  process.exit(1);
});
