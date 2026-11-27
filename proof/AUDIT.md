# Quine Relay 256 — Verification & Audit Summary

**Date:** 2026-11-26  
**Verified Snapshot:** v3.3 release (`QR.aj` `54,812 B` pure-code seed; `README.md`, `proof/*`, `assets/*`, and `tools/relay_ui.py` `--demo` display constants synced afterward to the measured Lap A outputs while `QR.aj`, `Makefile`, `Dockerfile`, `src/code-gen.rb`, `src/engine_body.java`, `src/gen-aj.rb`, `src/Rakefile`, and `vendor/*` remain byte-identical to the verified image)  
**Platform:** Ubuntu 26.04 container environment  
**Verified Image ID:** `sha256:6faf3aa8deb65ec6f9fa244e94182de95086d4786dafca4dc5cf018ef96d7853`

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
- `src/gen-aj.rb` + `src/engine_body.java` emit a lean pure-code **`54,812 B` (`53.5 KiB`)** `QR.aj` seed with zero ASCII-art padding (`214.1 B/step`), while `src/code-gen.rb` compacts `Asm6502` printable runs into `.byt "..."` strings (excluding `"`/`\`) and raises `ARM64Asm` `.ascii` chunks from `{1,60}` to `{1,4000}` — giving all three 16-bit 64 KiB ROMs `14.5–19.2 KiB` of spare headroom (`45,842 B` / `50,152 B` / `45,626 B`).
- Compresses `Julia` (`QR.jl`) with deterministic LZ77 (skipping `[`, `\`, `]` tokens so `Jasmin#check` bracket balance and downstream `dc` remain intact) and packs `Uxntal` (`QR.tal`, `136,874 B`) via raw-byte `@z` plus in-Uxn Base64 decoding (`45,626 B` ROM).
- Encodes `Ion` (`QR.ion`, `241,741 B` -> `QR.ijs` `210,558 B` -> `QR.janet` `209,156 B`) using variable concatenation across 4,000-byte single-quoted chunks, escaping all ten Redox `ion` syntax characters (`' \ $ @ [ ] { } ( )`) so escaped strings and harsh punctuation payloads propagate cleanly through Step 98 (`Ion -> J`).
- Default Docker `CMD` launches `tools/relay_ui.py` for an animated terminal visualizer with a bold `256` victory card on interactive TTY runs and hands off cleanly to unmodified `make check -j 10000` (with stdin detached to `/dev/null` on TTYs) when non-TTY (`CI=true`, `NO_COLOR`, `--plain`, or redirected stdout).

---

## 2. Deterministic Engine, Order, & 16-bit Hardware/VM Checks

- **Order & uniqueness**: `256` unique `RunSteps` (`225` `GenSteps`, `224` code-generating entries), all `128` upstream languages present, all `16` restored historical languages present, `Out of order: 0`.
- **Differential engine check**: `self() == QR.aj` byte-for-byte (`54,812 B` / `53.5 KiB` / `54.8 kB`, `sha256: 0c88b16fd93c05cc6d19af4b7d23abb2ca97eb622c3f01d933c57c0e1c92d778`), **Phase 1 `exact=224/224`, `fails=0`**, **Phase 2 Java chain `check()`s `224/224` passed** and Ruby-vs-Java parity (`QR.asy` = `710,423 B`).
- **Generator determinism**: `cd src && rake` inside the Ubuntu 26.04 Docker image reproduces `QR.aj` (`54,812 B`, `0c88b16f...`) byte-identically; ROM guards fail immediately if `xa`, `z80asm`, or `uxnasm` is missing from `PATH`.
- **16-bit `< 64,000 B` ROM limits (`src/gen-aj.rb` + `src/vm-exec.rb`)**:
  - `6502 asm` (`xa` + `sim65`): `45,842 B / 65,012 B` (`guard < 64,000 B`, `spare = 19,170 B`, `0.02s`, `exact=true`)
  - `Z80 asm` (`z80asm` + `tnylpo`): `50,152 B / 64,991 B` (`guard < 64,000 B`, `spare = 14,839 B`, `0.01s`, `exact=true`)
  - `Uxntal` (`uxnasm` + `uxncli`): `45,626 B / 65,280 B` (`guard < 64,000 B`, `spare = 19,654 B`, `0.12s`, `exact=true`)

---

## 3. Full Offline Proof, Harsh Mutation Canary, & `strace` Laps (`--network=none`, `USER qr`, `187.3 min` total)

1. **Lap A (`make all` + `SHA256SUMS` + UI checks, offline `--network=none`)**:
   - **256 / 256 PASS** in **`2,772s` (`46.2 min`)** (wrapper duration `2,787s`; `433,041,032 B` / `413.0 MiB` total source bytes across all 256 steps)
   - `diff -s QR.aj QR2.aj` -> `Files QR.aj and QR2.aj are identical` (`54,812 B`)
   - `SHA256SUMS` -> `256` entries generated (`sha256: 4b8da55cac5c2c78def15b286288111f841582e6a062da4210dfa7312b20e241`), verified **256 / 256 PASS** in Lap C
   - Visualizer UI checks: `python3 tools/relay_ui.py < /dev/null` non-TTY fallback **PASS** (`NONTTY_RC=0`, running unmodified `make check` -> `Files QR.aj and QR2.aj are identical`); `script -qec "python3 tools/relay_ui.py --demo --fast" /dev/null` real PTY demo **PASS** (`PTY_DEMO_RC=0`)
   - Supplemental artifact checks verified on v3.3 Lap C outputs (`trace/qr-files.tar`):
     - `QR.jsfuck` -> `16,740,100 B`, `0` characters outside `[]()!+\n`
     - `Malbolge Unshackled` -> both `unshackled` (`Unshackled.c`) and `unshackled20` (`Unshackled-20.c`) produced byte-identical `QR.wl` (`161,404 B`, from `3,080,162 B` `QR.mb`) on both empty and non-empty stdin (`MALBOLGE_PARITY=OK`)
2. **Lap B (In-image rebuild + harsh engine-mutation test: `"bad op "` -> `"Q'$@{( "` in `src/engine_body.java`)**:
   - In-image rebuild (`cd src && rake`) produced byte-identical `QR.aj` (`REGEN_IDENTICAL=YES`, `sha256: 0c88b16f...`).
   - Mutated canary `QR.aj` (`54,815 B`, `sha256: 8971e382122d7421cf94a29738b0594c8f581ad02f5c661a33a092854a4cba25`, `CANARY_IN_QR_AJ=1`; ROM guards `45,784 B` / `49,997 B` / `45,443 B`, all `< 64,000 B`)
   - Full `make` -> **PASS** in **`2,783s` (`46.4 min`)**, `CANARY_ROUNDTRIP=OK`, `QR2.aj` preserves the canary marker (`CANARY_QR2_HAS_MARK=1`)
   - **256 / 256 intermediate step file SHA-256 hashes changed** (`STEP_HASH_CHANGED=256 UNCHANGED=0 MISSING=0`)
3. **Lap C (Full-build `strace` audit on `qr256-v33-trace`)**:
   - Full `make` -> **PASS** in **`5,620s` (`93.7 min`)**, `ROUNDTRIP=OK`, **256 / 256** `SHA256SUMS` match (`SUMS_OK=256 FAILED=0`)
   - `2,472` `strace` audit entries across `256` steps (`256` Makefile rules; `READ-FOREIGN: 851`, `WRITE-ODD: 1059`, `RENAME: 562`): **`0` critical violations** (all `128 / 128` fork additions verified pure stdout with no CLI code or file reads; upstream tool invocation notes are listed in Section 4 below)
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
- **Memory & peak file size**: `Piet` (`QR.ppm`) peaks at `165,899,154 B` (`158.21 MiB`); `Shakespeare` (`gcc -O0` on `QR.spl.c` compiled from `28,988,217 B` `QR.spl`) peaks near `~21 GB` RSS (`>= 24 GB` VM RAM required).
