# Quine Relay 256 — Verification & Audit Summary

**Date:** 2026-11-24  
**Verified Commit:** `e1a0e4b` *(only docs and proof logs updated since)*  
**Platform:** Ubuntu 26.04 container environment  
**Verified Image ID:** `sha256:da026b1b4c6e26e0c1f45b4ef9c28672bb1154bc3c3e72a58cfa8475e3bc20d4`

---

## 1. Accounting (128 + 128 = 256)

This fork keeps all **128** languages of Yusuke Endoh's Ubuntu 26.04 `mame/quine-relay` on the same upstream tools and pairs them with **128** additions in this fork running on canonical third-party upstream compilers and interpreters. Every step's generated payload was rewritten for strict A–Z ordering, and 11 Makefile commands differ in flags or build layout from upstream (`AspectJ`, `ALGOL 68`, `C#`, `F#`, `Visual Basic`, `FORTRAN77`, `Lazy K`, `Nim`, `Objective-C`, `Piet`, and `Shakespeare`).

| Component | Count | Status |
|---|---:|---|
| `mame/quine-relay` Ubuntu 26.04 base | **128** | All **128** languages run on the same upstream tools |
| Restored historical `mame/quine-relay` languages | **16** | `A+`, `AspectC++`, `Boo`, `CDuce`, `Dafny`, `eC`, `Falcon`, `Generator Scripting Language`, `GNU Smalltalk`, `Gri`, `Julia`, `Lisaac`, `Maxima`, `nesC`, `Parrot asm (PASM)`, `UCBLogo` |
| Unbounded Malbolge (`Malbolge Unshackled`) | **1** | CC0 `Unshackled.c` / `Unshackled-20.c` (dual-interpreter parity and stdin-invariance verified) |
| Additional third-party upstream languages | **111** | Canonical upstream compilers/interpreters only |
| **Total (`RunSteps`)** | **256** | **Strict A–Z** (`Out of order: 0`, entry `#1 AspectJ`, wrap `#244 6502 asm`) |

Every step is listed openly in [LANGUAGES.md](../LANGUAGES.md) with full composition and `vendor/` provenance in [RECORDS.md](../RECORDS.md).

### Key Engineering Details
- Every entry in `vendor/` is either inherited from `mame/quine-relay` (all 13 helper scripts match upstream byte-for-byte) or a canonical third-party upstream source/reference implementation (`0` custom fork esolang interpreters).
- Uses upstream `gfortran` (`FORTRAN77` -> `Fortran90`), `gzip -cd` (`Gzip`), pure `[]()!+` charset `JSFuck`, `vendor/ook-to-bf.rb` + `vendor/bf.rb` (`Ook!`), `vendor/wasi-runtime.js` + `wat2wasm` (`WebAssembly`), and `vendor/unlambda.rb` (`Unlambda`).
- Compresses `Julia` (`QR.jl`) with deterministic LZ77 (skipping `[`, `\`, `]` tokens so `Jasmin#check` bracket balance and downstream `dc` remain intact) and packs `Uxntal` (`QR.tal`) via raw-byte `@z` plus in-Uxn Base64 decoding (`57,371 B` ROM).
- Encodes `Ion` (`QR.ion`) using variable concatenation across 4,000-byte single-quoted chunks, escaping all ten Redox `ion` syntax characters (`' \ $ @ [ ] { } ( )`) so escaped strings and harsh punctuation payloads propagate cleanly through Step 98 (`Ion -> J`).

---

## 2. Deterministic Engine, Order, & 16-bit Hardware/VM Checks

- **Order & uniqueness**: `256` unique `RunSteps` (`225` `GenSteps`, `224` code-generating entries), all `128` upstream languages present, all `16` restored historical languages present, `Out of order: 0`.
- **Differential engine check**: `self() == QR.aj` byte-for-byte (`54,170 B` / `52.9 KiB` / `54.2 kB`, `sha256: 126a0c37b07545182d95ebd060ad46241ff2033151fa9f061d66f89ae2f911f2`), **Phase 1 `exact=224, fails=0 / 224`**, **Phase 2 Java chain `check()`s `224 / 224` passed** (`final=856,020 B`).
- **Generator determinism**: `cd src && rake` inside the Ubuntu 26.04 Docker image reproduces `QR.aj` (`54,170 B`, `126a0c37...`) byte-identically; ROM guards fail immediately if `xa`, `z80asm`, or `uxnasm` is missing from `PATH`.
- **16-bit `< 64,000 B` ROM limits (`src/gen-aj.rb` + `src/vm-exec.rb`)**:
  - `6502 asm` (`xa` + `sim65`): `46,799 B / 65,012 B` (`spare = 18,213 B`, `0.02s`, `exact=true`)
  - `Z80 asm` (`z80asm` + `tnylpo`): `63,563 B / 64,991 B` (`spare = 1,428 B`, `0.01s`, `exact=true`)
  - `Uxntal` (`uxnasm` + `uxncli`): `57,371 B / 65,280 B` (`spare = 7,909 B`, `88.28%`, `0.11s`, `exact=true`)
- **Isolated `Ion -> J -> Janet` runtime check**: `QR.aj` (`54,170 B`) -> `QR.ion` `291,503 B` -> `QR.ijs` `256,207 B` (exact) -> `QR.janet` `254,558 B` (exact).

---

## 3. Full Offline Proof, Harsh Mutation Canary, & `strace` Laps (`e1a0e4b`, `--network=none`, `USER qr`)

1. **Lap A (`make check`, offline `--network=none`)**:
   - **256 / 256 PASS** in **`2,311s` (`38.5 min`)**
   - `diff -s QR.aj QR2.aj` -> `Files QR.aj and QR2.aj are identical` (`54,170 B`)
   - `SHA256SUMS` -> **256 / 256 PASS** (`sha256: e821f3110dfa3cc19b6d9a19d0b49100e3490365cdb7cd62ab424ff7b1ea7214`)
   - Supplemental checks on same `QR.aj` (`126a0c37...`):
     - `QR.jsfuck` -> `20,430,412 B`, strictly characters in `[][()!+\n]`
     - `Malbolge Unshackled` -> both `unshackled` (`Unshackled.c`) and `unshackled20` (`Unshackled-20.c`) produced byte-identical `QR.wl` (`198,440 B`, from `3,811,135 B` `QR.mb`) on both empty and non-empty stdin
     - `make clean` -> `0` leftover `QR.*` files (other than `QR.aj`) and `QR2.aj` removed (`14` compiler/runtime cache entries left outside `clean` targets: `.Random.seed`, `.build/`, `QR_dats.c`, `__pycache__/`, `build/`, `qrgleam/manifest.toml`)
2. **Lap B (In-image rebuild + harsh engine-mutation test: `"bad op "` -> `"Q'$@{( "` in `src/engine_body.java`)**:
   - In-image rebuild of unmodified `src/` produced byte-identical `QR.aj` (`126a0c37...`).
   - Mutated `QR.aj` (`54,175 B`, `sha256: 8be3be7f6a96c6edf0d732d5731ad8c648d56baaa503f52186e74a8583ba0380`; ROM guards `46,857 B` / `63,575 B` / `57,272 B` all `< 64,000 B`)
   - Full `make` -> **PASS** in **`2,408s` (`40.1 min`)**, `QR2.aj` matches mutated `QR.aj` with the canary marker present
   - **256 / 256 intermediate step file SHA-256 hashes changed** (`0` unchanged, `0` missing)
3. **Lap C (Full-build `strace` audit on `e1a0e4b`)**:
   - Full `make` -> **PASS** in **`5,045s` (`84.1 min`)**, `ROUNDTRIP=OK`, `256 / 256` `SHA256SUMS` match
   - `2,474` `strace` audit entries across `256` steps (`256` Makefile rules): **`0` critical violations** (all `128 / 128` fork additions verified pure stdout with no CLI code or file reads; upstream tool invocation notes are listed in Section 4 below)
   - **`12` cross-step `QR*`/`qr*` file accesses**, all verified harmless:
     - Persistent `.NET` `VBCSCompiler` build server started during `C#` later compiling `Dafny`'s code (attributed to `C#`)
     - `Scala` probing for a file named `QR`
     - `.NET` and `Gleam` steps reading their own committed project files
     - `make`'s final `diff` check

---

## 4. Technical Notes & Upstream Tool Invocations

- **Classic 10-trit Malbolge caveat**: Because strict A–Z ordering puts the `M` section at several hundred kilobytes, step 127 uses `Malbolge Unshackled` rather than classic 10-trit Malbolge (whose `59,049`-cell limit remains unbroken in classic Malbolge).
- **Upstream `mame/quine-relay` tool invocations (documented for auditors inspecting the Makefile)**:
  - **Self-operand input**: `sed` (`sed -E -f QR.sed QR.sed`), `Mustache` (`mustache QR.mustache QR.mustache`), `XSLT` (`<?xml-stylesheet ... href=''?>`, `xsltproc QR.xslt`)
  - **Side file passed to next command**: `Ook!` (`ruby vendor/ook-to-bf.rb QR.ook QR.ook.bf && ruby vendor/bf.rb QR.ook.bf`)
  - **Environment variable or flag shaping output**: `bc` (`BC_LINE_LENGTH=4000000 bc -q`), `MiniZinc` (`--soln-sep ''`), `Promela` (`spin -T`), `Jq` (`jq -r -n -f QR.jq`)
  - **External echo or data decompression**: `Execline` (`foreground { echo -n ... }` here; upstream uses `echo "..."`), `Gzip` (`gzip -cd QR.gz`)
  - **Inherited exit-code note**: `dc` (`dc QR.dc > QR.dhall || true`, marked `XXX` upstream).
- **11 stdlib zlib unpacker steps**: `C#`, `CoffeeScript`, `Elixir`, `F#`, `Go`, `Groovy`, `Mathics`, `PowerShell`, `Tcl`, `V`, `Zig`.
- **Memory**: `Shakespeare` (`gcc -O0` on `QR.spl.c`, `64,148,416 B`) peaks at `~21 GB` RSS (`>= 24 GB` VM RAM required).
