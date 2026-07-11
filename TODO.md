# Buddian iOS — Remaining Work

## Handoff for macOS Agent

**Repo:** `Human-Rated-AI/buddian-ios` (pull latest `main`)
**Build:** `xcodebuild -project Buddian.xcodeproj -scheme Buddian -destination 'platform=iOS Simulator,name=iPhone 16' build`
**API:** `https://api.buddian.com` (live, deployed 2026-07-11)
**What works now:** Model catalog (78 models, 3 free Pollinations), submit generation, list generations, async image thumbnails in Library, direct Pollinations image generation (instant, free).

### Two generation paths

1. **Pollinations models** (`pollinations/flux`, `pollinations/gptimage`, `pollinations/seedream`): free, instant — `PollinationsClient.swift` calls `gen.pollinations.ai` directly, no server queue. Result displayed inline in GenerateView.
2. **GPU models** (SDXL, FLUX, etc.): paid, async — `POST /generations` queues a job, worker processes it, result saved to disk. iOS needs polling + download (not yet wired in UI).

### Auth flow

Apple Sign In → Firebase ID token → `POST /web/auth/firebase { id_token, platform: "ios" }` → session token stored in Keychain → `Bearer {token}` on all requests. Google Sign In deferred (repo inaccessible).

### Priority next steps

1. **Firebase Auth verification** — Apple Sign In is coded but needs testing on device. Google Sign In blocked.
2. **Models tab** — filter by image/video, tap to pre-select in Generate tab. Data already in `ModelCache.models`.
3. **Job polling** — for GPU models, poll `GET /generations/{job_id}` every 5s, show status, display result when completed.
4. **Job detail view** — tap job in Library → full-screen image preview + download button.
5. **Wallet tab** — balance display, StoreKit integration, purchase flow.

### Key files

| File | Lines | Purpose |
|------|-------|---------|
| `Buddian/Networking/PollinationsClient.swift` | 48 | Direct Pollinations API (free, instant) |
| `Buddian/Views/GenerateView.swift` | 198 | Generate tab with two paths |
| `Buddian/Views/LibraryView.swift` | 128 | History list with AsyncImage thumbnails |
| `Buddian/Networking/APIClient.swift` | 152 | All Buddian API calls |
| `Buddian/Networking/ModelsResponse.swift` | 77 | RemoteModel with pricing/params |
| `Buddian/Models/Generation.swift` | 98 | Generation model with status/result |
| `API_HANDOFF.md` | 170 | Full API contract |

### Gotchas

- `project.pbxproj` has been updated with `PollinationsClient.swift` — don't re-add it.
- All UI text to stderr, machine output to stdout (project rule).
- Backend returns `per_image` as string (e.g. `"0.04"`), not number — `UserPricing` handles this.
- `AsyncImage` requires no auth header; `/generations/{id}/result` is unauthenticated.
- Dark mode works via `.foregroundStyle(.primary)` / `.secondary` — use semantic colors.

---

## What's Built

- ✅ SwiftUI scaffold with 4 tabs (Generate, Models, Library, Wallet)
- ✅ API client: health check, fetch models, fetch account
- ✅ Model catalog: 75 models, filter by type, pricing display
- ✅ Model caching: loads on startup
- ✅ Account/balance display
- ✅ Reusable components: CardView, PrimaryButton, SectionHeader, EmptyStateView
- ✅ Theme system with dark mode
- ✅ Backend endpoints ready: auth, models, generations, balance

## MVP Tasks (v1)

### 1. Firebase Authentication

- [x] Add Firebase iOS SDK via Swift Package Manager
- [x] Add `GoogleService-Info.plist` (Firebase config, safe for public repo)
- [x] Implement Sign in with Apple (`AuthenticationServices`)
- [ ] Implement Google Sign In (`GoogleSignIn` framework) — deferred, repo inaccessible
- [x] Exchange Firebase ID token for Buddian session via `POST /web/auth/firebase`
- [x] Store session token in Keychain
- [x] Handle auth state: logged in → show app, logged out → show login screen
- [x] Auto-login on app launch if session token exists

### 2. Generate Tab

- [x] Model picker: list generation models (image/video), show pricing, select one
- [x] Prompt input: text field with character count
- [ ] Optional parameters: negative prompt, width, height, steps, cfg scale
- [x] Cost preview: show estimated cost before submission
- [x] Submit button → `POST /generations` → show "Job submitted" with job_id (for non-Pollinations models)
- [x] Direct Pollinations generation: Pollinations models generate instantly via direct API call
- [ ] Job status view: poll `GET /generations/{job_id}` every 5 seconds
- [x] Result view: show completed image (Pollinations: inline, queue: via result download)
- [ ] Error handling: insufficient balance, model not available, timeout

### 3. Models Tab

- [ ] List all generation models from `GET /models?output_modality=image` and `?output_modality=video`
- [ ] Filter chips: All / Image / Video
- [ ] Each model card: name, type badge, pricing, default parameters
- [ ] Tap model → navigate to Generate tab with model pre-selected

### 4. Library Tab

- [x] List past generation jobs from `GET /generations`
- [x] Each job card: model name, status badge, cost, date, thumbnail (AsyncImage)
- [ ] Tap job → detail view with result preview and download
- [x] Pull-to-refresh
- [x] Empty state: "No generations yet. Start creating!"

### 5. Wallet Tab

- [ ] Balance display from `GET /web/me` → `user.balance.available_usd`
- [ ] Transaction history from `GET /web/me` → `transactions[]`
- [ ] "Add Funds" button → StoreKit product list
- [ ] StoreKit products: Starter ($4.99), Pro ($9.99), Studio ($24.99)
- [ ] Purchase flow: buy → verify receipt → backend credits balance
- [ ] Balance refresh after purchase

### 6. Backend: StoreKit Verification

- [ ] Add `POST /storekit/verify` endpoint to backend
- [ ] Accept Apple receipt data, verify with Apple servers, credit user balance
- [ ] This is in the `buddian` repo, not this one — coordinate with backend session

### 7. Push Notifications

- [ ] Register for remote notifications
- [ ] Send device token to backend
- [ ] Backend sends notification when generation job completes
- [ ] Tap notification → open app → navigate to Library → show result

### 8. Polish

- [ ] Loading states for all async operations
- [ ] Error alerts with retry
- [ ] Pull-to-refresh on Library and Models
- [ ] Haptic feedback on actions
- [ ] App icon and launch screen
- [ ] Localization (English first, then Spanish/Russian)

## v2+ Tasks

### 9. Confidential Inference (Phala TEE)

- [ ] Add Shield tab
- [ ] Port E2EE crypto from `buddian-web` to Swift (secp256k1, HKDF, AES-GCM)
- [ ] Tier selector: Confidential / Standard
- [ ] Encrypted request flow: attestation → encrypt → send → decrypt → display
- [ ] Proof bundle download and verification

### 10. Batch Generation

- [ ] Batch prompt upload (multiple prompts)
- [ ] GPU time purchase via StoreKit (1hr/3hr/6hr/24hr packages)
- [ ] Progress view: X/Y completed
- [ ] Batch result download (ZIP)

### 11. Advanced Features

- [ ] Custom model deployment
- [ ] Model catalog from Hugging Face
- [ ] Batch job splitting across GPU sessions
- [ ] Encrypted media storage

## Verification

After each milestone:
- Build succeeds on `macos-latest` via GitHub Actions
- No secrets or credentials in git history
- All API calls work against production `api.buddian.com`
- UI renders correctly on iPhone SE (smallest) and iPhone 16 Pro Max (largest)
- Dark mode and light mode both look correct
