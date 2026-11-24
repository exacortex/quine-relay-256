# Quine Relay 256 — Design & Counting Notes

These notes document how [exacortex/quine-relay-256](https://github.com/exacortex/quine-relay-256) relates to Yusuke Endoh's upstream [`mame/quine-relay`](https://github.com/mame/quine-relay) without changing or second-guessing upstream's own standard.

## Overview: Upstream Base + Fork Additions (128 + 128 = 256)

| Relay | Steps | Composition | Order | Verification |
|---|---:|---|---|---|
| [`mame/quine-relay`](https://github.com/mame/quine-relay) *(upstream original, 2013–2026)* | **128** | All 128 steps of Endoh's Ubuntu 26.04 relay | Hand-tuned (`Ruby -> ... -> Ruby`) | Upstream CI, Ubuntu 26.04 (`QR.rb` 13,664 B) |
| **[exacortex/quine-relay-256](https://github.com/exacortex/quine-relay-256)** *(this fork, v3 "The Endoh Stamp")* | **256** | **128** upstream Endoh steps (`100%` preserved) + **128** standalone fork additions | **Strict A–Z** (`AspectJ -> Asymptote -> ... -> Zsh -> 6502 asm -> A+ -> ... -> AspectC++ -> AspectJ`) | Offline `--network=none` non-root `USER qr` lap (`39.9 min` / `2,396.8s`, `QR.aj` 54,047 B `sha256: ed0fbe68...` == `QR2.aj`, **256/256** `SHA256SUMS`, `U20_PARITY=OK`; [proof](proof/)) |

## Counting Table (Rule 7 Disclosure)

Upstream `mame/quine-relay` counts **128** steps by Endoh's own standard. For this fork, different readers apply different distinctness lenses:

| Lens | Count | Notes |
|---|---:|---|
| **Relay Steps** *(Endoh's standard / Endoh Stamp)* | **256** | All `128` Endoh steps intact + `128` standalone fork additions |
| **Strict Distinct Languages** *(1:1 distinct-language lens)* | **251** | Excludes the 5 Endoh-Stamp alternate formats/versions/encodings (`FORTRAN77` alongside Fortran90, `Gzip`, `JSFuck` alongside JavaScript, `Ook!` alongside Brainfuck, `WebAssembly (Binary format)` alongside WebAssembly Text) |
| **No-Superset / Dialect Lens** *(judgment-call exclusions)* | **246** | Further excludes 5 close extensions/dialects/family members (`AspectC++` on C++, `eC` & `nesC` on C, `rep` / librep close to Emacs Lisp, `Racket` in Scheme family) |

*(Caveat: step 127 uses `Malbolge Unshackled` rather than classic 10-trit Malbolge; see below.)*

## "The Endoh Stamp" & Endoh-Method Exceptions

Yusuke Endoh invented and hand-crafted Quine Relay across more than a decade. Rather than imposing an external deduplication rule back onto upstream:

1. **All 128 / 128 Ubuntu 26.04 upstream steps stay intact (`mame (Endoh Stamp)`)**: Including `FORTRAN77`, `Gzip`, `JSFuck`, `Ook!`, and `WebAssembly (Binary format)`, plus **10 Endoh-method exceptions** (all inherited verbatim from `mame/quine-relay` and run with Endoh's own commands):
   - **Rule 1 (self-operand input)**: `sed` (`sed -E -f QR.sed QR.sed`), `Mustache` (`mustache QR.mustache QR.mustache`), `XSLT` (`<?xml-stylesheet ... href=''?>`, `xsltproc QR.xslt`)
   - **Rule 2 (side file read by next command)**: `Ook!` (`ruby vendor/ook-to-bf.rb QR.ook QR.ook.bf && ruby vendor/bf.rb QR.ook.bf`)
   - **Rule 3 (env/flag shaping output)**: `bc` (`BC_LINE_LENGTH=4000000 bc -q`), `MiniZinc` (`--soln-sep ''`), `Promela` (`spin -T`), `Jq` (`jq -r -n -f QR.jq`)
   - **Rules 4 / 6 (external echo or data decompression)**: `Execline` (`foreground { echo -n ... }`), `Gzip` (`gzip -cd QR.gz`)
   - **Exit-code suppression note**: `dc` (`dc QR.dc > QR.dhall || true`, marked `XXX` in `mame/quine-relay`) hides `dc`'s exit code.
2. **Every one of our 128 fork additions stands on its own canonical third-party upstream toolchain (`this fork`)**:
   - **246 / 256 steps** pass all 7 static purity rules cleanly, including **128 / 128** of our fork additions (zero fork-side tool accommodations, zero custom fork runners).
   - **16 / 20 historical `mame` retirees** restored (`AspectC++`, `Parrot asm (PASM)`, `Boo`, `Maxima`, `Gri`, `UCBLogo`, `GNU Smalltalk`, `Julia`, `Dafny`, `Generator Scripting Language`, `nesC`, `Lisaac`, `eC`, `CDuce`, `A+`, `Falcon`).
   - **Malbolge Unshackled** (unbounded ternary Malbolge via CC0 `Unshackled.c` / `Unshackled-20.c`; zero `'/'` input ops executed, `0` stdin reads under `strace`, `MB_STDIN_SAME`, `U20_PARITY=OK`) — noting candidly that classic 10-trit Malbolge's `59,049`-cell limit remains unbroken in strict A–Z ordering.
   - **111 standalone fork languages**, with zero duplicate dialects/shells, zero query-only formats, and zero custom fork esolang runners in `vendor/`.

[LANGUAGES.md](LANGUAGES.md) lists all **256 steps** (`128 mame (Endoh Stamp) + 128 this fork`) in exact A–Z run order.

## Reproducibility, Hardware / VM Limits & `vendor/` Inventory

- **Deterministic rebuild scope**: Inside the Ubuntu 26.04 Docker image (matching the image's system `zlib` and with `xa`, `z80asm`, and `uxnasm` required on `PATH` for the ROM guard), `cd src && rake` reproduces `QR.aj` (`54,047 B`, `ed0fbe68141e50a7b8cb06c1ebbbe86e17b797823a20a9d1403df256f134e2c8`) byte-identically. Outside that image, differing host `zlib` versions yield a valid, slightly different-size `QR.aj` (for example `54,129 B`).
- **16-bit 64 KiB VMs (`< 64,000 B` hard guard in `src/gen-aj.rb` and `src/vm-exec.rb`; raises if assembler missing)**:
  - `6502 asm` (`xa` + `sim65`): `46,723 B` / `65,012 B` limit (`spare = 18,289 B`)
  - `Z80 asm` (`z80asm` + `tnylpo`): `63,281 B` / `64,991 B` limit (`spare = 1,710 B`)
  - `Uxntal` (`uxnasm` + `uxncli`): `57,065 B` / `65,280 B` limit (`spare = 8,215 B`)
- **Pure stdout / zero-cheating checks**: Verified with an offline non-root lap, `strace` inspection, and a 1-byte engine canary patch (`256/256` intermediate hashes change, `QR.aj == QR2.aj`).
- **Complete `vendor/` inventory**:
  - **13 byte-identical `mame/quine-relay` helpers**: `aheui.rb`, `ante.rb`, `bf.rb`, `blc.rb`, `false.rb`, `golfscript.rb`, `grass.rb`, `ook-to-bf.rb`, `subleq.rb`, `thue.rb`, `unlambda.rb`, `wasi-runtime.js`, `whitespace.rb`.
  - **Bundled upstream source / binaries compiled by `vendor/Makefile`**: `ngnk-b9eeb91e.tar.gz` (K), `lci-0.10.5.zip` (LOLCODE), `npiet-1.3e.tar.gz` (Piet), `cfunge-0.9.0.tar.bz2` (Befunge), `Acme-Chef-1.03.tar.gz` (Chef), `spl-1.2.1.tar.gz` (Shakespeare), `lazyk.c` (Lazy K, upstream source with `RDSTACK_SIZE = 10,000,000`), `Velato_0_1.zip` (Velato), and `Unshackled.c` / `Unshackled-20.c` (Malbolge Unshackled).
  - Upstream `Taxi` compiled with its own `-DNO_GREETINGS` flag.
  - **Zero** custom fork esolang interpreters (`beatnik.rb`, `emmental.rb`, `slashes.rb`, `underload.rb` were all removed in v3).
