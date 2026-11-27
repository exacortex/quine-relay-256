# encoding: UTF-8
require_relative "code-gen"
require "digest"
require "erb"

qr_path = File.join(__dir__, "../QR.aj")
qr_size = File.size(qr_path)
qr_size_fmt = qr_size.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse
qr_kib = format("%.1f", qr_size / 1024.0)
qr_kb = format("%.1f", qr_size / 1000.0)
qr_sha = Digest::SHA256.file(qr_path).hexdigest
qr_sha8 = qr_sha[0, 8]
step_count = RunSteps.size
compiled_steps = GenSteps.count {|s| !s.code.nil? }

tpl = DATA.read.force_encoding("UTF-8")
File.binwrite(File.join(__dir__, "../README.md"), ERB.new(tpl, trim_mode: "%").result(binding).encode("UTF-8"))

__END__
# Quine Relay <%= step_count %> — Strict A–Z Edition

**All 128 languages from Yusuke Endoh's relay + 128 additions = <%= step_count %> steps in strict A–Z alphabetical order**, forming a closed self-reproducing loop (`AspectJ -> Asymptote -> ATS -> ... -> Zsh -> 6502 asm -> A+ -> ... -> Arturo -> AspectC++ -> AspectJ`) — starting from a compact **<%= qr_kib %> KiB (`<%= qr_size_fmt %> B`) pure-code AspectJ program (`QR.aj`)**.

<p align="center">
  <img src="assets/terminal-demo.gif" alt="Quine Relay 256 live ANSI terminal visualizer" width="760">
</p>

This fork builds on [Yusuke Endoh's (mame) Quine Relay](https://github.com/mame/quine-relay) (started in **2013**, MIT License). All **128** languages of Endoh's Ubuntu 26.04 relay are kept and run on the same upstream tools alongside **128** additions in this fork running on canonical third-party upstream compilers and interpreters, running offline in Docker (`--network=none`) as an unprivileged user (`USER qr`). Every step payload was rewritten for the strict A–Z cycle order. Separately, 11 Makefile commands differ in flags or build layout from upstream (`AspectJ`, `ALGOL 68`, `C#`, `F#`, `Visual Basic`, `FORTRAN77`, `Lazy K`, `Nim`, `Objective-C`, `Piet`, and `Shakespeare`).

<p align="center">
  <a href="langs.png"><img src="langs.png" alt="256-Language Strict A–Z Uroboros Wheel" width="520"></a><br>
  <sub><b>256-Language A–Z Wheel</b> — <code>mame/quine-relay</code> (128, black) + this fork (128, rust)</sub>
</p>

<p align="center">
  <a href="assets/payload-curve.png"><img src="assets/payload-curve.png" alt="Quine Relay 256 log-scale payload breathing curve" width="840"></a>
</p>

## Highlights

- **128 + 128 = <%= step_count %> steps**: Includes all **128** languages from Endoh's Ubuntu 26.04 relay on the same upstream tools, paired with **128** additions in this fork (`16/20` restored historical `mame` languages + `Malbolge Unshackled` + `111` additional upstream-toolchain languages). Every one of our 128 additions uses a canonical third-party upstream toolchain with zero custom runners in `vendor/`. See [LANGUAGES.md](LANGUAGES.md) for the complete A–Z list and [RECORDS.md](RECORDS.md) for composition and design notes.
- **Lean pure-code AspectJ seed (`QR.aj`, `<%= qr_size_fmt %> B`, `<%= qr_kib %> KiB` / `<%= qr_kb %> kB`, `sha256: <%= qr_sha8 %>...`)**: Advice (`aspect Q { before(): execution(void QR.main(..)) { ... } } public class QR { public static void main(String[] a) {} }`) packed by `src/gen-aj.rb` with zero ASCII-art padding (`~<%= format("%.0f", qr_size / step_count.to_f) %> B/step`), zero file I/O, zero CLI code, and zero external processes. Inside the Ubuntu 26.04 Docker image (matching the image's system `zlib` and with `xa`, `z80asm`, and `uxnasm` on `PATH`), `cd src && rake` rebuilds `QR.aj` byte-identically.
- **Live ANSI Terminal Visualizer (`tools/relay_ui.py`)**: Interactive `docker run -it` runs wrap `make check -j 10000` with an animated ExaCortex ring-and-dot header, spinning 256-step A–Z dial, log-scale payload sparkline, milestone badges, live generated-source peek, and a bold `256` verification card. Non-interactive runs (`CI=true`, `NO_COLOR`, `--plain`, or redirected stdout) hand off immediately to unmodified `make check -j 10000` (with stdin detached to `/dev/null` on interactive TTYs).
- **Strict A–Z alphabetical order (`out of order: 0`)**: Ignoring case and punctuation, every step proceeds in A–Z order around the <%= step_count %>-step cycle, rotated to enter at **Step #1 `AspectJ` (`QR.aj`)** so all three 16-bit 64 KiB hardware/VM targets (`6502 asm`, `Z80 asm`, `Uxntal`) sit near the compact inner tail and assemble well inside real `< 64 KiB` RAM/ROM limits, enforced by a `< 64,000 B` check in `src/gen-aj.rb` and `src/vm-exec.rb`:
  - **`6502 asm`** (`xa` + `sim65`): **`45,842 B / 65,012 B`** (`19,170 B` spare, `0.02s`, `exact=true`)
  - **`Z80 asm`** (`z80asm` + `tnylpo`): **`50,152 B / 64,991 B`** (`14,839 B` spare, `0.01s`, `exact=true`)
  - **`Uxntal`** (`uxnasm` + `uxncli`): **`45,626 B / 65,280 B`** (`19,654 B` spare, `0.12s`, `exact=true`)
- **Offline 3-lap verification (`256-v33-verify`, `--network=none`, `USER qr`, `187.3 min` total)**:
  - **Engine & Lap A (`make all` + `SHA256SUMS` + UI checks)**: **256 / 256 PASS** in **`2,772s` (`46.2 min`)**, `diff -s QR.aj QR2.aj` -> identical (`<%= qr_size_fmt %> B`), fresh `256`-line [`SHA256SUMS`](SHA256SUMS) (verified 256/256 in Lap C), `NONTTY_RC=0`, `PTY_DEMO_RC=0`; `self() == QR.aj`, Phase 1 `224/224` exact (`fails=0`), Phase 2 `224/224` chain `check()`s and Ruby-vs-Java parity (`QR.asy` = `710,423 B`), `JSFuck` `16,740,100 B` (`0` invalid chars), and `Malbolge Unshackled` `3,080,162 B` -> `161,404 B` dual-interpreter parity (`Unshackled.c == Unshackled-20.c`).
  - **Lap B (in-image rebuild + harsh `"Q'$@{( "` canary)**: `cd src && rake` inside the Ubuntu 26.04 image reproduced `QR.aj` byte-identically (`<%= qr_sha8 %>...`); mutating `"bad op "` -> `"Q'$@{( "` (`54,815 B` canary, ROMs `45,784 B` / `49,997 B` / `45,443 B`) still completed **256 / 256 PASS** in **`2,783s` (`46.4 min`)**, preserved the mark in `QR2.aj`, and changed **256 / 256 intermediate step hashes**.
  - **Lap C (full-build `strace` audit)**: **256 / 256 PASS** in **`5,620s` (`93.7 min`)**, `ROUNDTRIP=OK`, `SUMS_OK=256`, **`2,472` `strace` findings** (`0` critical violations; `12` benign cross-step `QR*`/`qr*` accesses). Full details in [`proof/RESULT.txt`](proof/RESULT.txt) and [`proof/AUDIT.md`](proof/AUDIT.md).

## Engineering Notes

- **Fork additions standard**: All **128** additions in this fork use canonical third-party upstream compilers and interpreters, pass no code on the command line, do not read payload data from files or stdin, and write strictly to stdout (with zero custom fork esolang runners in `vendor/`).
- **Classic 10-trit Malbolge limitation**: Because strict A–Z ordering pushes the `M` section to several hundred kilobytes, this fork uses `Malbolge Unshackled` rather than classic 10-trit Malbolge (whose `59,049`-cell ternary memory limit stands unbroken in classic Malbolge).
- **Generated seed vs. hand-crafted original**: `QR.aj` (`<%= qr_size_fmt %> B`, `<%= qr_kib %> KiB`) is a generated, zlib-packed AspectJ program — a different engineering exercise from Endoh's hand-crafted `13,664 B` `QR.rb`.
- **11 stdlib zlib unpacker steps** (`C#`, `CoffeeScript`, `Elixir`, `F#`, `Go`, `Groovy`, `Mathics`, `PowerShell`, `Tcl`, `V`, `Zig`) use their own language's standard library zlib/deflate implementation (zero external decompression binaries).
- **`Piet` & `Shakespeare` memory/disk peaks**: `QR.ppm` peaks at `165.9 MB` (`158.2 MiB`) uncompressed PPM, and compiling `Shakespeare` (`gcc -O0` on `QR.spl.c` from `29.0 MB` / `27.6 MiB` `QR.spl`) peaks near `~21 GB` RSS in `cc1`; plan for **>= 24 GB RAM** in your Docker VM when running a full lap.
- Full step-by-step inventory, `vendor/` provenance, and Makefile/`strace` implementation notes live in [LANGUAGES.md](LANGUAGES.md), [RECORDS.md](RECORDS.md), [proof/AUDIT.md](proof/AUDIT.md), and [proof/RESULT.txt](proof/RESULT.txt).

## Quick Start (Standalone Docker Build & Offline Proof Lap)

```bash
docker build --pull --no-cache -t quine-relay-256 .
docker run --rm -it --network=none quine-relay-256
```

This builds Ubuntu 26.04 with all <%= step_count %> language toolchains, switches to non-root `USER qr`, and launches the live terminal visualizer around `make check -j 10000` (`QR.aj` -> `QR2.aj` offline, verifying `diff -s QR.aj QR2.aj` and `SHA256SUMS`). Omit `-it` (or pass `--plain`) for plain unmodified `make check` output, or run `make watch` / `python3 tools/relay_ui.py --demo` directly.

To regenerate `QR.aj` (with the `< 64,000 B` ROM guard, requiring `xa`, `z80asm`, and `uxnasm` on `PATH`) and all generated repository files inside the Ubuntu 26.04 Docker image:
```bash
cd src && rake
```

## History & Credits

- **2013–2026**: [Yusuke Endoh (@mametter)](https://github.com/mame/quine-relay) — original 50 / 100 / 128-language Quine Relay (MIT License).
- **2026-11-21**: `quine-relay-256` initial 256-language prototype (`QR.rb`).
- **2026-11-22**: Strict A–Z `AspectJ` seed refactor (`QR.aj`, non-root `USER qr`, `< 64,000 B` 6502/Z80/Uxntal ROMs).
- **2026-11-23**: Kept all 128 languages from upstream `mame/quine-relay` on the same upstream tools alongside 128 standalone additions = 256 steps (`QR.aj`).
- **2026-11-24**: Hardened `Ion` shell quoting using variable concatenation in 4,000-byte chunks (`QR.aj` `54,170 B`, v3.1), verified on all three offline Docker laps.
- **2026-11-25**: Experimental QR-code `QR.aj` (`133,101 B`), `Asm6502` `.byt` string and `ARM64` `.ascii` run compaction, `tools/relay_ui.py` visualizer (`CMD`), `langs.png`, `assets/payload-curve.png`, and `assets/terminal-demo.gif`.
- **2026-11-26**: Reverted `QR.aj` to the lean pure-code seed (`<%= qr_size_fmt %> B`, zero ASCII-art padding) while keeping `Asm6502`/`ARM64` compaction (lowering 16-bit ROMs to `45,842` / `50,152` / `45,626 B`), updated `tools/relay_ui.py` and `assets/terminal-demo.gif` to a bold `256` victory card, and verified across all three offline Docker laps (`256-v33-verify`, `187.3 min`).

See [LICENSE](LICENSE) for full MIT license terms.
