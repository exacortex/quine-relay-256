#!/usr/bin/env python3
"""
ExaCortex Quine Relay 256 — Live ANSI Terminal Visualizer.

Default container entrypoint:
- When attached to an interactive TTY (e.g. `docker run -it ...`), renders a live
  ExaCortex telemetry dashboard around the real `make check -j 10000` run:
  orbiting ExaCortex ring-and-dot mark, spinning 256-step A-Z dial, log-scale
  payload sparkline, milestone badges, live generated-code peek, and victory card.
- When non-interactive (piped logs, CI=true, NO_COLOR, or `--plain`), immediately
  hands control over to unmodified `make check -j 10000` via `os.execvp`.
- Pass `--demo` for a quick self-contained ~10s preview of all 256 steps.
"""

from __future__ import annotations

import hashlib
import math
import os
import re
import shutil
import signal
import subprocess
import sys
import threading
import time
from collections import deque

REPO_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
BANNER_STEP_RE = re.compile(r"^##\s+(\d+):\s+(.+?)\s+->\s+(.+?)\s+##$")
BANNER_CHECK_RE = re.compile(r"^##\s+CHECK\s+##$")
RULE_RE = re.compile(r"^([^\s:#]+):\s+([^\s:#]+)\s*$")
LANG_ROW_RE = re.compile(r"^\|\s*(\d+)\s*\|\s*(.+?)\s*\|\s*(.+?)\s*\|")

SPINNER = "⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"
SPARK_CHARS = " ▁▂▃▄▅▆▇█"
DIAL_SLOTS = list("ABCDEFGHIJKLMNOPQRSTUVWXYZ6")

# Truecolor ExaCortex palette (Bone, Brass, Rust, Emerald, Slate, Dim)
C_RESET = "\x1b[0m"
C_BOLD = "\x1b[1m"
C_BONE = "\x1b[38;2;243;239;231m"
C_BRASS = "\x1b[38;2;196;154;69m"
C_RUST = "\x1b[38;2;224;98;54m"
C_GREEN = "\x1b[38;2;74;222;128m"
C_CYAN = "\x1b[38;2;125;211;252m"
C_MUTED = "\x1b[38;2;140;134;125m"
C_DIM = "\x1b[38;2;86;82;76m"
C_RED = "\x1b[38;2;248;113;113m"

MILESTONES = [
    ("JSFuck", "JSFuck", "20M []()!+"),
    ("Malbolge Unshackled", "Malbolge", "Unshackled"),
    ("Piet", "Piet", "199M PPM"),
    ("Shakespeare", "Shakespeare", "35M Play"),
    ("Uxntal", "Uxntal", "<64K ROM"),
    ("Z80 asm", "Z80", "<64K COM"),
    ("6502 asm", "6502", "<64K BIN"),
]

# Representative payload curve anchor sizes (step -> bytes) for --demo mode
DEMO_ANCHORS = [
    (1, 133_101), (2, 836_011), (10, 410_000), (25, 392_000),
    (59, 345_000), (70, 315_000), (85, 289_000), (103, 243_371),
    (105, 19_881_169), (110, 250_000), (125, 198_613), (127, 3_727_660),
    (140, 210_000), (166, 173_889), (167, 199_588_242), (185, 290_000),
    (200, 326_870), (201, 35_054_824), (215, 180_000), (222, 73_884),
    (231, 66_285), (240, 61_603), (244, 204_128), (247, 195_690),
    (253, 172_567), (255, 134_770), (256, 133_205),
]

DEMO_SNIPPETS = {
    "AspectJ": [
        "import java.io.*;import java.util.*;import java.util.regex.*;import java.util.zip.*;/*##*/",
        '  "MnQKRd95DF(]2;|^74DY.ZXp0c@8}   03hh4l]!As9c   <?_QNKYvwS4W_%O<RkeMFL;"',
        "aspect Q{static String[]B={...};before():execution(void QR.main(..)){init();}}",
    ],
    "Chapel": [
        "use IO;proc main(){var s=\"\"\"...",
        "write(s);}",
    ],
    "JSFuck": [
        "[][(![]+[])[+[]]+(![]+[])[!+[]+!+[]]+(![]+[])[+!+[]]+(!![]+[])[+[]]][([][(![]+[])...",
        "+(+!+[]+[+!+[]]+(!![]+[])[!+[]+!+[]+!+[]]+[!+[]+!+[]]+[+[]])+[])[+!+[]]+...",
        "(19,881,169 bytes strictly using []()!+)",
    ],
    "Malbolge Unshackled": [
        "(=<`#9]~6ZY327Uv4-QsqpMn&+Ij\"'E%e{Ab~w=_:]Kw%o44Uqp0/Q?xNvL:`H%c#DD2^WV>gY;Nj3?",
        "(&%$#\"!~}|{zyxwvutsrqponmlkjihgfedcba`_^]\\[ZYXWVUTSRQPONMLKJIHGFEDCBA@?>=<;:987",
        "(3,727,660 bytes — zero '/' ops, dual-interpreter CC0 verified)",
    ],
    "Piet": [
        "P6  512 129940 255  [199,588,242 bytes raw RGB PPM codel grid]",
        "000000 ffffff 00c0ff c000ff ff0000 00ff00 c0c000 ... [npiet codels]",
    ],
    "Shakespeare": [
        "The Relay of Quine.",
        "Ajax, a young man.   Ford, a trustworthy old man.",
        "[Enter Ajax and Ford]  Ajax: Thou art as bad as the sum of a cat and a...",
    ],
    "Uxntal": [
        "|0100 ;pre ;p JSR2 ;z @l DUP2 ;ze EQU2 ;d JCN2 LDAk #00 STZ INC2...",
        "@t 41 42 43 44 45 46 47 48 ...   (ROM 55,661 B / 65,280 B)",
    ],
    "Z80 asm": [
        " org 0100h / ld hl,msg / loop: ld a,(hl) / or a / jr z,done / call 5",
        ' db "const s=@import(\\"std\\");pub fn main()!void{..." (COM 61,603 B / 64,991 B)',
    ],
    "6502 asm": [
        ' .byt "sim65",2,0,2,$00,$02,$00,$02  * = $0200  ldx #$ff  txs  jsr emit',
        ' .byt ".global _start",".text",10,"_start:",10,...  (BIN 57,006 B / 65,012 B)',
    ],
    "ArnoldC": [
        "IT'S SHOWTIME",
        "DO IT NOW m0",
        'TALK TO THE HAND "s: {:import stdlib..."  YOU HAVE BEEN TERMINATED',
    ],
    "AspectC++": [
        "#include<cstdio>",
        'aspect Q{advice execution("int main()"):before(){fputs(R"Q(import java.io.*;...',
        ')Q",stdout);} };int main(){}',
    ],
}


def enable_windows_vt() -> None:
    if os.name != "nt":
        return
    try:
        import ctypes
        k32 = ctypes.windll.kernel32
        h = k32.GetStdHandle(-11)
        mode = ctypes.c_uint32()
        if k32.GetConsoleMode(h, ctypes.byref(mode)):
            k32.SetConsoleMode(h, mode.value | 0x0004)
    except Exception:
        pass


def fmt_bytes(n: int | None) -> str:
    if n is None or n < 0:
        return "—"
    if n < 1024:
        return f"{n} B"
    if n < 1024 * 1024:
        return f"{n / 1024:.1f} KiB"
    return f"{n / (1024 * 1024):.2f} MiB"


def fmt_dur(sec: float) -> str:
    if sec < 60:
        return f"{sec:5.1f}s"
    m, s = divmod(int(sec), 60)
    h, m = divmod(m, 60)
    if h:
        return f"{h:d}:{m:02d}:{s:02d}"
    return f"{m:02d}:{s:02d}"


def slot_for_lang(name: str) -> int:
    for ch in name:
        if ch.isalpha():
            return ord(ch.upper()) - ord("A")
        if ch.isdigit():
            return 26
    return 0


def load_metadata(root: str):
    """Parse Makefile target->dep pairs and LANGUAGES.md origins."""
    targets = []  # list of (out_src, in_src)
    mk_path = os.path.join(root, "Makefile")
    if os.path.exists(mk_path):
        with open(mk_path, "r", encoding="utf-8", errors="replace") as fh:
            for line in fh:
                m = RULE_RE.match(line.rstrip("\n"))
                if m:
                    out_s, in_s = m.group(1), m.group(2)
                    if out_s not in ("all", "check", "clean", "watch"):
                        targets.append((out_s, in_s))

    steps = []
    lang_path = os.path.join(root, "LANGUAGES.md")
    if os.path.exists(lang_path):
        with open(lang_path, "r", encoding="utf-8", errors="replace") as fh:
            for line in fh:
                m = LANG_ROW_RE.match(line.strip())
                if m:
                    idx = int(m.group(1))
                    name = m.group(2).strip()
                    orig = m.group(3).strip()
                    in_s = targets[idx - 1][1] if idx - 1 < len(targets) else "QR.aj"
                    out_s = targets[idx - 1][0] if idx - 1 < len(targets) else "QR2.aj"
                    steps.append({
                        "step": idx,
                        "name": name,
                        "origin": "upstream" if "mame" in orig else "fork",
                        "in_src": in_s,
                        "out_src": out_s,
                    })
    return steps


def read_code_peek(path: str, max_lines: int = 3, max_cols: int = 84) -> list[str]:
    if not path or not os.path.exists(path):
        return []
    try:
        with open(path, "rb") as fh:
            raw = fh.read(512)
    except OSError:
        return []
    if not raw:
        return ["<empty>"]
    # Binary magic detection
    non_print = sum(1 for b in raw[:128] if b not in (9, 10, 13) and not (32 <= b <= 126))
    if non_print > len(raw[:128]) * 0.25 or raw.startswith((b"\x00asm", b"MThd", b"\x1f\x8b", b"\x89PNG")):
        hex_s = " ".join(f"{b:02x}" for b in raw[:24])
        asc_s = "".join(chr(b) if 32 <= b <= 126 else "." for b in raw[:24])
        return [f"[binary {os.path.basename(path)}] {hex_s}", f"ascii: {asc_s}"][:max_lines]
    txt = raw.decode("utf-8", errors="replace").replace("\r\n", "\n").replace("\r", "\n")
    out = []
    for ln in txt.split("\n"):
        clean = "".join(ch if ch >= " " and ch != "\x7f" else " " for ch in ln).rstrip()
        if clean:
            out.append(clean[: max(20, max_cols - 3)] + ("..." if len(clean) > max(20, max_cols - 3) else ""))
        if len(out) >= max_lines:
            break
    return out or ["<whitespace>"]


def mark_grid(tick: int) -> list[str]:
    """5x11 animated ExaCortex ring-and-dot mark."""
    ring = [
        (0, 3), (0, 4), (0, 5), (0, 6), (0, 7),
        (1, 9), (2, 10), (3, 9),
        (4, 7), (4, 6), (4, 5), (4, 4), (4, 3),
        (3, 1), (2, 0), (1, 1),
    ]
    pulse = ring[tick % len(ring)]
    trail = ring[(tick - 1) % len(ring)]
    grid = [[" " for _ in range(11)] for _ in range(5)]
    chars = {
        (0, 3): "╭", (0, 4): "─", (0, 5): "─", (0, 6): "─", (0, 7): "╮",
        (1, 1): "╱", (1, 9): "╲",
        (2, 0): "│", (2, 5): "●", (2, 10): "│",
        (3, 1): "╲", (3, 9): "╱",
        (4, 3): "╰", (4, 4): "─", (4, 5): "─", (4, 6): "─", (4, 7): "╯",
    }
    lines = []
    for r in range(5):
        row_s = []
        for c in range(11):
            ch = chars.get((r, c), " ")
            if (r, c) == (2, 5):
                row_s.append(f"{C_BOLD}{C_BONE}{ch}{C_RESET}")
            elif (r, c) == pulse:
                row_s.append(f"{C_BOLD}{C_RUST}◉{C_RESET}")
            elif (r, c) == trail:
                row_s.append(f"{C_BRASS}◌{C_RESET}")
            elif ch != " ":
                row_s.append(f"{C_BRASS}{ch}{C_RESET}")
            else:
                row_s.append(" ")
        lines.append("".join(row_s))
    return lines


def demo_size_for_step(step: int) -> int:
    for i in range(len(DEMO_ANCHORS) - 1):
        s0, b0 = DEMO_ANCHORS[i]
        s1, b1 = DEMO_ANCHORS[i + 1]
        if s0 <= step <= s1:
            if s1 == s0:
                return b0
            t = (step - s0) / (s1 - s0)
            return int(round(10 ** (math.log10(b0) + t * (math.log10(b1) - math.log10(b0)))))
    return 133_101


class RelayState:
    def __init__(self, root: str, steps_meta: list[dict]):
        self.lock = threading.Lock()
        self.root = root
        self.steps_meta = steps_meta
        self.total_steps = len(steps_meta) or 256
        self.start_ts = time.monotonic()
        self.step_start_ts = self.start_ts
        self.cur_step = 0
        self.cur_from = "AspectJ"
        self.cur_to = "Asymptote"
        self.cur_cmd = ""
        self.phase = "INIT"  # INIT | STEP | CHECK | DONE | FAIL
        self.completed: deque[tuple[int, str, str, int | None, float]] = deque(maxlen=5)
        self.sizes: list[tuple[int, int]] = []  # (step, bytes)
        self.peak_bytes = 0
        self.peak_label = "QR.aj"
        self.cur_bytes = 0
        self.cur_src = "QR.aj"
        self.peek_lines: list[str] = []
        self.passed_milestones: dict[str, int] = {}
        self.raw_tail: deque[str] = deque(maxlen=40)
        self.diff_ok = False
        self.sums_ok = False
        self.rc: int | None = None

    def on_step(self, num: int, frm: str, to: str, demo_bytes: int | None = None, demo_peek: list[str] | None = None) -> None:
        now = time.monotonic()
        with self.lock:
            if self.cur_step > 0:
                dt = max(0.05, now - self.step_start_ts)
                # Measure the file produced by cur_step (which is input to step `num`)
                meta_cur = self.steps_meta[self.cur_step - 1] if self.cur_step - 1 < len(self.steps_meta) else None
                out_f = meta_cur["out_src"] if meta_cur else None
                out_sz = demo_bytes
                if out_sz is None and out_f:
                    p = os.path.join(self.root, out_f)
                    if os.path.exists(p):
                        try:
                            out_sz = os.path.getsize(p)
                        except OSError:
                            out_sz = None
                self.completed.append((self.cur_step, self.cur_from, self.cur_to, out_sz, dt))
                if self.cur_from in dict((m[0], m[1]) for m in MILESTONES):
                    self.passed_milestones[self.cur_from] = out_sz or 0

            self.phase = "STEP"
            self.cur_step = num
            self.cur_from = frm
            self.cur_to = to
            self.step_start_ts = now

            meta = self.steps_meta[num - 1] if 0 <= num - 1 < len(self.steps_meta) else None
            in_src = meta["in_src"] if meta else "QR.aj"
            self.cur_src = in_src
            sz = demo_bytes
            if sz is None:
                p = os.path.join(self.root, in_src)
                if os.path.exists(p):
                    try:
                        sz = os.path.getsize(p)
                    except OSError:
                        sz = None
                self.peek_lines = read_code_peek(p, max_lines=3, max_cols=86)
            else:
                self.peek_lines = demo_peek or []
            if sz and sz > 0:
                self.cur_bytes = sz
                self.sizes.append((num, sz))
                if sz > self.peak_bytes:
                    self.peak_bytes = sz
                    self.peak_label = f"#{num} {frm} ({in_src})"
            if frm in dict((m[0], m[1]) for m in MILESTONES):
                self.passed_milestones[frm] = sz or self.cur_bytes

    def on_check(self) -> None:
        now = time.monotonic()
        with self.lock:
            if self.cur_step > 0 and self.phase == "STEP":
                dt = max(0.05, now - self.step_start_ts)
                p = os.path.join(self.root, "QR2.aj")
                sz = os.path.getsize(p) if os.path.exists(p) else self.cur_bytes
                self.completed.append((self.cur_step, self.cur_from, self.cur_to, sz, dt))
                self.cur_bytes = sz
                self.sizes.append((self.total_steps + 1, sz))
            self.phase = "CHECK"
            self.step_start_ts = now
            self.cur_cmd = "diff -s QR.aj QR2.aj && sha256sum --quiet -c SHA256SUMS"

    def render(self, tick: int, cols: int, rows: int) -> str:
        with self.lock:
            now = time.monotonic()
            total_dt = now - self.start_ts
            step_dt = now - self.step_start_ts
            cur = self.cur_step
            tot = self.total_steps
            frm = self.cur_from
            to = self.cur_to
            phase = self.phase
            cmd = self.cur_cmd
            sizes = list(self.sizes)
            peak_b = self.peak_bytes
            peak_lbl = self.peak_label
            cur_b = self.cur_bytes
            cur_src = self.cur_src
            peek = list(self.peek_lines)
            completed = list(self.completed)
            milestones_hit = dict(self.passed_milestones)

        w = max(72, min(116, cols - 1))
        meta = self.steps_meta[cur - 1] if 0 <= cur - 1 < len(self.steps_meta) else None
        origin = meta["origin"] if meta else ""
        origin_tag = (
            f"{C_DIM}[mame-128]{C_RESET}" if origin == "upstream"
            else (f"{C_RUST}[fork-128]{C_RESET}" if origin == "fork" else "")
        )

        logo = mark_grid(tick)
        spin = SPINNER[tick % len(SPINNER)]
        active_slot = slot_for_lang(frm) if cur > 0 else 0

        # Build spinning A-Z dial
        dial_parts = []
        for idx, ch in enumerate(DIAL_SLOTS):
            if phase == "CHECK" or cur >= tot:
                dial_parts.append(f"{C_GREEN}{ch}{C_RESET}")
            elif idx < active_slot:
                dial_parts.append(f"{C_BRASS}{ch}{C_RESET}")
            elif idx == active_slot:
                dial_parts.append(f"{C_BOLD}{C_RUST}[{ch}]{C_RESET}")
            else:
                dial_parts.append(f"{C_DIM}{ch}{C_RESET}")
        dial_str = " ".join(dial_parts)

        # Progress bar
        frac = 1.0 if phase == "CHECK" else (cur / max(1, tot))
        bar_w = max(20, w - 26)
        filled = int(frac * bar_w)
        bar = f"{C_RUST}{'█' * filled}{C_DIM}{'░' * (bar_w - filled)}{C_RESET}"

        # Log-scale sparkline (4.7..8.3 -> 50 KB .. 200 MB)
        spark_w = max(20, w - 34)
        vals = [math.log10(max(10_000, b)) for _, b in sizes]
        if len(vals) > spark_w:
            vals = [vals[int(i * len(vals) / spark_w)] for i in range(spark_w)]
        spark_chars = []
        for lv in vals:
            norm = max(0.0, min(1.0, (lv - 4.7) / 3.65))
            idx = max(1, min(8, 1 + int(norm * 7.99)))
            col = C_RUST if lv > 7.0 else (C_BRASS if lv > 5.7 else C_GREEN)
            spark_chars.append(f"{col}{SPARK_CHARS[idx]}{C_RESET}")
        spark_pad = f"{C_DIM}{'·' * max(0, spark_w - len(vals))}{C_RESET}"
        spark_str = "".join(spark_chars) + spark_pad

        # Milestone strip
        badge_str = []
        for m_key, m_lbl, _ in MILESTONES:
            if m_key in milestones_hit:
                badge_str.append(f"{C_GREEN}● {m_lbl}{C_RESET}")
            elif cur > 0 and m_key == frm:
                badge_str.append(f"{C_BOLD}{C_RUST}◉ {m_lbl}{C_RESET}")
            else:
                badge_str.append(f"{C_DIM}○ {m_lbl}{C_RESET}")

        hr = f"{C_DIM}{'─' * w}{C_RESET}"
        out = ["\x1b[H"]
        out.append(f"{logo[0]}  {C_BOLD}{C_BONE}EXACORTEX // QUINE RELAY 256{C_RESET}  {C_MUTED}Strict A–Z Edition{C_RESET}")
        out.append(f"{logo[1]}  {C_MUTED}128 upstream + 128 fork · offline Ubuntu 26.04 · QR.aj -> QR2.aj{C_RESET}")
        out.append(f"{logo[2]}  {dial_str}")
        if phase == "CHECK":
            step_lbl = f"{C_GREEN}{spin} CHECK{C_RESET}  diff QR.aj QR2.aj & SHA256SUMS"
        else:
            step_lbl = f"{C_RUST}{spin}{C_RESET} {C_BOLD}{C_BONE}[{cur:3d}/{tot}]{C_RESET}  {C_BONE}{frm}{C_RESET} {C_MUTED}->{C_RESET} {C_BRASS}{to}{C_RESET}  {origin_tag}"
        out.append(f"{logo[3]}  {step_lbl}")
        out.append(f"{logo[4]}  {C_MUTED}Elapsed:{C_RESET} {C_BONE}{fmt_dur(total_dt)}{C_RESET}   {C_MUTED}Step:{C_RESET} {C_BRASS}{fmt_dur(step_dt)}{C_RESET}   {C_MUTED}File:{C_RESET} {C_CYAN}{cur_src}{C_RESET} ({fmt_bytes(cur_b)})")
        out.append(hr)
        out.append(f"  {bar}  {C_BOLD}{C_BONE}{frac * 100:5.1f}%{C_RESET}  {C_MUTED}Peak:{C_RESET} {C_BRASS}{fmt_bytes(peak_b)}{C_RESET}")
        out.append(f"  {C_MUTED}Payload (log):{C_RESET} {spark_str}  {C_MUTED}({fmt_bytes(cur_b)}){C_RESET}")
        out.append(f"  {'  '.join(badge_str)}")
        out.append(hr)
        out.append(f"  {C_MUTED}LIVE SOURCE PEEK{C_RESET}  {C_CYAN}{cur_src}{C_RESET}")
        for i in range(3):
            ln = peek[i] if i < len(peek) else ""
            out.append(f"    {C_BONE}{ln[:w - 6]}{C_RESET}")
        out.append(hr)
        cmd_disp = cmd[: w - 8] if cmd else "waiting..."
        out.append(f"  {C_BRASS}${C_RESET} {C_BONE}{cmd_disp}{C_RESET}")
        for c_num, c_frm, c_to, c_sz, c_dt in reversed(completed):
            out.append(
                f"  {C_GREEN}✓{C_RESET} {C_DIM}#{c_num:03d}{C_RESET} "
                f"{C_MUTED}{c_frm} -> {c_to:<28s}{C_RESET} "
                f"{C_BONE}{fmt_bytes(c_sz):>10s}{C_RESET}  {C_DIM}{c_dt:5.1f}s{C_RESET}"
            )
        # Clear each line to EOL and clear below
        return "\n".join(line + "\x1b[K" for line in out) + "\x1b[J"


ANSI_RE = re.compile(r"\x1b\[[0-9;]*m")


def box_line(inner: str, width: int = 70) -> str:
    vis = len(ANSI_RE.sub("", inner))
    pad = max(0, width - 2 - vis)
    return f"{C_BRASS}│{C_RESET}  {inner}{' ' * pad}{C_BRASS}│{C_RESET}"


def print_victory_card(state: RelayState) -> None:
    dt = time.monotonic() - state.start_ts
    aj_path = os.path.join(state.root, "QR.aj")
    aj_sz = os.path.getsize(aj_path) if os.path.exists(aj_path) else 133_101
    sha8 = ""
    if os.path.exists(aj_path):
        h = hashlib.sha256()
        with open(aj_path, "rb") as fh:
            for chunk in iter(lambda: fh.read(65536), b""):
                h.update(chunk)
        sha8 = h.hexdigest()[:16]

    print()
    print(f"{C_BRASS}╭{'─' * 70}╮{C_RESET}")
    print(box_line(f"{C_BOLD}{C_GREEN}● QUINE RELAY 256 — VERIFIED ROUND-TRIP COMPLETE{C_RESET}"))
    print(f"{C_BRASS}├{'─' * 70}┤{C_RESET}")
    print(box_line(f"{C_BONE}Steps:{C_RESET}   256 / 256 Strict A–Z (128 upstream + 128 fork)"))
    print(box_line(f"{C_BONE}Match:{C_RESET}   diff -s QR.aj QR2.aj -> identical ({aj_sz:,} B)"))
    print(box_line(f"{C_BONE}Hashes:{C_RESET}  sha256sum --quiet -c SHA256SUMS -> 256 / 256 OK"))
    print(box_line(f"{C_BONE}Peak:{C_RESET}    {fmt_bytes(state.peak_bytes)} ({state.peak_label})"))
    print(box_line(f"{C_BONE}Elapsed:{C_RESET} {fmt_dur(dt).strip()}  ·  QR.aj sha256: {sha8}..."))
    print(f"{C_BRASS}╰{'─' * 70}╯{C_RESET}")
    print()


def run_demo(state: RelayState, fast: bool = False) -> int:
    steps = state.steps_meta or [{"step": i + 1, "name": f"Lang{i+1}", "origin": "fork", "in_src": "QR.aj", "out_src": "QR.aj"} for i in range(256)]
    key_indices = [0, 23, 58, 104, 126, 166, 200, 221, 239, 243, 253, 255]
    highlights = set(key_indices)
    dt_norm = 0.015 if fast else 0.032
    dt_key = 0.25 if fast else 0.70

    enable_windows_vt()
    sys.stdout.write("\x1b[?1049h\x1b[?25l")
    sys.stdout.flush()
    tick = 0
    try:
        for i, m in enumerate(steps):
            nxt_name = steps[(i + 1) % len(steps)]["name"]
            b = demo_size_for_step(m["step"])
            peek = DEMO_SNIPPETS.get(m["name"], [
                f"/* {m['in_src']} — Step #{m['step']} ({m['name']}) -> {nxt_name} */",
                f"payload_bytes = {b:,} B",
            ])
            state.on_step(m["step"], m["name"], nxt_name, demo_bytes=b, demo_peek=peek)
            state.cur_cmd = f"run {m['name']} -> {m['out_src']}"
            dwell = dt_key if i in highlights else dt_norm
            end_t = time.monotonic() + dwell
            while time.monotonic() < end_t:
                cols, rows = shutil.get_terminal_size((100, 28))
                sys.stdout.write(state.render(tick, cols, rows))
                sys.stdout.flush()
                tick += 1
                time.sleep(0.08 if i in highlights else dt_norm)
        state.on_check()
        for _ in range(4 if fast else 10):
            cols, rows = shutil.get_terminal_size((100, 28))
            sys.stdout.write(state.render(tick, cols, rows))
            sys.stdout.flush()
            tick += 1
            time.sleep(0.08)
    finally:
        sys.stdout.write("\x1b[?25h\x1b[?1049l")
        sys.stdout.flush()
    state.peak_bytes = max(state.peak_bytes, 199_588_242)
    state.peak_label = "#167 Piet (QR.ppm)"
    print_victory_card(state)
    return 0


def run_live(state: RelayState) -> int:
    enable_windows_vt()
    proc = subprocess.Popen(
        ["make", "check", "-j", "10000"],
        cwd=state.root,
        stdin=subprocess.DEVNULL,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        encoding="utf-8",
        errors="replace",
        bufsize=1,
    )

    def reader() -> None:
        assert proc.stdout is not None
        for raw_ln in proc.stdout:
            ln = raw_ln.rstrip("\r\n")
            with state.lock:
                if ln:
                    state.raw_tail.append(ln)
            m = BANNER_STEP_RE.match(ln)
            if m:
                state.on_step(int(m.group(1)), m.group(2), m.group(3))
            elif BANNER_CHECK_RE.match(ln):
                state.on_check()
            elif ln.startswith("Files QR.aj and QR2.aj are identical"):
                with state.lock:
                    state.diff_ok = True
            elif ln and not ln.startswith("#"):
                with state.lock:
                    state.cur_cmd = ln.strip()

    t = threading.Thread(target=reader, daemon=True)
    t.start()

    def handle_sig(signum, _frame):
        try:
            proc.terminate()
        except Exception:
            pass
        sys.stdout.write("\x1b[?25h\x1b[?1049l")
        sys.stdout.flush()
        sys.exit(128 + signum)

    signal.signal(signal.SIGINT, handle_sig)
    signal.signal(signal.SIGTERM, handle_sig)

    sys.stdout.write("\x1b[?1049h\x1b[?25l")
    sys.stdout.flush()
    tick = 0
    try:
        while proc.poll() is None:
            cols, rows = shutil.get_terminal_size((100, 28))
            sys.stdout.write(state.render(tick, cols, rows))
            sys.stdout.flush()
            tick += 1
            time.sleep(0.10)
        t.join(timeout=2.0)
    finally:
        sys.stdout.write("\x1b[?25h\x1b[?1049l")
        sys.stdout.flush()

    rc = proc.returncode or 0
    if rc == 0:
        print_victory_card(state)
    else:
        print(f"\n{C_RED}{C_BOLD}Quine Relay 256 failed (exit={rc}). Last output lines:{C_RESET}\n")
        for ln in state.raw_tail:
            print(f"  {ln}")
    return rc


def main() -> int:
    args = sys.argv[1:]
    demo = "--demo" in args
    fast = "--fast" in args
    plain = "--plain" in args

    if not demo:
        if plain or not sys.stdout.isatty() or os.environ.get("CI") == "true" or os.environ.get("NO_COLOR"):
            if sys.stdin and sys.stdin.isatty():
                devnull = os.open(os.devnull, os.O_RDONLY)
                os.dup2(devnull, 0)
                os.close(devnull)
            os.chdir(REPO_ROOT)
            os.execvp("make", ["make", "check", "-j", "10000"])

    steps_meta = load_metadata(REPO_ROOT)
    state = RelayState(REPO_ROOT, steps_meta)
    if demo:
        return run_demo(state, fast=fast)
    return run_live(state)


if __name__ == "__main__":
    sys.exit(main())
