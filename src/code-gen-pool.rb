# Optional staging pool loaded by src/code-gen.rb when ENV["ALL"] is set.
#
# Languages originally prototyped here by Yusuke Endoh (mame) that are now
# active in src/code-gen.rb:
#   Zig, Elvish, Hare, Maxima (MaximaLang), CLIPS, nesC, Racket, newLISP.
# They have been removed from this file so ENV["ALL"]=1 does not reopen or
# clobber active CodeGen definitions.

original_list_size = CodeGen::List.size

#class Nim_NVSPL2 < CodeGen
#  After = Nim
#  Obsoletes = Nim
#  File = ["QR.nim", "QR.nvspl2"]
#  Cmd = ["nim c QR.nim && ./QR > OUTFILE", "ruby vendor/nvspl2.rb QR.nvspl2 > OUTFILE"]
#  Apt = ["nim", nil]
#  Code = %q(%((for i, c in#{E[PREV]}:echo ",",int(c),"CO");echo "Q"))
#end

# Snek: embedded system programming language (Python-like)
# Note: has very limited string length (~256 bytes), cannot handle quine relay output.
#class Snek < CodeGen
#  After = Scilab_Sed_Shakespeare_SLang
#  File = "QR.snek"
#  Cmd = "snek QR.snek > OUTFILE"
#  Apt = "snek-bin"
#  Code = %q(%(print#{E[PREV]},end=""))
#end

# Excluded / unsuitable candidates (upstream mame notes + fork notes):
# - Elm: no stdout I/O (web-only)
# - Coq/Rocq, Agda: proof assistants without native standalone stdout I/O
#   (would require foreign-language extraction/FFI escapes to OCaml or GHC)
# - Futhark: GPU-oriented, outputs arrays rather than arbitrary strings
# - CafeOBJ: algebraic specification, not general-purpose
# - goo: appears abandoned, hard to script
# - golf: command not found / different purpose
# - chuck: audio programming DSL
# - basic256, brandy (BBC BASIC): banner/GUI issues
# - BWBASIC, Wodan58/joy0 (unpatched): banner/timing output to stdout
# - Aribas: string literals have no escapes, so a " cannot be written
#   (Note: Numbat >= 1.24.0 supports standard string escapes and is in code-gen.rb.)

CodeGen::List.slice!(original_list_size..-1).each do |s|
  i = CodeGen::List.find_index(s::After)
  CodeGen::List.insert(i, s)
  [*s::Obsoletes].each {|s_| CodeGen::List.delete(s_) } if defined?(s::Obsoletes)
end
