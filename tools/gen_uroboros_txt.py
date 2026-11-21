#!/usr/bin/env python3
"""
gen_uroboros_txt.py -- Pure-stdlib SVG-to-ASCII rasterizer for uroboros.txt

Rasterizes Yusuke Endoh's vector src/uroboros.svg into a properly scaled
`uroboros.txt` ASCII template (`#` for code cells, ` ` for the Ouroboros
dragon silhouette) with zero third-party dependencies.

Why scale uroboros.txt for Quine Relay 256?
-------------------------------------------
Endoh's original `uroboros.txt` (59 rows x 211 cols, 8,523 B capacity) was
sized for the 100/128-language relay (~9.6 KB code payload -> 1 overflow pass
to 61 x 223, where the dragon occupies 27.3% of the canvas).

With 256 languages (~32.5-36.8 KB compressed Ruby payload), the 59 x 211
template overflows 16 times into a 91 x 403 block where the dragon shrinks
to 10.1% of the canvas inside 22-row/101-column walls of code.

Default target: 115 rows x 409 cols (pad_y=8, pad_x=19, threshold=0.45)
  - Visual size in thumbnail.png (4x8 px/char): 1636 x 920 px (AR 1.778 = 16:9)
  - Dragon bounding box: 99 rows x 371 cols (AR 1.874 vs uroboros.svg 1.866)
  - Dragon silhouette area: ~28.3% at 0 overflows, ~27.0% at 1 overflow,
    ~25.8% at 2 overflows (matching mame-128's 27.3% proportions!)
  - Base capacity (0 overflows): ~33,341 B compressed code
  - Graceful scaling through 0-3 overflows up to ~40,000 B code payloads

Usage
-----
  python3 gen_uroboros_txt.py                           # default 115x409
  python3 gen_uroboros_txt.py --svg src/uroboros.svg -o src/uroboros.txt
  python3 gen_uroboros_txt.py --rows 117 --cols 417 --pad-y 9 --pad-x 23
"""

import argparse
import re
import sys
from pathlib import Path

_TOKEN_RE = re.compile(
    r"[A-Za-z]|[-+]?(?:\d+\.?\d*|\.\d+)(?:[eE][-+]?\d+)?"
)


def parse_svg_geometry(svg_text: str) -> tuple[float, float, list[list[tuple[float, float]]]]:
    """Extract (view_w, view_h, flattened_subpaths) from uroboros.svg."""
    vb = re.search(
        r'viewBox\s*=\s*"\s*([-+0-9.eE]+)\s+([-+0-9.eE]+)\s+([-+0-9.eE]+)\s+([-+0-9.eE]+)\s*"',
        svg_text,
    )
    if vb:
        vx, vy, vw, vh = (float(vb.group(i)) for i in range(1, 5))
    else:
        wm = re.search(r'width\s*=\s*"([-+0-9.eE]+)', svg_text)
        hm = re.search(r'height\s*=\s*"([-+0-9.eE]+)', svg_text)
        if not (wm and hm):
            raise ValueError("SVG missing viewBox and width/height")
        vx, vy, vw, vh = 0.0, 0.0, float(wm.group(1)), float(hm.group(1))

    path_ds = re.findall(r'<path[^>]*\bd="([^"]+)"', svg_text, re.S)
    if not path_ds:
        raise ValueError("No <path d=...> found in SVG")

    subpaths = []
    for d_attr in path_ds:
        subpaths.extend(_parse_and_flatten_path(d_attr, vx, vy, steps=48))
    return vw, vh, subpaths


def _parse_and_flatten_path(
    d_attr: str, ox: float, oy: float, steps: int = 48
) -> list[list[tuple[float, float]]]:
    tokens = _TOKEN_RE.findall(d_attr)
    subpaths: list[list[tuple[float, float]]] = []
    cur: list[tuple[float, float]] = []
    i = 0
    x = y = sx = sy = 0.0
    last_cp: tuple[float, float] | None = None
    cmd: str | None = None

    def nxt() -> float:
        nonlocal i
        val = float(tokens[i])
        i += 1
        return val

    while i < len(tokens):
        if tokens[i].isalpha():
            cmd = tokens[i]
            i += 1
        if cmd == "M":
            if cur:
                subpaths.append(cur)
                cur = []
            x, y = nxt() - ox, nxt() - oy
            sx, sy = x, y
            cur.append((x, y))
            last_cp = None
            cmd = "L"
        elif cmd == "m":
            if cur:
                subpaths.append(cur)
                cur = []
            x += nxt()
            y += nxt()
            if not subpaths and not cur:
                x -= ox
                y -= oy
            sx, sy = x, y
            cur.append((x, y))
            last_cp = None
            cmd = "l"
        elif cmd == "L":
            x, y = nxt() - ox, nxt() - oy
            cur.append((x, y))
            last_cp = None
        elif cmd == "l":
            x += nxt()
            y += nxt()
            cur.append((x, y))
            last_cp = None
        elif cmd == "H":
            x = nxt() - ox
            cur.append((x, y))
            last_cp = None
        elif cmd == "h":
            x += nxt()
            cur.append((x, y))
            last_cp = None
        elif cmd == "V":
            y = nxt() - oy
            cur.append((x, y))
            last_cp = None
        elif cmd == "v":
            y += nxt()
            cur.append((x, y))
            last_cp = None
        elif cmd in ("C", "c", "S", "s"):
            x0, y0 = x, y
            if cmd == "C":
                x1, y1 = nxt() - ox, nxt() - oy
                x2, y2 = nxt() - ox, nxt() - oy
                x3, y3 = nxt() - ox, nxt() - oy
            elif cmd == "c":
                x1, y1 = x + nxt(), y + nxt()
                x2, y2 = x + nxt(), y + nxt()
                x3, y3 = x + nxt(), y + nxt()
            elif cmd == "S":
                x1, y1 = (2 * x - last_cp[0], 2 * y - last_cp[1]) if last_cp else (x, y)
                x2, y2 = nxt() - ox, nxt() - oy
                x3, y3 = nxt() - ox, nxt() - oy
            else:
                x1, y1 = (2 * x - last_cp[0], 2 * y - last_cp[1]) if last_cp else (x, y)
                x2, y2 = x + nxt(), y + nxt()
                x3, y3 = x + nxt(), y + nxt()
            for k in range(1, steps + 1):
                t = k / steps
                mt = 1.0 - t
                px = mt**3 * x0 + 3 * mt**2 * t * x1 + 3 * mt * t**2 * x2 + t**3 * x3
                py = mt**3 * y0 + 3 * mt**2 * t * y1 + 3 * mt * t**2 * y2 + t**3 * y3
                cur.append((px, py))
            last_cp = (x2, y2)
            x, y = x3, y3
        elif cmd in ("Z", "z"):
            cur.append((sx, sy))
            subpaths.append(cur)
            cur = []
            x, y = sx, sy
            last_cp = None
            cmd = None
        else:
            raise ValueError(f"Unsupported SVG path command: {cmd!r}")

    if cur:
        subpaths.append(cur)
    return subpaths


def rasterize_uroboros(
    svg_w: float,
    svg_h: float,
    subpaths: list[list[tuple[float, float]]],
    rows: int,
    cols: int,
    pad_top: int,
    pad_bot: int,
    pad_left: int,
    pad_right: int,
    supersample: int = 16,
    threshold: float = 0.45,
) -> list[str]:
    """Supersampled nonzero-winding scanline rasterization into '#' / ' ' grid."""
    dr_rows = rows - pad_top - pad_bot
    dr_cols = cols - pad_left - pad_right
    if dr_rows <= 0 or dr_cols <= 0:
        raise ValueError("Padding exceeds canvas dimensions")

    edges = []
    for poly in subpaths:
        for j in range(len(poly) - 1):
            x0, y0 = poly[j]
            x1, y1 = poly[j + 1]
            if y0 == y1:
                continue
            if y0 < y1:
                edges.append((y0, y1, x0, (x1 - x0) / (y1 - y0), +1))
            else:
                edges.append((y1, y0, x1, (x0 - x1) / (y0 - y1), -1))

    grid = [["#"] * cols for _ in range(rows)]
    ss = supersample
    ss2 = ss * ss
    cutoff = threshold * ss2
    x_scale = (dr_cols * ss) / svg_w

    for r in range(dr_rows):
        counts = [0] * dr_cols
        for sy_i in range(ss):
            y = ((r + (sy_i + 0.5) / ss) / dr_rows) * svg_h
            xs = [
                (x0 + (y - y0) * dxdy, w)
                for y0, y1, x0, dxdy, w in edges
                if y0 <= y < y1
            ]
            xs.sort(key=lambda pair: pair[0])
            winding = 0
            start = None
            for x_pos, w in xs:
                prev_in = winding != 0
                winding += w
                now_in = winding != 0
                if not prev_in and now_in:
                    start = x_pos
                elif prev_in and not now_in and start is not None:
                    ca = max(0, int(start * x_scale))
                    cb = min(dr_cols * ss, int(x_pos * x_scale + 0.5))
                    for sx_i in range(ca, cb):
                        counts[sx_i // ss] += 1
                    start = None
        row_out = grid[pad_top + r]
        for c in range(dr_cols):
            if counts[c] >= cutoff:
                row_out[pad_left + c] = " "

    return ["".join(row) for row in grid]


def main() -> int:
    here = Path(__file__).resolve().parent
    default_svg = here / "uroboros.svg"
    if not default_svg.exists() and (here.parent / "src" / "uroboros.svg").exists():
        default_svg = here.parent / "src" / "uroboros.svg"

    default_out = here / "uroboros.txt"
    if (here.parent / "src" / "uroboros.svg").exists():
        default_out = here.parent / "src" / "uroboros.txt"

    parser = argparse.ArgumentParser(
        description="Rasterize uroboros.svg into a scaled uroboros.txt template."
    )
    parser.add_argument("--svg", type=Path, default=default_svg, help="Input uroboros.svg path")
    parser.add_argument(
        "-o",
        "--output",
        type=Path,
        default=default_out,
        help="Output uroboros.txt path",
    )
    parser.add_argument("--rows", type=int, default=113, help="Total rows (default: 113)")
    parser.add_argument("--cols", type=int, default=397, help="Total columns (default: 397)")
    parser.add_argument("--pad-y", type=int, default=10, help="Top/bottom '#' border rows (default: 10)")
    parser.add_argument("--pad-x", type=int, default=26, help="Left/right '#' border cols (default: 26)")
    parser.add_argument(
        "--threshold",
        type=float,
        default=0.45,
        help="Subpixel fill fraction cutoff for dragon space (default: 0.45)",
    )
    parser.add_argument(
        "--supersample",
        type=int,
        default=16,
        help="Supersampling factor per axis (default: 16 -> 256 samples/cell)",
    )
    parser.add_argument("-q", "--quiet", action="store_true", help="Suppress stderr stats")
    args = parser.parse_args()

    svg_text = args.svg.read_text(encoding="utf-8")
    svg_w, svg_h, subpaths = parse_svg_geometry(svg_text)
    lines = rasterize_uroboros(
        svg_w,
        svg_h,
        subpaths,
        rows=args.rows,
        cols=args.cols,
        pad_top=args.pad_y,
        pad_bot=args.pad_y,
        pad_left=args.pad_x,
        pad_right=args.pad_x,
        supersample=args.supersample,
        threshold=args.threshold,
    )

    assert len(lines) == args.rows
    assert all(len(line) == args.cols for line in lines)
    assert lines[0] == "#" * args.cols and lines[-1] == "#" * args.cols

    args.output.write_bytes(("\n".join(lines) + "\n").encode("ascii"))

    if not args.quiet:
        total = args.rows * args.cols
        spaces = sum(line.count(" ") for line in lines)
        hashes = total - spaces
        cap0 = hashes - args.cols
        dr_rows = args.rows - 2 * args.pad_y
        dr_cols = args.cols - 2 * args.pad_x
        print(
            f"wrote {args.output}: {args.rows}x{args.cols} "
            f"({args.cols * 4}x{args.rows * 8} px, AR={args.cols / (2 * args.rows):.3f}), "
            f"dragon={spaces:,} ({100.0 * spaces / total:.2f}%, bbox={dr_rows}x{dr_cols}, "
            f"drAR={dr_cols / (2 * dr_rows):.3f} vs SVG {svg_w / svg_h:.3f}), "
            f"0-overflow cap={cap0:,} B",
            file=sys.stderr,
        )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
