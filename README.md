# Buddian iOS

iOS client for Buddian — an AI video streaming and creation platform where subscribers create AI-generated videos and earn money when others watch them.

## Product Vision

A hybrid of Runway (AI video generation) and YouTube Premium (monetized streaming). Users pay a monthly subscription for AI video generation seconds and ad-free streaming. When a user watches a video, a fraction of their subscription fee is credited to the creator's fiat balance.

See [buddian repo](https://github.com/Human-Rated-AI/buddian) for full product specs:
- [Agent_Project_Brief_Buddian.md](https://github.com/Human-Rated-AI/buddian/blob/main/Agent_Project_Brief_Buddian.md) — system context and business logic
- [iOSApp.md](https://github.com/Human-Rated-AI/buddian/blob/main/iOSApp.md) — iOS app feature spec
- [API.md](https://github.com/Human-Rated-AI/buddian/blob/main/API.md) — backend API endpoints

## Architecture

```
iOS App → Buddian API (auth + generation + billing + streaming)
                ↓
Buddian API → GPU Provider (video generation)
```

Users authorize with Buddian and pay via Apple IAP. Buddian handles video generation and streaming economy.

## Key Features

- **Sign in with Apple/Google** via Firebase Auth
- **Dual Wallet**: Generation Seconds (consumed by AI video creation) + Fiat Earned (from views)
- **Subscription**: $14.99/mo, $59.99/6mo, $99.99/yr via StoreKit
- **Video Feed**: Vertical, swipeable feed (Reels/TikTok style)
- **AI Studio**: Text prompt → AI video generation
- **Studio**: Video management, metadata editing, stats
- **Push Notifications**: "Your video is ready!"
- **Earnings Dashboard**: View count, seconds watched, fiat earned per video

## iOS API Endpoints

See `IOS_API.md` in the backend repo for complete API reference.

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `POST /web/auth/firebase` | POST | Firebase token → session |
| `GET /users/me` | GET | Profile + dual wallet |
| `GET /models` | GET | Available models |
| `POST /generate/request` | POST | Submit video generation |
| `GET /generate/status/{job_id}` | GET | Poll generation status |
| `GET /feed` | GET | Video feed |
| `POST /player/track-view` | POST | Track watch time |
| `GET /videos/me` | GET | List user's videos |
| `PUT /videos/{id}` | PUT | Update video metadata |
| `DELETE /videos/{id}` | DELETE | Soft-delete video |
| `GET /videos/{id}/stats` | GET | Video analytics |
| `POST /billing/subscribe` | POST | Subscribe via StoreKit |
| `POST /billing/top-up` | POST | Buy extra seconds |

## Tabs

1. **Home (Feed)** — Vertical swipeable video feed
2. **Create** — AI video generation prompt input
3. **Studio (My Videos)** — Video list, edit, delete, stats
4. **Profile** — Dual wallet display, subscription status

## Building

Requires macOS with Xcode.

```bash
git clone https://github.com/Human-Rated-AI/buddian-ios.git
cd buddian-ios
open Buddian.xcodeproj
# Build for simulator or device
```

## Related Repos

- [buddian](https://github.com/Human-Rated-AI/buddian) — Backend API (private)
- [buddian-web](https://github.com/Human-Rated-AI/buddian-web) — Web client (public)
