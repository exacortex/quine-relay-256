#!/usr/bin/env python3
"""
Render assets/payload-curve.png from measured 256-step byte sizes.
Usage: python3 tools/render_payload_chart.py [sizes.json] [out/payload-curve.png]
"""

import json
import os
import sys
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import matplotlib.ticker as ticker
import numpy as np

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
DEFAULT_JSON = r"D:\DrawnWithCode\_tmp\qr256_sizes.json"


def fmt_size_tick(val, _pos=None):
    if val >= 1_000_000:
        mb = val / (1024 * 1024)
        return f"{mb:.0f} MiB" if mb >= 10 else f"{mb:.1f} MiB"
    if val >= 1024:
        return f"{val / 1024:.0f} KiB"
    return f"{int(val)} B"


def main() -> int:
    json_path = sys.argv[1] if len(sys.argv) > 1 else DEFAULT_JSON
    out_path = sys.argv[2] if len(sys.argv) > 2 else os.path.join(ROOT, "assets", "payload-curve.png")
    os.makedirs(os.path.dirname(out_path), exist_ok=True)

    with open(json_path, "r", encoding="utf-8") as fh:
        data = json.load(fh)

    runs = data["run_steps"]
    xs = np.array([r["step"] for r in runs] + [257])
    ys = np.array([r["bytes"] for r in runs] + [data["aj_bytes"]], dtype=float)

    plt.rcParams["font.sans-serif"] = ["Segoe UI", "DejaVu Sans", "Arial"]
    plt.rcParams["axes.unicode_minus"] = False

    fig, ax = plt.subplots(figsize=(12.5, 6.2), dpi=180)
    bg = "#FAF8F4"
    ink = "#1B1916"
    rust = "#9E3B1E"
    brass = "#A9843F"
    muted = "#686259"
    grid_col = "#E3DDD2"

    fig.patch.set_facecolor(bg)
    ax.set_facecolor(bg)

    # Shaded <64 KiB 16-bit vintage ROM ceiling zone
    ax.axhspan(30_000, 65_536, color="#E8DFCD", alpha=0.55, zorder=1)
    ax.axhline(65_536, color=brass, linestyle="--", linewidth=1.2, alpha=0.9, zorder=2)
    ax.text(8, 52_000, "64 KiB vintage 8/16-bit ROM ceiling", color="#7A5D28", fontsize=9, fontweight="bold", va="center")

    # Log-scale filled area + line
    ax.fill_between(xs, 30_000, ys, color=rust, alpha=0.10, zorder=2)
    ax.plot(xs, ys, color=ink, linewidth=1.6, zorder=3)

    # Highlight key milestones
    callouts = [
        (1,   data["aj_bytes"],         "#1 QR.aj (130 KiB)",              (14, 20),   "left",   rust),
        (16,  30_778_716,               "#16 Brainflak\n29.4 MiB",         (14, 12),   "left",   rust),
        (105, 19_881_169,               "#105 JSFuck\n19.0 MiB",           (-12, 22),  "center", ink),
        (127, 3_727_660,                "#127 Malbolge\nUnshackled 3.6 MiB", (-4, 30), "center", rust),
        (167, 199_588_242,              "#167 Piet (PPM peak)\n190.3 MiB", (-16, -4),  "right",  ink),
        (201, 35_054_824,               "#201 Shakespeare\n33.4 MiB play", (10, 16),   "left",   ink),
        (222, runs[221]["bytes"],       "#222 Uxntal",                     (-12, -34), "right",  rust),
        (240, runs[239]["bytes"],       "#240 Z80 <64K",                   (-2, -28),  "center", rust),
        (244, runs[243]["bytes"],       "#244 6502",                       (2, 92),    "center", rust),
        (257, data["aj_bytes"],         "#256 QR2.aj\n(130 KiB)",          (12, 2),    "left",   rust),
    ]

    for sx, sy, lbl, (dx, dy), ha, col in callouts:
        ax.scatter([sx], [sy], color=col, s=38, zorder=5, edgecolors=bg, linewidths=1.0)
        ax.annotate(
            lbl,
            xy=(sx, sy),
            xytext=(dx, dy),
            textcoords="offset points",
            ha=ha,
            va="center",
            fontsize=8.5,
            fontweight="bold",
            color=col,
            bbox=dict(boxstyle="round,pad=0.18", facecolor=bg, edgecolor="none", alpha=0.88),
            arrowprops=dict(arrowstyle="-", color=muted, lw=0.8, shrinkA=2, shrinkB=4),
            zorder=6,
        )

    ax.set_yscale("log")
    ax.set_xlim(0, 282)
    ax.set_ylim(30_000, 380_000_000)
    ax.set_xticks([1, 32, 64, 96, 128, 160, 192, 224, 256])
    ax.set_xticklabels(["#1\nAspJ", "#32\nCoff", "#64\nGamb", "#96\nJ", "#128\nMaca", "#160\nPerl5", "#192\nRock", "#224\nVala", "#256\nAspC++"], fontsize=9, color=muted)

    ax.yaxis.set_major_locator(ticker.FixedLocator([65_536, 262_144, 1_048_576, 8_388_608, 67_108_864, 268_435_456]))
    ax.yaxis.set_major_formatter(ticker.FuncFormatter(lambda v, p: {
        65536: "64 KiB",
        262144: "256 KiB",
        1048576: "1 MiB",
        8388608: "8 MiB",
        67108864: "64 MiB",
        268435456: "256 MiB",
    }.get(int(v), fmt_size_tick(v))))
    ax.tick_params(axis="y", colors=muted, labelsize=9)
    ax.grid(True, which="major", axis="y", color=grid_col, linewidth=0.8)
    ax.grid(True, which="major", axis="x", color=grid_col, linewidth=0.6, alpha=0.7)

    for sp in ("top", "right"):
        ax.spines[sp].set_visible(False)
    for sp in ("bottom", "left"):
        ax.spines[sp].set_color("#CFC7B8")

    ax.set_title(
        "Quine Relay 256 — Payload Breathing Curve (Log Scale, Strict A–Z)",
        loc="left",
        fontsize=14,
        fontweight="bold",
        color=ink,
        pad=22,
    )
    fig.text(
        0.072,
        0.905,
        "Intermediate source sizes from 130 KiB QR.aj -> 190.3 MiB Piet PPM & 33.4 MiB Shakespeare -> <64 KiB vintage ROMs -> identical 130 KiB QR2.aj",
        fontsize=9.5,
        color=muted,
    )

    plt.tight_layout(rect=[0.01, 0.01, 0.99, 0.90])
    fig.savefig(out_path, dpi=180, facecolor=bg)
    plt.close(fig)
    print(f"Wrote {out_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
