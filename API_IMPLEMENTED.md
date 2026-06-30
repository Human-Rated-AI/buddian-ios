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
| Image | User balance = $0 | `free` |
| Image | User balance > $0 | `available` |
| Video | Any | `unavailable` (filtered out) |

- Phala balance is checked live from Phala Cloud API (currently $20)
- Floor is $10 — text models are free while balance exceeds floor
- Video models are excluded entirely (no free video generation yet)
- `availability_reason` is `null` for all current models

### Generation model defaults

Each generation model includes auto-fill parameters:

| Model | width | height | steps | cfg_scale |
|-------|-------|--------|-------|-----------|
| SDXL | 1024 | 1024 | 30 | 7.5 |
| SD3 | 1024 | 1024 | 30 | 7.0 |
| FLUX 1.1 Pro | 1024 | 1024 | 28 | 3.5 |
| FLUX Schnell | 1024 | 1024 | 4 | 0.0 |

### Available models

**Image (status=free):**
- black-forest-labs/flux-schnell ($0.01/image)
- black-forest-labs/flux-1.1-pro ($0.04/image)
- stabilityai/stable-diffusion-xl ($0.025/image)
- stabilityai/stable-diffusion-3 ($0.035/image)

**Text (status=free):** 67 Phala models (gemma, llama, qwen, etc.)

**Video:** Filtered out (status=unavailable, not returned)

### Filtering

- `?output_modality=image` → 4 image models
- `?output_modality=video` → 0 (filtered out)
- `?output_modality=text` → 67 text models
- `?search=flux` → FLUX models only
- All filters work with `status` field

### Mock mode rate limiting

- 60-second minimum between generations per user
- Returns "rate limited" error with retry info
- Applies to Gemini mock image generation

## How to use from iOS

1. Call `GET /models?output_modality=image` to get image models
2. Check `status` field: `free` = no charge needed, `available` = costs money
3. For `free` models: submit generation without balance check
4. For `available` models: check `user_pricing.per_image` against user balance
5. Use `default_width`, `default_height`, `default_steps`, `default_cfg_scale` to pre-fill the generate form
