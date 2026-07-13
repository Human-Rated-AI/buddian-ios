# Buddian API Handoff — iOS App Requirements

## Current Status

The Buddian API backend has been updated with Pollinations support, but the worker code is NOT using the API key.

### What's Working ✅

| Component | Status | Notes |
|-----------|--------|-------|
| `GET /health` | ✅ | Returns service status |
| `GET /models` | ✅ | 75 models, 7 image, 3 Pollinations |
| `POST /web/auth/firebase` | ✅ | Accepts Firebase ID tokens |
| `GET /web/me` | ✅ | Returns user balance, transactions |
| `GET /generations` | ✅ | Lists user's generations |
| `GET /generations/{id}` | ✅ | Returns generation status |
| Pollinations API Key | ✅ | Configured in `.env` |
| Pollinations API Works | ✅ | Tested: returns 200 with image |

### What's Broken ❌

| Component | Issue | Impact |
|-----------|-------|--------|
| Worker Pollinations calls | NOT using API key | Returns 401 |
| `POST /generations` | Worker can't process | Jobs stay "queued" |
| `GET /generations/{id}/result` | No result file | Can't download images |

## Root Cause

In `api/workers/generation_worker.py` lines 176-182:

```python
# CURRENT CODE (BROKEN):
for img_url in [
    f"https://gen.pollinations.ai/image/{encoded}?model=flux",
    f"https://image.pollinations.ai/prompt/{encoded}?width={width}&height={height}&nologo=true",
]:
    try:
        with httpx.Client(timeout=60, follow_redirects=True) as client:
            resp = client.get(img_url)  # ← NO AUTH HEADER!
```

The API key is in `.env` as `POLLINATIONS_API_KEY=sk_9sxlBNAHcvmdg4C8QiTj4D3dNmrHHNLJ` but the worker doesn't use it.

## Required Fix

Update `api/workers/generation_worker.py` lines 172-189:

```python
# 1. Try Pollinations.ai (requires API key)
try:
    encoded = urllib.parse.quote(prompt)
    api_key = os.environ.get("POLLINATIONS_API_KEY", "")
    headers = {"Authorization": f"Bearer {api_key}"} if api_key else {}
    
    for img_url in [
        f"https://gen.pollinations.ai/image/{encoded}?model=flux",
        f"https://image.pollinations.ai/prompt/{encoded}?width={width}&height={height}&nologo=true",
    ]:
        try:
            with httpx.Client(timeout=60, follow_redirects=True) as client:
                resp = client.get(img_url, headers=headers)  # ← ADD HEADERS!
                resp.raise_for_status()
                ct = resp.headers.get("content-type", "")
                if "image" in ct and len(resp.content) > 1000:
                    logger.info("Pollinations generated image (%d bytes)", len(resp.content))
                    return resp.content
        except Exception:
            continue
    logger.warning("Pollinations returned no valid image from any endpoint")
except Exception as exc:
    logger.warning("Pollinations failed (%s), trying Gemini", exc)
```

## iOS App Status

The iOS app is **ready** — it calls the Buddian API correctly:

1. ✅ Fetches models from `GET /models`
2. ✅ Submits generations via `POST /generations`
3. ✅ Polls status via `GET /generations/{id}`
4. ✅ Downloads results via `GET /generations/{id}/result`
5. ✅ Stores generations locally

**No iOS app changes needed** — just fix the backend worker.

## Testing After Fix

```bash
# 1. Update worker code
# 2. Restart worker
docker compose restart generation-worker

# 3. Test generation (requires auth token)
curl -X POST https://api.buddian.com/generations \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <session_token>" \
  -d '{"model_id": "pollinations/flux", "prompt": "a cat in space"}'

# 4. Check status
curl https://api.buddian.com/generations/<job_id> \
  -H "Authorization: Bearer <session_token>"

# 5. Download result
curl https://api.buddian.com/generations/<job_id>/result \
  -H "Authorization: Bearer <session_token>" -o image.png
```
