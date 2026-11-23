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

tpl = DATA.read.force_encoding("UTF-8")
File.binwrite(File.join(__dir__, "../README.md"), ERB.new(tpl, trim_mode: "%").result(binding).encode("UTF-8"))

__END__
# Quine Relay <%= step_count %> — Strict A–Z Edition

**<%= step_count %> distinct programming languages in strict A–Z alphabetical order**, forming a closed self-reproducing loop (`AspectJ -> Asymptote -> ATS -> ... -> Zsh -> 6502 asm -> A+ -> ... -> Arturo -> AspectC++ -> AspectJ`).

This repository builds on [Yusuke Endoh's (mame) Quine Relay](https://github.com/mame/quine-relay) (first published in **2013**, MIT License). Every step is a distinct standalone programming language (**<%= step_count %> steps = <%= step_count %> distinct languages**), verified offline in Docker (`--network=none`) as an unprivileged user (`USER qr`).

## Highlights

- **Strict A–Z alphabetical order (`out of order: 0`)**: Ignoring case and punctuation, every step proceeds in A–Z order around the <%= step_count %>-language cycle, rotated to enter at **Step #1 `AspectJ` (`QR.aj`)** so all three 16-bit 64 KiB hardware/VM targets (`6502 asm`, `Z80 asm`, `Uxntal`) sit near the compact inner tail and assemble cleanly inside real `< 64 KiB` RAM/ROM limits (`Asm6502` 43,323 B / 65,012 B; `Z80 asm` 63,541 B / 64,991 B; `Uxntal` 63,952 B / 65,280 B), enforced by a `< 64,000 B` hard guard in `src/gen-aj.rb` and `src/vm-exec.rb`.
- **Self-reproducing AspectJ seed (`QR.aj`, `<%= qr_size_fmt %> B`, `sha256: <%= qr_sha8 %>...`)**: Genuine AspectJ (`aspect Q { before(): execution(void QR.main(..)) { ... } } public class QR { public static void main(String[] a) {} }`), storing its compressed engine + 227-step spec table in chunked printable-ASCII Base91 string literals (`java.util.zip.InflaterInputStream`), with zero file I/O, zero CLI code, and zero external processes. Rebuilds byte-identical from `src/` via `ruby src/gen-aj.rb`.
- **Verified from-scratch offline proof lap ([proof/](proof/))**:
  - **From-scratch `ubuntu:26.04` Docker build (`docker build --pull --no-cache`)**: **80.2 min** on a fresh clone of commit `1727379` (image `qr256-1727379-scratch`, `sha256:a8ed91e7...`, non-root `USER qr`, `uid=1001`; [proof/SCRATCH-RESULT.txt](proof/SCRATCH-RESULT.txt)).
  - **Untouched default `CMD` (`make check -j 10000`) under `--network=none`**: **<%= step_count %> / <%= step_count %> steps PASS** in **32.1 min** (`Files QR.aj and QR2.aj are identical`, `<%= qr_size_fmt %> B`, **<%= step_count %> / <%= step_count %>** `SHA256SUMS` verified).
  - **Malbolge Unshackled `U20` parity ([proof/RESULT.txt](proof/RESULT.txt))**: `U20_PARITY=OK` (`Unshackled.c` vs `Unshackled-20.c` byte-identical on real `QR.mb` with `< /dev/null`, zero `'/'` input ops; full per-step log in [proof/run.log](proof/run.log)).

## Audit & No-Cheating Transparency

We follow the three principles Yusuke Endoh (mame) shared when reviewing earlier prototypes: (1) no code on the command line, (2) no reading files or stdin payload, and (3) output on stdout only.

A full per-step `strace` + canary audit found **0 critical violations** and **0 fork-specific borderline steps**: **248 / <%= step_count %> steps** pass all rules with zero exceptions (all 4 prior fork borderlines — `PureScript`, `Gleam`, `Pony`, `Z80 asm` — and 7 inherited borderlines — `C#`, `Visual Basic`, `bash`, `tcsh`, `zsh`, `ksh`, `Makefile` — have been eliminated cleanly).

**8 remaining disclosed borderline steps** (all inherited from upstream `mame/quine-relay` where the language/tool has no pure alternative):
- **Rule 1 (self-operand input, 3 steps)**: `sed` (`sed -E -f QR.sed QR.sed`), `Mustache` (`mustache QR.mustache QR.mustache`), `XSLT` (`<?xml-stylesheet ... href=''?>`).
- **Rule 3 (command/flag plumbing, 5 steps)**: `Execline` (`foreground { echo -n ... }`), `bc` (`BC_LINE_LENGTH=4000000`), `MiniZinc` (`--soln-sep ''`), `Promela` (`spin -T`), `Jq` (`jq -j -n -f QR.jq`).

Additional notes:
- **11 stdlib zlib unpacker steps** (`C#`, `CoffeeScript`, `Elixir`, `F#`, `Go`, `Groovy`, `Mathics`, `PowerShell`, `Tcl`, `V`, `Zig`) use their own language's standard library zlib/deflate implementation (no external tools).
- **`Shakespeare` (`gcc -O0` on `QR.spl.c`)** peaks at ~21 GB RSS in `cc1`; plan for **>= 24 GB RAM** in the Docker VM when running a full lap.
- See [LANGUAGES.md](LANGUAGES.md) for all <%= step_count %> languages in exact A–Z run order and [RECORDS.md](RECORDS.md) for counting rules (including the 128 vs 123 comparison table).

## Quick Start (Standalone Docker Build & Offline Proof Lap)

```bash
docker build --pull --no-cache -t quine-relay-256 .
docker run --rm --network=none quine-relay-256
```

This builds Ubuntu 26.04 with all <%= step_count %> language toolchains, switches to non-root `USER qr`, executes all <%= step_count %> steps from `QR.aj` -> `QR2.aj` offline (`make check -j 10000`), verifies `diff -s QR.aj QR2.aj`, and checks all <%= step_count %> hashes in `SHA256SUMS`.

To regenerate `QR.aj` (with the `< 64,000 B` ROM guard) and all generated repo files from `src/`:
```bash
ruby src/gen-aj.rb
```

## History & Credits

- **2013–2026**: [Yusuke Endoh (@mametter)](https://github.com/mame/quine-relay) — original 50 / 100 / 128-language Quine Relay (MIT License).
- **2026-11-21**: `quine-relay-256` initial release — 256 distinct languages (`QR.rb` 45,828 B, custom order).
- **2026-11-22**: `quine-relay-256` unified strict A–Z release — all 256 distinct languages in strict A–Z alphabetical order (`QR.aj` <%= qr_size_fmt %> B, AspectJ entry point, non-root `USER qr`, 248/256 clean / 0 critical / 0 fork borderlines, 256/256 `SHA256SUMS`, `U20_PARITY=OK`).

See [LICENSE](LICENSE) for full MIT license terms.
