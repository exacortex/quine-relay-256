#!/usr/bin/env python3
"""
malbolge-boot.dat.gen.py -- Reproducible generator for src/malbolge-boot.dat

Builds the 100% self-contained, rotwidth-independent Malbolge Unshackled
bootstrapper (1,571-byte prologue + 100-cell guardian ring) from first
principles, verifies it on an exact ternary-bigint simulator matching both
Matthias Lutter's Unshackled.c (dynamic rotwidth) and Unshackled-20.c
(fixed R=20), and packs it into src/malbolge-boot.dat (860 B ASCII:
base64(zlib(raw_1173B, level=9))).

Architecture overview
---------------------
Malbolge Unshackled extends Malbolge's 10-trit word width to unbounded
balanced-tail ternary integers (head in {0,1,2} repeated infinitely to the
left, plus a finite LSB-first trit suffix). Crucially, the right-rotate
instruction (`*`) rotates across a dynamic `rotwidth` R (>= 10) that depends
on the interpreter and on previously accessed address widths.

To work identically on EVERY compliant Malbolge Unshackled interpreter
(Unshackled.c with any initial/dynamic R, Unshackled-20.c with R=20, etc.)
with ZERO input instructions (`/`), the generated program uses 4 phases:

  Tail invariant:
    Program length satisfies L % 564 == 34 and ends with bytes [36, 101].
    This fixes the periodic initial memory fill iv[0..5] for all cells >= L:
      iv = [(1, 48), (0, 101), (1, 39), (0, 101), (1, 48), (0, 92)]

  Entry (c = 0, c = 99):
    At c = 0, d = 0: mem[0] = 98 encodes `i` (jmp), setting c = mem[0] = 98
    (xlat2 on landing pad 98, then increment -> c = 99, d = 1).
    At c = 99, d = 1: `i` sets c = mem[1] = 116 (xlat2 on landing pad 116,
    then increment -> c = 117, d = 2).

  Phase 1 (c = 117 .. 860, 744 ops; cells 861..1458 are pure `o` NOPs):
    Uses deterministic BFS over load-valid initial cells in mem[2..115] to
    write 26 fixed targets (loop pointers, X@54, Y@70, A_STOP-1@108, etc.),
    rotates X@54 four times (placing trit=2 at position R-4) and Y@70 once
    (placing trit=2 at position R-1), writes mem[A_STOP] = 11 (LOOP_EXIT-1),
    and jumps to c = 9 to enter the Phase 2 loop.

  Phase 2 (17-cell zero-hazard R-probe loop):
    Runs (R - 7) iterations regardless of R until X reaches A_STOP, leaving Y
    at the exact value needed to break out cleanly to LOOP_EXIT = 12.

  Phase 3 (c = 12 .. 17):
    Performs `p` on mem[75] = (1, 121) to produce a = 1458 (exact, independent
    of R!) and jumps directly to c = 1459 with d = 76, a = 1458.

  Phase 4 (c = 1459 .. 1570, 112 ops):
    Rotates a = 1458 -> 486 -> 162 (= 0t20000, zero-drift, trit4 = 2), jumps d
    via load-valid mem[77] = 116 to d = 117 (the untouched 100-cell guardian
    ring mem[117..216]), stamps trit4 = 2 onto 34 cells in mem[117..202], uses
    a 14-step BFS over mem[203..216] to write loop-back pointer mem[217] = 116,
    and executes `j` at mem[222] = 122 to enter the ring at d = 123 (index 6)
    with a = 116 and c = 1571 (start of emitted ASCII payload body).

Packed binary format (1,173 bytes before zlib+base64)
-----------------------------------------------------
  bytes    0..860  (861 B): prologue[0..860]   (entry + Phase 1..3 + Phase 1 ops)
                            [prologue[861..1458] are pure `o` NOPs, omitted here
                             and reconstructed at runtime in QR.py]
  bytes  861..972  (112 B): prologue[1459..1570] (Phase 4)
  bytes  973..1072 (100 B): low bytes  (x & 0xFF) of ring0[0..99]
  bytes 1073..1172 (100 B): high bytes (x >> 8)   of ring0[0..99]

Usage
-----
  python3 malbolge-boot.dat.gen.py              # generate src/malbolge-boot.dat
  python3 malbolge-boot.dat.gen.py --verify     # full R=10..50 + payload self-test
  python3 malbolge-boot.dat.gen.py -o OUT_PATH  # write to custom output path
"""

import argparse
import base64
import hashlib
import random
import sys
import zlib
from pathlib import Path

# ---------------------------------------------------------------------------
# Malbolge Unshackled specification tables & exact ternary-bigint simulator
# ---------------------------------------------------------------------------

# Malbolge "crazy" ternary operation table: CRZ[d_trit][a_trit]
CRZ = (
    (1, 0, 0),
    (1, 0, 2),
    (2, 2, 1),
)

# Post-execution instruction cipher table (xlat2, indexed by ord(c) - 33)
X2 = (
    "5z]&gqtyfr$(we4{WP)H-Zn,[%\\3dL+Q;>U!pJS72FhOA1CB6v^=I_0/8|jsb9m"
    "<.TVac`uY*MK'X~xDl}REokN:#?G\"i@"
)

# Valid (mem[c] + c) % 94 instruction residues
VALID_MAP = {4: "i", 5: "<", 23: "/", 39: "*", 40: "j", 62: "p", 68: "o", 81: "v"}
OP_NUM = {op: residue for residue, op in VALID_MAP.items()}


def ch(op: str, pos: int) -> int:
    """Return the printable ASCII byte (33..126) encoding `op` at address `pos`."""
    target = OP_NUM[op]
    for byte in range(33, 127):
        if (byte + pos) % 94 == target:
            return byte
    raise ValueError(f"no printable ASCII encoding for op={op!r} at pos={pos}")


def valid_chars_at(pos: int) -> list[int]:
    """Return all load-valid printable ASCII bytes (33..126) at address `pos`."""
    return [b for b in range(33, 127) if (b + pos) % 94 in VALID_MAP]


# Exact Malbolge Unshackled integer representation: (head, trits_tuple)
# where `head` in {0, 1, 2} is the infinite high-trit prefix and `trits_tuple`
# is LSB-first with trailing `head` trits stripped.
def norm(head: int, trits) -> tuple[int, tuple[int, ...]]:
    t = list(trits)
    while t and t[-1] == head:
        t.pop()
    return (head, tuple(t))


def from_int(n: int) -> tuple[int, tuple[int, ...]]:
    assert n >= 0
    t = []
    while n:
        t.append(n % 3)
        n //= 3
    return norm(0, t)


def to_int(num: tuple[int, tuple[int, ...]]) -> int:
    head, ts = num
    assert head == 0, f"cannot convert non-0t Unshackled integer to int: {num}"
    val = 0
    power = 1
    for trit in ts:
        val += trit * power
        power *= 3
    return val


def num_opr(a, d):
    ah, at = a
    dh, dt = d
    n = max(len(at), len(dt))
    rh = CRZ[dh][ah]
    rt = [
        CRZ[dt[i] if i < len(dt) else dh][at[i] if i < len(at) else ah]
        for i in range(n)
    ]
    return norm(rh, rt)


def num_rot(num, rotwidth: int):
    head, ts = num
    t = list(ts)
    while len(t) < rotwidth:
        t.append(head)
    # Right-rotate across max(len(t), rotwidth), matching Unshackled.c
    t = t[1:] + [t[0]]
    return norm(head, t)


def num_inc(num):
    head, ts = num
    t = list(ts)
    for i in range(len(t)):
        t[i] = (t[i] + 1) % 3
        if t[i] != 0:
            return norm(head, t)
    if head == 2:
        return (0, ())
    t.append(head + 1)
    return norm(head, t)


def num_mod(num, modul: int) -> int:
    head, ts = num
    res = (29524 % modul) * head
    pos = 1
    for trit in ts:
        res = (res + pos * (trit + modul - head)) % modul
        pos = (pos * 3) % modul
    return res


def run_sim(
    prog_bytes: list[int],
    init_rotwidth: int = 10,
    growth_mode: str = "fixed",
    max_steps: int = 50000,
):
    """
    Exact Malbolge Unshackled simulator matching both Unshackled.c (dynamic
    rotwidth growth) and Unshackled-20.c (fixed rotwidth=20). Raises immediately
    if any forbidden `/` (input) instruction is executed.
    """
    mem = {}
    prog_len = len(prog_bytes)
    for i, b in enumerate(prog_bytes):
        if not (33 <= b <= 126 and (b + i) % 94 in VALID_MAP):
            raise ValueError(f"invalid load byte {b} at address {i}")
        mem[from_int(i)] = from_int(b)

    # Periodic initial memory fill iv[0..5] for addresses >= prog_len
    prev = mem[from_int(prog_len - 1)]
    prevprev = mem[from_int(prog_len - 2)]
    iv = [None] * 6
    cur_i = prog_len
    pos = prog_len % 6
    while pos < 18:
        m1 = num_opr(prev, prevprev)
        mem[from_int(cur_i)] = m1
        if pos >= 12:
            iv[pos - 12] = m1
        prevprev = prev
        prev = m1
        cur_i += 1
        pos += 1

    def get_mem(addr):
        if addr not in mem:
            mem[addr] = iv[num_mod(addr, 6)]
        return mem[addr]

    a = from_int(0)
    c = from_int(0)
    d = from_int(0)
    rotwidth = init_rotwidth
    max_w = 0
    out = bytearray()

    for step in range(1, max_steps + 1):
        mc = get_mem(c)
        assert mc[0] == 0, f"step {step}: non-0t instruction at c={c}: {mc}"
        uc = to_int(mc)
        assert 33 <= uc <= 126, f"step {step}: invalid instruction {uc} at c={c}"
        op = (uc + num_mod(c, 94)) % 94

        if op == 4:  # i: jmp
            c = get_mem(d)
        elif op == 5:  # <: out
            assert a[0] == 0 and to_int(a) < 128, f"step {step}: bad out a={a}"
            out.append(to_int(a))
        elif op == 23:  # /: in (strictly forbidden)
            raise RuntimeError("forbidden '/' input instruction executed")
        elif op == 39:  # *: rot
            v = num_rot(get_mem(d), rotwidth)
            mem[d] = v
            a = v
        elif op == 40:  # j: movd
            d = get_mem(d)
            w = len(d[1])
            if w > max_w:
                max_w = w
                if growth_mode == "det" and max_w > rotwidth // 2:
                    rotwidth = max(rotwidth + 7, 2 * max_w)
                elif growth_mode == "aggressive":
                    rotwidth = max(2 * max_w + 5, rotwidth + 3)
        elif op == 62:  # p: opr
            v = num_opr(a, get_mem(d))
            mem[d] = v
            a = v
        elif op == 81:  # v: hlt
            return bytes(out), step, a, c, d, mem

        # Post-execution xlat2 cipher on mem[c]
        mc2 = get_mem(c)
        assert mc2[0] == 0, f"step {step}: xlat2 non-0t at c={c}: {mc2}"
        uc2 = to_int(mc2)
        assert 33 <= uc2 <= 126, f"step {step}: cannot xlat2 {uc2} at c={c}"
        mem[c] = from_int(ord(X2[uc2 - 33]))
        c = num_inc(c)
        d = num_inc(d)

    raise RuntimeError(f"max_steps={max_steps} exceeded at c={c}, d={d}, a={a}")


# ---------------------------------------------------------------------------
# 5-trit + head (486-state) tables for BFS synthesis
# ---------------------------------------------------------------------------
# State index s in 0..485 represents (head = s // 243, low5 = s % 243)
# with head in {0, 1} and low5 in 0..242 (5 ternary trits).

OPR = [[0] * 486 for _ in range(486)]
ROT = [-1] * 486
for _a in range(486):
    _ah, _al = divmod(_a, 243)
    if (_al % 3) == _ah:
        ROT[_a] = _ah * 243 + (_al // 3) + _ah * 81
    for _d in range(486):
        _dh, _dl = divmod(_d, 243)
        _rh = CRZ[_dh][_ah]
        _rl = 0
        _p = 1
        _x = _al
        _y = _dl
        for _ in range(5):
            _rl += CRZ[_y % 3][_x % 3] * _p
            _x //= 3
            _y //= 3
            _p *= 3
        OPR[_a][_d] = _rh * 243 + _rl

TRIT_OF = [[(s % 243) // (3**k) % 3 for k in range(5)] for s in range(486)]

# Fixed machine layout for entry, Phase 2 R-probe loop, and Phase 3 exit
LOOP_EXIT = 12
PRE_STOP = {
    a
    for a in range(486)
    if (a // 243) == ((a % 243) // 81) and OPR[a][101] == LOOP_EXIT - 1
}

LOOP_CODE = {
    0: ch("i", 0),
    1: 116,  # jmp target for c = 99 -> c = 117
    99: ch("i", 99),
    8: ch("o", 8),
    9: 125,
    10: ch("o", 10),
    11: ch("i", 11),
    29: 105,
    30: ch("i", 30),
    59: 74,
    60: 74,
    61: ch("i", 61),
    63: 70,
    64: 70,
    65: ch("i", 65),
    102: ch("o", 102),
    103: 125,
    104: ch("o", 104),
    105: 51,
    106: 50,
    107: ch("i", 107),
}
for _idx, _op in enumerate(("o", "j", "j", "p", "j", "i")):
    LOOP_CODE[LOOP_EXIT + _idx] = ch(_op, LOOP_EXIT + _idx)

LANDING_PADS = {7, 28, 58, 62, 98, 101, 116}


# ---------------------------------------------------------------------------
# Phase 1..4 deterministic prologue synthesis
# ---------------------------------------------------------------------------


def _try_straight_write(a0, d0, dest, val, mem, free_scratch):
    lv = {a0: None}
    hist = []
    for pos in range(d0, dest):
        md = mem[pos]
        can = pos in free_scratch
        nx = {}
        r_val = ROT[md] if can else -1
        for v in lv:
            if v not in nx:
                nx[v] = (v, "o")
            if can:
                z = OPR[v][md]
                if z not in nx:
                    nx[z] = (v, "p")
                if r_val != -1 and r_val not in nx:
                    nx[r_val] = (v, "*")
        hist.append(nx)
        lv = nx
    md = mem[dest]
    for v in lv:
        if OPR[v][md] == val:
            ops = ["p"]
            cur = v
            for h in reversed(hist):
                pv, op = h[cur]
                ops.append(op)
                cur = pv
            ops.reverse()
            return ops
    if ROT[md] == val:
        v = next(iter(lv))
        ops = ["*"]
        cur = v
        for h in reversed(hist):
            pv, op = h[cur]
            ops.append(op)
            cur = pv
        ops.reverse()
        return ops
    return None


def _try_straight_set(a0, d0, dest, tgt_set, mem, free_scratch):
    lv = {a0: None}
    hist = []
    for pos in range(d0, dest):
        md = mem[pos]
        can = pos in free_scratch
        nx = {}
        r_val = ROT[md] if can else -1
        for v in lv:
            if v not in nx:
                nx[v] = (v, "o")
            if can:
                z = OPR[v][md]
                if z not in nx:
                    nx[z] = (v, "p")
                if r_val != -1 and r_val not in nx:
                    nx[r_val] = (v, "*")
        hist.append(nx)
        lv = nx
    hit = next((v for v in lv if v in tgt_set), None)
    if hit is None:
        return None
    ops = []
    cur = hit
    for h in reversed(hist):
        pv, op = h[cur]
        ops.append(op)
        cur = pv
    ops.reverse()
    return ops


def _apply_straight(a, d0, ops, mem):
    for i, op in enumerate(ops):
        pos = d0 + i
        if op == "p":
            a = OPR[a][mem[pos]]
            mem[pos] = a
        elif op == "*":
            a = ROT[mem[pos]]
            mem[pos] = a
    return a


def build_prologue_and_ring(full_verify: bool = False, quiet: bool = False):
    """
    Deterministically synthesize the 1,571-byte prologue and 100-cell guardian
    ring, verify rotwidth independence on the exact simulator, and return
    (prologue_bytes, ring0, a0, d0).
    """
    ep = 78  # Phase-1 exit pair (78, 79) = (8, 361)
    targets = {
        31: 58, 34: 62, 37: 28, 39: 28, 41: 28,
        43: 8, 46: 8, 49: 8, 52: 7, 53: 58,
        54: 365, 55: 68, 69: 62, 70: 365, 71: 30,
        75: 364, 76: 74,
        ep: 8, ep + 1: 361,
        93: 74, 96: 28, 97: 52,
        108: 392,  # A_STOP - 1 = (1, 149)
        114: 29,   # Phase-1 loop-back ptr (-> 30)
    }
    # mem[77] = 116 is load-valid at address 77, jumping d -> 117 in Phase 4
    fixed_ptrs = {56: 42, 77: 116, 115: 41}
    assert 116 in valid_chars_at(77)

    never_touch = set(LOOP_CODE) | LANDING_PADS | set(fixed_ptrs)
    assert not (set(targets) & never_touch)

    tgt_cands = {}
    for pos, tgt in targets.items():
        if tgt in valid_chars_at(pos):
            tgt_cands[pos] = [tgt]
        else:
            cs = [
                md
                for md in valid_chars_at(pos)
                if any(
                    (a // 243) == ((a % 243) // 81) and OPR[a][md] == tgt
                    for a in range(486)
                )
            ]
            assert cs, f"no 1-op load-valid candidate for mem[{pos}]={tgt}"
            tgt_cands[pos] = cs

    all_free = {p for p in range(2, 116) if p not in never_touch and p not in targets}
    all_free_ordered = sorted(all_free)

    rng = random.Random(42)
    best_p1 = None
    for trial in range(100):
        mem = {p: ch("o", p) for p in range(117)}
        mem.update(LOOP_CODE)
        mem.update(fixed_ptrs)
        for p in all_free_ordered:
            mem[p] = rng.choice(valid_chars_at(p))
        for p, cs in tgt_cands.items():
            mem[p] = rng.choice(cs)
        init_mem = dict(mem)

        pending = {p for p, v in targets.items() if mem[p] != v}
        a, d = 0, 2
        ops = []
        ok = True
        for _lap in range(20):
            if not pending:
                break
            while d <= 114:
                nxt_list = [p for p in sorted(pending) if p >= d]
                if not nxt_list:
                    break
                wrote = False
                for tgt_p in nxt_list:
                    sub = _try_straight_write(a, d, tgt_p, targets[tgt_p], mem, all_free)
                    if sub is not None:
                        a = _apply_straight(a, d, sub, mem)
                        ops.extend(sub)
                        d = tgt_p + 1
                        pending.remove(tgt_p)
                        wrote = True
                        break
                if not wrote:
                    break
            if not pending:
                break
            min_p = min(pending)
            if min_p >= 43 and d <= 56:
                ops.extend(["o"] * (56 - d) + ["j"])
                d = 43
            elif 114 not in pending and d <= 114:
                ops.extend(["o"] * (114 - d) + ["j"])
                d = 30
            elif d <= 115:
                ops.extend(["o"] * (115 - d) + ["j"])
                d = 42
            else:
                ok = False
                break
            if len(ops) > 1100:
                ok = False
                break

        if not ok or pending or d > 114:
            continue

        # Return to d = 30 before any rotation so max_wordwidth == 4 stays fixed
        ops.extend(["o"] * (114 - d) + ["j"])
        d = 30

        # Rotate X@54 four times (2 at R-4) and Y@70 once (2 at R-1)
        for _ in range(3):
            ops.extend(["o"] * (54 - d) + ["*", "o", "j"])
            d = 43
        ops.extend(["o"] * (54 - d) + ["*"])
        d = 55
        ops.extend(["o"] * (70 - d) + ["*"])
        d = 71

        # Clear high 2 from a = Y (low5 = (1, 121)) on first head=0 free cell >= 72
        clean_p = next((p for p in range(72, 108) if p in all_free and mem[p] < 243), None)
        if clean_p is None:
            continue
        ops.extend(["o"] * (clean_p - d) + ["p"])
        a = OPR[243 + 121][mem[clean_p]]
        mem[clean_p] = a
        d = clean_p + 1

        # Steer a into PRE_STOP arriving at d == 108
        sub = _try_straight_set(a, d, 108, PRE_STOP, mem, all_free)
        if sub is None:
            continue
        a = _apply_straight(a, d, sub, mem)
        ops.extend(sub)
        d = 108

        # Final exit of Phase 1 into Phase 2 loop (c = 9)
        ops.extend(["j", "p", "o", "j", "j"] + ["o"] * (ep - 75) + ["i"])
        if len(ops) <= 1340:
            if best_p1 is None or len(ops) < len(best_p1[0]):
                best_p1 = (ops, init_mem)
                if len(ops) <= 750:
                    break

    assert best_p1 is not None, "failed to synthesize Phase 1"
    ops_p1, init_mem = best_p1
    assert 117 + len(ops_p1) == 861, f"unexpected Phase 1 end: {117 + len(ops_p1)}"

    # Assemble Phases 1..3 + Phase 4 entry (c = 0..1464) and extract mem[117..239]
    prog_base = [ch("o", i) for i in range(1466)]
    for k, v in init_mem.items():
        prog_base[k] = v
    for i, op in enumerate(ops_p1):
        prog_base[117 + i] = ch(op, 117 + i)

    # Phase 4 entry (1459..1464): 1458 -> 486 -> 162 (= 0t20000), jump d -> 117
    prog_base[1459] = ch("j", 1459)
    prog_base[1460] = ch("*", 1460)
    prog_base[1461] = ch("j", 1461)
    prog_base[1462] = ch("*", 1462)
    prog_base[1463] = ch("o", 1463)
    prog_base[1464] = ch("j", 1464)
    prog_base[1465] = ch("v", 1465)

    probe_prog = list(prog_base)
    while (len(probe_prog) + 2) % 564 != 34:
        probe_prog.append(ch("o", len(probe_prog)))
    probe_prog.extend((36, 101))

    rotwidths = (10, 11, 12, 13, 14, 15, 20, 30, 50) if full_verify else (10, 20)
    modes = ("fixed", "det", "aggressive") if full_verify else ("aggressive",)
    ref_ring = None
    for r_init in rotwidths:
        for mode in modes:
            _, _, a_end, c_end, d_end, mem_end = run_sim(
                probe_prog, init_rotwidth=r_init, growth_mode=mode, max_steps=30000
            )
            assert a_end == from_int(162), f"Phase 1..3 fail R={r_init} {mode}: a={a_end}"
            assert c_end == from_int(1465), f"Phase 1..3 fail R={r_init} {mode}: c={c_end}"
            assert d_end == from_int(117), f"Phase 1..3 fail R={r_init} {mode}: d={d_end}"
            snap = tuple(to_int(mem_end[from_int(p)]) for p in range(117, 240))
            if ref_ring is None:
                ref_ring = snap
            else:
                assert snap == ref_ring, f"R-dependent cell in 117..239 at R={r_init} {mode}"

    # Phase 4 body (c = 1465..1570): stamp trit4=2 onto 34 ring cells, write
    # loop-back pointer mem[217]=116, and re-enter ring via mem[222]=122 -> d=123
    ring_mem = {117 + i: ref_ring[i] for i in range(len(ref_ring))}
    a = 162
    p4_ops = []

    stamped = 0
    for pos in range(117, 203):
        md = ring_mem[pos]
        if md >= 81 and stamped < 34:
            a = OPR[a][md]
            ring_mem[pos] = a
            p4_ops.append("p")
            stamped += 1
        else:
            p4_ops.append("o")

    lv = {a: None}
    hist = []
    for pos in range(203, 217):
        md = ring_mem[pos]
        r_val = ROT[md]
        nx = {}
        for v in lv:
            if v not in nx:
                nx[v] = (v, "o")
            z = OPR[v][md]
            if z not in nx:
                nx[z] = (v, "p")
            if r_val != -1 and r_val not in nx:
                nx[r_val] = (v, "*")
        hist.append(nx)
        lv = nx

    hit_v = next((v for v in lv if OPR[v][ring_mem[217]] == 116), None)
    assert hit_v is not None, "could not write 116 to mem[217]"
    sub = ["p"]
    cur = hit_v
    for h in reversed(hist):
        pv, op = h[cur]
        sub.append(op)
        cur = pv
    sub.reverse()
    for i, op in enumerate(sub):
        pos = 203 + i
        if op == "p":
            a = OPR[a][ring_mem[pos]]
            ring_mem[pos] = a
        elif op == "*":
            a = ROT[ring_mem[pos]]
            ring_mem[pos] = a
    p4_ops.extend(sub)
    assert a == 116 and ring_mem[217] == 116
    assert ring_mem[222] == 122
    p4_ops.extend(("o", "o", "o", "o", "j"))

    prologue = list(prog_base[:1465])
    for i, op in enumerate(p4_ops):
        prologue.append(ch(op, 1465 + i))
    assert len(prologue) == 1571
    # Verify cells 861..1458 are pure `o` NOPs so QR.py can reconstruct them
    assert all(prologue[i] == ch("o", i) for i in range(861, 1459))

    ring0 = [ring_mem[117 + i] for i in range(100)]
    a0 = 116
    d0 = 123 - 117  # 6

    # Verify complete 1,571-byte prologue end-to-end across rotwidths
    test_prog = list(prologue) + [ch("v", len(prologue))]
    while (len(test_prog) + 2) % 564 != 34:
        test_prog.append(ch("o", len(test_prog)))
    test_prog.extend((36, 101))

    verify_rs = (10, 15, 20, 30, 50) if full_verify else (10, 15, 20, 30)
    for r_init in verify_rs:
        _, _, a_end, c_end, d_end, mem_end = run_sim(
            test_prog, init_rotwidth=r_init, growth_mode="aggressive", max_steps=30000
        )
        assert a_end == from_int(a0)
        assert c_end == from_int(len(prologue))
        assert d_end == from_int(117 + d0)
        assert mem_end[from_int(217)] == from_int(116)
        for i in range(100):
            h, lo = divmod(ring0[i], 243)
            ts = [(lo // (3**k)) % 3 for k in range(5)]
            assert mem_end[from_int(117 + i)] == norm(h, ts), f"ring[{i}] mismatch at R={r_init}"

    if not quiet:
        print(
            f"malbolge-boot: verified {len(prologue)} B prologue + {len(ring0)}-cell ring "
            f"(a0={a0}, d0={d0}) across R={list(verify_rs)}",
            file=sys.stderr,
        )
    return bytes(prologue), ring0, a0, d0


def pack_boot_blob(prologue: bytes, ring0: list[int]) -> tuple[bytes, str]:
    """Pack prologue + ring0 into the 1,173-byte binary payload and base64+zlib string."""
    raw = (
        prologue[:861]
        + prologue[1459:]
        + bytes(x & 0xFF for x in ring0)
        + bytes((x >> 8) & 0xFF for x in ring0)
    )
    assert len(raw) == 1173
    blob = base64.b64encode(zlib.compress(raw, 9)).decode("ascii")
    return raw, blob


def _verify_payload_roundtrip(blob: str) -> None:
    """Emit and simulate a full ASCII test program using the exact QR.py algorithm."""
    w = zlib.decompress(base64.b64decode(blob))
    co, cp, cr, cj, cu, cv = [
        [33 + (q - i) % 94 for i in range(94)] for q in (35, 29, 6, 7, 66, 48)
    ]
    rg = [w[973 + i] + (w[1073 + i] << 8) for i in range(100)]
    out = bytearray(w[:861] + bytes(co[i % 94] for i in range(861, 1459)) + w[861:973])
    oc = [[0] * 486 for _ in range(486)]
    oi = [[[] for _ in range(128)] for _ in range(486)]
    rt = [-1] * 486
    m2 = [0] * 486
    m0 = [0] * 486
    for d in range(486):
        dh, dl = divmod(d, 243)
        q2 = q0 = 0
        u = dl
        if dl % 3 == dh:
            rt[d] = dh * 243 + dl // 3 + dh * 81
        for k in range(5):
            t0 = u % 3
            u //= 3
            q2 |= (t0 == 2) << k
            q0 |= (t0 == 0) << k
        m2[d] = q2
        m0[d] = q0
        cl = oc[d]
        iv = oi[d]
        for a in range(486):
            ah, al = divmod(a, 243)
            rl = 0
            pw = 1
            x = al
            y = dl
            for _ in range(5):
                rl += CRZ[y % 3][x % 3] * pw
                x //= 3
                y //= 3
                pw *= 3
            z = CRZ[dh][ah] * 243 + rl
            cl[a] = z
            if z < 128:
                iv[z].append(a)

    n = 100
    a = 116
    d = 6
    c = len(out)
    ap = out.append
    sv = [0] * 486
    ps = [0] * 486
    pp = [0] * 486
    po = [0] * 486
    vr = 0
    tw = [sum(m2[x] >> k & 1 for x in rg) for k in range(5)]
    zr = [sum(m0[x] >> k & 1 for x in rg) for k in range(5)]

    def upd(u, nw):
        ol = rg[u]
        if ol != nw:
            a2, b2, a0_, b0_ = m2[ol], m2[nw], m0[ol], m0[nw]
            rg[u] = nw
            if a2 != b2:
                df = a2 ^ b2
                for k in range(5):
                    if df >> k & 1:
                        tw[k] += 1 if b2 >> k & 1 else -1
            if a0_ != b0_:
                df = a0_ ^ b0_
                for k in range(5):
                    if df >> k & 1:
                        zr[k] += 1 if b0_ >> k & 1 else -1

    sample = (
        "Quine Relay 256 -> Malbolge Unshackled!\n"
        + "".join(chr(x) for x in range(32, 127))
        + "\t\n"
    ).encode("ascii")

    for b in sample:
        mt = 20
        fb = 0
        while a != b:
            n2 = (
                (tw[0] <= mt)
                | ((tw[1] <= mt) << 1)
                | ((tw[2] <= mt) << 2)
                | ((tw[3] <= mt) << 3)
                | ((tw[4] <= mt) << 4)
            )
            n0 = (
                (zr[0] <= mt)
                | ((zr[1] <= mt) << 1)
                | ((zr[2] <= mt) << 2)
                | ((zr[3] <= mt) << 3)
                | ((zr[4] <= mt) << 4)
            )
            vr += 1
            sv[a] = vr
            fr = [a]
            ds = []
            cd = d
            vs = fd = hp = ho = si = 0
            while vs < n:
                if cd == n:
                    ds.append(n)
                    cd = 0
                    si += 1
                    continue
                md = rg[cd]
                p2 = n2 & m2[md]
                p0 = n0 & m0[md]
                rv = rt[md] if (p2 | p0) == 0 else -1
                if rv == b:
                    hp = fr[0]
                    ho = 2
                    ds.append(cd)
                    fd = 1
                    break
                for v in oi[md][b]:
                    if sv[v] == vr and (m2[v] & p2) == 0 and (m0[v] & p0) == 0:
                        hp = v
                        ho = 1
                        ds.append(cd)
                        fd = 1
                        break
                if fd:
                    break
                fl = len(fr)
                cl = oc[md]
                if rv != -1 and sv[rv] != vr:
                    sv[rv] = vr
                    ps[rv] = si
                    pp[rv] = fr[0]
                    po[rv] = 2
                    fr.append(rv)
                if (p2 | p0) == 0:
                    for i in range(fl):
                        v = fr[i]
                        z = cl[v]
                        if sv[z] != vr:
                            sv[z] = vr
                            ps[z] = si
                            pp[z] = v
                            po[z] = 1
                            fr.append(z)
                else:
                    for i in range(fl):
                        v = fr[i]
                        if (m2[v] & p2) == 0 and (m0[v] & p0) == 0:
                            z = cl[v]
                            if sv[z] != vr:
                                sv[z] = vr
                                ps[z] = si
                                pp[z] = v
                                po[z] = 1
                                fr.append(z)
                ds.append(cd)
                cd += 1
                vs += 1
                si += 1
            if fd:
                ns = len(ds)
                op = [0] * ns
                op[ns - 1] = ho
                v = hp
                while v != a:
                    s0 = ps[v]
                    op[s0] = po[v]
                    v = pp[v]
                for i in range(ns):
                    u = ds[i]
                    if u == n:
                        ap(cj[c % 94])
                        c += 1
                        d = 0
                    elif op[i] == 0:
                        ap(co[c % 94])
                        c += 1
                        d += 1
                    else:
                        if op[i] == 1:
                            ap(cp[c % 94])
                            nw = oc[rg[u]][a]
                        else:
                            ap(cr[c % 94])
                            nw = rt[rg[u]]
                        c += 1
                        upd(u, nw)
                        a = nw
                        d += 1
            else:
                fb += 1
                mt = max(0, mt - 6)
                if mt == 0 and fb > 4:
                    if d == n:
                        ap(cj[c % 94])
                        c += 1
                        d = 0
                    nw = oc[rg[d]][a]
                    ap(cp[c % 94])
                    c += 1
                    upd(d, nw)
                    a = nw
                    d += 1
        if d == n:
            ap(cj[c % 94])
            c += 1
            d = 0
        ap(cu[c % 94])
        c += 1
        d += 1

    ap(cv[c % 94])
    c += 1
    while (c + 2) % 564 != 34:
        ap(co[c % 94])
        c += 1
    out.extend((36, 101))

    for r_init in (10, 15, 20):
        got, steps, *_ = run_sim(
            list(out), init_rotwidth=r_init, growth_mode="aggressive", max_steps=100000
        )
        assert got == sample, f"round-trip payload mismatch at R={r_init}"
    print(
        f"malbolge-boot: full ASCII round-trip PASS ({len(sample)} B -> {len(out)} B .mb) "
        f"across R=[10, 15, 20]",
        file=sys.stderr,
    )


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Generate src/malbolge-boot.dat from first principles."
    )
    parser.add_argument(
        "-o",
        "--output",
        type=Path,
        default=Path(__file__).resolve().parent / "malbolge-boot.dat",
        help="Output path (default: malbolge-boot.dat next to this script)",
    )
    parser.add_argument(
        "--verify",
        action="store_true",
        help="Run extended R=10..50 sweep and full ASCII payload round-trip test",
    )
    parser.add_argument(
        "-q",
        "--quiet",
        action="store_true",
        help="Suppress informational stderr output",
    )
    args = parser.parse_args()

    prologue, ring0, _, _ = build_prologue_and_ring(
        full_verify=args.verify, quiet=args.quiet
    )
    raw, blob = pack_boot_blob(prologue, ring0)

    if args.verify:
        _verify_payload_roundtrip(blob)

    args.output.write_bytes(blob.encode("ascii"))
    if not args.quiet:
        raw_sha = hashlib.sha256(raw).hexdigest()
        blob_sha = hashlib.sha256(blob.encode("ascii")).hexdigest()
        print(
            f"wrote {args.output} ({len(blob)} B base64+zlib, sha256={blob_sha[:16]}...; "
            f"raw={len(raw)} B, sha256={raw_sha[:16]}...)",
            file=sys.stderr,
        )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
