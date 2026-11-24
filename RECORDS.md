# Quine Relay 256 — Design & Counting Notes

These notes document how [exacortex/quine-relay-256](https://github.com/exacortex/quine-relay-256) relates to Yusuke Endoh's upstream [`mame/quine-relay`](https://github.com/mame/quine-relay) without changing or second-guessing upstream's own standard.

## Overview: Upstream Base + Fork Additions (128 + 128 = 256)

| Relay | Steps | Composition | Order | Verification |
|---|---:|---|---|---|
| [`mame/quine-relay`](https://github.com/mame/quine-relay) *(upstream original, 2013–2026)* | **128** | All 128 steps of Endoh's Ubuntu 26.04 relay | Hand-tuned (`Ruby -> ... -> Ruby`) | Upstream CI, Ubuntu 26.04 (`QR.rb` 13,664 B) |
| **[exacortex/quine-relay-256](https://github.com/exacortex/quine-relay-256)** *(this fork, v3 "The Endoh Stamp")* | **256** | **128** upstream Endoh steps (`100%` preserved) + **128** standalone fork additions | **Strict A–Z** (`AspectJ -> Asymptote -> ... -> Zsh -> 6502 asm -> A+ -> ... -> AspectC++ -> AspectJ`) | Offline `--network=none` non-root `USER qr` lap (`39.9 min` / `2,396.8s`, `QR.aj` 54,047 B `sha256: ed0fbe68...` == `QR2.aj`, **256/256** `SHA256SUMS`, `U20_PARITY=OK`; [proof](proof/)) |

## "The Endoh Stamp" Rule

Yusuke Endoh invented and hand-crafted Quine Relay across more than a decade. Rather than imposing an external deduplication rule back onto upstream:

1. **All 128 / 128 Ubuntu 26.04 upstream steps stay intact (`mame (Endoh Stamp)`)**: Including `FORTRAN77`, `Gzip`, `JSFuck`, `Ook!`, and `WebAssembly (Binary format)`, plus the 8 upstream tool conventions (`sed`, `Mustache`, `XSLT`, `Execline`, `bc`, `MiniZinc`, `Promela`, `Jq`).
2. **Every one of our 128 fork additions stands on its own canonical third-party upstream toolchain (`this fork`)**:
   - **16 / 20 historical `mame` retirees** restored (`AspectC++`, `Parrot asm (PASM)`, `Boo`, `Maxima`, `Gri`, `UCBLogo`, `GNU Smalltalk`, `Julia`, `Dafny`, `Generator Scripting Language`, `nesC`, `Lisaac`, `eC`, `CDuce`, `A+`, `Falcon`).
   - **Malbolge Unshackled** (unbounded ternary Malbolge via CC0 `Unshackled.c` / `Unshackled-20.c`; zero `'/'` input ops executed, `0` stdin reads under `strace`, `MB_STDIN_SAME`, `U20_PARITY=OK`) — noting candidly that classic 10-trit Malbolge's `59,049`-cell limit remains unbroken in strict A–Z ordering.
   - **111 standalone fork languages**, with zero duplicate dialects/shells, zero query-only formats, zero custom fork esolang runners in `vendor/`, and zero fork-side CLI/file-reading accommodations.

[LANGUAGES.md](LANGUAGES.md) lists all **256 steps** (`128 mame (Endoh Stamp) + 128 this fork`) in exact A–Z run order.

## Hardware / VM Limits & `vendor/` Inventory

- **16-bit 64 KiB VMs (`< 64,000 B` hard guard in `src/gen-aj.rb` and `src/vm-exec.rb`)**:
  - `6502 asm` (`xa` + `sim65`): `46,723 B` / `65,012 B` limit (`spare = 18,289 B`)
  - `Z80 asm` (`z80asm` + `tnylpo`): `63,281 B` / `64,991 B` limit (`spare = 1,710 B`)
  - `Uxntal` (`uxnasm` + `uxncli`): `57,065 B` / `65,280 B` limit (`spare = 8,215 B`)
- **Pure stdout / zero-cheating checks**: Verified with an offline non-root lap, `strace` inspection, and a 1-byte engine canary patch (`256/256` intermediate hashes change, `QR.aj == QR2.aj`).
- **What lives in `vendor/`**:
  - Upstream `mame/quine-relay` helpers: `bf.rb`, `false.rb`, `ook-to-bf.rb`, `unlambda.rb`, `wasi-runtime.js`.
  - Upstream third-party interpreters/compilers built by `vendor/Makefile`: `lci-0.10.5` (LOLCODE), `npiet-1.3e` (Piet), `cfunge-0.9.0` (Befunge), `Acme-Chef-1.03` (Chef), `spl-1.2.1` (Shakespeare), `lazyk.c` (Lazy K, upstream source with `RDSTACK_SIZE = 10,000,000`), `Velato_0_1.zip` (Velato), and `Unshackled.c` / `Unshackled-20.c` (Malbolge Unshackled).
  - Upstream `Taxi` compiled with its own `-DNO_GREETINGS` flag.
  - **Zero** custom fork esolang interpreters (`beatnik.rb`, `emmental.rb`, `slashes.rb`, `underload.rb` were all removed in v3).
