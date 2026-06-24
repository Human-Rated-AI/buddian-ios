# Buddian iOS — API Handoff

Requirements for backend API changes to support iOS app MVP.

---

## 1. Custom Model Installation Endpoint

**Purpose:** Allow users to install image/video generation models on rented GPUs.

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

**Requirements:**
- Must support model catalog from Hugging Face
- Must handle GPU lifecycle (start, install, run, shutdown)
- Must integrate with vast.ai for GPU rental
- Must support both standard and confidential (TEE) tiers

---

## 2. Image/Video Generation Endpoint

**Purpose:** Submit prompts for image/video generation on installed models.

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

## 3. Generation Status Endpoint

**Purpose:** Check status of a generation job.

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

## 4. Model Catalog with Image/Video Models

**Purpose:** Return available models including image/video generation models.

**Current state:** `/models` returns 68 text-only models.

**Required additions:**
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

## 5. User Balance & Credits

**Purpose:** Fetch user balance, GPU credits, and transaction history.

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

**Purpose:** Exchange Firebase token for session token.

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

## Summary

| Priority | Endpoint | Status |
|----------|----------|--------|
| P0 | `/models` — add image/video models | Needed |
| P0 | `/generations` — submit prompts | Needed |
| P0 | `/generations/{id}` — check status | Needed |
| P1 | `/web/me` — user balance | Needed |
| P1 | `/web/auth/firebase` — session auth | Needed |
| P2 | `/installable-models/install` — model installation | Future |
