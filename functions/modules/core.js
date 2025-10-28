/**
 * Core gameplay functions - Daily updates, leaderboards, achievements
 * TODO: Extract from legacy index.js
 */

// Lazy load to avoid circular dependency
let legacy = null;
function getLegacy() {
  if (!legacy) legacy = require('../index.legacy.js');
  return legacy;
}

// Re-export from legacy with lazy loading
Object.defineProperty(exports, 'dailyGameUpdate', { get: () => getLegacy().dailyGameUpdate });
Object.defineProperty(exports, 'weeklyLeaderboardUpdate', { get: () => getLegacy().weeklyLeaderboardUpdate });
Object.defineProperty(exports, 'checkAchievements', { get: () => getLegacy().checkAchievements });
Object.defineProperty(exports, 'validateSongRelease', { get: () => getLegacy().validateSongRelease });
Object.defineProperty(exports, 'triggerSpecialEvent', { get: () => getLegacy().triggerSpecialEvent });
