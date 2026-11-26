#!/usr/bin/env python3
"""
Render langs.png — 256-Language Strict A-Z Uroboros Wheel (pure PIL, no Cairo needed).
Reads step names and origins directly from LANGUAGES.md.
Usage: python3 tools/langs_png.py [out/langs.png]
"""

import math
import os
import re
import sys
from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
LANG_ROW_RE = re.compile(r"^\|\s*(\d+)\s*\|\s*(.+?)\s*\|\s*(.+?)\s*\|")

BG = (250, 248, 244)       # Warm editorial ivory (#FAF8F4)
INK = (27, 25, 22)         # Near-black (#1B1916) for mame-128
RUST = (158, 59, 30)       # ExaCortex Rust (#9E3B1E) for fork-128
BRASS = (169, 132, 63)     # ExaCortex Brass (#A9843F)
MUTED = (105, 98, 90)
RULE = (224, 218, 208)


def pick_font(candidates: list[str], size: int) -> ImageFont.FreeTypeFont:
    for p in candidates:
        if os.path.exists(p):
            return ImageFont.truetype(p, size)
    return ImageFont.load_default()


def load_languages(root: str) -> list[tuple[int, str, bool]]:
    path = os.path.join(root, "LANGUAGES.md")
    rows = []
    with open(path, "r", encoding="utf-8") as fh:
        for ln in fh:
            m = LANG_ROW_RE.match(ln.strip())
            if m:
                idx = int(m.group(1))
                name = m.group(2).strip()
                is_upstream = "mame" in m.group(3)
                rows.append((idx, name, is_upstream))
    if len(rows) != 256:
        raise RuntimeError(f"Expected 256 rows in LANGUAGES.md, got {len(rows)}")
    return rows


def main() -> int:
    out_path = sys.argv[1] if len(sys.argv) > 1 else os.path.join(ROOT, "langs.png")
    rows = load_languages(ROOT)
    N = len(rows)

    # Work at 2x supersampled resolution (4200x4200 -> downscale to 2100x2100)
    S = 2
    W = H = 2100 * S
    cx = cy = W // 2
    R = 670 * S

    sans_bold = [
        r"C:\Windows\Fonts\segoeuib.ttf",
        r"C:\Windows\Fonts\arialbd.ttf",
        "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
    ]
    sans_reg = [
        r"C:\Windows\Fonts\segoeui.ttf",
        r"C:\Windows\Fonts\arial.ttf",
        "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
    ]
    mono_bold = [
        r"C:\Windows\Fonts\consolab.ttf",
        "/usr/share/fonts/truetype/dejavu/DejaVuSansMono-Bold.ttf",
    ]

    f_name = pick_font(sans_bold, 13 * S)
    f_sub = pick_font(sans_reg, 10 * S)
    f_title = pick_font(sans_bold, 54 * S)
    f_subtitle = pick_font(sans_reg, 26 * S)
    f_legend = pick_font(sans_bold, 22 * S)
    f_tag = pick_font(mono_bold, 11 * S)

    img = Image.new("RGB", (W, H), BG)
    draw = ImageDraw.Draw(img)

    # Outer subtle reference ring and directional clockwise arcs
    draw.ellipse((cx - R - 8 * S, cy - R - 8 * S, cx + R + 8 * S, cy + R + 8 * S), outline=RULE, width=1 * S)

    num_arcs = 12
    gap_deg = 4.5
    span_deg = 360.0 / num_arcs
    for k in range(num_arcs):
        a0 = -90.0 + k * span_deg + gap_deg / 2.0
        a1 = -90.0 + (k + 1) * span_deg - gap_deg / 2.0
        draw.arc((cx - R, cy - R, cx + R, cy + R), start=a0, end=a1, fill=INK, width=3 * S)
        # Arrowhead at a1 pointing clockwise
        rad = math.radians(a1)
        ax = cx + R * math.cos(rad)
        ay = cy + R * math.sin(rad)
        # Tangent clockwise vector = (-sin(rad), cos(rad))
        tx, ty = -math.sin(rad), math.cos(rad)
        nx, ny = math.cos(rad), math.sin(rad)
        tip = (ax + tx * 10 * S, ay + ty * 10 * S)
        p1 = (ax - tx * 5 * S + nx * 6 * S, ay - ty * 5 * S + ny * 6 * S)
        p2 = (ax - tx * 5 * S - nx * 6 * S, ay - ty * 5 * S - ny * 6 * S)
        draw.polygon([tip, p1, p2], fill=RUST if k == 0 else INK)

    # Radial labels starting at 12 o'clock (#1 AspectJ) clockwise
    for i, (idx, full, is_up) in enumerate(rows):
        if "(" in full and full.endswith(")"):
            k = full.index("(")
            main_s, paren_s = full[:k].rstrip(), " " + full[k:]
        else:
            main_s, paren_s = full, ""

        col = INK if is_up else RUST
        b1 = draw.textbbox((0, 0), main_s, font=f_name)
        b2 = draw.textbbox((0, 0), paren_s, font=f_sub) if paren_s else (0, 0, 0, 0)
        w1 = b1[2] - b1[0]
        w2 = b2[2] - b2[0]
        tw = w1 + w2 + 8 * S
        th = max(b1[3] - b1[1], b2[3] - b2[1]) + 10 * S

        stamp = Image.new("RGBA", (tw, th), (0, 0, 0, 0))
        sd = ImageDraw.Draw(stamp)
        # Math angle: 12 o'clock = 90 deg, clockwise decreases
        math_deg = 90.0 - (360.0 * i / N)
        right_half = i < (N // 2)

        if right_half:
            sd.text((0, 2 * S), main_s, fill=col + (255,), font=f_name)
            if paren_s:
                sd.text((w1, 4 * S), paren_s, fill=(MUTED if is_up else col) + (255,), font=f_sub)
            rot_deg = math_deg
        else:
            # Left half rotated +180 deg: text still reads left-to-right (main_s then paren_s),
            # right-aligned cleanly near the ring (outer side on left, inner side near R).
            x0 = 6 * S
            sd.text((x0, 2 * S), main_s, fill=col + (255,), font=f_name)
            if paren_s:
                sd.text((x0 + w1, 4 * S), paren_s, fill=(MUTED if is_up else col) + (255,), font=f_sub)
            rot_deg = math_deg + 180.0

        rotated = stamp.rotate(rot_deg, resample=Image.Resampling.BICUBIC, expand=True)
        rad = math.radians(math_deg)
        center_r = R + 18 * S + (tw / 2.0)
        px = int(round(cx + center_r * math.cos(rad) - rotated.width / 2.0))
        py = int(round(cy - center_r * math.sin(rad) - rotated.height / 2.0))
        img.paste(rotated, (px, py), rotated)

    # Step #1 entry marker inside ring at 12 o'clock
    t_lbl = "#1 ENTRY (QR.aj)"
    tb = draw.textbbox((0, 0), t_lbl, font=f_tag)
    draw.text((cx - (tb[2] - tb[0]) // 2, cy - R + 22 * S), t_lbl, fill=RUST, font=f_tag)

    # Centerpiece: ExaCortex Ring & Dot mark (Variant A proportions: R=40, stroke=6, r_dot=12)
    mr = 135 * S
    mcy = cy - 115 * S
    draw.ellipse((cx - mr, mcy - mr, cx + mr, mcy + mr), outline=INK, width=int(round(mr * 0.15)))
    dr_dot = int(round(mr * 0.30))
    draw.ellipse((cx - dr_dot, mcy - dr_dot, cx + dr_dot, mcy + dr_dot), fill=INK)

    # Center typography & legend
    title = "Quine Relay 256"
    sub = "Strict A–Z Edition  ·  256 Distinct Steps"
    tb = draw.textbbox((0, 0), title, font=f_title)
    draw.text((cx - (tb[2] - tb[0]) // 2, cy + 52 * S), title, fill=INK, font=f_title)
    sb_box = draw.textbbox((0, 0), sub, font=f_subtitle)
    draw.text((cx - (sb_box[2] - sb_box[0]) // 2, cy + 124 * S), sub, fill=MUTED, font=f_subtitle)

    # Color legend pills
    leg_y = cy + 190 * S
    l1 = "mame/quine-relay (128)"
    l2 = "this fork additions (128)"
    b1 = draw.textbbox((0, 0), l1, font=f_legend)
    b2 = draw.textbbox((0, 0), l2, font=f_legend)
    gap = 44 * S
    sw = 18 * S
    tot_w = (sw + 10 * S + b1[2] - b1[0]) + gap + (sw + 10 * S + b2[2] - b2[0])
    lx = cx - tot_w // 2
    draw.ellipse((lx, leg_y + 5 * S, lx + sw, leg_y + 5 * S + sw), fill=INK)
    draw.text((lx + sw + 10 * S, leg_y), l1, fill=INK, font=f_legend)
    lx2 = lx + sw + 10 * S + (b1[2] - b1[0]) + gap
    draw.ellipse((lx2, leg_y + 5 * S, lx2 + sw, leg_y + 5 * S + sw), fill=RUST)
    draw.text((lx2 + sw + 10 * S, leg_y), l2, fill=RUST, font=f_legend)

    final_img = img.resize((2100, 2100), Image.Resampling.LANCZOS)
    final_img.save(out_path, optimize=True)
    print(f"Wrote {out_path} ({final_img.size[0]}x{final_img.size[1]})")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
