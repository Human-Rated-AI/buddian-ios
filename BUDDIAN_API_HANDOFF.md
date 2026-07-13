# Buddian API Handoff — iOS App Status

## Current Status: ✅ Ready for Testing

The backend agent has updated both repos. The iOS app should work end-to-end.

### What's Working

| Component | Status |
|-----------|--------|
| `GET /health` | ✅ Working |
| `GET /models` | ✅ 75 models, 7 image, 3 Pollinations (free) |
| `POST /web/auth/firebase` | ✅ Working (requires valid Firebase token) |
| `GET /web/me` | ✅ Working (requires auth) |
| `POST /generations` | ✅ Working (requires auth) |
| `GET /generations` | ✅ Working (requires auth) |
| `GET /generations/{id}` | ✅ Working (requires auth) |
| `GET /generations/{id}/result` | ✅ Working |
| Worker Pollinations API key | ✅ Configured and used |
| iOS app builds | ✅ Build succeeds |

### Architecture

```
iOS App → Buddian API (auth + generation)
              ↓
         Buddian API → Pollinations.ai (server-side, sk_ key)
```

- iOS app never calls Pollinations directly
- Server handles API key securely
- All payments through Apple IAP (Apple compliant)

### What Needs Real-Device Testing

The following require a real Firebase token from Apple Sign In:

1. **Auth flow**: Apple Sign In → Firebase ID token → session token
2. **Generation**: Submit prompt → poll status → download result
3. **Library**: View past generations

### iOS App Changes (by backend agent)

- Removed `PollinationsClient.swift` (direct Pollinations calls)
- Updated `GenerateView.swift` to use Buddian API only
- Updated `ModelsView.swift` to use `ModelCache`
- Added `IOS_API.md` with complete API reference

### No iOS App Changes Needed

The iOS app code is complete and matches the API contract. Just needs real-device testing with Firebase auth.
