# Quine Relay Records

These are the rules we use to count a quine relay, and the leaderboard for anyone who wants to build on or beat it.
A record needs a public repo and a full run from a clean build that anyone can repeat. A number alone doesn't count.

## Leaderboard

| Relay | Distinct languages | Relay steps | Verified | Date |
|---|---:|---:|---|---|
| [exacortex/quine-relay-256](https://github.com/exacortex/quine-relay-256) (this repo) | **256** | **256** | `docker build --pull --no-cache` from this repo's `Dockerfile` (59.1 min) + offline `make check` (`--network=none`, 25.3 min) on Ubuntu 26.04, `QR.rb` 45,828 B (`ff759bc6...`), image `0de4a22a...`, `U20 parity: OK`, canary checks `PASS` ([proof](proof/)) | 2026-11-21 |
| [exacortex/quine-relay-267](https://github.com/exacortex/quine-relay-267) *(prior stepping stone)* | 257 | 267 | `docker build --no-cache` (79.9 min) + `make check` (23.9 min) on Ubuntu 26.04 | 2026-11-19 |
| [mame/quine-relay](https://github.com/mame/quine-relay) *(original upstream relay)* | 123 *(under 1:1 rule)* | 128 | mame's CI, Ubuntu 26.04 (`QR.rb` 13,664 B) | 2026 |

Withdrawn: [exacortex/quine-relay-284](https://github.com/exacortex/quine-relay-284) (273 / 284, Nov 18, 2026). Several steps broke the no-cheating rules below.
Not counted: [exacortex/quine-relay-151](https://github.com/exacortex/quine-relay-151) (143 / 151, Nov 13, 2026). Its BASIC step wrote a file and printed it with `cat` (rule 3).

To add a relay, open a pull request that edits this table and links to your proof (see "How to claim a record" below).

## Counting rule: distinct languages only (1 step = 1 language)

Earlier milestones kept a separate "Tier 2 (relay steps)" count for extra implementations, dialects, or encodings. **This release drops Tier 2 completely.** Every step in the relay must be a distinct, standalone open-source programming language with its own name, grammar/spec, and real compiler or interpreter:

- **One entry per language.** Multiple implementations of the same language count once (we dropped `mksh`, `BusyBox ash`, `yash`, `dash`, `Chicken Scheme`, and `Chez Scheme`).
- **One entry per language across versions.** Older versions of a language do not count separately (we dropped `FORTRAN77`, keeping `Fortran90`). Raku is the standard exception: renamed from Perl 6 in 2019, it is its own language separate from Perl 5.
- **No encodings, word-swaps, dialects, or thin supersets of another included language.** We omit `Ook!` (Brainfuck word-swap), `JSFuck` (JavaScript subset), `WebAssembly (Binary format)` (binary encoding of WebAssembly Text), `NQP` (Raku bootstrapping subset), `Genie` (`valac` surface syntax), plain-Lua dialects (`Teal`, `MoonScript`, `YueScript`), and plain-Python supersets (`xonsh`, `Coconut`). Every language in the relay that extends another grammar (`AspectJ`, `AspectC++`, `TypeScript`, `Objective-C`, `nesC`) uses real language-specific syntax of its own.
- **No file formats or non-programming config/query/markup additions.** We omit `Gzip` and avoid adding pure configuration, query, or narrative-markup formats in this fork (retaining only upstream `mame/quine-relay` precedents such as `Dhall`, `XSLT`, `M4`, `Mustache`, `CMake`, `Flex`, `Jq`, `sed`, and `Makefile`).
- **No proof-assistant extraction workarounds for languages lacking a standalone runtime.** Proof assistants that must extract to OCaml or Haskell to print (`Rocq`, `Agda`) are omitted; languages with standalone runtimes (`Lean 4`, `Idris 2`, `Dafny`, and BEAM-compiled `Gleam`) are kept.
- **Different CPU/VM instruction sets *do* count separately** when each has its own ISA and real assembler/runtime (32-bit x86 (`i386`) NASM, ARM64, RISC-V, 6502, Z80, MMIX, Uxntal, Parrot PASM, QBE, LLVM IR, JVM Jasmin, .NET MSIL).
- **A distinct language compiling to a shared VM or target *does* count** when it has its own grammar, specification, and compiler (for example TypeScript, CoffeeScript, Hy, Racket, PureScript, Gleam, Clojure, Scala, Kotlin, Elixir).

[LANGUAGES.md](LANGUAGES.md) lists all **256 steps = 256 distinct languages** in exact run order.

## No-cheating rules

These follow the three principles Yusuke Endoh (mame) shared when reviewing our earlier prototype (with the inherited `mame` `sed` and `Mustache` self-operand exceptions noted transparently below):

1. **No code on the command line.** A command names the program file and sets compiler/interpreter options. It cannot carry program text (`node -e '...'`, a `printf` that prepends code, or a CLI query expression such as `opa eval ... data.qr.x`).
2. **No reading files.** A program cannot open its own source, another step's file, or `/dev/stdout`, and cannot consume payload via stdin (including Malbolge's `'/'` opcode). All text it prints lives inside the program itself.
3. **Output on stdout only.** No writing a temporary file and then `cat`/`tail`, no redirecting stderr to the output (`2> OUTFILE`), no cleaning a tool's output with `tail`, `grep`, or `tr`, and no build-time source patches that strip an interpreter's stdout banners (such as patching `Wodan58/joy0` `main.c`).

### Upstream precedents and disclosed accommodations

Minimal build and toolchain plumbing inherited from `mame/quine-relay` is kept where required by the upstream tool itself, and disclosed openly rather than hidden:

- **Upstream `mame/quine-relay` precedents:** `sed -E -f QR.sed QR.sed`, `mustache QR.mustache QR.mustache`, shell/build steps calling standard Unix utilities (`bash` calling `sed`, `tcsh`/`zsh` calling `cat`, `ksh` calling `od`, `Makefile` calling `@printf`, `Execline` calling `echo`), `Dhall`, `XSLT`, `M4`, `Flex`, `CMake`, `Promela` (`spin -T`), `dc ... || true`, `.NET` `tmp.*proj` project manifests (`C#`, `Visual Basic`; `F#` runs offline via `dotnet fsi`), `mv` filename collision backups (`QR.c`, `QR.bc`, `QR.m`), and minimal MIT Ruby esolang runners under `vendor/`.
- **Disclosed fork accommodations:** `vendor/lazyk.c` (`RDSTACK_SIZE` raised from `100,000` to `10,000,000` for 256-step stack depth; semantics unchanged), `Taxi` compiled with BigZaphod's official upstream `-DNO_GREETINGS` macro, `A+` run with `2> /dev/null < /dev/null` to discard stderr diagnostics and close stdin, `Gleam` minimal `gleam.toml` manifest with `@external(erlang, ...)` bindings to BEAM `io:put_chars`/`string:replace` for offline zero-dependency compilation, `Z80 asm` (`tnylpo`) dropping UID 0 to `nobody` via `setpriv` when invoked as root, and 4 spec-complete MIT esolang runners in `vendor/` (`underload.rb`, `emmental.rb`, `slashes.rb`, `beatnik.rb`). Every step where a canonical upstream interpreter or emulator exists (`CJam`, `Glass`, `><> (Fish)`, `Brain-Flak`, `6502 asm`, `Z80 asm`) runs on that canonical upstream tool.

## How to claim a record

A claim needs all of these:

1. **A public repo** with the seed program (`QR.rb`), a `Dockerfile` that installs every language from distro packages or pinned open-source versions with checksums/commits (no proprietary binaries committed without redistribution rights), and a complete `LANGUAGES.md` step list.
2. **A full from-scratch run in Docker** (`docker build --pull --no-cache` + unprivileged `make check`) running all steps in order inside one image, with any bundled `vendor/` interpreters documented transparently in `vendor/README`.
3. **Every step follows the no-cheating rules** above, and every step is a distinct language.
4. **A closed loop** with `SHA256SUMS` covering every intermediate file and `QR2.rb` byte-for-byte identical to `QR.rb`.
5. **The full build and run logs**, committed under `proof/` (LF line endings).
6. **Credit** to Yusuke Endoh's Quine Relay if building on it, preserving its MIT license (and documenting third-party `vendor/` licenses accurately).

Anyone should be able to reproduce the run with `docker build` and `docker run`. If they can't, the claim doesn't stand.

## Comparison across verified builds

| Measure | `mame/quine-relay` (128) | `quine-relay-267` *(stepping stone)* | **`quine-relay-256` (this repo)** |
|---|---:|---:|---:|
| Distinct programming languages *(1:1 rule)* | 123 | 257 | **256** |
| Total relay steps | 128 | 267 | **256** (1:1 distinct) |
| Single-implementation `mame-128` languages included | 123 / 123 | 119 / 123 | **123 / 123 (100%)** |
| Retired `mame` classics restored | — | 16 / 20 | **16 / 20** |
| Includes Malbolge Unshackled | No | No | **Yes** (CC0 `Unshackled.c`, zero `'/'` ops) |
| Seed `QR.rb` size | **13,664 B** (106.8 B/step) | 34,888 B (130.7 B/step) | **45,828 B** (179.0 B/step, `ff759bc6...`) |
| Total class-boundary intermediates (`amap2`) | — | ~559 MB | **316.24 MB** (all 256 real files: **505.41 MB**) |
| Clean `docker build --pull --no-cache` | — | 79.9 min | **59.1 min** (`ubuntu:26.04`, 40 base layers, 27.81 GB) |
| Full `make check` lap time | — | 23.9 min | **25.3 min** (`--network=none` offline, `256/256` `SHA256SUMS`, `U20 parity: OK`) |
| Docker image ID | — | `fd722d9b...` | `sha256:0de4a22a3e1960ef57e507416a80b2b71dc104c267efabd780e31cd3ffa75dc7` |
