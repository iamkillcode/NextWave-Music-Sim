// Manual trigger for weekly leaderboard update
// Run this after deploying fixed Cloud Functions to regenerate snapshots

const admin = require('firebase-admin');

// Dry-run support: when --dry-run is passed or env DRY_RUN=1, the script will
// print what it would write instead of performing Firestore writes. This
// allows previewing payloads without credentials.
const DRY_RUN = process.argv.includes('--dry-run') || process.env.DRY_RUN === '1';

// Allow overriding project id with --project or PROJECT_ID env var. This helps
// when running locally so Firestore client can detect project id without
// relying on ambient credentials.
const argIndex = process.argv.indexOf('--project');
const CLI_PROJECT = argIndex >= 0 && process.argv[argIndex + 1] ? process.argv[argIndex + 1] : null;
const PROJECT_ID = CLI_PROJECT || process.env.PROJECT_ID || process.env.GOOGLE_CLOUD_PROJECT || process.env.GCLOUD_PROJECT || null;
if (PROJECT_ID) {
  process.env.GCLOUD_PROJECT = PROJECT_ID;
  process.env.GOOGLE_CLOUD_PROJECT = PROJECT_ID;
  console.log(`ℹ️ Using project id: ${PROJECT_ID}`);
}

// Initialize Firebase Admin (uses default project credentials). When running
// in DRY_RUN mode we avoid calling Firestore APIs if initialization fails.
let initialized = false;
try {
  const initOpts = PROJECT_ID ? { projectId: PROJECT_ID } : undefined;
  admin.initializeApp(initOpts);
  initialized = true;
} catch (initErr) {
  if (!DRY_RUN) {
    console.error('Failed to initialize Firebase Admin SDK:', initErr.message || initErr);
    process.exit(1);
  } else {
    console.log('⚠️ Running in DRY-RUN mode; Firebase Admin SDK initialization failed but continuing in preview mode.');
  }
}

// Only construct a Firestore client if initialization succeeded and we're not
// intentionally in DRY_RUN without credentials.
let db = null;
if (initialized && !DRY_RUN) {
  try {
    db = admin.firestore();
  } catch (err) {
    console.log('⚠️ Could not create Firestore client:', err.message || err);
    db = null;
  }
} else {
  db = null; // safe: do not call Firestore in dry-run or without successful init
}

function tsFromDate(date) {
  if (DRY_RUN) return date.toISOString();
  return admin.firestore.Timestamp.fromDate(date);
}

// Generate synthetic sample data for dry-run mode
function generateSyntheticSongs(count = 10) {
  const genres = ['Pop', 'Rock', 'Hip Hop', 'R&B', 'Electronic', 'Country', 'Jazz', 'Indie'];
  const titles = [
    'Lost in the Music', 'Chasing Stars', 'Heart & Soul', 'Trap Move', 'Never Give Up',
    'Summer Nights', 'Electric Dreams', 'Midnight City', 'Golden Hour', 'Neon Lights',
    'Wild Hearts', 'Diamond Sky', 'Velvet Moon', 'Crystal Rain', 'Phoenix Rising',
    'Thunder Roads', 'Ocean Eyes', 'Silver Lining', 'Cosmic Love', 'Paradise Found'
  ];
  const artists = [
    'Luna Grey', 'Kazuya Rin', 'Zyrah', 'Manny Black', 'Nova Storm',
    'Alex Rivers', 'Maya Chen', 'Jake Morrison', 'Sophia Lee', 'Marcus Cole',
    'Isabella Rose', 'Tyler West', 'Emma Knight', 'Chris Parker', 'Olivia Stone'
  ];

  const songs = [];
  for (let i = 0; i < count; i++) {
    const baseStreams = Math.floor(500000 - (i * 30000) + Math.random() * 20000);
    const totalStreams = baseStreams * (2 + Math.random() * 3);
    songs.push({
      id: `synthetic_song_${i + 1}`,
      songId: `synthetic_song_${i + 1}`,
      title: titles[i % titles.length],
      artistId: `synthetic_artist_${(i % 5) + 1}`,
      artistName: artists[i % artists.length],
      last7DaysStreams: baseStreams,
      streams: Math.floor(totalStreams),
      genre: genres[i % genres.length],
      coverArtUrl: `https://placeholder.com/cover_${i + 1}.jpg`,
      isNPC: i % 3 === 0,
    });
  }
  return songs;
}

function generateSyntheticArtists(count = 10) {
  const artists = [
    'Luna Grey', 'Kazuya Rin', 'Zyrah', 'Manny Black', 'Nova Storm',
    'Alex Rivers', 'Maya Chen', 'Jake Morrison', 'Sophia Lee', 'Marcus Cole'
  ];

  const result = [];
  for (let i = 0; i < count; i++) {
    const weeklyStreams = Math.floor(800000 - (i * 50000) + Math.random() * 30000);
    const totalStreams = weeklyStreams * (3 + Math.random() * 4);
    result.push({
      artistId: `synthetic_artist_${i + 1}`,
      artistName: artists[i % artists.length],
      weeklyStreams,
      totalStreams: Math.floor(totalStreams),
      fanbase: Math.floor(50000 - (i * 3000) + Math.random() * 5000),
      songCount: Math.floor(3 + Math.random() * 12),
      region: 'global',
      isNPC: i % 4 === 0,
    });
  }
  return result;
}

// Helper function to get week ID (YYYYWW format)
function getWeekId(date) {
  const year = date.getFullYear();
  const firstDayOfYear = new Date(year, 0, 1);
  const pastDaysOfYear = (date - firstDayOfYear) / 86400000;
  const weekNumber = Math.ceil((pastDaysOfYear + firstDayOfYear.getDay() + 1) / 7);
  return `${year}${String(weekNumber).padStart(2, '0')}`;
}

function getPreviousWeekId(weekId) {
  // Accept numeric or string weekId like '202544' or 202544
  const idStr = String(weekId);
  const year = parseInt(idStr.slice(0, 4), 10);
  const week = parseInt(idStr.slice(4), 10);
  if (Number.isNaN(year) || Number.isNaN(week)) return idStr;

  if (week > 1) {
    return `${year}${String(week - 1).padStart(2, '0')}`;
  }
  // If week == 1, roll back to previous year week 52 (approximate)
  return `${year - 1}${String(52).padStart(2, '0')}`;
}

// Create song leaderboard snapshot
async function createSongLeaderboardSnapshot(weekId, timestamp) {
  console.log(`  📊 Creating song leaderboard snapshot for week ${weekId}...`);

  // Load previous week snapshots to calculate movement (best-effort). In
  // DRY_RUN mode, we skip reads that fail and continue with synthetic previous data.
  const previousWeekId = getPreviousWeekId(weekId);
  const previousSnapshots = {};
  try {
    if (db) {
      const prevGlobalDoc = await db.collection('leaderboard_history')
        .doc(`songs_global_${previousWeekId}`)
        .get();
      if (prevGlobalDoc.exists) {
        const prevData = prevGlobalDoc.data();
        (prevData.rankings || []).forEach(entry => {
          previousSnapshots[`global_${entry.songId}`] = {
            position: entry.position,
            weeksOnChart: entry.weeksOnChart || 0,
            consecutiveWeeks: entry.consecutiveWeeks || 0,
          };
        });
      }

      const regions = ['usa', 'europe', 'uk', 'asia', 'africa', 'latin_america', 'oceania'];
      for (const region of regions) {
        const prevRegionalDoc = await db.collection('leaderboard_history')
          .doc(`songs_${region}_${previousWeekId}`)
          .get();
        if (prevRegionalDoc.exists) {
          const prevData = prevRegionalDoc.data();
          (prevData.rankings || []).forEach(entry => {
            previousSnapshots[`${region}_${entry.songId}`] = {
              position: entry.position,
              weeksOnChart: entry.weeksOnChart || 0,
              consecutiveWeeks: entry.consecutiveWeeks || 0,
            };
          });
        }
      }
    } else if (DRY_RUN) {
      console.log('ℹ️ Generating synthetic previous week data for movement calculation...');
      // Create synthetic previous positions (simulate some movement)
      for (let i = 0; i < 10; i++) {
        const songId = `synthetic_song_${i + 1}`;
        // Mix up positions to show various movement scenarios
        let prevPosition;
        if (i === 0) prevPosition = 3;  // Was #3, now #1 (up 2)
        else if (i === 1) prevPosition = 1;  // Was #1, now #2 (down 1)
        else if (i === 2) prevPosition = 2;  // Was #2, now #3 (down 1)
        else if (i === 3) prevPosition = 4;  // Was #4, now #4 (no change)
        else if (i === 4) prevPosition = 8;  // Was #8, now #5 (up 3)
        else prevPosition = i + 1;  // Same position or new entry

        previousSnapshots[`global_${songId}`] = {
          position: prevPosition,
          weeksOnChart: i < 7 ? Math.floor(1 + Math.random() * 5) : 0, // 0 = new entry
          consecutiveWeeks: i < 7 ? Math.floor(1 + Math.random() * 5) : 0,
        };
      }
    } else {
      console.log('ℹ️ No Firestore connection available; skipping previous snapshot reads.');
    }
  } catch (err) {
    console.log(`⚠️ Could not load previous snapshots for ${previousWeekId}:`, err.message || err);
  }

  // Build song list from players and NPCs similar to scheduled function.
  // Use safe reads: if Firestore isn't available (DRY_RUN), fall back to synthetic data.
  let allSongs = [];
  try {
    if (db) {
      const playersSnapshot = await db.collection('players').get();
      playersSnapshot.forEach(playerDoc => {
        const playerData = playerDoc.data();
        const songs = playerData.songs || [];
        songs.forEach(song => {
          if (song.state === 'released') {
            // Only extract essential fields to avoid bloating the snapshot
            // CRITICAL: Exclude base64 coverArtUrls (they can be 50-100KB each!)
            const coverUrl = song.coverArtUrl || null;
            const safeCoverUrl = (coverUrl && !coverUrl.startsWith('data:')) ? coverUrl : null;
            
            allSongs.push({
              id: song.id || song.songId || '',
              songId: song.id || song.songId || '',
              title: song.title || 'Untitled',
              artistId: playerDoc.id,
              artistName: playerData.displayName || 'Unknown',
              last7DaysStreams: song.last7DaysStreams || song.weeklyStreams || 0,
              streams: song.streams || 0,
              coverArtUrl: safeCoverUrl,
              isNPC: false,
            });
          }
        });
      });
    } else if (DRY_RUN) {
      console.log('ℹ️ Generating synthetic song data for DRY-RUN preview (10 sample songs)...');
      allSongs = generateSyntheticSongs(10);
    } else {
      console.log('ℹ️ Skipping players read (no Firestore) — continuing with empty song list.');
    }
  } catch (err) {
    console.log('⚠️ Could not read players collection:', err.message || err);
  }

  // Add NPC songs
  try {
    if (db) {
      const npcsSnapshot = await db.collection('npcs').get();
      npcsSnapshot.forEach(npcDoc => {
        const npcData = npcDoc.data();
        const songs = npcData.songs || [];
        songs.forEach(song => {
          if (song.state === 'released') {
            // Only extract essential fields to avoid bloating the snapshot
            // CRITICAL: Exclude base64 coverArtUrls (they can be 50-100KB each!)
            const coverUrl = song.coverArtUrl || null;
            const safeCoverUrl = (coverUrl && !coverUrl.startsWith('data:')) ? coverUrl : null;
            
            allSongs.push({
              id: song.id || song.songId || '',
              songId: song.id || song.songId || '',
              title: song.title || 'Untitled',
              artistId: npcDoc.id,
              artistName: npcData.name || 'Unknown NPC',
              last7DaysStreams: song.last7DaysStreams || song.weeklyStreams || 0,
              streams: song.streams || 0,
              coverArtUrl: safeCoverUrl,
              isNPC: true,
            });
          }
        });
      });
    } else if (DRY_RUN) {
      // Synthetic data already generated above
      console.log('ℹ️ Using synthetic song data (includes both player and NPC songs).');
    } else {
      console.log('ℹ️ Skipping NPCs read (no Firestore).');
    }
  } catch (err) {
    console.log('⚠️ Could not read npcs collection:', err.message || err);
  }

  // Global chart
  const globalSongs = [...allSongs];
  console.log(`  📊 Total songs found: ${globalSongs.length}`);
  globalSongs.sort((a, b) => (b.last7DaysStreams || 0) - (a.last7DaysStreams || 0));
  const globalTop100 = globalSongs.slice(0, 100);
  console.log(`  📊 Taking top ${globalTop100.length} songs for snapshot`);

  const globalRankings = globalTop100.map((song, index) => {
    const position = index + 1;
    const songId = song.id || song.songId || '';
    const prevKey = `global_${songId}`;
    const prevData = previousSnapshots[prevKey];

    let movement = 0;
    let lastWeekPosition = null;
    let weeksOnChart = 1;
    let consecutiveWeeks = 1;
    let entryType = 'new';

    if (prevData) {
      lastWeekPosition = prevData.position;
      movement = lastWeekPosition - position;
      weeksOnChart = (prevData.weeksOnChart || 0) + 1;
      consecutiveWeeks = (prevData.consecutiveWeeks || 0) + 1;
      entryType = null;
    }

    // Only include essential fields to keep document size under 1MB
    return {
      position,
      rank: position,
      songId,
      title: song.title || 'Untitled',
      artistId: song.artistId || '',
      artist: song.artistName || 'Unknown',
      streams: song.last7DaysStreams || 0,
      periodStreams: song.last7DaysStreams || 0,
      totalStreams: song.streams || 0,
      coverArtUrl: song.coverArtUrl || null,
      isNPC: song.isNPC || false,
      movement,
      lastWeekPosition,
      weeksOnChart,
      entryType,
    };
  });

  const songDocId = `songs_global_${weekId}`;
  const songPayload = {
    type: 'songs',
    region: 'global',
    weekId,
    timestamp: tsFromDate(timestamp),
    rankings: globalRankings,
  };

  // Log document size estimate
  const payloadSize = JSON.stringify(songPayload).length;
  console.log(`  📏 Estimated document size: ${(payloadSize / 1024).toFixed(2)} KB (${globalRankings.length} entries)`);
  
  if (payloadSize > 900000) {
    console.warn(`  ⚠️  Warning: Document size (${(payloadSize / 1024).toFixed(2)} KB) is close to Firestore's 1MB limit!`);
  }

  if (DRY_RUN) {
    console.log(`
DRY RUN: Would write document leaderboard_history/${songDocId} with payload:`);
    console.log(JSON.stringify(songPayload, null, 2).slice(0, 20000));
  } else {
    await db.collection('leaderboard_history').doc(songDocId).set(songPayload);
    console.log(`  ✅ Song snapshot created with ${globalRankings.length} entries`);
  }
}

// Create artist leaderboard snapshot
async function createArtistLeaderboardSnapshot(weekId, timestamp) {
  console.log(`  📊 Creating artist leaderboard snapshot for week ${weekId}...`);
  
  // Get all players with released songs. In DRY_RUN or when db is null we
  // generate synthetic artist data for the preview.
  let artists = [];
  try {
    if (db) {
      const playersSnapshot = await db.collection('players').get();
      for (const doc of playersSnapshot.docs) {
        const playerData = doc.data();
        const releasedSongs = playerData.releasedSongs || 0;

        // Skip artists with no released songs
        if (releasedSongs === 0) continue;

        const weeklyStreams = playerData.weeklyStreams || 0;
        const fanbase = playerData.fanCount || playerData.fans || 0;

        artists.push({
          artistId: doc.id,
          artistName: playerData.displayName || playerData.artistName || 'Unknown',
          weeklyStreams,
          totalStreams: playerData.totalStreams || 0,
          fanbase,
          songCount: releasedSongs,
          region: playerData.region || 'global',
        });
      }
    } else if (DRY_RUN) {
      console.log('ℹ️ Generating synthetic artist data for DRY-RUN preview (10 sample artists)...');
      artists = generateSyntheticArtists(10);
    } else {
      console.log('ℹ️ Skipping players read (no Firestore) — artist list will be empty.');
    }
  } catch (err) {
    console.log('⚠️ Could not read players for artists snapshot:', err.message || err);
  }

  // Sort by weekly streams and assign ranks
  artists.sort((a, b) => b.weeklyStreams - a.weeklyStreams);
  artists.forEach((artist, index) => {
    artist.rank = index + 1;
  });

  // Take top 100
  const top100 = artists.slice(0, 100);

  // Save to leaderboard_history (normalize to the modern 'rankings' format)
  const artistDocId = `artists_global_${weekId}`;
  const artistPayload = {
    type: 'artists',
    region: 'global',
    weekId,
    timestamp: tsFromDate(timestamp),
    rankings: top100.map(a => ({
      position: a.rank || 0,
      rank: a.rank || 0,
      artistId: a.artistId || '',
      artistName: a.artistName || 'Unknown',
      streams: a.weeklyStreams || 0,
      weeklyStreams: a.weeklyStreams || 0,
      totalStreams: a.totalStreams || 0,
      fanbase: a.fanbase || 0,
      songCount: a.songCount || 0,
      isNPC: a.isNPC || false,
      movement: 0,
      lastWeekPosition: null,
      weeksOnChart: 1,
    })),
  };

  if (DRY_RUN) {
    console.log(`\nDRY RUN: Would write document leaderboard_history/${artistDocId} with payload:`);
    console.log(JSON.stringify(artistPayload, null, 2).slice(0, 20000));
  } else {
    await db.collection('leaderboard_history').doc(artistDocId).set(artistPayload);
    console.log(`  ✅ Artist snapshot created with ${top100.length} entries`);
  }
}

// Update chart statistics
async function updateChartStatistics(weekId) {
  console.log(`  📊 Updating chart statistics for week ${weekId}...`);
  
  const stats = {
    weekId,
    lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
    totalSongs: 0,
    totalArtists: 0,
    totalStreams: 0,
  };
  
  // Get song snapshot
  try {
    if (db) {
      const songDoc = await db.collection('leaderboard_history').doc(`songs_global_${weekId}`).get();
      if (songDoc.exists) {
        const songData = songDoc.data();
        // Support both legacy 'entries' and modern 'rankings'
        const songEntries = songData.rankings || songData.entries || [];
        stats.totalSongs = songEntries.length || 0;
        stats.totalStreams = songEntries.reduce((sum, entry) => sum + (entry.weeklyStreams || entry.periodStreams || 0), 0) || 0;
      }

      const artistDoc = await db.collection('leaderboard_history').doc(`artists_global_${weekId}`).get();
      if (artistDoc.exists) {
        const artistData = artistDoc.data();
        const artistEntries = artistData.rankings || artistData.entries || [];
        stats.totalArtists = artistEntries.length || 0;
      }
    } else {
      console.log('ℹ️ Skipping stats reads (no Firestore) — DRY-RUN mode; stats will be zeroed.');
    }
  } catch (err) {
    console.log('⚠️ Error reading snapshots for statistics:', err.message || err);
  }

  // Use a server timestamp when writing unless in DRY-RUN
  if (!DRY_RUN) {
    stats.lastUpdated = admin.firestore.FieldValue.serverTimestamp();
  } else {
    stats.lastUpdated = 'DRY-RUN';
  }

  if (DRY_RUN) {
    console.log(`\nDRY RUN: Would write document chart_statistics/${weekId} with payload:`);
    console.log(JSON.stringify(stats, null, 2));
  } else {
    await db.collection('chart_statistics').doc(weekId).set(stats);
    console.log(`  ✅ Chart statistics updated`);
  }
}

async function triggerWeeklyUpdate(weeksAhead = 1) {
  console.log(`🔄 Manually triggering weekly leaderboard update for ${weeksAhead} week(s) ahead...`);
  try {
    const now = new Date();
    for (let i = 0; i < weeksAhead; i++) {
      // Advance the date by i weeks
      const futureDate = new Date(now.getTime() + i * 7 * 24 * 60 * 60 * 1000);
      const weekId = getWeekId(futureDate);
      console.log(`\n➡️  Week ${i + 1}/${weeksAhead}: ${weekId} (${futureDate.toISOString().slice(0,10)})`);
      
      await createSongLeaderboardSnapshot(weekId, futureDate);
      await createArtistLeaderboardSnapshot(weekId, futureDate);
      await updateChartStatistics(weekId);
    }
    console.log('\n✅ Weekly updates triggered!');
    console.log('📊 Check Firestore console for new leaderboard_history documents');
    console.log('🔍 Look for documents like: songs_global_YYYYWW, artists_global_YYYYWW');
  } catch (error) {
    console.error('❌ Error triggering weekly update:', error);
    console.error(error.stack);
  }
  process.exit(0);
}

// Alternative: Use PubSub trigger or callable function
const weeksAhead = process.argv[2] ? parseInt(process.argv[2], 10) : 2;
triggerWeeklyUpdate(weeksAhead);
