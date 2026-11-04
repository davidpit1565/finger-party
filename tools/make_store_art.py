#!/usr/bin/env python3
"""Plain branded backdrops for framing REAL App Store screenshots later.

No UI, no text, no device frames. Dark #0B0B10 base with soft coloured glows
near the top and bottom edges (the middle stays calm for a framed screenshot).
Output: opaque RGB PNGs, sRGB, no alpha.

Usage: python3 tools/make_store_art.py
"""
import os
import numpy as np
from PIL import ImageCms
from PIL import Image

SRGB = ImageCms.ImageCmsProfile(ImageCms.createProfile("sRGB")).tobytes()
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "Design/store")
SIZES = {
    "screenshot-backdrop-6.9in-1320x2868.png": (1320, 2868),
    "screenshot-backdrop-6.5in-1284x2778.png": (1284, 2778),
}
BG = np.array([11, 11, 16], np.float32) / 255
GLOWS = [  # (x frac, y frac, radius frac of width, colour, strength)
    (0.12, 0.05, 0.85, (51, 199, 255), 0.20),
    (0.92, 0.10, 0.80, (184, 102, 255), 0.17),
    (0.78, 0.95, 0.95, (255, 69, 89), 0.24),
    (0.10, 0.90, 0.75, (255, 204, 38), 0.12),
]


def render(w, h):
    yy, xx = np.mgrid[0:h, 0:w].astype(np.float32)
    img = np.broadcast_to(BG, (h, w, 3)).copy()
    for fx, fy, fr, c, k in GLOWS:
        d = np.hypot(xx - fx * w, yy - fy * h) / (fr * w)
        g = np.exp(-d ** 2 * 2.2) * k
        img = 1 - (1 - img) * np.exp(-g[..., None] * (np.array(c, np.float32) / 255) * 1.6)
    rng = np.random.default_rng(7)
    img += (rng.random((h, w, 1), dtype=np.float32) - 0.5) / 255  # dither vs banding
    return Image.fromarray((np.clip(img, 0, 1) * 255 + 0.5).astype(np.uint8), "RGB")


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    for name, (w, h) in SIZES.items():
        render(w, h).save(os.path.join(OUT, name), optimize=True, icc_profile=SRGB)
        print("wrote", name)
