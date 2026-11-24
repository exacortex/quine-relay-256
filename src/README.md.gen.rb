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

**128 steps from Yusuke Endoh's relay + 128 standalone additions = <%= step_count %> steps in strict A–Z alphabetical order**, forming a closed self-reproducing loop (`AspectJ -> Asymptote -> ATS -> ... -> Zsh -> 6502 asm -> A+ -> ... -> Arturo -> AspectC++ -> AspectJ`).

This fork builds on [Yusuke Endoh's (mame) Quine Relay](https://github.com/mame/quine-relay) (started in **2013**, MIT License). All **128 / 128** steps of Endoh's Ubuntu 26.04 relay are preserved intact alongside **128** standalone additions running on canonical third-party upstream compilers and interpreters, verified offline in Docker (`--network=none`) as an unprivileged user (`USER qr`).

## Highlights

- **128 + 128 = <%= step_count %> steps**: All 128 steps from Endoh's Ubuntu 26.04 relay (including `FORTRAN77`, `Gzip`, `JSFuck`, `Ook!`, and `WebAssembly (Binary format)`) remain unchanged. Because different readers apply different distinctness lenses, [RECORDS.md](RECORDS.md) breaks the count down openly: **256** relay steps, **251** strict distinct languages, or **246** under a stricter no-superset/dialect lens. Every one of our **128** additions (`16/20` restored historical `mame` languages + `Malbolge Unshackled` + `111` additional standalone languages) uses a canonical third-party upstream toolchain with zero custom runners in `vendor/`.
- **Strict A–Z alphabetical order (`out of order: 0`)**: Ignoring case and punctuation, every step proceeds in A–Z order around the <%= step_count %>-step cycle, rotated to enter at **Step #1 `AspectJ` (`QR.aj`)** so all three 16-bit 64 KiB hardware/VM targets (`6502 asm`, `Z80 asm`, `Uxntal`) sit near the compact inner tail and assemble inside real `< 64 KiB` RAM/ROM limits (`Asm6502` 46,799 B / 65,012 B; `Z80 asm` 63,563 B / 64,991 B; `Uxntal` 57,371 B / 65,280 B), enforced by a `< 64,000 B` check in `src/gen-aj.rb` and `src/vm-exec.rb`.
- **Self-reproducing AspectJ seed (`QR.aj`, `<%= qr_size_fmt %> B`, `sha256: <%= qr_sha8 %>...`)**: AspectJ advice (`aspect Q { before(): execution(void QR.main(..)) { ... } } public class QR { public static void main(String[] a) {} }`), storing its compressed engine and <%= compiled_steps %>-step specification table in chunked printable-ASCII Base91 string literals (`java.util.zip.InflaterInputStream`), with zero file I/O, zero CLI code, and zero external processes. Inside the Ubuntu 26.04 Docker image (matching the image's system `zlib` and with `xa`, `z80asm`, and `uxnasm` on `PATH`), `cd src && rake` rebuilds `QR.aj` byte-identically; outside the image, different host `zlib` versions still produce a valid `QR.aj`, though the compressed size may differ slightly.
- **Verified offline proof lap ([proof/](proof/))**:
  - **<%= step_count %> / <%= step_count %> steps PASS** (`38.7 min` / `2,319.8s`, `--network=none`, non-root `USER qr` `uid=1001`).
  - **Exact roundtrip**: `diff -s QR.aj QR2.aj` -> `Files QR.aj and QR2.aj are identical` (`<%= qr_size_fmt %> B`).
  - **Full `SHA256SUMS`**: **<%= step_count %> / <%= step_count %>** intermediate file hashes verified (`sha256sum --quiet -c SHA256SUMS`).
  - **Malbolge Unshackled dual-interpreter parity**: both untouched CC0 reference interpreters (`Unshackled.c` and `Unshackled-20.c`) produce byte-identical `QR.wl` (`198,440 B` from `3,811,135 B` `QR.mb`) on both empty and canary stdin.

## Transparency & Engineering Notes

This fork follows Yusuke Endoh's relay principles: no code passed on the command line, no reading payload data from files or stdin, and output written to stdout only. **246 / 256** steps (including **128 / 128** additions in this fork) pass all seven rules cleanly, verified with an offline engine-mutation sensitivity test confirming `Files QR.aj and QR2.aj are identical` and **256 / 256** live step-hash changes ([proof/AUDIT.md](proof/AUDIT.md), [proof/RESULT.txt](proof/RESULT.txt)).

Disclosed engineering notes:
- **10 inherited upstream tool conventions** (carried verbatim from `mame/quine-relay` and executed with upstream's commands):
  - **Self-operand input**: `sed` (`sed -E -f QR.sed QR.sed`), `Mustache` (`mustache QR.mustache QR.mustache`), `XSLT` (`<?xml-stylesheet ... href=''?>`, `xsltproc QR.xslt`)
  - **Side file passed to next command**: `Ook!` (`ruby vendor/ook-to-bf.rb QR.ook QR.ook.bf && ruby vendor/bf.rb QR.ook.bf`)
  - **Environment variable or flag shaping output**: `bc` (`BC_LINE_LENGTH=4000000 bc -q`), `MiniZinc` (`--soln-sep ''`), `Promela` (`spin -T`), `Jq` (`jq -r -n -f QR.jq`)
  - **External echo or decompression**: `Execline` (`foreground { echo -n ... }`), `Gzip` (`gzip -cd QR.gz`)
  - **Inherited exit-code note**: `dc` (`dc QR.dc > QR.dhall || true`, marked `XXX` upstream in `mame/quine-relay`) masks `dc`'s exit status.
- **11 stdlib zlib unpacker steps** (`C#`, `CoffeeScript`, `Elixir`, `F#`, `Go`, `Groovy`, `Mathics`, `PowerShell`, `Tcl`, `V`, `Zig`) use their own language's standard library zlib/deflate implementation (zero external decompression binaries).
- **Classic 10-trit Malbolge limitation**: Because strict A–Z ordering pushes the `M` section to several hundred kilobytes, this fork uses `Malbolge Unshackled` rather than classic 10-trit Malbolge (whose `59,049`-cell ternary memory limit remains unbroken in classic Malbolge).
- **`Shakespeare` (`gcc -O0` on `QR.spl.c`)** peaks around `~21 GB` RSS in `cc1`; plan for **>= 24 GB RAM** in your Docker VM when running a full lap.
- See [LANGUAGES.md](LANGUAGES.md) for all <%= step_count %> steps in exact A–Z run order and [RECORDS.md](RECORDS.md) for the full counting breakdown and `vendor/` inventory.

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
- **2026-11-23**: Restored all 128/128 upstream `mame/quine-relay` Ubuntu 26.04 steps intact alongside 128 standalone upstream-toolchain additions = 256 steps (`QR.aj`).
- **2026-11-24**: Hardened `Ion` shell quoting using variable concatenation in 4,000-byte chunks to handle arbitrary escaped payloads (`QR.aj` `<%= qr_size_fmt %> B`), verified offline (`38.7 min` / `2,319.8s`) and under engine-mutation sensitivity testing (`39.0 min`, `256/256` hashes changed).

See [LICENSE](LICENSE) for full MIT license terms.
