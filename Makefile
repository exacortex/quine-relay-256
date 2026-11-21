MAKEFLAGS += --no-print-directory

PATH := $(CURDIR)/vendor/local/bin:/usr/games:$(PATH)
CLASSPATH := .

find_any0 = $(firstword $(foreach x,$(1),$(if $(shell which $(x) 2>/dev/null),$(x),)))
check = $(if $(2),$(2),$(error $(1) interpreter not found!))
find_any = $(call check,$(1),$(call find_any0,$(2)))

JAVASCRIPT   := $(call find_any,JavaScript,nodejs node js)
SCHEME       := $(call find_any,Scheme,guile csi gosh)
GBS          := $(call find_any,Gambas script,gbs3 gbs2 gba3)
WASI_RUNTIME := $(call find_any,WASI runtime,wasmtime node)

ifeq ($(SCHEME),csi)
  SCHEME := csi -s
endif
ifeq ($(WASI_RUNTIME),node)
  WASI_RUNTIME := node --experimental-wasi-unstable-preview1 vendor/wasi-runtime.js
endif

.DELETE_ON_ERROR:

all: QR2.rb
	@echo
	@echo "#############"
	@echo "##  CHECK  ##"
	@echo "#############"
	@echo
	diff -s QR.rb QR2.rb

check: all
	@sha256sum --quiet -c SHA256SUMS

QR.sim: QR.rb
	@echo
	@echo "#########################"
	@echo "##  1: Ruby -> Simula  ##"
	@echo "#########################"
	@echo
	ruby QR.rb > QR.sim

QR.obn: QR.sim
	@echo
	@echo "###########################"
	@echo "##  2: Simula -> Oberon  ##"
	@echo "###########################"
	@echo
	@[ ! -f QR.c ] || mv QR.c QR.c.bak
	cim -q -b -w QR.sim
	./QR > QR.obn
	rm -f QR QR.o
	@[ ! -f QR.c.bak ] || mv QR.c.bak QR.c

QR.ex: QR.obn
	@echo
	@echo "#############################"
	@echo "##  3: Oberon -> Euphoria  ##"
	@echo "#############################"
	@echo
	rm -rf QR .obnc
	obnc QR.obn >/dev/null
	./QR > QR.ex
	rm -rf QR .obnc

QR.alg: QR.ex
	@echo
	@echo "###############################"
	@echo "##  4: Euphoria -> ALGOL 60  ##"
	@echo "###############################"
	@echo
	eui QR.ex > QR.alg

QR.v: QR.alg
	@echo
	@echo "##############################"
	@echo "##  5: ALGOL 60 -> Verilog  ##"
	@echo "##############################"
	@echo
	marst QR.alg -o QR.alg.c
	gcc QR.alg.c -lalgol -lm -o QR
	./QR > QR.v
	rm -f QR QR.alg.c

QR.ss: QR.v
	@echo
	@echo "#################################"
	@echo "##  6: Verilog -> SurgeScript  ##"
	@echo "#################################"
	@echo
	iverilog -o QR QR.v
	./QR -vcd-none > QR.ss

QR.tcl: QR.ss
	@echo
	@echo "#############################"
	@echo "##  7: SurgeScript -> Tcl  ##"
	@echo "#############################"
	@echo
	surgescript QR.ss > QR.tcl

QR.rhai: QR.tcl
	@echo
	@echo "######################"
	@echo "##  8: Tcl -> Rhai  ##"
	@echo "######################"
	@echo
	tclsh QR.tcl > QR.rhai

QR.dart: QR.rhai
	@echo
	@echo "#######################"
	@echo "##  9: Rhai -> Dart  ##"
	@echo "#######################"
	@echo
	rhai-run QR.rhai > QR.dart

QR.gel: QR.dart
	@echo
	@echo "################################"
	@echo "##  10: Dart -> GEL (Genius)  ##"
	@echo "################################"
	@echo
	dart run QR.dart > QR.gel

QR.hxg: QR.gel
	@echo
	@echo "####################################"
	@echo "##  11: GEL (Genius) -> Hexagony  ##"
	@echo "####################################"
	@echo
	genius QR.gel > QR.hxg

QR.k.k: QR.hxg
	@echo
	@echo "#################################"
	@echo "##  12: Hexagony -> K (ngn/k)  ##"
	@echo "#################################"
	@echo
	ruby /opt/hexagony/interpreter.rb QR.hxg > QR.k.k

QR.azm: QR.k.k
	@echo
	@echo "#############################"
	@echo "##  13: K (ngn/k) -> Zoem  ##"
	@echo "#############################"
	@echo
	ngnk QR.k.k < /dev/null > QR.azm

QR.ha: QR.azm
	@echo
	@echo "########################"
	@echo "##  14: Zoem -> Hare  ##"
	@echo "########################"
	@echo
	zoem -i QR.azm > QR.ha

QR.golo: QR.ha
	@echo
	@echo "########################"
	@echo "##  15: Hare -> Golo  ##"
	@echo "########################"
	@echo
	hare build -q -o QR QR.ha
	./QR > QR.golo

QR.scala: QR.golo
	@echo
	@echo "#########################"
	@echo "##  16: Golo -> Scala  ##"
	@echo "#########################"
	@echo
	golo golo --files QR.golo > QR.scala

QR.ndf: QR.scala
	@echo
	@echo "#########################"
	@echo "##  17: Scala -> Nial  ##"
	@echo "#########################"
	@echo
	scalac QR.scala
	scala QR > QR.ndf

QR.yab: QR.ndf
	@echo
	@echo "###########################"
	@echo "##  18: Nial -> Yabasic  ##"
	@echo "###########################"
	@echo
	nial -defs QR.ndf < /dev/null > QR.yab

QR.ua: QR.yab
	@echo
	@echo "###########################"
	@echo "##  19: Yabasic -> Uiua  ##"
	@echo "###########################"
	@echo
	yabasic QR.yab > QR.ua

QR.bqn: QR.ua
	@echo
	@echo "#######################"
	@echo "##  20: Uiua -> BQN  ##"
	@echo "#######################"
	@echo
	uiua run --no-format QR.ua > QR.bqn

QR.fan: QR.bqn
	@echo
	@echo "#########################"
	@echo "##  21: BQN -> Fantom  ##"
	@echo "#########################"
	@echo
	bqn QR.bqn > QR.fan

QR.um: QR.fan
	@echo
	@echo "##########################"
	@echo "##  22: Fantom -> Umka  ##"
	@echo "##########################"
	@echo
	fan QR.fan > QR.um

QR.vim: QR.um
	@echo
	@echo "#############################"
	@echo "##  23: Umka -> Vimscript  ##"
	@echo "#############################"
	@echo
	umka QR.um > QR.vim

QR.fr: QR.vim
	@echo
	@echo "##############################"
	@echo "##  24: Vimscript -> Frege  ##"
	@echo "##############################"
	@echo
	vim -EsS QR.vim > QR.fr

QR.ijs: QR.fr
	@echo
	@echo "######################"
	@echo "##  25: Frege -> J  ##"
	@echo "######################"
	@echo
	mkdir -p frege-out
	frege -d frege-out QR.fr
	java -cp frege-out:/usr/local/lib/frege.jar QR > QR.ijs

QR.ring: QR.ijs
	@echo
	@echo "#####################"
	@echo "##  26: J -> Ring  ##"
	@echo "#####################"
	@echo
	ijconsole QR.ijs < /dev/null > QR.ring

QR.dats: QR.ring
	@echo
	@echo "#######################"
	@echo "##  27: Ring -> ATS  ##"
	@echo "#######################"
	@echo
	ring QR.ring > QR.dats

QR.ps1: QR.dats
	@echo
	@echo "#############################"
	@echo "##  28: ATS -> PowerShell  ##"
	@echo "#############################"
	@echo
	patscc -o QR QR.dats
	./QR > QR.ps1

QRMUMPS.m: QR.ps1
	@echo
	@echo "###############################"
	@echo "##  29: PowerShell -> MUMPS  ##"
	@echo "###############################"
	@echo
	DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=1 POWERSHELL_TELEMETRY_OPTOUT=1 pwsh -NoProfile -NonInteractive -File QR.ps1 > QRMUMPS.m

QR.ms: QRMUMPS.m
	@echo
	@echo "###############################"
	@echo "##  30: MUMPS -> MiniScript  ##"
	@echo "###############################"
	@echo
	ydb_dist=/opt/yottadb ydb_routines=. /opt/yottadb/yottadb -run QRMUMPS > QR.ms

QR.boron: QR.ms
	@echo
	@echo "###############################"
	@echo "##  31: MiniScript -> Boron  ##"
	@echo "###############################"
	@echo
	miniscript QR.ms > QR.boron

QR.mk: QR.boron
	@echo
	@echo "#############################"
	@echo "##  32: Boron -> Makefile  ##"
	@echo "#############################"
	@echo
	boron QR.boron > QR.mk

QR.mth: QR.mk
	@echo
	@echo "#############################"
	@echo "##  33: Makefile -> Mirth  ##"
	@echo "#############################"
	@echo
	make -f QR.mk > QR.mth

QR.lily: QR.mth
	@echo
	@echo "#########################"
	@echo "##  34: Mirth -> Lily  ##"
	@echo "#########################"
	@echo
	mirth -p std:/opt/mirth/lib/std -p qr:. ./QR.mth -o QR.mth.c > /dev/null
	$(CC) -O2 -Wno-trigraphs -o QR QR.mth.c
	./QR > QR.lily

qr.adb: QR.lily
	@echo
	@echo "#######################"
	@echo "##  35: Lily -> Ada  ##"
	@echo "#######################"
	@echo
	lily QR.lily > qr.adb

QR.aj: qr.adb
	@echo
	@echo "##########################"
	@echo "##  36: Ada -> AspectJ  ##"
	@echo "##########################"
	@echo
	gnatmake qr.adb
	./qr > QR.aj

QR.asy: QR.aj
	@echo
	@echo "################################"
	@echo "##  37: AspectJ -> Asymptote  ##"
	@echo "################################"
	@echo
	ajc QR.aj
	java QR > QR.asy

QR.bal: QR.asy
	@echo
	@echo "##################################"
	@echo "##  38: Asymptote -> Ballerina  ##"
	@echo "##################################"
	@echo
	asy QR.asy > QR.bal

QR.scm: QR.bal
	@echo
	@echo "###############################"
	@echo "##  39: Ballerina -> Scheme  ##"
	@echo "###############################"
	@echo
	bal run --offline QR.bal > QR.scm

QR.vhdl: QR.scm
	@echo
	@echo "##########################"
	@echo "##  40: Scheme -> VHDL  ##"
	@echo "##########################"
	@echo
	$(SCHEME) QR.scm > QR.vhdl

QR.bash: QR.vhdl
	@echo
	@echo "########################"
	@echo "##  41: VHDL -> bash  ##"
	@echo "########################"
	@echo
	ghdl -a QR.vhdl
	ghdl -e qr
	ghdl -r qr > QR.bash

QR.bc: QR.bash
	@echo
	@echo "######################"
	@echo "##  42: bash -> bc  ##"
	@echo "######################"
	@echo
	bash QR.bash > QR.bc

QR.rs: QR.bc
	@echo
	@echo "######################"
	@echo "##  43: bc -> Rust  ##"
	@echo "######################"
	@echo
	BC_LINE_LENGTH=4000000 bc -q QR.bc > QR.rs

QR.e: QR.rs
	@echo
	@echo "############################"
	@echo "##  44: Rust -> Execline  ##"
	@echo "############################"
	@echo
	rustc QR.rs
	./QR > QR.e

QR.yorick: QR.e
	@echo
	@echo "##############################"
	@echo "##  45: Execline -> Yorick  ##"
	@echo "##############################"
	@echo
	execlineb QR.e > QR.yorick

QR.wl: QR.yorick
	@echo
	@echo "#############################"
	@echo "##  46: Yorick -> Mathics  ##"
	@echo "#############################"
	@echo
	yorick -batch QR.yorick > QR.wl

QR.nl: QR.wl
	@echo
	@echo "##############################"
	@echo "##  47: Mathics -> newLISP  ##"
	@echo "##############################"
	@echo
	mathics -q --no-completion -f QR.wl < /dev/null > QR.nl

QR.awk: QR.nl
	@echo
	@echo "##########################"
	@echo "##  48: newLISP -> Awk  ##"
	@echo "##########################"
	@echo
	newlisp -n QR.nl > QR.awk

QR.nelua: QR.awk
	@echo
	@echo "########################"
	@echo "##  49: Awk -> Nelua  ##"
	@echo "########################"
	@echo
	awk -f QR.awk > QR.nelua

QR.hy: QR.nelua
	@echo
	@echo "#######################"
	@echo "##  50: Nelua -> Hy  ##"
	@echo "#######################"
	@echo
	nelua --no-cache QR.nelua > QR.hy

QR.be: QR.hy
	@echo
	@echo "#######################"
	@echo "##  51: Hy -> Berry  ##"
	@echo "#######################"
	@echo
	hy QR.hy > QR.be

QR.chai: QR.be
	@echo
	@echo "###############################"
	@echo "##  52: Berry -> ChaiScript  ##"
	@echo "###############################"
	@echo
	berry QR.be > QR.chai

QR.glu: QR.chai
	@echo
	@echo "###############################"
	@echo "##  53: ChaiScript -> Gluon  ##"
	@echo "###############################"
	@echo
	chai QR.chai > QR.glu

QR.purs: QR.glu
	@echo
	@echo "###############################"
	@echo "##  54: Gluon -> PureScript  ##"
	@echo "###############################"
	@echo
	gluon QR.glu > QR.purs

QR.c: QR.purs
	@echo
	@echo "###########################"
	@echo "##  55: PureScript -> C  ##"
	@echo "###########################"
	@echo
	purs compile -o purs_out QR.purs '/opt/purs/lib/*/src/**/*.purs'
	node purs_out/QR/index.js > QR.c
	rm -rf purs_out

QR.cpp: QR.c
	@echo
	@echo "####################"
	@echo "##  56: C -> C++  ##"
	@echo "####################"
	@echo
	$(CC) -o QR QR.c
	./QR > QR.cpp

QR.mms: QR.cpp
	@echo
	@echo "#######################"
	@echo "##  57: C++ -> MMIX  ##"
	@echo "#######################"
	@echo
	$(CXX) -o QR QR.cpp
	./QR > QR.mms

QR.pyth: QR.mms
	@echo
	@echo "########################"
	@echo "##  58: MMIX -> Pyth  ##"
	@echo "########################"
	@echo
	mmixal -b 2000000 -o QR.mmo QR.mms
	mmix QR.mmo > QR.pyth
	rm -f QR.mmo

QR.emmental: QR.pyth
	@echo
	@echo "############################"
	@echo "##  59: Pyth -> Emmental  ##"
	@echo "############################"
	@echo
	python3 /opt/pyth/pyth.py -n QR.pyth > QR.emmental

QR.lobster: QR.emmental
	@echo
	@echo "###############################"
	@echo "##  60: Emmental -> Lobster  ##"
	@echo "###############################"
	@echo
	ruby vendor/emmental.rb QR.emmental > QR.lobster

QR.factor: QR.lobster
	@echo
	@echo "#############################"
	@echo "##  61: Lobster -> Factor  ##"
	@echo "#############################"
	@echo
	lobster QR.lobster > QR.factor

QR.ion: QR.factor
	@echo
	@echo "#########################"
	@echo "##  62: Factor -> Ion  ##"
	@echo "#########################"
	@echo
	/opt/factor/factor QR.factor > QR.ion

QR.gsl: QR.ion
	@echo
	@echo "#####################################################"
	@echo "##  63: Ion -> GSL (Generator Scripting Language)  ##"
	@echo "#####################################################"
	@echo
	ion QR.ion > QR.gsl

QR.arnoldc: QR.gsl
	@echo
	@echo "#########################################################"
	@echo "##  64: GSL (Generator Scripting Language) -> ArnoldC  ##"
	@echo "#########################################################"
	@echo
	gsl -q QR.gsl > QR.arnoldc

QR.lfe: QR.arnoldc
	@echo
	@echo "##########################"
	@echo "##  65: ArnoldC -> LFE  ##"
	@echo "##########################"
	@echo
	rm -f QR.class
	java -jar /opt/ArnoldC.jar QR.arnoldc
	java QR > QR.lfe
	rm -f QR.class

QR.cy: QR.lfe
	@echo
	@echo "########################"
	@echo "##  66: LFE -> Cyber  ##"
	@echo "########################"
	@echo
	lfe QR.lfe > QR.cy

QR.pk: QR.cy
	@echo
	@echo "###############################"
	@echo "##  67: Cyber -> PocketLang  ##"
	@echo "###############################"
	@echo
	cyber QR.cy > QR.pk

QR.d: QR.pk
	@echo
	@echo "###########################"
	@echo "##  68: PocketLang -> D  ##"
	@echo "###########################"
	@echo
	pocket QR.pk > QR.d

QR.nu: QR.d
	@echo
	@echo "########################"
	@echo "##  69: D -> Nushell  ##"
	@echo "########################"
	@echo
	gdc -o QR QR.d
	./QR > QR.nu

QR.gsp: QR.nu
	@echo
	@echo "###########################"
	@echo "##  70: Nushell -> Gosu  ##"
	@echo "###########################"
	@echo
	nu --no-config-file QR.nu > QR.gsp

QR.ysh: QR.gsp
	@echo
	@echo "#######################"
	@echo "##  71: Gosu -> YSH  ##"
	@echo "#######################"
	@echo
	gosu QR.gsp > QR.ysh

QR.tengo: QR.ysh
	@echo
	@echo "########################"
	@echo "##  72: YSH -> Tengo  ##"
	@echo "########################"
	@echo
	ysh QR.ysh > QR.tengo

QR.coffee: QR.tengo
	@echo
	@echo "#################################"
	@echo "##  73: Tengo -> CoffeeScript  ##"
	@echo "#################################"
	@echo
	tengo QR.tengo > QR.coffee

QR.lisp: QR.coffee
	@echo
	@echo "#######################################"
	@echo "##  74: CoffeeScript -> Common Lisp  ##"
	@echo "#######################################"
	@echo
	coffee --nodejs --stack_size=100000 QR.coffee > QR.lisp

QR.cr: QR.lisp
	@echo
	@echo "##################################"
	@echo "##  75: Common Lisp -> Crystal  ##"
	@echo "##################################"
	@echo
	clisp QR.lisp > QR.cr

QR.ank: QR.cr
	@echo
	@echo "###########################"
	@echo "##  76: Crystal -> Anko  ##"
	@echo "###########################"
	@echo
	crystal QR.cr > QR.ank

QR.el: QR.ank
	@echo
	@echo "##############################"
	@echo "##  77: Anko -> Emacs Lisp  ##"
	@echo "##############################"
	@echo
	anko QR.ank > QR.el

QR.dc: QR.el
	@echo
	@echo "############################"
	@echo "##  78: Emacs Lisp -> dc  ##"
	@echo "############################"
	@echo
	emacs -Q --script QR.el > QR.dc

QR.dhall: QR.dc
	@echo
	@echo "#######################"
	@echo "##  79: dc -> Dhall  ##"
	@echo "#######################"
	@echo
	dc QR.dc > QR.dhall || true

QR.exs: QR.dhall
	@echo
	@echo "###########################"
	@echo "##  80: Dhall -> Elixir  ##"
	@echo "###########################"
	@echo
	dhall text --file QR.dhall > QR.exs

QR.erl: QR.exs
	@echo
	@echo "############################"
	@echo "##  81: Elixir -> Erlang  ##"
	@echo "############################"
	@echo
	elixir QR.exs > QR.erl

QR.mx: QR.erl
	@echo
	@echo "###########################"
	@echo "##  82: Erlang -> Murex  ##"
	@echo "###########################"
	@echo
	escript QR.erl > QR.mx

QR.fnl: QR.mx
	@echo
	@echo "###########################"
	@echo "##  83: Murex -> Fennel  ##"
	@echo "###########################"
	@echo
	murex QR.mx > QR.fnl

QR.tcsh: QR.fnl
	@echo
	@echo "##########################"
	@echo "##  84: Fennel -> tcsh  ##"
	@echo "##########################"
	@echo
	fennel QR.fnl > QR.tcsh

QR.t: QR.tcsh
	@echo
	@echo "########################"
	@echo "##  85: tcsh -> Thue  ##"
	@echo "########################"
	@echo
	tcsh QR.tcsh > QR.t

QR.hx: QR.t
	@echo
	@echo "########################"
	@echo "##  86: Thue -> Haxe  ##"
	@echo "########################"
	@echo
	ruby vendor/thue.rb QR.t > QR.hx

QR.g: QR.hx
	@echo
	@echo "#######################"
	@echo "##  87: Haxe -> GAP  ##"
	@echo "#######################"
	@echo
	haxe -main QR -neko QR.n
	neko QR.n > QR.g

QR.zsh: QR.g
	@echo
	@echo "######################"
	@echo "##  88: GAP -> zsh  ##"
	@echo "######################"
	@echo
	gap -q QR.g > QR.zsh

QR.nut: QR.zsh
	@echo
	@echo "###########################"
	@echo "##  89: zsh -> Squirrel  ##"
	@echo "###########################"
	@echo
	zsh QR.zsh > QR.nut

QR.gdb: QR.nut
	@echo
	@echo "###########################"
	@echo "##  90: Squirrel -> GDB  ##"
	@echo "###########################"
	@echo
	squirrel QR.nut > QR.gdb

QR.pi: QR.gdb
	@echo
	@echo "########################"
	@echo "##  91: GDB -> Picat  ##"
	@echo "########################"
	@echo
	gdb -q -x QR.gdb > QR.pi

QR.fs: QR.pi
	@echo
	@echo "##########################"
	@echo "##  92: Picat -> Forth  ##"
	@echo "##########################"
	@echo
	picat QR.pi > QR.fs

QR.f90: QR.fs
	@echo
	@echo "##############################"
	@echo "##  93: Forth -> Fortran90  ##"
	@echo "##############################"
	@echo
	gforth QR.fs > QR.f90

QR.fal: QR.f90
	@echo
	@echo "###############################"
	@echo "##  94: Fortran90 -> Falcon  ##"
	@echo "###############################"
	@echo
	gfortran -o QR QR.f90
	./QR > QR.fal

QR.fish: QR.fal
	@echo
	@echo "##########################"
	@echo "##  95: Falcon -> Fish  ##"
	@echo "##########################"
	@echo
	falcon QR.fal > QR.fish

QR.false: QR.fish
	@echo
	@echo "#########################"
	@echo "##  96: Fish -> FALSE  ##"
	@echo "#########################"
	@echo
	fish QR.fish > QR.false

QR.xslt: QR.false
	@echo
	@echo "#########################"
	@echo "##  97: FALSE -> XSLT  ##"
	@echo "#########################"
	@echo
	ruby vendor/false.rb QR.false > QR.xslt

QR.go: QR.xslt
	@echo
	@echo "######################"
	@echo "##  98: XSLT -> Go  ##"
	@echo "######################"
	@echo
	xsltproc QR.xslt > QR.go

QR.fl: QR.go
	@echo
	@echo "######################"
	@echo "##  99: Go -> Flex  ##"
	@echo "######################"
	@echo
	go run QR.go > QR.fl

QR.fsx: QR.fl
	@echo
	@echo "#######################"
	@echo "##  100: Flex -> F#  ##"
	@echo "#######################"
	@echo
	flex -o QR.fl.c QR.fl
	gcc -o QR QR.fl.c
	./QR > QR.fsx

QR.fish.fish: QR.fsx
	@echo
	@echo "#############################"
	@echo "##  101: F# -> ><> (Fish)  ##"
	@echo "#############################"
	@echo
	echo '<Project Sdk="Microsoft.NET.Sdk"><PropertyGroup><OutputType>Exe</OutputType><TargetFramework>net10.0</TargetFramework><EnableDefaultCompileItems>false</EnableDefaultCompileItems></PropertyGroup><ItemGroup><Compile Include="QR.fsx" /></ItemGroup></Project>' > tmp.fsproj
	DOTNET_NOLOGO=1 dotnet run --project tmp.fsproj > QR.fish.fish

QR.vlang.v: QR.fish.fish
	@echo
	@echo "############################"
	@echo "##  102: ><> (Fish) -> V  ##"
	@echo "############################"
	@echo
	python3 /opt/fish/fish.py QR.fish.fish > QR.vlang.v

QR.sing: QR.vlang.v
	@echo
	@echo "##########################"
	@echo "##  103: V -> Singular  ##"
	@echo "##########################"
	@echo
	v run QR.vlang.v > QR.sing

QR.idr: QR.sing
	@echo
	@echo "################################"
	@echo "##  104: Singular -> Idris 2  ##"
	@echo "################################"
	@echo
	Singular -q QR.sing > QR.idr

QR.swift: QR.idr
	@echo
	@echo "#############################"
	@echo "##  105: Idris 2 -> Swift  ##"
	@echo "#############################"
	@echo
	idris2 --exec main QR.idr > QR.swift

QR.koto: QR.swift
	@echo
	@echo "##########################"
	@echo "##  106: Swift -> Koto  ##"
	@echo "##########################"
	@echo
	swiftc QR.swift
	./QR > QR.koto

QR.janet: QR.koto
	@echo
	@echo "##########################"
	@echo "##  107: Koto -> Janet  ##"
	@echo "##########################"
	@echo
	koto QR.koto > QR.janet

QR.c3: QR.janet
	@echo
	@echo "########################"
	@echo "##  108: Janet -> C3  ##"
	@echo "########################"
	@echo
	janet QR.janet > QR.c3

QR.plt: QR.c3
	@echo
	@echo "##########################"
	@echo "##  109: C3 -> Gnuplot  ##"
	@echo "##########################"
	@echo
	c3c compile QR.c3 -o QR
	./QR > QR.plt

QR.gbs: QR.plt
	@echo
	@echo "#####################################"
	@echo "##  110: Gnuplot -> Gambas script  ##"
	@echo "#####################################"
	@echo
	gnuplot QR.plt > QR.gbs

QR.ts: QR.gbs
	@echo
	@echo "########################################"
	@echo "##  111: Gambas script -> TypeScript  ##"
	@echo "########################################"
	@echo
	$(GBS) QR.gbs > QR.ts

QR.unl: QR.ts
	@echo
	@echo "###################################"
	@echo "##  112: TypeScript -> Unlambda  ##"
	@echo "###################################"
	@echo
	tsc --outFile QR.ts.js QR.ts
	$(JAVASCRIPT) QR.ts.js > QR.unl

QR.groovy: QR.unl
	@echo
	@echo "###############################"
	@echo "##  113: Unlambda -> Groovy  ##"
	@echo "###############################"
	@echo
	ruby vendor/unlambda.rb QR.unl > QR.groovy

QR.io: QR.groovy
	@echo
	@echo "#########################"
	@echo "##  114: Groovy -> Io  ##"
	@echo "#########################"
	@echo
	groovy QR.groovy > QR.io

QR.j: QR.io
	@echo
	@echo "#########################"
	@echo "##  115: Io -> Jasmin  ##"
	@echo "#########################"
	@echo
	io QR.io > QR.j

QR.zig: QR.j
	@echo
	@echo "##########################"
	@echo "##  116: Jasmin -> Zig  ##"
	@echo "##########################"
	@echo
	jasmin QR.j
	java QR > QR.zig

QR.wren: QR.zig
	@echo
	@echo "########################"
	@echo "##  117: Zig -> Wren  ##"
	@echo "########################"
	@echo
	zig run QR.zig > QR.wren

QR.arr: QR.wren
	@echo
	@echo "##########################"
	@echo "##  118: Wren -> Pyret  ##"
	@echo "##########################"
	@echo
	wren_cli QR.wren > QR.arr

QR.hs: QR.arr
	@echo
	@echo "#############################"
	@echo "##  119: Pyret -> Haskell  ##"
	@echo "#############################"
	@echo
	pyretc QR.arr QR.jarr
	NODE_PATH=/opt/b05/node_modules node QR.jarr > QR.hs

QR.pike: QR.hs
	@echo
	@echo "############################"
	@echo "##  120: Haskell -> Pike  ##"
	@echo "############################"
	@echo
	rm -f QR.o
	ghc QR.hs
	./QR > QR.pike

QR.ps: QR.pike
	@echo
	@echo "###############################"
	@echo "##  121: Pike -> PostScript  ##"
	@echo "###############################"
	@echo
	pike QR.pike > QR.ps

QR.prolog: QR.ps
	@echo
	@echo "#################################"
	@echo "##  122: PostScript -> Prolog  ##"
	@echo "#################################"
	@echo
	gs -dNODISPLAY -q QR.ps > QR.prolog

QR.res: QR.prolog
	@echo
	@echo "###############################"
	@echo "##  123: Prolog -> ReScript  ##"
	@echo "###############################"
	@echo
	swipl -q -t qr -f QR.prolog > QR.res

QR.dfy: QR.res
	@echo
	@echo "##############################"
	@echo "##  124: ReScript -> Dafny  ##"
	@echo "##############################"
	@echo
	bsc QR.res > QR.res.js
	node QR.res.js > QR.dfy

QR.jl: QR.dfy
	@echo
	@echo "###########################"
	@echo "##  125: Dafny -> Julia  ##"
	@echo "###########################"
	@echo
	dafny build -o dafny-out/QR QR.dfy
	DOTNET_ROLL_FORWARD=Major dotnet dafny-out/QR.dll > QR.jl

QR.mac: QR.jl
	@echo
	@echo "############################"
	@echo "##  126: Julia -> Maxima  ##"
	@echo "############################"
	@echo
	julia QR.jl > QR.mac

QR.gri: QR.mac
	@echo
	@echo "##########################"
	@echo "##  127: Maxima -> Gri  ##"
	@echo "##########################"
	@echo
	maxima -q --init-mac=QR.mac > QR.gri

QR.logo: QR.gri
	@echo
	@echo "###########################"
	@echo "##  128: Gri -> UCBLogo  ##"
	@echo "###########################"
	@echo
	gri -output QR.gri.ps QR.gri > QR.logo

QR.java: QR.logo
	@echo
	@echo "############################"
	@echo "##  129: UCBLogo -> Java  ##"
	@echo "############################"
	@echo
	ucblogo QR.logo > QR.java

QR.mira: QR.java
	@echo
	@echo "############################"
	@echo "##  130: Java -> Miranda  ##"
	@echo "############################"
	@echo
	javac QR.java
	java QR > QR.mira

QR.icl: QR.mira
	@echo
	@echo "#############################"
	@echo "##  131: Miranda -> Clean  ##"
	@echo "#############################"
	@echo
	mira -exec QR.mira > QR.icl

QR.m2: QR.icl
	@echo
	@echo "###############################"
	@echo "##  132: Clean -> Macaulay2  ##"
	@echo "###############################"
	@echo
	clm -nt -nr QR -o QR > /dev/null
	./QR > QR.m2

QR.cs: QR.m2
	@echo
	@echo "############################"
	@echo "##  133: Macaulay2 -> C#  ##"
	@echo "############################"
	@echo
	M2 --script QR.m2 > QR.cs

QR.chef: QR.cs
	@echo
	@echo "#######################"
	@echo "##  134: C# -> Chef  ##"
	@echo "#######################"
	@echo
	echo '<Project Sdk="Microsoft.NET.Sdk"><PropertyGroup><OutputType>Exe</OutputType><TargetFramework>net10.0</TargetFramework><EnableDefaultCompileItems>false</EnableDefaultCompileItems></PropertyGroup><ItemGroup><Compile Include="QR.cs" /></ItemGroup></Project>' > tmp.csproj
	DOTNET_NOLOGO=1 dotnet run --project tmp.csproj > QR.chef

qr.li: QR.chef
	@echo
	@echo "###########################"
	@echo "##  135: Chef -> Lisaac  ##"
	@echo "###########################"
	@echo
	PERL5LIB=vendor/local/lib/perl5 compilechef QR.chef QR.chef.pl
	perl QR.chef.pl > qr.li

QR.clj: qr.li
	@echo
	@echo "##############################"
	@echo "##  136: Lisaac -> Clojure  ##"
	@echo "##############################"
	@echo
	lisaac -gcc -Wno-implicit-function-declaration qr.li > /dev/null
	./qr > QR.clj

QR.cmake: QR.clj
	@echo
	@echo "#############################"
	@echo "##  137: Clojure -> CMake  ##"
	@echo "#############################"
	@echo
	clojure QR.clj > QR.cmake

QR.cob: QR.cmake
	@echo
	@echo "###########################"
	@echo "##  138: CMake -> Cobol  ##"
	@echo "###########################"
	@echo
	cmake -P QR.cmake > QR.cob

qr.kk: QR.cob
	@echo
	@echo "##########################"
	@echo "##  139: Cobol -> Koka  ##"
	@echo "##########################"
	@echo
	cobc -O2 -x QR.cob
	./QR > qr.kk

QR.st: qr.kk
	@echo
	@echo "##################################"
	@echo "##  140: Koka -> GNU Smalltalk  ##"
	@echo "##################################"
	@echo
	koka -v0 -o qrkoka qr.kk
	chmod +x qrkoka
	./qrkoka > QR.st

QR.ll: QR.st
	@echo
	@echo "######################################"
	@echo "##  141: GNU Smalltalk -> LLVM asm  ##"
	@echo "######################################"
	@echo
	gst QR.st > QR.ll

QR.lol: QR.ll
	@echo
	@echo "################################"
	@echo "##  142: LLVM asm -> LOLCODE  ##"
	@echo "################################"
	@echo
	@mv QR.bc QR.bc.bak
	llvm-as QR.ll
	lli QR.bc > QR.lol
	@mv QR.bc.bak QR.bc

QR.lua: QR.lol
	@echo
	@echo "###########################"
	@echo "##  143: LOLCODE -> Lua  ##"
	@echo "###########################"
	@echo
	lci QR.lol > QR.lua

QR.sml: QR.lua
	@echo
	@echo "###############################"
	@echo "##  144: Lua -> Standard ML  ##"
	@echo "###############################"
	@echo
	lua5.3 QR.lua > QR.sml

QR.sq: QR.sml
	@echo
	@echo "##################################"
	@echo "##  145: Standard ML -> Subleq  ##"
	@echo "##################################"
	@echo
	polyc -o QR QR.sml
	./QR > QR.sq

QR.boo: QR.sq
	@echo
	@echo "##########################"
	@echo "##  146: Subleq -> Boo  ##"
	@echo "##########################"
	@echo
	ruby vendor/subleq.rb QR.sq > QR.boo

QR.cd: QR.boo
	@echo
	@echo "#########################"
	@echo "##  147: Boo -> CDuce  ##"
	@echo "#########################"
	@echo
	booi QR.boo > QR.cd

QR.txrlisp: QR.cd
	@echo
	@echo "#########################"
	@echo "##  148: CDuce -> TXR  ##"
	@echo "#########################"
	@echo
	cduce QR.cd > QR.txrlisp

QR.js: QR.txrlisp
	@echo
	@echo "##############################"
	@echo "##  149: TXR -> JavaScript  ##"
	@echo "##############################"
	@echo
	txr --lisp QR.txrlisp > QR.js

QR.jq: QR.js
	@echo
	@echo "#############################"
	@echo "##  150: JavaScript -> Jq  ##"
	@echo "#############################"
	@echo
	$(JAVASCRIPT) QR.js > QR.jq

QR.nc: QR.jq
	@echo
	@echo "#######################"
	@echo "##  151: Jq -> nesC  ##"
	@echo "#######################"
	@echo
	jq -j -n -f QR.jq > QR.nc

QR.gravity: QR.nc
	@echo
	@echo "############################"
	@echo "##  152: nesC -> Gravity  ##"
	@echo "############################"
	@echo
	nescc -gcc=gcc-14 -o QR QR.nc
	./QR > QR.gravity

QR.rkt: QR.gravity
	@echo
	@echo "##############################"
	@echo "##  153: Gravity -> Racket  ##"
	@echo "##############################"
	@echo
	gravity -q QR.gravity > QR.rkt

QR.aplus.a: QR.rkt
	@echo
	@echo "#########################"
	@echo "##  154: Racket -> A+  ##"
	@echo "#########################"
	@echo
	racket QR.rkt > QR.aplus.a

QR.kt: QR.aplus.a
	@echo
	@echo "#########################"
	@echo "##  155: A+ -> Kotlin  ##"
	@echo "#########################"
	@echo
	a+ QR.aplus.a > QR.kt 2> /dev/null < /dev/null

QR.arm64.s: QR.kt
	@echo
	@echo "################################"
	@echo "##  156: Kotlin -> ARM64 asm  ##"
	@echo "################################"
	@echo
	kotlinc QR.kt -include-runtime -d QR.jar
	kotlin QR.jar > QR.arm64.s

QR.sql: QR.arm64.s
	@echo
	@echo "######################################"
	@echo "##  157: ARM64 asm -> SQL (SQLite)  ##"
	@echo "######################################"
	@echo
	rm -f QR
	aarch64-linux-gnu-gcc -nostdlib -static -o QR QR.arm64.s
	qemu-aarch64 ./QR > QR.sql
	rm -f QR

QR.pasm: QR.sql
	@echo
	@echo "##############################################"
	@echo "##  158: SQL (SQLite) -> Parrot asm (PASM)  ##"
	@echo "##############################################"
	@echo
	sqlite3 < QR.sql > QR.pasm

QR.rv.s: QR.pasm
	@echo
	@echo "############################################"
	@echo "##  159: Parrot asm (PASM) -> RISC-V asm  ##"
	@echo "############################################"
	@echo
	parrot QR.pasm > QR.rv.s

QR.mzn: QR.rv.s
	@echo
	@echo "###################################"
	@echo "##  160: RISC-V asm -> MiniZinc  ##"
	@echo "###################################"
	@echo
	rm -f QR
	riscv64-linux-gnu-gcc -nostdlib -static -o QR QR.rv.s
	qemu-riscv64 ./QR > QR.mzn
	rm -f QR

QR.yeti: QR.mzn
	@echo
	@echo "#############################"
	@echo "##  161: MiniZinc -> Yeti  ##"
	@echo "#############################"
	@echo
	minizinc --solver COIN-BC --soln-sep '' QR.mzn > QR.yeti

QR.cc: QR.yeti
	@echo
	@echo "##############################"
	@echo "##  162: Yeti -> AspectC++  ##"
	@echo "##############################"
	@echo
	yeti QR.yeti > QR.cc

QR.vb: QR.cc
	@echo
	@echo "######################################"
	@echo "##  163: AspectC++ -> Visual Basic  ##"
	@echo "######################################"
	@echo
	ag++ --keywords -o QR QR.cc
	./QR > QR.vb

QR.wat: QR.vb
	@echo
	@echo "######################################################"
	@echo "##  164: Visual Basic -> WebAssembly (Text format)  ##"
	@echo "######################################################"
	@echo
	echo '<Project Sdk="Microsoft.NET.Sdk"><PropertyGroup><OutputType>Exe</OutputType><TargetFramework>net10.0</TargetFramework><EnableDefaultCompileItems>false</EnableDefaultCompileItems></PropertyGroup><ItemGroup><Compile Include="QR.vb" /></ItemGroup></Project>' > tmp.vbproj
	DOTNET_NOLOGO=1 dotnet run --project tmp.vbproj > QR.wat

QR.ws: QR.wat
	@echo
	@echo "####################################################"
	@echo "##  165: WebAssembly (Text format) -> Whitespace  ##"
	@echo "####################################################"
	@echo
	wat2wasm QR.wat -o QR.wat.wasm
	$(WASI_RUNTIME) QR.wat.wasm > QR.ws

QR.nbt: QR.ws
	@echo
	@echo "#################################"
	@echo "##  166: Whitespace -> Numbat  ##"
	@echo "#################################"
	@echo
	ruby vendor/whitespace.rb QR.ws > QR.nbt

QR.mod: QR.nbt
	@echo
	@echo "###############################"
	@echo "##  167: Numbat -> Modula-2  ##"
	@echo "###############################"
	@echo
	numbat QR.nbt > QR.mod

QR.il: QR.mod
	@echo
	@echo "#############################"
	@echo "##  168: Modula-2 -> MSIL  ##"
	@echo "#############################"
	@echo
	gm2 -fiso QR.mod -o QR
	./QR > QR.il

QR.gleam: QR.il
	@echo
	@echo "##########################"
	@echo "##  169: MSIL -> Gleam  ##"
	@echo "##########################"
	@echo
	ilasm QR.il
	mono QR.exe > QR.gleam

QR.dyon: QR.gleam
	@echo
	@echo "##########################"
	@echo "##  170: Gleam -> Dyon  ##"
	@echo "##########################"
	@echo
	mkdir -p qrgleam/src
	cp QR.gleam qrgleam/src/qr.gleam
	printf 'name = "qr"\nversion = "1.0.0"\n' > qrgleam/gleam.toml
	(cd qrgleam; gleam run --no-print-progress) > QR.dyon

QR.rye: QR.dyon
	@echo
	@echo "########################"
	@echo "##  171: Dyon -> Rye  ##"
	@echo "########################"
	@echo
	dyonrun QR.dyon > QR.rye

QR.a68: QR.rye
	@echo
	@echo "############################"
	@echo "##  172: Rye -> ALGOL 68  ##"
	@echo "############################"
	@echo
	rye QR.rye > QR.a68

QR.ante: QR.a68
	@echo
	@echo "#############################"
	@echo "##  173: ALGOL 68 -> Ante  ##"
	@echo "#############################"
	@echo
	a68g --heap 512M QR.a68 > QR.ante

QR.neko: QR.ante
	@echo
	@echo "#########################"
	@echo "##  174: Ante -> Neko  ##"
	@echo "#########################"
	@echo
	ruby vendor/ante.rb QR.ante > QR.neko

QR.nim: QR.neko
	@echo
	@echo "########################"
	@echo "##  175: Neko -> Nim  ##"
	@echo "########################"
	@echo
	nekoc QR.neko
	neko QR.n > QR.nim

QR_ec.ec: QR.nim
	@echo
	@echo "######################"
	@echo "##  176: Nim -> eC  ##"
	@echo "######################"
	@echo
	nim compile QR.nim
	./QR > QR_ec.ec

QR.vala: QR_ec.ec
	@echo
	@echo "#######################"
	@echo "##  177: eC -> Vala  ##"
	@echo "#######################"
	@echo
	ecp -c QR_ec.ec -o QR_ec.sym
	ecc -c QR_ec.ec -o QR_ec.c
	ecs -console QR_ec.sym QR_ec.imp -o QR_ec.main.ec
	ecp -c QR_ec.main.ec -o QR_ec.main.sym
	ecc -c QR_ec.main.ec -o QR_ec.main.c
	gcc -std=gnu17 -w -o QR_ec QR_ec.c QR_ec.main.c -lecereCOM
	./QR_ec > QR.vala

QR.mid: QR.vala
	@echo
	@echo "###########################"
	@echo "##  178: Vala -> Velato  ##"
	@echo "###########################"
	@echo
	valac QR.vala
	./QR > QR.mid

QR.gp: QR.mid
	@echo
	@echo "##############################"
	@echo "##  179: Velato -> PARI/GP  ##"
	@echo "##############################"
	@echo
	mono vendor/local/bin/Vlt.exe /s QR.mid
	mono QR.exe > QR.gp

QR.mustache: QR.gp
	@echo
	@echo "################################"
	@echo "##  180: PARI/GP -> Mustache  ##"
	@echo "################################"
	@echo
	gp -f -q QR.gp > QR.mustache

QR.asm: QR.mustache
	@echo
	@echo "#############################"
	@echo "##  181: Mustache -> NASM  ##"
	@echo "#############################"
	@echo
	mustache QR.mustache QR.mustache > QR.asm

QR.roc: QR.asm
	@echo
	@echo "########################"
	@echo "##  182: NASM -> Roc  ##"
	@echo "########################"
	@echo
	nasm -felf QR.asm
	ld -m elf_i386 -o QR QR.o
	./QR > QR.roc

QR.effekt: QR.roc
	@echo
	@echo "##########################"
	@echo "##  183: Roc -> Effekt  ##"
	@echo "##########################"
	@echo
	roc build --output qrroc QR.roc
	./qrroc > QR.effekt
	rm -f qrroc

QR.inko: QR.effekt
	@echo
	@echo "###########################"
	@echo "##  184: Effekt -> Inko  ##"
	@echo "###########################"
	@echo
	rm -rf qr_effekt_out
	effekt --backend js --out qr_effekt_out QR.effekt > QR.inko
	rm -rf qr_effekt_out

QR.ssa: QR.inko
	@echo
	@echo "########################"
	@echo "##  185: Inko -> QBE  ##"
	@echo "########################"
	@echo
	inko run QR.inko > QR.ssa

QR.apl: QR.ssa
	@echo
	@echo "###########################"
	@echo "##  186: QBE -> GNU APL  ##"
	@echo "###########################"
	@echo
	qbe QR.ssa > QR.qbe.s
	$(CC) QR.qbe.s -o QR
	./QR > QR.apl

QR.vale: QR.apl
	@echo
	@echo "############################"
	@echo "##  187: GNU APL -> Vale  ##"
	@echo "############################"
	@echo
	apl --script --OFF -s -f QR.apl > QR.vale

QR.pawn: QR.vale
	@echo
	@echo "#########################"
	@echo "##  188: Vale -> Pawn  ##"
	@echo "#########################"
	@echo
	rm -rf qr_vale_out
	valec build qr=QR.vale --output_dir qr_vale_out > /dev/null
	./qr_vale_out/main > QR.pawn
	rm -rf qr_vale_out

QR.m: QR.pawn
	@echo
	@echo "################################"
	@echo "##  189: Pawn -> Objective-C  ##"
	@echo "################################"
	@echo
	pawncc -C64 QR.pawn -oQR.amx > /dev/null
	pawnrun QR.amx > QR.m
	rm -f QR.amx

QR.octave: QR.m
	@echo
	@echo "##################################"
	@echo "##  190: Objective-C -> Octave  ##"
	@echo "##################################"
	@echo
	gcc -o QR QR.m
	./QR > QR.octave

QR.ml: QR.octave
	@echo
	@echo "############################"
	@echo "##  191: Octave -> OCaml  ##"
	@echo "############################"
	@echo
	mv QR.m QR.m.bak
	octave -qf QR.octave > QR.ml
	mv QR.m.bak QR.m

QR.chpl: QR.ml
	@echo
	@echo "############################"
	@echo "##  192: OCaml -> Chapel  ##"
	@echo "############################"
	@echo
	ocaml QR.ml > QR.chpl

QR.pony: QR.chpl
	@echo
	@echo "###########################"
	@echo "##  193: Chapel -> Pony  ##"
	@echo "###########################"
	@echo
	chpl -o qrchpl QR.chpl
	./qrchpl > QR.pony

QR.pl6: QR.pony
	@echo
	@echo "###########################"
	@echo "##  194: Pony -> Perl 6  ##"
	@echo "###########################"
	@echo
	mkdir -p qrpony
	cp QR.pony qrpony/main.pony
	ponyc -V0 -b qrpony.out -o . qrpony
	./qrpony.out > QR.pl6

qr_mercury.m: QR.pl6
	@echo
	@echo "##############################"
	@echo "##  195: Perl 6 -> Mercury  ##"
	@echo "##############################"
	@echo
	perl6 QR.pl6 > qr_mercury.m

QR.odin: qr_mercury.m
	@echo
	@echo "############################"
	@echo "##  196: Mercury -> Odin  ##"
	@echo "############################"
	@echo
	mmc --make qr_mercury > /dev/null
	./qr_mercury > QR.odin

QR.art: QR.odin
	@echo
	@echo "###########################"
	@echo "##  197: Odin -> Arturo  ##"
	@echo "###########################"
	@echo
	odin run QR.odin -file > QR.art

QR.l: QR.art
	@echo
	@echo "###############################"
	@echo "##  198: Arturo -> PicoLisp  ##"
	@echo "###############################"
	@echo
	arturo QR.art < /dev/null > QR.l

QR.elv: QR.l
	@echo
	@echo "###############################"
	@echo "##  199: PicoLisp -> Elvish  ##"
	@echo "###############################"
	@echo
	pil QR.l > QR.elv

QR.lean: QR.elv
	@echo
	@echo "#############################"
	@echo "##  200: Elvish -> Lean 4  ##"
	@echo "#############################"
	@echo
	elvish QR.elv > QR.lean

QR.slashes: QR.lean
	@echo
	@echo "##########################"
	@echo "##  201: Lean 4 -> ///  ##"
	@echo "##########################"
	@echo
	lean --run QR.lean > QR.slashes

QR.cjam: QR.slashes
	@echo
	@echo "########################"
	@echo "##  202: /// -> CJam  ##"
	@echo "########################"
	@echo
	ruby vendor/slashes.rb QR.slashes > QR.cjam

QR.ul: QR.cjam
	@echo
	@echo "##############################"
	@echo "##  203: CJam -> Underload  ##"
	@echo "##############################"
	@echo
	java -jar /opt/cjam/cjam-0.6.5.jar QR.cjam > QR.ul

QR.bflk: QR.ul
	@echo
	@echo "####################################"
	@echo "##  204: Underload -> Brain-Flak  ##"
	@echo "####################################"
	@echo
	ruby vendor/underload.rb QR.ul > QR.bflk

QR.sno: QR.bflk
	@echo
	@echo "##################################"
	@echo "##  205: Brain-Flak -> SNOBOL4  ##"
	@echo "##################################"
	@echo
	craneflak -A QR.bflk > QR.sno

QR.kg: QR.sno
	@echo
	@echo "#############################"
	@echo "##  206: SNOBOL4 -> Klong  ##"
	@echo "#############################"
	@echo
	snobol4 -b QR.sno > QR.kg

QR.sd7: QR.kg
	@echo
	@echo "###########################"
	@echo "##  207: Klong -> Seed7  ##"
	@echo "###########################"
	@echo
	kg QR.kg < /dev/null > QR.sd7

QR.gs: QR.sd7
	@echo
	@echo "################################"
	@echo "##  208: Seed7 -> GolfScript  ##"
	@echo "################################"
	@echo
	s7 -q QR.sd7 > QR.gs

QR.gpt: QR.gs
	@echo
	@echo "#####################################"
	@echo "##  209: GolfScript -> G-Portugol  ##"
	@echo "#####################################"
	@echo
	ruby vendor/golfscript.rb QR.gs > QR.gpt

QR.grass: QR.gpt
	@echo
	@echo "################################"
	@echo "##  210: G-Portugol -> Grass  ##"
	@echo "################################"
	@echo
	mv QR.c QR.c.bak
	gpt -t QR.c QR.gpt
	gcc -o QR QR.c
	./QR > QR.grass
	mv QR.c.bak QR.c

QR.als: QR.grass
	@echo
	@echo "###########################"
	@echo "##  211: Grass -> AFNIX  ##"
	@echo "###########################"
	@echo
	ruby vendor/grass.rb QR.grass > QR.als

QR.aheui: QR.als
	@echo
	@echo "###########################"
	@echo "##  212: AFNIX -> Aheui  ##"
	@echo "###########################"
	@echo
	LANG=C LD_LIBRARY_PATH=/usr/lib/afnix axi QR.als > QR.aheui

QR.php: QR.aheui
	@echo
	@echo "#########################"
	@echo "##  213: Aheui -> PHP  ##"
	@echo "#########################"
	@echo
	ruby vendor/aheui.rb QR.aheui > QR.php

QR.png: QR.php
	@echo
	@echo "########################"
	@echo "##  214: PHP -> Piet  ##"
	@echo "########################"
	@echo
	php QR.php > QR.png

QR.pr: QR.png
	@echo
	@echo "###################################"
	@echo "##  215: Piet -> Promela (Spin)  ##"
	@echo "###################################"
	@echo
	npiet QR.png > QR.pr

QR.rail: QR.pr
	@echo
	@echo "###################################"
	@echo "##  216: Promela (Spin) -> Rail  ##"
	@echo "###################################"
	@echo
	spin -T QR.pr > QR.rail

QR.kpl: QR.rail
	@echo
	@echo "###########################"
	@echo "##  217: Rail -> Kipple  ##"
	@echo "###########################"
	@echo
	rail QR.rail > QR.kpl

QR.beatnik: QR.kpl
	@echo
	@echo "##############################"
	@echo "##  218: Kipple -> Beatnik  ##"
	@echo "##############################"
	@echo
	cipple QR.kpl > QR.beatnik

QR.m4: QR.beatnik
	@echo
	@echo "##########################"
	@echo "##  219: Beatnik -> M4  ##"
	@echo "##########################"
	@echo
	ruby vendor/beatnik.rb QR.beatnik > QR.m4

QR.icn: QR.m4
	@echo
	@echo "#######################"
	@echo "##  220: M4 -> Icon  ##"
	@echo "#######################"
	@echo
	m4 QR.m4 > QR.icn

QR.i: QR.icn
	@echo
	@echo "#############################"
	@echo "##  221: Icon -> INTERCAL  ##"
	@echo "#############################"
	@echo
	icont -s QR.icn
	./QR > QR.i

QR.clp: QR.i
	@echo
	@echo "##############################"
	@echo "##  222: INTERCAL -> CLIPS  ##"
	@echo "##############################"
	@echo
	@mv QR.c QR.c.bak
	ick -bfOc QR.i
	gcc -std=c99 -static QR.c -I /usr/include/ick-* -o QR -lick
	./QR > QR.clp
	@mv QR.c.bak QR.c

QR.rock: QR.clp
	@echo
	@echo "##############################"
	@echo "##  223: CLIPS -> Rockstar  ##"
	@echo "##############################"
	@echo
	clips -f2 QR.clp > QR.rock

QR.p: QR.rock
	@echo
	@echo "#################################"
	@echo "##  224: Rockstar -> Parser 3  ##"
	@echo "#################################"
	@echo
	rockstar QR.rock > QR.p

QR.glass: QR.p
	@echo
	@echo "##############################"
	@echo "##  225: Parser 3 -> Glass  ##"
	@echo "##############################"
	@echo
	parser3 QR.p > QR.glass

QR.taxi: QR.glass
	@echo
	@echo "##########################"
	@echo "##  226: Glass -> Taxi  ##"
	@echo "##########################"
	@echo
	glass QR.glass > QR.taxi

QR.pas: QR.taxi
	@echo
	@echo "###########################"
	@echo "##  227: Taxi -> Pascal  ##"
	@echo "###########################"
	@echo
	taxi QR.taxi > QR.pas

QR.pl: QR.pas
	@echo
	@echo "#############################"
	@echo "##  228: Pascal -> Perl 5  ##"
	@echo "#############################"
	@echo
	fpc QR.pas
	./QR > QR.pl

QR.5c: QR.pl
	@echo
	@echo "#############################"
	@echo "##  229: Perl 5 -> Nickle  ##"
	@echo "#############################"
	@echo
	perl QR.pl > QR.5c

QR.rep: QR.5c
	@echo
	@echo "###################################"
	@echo "##  230: Nickle -> rep (librep)  ##"
	@echo "###################################"
	@echo
	nickle QR.5c > QR.rep

QR.gr: QR.rep
	@echo
	@echo "##################################"
	@echo "##  231: rep (librep) -> Grain  ##"
	@echo "##################################"
	@echo
	rep QR.rep > QR.gr

QR.hoc: QR.gr
	@echo
	@echo "#########################"
	@echo "##  232: Grain -> HOC  ##"
	@echo "#########################"
	@echo
	grain QR.gr > QR.hoc

QR.flix: QR.hoc
	@echo
	@echo "########################"
	@echo "##  233: HOC -> Flix  ##"
	@echo "########################"
	@echo
	/usr/lib/plan9/bin/hoc QR.hoc > QR.flix

QR.hop: QR.flix
	@echo
	@echo "#########################"
	@echo "##  234: Flix -> Hope  ##"
	@echo "#########################"
	@echo
	java -XX:TieredStopAtLevel=1 -jar /opt/flix/flix.jar QR.flix > QR.hop

QR.aum: QR.hop
	@echo
	@echo "############################"
	@echo "##  235: Hope -> Austral  ##"
	@echo "############################"
	@echo
	hope -f QR.hop > QR.aum

QR.s65: QR.aum
	@echo
	@echo "################################"
	@echo "##  236: Austral -> 6502 asm  ##"
	@echo "################################"
	@echo
	austral compile QR.aum --entrypoint=QR:main --output=qr_austral
	./qr_austral > QR.s65
	rm -f qr_austral

QR.tal: QR.s65
	@echo
	@echo "###############################"
	@echo "##  237: 6502 asm -> Uxntal  ##"
	@echo "###############################"
	@echo
	xa -o QR.o65 QR.s65
	sim65 QR.o65 > QR.tal
	rm -f QR.o65

QR.z80: QR.tal
	@echo
	@echo "##############################"
	@echo "##  238: Uxntal -> Z80 asm  ##"
	@echo "##############################"
	@echo
	uxnasm QR.tal QR.rom
	uxncli QR.rom > QR.z80
	rm -f QR.rom

QR.sci: QR.z80
	@echo
	@echo "##############################"
	@echo "##  239: Z80 asm -> Scilab  ##"
	@echo "##############################"
	@echo
	z80asm QR.z80 -o qr.com
	chmod a+r qr.com
	if [ $$(id -u) = 0 ]; then setpriv --reuid=nobody --regid=nogroup --clear-groups tnylpo -b qr.com; else tnylpo -b qr.com; fi < /dev/null > QR.sci
	rm -f qr.com

QR.sed: QR.sci
	@echo
	@echo "##########################"
	@echo "##  240: Scilab -> sed  ##"
	@echo "##########################"
	@echo
	scilab-cli -nb -f QR.sci > QR.sed

QR.spl: QR.sed
	@echo
	@echo "###############################"
	@echo "##  241: sed -> Shakespeare  ##"
	@echo "###############################"
	@echo
	sed -E -f QR.sed QR.sed > QR.spl

QR.sl: QR.spl
	@echo
	@echo "##################################"
	@echo "##  242: Shakespeare -> S-Lang  ##"
	@echo "##################################"
	@echo
	spl2c < QR.spl > QR.spl.c
	gcc -z muldefs -o QR -I ./vendor/local/include -L ./vendor/local/lib QR.spl.c -lspl -lm
	./QR > QR.sl

QR.ksh: QR.sl
	@echo
	@echo "##########################"
	@echo "##  243: S-Lang -> ksh  ##"
	@echo "##########################"
	@echo
	slsh QR.sl > QR.ksh

QR.lazy: QR.ksh
	@echo
	@echo "##########################"
	@echo "##  244: ksh -> Lazy K  ##"
	@echo "##########################"
	@echo
	ksh QR.ksh > QR.lazy

QR.ls: QR.lazy
	@echo
	@echo "#################################"
	@echo "##  245: Lazy K -> LiveScript  ##"
	@echo "#################################"
	@echo
	ulimit -s unlimited && lazyk QR.lazy > QR.ls

QR.bsh: QR.ls
	@echo
	@echo "####################################"
	@echo "##  246: LiveScript -> BeanShell  ##"
	@echo "####################################"
	@echo
	@mv QR.c QR.c.bak
	lsc QR.ls > QR.bsh
	@mv QR.c.bak QR.c

QR.bef: QR.bsh
	@echo
	@echo "#################################"
	@echo "##  247: BeanShell -> Befunge  ##"
	@echo "#################################"
	@echo
	bsh QR.bsh > QR.bef
	-@stty echo

QR.Blc: QR.bef
	@echo
	@echo "############################"
	@echo "##  248: Befunge -> BLC8  ##"
	@echo "############################"
	@echo
	cfunge QR.bef > QR.Blc

QR.bf: QR.Blc
	@echo
	@echo "##############################"
	@echo "##  249: BLC8 -> Brainfuck  ##"
	@echo "##############################"
	@echo
	ruby vendor/blc.rb < QR.Blc > QR.bf

QR.py: QR.bf
	@echo
	@echo "################################"
	@echo "##  250: Brainfuck -> Python  ##"
	@echo "################################"
	@echo
	ruby vendor/bf.rb QR.bf > QR.py

QR.mb: QR.py
	@echo
	@echo "##########################################"
	@echo "##  251: Python -> Malbolge Unshackled  ##"
	@echo "##########################################"
	@echo
	python3 QR.py > QR.mb

QR.R: QR.mb
	@echo
	@echo "#####################################"
	@echo "##  252: Malbolge Unshackled -> R  ##"
	@echo "#####################################"
	@echo
	unshackled QR.mb < /dev/null > QR.R

QR.ratfor: QR.R
	@echo
	@echo "########################"
	@echo "##  253: R -> Ratfor  ##"
	@echo "########################"
	@echo
	R --slave -f QR.R > QR.ratfor

QR.rc: QR.ratfor
	@echo
	@echo "#########################"
	@echo "##  254: Ratfor -> rc  ##"
	@echo "#########################"
	@echo
	ratfor -o QR.ratfor.f QR.ratfor
	gfortran -o QR QR.ratfor.f
	./QR > QR.rc

QR.rexx: QR.rc
	@echo
	@echo "#######################"
	@echo "##  255: rc -> REXX  ##"
	@echo "#######################"
	@echo
	rc QR.rc > QR.rexx

QR2.rb: QR.rexx
	@echo
	@echo "#########################"
	@echo "##  256: REXX -> Ruby  ##"
	@echo "#########################"
	@echo
	rexx ./QR.rexx > QR2.rb

clean:
	@mv QR.rb quine-relay.rb
	rm -f qr QR qr.* QR.* QR2.rb *.class gst.im QR_ec* qr_mercury* qrkoka qrchpl qrroc tmp.*proj work-obj93.cf QRMUMPS.* .apl.history QR.qbe.s QR.mth.c QR.gro QR.wasm qr_austral QR.amx qr.com
	rm -rf Mercury qrpony* qrgleam .koka .obnc dafny-out frege-out purs_out bin obj 'Clean System Files' target qr_effekt_out qr_vale_out
	@mv quine-relay.rb QR.rb
