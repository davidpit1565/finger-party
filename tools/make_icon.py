#!/usr/bin/env python3
"""Procedural Finger Picker app icon (original artwork, no external assets).

Rings are drawn crisp at 4096px (supersampled), downscaled with LANCZOS to
1024, then glow/bloom are composited additively in linear-ish float space.
Output: opaque sRGB RGB 1024x1024 PNG, no alpha.

Usage: python3 tools/make_icon.py
"""
import os
import numpy as np
from PIL import ImageCms
from PIL import Image, ImageDraw, ImageFilter

SRGB = ImageCms.ImageCmsProfile(ImageCms.createProfile("sRGB")).tobytes()
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
    (540, 545, 170, 60, CORAL, 1.00),   # winner
    (315, 410, 135, 44, CYAN, 0.85),
    (740, 330, 118, 40, VIOLET, 0.82),
    (345, 740, 125, 42, AMBER, 0.85),
    (735, 720, 112, 38, LIME, 0.80),
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
    # Background: near-black with a barely-there lift toward centre.
    d = np.sqrt((xx - 530) ** 2 + (yy - 530) ** 2) / 800
    img = BG[None, None, :] * (1.0 + 0.35 * np.clip(1 - d, 0, 1)[..., None] ** 2)
    img = np.broadcast_to(img, (N, N, 3)).copy()

    # Radial colour bloom spreading from the winner.
    wx, wy, wr, ww, wc, _ = RINGS[0]
    dist = np.sqrt((xx - wx) ** 2 + (yy - wy) ** 2)
    bloom = np.exp(-(dist / 360.0) ** 2) * 0.26 + np.exp(-(dist / 640.0) ** 1.5) * 0.07
    img += bloom[..., None] * col(wc)

    glow_add = np.zeros_like(img)
    for i, (cx, cy, r, w, c, k) in enumerate(RINGS):
        m = ring_mask(cx, cy, r, w)
        cc = col(c)
        glow = blur(m, 55) * 0.95 + blur(m, 20) * 0.85 + blur(m, 6) * 0.45
        glow_add += glow[..., None] * cc * k * (1.7 if i == 0 else 1.0)
        # faint fingertip-contact fill inside the ring
        disc = ring_mask(cx, cy, r - w / 2, w, fill=True)
        glow_add += (disc * 0.07 * k)[..., None] * cc
        if i == 0:
            dot = ring_mask(cx, cy, 20, 0, fill=True)
            glow_add += blur(dot, 16)[..., None] * cc * 0.9
    out = 1 - (1 - np.clip(img, 0, 1)) * np.exp(-glow_add * 1.1)

    cov = np.zeros((N, N), np.float32)
    # Ring bodies: saturated colour composited over the glow; hot core on edges.
    for i, (cx, cy, r, w, c, k) in enumerate(RINGS):
        m = ring_mask(cx, cy, r, w)
        cc = col(c)
        # soft hot core: blurred centre-line highlight (no hard stripe)
        core = blur(ring_mask(cx, cy, r, w * 0.45), 4)
        tint = cc * (0.82 + 0.18 * k)
        body = tint + core[..., None] * (0.22 if i == 0 else 0.10) * (1 - tint)
        # light-like screen blend so overlaps brighten instead of occluding
        out = out * (1 - m[..., None]) + body * m[..., None]
        cov += m
        if i == 0:
            dot = ring_mask(cx, cy, 20, 0, fill=True)
            dc = cc + 0.45 * (1 - cc)
            out = out * (1 - dot[..., None]) + dc * dot[..., None]
    # where two rings cross, light adds up: soft brightening of the overlap
    ovl = np.clip(cov - 1.0, 0, 1)
    out = out + ovl[..., None] * (1 - out) * 0.38
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
    icon.save(OUT_ICON, optimize=True, icc_profile=SRGB)
    icon.save(OUT_COPY, optimize=True, icc_profile=SRGB)
    sheet(icon).save(OUT_SHEET, optimize=True, icc_profile=SRGB)
    print("wrote", OUT_ICON, OUT_COPY, OUT_SHEET)
