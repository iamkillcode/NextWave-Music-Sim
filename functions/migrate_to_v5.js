#!/usr/bin/env node

/**
 * Firebase Functions v4 to v5 Migration Script
 * 
 * This script helps convert function declarations from v4 to v5 syntax.
 * It performs safe text replacements with context checking.
 * 
 * Usage:
 *   node migrate_to_v5.js
 * 
 * This will create a backup and update index.js with v5 syntax.
 */

const fs = require('fs');
const path = require('path');

const INDEX_FILE = path.join(__dirname, 'index.js');
const BACKUP_FILE = path.join(__dirname, 'index.js.v4.backup');

// Create backup
function createBackup() {
  console.log('📦 Creating backup...');
  fs.copyFileSync(INDEX_FILE, BACKUP_FILE);
  console.log(`✅ Backup created: ${BACKUP_FILE}`);
}

// Read file
function readFile() {
  return fs.readFileSync(INDEX_FILE, 'utf8');
}

// Write file
function writeFile(content) {
  fs.writeFileSync(INDEX_FILE, content, 'utf8');
}

// Migration patterns
const migrations = [
  // Callable functions: functions.https.onCall
  {
    name: 'Callable Functions',
    pattern: /exports\.(\w+)\s*=\s*functions\.https\.onCall\(async\s*\(data,\s*context\)\s*=>\s*{/g,
    replacement: 'exports.$1 = onCall(async (request) => {\n  const data = request.data;',
    postProcess: (content) => {
      // Replace context.auth with request.auth
      content = content.replace(/context\.auth/g, 'request.auth');
      // Replace functions.https.HttpsError with HttpsError
      content = content.replace(/functions\.https\.HttpsError/g, 'HttpsError');
      return content;
    }
  },
  
  // Scheduled functions: functions.pubsub.schedule
  {
    name: 'Scheduled Functions (pattern 1)',
    pattern: /exports\.(\w+)\s*=\s*functions\.pubsub\s*\.schedule\('([^']+)'\)\s*\.timeZone\('([^']+)'\)\s*\.onRun\(async\s*\(context\)\s*=>\s*{/g,
    replacement: 'exports.$1 = onSchedule({\n  schedule: \'$2\',\n  timeZone: \'$3\',\n  timeoutSeconds: 540,\n  memory: \'512MiB\',\n}, async (event) => {',
  },
  
  // Scheduled functions without timezone
  {
    name: 'Scheduled Functions (pattern 2)',
    pattern: /exports\.(\w+)\s*=\s*functions\.pubsub\s*\.schedule\('([^']+)'\)\s*\.onRun\(async\s*\(context\)\s*=>\s*{/g,
    replacement: 'exports.$1 = onSchedule({\n  schedule: \'$2\',\n  timeoutSeconds: 540,\n  memory: \'512MiB\',\n}, async (event) => {',
  },
  
  // Firestore triggers: onUpdate
  {
    name: 'Firestore onUpdate',
    pattern: /exports\.(\w+)\s*=\s*functions\.firestore\s*\.document\('([^']+)'\)\s*\.onUpdate\(async\s*\(change,\s*context\)\s*=>\s*{/g,
    replacement: 'exports.$1 = onDocumentWritten(\'$2\', async (event) => {\n  const change = { before: event.data?.before, after: event.data?.after };\n  if (!change.before || !change.after) return null;',
    postProcess: (content) => {
      // Replace context.params with event.params in these functions
      content = content.replace(/const\s+(\w+)\s*=\s*context\.params\.(\w+);/g, 'const $1 = event.params.$2;');
      return content;
    }
  },
  
  // Firestore triggers: onCreate
  {
    name: 'Firestore onCreate',
    pattern: /exports\.(\w+)\s*=\s*functions\.firestore\s*\.document\('([^']+)'\)\s*\.onCreate\(async\s*\(snap,\s*context\)\s*=>\s*{/g,
    replacement: 'exports.$1 = onDocumentWritten(\'$2\', async (event) => {\n  const snap = event.data?.after;\n  if (!snap || !snap.exists) return null;',
  },
  
  // Firestore triggers: onDelete
  {
    name: 'Firestore onDelete',
    pattern: /exports\.(\w+)\s*=\s*functions\.firestore\s*\.document\('([^']+)'\)\s*\.onDelete\(async\s*\(snap,\s*context\)\s*=>\s*{/g,
    replacement: 'exports.$1 = onDocumentWritten(\'$2\', async (event) => {\n  const snap = event.data?.before;\n  if (!snap || !snap.exists) return null;',
  },
];

// Apply migrations
function applyMigrations() {
  let content = readFile();
  let changesMade = 0;

  migrations.forEach(migration => {
    const matches = content.match(migration.pattern);
    if (matches) {
      console.log(`\n🔄 Migrating ${migration.name}...`);
      console.log(`   Found ${matches.length} occurrence(s)`);
      
      content = content.replace(migration.pattern, migration.replacement);
      
      if (migration.postProcess) {
        content = migration.postProcess(content);
      }
      
      changesMade += matches.length;
      console.log(`   ✅ Migrated ${matches.length} function(s)`);
    }
  });

  return { content, changesMade };
}

// Verify imports exist
function verifyImports(content) {
  const requiredImports = [
    'onSchedule',
    'onCall',
    'HttpsError',
    'onDocumentWritten',
    'setGlobalOptions'
  ];

  const missing = requiredImports.filter(imp => !content.includes(imp));
  
  if (missing.length > 0) {
    console.warn(`⚠️  Warning: The following imports may be missing: ${missing.join(', ')}`);
    console.warn('   Make sure you have the correct import statements at the top of index.js');
  }
}

// Main execution
function main() {
  console.log('🚀 Firebase Functions v4 → v5 Migration\n');
  
  try {
    // Check if index.js exists
    if (!fs.existsSync(INDEX_FILE)) {
      console.error(`❌ Error: ${INDEX_FILE} not found`);
      process.exit(1);
    }

    // Create backup
    createBackup();

    // Apply migrations
    const { content, changesMade } = applyMigrations();

    if (changesMade === 0) {
      console.log('\n✅ No migrations needed - file appears to already use v5 syntax');
      return;
    }

    // Verify imports
    verifyImports(content);

    // Write updated content
    writeFile(content);

    console.log(`\n✅ Migration complete!`);
    console.log(`   Total changes: ${changesMade}`);
    console.log(`   Backup saved: ${BACKUP_FILE}`);
    console.log('\n📝 Next steps:');
    console.log('   1. Review the changes in index.js');
    console.log('   2. Run: npm install');
    console.log('   3. Test locally: firebase emulators:start --only functions');
    console.log('   4. Deploy: firebase deploy --only functions:yourFunctionName');
    console.log('\n⚠️  Note: This script handles most cases but manual review is recommended');
    console.log('   Check for any context.params or context.auth that need updating');
    
  } catch (error) {
    console.error('❌ Migration failed:', error.message);
    console.error('   Backup file:', BACKUP_FILE);
    process.exit(1);
  }
}

// Run if called directly
if (require.main === module) {
  main();
}

module.exports = { applyMigrations, verifyImports };
