require_relative "code-gen"

OUT = []

def banner(s1, s2=nil, i=nil)
  s = "##  #{ "#{ i + 1 }: " if i }#{ s1 }#{ ' -> ' + s2 if s2 }  ##"
  OUT << "\t@echo"
  OUT << "\t@echo \"#{ "#" * s.size }\""
  OUT << "\t@echo \"#{ s }\""
  OUT << "\t@echo \"#{ "#" * s.size }\""
  OUT << "\t@echo"
end

OUT << <<-END
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
END
OUT << "all: QR2.aj"
banner("CHECK")
OUT << "\tdiff -s QR.aj QR2.aj"
OUT << ""
OUT << "check: all"
OUT << "\t@sha256sum --quiet -c SHA256SUMS"

[*RunSteps, RunStep["AspectJ", "QR2.aj"]].each_cons(2).with_index do |(s1, s2), i|
  cmd = s1.cmd_make.gsub("OUTFILE", s2.src)

  OUT << ""
  OUT << "#{ s2.src }: #{ s1.src }"
  banner(s1.name, s2.name, i)
  if s1.backup
    if s1.backup.is_a?(String)
      OUT << "\t@mv #{ s1.backup } #{ s1.backup }.bak"
    else
      OUT << "\t@#{ s1.backup[0] }"
    end
  end
  cmd.split("&&").each {|c| OUT << "\t" + c.strip.gsub(/^!/, "ulimit -s unlimited && ") }
  if s1.backup
    if s1.backup.is_a?(String)
      OUT << "\t@mv #{ s1.backup }.bak #{ s1.backup }"
    else
      OUT << "\t@#{ s1.backup[1] }"
    end
  end
end

# Files and directories emitted by non-QR.* compiler/runtime targets.
# Add any extra build outputs from replacement languages to EXTRA_CLEAN_FILES
# or EXTRA_CLEAN_DIRS so `make clean` always leaves a spotless working tree.
CLEAN_FILES = %w[
  qr QR qr.* QR.* QRP.* QR2.aj qrgleam/src/qr.gleam qrpony/main.pony qrpony.out qr_cs/QR.cs qr_vb/QR.vb *.class gst.im
  QR_ec* qr_mercury* qrkoka qrchpl qrroc
  tmp.*proj work-obj93.cf
]
EXTRA_CLEAN_FILES = %w[
  QRMUMPS.* .apl.history QR.qbe.s QR.mth.c QR.gro QR.wasm QR.ook.bf
  qr_austral QR.amx qr.com
]

CLEAN_DIRS = %w[
  Mercury .koka .obnc
  dafny-out frege-out purs_out bin obj qrgleam/build qr_cs/bin qr_cs/obj qr_vb/bin qr_vb/obj
]
EXTRA_CLEAN_DIRS = [
  "'Clean System Files'", "target", "qr_effekt_out", "qr_vale_out"
]

OUT << <<-END

clean:
\t@mv QR.aj quine-relay.aj
\trm -f #{ (CLEAN_FILES + EXTRA_CLEAN_FILES).join(" ") }
\trm -rf #{ (CLEAN_DIRS + EXTRA_CLEAN_DIRS).join(" ") }
\t@mv quine-relay.aj QR.aj

watch:
\t@python3 tools/relay_ui.py
END

File.binwrite("../Makefile", OUT.join("\n"))
