#!/usr/bin/env python3
"""
Render thumbnail.png directly from the real QR.aj source text.
Usage: python3 tools/render_qr_thumb.py [path/to/QR.aj] [out/thumbnail.png]
"""

import os
import sys
from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
BG = (250, 248, 244)       # Crisp warm ivory (#FAF8F4) for high QR scanner contrast
INK = (20, 18, 16)         # Near-black ink (#141210)
MUTED = (105, 98, 90)
RUST = (158, 59, 30)


def pick_font(candidates: list[str], size: int) -> ImageFont.FreeTypeFont:
    for path in candidates:
        if os.path.exists(path):
            return ImageFont.truetype(path, size)
    return ImageFont.load_default()


def main() -> int:
    aj_path = sys.argv[1] if len(sys.argv) > 1 else os.path.join(ROOT, "QR.aj")
    out_path = sys.argv[2] if len(sys.argv) > 2 else os.path.join(ROOT, "thumbnail.png")

    with open(aj_path, "r", encoding="utf-8") as fh:
        lines = [ln.rstrip("\r\n") for ln in fh]

    max_cols = max(len(ln) for ln in lines)
    n_rows = len(lines)

    mono_candidates = [
        r"C:\Windows\Fonts\consolab.ttf",
        r"C:\Windows\Fonts\CascadiaMono.ttf",
        "/usr/share/fonts/truetype/dejavu/DejaVuSansMono-Bold.ttf",
        "/usr/share/fonts/truetype/liberation/LiberationMono-Bold.ttf",
    ]
    sans_candidates = [
        r"C:\Windows\Fonts\segoeuib.ttf",
        r"C:\Windows\Fonts\arialbd.ttf",
        "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
    ]
    sans_reg_candidates = [
        r"C:\Windows\Fonts\segoeui.ttf",
        r"C:\Windows\Fonts\arial.ttf",
        "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
    ]

    # Pick font size where 18 chars * adv ~= 9 lines * ch (1:1 square QR modules)
    font = pick_font(mono_candidates, 13)
    adv = font.getlength("M")
    ch = max(12, round(adv * 1.92))

    grid_w = int(round(max_cols * adv))
    grid_h = n_rows * ch

    # Generous 4.5-module quiet zone around the 29x29 QR code
    mod_px = 18 * adv
    qz = int(round(4.5 * mod_px))
    footer_h = int(round(mod_px * 3.0))

    W = grid_w + 2 * qz
    H = grid_h + 2 * qz + footer_h

    img = Image.new("RGB", (W, H), BG)
    draw = ImageDraw.Draw(img)

    # Render actual QR.aj lines verbatim (1px stroke keeps dark modules scannable on phone cameras)
    for r, ln in enumerate(lines):
        if ln.strip():
            draw.text((qz, qz + r * ch), ln, fill=INK, font=font, stroke_width=1, stroke_fill=INK)

    # Editorial footer strictly below the 4.5-module quiet zone
    f_y0 = qz + grid_h + qz
    draw.line([(qz, f_y0 - int(mod_px * 0.4)), (W - qz, f_y0 - int(mod_px * 0.4))], fill=(224, 218, 208), width=2)

    # ExaCortex Ring & Dot mark in footer
    mr = int(mod_px * 0.95)
    mcx = qz + mr
    mcy = f_y0 + mr + 4
    draw.ellipse((mcx - mr, mcy - mr, mcx + mr, mcy + mr), outline=INK, width=max(4, mr // 6))
    dr_dot = max(4, int(mr * 0.30))
    draw.ellipse((mcx - dr_dot, mcy - dr_dot, mcx + dr_dot, mcy + dr_dot), fill=RUST)

    f_title = pick_font(sans_candidates, max(22, int(mod_px * 0.68)))
    f_sub = pick_font(sans_reg_candidates, max(16, int(mod_px * 0.46)))
    tx = mcx + mr + int(mod_px * 0.65)
    draw.text((tx, f_y0 + 2), "QR.aj  —  Quine Relay 256 (Strict A–Z)", fill=INK, font=f_title)
    draw.text(
        (tx, f_y0 + int(mod_px * 0.95)),
        f"{os.path.getsize(aj_path):,} B AspectJ source  ·  Zoom in for code, or scan QR -> github.com/exacortex/quine-relay-256",
        fill=MUTED,
        font=f_sub,
    )

    # Keep 2200px wide so zooming in clearly reads the AspectJ source code
    target_w = 2200
    if W > target_w:
        target_h = int(round(H * target_w / W))
        img = img.resize((target_w, target_h), Image.Resampling.LANCZOS)

    img.save(out_path, optimize=True)
    print(f"Wrote {out_path} ({img.size[0]}x{img.size[1]} px from {max_cols}x{n_rows} chars)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
