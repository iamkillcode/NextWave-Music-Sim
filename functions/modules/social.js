/**
 * Social features - EchoX posts, notifications, Gandalf, side hustles
 * TODO: Extract from legacy index.js
 */

// Lazy load to avoid circular dependency
let legacy = null;
function getLegacy() {
  if (!legacy) legacy = require('../index.legacy.js');
  return legacy;
}

Object.defineProperty(exports, 'onPostEngagement', { get: () => getLegacy().onPostEngagement });
Object.defineProperty(exports, 'onChartUpdate', { get: () => getLegacy().onChartUpdate });
Object.defineProperty(exports, 'checkRivalChartPositions', { get: () => getLegacy().checkRivalChartPositions });
Object.defineProperty(exports, 'gandalfTheBlackPosts', { get: () => getLegacy().gandalfTheBlackPosts });
Object.defineProperty(exports, 'triggerGandalfPost', { get: () => getLegacy().triggerGandalfPost });
Object.defineProperty(exports, 'dailySideHustleGeneration', { get: () => getLegacy().dailySideHustleGeneration });
Object.defineProperty(exports, 'triggerSideHustleGeneration', { get: () => getLegacy().triggerSideHustleGeneration });
