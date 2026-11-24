# Quine Relay 256 v3.1 ("The Endoh Stamp") — Verification & Audit Summary

**Date:** 2026-11-24  
**Base Image:** `qr256-1727379-scratch` (Ubuntu 26.04)  
**Verified Image:** `qr256-alpha-v3` (`sha256:78891375f453f39e6b6899d0504e7244a584931ca4f7b139cc005938af0c60ef`)

---

## 1. Accounting ("The Endoh Stamp": 128 + 128 = 256)

Rather than retroactively applying an external deduplication rule to upstream `mame/quine-relay`, `v3` / `v3.1` preserves **100%** of Yusuke Endoh's Ubuntu 26.04 relay and holds our **128** additions to a strict standalone upstream-toolchain standard:

| Component | Count | Rule / Status |
|---|---:|---|
| `mame/quine-relay` Ubuntu 26.04 base (`mame (Endoh Stamp)`) | **128** | **128 / 128 preserved**, including `FORTRAN77`, `Gzip`, `JSFuck`, `Ook!`, and `WebAssembly (Binary format)` |
| Restored `mame` retirees (`RESTORED_MAME`) | **16** | `A+`, `AspectC++`, `Boo`, `CDuce`, `Dafny`, `eC`, `Falcon`, `Generator Scripting Language`, `GNU Smalltalk`, `Gri`, `Julia`, `Lisaac`, `Maxima`, `nesC`, `Parrot asm (PASM)`, `UCBLogo` |
| Unbounded Malbolge (`Malbolge Unshackled`) | **1** | CC0 `Unshackled.c` / `Unshackled-20.c` (`U20_PARITY=OK`, `MB_STDIN_SAME=OK`, `0` stdin reads under baseline `strace`) |
| Standalone third-party fork additions | **111** | Canonical upstream compilers/interpreters only |
| **Total (`RunSteps`)** | **256** | **Strict A–Z** (`Out of order: 0`, entry `#1 AspectJ`, wrap `#244 6502 asm`) |

Counting lenses disclosed in `RECORDS.md`: **256** relay steps (Endoh's standard) / **251** strict distinct languages / **246** under a stricter no-superset/dialect lens.

### Key v3 / v3.1 Engineering Updates
- Deleted `vendor/beatnik.rb`, `vendor/emmental.rb`, `vendor/slashes.rb`, `vendor/underload.rb` and retired `Beatnik`, `Emmental`, `///`, `Underload` (`0` custom fork esolang runners remain in `vendor/`; all `13` vendor helpers match `mame/quine-relay` byte-for-byte).
- Retired `SQL (SQLite)` (single `SELECT '...'` query format).
- Upgraded `Forth -> FORTRAN77 -> Fortran90` (`gfortran`), `Groovy -> Gzip` (`gzip -cd`), `JavaScript -> Jq -> JSFuck` (`[]()!+` charset + balanced binary-tree `+`), `Odin -> Ook!` (`vendor/ook-to-bf.rb` + `vendor/bf.rb`), `Visual Basic -> WebAssembly (Binary format) -> WebAssembly (Text format) -> Whitespace` (`vendor/wasi-runtime.js` + `wat2wasm`), `Umka -> Unlambda` (`vendor/unlambda.rb`), `BeanShell`, and `Emacs Lisp`.
- Upgraded `JuliaLang` (`QR.jl`) with deterministic LZ77 compression (skipping `[`, `\`, `]` tokens so `Jasmin#check` `BRACKETS` invariant and downstream `dc` remain intact) and `Uxntal` (`QR.tal`) with raw-byte `@z` + in-Uxn Base64 encoding (`57,371 B` ROM).
- Hardened `IonShell` (`QR.ion`) in `v3.1` with `CHUNK_NOBR` variable concatenation (`4000`-byte `let x ++= '...'` chunks mapping `'`, `\`, `$`, `@`, `[`, `]`, `{`, `}`, `(`, `)` to `'$q'`/`'$b'`/... plus `echo -n $x`), fixing Redox `ion`'s `\'` single-quote escape edge case exposed by the verifier's `"QRCAN! "` canary lap at Step 98 (`Ion -> J`).

---

## 2. Deterministic Engine, Order, & 16-bit Hardware/VM Guards (`v3.1`)

- **Order & count (`check_order.rb`)**: `256` unique steps (`225` `GenSteps`, `224` non-nil), missing from `MAME_128`: `[]`, missing from `RESTORED_16`: `[]`, `Out of order: 0`.
- **Differential verifier (`diff-test-v3.rb`)**: `self() == QR.aj` byte-for-byte (`54,170 B`, `sha256: 126a0c37b07545182d95ebd060ad46241ff2033151fa9f061d66f89ae2f911f2`), **Phase 1 `exact=224, fails=0 / 224`**, **Phase 2 chain `check()`s `224 / 224` passed** (`final=856,020 B`).
- **6-generator consistency**: `cd src && rake` reproduces `QR.aj` (`54,170 B`, `126a0c37...`) cleanly inside the Ubuntu 26.04 Docker image; ROM guards fail loudly if `xa`, `z80asm`, or `uxnasm` is missing from `PATH`.
- **16-bit `< 64,000 B` ROM guards (`gen-aj.rb` + `vm-exec.rb`)**:
  - `6502 asm` (`xa` + `sim65`): `46,799 B / 65,012 B` (`spare = 18,213 B`, `0.02s`, `exact=true`)
  - `Z80 asm` (`z80asm` + `tnylpo`): `63,563 B / 64,991 B` (`spare = 1,428 B`, `0.01s`, `exact=true`)
  - `Uxntal` (`uxnasm` + `uxncli`): `57,371 B / 65,280 B` (`spare = 7,909 B`, `88.28%`, `0.11s`, `exact=true`)
- **Isolated `Ion -> J -> Janet` runtime check**:
  - Real `QR.aj` (`54,170 B`): `QR.ion` `291,503 B` -> `QR.ijs` `256,207 B` (exact) -> `QR.janet` `254,558 B` (exact).
  - `"QRCAN! "` canary `QR.aj` (`54,175 B`): `QR.ion` `297,823 B` -> `QR.ijs` `257,814 B` (exact) -> `QR.janet` `256,196 B` (exact).

---

## 3. Full Offline Proof & Canary Laps (`--network=none`, `USER qr` `uid=1001`)

1. **Lap 1 (`v3.1`, `make all -j 10000`)**:
   - **256 / 256 PASS** in **`2,319.8s` (`38.7 min`)**
   - `diff -s QR.aj QR2.aj` -> `Files QR.aj and QR2.aj are identical` (`54,170 B`)
   - `QR.jsfuck` -> `20,430,412 B`, strictly characters in `[][()!+\n]`
   - `SHA256SUMS` -> `256` entries generated and verified (`sha256: e821f3110dfa3cc19b6d9a19d0b49100e3490365cdb7cd62ab424ff7b1ea7214`, `sha256sum --quiet -c SHA256SUMS` exit `0`)
   - `Malbolge Unshackled` -> `U20_PARITY=OK`, `MB_STDIN_SAME=OK`: both `unshackled` (`Unshackled.c`) and `unshackled20` (`Unshackled-20.c`) produced byte-identical `QR.wl` (`198,440 B`, from `3,811,135 B` `QR.mb`) with both `< /dev/null` and 50-line canary stdin (`XYZ_CANARY_INPUT_999\n` * 50)
   - `make clean` check -> `0` leftover `QR.*` files (other than `QR.aj`) and `QR2.aj` removed (`14` non-QR toolchain cache entries left by `Makefile` clean targets: `.Random.seed`, `.build/`, `QR_dats.c`, `__pycache__/`, `build/`, `qrgleam/manifest.toml`)
2. **Lap 2 (`v3.1`, Verifier `"bad op "` -> `"QRCAN! "` engine canary in `src/engine_body.java`)**:
   - Rebuilt `QR.aj` (`54,175 B`, `sha256: 3ef81e77ff1a0003372894c55e22b860ea520227688e9cd8a44ee58eb4903a3c`, ROMs `46,904 B` / `63,673 B` / `57,324 B` all `< 64,000 B`)
   - Full `make all -j 10000` -> **PASS** in `2,339.4s` (`39.0 min`, `Files QR.aj and QR2.aj are identical`)
   - **`CANARY_STEP_HASH_CHANGED=256/256 UNCHANGED=0/256`**

---

## 4. Baseline `strace -f` Audit (`bb598ba`, prior to `v3.1` `IonShell` quoting patch)

- **Independent Verifier Lap C (`bb598ba`)**: `3,930` `strace` rows across full `make`, `0` foreign `QR.*` file reads, `SUMS_OK=256 FAILED=0` (`5,401s`), `ROUNDTRIP=OK`.
- **v3 Baseline `strace` Audit (`QR.aj` `ed0fbe68...`)**:
  - `Malbolge Unshackled` (`strace -f -e trace=read`): **`0` `read(0, ...)` syscalls** across `925` trace lines while emitting exact `QR.wl`.
  - `49` changed/restored/adjacent steps (`audit_strace.rb`): `49 / 49` exited `ok=true exact=true` with `0` CLI code injections (`44/49` zero noise, `5/49` benign runtime resolver/ESM probes under `--network=none`).

---

## 5. Honest Disclosed Limitations & Upstream Conventions

- **Classic 10-trit Malbolge caveat**: Because strict A–Z ordering puts the `M` section at several hundred kilobytes, step 127 uses `Malbolge Unshackled` rather than classic 10-trit Malbolge (whose `59,049`-cell limit remains unbroken in classic Malbolge).
- **10 Endoh-method exceptions** (inherited unchanged from `mame/quine-relay` under the Endoh Stamp):
  - Rule 1 (self-operand input): `sed` (`sed -E -f QR.sed QR.sed`), `Mustache` (`mustache QR.mustache QR.mustache`), `XSLT` (`<?xml-stylesheet ... href=''?>`, `xsltproc QR.xslt`)
  - Rule 2 (side file passed to next command): `Ook!` (`ruby vendor/ook-to-bf.rb QR.ook QR.ook.bf && ruby vendor/bf.rb QR.ook.bf`)
  - Rule 3 (env/flag shaping output): `bc` (`BC_LINE_LENGTH=4000000 bc -q`), `MiniZinc` (`--soln-sep ''`), `Promela` (`spin -T`), `Jq` (`jq -r -n -f QR.jq`)
  - Rules 4 / 6 (external echo or data decompression): `Execline` (`foreground { echo -n ... }`), `Gzip` (`gzip -cd QR.gz`)
  - Plus inherited `dc` exit-code mask (`dc QR.dc > QR.dhall || true`, marked `XXX` upstream).
- **11 stdlib zlib unpacker steps**: `C#`, `CoffeeScript`, `Elixir`, `F#`, `Go`, `Groovy`, `Mathics`, `PowerShell`, `Tcl`, `V`, `Zig`.
- **Memory**: `Shakespeare` (`gcc -O0` on `QR.spl.c`, `64,148,416 B`) peaks at `~21 GB` RSS (`>= 24 GB` VM RAM required).
