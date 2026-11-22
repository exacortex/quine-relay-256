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

all: QR2.aj
	@echo
	@echo "#############"
	@echo "##  CHECK  ##"
	@echo "#############"
	@echo
	diff -s QR.aj QR2.aj

check: all
	@sha256sum --quiet -c SHA256SUMS

QR.asy: QR.aj
	@echo
	@echo "###############################"
	@echo "##  1: AspectJ -> Asymptote  ##"
	@echo "###############################"
	@echo
	ajc -source 1.8 -target 1.8 -nowarn QR.aj
	java -Xmx2g -cp .:/usr/share/java/aspectjrt.jar QR > QR.asy

QR.dats: QR.asy
	@echo
	@echo "###########################"
	@echo "##  2: Asymptote -> ATS  ##"
	@echo "###########################"
	@echo
	asy QR.asy > QR.dats

QR.aum: QR.dats
	@echo
	@echo "#########################"
	@echo "##  3: ATS -> Austral  ##"
	@echo "#########################"
	@echo
	patscc -o QR QR.dats
	./QR > QR.aum

QR.awk: QR.aum
	@echo
	@echo "#########################"
	@echo "##  4: Austral -> Awk  ##"
	@echo "#########################"
	@echo
	austral compile QR.aum --entrypoint=QR:main --output=qr_austral
	./qr_austral > QR.awk
	rm -f qr_austral

QR.bal: QR.awk
	@echo
	@echo "###########################"
	@echo "##  5: Awk -> Ballerina  ##"
	@echo "###########################"
	@echo
	awk -f QR.awk > QR.bal

QR.bash: QR.bal
	@echo
	@echo "############################"
	@echo "##  6: Ballerina -> bash  ##"
	@echo "############################"
	@echo
	bal run --offline QR.bal > QR.bash

QR.bc: QR.bash
	@echo
	@echo "#####################"
	@echo "##  7: bash -> bc  ##"
	@echo "#####################"
	@echo
	bash QR.bash > QR.bc

QR.bsh: QR.bc
	@echo
	@echo "##########################"
	@echo "##  8: bc -> BeanShell  ##"
	@echo "##########################"
	@echo
	BC_LINE_LENGTH=4000000 bc -q QR.bc > QR.bsh

QR.beatnik: QR.bsh
	@echo
	@echo "###############################"
	@echo "##  9: BeanShell -> Beatnik  ##"
	@echo "###############################"
	@echo
	bsh QR.bsh > QR.beatnik

QR.bef: QR.beatnik
	@echo
	@echo "##############################"
	@echo "##  10: Beatnik -> Befunge  ##"
	@echo "##############################"
	@echo
	ruby vendor/beatnik.rb QR.beatnik > QR.bef

QR.be: QR.bef
	@echo
	@echo "############################"
	@echo "##  11: Befunge -> Berry  ##"
	@echo "############################"
	@echo
	cfunge QR.bef > QR.be

QR.Blc: QR.be
	@echo
	@echo "#########################"
	@echo "##  12: Berry -> BLC8  ##"
	@echo "#########################"
	@echo
	berry QR.be > QR.Blc

QR.boo: QR.Blc
	@echo
	@echo "#######################"
	@echo "##  13: BLC8 -> Boo  ##"
	@echo "#######################"
	@echo
	ruby vendor/blc.rb < QR.Blc > QR.boo

QR.boron: QR.boo
	@echo
	@echo "########################"
	@echo "##  14: Boo -> Boron  ##"
	@echo "########################"
	@echo
	booi QR.boo > QR.boron

QR.bqn: QR.boron
	@echo
	@echo "########################"
	@echo "##  15: Boron -> BQN  ##"
	@echo "########################"
	@echo
	boron QR.boron > QR.bqn

QR.bflk: QR.bqn
	@echo
	@echo "#############################"
	@echo "##  16: BQN -> Brain-Flak  ##"
	@echo "#############################"
	@echo
	bqn QR.bqn > QR.bflk

QR.bf: QR.bflk
	@echo
	@echo "###################################"
	@echo "##  17: Brain-Flak -> Brainfuck  ##"
	@echo "###################################"
	@echo
	craneflak -A QR.bflk > QR.bf

QR.c: QR.bf
	@echo
	@echo "##########################"
	@echo "##  18: Brainfuck -> C  ##"
	@echo "##########################"
	@echo
	ruby vendor/bf.rb QR.bf > QR.c

QR.cpp: QR.c
	@echo
	@echo "####################"
	@echo "##  19: C -> C++  ##"
	@echo "####################"
	@echo
	$(CC) -o QR QR.c
	./QR > QR.cpp

qr_cs/QR.cs: QR.cpp
	@echo
	@echo "#####################"
	@echo "##  20: C++ -> C#  ##"
	@echo "#####################"
	@echo
	$(CXX) -o QR QR.cpp
	./QR > qr_cs/QR.cs

QR.c3: qr_cs/QR.cs
	@echo
	@echo "####################"
	@echo "##  21: C# -> C3  ##"
	@echo "####################"
	@echo
	DOTNET_NOLOGO=1 dotnet run --project qr_cs > QR.c3

QR.cd: QR.c3
	@echo
	@echo "#######################"
	@echo "##  22: C3 -> CDuce  ##"
	@echo "#######################"
	@echo
	c3c compile QR.c3 -o QR
	./QR > QR.cd

QR.chai: QR.cd
	@echo
	@echo "###############################"
	@echo "##  23: CDuce -> ChaiScript  ##"
	@echo "###############################"
	@echo
	cduce QR.cd > QR.chai

QR.chpl: QR.chai
	@echo
	@echo "################################"
	@echo "##  24: ChaiScript -> Chapel  ##"
	@echo "################################"
	@echo
	chai QR.chai > QR.chpl

QR.chef: QR.chpl
	@echo
	@echo "##########################"
	@echo "##  25: Chapel -> Chef  ##"
	@echo "##########################"
	@echo
	chpl -o qrchpl QR.chpl
	./qrchpl > QR.chef

QR.cjam: QR.chef
	@echo
	@echo "########################"
	@echo "##  26: Chef -> CJam  ##"
	@echo "########################"
	@echo
	PERL5LIB=vendor/local/lib/perl5 compilechef QR.chef QR.chef.pl
	perl QR.chef.pl > QR.cjam

QR.icl: QR.cjam
	@echo
	@echo "#########################"
	@echo "##  27: CJam -> Clean  ##"
	@echo "#########################"
	@echo
	java -jar /opt/cjam/cjam-0.6.5.jar QR.cjam > QR.icl

QR.clp: QR.icl
	@echo
	@echo "##########################"
	@echo "##  28: Clean -> CLIPS  ##"
	@echo "##########################"
	@echo
	clm -nt -nr QR -o QR > /dev/null
	./QR > QR.clp

QR.clj: QR.clp
	@echo
	@echo "############################"
	@echo "##  29: CLIPS -> Clojure  ##"
	@echo "############################"
	@echo
	clips -f2 QR.clp > QR.clj

QR.cmake: QR.clj
	@echo
	@echo "############################"
	@echo "##  30: Clojure -> CMake  ##"
	@echo "############################"
	@echo
	clojure QR.clj > QR.cmake

QR.cob: QR.cmake
	@echo
	@echo "##########################"
	@echo "##  31: CMake -> Cobol  ##"
	@echo "##########################"
	@echo
	cmake -P QR.cmake > QR.cob

QR.coffee: QR.cob
	@echo
	@echo "#################################"
	@echo "##  32: Cobol -> CoffeeScript  ##"
	@echo "#################################"
	@echo
	cobc -O2 -x QR.cob
	./QR > QR.coffee

QR.lisp: QR.coffee
	@echo
	@echo "#######################################"
	@echo "##  33: CoffeeScript -> Common Lisp  ##"
	@echo "#######################################"
	@echo
	coffee --nodejs --stack_size=100000 QR.coffee > QR.lisp

QR.cr: QR.lisp
	@echo
	@echo "##################################"
	@echo "##  34: Common Lisp -> Crystal  ##"
	@echo "##################################"
	@echo
	clisp QR.lisp > QR.cr

QR.cy: QR.cr
	@echo
	@echo "############################"
	@echo "##  35: Crystal -> Cyber  ##"
	@echo "############################"
	@echo
	crystal QR.cr > QR.cy

QR.d: QR.cy
	@echo
	@echo "######################"
	@echo "##  36: Cyber -> D  ##"
	@echo "######################"
	@echo
	cyber QR.cy > QR.d

QR.dfy: QR.d
	@echo
	@echo "######################"
	@echo "##  37: D -> Dafny  ##"
	@echo "######################"
	@echo
	gdc -o QR QR.d
	./QR > QR.dfy

QR.dart: QR.dfy
	@echo
	@echo "#########################"
	@echo "##  38: Dafny -> Dart  ##"
	@echo "#########################"
	@echo
	dafny build -o dafny-out/QR QR.dfy
	DOTNET_ROLL_FORWARD=Major dotnet dafny-out/QR.dll > QR.dart

QR.dc: QR.dart
	@echo
	@echo "######################"
	@echo "##  39: Dart -> dc  ##"
	@echo "######################"
	@echo
	dart run QR.dart > QR.dc

QR.dhall: QR.dc
	@echo
	@echo "#######################"
	@echo "##  40: dc -> Dhall  ##"
	@echo "#######################"
	@echo
	dc QR.dc > QR.dhall || true

QR.dyon: QR.dhall
	@echo
	@echo "#########################"
	@echo "##  41: Dhall -> Dyon  ##"
	@echo "#########################"
	@echo
	dhall text --file QR.dhall > QR.dyon

QR_ec.ec: QR.dyon
	@echo
	@echo "######################"
	@echo "##  42: Dyon -> eC  ##"
	@echo "######################"
	@echo
	dyonrun QR.dyon > QR_ec.ec

QR.effekt: QR_ec.ec
	@echo
	@echo "########################"
	@echo "##  43: eC -> Effekt  ##"
	@echo "########################"
	@echo
	ecp -c QR_ec.ec -o QR_ec.sym
	ecc -c QR_ec.ec -o QR_ec.c
	ecs -console QR_ec.sym QR_ec.imp -o QR_ec.main.ec
	ecp -c QR_ec.main.ec -o QR_ec.main.sym
	ecc -c QR_ec.main.ec -o QR_ec.main.c
	gcc -std=gnu17 -w -o QR_ec QR_ec.c QR_ec.main.c -lecereCOM
	./QR_ec > QR.effekt

QR.exs: QR.effekt
	@echo
	@echo "############################"
	@echo "##  44: Effekt -> Elixir  ##"
	@echo "############################"
	@echo
	rm -rf qr_effekt_out
	effekt --backend js --out qr_effekt_out QR.effekt > QR.exs
	rm -rf qr_effekt_out

QR.elv: QR.exs
	@echo
	@echo "############################"
	@echo "##  45: Elixir -> Elvish  ##"
	@echo "############################"
	@echo
	elixir QR.exs > QR.elv

QR.el: QR.elv
	@echo
	@echo "################################"
	@echo "##  46: Elvish -> Emacs Lisp  ##"
	@echo "################################"
	@echo
	elvish QR.elv > QR.el

QR.emmental: QR.el
	@echo
	@echo "##################################"
	@echo "##  47: Emacs Lisp -> Emmental  ##"
	@echo "##################################"
	@echo
	emacs -Q --script QR.el > QR.emmental

QR.erl: QR.emmental
	@echo
	@echo "##############################"
	@echo "##  48: Emmental -> Erlang  ##"
	@echo "##############################"
	@echo
	ruby vendor/emmental.rb QR.emmental > QR.erl

QR.ex: QR.erl
	@echo
	@echo "##############################"
	@echo "##  49: Erlang -> Euphoria  ##"
	@echo "##############################"
	@echo
	escript QR.erl > QR.ex

QR.e: QR.ex
	@echo
	@echo "################################"
	@echo "##  50: Euphoria -> Execline  ##"
	@echo "################################"
	@echo
	eui QR.ex > QR.e

QR.fsx: QR.e
	@echo
	@echo "##########################"
	@echo "##  51: Execline -> F#  ##"
	@echo "##########################"
	@echo
	execlineb QR.e > QR.fsx

QR.factor: QR.fsx
	@echo
	@echo "########################"
	@echo "##  52: F# -> Factor  ##"
	@echo "########################"
	@echo
	DOTNET_NOLOGO=1 dotnet fsi --quiet --exec QR.fsx > QR.factor

QR.fal: QR.factor
	@echo
	@echo "############################"
	@echo "##  53: Factor -> Falcon  ##"
	@echo "############################"
	@echo
	/opt/factor/factor QR.factor > QR.fal

QR.false: QR.fal
	@echo
	@echo "###########################"
	@echo "##  54: Falcon -> FALSE  ##"
	@echo "###########################"
	@echo
	falcon QR.fal > QR.false

QR.fan: QR.false
	@echo
	@echo "###########################"
	@echo "##  55: FALSE -> Fantom  ##"
	@echo "###########################"
	@echo
	ruby vendor/false.rb QR.false > QR.fan

QR.fnl: QR.fan
	@echo
	@echo "############################"
	@echo "##  56: Fantom -> Fennel  ##"
	@echo "############################"
	@echo
	fan QR.fan > QR.fnl

QR.fish.fish: QR.fnl
	@echo
	@echo "################################"
	@echo "##  57: Fennel -> ><> (Fish)  ##"
	@echo "################################"
	@echo
	fennel QR.fnl > QR.fish.fish

QR.fish: QR.fish.fish
	@echo
	@echo "##############################"
	@echo "##  58: ><> (Fish) -> Fish  ##"
	@echo "##############################"
	@echo
	python3 /opt/fish/fish.py QR.fish.fish > QR.fish

QR.fl: QR.fish
	@echo
	@echo "########################"
	@echo "##  59: Fish -> Flex  ##"
	@echo "########################"
	@echo
	fish QR.fish > QR.fl

QR.flix: QR.fl
	@echo
	@echo "########################"
	@echo "##  60: Flex -> Flix  ##"
	@echo "########################"
	@echo
	flex -o QR.fl.c QR.fl
	gcc -o QR QR.fl.c
	./QR > QR.flix

QR.fs: QR.flix
	@echo
	@echo "#########################"
	@echo "##  61: Flix -> Forth  ##"
	@echo "#########################"
	@echo
	java -XX:TieredStopAtLevel=1 -jar /opt/flix/flix.jar QR.flix > QR.fs

QR.f90: QR.fs
	@echo
	@echo "##############################"
	@echo "##  62: Forth -> Fortran90  ##"
	@echo "##############################"
	@echo
	gforth QR.fs > QR.f90

QR.fr: QR.f90
	@echo
	@echo "##############################"
	@echo "##  63: Fortran90 -> Frege  ##"
	@echo "##############################"
	@echo
	gfortran -o QR QR.f90
	./QR > QR.fr

QR.gbs: QR.fr
	@echo
	@echo "##################################"
	@echo "##  64: Frege -> Gambas script  ##"
	@echo "##################################"
	@echo
	mkdir -p frege-out
	frege -d frege-out QR.fr
	java -cp frege-out:/usr/local/lib/frege.jar QR > QR.gbs

QR.g: QR.gbs
	@echo
	@echo "################################"
	@echo "##  65: Gambas script -> GAP  ##"
	@echo "################################"
	@echo
	$(GBS) QR.gbs > QR.g

QR.gdb: QR.g
	@echo
	@echo "######################"
	@echo "##  66: GAP -> GDB  ##"
	@echo "######################"
	@echo
	gap -q QR.g > QR.gdb

QR.gel: QR.gdb
	@echo
	@echo "###############################"
	@echo "##  67: GDB -> GEL (Genius)  ##"
	@echo "###############################"
	@echo
	gdb -q -x QR.gdb > QR.gel

QR.glass: QR.gel
	@echo
	@echo "#################################"
	@echo "##  68: GEL (Genius) -> Glass  ##"
	@echo "#################################"
	@echo
	genius QR.gel > QR.glass

qrgleam/src/qr.gleam: QR.glass
	@echo
	@echo "##########################"
	@echo "##  69: Glass -> Gleam  ##"
	@echo "##########################"
	@echo
	glass QR.glass > qrgleam/src/qr.gleam

QR.glu: qrgleam/src/qr.gleam
	@echo
	@echo "##########################"
	@echo "##  70: Gleam -> Gluon  ##"
	@echo "##########################"
	@echo
	(cd qrgleam; gleam run --no-print-progress) > QR.glu

QR.apl: QR.glu
	@echo
	@echo "############################"
	@echo "##  71: Gluon -> GNU APL  ##"
	@echo "############################"
	@echo
	gluon QR.glu > QR.apl

QR.plt: QR.apl
	@echo
	@echo "##############################"
	@echo "##  72: GNU APL -> Gnuplot  ##"
	@echo "##############################"
	@echo
	apl --script --OFF -s -f QR.apl > QR.plt

QR.st: QR.plt
	@echo
	@echo "####################################"
	@echo "##  73: Gnuplot -> GNU Smalltalk  ##"
	@echo "####################################"
	@echo
	gnuplot QR.plt > QR.st

QR.go: QR.st
	@echo
	@echo "###############################"
	@echo "##  74: GNU Smalltalk -> Go  ##"
	@echo "###############################"
	@echo
	gst QR.st > QR.go

QR.gs: QR.go
	@echo
	@echo "############################"
	@echo "##  75: Go -> GolfScript  ##"
	@echo "############################"
	@echo
	go run QR.go > QR.gs

QR.golo: QR.gs
	@echo
	@echo "##############################"
	@echo "##  76: GolfScript -> Golo  ##"
	@echo "##############################"
	@echo
	ruby vendor/golfscript.rb QR.gs > QR.golo

QR.gsp: QR.golo
	@echo
	@echo "########################"
	@echo "##  77: Golo -> Gosu  ##"
	@echo "########################"
	@echo
	golo golo --files QR.golo > QR.gsp

QR.gpt: QR.gsp
	@echo
	@echo "##############################"
	@echo "##  78: Gosu -> G-Portugol  ##"
	@echo "##############################"
	@echo
	gosu QR.gsp > QR.gpt

QR.gr: QR.gpt
	@echo
	@echo "###############################"
	@echo "##  79: G-Portugol -> Grain  ##"
	@echo "###############################"
	@echo
	mv QR.c QR.c.bak
	gpt -t QR.c QR.gpt
	gcc -o QR QR.c
	./QR > QR.gr
	mv QR.c.bak QR.c

QR.grass: QR.gr
	@echo
	@echo "##########################"
	@echo "##  80: Grain -> Grass  ##"
	@echo "##########################"
	@echo
	grain QR.gr > QR.grass

QR.gravity: QR.grass
	@echo
	@echo "############################"
	@echo "##  81: Grass -> Gravity  ##"
	@echo "############################"
	@echo
	ruby vendor/grass.rb QR.grass > QR.gravity

QR.gri: QR.gravity
	@echo
	@echo "##########################"
	@echo "##  82: Gravity -> Gri  ##"
	@echo "##########################"
	@echo
	gravity -q QR.gravity > QR.gri

QR.groovy: QR.gri
	@echo
	@echo "#########################"
	@echo "##  83: Gri -> Groovy  ##"
	@echo "#########################"
	@echo
	gri -output QR.gri.ps QR.gri > QR.groovy

QR.gsl: QR.groovy
	@echo
	@echo "########################################################"
	@echo "##  84: Groovy -> GSL (Generator Scripting Language)  ##"
	@echo "########################################################"
	@echo
	groovy QR.groovy > QR.gsl

QR.ha: QR.gsl
	@echo
	@echo "######################################################"
	@echo "##  85: GSL (Generator Scripting Language) -> Hare  ##"
	@echo "######################################################"
	@echo
	gsl -q QR.gsl > QR.ha

QR.hs: QR.ha
	@echo
	@echo "###########################"
	@echo "##  86: Hare -> Haskell  ##"
	@echo "###########################"
	@echo
	hare build -q -o QR QR.ha
	./QR > QR.hs

QR.hx: QR.hs
	@echo
	@echo "###########################"
	@echo "##  87: Haskell -> Haxe  ##"
	@echo "###########################"
	@echo
	rm -f QR.o
	ghc QR.hs
	./QR > QR.hx

QR.hxg: QR.hx
	@echo
	@echo "############################"
	@echo "##  88: Haxe -> Hexagony  ##"
	@echo "############################"
	@echo
	haxe -main QR -neko QR.n
	neko QR.n > QR.hxg

QR.hoc: QR.hxg
	@echo
	@echo "###########################"
	@echo "##  89: Hexagony -> HOC  ##"
	@echo "###########################"
	@echo
	ruby /opt/hexagony/interpreter.rb QR.hxg > QR.hoc

QR.hop: QR.hoc
	@echo
	@echo "#######################"
	@echo "##  90: HOC -> Hope  ##"
	@echo "#######################"
	@echo
	/usr/lib/plan9/bin/hoc QR.hoc > QR.hop

QR.hy: QR.hop
	@echo
	@echo "######################"
	@echo "##  91: Hope -> Hy  ##"
	@echo "######################"
	@echo
	hope -f QR.hop > QR.hy

QR.icn: QR.hy
	@echo
	@echo "######################"
	@echo "##  92: Hy -> Icon  ##"
	@echo "######################"
	@echo
	hy QR.hy > QR.icn

QR.idr: QR.icn
	@echo
	@echo "###########################"
	@echo "##  93: Icon -> Idris 2  ##"
	@echo "###########################"
	@echo
	icont -s QR.icn
	./QR > QR.idr

QR.inko: QR.idr
	@echo
	@echo "###########################"
	@echo "##  94: Idris 2 -> Inko  ##"
	@echo "###########################"
	@echo
	idris2 --exec main QR.idr > QR.inko

QR.i: QR.inko
	@echo
	@echo "############################"
	@echo "##  95: Inko -> INTERCAL  ##"
	@echo "############################"
	@echo
	inko run QR.inko > QR.i

QR.io: QR.i
	@echo
	@echo "##########################"
	@echo "##  96: INTERCAL -> Io  ##"
	@echo "##########################"
	@echo
	@mv QR.c QR.c.bak
	ick -bfOc QR.i
	gcc -std=c99 -static QR.c -I /usr/include/ick-* -o QR -lick
	./QR > QR.io
	@mv QR.c.bak QR.c

QR.ion: QR.io
	@echo
	@echo "#####################"
	@echo "##  97: Io -> Ion  ##"
	@echo "#####################"
	@echo
	io QR.io > QR.ion

QR.ijs: QR.ion
	@echo
	@echo "####################"
	@echo "##  98: Ion -> J  ##"
	@echo "####################"
	@echo
	ion QR.ion > QR.ijs

QR.janet: QR.ijs
	@echo
	@echo "######################"
	@echo "##  99: J -> Janet  ##"
	@echo "######################"
	@echo
	ijconsole QR.ijs < /dev/null > QR.janet

QR.j: QR.janet
	@echo
	@echo "############################"
	@echo "##  100: Janet -> Jasmin  ##"
	@echo "############################"
	@echo
	janet QR.janet > QR.j

QR.java: QR.j
	@echo
	@echo "###########################"
	@echo "##  101: Jasmin -> Java  ##"
	@echo "###########################"
	@echo
	jasmin QR.j
	java QR > QR.java

QR.js: QR.java
	@echo
	@echo "###############################"
	@echo "##  102: Java -> JavaScript  ##"
	@echo "###############################"
	@echo
	javac QR.java
	java QR > QR.js

QR.jq: QR.js
	@echo
	@echo "#############################"
	@echo "##  103: JavaScript -> Jq  ##"
	@echo "#############################"
	@echo
	$(JAVASCRIPT) QR.js > QR.jq

QR.jl: QR.jq
	@echo
	@echo "########################"
	@echo "##  104: Jq -> Julia  ##"
	@echo "########################"
	@echo
	jq -j -n -f QR.jq > QR.jl

QR.k.k: QR.jl
	@echo
	@echo "###############################"
	@echo "##  105: Julia -> K (ngn/k)  ##"
	@echo "###############################"
	@echo
	julia QR.jl > QR.k.k

QR.kpl: QR.k.k
	@echo
	@echo "################################"
	@echo "##  106: K (ngn/k) -> Kipple  ##"
	@echo "################################"
	@echo
	ngnk QR.k.k < /dev/null > QR.kpl

QR.kg: QR.kpl
	@echo
	@echo "############################"
	@echo "##  107: Kipple -> Klong  ##"
	@echo "############################"
	@echo
	cipple QR.kpl > QR.kg

qr.kk: QR.kg
	@echo
	@echo "##########################"
	@echo "##  108: Klong -> Koka  ##"
	@echo "##########################"
	@echo
	kg QR.kg < /dev/null > qr.kk

QR.kt: qr.kk
	@echo
	@echo "###########################"
	@echo "##  109: Koka -> Kotlin  ##"
	@echo "###########################"
	@echo
	koka -v0 -o qrkoka qr.kk
	chmod +x qrkoka
	./qrkoka > QR.kt

QR.koto: QR.kt
	@echo
	@echo "###########################"
	@echo "##  110: Kotlin -> Koto  ##"
	@echo "###########################"
	@echo
	kotlinc QR.kt -include-runtime -d QR.jar
	kotlin QR.jar > QR.koto

QR.ksh: QR.koto
	@echo
	@echo "########################"
	@echo "##  111: Koto -> ksh  ##"
	@echo "########################"
	@echo
	koto QR.koto > QR.ksh

QR.lazy: QR.ksh
	@echo
	@echo "##########################"
	@echo "##  112: ksh -> Lazy K  ##"
	@echo "##########################"
	@echo
	ksh QR.ksh > QR.lazy

QR.lean: QR.lazy
	@echo
	@echo "#############################"
	@echo "##  113: Lazy K -> Lean 4  ##"
	@echo "#############################"
	@echo
	ulimit -s unlimited && lazyk QR.lazy > QR.lean

QR.lfe: QR.lean
	@echo
	@echo "##########################"
	@echo "##  114: Lean 4 -> LFE  ##"
	@echo "##########################"
	@echo
	lean --run QR.lean > QR.lfe

QR.lily: QR.lfe
	@echo
	@echo "########################"
	@echo "##  115: LFE -> Lily  ##"
	@echo "########################"
	@echo
	lfe QR.lfe > QR.lily

qr.li: QR.lily
	@echo
	@echo "###########################"
	@echo "##  116: Lily -> Lisaac  ##"
	@echo "###########################"
	@echo
	lily QR.lily > qr.li

QR.ls: qr.li
	@echo
	@echo "#################################"
	@echo "##  117: Lisaac -> LiveScript  ##"
	@echo "#################################"
	@echo
	lisaac -gcc -Wno-implicit-function-declaration qr.li > /dev/null
	./qr > QR.ls

QR.ll: QR.ls
	@echo
	@echo "###################################"
	@echo "##  118: LiveScript -> LLVM asm  ##"
	@echo "###################################"
	@echo
	@mv QR.c QR.c.bak
	lsc QR.ls > QR.ll
	@mv QR.c.bak QR.c

QR.lobster: QR.ll
	@echo
	@echo "################################"
	@echo "##  119: LLVM asm -> Lobster  ##"
	@echo "################################"
	@echo
	@mv QR.bc QR.bc.bak
	llvm-as QR.ll
	lli QR.bc > QR.lobster
	@mv QR.bc.bak QR.bc

QR.lol: QR.lobster
	@echo
	@echo "###############################"
	@echo "##  120: Lobster -> LOLCODE  ##"
	@echo "###############################"
	@echo
	lobster QR.lobster > QR.lol

QR.lua: QR.lol
	@echo
	@echo "###########################"
	@echo "##  121: LOLCODE -> Lua  ##"
	@echo "###########################"
	@echo
	lci QR.lol > QR.lua

QR.m4: QR.lua
	@echo
	@echo "######################"
	@echo "##  122: Lua -> M4  ##"
	@echo "######################"
	@echo
	lua5.3 QR.lua > QR.m4

QR.m2: QR.m4
	@echo
	@echo "############################"
	@echo "##  123: M4 -> Macaulay2  ##"
	@echo "############################"
	@echo
	m4 QR.m4 > QR.m2

QR.mk: QR.m2
	@echo
	@echo "##################################"
	@echo "##  124: Macaulay2 -> Makefile  ##"
	@echo "##################################"
	@echo
	M2 --script QR.m2 > QR.mk

QR.mb: QR.mk
	@echo
	@echo "############################################"
	@echo "##  125: Makefile -> Malbolge Unshackled  ##"
	@echo "############################################"
	@echo
	make -f QR.mk > QR.mb

QR.wl: QR.mb
	@echo
	@echo "###########################################"
	@echo "##  126: Malbolge Unshackled -> Mathics  ##"
	@echo "###########################################"
	@echo
	unshackled QR.mb < /dev/null > QR.wl

QR.mac: QR.wl
	@echo
	@echo "##############################"
	@echo "##  127: Mathics -> Maxima  ##"
	@echo "##############################"
	@echo
	mathics -q --no-completion -f QR.wl < /dev/null > QR.mac

qr_mercury.m: QR.mac
	@echo
	@echo "##############################"
	@echo "##  128: Maxima -> Mercury  ##"
	@echo "##############################"
	@echo
	maxima -q --init-mac=QR.mac > qr_mercury.m

QR.ms: qr_mercury.m
	@echo
	@echo "##################################"
	@echo "##  129: Mercury -> MiniScript  ##"
	@echo "##################################"
	@echo
	mmc --make qr_mercury > /dev/null
	./qr_mercury > QR.ms

QR.mzn: QR.ms
	@echo
	@echo "###################################"
	@echo "##  130: MiniScript -> MiniZinc  ##"
	@echo "###################################"
	@echo
	miniscript QR.ms > QR.mzn

QR.mira: QR.mzn
	@echo
	@echo "################################"
	@echo "##  131: MiniZinc -> Miranda  ##"
	@echo "################################"
	@echo
	minizinc --solver COIN-BC --soln-sep '' QR.mzn > QR.mira

QR.mth: QR.mira
	@echo
	@echo "#############################"
	@echo "##  132: Miranda -> Mirth  ##"
	@echo "#############################"
	@echo
	mira -exec QR.mira > QR.mth

QR.mms: QR.mth
	@echo
	@echo "##########################"
	@echo "##  133: Mirth -> MMIX  ##"
	@echo "##########################"
	@echo
	mirth -p std:/opt/mirth/lib/std -p qr:. ./QR.mth -o QR.mth.c > /dev/null
	$(CC) -O2 -Wno-trigraphs -o QR QR.mth.c
	./QR > QR.mms

QR.mod: QR.mms
	@echo
	@echo "#############################"
	@echo "##  134: MMIX -> Modula-2  ##"
	@echo "#############################"
	@echo
	mmixal -b 2000000 -o QR.mmo QR.mms
	mmix QR.mmo > QR.mod
	rm -f QR.mmo

QR.il: QR.mod
	@echo
	@echo "#############################"
	@echo "##  135: Modula-2 -> MSIL  ##"
	@echo "#############################"
	@echo
	gm2 -fiso QR.mod -o QR
	./QR > QR.il

QRMUMPS.m: QR.il
	@echo
	@echo "##########################"
	@echo "##  136: MSIL -> MUMPS  ##"
	@echo "##########################"
	@echo
	ilasm QR.il
	mono QR.exe > QRMUMPS.m

QR.mx: QRMUMPS.m
	@echo
	@echo "###########################"
	@echo "##  137: MUMPS -> Murex  ##"
	@echo "###########################"
	@echo
	ydb_dist=/opt/yottadb ydb_routines=. /opt/yottadb/yottadb -run QRMUMPS > QR.mx

QR.mustache: QR.mx
	@echo
	@echo "##############################"
	@echo "##  138: Murex -> Mustache  ##"
	@echo "##############################"
	@echo
	murex QR.mx > QR.mustache

QR.asm: QR.mustache
	@echo
	@echo "#############################"
	@echo "##  139: Mustache -> NASM  ##"
	@echo "#############################"
	@echo
	mustache QR.mustache QR.mustache > QR.asm

QR.neko: QR.asm
	@echo
	@echo "#########################"
	@echo "##  140: NASM -> Neko  ##"
	@echo "#########################"
	@echo
	nasm -felf QR.asm
	ld -m elf_i386 -o QR QR.o
	./QR > QR.neko

QR.nelua: QR.neko
	@echo
	@echo "##########################"
	@echo "##  141: Neko -> Nelua  ##"
	@echo "##########################"
	@echo
	nekoc QR.neko
	neko QR.n > QR.nelua

QR.nc: QR.nelua
	@echo
	@echo "##########################"
	@echo "##  142: Nelua -> nesC  ##"
	@echo "##########################"
	@echo
	nelua --no-cache QR.nelua > QR.nc

QR.nl: QR.nc
	@echo
	@echo "############################"
	@echo "##  143: nesC -> newLISP  ##"
	@echo "############################"
	@echo
	nescc -gcc=gcc-14 -o QR QR.nc
	./QR > QR.nl

QR.ndf: QR.nl
	@echo
	@echo "############################"
	@echo "##  144: newLISP -> Nial  ##"
	@echo "############################"
	@echo
	newlisp -n QR.nl > QR.ndf

QR.5c: QR.ndf
	@echo
	@echo "###########################"
	@echo "##  145: Nial -> Nickle  ##"
	@echo "###########################"
	@echo
	nial -defs QR.ndf < /dev/null > QR.5c

QR.nim: QR.5c
	@echo
	@echo "##########################"
	@echo "##  146: Nickle -> Nim  ##"
	@echo "##########################"
	@echo
	nickle QR.5c > QR.nim

QR.nbt: QR.nim
	@echo
	@echo "##########################"
	@echo "##  147: Nim -> Numbat  ##"
	@echo "##########################"
	@echo
	nim compile --hints:off --warnings:off QR.nim
	./QR > QR.nbt

QR.nu: QR.nbt
	@echo
	@echo "##############################"
	@echo "##  148: Numbat -> Nushell  ##"
	@echo "##############################"
	@echo
	numbat QR.nbt > QR.nu

QR.obn: QR.nu
	@echo
	@echo "##############################"
	@echo "##  149: Nushell -> Oberon  ##"
	@echo "##############################"
	@echo
	nu --no-config-file QR.nu > QR.obn

QR.m: QR.obn
	@echo
	@echo "##################################"
	@echo "##  150: Oberon -> Objective-C  ##"
	@echo "##################################"
	@echo
	@[ ! -f QR.c ] || mv QR.c QR.c.bak
	rm -rf QR .obnc
	obnc QR.obn >/dev/null
	./QR > QR.m
	rm -rf QR .obnc
	@[ ! -f QR.c.bak ] || mv QR.c.bak QR.c

QR.ml: QR.m
	@echo
	@echo "#################################"
	@echo "##  151: Objective-C -> OCaml  ##"
	@echo "#################################"
	@echo
	gcc -o QR QR.m -lobjc
	./QR > QR.ml

QR.octave: QR.ml
	@echo
	@echo "############################"
	@echo "##  152: OCaml -> Octave  ##"
	@echo "############################"
	@echo
	ocaml QR.ml > QR.octave

QR.odin: QR.octave
	@echo
	@echo "###########################"
	@echo "##  153: Octave -> Odin  ##"
	@echo "###########################"
	@echo
	mv QR.m QR.m.bak
	octave -qf QR.octave > QR.odin
	mv QR.m.bak QR.m

QR.gp: QR.odin
	@echo
	@echo "############################"
	@echo "##  154: Odin -> PARI/GP  ##"
	@echo "############################"
	@echo
	odin run QR.odin -file > QR.gp

QR.pasm: QR.gp
	@echo
	@echo "#########################################"
	@echo "##  155: PARI/GP -> Parrot asm (PASM)  ##"
	@echo "#########################################"
	@echo
	gp -f -q QR.gp > QR.pasm

QR.p: QR.pasm
	@echo
	@echo "##########################################"
	@echo "##  156: Parrot asm (PASM) -> Parser 3  ##"
	@echo "##########################################"
	@echo
	parrot QR.pasm > QR.p

QR.pas: QR.p
	@echo
	@echo "###############################"
	@echo "##  157: Parser 3 -> Pascal  ##"
	@echo "###############################"
	@echo
	parser3 QR.p > QR.pas

QR.pawn: QR.pas
	@echo
	@echo "###########################"
	@echo "##  158: Pascal -> Pawn  ##"
	@echo "###########################"
	@echo
	fpc QR.pas
	./QR > QR.pawn

QR.pl: QR.pawn
	@echo
	@echo "###########################"
	@echo "##  159: Pawn -> Perl 5  ##"
	@echo "###########################"
	@echo
	pawncc -C64 QR.pawn -oQR.amx > /dev/null
	pawnrun QR.amx > QR.pl
	rm -f QR.amx

QR.pl6: QR.pl
	@echo
	@echo "#############################"
	@echo "##  160: Perl 5 -> Perl 6  ##"
	@echo "#############################"
	@echo
	perl QR.pl > QR.pl6

QR.php: QR.pl6
	@echo
	@echo "##########################"
	@echo "##  161: Perl 6 -> PHP  ##"
	@echo "##########################"
	@echo
	perl6 QR.pl6 > QR.php

QR.pi: QR.php
	@echo
	@echo "#########################"
	@echo "##  162: PHP -> Picat  ##"
	@echo "#########################"
	@echo
	php QR.php > QR.pi

QR.l: QR.pi
	@echo
	@echo "##############################"
	@echo "##  163: Picat -> PicoLisp  ##"
	@echo "##############################"
	@echo
	picat QR.pi > QR.l

QR.ppm: QR.l
	@echo
	@echo "#############################"
	@echo "##  164: PicoLisp -> Piet  ##"
	@echo "#############################"
	@echo
	pil QR.l > QR.ppm

QR.pike: QR.ppm
	@echo
	@echo "#########################"
	@echo "##  165: Piet -> Pike  ##"
	@echo "#########################"
	@echo
	npiet QR.ppm > QR.pike

QR.pk: QR.pike
	@echo
	@echo "###############################"
	@echo "##  166: Pike -> PocketLang  ##"
	@echo "###############################"
	@echo
	pike QR.pike > QR.pk

qrpony/main.pony: QR.pk
	@echo
	@echo "###############################"
	@echo "##  167: PocketLang -> Pony  ##"
	@echo "###############################"
	@echo
	pocket QR.pk > qrpony/main.pony

QR.ps: qrpony/main.pony
	@echo
	@echo "###############################"
	@echo "##  168: Pony -> PostScript  ##"
	@echo "###############################"
	@echo
	ponyc -V0 -b qrpony.out -o . qrpony
	./qrpony.out > QR.ps

QR.ps1: QR.ps
	@echo
	@echo "#####################################"
	@echo "##  169: PostScript -> PowerShell  ##"
	@echo "#####################################"
	@echo
	gs -dNODISPLAY -q QR.ps > QR.ps1

QR.prolog: QR.ps1
	@echo
	@echo "#################################"
	@echo "##  170: PowerShell -> Prolog  ##"
	@echo "#################################"
	@echo
	DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=1 POWERSHELL_TELEMETRY_OPTOUT=1 pwsh -NoProfile -NonInteractive -File QR.ps1 > QR.prolog

QR.pr: QR.prolog
	@echo
	@echo "#####################################"
	@echo "##  171: Prolog -> Promela (Spin)  ##"
	@echo "#####################################"
	@echo
	swipl -q -t qr -f QR.prolog > QR.pr

QRP.purs: QR.pr
	@echo
	@echo "#########################################"
	@echo "##  172: Promela (Spin) -> PureScript  ##"
	@echo "#########################################"
	@echo
	spin -T QR.pr > QRP.purs

QR.arr: QRP.purs
	@echo
	@echo "################################"
	@echo "##  173: PureScript -> Pyret  ##"
	@echo "################################"
	@echo
	purs compile -o purs_out QRP.purs '/opt/purs/lib/*/src/**/*.purs'
	node purs_out/QRP/index.js > QR.arr
	rm -rf purs_out

QR.pyth: QR.arr
	@echo
	@echo "##########################"
	@echo "##  174: Pyret -> Pyth  ##"
	@echo "##########################"
	@echo
	pyretc QR.arr QR.jarr
	NODE_PATH=/opt/b05/node_modules node QR.jarr > QR.pyth

QR.py: QR.pyth
	@echo
	@echo "###########################"
	@echo "##  175: Pyth -> Python  ##"
	@echo "###########################"
	@echo
	python3 /opt/pyth/pyth.py -n QR.pyth > QR.py

QR.ssa: QR.py
	@echo
	@echo "##########################"
	@echo "##  176: Python -> QBE  ##"
	@echo "##########################"
	@echo
	python3 QR.py > QR.ssa

QR.R: QR.ssa
	@echo
	@echo "#####################"
	@echo "##  177: QBE -> R  ##"
	@echo "#####################"
	@echo
	qbe QR.ssa > QR.qbe.s
	$(CC) QR.qbe.s -o QR
	./QR > QR.R

QR.rkt: QR.R
	@echo
	@echo "########################"
	@echo "##  178: R -> Racket  ##"
	@echo "########################"
	@echo
	R --slave -f QR.R > QR.rkt

QR.rail: QR.rkt
	@echo
	@echo "###########################"
	@echo "##  179: Racket -> Rail  ##"
	@echo "###########################"
	@echo
	racket QR.rkt > QR.rail

QR.ratfor: QR.rail
	@echo
	@echo "###########################"
	@echo "##  180: Rail -> Ratfor  ##"
	@echo "###########################"
	@echo
	rail QR.rail > QR.ratfor

QR.rc: QR.ratfor
	@echo
	@echo "#########################"
	@echo "##  181: Ratfor -> rc  ##"
	@echo "#########################"
	@echo
	ratfor -o QR.ratfor.f QR.ratfor
	gfortran -o QR QR.ratfor.f
	./QR > QR.rc

QR.rep: QR.rc
	@echo
	@echo "###############################"
	@echo "##  182: rc -> rep (librep)  ##"
	@echo "###############################"
	@echo
	rc QR.rc > QR.rep

QR.res: QR.rep
	@echo
	@echo "#####################################"
	@echo "##  183: rep (librep) -> ReScript  ##"
	@echo "#####################################"
	@echo
	rep QR.rep > QR.res

QR.rexx: QR.res
	@echo
	@echo "#############################"
	@echo "##  184: ReScript -> REXX  ##"
	@echo "#############################"
	@echo
	bsc QR.res > QR.res.js
	node QR.res.js > QR.rexx

QR.rhai: QR.rexx
	@echo
	@echo "#########################"
	@echo "##  185: REXX -> Rhai  ##"
	@echo "#########################"
	@echo
	rexx ./QR.rexx > QR.rhai

QR.ring: QR.rhai
	@echo
	@echo "#########################"
	@echo "##  186: Rhai -> Ring  ##"
	@echo "#########################"
	@echo
	rhai-run QR.rhai > QR.ring

QR.rv.s: QR.ring
	@echo
	@echo "###############################"
	@echo "##  187: Ring -> RISC-V asm  ##"
	@echo "###############################"
	@echo
	ring QR.ring > QR.rv.s

QR.roc: QR.rv.s
	@echo
	@echo "##############################"
	@echo "##  188: RISC-V asm -> Roc  ##"
	@echo "##############################"
	@echo
	rm -f QR
	riscv64-linux-gnu-gcc -nostdlib -static -o QR QR.rv.s
	qemu-riscv64 ./QR > QR.roc
	rm -f QR

QR.rock: QR.roc
	@echo
	@echo "############################"
	@echo "##  189: Roc -> Rockstar  ##"
	@echo "############################"
	@echo
	roc build --output qrroc QR.roc
	./qrroc > QR.rock
	rm -f qrroc

QR.rb: QR.rock
	@echo
	@echo "#############################"
	@echo "##  190: Rockstar -> Ruby  ##"
	@echo "#############################"
	@echo
	rockstar QR.rock > QR.rb

QR.rs: QR.rb
	@echo
	@echo "#########################"
	@echo "##  191: Ruby -> Rust  ##"
	@echo "#########################"
	@echo
	ruby QR.rb > QR.rs

QR.rye: QR.rs
	@echo
	@echo "########################"
	@echo "##  192: Rust -> Rye  ##"
	@echo "########################"
	@echo
	rustc QR.rs
	./QR > QR.rye

QR.scala: QR.rye
	@echo
	@echo "#########################"
	@echo "##  193: Rye -> Scala  ##"
	@echo "#########################"
	@echo
	rye QR.rye > QR.scala

QR.scm: QR.scala
	@echo
	@echo "############################"
	@echo "##  194: Scala -> Scheme  ##"
	@echo "############################"
	@echo
	scalac QR.scala
	scala QR > QR.scm

QR.sci: QR.scm
	@echo
	@echo "#############################"
	@echo "##  195: Scheme -> Scilab  ##"
	@echo "#############################"
	@echo
	$(SCHEME) QR.scm > QR.sci

QR.sed: QR.sci
	@echo
	@echo "##########################"
	@echo "##  196: Scilab -> sed  ##"
	@echo "##########################"
	@echo
	scilab-cli -nb -f QR.sci > QR.sed

QR.sd7: QR.sed
	@echo
	@echo "#########################"
	@echo "##  197: sed -> Seed7  ##"
	@echo "#########################"
	@echo
	sed -E -f QR.sed QR.sed > QR.sd7

QR.spl: QR.sd7
	@echo
	@echo "#################################"
	@echo "##  198: Seed7 -> Shakespeare  ##"
	@echo "#################################"
	@echo
	s7 -q QR.sd7 > QR.spl

QR.sim: QR.spl
	@echo
	@echo "##################################"
	@echo "##  199: Shakespeare -> Simula  ##"
	@echo "##################################"
	@echo
	spl2c < QR.spl > QR.spl.c
	gcc -O0 -z muldefs -o QR -I ./vendor/local/include -L ./vendor/local/lib QR.spl.c -lspl -lm
	./QR > QR.sim

QR.sing: QR.sim
	@echo
	@echo "###############################"
	@echo "##  200: Simula -> Singular  ##"
	@echo "###############################"
	@echo
	@[ ! -f QR.c ] || mv QR.c QR.c.bak
	cim -q -b -w QR.sim
	./QR > QR.sing
	rm -f QR QR.o
	@[ ! -f QR.c.bak ] || mv QR.c.bak QR.c

QR.sl: QR.sing
	@echo
	@echo "###############################"
	@echo "##  201: Singular -> S-Lang  ##"
	@echo "###############################"
	@echo
	Singular -q QR.sing > QR.sl

QR.slashes: QR.sl
	@echo
	@echo "##########################"
	@echo "##  202: S-Lang -> ///  ##"
	@echo "##########################"
	@echo
	slsh QR.sl > QR.slashes

QR.sno: QR.slashes
	@echo
	@echo "###########################"
	@echo "##  203: /// -> SNOBOL4  ##"
	@echo "###########################"
	@echo
	ruby vendor/slashes.rb QR.slashes > QR.sno

QR.sql: QR.sno
	@echo
	@echo "####################################"
	@echo "##  204: SNOBOL4 -> SQL (SQLite)  ##"
	@echo "####################################"
	@echo
	snobol4 -b QR.sno > QR.sql

QR.nut: QR.sql
	@echo
	@echo "#####################################"
	@echo "##  205: SQL (SQLite) -> Squirrel  ##"
	@echo "#####################################"
	@echo
	sqlite3 < QR.sql > QR.nut

QR.sml: QR.nut
	@echo
	@echo "####################################"
	@echo "##  206: Squirrel -> Standard ML  ##"
	@echo "####################################"
	@echo
	squirrel QR.nut > QR.sml

QR.sq: QR.sml
	@echo
	@echo "##################################"
	@echo "##  207: Standard ML -> Subleq  ##"
	@echo "##################################"
	@echo
	polyc -o QR QR.sml
	./QR > QR.sq

QR.ss: QR.sq
	@echo
	@echo "##################################"
	@echo "##  208: Subleq -> SurgeScript  ##"
	@echo "##################################"
	@echo
	ruby vendor/subleq.rb QR.sq > QR.ss

QR.swift: QR.ss
	@echo
	@echo "#################################"
	@echo "##  209: SurgeScript -> Swift  ##"
	@echo "#################################"
	@echo
	surgescript QR.ss > QR.swift

QR.taxi: QR.swift
	@echo
	@echo "##########################"
	@echo "##  210: Swift -> Taxi  ##"
	@echo "##########################"
	@echo
	swiftc QR.swift
	./QR > QR.taxi

QR.tcl: QR.taxi
	@echo
	@echo "########################"
	@echo "##  211: Taxi -> Tcl  ##"
	@echo "########################"
	@echo
	taxi QR.taxi > QR.tcl

QR.tcsh: QR.tcl
	@echo
	@echo "########################"
	@echo "##  212: Tcl -> tcsh  ##"
	@echo "########################"
	@echo
	tclsh QR.tcl > QR.tcsh

QR.tengo: QR.tcsh
	@echo
	@echo "##########################"
	@echo "##  213: tcsh -> Tengo  ##"
	@echo "##########################"
	@echo
	tcsh QR.tcsh > QR.tengo

QR.t: QR.tengo
	@echo
	@echo "##########################"
	@echo "##  214: Tengo -> Thue  ##"
	@echo "##########################"
	@echo
	tengo QR.tengo > QR.t

QR.txrlisp: QR.t
	@echo
	@echo "########################"
	@echo "##  215: Thue -> TXR  ##"
	@echo "########################"
	@echo
	ruby vendor/thue.rb QR.t > QR.txrlisp

QR.ts: QR.txrlisp
	@echo
	@echo "##############################"
	@echo "##  216: TXR -> TypeScript  ##"
	@echo "##############################"
	@echo
	txr --lisp QR.txrlisp > QR.ts

QR.logo: QR.ts
	@echo
	@echo "##################################"
	@echo "##  217: TypeScript -> UCBLogo  ##"
	@echo "##################################"
	@echo
	tsc --outFile QR.ts.js QR.ts
	$(JAVASCRIPT) QR.ts.js > QR.logo

QR.ua: QR.logo
	@echo
	@echo "############################"
	@echo "##  218: UCBLogo -> Uiua  ##"
	@echo "############################"
	@echo
	ucblogo QR.logo > QR.ua

QR.um: QR.ua
	@echo
	@echo "#########################"
	@echo "##  219: Uiua -> Umka  ##"
	@echo "#########################"
	@echo
	uiua run --no-format QR.ua > QR.um

QR.ul: QR.um
	@echo
	@echo "##############################"
	@echo "##  220: Umka -> Underload  ##"
	@echo "##############################"
	@echo
	umka QR.um > QR.ul

QR.unl: QR.ul
	@echo
	@echo "##################################"
	@echo "##  221: Underload -> Unlambda  ##"
	@echo "##################################"
	@echo
	ruby vendor/underload.rb QR.ul > QR.unl

QR.tal: QR.unl
	@echo
	@echo "###############################"
	@echo "##  222: Unlambda -> Uxntal  ##"
	@echo "###############################"
	@echo
	ruby vendor/unlambda.rb QR.unl > QR.tal

QR.vlang.v: QR.tal
	@echo
	@echo "########################"
	@echo "##  223: Uxntal -> V  ##"
	@echo "########################"
	@echo
	uxnasm QR.tal QR.rom
	uxncli QR.rom > QR.vlang.v
	rm -f QR.rom

QR.vala: QR.vlang.v
	@echo
	@echo "######################"
	@echo "##  224: V -> Vala  ##"
	@echo "######################"
	@echo
	v run QR.vlang.v > QR.vala

QR.vale: QR.vala
	@echo
	@echo "#########################"
	@echo "##  225: Vala -> Vale  ##"
	@echo "#########################"
	@echo
	valac QR.vala
	./QR > QR.vale

QR.mid: QR.vale
	@echo
	@echo "###########################"
	@echo "##  226: Vale -> Velato  ##"
	@echo "###########################"
	@echo
	rm -rf qr_vale_out
	valec build qr=QR.vale --output_dir qr_vale_out > /dev/null
	./qr_vale_out/main > QR.mid
	rm -rf qr_vale_out

QR.v: QR.mid
	@echo
	@echo "##############################"
	@echo "##  227: Velato -> Verilog  ##"
	@echo "##############################"
	@echo
	mono vendor/local/bin/Vlt.exe /s QR.mid
	mono QR.exe > QR.v

QR.vhdl: QR.v
	@echo
	@echo "############################"
	@echo "##  228: Verilog -> VHDL  ##"
	@echo "############################"
	@echo
	iverilog -o QR QR.v
	./QR -vcd-none > QR.vhdl

QR.vim: QR.vhdl
	@echo
	@echo "##############################"
	@echo "##  229: VHDL -> Vimscript  ##"
	@echo "##############################"
	@echo
	ghdl -a QR.vhdl
	ghdl -e qr
	ghdl -r qr > QR.vim

qr_vb/QR.vb: QR.vim
	@echo
	@echo "######################################"
	@echo "##  230: Vimscript -> Visual Basic  ##"
	@echo "######################################"
	@echo
	vim -EsS QR.vim > qr_vb/QR.vb

QR.wat: qr_vb/QR.vb
	@echo
	@echo "######################################################"
	@echo "##  231: Visual Basic -> WebAssembly (Text format)  ##"
	@echo "######################################################"
	@echo
	DOTNET_NOLOGO=1 dotnet run --project qr_vb > QR.wat

QR.ws: QR.wat
	@echo
	@echo "####################################################"
	@echo "##  232: WebAssembly (Text format) -> Whitespace  ##"
	@echo "####################################################"
	@echo
	wat2wasm QR.wat -o QR.wat.wasm
	$(WASI_RUNTIME) QR.wat.wasm > QR.ws

QR.wren: QR.ws
	@echo
	@echo "###############################"
	@echo "##  233: Whitespace -> Wren  ##"
	@echo "###############################"
	@echo
	ruby vendor/whitespace.rb QR.ws > QR.wren

QR.xslt: QR.wren
	@echo
	@echo "#########################"
	@echo "##  234: Wren -> XSLT  ##"
	@echo "#########################"
	@echo
	wren_cli QR.wren > QR.xslt

QR.yab: QR.xslt
	@echo
	@echo "############################"
	@echo "##  235: XSLT -> Yabasic  ##"
	@echo "############################"
	@echo
	xsltproc QR.xslt > QR.yab

QR.yeti: QR.yab
	@echo
	@echo "############################"
	@echo "##  236: Yabasic -> Yeti  ##"
	@echo "############################"
	@echo
	yabasic QR.yab > QR.yeti

QR.yorick: QR.yeti
	@echo
	@echo "###########################"
	@echo "##  237: Yeti -> Yorick  ##"
	@echo "###########################"
	@echo
	yeti QR.yeti > QR.yorick

QR.ysh: QR.yorick
	@echo
	@echo "##########################"
	@echo "##  238: Yorick -> YSH  ##"
	@echo "##########################"
	@echo
	yorick -batch QR.yorick > QR.ysh

QR.z80: QR.ysh
	@echo
	@echo "###########################"
	@echo "##  239: YSH -> Z80 asm  ##"
	@echo "###########################"
	@echo
	ysh QR.ysh > QR.z80

QR.zig: QR.z80
	@echo
	@echo "###########################"
	@echo "##  240: Z80 asm -> Zig  ##"
	@echo "###########################"
	@echo
	z80asm QR.z80 -o qr.com
	tnylpo -b qr.com < /dev/null > QR.zig
	rm -f qr.com

QR.azm: QR.zig
	@echo
	@echo "########################"
	@echo "##  241: Zig -> Zoem  ##"
	@echo "########################"
	@echo
	zig run QR.zig > QR.azm

QR.zsh: QR.azm
	@echo
	@echo "########################"
	@echo "##  242: Zoem -> zsh  ##"
	@echo "########################"
	@echo
	zoem -i QR.azm > QR.zsh

QR.s65: QR.zsh
	@echo
	@echo "############################"
	@echo "##  243: zsh -> 6502 asm  ##"
	@echo "############################"
	@echo
	zsh QR.zsh > QR.s65

QR.aplus.a: QR.s65
	@echo
	@echo "###########################"
	@echo "##  244: 6502 asm -> A+  ##"
	@echo "###########################"
	@echo
	xa -o QR.o65 QR.s65
	sim65 QR.o65 > QR.aplus.a
	rm -f QR.o65

qr.adb: QR.aplus.a
	@echo
	@echo "######################"
	@echo "##  245: A+ -> Ada  ##"
	@echo "######################"
	@echo
	a+ QR.aplus.a > qr.adb 2> /dev/null < /dev/null

QR.als: qr.adb
	@echo
	@echo "#########################"
	@echo "##  246: Ada -> AFNIX  ##"
	@echo "#########################"
	@echo
	gnatmake qr.adb
	./qr > QR.als

QR.aheui: QR.als
	@echo
	@echo "###########################"
	@echo "##  247: AFNIX -> Aheui  ##"
	@echo "###########################"
	@echo
	LANG=C LD_LIBRARY_PATH=/usr/lib/afnix axi QR.als > QR.aheui

QR.alg: QR.aheui
	@echo
	@echo "##############################"
	@echo "##  248: Aheui -> ALGOL 60  ##"
	@echo "##############################"
	@echo
	ruby vendor/aheui.rb QR.aheui > QR.alg

QR.a68: QR.alg
	@echo
	@echo "#################################"
	@echo "##  249: ALGOL 60 -> ALGOL 68  ##"
	@echo "#################################"
	@echo
	marst QR.alg -o QR.alg.c
	gcc QR.alg.c -lalgol -lm -o QR
	./QR > QR.a68
	rm -f QR QR.alg.c

QR.ank: QR.a68
	@echo
	@echo "#############################"
	@echo "##  250: ALGOL 68 -> Anko  ##"
	@echo "#############################"
	@echo
	a68g --heap 512M QR.a68 > QR.ank

QR.ante: QR.ank
	@echo
	@echo "#########################"
	@echo "##  251: Anko -> Ante  ##"
	@echo "#########################"
	@echo
	anko QR.ank > QR.ante

QR.arm64.s: QR.ante
	@echo
	@echo "##############################"
	@echo "##  252: Ante -> ARM64 asm  ##"
	@echo "##############################"
	@echo
	ruby vendor/ante.rb QR.ante > QR.arm64.s

QR.arnoldc: QR.arm64.s
	@echo
	@echo "#################################"
	@echo "##  253: ARM64 asm -> ArnoldC  ##"
	@echo "#################################"
	@echo
	rm -f QR
	aarch64-linux-gnu-gcc -nostdlib -static -o QR QR.arm64.s
	qemu-aarch64 ./QR > QR.arnoldc
	rm -f QR

QR.art: QR.arnoldc
	@echo
	@echo "##############################"
	@echo "##  254: ArnoldC -> Arturo  ##"
	@echo "##############################"
	@echo
	rm -f QR.class
	java -jar /opt/ArnoldC.jar QR.arnoldc
	java QR > QR.art
	rm -f QR.class

QR.cc: QR.art
	@echo
	@echo "################################"
	@echo "##  255: Arturo -> AspectC++  ##"
	@echo "################################"
	@echo
	arturo QR.art < /dev/null > QR.cc

QR2.aj: QR.cc
	@echo
	@echo "#################################"
	@echo "##  256: AspectC++ -> AspectJ  ##"
	@echo "#################################"
	@echo
	ag++ --keywords -o QR QR.cc
	./QR > QR2.aj

clean:
	@mv QR.aj quine-relay.aj
	rm -f qr QR qr.* QR.* QRP.* QR2.aj qrgleam/src/qr.gleam qrpony/main.pony qrpony.out qr_cs/QR.cs qr_vb/QR.vb *.class gst.im QR_ec* qr_mercury* qrkoka qrchpl qrroc tmp.*proj work-obj93.cf QRMUMPS.* .apl.history QR.qbe.s QR.mth.c QR.gro QR.wasm qr_austral QR.amx qr.com
	rm -rf Mercury .koka .obnc dafny-out frege-out purs_out bin obj qrgleam/build qr_cs/bin qr_cs/obj qr_vb/bin qr_vb/obj 'Clean System Files' target qr_effekt_out qr_vale_out
	@mv quine-relay.aj QR.aj
