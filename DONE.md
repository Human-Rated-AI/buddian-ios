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

- Created `AIModel` struct with sample data (6 models: SDXL, DALL·E 3, Flux Pro, SVD, plus confidential variants)
- `ModelsView` shows models grouped by tier (Standard/Confidential)
- Each row shows name, type badge, description, and price per unit
- Verified: build succeeds on iPhone 17 simulator
- Files: `Buddian/Models/AIModel.swift`, `Buddian/Views/ModelsView.swift`

## Step 6: Ask Tab — Prompt Composer ✅

- Created `AskView` with tier selector (Standard/Confidential), model picker, prompt text editor
- Shows estimated cost based on selected model
- Generate button disabled when prompt is empty or no model selected
- Verified: build succeeds on iPhone 17 simulator
- Files: `Buddian/Views/AskView.swift`
