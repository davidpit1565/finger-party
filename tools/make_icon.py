#!/usr/bin/env python3
"""Procedural Finger Picker app icon (original artwork, no external assets).

Rings are drawn crisp at 4096px (supersampled), downscaled with LANCZOS to
1024, then glow/bloom are composited additively in linear-ish float space.
Output: opaque sRGB RGB 1024x1024 PNG, no alpha.

Usage: python3 tools/make_icon.py
"""
import os
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT_ICON = os.path.join(ROOT, "App/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png")
OUT_COPY = os.path.join(ROOT, "Design/icon/AppIcon-1024.png")
OUT_SHEET = os.path.join(ROOT, "Design/icon/AppIcon-preview-sizes.png")

SS, N = 4096, 1024
BG = np.array([11, 11, 16], np.float32) / 255
CORAL = (255, 69, 89); CYAN = (51, 199, 255); AMBER = (255, 204, 38)
LIME = (102, 230, 102); VIOLET = (184, 102, 255)

# (cx, cy, radius, stroke, color, intensity) in 1024 space. First = winner.
RINGS = [
    (570, 560, 168, 58, CORAL, 1.00),   # winner
    (330, 470, 140, 46, CYAN, 0.80),
    (700, 300, 130, 42, VIOLET, 0.78),
    (440, 760, 128, 42, AMBER, 0.80),
    (770, 770, 118, 38, LIME, 0.72),
]


def ring_mask(cx, cy, r, w, fill=False):
    s = SS / N
    im = Image.new("L", (SS, SS), 0)
    d = ImageDraw.Draw(im)
    R = r * s
    if fill:
        d.ellipse([cx*s-R, cy*s-R, cx*s+R, cy*s+R], fill=255)
    else:
        d.ellipse([cx*s-R-w*s/2, cy*s-R-w*s/2, cx*s+R+w*s/2, cy*s+R+w*s/2], fill=255)
        d.ellipse([cx*s-R+w*s/2, cy*s-R+w*s/2, cx*s+R-w*s/2, cy*s+R-w*s/2], fill=0)
    im = im.resize((N, N), Image.LANCZOS)
    return np.asarray(im, np.float32) / 255


def blur(a, rad):
    """Gaussian blur of a float image via FFT (zero-padded, so glow fades off-canvas)."""
    pad = int(rad * 3)
    h, w = a.shape
    P = np.pad(a.astype(np.float32), pad)
    fy = np.fft.fftfreq(P.shape[0])[:, None]
    fx = np.fft.rfftfreq(P.shape[1])[None, :]
    g = np.exp(-2 * (np.pi ** 2) * rad ** 2 * (fx ** 2 + fy ** 2))
    out = np.fft.irfft2(np.fft.rfft2(P) * g, s=P.shape)
    return out[pad:pad + h, pad:pad + w].astype(np.float32)


def col(c):
    return (np.array(c, np.float32) / 255)[None, None, :]


def main():
    yy, xx = np.mgrid[0:N, 0:N].astype(np.float32)
    # Background: near-black with extremely subtle vignette lift toward centre.
    d = np.sqrt((xx - 540) ** 2 + (yy - 520) ** 2) / 800
    img = BG[None, None, :] * (1.0 + 0.55 * np.clip(1 - d, 0, 1)[..., None] ** 2)
    img = np.broadcast_to(img, (N, N, 3)).copy()

    # Radial colour bloom from the winner.
    wx, wy, wr, ww, wc, _ = RINGS[0]
    dist = np.sqrt((xx - wx) ** 2 + (yy - wy) ** 2)
    bloom = np.exp(-(dist / 430.0) ** 2) * 0.30 + np.exp(-(dist / 700.0) ** 1.5) * 0.10
    img += bloom[..., None] * col(wc)

    add = np.zeros_like(img)
    for i, (cx, cy, r, w, c, k) in enumerate(RINGS):
        m = ring_mask(cx, cy, r, w)
        disc = ring_mask(cx, cy, r - w / 2, w, fill=True)
        cc = col(c)
        # soft wide glow, mid glow, tight halo
        glow = blur(m, 70) * 1.5 + blur(m, 28) * 0.9 + blur(m, 9) * 0.55
        add += glow[..., None] * cc * k * 0.85
        # faint fingertip-contact fill inside the ring
        add += (disc * 0.10 * k)[..., None] * cc
        # ring body: saturated colour with whitened hot core
        core = m[..., None]
        edge = blur(m, 5)
        hot = np.clip(edge * 1.6 - 0.35, 0, 1)[..., None]
        body = cc * (1.0 if i == 0 else 0.95)
        add += core * (body * (0.55 + 0.45 * k) + hot * (0.35 if i == 0 else 0.18))
        if i == 0:
            # winner centre dot + extra crisp halo ring
            dot = ring_mask(cx, cy, 22, 0, fill=True)
            add += blur(dot, 14)[..., None] * cc * 0.9 + dot[..., None] * (cc * 0.6 + 0.4)
            halo = ring_mask(cx, cy, r + 70, 8)
            add += (halo * 0.50)[..., None] * cc + blur(halo, 10)[..., None] * cc * 0.5

    # Screen-style combine so overlaps glow without hard clipping.
    add = np.clip(add, 0, None)
    out = 1 - (1 - np.clip(img, 0, 1)) * np.exp(-add * 1.15)
    # Gentle tone shaping keeps the background dark.
    out = np.clip(out, 0, 1)
    rgb = (out * 255 + 0.5).astype(np.uint8)
    im = Image.fromarray(rgb, "RGB")
    return im


def sheet(icon):
    sizes = [180, 120, 87, 80, 60, 58, 40, 29]
    pad = 24
    W = sum(sizes) + pad * (len(sizes) + 1)
    H = 180 + pad * 2 + 20
    sh = Image.new("RGB", (W, H), (38, 38, 46))
    x = pad
    for s in sizes:
        t = icon.resize((s, s), Image.LANCZOS)
        # iOS-style squircle-ish rounded mask for review only
        m = Image.new("L", (s * 4, s * 4), 0)
        ImageDraw.Draw(m).rounded_rectangle([0, 0, s * 4 - 1, s * 4 - 1], radius=int(s * 4 * 0.2237), fill=255)
        m = m.resize((s, s), Image.LANCZOS)
        sh.paste(t, (x, pad + (180 - s) // 2), m)
        x += s + pad
    return sh


if __name__ == "__main__":
    icon = main()
    for p in (OUT_ICON, OUT_COPY, OUT_SHEET):
        os.makedirs(os.path.dirname(p), exist_ok=True)
    icon.save(OUT_ICON, optimize=True)
    icon.save(OUT_COPY, optimize=True)
    sheet(icon).save(OUT_SHEET, optimize=True)
    print("wrote", OUT_ICON, OUT_COPY, OUT_SHEET)
