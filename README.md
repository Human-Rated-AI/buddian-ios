# Buddian iOS

Open source iOS client for Buddian, a private AI companion that helps users run confidential AI requests on remote secure GPUs.

Buddian is a coined name from "buddy" and "guardian": a helpful AI companion whose first job is to guard private work.

## Status

MVP focus: simple image/video generation via vast.ai (non-confidential). Confidential inference via Phala TEE is v2+.

The App Store app may be a private host app that imports this repository as a pinned Swift package. This repository contains the auditable user client core. App Store-only live payments, production release automation, and admin-only UI live in the private host.

The production service is available at:

- Web app: https://buddian.com
- API: https://api.buddian.com
- Public web client: https://github.com/Human-Rated-AI/buddian-web

## MVP: Simple GPU Generation (v1)

**User flow** (one-way, simple):

1. Open app → see available models (image/video generation)
2. Select model → see pricing per image/second
3. Select GPU type/usage → estimate cost
4. Pay via Apple IAP → credits added
5. Submit prompts → GPU processes batch
6. Get notification when ready → view/download results
7. View past jobs (inc. videos and images generated)

**Key design decisions**:

- **Async processing**: User submits request, closes app, gets notification when ready, comes back to view results.
- **GPU lifecycle**: GPU allocated only when batch starts. Idle timeout (30s no user activity) shuts down GPU. User pays only for GPU usage time.
- **Pricing**: Must cover Apple's 30% commission + payment processing. Target: match or beat vast.ai's listed prices.
- **Two inference tiers**: "Confidential" (Phala TEE, premium) and "Standard" (vast.ai, cheaper).

**Future features (v2+)**:

- Confidential inference via Phala TEE
- Custom model deployment
- Batch job splitting across GPU sessions
- Model catalog from Hugging Face
- Proof bundles and attestation

## Related Repositories

| Repo | URL | Purpose |
| --- | --- | --- |
| `buddian-ios` | https://github.com/Human-Rated-AI/buddian-ios | iOS app (this repo) |
| `buddian` (private) | https://github.com/Human-Rated-AI/buddian | Backend API, admin, deployment |
| `buddian-web` | https://github.com/Human-Rated-AI/buddian-web | Public web client (reference for E2EE crypto) |
| `buddian-proxy` | https://github.com/Human-Rated-AI/buddian-proxy | Local E2EE proxy for editors |

## Backend API Endpoints

| Endpoint | Method | Auth | Purpose |
| --- | --- | --- |--- |
| `/health` | GET | None | API health check |
| `/web/config` | GET | None | Firebase config, payment links |
| `/web/auth/firebase` | POST | Firebase ID token | Session exchange |
| `/web/me` | GET | Session | User profile, balance, transactions |
| `/models` | GET | None | Model catalog (68 models) |
| `/e2ee/attestation` | POST | Session | Get TEE attestation for model |
| `/e2ee/chat/completions` | POST | Session | Encrypted inference |
| `/e2ee/signature/{id}` | GET | Session | Response signature |
| `/pricing/chat-quote` | POST | Session | Estimate text token cost |
| `/billing/ledger` | GET | Session | Transaction history |
| `/admin/overview` | GET | Admin | Provider balances, users |
| `/installable-models` | GET | Session | Installable model sources |
| `/custom-models/jobs` | GET/POST | Session | Custom model job queue |

## Two-Tier Inference

Users choose between two tiers:

| Tier | Provider | Security | Price |
| --- | --- | --- | --- |
| Confidential (TEE) | Phala Cloud | GPU TEE, encrypted inference | Higher |
| Standard | vast.ai | Raw GPU compute | Lower |

Backend routes requests to the appropriate provider based on tier selection.

## E2EE Crypto (for iOS port)

The iOS app should use the same crypto as `buddian-web`:

- **Key exchange**: secp256k1 ECDH
- **Key derivation**: HKDF-SHA256 with `ecdsa_encryption` info
- **Encryption**: AES-256-GCM
- **Key format**: 64-byte uncompressed public key (no 04 prefix)
- **Ciphertext format**: `ephemeralPublicKey || nonce || ciphertext` (hex)

Reference: `buddian-web/src/crypto.js` lines 379-653

## Key Files to Reference (in `buddian` repo)

| File | Path | What it contains |
| --- | --- | --- |
| E2EE crypto | `web/app.js` lines 379-653 | secp256k1, HKDF, AES-GCM, attestation verification |
| Model catalog | `api/main.py` line 5608+ | `/models` endpoint, pricing, filtering |
| Billing | `api/main.py` line 4936+ | `chat_cost_from_model`, reconciliation |
| Proof bundles | `web/app.js` line 2614+ | `buddian.e2ee-proof-bundle.v1` format |
| Auth flow | `web/app.js` line 1755+ | Firebase session exchange |

## iOS-Specific Notes

- Use the same E2EE crypto as `buddian-web` (secp256k1 ECDH + HKDF-SHA256 + AES-GCM)
- Call the same API endpoints as the web client
- Firebase config is public and can be embedded in the iOS app
- Provider API keys never ship to the iOS app
- Verify attestation the same way as the web client

## Secrets Model

This repository may contain:

- Firebase iOS app identifiers
- Google Sign-In client IDs and URL schemes
- Apple Sign in capability metadata
- Public API defaults (`https://api.buddian.com`)
- StoreKit product identifiers

This repository must not contain:

- Buddian API signing secrets
- Firebase service account JSON
- Apple private keys or App Store Connect API private keys
- Provider API keys
- Payment webhook secrets
- Database credentials

## Build And Verification

1. Required Xcode and iOS versions
2. Exact source tag
3. Dependency lockfiles
4. Build command or Xcode archive steps
5. Public package checksum
6. Compare checked-out source tag and lockfiles with published release metadata
