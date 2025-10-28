/**
 * NexTube (YouTube-like video feature)
 * TODO: Extract from legacy index.js
 */

// Lazy load to avoid circular dependency
let legacy = null;
function getLegacy() {
  if (!legacy) legacy = require('../index.legacy.js');
  return legacy;
}

Object.defineProperty(exports, 'validateNexTubeUpload', { get: () => getLegacy().validateNexTubeUpload });
Object.defineProperty(exports, 'updateNextTubeDaily', { get: () => getLegacy().updateNextTubeDaily });
Object.defineProperty(exports, 'runNextTubeNow', { get: () => getLegacy().runNextTubeNow });
Object.defineProperty(exports, 'runNextTubeForAllAdmin', { get: () => getLegacy().runNextTubeForAllAdmin });
