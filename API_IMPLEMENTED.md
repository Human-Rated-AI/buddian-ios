# iOS API — What Was Implemented

## Endpoint: `GET /models`

All models now return a `status` field per the iOS API_HANDOFF_MODELS.md spec.

### Response shape

```json
{
  "id": "black-forest-labs/flux-schnell",
  "name": "FLUX Schnell",
  "type": "image_generation",
  "status": "free",
  "availability_reason": null,
  "output_modalities": ["image"],
  "user_pricing": { "currency": "USD", "per_image": "0.01" },
  "default_width": 1024,
  "default_height": 1024,
  "default_steps": 4,
  "default_cfg_scale": 1.0
}
```

### Status logic

| Model type | Condition | Status |
|------------|-----------|--------|
| Text (`chat`) | Phala balance > $10 | `free` |
| Text (`chat`) | Phala balance <= $10 | `available` |
| Image | Any balance | `free` (Gemini generates for free) |
| Video | Any | `unavailable` (filtered out) |

- Phala balance checked live from Phala Cloud API (currently $20, floor $10)
- Video models excluded entirely (no free video generation yet)

### Image generation models (tested and working)

| Model | Price | Gemini model | Status |
|-------|-------|-------------|--------|
| black-forest-labs/flux-schnell | $0.01/image | gemini-3-pro-image | ✅ Works |
| black-forest-labs/flux-1.1-pro | $0.04/image | gemini-3-pro-image | ✅ Works |
| stabilityai/stable-diffusion-xl | $0.025/image | gemini-3-pro-image | ✅ Works |
| stabilityai/stable-diffusion-3 | $0.035/image | gemini-3-pro-image | ✅ Works |

### Text generation models (tested)

3 Phala models confirmed working:

```bash
# Gemma 4 26B (uncensored)
TOKEN=$(curl -s -X POST https://api.buddian.com/web/auth/test \
  -H "Content-Type: application/json" \
  -d '{"email":"your@email.com","secret":"YOUR_SECRET"}' | python3 -c "import sys,json; print(json.load(sys.stdin)['session_token'])")

curl -s -X POST "https://api.buddian.com/generations" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"model_id":"phala/gemma-4-26b-a4b-uncensored","prompt":"What is 2+2?"}'

# Gemma 4 31B
curl -s -X POST "https://api.buddian.com/generations" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"model_id":"phala/gemma-4-31b-it","prompt":"Explain quantum computing in one sentence"}'

# Qwen 3.6 35B
curl -s -X POST "https://api.buddian.com/generations" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"model_id":"phala/qwen3.6-35b-a3b-uncensored","prompt":"Write a haiku about programming"}'
```

### Image generation (tested, working)

```bash
# FLUX Schnell (fast, ~$0.01/image)
curl -s -X POST "https://api.buddian.com/generations" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"model_id":"black-forest-labs/flux-schnell","prompt":"A red cat sitting on a blue chair"}'
# Returns: job_id, status, estimated_seconds, cost_estimate

# Poll until complete
curl -s "https://api.buddian.com/generations/$JOB_ID" \
  -H "Authorization: Bearer $TOKEN"
# Returns: status, result_url (/storage/generations/{user_id}/{job_id}.png)

# Download result
curl -o result.png "https://buddian.com/storage/generations/{user_id}/{job_id}.png"
```

### Rate limiting

- 60-second minimum between generations per user
- Returns `status: "failed"`, `status_detail: "Rate limited. Wait Xs..."`

### Free text generation

Text models are free while Phala balance > $10 (currently $20). No balance deduction for text generation.
