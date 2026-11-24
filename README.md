# Quine Relay 256 — Strict A–Z Edition ("The Endoh Stamp")

**128 from Yusuke Endoh's relay + 128 standalone additions = 256 steps in strict A–Z alphabetical order**, forming a closed self-reproducing loop (`AspectJ -> Asymptote -> ATS -> ... -> Zsh -> 6502 asm -> A+ -> ... -> Arturo -> AspectC++ -> AspectJ`).

This repository builds in gratitude on [Yusuke Endoh's (mame) Quine Relay](https://github.com/mame/quine-relay) (started in **2013**, MIT License). All **128 / 128** steps of Endoh's Ubuntu 26.04 relay are preserved intact (**"The Endoh Stamp"**) alongside **128** standalone fork additions running on canonical third-party upstream compilers and interpreters, verified offline in Docker (`--network=none`) as an unprivileged user (`USER qr`).

## Highlights

- **128 + 128 = 256 ("The Endoh Stamp")**: Every single step from Endoh's Ubuntu 26.04 relay (including `FORTRAN77`, `Gzip`, `JSFuck`, `Ook!`, and `WebAssembly (Binary format)`) stays intact by Endoh's own standard (`256` relay steps; `251` strict distinct languages, or `246` under a stricter no-superset/dialect lens — see the counting table in [RECORDS.md](RECORDS.md)). Every one of our **128** fork additions (`16/20` restored `mame` retirees + `Malbolge Unshackled` + `111` standalone languages) uses a canonical third-party upstream toolchain with zero custom fork runners in `vendor/` and zero fork-side tool accommodations.
- **Strict A–Z alphabetical order (`out of order: 0`)**: Ignoring case and punctuation, every step proceeds in A–Z order around the 256-step cycle, rotated to enter at **Step #1 `AspectJ` (`QR.aj`)** so all three 16-bit 64 KiB hardware/VM targets (`6502 asm`, `Z80 asm`, `Uxntal`) sit near the compact inner tail and assemble cleanly inside real `< 64 KiB` RAM/ROM limits (`Asm6502` 46,723 B / 65,012 B; `Z80 asm` 63,281 B / 64,991 B; `Uxntal` 57,065 B / 65,280 B), enforced by a `< 64,000 B` hard guard in `src/gen-aj.rb` and `src/vm-exec.rb`.
- **Self-reproducing AspectJ seed (`QR.aj`, `54,047 B`, `sha256: ed0fbe68...`)**: Genuine AspectJ (`aspect Q { before(): execution(void QR.main(..)) { ... } } public class QR { public static void main(String[] a) {} }`), storing its compressed engine + 224-step spec table in chunked printable-ASCII Base91 string literals (`java.util.zip.InflaterInputStream`), with zero file I/O, zero CLI code, and zero external processes. Inside the Ubuntu 26.04 Docker image (matching the image's system `zlib` and with `xa`, `z80asm`, and `uxnasm` on `PATH`), `cd src && rake` rebuilds `QR.aj` byte-identically; outside the image, different host `zlib` versions produce a valid, slightly different-sized `QR.aj` (e.g., `54,129 B`).
- **Verified offline proof lap ([proof/](proof/))**:
  - **256 / 256 steps PASS** (`39.9 min` / `2,396.8s`, `--network=none`, non-root `USER qr` `uid=1001`).
  - **Exact roundtrip**: `diff -s QR.aj QR2.aj` -> `Files QR.aj and QR2.aj are identical` (`54,047 B`).
  - **Full `SHA256SUMS`**: **256 / 256** step file hashes verified (`sha256sum --quiet -c SHA256SUMS`).
  - **Malbolge Unshackled `U20` parity**: `U20_PARITY=OK` (`Unshackled.c` vs `Unshackled-20.c` byte-identical on real `QR.mb` (`197,676 B` `QR.wl`) with zero `'/'` input ops executed, `0` stdin reads under `strace`, `MB_STDIN_SAME`).

## Transparency & Engineering Notes

This fork follows the principles Yusuke Endoh established for Quine Relay: no code on the command line, no reading payload from files or stdin, and output on stdout only. **246 / 256** steps (including **128 / 128** fork additions) pass all 7 static rules cleanly, verified with an automated `strace` + 1-byte engine canary lap confirming **0** fork-side tool accommodations and **256 / 256** live hash sensitivity.

Disclosed engineering details:
- **10 Endoh-method exceptions** (inherited unchanged from `mame/quine-relay`, run with Endoh's own commands):
  - **Rule 1 (self-operand input)**: `sed` (`sed -E -f QR.sed QR.sed`), `Mustache` (`mustache QR.mustache QR.mustache`), `XSLT` (`<?xml-stylesheet ... href=''?>`, `xsltproc QR.xslt`)
  - **Rule 2 (side file passed to next command)**: `Ook!` (`ruby vendor/ook-to-bf.rb QR.ook QR.ook.bf && ruby vendor/bf.rb QR.ook.bf`)
  - **Rule 3 (env/flag shaping output)**: `bc` (`BC_LINE_LENGTH=4000000 bc -q`), `MiniZinc` (`--soln-sep ''`), `Promela` (`spin -T`), `Jq` (`jq -r -n -f QR.jq`)
  - **Rules 4 / 6 (external echo or data decompression)**: `Execline` (`foreground { echo -n ... }`), `Gzip` (`gzip -cd QR.gz`)
  - **Inherited exit-code note**: `dc` (`dc QR.dc > QR.dhall || true`, marked `XXX` upstream in `mame/quine-relay`) masks `dc`'s exit status.
- **11 stdlib zlib unpacker steps** (`C#`, `CoffeeScript`, `Elixir`, `F#`, `Go`, `Groovy`, `Mathics`, `PowerShell`, `Tcl`, `V`, `Zig`) use their own language's standard library zlib/deflate implementation (zero external decompression binaries).
- **Classic 10-trit Malbolge caveat**: Because a strict A–Z pass pushes the `M`-section payload to several hundred kilobytes, this fork uses `Malbolge Unshackled` rather than classic 10-trit Malbolge (whose `59,049`-cell ternary memory limit remains un-bypassed in standard Malbolge).
- **`Shakespeare` (`gcc -O0` on `QR.spl.c`)** peaks around `~21 GB` RSS in `cc1`; plan for **>= 24 GB RAM** in your Docker VM when running a full lap.
- See [LANGUAGES.md](LANGUAGES.md) for all 256 steps in exact A–Z run order and [RECORDS.md](RECORDS.md) for the full counting table and `vendor/` inventory.

## Quick Start (Standalone Docker Build & Offline Proof Lap)

```bash
docker build --pull --no-cache -t quine-relay-256 .
docker run --rm --network=none quine-relay-256
```

This builds Ubuntu 26.04 with all 256 language toolchains, switches to non-root `USER qr`, executes all 256 steps from `QR.aj` -> `QR2.aj` offline (`make check -j 10000`), verifies `diff -s QR.aj QR2.aj`, and checks all 256 hashes in `SHA256SUMS`.

To regenerate `QR.aj` (with the `< 64,000 B` ROM guard, requiring `xa`, `z80asm`, and `uxnasm` on `PATH`) and all generated repo files inside the Ubuntu 26.04 Docker image:
```bash
cd src && rake
```

## History & Credits

- **2013–2026**: [Yusuke Endoh (@mametter)](https://github.com/mame/quine-relay) — original 50 / 100 / 128-language Quine Relay (MIT License).
- **2026-11-21**: `quine-relay-256` initial 256-language prototype (`QR.rb`).
- **2026-11-22**: `quine-relay-256` strict A–Z `AspectJ` seed refactor (`QR.aj`, non-root `USER qr`, `< 64,000 B` 6502/Z80/Uxntal ROMs).
- **2026-11-23**: `quine-relay-256` **"The Endoh Stamp"** edition — all 128/128 upstream Endoh steps restored intact + 128 standalone upstream-toolchain additions = 256 steps (`QR.aj` 54,047 B).

See [LICENSE](LICENSE) for full MIT license terms.
