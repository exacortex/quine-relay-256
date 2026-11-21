# Quine Relay 256

**A 256-language quine relay extending [Yusuke Endoh's Quine Relay](https://github.com/mame/quine-relay) — preserving all 123 single-implementation languages from Endoh's Ubuntu 26.04 relay, restoring 16/20 languages retired from its earlier Ubuntu editions, adding Malbolge Unshackled, and adding 116 standalone open-source languages.**

This fork targets a strict 1-to-1 count (**steps = distinct languages = 256**), omitting the 5 alternate encodings/versions/formats from the 128-step base (`Ook!`, `JSFuck`, `WebAssembly (Binary format)`, `FORTRAN77`, `Gzip`) and avoiding duplicate shell/Scheme/dialect entries so every step is a distinct programming language.

## What this is

[QR.rb](QR.rb) is a Ruby program that generates
a Simula program that generates
an Oberon program that generates
...(through 256 distinct languages in total)...
a REXX program that generates
the original Ruby code again.

![Language Uroboros][langs]

[langs]: langs.png

The languages in red are the 133 languages added in this fork. Everything in black is from Yusuke Endoh's Ubuntu 26.04 `mame/quine-relay`.

## The rules every step follows

Yusuke Endoh (mame) reviewed an earlier prototype and shared three no-cheating principles he uses as a matter of craft and fairness. Every step added or modified in this fork follows all three (with the inherited `mame/quine-relay` `sed` and `Mustache` self-operand steps noted transparently below):

1. **No code on the command line.** A command names the program file and sets compiler or interpreter options. It never passes program source or query expressions on the CLI (`node -e '...'`, `printf` shims, etc.).
2. **No reading files.** Programs do not open their own source, another step's file, or `/dev/stdout`, and do not consume payload via stdin (including Malbolge's `'/'` opcode). All printed text lives inside the program.
3. **Output on stdout only.** No writing a temporary file and printing it with `cat`/`tail`, no redirecting stderr into the output file (`2> OUTFILE`), and no filtering a tool's stdout with `tail`, `grep`, or `tr`.

### Upstream precedents and build disclosures

In the spirit of complete transparency, this fork inherits the same minimal toolchain precedents already present in upstream `mame/quine-relay`, and discloses its own minor accommodations explicitly:

- **Inherited from `mame/quine-relay`:** `sed -E -f QR.sed QR.sed` and `mustache QR.mustache QR.mustache` (passing the source file as the template/input operand required by those tools), shell/build steps invoking standard Unix utilities (`bash` calling `sed`, `tcsh`/`zsh` calling `cat`, `ksh` calling `od`, `Makefile` calling `@printf`, `Execline` calling `echo`), `Dhall`, `XSLT`, `M4`, `Flex`, `CMake`, `Promela` (`spin -T`), `dc ... || true`, `.NET` `tmp.*proj` project manifests (`C#`, `Visual Basic`; `F#` now runs offline via `dotnet fsi` with no project file or NuGet access), `mv` collision backups (`LLVM asm`, `Octave`, `G-Portugol`, `INTERCAL`, `LiveScript`, plus `Simula`), and minimal self-made MIT Ruby interpreters under `vendor/` for classic esolangs.
- **Disclosed fork accommodations:**
  - `Lazy K` (`vendor/lazyk.c`, MIT): `RDSTACK_SIZE` is raised from `100,000` to `10,000,000` (and run with `ulimit -s unlimited`) so the interpreter's reduction stack handles 256-step payloads without altering Lazy K semantics.
  - `Taxi`: compiled with BigZaphod's official upstream `-DNO_GREETINGS` preprocessor flag (suppresses Taxi's startup banner without modifying source).
  - `A+`: invoked as `a+ QR.aplus.a > OUTFILE 2> /dev/null < /dev/null` to discard interpreter diagnostics on stderr and close interactive stdin (stdout is untouched).
  - `Gleam`: uses a minimal `gleam.toml` manifest alongside `QR.gleam` (analogous to `.NET` `tmp.*proj`) and binds BEAM's built-in `io:put_chars/1` and `string:replace/4` via `@external(erlang, ...)` (the same Erlang primitives wrapped by official `gleam_stdlib`) so `QR.gleam` compiles 100% offline with zero package downloads.
  - `Z80 asm`: `tnylpo` (CP/M 2.2 emulator) refuses UID 0 for safety, so the step recipe guards `setpriv --reuid=nobody --regid=nogroup --clear-groups` on `id -u = 0` and runs `tnylpo -b qr.com` directly for non-root users.
  - `K (ngn/k)`: built from a pinned vendored `AGPLv3` source tarball (`vendor/ngnk-b9eeb91e.tar.gz`) because upstream Codeberg archived the repository.
  - `vendor/` esolang runners: every bundled interpreter and runner (both upstream `mame` and fork-authored MIT runners such as `underload.rb`, `emmental.rb`, `slashes.rb`, and `beatnik.rb`) is listed explicitly in the table below and in [`vendor/README`](vendor/README). Where canonical upstream interpreters or emulators exist (`CJam`, `Glass`, `><> (Fish)`, `Brain-Flak`, `6502 asm`, `Z80 asm`), this fork uses the real upstream tool rather than a custom stub.

All 123 single-implementation languages from Endoh's Ubuntu 26.04 relay — including the verbatim, zero-`fopen` `Scilab -> sed -> Shakespeare -> S-Lang` chain — run intact alongside **Malbolge Unshackled** (self-contained, rotwidth-independent, zero `'/'` input executions, built from an in-tree generator `src/malbolge-boot.dat.gen.py` and verified byte-exact on both untouched CC0 `Unshackled.c` and `Unshackled-20.c`).

## Proof that it works

This repository's [`Dockerfile`](Dockerfile) builds from scratch (`docker build --pull --no-cache`, `FROM ubuntu:26.04`, 67.3 min, 27.79 GB, 40 RootFS layers, image `d7666b94...`) and passes its untouched default `CMD` (`make check -j 10000`) **100% offline (`docker run --rm --network=none`)** in 23.6 min:

- **All 256 languages run in sequence offline** inside one self-contained Ubuntu 26.04 Docker image with pinned open-source toolchains and bundled `vendor/` interpreters (zero network calls during execution).
- **Every intermediate file matches [`SHA256SUMS`](SHA256SUMS)** (all 256 of them, verified by `sha256sum --quiet -c SHA256SUMS` inside the image's own default `CMD`).
- **Step 256 (REXX) prints `QR2.rb`, byte-for-byte identical to `QR.rb`** (45828 bytes, SHA-256 `ff759bc61e2bb755dccc48e8ba46c15318a9529a6ac8efe434e8fd238928728d`).
- **Canary & dual-interpreter checks:** verified byte-exact on both `Unshackled.c` and `Unshackled-20.c` (`U20 PARITY OK`), plus a full 256-step offline canary loop (`Drawn With Code` -> `Drawn With K0de` under `--network=none`, closing `QR2.rb == modified QR.rb`).

The full build log, offline run log, and verification result live in [`proof/`](proof/). Anyone can reproduce the entire proof with the two Docker commands under Usage.

## What's new in this fork

**133 languages added beyond Endoh's current Ubuntu 26.04 relay** (16/20 restored from earlier Ubuntu editions of `mame/quine-relay`, **Malbolge Unshackled**, and 116 standalone open-source languages):

Simula, Oberon, Euphoria, ALGOL 60, Rhai, Dart, Hexagony, K (ngn/k), Hare, Golo, Nial, Uiua, BQN, Fantom, Umka, Frege, J, Ring, PowerShell, MUMPS, MiniScript, Boron, Mirth, Lily, Ballerina, VHDL, Mathics, newLISP, Nelua, Hy, Berry, ChaiScript, Gluon, PureScript, MMIX, Pyth, Emmental, Lobster, Factor, Ion, GSL (Generator Scripting Language), ArnoldC, LFE, Cyber, PocketLang, Nushell, Gosu, YSH, Tengo, Anko, Murex, Picat, Falcon, ><> (Fish), V, Singular, Idris 2, Koto, Janet, C3, Io, Zig, Wren, Pyret, ReScript, Dafny, Julia, Maxima, Gri, UCBLogo, Miranda, Clean, Macaulay2, Lisaac, Koka, GNU Smalltalk, Boo, CDuce, TXR, nesC, Gravity, Racket, A+, ARM64 asm, SQL (SQLite), Parrot asm (PASM), RISC-V asm, Yeti, AspectC++, Numbat, Gleam, Dyon, Rye, eC, Roc, Effekt, Inko, QBE, GNU APL, Vale, Pawn, Chapel, Pony, Mercury, Odin, Arturo, PicoLisp, Elvish, Lean 4, ///, CJam, Underload, Brain-Flak, SNOBOL4, Klong, Seed7, Rail, Kipple, Beatnik, CLIPS, Rockstar, Glass, Taxi, rep (librep), Grain, HOC, Flix, Hope, Austral, 6502 asm, Uxntal, Z80 asm, Malbolge Unshackled.

[RELAY-256.md](RELAY-256.md) explains the compression architecture, run-order optimization (~1,100 MB down to 316.24 MB), 64 KB VM ROM budgets, and Malbolge Unshackled generator. [RECORDS.md](RECORDS.md) documents the counting rules and [LANGUAGES.md](LANGUAGES.md) lists all 256 languages in run order.

## Usage

### Docker (recommended)

    $ docker build -t qr .
    $ docker run --rm --network=none qr

This installs every Ubuntu package, builds all pinned toolchains and bundled interpreters in `vendor/`, runs all 256 steps offline in order (unprivileged), and verifies `QR2.rb == QR.rb`. Note that the full image requires roughly ~28 GB of disk space (~40+ GB free during build).

### Ubuntu 26.04

#### 1. Install the Ubuntu packages and extra toolchains.

    $ sudo apt-get install 9base afnix algol68g aspectc++ aspectj asymptote \
      ats2-lang bash bc bsh cc65 clips clisp clojure cmake coffeescript \
      crystal dc default-jdk-headless dhall dotnet-sdk-10.0 elixir elvish \
      emacs-nox erlang erlang-nox execline fennel fish flex fp-compiler g++ \
      gambas3-gb-pcre gambas3-scripter gap gawk gcc gcc-aarch64-linux-gnu \
      gcc-riscv64-linux-gnu gdb gdc generator-scripting-language genius \
      gforth gfortran ghc ghdl ghostscript gm2 gnat gnucobol4 gnuplot gobjc \
      golang gpt gri groovy guile-3.0 hare haxe hy icont iconx intercal \
      iverilog jasmin-sable jq kotlin ksh libevent-dev libpolyml-dev \
      livescript llvm lua5.3 m4 macaulay2 make maxima minizinc mono-devel \
      nasm neko newlisp nickle nim node-typescript nodejs ocaml octave \
      openjdk-25-jdk pari-gp parser3-cgi perl php-cli picolisp pike8.0 \
      polyml python3 qbe qemu-user r-base racket rakudo ratfor rc \
      regina-rexx rep ruby ruby-mustache rustc scala scilab-cli sed singular \
      slsh spin sqlite3 squirrel3 surgescript swi-prolog swiftlang tcl tcsh \
      valac vim wabt xa65 xsltproc yabasic yorick z80asm zoem zsh

For the remaining languages installed from pinned releases, cargo, Go, npm, pip, or source tarballs, see [`Dockerfile`](Dockerfile) (generated from [`src/Dockerfile.gen.rb`](src/Dockerfile.gen.rb) and [`src/extra-installs/`](src/extra-installs/)).

Then build the bundled interpreters:

    $ sudo apt-get install cmake libpng-dev libgd-dev libfl-dev bison curl unzip
    $ make -C vendor

#### 2. Run each program on each interpreter/compiler.

    $ ulimit -s unlimited
    $ ruby QR.rb > QR.sim
    $ cim -q -b -w QR.sim && ./QR > QR.obn && rm -f QR QR.o
    $ rm -rf QR .obnc && obnc QR.obn >/dev/null && ./QR > QR.ex && rm -rf QR .obnc
    $ eui QR.ex > QR.alg
    $ marst QR.alg -o QR.alg.c && gcc QR.alg.c -lalgol -lm -o QR && ./QR > QR.v &&
      rm -f QR QR.alg.c
    $ iverilog -o QR QR.v && ./QR -vcd-none > QR.ss
    $ surgescript QR.ss > QR.tcl
    $ tclsh QR.tcl > QR.rhai
    $ rhai-run QR.rhai > QR.dart
    $ dart run QR.dart > QR.gel
    $ genius QR.gel > QR.hxg
    $ ruby /opt/hexagony/interpreter.rb QR.hxg > QR.k.k
    $ ngnk QR.k.k < /dev/null > QR.azm
    $ zoem -i QR.azm > QR.ha
    $ hare build -q -o QR QR.ha && ./QR > QR.golo
    $ golo golo --files QR.golo > QR.scala
    $ scalac QR.scala && scala QR > QR.ndf
    $ nial -defs QR.ndf < /dev/null > QR.yab
    $ yabasic QR.yab > QR.ua
    $ uiua run --no-format QR.ua > QR.bqn
    $ bqn QR.bqn > QR.fan
    $ fan QR.fan > QR.um
    $ umka QR.um > QR.vim
    $ vim -EsS QR.vim > QR.fr
    $ mkdir -p frege-out && frege -d frege-out QR.fr && java -cp frege-out:/usr/local/lib/frege.jar QR > QR.ijs
    $ ijconsole QR.ijs < /dev/null > QR.ring
    $ ring QR.ring > QR.dats
    $ patscc -o QR QR.dats && ./QR > QR.ps1
    $ DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=1 POWERSHELL_TELEMETRY_OPTOUT=1 pwsh -NoProfile -NonInteractive -File QR.ps1 > QRMUMPS.m
    $ ydb_dist=/opt/yottadb ydb_routines=. /opt/yottadb/yottadb -run QRMUMPS > QR.ms
    $ miniscript QR.ms > QR.boron
    $ boron QR.boron > QR.mk
    $ make -f QR.mk > QR.mth
    $ mirth -p std:/opt/mirth/lib/std -p qr:. ./QR.mth -o QR.mth.c > /dev/null &&
      gcc -O2 -Wno-trigraphs -o QR QR.mth.c && ./QR > QR.lily
    $ lily QR.lily > qr.adb
    $ gnatmake qr.adb && ./qr > QR.aj
    $ ajc QR.aj && java -cp .:/usr/share/java/aspectjrt.jar QR > QR.asy
    $ asy QR.asy > QR.bal
    $ bal run --offline QR.bal > QR.scm
    $ guile QR.scm > QR.vhdl
    $ ghdl -a QR.vhdl && ghdl -e qr && ghdl -r qr > QR.bash
    $ bash QR.bash > QR.bc
    $ BC_LINE_LENGTH=4000000 bc -q QR.bc > QR.rs
    $ rustc QR.rs && ./QR > QR.e
    $ execlineb QR.e > QR.yorick
    $ yorick -batch QR.yorick > QR.wl
    $ mathics -q --no-completion -f QR.wl < /dev/null > QR.nl
    $ newlisp -n QR.nl > QR.awk
    $ awk -f QR.awk > QR.nelua
    $ nelua --no-cache QR.nelua > QR.hy
    $ hy QR.hy > QR.be
    $ berry QR.be > QR.chai
    $ chai QR.chai > QR.glu
    $ gluon QR.glu > QR.purs
    $ purs compile -o purs_out QR.purs '/opt/purs/lib/*/src/**/*.purs' &&
      node purs_out/QR/index.js > QR.c && rm -rf purs_out
    $ gcc -o QR QR.c && ./QR > QR.cpp
    $ g++ -o QR QR.cpp && ./QR > QR.mms
    $ mmixal -b 2000000 -o QR.mmo QR.mms && mmix QR.mmo > QR.pyth &&
      rm -f QR.mmo
    $ python3 /opt/pyth/pyth.py -n QR.pyth > QR.emmental
    $ ruby vendor/emmental.rb QR.emmental > QR.lobster
    $ lobster QR.lobster > QR.factor
    $ /opt/factor/factor QR.factor > QR.ion
    $ ion QR.ion > QR.gsl
    $ gsl -q QR.gsl > QR.arnoldc
    $ rm -f QR.class && java -jar /opt/ArnoldC.jar QR.arnoldc && java QR > QR.lfe &&
      rm -f QR.class
    $ lfe QR.lfe > QR.cy
    $ cyber QR.cy > QR.pk
    $ pocket QR.pk > QR.d
    $ gdc -o QR QR.d && ./QR > QR.nu
    $ nu --no-config-file QR.nu > QR.gsp
    $ gosu QR.gsp > QR.ysh
    $ ysh QR.ysh > QR.tengo
    $ tengo QR.tengo > QR.coffee
    $ coffee --nodejs --stack_size=100000 QR.coffee > QR.lisp
    $ clisp QR.lisp > QR.cr
    $ crystal QR.cr > QR.ank
    $ anko QR.ank > QR.el
    $ emacs -Q --script QR.el > QR.dc
    $ dc QR.dc > QR.dhall || true
    $ dhall text --file QR.dhall > QR.exs
    $ elixir QR.exs > QR.erl
    $ escript QR.erl > QR.mx
    $ murex QR.mx > QR.fnl
    $ fennel QR.fnl > QR.tcsh
    $ tcsh QR.tcsh > QR.t
    $ ruby vendor/thue.rb QR.t > QR.hx
    $ haxe -main QR -neko QR.n && neko QR.n > QR.g
    $ gap -q QR.g > QR.zsh
    $ zsh QR.zsh > QR.nut
    $ squirrel QR.nut > QR.gdb
    $ gdb -q -x QR.gdb > QR.pi
    $ picat QR.pi > QR.fs
    $ gforth QR.fs > QR.f90
    $ gfortran -o QR QR.f90 && ./QR > QR.fal
    $ falcon QR.fal > QR.fish
    $ fish QR.fish > QR.false
    $ ruby vendor/false.rb QR.false > QR.xslt
    $ xsltproc QR.xslt > QR.go
    $ go run QR.go > QR.fl
    $ flex -o QR.fl.c QR.fl && gcc -o QR QR.fl.c && ./QR > QR.fsx
    $ DOTNET_NOLOGO=1 dotnet fsi --quiet --exec QR.fsx > QR.fish.fish
    $ python3 /opt/fish/fish.py QR.fish.fish > QR.vlang.v
    $ v run QR.vlang.v > QR.sing
    $ Singular -q QR.sing > QR.idr
    $ idris2 --exec main QR.idr > QR.swift
    $ swiftc QR.swift && ./QR > QR.koto
    $ koto QR.koto > QR.janet
    $ janet QR.janet > QR.c3
    $ c3c compile QR.c3 -o QR && ./QR > QR.plt
    $ gnuplot QR.plt > QR.gbs
    $ gbs3 QR.gbs > QR.ts
    $ tsc --outFile QR.ts.js QR.ts && nodejs QR.ts.js > QR.unl
    $ ruby vendor/unlambda.rb QR.unl > QR.groovy
    $ groovy QR.groovy > QR.io
    $ io QR.io > QR.j
    $ jasmin QR.j && java QR > QR.zig
    $ zig run QR.zig > QR.wren
    $ wren_cli QR.wren > QR.arr
    $ pyretc QR.arr QR.jarr && NODE_PATH=/opt/b05/node_modules node QR.jarr > QR.hs
    $ rm -f QR.o && ghc QR.hs && ./QR > QR.pike
    $ pike QR.pike > QR.ps
    $ gs -dNODISPLAY -q QR.ps > QR.prolog
    $ swipl -q -t qr -f QR.prolog > QR.res
    $ bsc QR.res > QR.res.js && node QR.res.js > QR.dfy
    $ dafny build -o dafny-out/QR QR.dfy && DOTNET_ROLL_FORWARD=Major dotnet dafny-out/QR.dll > QR.jl
    $ julia QR.jl > QR.mac
    $ maxima -q --init-mac=QR.mac > QR.gri
    $ gri -output QR.gri.ps QR.gri > QR.logo
    $ ucblogo QR.logo > QR.java
    $ javac QR.java && java QR > QR.mira
    $ mira -exec QR.mira > QR.icl
    $ clm -nt -nr QR -o QR > /dev/null && ./QR > QR.m2
    $ M2 --script QR.m2 > QR.cs
    $ echo '<Project Sdk="Microsoft.NET.Sdk"><PropertyGroup><OutputType>Exe</OutputType><TargetFramework>net10.0</TargetFramework><EnableDefaultCompileItems>false</EnableDefaultCompileItems></PropertyGroup><ItemGroup><Compile Include="QR.cs" /></ItemGroup></Project>' > tmp.csproj &&
      DOTNET_NOLOGO=1 dotnet run --project tmp.csproj > QR.chef
    $ PERL5LIB=vendor/local/lib/perl5 compilechef QR.chef QR.chef.pl &&
      perl QR.chef.pl > qr.li
    $ lisaac -gcc -Wno-implicit-function-declaration qr.li > /dev/null &&
      ./qr > QR.clj
    $ clojure QR.clj > QR.cmake
    $ cmake -P QR.cmake > QR.cob
    $ cobc -O2 -x QR.cob && ./QR > qr.kk
    $ koka -v0 -o qrkoka qr.kk && chmod +x qrkoka && ./qrkoka > QR.st
    $ gst QR.st > QR.ll
    $ llvm-as QR.ll && lli QR.bc > QR.lol
    $ lci QR.lol > QR.lua
    $ lua5.3 QR.lua > QR.sml
    $ polyc -o QR QR.sml && ./QR > QR.sq
    $ ruby vendor/subleq.rb QR.sq > QR.boo
    $ booi QR.boo > QR.cd
    $ cduce QR.cd > QR.txrlisp
    $ txr --lisp QR.txrlisp > QR.js
    $ nodejs QR.js > QR.jq
    $ jq -j -n -f QR.jq > QR.nc
    $ nescc -gcc=gcc-14 -o QR QR.nc && ./QR > QR.gravity
    $ gravity -q QR.gravity > QR.rkt
    $ racket QR.rkt > QR.aplus.a
    $ a+ QR.aplus.a > QR.kt 2> /dev/null < /dev/null
    $ kotlinc QR.kt -include-runtime -d QR.jar && kotlin QR.jar > QR.arm64.s
    $ rm -f QR && aarch64-linux-gnu-gcc -nostdlib -static -o QR QR.arm64.s &&
      qemu-aarch64 ./QR > QR.sql && rm -f QR
    $ sqlite3 < QR.sql > QR.pasm
    $ parrot QR.pasm > QR.rv.s
    $ rm -f QR && riscv64-linux-gnu-gcc -nostdlib -static -o QR QR.rv.s &&
      qemu-riscv64 ./QR > QR.mzn && rm -f QR
    $ minizinc --solver COIN-BC --soln-sep '' QR.mzn > QR.yeti
    $ yeti QR.yeti > QR.cc
    $ ag++ --keywords -o QR QR.cc && ./QR > QR.vb
    $ echo '<Project Sdk="Microsoft.NET.Sdk"><PropertyGroup><OutputType>Exe</OutputType><TargetFramework>net10.0</TargetFramework><EnableDefaultCompileItems>false</EnableDefaultCompileItems></PropertyGroup><ItemGroup><Compile Include="QR.vb" /></ItemGroup></Project>' > tmp.vbproj &&
      DOTNET_NOLOGO=1 dotnet run --project tmp.vbproj > QR.wat
    $ wat2wasm QR.wat -o QR.wat.wasm && $(WASI_RUNTIME) QR.wat.wasm > QR.ws
    $ ruby vendor/whitespace.rb QR.ws > QR.nbt
    $ numbat QR.nbt > QR.mod
    $ gm2 -fiso QR.mod -o QR && ./QR > QR.il
    $ ilasm QR.il && mono QR.exe > QR.gleam
    $ mkdir -p qrgleam/src && cp QR.gleam qrgleam/src/qr.gleam && printf 'name = "qr"\nversion = "1.0.0"\n' > qrgleam/gleam.toml &&
      (cd qrgleam; gleam run --no-print-progress) > QR.dyon
    $ dyonrun QR.dyon > QR.rye
    $ rye QR.rye > QR.a68
    $ a68g --heap 512M QR.a68 > QR.ante
    $ ruby vendor/ante.rb QR.ante > QR.neko
    $ nekoc QR.neko && neko QR.n > QR.nim
    $ nim compile QR.nim && ./QR > QR_ec.ec
    $ ecp -c QR_ec.ec -o QR_ec.sym && ecc -c QR_ec.ec -o QR_ec.c && ecs -console QR_ec.sym QR_ec.imp -o QR_ec.main.ec &&
      ecp -c QR_ec.main.ec -o QR_ec.main.sym && ecc -c QR_ec.main.ec -o QR_ec.main.c &&
      gcc -std=gnu17 -w -o QR_ec QR_ec.c QR_ec.main.c -lecereCOM &&
      ./QR_ec > QR.vala
    $ valac QR.vala && ./QR > QR.mid
    $ mono vendor/local/bin/Vlt.exe /s QR.mid && mono QR.exe > QR.gp
    $ gp -f -q QR.gp > QR.mustache
    $ mustache QR.mustache QR.mustache > QR.asm
    $ nasm -felf QR.asm && ld -m elf_i386 -o QR QR.o && ./QR > QR.roc
    $ roc build --output qrroc QR.roc && ./qrroc > QR.effekt && rm -f qrroc
    $ rm -rf qr_effekt_out && effekt --backend js --out qr_effekt_out QR.effekt > QR.inko &&
      rm -rf qr_effekt_out
    $ inko run QR.inko > QR.ssa
    $ qbe QR.ssa > QR.qbe.s && gcc QR.qbe.s -o QR && ./QR > QR.apl
    $ apl --script --OFF -s -f QR.apl > QR.vale
    $ rm -rf qr_vale_out && valec build qr=QR.vale --output_dir qr_vale_out > /dev/null &&
      ./qr_vale_out/main > QR.pawn && rm -rf qr_vale_out
    $ pawncc -C64 QR.pawn -oQR.amx > /dev/null && pawnrun QR.amx > QR.m &&
      rm -f QR.amx
    $ gcc -o QR QR.m -lobjc && ./QR > QR.octave
    $ mv QR.m QR.m.bak && octave -qf QR.octave > QR.ml && mv QR.m.bak QR.m
    $ ocaml QR.ml > QR.chpl
    $ chpl -o qrchpl QR.chpl && ./qrchpl > QR.pony
    $ mkdir -p qrpony && cp QR.pony qrpony/main.pony && ponyc -V0 -b qrpony.out -o . qrpony &&
      ./qrpony.out > QR.pl6
    $ perl6 QR.pl6 > qr_mercury.m
    $ mmc --make qr_mercury > /dev/null && ./qr_mercury > QR.odin
    $ odin run QR.odin -file > QR.art
    $ arturo QR.art < /dev/null > QR.l
    $ pil QR.l > QR.elv
    $ elvish QR.elv > QR.lean
    $ lean --run QR.lean > QR.slashes
    $ ruby vendor/slashes.rb QR.slashes > QR.cjam
    $ java -jar /opt/cjam/cjam-0.6.5.jar QR.cjam > QR.ul
    $ ruby vendor/underload.rb QR.ul > QR.bflk
    $ craneflak -A QR.bflk > QR.sno
    $ snobol4 -b QR.sno > QR.kg
    $ kg QR.kg < /dev/null > QR.sd7
    $ s7 -q QR.sd7 > QR.gs
    $ ruby vendor/golfscript.rb QR.gs > QR.gpt
    $ mv QR.c QR.c.bak && gpt -t QR.c QR.gpt && gcc -o QR QR.c && ./QR > QR.grass &&
      mv QR.c.bak QR.c
    $ ruby vendor/grass.rb QR.grass > QR.als
    $ LANG=C LD_LIBRARY_PATH=/usr/lib/afnix axi QR.als > QR.aheui
    $ ruby vendor/aheui.rb QR.aheui > QR.php
    $ php QR.php > QR.png
    $ npiet QR.png > QR.pr
    $ spin -T QR.pr > QR.rail
    $ rail QR.rail > QR.kpl
    $ cipple QR.kpl > QR.beatnik
    $ ruby vendor/beatnik.rb QR.beatnik > QR.m4
    $ m4 QR.m4 > QR.icn
    $ icont -s QR.icn && ./QR > QR.i
    $ ick -bfOc QR.i && gcc -std=c99 -static QR.c -I /usr/include/ick-* -o QR -lick &&
      ./QR > QR.clp
    $ clips -f2 QR.clp > QR.rock
    $ rockstar QR.rock > QR.p
    $ parser3 QR.p > QR.glass
    $ glass QR.glass > QR.taxi
    $ taxi QR.taxi > QR.pas
    $ fpc QR.pas && ./QR > QR.pl
    $ perl QR.pl > QR.5c
    $ nickle QR.5c > QR.rep
    $ rep QR.rep > QR.gr
    $ grain QR.gr > QR.hoc
    $ /usr/lib/plan9/bin/hoc QR.hoc > QR.flix
    $ java -XX:TieredStopAtLevel=1 -jar /opt/flix/flix.jar QR.flix > QR.hop
    $ hope -f QR.hop > QR.aum
    $ austral compile QR.aum --entrypoint=QR:main --output=qr_austral &&
      ./qr_austral > QR.s65 && rm -f qr_austral
    $ xa -o QR.o65 QR.s65 && sim65 QR.o65 > QR.tal && rm -f QR.o65
    $ uxnasm QR.tal QR.rom && uxncli QR.rom > QR.z80 && rm -f QR.rom
    $ z80asm QR.z80 -o qr.com && chmod a+r qr.com && if [ $(id -u) = 0 ]; then setpriv --reuid=nobody --regid=nogroup --clear-groups tnylpo -b qr.com; else tnylpo -b qr.com; fi < /dev/null > QR.sci &&
      rm -f qr.com
    $ scilab-cli -nb -f QR.sci > QR.sed
    $ sed -E -f QR.sed QR.sed > QR.spl
    $ spl2c < QR.spl > QR.spl.c && gcc -z muldefs -o QR -I ./vendor/local/include -L ./vendor/local/lib QR.spl.c -lspl -lm &&
      ./QR > QR.sl
    $ slsh QR.sl > QR.ksh
    $ ksh QR.ksh > QR.lazy
    $ lazyk QR.lazy > QR.ls
    $ lsc QR.ls > QR.bsh
    $ bsh QR.bsh > QR.bef
    $ cfunge QR.bef > QR.Blc
    $ ruby vendor/blc.rb < QR.Blc > QR.bf
    $ ruby vendor/bf.rb QR.bf > QR.py
    $ python3 QR.py > QR.mb
    $ unshackled QR.mb < /dev/null > QR.R
    $ R --slave -f QR.R > QR.ratfor
    $ ratfor -o QR.ratfor.f QR.ratfor && gfortran -o QR QR.ratfor.f &&
      ./QR > QR.rc
    $ rc QR.rc > QR.rexx
    $ rexx ./QR.rexx > QR2.rb

You will see that `QR.rb` is byte-for-byte identical to `QR2.rb`:

    $ diff -s QR.rb QR2.rb

Or just run `make check`:

    $ make check

## Languages and packages

\#  |language                           |ubuntu package (or how to get it)                                                                                                   |added in
----|-----------------------------------|------------------------------------------------------------------------------------------------------------------------------------|--------------
1   |Ruby                               |ruby                                                                                                                                |mame
2   |Simula                             |`GNU Cim 5.1 source tarball`                                                                                                        |**this fork**
3   |Oberon                             |`OBNC 0.17.2 source tarball`                                                                                                        |**this fork**
4   |Euphoria                           |`OpenEuphoria 4.1.0 release`                                                                                                        |**this fork**
5   |ALGOL 60                           |`GNU MARST 2.8 source tarball`                                                                                                      |**this fork**
6   |Verilog                            |iverilog                                                                                                                            |mame
7   |SurgeScript                        |surgescript                                                                                                                         |mame
8   |Tcl                                |tcl                                                                                                                                 |mame
9   |Rhai                               |`cargo install rhai@1.27.0`                                                                                                         |**this fork**
10  |Dart                               |`Dart SDK 3.14.0 release`                                                                                                           |**this fork**
11  |GEL (Genius)                       |genius                                                                                                                              |mame
12  |Hexagony                           |`m-ender/hexagony (official Ruby interpreter, pinned commit b674f59a)`                                                              |**this fork**
13  |K (ngn/k)                          |`ngn/k commit b9eeb91e (vendored AGPLv3 source tarball vendor/ngnk-b9eeb91e.tar.gz, clang build)`                                   |**this fork**
14  |Zoem                               |zoem                                                                                                                                |mame
15  |Hare                               |hare                                                                                                                                |**this fork**
16  |Golo                               |`Eclipse Golo 3.4.0 release`                                                                                                        |**this fork**
17  |Scala                              |scala                                                                                                                               |mame
18  |Nial                               |`Q'Nial nialcore source build`                                                                                                      |**this fork**
19  |Yabasic                            |yabasic                                                                                                                             |mame
20  |Uiua                               |`cargo install uiua@0.19.1`                                                                                                         |**this fork**
21  |BQN                                |`CBQN v0.9.0 (clang build)`                                                                                                         |**this fork**
22  |Fantom                             |`Fantom v1.0.84 release`                                                                                                            |**this fork**
23  |Umka                               |`Umka v1.5.7 source build`                                                                                                          |**this fork**
24  |Vimscript                          |vim                                                                                                                                 |mame
25  |Frege                              |`Frege 3.25.84 jar release`                                                                                                         |**this fork**
26  |J                                  |`J 9.7 release`                                                                                                                     |**this fork**
27  |Ring                               |`Ring v1.27 source build`                                                                                                           |**this fork**
28  |ATS                                |ats2-lang                                                                                                                           |mame
29  |PowerShell                         |`PowerShell v7.4.6 release`                                                                                                         |**this fork**
30  |MUMPS                              |`YottaDB r2.06 release tarball (AGPLv3, sha256-pinned)`                                                                             |**this fork**
31  |MiniScript                         |`MiniScript v2.0.0 static Linux x64 binary (MIT, sha256-pinned)`                                                                    |**this fork**
32  |Boron                              |`Boron v2.0.8 C99 source build (LGPL-3.0)`                                                                                          |**this fork**
33  |Makefile                           |make                                                                                                                                |mame
34  |Mirth                              |`Mirth source build (MIT/0BSD, commit b6d5e9c0, sha256-pinned)`                                                                     |**this fork**
35  |Lily                               |`Lily v2.6 CMake C source build (MIT)`                                                                                              |**this fork**
36  |Ada                                |gnat                                                                                                                                |mame
37  |AspectJ                            |aspectj                                                                                                                             |mame
38  |Asymptote                          |asymptote                                                                                                                           |mame
39  |Ballerina                          |`Ballerina 2201.14.1 (.deb)`                                                                                                        |**this fork**
40  |Scheme                             |guile-3.0                                                                                                                           |mame
41  |VHDL                               |ghdl                                                                                                                                |**this fork**
42  |bash                               |bash                                                                                                                                |mame
43  |bc                                 |bc                                                                                                                                  |mame
44  |Rust                               |rustc                                                                                                                               |mame
45  |Execline                           |execline                                                                                                                            |mame
46  |Yorick                             |yorick                                                                                                                              |mame
47  |Mathics                            |`pip install mathics3==10.0.1`                                                                                                      |**this fork**
48  |newLISP                            |newlisp                                                                                                                             |**this fork**
49  |Awk                                |gawk                                                                                                                                |mame
50  |Nelua                              |`nelua-lang source build`                                                                                                           |**this fork**
51  |Hy                                 |hy                                                                                                                                  |**this fork**
52  |Berry                              |`Berry v1.1.0 source build`                                                                                                         |**this fork**
53  |ChaiScript                         |`ChaiScript C++17 source build (BSD-3-Clause, commit f635b51e)`                                                                     |**this fork**
54  |Gluon                              |`cargo install gluon_repl@0.18.4 --locked (MIT)`                                                                                    |**this fork**
55  |PureScript                         |`npm install purescript@0.15.17`                                                                                                    |**this fork**
56  |C                                  |gcc                                                                                                                                 |mame
57  |C++                                |g++                                                                                                                                 |mame
58  |MMIX                               |`Knuth MMIXware source build (pinned commit 8a5ce829, sha256-pinned)`                                                               |**this fork**
59  |Pyth                               |`isaacg1/pyth (pinned commit 97cdf30d, sha256-pinned) + python3`                                                                    |**this fork**
60  |Emmental                           |*bundled in vendor/* (`vendor/emmental.rb`)                                                                                         |**this fork**
61  |Lobster                            |`Lobster v2026.9 headless CMake build (Apache-2.0, sha256-pinned)`                                                                  |**this fork**
62  |Factor                             |`Factor 0.100 release`                                                                                                              |**this fork**
63  |Ion                                |`cargo install ion-shell`                                                                                                           |**this fork**
64  |GSL (Generator Scripting Language) |generator-scripting-language                                                                                                        |**this fork**
65  |ArnoldC                            |`ArnoldC.jar (sha256-pinned) + default-jdk-headless`                                                                                |**this fork**
66  |LFE                                |`lfe 2.1.4 source build from git (on erlang-nox)`                                                                                   |**this fork**
67  |Cyber                              |`Cyber 0.3 Linux x64 release (MIT, sha256-pinned)`                                                                                  |**this fork**
68  |PocketLang                         |`PocketLang C99 source build (MIT, commit cc73ca61)`                                                                                |**this fork**
69  |D                                  |gdc                                                                                                                                 |mame
70  |Nushell                            |`Nushell 0.101.0 release`                                                                                                           |**this fork**
71  |Gosu                               |`Gosu 1.18.14 Maven release`                                                                                                        |**this fork**
72  |YSH                                |`Oils for Unix 0.24.0 source tarball`                                                                                               |**this fork**
73  |Tengo                              |`go install github.com/d5/tengo/v2/cmd/tengo@v2.17.0`                                                                               |**this fork**
74  |CoffeeScript                       |coffeescript                                                                                                                        |mame
75  |Common Lisp                        |clisp                                                                                                                               |mame
76  |Crystal                            |crystal, libevent-dev                                                                                                               |mame
77  |Anko                               |`go install github.com/mattn/anko@v0.1.15`                                                                                          |**this fork**
78  |Emacs Lisp                         |emacs-nox                                                                                                                           |mame
79  |dc                                 |dc                                                                                                                                  |mame
80  |Dhall                              |dhall                                                                                                                               |mame
81  |Elixir                             |elixir                                                                                                                              |mame
82  |Erlang                             |erlang                                                                                                                              |mame
83  |Murex                              |`Murex v7.4.2002 (Go build)`                                                                                                        |**this fork**
84  |Fennel                             |fennel                                                                                                                              |mame
85  |tcsh                               |tcsh                                                                                                                                |mame
86  |Thue                               |*bundled in vendor/* (`vendor/thue.rb`)                                                                                             |mame
87  |Haxe                               |haxe                                                                                                                                |mame
88  |GAP                                |gap                                                                                                                                 |mame
89  |zsh                                |zsh                                                                                                                                 |mame
90  |Squirrel                           |squirrel3                                                                                                                           |mame
91  |GDB                                |gdb                                                                                                                                 |mame
92  |Picat                              |`Picat 3.9#12 release`                                                                                                              |**this fork**
93  |Forth                              |gforth                                                                                                                              |mame
94  |Fortran90                          |gfortran                                                                                                                            |mame
95  |Falcon                             |`Ubuntu archive falconpl 0.9.6.9 (.deb)`                                                                                            |**this fork**
96  |Fish                               |fish                                                                                                                                |mame
97  |FALSE                              |*bundled in vendor/* (`vendor/false.rb`)                                                                                            |mame
98  |XSLT                               |xsltproc                                                                                                                            |mame
99  |Go                                 |golang                                                                                                                              |mame
100 |Flex                               |flex                                                                                                                                |mame
101 |F#                                 |dotnet-sdk-10.0                                                                                                                     |mame
102 |><> (Fish)                         |`Official Jonathan fish.py (gist 6392418@3b16018c, sha256-pinned) + python3`                                                        |**this fork**
103 |V                                  |`V 0.4.12 release`                                                                                                                  |**this fork**
104 |Singular                           |singular                                                                                                                            |**this fork**
105 |Idris 2                            |`Idris2 v0.8.0 source build`                                                                                                        |**this fork**
106 |Swift                              |swiftlang                                                                                                                           |mame
107 |Koto                               |`cargo install koto_cli@0.16.1`                                                                                                     |**this fork**
108 |Janet                              |`Janet v1.43.0 source build`                                                                                                        |**this fork**
109 |C3                                 |`c3c v0.7.0 release`                                                                                                                |**this fork**
110 |Gnuplot                            |gnuplot                                                                                                                             |mame
111 |Gambas script                      |gambas3-scripter, gambas3-gb-pcre                                                                                                   |mame
112 |TypeScript                         |node-typescript                                                                                                                     |mame
113 |Unlambda                           |*bundled in vendor/* (`vendor/unlambda.rb`)                                                                                         |mame
114 |Groovy                             |groovy                                                                                                                              |mame
115 |Io                                 |`Io 2019.05.22 source build`                                                                                                        |**this fork**
116 |Jasmin                             |jasmin-sable                                                                                                                        |mame
117 |Zig                                |`Zig 0.13.0 release`                                                                                                                |**this fork**
118 |Wren                               |`Wren CLI 0.4.0 source build`                                                                                                       |**this fork**
119 |Pyret                              |`npm install pyret-npm@0.1.29`                                                                                                      |**this fork**
120 |Haskell                            |ghc                                                                                                                                 |mame
121 |Pike                               |pike8.0                                                                                                                             |mame
122 |PostScript                         |ghostscript                                                                                                                         |mame
123 |Prolog                             |swi-prolog                                                                                                                          |mame
124 |ReScript                           |`npm install rescript@12.3.1`                                                                                                       |**this fork**
125 |Dafny                              |`Dafny v4.11.0 release`                                                                                                             |**this fork**
126 |Julia                              |`Julia 1.13.4 release`                                                                                                              |**this fork**
127 |Maxima                             |maxima                                                                                                                              |**this fork**
128 |Gri                                |gri                                                                                                                                 |**this fork**
129 |UCBLogo                            |`UCBLogo 6.2.5 source tarball`                                                                                                      |**this fork**
130 |Java                               |openjdk-25-jdk                                                                                                                      |mame
131 |Miranda                            |`Miranda 2.066 source tarball (BSD-2-Clause, sha256-pinned)`                                                                        |**this fork**
132 |Clean                              |`Clean 3.1 Linux x64 release (BSD-2-Clause, sha256-pinned)`                                                                         |**this fork**
133 |Macaulay2                          |macaulay2                                                                                                                           |**this fork**
134 |C#                                 |dotnet-sdk-10.0                                                                                                                     |mame
135 |Chef                               |*bundled in vendor/* (`vendor/Acme-Chef-1.03.tar.gz`, Artistic)                                                                     |mame
136 |Lisaac                             |`Ubuntu archive lisaac 0.39 (.deb)`                                                                                                 |**this fork**
137 |Clojure                            |clojure                                                                                                                             |mame
138 |CMake                              |cmake                                                                                                                               |mame
139 |Cobol                              |gnucobol4                                                                                                                           |mame
140 |Koka                               |`Koka v3.2.9 release`                                                                                                               |**this fork**
141 |GNU Smalltalk                      |`GNU Smalltalk 3.2.5 source tarball`                                                                                                |**this fork**
142 |LLVM asm                           |llvm                                                                                                                                |mame
143 |LOLCODE                            |*bundled in vendor/* (`vendor/lci-0.10.5.zip`, GPLv3+)                                                                              |mame
144 |Lua                                |lua5.3                                                                                                                              |mame
145 |Standard ML                        |polyml, libpolyml-dev                                                                                                               |mame
146 |Subleq                             |*bundled in vendor/* (`vendor/subleq.rb`)                                                                                           |mame
147 |Boo                                |`Ubuntu archive boo 0.9.5 (.deb)`                                                                                                   |**this fork**
148 |CDuce                              |`Ubuntu archive cduce 0.6.0 (.deb)`                                                                                                 |**this fork**
149 |TXR                                |`TXR 302 source tarball`                                                                                                            |**this fork**
150 |JavaScript                         |nodejs                                                                                                                              |mame
151 |Jq                                 |jq                                                                                                                                  |mame
152 |nesC                               |`nesC v1.4.0 source build`                                                                                                          |**this fork**
153 |Gravity                            |`Gravity 0.9.9 source build`                                                                                                        |**this fork**
154 |Racket                             |racket                                                                                                                              |**this fork**
155 |A+                                 |`Ubuntu archive aplus-fsf 4.22.1 (.deb; invoked with 2> /dev/null < /dev/null)`                                                     |**this fork**
156 |Kotlin                             |kotlin                                                                                                                              |mame
157 |ARM64 asm                          |gcc-aarch64-linux-gnu, qemu-user                                                                                                    |**this fork**
158 |SQL (SQLite)                       |sqlite3                                                                                                                             |**this fork**
159 |Parrot asm (PASM)                  |`Parrot 8.1.0 source build`                                                                                                         |**this fork**
160 |RISC-V asm                         |gcc-riscv64-linux-gnu, qemu-user                                                                                                    |**this fork**
161 |MiniZinc                           |minizinc                                                                                                                            |mame
162 |Yeti                               |`Yeti ML source build (ant)`                                                                                                        |**this fork**
163 |AspectC++                          |aspectc++                                                                                                                           |**this fork**
164 |Visual Basic                       |dotnet-sdk-10.0                                                                                                                     |mame
165 |WebAssembly (Text format)          |wabt + *bundled in vendor/* (`vendor/wasi-runtime.js` on Node, or `wasmtime`)                                                       |mame
166 |Whitespace                         |*bundled in vendor/* (`vendor/whitespace.rb`)                                                                                       |mame
167 |Numbat                             |`cargo install numbat-cli@1.24.0`                                                                                                   |**this fork**
168 |Modula-2                           |gm2                                                                                                                                 |mame
169 |MSIL                               |mono-devel                                                                                                                          |mame
170 |Gleam                              |`Gleam v1.19.2 release`                                                                                                             |**this fork**
171 |Dyon                               |`cargo install dyon@0.51.3 --example dyonrun --locked (Apache-2.0/MIT)`                                                             |**this fork**
172 |Rye                                |`Rye v0.2.82 Linux x64 release (BSD-3-Clause, sha256-pinned)`                                                                       |**this fork**
173 |ALGOL 68                           |algol68g                                                                                                                            |mame
174 |Ante                               |*bundled in vendor/* (`vendor/ante.rb`)                                                                                             |mame
175 |Neko                               |neko                                                                                                                                |mame
176 |Nim                                |nim                                                                                                                                 |mame
177 |eC                                 |`Ubuntu archive ecere-sdk 0.44.15 (.deb)`                                                                                           |**this fork**
178 |Vala                               |valac                                                                                                                               |mame
179 |Velato                             |*bundled in vendor/* (`vendor/Velato_0_1.zip`, freeware non-commercial)                                                             |mame
180 |PARI/GP                            |pari-gp                                                                                                                             |mame
181 |Mustache                           |ruby-mustache                                                                                                                       |mame
182 |NASM                               |nasm                                                                                                                                |mame
183 |Roc                                |`Roc 0.0.0-alpha1 + offline local basic-cli 0.18.0 (both sha256-pinned)`                                                            |**this fork**
184 |Effekt                             |`Effekt v0.85.0 release tarball (MIT, sha256-pinned)`                                                                               |**this fork**
185 |Inko                               |`Inko v0.21.1 source build`                                                                                                         |**this fork**
186 |QBE                                |qbe                                                                                                                                 |**this fork**
187 |GNU APL                            |`GNU APL 2.0 source tarball (GPLv3, sha256-pinned)`                                                                                 |**this fork**
188 |Vale                               |`Vale 0.2.0.28 Linux x64 release (Apache-2.0, sha256-pinned)`                                                                       |**this fork**
189 |Pawn                               |`Pawn v4.1.7152 CMake C build (Apache-2.0, -DHAVE_CURSES_H=0)`                                                                      |**this fork**
190 |Objective-C                        |gobjc                                                                                                                               |mame
191 |Octave                             |octave                                                                                                                              |mame
192 |OCaml                              |ocaml                                                                                                                               |mame
193 |Chapel                             |`Chapel 2.10.0 (.deb)`                                                                                                              |**this fork**
194 |Pony                               |`ponyc 0.78.2 release`                                                                                                              |**this fork**
195 |Perl 6                             |rakudo                                                                                                                              |mame
196 |Mercury                            |`Mercury 22.01.8 apt repository`                                                                                                    |**this fork**
197 |Odin                               |`Odin dev-2026-10 release`                                                                                                          |**this fork**
198 |Arturo                             |`Arturo v0.10.0 release`                                                                                                            |**this fork**
199 |PicoLisp                           |picolisp                                                                                                                            |**this fork**
200 |Elvish                             |elvish                                                                                                                              |**this fork**
201 |Lean 4                             |`Lean v4.35.0 release`                                                                                                              |**this fork**
202 |///                                |*bundled in vendor/* (`vendor/slashes.rb`)                                                                                          |**this fork**
203 |CJam                               |`Official CJam 0.6.5 JAR (MIT, sha256-pinned) + default-jdk-headless`                                                               |**this fork**
204 |Underload                          |*bundled in vendor/* (`vendor/underload.rb`)                                                                                        |**this fork**
205 |Brain-Flak                         |`Official Flakheads CraneFlak C interpreter (MIT, commit 049f09ea, sha256-pinned)`                                                  |**this fork**
206 |SNOBOL4                            |`CSNOBOL4 2.3.3 source tarball (sha256-pinned)`                                                                                     |**this fork**
207 |Klong                              |`Klong 20221212 source tarball`                                                                                                     |**this fork**
208 |Seed7                              |`Seed7 2026-07-11 source build`                                                                                                     |**this fork**
209 |GolfScript                         |*bundled in vendor/* (`vendor/golfscript.rb`)                                                                                       |mame
210 |G-Portugol                         |gpt                                                                                                                                 |mame
211 |Grass                              |*bundled in vendor/* (`vendor/grass.rb`)                                                                                            |mame
212 |AFNIX                              |afnix                                                                                                                               |mame
213 |Aheui                              |*bundled in vendor/* (`vendor/aheui.rb`)                                                                                            |mame
214 |PHP                                |php-cli                                                                                                                             |mame
215 |Piet                               |*bundled in vendor/* (`vendor/npiet-1.3e.tar.gz`, GPLv2)                                                                            |mame
216 |Promela (Spin)                     |spin                                                                                                                                |mame
217 |Rail                               |`TryItOnline/rail C++ build (pinned commit 04b7259f)`                                                                               |**this fork**
218 |Kipple                             |`cipple 0.2.1 C build (pinned commit 07dce2db)`                                                                                     |**this fork**
219 |Beatnik                            |*bundled in vendor/* (`vendor/beatnik.rb`)                                                                                          |**this fork**
220 |M4                                 |m4                                                                                                                                  |mame
221 |Icon                               |icont, iconx                                                                                                                        |mame
222 |INTERCAL                           |intercal                                                                                                                            |mame
223 |CLIPS                              |clips                                                                                                                               |**this fork**
224 |Rockstar                           |`Rockstar v2.0.15 release`                                                                                                          |**this fork**
225 |Parser 3                           |parser3-cgi                                                                                                                         |mame
226 |Glass                              |`Official Gregor Richards C++ glass-0.12 (GPLv2, graue/esofiles@07dce2db, sha256-pinned)`                                           |**this fork**
227 |Taxi                               |`BigZaphod Taxi C++ build (pinned commit 61383585, compiled with upstream -DNO_GREETINGS flag)`                                     |**this fork**
228 |Pascal                             |fp-compiler                                                                                                                         |mame
229 |Perl 5                             |perl                                                                                                                                |mame
230 |Nickle                             |nickle                                                                                                                              |mame
231 |rep (librep)                       |rep                                                                                                                                 |**this fork**
232 |Grain                              |`Grain v0.7.3 Linux x64 release (Apache-2.0, sha256-pinned)`                                                                        |**this fork**
233 |HOC                                |9base                                                                                                                               |**this fork**
234 |Flix                               |`Flix v0.80.0 JAR (Apache-2.0, sha256-pinned) + default-jdk-headless`                                                               |**this fork**
235 |Hope                               |`Hope C interpreter (GPLv2, dmbaturin/hope@94fc5a09, sha256-pinned)`                                                                |**this fork**
236 |Austral                            |`Austral v0.2.0 Linux x64 binary (Apache-2.0+LLVM, sha256-pinned)`                                                                  |**this fork**
237 |6502 asm                           |xa65, cc65 (`sim65`)                                                                                                                |**this fork**
238 |Uxntal                             |`Uxn uxnasm + uxncli C build (kivutar/uxn@9e483ae8, sha256-pinned)`                                                                 |**this fork**
239 |Z80 asm                            |`z80asm + official tnylpo 1.2.2 CP/M 2.2 emulator (BSD-3-Clause, sha256-pinned)`                                                    |**this fork**
240 |Scilab                             |scilab-cli                                                                                                                          |mame
241 |sed                                |sed                                                                                                                                 |mame
242 |Shakespeare                        |*bundled in vendor/* (`vendor/spl-1.2.1.tar.gz`, GPLv2)                                                                             |mame
243 |S-Lang                             |slsh                                                                                                                                |mame
244 |ksh                                |ksh                                                                                                                                 |mame
245 |Lazy K                             |*bundled in vendor/* (`vendor/lazyk.c`, MIT; `RDSTACK_SIZE` raised 100,000 -> 10,000,000 for 256-step stack depth)                  |mame
246 |LiveScript                         |livescript                                                                                                                          |mame
247 |BeanShell                          |bsh                                                                                                                                 |mame
248 |Befunge                            |*bundled in vendor/* (`vendor/cfunge-0.9.0.tar.bz2`, GPLv3)                                                                         |mame
249 |BLC8                               |*bundled in vendor/* (`vendor/blc.rb`)                                                                                              |mame
250 |Brainfuck                          |*bundled in vendor/* (`vendor/bf.rb`)                                                                                               |mame
251 |Python                             |python3                                                                                                                             |mame
252 |Malbolge Unshackled                |*bundled in vendor/* (`vendor/Unshackled.c`, untouched CC0 1.0 by Matthias Lutter; `Unshackled-20.c` built for parity verification) |**this fork**
253 |R                                  |r-base                                                                                                                              |mame
254 |Ratfor                             |ratfor                                                                                                                              |mame
255 |rc                                 |rc                                                                                                                                  |mame
256 |REXX                               |regina-rexx                                                                                                                         |mame

Every language marked *bundled in vendor/* uses an archive, binary, or interpreter in `vendor/`; see [`vendor/README`](vendor/README) for complete provenance, modifications, and per-file licenses.

## Frequently asked questions

### Q. Who made this?

A. The original 128-language Quine Relay, its uroboros code generator, and the core compression architecture were created by [Yusuke Endoh (mame)](https://github.com/mame) and contributors starting in 2013. This fork extends the relay to 256 distinct languages (including Malbolge Unshackled and 16/20 restored retirees from earlier Ubuntu editions of `mame/quine-relay`), optimizes the run order, and documents the counting rules. Built by [Drawn With Code](https://www.youtube.com/@DrawnWithCode).

### Q. How does a quine relay work?

A. mame explains the original design in ["The World of Obfuscated, Esoteric, Artistic Programming"](http://gihyo.jp/book/2015/978-4-7741-7643-7) (in Japanese), and [RELAY-256.md](RELAY-256.md) covers how this fork scales to 256 languages.

### Q. Language XXX is missing!

A. Pull requests and suggestions are welcome! Every step must be a distinct open-source language running on its real compiler or interpreter inside the Docker image, following the no-cheating rules in [RECORDS.md](RECORDS.md), and closing the full loop.

### Q. The code does not fit on my screen!

A. [Here is the 1-pixel-per-bit bitmap of `QR.rb`][thumbnail].

[thumbnail]: thumbnail.png

### Q. How was the code generated?

A.

    $ cd src
    $ rake

`src/code-gen.rb` defines all 256 steps, and `src/malbolge-boot.dat.gen.py` (alongside `blc-boot.dat.gen.rb`, `grass-boot.dat.gen.rb`, and `lazyk-boot.dat.gen.rb`) builds the bootstrapper data files. `rake` rebuilds `QR.rb`, `Makefile`, `Dockerfile`, `LANGUAGES.md`, `.github/workflows/main.yml`, and this `README.md`. `src/langs.png.gen.rb` (or `tools/langs_png.py`) renders `langs.png`, and `src/thumbnail.png.gen.rb` renders `thumbnail.png`.

## History

### This fork

- **256 steps / 256 distinct languages (re-audited offline-verified release), Ubuntu 26.04 (Nov 21, 2026).** This repo. Re-audited from top to bottom (including independent `strace` + canary verification): eliminated temp-file/`tail` in `Makefile`, switched `F#` to offline `dotnet fsi` (full 256-step lap passes `docker run --rm --network=none`), chunked `Picat` and `Austral` to eliminate recursive-parser stack overflows, escaped `Murex` `{...}` ANSI brace expansion, expanded `Uxntal` and `6502 asm` Re-Pair dictionaries to 159 non-printable slots (>10.9 KB headroom on all three 64 KB VM ROMs), added genuine language-specific syntax to `AspectJ` (`aspect`), `TypeScript` (type annotations), and `Objective-C` (`@interface`/`@implementation`), replaced custom mock/subset interpreters with canonical upstream tools, removed proprietary `frink.jar` and banner-patched `Joy`, swapped dialect/config-language gray-zone steps for standalone open-source languages, added in-tree `malbolge-boot.dat.gen.py`, scaled the Ouroboros ASCII art (`114x401`), and documented all upstream precedents transparently.
- **256 steps / 256 distinct languages (initial release), Ubuntu 26.04 (Nov 19, 2026).** First 256-step closed loop with Malbolge Unshackled and clean `Scilab -> sed -> Shakespeare -> S-Lang`; subsequently hardened after an internal line-by-line purity audit.
- **267 steps / 257 distinct languages, Ubuntu 26.04 (Nov 19, 2026).** Stepping-stone no-cheat milestone prior to dropping the 10 non-distinct entries and adding Malbolge Unshackled.
- **284 steps (Nov 18, 2026), withdrawn.** Earlier prototype superseded after mame's no-cheat review.
- **151 steps / 143 distinct languages, Ubuntu 26.04 (Nov 13, 2026).** First public milestone.

### mame's Quine Relay

- **50 -> 64 -> 100 -> 128 languages (Ubuntu 13.04 through Ubuntu 26.04):** [mame/quine-relay](https://github.com/mame/quine-relay).

## License

The MIT License applies to all resources
*except* the files in the `vendor/` directory.

The files in the `vendor/` directory are from third-parties (or self-made esolang runners)
and are distributed under their respective licenses.
See [`vendor/README`](vendor/README) in detail. See also root [`LICENSE`](LICENSE).

---

The MIT License (MIT)

Copyright (c) 2013-2026 Yusuke Endoh (@mametter), @hirekoke
Copyright (c) 2026 Drawn With Code (@exacortex / @rasteia): the steps and scale architecture added in this fork

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
