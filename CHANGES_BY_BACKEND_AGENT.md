# Changes Made by Backend Agent (2026-07-13)

**Warning:** These changes were made by the backend agent (Ubuntu). They have NOT been verified with Xcode build. The iOS developer should review, test, and potentially adjust before shipping.

---

## What Changed and Why

The backend agent made changes to BOTH repos in this session. The `buddian-ios` changes below need iOS developer review.

### Core Architecture Change

**Before:** iOS app had a `PollinationsClient.swift` that called `gen.pollinations.ai` directly for free image generation.

**After:** All generation goes through Buddian API server. The iOS app NEVER calls Pollinations directly. The server proxies to Pollinations with its `sk_` API key.

```
iOS App → Buddian API (auth + generation + billing)
                ↓
Buddian API → Pollinations.ai (server-side, sk_ key)
```

---

## Files Changed in buddian-ios

### 1. DELETED: `Buddian/Networking/PollinationsClient.swift`

This file was created by the backend agent earlier and has now been removed. It was a direct HTTP client to `gen.pollinations.ai`. The iOS app must not call external AI APIs directly — all requests go through `api.buddian.com`.

**Impact:** Any code that referenced `PollinationsClient` will fail to compile.

### 2. MODIFIED: `Buddian/Views/GenerateView.swift`

**What changed:**
- Removed the `generateViaPollinations()` method (direct API call path)
- Removed `PollinationsClient` import/usage
- Removed `generatedImageData` state for inline result display
- Added `jobId`, `jobStatus`, `isPolling` state for server-side job polling
- Added `pollJobStatus()` — polls `GET /generations/{job_id}` every 5 seconds
- Added `downloadResult()` — downloads image via `GET /generations/{job_id}/result`
- All models now go through the same path: `POST /generations` → poll → download

**What you should verify:**
- The `APIClient.shared.fetchGeneration(jobId:)` method exists and returns a `Generation` object
- The `APIClient.shared.downloadResult(jobId:)` method exists and returns `Data`
- The `Generation` model has `status`, `statusDetail` fields
- The polling loop handles all edge cases (timeout, network error, etc.)
- The `Task.sleep` works correctly for the 5s interval

**Current GenerateView flow:**
1. User selects model + types prompt
2. `submitGeneration()` → `POST /generations` → gets `job_id`
3. `pollJobStatus()` loops: `GET /generations/{job_id}` every 5s
4. When `status == "completed"` → `downloadResult()` → `GET /generations/{job_id}/result`
5. Result image displayed inline

### 3. MODIFIED: `Buddian/Views/ModelsView.swift`

**What changed:**
- Completely rewritten to use `ModelCache` (Buddian API models) instead of `PollinationsClient`
- Removed `PollinationsModel` type, uses `RemoteModel` instead
- Added `ModalityFilter` enum for All/Image/Video filter
- Uses `@EnvironmentObject var modelCache: ModelCache`
- Shows "Free" badge for free models, pricing for paid models

**What you should verify:**
- `ModelCache.shared` is properly injected as `@EnvironmentObject` in the view hierarchy
- `ModelCache` has a `refresh()` async method
- `ModelCache.isLoading` property exists
- `RemoteModel` has `name`, `description`, `type`, `isFree`, `userPricing`, `outputModalities` properties

### 4. MODIFIED: `Buddian.xcodeproj/project.pbxproj`

Removed all references to `PollinationsClient.swift`:
- PBXBuildFile entry (line ~27)
- PBXFileReference entry (line ~71)
- Networking group children entry (line ~158)
- Sources build phase entry (line ~280)

**What you should verify:**
- No orphan references remain (grep for "PollinationsClient" in the pbxproj)
- All other files still compile (no broken references)

### 5. NEW: `IOS_API.md`

Complete iOS-specific API reference document. This is the authoritative API docs for the iOS developer. It covers:
- Authentication flow (`POST /web/auth/firebase`)
- User profile (`GET /web/me`)
- Model catalog (`GET /models`)
- Generation (`POST /generations`, `GET /generations/{id}`, `GET /generations/{id}/result`)
- Wallet/Apple IAP (planned)
- Complete user flow
- Error responses

### 6. MODIFIED: `README.md`

Updated "What's Built" section to reflect server-only architecture. Removed mention of `PollinationsClient.swift`. Added architecture diagram.

### 7. MODIFIED: `TODO.md`

Updated the "Handoff for macOS Agent" section at the top. Key changes:
- Removed "Two generation paths" section (Pollinations direct vs queue)
- Added "Architecture — server-only" section
- Updated "Key files" table (removed PollinationsClient, added IOS_API.md)
- Updated "Gotchas" section

---

## What You Should Do Next

1. **Pull the changes:** `git pull origin main`
2. **Verify build:** `xcodebuild -project Buddian.xcodeproj -scheme Buddian -destination 'platform=iOS Simulator,name=iPhone 16' build`
3. **Fix any compilation errors** from the removed `PollinationsClient`
4. **Test the full flow:**
   - Sign in with Apple
   - Fetch models (should show 78 models including 3 Pollinations)
   - Select a Pollinations model (e.g., `pollinations/flux`)
   - Enter prompt, tap Generate
   - Should see "Generating... (queued)" → "running" → "completed"
   - Result image should display inline
5. **Review `IOS_API.md`** for the complete API contract
6. **Test edge cases:** network error, timeout, failed generation

---

## Backend Changes (for reference)

These are in the `buddian` repo, already deployed:
- `.env`: Added `POLLINATIONS_API_KEY` and `POLLINATIONS_APP_KEY`
- `.env.example`: Added placeholders for both keys
- `api/workers/generation_worker.py`: Worker uses `POLLINATIONS_API_KEY` with `Authorization: Bearer` header
- `api/main.py`: Added 3 Pollinations models to `GENERATION_MODELS` (flux, gptimage, seedream)
- `credentials.sh`: Falls back to Pollinations when `GEMINI_API_KEY` is absent

---

## API Contract Summary

All generation goes through Buddian API. Key endpoints the iOS app uses:

| Endpoint | Method | Auth | Purpose |
|----------|--------|------|---------|
| `POST /web/auth/firebase` | POST | None | Exchange Firebase token → session |
| `GET /models` | GET | None | List all models (including free Pollinations) |
| `POST /generations` | POST | Bearer | Submit generation job |
| `GET /generations` | GET | Bearer | List user's jobs |
| `GET /generations/{id}` | GET | Bearer | Poll job status |
| `GET /generations/{id}/result` | GET | None | Download result image |
| `GET /web/me` | GET | Bearer | User balance + transactions |
