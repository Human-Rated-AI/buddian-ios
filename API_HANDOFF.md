# Buddian iOS — API Handoff

Requirements for backend API changes to support iOS app MVP.

---

## API Status (Verified 2026-06-24)

| Endpoint | Method | Status | Notes |
|----------|--------|--------|-------|
| `/models` | GET | ✅ Working | 75 models (67 text + 4 image + 4 video) |
| `/generations` | POST | ✅ Implemented | Requires auth (401 without session) |
| `/generations/{id}` | GET | ✅ Implemented | Requires auth |
| `/web/me` | GET | ✅ Implemented | Requires auth |
| `/web/auth/firebase` | POST | ✅ Implemented | Session exchange |
| `/installable-models` | GET | ✅ Implemented | Requires auth |
| `/health` | GET | ✅ Working | No auth required |

---

## 1. Model Catalog — Image/Video Models Needed

**Current state:** `/models` returns 75 models: 67 text-only upstream models plus 8 static image/video generation entries (SDXL, SD3, FLUX 1.1 Pro, FLUX Schnell, Stable Video Diffusion, Mochi 1, Ray 2 Flash, Wan 2.1).

**Required:** Add image/video generation models with:
```json
{
  "id": "stabilityai/stable-diffusion-xl",
  "name": "Stable Diffusion XL",
  "type": "image_generation",
  "output_modalities": ["image"],
  "pricing": {
    "per_image": 0.025
  },
  "installed": false,
  "install_time_seconds": 120
}
```

**Filter fields needed:**
- `output_modalities`: `["text"]`, `["image"]`, `["video"]`
- `type`: `"chat"`, `"image_generation"`, `"video_generation"`

---

## 2. Custom Model Installation

**Endpoint:** `POST /installable-models/install`

**Request:**
```json
{
  "model_id": "stabilityai/stable-diffusion-xl",
  "gpu_type": "nvidia-a100",
  "tier": "standard"
}
```

**Response:**
```json
{
  "job_id": "install_abc123",
  "status": "installing",
  "estimated_seconds": 120
}
```

---

## 3. Image/Video Generation

**Endpoint:** `POST /generations`

**Request:**
```json
{
  "model_id": "stabilityai/stable-diffusion-xl",
  "prompt": "A sunset over mountains",
  "negative_prompt": "blurry, low quality",
  "width": 1024,
  "height": 1024,
  "steps": 30,
  "cfg_scale": 7.5
}
```

**Response:**
```json
{
  "job_id": "gen_xyz789",
  "status": "queued",
  "estimated_seconds": 30,
  "cost_estimate": 0.025
}
```

---

## 4. Generation Status

**Endpoint:** `GET /generations/{job_id}`

**Response:**
```json
{
  "job_id": "gen_xyz789",
  "status": "completed",
  "result_url": "https://storage.buddian.com/results/gen_xyz789.png",
  "cost_actual": 0.023,
  "gpu_seconds": 15.2
}
```

---

## 5. User Balance & Credits

**Endpoint:** `GET /web/me`

**Required fields:**
```json
{
  "uid": "user_abc123",
  "email": "user@example.com",
  "balance": 12.50,
  "credits": {
    "gpu_minutes": 40.0
  },
  "transactions": [
    {
      "id": "tx_001",
      "type": "purchase",
      "amount": 4.99,
      "description": "Starter Pack",
      "created_at": "2026-06-23T10:00:00Z"
    }
  ]
}
```

---

## 6. Session Authentication

**Endpoint:** `POST /web/auth/firebase`

**Request:**
```json
{
  "firebase_token": "eyJhbGciOiJSUzI1NiIs...",
  "platform": "ios"
}
```

**Response:**
```json
{
  "session_token": "sess_abc123def456",
  "expires_at": "2026-06-24T10:00:00Z"
}
```

---

## Next Steps for Backend

1. **Add image/video generation models** to `/models` endpoint
2. **Verify `/generations` endpoint** accepts the request format above
3. **Verify `/generations/{id}` endpoint** returns status and result URL
4. **Verify `/web/me` endpoint** returns balance and transactions
