/**
 * Secure gameplay actions - Song creation, album release, stats
 * TODO: Extract from legacy index.js
 */

// Lazy load to avoid circular dependency
let legacy = null;
function getLegacy() {
  if (!legacy) legacy = require('../index.legacy.js');
  return legacy;
}

Object.defineProperty(exports, 'secureSongCreation', { get: () => getLegacy().secureSongCreation });
Object.defineProperty(exports, 'secureReleaseAlbum', { get: () => getLegacy().secureReleaseAlbum });
Object.defineProperty(exports, 'secureStatUpdate', { get: () => getLegacy().secureStatUpdate });
Object.defineProperty(exports, 'secureSideHustleReward', { get: () => getLegacy().secureSideHustleReward });
Object.defineProperty(exports, 'migratePlayerContentToSubcollections', { get: () => getLegacy().migratePlayerContentToSubcollections });
