/**
 * Admin utilities - Gifts, migrations, manual triggers
 * TODO: Extract from legacy index.js
 */

// Lazy load to avoid circular dependency
let legacy = null;
function getLegacy() {
  if (!legacy) legacy = require('../index.legacy.js');
  return legacy;
}

Object.defineProperty(exports, 'checkAdminStatus', { get: () => getLegacy().checkAdminStatus });
Object.defineProperty(exports, 'sendGiftToPlayer', { get: () => getLegacy().sendGiftToPlayer });
Object.defineProperty(exports, 'triggerDailyUpdate', { get: () => getLegacy().triggerDailyUpdate });
Object.defineProperty(exports, 'catchUpMissedDays', { get: () => getLegacy().catchUpMissedDays });
Object.defineProperty(exports, 'triggerWeeklyLeaderboardUpdate', { get: () => getLegacy().triggerWeeklyLeaderboardUpdate });
Object.defineProperty(exports, 'sendGlobalNotificationToPlayers', { get: () => getLegacy().sendGlobalNotificationToPlayers });
Object.defineProperty(exports, 'syncAllPlayerStreams', { get: () => getLegacy().syncAllPlayerStreams });
