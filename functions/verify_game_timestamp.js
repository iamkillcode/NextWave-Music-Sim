/**
 * Verifies how many 'news' documents are missing 'gameTimestamp' and reports totals.
 * Usage:
 *   node verify_game_timestamp.js --service-account ./serviceAccountKey.json
 */

const admin = require('firebase-admin');
const path = require('path');

function initAdmin() {
  const args = process.argv.slice(2);
  const saIndex = args.indexOf('--service-account');
  if (saIndex !== -1 && args[saIndex + 1]) {
    const saPath = path.resolve(args[saIndex + 1]);
    admin.initializeApp({
      credential: admin.credential.cert(require(saPath)),
    });
    console.log('✅ Initialized firebase-admin with service account');
  } else {
    admin.initializeApp();
    console.log('ℹ️ Initialized firebase-admin with Application Default Credentials');
  }
}

async function main() {
  initAdmin();
  const db = admin.firestore();

  const batchSize = 500;
  let lastId = undefined;
  let processed = 0;
  let missing = 0;

  const idField = admin.firestore.FieldPath.documentId();

  console.log('🔍 Scanning news collection in batches of', batchSize);
  while (true) {
    let query = db.collection('news').orderBy(idField).limit(batchSize);
    if (lastId) query = query.startAfter(lastId);
    const snap = await query.get();
    if (snap.empty) break;

    for (const doc of snap.docs) {
      processed++;
      const data = doc.data();
      if (!('gameTimestamp' in data) || data.gameTimestamp == null) {
        missing++;
      }
    }

    lastId = snap.docs[snap.docs.length - 1].id;
    console.log(`...progress: processed=${processed}, missing=${missing}`);
  }

  console.log('✅ Verification complete.');
  console.log('Processed:', processed);
  console.log('Missing gameTimestamp:', missing);
  process.exit(0);
}

main().catch((err) => {
  console.error('❌ Verification failed:', err);
  process.exit(1);
});
