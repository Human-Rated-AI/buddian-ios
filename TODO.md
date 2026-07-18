# Buddian iOS — Remaining Work

## Handoff for macOS Agent

**Repo:** `Human-Rated-AI/buddian-ios` (pull latest `main`)
**Build:** `xcodebuild -project Buddian.xcodeproj -scheme Buddian -destination 'platform=iOS Simulator,name=iPhone 16' build`
**Backend repo:** `Human-Rated-AI/buddian` (see `API.md` for all endpoints)
**Product spec:** `iOSApp.md` in backend repo

### Product Pivot (2026-07-18)

Buddian is now an **AI video streaming and creation platform** with dual-wallet monetization:
- Users pay subscriptions ($14.99/mo, $59.99/6mo, $99.99/yr) for AI video generation seconds
- Users earn fiat money when other paid users watch their videos
- No free tier — everyone pays

### Architecture

```
iOS App → Buddian API (auth + generation + billing + streaming)
                ↓
Buddian API → GPU Provider (video generation)
```

### iOS API Endpoints (see API.md in backend repo)

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `POST /web/auth/firebase` | POST | Firebase token → session |
| `GET /users/me` | GET | Profile + dual wallet (generation seconds + fiat earned) |
| `POST /generate/request` | POST | Submit video generation |
| `GET /generate/status/{job_id}` | GET | Poll generation status |
| `GET /feed` | GET | Video feed for watching |
| `POST /player/track-view` | POST | Track watch time (anti-fraud) |
| `GET /videos/me` | GET | List user's generated videos |
| `PUT /videos/{id}` | PUT | Update video metadata |
| `DELETE /videos/{id}` | DELETE | Soft-delete video |
| `GET /videos/{id}/stats` | GET | Video analytics (views, earnings) |
| `POST /billing/subscribe` | POST | Subscribe via StoreKit |
| `POST /billing/top-up` | POST | Buy extra generation seconds (min $5) |

### iOS App Tabs

1. **Home (Feed)** — Vertical swipeable video feed (Reels/TikTok style)
2. **Create** — AI video generation prompt input, aspect ratio selector
3. **Studio (My Videos)** — Video list, swipe-left to delete, tap to edit/view stats
4. **Profile** — Dual wallet display (Fiat Earned + Generation Seconds + Subscription status)

### Priority Tasks for iOS Agent

1. **Restructure tabs** — Change from Generate/Models/Library/Wallet to Home/Create/Studio/Profile
2. **Video Feed** — Vertical swipeable feed with view tracking (ping API every X seconds while playing)
3. **Dual Wallet UI** — Profile tab shows fiat earned ($) and generation seconds (s) separately
4. **StoreKit Integration** — Subscription sheets for 3 tiers + top-up IAP (min $5)
5. **Push Notifications** — Register for remote notifications, send "Your video is ready!"
6. **Video Player** — HTML5 player with lifecycle hooks for accurate view tracking
7. **Content Manager** — Studio tab: list, edit metadata, delete, view stats per video
8. **Generation Flow** — Create tab: text input, aspect ratio, generate, progress bar, push notification on completion

### Key Files to Review

| File | Purpose | Status |
|------|---------|--------|
| `Buddian/Views/GenerateView.swift` | Old generate tab | Needs rewrite → Create tab |
| `Buddian/Views/LibraryView.swift` | Old library | Needs rewrite → Studio tab |
| `Buddian/Views/ContentView.swift` | Tab navigation | Needs new tabs: Home, Create, Studio, Profile |
| `Buddian/Networking/APIClient.swift` | API calls | Needs new endpoints (feed, track-view, videos, billing) |
| `Buddian/Models/Generation.swift` | Generation model | Needs update for video (not image) |

### What NOT to Build

- Do NOT call Pollinations or any external AI API directly from iOS
- All requests go through Buddian API server
- The server handles GPU provisioning and IP protection

### Verification

- Build succeeds on `macos-latest` via GitHub Actions
- All API calls work against production `api.buddian.com`
- UI renders correctly on iPhone SE through iPhone 16 Pro Max
- Dark mode and light mode both look correct
