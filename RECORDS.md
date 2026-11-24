# Quine Relay 256 — Design & Counting Notes

These notes document how [exacortex/quine-relay-256](https://github.com/exacortex/quine-relay-256) relates to Yusuke Endoh's upstream [`mame/quine-relay`](https://github.com/mame/quine-relay) without altering upstream's conventions or standards.

## Overview: Upstream Base + Fork Additions (128 + 128 = 256)

| Relay | Steps | Composition | Order | Verification |
|---|---:|---|---|---|
| [`mame/quine-relay`](https://github.com/mame/quine-relay) *(upstream original, 2013–2026)* | **128** | All 128 steps of Endoh's Ubuntu 26.04 relay | Hand-tuned (`Ruby -> ... -> Ruby`) | Upstream CI, Ubuntu 26.04 (`QR.rb` 13,664 B) |
| **[exacortex/quine-relay-256](https://github.com/exacortex/quine-relay-256)** *(this fork)* | **256** | **128** upstream Endoh steps (`100%` preserved) + **128** standalone fork additions | **Strict A–Z** (`AspectJ -> Asymptote -> ... -> Zsh -> 6502 asm -> A+ -> ... -> AspectC++ -> AspectJ`) | Offline `--network=none` non-root `USER qr` lap (`38.7 min` / `2,319.8s`, `QR.aj` 54,170 B `sha256: 126a0c37...` == `QR2.aj`, **256/256** `SHA256SUMS`, dual-interpreter Malbolge Unshackled parity; [proof](proof/)) |

## Counting Lenses

Upstream `mame/quine-relay` counts **128** steps by Endoh's standard. Because different readers apply different distinctness criteria, this fork documents all three counts openly:

| Lens | Count | Notes |
|---|---:|---|
| **Relay Steps** *(upstream `mame/quine-relay` standard)* | **256** | All `128` Endoh steps intact + `128` standalone fork additions |
| **Strict Distinct Languages** *(1:1 distinct-language lens)* | **251** | Excludes the 5 upstream alternate formats/versions/encodings (`FORTRAN77` alongside Fortran90, `Gzip`, `JSFuck` alongside JavaScript, `Ook!` alongside Brainfuck, `WebAssembly (Binary format)` alongside WebAssembly Text) |
| **No-Superset / Dialect Lens** *(narrower classification)* | **246** | Further excludes 5 close extensions/dialects/family members (`AspectC++` on C++, `eC` & `nesC` on C, `rep` / librep close to Emacs Lisp, `Racket` in Scheme family) |

*(Caveat: step 127 uses `Malbolge Unshackled` rather than classic 10-trit Malbolge; see below.)*

## Upstream Preservation & Engineering Standards

Yusuke Endoh designed and maintained `mame/quine-relay` across more than a decade. Rather than rewriting or excluding parts of upstream's relay, this fork preserves all 128 upstream steps as-is while holding our 128 additions to canonical third-party upstream toolchains:

1. **All 128 / 128 Ubuntu 26.04 upstream steps remain intact (`mame/quine-relay`)**: Including `FORTRAN77`, `Gzip`, `JSFuck`, `Ook!`, and `WebAssembly (Binary format)`, plus **10 inherited upstream tool conventions** executed with upstream's commands:
   - **Self-operand input**: `sed` (`sed -E -f QR.sed QR.sed`), `Mustache` (`mustache QR.mustache QR.mustache`), `XSLT` (`<?xml-stylesheet ... href=''?>`, `xsltproc QR.xslt`)
   - **Side file passed to next command**: `Ook!` (`ruby vendor/ook-to-bf.rb QR.ook QR.ook.bf && ruby vendor/bf.rb QR.ook.bf`)
   - **Environment variable or flag shaping output**: `bc` (`BC_LINE_LENGTH=4000000 bc -q`), `MiniZinc` (`--soln-sep ''`), `Promela` (`spin -T`), `Jq` (`jq -r -n -f QR.jq`)
   - **External echo or data decompression**: `Execline` (`foreground { echo -n ... }`), `Gzip` (`gzip -cd QR.gz`)
   - **Exit-code suppression note**: `dc` (`dc QR.dc > QR.dhall || true`, marked `XXX` in `mame/quine-relay`) masks `dc`'s exit code.
2. **All 128 fork additions run on canonical third-party upstream toolchains (`this fork`)**:
   - **246 / 256 steps** pass all seven purity checks cleanly, including **128 / 128** of the fork's own additions (zero custom fork esolang runners).
   - **16 / 20 historical `mame` retirees** restored (`AspectC++`, `Parrot asm (PASM)`, `Boo`, `Maxima`, `Gri`, `UCBLogo`, `GNU Smalltalk`, `Julia`, `Dafny`, `Generator Scripting Language`, `nesC`, `Lisaac`, `eC`, `CDuce`, `A+`, `Falcon`).
   - **Malbolge Unshackled** (unbounded ternary Malbolge via CC0 `Unshackled.c` / `Unshackled-20.c`; dual-interpreter parity and stdin-invariance verified on empty and non-empty stdin, with `0` stdin reads in baseline `strace`) — noting candidly that classic 10-trit Malbolge's `59,049`-cell limit remains unbroken in strict A–Z ordering.
   - **111 additional standalone languages**, with zero duplicate dialects/shells, zero query-only formats, and zero custom fork esolang runners in `vendor/`.

[LANGUAGES.md](LANGUAGES.md) lists all **256 steps** (`128 mame/quine-relay + 128 this fork`) in exact A–Z run order.

## Reproducibility, Hardware / VM Limits & `vendor/` Inventory

- **Deterministic rebuild scope**: Inside the Ubuntu 26.04 Docker image (matching the image's system `zlib` and with `xa`, `z80asm`, and `uxnasm` required on `PATH` for the ROM guard), `cd src && rake` reproduces `QR.aj` (`54,170 B`, `126a0c37b07545182d95ebd060ad46241ff2033151fa9f061d66f89ae2f911f2`) byte-identically. Outside that image, differing host `zlib` versions still produce a valid `QR.aj`, though its compressed size may differ slightly.
- **16-bit 64 KiB VMs (`< 64,000 B` hard guard in `src/gen-aj.rb` and `src/vm-exec.rb`; raises if assembler is missing)**:
  - `6502 asm` (`xa` + `sim65`): `46,799 B` / `65,012 B` limit (`spare = 18,213 B`)
  - `Z80 asm` (`z80asm` + `tnylpo`): `63,563 B` / `64,991 B` limit (`spare = 1,428 B`)
  - `Uxntal` (`uxnasm` + `uxncli`): `57,371 B` / `65,280 B` limit (`spare = 7,909 B`)
- **Pure stdout / end-to-end integrity checks**: Verified with an offline non-root lap, an engine-mutation sensitivity test (`"bad op "` -> `"QRCAN! "` changing `256/256` intermediate step hashes while preserving `QR.aj == QR2.aj`), and a prior `strace` trace confirming `0` critical violations and `0` stdin reads in Malbolge.
- **Complete `vendor/` inventory**:
  - **13 byte-identical `mame/quine-relay` helpers**: `aheui.rb`, `ante.rb`, `bf.rb`, `blc.rb`, `false.rb`, `golfscript.rb`, `grass.rb`, `ook-to-bf.rb`, `subleq.rb`, `thue.rb`, `unlambda.rb`, `wasi-runtime.js`, `whitespace.rb`.
  - **Bundled upstream source / archives compiled by `vendor/Makefile`**: `ngnk-b9eeb91e.tar.gz` (K), `lci-0.10.5.zip` (LOLCODE), `npiet-1.3e.tar.gz` (Piet), `cfunge-0.9.0.tar.bz2` (Befunge), `Acme-Chef-1.03.tar.gz` (Chef), `spl-1.2.1.tar.gz` (Shakespeare), `lazyk.c` (Lazy K, upstream source with `RDSTACK_SIZE = 10,000,000`), `Velato_0_1.zip` (Velato), and `Unshackled.c` / `Unshackled-20.c` (Malbolge Unshackled).
  - Upstream `Taxi` compiled with its own `-DNO_GREETINGS` flag.
  - **Zero** custom fork esolang interpreters.
