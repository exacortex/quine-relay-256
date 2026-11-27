#!/usr/bin/env python3
"""
Render assets/terminal-demo.gif (and inspection PNG keyframes) depicting
tools/relay_ui.py running across the 256-step A-Z relay.
Usage: python3 tools/render_demo_gif.py [sizes.json] [out/terminal-demo.gif]
"""

import json
import math
import os
import sys
from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
DEFAULT_JSON = r"D:\DrawnWithCode\_tmp\qr256_sizes.json"

BG = (20, 19, 17)         # Dark warm terminal (#141311)
BAR_BG = (32, 30, 27)
BORDER = (72, 68, 62)
BONE = (243, 239, 231)
BRASS = (196, 154, 69)
RUST = (224, 98, 54)
GREEN = (74, 222, 128)
CYAN = (125, 211, 252)
MUTED = (145, 138, 128)
DIM = (86, 82, 76)

SNIPPETS = {
    1: ("QR.aj", "AspectJ -> Asymptote", "mame-128", [
        "import java.io.*;import java.util.*;import java.util.regex.*;import java.util.zip.*;",
        'static String[]B={"MnQKRd95DF(]2;|^h7DY.ZXp0c@8}03hh4l]!As9/B(v>zr4&}Xe5z#mY...',
        "aspect Q{static byte[]D;static int P;before():execution(void QR.main(..)){init();}}",
    ]),
    24: ("QR.chpl", "Chapel -> Chef", "fork-128", [
        'use IO;proc main(){var s="""...',
        "write(s);}",
        "# Emitting 2,442,046-byte Chef recipe payload...",
    ]),
    59: ("QR.flix", "Flix -> Forth", "fork-128", [
        "def main(): Unit \\ IO =",
        '    let s = "...";',
        "    Console.print(s)",
    ]),
    105: ("QR.jsfuck", "JSFuck -> Julia", "mame-128", [
        "[][(![]+[])[+[]]+(![]+[])[!+[]+!+[]]+(![]+[])[+!+[]]+(!![]+[])[+[]]][([][(![]+[])...",
        "+(+!+[]+[+!+[]]+(!![]+[])[!+[]+!+[]+!+[]]+[!+[]+!+[]]+[+[]])+[])[+!+[]]+...",
        "(16,740,100 bytes strictly using []()!+)",
    ]),
    127: ("QR.mb", "Malbolge Unshackled -> Mathics", "fork-128", [
        "(=<`#9]~6ZY327Uv4-QsqpMn&+Ij\"'E%e{Ab~w=_:]Kw%o44Uqp0/Q?xNvL:`H%c#DD2^WV>gY;Nj3?",
        "(&%$#\"!~}|{zyxwvutsrqponmlkjihgfedcba`_^]\\[ZYXWVUTSRQPONMLKJIHGFEDCBA@?>=<;:987",
        "(3,080,162 bytes · zero '/' ops · dual CC0 parity)",
    ]),
    167: ("QR.ppm", "Piet -> Pike", "mame-128", [
        "P6  432029 128 255   [165,899,154 bytes raw RGB PPM codels]",
        "000000 ffffff 00c0ff c000ff ff0000 00ff00 c0c000 ...",
        "$ npiet QR.ppm > QR.pike",
    ]),
    201: ("QR.spl", "Shakespeare -> Simula", "mame-128", [
        "The Relay of Quine.",
        "Ajax, a young man.   Ford, a trustworthy old man.",
        "[Enter Ajax and Ford]  Ajax: Thou art as bad as the sum of a cat and a...",
    ]),
    222: ("QR.tal", "Uxntal -> V", "fork-128", [
        "|0100 ;pre ;p JSR2 ;z @l DUP2 ;ze EQU2 ;d JCN2 LDAk #00 STZ INC2...",
        "@t 41 42 43 44 45 46 47 48 ...   (ROM 45,626 B / 65,280 B)",
        "$ uxnasm QR.tal QR.rom && uxncli QR.rom > QR.vlang.v",
    ]),
    240: ("QR.z80", "Z80 asm -> Zig", "fork-128", [
        " org 0100h / ld hl,msg / loop: ld a,(hl) / or a / jr z,done / call 5",
        ' db "const s=@import(\\"std\\");pub fn main()!void{..." (COM 50,152 B / 64,991 B)',
        "$ z80asm QR.z80 -o qr.com && tnylpo -b qr.com < /dev/null > QR.zig",
    ]),
    244: ("QR.s65", "6502 asm -> A+", "fork-128", [
        ' .byt "sim65",2,0,2,$00,$02,$00,$02  * = $0200  ldx #$ff  txs  jsr emit',
        ' .byt ".global _start",".text",10,"_start:",10,...  (BIN 45,842 B / 65,012 B)',
        "$ xa -o QR.o65 QR.s65 && sim65 QR.o65 > QR.aplus.a",
    ]),
    254: ("QR.arnoldc", "ArnoldC -> Arturo", "fork-128", [
        "IT'S SHOWTIME   /   DO IT NOW m0",
        'TALK TO THE HAND "s: {:import stdlib..."',
        "YOU HAVE BEEN TERMINATED",
    ]),
    256: ("QR.cc", "AspectC++ -> AspectJ", "fork-128", [
        "#include<cstdio>",
        'aspect Q{advice execution("int main()"):before(){fputs(R"Q(import java.io.*;...',
        ')Q",stdout);} };int main(){}',
    ]),
}

MILESTONES = [
    (105, "JSFuck"),
    (127, "Malbolge"),
    (167, "Piet 158M"),
    (201, "Shakespeare"),
    (222, "Uxntal <64K"),
    (240, "Z80 <64K"),
    (244, "6502 <64K"),
]

DIAL = list("ABCDEFGHIJKLMNOPQRSTUVWXYZ6")


def pick_font(cands: list[str], size: int):
    for p in cands:
        if os.path.exists(p):
            return ImageFont.truetype(p, size)
    return ImageFont.load_default()


def fmt_bytes(n: int) -> str:
    if n < 1024:
        return f"{n} B"
    if n < 1024 * 1024:
        return f"{n / 1024:.1f} KiB"
    return f"{n / (1024 * 1024):.2f} MiB"


def slot_for(name: str) -> int:
    for c in name:
        if c.isalpha():
            return ord(c.upper()) - ord("A")
        if c.isdigit():
            return 26
    return 0


def render_frame(runs, tick: int, cur_step: int, f_m, f_b, f_s, f_vm, f_vb, f_hero=None, victory: bool = False) -> Image.Image:
    W, H = 920, 520
    img = Image.new("RGB", (W, H), BG)
    dr = ImageDraw.Draw(img)

    # Outer terminal window frame & titlebar
    dr.rounded_rectangle((6, 6, W - 7, H - 7), radius=10, fill=BG, outline=BORDER, width=2)
    dr.rectangle((8, 8, W - 9, 36), fill=BAR_BG)
    dr.line([(8, 36), (W - 9, 36)], fill=BORDER, width=1)
    for idx, col in enumerate(((224, 98, 54), (196, 154, 69), (74, 222, 128))):
        dr.ellipse((20 + idx * 18, 17, 30 + idx * 18, 27), fill=col)
    dr.text((86, 14), "docker run --rm -it --network=none quine-relay-256", fill=MUTED, font=f_s)

    if victory:
        # Left panel: verified round-trip summary card
        bx0, by0, bx1, by1 = 26, 68, 606, 444
        dr.rounded_rectangle((bx0, by0, bx1, by1), radius=8, fill=(24, 23, 20), outline=BRASS, width=2)
        dr.line([(bx0, by0 + 52), (bx1, by0 + 52)], fill=BRASS, width=1)
        dr.ellipse((bx0 + 20, by0 + 19, bx0 + 34, by0 + 33), fill=GREEN)
        dr.text((bx0 + 44, by0 + 17), "QUINE RELAY 256 — VERIFIED ROUND-TRIP", fill=GREEN, font=f_vb)

        lines = [
            ("Steps:",   "256 / 256 Strict A–Z (128 upstream + 128 fork)"),
            ("Match:",   "diff -s QR.aj QR2.aj -> identical (54,812 B)"),
            ("Hashes:",  "sha256sum --quiet -c SHA256SUMS -> 256/256 OK"),
            ("Peak:",    "158.21 MiB (#167 Piet) · 27.6 MiB (Shakespeare)"),
            ("16-bit:",  "6502 45,842 B · Z80 50,152 B · Uxntal 45,626 B"),
            ("QR.aj:",   "sha256: 0c88b16f... · lean 53.5 KiB pure seed"),
        ]
        y = by0 + 78
        for k, v in lines:
            dr.text((bx0 + 20, y), k, fill=BRASS, font=f_vb)
            dr.text((bx0 + 96, y), v, fill=BONE, font=f_vm)
            y += 46

        # Right panel: ExaCortex Ring & Dot + bold '256' emblem
        qx0, qy0, qx1, qy1 = 624, 68, 894, 444
        dr.rounded_rectangle((qx0, qy0, qx1, qy1), radius=8, fill=(24, 23, 20), outline=BRASS, width=2)
        qcx = (qx0 + qx1) / 2
        rcy = 148
        rr = 52
        dr.ellipse((qcx - rr, rcy - rr, qcx + rr, rcy + rr), outline=BRASS, width=4)
        dr.ellipse((qcx - 14, rcy - 14, qcx + 14, rcy + 14), fill=BONE)
        dr.ellipse((qcx - 5, rcy - rr - 5, qcx + 5, rcy - rr + 5), fill=RUST)

        if f_hero is not None:
            bb = dr.textbbox((0, 0), "256", font=f_hero)
            tw = bb[2] - bb[0]
            dr.text((qcx - tw / 2 - bb[0], 222 - bb[1]), "256", fill=BONE, font=f_hero)

        c1 = "STRICT A–Z CYCLE"
        c2 = "128 upstream + 128 fork"
        c3 = "54,812 B pure-code seed"
        dr.text((qcx - dr.textlength(c1, font=f_vb) / 2, 314), c1, fill=BRASS, font=f_vb)
        dr.text((qcx - dr.textlength(c2, font=f_s) / 2, 344), c2, fill=MUTED, font=f_s)
        dr.text((qcx - dr.textlength(c3, font=f_s) / 2, 372), c3, fill=MUTED, font=f_s)

        dr.text((28, 466), "$ _", fill=MUTED, font=f_m)
        return img

    # Animated ExaCortex Ring & Dot mark (top-left)
    mcx, mcy, mr = 64, 96, 36
    dr.ellipse((mcx - mr, mcy - mr, mcx + mr, mcy + mr), outline=BRASS, width=4)
    dr.ellipse((mcx - 10, mcy - 10, mcx + 10, mcy + 10), fill=BONE)
    ang = (tick * 0.42) - math.pi / 2.0
    ox = mcx + mr * math.cos(ang)
    oy = mcy + mr * math.sin(ang)
    dr.ellipse((ox - 5, oy - 5, ox + 5, oy + 5), fill=RUST)

    # Header text & A-Z dial
    r_info = runs[cur_step - 1]
    name = r_info["name"]
    sn = SNIPPETS.get(cur_step)
    trans = sn[1] if sn else f"{name} -> {runs[cur_step % 256]['name']}"
    src_f = r_info["src"]
    cur_b = r_info["bytes"]
    peak_b = max(r["bytes"] for r in runs[:cur_step])

    dr.text((120, 56), "EXACORTEX // QUINE RELAY 256", fill=BONE, font=f_b)
    dr.text((395, 58), "Strict A–Z  ·  128 upstream + 128 fork", fill=MUTED, font=f_s)

    # Spinning A-Z dial
    active_slot = slot_for(name)
    dx = 120
    for idx, ch in enumerate(DIAL):
        if idx < active_slot:
            col = BRASS
        elif idx == active_slot:
            dr.rounded_rectangle((dx - 3, 82, dx + 14, 102), radius=3, fill=RUST)
            col = BONE
        else:
            col = DIM
        dr.text((dx, 84), ch, fill=col, font=f_b)
        dx += 24

    dr.text((120, 114), f"[{cur_step:3d}/256]  {trans}", fill=BONE, font=f_b)
    dr.text((640, 115), f"File: {src_f} ({fmt_bytes(cur_b)})", fill=CYAN, font=f_m)

    dr.line([(24, 148), (W - 24, 148)], fill=BORDER, width=1)

    # Progress bar
    frac = cur_step / 256.0
    pb_x0, pb_y0, pb_x1, pb_y1 = 24, 164, W - 236, 182
    dr.rounded_rectangle((pb_x0, pb_y0, pb_x1, pb_y1), radius=4, fill=(38, 36, 32))
    fw = max(8, int((pb_x1 - pb_x0) * frac))
    dr.rounded_rectangle((pb_x0, pb_y0, pb_x0 + fw, pb_y1), radius=4, fill=RUST)
    dr.text((pb_x1 + 14, 164), f"{frac * 100:5.1f}%  Peak: {fmt_bytes(peak_b)}", fill=BONE, font=f_m)

    # Log-scale payload sparkline bar graph
    sp_x0, sp_y0, sp_x1, sp_y1 = 24, 200, W - 24, 260
    dr.rounded_rectangle((sp_x0, sp_y0, sp_x1, sp_y1), radius=5, fill=(26, 24, 21), outline=(48, 45, 40))
    dr.text((sp_x0 + 10, sp_y0 + 6), "PAYLOAD (LOG SCALE)", fill=MUTED, font=f_s)
    bars_x0 = sp_x0 + 150
    bars_w = sp_x1 - bars_x0 - 14
    n_bars = 80
    for bi in range(n_bars):
        st_idx = int(bi * 256 / n_bars)
        bx = bars_x0 + int(bi * bars_w / n_bars)
        bw = max(3, int(bars_w / n_bars) - 2)
        if st_idx + 1 <= cur_step:
            bval = runs[st_idx]["bytes"]
            lv = math.log10(max(10_000, bval))
            norm = max(0.08, min(1.0, (lv - 4.7) / 3.65))
            bh = int(norm * 42)
            col = RUST if lv > 7.0 else (BRASS if lv > 5.7 else GREEN)
            dr.rectangle((bx, sp_y1 - 8 - bh, bx + bw, sp_y1 - 8), fill=col)
        else:
            dr.rectangle((bx, sp_y1 - 10, bx + bw, sp_y1 - 8), fill=DIM)

    # Milestone strip
    mx = 24
    for m_step, m_lbl in MILESTONES:
        hit = cur_step >= m_step
        col = GREEN if cur_step > m_step else (RUST if cur_step == m_step else DIM)
        dr.ellipse((mx, 278, mx + 9, 287), fill=col)
        dr.text((mx + 14, 275), m_lbl, fill=BONE if hit else DIM, font=f_s)
        mx += 124

    dr.line([(24, 304), (W - 24, 304)], fill=BORDER, width=1)

    # Live source peek box
    dr.text((24, 316), "LIVE GENERATED SOURCE PEEK", fill=MUTED, font=f_s)
    dr.text((240, 316), src_f, fill=CYAN, font=f_s)
    peek_lines = sn[3] if sn else [f"/* Step #{cur_step}: {name} */", f"size = {cur_b:,} bytes"]
    py = 340
    for pl in peek_lines[:3]:
        dr.text((34, py), pl[:95], fill=BONE, font=f_m)
        py += 22

    dr.line([(24, 412), (W - 24, 412)], fill=BORDER, width=1)

    # Recent completed steps
    ry = 424
    prev_steps = [max(1, cur_step - 1), max(1, cur_step - 2), max(1, cur_step - 3)]
    for ps in prev_steps:
        if ps < cur_step:
            pr = runs[ps - 1]
            nxt_n = runs[ps % 256]["name"]
            dr.text((28, ry), f"✓ #{ps:03d}  {pr['name']} -> {nxt_n}", fill=GREEN, font=f_m)
            dr.text((680, ry), f"{fmt_bytes(pr['bytes']):>10s}", fill=MUTED, font=f_m)
            ry += 26

    return img


def main() -> int:
    json_path = sys.argv[1] if len(sys.argv) > 1 else DEFAULT_JSON
    out_gif = sys.argv[2] if len(sys.argv) > 2 else os.path.join(ROOT, "assets", "terminal-demo.gif")
    os.makedirs(os.path.dirname(out_gif), exist_ok=True)

    with open(json_path, "r", encoding="utf-8") as fh:
        runs = json.load(fh)["run_steps"]

    mono = [r"C:\Windows\Fonts\CascadiaMono.ttf", r"C:\Windows\Fonts\consola.ttf", "/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf"]
    mono_b = [r"C:\Windows\Fonts\consolab.ttf", r"C:\Windows\Fonts\CascadiaMono.ttf", "/usr/share/fonts/truetype/dejavu/DejaVuSansMono-Bold.ttf"]
    sans_b = [r"C:\Windows\Fonts\segoeuib.ttf", r"C:\Windows\Fonts\arialbd.ttf", "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"]
    f_m = pick_font(mono, 14)
    f_b = pick_font(mono_b, 14)
    f_s = pick_font(mono, 12)
    f_vm = pick_font(mono, 13)
    f_vb = pick_font(mono_b, 13)
    f_hero = pick_font(sans_b, 68)

    timeline = [
        (1, 4), (24, 3), (59, 3), (105, 4), (127, 4),
        (167, 5), (201, 5), (222, 4), (240, 4), (244, 4),
        (254, 3), (256, 3),
    ]
    frames = []
    durations = []
    tick = 0
    keyframe_saved = False
    for step, count in timeline:
        for _ in range(count):
            fr = render_frame(runs, tick, step, f_m, f_b, f_s, f_vm, f_vb, victory=False)
            frames.append(fr)
            durations.append(160)
            if step == 167 and not keyframe_saved:
                fr.save(r"D:\DrawnWithCode\_tmp\demo_keyframe.png")
                keyframe_saved = True
            tick += 1

    v_fr = render_frame(runs, tick, 256, f_m, f_b, f_s, f_vm, f_vb, f_hero=f_hero, victory=True)
    v_fr.save(r"D:\DrawnWithCode\_tmp\demo_victory.png")
    frames.append(v_fr)
    durations.append(3200)

    # Quantize smoothly with adaptive palette for crisp compact GIF
    q_frames = [f.convert("P", palette=Image.Palette.ADAPTIVE, colors=64) for f in frames]
    q_frames[0].save(
        out_gif,
        save_all=True,
        append_images=q_frames[1:],
        duration=durations,
        loop=0,
        optimize=True,
    )
    print(f"Wrote {out_gif} ({len(frames)} frames, {os.path.getsize(out_gif):,} B)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
