# Buddian iOS — Model Availability API Handoff

## Goal

The iOS app needs to show models in three tiers based on user balance and model state. The backend should filter out models that cannot be used.

---

## Proposed Response Shape

```json
GET /models?output_modality=image

{
  "models": [
    {
      "id": "stabilityai/stable-diffusion-xl",
      "name": "Stable Diffusion XL",
      "type": "image_generation",
      "output_modalities": ["image"],
      "status": "available",
      "availability_reason": null,
      "user_pricing": {
        "currency": "USD",
        "per_image": "0.025"
      },
      "default_width": 1024,
      "default_height": 1024,
      "default_steps": 30,
      "default_cfg_scale": 7.5
    }
  ]
}
```

---

## Model Status Values

| Status | Meaning | iOS Display |
|--------|---------|-------------|
| `available` | Ready to use immediately | Full color, tappable |
| `free` | No charge required (promotional/demo) | Green badge |
| `pending` | Model available but needs GPU spin-up (~30-120s) | Amber badge, "Loading..." on tap |
| `unavailable` | Cannot be used right now (GPU quota, provider down) | Grayed out, not tappable |
| `setup_required` | User needs to configure something first (API key, acceptance) | Orange badge, tap opens setup flow |

**Backend should NOT return models with status `unavailable`** — filter them out entirely.

---

## Three-Tier Display Rules

### Tier 1: Free models (user balance = $0)
- Show `free` and `available` models
- Green accent color
- Label: "Free"

### Tier 2: Paid models with sufficient balance
- Show `available` models where user can afford at least 1 generation
- Blue accent color
- Label: price per unit

### Tier 3: Paid models insufficient balance
- Show `pending` models (GPU needs spin-up) as dimmed
- Show `available` models user can't afford as dimmed
- Dimmed = 50% opacity, not tappable, "Insufficient balance" tooltip

---

## Backend Changes Needed

### 1. Filter endpoint

`GET /models` should accept a query parameter to filter by availability:

```
GET /models?status=available,pending&output_modality=image
```

If no `status` param, return all except `unavailable`.

### 2. Add `status` field to each model

The `status` is computed per-user based on:
- GPU provider availability
- User balance vs model cost
- Any setup requirements

### 3. Add `availability_reason` field

When status is not `available`, explain why:

```json
{
  "status": "pending",
  "availability_reason": "GPU spinning up, estimated 45 seconds"
}
```

```json
{
  "status": "setup_required",
  "availability_reason": "Accept terms of service for this model"
}
```

### 4. Add model defaults

Each generation model should return default parameters:

```json
{
  "default_width": 1024,
  "default_height": 1024,
  "default_steps": 30,
  "default_cfg_scale": 7.5
}
```

These let the Generate tab auto-fill parameters without user configuration.

---

## Example: Three Models With Different States

```json
{
  "models": [
    {
      "id": "black-forest-labs/flux-schnell",
      "name": "FLUX Schnell",
      "type": "image_generation",
      "status": "available",
      "availability_reason": null,
      "user_pricing": { "currency": "USD", "per_image": "0.003" }
    },
    {
      "id": "black-forest-labs/flux-1.1-pro",
      "name": "FLUX 1.1 Pro",
      "type": "image_generation",
      "status": "pending",
      "availability_reason": "GPU allocating, ~30s",
      "user_pricing": { "currency": "USD", "per_image": "0.04" }
    },
    {
      "id": "stabilityai/stable-diffusion-xl",
      "name": "Stable Diffusion XL",
      "type": "image_generation",
      "status": "available",
      "availability_reason": null,
      "user_pricing": { "currency": "USD", "per_image": "0.025" }
    }
  ]
}
```

For a user with $0 balance, only FLUX Schnell ($0.003/image) might show as "free" if the backend marks it as promotional. FLUX Pro and SDXL would be dimmed.

For a user with $5.00 balance, all three show as available (full color, tappable).

---

## iOS Implementation Notes

The iOS app will:

1. Fetch models with the new response shape
2. Group by status for display
3. Dim models where `status != "available"` or user can't afford
4. Show green badge for `free`, blue for `available`, amber for `pending`
5. On tap of `pending` model, show loading spinner and poll for status change
6. On tap of `setup_required`, navigate to setup flow

The `status` field is the single source of truth — no client-side price checking needed.
