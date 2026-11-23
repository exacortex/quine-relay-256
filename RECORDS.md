# Quine Relay Records

These are the counting rules and verified comparisons for [exacortex/quine-relay-256](https://github.com/exacortex/quine-relay-256).

## Leaderboard

| Relay | Strict Distinct *(1:1 rule)* | Relay Steps *(Endoh's standard)* | Order | Verified | Date |
|---|---:|---:|---|---|---|
| **[exacortex/quine-relay-256](https://github.com/exacortex/quine-relay-256)** *(this repo)* | **256** | **256** | **Strict A–Z** (`AspectJ -> ... -> AspectC++ -> AspectJ`) | From-scratch `ubuntu:26.04` build (`80.2 min`, `a8ed91e7...`) + offline `--network=none` non-root `USER qr` default `CMD` lap (`32.1 min`, `QR.aj` 50,342 B `65c6b3ca...` == `QR2.aj`, **256/256** `SHA256SUMS`, `U20_PARITY=OK`, 0 critical / 248 clean / 8 disclosed inherited borderlines; [proof](proof/)) | 2026-11-22 |
| [`mame/quine-relay`](https://github.com/mame/quine-relay) *(original upstream, 2013–2026)* | 123 *(under 1:1 rule)* | **128** *(Endoh counts all 128 by his own test)* | Custom (`Ruby -> ...`) | mame's CI, Ubuntu 26.04 (`QR.rb` 13,664 B) | 2026 |

*(Note: Yusuke Endoh counts all 128 steps in `mame/quine-relay` as languages by his own test; the "Strict Distinct (1:1 rule)" column reflects our fork's stricter rule omitting 5 non-distinct entries: `Ook!`, `JSFuck`, `WebAssembly (Binary format)`, `FORTRAN77`, and `Gzip`.)*

## Counting Rule: Distinct Languages Only (1 step = 1 language)

- **One entry per language**: Multiple implementations of the same language count once (`mksh`, `BusyBox ash`, `yash`, `dash`, `Chicken Scheme`, `Chez Scheme` omitted).
- **One entry per language across versions**: `FORTRAN77` omitted in favor of `Fortran90`; `Perl 6` (Raku) is distinct from `Perl 5`.
- **No encodings, word-swaps, dialects, or thin supersets**: `Ook!`, `JSFuck`, `WebAssembly (Binary format)`, `NQP`, `Genie`, `Teal`, `MoonScript`, `YueScript`, `xonsh`, `Coconut` omitted. Languages extending another grammar (`AspectJ`, `AspectC++`, `TypeScript`, `Objective-C`, `nesC`) use real language-specific syntax of their own.
- **No pure config/markup formats**: `Gzip` omitted; `SQL (SQLite)` is kept as a fork addition (noting its program is a single `SELECT '...'`, alongside upstream `mame` precedents `Dhall`, `XSLT`, `M4`, `Mustache`, `CMake`, `Flex`, `Jq`, `sed`, `Makefile`).
- **Distinct CPU/VM ISAs count separately** when each has its own ISA and real assembler/runtime (`NASM` i386, `ARM64 asm`, `RISC-V asm`, `6502 asm`, `Z80 asm`, `MMIX`, `Uxntal`, `Parrot asm`, `QBE`, `LLVM asm`, `Jasmin`, `MSIL`).

[LANGUAGES.md](LANGUAGES.md) lists all **256 steps = 256 distinct languages** in exact A–Z run order.

## No-Cheating Rules & Disclosed Accommodations

1. **No code on the command line** (no `-e`/`-c`, no CLI `printf` prepending code).
2. **No reading files or stdin payload** (all printed text lives inside the program itself; `Malbolge Unshackled` uses zero `'/'` input ops).
3. **Output on stdout only** (no temp-file + `cat`/`tail`, no stderr redirection into output).

- **0 critical violations, 0 fork borderlines**; **248 / 256 steps** pass all 7 audit rules cleanly.
- **8 remaining disclosed borderline steps** (all inherited from `mame/quine-relay`): `sed`, `Mustache`, `XSLT` (self-operand input); `Execline` (`/bin/echo`), `bc` (`BC_LINE_LENGTH`), `MiniZinc` (`--soln-sep ''`), `Promela` (`spin -T`), `Jq` (`-j`).
- **Hardware/VM & runtime notes**: `6502 asm` (`xa`+`sim65`), `Z80 asm` (`z80asm`+`tnylpo`), and `Uxntal` (`uxnasm`+`uxncli`) all assemble and execute inside real `< 64 KiB` RAM/ROM limits (`< 64,000 B` hard guard enforced in `src/gen-aj.rb` and `src/vm-exec.rb`). `vendor/lazyk.c` raises `RDSTACK_SIZE` to `10,000,000` (semantics unchanged); `Taxi` uses upstream `-DNO_GREETINGS`; `vendor/` includes 4 MIT esolang runners (`underload.rb`, `emmental.rb`, `slashes.rb`, `beatnik.rb`).
