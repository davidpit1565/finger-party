# Finger Picker - design assets

Visual identity: near-black charcoal `#0B0B10`, glowing rings in coral `#FF4559`,
cyan `#33C7FF`, amber `#FFCC26`, lime `#66E666`, violet `#B866FF`. All artwork is
original, procedural, and contains no text, trademarks, Apple marks or devices.

| Asset | Purpose |
|---|---|
| `App/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png` | The shipping app icon (iOS 17+ single-size, 1024x1024, opaque sRGB RGB, no alpha). iOS applies the corner mask. |
| `App/Resources/Assets.xcassets/AppIcon.appiconset/Contents.json` | Single universal `ios` 1024x1024 entry (valid for Xcode 15/16). |
| `App/Resources/Assets.xcassets/AccentColor.colorset/` | App accent colour = cyan `#33C7FF` (sRGB). |
| `Design/icon/AppIcon-1024.png` | Identical copy of the icon for review/handoff. |
| `Design/icon/AppIcon-preview-sizes.png` | Contact sheet at 180, 120, 87, 80, 60, 58, 40, 29 px (rounded mask for review only; not shipped). |
| `Design/store/screenshot-backdrop-6.9in-1320x2868.png` | Plain branded backdrop (dark + soft glows, no UI) for framing real 6.9" screenshots. |
| `Design/store/screenshot-backdrop-6.5in-1284x2778.png` | Same, for 6.5" screenshots. |

Backdrops are NOT screenshots; real captured screenshots must be composited on them later.

## Regenerate

Requires Python 3, Pillow, numpy. From the repo root:

```
python3 tools/make_icon.py        # icon (4096px supersample -> 1024 LANCZOS), copy, preview sheet
python3 tools/make_store_art.py   # store backdrops
```

Ring layout, colours and glow strengths are constants at the top of `tools/make_icon.py`
(`RINGS`, first entry is the "winner" with the colour bloom).
