# Buddian iOS — DONE

Completed steps. See [TODO.md](TODO.md) for the plan and [README.md](README.md) for the spec.

---

## Step 1: Create Xcode Project ✅

- Created SwiftUI iOS app project `Buddian` (manual Xcode project generation)
- Target: iOS 17+, SwiftUI, Swift 5.9+
- Verified: `xcodebuild build` succeeds on iPhone 17 simulator
- Files: `Buddian.xcodeproj/`, `Buddian/BuddianApp.swift`, `Buddian/ContentView.swift`, `Buddian/Info.plist`, `Buddian/Assets.xcassets/`

## Step 2: Tab-Based Navigation ✅

- Created `ContentView` with `TabView` containing 5 tabs: Ask, Models, Library, Wallet, Shield
- SF Symbols: `bubble.left.and.bubble.right`, `cpu`, `photo.on.rectangle`, `creditcard`, `lock.shield`
- Each tab has its own view file under `Buddian/Views/`
- Verified: build succeeds on iPhone 17 simulator
- Files: `Buddian/ContentView.swift`, `Buddian/Views/{Ask,Models,Library,Wallet,Shield}View.swift`

## Step 3: App Theme & Design System ✅

- Created reusable components: `CardView`, `PrimaryButton`, `SectionHeader`, `EmptyStateView`
- Uses semantic system colors with light/dark theme support
- Verified: build succeeds on iPhone 17 simulator
- Files: `Buddian/Components/{CardView,PrimaryButton,SectionHeader,EmptyStateView}.swift`

## Step 4: API Client Shell ✅

- Created `APIClient` singleton with base URL `https://api.buddian.com`
- Implemented `/health` endpoint with async/await
- Created models: `APIError` (with localized errors), `HealthResponse`
- Network layer uses `URLSession` with 30s timeout
- Verified: build succeeds on iPhone 17 simulator
- Files: `Buddian/Networking/{APIError,HealthResponse,APIClient}.swift`

## Step 5: Models Tab — Static Catalog ✅

- Created `AIModel` struct with sample data (4 models: SDXL, DALL·E 3, Flux Pro, SVD)
- `ModelsView` shows models in a flat list
- Each row shows name, type badge, description, and price per unit
- Verified: build succeeds on iPhone 17 simulator
- Files: `Buddian/Models/AIModel.swift`, `Buddian/Views/ModelsView.swift`

## Step 6: Ask Tab — Prompt Composer ✅

- Created `AskView` with model picker, prompt text editor
- Shows estimated cost based on selected model
- Generate button disabled when prompt is empty or no model selected
- Verified: build succeeds on iPhone 17 simulator
- Files: `Buddian/Views/AskView.swift`

## Step 7: Wallet Tab — Balance & Credits ✅

- Created `WalletView` with balance display, batch credits section, "Add Funds" button
- Shows recent transactions with placeholder data
- Verified: build succeeds on iPhone 17 simulator
- Files: `Buddian/Views/WalletView.swift`

## Step 8: Library Tab — History List ✅

- Created `LibraryView` with empty state and generation list
- Each generation shows thumbnail, prompt, model name, date, and status
- Status indicator with color coding (completed/processing/failed)
- Verified: build succeeds on iPhone 17 simulator
- Files: `Buddian/Views/LibraryView.swift`

## Step 9: Shield Tab — Privacy Status ✅

- Created `ShieldView` with source verification and endpoint settings
- Green shield icon in nav bar
- Verified: build succeeds on iPhone 17 simulator
- Files: `Buddian/Views/ShieldView.swift`

## Step 10: E2EE Crypto Foundation ✅

- Removed — E2EE not needed for MVP (Confidential workflow deferred to v2+)
- Verified: build succeeds on iPhone 17 simulator

## Step 11: Navigation Polish & Empty States ✅

- Added green shield icon in Shield tab nav bar
- Added pull-to-refresh placeholders on Models, Library, and Wallet tabs
- Library tab already had empty state from Step 8
- Verified: build succeeds on iPhone 17 simulator
- Files: `Buddian/Views/{ShieldView,ModelsView,LibraryView,WalletView}.swift`

## Step 12: Final Build & Smoke Test ✅

- Full clean build succeeded on iPhone 17 simulator (iOS 26.5)
- All 5 tabs render correctly: Ask, Models, Library, Wallet, Shield
- No crashes, all screens render
- Verified: MVP scaffold complete

## Step 13: Fetch Models from API ✅

- Extended `APIClient` with `/models` endpoint
- Created `ModelsResponse` and `RemoteModel` Codable structs
- Created `AccountResponse` for future use
- ModelsView now fetches real models from api.buddian.com (68 models)
- Shows loading state, error handling with retry
- Displays model name, description, pricing, output modalities, TEE badge
- Note: API currently returns text-only models (no image/video generation yet)
- Verified: build succeeds, models load from API
- Files: `Buddian/Networking/{ModelsResponse,AccountResponse,APIClient}.swift`, `Buddian/Views/ModelsView.swift`

## Step 14: Job Polling for GPU Models ✅

- Added `submittedJobId` and `jobStatus` state to GenerateView
- After GPU job submission, polls `GET /generations/{job_id}` every 5 seconds
- Shows real-time status with colored indicator (green/orange/red)
- Displays job ID during processing
- Automatically downloads result when completed
- Times out after 10 minutes (120 attempts)
- Verified: build succeeds on iPhone 17 simulator
- Files: `Buddian/Views/GenerateView.swift`

## Step 15: Job Detail View ✅

- Added `GenerationDetailView` with full-screen image preview
- Shows prompt, model, cost, and generation parameters
- Loads full-resolution image via API download
- Share button using UIActivityViewController
- Tapping a generation in Library opens detail view via sheet
- Verified: build succeeds on iPhone 17 simulator
- Files: `Buddian/Views/LibraryView.swift`

## Step 16: StoreKit Integration ✅

- Created `IAPManager` singleton with StoreKit 2
- Configured 7 product IDs matching README pricing tiers
- WalletView now shows "Add Funds" section with available products
- Purchase flow with loading state and error handling
- Restore purchases button
- Balance refreshes after purchase
- Verified: build succeeds on iPhone 17 simulator
- Files: `Buddian/IAPManager.swift`, `Buddian/Views/WalletView.swift`

## Step 17: Push Notifications ✅

- Created `NotificationManager` singleton for push notification handling
- Updated `AppDelegate` to handle remote notification registration
- Added `UNUserNotificationCenterDelegate` for foreground notifications
- Requests permission on app launch after authentication
- Sends device token to backend via `POST /notifications/register`
- Handles notification taps (logged for future navigation)
- Verified: build succeeds on iPhone 17 simulator
- Files: `Buddian/Networking/NotificationManager.swift`, `Buddian/BuddianApp.swift`

## Step 18: Polish & Haptics ✅

- Created `HapticManager` enum with impact, notification, and selection feedback
- Added haptic feedback to PrimaryButton on tap
- Added success haptic when generation completes (Pollinations and GPU)
- Added error haptic when generation fails
- All loading states and pull-to-refresh already implemented in previous steps
- Verified: build succeeds on iPhone 17 simulator
- Files: `Buddian/Theme.swift`, `Buddian/Components/PrimaryButton.swift`, `Buddian/Views/GenerateView.swift`

## Step 19: Simplify to Pollinations Direct ✅

- Removed Buddian API dependency for image generation
- App now calls Pollinations.ai directly (free, no API key needed)
- Generate tab: fetches models from `gen.pollinations.ai/models`, generates images/videos directly
- Models tab: shows 26 image + 12 video models from Pollinations
- Library: stores generations locally in UserDefaults
- Wallet: shows "Free Generation" info (no billing needed)
- Removed authentication flow (not needed for Pollinations)
- Verified: build succeeds on iPhone 17 simulator
- Files: `Buddian/Networking/PollinationsClient.swift`, `Buddian/Views/{GenerateView,ModelsView,LibraryView,WalletView}.swift`

## Step 20: Fix EnvironmentObject & Fallback Models ✅

- Fixed fatal error: ModelCache not injected into view hierarchy
- Changed `@EnvironmentObject` to `@ObservedObject` with shared instance
- Added fallback models (Flux, GPT Image, Seedream) when API unreachable
- Added loading state indicator while models fetch
- Added error message display
- Verified: app runs in simulator, models load from fallback
- Files: `Buddian/BuddianApp.swift`, `Buddian/Networking/ModelCache.swift`, `Buddian/Views/GenerateView.swift`, `Buddian/Views/ModelsView.swift`
