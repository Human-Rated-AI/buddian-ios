# Buddian iOS — Remaining Work

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
- [ ] Implement Google Sign In (`GoogleSignIn` framework)
- [x] Exchange Firebase ID token for Buddian session via `POST /web/auth/firebase`
- [x] Store session token in Keychain
- [x] Handle auth state: logged in → show app, logged out → show login screen
- [x] Auto-login on app launch if session token exists

### 2. Generate Tab

- [ ] Model picker: list generation models (image/video), show pricing, select one
- [ ] Prompt input: text field with character count
- [ ] Optional parameters: negative prompt, width, height, steps, cfg scale
- [ ] Cost preview: show estimated cost before submission
- [ ] Submit button → `POST /generations` → show "Job submitted" with job_id
- [ ] Job status view: poll `GET /generations/{job_id}` every 5 seconds
- [ ] Result view: show completed image/video, download button
- [ ] Error handling: insufficient balance, model not available, timeout

### 3. Models Tab

- [ ] List all generation models from `GET /models?output_modality=image` and `?output_modality=video`
- [ ] Filter chips: All / Image / Video
- [ ] Each model card: name, type badge, pricing, default parameters
- [ ] Tap model → navigate to Generate tab with model pre-selected

### 4. Library Tab

- [ ] List past generation jobs from `GET /generations`
- [ ] Each job card: model name, status badge, cost, date, thumbnail
- [ ] Tap job → detail view with result preview and download
- [ ] Pull-to-refresh
- [ ] Empty state: "No generations yet. Start creating!"

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
