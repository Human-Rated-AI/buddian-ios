# Buddian iOS

Open source iOS client for Buddian, a private AI companion that helps users run confidential AI requests on remote secure GPUs.

Buddian is a coined name from "buddy" and "guardian": a helpful AI companion whose first job is to guard private work.

## Status

This repository is the public iOS client home. The first SwiftUI scaffold is not committed yet; this README defines the intended product, security model, and release verification workflow before implementation starts.

The App Store app may be a private host app that imports this repository as a pinned Swift package. This repository should contain the auditable user client core: authentication integration points, encrypted inference, model browsing, wallet balance/history display, proof verification, and the open-source host app. App Store-only live payments, production release automation, and admin-only UI can live in the private host while the security-sensitive client code remains shared.

The App Store binary is not the reproducibility target. Users who want maximum assurance should build and install this open-source app themselves with Xcode. The App Store app should disclose which public `buddian-ios` tag or commit it embeds, but platform packaging, signing, and distribution steps mean users should not be asked to compare the App Store binary byte-for-byte against a local build.

The production service is available at:

- Web app: https://buddian.com
- API: https://api.buddian.com
- Public web client: https://github.com/Human-Rated-AI/buddian-web

## Product Goal

Buddian for iOS should let users:

- Sign in with Apple or Google.
- List pre-installed secure AI models.
- Install and manage open-source AI models on remote secure GPU servers.
- Run encrypted text, image, audio, video, and file-based inference workflows as model support grows.
- See balance, spending, refunds, and usage history.
- Add funds in the App Store build.
- Upload inputs and download generated media while keeping plaintext local to the device.
- Verify that encrypted requests, encrypted responses, and proof bundles match the public client code.

## Planned Tabs

### Ask

Run encrypted inference with the active model. The screen should show the selected model, proof/lock state, cost preview, prompt composer, attachment button, send button, local decrypted result, and proof download.

### Models

Browse installed models, discover open-source models, deploy supported models to secure GPUs, stop billing, and remove deployments. Model rows should show capabilities, input/output media types, estimated user-facing cost, and proof state.

### Library

Keep local-first history and decrypted generated media. Chats, images, audio/video, and files should be browseable and exportable through the native iOS share sheet. Server-side encrypted media should remain unusable without the user's local key.

### Wallet

Show Buddian balance, transaction history, model spending, refunds, and runtime estimates. The App Store build should use StoreKit products for real balance top-ups after backend transaction verification.

### Shield

Explain and verify privacy. Show current attestation/proof state, local key state, source/release verification, proof bundle export, and advanced endpoint settings.

## Secrets Model

The preferred implementation shape is:

- `BuddianCore`: API models, auth session exchange, account state, ledger decoding, cost math, and feature flags.
- `BuddianCrypto`: local key handling, request encryption, response decryption, proof parsing, and test vectors.
- `BuddianUI`: Ask, Models, Library, Wallet, Shield, and reusable native SwiftUI components.
- `BuddianOpenApp`: the public app target with no live StoreKit purchases and no admin panel.

A private App Store host can import these targets at an exact tag or commit and add StoreKit live top-ups, production entitlements, release automation, and admin-only screens. Backend authorization remains the security boundary for admin access.

This repository may contain public client configuration:

- Firebase iOS app identifiers.
- Google Sign-In client IDs and URL schemes.
- Apple Sign in capability metadata.
- Public API defaults such as `https://api.buddian.com`.
- StoreKit product identifiers.

This repository must not contain:

- Buddian API signing secrets.
- Firebase service account JSON.
- Apple private keys or App Store Connect API private keys.
- Provider API keys.
- Payment webhook secrets.
- Database credentials.
- Admin-only configuration.

The backend verifies authentication, billing, provider access, payments, and admin rights. Provider keys never ship in the iOS app.

## Payments

The open-source local Xcode build should be able to log in and use an existing Buddian balance. Real balance purchases are planned for the App Store/TestFlight build through StoreKit and backend transaction verification.

Users who want to audit the client can:

1. Install the App Store build.
2. Add funds there.
3. Build this repository locally in Xcode.
4. Install the local build.
5. Log into the same account.
6. Use the same server-side balance with locally built client code.

Before enabling production payments, the implementation must re-check current Apple App Store and StoreKit requirements.

## Build And Verification Plan

The first working release should document:

1. Required Xcode and iOS versions.
2. Exact source tag.
3. Dependency lockfiles.
4. Build command or Xcode archive steps.
5. Public package checksum.
6. How to compare the checked-out source tag and lockfiles with the published release metadata.

The goal is that a technical user can build the open-source client locally and use it for inference with the same Buddian account, while server-side secrets remain private.

## Implementation Roadmap

1. Add SwiftUI app scaffold.
2. Add API client for health, config, models, account, ledger, media, and encrypted inference.
3. Add Firebase Auth with Apple and Google providers.
4. Port Buddian E2EE request encryption and response decryption to Swift.
5. Build Ask tab with encrypted text inference and proof download.
6. Build Wallet tab with balance and ledger history.
7. Add StoreKit product shell and backend verification endpoints.
8. Build Models tab for catalog, installation, deployment, and shutdown.
9. Build Library tab for local history and encrypted media workflows.
10. Build Shield tab for proof verification and source/release checks.

## Related Repositories

- Private backend/deployment: https://github.com/Human-Rated-AI/buddian
- Public web client: https://github.com/Human-Rated-AI/buddian-web
