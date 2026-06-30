# Buddian iOS — Model Availability API Handoff

## Current Implementation (Verified 2026-06-30)

`GET /models` returns all models with these fields:

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

### Status logic (current)

| Model type | Condition | Status |
|------------|-----------|--------|
| Text (`chat`) | Phala balance > $10 | `free` |
| Text (`chat`) | Phala balance <= $10 | `available` |
| Image | User balance = $0 | `free` |
| Image | User balance > $0 | `available` |
| Video | Any | `unavailable` (filtered out, not returned) |

### Current model catalog

**Image (4 models, all `status=free`):**
| Model | Price | Steps | CFG Scale |
|-------|-------|-------|-----------|
| FLUX 1.1 Pro | $0.04/image | 28 | 3.5 |
| FLUX Schnell | $0.01/image | 4 | 0.0 |
| SD3 | $0.035/image | 30 | 7.0 |
| SDXL | $0.025/image | 30 | 7.5 |

**Text (67 models, `status=free`):** Phala-hosted chat models.

**Video:** 0 returned (filtered out).

### Filtering

- `?output_modality=image` → 4 models
- `?output_modality=video` → 0
- `?output_modality=text` → 67 models
- `?search=flux` → FLUX models only

### Rate limiting

- 60-second minimum between generations per user
- Returns rate limit error with retry info

---

## Proposed Changes

### 1. Add `pending` status for GPU spin-up

Some models may need GPU allocation before they can serve. Return `status: "pending"` with `availability_reason: "GPU spinning up, ~30s"`.

**Backend:** Check if model's GPU is allocated. If not, return `pending` instead of `available`.

### 2. Add `setup_required` status

If a model requires user action before use (terms acceptance, API key), return `status: "setup_required"` with a reason.

### 3. Ensure video models are never returned

Currently video models are filtered out at the database level. Keep this behavior — no video generation until the worker is ready.

### 4. Expose generation defaults

Already implemented. Each generation model returns `default_width`, `default_height`, `default_steps`, `default_cfg_scale`. The iOS app uses these to pre-fill the Generate form.

---

## iOS Display Rules

| Status | Color | Behavior |
|--------|-------|----------|
| `free` | Green badge | Tappable, no charge |
| `available` | Blue badge | Tappable, charges apply |
| `pending` | Amber badge | Tappable, shows loading spinner |
| `unavailable` | Not shown | Filtered out by backend |
| `setup_required` | Orange badge | Tappable, opens setup flow |

### Balance-based dimming (client-side)

- User balance = $0: `free` models full color, `available` models dimmed
- User balance > $0: All models full color
- Dimmed = 50% opacity, shows "Insufficient balance" on tap
