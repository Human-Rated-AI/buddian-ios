# Buddian iOS

iOS client for Buddian — a private AI companion that generates images and videos on remote GPUs with hardware-encrypted privacy.

Buddian is a coined name from "buddy" and "guardian": a helpful AI companion whose first job is to guard private work.

## Status

**MVP (v1)**: Simple image/video generation via vast.ai. No confidential workflow yet. The App Store app is a private host app; this repository contains the auditable user client core. Users select a model, pay via Apple IAP, submit prompts, and view/download results. All generation runs on standard (non-encrypted) GPU compute.

**v2+**: Confidential inference via Phala TEE, custom model deployment, Hugging Face catalog, proof bundles.

The production service is at https://buddian.com (API: https://api.buddian.com).

## MVP: Simple GPU Generation

### User Flow

1. Open app → see available models (image/video generation)
2. Select model → see pricing per image/second
3. Select GPU type/usage → estimate cost
4. Pay via Apple IAP → credits added
5. Submit prompts → GPU processes batch
6. Get notification when ready → view/download results
7. View past jobs (videos and images generated)

### Key Design Decisions

- **Async processing**: User submits request, closes app, gets notification when ready, comes back to view results.
- **GPU lifecycle**: GPU allocated only when batch starts. Idle timeout (30s no activity) shuts down GPU. User pays only for GPU usage time.
- **Pricing**: Must cover Apple's 30% commission + payment processing. Target: match or beat vast.ai's listed prices.
- **Competitive pricing**: 2X markup on raw GPU cost undercuts existing services while generating revenue to fund the future encrypted tier.

### Future Features (v2+)

- Confidential inference via Phala TEE
- Custom model deployment
- Batch job splitting across GPU sessions
- Model catalog from Hugging Face
- Proof bundles and attestation

## Product Shape

The app should feel like a native Apple productivity app: quiet, fast, clear, and confidence-building. Use SwiftUI, semantic system colors, Dynamic Type, VoiceOver labels, system SF Symbols, and first-class light/dark themes.

Two primary workflows:

1. **Image generation**: Select model (FLUX, SDXL, SD3), enter prompt, generate image, download.
2. **Video generation**: Select model (Seedance 2, Mochi 1, Ray 2 Flash, Wan 2.1), enter prompt, generate video, download.

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

## Batch Generation (v2+ Feature)

The MVP uses simple per-generation pricing. Batch generation with GPU time packages is a v2+ feature.

### GPU Availability (v2+)

- GPU up (shared session): buy any increment (1hr, 3hr, 6hr).
- GPU down: must buy 24hr minimum ($39.99).

### Batch Job Lifecycle (v2+)

1. Queued → prompts queued for processing
2. Provisioning → GPU allocated
3. Running → inference in batches, progress X/Y
4. Completed → results available for download
5. Idle → GPU stays for remaining purchased time, then shuts down

### Pricing (Apple IAP)

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

## Two-Tier Inference (v2+)

The MVP uses standard (non-encrypted) vast.ai only. The two-tier model is a v2+ feature.

| Tier | Provider | Security | Price |
| --- | --- | --- | --- |
| Confidential (TEE) | Phala Cloud | GPU TEE, encrypted | Higher |
| Standard | vast.ai | Raw GPU compute | Lower |

## E2EE Crypto

Same as `buddian-web`: secp256k1 ECDH, HKDF-SHA256 (`ecdsa_encryption`), AES-256-GCM. Key: 64-byte uncompressed public key. Ciphertext: `ephemeralPublicKey || nonce || ciphertext` (hex).

## Backend API Endpoints

| Endpoint | Method | Auth | Purpose |
| --- | --- | --- |--- |
| `/health` | GET | None | Health check |
| `/web/config` | GET | None | Firebase config |
| `/web/auth/firebase` | POST | Firebase token | Session exchange |
| `/web/me` | GET | Session | Profile, balance, transactions |
| `/models` | GET | None | Model catalog (68 models) |
| `/e2ee/attestation` | POST | Session | TEE attestation |
| `/e2ee/chat/completions` | POST | Session | Encrypted inference |
| `/pricing/chat-quote` | POST | Session | Cost estimate |
| `/billing/ledger` | GET | Session | Transaction history |
| `/installable-models` | GET | Session | Installable sources |
| `/custom-models/jobs` | GET/POST | Session | Job queue |

## Key Files to Reference (in `buddian` repo)

| File | Lines | Contents |
| --- | --- | --- |
| E2EE crypto | `web/app.js` 379-653 | secp256k1, HKDF, AES-GCM, attestation |
| Model catalog | `api/main.py` 5608+ | `/models`, pricing, filtering |
| Billing | `api/main.py` 4936+ | Cost calculation, reconciliation |
| Proof bundles | `web/app.js` 2614+ | `buddian.e2ee-proof-bundle.v1` |
| Auth flow | `web/app.js` 1755+ | Firebase session exchange |
| Batch jobs | `api/main.py` 2578+ | `custom_model_jobs` queue pattern |

## Repositories

| Repo | URL | Purpose |
| --- | --- | --- |
| `buddian-ios` | https://github.com/Human-Rated-AI/buddian-ios | iOS app (this repo) |
| `buddian` | https://github.com/Human-Rated-AI/buddian | Backend API (private) |
| `buddian-web` | https://github.com/Human-Rated-AI/buddian-web | Web client (E2EE reference) |
| `buddian-proxy` | https://github.com/Human-Rated-AI/buddian-proxy | Local E2EE proxy |

## Secrets Model

May contain: Firebase iOS config, Google Sign-In IDs, Apple Sign In metadata, API defaults (`https://api.buddian.com`), StoreKit product IDs.

Must NOT contain: API signing secrets, Firebase service account, Apple private keys, provider API keys, payment webhook secrets, database credentials.

## Backend Work Required

- iOS session exchange endpoint
- StoreKit transaction verification
- Batch generation queue endpoint
- GPU-time credit purchase endpoint
- Batch result download (individual or ZIP)
- Apple IAP receipt verification

## Design Guardrails

- One primary action per screen
- Cost shown before every billable action
- Balance and proof state visible near billable actions
- Clear empty states with single next step
- No admin UI in public app
- No provider pricing/balance in user screens
- Native sheets for model selection, top-up, proof, export

## Implementation Milestones

1. SwiftUI scaffold + Xcode build verification
2. API client (health, config, models, account, ledger, auth)
3. Firebase Auth (Apple + Google)
4. E2EE client port from `buddian-web` to Swift
5. Ask tab: model selection, quote, encrypted inference, proof download
6. Batch tab: prompt upload, GPU-time purchase, progress, results
7. Wallet tab: balance, ledger, batch credits, StoreKit shell
8. StoreKit transaction verification endpoint
9. Models tab: catalog, install, deploy, shutdown
10. Library tab: local history, encrypted media
11. Shield tab: proof verification, source checks
12. Unit tests for API, crypto, proof validation
13. TestFlight/App Store configuration

## Build And Verification

1. Required Xcode and iOS versions
2. Exact source tag
3. Dependency lockfiles
4. Build command
5. Public package checksum
6. Compare source tag and lockfiles with release metadata
