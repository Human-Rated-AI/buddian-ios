# Buddian iOS API Reference

All iOS app requests go through `https://api.buddian.com`. The server proxies to Pollinations.ai — the iOS app never calls Pollinations directly.

**Base URL:** `https://api.buddian.com`

---

## Authentication

### `POST /web/auth/firebase`

Exchange a Firebase ID token (from Apple Sign In) for a Buddian session token.

**Request:**
```json
{
  "id_token": "eyJhbGciOiJSUzI1NiIs...",
  "platform": "ios"
}
```

**Response:**
```json
{
  "session_token": "sess_abc123def456",
  "account": {
    "id": 26,
    "email": "user@icloud.com",
    "balance": { "available_usd": 0.00 }
  }
}
```

**Auth:** None (Firebase token in body).

All subsequent requests use `Authorization: Bearer {session_token}` header.

---

### `GET /web/me`

Get current user profile and balance.

**Response:**
```json
{
  "id": 26,
  "email": "user@icloud.com",
  "balance": { "available_usd": 5.00 },
  "transactions": [
    {
      "id": 1,
      "type": "topup",
      "amount_usd": 5.00,
      "description": "Apple IAP — Starter Pack",
      "created_at": "2026-07-10T12:00:00Z"
    }
  ]
}
```

**Auth:** Required (Bearer token).

---

## Model Catalog

### `GET /models`

List all available models. No auth required.

**Query params:**
- `output_modality=image` — image generation models only
- `output_modality=video` — video generation models only

**Response:**
```json
{
  "data": [
    {
      "id": "pollinations/flux",
      "name": "Flux (Pollinations)",
      "type": "image_generation",
      "status": "free",
      "output_modalities": ["image"],
      "user_pricing": { "currency": "USD", "per_image": "0" },
      "default_width": 1024,
      "default_height": 1024
    },
    {
      "id": "black-forest-labs/flux-1.1-pro",
      "name": "FLUX 1.1 Pro",
      "type": "image_generation",
      "status": "available",
      "output_modalities": ["image"],
      "user_pricing": { "currency": "USD", "per_image": "0.04" },
      "default_width": 1024,
      "default_height": 1024,
      "default_steps": 28,
      "default_cfg_scale": 3.5
    }
  ],
  "count": 78
}
```

**Model status meanings:**
- `"free"` — available at no cost (Pollinations models, or user has balance for GPU models)
- `"available"` — requires user balance
- `"unavailable"` — not enough balance or provider offline

---

## Generation

### `POST /generations`

Submit a generation job. The server queues it and the worker processes it via Pollinations.ai (or GPU for paid models).

**Request:**
```json
{
  "model_id": "pollinations/flux",
  "prompt": "A sunset over mountains",
  "width": 1024,
  "height": 1024,
  "num_images": 1
}
```

**Optional fields:** `negative_prompt`, `steps`, `cfg_scale`

**Response:**
```json
{
  "job_id": "42",
  "status": "queued",
  "estimated_seconds": 30,
  "cost_estimate": 0
}
```

**Auth:** Required. Balance check: if `cost_estimate > 0`, user must have sufficient balance.

---

### `GET /generations`

List current user's generation jobs.

**Query params:** `limit` (1-200, default 50)

**Response:**
```json
{
  "data": [
    {
      "job_id": "42",
      "model_id": "pollinations/flux",
      "prompt": "A sunset over mountains",
      "status": "completed",
      "cost_estimate": 0,
      "cost_actual": 0,
      "result_url": "/storage/generations/26/42.png",
      "gpu_seconds": 2.1,
      "created_at": "2026-07-10T12:00:00Z",
      "completed_at": "2026-07-10T12:00:02Z"
    }
  ]
}
```

**Auth:** Required.

---

### `GET /generations/{job_id}`

Get status of a specific generation job.

**Response:**
```json
{
  "job_id": "42",
  "model_id": "pollinations/flux",
  "prompt": "A sunset over mountains",
  "status": "completed",
  "status_detail": null,
  "cost_estimate": 0,
  "cost_actual": 0,
  "result_url": "/storage/generations/26/42.png",
  "gpu_seconds": 2.1,
  "created_at": "2026-07-10T12:00:00Z",
  "updated_at": "2026-07-10T12:00:02Z",
  "completed_at": "2026-07-10T12:00:02Z"
}
```

**Status values:** `queued` → `running` → `completed` | `failed`

**Auth:** Required.

---

### `GET /generations/{job_id}/result`

Download the generated image/video file.

**Response:** Binary file (image/png or video/mp4).

**Auth:** None (unauthenticated, serves from local storage).

---

## Wallet (Apple IAP) — Planned

### Purchase Flow

1. iOS app fetches StoreKit products
2. User purchases via Apple IAP
3. iOS sends receipt to `POST /storekit/verify`
4. Backend verifies with Apple, credits user balance
5. Balance deducted per generation job

**StoreKit products (planned):**

| Product | Price | GPU time |
|---------|-------|----------|
| Starter | $4.99 | ~40 min |
| Pro | $9.99 | ~100 min |
| Studio | $24.99 | ~280 min |

---

## Complete User Flow

```
1.  Open app → LoginView (Sign in with Apple)
2.  Firebase Auth → ID token → POST /web/auth/firebase → session_token
3.  Session stored in Keychain → auto-login on next launch
4.  Fetch models → GET /models → show image/video models
5.  Select model → enter prompt → tap Generate
6.  POST /generations → get job_id
7.  Poll GET /generations/{job_id} every 5 seconds
8.  When "completed" → GET /generations/{job_id}/result → download image
9.  Display image in GenerateView
10. View history in LibraryView (GET /generations)
```

---

## Error Responses

All errors return JSON:

```json
{
  "detail": "Error message here"
}
```

**Common HTTP codes:**
- `401` — Not authenticated (missing or expired session token)
- `402` — Insufficient balance
- `404` — Resource not found
- `422` — Invalid request parameters
