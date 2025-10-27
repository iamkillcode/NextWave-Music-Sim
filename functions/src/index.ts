/**
 * Import function triggers from their respective submodules:
 *
 * import {onCall} from "firebase-functions/v2/https";
 * import {onDocumentWritten} from "firebase-functions/v2/firestore";
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

// import {setGlobalOptions} from "firebase-functions"; // Not available in current setup
import * as logger from "firebase-functions/logger";
import {onSchedule} from "firebase-functions/v2/scheduler";
import {onCall, HttpsError} from "firebase-functions/v2/https";
import {initializeApp} from "firebase-admin/app";
import * as admin from "firebase-admin";
import {getFirestore, Timestamp, FieldValue, DocumentData} from "firebase-admin/firestore";

// Start writing functions
// https://firebase.google.com/docs/functions/typescript

// For cost control, you can set the maximum number of containers that can be
// running at the same time. This helps mitigate the impact of unexpected
// traffic spikes by instead downgrading performance. This limit is a
// per-function limit. You can override the limit for each function using the
// `maxInstances` option in the function's options, e.g.
// `onRequest({ maxInstances: 5 }, (req, res) => { ... })`.
// NOTE: setGlobalOptions does not apply to functions using the v1 API. V1
// functions should each use functions.runWith({ maxInstances: 10 }) instead.
// In the v1 API, each function can only serve one request per container, so
// this will be the maximum concurrent request count.
// Global options not supported via setGlobalOptions in this setup; use per-function options instead.

// Initialize Admin SDK (idempotent)
try {
	initializeApp();
} catch (e) {
	// no-op if already initialized
}

const db = getFirestore();

/**
 * NexTube daily simulation: runs every 60 minutes (1h == 1 in-game day)
 * For each video, compute viewsToday based on owner stats and video attributes,
 * then update totalViews, dailyViews, and earnings. Credits player's money.
 */
export const updateNextTubeDaily = onSchedule({
	schedule: "every 60 minutes",
	timeZone: "Etc/UTC",
	region: "us-central1",
}, async () => {
		logger.info("NexTube daily simulation started");

		// Configurable knobs (Remote Config or ENV with sane defaults)
		let rc: any = {};
		try {
			const anyAdmin: any = (admin as any);
			if (anyAdmin.remoteConfig) {
				const tmpl = await anyAdmin.remoteConfig().getTemplate();
				rc = tmpl?.parameters ?? {};
			}
		} catch (e) {
			logger.warn("Remote Config unavailable, using defaults");
		}
		const getParam = (key: string, def: number) => {
			try {
				const p = rc?.[key]?.defaultValue?.value ?? process.env[key];
				return numOr(p, def);
			} catch {
				return def;
			}
		};

		const RPM_MIN = getParam('nexRPMMinCents', 60);
		const RPM_MAX = getParam('nexRPMMaxCents', 240);
		const FAME_MULT_CAP = getParam('nexFameMultCap', 2);
		const DAILY_VIEW_CAP = getParam('nexDailyViewCap', 200000);
		const SUBS_GAIN_CAP = getParam('nexSubsGainCap', 10000);
		const SUBS_MONETIZE_THRESHOLD = getParam('nexSubsMonetize', 1000);
		const TYPE_WEIGHT_OFFICIAL = getParam('nexWeightOfficial', 1.0);
		const TYPE_WEIGHT_LYRICS = getParam('nexWeightLyrics', 0.7);
		const TYPE_WEIGHT_LIVE = getParam('nexWeightLive', 0.5);
		const NOVELTY_HALF_LIFE_DAYS = getParam('nexNoveltyHalfLifeDays', 14);

	// Process in chunks to avoid large batch limits
	const pageSize = 250;
	let lastDoc: FirebaseFirestore.QueryDocumentSnapshot<DocumentData> | null = null;
	let processed = 0;

	while (true) {
		let query = db.collection("nexttube_videos").orderBy("createdAt").limit(pageSize);
		if (lastDoc) query = query.startAfter(lastDoc);
		const snap = await query.get();
		if (snap.empty) break;

		const batch = db.batch();

			for (const doc of snap.docs) {
			const data = doc.data();
			const ownerId = (data.ownerId || "").toString();
			if (!ownerId) continue;

			// Load owner stats (players/{ownerId})
			const playerRef = db.collection("players").doc(ownerId);
			const playerSnap = await playerRef.get();
			const player = playerSnap.exists ? playerSnap.data() || {} : {};

				// Load channel doc (players/{ownerId}/nexTubeChannel/main)
				const channelRef = playerRef.collection("nexTubeChannel").doc("main");
				const channelSnap = await channelRef.get();
				const channel = channelSnap.exists ? channelSnap.data() || {} : {};

			// Inputs
			const fanbase = safeInt(player.fanbase, 100);
			const loyalFanbase = safeInt(player.loyalFanbase, 0);
			const fame = safeInt(player.currentFame, 0);
			const createdAt = toDate(data.createdAt) ?? new Date();
			const type = (data.type || "official").toString();
				// Prefer channel monetization/RPM if present
				const channelSubs = safeInt(channel.subscribers, 0);
				const channelMonetized = channel.isMonetized === true || channelSubs >= SUBS_MONETIZE_THRESHOLD;
				const channelRpm = safeInt(channel.rpmCents, 250);
				const isMonetized = channelMonetized || data.isMonetized === true;
				const rpmCentsRaw = channelMonetized ? channelRpm : safeInt(data.rpmCents, 200);
				const rpmCents = Math.max(RPM_MIN, Math.min(RPM_MAX, rpmCentsRaw));

			// Derived
			const ageDays = Math.max(0, Math.floor((Date.now() - createdAt.getTime()) / 86_400_000));

			// --- Views formula (simple, tunable) ---
			// Base audience draw
			let base = fanbase * 0.5 + loyalFanbase * 2; // loyal fans are stronger
			// Fame multiplier (cap configurable)
			const fameMult = 1 + Math.min(FAME_MULT_CAP, fame / 300);
			// Type weight (configurable)
			const typeWeight = type === "official"
				? TYPE_WEIGHT_OFFICIAL
				: (type === "lyrics" ? TYPE_WEIGHT_LYRICS : TYPE_WEIGHT_LIVE);
			// Novelty boost with half-life decay
			const novelty = Math.pow(0.5, ageDays / Math.max(1, NOVELTY_HALF_LIFE_DAYS));
			// Randomness (±20%)
			const rand = 0.8 + Math.random() * 0.4;
			// Cap daily views vs fanbase (anti-abuse)
			const cap = Math.max(300, Math.min(DAILY_VIEW_CAP, Math.floor(fanbase * 3)));

			let viewsToday = Math.floor(base * fameMult * typeWeight * novelty * rand);
			if (!Number.isFinite(viewsToday) || viewsToday < 0) viewsToday = 0;
			viewsToday = Math.max(0, Math.min(cap, viewsToday));

			// Earnings (cents)
			const earningsCents = isMonetized ? Math.floor((rpmCents * viewsToday) / 1000) : 0;

			// Prepare updates
			batch.update(doc.ref, {
				dailyViews: viewsToday,
				totalViews: FieldValue.increment(viewsToday),
				earningsTotal: FieldValue.increment(earningsCents),
				updatedAt: Timestamp.now(),
			});

					if (earningsCents > 0) {
				// Credit dollars to player's balance
				const dollars = Math.floor(earningsCents / 100);
				if (dollars > 0) {
					batch.update(playerRef, {
						currentMoney: FieldValue.increment(dollars),
					});
				}
			}

					// Simulate channel subscribers growth (once per owner per page loop)
					// We'll approximate by updating per video iteration but scale it down
					const subBase = fanbase * 0.002 + loyalFanbase * 0.01; // loyal fans drive subs more
					const subFameMult = 1 + Math.min(1.5, fame / 400);
					const subRand = 0.8 + Math.random() * 0.4;
					let subsGain = Math.floor(subBase * subFameMult * subRand);
					subsGain = Math.max(0, Math.min(SUBS_GAIN_CAP, subsGain));

					if (subsGain > 0) {
						batch.set(channelRef, {
							ownerId: ownerId,
							subscribers: FieldValue.increment(subsGain),
							last28DaysViews: FieldValue.increment(viewsToday),
							// Set monetized if threshold hit
							isMonetized: channelMonetized || channelSubs + subsGain >= SUBS_MONETIZE_THRESHOLD,
							rpmCents: channelRpm,
							updatedAt: Timestamp.now(),
						}, {merge: true});
					} else {
						batch.set(channelRef, {
							ownerId: ownerId,
							last28DaysViews: FieldValue.increment(viewsToday),
							isMonetized: channelMonetized,
							rpmCents: channelRpm,
							updatedAt: Timestamp.now(),
						}, {merge: true});
					}
			processed++;
		}

		await batch.commit();
		lastDoc = snap.docs[snap.docs.length - 1];
		if (snap.size < pageSize) break;
	}

	logger.info(`NexTube daily simulation finished. Processed videos=${processed}`);
});

// Helpers
function safeInt(v: any, fallback = 0): number {
	if (typeof v === "number") return Math.floor(v);
	const parsed = parseInt(String(v ?? ""), 10);
	return Number.isFinite(parsed) ? parsed : fallback;
}

function toDate(v: any): Date | null {
	if (!v) return null;
	if (v instanceof Date) return v;
	if (v instanceof Timestamp) return v.toDate();
	const d = new Date(String(v));
	return Number.isNaN(d.getTime()) ? null : d;
}

function numOr(v: any, def: number): number {
	const n = Number(v);
	return Number.isFinite(n) ? n : def;
}

// (intOr removed: unused)

/**
 * Server-side NexTube upload validation callable function
 * Enforces cooldown, daily limits, and duplicate title checks server-side
 * Returns {allowed: boolean, reason?: string}
 */
export const validateNexTubeUpload = onCall({
	region: "us-central1",
}, async (request) => {
	const userId = request.auth?.uid;
	if (!userId) {
		throw new HttpsError("unauthenticated", "User must be authenticated");
	}

	const {title, songId, videoType} = request.data;
	if (!title || !songId || !videoType) {
		throw new HttpsError("invalid-argument", "Missing required fields");
	}

	// Get config (with fallbacks)
	const getEnvInt = (key: string, def: number) => numOr(process.env[key], def);
	const getEnvDouble = (key: string, def: number) => numOr(process.env[key], def);

	const COOLDOWN_MINUTES = getEnvInt("NEXTTUBE_COOLDOWN_MINUTES", 10);
	const DAILY_LIMIT = getEnvInt("NEXTTUBE_DAILY_LIMIT", 5);
	const DUPLICATE_WINDOW_DAYS = getEnvInt("NEXTTUBE_DUPLICATE_WINDOW_DAYS", 60);
	const SIMILARITY_THRESHOLD = getEnvDouble("NEXTTUBE_SIMILARITY_THRESHOLD", 0.92);

	try {
		const now = Date.now();
		const cooldownMs = COOLDOWN_MINUTES * 60 * 1000;
		const dailyMs = 24 * 60 * 60 * 1000;
		const duplicateMs = DUPLICATE_WINDOW_DAYS * 24 * 60 * 60 * 1000;

		const videosRef = db.collection("nexttube_videos");

		// Check cooldown
		const recentSnap = await videosRef
			.where("ownerId", "==", userId)
			.where("createdAt", ">=", Timestamp.fromMillis(now - cooldownMs))
			.limit(1)
			.get();

		if (!recentSnap.empty) {
			return {
				allowed: false,
				reason: `Please wait ${COOLDOWN_MINUTES} minutes between uploads`,
			};
		}

		// Check daily limit
		const dailySnap = await videosRef
			.where("ownerId", "==", userId)
			.where("createdAt", ">=", Timestamp.fromMillis(now - dailyMs))
			.limit(DAILY_LIMIT + 1)
			.get();

		if (dailySnap.size >= DAILY_LIMIT) {
			return {
				allowed: false,
				reason: `Daily upload limit reached (${DAILY_LIMIT} per day)`,
			};
		}

		// Check for official video duplicate (one per song)
		if (videoType === "official") {
			const officialSnap = await videosRef
				.where("ownerId", "==", userId)
				.where("songId", "==", songId)
				.where("type", "==", "official")
				.limit(1)
				.get();

			if (!officialSnap.empty) {
				return {
					allowed: false,
					reason: "Song already has an official video",
				};
			}
		}

		// Check same song/type recently
		const songTypeSnap = await videosRef
			.where("ownerId", "==", userId)
			.where("songId", "==", songId)
			.where("type", "==", videoType)
			.where("createdAt", ">=", Timestamp.fromMillis(now - duplicateMs))
			.limit(1)
			.get();

		if (!songTypeSnap.empty) {
			return {
				allowed: false,
				reason: `You already uploaded a ${videoType} video for this song recently`,
			};
		}

		// Check title duplication
		const normalizedTitle = normalizeTitle(title);
		const titleSnap = await videosRef
			.where("ownerId", "==", userId)
			.where("normalizedTitle", "==", normalizedTitle)
			.where("createdAt", ">=", Timestamp.fromMillis(now - duplicateMs))
			.limit(1)
			.get();

		if (!titleSnap.empty) {
			return {
				allowed: false,
				reason: "You already used a very similar title recently",
			};
		}

		// Check near-duplicate titles via similarity (Jaccard)
		const recentTitlesSnap = await videosRef
			.where("ownerId", "==", userId)
			.where("createdAt", ">=", Timestamp.fromMillis(now - duplicateMs))
			.limit(100)
			.get();

		for (const doc of recentTitlesSnap.docs) {
			const existingTitle = doc.get("title") || "";
			const existingNorm = normalizeTitle(existingTitle);
			const similarity = jaccardSimilarity(normalizedTitle, existingNorm);
			if (similarity > SIMILARITY_THRESHOLD) {
				return {
					allowed: false,
					reason: "Title looks like a near-duplicate of a recent upload",
				};
			}
		}

		// All checks passed
		return {allowed: true};
	} catch (error) {
		logger.error("Error in validateNexTubeUpload", error);
		throw new HttpsError("internal", "Upload validation failed");
	}
});

// Helper: normalize title for comparison
function normalizeTitle(title: string): string {
	return title
		.toLowerCase()
		.replace(/[^a-z0-9\s]/g, "")
		.replace(/\s+/g, " ")
		.trim();
}

// Helper: Jaccard similarity for near-duplicate detection
function jaccardSimilarity(a: string, b: string): number {
	const setA = new Set(a.split(" ").filter((w) => w.length > 0));
	const setB = new Set(b.split(" ").filter((w) => w.length > 0));
	if (setA.size === 0 && setB.size === 0) return 1.0;

	const intersection = new Set([...setA].filter((x) => setB.has(x)));
	const union = new Set([...setA, ...setB]);

	return union.size === 0 ? 0.0 : intersection.size / union.size;
}

// export const helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });
