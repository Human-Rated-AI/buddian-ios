# Buddian iOS

iOS client for Buddian — a private AI companion that generates images and videos on remote GPUs.

Buddian is a coined name from "buddy" and "guardian": a helpful AI companion whose first job is to guard private work.

## Status

**MVP (v1)**: Simple image/video generation via vast.ai. No confidential workflow yet. The App Store app is a private host app; this repository contains the auditable user client core. Users select a model, pay via Apple IAP, submit prompts, and view/download results. All generation runs on standard (non-encrypted) GPU compute.

**v2+**: Confidential inference via Phala TEE, custom model deployment, Hugging Face catalog, proof bundles.

The production service is at https://buddian.com (API: https://api.buddian.com).

## What's Built (as of 2026-07-11)

### iOS App (this repo)

- SwiftUI scaffold with 4 MVP tabs (Generate, Models, Library, Wallet)
- API client (`APIClient.swift`) — health check, fetch models, fetch account, submit/list generations
- Pollinations client (`PollinationsClient.swift`) — direct free image generation, no server queue
- Generate tab — model picker, prompt input, cost preview, direct Pollinations generation, queue submission for GPU models, inline result image display
- Library tab — AsyncImage thumbnails for completed generations, pull-to-refresh, empty state
- Model catalog — fetches from `/models`, filters by output modality, shows pricing
- Model caching — loads on startup, stores in memory with 1-hour TTL
- Account/balance display from `/web/me`
- Reusable components: CardView, PrimaryButton, SectionHeader, EmptyStateView
- Theme system with dark mode
- 19 Swift files, ~1000 lines total

### Backend (buddian repo) — deployed and ready

| Endpoint | Method | Auth | Status | iOS Use |
|----------|--------|------|--------|---------|
| `/health` | GET | None | ✅ Working | Startup check |
| `/web/config` | GET | None | ✅ Working | Firebase setup |
| `/web/auth/firebase` | POST | Firebase token | ✅ Working | Login (accepts `platform: "ios"`) |
| `/web/me` | GET | Session | ✅ Working | Balance, transactions, providerData |
| `/models` | GET | None | ✅ Working | 78 models (67 text + 7 image + 4 video) |
| `/generations` | POST | Session | ✅ Working | Submit generation job (GPU models) |
| `/generations` | GET | Session | ✅ Working | List user's generation jobs |
| `/generations/{id}` | GET | Session | ✅ Working | Poll job status |
| `/generations/{id}/result` | GET | None | ✅ Working | Download result image |

**Pollinations.ai models** (`pollinations/flux`, `pollinations/gptimage`, `pollinations/seedream`) are listed as free in `/models`. The iOS app calls Pollinations directly for instant results — no server queue needed.

**GPU models** (SDXL, SD3, FLUX, etc.) still go through the server queue → worker pipeline.

### Backend model catalog

`GET /models` returns 78 models including 3 free Pollinations.ai models:

**Pollinations.ai models (free, instant, no GPU):**

```json
{
  "id": "pollinations/flux",
  "name": "Flux (Pollinations)",
  "type": "image_generation",
  "status": "free",
  "user_pricing": { "currency": "USD", "per_image": "0" },
  "default_width": 1024,
  "default_height": 1024
}
```

Available Pollinations models: `pollinations/flux`, `pollinations/gptimage`, `pollinations/seedream`.

**GPU models (paid, async queue):**

```json
{
  "id": "black-forest-labs/flux-1.1-pro",
  "name": "FLUX 1.1 Pro",
  "type": "image_generation",
  "user_pricing": { "currency": "USD", "per_image": "0.04" },
  "default_width": 1024,
  "default_height": 1024,
  "default_steps": 28,
  "default_cfg_scale": 3.5
}
```

Filter by modality: `GET /models?output_modality=image` or `?output_modality=video`.

Generation models available: 3 Pollinations (free) + SDXL, SD3, FLUX 1.1 Pro, FLUX Schnell, Stable Video Diffusion, Mochi 1, Ray 2 Flash, Wan 2.1, Seedance 2.

## MVP: Simple GPU Generation

### User Flow

1. Open app → see available models (image/video generation)
2. Select model → see pricing per image/second
3. Pay via Apple IAP → credits added to balance
4. Submit prompts → GPU processes job async
5. Get notification when ready → view/download results
6. View past jobs (videos and images generated)

### Key Design Decisions

- **Async processing**: User submits request, closes app, gets notification when ready, comes back to view results.
- **GPU lifecycle**: GPU allocated only when batch starts. Idle timeout (30s no activity) shuts down GPU. User pays only for GPU usage time.
- **Pricing**: Must cover Apple's 30% commission + payment processing. Target: match or beat vast.ai's listed prices.
- **Competitive pricing**: 2X markup on raw GPU cost undercuts existing services while generating revenue to fund the future encrypted tier.
- **Non-confidential**: All MVP generation is standard-tier (non-encrypted) via vast.ai.

### Future Features (v2+)

- Confidential inference via Phala TEE
- Custom model deployment
- Batch job splitting across GPU sessions
- Model catalog from Hugging Face
- Proof bundles and attestation

## Product Shape

The app should feel like a native Apple productivity app: quiet, fast, clear, and confidence-building. Use SwiftUI, semantic system colors, Dynamic Type, VoiceOver labels, system SF Symbols, and first-class light/dark themes.

Two primary workflows:

1. **Image generation (free, instant)**: Select a Pollinations model, enter prompt, generate image instantly via direct API call, view/download. No payment required.
2. **Image/Video generation (paid, async)**: Select a GPU model (FLUX, SDXL, etc.), pay via Apple IAP, submit prompts, GPU processes job async, get notification when ready, view/download results.

**MVP scope:** Standard-tier generation only (non-encrypted, via vast.ai). Confidential inference is v2+.

## Navigation

Bottom `TabView` with five tabs:

**MVP tabs:**

1. **Generate** — Select model, enter prompt, see pricing per image/second, submit generation job, view results, download.
2. **Models** — Browse available generation models (image/video), see pricing, filter by type.
3. **Library** — Job history: past generations, images, videos. Re-download results.
4. **Wallet** — Balance, transaction history, "Add Funds" (StoreKit), spending breakdown.

**v2+ tabs:**

5. **Shield** — Privacy verification: attestation/proof state, local key state, source/release verification, proof bundle export, endpoint settings.

## Pricing (Apple IAP)

| Product | Price | GPU time | Est. images | Est. video sec |
| --- | ---: | ---: | ---: | ---: |
| Starter | $4.99 | ~40 min | ~80 | ~13 |
| Pro | $9.99 | ~100 min | ~200 | ~34 |
| Studio | $24.99 | ~280 min | ~560 | ~94 |
| 1-Hour | $1.99 | ~1 hr | ~200 | ~34 |
| 3-Hour | $4.99 | ~3 hr | ~600 | ~100 |
| 6-Hour | $9.99 | ~6 hr | ~1,200 | ~200 |
| 24-Hour | $39.99 | ~24 hr | ~4,800 | ~800 |

Apple takes 30%. Prices include margin for Apple fees, processing, and GPU costs.

## E2EE Crypto (v2+)

Same as `buddian-web`: secp256k1 ECDH, HKDF-SHA256 (`ecdsa_encryption`), AES-256-GCM. Key: 64-byte uncompressed public key. Ciphertext: `ephemeralPublicKey || nonce || ciphertext` (hex).

## Repositories

| Repo | URL | Purpose |
| --- | --- | --- |
| `buddian-ios` | https://github.com/Human-Rated-AI/buddian-ios | iOS app (this repo, **public**) |
| `buddian` | https://github.com/Human-Rated-AI/buddian | Backend API (private) |
| `buddian-web` | https://github.com/Human-Rated-AI/buddian-web | Web client (E2EE reference) |
| `buddian-proxy` | https://github.com/Human-Rated-AI/buddian-proxy | Local E2EE proxy |

## Secrets Model

This is a **public** repository. It must NOT contain:

- API signing secrets
- Firebase service account
- Apple private keys (`.p12`, `.p8`)
- Provider API keys (vast.ai, Phala, etc.)
- Payment webhook secrets
- Database credentials
- `.env` files

This MAY contain:

- Firebase iOS config (`GoogleService-Info.plist`) — these are client-side and safe for public repos
- Apple Sign-In entitlements
- API base URL (`https://api.buddian.com`)
- StoreKit product IDs
- Build configuration

## CI/CD: GitHub Actions (macOS)

This repo is public, which gives **unlimited** macOS runner minutes on GitHub Actions.

### Build Workflow

Create `.github/workflows/build.yml`:

```yaml
name: Build
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]
jobs:
  build:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4
      - name: Build
        run: xcodebuild -project Buddian.xcodeproj -scheme Buddian -destination 'platform=iOS Simulator,name=iPhone 16' build
      - name: Test
        run: xcodebuild test -project Buddian.xcodeproj -scheme Buddian -destination 'platform=iOS Simulator,name=iPhone 16' || true
```

### Why macOS is needed

- SwiftUI requires Apple frameworks (`SwiftUI`, `UIKit`, `AuthenticationServices`)
- These frameworks don't exist on Linux — Swift on Linux cannot compile SwiftUI apps
- Xcode is only available on macOS
- Ubuntu can do syntax-only checks (`swiftc -parse`) but not full compilation

## Backend API Details

See `API_HANDOFF.md` for full endpoint specifications with request/response formats.

Key points for iOS integration:

- **Auth**: `POST /web/auth/firebase` with `{ id_token, platform: "ios" }` → returns `{ session_token, account }`. Use `Bearer {session_token}` for all authenticated requests.
- **Models**: `GET /models` returns all 75 models. Filter: `?output_modality=image` or `?output_modality=video`. Each model has `id`, `name`, `type`, `output_modalities`, `user_pricing`, `default_width/height/steps/cfg_scale`.
- **Generations**: `POST /generations` with `{ model_id, prompt, negative_prompt, width, height, steps, cfg_scale, num_images }` → returns `{ job_id, status, estimated_seconds, cost_estimate }`. Poll with `GET /generations/{job_id}` for status and result.
- **Balance**: `GET /web/me` returns `user.balance.available_usd` and `transactions[]`.
- **Job history**: `GET /generations` returns all user's generation jobs with status, cost, timing.

## Key Files to Reference (in `buddian` repo)

| File | Lines | Contents |
| --- | --- | --- |
| Auth flow | `api/main.py` 5516+ | `/web/auth/firebase` session exchange |
| Models | `api/main.py` 5811+ | `/models` catalog with generation entries |
| Generations | `api/main.py` 6327+ | `/generations` queue endpoints |
| Billing | `api/main.py` 4936+ | Cost calculation, ledger entries |
| E2EE crypto | `web/app.js` 379-653 | secp256k1, HKDF, AES-GCM (v2+ reference) |
| User payload | `api/main.py` 4865+ | `/web/me` response shape |

## Implementation Milestones

1. ✅ SwiftUI scaffold + Xcode build verification
2. ✅ API client (health, config, models, account)
3. ✅ Model catalog with generation models (image/video) + Pollinations (free)
4. ⬜ Firebase Auth (Apple + Google Sign In)
5. ✅ Generate tab: model selection, prompt, submit job, Pollinations instant generation, result display
6. ⬜ Models tab: browse with filter by type
7. ✅ Library tab: generation history with AsyncImage thumbnails, pull-to-refresh
8. ⬜ Wallet tab: balance, ledger, StoreKit integration
9. ⬜ StoreKit transaction verification endpoint (backend)
10. ⬜ Push notifications for job completion
11. ⬜ Unit tests
12. ⬜ TestFlight / App Store configuration
13. ⬜ (v2+) E2EE client port from `buddian-web` to Swift
14. ⬜ (v2+) Shield tab: proof verification, source checks

## Design Guardrails

- One primary action per screen
- Cost shown before every billable action
- Balance visible near billable actions
- Clear empty states with single next step
- No admin UI in public app
- No provider pricing/balance in user screens
- Native sheets for model selection, top-up
