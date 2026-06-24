# Buddian iOS — MVP TODO

Step-by-step plan for the MVP. See [README.md](README.md) for full spec.
See [DONE.md](DONE.md) for completed steps.

---

## ~~Step 1: Create Xcode Project~~ ✅

- ~~Create SwiftUI iOS app project `Buddian` via `swift package init` or manual Xcode project generation~~
- ~~Target: iOS 17+, SwiftUI, Swift 5.9+~~
- ~~Verify: `xcodebuild build` succeeds~~
- ~~Commit: initial scaffold~~

## ~~Step 2: Tab-Based Navigation~~ ✅

- ~~Create `ContentView` with `TabView` containing 5 tabs: Ask, Models, Library, Wallet, Shield~~
- ~~Use SF Symbols for tab icons~~
- ~~Each tab gets its own view file under `Views/`~~
- ~~Verify: app launches in Simulator, all 5 tabs visible and tappable~~
- ~~Commit: tab navigation~~

## ~~Step 3: App Theme & Design System~~ ✅

- ~~Define color palette (semantic system colors, light/dark support)~~
- ~~Create reusable components: `CardView`, `PrimaryButton`, `SectionHeader`~~
- ~~Apply consistent padding, spacing, typography~~
- ~~Verify: all tabs render with consistent styling~~
- ~~Commit: design system~~

## ~~Step 4: API Client Shell~~ ✅

- ~~Create `APIClient` with base URL `https://api.buddian.com`~~
- ~~Implement `/health` endpoint check~~
- ~~Create models: `APIError`, `HealthResponse`~~
- ~~Add network layer with `URLSession`~~
- ~~Verify: health check returns response (or proper error if server unreachable)~~
- ~~Commit: API client~~

## ~~Step 5: Models Tab — Static Catalog~~ ✅

- ~~Create `ModelsView` with list of available models~~
- ~~Hardcode sample model data matching README pricing tiers~~
- ~~Show model name, type (image/video), pricing per unit~~
- ~~Verify: models list renders with correct data~~
- ~~Commit: models tab~~

## ~~Step 6: Ask Tab — Prompt Composer~~ ✅

- ~~Create `AskView` with: model selector, prompt text field, tier selector (Standard/Confidential)~~
- ~~Show estimated cost preview (placeholder calculation)~~
- ~~"Generate" button (disabled until valid input)~~
- ~~Verify: form renders, inputs are interactive, button state changes~~
- ~~Commit: ask tab~~

## ~~Step 7: Wallet Tab — Balance & Credits~~ ✅

- ~~Create `WalletView` with balance display, transaction list (placeholder data)~~
- ~~"Add Funds" button (StoreKit integration placeholder)~~
- ~~Show batch credit balance~~
- ~~Verify: wallet UI renders with placeholder data~~
- ~~Commit: wallet tab~~

## ~~Step 8: Library Tab — History List~~ ✅

- ~~Create `LibraryView` with past generations list (placeholder data)~~
- ~~Show thumbnail, prompt, date, status~~
- ~~Empty state with call-to-action~~
- ~~Verify: library renders, empty state shows correctly~~
- ~~Commit: library tab~~

## ~~Step 9: Shield Tab — Privacy Status~~ ✅

- ~~Create `ShieldView` with attestation status, key state, endpoint settings~~
- ~~Lock indicator in nav bar (green/gray/yellow/red)~~
- ~~Source verification display~~
- ~~Verify: shield tab renders with status indicators~~
- ~~Commit: shield tab~~

## Step 10: E2EE Crypto Foundation

- Port secp256k1 ECDH key generation to Swift
- Implement HKDF-SHA256 key derivation
- Implement AES-256-GCM encrypt/decrypt
- Create `CryptoManager` singleton
- Verify: unit tests pass for key gen, encrypt, decrypt roundtrip
- Commit: crypto foundation

## Step 11: Navigation Polish & Empty States

- Add nav bar titles, lock indicator
- Implement empty states for all tabs
- Add pull-to-refresh placeholders
- Verify: all tabs have proper nav bars and empty states
- Commit: navigation polish

## Step 12: Final Build & Smoke Test

- Full clean build
- Run in Simulator on latest iOS
- Test all 5 tabs navigate correctly
- Verify: no crashes, all screens render
- Commit: MVP ready
