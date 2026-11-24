# Quine Relay 256 v3 ("The Endoh Stamp") — Verification & Security Audit

**Date:** 2026-11-23  
**Tree:** `milestones/256-alpha/v3/quine-relay/`  
**Base Image:** `qr256-1727379-scratch` (Ubuntu 26.04)  
**Verified Image:** `qr256-alpha-v3` (`sha256:77705ddce1d0e763e6507292f7161fe8dd74f1c1e9a4b174c2fe7cca75b417f6`)

---

## 1. Accounting ("The Endoh Stamp": 128 + 128 = 256)

Rather than retroactively applying an external deduplication rule to upstream `mame/quine-relay`, `v3` preserves **100%** of Yusuke Endoh's Ubuntu 26.04 relay and holds our **128** additions to a strict standalone upstream-toolchain standard:

| Component | Count | Rule / Status |
|---|---:|---|
| `mame/quine-relay` Ubuntu 26.04 base (`mame (Endoh Stamp)`) | **128** | **128 / 128 preserved**, including `FORTRAN77`, `Gzip`, `JSFuck`, `Ook!`, and `WebAssembly (Binary format)` |
| Restored `mame` retirees (`RESTORED_MAME`) | **16** | `A+`, `AspectC++`, `Boo`, `CDuce`, `Dafny`, `eC`, `Falcon`, `Generator Scripting Language`, `GNU Smalltalk`, `Gri`, `Julia`, `Lisaac`, `Maxima`, `nesC`, `Parrot asm (PASM)`, `UCBLogo` |
| Unbounded Malbolge (`Malbolge Unshackled`) | **1** | CC0 `Unshackled.c` / `Unshackled-20.c` (`U20_PARITY=OK`, `MB_STDIN_SAME`, `0` stdin reads under `strace`) |
| Standalone third-party fork additions | **111** | Canonical upstream compilers/interpreters only |
| **Total (`RunSteps`)** | **256** | **Strict A–Z** (`Out of order: 0`, entry `#1 AspectJ`, wrap `#244 6502 asm`) |

### Removed in v3 (eliminating all fork-side asterisks)
- Deleted `vendor/beatnik.rb`, `vendor/emmental.rb`, `vendor/slashes.rb`, `vendor/underload.rb` and retired `Beatnik`, `Emmental`, `///`, `Underload` (`0` custom fork esolang runners remain in `vendor/`).
- Retired `SQL (SQLite)` (single `SELECT '...'` query format).
- Upgraded `Forth -> FORTRAN77 -> Fortran90` (`gfortran`), `Groovy -> Gzip` (`gzip -cd`), `JavaScript -> Jq -> JSFuck` (`[]()!+` charset + balanced binary-tree `+`), `Odin -> Ook!` (`vendor/ook-to-bf.rb` + `vendor/bf.rb`), `Visual Basic -> WebAssembly (Binary format) -> WebAssembly (Text format) -> Whitespace` (`vendor/wasi-runtime.js` + `wat2wasm`), `Umka -> Unlambda` (`vendor/unlambda.rb`), `BeanShell`, and `Emacs Lisp`.
- Upgraded `JuliaLang` (`QR.jl`) with deterministic LZ77 compression (skipping `[`, `\`, `]` tokens so `Jasmin#check` `BRACKETS` invariant and downstream `dc` remain intact), `Uxntal` (`QR.tal`) with raw-byte `@z` + in-Uxn Base64 encoding (`57,065 B` ROM), and `IonShell` (`QR.ion`) with single-quote sigil-opener splitting (`@{`, `@(`, `${`, `$(` -> `@''{`, etc.).

---

## 2. Deterministic Engine, Order, & 16-bit Hardware/VM Guards

- **Order & count (`check_order.rb`)**: `256` unique steps (`225` `GenSteps`, `224` non-nil), missing from `MAME_128`: `[]`, missing from `RESTORED_16`: `[]`, `Out of order: 0`.
- **Differential verifier (`diff-test-v3.rb`)**: `self() == QR.aj` byte-for-byte (`54,047 B`, `sha256: ed0fbe68141e50a7b8cb06c1ebbbe86e17b797823a20a9d1403df256f134e2c8`), **Phase 1 `exact=224, fails=0 / 224`**, **Phase 2 chain `check()`s `224 / 224` passed**.
- **6-generator idempotency**: Two consecutive runs of `gen-aj.rb`, `LANGUAGES.md.gen.rb`, `Makefile.gen.rb`, `Dockerfile.gen.rb`, `dot.github.workflows.main.yml.gen.rb`, and `README.md.gen.rb` produced 100% byte-identical SHA-256 digests (`QR.aj` unchanged at `ed0fbe68...`).
- **16-bit `< 64,000 B` ROM guards (`gen-aj.rb` + `vm-exec.rb`)**:
  - `6502 asm` (`xa` + `sim65`): `46,723 B / 65,012 B` (`spare = 18,289 B`, `0.02s`, `exact=true`)
  - `Z80 asm` (`z80asm` + `tnylpo`): `63,281 B / 64,991 B` (`spare = 1,710 B`, `0.01s`, `exact=true`)
  - `Uxntal` (`uxnasm` + `uxncli`): `57,065 B / 65,280 B` (`spare = 8,215 B`, `87.81%`, `0.10s`, `exact=true`)

---

## 3. Full Offline Proof Laps (`--network=none`, `USER qr` `uid=1001`)

1. **Lap 1 (`qr_v3_lap1`, `make all -j 10000`)**:
   - **256 / 256 PASS** in **`2,396.8s` (`39.9 min`)**
   - `diff -s QR.aj QR2.aj` -> `Files QR.aj and QR2.aj are identical` (`54,047 B`)
   - `QR.jsfuck` -> `20,371,566 B`, strictly characters in `[][()!+\n]`
   - `SHA256SUMS` -> `256` entries generated and verified (`sha256sum --quiet -c SHA256SUMS` exit 0)
   - `Malbolge Unshackled` -> `U20_PARITY=OK`, `MB_STDIN_SAME=OK`: both `unshackled` (`Unshackled.c`) and `unshackled20` (`Unshackled-20.c`) produced byte-identical `QR.wl` (`197,676 B`) with both `< /dev/null` and 50-line canary stdin (`XYZ_CANARY_INPUT_999\n` * 50)
2. **Lap 2 (`qr_v3_lap2`, untouched default `CMD ["make", "check", "-j", "10000"]`)**:
   - Exited **0** (`Files QR.aj and QR2.aj are identical`, `256 / 256` `SHA256SUMS` verified)
   - `make clean` check -> `Only in pre_lap: []`, `Only in post_clean (LEFTOVERS): []` (zero leftover files or directories)
3. **Lap 3 (1-byte engine canary: `"bad op "` -> `"bad oq "` in `src/engine_body.java`)**:
   - Rebuilt `QR.aj` (`54,048 B`, `sha256: 52500fe2...`, ROMs `46,721 B` / `63,388 B` / `57,246 B`)
   - Full `make all -j 10000` -> PASS in `2,453.2s` (`Files QR.aj and QR2.aj are identical`)
   - **`CANARY_CHANGED=256/256 UNCHANGED=0/256`**

---

## 4. `strace -f` Audit (`--network=none --cap-add=SYS_PTRACE`)

Verified inside a throwaway `strace` layer built on top of the offline Lap 1 snapshot (`qr_v3_lap1_audit`, deleted after audit):
- **`Malbolge Unshackled` (`strace -f -e trace=read`)**: **`0` `read(0, ...)` syscalls** across `925` trace lines while emitting exact `197,676 B` `QR.wl` (`cmp -s` exit 0). (Note: `QR.mb` `3,774,473 B` contains `39,934` literal `'/'` ASCII bytes inside payload/cell data, none of which execute as input ops.)
- **49 changed, restored, and adjacent steps (`audit_strace.rb`)**: **49 / 49 exited `ok=true exact=true`** (byte-identical output) and **0** CLI code injections:
  - **44 / 49** passed with `bad_reads=0 net=0` (`BeanShell`, `Emacs Lisp`, `Forth`, `FORTRAN77`, `Fortran90`, `Generator Scripting Language`, `Groovy`, `Gzip`, `Ion`, `JavaScript`, `Jq`, `JSFuck`, `Julia`, `Odin`, `Ook!`, `Umka`, `Unlambda`, `Uxntal`, `V`, `Vala`, `Whitespace`, `Zig`, `Z80 asm`, `Befunge`, `Glass`, `GEL (Genius)`, `PARI/GP`, `Scheme`, `SNOBOL4`, `Standard ML`, `Malbolge Unshackled`, `AspectC++`, `Parrot asm (PASM)`, `Boo`, `Maxima`, `Gri`, `UCBLogo`, `GNU Smalltalk`, `nesC`, `Lisaac`, `eC`, `CDuce`, `A+`, `Falcon`).
  - **5 / 49 runtime lookup/resolver artifacts only** (zero actual file leaks or external connections):
    - `Visual Basic`, `Dafny`, `Erlang`: `.NET` / BEAM libc DNS resolver probing `192.168.65.7:53` returning `-1 ENETUNREACH` under `--network=none` (`bad_reads=0`).
    - `WebAssembly (Binary format)`, `WebAssembly (Text format)`: Node.js ESM parent-directory probe for non-existent `/usr/local/share/quine-relay/package.json` returning `-1 ENOENT` (`net=0`).

---

## 5. Honest Disclosed Limitations & Upstream Conventions

- **Classic 10-trit Malbolge caveat**: Because strict A–Z ordering puts the `M` section at several hundred kilobytes, step 127 uses `Malbolge Unshackled` rather than classic 10-trit Malbolge (whose `59,049`-cell limit remains unbroken in classic Malbolge).
- **8 upstream `mame` tool conventions** (inherited unchanged under the Endoh Stamp): `sed` (`sed -E -f QR.sed QR.sed`), `Mustache` (`mustache QR.mustache QR.mustache`), `XSLT` (`<?xml-stylesheet ... href=''?>`), `Execline` (`foreground { echo -n ... }`), `bc` (`BC_LINE_LENGTH=4000000`), `MiniZinc` (`--soln-sep ''`), `Promela` (`spin -T`), and `Jq` (`jq -r -n -f QR.jq`).
- **11 stdlib zlib unpacker steps**: `C#`, `CoffeeScript`, `Elixir`, `F#`, `Go`, `Groovy`, `Mathics`, `PowerShell`, `Tcl`, `V`, `Zig`.
- **Memory**: `Shakespeare` (`gcc -O0` on `QR.spl.c`, `63,872,679 B`) peaks at `~21 GB` RSS (`>= 24 GB` VM RAM required).
