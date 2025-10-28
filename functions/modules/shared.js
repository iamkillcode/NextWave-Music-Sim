/**
 * Shared utilities and helpers for NextWave Cloud Functions
 * Common functions used across multiple modules
 */

const admin = require('firebase-admin');
const db = admin.firestore();

/**
 * Merge incoming song list with existing songs and preserve server-managed fields
 * unless performing an admin update.
 */
function mergeSongs(incomingValue, existingSongs, action) {
  const incomingSongs = Array.isArray(incomingValue) ? incomingValue : [];
  const existing = existingSongs || [];

  if (action === 'admin_stat_update') {
    return incomingSongs;
  }

  return incomingSongs.map((inc) => {
    if (!inc || !inc.id) return inc;
    const ex = existing.find((s) => s.id === inc.id) || {};

    return {
      ...ex,
      ...inc,
      streams: (ex.streams !== undefined && ex.streams !== null) ? ex.streams : inc.streams,
      lastDayStreams: (ex.lastDayStreams !== undefined && ex.lastDayStreams !== null) ? ex.lastDayStreams : inc.lastDayStreams,
      last7DaysStreams: (ex.last7DaysStreams !== undefined && ex.last7DaysStreams !== null) ? ex.last7DaysStreams : inc.last7DaysStreams,
      regionalStreams: (ex.regionalStreams !== undefined && ex.regionalStreams !== null) ? ex.regionalStreams : inc.regionalStreams,
      peakDailyStreams: (ex.peakDailyStreams !== undefined && ex.peakDailyStreams !== null) ? ex.peakDailyStreams : inc.peakDailyStreams,
      daysOnChart: (ex.daysOnChart !== undefined && ex.daysOnChart !== null) ? ex.daysOnChart : inc.daysOnChart,
    };
  });
}

/**
 * Utility: normalize various date shapes (Firestore Timestamp, JS Date, string, epoch)
 */
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

/**
 * Compute the current in-game date based on game settings
 * 1 real-world hour = 1 in-game day
 */
async function getCurrentGameDateServer() {
  try {
    const gameSettingsRef = db.collection('gameSettings').doc('globalTime');
    const gameSettingsDoc = await gameSettingsRef.get();
    if (!gameSettingsDoc.exists) {
      // Default to Jan 1, 2020 if not initialized
      return new Date(2020, 0, 1);
    }

    const data = gameSettingsDoc.data();
    const realWorldStartDate = toDateSafe(data.realWorldStartDate);
    const gameWorldStartDate = toDateSafe(data.gameWorldStartDate);

    // Use server time to keep consistent across users
    const now = new Date();

    const realHoursElapsed = Math.floor((now - realWorldStartDate) / (1000 * 60 * 60));
    const gameDaysElapsed = realHoursElapsed; // 1 real hour = 1 game day
    const calculated = new Date(gameWorldStartDate.getTime());
    calculated.setDate(calculated.getDate() + gameDaysElapsed);
    // Normalize to midnight
    return new Date(calculated.getFullYear(), calculated.getMonth(), calculated.getDate());
  } catch (e) {
    console.error('❌ Error computing current game date on server:', e);
    return new Date(2020, 0, 1);
  }
}

/**
 * Get Remote Config parameter with fallback
 */
async function getRemoteConfigParam(key, defaultValue) {
  try {
    const template = await admin.remoteConfig().getTemplate();
    const param = template.parameters?.[key];
    if (param && param.defaultValue) {
      const value = param.defaultValue.value;
      // Try to parse as number if default is number
      if (typeof defaultValue === 'number') {
        const num = Number(value);
        return isFinite(num) ? num : defaultValue;
      }
      // Try to parse as boolean if default is boolean
      if (typeof defaultValue === 'boolean') {
        return value === 'true' || value === true;
      }
      return value || defaultValue;
    }
  } catch (e) {
    console.warn(`Failed to get Remote Config param ${key}, using default:`, e.message);
  }
  return defaultValue;
}

/**
 * Get multiple Remote Config parameters in batch
 */
async function getRemoteConfigParams(paramsMap) {
  try {
    const template = await admin.remoteConfig().getTemplate();
    const result = {};
    for (const [key, defaultValue] of Object.entries(paramsMap)) {
      const param = template.parameters?.[key];
      if (param && param.defaultValue) {
        const value = param.defaultValue.value;
        if (typeof defaultValue === 'number') {
          const num = Number(value);
          result[key] = isFinite(num) ? num : defaultValue;
        } else if (typeof defaultValue === 'boolean') {
          result[key] = value === 'true' || value === true;
        } else {
          result[key] = value || defaultValue;
        }
      } else {
        result[key] = defaultValue;
      }
    }
    return result;
  } catch (e) {
    console.warn('Failed to get Remote Config params, using defaults:', e.message);
    return paramsMap;
  }
}

/**
 * Verify admin privileges
 */
async function verifyAdmin(uid) {
  if (!uid) {
    throw new Error('Unauthorized: No user ID');
  }
  const userDoc = await db.collection('players').doc(uid).get();
  if (!userDoc.exists) {
    throw new Error('Unauthorized: User not found');
  }
  const data = userDoc.data();
  if (!data.isAdmin) {
    throw new Error('Unauthorized: Admin privileges required');
  }
  return data;
}

module.exports = {
  mergeSongs,
  toDateSafe,
  getCurrentGameDateServer,
  getRemoteConfigParam,
  getRemoteConfigParams,
  verifyAdmin,
  db,
};
