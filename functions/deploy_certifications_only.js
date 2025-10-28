#!/usr/bin/env node

/**
 * Quick Fix: Deploy Critical Certification Functions
 * 
 * This creates a minimal index.js with only certification functions
 * to unblock the certification feature deployment.
 * 
 * Usage:
 *   node deploy_certifications_only.js
 *   firebase deploy --only functions:listAlbumCertificationEligibility,functions:submitAlbumForCertification,functions:runCertificationsMigrationAdmin
 */

const fs = require('path');
const path = require('path');

const MINIMAL_INDEX = `
// Minimal Firebase Functions - Certifications Only
const {onCall, HttpsError} = require('firebase-functions/v2/https');
const {setGlobalOptions} = require('firebase-functions/v2');
const admin = require('firebase-admin');
admin.initializeApp();

const db = admin.firestore();

setGlobalOptions({
  region: 'us-central1',
  maxInstances: 100,
  timeoutSeconds: 540,
  memory: '512MiB',
});

// ===================================================================
// CERTIFICATION FUNCTIONS
// ===================================================================

// Helper: validate admin access
async function validateAdminAccess(request) {
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'Must be authenticated');
  }

  const userId = request.auth.uid;
  const ADMIN_USER_IDS = ['xjJFuMCEKMZwkI8uIP34Jl2bfQA3'];
  
  if (ADMIN_USER_IDS.includes(userId)) return true;

  try {
    const adminDoc = await db.collection('admins').doc(userId).get();
    if (adminDoc.exists && adminDoc.data().isAdmin === true) return true;
  } catch (error) {
    console.warn('Error checking admin collection:', error);
  }

  throw new HttpsError('permission-denied', 'Admin access required');
}

// List album certification eligibility
exports.listAlbumCertificationEligibility = onCall(async (request) => {
  const data = request.data;
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'Authentication required');
  }

  const userId = request.auth.uid;
  const playerDoc = await db.collection('players').doc(userId).get();
  
  if (!playerDoc.exists) {
    throw new HttpsError('not-found', 'Player not found');
  }

  const playerData = playerDoc.data();
  const albums = playerData.albums || [];
  
  // Load RC params for thresholds
  let rc = {};
  try {
    if (admin.remoteConfig) {
      const tmpl = await admin.remoteConfig().getTemplate();
      rc = (tmpl && tmpl.parameters) ? tmpl.parameters : {};
    }
  } catch (e) {
    console.warn('RC unavailable, using defaults');
  }

  const getParam = (key, def) => {
    try {
      const rcVal = rc && rc[key] && rc[key].defaultValue && rc[key].defaultValue.value;
      return Number(rcVal ?? process.env[key] ?? def);
    } catch (e) {
      return def;
    }
  };

  const thresholds = {
    silver: getParam('certSilverUnits', 50000),
    gold: getParam('certGoldUnits', 100000),
    platinum: getParam('certPlatinumUnits', 250000),
    diamond: getParam('certDiamondUnits', 1000000),
    multiStep: getParam('certMultiPlatinumStepUnits', 250000),
  };

  const result = [];
  
  for (const album of albums) {
    if (album.state !== 'released') continue;

    const units = album.eligibleUnits || 0;
    const current = album.highestCertification || 'none';
    const level = album.certificationLevel || 0;

    let nextTier = 'none';
    let nextLevel = 0;
    let eligible = false;

    if (current === 'none' && units >= thresholds.silver) {
      nextTier = 'silver';
      nextLevel = 1;
      eligible = true;
    } else if (current === 'silver' && units >= thresholds.gold) {
      nextTier = 'gold';
      nextLevel = 1;
      eligible = true;
    } else if (current === 'gold' && units >= thresholds.platinum) {
      nextTier = 'platinum';
      nextLevel = 1;
      eligible = true;
    } else if (current === 'platinum') {
      const nextMulti = thresholds.platinum + (level * thresholds.multiStep);
      if (units >= nextMulti) {
        nextTier = 'multi_platinum';
        nextLevel = level + 1;
        eligible = true;
      }
    } else if (current === 'multi_platinum') {
      if (units >= thresholds.diamond) {
        nextTier = 'diamond';
        nextLevel = 1;
        eligible = true;
      } else {
        const nextMulti = thresholds.platinum + (level * thresholds.multiStep);
        if (units >= nextMulti) {
          nextTier = 'multi_platinum';
          nextLevel = level + 1;
          eligible = true;
        }
      }
    }

    result.push({
      id: album.id,
      title: album.title || 'Untitled',
      units,
      currentTier: current,
      currentLevel: level,
      nextTier,
      nextLevel,
      eligibleNow: eligible,
    });
  }

  return { albums: result };
});

// Submit album for certification
exports.submitAlbumForCertification = onCall(async (request) => {
  const data = request.data;
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'Authentication required');
  }

  const userId = request.auth.uid;
  const albumId = data.albumId;

  if (!albumId) {
    throw new HttpsError('invalid-argument', 'albumId required');
  }

  const playerRef = db.collection('players').doc(userId);
  const playerDoc = await playerRef.get();

  if (!playerDoc.exists) {
    throw new HttpsError('not-found', 'Player not found');
  }

  const playerData = playerDoc.data();
  const albums = playerData.albums || [];
  const albumIdx = albums.findIndex((a) => a.id === albumId);

  if (albumIdx < 0) {
    throw new HttpsError('not-found', 'Album not found');
  }

  const album = albums[albumIdx];

  if (album.state !== 'released') {
    return { awarded: false, message: 'Album not released yet' };
  }

  // Load RC
  let rc = {};
  try {
    if (admin.remoteConfig) {
      const tmpl = await admin.remoteConfig().getTemplate();
      rc = (tmpl && tmpl.parameters) ? tmpl.parameters : {};
    }
  } catch (e) {}

  const getParam = (key, def) => {
    try {
      const rcVal = rc && rc[key] && rc[key].defaultValue && rc[key].defaultValue.value;
      return Number(rcVal ?? process.env[key] ?? def);
    } catch (e) {
      return def;
    }
  };

  const thresholds = {
    silver: getParam('certSilverUnits', 50000),
    gold: getParam('certGoldUnits', 100000),
    platinum: getParam('certPlatinumUnits', 250000),
    diamond: getParam('certDiamondUnits', 1000000),
    multiStep: getParam('certMultiPlatinumStepUnits', 250000),
  };

  const units = album.eligibleUnits || 0;
  const current = album.highestCertification || 'none';
  const level = album.certificationLevel || 0;

  let newTier = current;
  let newLevel = level;
  let awarded = false;

  if (current === 'none' && units >= thresholds.silver) {
    newTier = 'silver';
    newLevel = 1;
    awarded = true;
  } else if (current === 'silver' && units >= thresholds.gold) {
    newTier = 'gold';
    newLevel = 1;
    awarded = true;
  } else if (current === 'gold' && units >= thresholds.platinum) {
    newTier = 'platinum';
    newLevel = 1;
    awarded = true;
  } else if (current === 'platinum') {
    const nextMulti = thresholds.platinum + (level * thresholds.multiStep);
    if (units >= nextMulti) {
      newTier = 'multi_platinum';
      newLevel = level + 1;
      awarded = true;
    }
  } else if (current === 'multi_platinum') {
    if (units >= thresholds.diamond) {
      newTier = 'diamond';
      newLevel = 1;
      awarded = true;
    } else {
      const nextMulti = thresholds.platinum + (level * thresholds.multiStep);
      if (units >= nextMulti) {
        newTier = 'multi_platinum';
        newLevel = level + 1;
        awarded = true;
      }
    }
  }

  if (!awarded) {
    return { awarded: false, message: 'Not eligible for next tier' };
  }

  // Update album
  albums[albumIdx].highestCertification = newTier;
  albums[albumIdx].certificationLevel = newLevel;
  albums[albumIdx].lastCertifiedAt = new Date();

  await playerRef.update({ albums });

  // Create notification
  const notifRef = playerRef.collection('notifications').doc();
  await notifRef.set({
    type: 'certification_awarded',
    title: 'Album Certified!',
    message: \`\${album.title} earned \${newTier} certification!\`,
    albumId,
    tier: newTier,
    level: newLevel,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    read: false,
  });

  return { awarded: true, tier: newTier, level: newLevel, units };
});

// Admin-only: run certifications migration
exports.runCertificationsMigrationAdmin = onCall(async (request) => {
  const data = request.data;
  await validateAdminAccess(request);

  const playerId = data.playerId;
  if (!playerId) {
    throw new HttpsError('invalid-argument', 'playerId required');
  }

  const playerRef = db.collection('players').doc(playerId);
  const playerDoc = await playerRef.get();

  if (!playerDoc.exists) {
    throw new HttpsError('not-found', 'Player not found');
  }

  // Load RC
  let rc = {};
  try {
    if (admin.remoteConfig) {
      const tmpl = await admin.remoteConfig().getTemplate();
      rc = (tmpl && tmpl.parameters) ? tmpl.parameters : {};
    }
  } catch (e) {}

  const getParam = (key, def) => {
    try {
      const rcVal = rc && rc[key] && rc[key].defaultValue && rc[key].defaultValue.value;
      return Number(rcVal ?? process.env[key] ?? def);
    } catch (e) {
      return def;
    }
  };

  const thresholds = {
    silver: getParam('certSilverUnits', 50000),
    gold: getParam('certGoldUnits', 100000),
    platinum: getParam('certPlatinumUnits', 250000),
    diamond: getParam('certDiamondUnits', 1000000),
    multiStep: getParam('certMultiPlatinumStepUnits', 250000),
  };

  const playerData = playerDoc.data();
  const songs = playerData.songs || [];
  let changed = 0;
  let awarded = 0;

  for (const song of songs) {
    if (song.state !== 'released') continue;

    const units = song.eligibleUnits || 0;
    const oldTier = song.highestCertification || 'none';
    const oldLevel = song.certificationLevel || 0;

    let newTier = oldTier;
    let newLevel = oldLevel;

    // Determine tier
    if (units >= thresholds.diamond) {
      newTier = 'diamond';
      newLevel = 1;
    } else if (units >= thresholds.platinum) {
      const multiCount = Math.floor((units - thresholds.platinum) / thresholds.multiStep);
      if (multiCount > 0) {
        newTier = 'multi_platinum';
        newLevel = multiCount + 1;
      } else {
        newTier = 'platinum';
        newLevel = 1;
      }
    } else if (units >= thresholds.gold) {
      newTier = 'gold';
      newLevel = 1;
    } else if (units >= thresholds.silver) {
      newTier = 'silver';
      newLevel = 1;
    }

    if (newTier !== oldTier || newLevel !== oldLevel) {
      song.highestCertification = newTier;
      song.certificationLevel = newLevel;
      song.lastCertifiedAt = new Date();
      changed++;
      
      if (oldTier === 'none' && newTier !== 'none') {
        awarded++;
      }
    }
  }

  if (changed > 0) {
    await playerRef.update({ songs });
  }

  return { migrated: true, changed, awarded };
});
`;

console.log('📦 Creating minimal certifications-only index.js...');
console.log('⚠️  This will overwrite your current index.js');
console.log('   Original backed up to: index.js.full.backup');
console.log('');
console.log('After running this script:');
console.log('   firebase deploy --only functions:listAlbumCertificationEligibility,functions:submitAlbumForCertification,functions:runCertificationsMigrationAdmin');
console.log('');
console.log('To restore full functions:');
console.log('   Copy-Item index.js.full.backup index.js');
