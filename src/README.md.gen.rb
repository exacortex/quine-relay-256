# encoding: UTF-8
require_relative "code-gen"
require "digest"
require "erb"

qr_path = File.join(__dir__, "../QR.aj")
qr_size = File.size(qr_path)
qr_size_fmt = qr_size.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse
qr_sha = Digest::SHA256.file(qr_path).hexdigest
qr_sha8 = qr_sha[0, 8]
step_count = RunSteps.size
compiled_steps = GenSteps.count {|s| !s.code.nil? }

tpl = DATA.read.force_encoding("UTF-8")
File.binwrite(File.join(__dir__, "../README.md"), ERB.new(tpl, trim_mode: "%").result(binding).encode("UTF-8"))

__END__
# Quine Relay <%= step_count %> — Strict A–Z Edition

**All 128 languages from Yusuke Endoh's relay + 128 additions = <%= step_count %> steps in strict A–Z alphabetical order**, forming a closed self-reproducing loop (`AspectJ -> Asymptote -> ATS -> ... -> Zsh -> 6502 asm -> A+ -> ... -> Arturo -> AspectC++ -> AspectJ`).

This fork builds on [Yusuke Endoh's (mame) Quine Relay](https://github.com/mame/quine-relay) (started in **2013**, MIT License). All **128** languages of Endoh's Ubuntu 26.04 relay are kept and run on the same upstream tools alongside **128** additions in this fork running on canonical third-party upstream compilers and interpreters, verified offline in Docker (`--network=none`) as an unprivileged user (`USER qr`). Every step payload was rewritten for the strict A–Z cycle order. Separately, 11 Makefile commands differ in flags or build layout from upstream (`AspectJ`, `ALGOL 68`, `C#`, `F#`, `Visual Basic`, `FORTRAN77`, `Lazy K`, `Nim`, `Objective-C`, `Piet`, and `Shakespeare`).

## Highlights

- **128 + 128 = <%= step_count %> steps**: Includes all **128** languages from Endoh's Ubuntu 26.04 relay on the same upstream tools, paired with **128** additions in this fork (`16/20` restored historical `mame` languages + `Malbolge Unshackled` + `111` additional upstream-toolchain languages). Every one of our 128 additions uses a canonical third-party upstream toolchain with zero custom runners in `vendor/`. See [LANGUAGES.md](LANGUAGES.md) for the complete A–Z list and [RECORDS.md](RECORDS.md) for composition and design notes.
- **Strict A–Z alphabetical order (`out of order: 0`)**: Ignoring case and punctuation, every step proceeds in A–Z order around the <%= step_count %>-step cycle, rotated to enter at **Step #1 `AspectJ` (`QR.aj`)** so all three 16-bit 64 KiB hardware/VM targets (`6502 asm`, `Z80 asm`, `Uxntal`) sit near the compact inner tail and assemble inside real `< 64 KiB` RAM/ROM limits (`Asm6502` 46,799 B / 65,012 B; `Z80 asm` 63,563 B / 64,991 B; `Uxntal` 57,371 B / 65,280 B), enforced by a `< 64,000 B` check in `src/gen-aj.rb` and `src/vm-exec.rb`.
- **Self-reproducing AspectJ seed (`QR.aj`, `<%= qr_size_fmt %> B`, `52.9 KiB` / `54.2 kB`, `sha256: <%= qr_sha8 %>...`)**: AspectJ advice (`aspect Q { before(): execution(void QR.main(..)) { ... } } public class QR { public static void main(String[] a) {} }`), storing its compressed engine and <%= compiled_steps %>-step specification table in chunked printable-ASCII Base91 string literals (`java.util.zip.InflaterInputStream`), with zero file I/O, zero CLI code, and zero external processes. Inside the Ubuntu 26.04 Docker image (matching the image's system `zlib` and with `xa`, `z80asm`, and `uxnasm` on `PATH`), `cd src && rake` rebuilds `QR.aj` byte-identically; outside the image, different host `zlib` versions still produce a valid `QR.aj`, though the compressed size may differ slightly.
- **Verified offline proof laps ([proof/](proof/))**:
  - **Lap A (`make check`, `256 / 256` steps PASS)**: `38.5 min` (`2,311s`) under `--network=none` as non-root `USER qr` (`uid=1001`), with `diff -s QR.aj QR2.aj` -> `Files QR.aj and QR2.aj are identical` (`<%= qr_size_fmt %> B`) and **256 / 256** `SHA256SUMS` passing.
  - **Lap B (in-image rebuild + harsh engine-mutation test)**: regenerating `QR.aj` inside the verification image produced a byte-identical file; patching `"bad op "` -> `"Q'$@{( "` in `src/engine_body.java` (`54,175 B`) completed all 256 steps offline in `40.1 min` (`2,408s`) with `QR2.aj` matching the mutated seed and **256 / 256** intermediate step hashes changed.
  - **Lap C (`strace` full-lap audit)**: completed in `84.1 min` (`5,045s`) with **256 / 256** `SHA256SUMS` and byte-identical `QR2.aj`, producing `2,474` audit rows with `0` critical violations (`12` cross-step file accesses, all verified harmless: the persistent `.NET` build server compiling Dafny's code while attributed to C#, Scala checking for a file named `QR`, `.NET` and Gleam reading their own committed project files, and `make`'s final `diff`).
  - **Malbolge Unshackled dual-interpreter parity**: both untouched CC0 reference interpreters (`Unshackled.c` and `Unshackled-20.c`) produce byte-identical `QR.wl` (`198,440 B` from `3,811,135 B` `QR.mb`) on both empty and non-empty stdin.

## Engineering Notes

- **Fork additions standard**: All **128** additions in this fork use canonical third-party upstream compilers and interpreters, pass no code on the command line, do not read payload data from files or stdin, and write strictly to stdout (with zero custom fork esolang runners in `vendor/`).
- **Classic 10-trit Malbolge limitation**: Because strict A–Z ordering pushes the `M` section to several hundred kilobytes, this fork uses `Malbolge Unshackled` rather than classic 10-trit Malbolge (whose `59,049`-cell ternary memory limit stands unbroken in classic Malbolge).
- **Generated seed vs. hand-crafted original**: `QR.aj` (`<%= qr_size_fmt %> B`, `52.9 KiB`) is a generated, zlib-packed AspectJ program — a different engineering exercise from Endoh's hand-crafted `13,664 B` `QR.rb`.
- **11 stdlib zlib unpacker steps** (`C#`, `CoffeeScript`, `Elixir`, `F#`, `Go`, `Groovy`, `Mathics`, `PowerShell`, `Tcl`, `V`, `Zig`) use their own language's standard library zlib/deflate implementation (zero external decompression binaries).
- **`Shakespeare` (`gcc -O0` on `QR.spl.c`)** peaks around `~21 GB` RSS in `cc1`; plan for **>= 24 GB RAM** in your Docker VM when running a full lap.
- Full step-by-step inventory, `vendor/` provenance, and Makefile/`strace` implementation notes live in [LANGUAGES.md](LANGUAGES.md), [RECORDS.md](RECORDS.md), [proof/AUDIT.md](proof/AUDIT.md), and [proof/RESULT.txt](proof/RESULT.txt).

## Quick Start (Standalone Docker Build & Offline Proof Lap)

```bash
docker build --pull --no-cache -t quine-relay-256 .
docker run --rm --network=none quine-relay-256
```

This builds Ubuntu 26.04 with all <%= step_count %> language toolchains, switches to non-root `USER qr`, executes all <%= step_count %> steps from `QR.aj` -> `QR2.aj` offline (`make check -j 10000`), verifies `diff -s QR.aj QR2.aj`, and checks all <%= step_count %> hashes in `SHA256SUMS`.

To regenerate `QR.aj` (with the `< 64,000 B` ROM guard, requiring `xa`, `z80asm`, and `uxnasm` on `PATH`) and all generated repository files inside the Ubuntu 26.04 Docker image:
```bash
cd src && rake
```

## History & Credits

- **2013–2026**: [Yusuke Endoh (@mametter)](https://github.com/mame/quine-relay) — original 50 / 100 / 128-language Quine Relay (MIT License).
- **2026-11-21**: `quine-relay-256` initial 256-language prototype (`QR.rb`).
- **2026-11-22**: Strict A–Z `AspectJ` seed refactor (`QR.aj`, non-root `USER qr`, `< 64,000 B` 6502/Z80/Uxntal ROMs).
- **2026-11-23**: Kept all 128 languages from upstream `mame/quine-relay` on the same upstream tools alongside 128 standalone additions = 256 steps (`QR.aj`).
- **2026-11-24**: Hardened `Ion` shell quoting using variable concatenation in 4,000-byte chunks (`QR.aj` `<%= qr_size_fmt %> B`, `52.9 KiB`), verified on all three offline Docker laps (`make check` `38.5 min`, harsh canary `"Q'$@{( "` `40.1 min`, and full `strace` `84.1 min`).

See [LICENSE](LICENSE) for full MIT license terms.
