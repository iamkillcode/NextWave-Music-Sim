// Simple test to verify v5 deployment works
const {onCall} = require('firebase-functions/v2/https');

exports.testV5Deploy = onCall(async (request) => {
  return { success: true, message: 'V5 deployment working!', timestamp: Date.now() };
});
