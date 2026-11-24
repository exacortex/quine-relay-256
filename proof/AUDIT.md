# Quine Relay 256 — Verification & Audit Summary

**Date:** 2026-11-24  
**Platform:** Ubuntu 26.04 container environment  
**Verified Image ID:** `sha256:78891375f453f39e6b6899d0504e7244a584931ca4f7b139cc005938af0c60ef`

---

## 1. Accounting (128 + 128 = 256)

This fork preserves **100%** of Yusuke Endoh's 128-step Ubuntu 26.04 relay unchanged and pairs it with **128** additions in this fork running on canonical third-party upstream compilers and interpreters:

| Component | Count | Status |
|---|---:|---|
| `mame/quine-relay` Ubuntu 26.04 base | **128** | **128 / 128 preserved**, including `FORTRAN77`, `Gzip`, `JSFuck`, `Ook!`, and `WebAssembly (Binary format)` |
| Restored historical `mame/quine-relay` languages | **16** | `A+`, `AspectC++`, `Boo`, `CDuce`, `Dafny`, `eC`, `Falcon`, `Generator Scripting Language`, `GNU Smalltalk`, `Gri`, `Julia`, `Lisaac`, `Maxima`, `nesC`, `Parrot asm (PASM)`, `UCBLogo` |
| Unbounded Malbolge (`Malbolge Unshackled`) | **1** | CC0 `Unshackled.c` / `Unshackled-20.c` (dual-interpreter parity and stdin-invariance verified; `0` stdin reads in prior `strace` trace) |
| Additional third-party upstream languages | **111** | Canonical upstream compilers/interpreters only |
| **Total (`RunSteps`)** | **256** | **Strict A–Z** (`Out of order: 0`, entry `#1 AspectJ`, wrap `#244 6502 asm`) |

Counting lenses documented in [RECORDS.md](../RECORDS.md): **256** relay steps (`mame/quine-relay` standard) / **251** strict distinct languages / **246** under a narrower no-superset/dialect lens.

### Key Engineering Details
- Every entry in `vendor/` is either inherited from `mame/quine-relay` (all 13 helper scripts match upstream byte-for-byte) or a canonical third-party upstream source/reference implementation (`0` custom fork esolang interpreters).
- Uses upstream `gfortran` (`FORTRAN77` -> `Fortran90`), `gzip -cd` (`Gzip`), pure `[]()!+` charset `JSFuck`, `vendor/ook-to-bf.rb` + `vendor/bf.rb` (`Ook!`), `vendor/wasi-runtime.js` + `wat2wasm` (`WebAssembly`), and `vendor/unlambda.rb` (`Unlambda`).
- Compresses `Julia` (`QR.jl`) with deterministic LZ77 (skipping `[`, `\`, `]` tokens so `Jasmin#check` bracket balance and downstream `dc` remain intact) and packs `Uxntal` (`QR.tal`) via raw-byte `@z` plus in-Uxn Base64 decoding (`57,371 B` ROM).
- Encodes `Ion` (`QR.ion`) using variable concatenation across 4,000-byte single-quoted chunks, escaping Redox `ion` syntax characters (`' \ $ @ [ ] { } ( )`) so escaped strings and arbitrary engine-mutation payloads propagate cleanly through Step 98 (`Ion -> J`).

---

## 2. Deterministic Engine, Order, & 16-bit Hardware/VM Checks

- **Order & uniqueness**: `256` unique `RunSteps` (`225` `GenSteps`, `224` code-generating entries), all `128` upstream steps present, all `16` restored historical languages present, `Out of order: 0`.
- **Differential engine check**: `self() == QR.aj` byte-for-byte (`54,170 B`, `sha256: 126a0c37b07545182d95ebd060ad46241ff2033151fa9f061d66f89ae2f911f2`), **Phase 1 `exact=224, fails=0 / 224`**, **Phase 2 Java chain `check()`s `224 / 224` passed** (`final=856,020 B`).
- **Generator determinism**: `cd src && rake` reproduces `QR.aj` (`54,170 B`, `126a0c37...`) byte-identically inside the Ubuntu 26.04 Docker image; ROM guards fail immediately if `xa`, `z80asm`, or `uxnasm` is missing from `PATH`.
- **16-bit `< 64,000 B` ROM limits (`src/gen-aj.rb` + `src/vm-exec.rb`)**:
  - `6502 asm` (`xa` + `sim65`): `46,799 B / 65,012 B` (`spare = 18,213 B`, `0.02s`, `exact=true`)
  - `Z80 asm` (`z80asm` + `tnylpo`): `63,563 B / 64,991 B` (`spare = 1,428 B`, `0.01s`, `exact=true`)
  - `Uxntal` (`uxnasm` + `uxncli`): `57,371 B / 65,280 B` (`spare = 7,909 B`, `88.28%`, `0.11s`, `exact=true`)
- **Isolated `Ion -> J -> Janet` verification**:
  - Standard `QR.aj` (`54,170 B`): `QR.ion` `291,503 B` -> `QR.ijs` `256,207 B` (exact) -> `QR.janet` `254,558 B` (exact).
  - Mutated engine `QR.aj` (`54,175 B`): `QR.ion` `297,823 B` -> `QR.ijs` `257,814 B` (exact) -> `QR.janet` `256,196 B` (exact).

---

## 3. Full Offline Proof & Engine-Mutation Laps (`--network=none`, `USER qr` `uid=1001`)

1. **Lap 1 (Full offline build, `make all -j 10000`)**:
   - **256 / 256 PASS** in **`2,319.8s` (`38.7 min`)**
   - `diff -s QR.aj QR2.aj` -> `Files QR.aj and QR2.aj are identical` (`54,170 B`)
   - `QR.jsfuck` -> `20,430,412 B`, strictly characters in `[][()!+\n]`
   - `SHA256SUMS` -> `256` entries generated and verified (`sha256: e821f3110dfa3cc19b6d9a19d0b49100e3490365cdb7cd62ab424ff7b1ea7214`, `sha256sum --quiet -c SHA256SUMS` exit `0`)
   - `Malbolge Unshackled` -> both `unshackled` (`Unshackled.c`) and `unshackled20` (`Unshackled-20.c`) produced byte-identical `QR.wl` (`198,440 B`, from `3,811,135 B` `QR.mb`) on both `< /dev/null` and 50-line non-empty stdin
   - `make clean` check -> `0` leftover `QR.*` files (other than `QR.aj`) and `QR2.aj` removed (`14` compiler/runtime cache entries left outside `clean` targets: `.Random.seed`, `.build/`, `QR_dats.c`, `__pycache__/`, `build/`, `qrgleam/manifest.toml`)
2. **Lap 2 (Engine-mutation sensitivity test: `"bad op "` -> `"QRCAN! "` in `src/engine_body.java`)**:
   - Rebuilt `QR.aj` (`54,175 B`, `sha256: 3ef81e77ff1a0003372894c55e22b860ea520227688e9cd8a44ee58eb4903a3c`, ROMs `46,904 B` / `63,673 B` / `57,324 B` all `< 64,000 B`)
   - Full `make all -j 10000` -> **PASS** in `2,339.4s` (`39.0 min`, `Files QR.aj and QR2.aj are identical`)
   - **256 / 256 intermediate step file SHA-256 hashes changed** (`0` unchanged)

---

## 4. Prior `strace -f` Audit (Recorded Before Final `IonShell` Quoting Update)

- **Full-lap `strace` trace**: `3,930` trace rows across a full `make` run, `0` cross-step `QR.*` reads, `256 / 256` `SHA256SUMS` verified (`5,401s`).
- **Focused `strace` check**:
  - `Malbolge Unshackled` (`strace -f -e trace=read`): `0` `read(0, ...)` syscalls across `925` trace lines while emitting exact `QR.wl`.
  - `49` sampled steps: `49 / 49` exited `0` with exact byte-for-byte stdout (`44/49` zero noise, `5/49` benign runtime resolver/`package.json` lookups under `--network=none`).

---

## 5. Honest Disclosed Limitations & Upstream Conventions

- **Classic 10-trit Malbolge caveat**: Because strict A–Z ordering puts the `M` section at several hundred kilobytes, step 127 uses `Malbolge Unshackled` rather than classic 10-trit Malbolge (whose `59,049`-cell limit remains unbroken in classic Malbolge).
- **10 inherited upstream tool conventions** (carried verbatim from `mame/quine-relay`):
  - **Self-operand input**: `sed` (`sed -E -f QR.sed QR.sed`), `Mustache` (`mustache QR.mustache QR.mustache`), `XSLT` (`<?xml-stylesheet ... href=''?>`, `xsltproc QR.xslt`)
  - **Side file passed to next command**: `Ook!` (`ruby vendor/ook-to-bf.rb QR.ook QR.ook.bf && ruby vendor/bf.rb QR.ook.bf`)
  - **Environment variable or flag shaping output**: `bc` (`BC_LINE_LENGTH=4000000 bc -q`), `MiniZinc` (`--soln-sep ''`), `Promela` (`spin -T`), `Jq` (`jq -r -n -f QR.jq`)
  - **External echo or data decompression**: `Execline` (`foreground { echo -n ... }`), `Gzip` (`gzip -cd QR.gz`)
  - **Inherited exit-code note**: `dc` (`dc QR.dc > QR.dhall || true`, marked `XXX` upstream).
- **11 stdlib zlib unpacker steps**: `C#`, `CoffeeScript`, `Elixir`, `F#`, `Go`, `Groovy`, `Mathics`, `PowerShell`, `Tcl`, `V`, `Zig`.
- **Memory**: `Shakespeare` (`gcc -O0` on `QR.spl.c`, `64,148,416 B`) peaks at `~21 GB` RSS (`>= 24 GB` VM RAM required).
