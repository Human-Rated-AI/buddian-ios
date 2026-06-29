# Buddian Logo

## Generation Prompt

Use this prompt with any image generation model (DALL-E, Midjourney, Flux, etc.):

```
Minimal app icon for "Buddian", a private AI companion app. A clean
blue four-pointed sparkle/star symbol centered on a white background.
The sparkle has one large four-pointed star with two smaller
four-pointed stars above and to the left. Flat vector style, no
shadows, no gradients, no 3D effects. Simple, modern, Apple-style
design. White background, blue (#007AFF) sparkle. Square 1:1 aspect
ratio. Suitable for iOS app icon.
```

## Required Sizes

After generating, export to these sizes for `AppIcon.appiconset/`:

| File | Size (px) | Usage |
|------|-----------|-------|
| 1024.png | 1024x1024 | App Store (master) |
| 512.png | 512x512 | Marketing |
| 256.png | 256x256 | Marketing |
| 180.png | 180x180 | iPhone @3x |
| 167.png | 167x167 | iPad Pro @2x |
| 152.png | 152x152 | iPad @2x |
| 144.png | 144x144 | iPad @2x |
| 128.png | 128x128 | Marketing |
| 120.png | 120x120 | iPhone @3x, iPad @2x |
| 114.png | 114x114 | iPhone @2x |
| 108.png | 108x108 | iPad @2x |
| 102.png | 102x102 | iPad @2x |
| 100.png | 100x100 | iPad @2x |
| 92.png | 92x92 | iPad @2x |
| 88.png | 88x88 | iPad @2x |
| 87.png | 87x87 | iPhone @3x |
| 80.png | 80x80 | iPhone @2x, iPad @2x |
| 76.png | 76x76 | iPad @1x |
| 72.png | 72x72 | iPad @1x |
| 66.png | 66x66 | iPad @2x |
| 64.png | 64x64 | Marketing |
| 60.png | 60x60 | iPhone @2x |
| 58.png | 58x58 | iPhone @2x |
| 57.png | 57x57 | iPhone @1x |
| 55.png | 55x55 | iPad @2x |
| 50.png | 50x50 | iPad @1x |
| 48.png | 48x48 | iPad @1x |
| 40.png | 40x40 | iPhone @2x, iPad @1x |
| 32.png | 32x32 | iPad @1x |
| 29.png | 29x29 | iPhone @1x |
| 20.png | 20x20 | Notification @1x |
| 16.png | 16x16 | Spotlight @1x |

## Where to Place

1. Generate the logo using the prompt above
2. Export to all sizes listed above
3. Replace files in `Buddian/Assets.xcassets/AppIcon.appiconset/`
4. Also place the 1024px version at `Buddian/Assets.xcassets/AppLogo.dataset/logo.png` for use in LoginView

## LoginScreen Logo

The LoginView currently uses `Image(systemName: "sparkles")` which is an SF Symbol.
Once you have the custom logo, replace it with:

```swift
Image("AppLogo")
    .resizable()
    .frame(width: 80, height: 80)
```
