# Quine Relay 256 — Verification & Audit Summary

**Date:** 2026-11-25  
**Verified Snapshot:** v3.2 release snapshot (from commit `e9334ba`, prior to final doc/proof log updates)  
**Platform:** Ubuntu 26.04 container environment  
**Verified Image ID:** `sha256:1a67fe8da35fa8c01cc0a26c473f11bed2e1f5af20619415818974aab67468e2`

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
- `src/qr_matrix.rb` + `src/gen-aj.rb` pack `QR.aj` into an edge-to-edge **29×29 ISO 18004 Version 3 EC-L scannable QR code (`522×261`)** encoding `https://github.com/exacortex/quine-relay-256`.
- `src/code-gen.rb` compacts `Asm6502` printable runs into `.byt "..."` strings (excluding `"`/`\`) and raises `ARM64Asm` `.ascii` chunks from `{1,60}` to `{1,4000}`, keeping `Z80 asm` (`61,603 B`) and `Uxntal` (`55,661 B`) well under the 64 KiB ceiling despite the larger QR-shaped seed.
- Compresses `Julia` (`QR.jl`) with deterministic LZ77 (skipping `[`, `\`, `]` tokens so `Jasmin#check` bracket balance and downstream `dc` remain intact) and packs `Uxntal` (`QR.tal`) via raw-byte `@z` plus in-Uxn Base64 decoding (`55,661 B` ROM).
- Encodes `Ion` (`QR.ion`, `287,835 B` -> `QR.ijs` `250,174 B` -> `QR.janet` `248,591 B`) using variable concatenation across 4,000-byte single-quoted chunks, escaping all ten Redox `ion` syntax characters (`' \ $ @ [ ] { } ( )`) so escaped strings and harsh punctuation payloads propagate cleanly through Step 98 (`Ion -> J`).
- Default Docker `CMD` launches `tools/relay_ui.py` for an animated terminal visualizer on interactive TTY runs and hands off cleanly to unmodified `make check -j 10000` when non-TTY (`CI=true`, `NO_COLOR`, `--plain`, or redirected stdout).

---

## 2. Deterministic Engine, Order, & 16-bit Hardware/VM Checks

- **Order & uniqueness**: `256` unique `RunSteps` (`225` `GenSteps`, `224` code-generating entries), all `128` upstream languages present, all `16` restored historical languages present, `Out of order: 0`.
- **Differential engine check**: `self() == QR.aj` byte-for-byte (`133,101 B` / `130.0 KiB` / `133.1 kB`, `sha256: 85ae8e2a56c20d8c3ad41471e3d48c083cc29792123ce4b093cdd34024c5e1ec`), **Phase 1 `exact=224/224`, `fails=0`**, **Phase 2 Java chain `check()`s `224/224` passed** and Ruby-vs-Java parity (`QR.asy` = `836,011 B`).
- **Generator determinism**: `cd src && rake` inside the Ubuntu 26.04 Docker image reproduces `QR.aj` (`133,101 B`, `85ae8e2a...`) byte-identically; ROM guards fail immediately if `xa`, `z80asm`, or `uxnasm` is missing from `PATH`.
- **16-bit `< 64,000 B` ROM limits (`src/gen-aj.rb` + `src/vm-exec.rb`)**:
  - `6502 asm` (`xa` + `sim65`): `57,006 B / 65,012 B` (`guard < 64,000 B`, `spare = 8,006 B`, `exact=true`)
  - `Z80 asm` (`z80asm` + `tnylpo`): `61,603 B / 64,991 B` (`guard < 64,000 B`, `spare = 3,388 B`, `exact=true`)
  - `Uxntal` (`uxnasm` + `uxncli`): `55,661 B / 65,280 B` (`guard < 64,000 B`, `spare = 9,619 B`, `exact=true`)

---

## 3. Full Offline Proof, Harsh Mutation Canary, & `strace` Laps (`--network=none`, `USER qr`, `161.2 min` total)

1. **Lap A (`make all` + `SHA256SUMS` + UI checks, offline `--network=none`)**:
   - **256 / 256 PASS** in **`2,284s` (`38.1 min`)** (total Lap A wrapper duration `2,298s`)
   - `diff -s QR.aj QR2.aj` -> `Files QR.aj and QR2.aj are identical` (`133,101 B`)
   - `SHA256SUMS` -> `256` entries generated (`sha256: 04d4aa5a07864d95a7b7b941d773659a40b76eab316a561dc50d843252bca1be`), verified **256 / 256 PASS** in Lap C
   - Visualizer UI checks: `python3 tools/relay_ui.py < /dev/null` non-TTY fallback **PASS** (`NONTTY_RC=0`, running unmodified `make check` -> `Files QR.aj and QR2.aj are identical`); `script -qec "python3 tools/relay_ui.py --demo --fast" /dev/null` real PTY demo **PASS** (`PTY_DEMO_RC=0`)
   - Supplemental artifact checks verified on v3.2 Lap C outputs (`qr-files.tar`):
     - `QR.jsfuck` -> `19,881,169 B`, `0` characters outside `[]()!+\n`
     - `Malbolge Unshackled` -> both `unshackled` (`Unshackled.c`) and `unshackled20` (`Unshackled-20.c`) produced byte-identical `QR.wl` (`192,900 B`, from `3,727,660 B` `QR.mb`) on both empty and non-empty stdin (`MALBOLGE_PARITY=OK`)
2. **Lap B (In-image rebuild + harsh engine-mutation test: `"bad op "` -> `"Q'$@{( "` in `src/engine_body.java`)**:
   - In-image rebuild (`cd src && rake`) produced byte-identical `QR.aj` (`REGEN_IDENTICAL=YES`, `sha256: 85ae8e2a...`).
   - Mutated canary `QR.aj` (`133,101 B`, `sha256: 09e1ac7c543684609cba8127d3b05fd81bcc134a860159dc85406627295fea5a`, `CANARY_IN_QR_AJ=1`; ROM guards `56,994 B` / `61,695 B` / `55,743 B`, all `< 64,000 B`)
   - Full `make` -> **PASS** in **`2,316s` (`38.6 min`)**, `CANARY_ROUNDTRIP=OK`, `QR2.aj` preserves the canary marker (`CANARY_QR2_HAS_MARK=1`)
   - **256 / 256 intermediate step file SHA-256 hashes changed** (`STEP_HASH_CHANGED=256 UNCHANGED=0 MISSING=0`)
3. **Lap C (Full-build `strace` audit on `qr256-v32-trace`)**:
   - Full `make` -> **PASS** in **`5,013s` (`83.6 min`)**, `ROUNDTRIP=OK`, **256 / 256** `SHA256SUMS` match (`SUMS_OK=256 FAILED=0`)
   - `2,474` `strace` audit entries across `256` steps (`256` Makefile rules; `READ-FOREIGN: 852`, `WRITE-ODD: 1060`, `RENAME: 562`): **`0` critical violations** (all `128 / 128` fork additions verified pure stdout with no CLI code or file reads; upstream tool invocation notes are listed in Section 4 below)
   - **`12` benign cross-step `QR*`/`qr*` accesses** (excluding Zig stdlib `std/*/sqrt.zig`):
     - Persistent `.NET` `VBCSCompiler` build server started during `C#` later compiling `Dafny`'s code (4 reads attributed to `C#`, 3 to `Dafny`)
     - `Scala` probing for a file named `QR`
     - `.NET` (`C#`, `Visual Basic`) and `Gleam` steps reading their own committed project files (`qr_cs/QR.csproj`, `qr_vb/QR.vbproj`, `qrgleam/gleam.toml`)
     - `make`'s final `diff` check reading `QR.aj`

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
- **Memory**: `Shakespeare` (`gcc -O0` on `QR.spl.c` compiled from `35,054,824 B` `QR.spl`) peaks near `~21 GB` RSS (`>= 24 GB` VM RAM required).
