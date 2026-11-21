# Quine Relay 256 — Technical Notes

A fork of Yusuke Endoh's (mame) [Quine Relay](https://github.com/mame/quine-relay) (128 languages on Ubuntu 26.04) rebuilt as an exact **256-step / 256-distinct-language** relay under Yusuke Endoh's no-cheating rules — preserving all **123** single-implementation languages from Endoh's current Ubuntu 26.04 relay, restoring **16/20** classic languages retired from earlier Ubuntu editions of `mame/quine-relay`, adding **Malbolge Unshackled**, and adding **116** standalone open-source languages.

## Composition (256 steps = 256 distinct languages)

| Group | Count | Notes |
|---|---:|---|
| **`mame-128` base (1:1 distinct)** | **123** | All 123 single-implementation languages from Endoh's Ubuntu 26.04 relay, including the verbatim no-read `Scilab -> sed -> Shakespeare -> S-Lang` chain. |
| **`mame-retired` restored** | **16 / 20** | Classic languages retired from earlier Ubuntu editions of `mame/quine-relay` (`AspectC++`, `Parrot asm`, `Boo`, `Dafny`, `Julia`, `Maxima`, `Gri`, `UCBLogo`, `GNU Smalltalk`, `GSL`, `nesC`, `Lisaac`, `eC`, `CDuce`, `A+`, `Falcon`). |
| **Malbolge Unshackled** | **1** | Unbounded Malbolge in the fused tail (`Python -> Malbolge Unshackled -> R -> Ratfor -> rc -> REXX`), generated from in-tree `src/malbolge-boot.dat.gen.py` and verified on both CC0 `Unshackled.c` and `Unshackled-20.c`. |
| **Standalone fork languages** | **116** | Standalone open-source languages running on real pinned compilers/interpreters under all three no-cheating rules. |
| **Total** | **256** | **256 steps, 256 distinct languages, 223 `CodeGen` classes.** |

---

## Master-Endoh Purity & Engineering Remediation

Before publishing, we ran a line-by-line adversarial audit of our initial 256-step prototype against Yusuke Endoh's standards and fixed every red-flag and gray-zone issue we found:

1. **Eliminated Step 166 `Makefile` temp-file + `tail` hack:** The initial 256 prototype had rewritten `mame`'s `Makefile` step to use `${file >QR_m,...}` and `tail -c+2 QR_m; rm -f QR_m` to work around Linux's 128 KiB `MAX_ARG_STRLEN`. We rewrote it to emit stdout directly via chunked `@printf '%s' '...'` recipes (`<= 25,000 B` chunks) with zero temporary files, zero `${file}`, zero `${shell}`, and zero `tail`.
2. **Replaced all 6 custom subset/mock interpreters with canonical upstream tools:**
   - `CJam`: replaced minimal `vendor/cjam.rb` stub -> official MIT `cjam-0.6.5.jar` (SourceForge, SHA-256 pinned).
   - `Glass`: replaced classless `vendor/glass.rb` mock -> official GPLv2 C++ `glass-0.12` (Gregor Richards, via `graue/esofiles@07dce2db`, zero source patches).
   - `><> (Fish)`: replaced custom `vendor/fish.py` -> official Jonathan `fish.py` (`gist/6392418@3b16018c`) paired with a 64x-unrolled 2D mirror-comb grid.
   - `Brain-Flak`: replaced custom `vendor/brain_flak.rb` -> official MIT C `Flakheads/CraneFlak` (`049f09ea`, `gcc -O3 -fcommon`).
   - `6502 asm`: replaced partial `vendor/run6502.py` -> official Ubuntu `apt` `sim65` (`cc65 2.19`, 128 B zero-page buffered `PVWrite`).
   - `Z80 asm`: replaced partial `vendor/runz80.py` -> official BSD-3-Clause C CP/M 2.2 emulator `tnylpo 1.2.2` running a genuine `ORG 0100h` CP/M `.com` binary via BDOS 6 raw console I/O.
3. **Removed licensing, banner-patch, and gray-zone steps (24 swapped cleanly 1-for-1):**
   - Removed proprietary closed-source `vendor/frink/frink.jar` (no open redistribution license) and banner-patched `Joy` (`Wodan58/joy0` `main.c` `sed` patch).
   - Removed 22 gray-zone dialects, supersets, config/query/markup formats, and foreign-FFI proof assistants (`Logtalk`, `Rocq`, `Agda`, `F*`, `ChucK`, `dash`, `NQP`, `es`, `Teal`, `MoonScript`, `YueScript`, `xonsh`, `Coconut`, `Ink`, `CUE`, `Pkl`, `Jsonnet`, `Nickel`, `Nix`, `XQuery`, `Wisp`, `Imba`) and replaced all 24 with standalone open-source languages (`MUMPS`, `Lobster`, `GNU APL`, `QBE`, `Hope`, `Clean`, `Miranda`, `Mirth`, `Grain`, `Flix`, `Boron`, `ChaiScript`, `MiniScript`, `Gluon`, `Effekt`, `Lily`, `HOC`, `PocketLang`, `Cyber`, `Dyon`, `Rye`, `Pawn`, `Austral`, `Vale`) running on pinned official toolchains.
4. **Reproducible Malbolge Unshackled generator + scaled Ouroboros art:**
   - Added standalone `src/malbolge-boot.dat.gen.py` (Python 3 stdlib) wired into `src/Rakefile`, matching Endoh's `blc-boot.dat.gen.rb` / `grass-boot.dat.gen.rb` / `lazyk-boot.dat.gen.rb` convention so zero opaque binary blobs live without source in `src/`.
   - Scaled `src/uroboros.txt` proportionally from `src/uroboros.svg` via `tools/gen_uroboros_txt.py` so the Ouroboros dragon keeps Endoh's visual proportions (`113x397`, `25.86%` silhouette area) rather than shrinking inside a 403-column code block.
5. **Hygiene, pinning, and honest disclosure:**
   - Pinned previously floating installs (`MMIX`, `ArnoldC.jar`, `SNOBOL4 2.3.3`, `Uxntal`, `Pyth`, `Roc 0.0.0-alpha1` + offline local `basic-cli 0.18.0`), removed `/usr/local/bin/clang -> gcc` shadow, moved `PureScript` build output from global `/opt/purs/out` to local `./purs_out` (with explicit `o :: Unit`), added conditional `QR.c` `Backup` + `-b -w` to `Simula`, fixed `Makefile clean:` and `src/Rakefile CLEAN`, fixed `vendor/beatnik.rb` (halt strictly on score 17) and `vendor/slashes.rb` (exact leftmost substitution spec), removed stale `--privileged` from CI and `.github/FUNDING.yml`, and added a root `LICENSE` cleanly separating MIT code from third-party `vendor/` archives.
   - Disclosed all inherited `mame/quine-relay` precedents (`sed`, `Mustache`, `Dhall`, `XSLT`, `M4`, `Flex`, `CMake`, `Promela`, `dc || true`, `.NET` `tmp.*proj`) and fork accommodations (`Lazy K` `RDSTACK_SIZE`, `Taxi` `-DNO_GREETINGS`, `A+` `2> /dev/null`, and retained spec-complete MIT `vendor/` runners) openly in `README.md`, `RECORDS.md`, and `vendor/README`.

*(Prior cleanup from `quine-relay-267`: dropped the 10 non-distinct Tier-2 steps — `Ook!`, `JSFuck`, `WebAssembly (Binary format)`, `FORTRAN77`, `Gzip`, `mksh`, `BusyBox ash`, `yash`, `Chicken Scheme`, `Chez Scheme` — plus `Genie`, `groff`, `Starlark`, `Rego`, `Hush`, and `Deadfish~`, and rewrote `Berry` from `open("/dev/stdout","w")` to plain `print(...)`.)*

---

## Key Engineering Solutions

### 1. Malbolge Unshackled (zero `'/'` input op, rotwidth-independent, ~0.3 s)

Classic 10-trit Malbolge has a hard 59,049-cell address space, far below relay payload sizes. **Malbolge Unshackled** removes the memory cap with unbounded trits, introducing three genuine algorithmic obstacles:

1. **Exact UTF-8 output (`<`):** Unlike classic Malbolge (`a % 256`), `Unshackled.c` prints the exact integer in `a`, requiring `head = 0` and exact `0 <= a < 128`.
2. **Non-deterministic `rotwidth`:** `Unshackled.c` initializes `rotwidth = 10 + rand() % 6` (from `time(NULL)`) and grows it dynamically on `j`, whereas `Unshackled-20.c` uses fixed `rotwidth = 20`. Any `rot` (`*`) with `x % 3 != x.head` leaks `rotwidth` into upper trits.
3. **The `trit4 == 2` reachability wall without `'/'` (`in`):** Without reading stdin (`/`), `head` stays closed in `{0, 1}` and all raw ASCII cells (`33..126`) have `trit4 in {0, 1}`. Since `CRZ[0][0] == CRZ[1][0] == 1` and `CRZ[0][1] == CRZ[1][1] == 0`, `opr` alone cannot reach ASCII `81..127` (including all lowercase letters) until a `rot` synthesizes `trit4 == 2`.

Our solution sits in the fused tail (`Python -> Malbolge Unshackled -> R -> Ratfor -> rc -> REXX`, step 252 of 256, `0 B` upstream bloat):

- **1,571-byte rotwidth-independent 4-phase bootstrapper** (`src/malbolge-boot.dat`, reproducibly generated by `src/malbolge-boot.dat.gen.py` as an `860 B` base64+zlib payload): locks `max_wordwidth = 4`, runs a 17-cell zero-hazard probe loop (`57*R + 451` steps for any `R >= 10`) that converges to an exact `R`-independent state `(c = 1571, a = 116, d = 123)`, synthesizes `trit4 == 2` via two zero-drift `rot`s (`1458 -> 486 -> 162`), and stamps it across 34 cells of a 100-cell constant ring. Audited 27/27 across `R in {10, 11, 12, 13, 14, 15, 20, 30, 50}` x `{fixed, det, aggressive}` growth policies with **zero `'/'` executions**.
- **Straight-Line Guardian-Ring BFS (`c >= 1571`):** searches normalized `(head in {0,1}, 5 low trits)` states using inverse `opr` lookahead and zero-drift `rot`, with dynamic `min_t = 20` guardian masks preventing trit depletion (`0` fallbacks). Emits strictly `{'*', '<', 'j', 'o', 'p', 'v'}` (0 `'/'`, 0 `'i'`), 100% printable ASCII `33..126`, terminating on a real `v` halt.
- **Verified parity & performance:** On the 256-step tail (`QR.mb = 470,410 B`, ~9.83 cells/byte -> `QR.R = 47,845 B`), both untouched CC0 interpreters (`Unshackled.c` and `Unshackled-20.c`, tested in isolation with `< /dev/null` in an empty directory and empty environment) emit byte-identical `QR.R` (SHA-256 `04832d3cd25e35b063d9ccb16679c6b22c4a3b4fddcb41007fb89ce5e99135d9`, `U20 parity: OK`) in **`0.324 s`** (`Unshackled.c`) and **`0.056 s`** (`Unshackled-20.c`), closing `QR2.rb == QR.rb` byte-for-byte.

### 2. Restoring mame's clean `Scilab -> sed -> Shakespeare -> S-Lang`

In the 267-step build, mame's 4-step `Scilab_Sed_Shakespeare_SLang` group was temporarily dropped because our earlier 284 prototype had `S-Lang` read `QR.sed` with `fopen` (violating rule 2), and mame's clean template expands non-backslash payloads ~25–32x (`spl2c` is `O(N^2)` in `QR.spl` size).

We restored Endoh's exact, verbatim, zero-`fopen` `Scilab_Sed_Shakespeare_SLang` class by placing it in the optimized tail (steps 240–243, directly after `Z80 asm` and before `ksh -> Lazy K -> LiveScript`):

- Its input payload (`QR.ksh`) is **`63,088 B`**, compressing under `rp[PREV, 127..255]` to **`QR.sl = 32,086 B`**.
- All 4 steps execute cleanly (`QR.sci = 1,451,094 B`).
- Because `QR.sci` is 99% repetitive Shakespeare sentences (`"You are as bad as... a son.Speak thy mind."`), `Z80 asm`'s Re-Pair compressor directly upstream packs `QR.sci` cleanly back into a **`52,444 B`** Z80 ROM under its 64 KB budget, preventing any upstream cascade.

### 3. Run-order optimization & 64 KB VM ROM budgets

Using an exact-evaluated ATSP / local-search order optimizer (`xsearch.py` + `worker.rb` + `junction.rb` AST-parenthesis parity gate) keeps total intermediate volume small while satisfying every escaping and memory constraint:

| Metric | Unreordered 256 | Optimized Master-Endoh 256 | Margin / Notes |
|---|---:|---:|---|
| Total class-boundary intermediates (`amap2`) | `~1,100 MB` | **`325.45 MB`** (`325,450,740 B`) | **-70.4%** |
| Total all 256 real intermediate files | — | **`520.98 MB`** (`520,982,742 B`) | Peak: `QR.mid` (`66.40 MB`) |
| Step 1 `Ruby` output (`QR.sim`) | — | **`9.48 MB`** (`9,482,588 B`) | — |
| `QR.rb` seed size (LF, `113x397`) | — | **`44,974 B`** | `175.7 B/step`, SHA-256 `36d70b16...` |
| `6502 asm` real assembled ROM (step 237) | — | **`63,113 B`** | **+2,423 B** under 64 KiB (+1,899 B under `sim65` RAM cap) |
| `Uxntal` real assembled ROM (step 238) | — | **`57,470 B`** | **+8,066 B** under 64 KiB (+7,810 B under Varvara RAM) |
| `Z80 asm` real assembled ROM (step 239) | — | **`52,444 B`** | **+13,092 B** under 64 KiB (+12,580 B under CP/M TPA) |
| `Ksh_LazyK_LiveScript` boundary input (`QR.bsh`) | — | **`54,644 B`** | Class boundary fed into `ksh -> Lazy K -> LiveScript` |
| `Lazy K` actual payload (`QR.ls`, step 245) | — | **`61,604 B`** (`<= 95,000`) | **+33,396 B** margin |
| `C` LZ77 input size | — | **`3.35 MB`** (`< 5.00 MB`) | **+1.65 MB** margin |
| `amap2.rb` checks / `junction.rb` | — | **`0` fails / `bare == parenthesized? true`** | 223 / 223 classes |
| Clean `docker build --pull --no-cache` | — | **`59.1 min`** (`40` RootFS layers, `27.79 GB`) | Verified 2026-11-21 from `ubuntu:26.04` |
| Full `make check -j 10000` lap time | — | **`27.6 min`** (`256/256` `SHA256SUMS` + `U20 parity: OK`) | Image `47335f5a...` ([proof](proof/)) |

### 4. Subtle runtime traps caught and guarded permanently

- **`Glass` & `Taxi`:** With `Deadfish~` removed, `Glass` runs on the canonical upstream interpreter with arbitrary-ASCII output, and `Taxi` uses native `\\`/`\n` escapes (`QR.taxi = 185,584 B`, down from `17.6 MB` in the pre-cleanup `Deadfish~` layout; `118.8 KB` in the Nov 19 proof).
- **`GSL` 1024-byte chunk `.` parser bug:** `gsl` aborts when a chunk boundary falls on `.` inside a `>= 1,024`-byte line; permanent `GeneratorScriptingLanguage#check` guards prevent this automatically.
- **Corridor engineering:** tilde-delimited backslash-free `Forth`, 500-call `Fortran 90` subroutines, `Scheme` RLE backslash packing, 400-statement procedure chunking in `Simula`/`Oberon`/`ALGOL 60`, `Kotlin` base-78 LZ78 compression, JVM 64 KB constant-pool chunking, and Re-Pair compression across the 64 KB VMs.

---

## The 133 languages added by this fork

| Theme | Languages |
|---|---|
| **Malbolge (1)** | Malbolge Unshackled |
| **Restored `mame` retirees (16)** | A+, AspectC++, Boo, CDuce, Dafny, eC, Falcon, GNU Smalltalk, Gri, GSL (Generator Scripting Language), Julia, Lisaac, Maxima, nesC, Parrot asm (PASM), UCBLogo |
| **Dynamic, scripting & embeddable (24)** | Anko, Arturo, Berry, Boron, ChaiScript, Cyber, Dart, Dyon, Gravity, Io, Janet, Koto, Lily, Lobster, MiniScript, Pawn, PocketLang, Rhai, Ring, Rye, TXR, Tengo, Umka, Wren |
| **Functional, Lisp & ML (17)** | Clean, Effekt, Gluon, Grain, Hope, Hy, Idris 2, Koka, LFE, Lean 4, Miranda, Mirth, PicoLisp, Racket, Roc, newLISP, rep (librep) |
| **Historical & classic (9)** | ALGOL 60, Euphoria, Factor, HOC, MUMPS, Oberon, SNOBOL4, Seed7, Simula |
| **Modern systems (12)** | Austral, C3, Chapel, Gleam, Hare, Inko, Nelua, Odin, Pony, V, Vale, Zig |
| **JVM & JS targets (10)** | Ballerina, Fantom, Flix, Frege, Golo, Gosu, PureScript, Pyret, ReScript, Yeti |
| **Modern shells (6)** | Elvish, Ion, Murex, Nushell, PowerShell, YSH |
| **Logic, rules & query (4)** | CLIPS, Mercury, Picat, SQL (SQLite) |
| **Array, math & HDL (12)** | BQN, GNU APL, J, K (ngn/k), Klong, Macaulay2, Mathics, Nial, Numbat, Singular, Uiua, VHDL |
| **Assembly, IR & tiny VMs (7)** | 6502 asm, ARM64 asm, MMIX, QBE, RISC-V asm, Uxntal, Z80 asm |
| **Esoteric languages (15)** | ///, ><> (Fish), ArnoldC, Beatnik, Brain-Flak, CJam, Emmental, Glass, Hexagony, Kipple, Pyth, Rail, Rockstar, Taxi, Underload |

*(All 133 languages above + all 123 single-implementation `mame-128` languages = **256 distinct languages**; see [LANGUAGES.md](LANGUAGES.md) for the exact run order.)*

## Credits & License

Original Quine Relay design, uroboros generator, and MIT license: **Yusuke Endoh (@mametter)** and contributors.
Malbolge Unshackled CC0 reference interpreters (`Unshackled.c`, `Unshackled-20.c`): **Matthias Lutter** (CC0 1.0 Public Domain).
256-language extension, Malbolge Unshackled bootstrapper/BFS, run-order optimization, and verification: **Drawn With Code (@exacortex / @rasteia)**, MIT license (excluding third-party `vendor/` archives; see [LICENSE](LICENSE) and [vendor/README](vendor/README)).
