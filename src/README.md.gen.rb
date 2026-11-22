require_relative "code-gen"
require "digest"
require "erb"

other_packages = %w(cmake libpng-dev libgd-dev libfl-dev bison curl unzip)

def a_or_an(name)
  article =
    if name =~ /\A(?:Eu|UCB|Uiua|Uni)/i
      "a"
    elsif name =~ /\A(?:[AEIOU]|F#|LFE\b|LLVM\b|M4\b|MMIX\b|MSIL\b|R\b|S-Lang\b|SQL\b|XSLT\b)/i
      "an"
    else
      "a"
    end
  "#{ article } #{ name }"
end

mame_128 = %w[
  Ruby Rust Scala Scheme Scilab sed Shakespeare S-Lang Squirrel Subleq
  SurgeScript Swift Tcl tcsh Thue TypeScript Unlambda Vala Velato Verilog
  Vimscript Whitespace XSLT Yabasic Yorick Zoem zsh Ada AFNIX Aheui
  Ante AspectJ Asymptote ATS Awk bash bc BeanShell Befunge BLC8
  Brainfuck C C++ C# Chef Clojure CMake Cobol CoffeeScript Crystal
  D dc Dhall Elixir Erlang Execline F# FALSE Fennel Flex
  Fish Forth FORTRAN77 Fortran90 GAP GDB Gnuplot Go GolfScript G-Portugol
  Grass Groovy Gzip Haskell Haxe Icon INTERCAL Jasmin Java JavaScript
  Jq JSFuck Kotlin ksh LiveScript LOLCODE Lua M4 Makefile MiniZinc
  Modula-2 MSIL Mustache NASM Neko Nickle Nim Objective-C OCaml Octave
  Ook! PARI/GP Pascal PHP Piet Pike PostScript Prolog Python R
  Ratfor rc REXX
] + [
  "Standard ML", "Visual Basic", "WebAssembly (Binary format)", "WebAssembly (Text format)",
  "ALGOL 68", "Common Lisp", "Emacs Lisp", "Gambas script", "GEL (Genius)",
  "Lazy K", "LLVM asm", "Parser 3", "Perl 5", "Perl 6", "Promela (Spin)"
]

# Classic languages retired from earlier Ubuntu editions of mame/quine-relay
# (16 of 20 historical retirees restored here).
TOTAL_MAME_RETIREES = 20
restored_mame = [
  "AspectC++", "Parrot asm (PASM)", "Boo", "Maxima", "Gri", "UCBLogo",
  "GNU Smalltalk", "Julia", "Dafny", "GSL (Generator Scripting Language)",
  "nesC", "Lisaac", "eC", "CDuce", "A+", "Falcon",
]

# Exact installation / runtime disclosures for non-plain-apt or special steps.
extra_installs = {
  # Bundled / vendored builds with explicit disclosures
  "Malbolge Unshackled" => "*bundled in vendor/* (`vendor/Unshackled.c`, untouched CC0 1.0 by Matthias Lutter; `Unshackled-20.c` built for parity verification)",
  "Lazy K" => "*bundled in vendor/* (`vendor/lazyk.c`, MIT; `RDSTACK_SIZE` raised 100,000 -> 10,000,000 for 256-step stack depth)",
  "K (ngn/k)" => "`ngn/k commit b9eeb91e (vendored AGPLv3 source tarball vendor/ngnk-b9eeb91e.tar.gz, clang build)`",
  "LFE" => "`lfe 2.1.4 source build from git (on erlang-nox)`",
  "Taxi" => "`BigZaphod Taxi C++ build (pinned commit 61383585, compiled with upstream -DNO_GREETINGS flag)`",
  "A+" => "`Ubuntu archive aplus-fsf 4.22.1 (.deb; invoked with 2> /dev/null < /dev/null)`",

  # Upgraded canonical upstream interpreters / emulators
  "CJam" => "`Official CJam 0.6.5 JAR (MIT, sha256-pinned) + default-jdk-headless`",
  "Glass" => "`Official Gregor Richards C++ glass-0.12 (GPLv2, graue/esofiles@07dce2db, sha256-pinned)`",
  "><> (Fish)" => "`Official Jonathan fish.py (gist 6392418@3b16018c, sha256-pinned) + python3`",
  "Brain-Flak" => "`Official Flakheads CraneFlak C interpreter (MIT, commit 049f09ea, sha256-pinned)`",
  "6502 asm" => "xa65, cc65 (`sim65`)",
  "Z80 asm" => "`z80asm + official tnylpo 1.2.2 CP/M 2.2 emulator (BSD-3-Clause, sha256-pinned)`",

  # Retained fork languages installed outside standard Ubuntu 26.04 apt
  "SNOBOL4" => "`CSNOBOL4 2.3.3 source tarball (sha256-pinned)`",
  "Simula" => "`GNU Cim 5.1 source tarball`",
  "Oberon" => "`OBNC 0.17.2 source tarball`",
  "Euphoria" => "`OpenEuphoria 4.1.0 release`",
  "ALGOL 60" => "`GNU MARST 2.8 source tarball`",
  "Parrot asm (PASM)" => "`Parrot 8.1.0 source build`",
  "Arturo" => "`Arturo v0.10.0 release`",
  "Lean 4" => "`Lean v4.35.0 release`",
  "Idris 2" => "`Idris2 v0.8.0 source build`",
  "V" => "`V 0.4.12 release`",
  "C3" => "`c3c v0.7.0 release`",
  "Nelua" => "`nelua-lang source build`",
  "Zig" => "`Zig 0.13.0 release`",
  "PowerShell" => "`PowerShell v7.4.6 release`",
  "Nushell" => "`Nushell 0.101.0 release`",
  "Ion" => "`cargo install ion-shell`",
  "YSH" => "`Oils for Unix 0.24.0 source tarball`",
  "Murex" => "`Murex v7.4.2002 (Go build)`",
  "Boo" => "`Ubuntu archive boo 0.9.5 (.deb)`",
  "Koto" => "`cargo install koto_cli@0.16.1`",
  "Dart" => "`Dart SDK 3.14.0 release`",
  "Anko" => "`go install github.com/mattn/anko@v0.1.15`",
  "Tengo" => "`go install github.com/d5/tengo/v2/cmd/tengo@v2.17.0`",
  "Rhai" => "`cargo install rhai@1.27.0`",
  "Hexagony" => "`m-ender/hexagony (official Ruby interpreter, pinned commit b674f59a)`",
  "Nial" => "`Q'Nial nialcore source build`",
  "Uiua" => "`cargo install uiua@0.19.1`",
  "BQN" => "`CBQN v0.9.0 (clang build)`",
  "Fantom" => "`Fantom v1.0.84 release`",
  "Golo" => "`Eclipse Golo 3.4.0 release`",
  "Ballerina" => "`Ballerina 2201.14.1 (.deb)`",
  "Yeti" => "`Yeti ML source build (ant)`",
  "Gosu" => "`Gosu 1.18.14 Maven release`",
  "Frege" => "`Frege 3.25.84 jar release`",
  "J" => "`J 9.7 release`",
  "Umka" => "`Umka v1.5.7 source build`",
  "Mathics" => "`pip install mathics3==10.0.1`",
  "Berry" => "`Berry v1.1.0 source build`",
  "ArnoldC" => "`ArnoldC.jar (sha256-pinned) + default-jdk-headless`",
  "Factor" => "`Factor 0.100 release`",
  "Numbat" => "`cargo install numbat-cli@1.24.0`",
  "Ring" => "`Ring v1.27 source build`",
  "Janet" => "`Janet v1.43.0 source build`",
  "Io" => "`Io 2019.05.22 source build`",
  "Picat" => "`Picat 3.9#12 release`",
  "Wren" => "`Wren CLI 0.4.0 source build`",
  "PureScript" => "`npm install purescript@0.15.17`",
  "Pyret" => "`npm install pyret-npm@0.1.29`",
  "ReScript" => "`npm install rescript@12.3.1`",
  "Dafny" => "`Dafny v4.11.0 release`",
  "Julia" => "`Julia 1.13.4 release`",
  "UCBLogo" => "`UCBLogo 6.2.5 source tarball`",
  "GNU Smalltalk" => "`GNU Smalltalk 3.2.5 source tarball`",
  "TXR" => "`TXR 302 source tarball`",
  "Gravity" => "`Gravity 0.9.9 source build`",
  "Klong" => "`Klong 20221212 source tarball`",
  "Seed7" => "`Seed7 2026-07-11 source build`",
  "nesC" => "`nesC v1.4.0 source build`",
  "Lisaac" => "`Ubuntu archive lisaac 0.39 (.deb)`",
  "eC" => "`Ubuntu archive ecere-sdk 0.44.15 (.deb)`",
  "CDuce" => "`Ubuntu archive cduce 0.6.0 (.deb)`",
  "Falcon" => "`Ubuntu archive falconpl 0.9.6.9 (.deb)`",
  "Gleam" => "`Gleam v1.19.2 release`",
  "Inko" => "`Inko v0.21.1 source build`",
  "Koka" => "`Koka v3.2.9 release`",
  "Chapel" => "`Chapel 2.10.0 (.deb)`",
  "Pony" => "`ponyc 0.78.2 release`",
  "Odin" => "`Odin dev-2026-10 release`",
  "Rockstar" => "`Rockstar v2.0.15 release`",
  "Mercury" => "`Mercury 22.01.8 apt repository`",
  "Rail" => "`TryItOnline/rail C++ build (pinned commit 04b7259f)`",
  "Kipple" => "`cipple 0.2.1 C build (pinned commit 07dce2db)`",
  "Uxntal" => "`Uxn uxnasm + uxncli C build (kivutar/uxn@9e483ae8, sha256-pinned)`",
  "MMIX" => "`Knuth MMIXware source build (pinned commit 8a5ce829, sha256-pinned)`",
  "Pyth" => "`isaacg1/pyth (pinned commit 97cdf30d, sha256-pinned) + python3`",
  "Roc" => "`Roc 0.0.0-alpha1 + offline local basic-cli 0.18.0 (both sha256-pinned)`",

  # Standalone replacement languages (non-apt; QBE uses apt `qbe`, HOC uses apt `9base`)
  "MUMPS" => "`YottaDB r2.06 release tarball (AGPLv3, sha256-pinned)`",
  "GNU APL" => "`GNU APL 2.0 source tarball (GPLv3, sha256-pinned)`",
  "Lobster" => "`Lobster v2026.9 headless CMake build (Apache-2.0, sha256-pinned)`",
  "Miranda" => "`Miranda 2.066 source tarball (BSD-2-Clause, sha256-pinned)`",
  "Hope" => "`Hope C interpreter (GPLv2, dmbaturin/hope@94fc5a09, sha256-pinned)`",
  "Clean" => "`Clean 3.1 Linux x64 release (BSD-2-Clause, sha256-pinned)`",
  "Grain" => "`Grain v0.7.3 Linux x64 release (Apache-2.0, sha256-pinned)`",
  "Mirth" => "`Mirth source build (MIT/0BSD, commit b6d5e9c0, sha256-pinned)`",
  "Flix" => "`Flix v0.80.0 JAR (Apache-2.0, sha256-pinned) + default-jdk-headless`",
  "Boron" => "`Boron v2.0.8 C99 source build (LGPL-3.0)`",
  "ChaiScript" => "`ChaiScript C++17 source build (BSD-3-Clause, commit f635b51e)`",
  "MiniScript" => "`MiniScript v2.0.0 static Linux x64 binary (MIT, sha256-pinned)`",
  "Gluon" => "`cargo install gluon_repl@0.18.4 --locked (MIT)`",
  "Effekt" => "`Effekt v0.85.0 release tarball (MIT, sha256-pinned)`",
  "Lily" => "`Lily v2.6 CMake C source build (MIT)`",
  "PocketLang" => "`PocketLang C99 source build (MIT, commit cc73ca61)`",
  "Cyber" => "`Cyber 0.3 Linux x64 release (MIT, sha256-pinned)`",
  "Dyon" => "`cargo install dyon@0.51.3 --example dyonrun --locked (Apache-2.0/MIT)`",
  "Rye" => "`Rye v0.2.82 Linux x64 release (BSD-3-Clause, sha256-pinned)`",
  "Pawn" => "`Pawn v4.1.7152 CMake C build (Apache-2.0, -DHAVE_CURSES_H=0)`",
  "Austral" => "`Austral v0.2.0 Linux x64 binary (Apache-2.0+LLVM, sha256-pinned)`",
  "Vale" => "`Vale 0.2.0.28 Linux x64 release (Apache-2.0, sha256-pinned)`",
}

# Explicit labels for steps whose compiled binary or runtime comes from vendor/
# without referencing a `vendor/...` path literally in Cmd.
compiled_vendor_notes = {
  "Befunge" => "*bundled in vendor/* (`vendor/cfunge-0.9.0.tar.bz2`, GPLv3)",
  "Chef" => "*bundled in vendor/* (`vendor/Acme-Chef-1.03.tar.gz`, Artistic)",
  "LOLCODE" => "*bundled in vendor/* (`vendor/lci-0.10.5.zip`, GPLv3+)",
  "Piet" => "*bundled in vendor/* (`vendor/npiet-1.3e.tar.gz`, GPLv2)",
  "Shakespeare" => "*bundled in vendor/* (`vendor/spl-1.2.1.tar.gz`, GPLv2)",
  "Velato" => "*bundled in vendor/* (`vendor/Velato_0_1.zip`, freeware non-commercial)",
  "WebAssembly (Text format)" => "wabt + *bundled in vendor/* (`vendor/wasi-runtime.js` on Node, or `wasmtime`)",
}

apts = RunSteps.map {|s| s.apt }
mame_steps = RunSteps.select {|s| mame_128.include?(s.name) }
new_steps = RunSteps.reject {|s| mame_128.include?(s.name) }
active_retirees = restored_mame & RunSteps.map(&:name)
fork_new_count = new_steps.size - active_retirees.size - 1
qr_size = File.size("../QR.rb")
qr_sha = Digest::SHA256.file("../QR.rb").hexdigest

rows = [["\\#", "language", "ubuntu package (or how to get it)", "added in"]]
rows += RunSteps.map.with_index do |s, idx|
  apt = s.apt.is_a?(Array) ? s.apt.join(", ") : s.apt
  vendor_refs = s.cmd_raw.scan(%r{vendor/(?!local/)[\w.\-/]+}).uniq

  how = if extra_installs[s.name]
    extra_installs[s.name].dup
  elsif compiled_vendor_notes[s.name]
    compiled_vendor_notes[s.name].dup
  elsif apt && !vendor_refs.empty?
    "#{ apt } + *bundled in vendor/* (`#{ vendor_refs.join("`, `") }`)"
  elsif !vendor_refs.empty?
    "*bundled in vendor/* (`#{ vendor_refs.join("`, `") }`)"
  elsif apt
    apt
  else
    "*bundled in vendor/*"
  end

  # Never hide any vendor/ file invoked by Cmd even if extra_installs was set.
  missing_vrefs = vendor_refs.reject {|v| how.include?(v) }
  unless missing_vrefs.empty?
    how = "#{ how } + *bundled in vendor/* (`#{ missing_vrefs.join("`, `") }`)"
  end

  [(idx + 1).to_s, s.name, how, mame_128.include?(s.name) ? "mame" : "**this fork**"]
end

ws = rows.transpose.map {|row| row.map {|s| s.size }.max + 1 }
rows[1, 0] = [ws.map {|w| "-" * w }]
rows = rows.map do |col|
  (col.zip(ws).map {|s, w| s.ljust(w) } * "|").rstrip
end

apt_get = "sudo apt-get install #{ [*apts.flatten.compact.uniq].sort * " " }"
apt_get.gsub!(/.{,70}( |\z)/) do
  $&[-1] == " " ? $& + "\\\n      " : $&
end

cmds = [*RunSteps, RunStep["Ruby", "QR2.rb"]].each_cons(2).map do |s1, s2|
  cmd = s1.cmd_raw
  src = s2.src
  cmd = cmd.gsub("OUTFILE", src)

  cmd = cmd.gsub(/^!/, "")
  cmd = cmd.gsub(/.{60,}?&&/, "\\0\n     ")

  cmd
end

File.binwrite("../README.md", ERB.new(DATA.read, trim_mode: "%").result(binding))


__END__
# Quine Relay 256

**A 256-language quine relay extending [Yusuke Endoh's Quine Relay](https://github.com/mame/quine-relay) — preserving all <%= mame_steps.size %> single-implementation languages from Endoh's Ubuntu 26.04 relay, restoring <%= active_retirees.size %>/<%= TOTAL_MAME_RETIREES %> languages retired from its earlier Ubuntu editions, adding Malbolge Unshackled, and adding <%= fork_new_count %> standalone open-source languages.**

This fork targets a strict 1-to-1 count (**steps = distinct languages = <%= RunSteps.size %>**), omitting the 5 alternate encodings/versions/formats from the 128-step base (`Ook!`, `JSFuck`, `WebAssembly (Binary format)`, `FORTRAN77`, `Gzip`) and avoiding duplicate shell/Scheme/dialect entries so every step is a distinct programming language.

## What this is

[QR.rb](QR.rb) is <%= a_or_an(RunSteps[0].name) %> program that generates
<%= a_or_an(RunSteps[1].name) %> program that generates
<%= a_or_an(RunSteps[2].name) %> program that generates
...(through <%= RunSteps.size %> distinct languages in total)...
<%= a_or_an(RunSteps[-1].name) %> program that generates
the original <%= RunSteps[0].name %> code again.

![Language Uroboros][langs]

[langs]: langs.png

The languages in red are the <%= new_steps.size %> languages added in this fork. Everything in black is from Yusuke Endoh's Ubuntu 26.04 `mame/quine-relay`.

## The rules every step follows

Yusuke Endoh (mame) reviewed an earlier prototype and shared three no-cheating principles he uses as a matter of craft and fairness. Every step in this relay follows these principles, with the inherited upstream precedents and minor fork toolchain accommodations disclosed transparently below:

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
  - `Pony`: `ponyc` compiles a package directory rather than a standalone source file, so the recipe stages `QR.pony` into `qrpony/main.pony` before invoking `ponyc qrpony`.
  - `Z80 asm`: `tnylpo` (CP/M 2.2 emulator) refuses UID 0 for safety, so the step recipe guards `setpriv --reuid=nobody --regid=nogroup --clear-groups` on `id -u = 0` and runs `tnylpo -b qr.com` directly for non-root users.
  - `K (ngn/k)`: built from a pinned vendored `AGPLv3` source tarball (`vendor/ngnk-b9eeb91e.tar.gz`) because upstream Codeberg archived the repository.
  - `vendor/` esolang runners: every bundled interpreter and runner (both upstream `mame` and fork-authored MIT runners such as `underload.rb`, `emmental.rb`, `slashes.rb`, and `beatnik.rb`) is listed explicitly in the table below and in [`vendor/README`](vendor/README). Where canonical upstream interpreters or emulators exist (`CJam`, `Glass`, `><> (Fish)`, `Brain-Flak`, `6502 asm`, `Z80 asm`), this fork uses the real upstream tool rather than a custom stub.

All <%= mame_steps.size %> single-implementation languages from Endoh's Ubuntu 26.04 relay — including the verbatim, zero-`fopen` `Scilab -> sed -> Shakespeare -> S-Lang` chain — run intact alongside **Malbolge Unshackled** (self-contained, rotwidth-independent, zero `'/'` input executions, built from an in-tree generator `src/malbolge-boot.dat.gen.py` and verified byte-exact on both untouched CC0 `Unshackled.c` and `Unshackled-20.c`).

## Proof that it works

This repository's [`Dockerfile`](Dockerfile) builds from scratch (`docker build --pull --no-cache`, `FROM ubuntu:26.04`, 67.3 min, 27.79 GB, 40 RootFS layers, image `d7666b94...`) and passes its untouched default `CMD` (`make check -j 10000`) **100% offline (`docker run --rm --network=none`)** in 23.6 min:

- **All <%= RunSteps.size %> languages run in sequence offline** inside one self-contained Ubuntu 26.04 Docker image with pinned open-source toolchains and bundled `vendor/` interpreters (zero network calls during execution).
- **Every intermediate file matches [`SHA256SUMS`](SHA256SUMS)** (all <%= RunSteps.size %> of them, verified by `sha256sum --quiet -c SHA256SUMS` inside the image's own default `CMD`).
- **Step <%= RunSteps.size %> (<%= RunSteps[-1].name %>) prints `QR2.rb`, byte-for-byte identical to `QR.rb`** (<%= qr_size %> bytes, SHA-256 `<%= qr_sha %>`).
- **Canary & dual-interpreter checks:** verified byte-exact on both `Unshackled.c` and `Unshackled-20.c` (`U20 PARITY OK`), plus a full 256-step offline canary loop (`Drawn With Code` -> `Drawn With K0de` under `--network=none`, closing `QR2.rb == modified QR.rb`).

The full build log, offline run log, and verification result live in [`proof/`](proof/). Anyone can reproduce the entire proof with the two Docker commands under Usage.

## What's new in this fork

**<%= new_steps.size %> languages added beyond Endoh's current Ubuntu 26.04 relay** (<%= active_retirees.size %>/<%= TOTAL_MAME_RETIREES %> restored from earlier Ubuntu editions of `mame/quine-relay`, **Malbolge Unshackled**, and <%= fork_new_count %> standalone open-source languages):

<%= new_steps.map {|s| s.name }.join(", ") %>.

[RELAY-256.md](RELAY-256.md) explains the compression architecture, run-order optimization (~1,100 MB down to 316.24 MB), 64 KB VM ROM budgets, and Malbolge Unshackled generator. [RECORDS.md](RECORDS.md) documents the counting rules and [LANGUAGES.md](LANGUAGES.md) lists all <%= RunSteps.size %> languages in run order.

## Usage

### Docker (recommended)

    $ docker build -t qr .
    $ docker run --rm --network=none qr

This installs every Ubuntu package, builds all pinned toolchains and bundled interpreters in `vendor/`, runs all <%= RunSteps.size %> steps offline in order (unprivileged), and verifies `QR2.rb == QR.rb`. Note that the full image requires roughly ~28 GB of disk space (~40+ GB free during build).

### Ubuntu 26.04

#### 1. Install the Ubuntu packages and extra toolchains.

    $ <%= apt_get %>

For the remaining languages installed from pinned releases, cargo, Go, npm, pip, or source tarballs, see [`Dockerfile`](Dockerfile) (generated from [`src/Dockerfile.gen.rb`](src/Dockerfile.gen.rb) and [`src/extra-installs/`](src/extra-installs/)).

Then build the bundled interpreters:

    $ sudo apt-get install <%= other_packages.join(" ") %>
    $ make -C vendor

#### 2. Run each program on each interpreter/compiler.

    $ ulimit -s unlimited
% cmds.each do |cmd|
    $ <%= cmd %>
% end

You will see that `QR.rb` is byte-for-byte identical to `QR2.rb`:

    $ diff -s QR.rb QR2.rb

Or just run `make check`:

    $ make check

## Languages and packages

% rows.each do |row|
<%= row %>
% end

Every language marked *bundled in vendor/* uses an archive, binary, or interpreter in `vendor/`; see [`vendor/README`](vendor/README) for complete provenance, modifications, and per-file licenses.

## Frequently asked questions

### Q. Who made this?

A. The original 128-language Quine Relay, its uroboros code generator, and the core compression architecture were created by [Yusuke Endoh (mame)](https://github.com/mame) and contributors starting in 2013. This fork extends the relay to 256 distinct languages (including Malbolge Unshackled and <%= active_retirees.size %>/<%= TOTAL_MAME_RETIREES %> restored retirees from earlier Ubuntu editions of `mame/quine-relay`), optimizes the run order, and documents the counting rules. Built by [Drawn With Code](https://www.youtube.com/@DrawnWithCode).

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

`src/code-gen.rb` defines all <%= RunSteps.size %> steps, and `src/malbolge-boot.dat.gen.py` (alongside `blc-boot.dat.gen.rb`, `grass-boot.dat.gen.rb`, and `lazyk-boot.dat.gen.rb`) builds the bootstrapper data files. `rake` rebuilds `QR.rb`, `Makefile`, `Dockerfile`, `LANGUAGES.md`, `.github/workflows/main.yml`, and this `README.md`. `src/langs.png.gen.rb` (or `tools/langs_png.py`) renders `langs.png`, and `src/thumbnail.png.gen.rb` renders `thumbnail.png`.

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
