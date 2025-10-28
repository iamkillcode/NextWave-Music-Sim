/**
 * Certifications system (RIAN awards)
 * TODO: Extract from legacy index.js
 */

// Lazy load to avoid circular dependency
let legacy = null;
function getLegacy() {
  if (!legacy) legacy = require('../index.legacy.js');
  return legacy;
}

Object.defineProperty(exports, 'listAlbumCertificationEligibility', { get: () => getLegacy().listAlbumCertificationEligibility });
Object.defineProperty(exports, 'submitAlbumForCertification', { get: () => getLegacy().submitAlbumForCertification });
Object.defineProperty(exports, 'runCertificationsMigrationAdmin', { get: () => getLegacy().runCertificationsMigrationAdmin });
