# Buddian API Handoff — iOS App Requirements

## Current Status

The Buddian API is partially working. Here's what needs to be fixed:

### Working ✅

| Endpoint | Status |
|----------|--------|
| `GET /health` | ✅ Returns `{"status": "available"}` |
| `GET /models` | ✅ Returns 75 models (7 image, 0 video) |
| `POST /web/auth/firebase` | ✅ Accepts Firebase ID tokens |
| `GET /web/me` | ✅ Returns user balance and transactions |
| `GET /generations` | ✅ Lists user's generations |
| `GET /generations/{id}` | ✅ Returns generation status |

### Not Working ❌

| Endpoint | Issue | Fix Needed |
|----------|-------|------------|
| `POST /generations` | Creates job but worker in mock mode | See below |
| `GET /generations/{id}/result` | Returns URL but no actual file | Worker must save results |

### Root Cause

In `.env`:
```
GENERATION_WORKER_ENABLED=true
GENERATION_MOCK_MODE=true  ← Problem: worker uses Pollinations/Gemini/Pillow fallback
```

The worker's `generate_mock_image()` function (line 162-231 in `generation_worker.py`) tries:
1. **Pollinations.ai** — Now requires API key (returns 401)
2. **Gemini** — Requires API key (optional)
3. **Pillow placeholder** — Generates mock image

## Required Fixes

### Fix 1: Add Pollinations API Key

Pollinations now requires authentication for image generation. Add to `.env`:

```bash
POLLINATIONS_API_KEY=sk_your_key_here
```

Get key at: https://enter.pollinations.ai

### Fix 2: Update Worker to Use API Key

In `api/workers/generation_worker.py`, update lines 176-189:

```python
# Current (broken):
for img_url in [
    f"https://gen.pollinations.ai/image/{encoded}?model=flux",
    f"https://image.pollinations.ai/prompt/{encoded}?width={width}&height={height}&nologo=true",
]:
    try:
        with httpx.Client(timeout=60, follow_redirects=True) as client:
            resp = client.get(img_url)
            resp.raise_for_status()

# Fixed:
api_key = os.environ.get("POLLINATIONS_API_KEY", "")
headers = {"Authorization": f"Bearer {api_key}"} if api_key else {}
for img_url in [
    f"https://gen.pollinations.ai/image/{encoded}?model=flux",
    f"https://image.pollinations.ai/prompt/{encoded}?width={width}&height={height}&nologo=true",
]:
    try:
        with httpx.Client(timeout=60, follow_redirects=True) as client:
            resp = client.get(img_url, headers=headers)
            resp.raise_for_status()
```

### Fix 3: Enable Worker (if not running)

Check if worker is running:
```bash
docker ps | grep worker
```

If not running:
```bash
docker compose up -d generation-worker
```

## iOS App Flow

```
1. User opens app → Firebase Auth (Apple Sign In)
2. Exchange Firebase token → POST /web/auth/firebase → get session token
3. Fetch models → GET /models → show image/video models
4. User selects model, enters prompt
5. Submit generation → POST /generations → get job_id
6. Poll status → GET /generations/{job_id} → wait for "completed"
7. Download result → GET /generations/{job_id}/result → get image URL
8. Load image from URL → store locally in UserDefaults
```

## Pricing Model

- **Pollinations models** (pollinations/flux, etc.): Free ($0/image)
- **GPU models** (FLUX, SDXL, etc.): Paid (requires balance)

## Testing Checklist

- [ ] Add `POLLINATIONS_API_KEY` to `.env`
- [ ] Update worker to use API key
- [ ] Restart worker: `docker compose restart generation-worker`
- [ ] Test: `POST /generations` with `pollinations/flux` model
- [ ] Verify worker processes job and saves result
- [ ] Test: `GET /generations/{id}/result` returns valid image
