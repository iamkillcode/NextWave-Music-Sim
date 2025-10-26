# News gameTimestamp Backfill

This document tracks the backfill of `gameTimestamp` for existing `news` documents and how to re-run or verify it if needed.

## What
- Align The Scoop with in-game time by adding `gameTimestamp` to all news items.
- Backfill existing `news` docs using a server-side mapping from real time to game time.

## Scripts
- `functions/backfill_game_timestamp.js` — populates `gameTimestamp` (dry-run by default; use `--commit` to write).
- `functions/verify_game_timestamp.js` — scans the `news` collection and reports any docs missing `gameTimestamp`.

## How to run (Windows PowerShell)

Prereqs:
- A Firebase service account JSON file with Firestore access (e.g. `functions/serviceAccountKey.json`).
- Node.js installed.

Dry run:

```powershell
cd .\nextwave\functions
node .\backfill_game_timestamp.js --service-account .\serviceAccountKey.json
```

Commit (writes updates):

```powershell
cd .\nextwave\functions
node .\backfill_game_timestamp.js --commit --service-account .\serviceAccountKey.json
```

Verify (expect Missing = 0):

```powershell
cd .\nextwave\functions
node .\verify_game_timestamp.js --service-account .\serviceAccountKey.json
```

## Current status
- Backfill executed with `--commit` on this project.
- Result: Processed 11, Updated 11, Missing 0 (verified).

## Notes
- The backfill computes `gameTimestamp` via the same mapping used by server news creation.
- If you add older legacy documents later, re-run the backfill (dry-run first) to fill any gaps.
