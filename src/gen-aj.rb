#!/usr/bin/env ruby
# Compiles the CodeGen steps from code-gen.rb into the self-reproducing AspectJ quine QR.aj.
require "zlib"
require "base64"
require "tmpdir"

CODE_GEN_PATH = ARGV[0] || File.expand_path("code-gen.rb", __dir__)
OUT_AJ_PATH   = ARGV[1] || File.expand_path("../QR.aj", __dir__)
ENGINE_PATH   = File.expand_path("engine_body.java", __dir__)

# Load code-gen.rb from its own directory so __dir__ resolves boot .dat files
require CODE_GEN_PATH

# Bitmask flags matching engine_body.java xf(s, f)
F_E        = 1
F_DQ       = 2
F_SQ       = 4
F_BQ       = 8
F_Q_BS_DQ  = 16
F_Q_BS_SQ  = 32
F_TAB      = 64
F_CR       = 128
F_DOLLAR   = 256
F_PCT      = 512
F_PCT2     = 1024
F_HASH     = 2048
F_QMARK    = 4096
F_SQ_BS    = 8192
F_BRACE2   = 16384
F_BRACE_BS = 32768
F_CTRL_HEX = 65536
F_CTRL_OCT = 131072
F_CHOMP    = 262144
F_HI_HEX   = 524288
F_NO_END_BS = 1048576
F_UTF16_U  = 2097152
F_UNICODE_U = 4194304

# Evaluate a single GenStep's Ruby code on a given string
def eval_step(step, str)
  src = GenPrologue + ";" + step.code.sub("PREV") { str.dump }
  Object.new.instance_eval(src)
end

PROBE = "___QR_PROBE_XYZ___"

# Base91 encoder using printable ASCII 33..126 minus '"' (34), ':' (58), '\\' (92)
# and B91Q excluding '\'' (39) instead of ':' (58) for Zig/V literals
B91  = (33..126).reject { |c| c == 34 || c == 58 || c == 92 }.map(&:chr)
B91Q = (33..126).reject { |c| c == 34 || c == 39 || c == 92 }.map(&:chr)
def b91_encode(bytes, alpha = B91)
  out = +""
  b = 0; n = 0
  bytes.each_byte do |x|
    b |= x << n; n += 8
    if n > 13
      v = b & 8191
      if v > 88
        b >>= 13; n -= 13
      else
        v = b & 16383; b >>= 14; n -= 14
      end
      out << alpha[v % 91] << alpha[v / 91]
    end
  end
  if n > 0
    out << alpha[b % 91]
    out << alpha[b / 91] if n > 7 || b > 90
  end
  out
end

def probe_wrap(step)
  out = eval_step(step, PROBE)
  parts = out.split(PROBE, -1)
  raise "probe_wrap failed for #{step.name}: found #{parts.size - 1} occurrences" unless parts.size == 2
  parts
end

# Binary encoder helpers matching ri()/rs() in engine_body.java
class BinBuf
  def initialize
    @buf = +"".b
  end

  def byte(b)
    @buf << (b & 255).chr
    self
  end

  def varint(v)
    raise "negative varint #{v}" if v < 0
    loop do
      b = v & 127
      v >>= 7
      if v > 0
        @buf << (b | 128).chr
      else
        @buf << b.chr
        break
      end
    end
    self
  end

  def str(s)
    b = s.encode("UTF-8").b
    varint(b.bytesize)
    @buf << b
    self
  end

  def wrap(pre, suf, flags = 0)
    chunk(pre, suf, "", "", "", 0, flags, 0, [])
  end

  def map_wrap(pre, suf, map, pf = 0, qf = 0)
    chunk(pre, suf, "", "", "", 0, pf, qf, map)
  end

  def chunk(pre, suf, cpre, csuf, join, clen, pf = 0, qf = 0, map = [])
    byte(2).str(pre).str(suf).str(cpre).str(csuf).str(join)
      .varint(clen).varint(pf).varint(qf).varint(map.size)
    map.each { |k, v| str(k).str(v) }
    self
  end

  def bytes
    @buf
  end
end

# Extract [pre, suf] for a chunked step by probing with 1 chunk and stripping cpre/csuf
def probe_chunk_ends(step, cpre, csuf)
  pre, suf = probe_wrap(step)
  raise "#{step.name}: pre does not end with cpre (#{cpre.inspect})" unless pre.end_with?(cpre)
  raise "#{step.name}: suf does not start with csuf (#{csuf.inspect})" unless suf.start_with?(csuf)
  [pre[0, pre.length - cpre.length], suf[csuf.length..]]
end

# Map each CodeGen class name to its binary spec record
def compile_step(buf, step)
  name = step.name
  code = step.code

  case name
  # --- Simple RAW WRAP ---
  when "Nushell", "ParrotAsm", "NewLISPLang", "Nelua", "Lean4", "Koto", "Idris2",
       "Effekt", "Dc_Dhall", "ChaiScript", "AspectCpp", "XSLT",
       "ThueLang", "Bash_Bc", "Macaulay2_Makefile_MalbolgeUnshackled"
    pre, suf = probe_wrap(step)
    buf.wrap(pre, suf, 0)

  when "PureScript"
    pre, suf = probe_wrap(step)
    buf.wrap(pre, suf, F_CHOMP)

  # --- Simple e[PREV] WRAP ---
  when "Rhai", "LibRep", "PythonLang", "Pyret", "Prolog", "Pony", "Pike", "PARIGP",
       "Odin_Ook", "OCaml", "ObjC", "Nickle", "Mustache_NASM", "MSIL", "MiniZinc",
       "LFE", "Janet", "IoLang", "Hy", "GDB", "GAP", "Gambas", "Flex",
       "Fennel", "Dyon", "Crystal", "AFNIX_Aheui", "VimScript",
       "Vala", "TypeScript", "TXR", "Swift", "StandardML_Subleq", "Squirrel",
       "Rye", "Rust", "EmacsLisp", "Umka_Unlambda"
    pre, suf = probe_wrap(step)
    buf.wrap(pre, suf, F_E)

  when "JavaScript_Jq_JSFuck"
    pre, suf = probe_wrap(step)
    buf.wrap(pre, suf, F_CHOMP | F_E)

  # --- e[PREV] + extra flag WRAP ---
  when "PocketLang"
    pre, suf = probe_wrap(step); buf.wrap(pre, suf, F_E | F_DOLLAR)
  when "Numbat"
    pre, suf = probe_wrap(step); buf.wrap(pre, suf, F_E | F_BRACE2)
  when "NesC"
    pre, suf = probe_wrap(step); buf.wrap(pre, suf, F_E | F_QMARK)
  when "LiveScriptLang"
    pre, suf = probe_wrap(step); buf.wrap(pre, suf, F_E | F_HASH)
  when "GolfScript"
    pre, suf = probe_wrap(step); buf.wrap(pre, suf, F_CHOMP | F_E | F_HASH | F_HI_HEX)
  when "Gnuplot"
    pre, suf = probe_wrap(step); buf.wrap(pre, suf, F_E | F_CTRL_OCT)
  when "Asymptote"
    pre, suf = probe_wrap(step); buf.wrap(pre, suf, F_E | F_SQ_BS)
  when "Wren"
    pre, suf = probe_wrap(step); buf.wrap(pre, suf, F_E | F_PCT)
  when "Vale_Velato"
    pre, suf = probe_wrap(step); buf.wrap(pre, suf, F_E | F_BRACE_BS)
  when "Cyber"
    pre, suf = probe_wrap(step); buf.map_wrap(pre, suf, [["$(", "\\$("]], F_E, 0)

  # --- Simple d / Q WRAP ---
  when "BQN_BrainFlak_Brainfuck", "DafnyLang"
    pre, suf = probe_wrap(step); buf.wrap(pre, suf, F_DQ)
  when "GNUSmalltalk", "Falcon", "Elvish"
    pre, suf = probe_wrap(step); buf.wrap(pre, suf, F_SQ)
  when "C3"
    pre, suf = probe_wrap(step); buf.wrap(pre, suf, F_BQ)
  when "CLIPS", "CJam"
    pre, suf = probe_wrap(step); buf.wrap(pre, suf, F_Q_BS_DQ)
  when "PHPLang", "Perl6", "Perl5", "Fish"
    pre, suf = probe_wrap(step); buf.wrap(pre, suf, F_Q_BS_SQ)

  # --- MAP_WRAP classes ---
  when "Roc"
    pre, suf = probe_wrap(step)
    buf.map_wrap(pre, suf, [["@", "@A"], ["\\", "@D"], ['"', "@C"], ["$", "@E"], ["\n", "@F"]])
  when "RingLang"
    pre, suf = probe_wrap(step)
    buf.map_wrap(pre, suf, [["'", "'+char(39)+'"]])
  when "ReScript"
    pre, suf = probe_wrap(step)
    buf.map_wrap(pre, suf, [["@", "@0"], ["\\", "@1"], ['"', "@2"], ["\n", "@4"]])
  when "Rail"
    pre, suf = probe_wrap(step)
    buf.map_wrap(pre, suf, [["\\", "\\\\"], ["[", "\\[\\"], ["]", "\\]\\"], ["\n", "\\n\\"]])
  when "RacketLang", "Mercury", "Erlang"
    pre, suf = probe_wrap(step)
    buf.map_wrap(pre, suf, [["@", "@0"], ["\\", "@1"], ['"', "@2"], ["'", "@3"], ["\n", "@4"], ["$", "@5"]])
  when "PicoLisp_Piet"
    pre, suf = probe_wrap(step)
    buf.map_wrap(pre, suf, [["\\", "\\\\"], ['"', '\\"'], ["^", "\\^"]])
  when "Parser3"
    pre, suf = probe_wrap(step)
    buf.map_wrap(pre, suf, %w[^ $ ; ( ) [ ] { }].map { |c| [c, "^" + c] })
  when "Octave"
    pre, suf = probe_wrap(step)
    buf.map_wrap(pre, suf, [["%", "%0"], ["\\", "%1"], ['"', "%2"], ["'", "%3"], ["\n", "%4"], ["$", "%5"]])
  when "Nim"
    pre, suf = probe_wrap(step)
    buf.map_wrap(pre, suf, [["#", "#0"], ["\\", "#1"], ['"', "#2"], ["'", "#3"], ["\n", "#4"], ["%", "#5"], ["}", "#6"]])
  when "Nial"
    pre, suf = probe_wrap(step)
    buf.map_wrap(pre, suf, [["'", "''"], ["\n", "' (char 10) '"]])
  when "Ksh_LazyK", "Zsh"
    pre, suf = probe_wrap(step)
    buf.map_wrap(pre, suf, [["'", "'\"'\"'"]])
  when "IonShell"
    pre = "let q = \"'\"\nlet b = \"\\\\\"\nlet d = '$'\nlet a = '@'\nlet l = '['\nlet r = ']'\nlet o = '{'\nlet c = '}'\nlet p = '('\nlet k = ')'\nlet x = ''\n"
    buf.chunk(pre, "\necho -n $x\n", "let x ++= '", "'", "\n", 4000, 0, 0,
      [["'", "'$q'"], ["\\", "'$b'"], ["$", "'$d'"], ["@", "'$a'"],
       ["[", "'$l'"], ["]", "'$r'"], ["{", "'$o'"], ["}", "'$c'"],
       ["(", "'$p'"], [")", "'$k'"]])
  when "TcshLang"
    buf.chunk("set echo_style=bsd\n", "\n", "echo -n '", "'", "\n", 1000, 0, 0, [["'", "'\"'\"'"], ["\n", "'\necho ''\necho -n '"]])
  when "JuliaLang"
    out = eval_step(step, PROBE)
    tok = (PROBE.bytesize - 1 + 37).chr + PROBE
    pre, suf = out.split(tok, -1)
    raise "Julia probe mismatch" unless pre && suf && out.split(tok, -1).size == 2
    buf.byte(55).str(pre).str(suf)
  when "J"
    pre, suf = probe_wrap(step)
    buf.map_wrap(pre, suf, [["'", "''"], ["\n", "',(10{a.),'"]])
  when "Inko_INTERCAL"
    pre, suf = probe_wrap(step)
    buf.map_wrap(pre, suf, [["@", "@A"], ["\\", "@D"], ["'", "@C"], ["$", "@E"]])
  when "Haskell"
    pre, suf = probe_wrap(step)
    buf.map_wrap(pre, suf, [["@", "@A"], ["\\", "@D"], ['"', "@C"], ["\n", "@N"]])
  when "Hare"
    pre, suf = probe_wrap(step)
    buf.map_wrap(pre, suf, [["`", '`"`"`']])
  when "Anko_Ante", "Tengo"
    pre, suf = probe_wrap(step)
    buf.map_wrap(pre, suf, [["`", '`+"`"+`']])
  when "Gleam"
    pre, suf = probe_wrap(step)
    p = code.include?('"%A"') ? "%" : "@"
    buf.map_wrap(pre, suf, [[p, "#{p}A"], ["\\", "#{p}D"], ['"', "#{p}C"]], 0, F_UNICODE_U)
  when "Glass"
    buf.byte(54).str("{M[m(_o)O!(_s)S!(q)<34>(_s)(ns).?=").str("(q)*(_o)o.?").str("\"(_o)o.?")
  when "FALSELang"
    pre, suf = probe_wrap(step)
    buf.map_wrap(pre, suf, [['"', '"34,"']])
  when "Elixir"
    if code.include?("Deflate")
      out = eval_step(step, PROBE)
      b64 = [Zlib::Deflate.deflate(PROBE, 9)].pack("m0")
      pre, suf = out.split(b64, -1)
      buf.byte(3).str(pre).str(suf).varint(0)
    else
      pre, suf = probe_wrap(step)
      p = code.include?('"%A"') ? "%" : "@"
      buf.map_wrap(pre, suf, [[p, "#{p}A"], ["\\", "#{p}D"], ['"', "#{p}C"], ["[", "#{p}L"], ["]", "#{p}R"], ["#", "#{p}H"], ["'", "#{p}Q"], ["\n", "#{p}N"]])
    end
  when "Dart"
    pre, suf = probe_wrap(step)
    buf.map_wrap(pre, suf, [["'", "'\"'\"r'"], ["\n", "'\"\\n\"r'"]])
  when "D"
    if code.include?("scan(")
      buf.chunk("import std;void main(){", "}", 'write("', '");', "", 15000, F_E)
    else
      pre, suf = probe_wrap(step)
      buf.map_wrap(pre, suf, [['"', '"~\'"\'~r"']])
    end
  when "CoffeeScript"
    if code.include?("Deflate")
      out = eval_step(step, PROBE)
      b64 = [Zlib::Deflate.deflate(PROBE, 9)].pack("m0")
      pre, suf = out.split(b64, -1)
      buf.byte(3).str(pre).str(suf).varint(0)
    else
      pre, suf = probe_wrap(step)
      buf.map_wrap(pre, suf, [["@", "@A"], ["\\", "@D"], ['"', "@C"], ["#", "@H"], ["\n", "@N"]])
    end
  when "CSharpLang", "FSharp"
    if code.include?("Deflate")
      out = eval_step(step, PROBE)
      b64 = [Zlib::Deflate.deflate(PROBE, 9)[2..-5]].pack("m0")
      pre, suf = out.split(b64, -1)
      buf.byte(3).str(pre).str(suf).varint(1)
    else
      pre, suf = probe_wrap(step)
      buf.wrap(pre, suf, code.include?("e[") ? F_E : 0)
    end
  when "Go"
    if code.include?("Deflate")
      out = eval_step(step, PROBE)
      b64 = [Zlib::Deflate.deflate(PROBE, 9)].pack("m0")
      pre, suf = out.split(b64, -1)
      buf.byte(3).str(pre).str(suf).varint(0)
    else
      pre, suf = probe_wrap(step)
      buf.wrap(pre, suf, F_E)
    end
  when "Boron"
    pre, suf = probe_wrap(step)
    buf.map_wrap(pre, suf, [["^", "^^"], ['"', '^"'], ["\n", "^/"], ["\t", "^-"]])
  when "Arturo"
    pre, suf = probe_wrap(step)
    buf.map_wrap(pre, suf, [["@", "@0"], ["\\", "@1"], ['"', "@2"]])
  when "Zoem"
    pre, suf = probe_wrap(step)
    buf.map_wrap(pre, suf, [["\\", "\\\\"], ["{", "\\{"], ["}", "\\}"]])
  when "VHDL"
    pre, suf = probe_wrap(step)
    buf.map_wrap(pre, suf, [['"', '""'], ["\n", "\"&character'val(10)&\""], ["\t", "\"&character'val(9)&\""]])
  when "Tcl"
    if code.include?("Deflate")
      out = eval_step(step, PROBE)
      b64 = [Zlib::Deflate.deflate(PROBE, 9)].pack("m0")
      pre, suf = out.split(b64, -1)
      buf.byte(3).str(pre).str(suf).varint(0)
    else
      pre, suf = probe_wrap(step)
      buf.map_wrap(pre, suf, [["\\", "\\\\"], ['"', '\\"'], ["$", "\\$"], ["[", "\\["]])
    end

  # --- CHUNK classes (Op 2) ---
  when "RLang"
    buf.chunk("", "", 'cat("', "\")\n", "", 2000, F_E)
  when "Promela"
    buf.chunk("init{\n", "}", 'printf("', "\");\n", "", 765, F_E | F_PCT2)
  when "PostScript"
    buf.chunk("", "\nquit\n", "(", ")print", "\n", 40000, 0, 0, [["\\", "\\\\"], ["(", "\\("], [")", "\\)"]])
  when "Picat"
    buf.chunk("main=>", ".\n", 'print("', '")', ",", 16000, F_E)
  when "Pawn"
    buf.chunk("#include <console>\nmain(){\n", "\n}\n", 'printf("%s","', '");', "\n", 120, F_E)
  when "Neko"
    buf.chunk("", "", '$print("', '");', "", 20000, F_E)
  when "Mirth"
    buf.chunk("module qr.QR\nimport std.prelude\nimport std.world\ndef main{\n", "}\n", ' "', "\" print-\n", "", 30000, F_E | F_TAB)
  when "Miranda"
    buf.chunk("main=[", "]\n", 'Stdout "', '"', ",", 12000, F_E | F_TAB)
  when "Lisaac"
    buf.chunk("Section Header+name:=QR;Section Public-main<-(", "\n);", "\n\"", '".print;', "", 88, F_E)
  when "Lily"
    buf.chunk("", "\n", 'stdout.write("', '")', "\n", 16000, F_E)
  when "Kotlin"
    buf.chunk("fun main(){", "}", 'print("', '");', "", 15000, F_E | F_DOLLAR)
  when "Klong"
    buf.chunk(".d(", ")\n", '"', '"', ",", 128, F_DQ)
  when "Java_"
    if code.include?("Zlib")
      pre, suf = probe_wrap(step)
      buf.byte(3).str(pre).str(suf).varint(0)
    else
      buf.chunk("class QR{public static void main(String[]a){", "}}", 'System.out.print("', '");', "", 15000, F_E)
    end
  when "Jasmin"
    pre, suf = probe_chunk_ends(step, 'ldc "', "\"\ninvokestatic java/lang/IO/print(Ljava/lang/Object;)V\n")
    buf.chunk(pre, suf, 'ldc "', "\"\ninvokestatic java/lang/IO/print(Ljava/lang/Object;)V\n", "", 20000, F_E)
  when "IconLang"
    buf.chunk("procedure main();", "end", 'writes("', '");', "", 2000, F_E | F_CTRL_HEX)
  when "Haxe_Hexagony"
    pre, suf = probe_chunk_ends(step, 'u.add("', '");')
    buf.chunk(pre, suf, 'u.add("', '");', "", 4000, F_E)
  when "Groovy_Gzip"
    if code.include?("Deflate")
      out = eval_step(step, PROBE)
      b64 = [Zlib::Deflate.deflate(PROBE, 9)].pack("m0")
      pre, suf = out.split("'#{b64}'", -1)
      buf.byte(3).str(pre).str(suf).varint(3)
    else
      csuf = "'"+[[1,92],[2,34],[3,39],[4,10],[0,63]].map{|i,k|".replace('?#{i}',((char)#{k}).toString())"}.join+";"
      buf.chunk("", "\n", "print '", csuf, "\n", 20000, 0, 0, [["?", "?0"], ["\\", "?1"], ['"', "?2"], ["'", "?3"], ["\n", "?4"]])
    end
  when "Gravity"
    buf.chunk("func main(){", "}", 'System.put("', '");', "", 20000, F_E)
  when "Grain_Grass"
    pre, suf = probe_chunk_ends(step, 'emit("', "\")\n")
    buf.chunk(pre, suf, 'emit("', "\")\n", "", 1000, F_E | F_TAB)
  when "GEL"
    buf.chunk("", "", 'printn("', '");', "", 61 * 255, F_E)
  when "Frege"
    buf.chunk("module QR where main args = do {", "}", 'putStr("', '")', ";", 15000, F_E)
  when "Forth_FORTRAN77_Fortran90"
    pre, suf = probe_chunk_ends(step, 'S\" ', "\" GO\n")
    buf.chunk(pre, suf, 'S\" ', "\" GO\n", "", 4000, F_E)
  when "Flix"
    buf.chunk("import java.lang.System\ndef main(): Unit \\ IO = {\nlet out = System.out;\n", "\n}\n", 'out.print("', '")', ";\n", 12000, F_E | F_TAB | F_CR, 0, [["${", "\\${"], ["%{", "\\%{"]])
  when "Fantom"
    buf.chunk("class QR{static Void main(){o:=Env.cur.out;", "o.flush} }", "o.print(Str<|", "|>);", "", 20000, 0, 0, [["|>", "||>+Str<|>"]])
  when "Factor"
    if code.include?("replace")
      buf.chunk("USING: io splitting ;\n", "", '"', "\" \"@D\" \"\\\\\" replace \"@C\" \"\\\"\" replace \"@N\" \"\\n\" replace \"@A\" \"@\" replace write\n", "", 15000, 0, 0, [["@", "@A"], ["\\", "@D"], ['"', "@C"], ["\n", "@N"]])
    else
      buf.chunk("USING: io ;\n", "", '"', "\" write\n", "", 15000, F_E)
    end
  when "Execline"
    buf.chunk("", 'echo ""', 'foreground { echo -n "', '" } ', "", 50000, F_E)
  when "Euphoria"
    buf.chunk("", "\n", 'puts(1,"', '")', "\n", 1000, F_E | F_TAB)
  when "CommonLisp"
    buf.chunk("", "", '(princ"', '")', "", 50000, F_E)
  when "Clojure_CMake_Cobol"
    pre, suf = probe_chunk_ends(step, '"', '"')
    buf.chunk(pre, suf, '"', '"', " ", 15000, F_E)
  when "Clean"
    buf.chunk("module QR\nimport StdEnv\nStart w\n # (c,w)=stdio w\n", " # (_,w)=fclose c w\n = w\n", ' # c=fwrites "', "\" c\n", "", 500, F_E | F_TAB)
  when "CDuce"
    buf.chunk("", "", 'print "', '";;', "", 2000, F_E)
  when "Cplusplus"
    pre, suf = probe_chunk_ends(step, '"', '"')
    p = code.include?('"%A"') ? "%" : "@"
    buf.chunk(pre, suf, '"', '"', "\n", 15000, 0, 0, [[p, "#{p}A"], ["\\", "#{p}D"], ['"', "#{p}C"], ["\n", "#{p}N"]])
  when "Boo"
    p = code.include?('"#A"') ? "#" : "@"
    csuf = "\".Replace(\"#{p}D\",\"\\\\\").Replace(\"#{p}C\",\"\\\"\").Replace(\"#{p}S\",\"$\").Replace(\"#{p}N\",\"\\n\").Replace(\"#{p}A\",\"#{p}\"))\n"
    pre, _ = probe_chunk_ends(step, 'Console.Write("', csuf)
    buf.chunk(pre, "", 'Console.Write("', csuf, "", 15000, 0, F_UTF16_U, [[p, "#{p}A"], ["\\", "#{p}D"], ['"', "#{p}C"], ["$", "#{p}S"], ["\n", "#{p}N"]])
  when "Berry_BLC8"
    pre, suf = probe_chunk_ends(step, '+"', '"')
    buf.chunk(pre, suf, '+"', '"', "", 2000, F_E)
  when "BeanShell"
    buf.chunk("", "", 'System.out.print("', '");', "", 15000, F_E)
  when "Ballerina"
    buf.chunk("import ballerina/io;public function main(){", " }", 'io:print("', '");', "", 15000, F_E)
  when "Awk"
    if code.include?("@A")
      csuf = "\";gsub(/@D/,\"\\\\\\\\\",s);gsub(/@C/,\"\\\"\",s);gsub(/@N/,\"\\n\",s);gsub(/@A/,\"@\",s);printf\"%s\",s;"
      buf.chunk("BEGIN{", "}", 's="', csuf, "", 15000, 0, 0, [["@", "@A"], ["\\", "@D"], ['"', "@C"], ["\n", "@N"]])
    else
      buf.chunk("BEGIN{", "}", 'printf"%s","', '";', "", 15000, F_E)
    end
  when "Austral"
    buf.chunk("module body QR is function main(): ExitCode is ", " return ExitSuccess(); end; end module body.\n", 'print("', '");', "", 8000, F_E | (code.include?("7999") ? F_NO_END_BS : 0))
  when "Ada"
    buf.chunk("with Text_Io;procedure qr is begin\n", "\nend;\n", 'Text_Io.Put("', '");', "\n", 15000, 0, 0, [['"', '""'], ["\n", '"&ASCII.LF&"']])
  when "YSH"
    buf.chunk("write --sep '' --end '' -- ", "", "r'", "'", " ", 32000, 0, 0, [["'", "' \"'\" r'"]])
  when "Yorick"
    buf.chunk('write,format="%s",', '""', '("', "\")+\n", "", 30 * 255, F_E)
  when "Yeti"
    buf.chunk("", "", 'print("', '")', ";", 15000, F_E)
  when "Verilog"
    buf.chunk("module QR;initial begin ", "end endmodule", '$write("%s",("', '"));', "", 3 * 255, F_E)
  when "Uiua"
    buf.chunk("", "", '&pf "', '"', "\n", 4000, F_E, 0, [["\u2022", "\\u{2022}"]])
  when "SurgeScript"
    buf.chunk('object"Application"{state"main"{', "exit();}}", 'Console.write("', '");', "", 4 * 255, F_E)
  when "SLang"
    buf.chunk("", "", 'printf("%s","', "\");\n", "", code[/1,(\d+)/, 1].to_i, F_E)
  when "Singular"
    if code.include?("split(N,-1)")
      buf.byte(6).varint(2000).varint(2).str("string s=\"\";\n").str("s=\"\";\n").str('s=s+"').str("\";\n").str("s;\n").str("quit;\n")
    else
      buf.chunk("string s=\"\";\n", "s;quit;\n", 's=s+"', "\";\n", "", 2000, F_CHOMP | F_Q_BS_DQ)
    end
  when "Seed7_Shakespeare"
    pre, suf = probe_chunk_ends(step, '"', '"')
    buf.chunk(pre, suf, '"', '"', "&\n", 200, F_E)
  when "Scala"
    buf.chunk("object QR extends App{", "}", 'print("', '");', "", 196 * 255, F_E)
  when "ALGOL68Lang"
    buf.chunk("", "", 'print("', '")', ";\n", 1000, 0, 0, [['"', '""'], ["\n", '"+REPR 10+"']])
  when "LOLCODE"
    buf.chunk("HAI 1\n", "\nKTHXBYE\n", 'VISIBLE "', '"!', "\n", 10000, 0, 0, [[":", "::"], ['"', ':"'], ["\n", ":)"]])

  # --- ZLIB_WRAP (Op 3) ---
  when "PowerShell"
    if code.include?("Deflate")
      out = eval_step(step, PROBE)
      b64 = [Zlib::Deflate.deflate(PROBE, 9)[2..-5]].pack("m0")
      pre, suf = out.split(b64, -1)
      buf.byte(3).str(pre).str(suf).varint(1)
    else
      pre, suf = probe_wrap(step)
      buf.wrap(pre, suf, code.include?("e[") ? F_E : 0)
    end
  when "Mathics"
    if code.include?("Deflate")
      out = eval_step(step, PROBE)
      b64 = [Zlib::Deflate.deflate("\"#{PROBE}\"", 9)].pack("m0")
      pre, suf = out.split(b64, -1)
      buf.byte(3).str(pre).str(suf).varint(2)
    else
      pre, suf = probe_wrap(step)
      buf.wrap(pre, suf, code.include?("e[") ? F_E : 0)
    end
  when "Zig"
    if code.include?("Deflate")
      out = eval_step(step, PROBE)
      b91 = b91_encode(Zlib::Deflate.deflate(PROBE, 9), B91Q)
      pre, suf = out.split(b91, -1)
      raise "#{name} B91Q split failed!" unless pre && suf && out.split(b91, -1).size == 2
      buf.byte(3).str(pre).str(suf).varint(4)
    else
      pre, suf = probe_wrap(step)
      buf.wrap(pre, suf, code.include?("e[") ? F_E : 0)
    end
  when "VLang"
    if code.include?("Deflate")
      out = eval_step(step, PROBE)
      b64 = [Zlib::Deflate.deflate(PROBE, 9)].pack("m0")
      pre, suf = out.split(b64, -1)
      buf.byte(3).str(pre).str(suf).varint(0)
    else
      pre, suf = probe_wrap(step)
      buf.wrap(pre, suf, code.include?("e[") ? F_E : 0)
    end

  # --- Dedicated SPECIAL opcodes ---
  when "Rockstar"
    buf.byte(4).varint(0).varint(0).str("let q be 34\nburn q\nlet z be 10\nburn z\nshout ").str("").str("").str("").str(" + ").str('"').str("\n").str("\"\n").str("q").str("z")
  when "RISCVAsm"
    out = eval_step(step, PROBE)
    p1, rest = out.split(PROBE.bytesize.to_s, 2)
    p2, _ = rest.split(".ascii \"#{PROBE}\"", 2)
    buf.byte(5).str(p1).str(p2)
  when "REXXLang"
    buf.byte(6).varint(16000).varint(0).str("").str("").str("call charout , '").str("'\n").str("call charout , d2c(10)\n").str("")
  when "RcLang"
    buf.byte(6).varint(1000).varint(3).str("").str("").str("echo -n '").str("'\n").str("echo '").str("")
  when "RatforLang"
    buf.byte(8).str("subroutine p(s)\ncharacter*(*) s\nwrite(*,'(a)',advance='no') s\nend\n")
      .str("call p('").str("call p(char(10))").str("subroutine s").str("\nend\n").str("call s")
  when "QBE"
    pre, suf = probe_chunk_ends(step, 'b "', '"')
    buf.byte(9).str(pre).str(suf)
  when "Pyth"
    buf.byte(4).varint(0).varint(0).str("ps[").str("").str("").str("").str("").str('"').str(")").str("\"\n\\").str("N").str("b").str("\\\\")
  when "Pascal"
    buf.byte(4).varint(120).varint(0).str("begin\n").str("write(").str(");").str("\n").str("+").str("'").str("\nend.\n").str("'\n\t").str("''''").str("#10").str("#9")
  when "Oberon"
    buf.byte(12).str("MODULE QR;IMPORT Out;\n").str("PROCEDURE P").str(";BEGIN\n").str("\nEND P").str("\nBEGIN\n").str("\nEND QR.\n")
      .str("Out.Char(22X);").str("Out.Char(9X);").str('Out.String("').str("Out.Ln;")
  when "Murex"
    buf.byte(13).str("';tout str \"'\";tout str '").str("';tout str '{';tout str '").str("tout str '")
  when "MUMPS"
    buf.byte(4).varint(12000).varint(1).str("QRMUMPS\n U 0:NOWRAP\n").str(" W ").str("\n").str("").str(",").str('"').str(" Q\n").str("\n\t").str("!").str("$C(9)")
  when "Modula2"
    buf.byte(15).str("MODULE Q;IMPORT StrIO;BEGIN ").str("StrIO.WriteString(").str("END Q.")
  when "MMIX"
    buf.byte(16)
      .str(" LOC #100\nMain GETA $255,S\n TRAP 0,Fputs,StdOut\n SET $255,0\n TRAP 0,Halt,0\nS BYTE ")
      .str("[\\x20\\x21\\x23-\\x7e]{1,100000}|.")
      .str("\"\n").str("").str("").str('"').str('"').str("\n BYTE ").str(",0\n")
  when "MiniScript" then buf.byte(17)
  when "MaximaLang"
    buf.byte(18).str('linel:99999;printf(true,sconcat(ascii(126),"a"),sconcat(').str("ascii(34)").str("ascii(10)").str("));quit();")
  when "M4"
    buf.byte(19).str("<@,@>,<%,%>,<#,#>,<[ ,]>,<{,}>".gsub(" ", ""))
  when "Lua"        then buf.byte(20)
  when "Lobster"    then buf.byte(21)
  when "LLVMAsm"
    buf.byte(22).str("x i8]c\"").str("\\00\"declare i32@puts(ptr)define i32@main(){call i32@puts(ptr@s)ret i32 0}")
  when "Koka"
    buf.byte(23).str("fun main(){print(r").str(")}").str("##").varint(0)
  when "Gluon"
    buf.byte(23).str("let io = import! std.io\nio.print r").str("\n").str("###").varint(1)
  when "Kipple"
    buf.byte(16).str("").str("[\\x00-\\x09\\x0b-\\x21\\x23-\\x5a\\x5e-\\x7f]+|.").str("\n\"[\\]").str("").str(">i").str('i<"').str('"').str(" ").str(" (i i>o)")
  when "K"      then buf.byte(25)
  when "Hope"
    buf.byte(26).str('write "').str("\";\n").str("").str("").varint(94).varint(1)
  when "HOC"
    buf.byte(26).str('print "').str('"').str("\n").str("\n").varint(95).varint(0)
  when "GPortugol"
    buf.byte(27).str("algoritmo A;in\u00edcio ")
  when "Gosu"
    buf.byte(28).str("System.out.write(195);System.out.write(173);").str('System.out.print(("')
  when "Golo"
    buf.byte(16).str("module QR function main=|a|{foreach s in array[").str(".{1,15000};|.+").str("").str("").str("").str('"""').str('"""').str(",").str("]{print(s)}}")
  when "GriLang"
    buf.map_wrap('show "', "\"\n", [["\n", "\"\nshow \""]], F_CHOMP, 0)
  when "GNUAPL" then buf.byte(31)
  when "GeneratorScriptingLanguage"
    buf.byte(32).str(".template 1\n.bs = string.substr(\"\\\\\", 0, 1)\n").str(".s = \"\"\n$(s:no)").str(".s = ").str("\n.s += ").str("\n.endtemplate")
  when "FishEsolang" then buf.byte(33)
  when "EC"
    buf.byte(34).str('class QR:Application{void f(String const s,int n){for(Print(s);n;n--)Print("\\\\");}void Main(){')
      .str("} }").str('",').str(');f("').varint(15 * 255)
  when "Yabasic"
    buf.byte(34).str('sub f(s$,n)?s$;:for i=1to n?"\\\\";next end sub:f("')
      .str('",0)').str('",').str('):f("').varint(0)
  when "Chapel_Chef"
    pre, suf = probe_wrap(step)
    raise "Chapel_Chef probe mismatch" unless pre.end_with?("'''") && suf.start_with?("'''")
    buf.byte(35).str(pre[0..-4]).str(suf[3..])
  when "C"
    buf.chunk("#include<stdio.h>\nint main(){", "return 0;}\n", 'fputs("', '",stdout);', "", 15000, F_E)
  when "BefungeLang" then buf.byte(37)
  when "ATS"
    buf.byte(39).str("implement main0()=(")
  when "ArnoldC"
    buf.byte(40).str("IT'S SHOWTIME\n").str("DO IT NOW m").str("YOU HAVE BEEN TERMINATED\n").str("LISTEN TO ME VERY CAREFULLY m").str('TALK TO THE HAND "').str("\nHASTA LA VISTA, BABY\n")
  when "ARM64Asm"
    buf.byte(16)
      .str(".global _start\n.text\n_start:\n mov x0, #1\n ldr x1, =msg\n ldr x2, =len\n mov x8, #64\n svc #0\n mov x0, #0\n mov x8, #93\n svc #0\n.data\nmsg:\n")
      .str("[\\x20\\x21\\x23-\\x5b\\x5d-\\x7e]{1,4000}|.")
      .str("\"\\\n").str(".byte ").str("").str('.ascii "').str('"').str("\n").str("\n.equ len, . - msg\n")
  when "ALGOL60"
    buf.byte(42).str(".{0,999}[\\x00-\\x5b\\x5d-\\x7f]|.{1,1000}").str('outstring(1,"').str("begin\n").str("procedure p").str(";begin\n").str("\nend;")
  when "Aplus"
    buf.byte(43).str("$mode ascii\nx:=").str("\nx:=x,").str("\nx\nsys.exit 0")
  when "Asm6502"
    r = Random.new(42)
    rich = Array.new(4000) { (32 + r.rand(90)).chr }.join
    hdr = eval_step(step, rich).split("dict0:\n", 2)[0] + "dict0:\n"
    buf.byte(44).str(hdr)
  when "Z80Asm"
    hdr = eval_step(step, PROBE).split(" db \"#{PROBE}\"", 2)[0]
    buf.byte(16).str(hdr).str("[\\x20\\x21\\x23-\\x7e]{1,2000}|.").str("\"\n").str(" db ").str("").str(' db "').str('"').str("\n").str("\n db 0\n")
  when "Uxntal"
    up = "pre\nbase64.decode('QUJDRQ==')suf"
    hdr = eval_step(step, up).split("@pre\n", 2)[0] + "@pre\n"
    buf.byte(56).str(hdr)
  when "VisualBasic_WebAssemblyBinary_WebAssemblyText_Whitespace"
    p2_probe = PROBE + "Q" * 1000
    out = eval_step(step, p2_probe)
    v1 = (p2_probe.bytesize * 16 + 3).to_s
    p1, rest1 = out.split(v1, -1)
    raise "VB probe p1 mismatch" unless p1 && rest1 && out.split(v1, -1).size == 2
    m = rest1.match(/\(8\*c-(\d+)\)/)
    raise "VB probe c2 mismatch" unless m
    c2 = m[1].to_i - p2_probe.bytesize
    p2, rest2 = rest1.split(m[1], -1)
    raise "VB probe p2 mismatch" unless p2 && rest2 && rest1.split(m[1], -1).size == 2
    p3, p4 = rest2.split(p2_probe, -1)
    raise "VB probe p3/p4 mismatch" unless p3 && p4 && rest2.split(p2_probe, -1).size == 2
    buf.byte(45).str(p1).str(p2).str(p3).str(p4).varint(c2)
  when "UCBLogo"
    buf.byte(47).str("CHAR ").str("FIRST [|").str("TYPE (WORD ").str(" BYE")
  when "Taxi"
    buf.byte(48)
      .str("34 is waiting at Starchild Numerology.")
      .str(" is waiting at the Writer's Depot.")
      .str("Go to Writer's Depot: west 1st left, 2nd right, 1st left, 2nd left.")
      .str("Go to Starchild Numerology: south 1st left, 2nd right. Pickup a passenger going to Charboil Grill. Go to Charboil Grill: east 1st left. Pickup a passenger going to the Post Office. Go to Go More: east. Go to Writer's Depot: west 1st right. Go to the Post Office: north 1st right, 2nd right, 1st left.")
      .str("Pickup a passenger going to the Post Office. Go to the Post Office: north 1st right, 2nd right, 1st left.")
      .str(" Go to Writer's Depot: south 1st right, 1st left, 2nd left.")
      .str("Go to the Taxi Garage: north 1st right, 1st left, 1st right.")
  when "SNOBOL4"
    buf.byte(49).str("  OUTPUT = ''").str("  S = ''\n").str("  S = S ").str("\n  OUTPUT = S").str("\nEND\n")
  when "Simula"
    buf.byte(50).str("OutChar(Char(9));").str('OutText("').str("OutImage;").str("Begin\n").str("Procedure P").str(";Begin\n").str("\nEnd;").str("\nSysOut.Image:-Blanks(20000);\n")
  when "SedLang"
    buf.map_wrap("1d;s/.//\n#", "\n", [["\n", "\n#"]], F_CHOMP, 0)
  when "ScilabLang"
    buf.byte(6).varint(1000).varint(1).str("").str("").str('mprintf("%s","').str("\");\n").str("mprintf(\"\\n\");\n").str("quit\n")
  when "Scheme"
    _, suf = probe_wrap(step)
    buf.byte(53).str(suf)
  when "RubyLang", "Ruby_"
    pre, suf = probe_wrap(step)
    buf.map_wrap(pre, suf, [["@", "@A"], ["\\", "@D"], ["'", "@Q"]])
  else
    raise "Unmapped CodeGen class: #{name} (code=#{code[0, 120].inspect})"
  end
end

# Token-level Java minifier (preserves strings, chars, semantics; wraps lines at ~180 chars)
def minify_java(src)
  tokens = []
  i = 0
  n = src.length
  while i < n
    c = src[i]
    if c =~ /\s/
      i += 1
    elsif c == "/" && src[i + 1] == "/"
      i += 1 while i < n && src[i] != "\n"
    elsif c == '"' || c == "'"
      q = c
      j = i + 1
      while j < n
        if src[j] == "\\"
          j += 2
        elsif src[j] == q
          j += 1
          break
        else
          j += 1
        end
      end
      tokens << [:str, src[i...j]]
      i = j
    elsif c =~ /[A-Za-z0-9_$]/
      j = i + 1
      j += 1 while j < n && src[j] =~ /[A-Za-z0-9_$]/
      tokens << [:id, src[i...j]]
      i = j
    elsif %w[++ -- += -= *= /= |= &= <= >= == != && || << >> ..].include?(src[i, 2])
      tokens << [:sym, src[i, 2]]
      i += 2
    else
      tokens << [:sym, c]
      i += 1
    end
  end

  out = +""
  line_len = 0
  tokens.each_with_index do |(kind, tok), idx|
    if idx > 0
      pk, pt = tokens[idx - 1]
      need_sp = (pk == :id && kind == :id) || (pt == "+" && tok == "+") || (pt == "-" && tok == "-")
      if need_sp
        out << " "
        line_len += 1
      elsif line_len > 180 && ";{}".include?(pt) && kind != :sym
        out << "\n"
        line_len = 0
      end
    end
    out << tok
    line_len += tok.length
  end
  out << "\n"
end

# Determine step order: AspectJ is the entry point; run all other steps in GenSteps order starting after AspectJ
aj_idx = GenSteps.index { |st| st.name == "AspectJ" }
raise "AspectJ not found in GenSteps!" unless aj_idx

ordered = (GenSteps[(aj_idx + 1)..] + GenSteps[0...aj_idx]).reject { |st| st.code.nil? }
$stderr.puts "Compiling #{ordered.size} steps: #{ordered.first.name} -> ... -> #{ordered.last.name}"

buf = BinBuf.new
buf.varint(ordered.size)
ordered.each { |st| compile_step(buf, st) }

raw_eng = File.read(ENGINE_PATH, encoding: "UTF-8")
min_eng = minify_java(raw_eng)

# Pack [min_eng, step_count, step_specs...] into a single zlib level-9 Base91 blob.
full_buf = BinBuf.new
full_buf.str(min_eng)
raw_blob = full_buf.bytes + buf.bytes
z_blob   = Zlib::Deflate.deflate(raw_blob, 9)
b91_blob = b91_encode(z_blob)

b_chunks = b91_blob.scan(/.{1,12000}/)

aj_src = +""
aj_src << "import java.io.*;import java.util.*;import java.util.regex.*;import java.util.zip.*;\n"
aj_src << "public class QR{public static void main(String[]a){}}\n"
aj_src << "aspect Q{\n"
aj_src << "static String[]B={\n"
aj_src << b_chunks.map { |c| %("#{c}") }.join(",\n")
aj_src << "\n};\n"
aj_src << min_eng

raise "QR.aj contains forbidden ':}' for Arturo!" if aj_src.include?(":}")
raise "QR.aj contains non-printable byte!" if aj_src =~ /[^\n\x20-\x7e]/

File.binwrite(OUT_AJ_PATH, aj_src)
z_aj = Zlib::Deflate.deflate(aj_src.b, 9)
$stderr.puts format(
  "Wrote %s: total=%d B, zlib(QR.aj)=%d B (blob raw=%d B -> b91=%d B; eng min=%d B)",
  OUT_AJ_PATH, aj_src.bytesize, z_aj.bytesize, raw_blob.bytesize, b91_blob.bytesize, min_eng.bytesize
)

# Hard < 64,000 B ROM guard for the three 16-bit 64 KiB VM targets (Asm6502, Z80Asm, Uxntal)
ROM_GUARD = (ENV["ROM_GUARD"] || 64000).to_i
rom_limits = { "Asm6502" => 65012, "Z80Asm" => 64991, "Uxntal" => 65280 }
cur_rom = aj_src.dup
ordered[0, 30].each do |st|
  st.check.call(cur_rom)
  nxt_rom = eval_step(st, cur_rom)
  if rom_limits.key?(st.name)
    bin_sz = nil
    case st.name
    when "Asm6502"
      raise "Asm6502 ROM guard requires 'xa' on PATH (run inside the Ubuntu 26.04 Docker image or install xa65)" unless system("command -v xa >/dev/null 2>&1")
      Dir.mktmpdir do |d|
        File.binwrite("#{d}/QR.s", nxt_rom.encode("UTF-8").b)
        raise "xa failed to assemble Asm6502 ROM!" unless system("xa -o #{d}/QR.bin #{d}/QR.s >/dev/null 2>&1")
        bin_sz = File.size("#{d}/QR.bin")
      end
    when "Z80Asm"
      raise "Z80Asm ROM guard requires 'z80asm' on PATH (run inside the Ubuntu 26.04 Docker image or install z80asm)" unless system("command -v z80asm >/dev/null 2>&1")
      Dir.mktmpdir do |d|
        File.binwrite("#{d}/QR.z80", nxt_rom.encode("UTF-8").b)
        raise "z80asm failed to assemble Z80Asm ROM!" unless system("z80asm -o #{d}/qr.com #{d}/QR.z80 >/dev/null 2>&1")
        bin_sz = File.size("#{d}/qr.com")
      end
    when "Uxntal"
      raise "Uxntal ROM guard requires 'uxnasm' on PATH (run inside the Ubuntu 26.04 Docker image or install uxnasm)" unless system("command -v uxnasm >/dev/null 2>&1")
      Dir.mktmpdir do |d|
        File.binwrite("#{d}/QR.tal", nxt_rom.encode("UTF-8").b)
        raise "uxnasm failed to assemble Uxntal ROM!" unless system("uxnasm #{d}/QR.tal #{d}/QR.rom >/dev/null 2>&1")
        bin_sz = File.size("#{d}/QR.rom")
      end
    end
    limit = rom_limits[st.name]
    $stderr.puts format("ROM guard %-8s: %d B / %d B (guard < %d B, spare=%d B)", st.name, bin_sz, limit, ROM_GUARD, limit - bin_sz)
    raise "#{st.name} ROM GUARD FAILED: #{bin_sz} B >= #{ROM_GUARD} B!" if bin_sz >= ROM_GUARD
  end
  cur_rom = nxt_rom
end
