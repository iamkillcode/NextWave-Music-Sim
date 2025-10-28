/**
 * NPC artist system - Simulation and management
 * TODO: Extract from legacy index.js
 */

// Lazy load to avoid circular dependency
let legacy = null;
function getLegacy() {
  if (!legacy) legacy = require('../index.legacy.js');
  return legacy;
}

Object.defineProperty(exports, 'initializeNPCArtists', { get: () => getLegacy().initializeNPCArtists });
Object.defineProperty(exports, 'simulateNPCActivity', { get: () => getLegacy().simulateNPCActivity });
Object.defineProperty(exports, 'forceNPCRelease', { get: () => getLegacy().forceNPCRelease });
