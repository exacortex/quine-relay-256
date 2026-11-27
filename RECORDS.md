# Quine Relay 256 — Design & Composition Notes

These notes document how [exacortex/quine-relay-256](https://github.com/exacortex/quine-relay-256) relates to Yusuke Endoh's upstream [`mame/quine-relay`](https://github.com/mame/quine-relay) without altering upstream's conventions or standards.

## Overview: Upstream Base + Fork Additions (128 + 128 = 256)

| Relay | Steps | Composition | Order | Verification |
|---|---:|---|---|---|
| [`mame/quine-relay`](https://github.com/mame/quine-relay) *(upstream original, 2013–2026)* | **128** | All 128 steps of Endoh's Ubuntu 26.04 relay | Hand-tuned (`Ruby -> ... -> Ruby`) | Upstream CI, Ubuntu 26.04 (`QR.rb` 13,664 B) |
| **[exacortex/quine-relay-256](https://github.com/exacortex/quine-relay-256)** *(this fork)* | **256** | **128** upstream Endoh languages (on the same tools) + **128** standalone fork additions | **Strict A–Z** (`AspectJ -> Asymptote -> ... -> Zsh -> 6502 asm -> A+ -> ... -> AspectC++ -> AspectJ`) | Offline `--network=none` non-root `USER qr` 3-lap run (`46.2 min` / `2,772s` `make all`, `QR.aj` `54,812 B` `53.5 KiB` `sha256: 0c88b16f...` == `QR2.aj`, **256/256** `SHA256SUMS`, `2,472`-row `strace` audit; [proof](proof/)) |

## Composition & Scope

Upstream `mame/quine-relay` counts **128** steps by Yusuke Endoh's convention, and this fork follows the same spirit rather than re-scoring upstream's choices: all **128** languages of Endoh's Ubuntu 26.04 relay are kept on the same upstream tools, paired with **128** additions in this fork (**256** steps total). Where to draw boundaries between programming languages, formats, and dialects is ultimately a matter of taste, so every step is listed openly in [LANGUAGES.md](LANGUAGES.md).

1. **All 128 Ubuntu 26.04 upstream languages (`mame/quine-relay`)**: Run on the same upstream tools, keeping all 13 `vendor/` helper scripts byte-for-byte identical to upstream. Every step's generated payload was rewritten for strict A–Z ordering. Separately, 11 Makefile commands differ in flags or build layout from upstream (`AspectJ`, `ALGOL 68`, `C#`, `F#`, `Visual Basic`, `FORTRAN77`, `Lazy K`, `Nim`, `Objective-C`, `Piet`, and `Shakespeare`). Detailed upstream Makefile invocation notes are recorded in [proof/AUDIT.md](proof/AUDIT.md).
2. **All 128 fork additions (`this fork`)**:
   - Every addition runs on a canonical third-party upstream compiler or interpreter, passes no code on the CLI, does not read payload data from files or stdin, writes strictly to stdout, and adds zero custom fork esolang runners to `vendor/`.
   - **16 / 20 historical `mame` retirees** restored (`AspectC++`, `Parrot asm (PASM)`, `Boo`, `Maxima`, `Gri`, `UCBLogo`, `GNU Smalltalk`, `Julia`, `Dafny`, `Generator Scripting Language`, `nesC`, `Lisaac`, `eC`, `CDuce`, `A+`, `Falcon`).
   - **Malbolge Unshackled** (unbounded ternary Malbolge via CC0 `Unshackled.c` / `Unshackled-20.c`; dual-interpreter parity and stdin-invariance verified on empty and non-empty stdin) — noting candidly that classic 10-trit Malbolge's `59,049`-cell limit remains unbroken in strict A–Z ordering.
   - **111 additional upstream-toolchain languages**.

[LANGUAGES.md](LANGUAGES.md) lists all **256 steps** (`128 mame/quine-relay + 128 this fork`) in exact A–Z run order.

## Reproducibility, Hardware / VM Limits & `vendor/` Inventory

- **Deterministic rebuild scope**: Inside the Ubuntu 26.04 Docker image (matching the image's system `zlib` and with `xa`, `z80asm`, and `uxnasm` required on `PATH` for the ROM guard), `cd src && rake` reproduces `QR.aj` (`54,812 B`, `53.5 KiB` / `54.8 kB`, `0c88b16fd93c05cc6d19af4b7d23abb2ca97eb622c3f01d933c57c0e1c92d778`) byte-identically. Outside that image, differing host `zlib` versions still produce a valid `QR.aj`, though its compressed size may differ slightly.
- **16-bit 64 KiB VMs (`< 64,000 B` hard guard in `src/gen-aj.rb` and `src/vm-exec.rb`; raises if assembler is missing)**:
  - `6502 asm` (`xa` + `sim65`): `45,842 B` / `65,012 B` limit (`spare = 19,170 B`)
  - `Z80 asm` (`z80asm` + `tnylpo`): `50,152 B` / `64,991 B` limit (`spare = 14,839 B`)
  - `Uxntal` (`uxnasm` + `uxncli`): `45,626 B` / `65,280 B` limit (`spare = 19,654 B`)
- **Pure stdout / end-to-end integrity checks**: Verified offline across three laps (`187.3 min` total: `46.2 min` `make all`, `46.4 min` harsh engine-mutation test `"bad op "` -> `"Q'$@{( "` changing `256/256` intermediate step hashes while preserving `QR.aj == QR2.aj`, and `93.7 min` full-build `strace` audit with `2,472` findings, `0` critical violations, and `12` benign cross-step file accesses).
- **Complete `vendor/` inventory**:
  - **13 byte-identical `mame/quine-relay` helpers**: `aheui.rb`, `ante.rb`, `bf.rb`, `blc.rb`, `false.rb`, `golfscript.rb`, `grass.rb`, `ook-to-bf.rb`, `subleq.rb`, `thue.rb`, `unlambda.rb`, `wasi-runtime.js`, `whitespace.rb`.
  - **Bundled upstream source / archives compiled by `vendor/Makefile`**: `ngnk-b9eeb91e.tar.gz` (K), `lci-0.10.5.zip` (LOLCODE), `npiet-1.3e.tar.gz` (Piet), `cfunge-0.9.0.tar.bz2` (Befunge), `Acme-Chef-1.03.tar.gz` (Chef), `spl-1.2.1.tar.gz` (Shakespeare), `lazyk.c` (Lazy K, upstream source with `RDSTACK_SIZE = 10,000,000`), `Velato_0_1.zip` (Velato), and `Unshackled.c` / `Unshackled-20.c` (Malbolge Unshackled).
  - Upstream `Taxi` compiled with its own `-DNO_GREETINGS` flag.
  - **Zero** custom fork esolang interpreters.
