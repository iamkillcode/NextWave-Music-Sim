const admin = require('firebase-admin');

/**
 * Shared utility functions used across all modules
 */

/**
 * Sanitize data for Firestore (replace NaN/Infinity with 0)
 */
function sanitizeForFirestore(data) {
  if (data === null || data === undefined) return data;
  
  if (typeof data === 'number') {
    if (isNaN(data) || !isFinite(data)) return 0;
    return data;
  }
  
  if (Array.isArray(data)) {
    return data.map(item => sanitizeForFirestore(item));
  }
  
  if (typeof data === 'object') {
    const sanitized = {};
    for (const [key, value] of Object.entries(data)) {
      sanitized[key] = sanitizeForFirestore(value);
    }
    return sanitized;
  }
  
  return data;
}

/**
 * Calculate total streams for a player
 */
function calculateTotalStreams(songs) {
  return songs.reduce((total, song) => {
    return total + (song.streams || 0);
  }, 0);
}

/**
 * Format date for logging
 */
function formatDate(date) {
  return date.toISOString().split('T')[0];
}

/**
 * Get current game date from player data
 */
function getCurrentGameDate(playerData) {
  const startDate = playerData.careerStartDate?.toDate() || new Date();
  const gameDate = new Date(startDate);
  gameDate.setDate(gameDate.getDate() + (playerData.currentDay || 0));
  return gameDate;
}

/**
 * Log to admin_logs collection
 */
async function logAdminAction(action, details) {
  try {
    await admin.firestore().collection('admin_logs').add({
      action,
      details: sanitizeForFirestore(details),
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });
  } catch (error) {
    console.error('Failed to log admin action:', error);
  }
}

/**
 * Convert a value to a Date object safely
 */
function toDateSafe(value) {
  if (!value) return null;
  if (value.toDate) return value.toDate();
  if (value instanceof Date) return value;
  return new Date(value);
}

module.exports = {
  sanitizeForFirestore,
  calculateTotalStreams,
  formatDate,
  getCurrentGameDate,
  logAdminAction,
  toDateSafe,
};
