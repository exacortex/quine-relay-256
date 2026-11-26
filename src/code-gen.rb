# A source for generating Quine Relay

GenStep = Struct.new(:name, :code, :run_steps, :check)
RunStep = Struct.new(:name, :src, :cmd_make, :cmd_raw, :backup, :apt)

# properly nested delimiters
PARENS   = /\A(?<b>[^()]*+(?:\(\g<b>\)[^()]*+)*+)\z/
BRACKETS = /\A(?<b>[^\[\]]*+(?:\[\g<b>\][^\[\]]*+)*+)\z/

# A class that generates Ruby code that generates a code (in a language X) that prints PREV.
class CodeGen
  # File = source file name of X
  # Cmd = command for execution/compilation
  # Apt = ubuntu package name of the interpreter/compiler of X

  List = []
  def self.inherited(c)
    List << c
  end

  def self.gen_step
    gen = new
    GenStep[name, gen.code, run_steps, gen.method(:check).to_proc]
  end

  def code
    self.class::Code
  end

  # check if PREV satisfies the assumption of the CodeGen
  def check(prev)
  end

  # The same escaping as e[] of GenPrologue, for check
  def escape(s)
    s.gsub(/[\\"]/) { "\\" + $& }.gsub("\n", "\\n")
  end

  def self.run_steps
    a = []
    a << (defined?(self::Name) ? [*self::Name] : self.to_s.split("_"))
    a << [*self::File]
    a << [*self::Cmd]
    a << (defined?(self::Backup) ? [*self::Backup] : [*self::Cmd].map { nil })
    a << [*self::Apt]
    a.transpose.map do |name, src, cmd_make, backup, apt|
      cmd_raw = cmd_make
      cmd_raw = cmd_raw.gsub("$(SCHEME)", "guile")
      cmd_raw = cmd_raw.gsub("$(JAVASCRIPT)", "nodejs")
      cmd_raw = cmd_raw.gsub("$(CC)", "gcc")
      cmd_raw = cmd_raw.gsub("$(CXX)", "g++")
      cmd_raw = cmd_raw.gsub("$(GBS)", "gbs3")
      cmd_raw = cmd_raw.gsub("$$", "$")
      RunStep[name, src, cmd_make, cmd_raw, backup, apt]
    end
  end
end

# Common part
GenPrologue = <<-'END'.lines.map {|l| l.strip }.join
  B=92.chr;
  g=32.chr;
  N=10.chr;
  n=0;
  e=->s{Q[Q[s,B],?"].gsub(N,B+?n)};
  E=->s{'("'+e[s]+'")'};
  d=->s,t=?"{s.gsub(t){t+t}};
  def f(s,n)s.gsub(/.{1,#{n*255}}/m){yield$S=E[$s=$&]}end;
  Q=->s,t=?${s.gsub(t){B+$&}};
  R=";return 0;";
  V=->s,a,z{s.gsub(/(#{B*4})+/){a+"#{$&.size/2}"+z}};
  C=%w(System.Console Write);
  $C=C*?.;
  $D="program QR";
  $L="public static";
  $W="s.WriteByte";
  rp=->s,r{
    v="";
    [r.inject(s){|s,j|
      o={};
      m=n=0;
      s.size.times{|i|
        o[f=s[i,2]]||=0;
        c=o[f]+=1;
        m<c&&(m=c;n=f)
      };
      v=n+v;
      s.gsub(n,(j%256).chr)
    },v]
  };
  b91q=->s{
    al=(33..126).reject{|c|c==34||c==39||c==92}.map(&:chr);
    o=+"";b=n=0;
    s.each_byte{|x|b|=x<<n;n+=8;if n>13;v=b&8191;if v>88;b>>=13;n-=13;else;v=b&16383;b>>=14;n-=14;end;o<<al[v%91]<<al[v/91];end};
    if n>0;o<<al[b%91];o<<al[b/91] if n>7||b>90;end;
    o
  };
END
class AspectCpp < CodeGen
  Name = "AspectC++"
  File = "QR.cc"
  Cmd = "ag++ --keywords -o QR QR.cc && ./QR > OUTFILE"
  Apt = "aspectc++"
  # the text is printed by a real aspect (advice on main), so plain g++ can't build this file
  # C++11 raw string: no escaping, so it adds no backslashes for the layers above to double.
  # "} }" not "}}": Mustache (step 181) hides its YAML in a {{! }} comment
  Code = %q(%(#include<cstdio>\naspect Q{advice execution("int main()"):before(){fputs(R"Q(#{PREV})Q",stdout);} };int main(){}))

  def check(prev)
    raise if prev.include?(')Q"') # it closes the raw string
    raise if prev.include?("\r")  # the compiler may turn CR LF into LF inside the raw string
  end
end

class Arturo < CodeGen
  Name = "Arturo"
  File = "QR.art"
  Cmd = "arturo QR.art < /dev/null > OUTFILE"
  Apt = [nil]
  Code = %q((p5am={?@=>"@0",B=>"@1",?"=>"@2"};"s: {:"+(PREV).gsub(Regexp.union(*p5am.keys),p5am)+":}\ns: replace s {:@1:} to :string to :char 92\ns: replace s {:@2:} to :string to :char 34\ns: replace s {:@0:} {:@:}\nprints s\n"))
  def check(prev)
    raise "Arturo: payload holds :}" if prev.include?(":}")
    raise "Arturo: non-printable byte" if prev =~ /[^\n\x20-\x7e]/
  end
end

class ArnoldC < CodeGen
  Name = "ArnoldC"
  File = "QR.arnoldc"
  Cmd = "rm -f QR.class && java -jar /opt/ArnoldC.jar QR.arnoldc && java QR > OUTFILE && rm -f QR.class"
  Apt = "default-jdk-headless"
  Code = %q((b16g=(PREV).lines.map{|b16e|"TALK TO THE HAND \""+b16e.chomp+"\x22"}.each_slice(2000).to_a;"IT\x27S SHOWTIME\n"+b16g.each_index.map{|b16i|"DO IT NOW m#{b16i}\n"}*""+"YOU HAVE BEEN TERMINATED\n"+b16g.each_with_index.map{|b16s,b16i|"LISTEN TO ME VERY CAREFULLY m#{b16i}\n"+b16s*N+"\nHASTA LA VISTA, BABY\n"}*""))
  def check(prev)
    raise "ArnoldC: non-ASCII" unless prev.ascii_only?
    raise "ArnoldC: quote, backslash, or CR" if prev =~ /["\\\r]/
  end
end

class ARM64Asm < CodeGen
  Name = "ARM64 asm"
  File = "QR.arm64.s"
  Cmd = "rm -f QR && aarch64-linux-gnu-gcc -nostdlib -static -o QR QR.arm64.s && qemu-aarch64 ./QR > OUTFILE && rm -f QR"
  Apt = [["gcc-aarch64-linux-gnu", "qemu-user"]]
  Code = %q(".global _start\n.text\n_start:\n mov x0, #1\n ldr x1, =msg\n ldr x2, =len\n mov x8, #64\n svc #0\n mov x0, #0\n mov x8, #93\n svc #0\n.data\nmsg:\n"+(PREV).scan(/[\x20\x21\x23-\x5b\x5d-\x7e]{1,4000}|./m).map{|b18n|b18n=="\x22"||b18n==B||b18n==N ? ".byte #{b18n.ord}" : %(.ascii "#{b18n}")}*N+"\n.equ len, . - msg\n")
  def check(prev)
    raise "ARM64 asm: bad byte" if !prev.ascii_only? || prev =~ /[\x00-\x09\x0b-\x1f\x7f]/
  end
end

class Anko_Ante < CodeGen
  Name = ["Anko", "Ante"]
  File = ["QR.ank", "QR.ante"]
  Cmd = ["anko QR.ank > OUTFILE", "ruby vendor/ante.rb QR.ante > OUTFILE"]
  Apt = [nil, nil]
  Code = %q(%(fmt=import("fmt")\nstrings=import("strings")\ns=`#{(PREV).gsub("`",%(`+"`"+`))}`\nD=toChar(9830)\nb=D+"2"+toChar(9824)\nc=b+"8"+toChar(9829)\nm={}\nfor i=0;i<128;i++{m[toChar(i)]=toChar(50+toInt(i/64))+c+toChar(50+toInt(i/8)%8)+c+toChar(50+i%8)+b+"J"+D}\no=[]\nfor ch in strings.Split(s,""){o+=m[ch]}\nfmt.Print(strings.Join(o,""))\n))
  def check(prev)
    raise "Anko > Ante: non-ASCII" unless prev.ascii_only?
  end
end

class ALGOL68Lang < CodeGen
  Name = "ALGOL 68"
  File = "QR.a68"
  Cmd = "a68g --heap 512M QR.a68 > OUTFILE"
  Apt = "algol68g"
  Code = %q(((PREV).scan(/.{1,1000}/m).map{|m00a|"print(\""+d[m00a].gsub(N,'"+REPR 10+"')+"\")"}*(";"+N)))
  def check(prev)
    raise "ALGOL 68: non-ASCII" unless prev.ascii_only?
  end
end

class ALGOL60 < CodeGen
  Name = "ALGOL 60"
  File = "QR.alg"
  Cmd = "marst QR.alg -o QR.alg.c && gcc QR.alg.c -lalgol -lm -o QR && ./QR > OUTFILE && rm -f QR QR.alg.c"
  Apt = [nil]
  Code = %q((nap=(PREV).scan(/.{0,999}[\x00-\x5b\x5d-\x7f]|.{1,1000}/m).map{|nau|"outstring(1,\x22"+nau.gsub(/[\x22\\\\\n\t]/){{"\x22"=>B+"\x22",B=>B+B,N=>B+"n","\t"=>B+"t"}[$&]}+"\x22);"};nag=nap.each_slice(400).to_a;"begin"+N+nag.each_with_index.map{|nax,nai|"procedure p#{nai};begin"+N+nax*N+N+"end;"}*N+N+(0...nag.size).map{|nai|"p#{nai};"}.each_slice(20).map(&:join)*N+N+"end"+N))

  def check(prev)
    raise unless prev.ascii_only?
    raise if prev.include?("\r")
  end
end

class AFNIX_Aheui < CodeGen
  File = ["QR.als", "QR.aheui"]
  Cmd = ["LANG=C LD_LIBRARY_PATH=/usr/lib/afnix axi QR.als > OUTFILE", "ruby vendor/aheui.rb QR.aheui > OUTFILE"]
  Apt = ["afnix", nil]
  def code
    <<-'END'.lines.map {|l| l.strip }.join
      %(
        trans o(interp:get-output-stream)\n
        o:set-encoding-mode"utf-8"\n
        trans f(v n){
          print(Character(+ 45056(+(* 64 n)v)))
        }\n
        trans D(n){
          if(< n 4){
            f(+(* 6 n)9)48
          }{
            if(n:odd-p){
              D(- n 3)\n
              f 27 48\n
              f 36 11
            }{
              D(/ n 2)\n
              f 21 48\n
              f 48 20
            }
          }
        }\n
        trans S(Buffer"#{e[PREV]}")\n
        while(>(S:length)0){
          trans c(S:read)\n
          D(c:to-integer)\n
          f 35 39
        }\n
        f 24 149
      )
    END
  end

  def check(prev)
    raise unless prev.ascii_only? # the AFNIX Buffer is read as characters
  end
end

class Ada < CodeGen
  File = "qr.adb"
  Cmd = "gnatmake qr.adb && ./qr > OUTFILE"
  Apt = "gnat"
  Code = %q(%(with Text_Io;procedure qr is begin\n#{PREV.scan(/.{1,15000}/m).map{|c|%(Text_Io.Put("#{d[c].gsub(N,'"&ASCII.LF&"')}");)}*N}\nend;\n))

  def check(prev)
    # gnat allows up to 32766 characters per line: the worst piece is 15000 chars plus its doubled " and &ASCII.LF&
    prev.scan(/.{1,15000}/m).each { |c| raise if c.size + c.count(?") + c.count("\n") * 11 + 20 > 32766 }
  end
end

class Aplus < CodeGen
  Name = "A+"
  File = "QR.aplus.a"
  Cmd = "a+ QR.aplus.a > OUTFILE 2> /dev/null < /dev/null"
  Apt = [nil]
  Code = %q((a7xs=(PREV).split(/(#{N})/).reject(&:empty?).flat_map{|a7xc|a7xc==N ? [34.chr+B+"n"+34.chr] : a7xc.scan(/.{1,30000}/).map{|a7xd|39.chr+a7xd.gsub(39.chr,39.chr*2)+39.chr}};"$mode ascii"+N+"x:="+a7xs*(N+"x:=x,")+N+"x"+N+"sys.exit 0"))
  def check(prev)
    raise "A+: non-printable byte" if prev =~ /[\x00-\x08\x0b-\x1f\x7f-\xff]/n
  end
end

class Asm6502 < CodeGen
  Name = "6502 asm"
  File = "QR.s65"
  Cmd = "xa -o QR.o65 QR.s65 && sim65 QR.o65 > OUTFILE && rm -f QR.o65"
  Apt = [["xa65", "cc65"]]
  Code = %q((b18t,b18w=rp[PREV,[*127..255,*1..9,*11..31]];b18p=b18w.scan(/../m).reverse.insert(138,"\0\0");b18e=b18p.map{|b18x|b18x.getbyte(0)};b18f=b18p.map{|b18x|b18x.getbyte(1)};b18b=->bs{o=[];cl=0;i=0;n=bs.size;ok=->u{u>=32&&u<=126&&u!=34&&u!=92};while i<n;u=bs[i];if ok[u]&&i+1<n&&ok[bs[i+1]];j=i+2;j+=1 while j<n&&j-i<120&&ok[bs[j]];tok=34.chr+bs[i...j].pack("C*")+34.chr;i=j;else;tok=u.to_s;i+=1;end;if cl>0&&cl+1+tok.bytesize>180;o<<N;cl=0;end;o<<(cl==0?" .byt ":",");cl+=(cl==0?6:1)+tok.bytesize;o<<tok;end;o*""};" .byt \"sim65\",2,0,2,$00,$02,$00,$02\n* = $0200\n ldx \#$ff\n txs\n lda \#$80\n sta $20\n lda #0\n sta $21\n sta $23\n sta 4\n lda #1\n sta $22\n lda #<msg\n sta 0\n lda #>msg\n sta 1\nloop:\n ldy #0\n lda (0),y\n beq done\n jsr emit\n inc 0\n bne loop\n inc 1\n jmp loop\ndone:\n jsr flush\n lda #0\n jmp $fff9\nflush:\n lda 4\n beq flret\n pha\n lda \#$20\n sta 2\n lda #0\n sta 3\n sta 4\n tax\n pla\n jsr $fff7\nflret:\n rts\nemit:\n cmp #10\n beq lit\n cmp #32\n bcc pair_lo\n cmp #127\n bcs pair_hi\nlit:\n ldx 4\n sta $80,x\n inx\n stx 4\n cpx #128\n beq flush\n rts\npair_lo:\n clc\n adc #128\n bne pair_go\npair_hi:\n sec\n sbc #127\npair_go:\n tax\n lda dict1,x\n pha\n lda dict0,x\n jsr emit\n pla\n jmp emit\ndict0:\n"+b18b[b18e]+"\ndict1:\n"+b18b[b18f]+"\nmsg:\n"+b18b[b18t.bytes+[0]]+N))
  def check(prev)
    raise "6502 asm: unsupported control or non-ASCII byte" if prev =~ /[^\n\x20-\x7e]/
  end
end

class Zsh < CodeGen
  Name = "zsh"
  File = "QR.zsh"
  Cmd = "zsh QR.zsh > OUTFILE"
  Apt = "zsh"
  Code = %q("print -rn -- '#{(PREV).gsub(?',%('"'"'))}'")
end

class Zoem < CodeGen
  File = "QR.azm"
  Cmd = "zoem -i QR.azm > OUTFILE"
  Apt = "zoem"
  Code = %q("\\\\write{-}{txt}{#{Q[PREV,/[\\\\{}]/]}}#{N}")
end

class Zig < CodeGen
  Name = "Zig"
  File = "QR.zig"
  Cmd = "zig run QR.zig > OUTFILE"
  Apt = [nil]
  Code = %q((require"zlib";%(const s=@import("std");pub fn main()!void{const b="#{b91q[Object.const_get("Zlib")::Deflate.deflate(PREV,9)]}";var t:[128]u8=undefined;var k:u8=0;for(33..127)|i|{if(i!=34 and i!=39 and i!=92){t[i]=k;k+=1;}}var d=try s.ArrayList(u8).initCapacity(s.heap.page_allocator,b.len);var v:i32=-1;var a:u32=0;var n:u5=0;for(b)|x|{const c:u32=t[x];if(v<0){v=@intCast(c);}else{v+=@intCast(c*91);a|=@as(u32,@intCast(v))<<n;n+=if((v&8191)>88)13 else 14;while(true){try d.append(@truncate(a));a>>=8;n-=8;if(n<=7)break;}v=-1;}}if(v>=0)try d.append(@truncate(a|(@as(u32,@intCast(v))<<n)));var f=s.io.fixedBufferStream(d.items);var w=s.io.bufferedWriter(s.io.getStdOut().writer());try s.compress.zlib.decompress(f.reader(),w.writer());try w.flush();})))
end

class Z80Asm < CodeGen
  Name = "Z80 asm"
  File = "QR.z80"
  Cmd = "z80asm QR.z80 -o qr.com && tnylpo -b qr.com < /dev/null > OUTFILE && rm -f qr.com"
  Apt = "z80asm"
  Code = %q(" org 0100h\n ld hl,msg\nloop:\n ld a,(hl)\n or a\n jr z,done\n push hl\n ld e,a\n ld c,6\n call 5\n pop hl\n inc hl\n jr loop\ndone:\n jp 0\nmsg:\n"+(PREV).scan(/[\x20\x21\x23-\x7e]{1,2000}|./m).map{|p13z|p13z==?"||p13z==N ? " db #{p13z.ord}" : " db \"#{p13z}\""}*N+"\n db 0\n")
  def check(prev)
    raise "Z80 asm: NUL or non-ASCII" if prev.include?("\0") || !prev.ascii_only?
    raise "Z80 asm: payload exceeds CP/M TPA (~64950 B)" if prev.bytesize > 64950
  end
end

class YSH < CodeGen
  Name = "YSH"
  File = "QR.ysh"
  Cmd = "ysh QR.ysh > OUTFILE"
  Apt = [nil]
  Code = %q(%(write --sep '' --end '' -- #{(PREV).scan(/.{1,32000}/m).map{|s|"r'"+s.gsub(?',%(' "'" r'))+"'"}.join(" ")}))
  def check(prev)
    raise if prev.include?("\0") || prev.include?("\r")
  end
end

class Yorick < CodeGen
  File = "QR.yorick"
  Cmd = "yorick -batch QR.yorick > OUTFILE"
  Apt = "yorick"
  Code = %q(%(write,format="%s",#{f(PREV,30){$S+"+\n"}}""))

  def check(prev)
    # yorick allows up to 16360 characters per line, and a chunk becomes ("...")+
    prev.scan(/.{1,#{ 30 * 255 }}/m) { raise if escape($&).size + 5 > 16360 }
  end
end

class Yeti < CodeGen
  File = "QR.yeti"
  Cmd = "yeti QR.yeti > OUTFILE"
  Apt = [nil]
  Code = %q((PREV).scan(/.{1,15000}/m).map{|b04c|"print"+E[b04c]}*";")

  def check(prev)
    prev.scan(/.{1,15000}/m) { raise if escape($&).bytesize > 65000 }
  end
end

class Yabasic < CodeGen
  File = "QR.yab"
  Cmd = "yabasic QR.yab > OUTFILE"
  Apt = "yabasic"
  def code
    <<-'END'.lines.map {|l| l.strip }.join
      %(
        sub f(s$,n)
          ?s$;:
          for i=1to n?"\\\\";
          next end sub:
        f("#{V[e[PREV],'",','):f("']}",0)
      )
    END
  end

  def check(prev)
    # yabasic allows up to 16383 characters per "..." literal
    escape(prev).split(/(?:\\\\)+/) { |s| raise if s.size + 2 > 16383 }
  end
end

class XSLT < CodeGen
  File = "QR.xslt"
  Cmd = "xsltproc QR.xslt > OUTFILE"
  Apt = "xsltproc"
  def code
    <<-'END'.lines.map {|l| l.strip }.join
      "
        <?xml-#{I="stylesheet"} type='text/xsl'href=''?>
        <#{I} version='1.0' xmlns='http://www.w3.org/1999/XSL/Transform'>
          <output method='text'/>
          <x xmlns='z:'><![CDATA[#{PREV}]]></x>
        </#{I}>
      "
    END
  end

  def check(prev)
    raise if prev.include?("]]>") # it closes the CDATA section
    raise if prev =~ /[\x00-\x08\x0b\x0c\x0e-\x1f]/ # XML 1.0 forbids it and CDATA cannot escape it
  end
end

class Wren < CodeGen
  Name = "Wren"
  File = "QR.wren"
  Cmd = "wren_cli QR.wren > OUTFILE"
  Apt = [nil]                # wren-cli 0.4.0 source build (one-line patch), see src/extra-installs/
  Code = %q(%(System.print("#{Q[e[PREV],"%"]}")))
  def check(prev)
    raise "Wren: non-printable byte" if prev =~ /[^\n\x20-\x7e]/
  end
end

class VisualBasic_WebAssemblyBinary_WebAssemblyText_Whitespace < CodeGen
  Name = ["Visual Basic", "WebAssembly (Binary format)", "WebAssembly (Text format)", "Whitespace"]
  File = ["qr_vb/QR.vb", "QR.wasm", "QR.wat", "QR.ws"]
  Cmd = [
    "DOTNET_NOLOGO=1 dotnet run --project qr_vb > OUTFILE",
    "$(WASI_RUNTIME) QR.wasm > OUTFILE",
    "wat2wasm QR.wat -o QR.wat.wasm && $(WASI_RUNTIME) QR.wat.wasm > OUTFILE",
    "ruby vendor/whitespace.rb QR.ws > OUTFILE"
  ]
  Apt = ["dotnet-sdk-10.0", "wabt", "wabt", nil]
  def code
    r = <<-'END'.lines.map {|l| l.strip }.join(?:)
      %(Module QR\nSub main()\nDim c,n:Dim s=#{C[0]}.openstandardoutput(),t={@@TBL@@}
          For Each d in"@@DATA1@@}@@DATA2@@~@@DATA3@@$@@DATA4@@"
            c=Asc(d)
            If c=36
              For c=0To 11
                #$W(If(c mod 3,Asc(#{s=PREV;s.size*16+3}.ToString("x8")(7-c*2\\3 xor 1)),92))
              Next
            Else
              n=(c>124)*(@@CONST1@@*c-#{s.size+@@CONST2@@})
              Do While n>127
                #$W(n mod 128+128)
                n\\=128
              Loop
              #$W(If(c<125,If((c-1)\\7-8,c-66*(c>65)*(c<91),t(c-57)),n))
            End If
          Next
          For Each c in"#{d[s].gsub N,'"& VbLf &"'}"
            #$W(Asc(c))
          Next
        End Sub
      end module)
    END
    tbl, data1, data2, data3, data4 = ::File.read(::File.join(__dir__, "wasm-tmpl.dat")).lines.map {|s| s.chomp }
    raise unless data3[0] == '('
    r.gsub(/@@\w+@@/, {
      "@@TBL@@" => tbl,
      "@@DATA1@@" => data1.gsub("\\"){"\\\\"},
      "@@DATA2@@" => data2.gsub("\\"){"\\\\"},
      "@@DATA3@@" => '#{40.chr}'+data3[1..].gsub("\\"){"\\\\"},
      "@@DATA4@@" => data4.gsub("\\"){"\\\\"},
      "@@CONST1@@" => "8",
      "@@CONST2@@" => (2 + (data3.size + data4.size + 18) + 125 * 8).to_s
    })
  end

  def check(prev)
    raise if prev.empty? || prev =~ /[^\n\x20-\x7e]/
    data3, data4 = ::File.read(::File.join(__dir__, "wasm-tmpl.dat")).lines.values_at(3, 4)
    k = data3.chomp.size + data4.chomp.size + 18
    raise unless (2**14...2**21).cover?(k + prev.bytesize)
  end
end

class VimScript < CodeGen
  Name = ["Vimscript"]
  Apt = "vim"
  File = "QR.vim"
  Cmd = "vim -EsS QR.vim > OUTFILE"
  def code
    <<-'END'.lines.map {|l| l.strip }.join
      "let s=#{E[PREV]}\nput=s\n2,$p\nq!"
    END
  end
end

class VHDL < CodeGen
  File = "QR.vhdl"
  Cmd = "ghdl -a QR.vhdl && ghdl -e qr && ghdl -r qr > OUTFILE"
  Apt = "ghdl"
  # "" for a quote; control characters are spliced in with character'val
  Code = %q(%(use std.textio.all;entity QR is end;architecture A of QR is begin process begin write(output,"#{(PREV).gsub(?",%("")).gsub(/[\x00-\x1f\x7f]/){%("&character'val(#{$&.ord})&")}}");wait;end process;end;))
end

class Verilog < CodeGen
  File = "QR.v"
  Cmd = "iverilog -o QR QR.v && ./QR -vcd-none > OUTFILE"
  Apt = "iverilog"
  Code = %q(%(module QR;initial begin #{f(PREV,3){%($write("%s",#$S);)}}end endmodule))
end

class Vale_Velato < CodeGen
  Name = ["Vale", "Velato"]
  File = ["QR.vale", "QR.mid"]
  Cmd = [
    "rm -rf qr_vale_out && valec build qr=QR.vale --output_dir qr_vale_out > /dev/null && ./qr_vale_out/main > OUTFILE && rm -rf qr_vale_out",
    "mono vendor/local/bin/Vlt.exe /s QR.mid && mono QR.exe > OUTFILE",
  ]
  Apt = [nil, nil]
  def code
    <<-'END'.lines.map {|l| l.strip }.join
      %(import stdlib.*;#{N}
      func b(x int){printstr(strfromascii(x),0,1);}
      func p(v int){b(v / 256);b(v - v / 256 * 256);}
      func n(v int){p(144);p(15450 + v * 256);p(384);p(15450 + v * 256);}
      exported func main(){
      s = "#{Q[e[PREV],/[{}]/]}";
      m = s.len() * 72 + 4;
      p(19796);p(26724);p(0);p(6);p(0);p(1);p(480);p(19796);p(29291);
      p(m / 65536);p(m - m / 65536 * 65536);
      i = 0;
      while i < s.len(){
      c = strtoascii(s,i,i + 1);
      n(0);n(9);n(7);n(4);n(5);
      n(c / 100 * 7 / 6 + 1);
      n((c - c / 100 * 100) / 10 * 7 / 6 + 1);
      n((c - c / 10 * 10) * 7 / 6 + 1);
      n(7);
      set i = i + 1;
      }
      p(255);p(12032);
      }#{N})
    END
  end

  def check(prev)
    raise "Vale > Velato: NUL, CR, or non-ASCII" if prev.include?("\0") || prev.include?("\r") || !prev.ascii_only?
  end
end

class Vala < CodeGen
  Name = "Vala"
  File = "QR.vala"
  Cmd = "valac QR.vala && ./QR > OUTFILE"
  Apt = "valac"
  Code = %q(%(void main(){stdout.puts#{E[PREV]};}))

  def check(prev)
    raise "Vala: NUL or CR" if prev.include?("\0") || prev.include?("\r")
  end
end

class VLang < CodeGen
  Name = "V"
  File = "QR.vlang.v"
  Cmd = "v run QR.vlang.v > OUTFILE"
  Apt = [nil]
  Code = %q((require"zlib";%(import compress.zlib#{N}import encoding.base64#{N}import os#{N}fn main(){d:=zlib.decompress(base64.decode('#{[Object.const_get("Zlib")::Deflate.deflate(PREV,9)].pack("m0")}')) or {panic(err)};mut o:=os.stdout();o.write(d) or {panic(err)}})))
end

class Uxntal < CodeGen
  Name = "Uxntal"
  File = "QR.tal"
  Cmd = "uxnasm QR.tal QR.rom && uxncli QR.rom > OUTFILE && rm -f QR.rom"
  Apt = [nil]
  Code = %q((uk="base64.decode"+40.chr+"'";ua,ub=PREV.split(uk,2);uc,ud=ub.split("'",2);ur=uc.unpack1("m0");un=(ur.bytesize/3)*3;uh=->(s){s.unpack1("H*").scan(/../).each_slice(120).map{|a|a*" "}*N};"|0100 ;pre ;p JSR2 ;z @l DUP2 ;ze EQU2 ;d JCN2 LDAk #00 STZ INC2 LDAk #01 STZ INC2 LDAk #02 STZ INC2 #00 LDZ #02 SFT ;e JSR2 #00 LDZ #03 AND #40 SFT #01 LDZ #04 SFT ORA ;e JSR2 #01 LDZ #0f AND #20 SFT #02 LDZ #06 SFT ORA ;e JSR2 #02 LDZ #3f AND ;e JSR2 ;l JMP2 @d POP2 ;suf ;p JSR2 #800f DEO BRK @e #00 SWP ;t ADD2 LDA #18 DEO JMP2r @p LDAk DUP #00 EQU ,&q JCN #18 DEO INC2 ,p JMP &q POP POP2 JMP2r\n@t "+uh[[*"A".."Z",*"a".."z",*"0".."9","+","/"]*""]+"\n@pre\n"+uh[ua+uk+"\0"]+"\n@z\n"+(un>0 ? uh[ur.byteslice(0,un)]+N : "")+"@ze\n@suf\n"+uh[uc[(un/3)*4..]+"'"+ud+"\0"]+"\n"))
  def check(prev)
    raise "Uxntal: non-printable byte" if prev =~ /[^\n\x20-\x7e]/
    raise "Uxntal: missing base64.decode('...')" unless prev.include?("base64.decode('") && prev.split("base64.decode('", 2)[1].include?("'")
  end
end

class Umka_Unlambda < CodeGen
  Name = ["Umka", "Unlambda"]
  File = ["QR.um", "QR.unl"]
  Cmd = [
    "umka QR.um > OUTFILE",
    "ruby vendor/unlambda.rb QR.unl > OUTFILE",
  ]
  Apt = [nil, nil]
  Code = %q(%(fn main(){s:="#{e[PREV]}";n:=len(s);for i:=0;i<n;i++{printf("\x60")};for i:=0;i<n;i++{if s[i]=='#{B}n'{printf("r")}else{printf(".%c",s[i])}};printf("k")}))
  def check(prev)
    raise "Umka_Unlambda: non-printable byte" if prev =~ /[^\n\x20-\x7e]/
  end
end

class Uiua < CodeGen
  Name = "Uiua"
  File = "QR.ua"
  Cmd = "uiua run --no-format QR.ua > OUTFILE"
  Apt = [nil]                # cargo install uiua 0.19.1, see src/extra-installs/
  Code = %q(%(#{PREV.dup.force_encoding("UTF-8").scan(/.{1,4000}/m).map{|u11|%|&pf "#{e[u11].gsub([8226].pack("U"),B+"u{2022}")}"|}*N}))
  def check(prev)
    raise "Uiua: payload is not valid UTF-8" unless prev.dup.force_encoding("UTF-8").valid_encoding?
    # only BQN's system dot is written as \u{2022}; any other non-ASCII would pass through raw
    raise "Uiua: non-ASCII other than U+2022" if prev.dup.force_encoding("UTF-8").delete([8226].pack("U")) =~ /[^\x00-\x7f]/
  end
end

class UCBLogo < CodeGen
  Name = "UCBLogo"
  File = "QR.logo"
  Cmd = "ucblogo QR.logo > OUTFILE"
  Apt = [nil]
  Code = %q(%(#{PREV.scan(/.{1,12000}/m).flat_map{|y|y.split(/(["|#{B*2}#{N}])/)}.reject(&:empty?).map{|x|x==?"?"CHAR 34":x==?|?"CHAR 124":x==B ? "CHAR 92":x==N ? "CHAR 10":"FIRST [|#{x}|]"}.inject([[]]){|g,x|g[-1][0]&&g[-1].sum(&:size)+x.size>24000?g<<[x]:g[-1]<<x;g}.map{|l|"TYPE (WORD #{l*" "})"}*N} BYE))
  def check(prev)
    raise "UCBLogo: non-ASCII or control byte" if prev =~ /[\x00-\x09\x0b-\x1f\x7f-\xff]/n
  end
end

class TypeScript < CodeGen
  Name = "TypeScript"
  File = "QR.ts"
  Cmd = "tsc --outFile QR.ts.js QR.ts && $(JAVASCRIPT) QR.ts.js > OUTFILE"
  Apt = "node-typescript"
  Code = %q(%(declare const process:any;let s:string=#{E[PREV]};process.stdout.write(s)))
end

class TXR < CodeGen
  Name = "TXR"
  File = "QR.txrlisp"
  Cmd = "txr --lisp QR.txrlisp > OUTFILE"
  Apt = [nil]                # source build txr-302, see src/extra-installs/
  Code = %q(%((put-string "#{e[PREV]}")))
  def check(prev)
    raise "TXR: non-printable byte" if prev =~ /[^\n\x20-\x7e]/
  end
end

class ThueLang < CodeGen
  Name = "Thue"
  File = "QR.t"
  Cmd = "ruby vendor/thue.rb QR.t > OUTFILE"
  Apt = [nil]
  Code = %q(%(a::=~#{PREV}\n::=\na\n))
  def check(prev)
    raise "Thue: a rule is one line" if prev.include?("\n")
  end
end

class Tengo < CodeGen
  File = "QR.tengo"
  Cmd = "tengo QR.tengo > OUTFILE"
  Apt = [nil] # go install github.com/d5/tengo/v2/cmd/tengo
  # raw back-tick string; each back-tick is spliced in as "`"
  Code = %q(%(fmt:=import("fmt");fmt.print(`#{(PREV).gsub("`",%(`+"`"+`))}`)))
end

class TcshLang < CodeGen
  Name = "tcsh"
  File = "QR.tcsh"
  Cmd = "tcsh QR.tcsh > OUTFILE"
  Apt = "tcsh"
  Code = %q("set echo_style=bsd\n"+(PREV).scan(/.{1,1000}/m).map{|p16t|"echo -n '#{p16t.gsub(?',%('"'"')).gsub(N,"'\necho ''\necho -n '")}'"}*N+N)
  def check(prev)
    raise "tcsh: NUL" if prev.include?("\0")
  end
end

class Tcl < CodeGen
  File = "QR.tcl"
  Cmd = "tclsh QR.tcl > OUTFILE"
  Apt = "tcl"
  Code = %q((require"zlib";%(fconfigure stdout -translation binary#{N}puts -nonewline [zlib decompress [binary decode base64 {#{[Object.const_get("Zlib")::Deflate.deflate(PREV,9)].pack("m0")}}]]#{N})))
end

class Taxi < CodeGen
  Name = "Taxi"
  File = "QR.taxi"
  Cmd = "taxi QR.taxi > OUTFILE"
  Apt = [nil]
  Code = %q((p4tp=(PREV).split(/(")/).reject(&:empty?);p4td=p4tp.map{|p4x|p4x==?" ? "34 is waiting at Starchild Numerology." : "\""+Q[p4x,B].gsub(N,B+?n).gsub("\t",B+?t).gsub("\r",B+?r)+"\" is waiting at the Writer\x27s Depot."}*N;p4tr="Go to Writer\x27s Depot: west 1st left, 2nd right, 1st left, 2nd left."+N+p4tp.each_with_index.map{|p4x,p4i|(p4x==?" ? "Go to Starchild Numerology: south 1st left, 2nd right. Pickup a passenger going to Charboil Grill. Go to Charboil Grill: east 1st left. Pickup a passenger going to the Post Office. Go to Go More: east. Go to Writer\x27s Depot: west 1st right. Go to the Post Office: north 1st right, 2nd right, 1st left." : "Pickup a passenger going to the Post Office. Go to the Post Office: north 1st right, 2nd right, 1st left.")+(p4i<p4tp.size-1 ? " Go to Writer\x27s Depot: south 1st right, 1st left, 2nd left." : "")}*N+N+"Go to the Taxi Garage: north 1st right, 1st left, 1st right.";p4td+N+p4tr))
  def check(prev)
    raise "Taxi: non-printable byte" if prev =~ /[\x00-\x08\x0b-\x0c\x0e-\x1f\x7f-\xff]/n
  end
end

class Swift < CodeGen
  File = "QR.swift"
  Cmd = "swiftc QR.swift && ./QR > OUTFILE"
  Apt = "swiftlang"
  Code = %q("print"+E[PREV])
end

class SurgeScript < CodeGen
  File = "QR.ss"
  Cmd = "surgescript QR.ss > OUTFILE"
  Apt = "surgescript"
  Code = %q(%(object"Application"{state"main"{#{f(PREV,4){%(Console.write#$S;)}}exit();}}))
end

class StandardML_Subleq < CodeGen
  Name = ["Standard ML", "Subleq"]
  File = ["QR.sml", "QR.sq"]
  Cmd = ["polyc -o QR QR.sml && ./QR > OUTFILE", "ruby vendor/subleq.rb QR.sq > OUTFILE"]
  Apt = [["polyml", "libpolyml-dev"], nil]
  def code
    <<-'END'.lines.map {|l| l.strip }.join
      %(
        fun p n=print(Int.toString n^" ");
        fun main()=(
          print"0 0 130 ";
          List.tabulate(127,p);
          String.map(fn c=>(p(3+ord c);print"-1 0 ";c))#{E[PREV]}
        )
      )
    END
  end

  def check(prev)
    raise if prev.bytes.max.to_i > 126
  end
end

class Squirrel < CodeGen
  File = "QR.nut"
  Cmd = "squirrel QR.nut > OUTFILE"
  Apt = "squirrel3"
  Code = %q("print"+E[PREV])
end

class SNOBOL4 < CodeGen
  Name = "SNOBOL4"
  File = "QR.sno"
  Cmd = "snobol4 -b QR.sno > OUTFILE"
  Apt = [nil]
  Code = %q((PREV).lines.map{|ncs|p4sc=ncs.chomp.scan(/.{1,200}/).flat_map{|p4p|p4p.split(/(\x27+)/).reject(&:empty?).map{|nct|nct[0]=="\x27" ? "\x22"+nct+"\x22" : "\x27"+nct+"\x27"}};p4sc.empty? ? "  OUTPUT = \x27\x27" : "  S = \x27\x27"+N+p4sc.map{|p4k|"  S = S "+p4k}*N+N+"  OUTPUT = S"}*N+N+"END"+N)
  def check(prev)
    raise "SNOBOL4: non-ASCII or CR" if !prev.ascii_only? || prev.include?("\r")
  end
end

class SLang < CodeGen
  Name = "S-Lang"
  File = "QR.sl"
  Cmd = "slsh QR.sl > OUTFILE"
  Apt = "slsh"
  Code = %q(((PREV).scan(/.{1,80}/m).map{|p12s|"printf(\"%s\",\"#{e[p12s]}\");#{N}"}*"" ))
  def check(prev)
    raise "S-Lang: non-printable byte" if prev =~ /[^\n\x20-\x7e]/
  end
end

class Singular < CodeGen
  Name = "Singular"
  File = "QR.sing"
  Cmd = "Singular -q QR.sing > OUTFILE"
  Apt = "singular"
  Code = %q(%(string s="";\n#{PREV.chomp.split(N,-1).map{|p15l|"s=\"\";\n"+p15l.scan(/.{1,2000}/).map{|c|%(s=s+"#{Q[Q[c,B],?"]}";\n)}*""+"s;\n"}*""}quit;\n))
  def check(prev)
    raise "Singular: payload must end with one newline" unless prev.end_with?("\n") && !prev.end_with?("\n\n")
    raise "Singular: non-printable byte" if prev =~ /[^\n\x20-\x7e]/
  end
end

class Simula < CodeGen
  Name = "Simula"
  File = "QR.sim"
  Cmd = "cim -q -b -w QR.sim && ./QR > OUTFILE && rm -f QR QR.o"
  Backup = [["[ ! -f QR.c ] || mv QR.c QR.c.bak", "[ ! -f QR.c.bak ] || mv QR.c.bak QR.c"]]
  Apt = [nil]
  Code = %q((ncp=[];(PREV).lines.each{|ncl|ncl.chomp.split(/(\t)/).flat_map{|ncq|ncq=="\t" ? [ncq] : ncq.scan(/.{1,2000}/)}.each{|ncc|ncp<<(ncc=="\t" ? "OutChar(Char(9));" : "OutText(\x22"+ncc.gsub("\x22","\x22\x22")+"\x22);")};ncp<<"OutImage;"};ncg=ncp.each_slice(400).to_a;"Begin"+N+ncg.each_with_index.map{|ncx,nci|"Procedure P#{nci};Begin"+N+ncx*N+N+"End;"}*N+N+"SysOut.Image:-Blanks(20000);"+N+(0...ncg.size).map{|nci|"P#{nci};"}.each_slice(20).map(&:join)*N+N+"End"+N))

  def check(prev)
    raise "Simula: OutImage drops trailing blanks" if prev.lines.any? { |l| l.chomp.end_with?(" ") }
    raise "Simula: line longer than the 20000-char image" if prev.lines.any? { |l| l.size > 19000 }
    raise unless prev.ascii_only? && prev.end_with?("\n")
    raise if prev.include?("\r")
  end
end

class Seed7_Shakespeare < CodeGen
  Name = ["Seed7", "Shakespeare"]
  File = ["QR.sd7", "QR.spl"]
  Cmd = [
    "s7 -q QR.sd7 > OUTFILE",
    "spl2c < QR.spl > QR.spl.c && gcc -O0 -z muldefs -o QR -I ./vendor/local/include -L ./vendor/local/lib QR.spl.c -lspl -lm && ./QR > OUTFILE"
  ]
  Apt = [nil, nil]
  Code = %q(%($ include "seed7_05.s7i";#{N}const func string: rom (in var integer: n) is func#{N}result var string: r is "";#{N}begin#{N}while n>=1000 do r&:="m";n-:=1000;end while;#{N}if n>=900 then r&:="cm";n-:=900;end if;#{N}if n>=500 then r&:="d";n-:=500;end if;#{N}if n>=400 then r&:="cd";n-:=400;end if;#{N}while n>=100 do r&:="c";n-:=100;end while;#{N}if n>=90 then r&:="xc";n-:=90;end if;#{N}if n>=50 then r&:="l";n-:=50;end if;#{N}if n>=40 then r&:="xl";n-:=40;end if;#{N}while n>=10 do r&:="x";n-:=10;end while;#{N}if n>=9 then r&:="ix";n-:=9;end if;#{N}if n>=5 then r&:="v";n-:=5;end if;#{N}if n>=4 then r&:="iv";n-:=4;end if;#{N}while n>=1 do r&:="i";n-:=1;end while;#{N}end func;#{N}const proc: main is func#{N}local#{N}var string: s is #{(PREV).scan(/.{1,200}/m).map{|p12s|?"+e[p12s]+?"}*"&#{N}"};#{N}var integer: i is 0;#{N}var integer: b is 0;#{N}var integer: act is 0;#{N}var integer: sc is 0;#{N}begin#{N}writeln("The Relay of Quine.");#{N}writeln("Ajax, a man.");#{N}writeln("Ford, a man.");#{N}for i range 1 to length(s) do#{N}if (i-1) rem 100 = 0 then#{N}if sc rem 20 = 0 then#{N}incr(act);sc:=1;writeln("Act "&rom(act)&": Quine.");#{N}else#{N}incr(sc);#{N}end if;#{N}writeln("Scene "&rom(sc)&": Relay.");#{N}if i=1 then writeln("[Enter Ajax and Ford]");end if;#{N}writeln("Ajax:");#{N}end if;#{N}b:=ord(s[i]);#{N}write("You are as bad as");#{N}while b>1 do#{N}if odd(b) then write(" the sum of a son and");end if;#{N}write(" twice");b:=b div 2;#{N}end while;#{N}writeln(" a son.Speak thy mind.");#{N}end for;#{N}writeln("[Exeunt]");#{N}end func;#{N}))
  def check(prev)
    raise "Seed7_Shakespeare: non-printable byte" if prev =~ /[^\n\x20-\x7e]/
  end
end

class SedLang < CodeGen
  Name = "sed"
  File = "QR.sed"
  Cmd = "sed -E -f QR.sed QR.sed > OUTFILE"
  Apt = "sed"
  Code = %q(("1d;s/.//#{N}"+(PREV).chomp.split(N,-1).map{|p12s|"##{p12s}"}*N+N))
  def check(prev)
    raise "sed: expected trailing newline" unless prev.end_with?("\n")
    raise "sed: non-ASCII or CR" if !prev.ascii_only? || prev.include?("\r")
  end
end

class ScilabLang < CodeGen
  Name = "Scilab"
  File = "QR.sci"
  Cmd = "scilab-cli -nb -f QR.sci > OUTFILE"
  Apt = "scilab-cli"
  Code = %q((p12l=(PREV).split(N,-1);p12l.each_with_index.map{|p12x,p12i|p12x.scan(/.{1,1000}/m).map{|p12s|"mprintf(\"%s\",\"#{d[d[p12s],?']}\");#{N}"}*""+(p12i<p12l.size-1 ? "mprintf(\"#{B}n\");#{N}" : "")}*""+"quit#{N}"))
  def check(prev)
    raise "Scilab: non-printable byte" if prev =~ /[^\n\x20-\x7e]/
  end
end

class Scheme < CodeGen
  File = "QR.scm"
  Cmd = "$(SCHEME) QR.scm > OUTFILE"
  Apt = "guile-3.0"
  Code = %q((nsx=(PREV).gsub(":",":c").gsub(34.chr,":q");9.downto(0){|nsi|nsx=nsx.gsub(B*(1<<nsi),":#{nsi}")};%((define s "#{nsx}")(define n (string-length s))(let l ((i 0)) (if (< i n) (let ((c (string-ref s i))) (if (char=? c (integer->char 58)) (let ((d (char->integer (string-ref s (+ i 1))))) (display (cond ((= d 99) ":") ((= d 113) (string (integer->char 34))) (else (make-string (expt 2 (- d 48)) (integer->char 92))))) (l (+ i 2))) (begin (write-char c) (l (+ i 1))))))))))
end

class Scala < CodeGen
  File = "QR.scala"
  Cmd = "scalac QR.scala && scala QR > OUTFILE"
  Apt = "scala"
  def code
    <<-'END'.lines.map {|l| l.strip }.join
      "
        object QR extends App{
          #{f(PREV,196){%(print#$S;)}}
        }
      "
    END
  end

  def check(prev)
    # the JVM allows up to 65535 bytes per CONSTANT_Utf8
    prev.scan(/.{1,#{ 196 * 255 }}/m) { raise if $&.bytesize > 65535 }
  end
end

class Rye < CodeGen
  Name = "Rye"
  File = "QR.rye"
  Cmd = "rye QR.rye > OUTFILE"
  Apt = [nil]
  Code = %q(%(prn "#{e[PREV]}"#{N}))

  def check(prev)
    raise "Rye: NUL, CR, or non-ASCII" if prev.include?("\0") || prev.include?("\r") || !prev.ascii_only?
  end
end

class Rust < CodeGen
  File = "QR.rs"
  Cmd = "rustc QR.rs && ./QR > OUTFILE"
  Apt = "rustc"
  Code = %q(%(fn main(){print!("{}",#{E[PREV]})}))
end

class Ruby_ < CodeGen
  Name = "Ruby"
  File = "QR.rb"
  Cmd = "ruby QR.rb > OUTFILE"
  Apt = "ruby"
  Code = %q(%(print '#{(PREV).gsub(?@,"@A").gsub(B,"@D").gsub(?',"@Q")}'.gsub("@D",92.chr).gsub("@Q",39.chr).gsub("@A","@")))
  def check(prev)
    raise "Ruby: NUL" if prev.include?("\0")
  end
end

class Rockstar < CodeGen
  Name = "Rockstar"
  File = "QR.rock"
  Cmd = "rockstar QR.rock > OUTFILE"
  Apt = [nil]
  Code = %q((p3rc=(PREV).split(/(["#{N}])/).reject(&:empty?).map{|p3rg|p3rg==34.chr ? "q" : p3rg==N ? "z" : 34.chr+p3rg+34.chr}*" + ";"let q be 34#{N}burn q#{N}let z be 10#{N}burn z#{N}shout #{p3rc.empty? ? 34.chr*2 : p3rc}#{N}"))
  def check(prev)
    raise "Rockstar: backslash in the payload" if prev.index(92.chr)
  end
end

class Roc < CodeGen
  Name = "Roc"
  File = "QR.roc"
  Cmd = "roc build --output qrroc QR.roc && ./qrroc > OUTFILE && rm -f qrroc"
  Apt = [nil]
  Code = %q(%(app [main!] { pf: platform "/opt/roc/basic-cli/main.roc" }#{N}import pf.Stdout#{N}d = #{B}s, a, b -> Str.joinWith(Str.splitOn(s, a), b)#{N}main! = #{B}_args -> Stdout.write!(d(d(d(d(d("#{(PREV).gsub(?@,"@A").gsub(B,"@D").gsub(?","@C").gsub(?$,"@E").gsub(N,"@F")}", "@D", "#{B+B}"), "@C", "#{B}""), "@E", "#{B}$"), "@F", "#{B}n"), "@A", "@"))#{N}))
  def check(prev)
    raise "Roc: not UTF-8" unless prev.dup.force_encoding("UTF-8").valid_encoding?
    raise "Roc: control character" if prev =~ /[\x00-\x08\x0b-\x1f\x7f]/
  end
end

class RISCVAsm < CodeGen
  Name = "RISC-V asm"
  File = "QR.rv.s"
  Cmd = "rm -f QR && riscv64-linux-gnu-gcc -nostdlib -static -o QR QR.rv.s && qemu-riscv64 ./QR > OUTFILE && rm -f QR"
  Apt = [["gcc-riscv64-linux-gnu", "qemu-user"]]
  Code = %q((p9rvz=(PREV);".global _start\n.text\n_start:\n li a0, 1\n la a1, msg\n li a2, #{p9rvz.bytesize}\n li a7, 64\n ecall\n li a0, 0\n li a7, 93\n ecall\n.data\nmsg:\n"+p9rvz.scan(/.{1,16000}/m).map{|p9rvr|%(.ascii "#{e[p9rvr]}")}*N+N))
  def check(prev)
    raise "RISC-V asm: bad byte" if !prev.ascii_only? || prev =~ /[\x00-\x09\x0b-\x1f\x7f]/
  end
end

class RingLang < CodeGen
  Name = "Ring"
  File = "QR.ring"
  Cmd = "ring QR.ring > OUTFILE"
  Apt = [nil]                # source build v1.27 (language/src only), see src/extra-installs/
  Code = %q(%(see '#{PREV.gsub("'","'+char(39)+'")}'))
  def check(prev)
    raise "Ring: non-printable byte" if prev =~ /[^\n\x20-\x7e]/
  end
end

class Rhai < CodeGen
  File = "QR.rhai"
  Cmd = "rhai-run QR.rhai > OUTFILE"
  Apt = [nil]
  Code = %q(%(print("#{e[PREV]}");))
  def check(prev)
    raise "Rhai: CR or NUL" if prev.include?("\r") || prev.include?("\0")
  end
end

class REXXLang < CodeGen
  Name = "REXX"
  File = "QR.rexx"
  Cmd = "rexx ./QR.rexx > OUTFILE"
  Apt = "regina-rexx"
  Code = %q((p9rxl=(PREV).split(N,-1);p9rxl.each_with_index.map{|p9rxz,p9rxi|p9rxz.scan(/.{1,16000}/m).map{|p9rxs|"call charout , '"+d[p9rxs,?']+"'"+N}*""+(p9rxi<p9rxl.size-1 ? "call charout , d2c(10)#{N}" : "")}*""))
  def check(prev)
    raise "REXX: non-ASCII" unless prev.bytes.all? {|c| c < 128 }
  end
end

class ReScript < CodeGen
  File = "QR.res"
  Cmd = "bsc QR.res > QR.res.js && node QR.res.js > OUTFILE"
  Apt = [nil]
  Code = %q((p3rm={?@=>"@0",B=>"@1",?"=>"@2",N=>"@4"};p3rs=%("#{(PREV).gsub(Regexp.union(*p3rm.keys),p3rm)}");[[1,92],[2,34],[4,10],[0,64]].each{|p3ri,p3rc|p3rs=%[String.replaceAll(#{p3rs}, "@#{p3ri}", String.fromCharCode(#{p3rc}))]};%[Console.log(#{p3rs})]))
  def check(prev)
    raise "ReScript: CR in the payload" if prev.include?("\r")
  end
end

class LibRep < CodeGen
  Name = "rep (librep)"
  File = "QR.rep"
  Cmd = "rep QR.rep > OUTFILE"
  Apt = "rep"
  Code = %q(%((princ "#{e[PREV]}")))
end

class RcLang < CodeGen
  Name = "rc"
  File = "QR.rc"
  Cmd = "rc QR.rc > OUTFILE"
  Apt = "rc"
  Code = %q((p12l=(PREV).split(N,-1);p12l.each_with_index.map{|p12x,p12i|p12p=p12x.scan(/.{1,1000}/m);p12p=[""] if p12p.empty?;p12p.each_with_index.map{|p12y,p12j|(p12i<p12l.size-1&&p12j==p12p.size-1 ? "echo '" : "echo -n '")+d[p12y,?']+"'"+N}*""}*""))
  def check(prev)
    raise "rc: NUL" if prev.include?("\0")
    raise "rc: a line that is just -n" if prev.split("\n").include?("-n")
  end
end

class RatforLang < CodeGen
  Name = "Ratfor"
  File = "QR.ratfor"
  Cmd = "ratfor -o QR.ratfor.f QR.ratfor && gfortran -o QR QR.ratfor.f && ./QR > OUTFILE"
  Apt = "ratfor"
  Code = %q((p9ral=(PREV).split(N,-1);p9rac=[];p9ral.each_with_index{|p9rax,p9rai|p9rab=+"";p9rax.each_char{|p9rah|p9raq=p9rah=="\x27" ? "\x27\x27" : p9rah;if p9rab.bytesize+p9raq.bytesize>122 then p9rac<<"call p('#{p9rab}')";p9rab=+"" end;p9rab<<p9raq};p9rac<<"call p('#{p9rab}')" unless p9rab.empty?;p9rac<<"call p(char(10))" if p9rai<p9ral.size-1};p9rag=p9rac.each_slice(200).to_a;"subroutine p(s)#{N}character*(*) s#{N}write(*,'(a)',advance='no') s#{N}end#{N}"+p9rag.each_with_index.map{|p9raa,p9rak|"subroutine s#{p9rak}#{N}"+p9raa*N+"#{N}end#{N}"}*""+(0...p9rag.size).map{|p9rak|"call s#{p9rak}#{N}"}*""+"end#{N}"))
  def check(prev)
    raise "Ratfor: non-printable byte" if prev =~ /[^\n\x20-\x7e]/
  end
end

class Rail < CodeGen
  Name = "Rail"
  File = "QR.rail"
  Cmd = "rail QR.rail > OUTFILE"
  Apt = [nil]
  Code = %q((p5rm={B=>B*2,?[=>B+"["+B,?]=>B+"]"+B,N=>B+"n"+B};%($ 'main'#{N} #{B}#{N}  #{B}-[#{(PREV).gsub(Regexp.union(*p5rm.keys),p5rm)}]o#)))
  def check(prev)
    raise "Rail: CR or NUL" if prev.include?("\r") || prev.include?("\0")
  end
end

class RacketLang < CodeGen
  Name = "Racket"
  File = "QR.rkt"
  Cmd = "racket QR.rkt > OUTFILE"
  Apt = "racket"
  Code = %q((p5km={?@=>"@0",B=>"@1",?"=>"@2",?'=>"@3",N=>"@4",?$=>"@5"};p5ks=%("#{(PREV).gsub(Regexp.union(*p5km.keys),p5km)}");[[1,92],[2,34],[3,39],[4,10],[5,36],[0,64]].each{|p5ki,p5kc|p5ks=%((r #{p5ks} "@#{p5ki}" #{p5kc}))};"#lang racket/base#{N}(require racket/string)#{N}(define (r s p c) (string-replace s p (string (integer->char c))))#{N}(display #{p5ks})#{N}"))
end

class RLang < CodeGen
  Name = "R"
  File = "QR.R"
  Cmd = "R --slave -f QR.R > OUTFILE"
  Apt = "r-base"
  Code = %q(((PREV).scan(/.{1,2000}/m).map{|p12r|"cat#{E[p12r]}#{N}"}*""))
  def check(prev)
    raise "R: NUL or non-ASCII" if prev.include?("\0") || !prev.ascii_only?
  end
end

class QBE < CodeGen
  Name = "QBE"
  File = "QR.ssa"
  Cmd = "qbe QR.ssa > QR.qbe.s && $(CC) QR.qbe.s -o QR && ./QR > OUTFILE"
  Apt = "qbe"
  # QBE SSA IL: chunked byte strings in data section printed via libc printf("%s", $s).
  # Emits non-ASCII bytes (e.g. UTF-8 APL symbols) as numeric `b N` so QR.ssa stays pure 7-bit ASCII.
  Code = %q(%(data \$f={b "%s",b 0}#{N}data \$s={#{(PREV).b.scan(/[\x20-\x7e\t\n]{1,500}|[\x80-\xff]/n).map{|s|s.getbyte(0)>126 ? "b #{s.getbyte(0)}" : %(b "#{e[s].gsub(9.chr,B+?t)}")}*","},b 0}#{N}export function w \$main(){#{N}@a#{N}call \$printf(l \$f,...,l \$s)#{N}ret 0#{N}}#{N}))

  def check(prev)
    raise "QBE: NUL or control byte" if prev.b =~ /[\x00-\x08\x0b-\x1f\x7f]/n
  end
end

class PythonLang < CodeGen
  Name = "Python"
  File = "QR.py"
  Cmd = "python3 QR.py > OUTFILE"
  Apt = "python3"
  Code = %q(%(import sys#{N}sys.stdout.write(#{E[PREV]})#{N}))
  def check(prev)
    raise "Python: CR, NUL or non-ASCII" if prev =~ /[\r\0]/ || !prev.ascii_only?
  end
end

class Pyth < CodeGen
  Name = "Pyth"
  File = "QR.pyth"
  Cmd = "python3 /opt/pyth/pyth.py -n QR.pyth > OUTFILE"
  Apt = "python3"
  Code = %q((p3ya=(PREV).split(/(["#{B*2}#{N}])/).reject(&:empty?).map{|p3yx|p3yx==34.chr ? "N" : p3yx==N ? "b" : p3yx==B ? B*2 : 34.chr+p3yx+34.chr};"ps["+p3ya.join+41.chr))
  def check(prev)
    raise "Pyth: non-ASCII" unless prev.ascii_only?
    raise "Pyth: CR" if prev.include?("\r")
  end
end

class Pyret < CodeGen
  File = "QR.arr"
  Cmd = "pyretc QR.arr QR.jarr && NODE_PATH=/opt/b05/node_modules node QR.jarr > OUTFILE"
  Apt = [nil] # npm pyret-npm; pyretc runs its compiler without the background server (src/extra-installs/)
  Code = %q(%(print("#{e[PREV]}")))
end

class PureScript < CodeGen
  File = "QRP.purs"
  Cmd = "purs compile -o purs_out QRP.purs '/opt/purs/lib/*/src/**/*.purs' && node purs_out/QRP/index.js > OUTFILE && rm -rf purs_out"
  Apt = [nil]
  Code = %q((p3ps=(PREV);p3ps=p3ps.chomp if p3ps.end_with?(N);%(module QRP where\nimport Prelude\nimport Effect.Console (log)\nimport Effect.Unsafe (unsafePerformEffect)\no :: Unit\no = unsafePerformEffect (log """#{p3ps}""")\n-- )))
  def check(prev)
    s = prev.end_with?("\n") ? prev.chomp : prev
    raise "PureScript: triple quote or trailing quote" if s.include?('"""') || s.end_with?('"')
  end
end

class Promela < CodeGen
  Name = "Promela (Spin)"
  File = "QR.pr"
  Cmd = "spin -T QR.pr > OUTFILE"
  Apt = "spin"
  Code = %q("init{\n#{f(PREV,3){"printf#{d[$S,?%]};\n"}}}")
  def check(prev)
    raise "Promela: payload must end with a line comment mark" unless prev.end_with?("-- ") || prev.end_with?(?#)
  end
end

class Prolog < CodeGen
  File = "QR.prolog"
  Cmd = "swipl -q -t qr -f QR.prolog > OUTFILE"
  Apt = "swi-prolog"
  Code = %q("qr:-write#{E[PREV]}.")
end

class PowerShell < CodeGen
  Name = "PowerShell"
  File = "QR.ps1"
  Cmd = "DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=1 POWERSHELL_TELEMETRY_OPTOUT=1 pwsh -NoProfile -NonInteractive -File QR.ps1 > OUTFILE"
  Apt = [nil]
  Code = %q((require"zlib";%([IO.Compression.DeflateStream]::new([IO.MemoryStream]::new([Convert]::FromBase64String('#{[Object.const_get("Zlib")::Deflate.deflate(PREV,9)[2..-5]].pack("m0")}')),[IO.Compression.CompressionMode]::Decompress).CopyTo([Console]::OpenStandardOutput())#{N})))
end

class PostScript < CodeGen
  Name = "PostScript"
  File = "QR.ps"
  Cmd = "gs -dNODISPLAY -q QR.ps > OUTFILE"
  Apt = "ghostscript"
  Code = %q((PREV).scan(/.{1,40000}/m).map{|p3po|"(#{p3po.gsub(/[#{B*2}()]/){B+$&}})print"}.join(N)+"\nquit\n")
  def check(prev)
    raise "PostScript: CR or NUL" if prev.include?("\r") || prev.include?("\0")
  end
end

class Pony < CodeGen
  Name = "Pony"
  File = "qrpony/main.pony"
  Cmd = "ponyc -V0 -b qrpony.out -o . qrpony && ./qrpony.out > OUTFILE"
  Apt = [nil]
  Code = %q(%(actor Main new create(e:Env)=>e.out.write("#{e[PREV]}")))
  def check(prev)
    raise "Pony: CR or NUL" if prev.include?("\r") || prev.include?("\0")
  end
end

class PocketLang < CodeGen
  Name = "PocketLang"
  File = "QR.pk"
  Cmd = "pocket QR.pk > OUTFILE"
  Apt = [nil]
  # $ triggers interpolation, escaped via Q[..., ?$]. io.write(io.stdout, ...) omits LF.
  Code = %q(%(import io#{N}io.write(io.stdout,"#{Q[e[PREV],?$]}")#{N}))

  def check(prev)
    raise "PocketLang: NUL, CR, or non-ASCII" if prev.include?("\0") || prev.include?("\r") || !prev.ascii_only?
  end
end

class Pike < CodeGen
  File = "QR.pike"
  Cmd = "pike QR.pike > OUTFILE"
  Apt = "pike8.0"
  Code = %q("int main(){write#{E[PREV]};}")

  def check(prev)
    # the Piet image reads a byte as a column height, and Perl 5's Re-Pair takes 0-31 and 128-255
    raise unless prev.bytes.all? {|c| c == 10 || (0x20..0x7e).cover?(c) }
  end
end

class PicoLisp_Piet < CodeGen
  Name = ["PicoLisp", "Piet"]
  File = ["QR.l", "QR.ppm"]
  Cmd = ["pil QR.l > OUTFILE", "npiet QR.ppm > OUTFILE"]
  Apt = ["picolisp", nil]
  Code = %q(%((setq S "#{Q[PREV,/[\\\\"^]/]}")(let (V (mapcar char (chop S)) W (* 3 (length V)) Z (+ 3 W) TT (192 0 255)) (prinl "P6") (prinl (+ W 2) " " 128) (prinl 255) (for R 128 (let P V (for C0 (- Z 1) (let (C1 (dec C0) I (+ (* (dec R) Z) C0) Cv (dec C0) Vv 0 Ok NIL) (when (or (<> C1 W) (> I Z)) (if (< C1 W) (setq Vv (car P)) (setq Vv (+ (% C1 3) 2) Cv (dec C1))) (setq Ok (< I (* Vv Z)))) (if Ok (wr 255 (get TT (inc (% (% Cv 3) 2))) (get TT (inc (% Cv 3)))) (wr 0 0 0)) (when (and (< C1 W) (=0 (% (inc C1) 3))) (setq P (cdr P))))))))(bye)))
  def check(prev)
    raise "Piet: only newline and space..~" unless prev.bytes.all? {|c| c == 10 || (0x20..0x7e).cover?(c) }
  end
end

class Picat < CodeGen
  Name = "Picat"
  File = "QR.pi"
  Cmd = "picat QR.pi > OUTFILE"
  Apt = [nil]                # release binary, see src/extra-installs/
  Code = %q(("main=>"+(PREV).scan(/.{1,16000}/m).map{|s|%(print("#{e[s]}"))}.join(",")+"."+N))
  def check(prev)
    raise "Picat: non-printable byte" if prev =~ /[^\n\x20-\x7e]/
  end
end

class PHPLang < CodeGen
  Name = "PHP"
  File = "QR.php"
  Cmd = "php QR.php > OUTFILE"
  Apt = "php-cli"
  Code = %q(%(<?php echo '#{(PREV).gsub(/[\\\\']/){B+$&}}';))
end

class Perl6 < CodeGen
  Name = "Perl 6"
  File = "QR.pl6"
  Cmd = "perl6 QR.pl6 > OUTFILE"
  Apt = "rakudo"
  Code = %q("print '#{(PREV).gsub(/[#{B*2}']/){B+$&}}'")
  def check(prev)
    raise "Perl 6: NUL or CR" if prev.include?("\0") || prev.include?("\r")
  end
end

class Perl5 < CodeGen
  Name = "Perl 5"
  File = "QR.pl"
  Cmd = "perl QR.pl > OUTFILE"
  Apt = "perl"
  Code = %q("print '#{(PREV).gsub(/[#{B*2}']/){B+$&}}'")
end

class Pawn < CodeGen
  Name = "Pawn"
  File = "QR.pawn"
  Cmd = "pawncc -C64 QR.pawn -oQR.amx > /dev/null && pawnrun QR.amx > OUTFILE && rm -f QR.amx"
  Apt = [nil]
  # Uses printf("%s", ...) chunked <=120 B (sLINEMAX=1023) to avoid n_print ANSI color resets.
  Code = %q(%(#include <console>#{N}main(){#{N}#{(PREV).scan(/.{1,120}/m).map{|s|%(printf("%s","#{e[s]}");)}*N}#{N}}#{N}))

  def check(prev)
    raise "Pawn: NUL, CR, or non-ASCII" if prev.include?("\0") || prev.include?("\r") || !prev.ascii_only?
  end
end

class Pascal < CodeGen
  File = "QR.pas"
  Cmd = "fpc QR.pas && ./QR > OUTFILE"
  Apt = "fp-compiler"
  Code = %q("begin\n"+(PREV).scan(/.{1,120}/m).map{|p3pc|"write("+p3pc.split(/(['#{N}\t])/).reject(&:empty?).map{|p3pt|p3pt=="'" ? "''''" : p3pt==N ? "#10" : p3pt==9.chr ? "#9" : "'#{p3pt}'"}.join("+")+");"}.join(N)+"\nend.\n")
  def check(prev)
    raise "Pascal: non-ASCII or CR" if !prev.ascii_only? || prev.include?("\r")
  end
end

class Parser3 < CodeGen
  Name = "Parser 3"
  File = "QR.p"
  Cmd = "parser3 QR.p > OUTFILE"
  Apt = "parser3-cgi"
  Code = %q((p5p3=Regexp.union(94.chr,?$,?;,?(,?),?[,?],?{,?});"$console:line[#{(PREV).gsub(p5p3){94.chr+$&}}]#{N}"))
  def check(prev)
    raise "Parser 3: CR" if prev.include?("\r")
  end
end

class ParrotAsm < CodeGen
  Name = "Parrot asm (PASM)"
  File = "QR.pasm"
  Cmd = "parrot QR.pasm > OUTFILE"
  Apt = [nil] # built from source in src/extra-installs/
  # single-quoted heredoc: raw text, no escaping
  Code = %q(%(print <<'Q'\n#{PREV}\nQ\nend\n))

  def check(prev)
    raise if prev =~ /^Q$/        # it ends the heredoc
    raise if prev.include?("\r")
  end
end

class PARIGP < CodeGen
  Name = "PARI/GP"
  File = "QR.gp"
  Cmd = "gp -f -q QR.gp > OUTFILE"
  Apt = "pari-gp"
  Code = %q("print#{E[PREV]};quit")
end

class Odin_Ook < CodeGen
  Name = ["Odin", "Ook!"]
  File = ["QR.odin", "QR.ook"]
  Cmd = [
    "odin run QR.odin -file > OUTFILE",
    "ruby vendor/ook-to-bf.rb QR.ook QR.ook.bf && ruby vendor/bf.rb QR.ook.bf > OUTFILE",
  ]
  Apt = [nil, nil]
  def code
    bf_to_ook = ->(bf) {
      mp = { '+' => 'Ook. Ook. ', '-' => 'Ook! Ook! ', '>' => 'Ook. Ook? ', '<' => 'Ook? Ook. ',
             '.' => 'Ook! Ook. ', ',' => 'Ook. Ook! ', '[' => 'Ook! Ook? ', ']' => 'Ook? Ook! ' }
      bf.chars.map { |ch| mp[ch] }.join
    }
    init_ook = bf_to_ook["++++++++++[>++>++++>+++++>+++++++>++++++++>++++++++++>+++++++++++>++++++++++++<<<<<<<<-]>"]
    %Q(%(package main\nimport "core:os"\nw::proc(b:[]u8,k:^int,t:string){for i:=0;i<len(t);i+=1{b[k^]=t[i];k^+=1;if k^>=65000{os.write(os.stdout,b[:k^]);k^=0}}}\nmain::proc(){s:="\#{e[PREV]}";b:=make([]u8,65536);k:=0;c:=[8]int{20,40,50,70,80,100,110,120};p:=0;w(b,&k,"#{init_ook}");for i:=0;i<len(s);i+=1{v:=int(s[i]);bj:=0;bc:=999;for j:=0;j<8;j+=1{d:=v-c[j];if d<0{d=-d};m:=j-p;if m<0{m=-m};if d+m<bc{bc=d+m;bj=j}};for p<bj{w(b,&k,"Ook. Ook? ");p+=1};for p>bj{w(b,&k,"Ook? Ook. ");p-=1};for c[p]<v{w(b,&k,"Ook. Ook. ");c[p]+=1};for c[p]>v{w(b,&k,"Ook! Ook! ");c[p]-=1};w(b,&k,"Ook! Ook. ")};if k>0{os.write(os.stdout,b[:k])}}))
  end

  def check(prev)
    raise if prev.bytesize > 1_000_000 || prev.include?("\0") || !prev.ascii_only?
  end
end

class Octave < CodeGen
  File = "QR.octave"
  Cmd = "mv QR.m QR.m.bak && octave -qf QR.octave > OUTFILE && mv QR.m.bak QR.m"
  Apt = "octave"
  Code = %q((p5om={?%=>"%0",B=>"%1",?"=>"%2",?'=>"%3",N=>"%4",?$=>"%5"};p5os=%("#{(PREV).gsub(Regexp.union(*p5om.keys),p5om)}");[[1,92],[2,34],[3,39],[4,10],[5,36],[0,37]].each{|p5oi,p5oc|p5os=%(strrep(#{p5os},"%#{p5oi}",char(#{p5oc})))};"printf(\"%s\",#{p5os});#{N}"))
  def check(prev)
    raise if prev =~ /[^\n\x20-\x7e]/
  end
end

class OCaml < CodeGen
  File = "QR.ml"
  Cmd = "ocaml QR.ml > OUTFILE"
  Apt = "ocaml"
  Code = %q("print_string#{E[PREV]}")
end

class ObjC < CodeGen
  Name = "Objective-C"
  File = "QR.m"
  Cmd = "gcc -o QR QR.m -lobjc && ./QR > OUTFILE"
  Apt = "gobjc"
  Code = %q("#import<stdio.h>#{N}#import<objc/Object.h>#{N}@interface Q:Object#{N}+(void)p;#{N}@end#{N}@implementation Q#{N}+(void)p{puts#{E[PREV]};}#{N}@end#{N}int main(){[Q p]#{R}}")
end

class Oberon < CodeGen
  Name = "Oberon"
  File = "QR.obn"
  Cmd = "rm -rf QR .obnc && obnc QR.obn >/dev/null && ./QR > OUTFILE && rm -rf QR .obnc"
  Backup = [["[ ! -f QR.c ] || mv QR.c QR.c.bak", "[ ! -f QR.c.bak ] || mv QR.c.bak QR.c"]]
  Apt = [nil]
  Code = %q((nop=[];(PREV).lines.each{|nol|nol.chomp.split(/([\x22\t])/).flat_map{|noq|noq=="\x22"||noq=="\t" ? [noq] : noq.scan(/.{1,2000}/)}.each{|noc|nop<<(noc=="\x22" ? "Out.Char(22X);" : noc=="\t" ? "Out.Char(9X);" : "Out.String(\x22"+noc+"\x22);")};nop<<"Out.Ln;" if nol.end_with?(N)};nog=nop.each_slice(400).to_a;"MODULE QR;IMPORT Out;"+N+nog.each_with_index.map{|nox,noi|nor=[];nox.each{|nos|nor[-1]&&nor[-1].size+nos.size<4000 ? nor[-1]<<nos : nor<<nos.dup};"PROCEDURE P#{noi};BEGIN"+N+nor*N+N+"END P#{noi};"}*N+N+"BEGIN"+N+(0...nog.size).map{|noi|"P#{noi};"}.each_slice(20).map(&:join)*N+N+"END QR."+N))

  def check(prev)
    raise unless prev.ascii_only?
    raise if prev.include?("\r")
  end
end

class Nushell < CodeGen
  Name = "Nushell"
  File = "QR.nu"
  Cmd = "nu --no-config-file QR.nu > OUTFILE"
  Apt = [nil]
  Code = %q(%(print -n r#####'#{PREV}'#####))
  def check(prev)
    raise if prev.include?("'#####") || prev.include?("\0") || prev.include?("\r")
  end
end

class Numbat < CodeGen
  Name = "Numbat"
  File = "QR.nbt"
  Cmd = "numbat QR.nbt > OUTFILE"
  Apt = [nil]                # cargo install numbat-cli 1.24.0, see src/extra-installs/
  Code = %q(%(print("#{e[PREV].gsub(/[{}]/){$&*2}}")))
  def check(prev)
    raise "Numbat: non-printable byte" if prev =~ /[^\n\x20-\x7e]/
  end
end

class Nim < CodeGen
  File = "QR.nim"
  Cmd = "nim compile --hints:off --warnings:off QR.nim && ./QR > OUTFILE"
  Apt = "nim"
  Code = %q((p1nm={?#=>"#0",B=>"#1",?"=>"#2",?'=>"#3",N=>"#4",?%=>"#5",?}=>"#6"};p1ns=%("#{(PREV).gsub(Regexp.union(*p1nm.keys),p1nm)}");[[1,92],[2,34],[3,39],[4,10],[5,37],[6,125],[0,35]].each{|p1ni,p1nc|p1ns=%(r(#{p1ns},"##{p1ni}",#{p1nc}))};%(import strutils#{N}proc r(s,p:string;c:int):string=s.replace(p,$chr(c))#{N}stdout.write(#{p1ns})#{N})))
end

class Nickle < CodeGen
  File = "QR.5c"
  Cmd = "nickle QR.5c > OUTFILE"
  Apt = "nickle"
  Code = %q("printf#{E[PREV]};")

  def check(prev)
    # it becomes printf's format string
    raise if prev.include?(?%)
  end
end

class Nial < CodeGen
  Name = "Nial"
  File = "QR.ndf"
  Cmd = "nial -defs QR.ndf < /dev/null > OUTFILE"
  Apt = [nil]                # Q'Nial 7 core, source build (pinned commit), see src/extra-installs/
  Code = %q(%(writechars link '#{d[PREV,?'].gsub(N,"' (char 10) '")}' ;#{N}bye#{N}))
  def check(prev)
    raise "Nial: non-printable byte" if prev =~ /[^\n\x20-\x7e]/
  end
end

class NewLISPLang < CodeGen
  Name = "newLISP"
  File = "QR.nl"
  Cmd = "newlisp -n QR.nl > OUTFILE"
  Apt = "newlisp"
  Code = %q(%((print [text]#{PREV}[/text])(exit)))

  def check(prev)
    raise if prev.include?("[/text]") # it closes the raw text block
  end
end

class NesC < CodeGen
  Name = "nesC"
  File = "QR.nc"
  # gcc 15 headers use C23 nullptr, which nesC 1.4.0 cannot parse; gcc-14 is its C back end
  Cmd = "nescc -gcc=gcc-14 -o QR QR.nc && ./QR > OUTFILE"
  Apt = [nil] # built from source in src/extra-installs/
  # every "?" becomes "\?" so no "??x" in the payload can turn into a trigraph
  Code = %q(%(#include<stdio.h>\nmodule QR{}implementation{int main()__attribute__((C,spontaneous)){puts#{E[PREV].gsub(??){B+$&}};return 0;} }))

  def check(prev)
    raise if prev =~ /[^\n -~]/ # e[] only escapes \ " and newline
  end
end

class Nelua < CodeGen
  Name = "Nelua"
  File = "QR.nelua"
  Cmd = "nelua --no-cache QR.nelua > OUTFILE"
  Apt = [nil]
  Code = %q(%(require 'io'\nio.write([===[#{PREV}]===])))
  def check(prev)
    raise if prev.include?("]===") || prev.include?("\r") || prev.include?("\0") || prev.start_with?("\n")
  end
end

class Neko < CodeGen
  File = "QR.neko"
  Cmd = "nekoc QR.neko && neko QR.n > OUTFILE"
  Apt = "neko"
  Code = %q((PREV).scan(/.{1,20000}/m).map{|m00n|"$print#{E[m00n]};"}*"")
end

class Mustache_NASM < CodeGen
  File = ["QR.mustache", "QR.asm"]
  Cmd = [
    "mustache QR.mustache QR.mustache > OUTFILE",
    "nasm -felf QR.asm && ld -m elf_i386 -o QR QR.o && ./QR > OUTFILE",
  ]
  Apt = ["ruby-mustache", "nasm"]
  def code
    <<-'END'.lines.map {|l| l.strip.gsub("^^^", " ") }.join("\\n")
      "_start{{!:
      q: |
      ^^^:mov edx,z-d
      ^^^global _start
      ^^^mov ecx,d
      ^^^inc ebx
      ^^^mov al,4
      ^^^int 128
      ^^^mov eax,1
      ^^^dec ebx
      ^^^int 128
      ^^^d:db\x60#{e[PREV]}\x60
      ^^^z:;}}{{{q}}}"
    END
  end

  def check(prev)
    raise if prev.include?(?`) # it closes NASM's `...` string, and e[] does not escape it
    # it closes the {{! ... }} comment that hides the YAML from the mustache pass
    raise if prev.include?("}}")
  end
end

class Murex < CodeGen
  Name = "Murex"
  File = "QR.mx"
  Cmd = "murex QR.mx > OUTFILE"
  Apt = [nil]
  # Split '{' before any Murex ANSI constant token ({F3}, {RED}, {RESET}, {+U}, etc.) so tout prints it literally.
  Code = %q(%(tout str '#{(PREV).gsub(?',%(';tout str "'";tout str ')).gsub(/\{(?=[[:alnum:]_+-]+\})/){"';tout str '{';tout str '"}}'))
  def check(prev)
    raise if prev.include?("\0") || prev.include?("\r")
  end
end

class MUMPS < CodeGen
  Name = "MUMPS"
  File = "QRMUMPS.m"
  Cmd = "ydb_dist=/opt/yottadb ydb_routines=. /opt/yottadb/yottadb -run QRMUMPS > OUTFILE"
  Apt = [nil]
  Code = %q(("QRMUMPS\n U 0:NOWRAP\n"+(PREV).scan(/.{1,12000}/m).map{|s|" W "+s.split(/(\n|\t)/).reject(&:empty?).map{|t|(t==N)?"!":(t==9.chr)?"$C(9)":?"+d[t]+?"}.join(",")+"\n"}.join+" Q\n"))
  def check(prev)
    raise "MUMPS: non-printable or non-ASCII byte" if prev =~ /[^\t\n\x20-\x7e]/
  end
end

class MSIL < CodeGen
  File = "QR.il"
  Cmd = "ilasm QR.il && mono QR.exe > OUTFILE"
  Apt = "mono-devel"
  def code
    <<-'END'.lines.map {|l| l.strip }.join
      %(
        .assembly t{}
        .method #$L void m()
        {
          .entrypoint ldstr"#{e[PREV]}"
          call void [mscorlib]#{C*"::"}(string)
          ret
        }
      )
    END
  end
end

class Modula2 < CodeGen
  Name = "Modula-2"
  File = "QR.mod"
  Cmd = "gm2 -fiso QR.mod -o QR && ./QR > OUTFILE"
  Apt = "gm2"
  def code
    <<-'END'.lines.map {|l| l.strip }.join
      "
        MODULE Q;
        IMPORT StrIO;
        BEGIN #{
          PREV.gsub(/()[#{i=?^}"]+|[#{i}']+/){
            ["StrIO.WriteString(",$&,");"]*($1??":?')
          }
        }END Q.
      "
    END
  end

  def check(prev)
    # it is cut into "..." and '...' literals without escaping, and neither can span lines
    raise if prev.include?("\n")
  end
end

class MMIX < CodeGen
  Name = "MMIX"
  File = "QR.mms"
  Cmd = "mmixal -b 2000000 -o QR.mmo QR.mms && mmix QR.mmo > OUTFILE && rm -f QR.mmo"
  Apt = [nil]
  Code = %q(" LOC #100\nMain GETA $255,S\n TRAP 0,Fputs,StdOut\n SET $255,0\n TRAP 0,Halt,0\nS BYTE "+(PREV).scan(/[\x20\x21\x23-\x7e]{1,100000}|./m).map{|b18m|b18m=="\x22"||b18m==N ? b18m.ord : %("#{b18m}")}.join("\n BYTE ")+",0\n")
  def check(prev)
    raise "MMIX: bad byte" if !prev.ascii_only? || prev =~ /[\x00-\x09\x0b-\x1f\x7f]/
  end
end

class Mirth < CodeGen
  Name = "Mirth"
  File = "QR.mth"
  Cmd = "mirth -p std:/opt/mirth/lib/std -p qr:. ./QR.mth -o QR.mth.c > /dev/null && $(CC) -O2 -Wno-trigraphs -o QR QR.mth.c && ./QR > OUTFILE"
  Apt = [nil]
  Code = %q(("module qr.QR\nimport std.prelude\nimport std.world\ndef main{\n"+(PREV).scan(/.{1,30000}/m).map{|s|%( "#{e[s].gsub(9.chr,B+?t)}" print-\n)}.join+"}\n"))
  def check(prev)
    raise "Mirth: non-printable or non-ASCII byte" if prev =~ /[^\t\n\x20-\x7e]/
  end
end

class Miranda < CodeGen
  Name = "Miranda"
  File = "QR.mira"
  Cmd = "mira -exec QR.mira > OUTFILE"
  Apt = [nil]
  Code = %q(("main=["+(PREV).scan(/.{1,12000}/m).map{|s|%(Stdout "#{e[s].gsub(9.chr,B+?t)}")}*","+"]\n"))
  def check(prev)
    raise "Miranda: non-printable or non-ASCII byte" if prev =~ /[^\t\n\x20-\x7e]/
  end
end

class MiniZinc < CodeGen
  File = "QR.mzn"
  Cmd = "minizinc --solver COIN-BC --soln-sep '' QR.mzn > OUTFILE"
  Apt = "minizinc"
  Code = %q("output#{E[PREV]}")
end

class MiniScript < CodeGen
  Name = "MiniScript"
  File = "QR.ms"
  Cmd = "miniscript QR.ms > OUTFILE"
  Apt = [nil]
  # "..." has zero backslash escapes (only "" -> "). print s, "" omits trailing newline.
  Code = %q(((PREV).lines.map{|l|l.end_with?(N) ? %(print "#{d[l.chomp]}") : %(print "#{d[l]}","")}.join(N)+N))

  def check(prev)
    raise "MiniScript: NUL, CR, or non-ASCII" if prev.include?("\0") || prev.include?("\r") || !prev.ascii_only?
  end
end

class Mercury < CodeGen
  Name = "Mercury"
  File = "qr_mercury.m"
  Cmd = "mmc --make qr_mercury > /dev/null && ./qr_mercury > OUTFILE"
  Apt = [nil]                # see src/extra-installs/
  Code = %q((p1mm={?@=>"@0",B=>"@1",?"=>"@2",?'=>"@3",N=>"@4",?$=>"@5"};p1ms=%("#{(PREV).gsub(Regexp.union(*p1mm.keys),p1mm)}");[[1,92],[2,34],[3,39],[4,10],[5,36],[0,64]].each{|p1mi,p1mc|p1ms=%(r(#{p1ms}, "@#{p1mi}", #{p1mc}))};%(:- module qr_mercury. :- interface. :- import_module io. :- pred main(io::di, io::uo) is det. :- implementation. :- import_module string, char. :- func r(string, string, int) = string. r(S, P, C) = string.replace_all(S, P, string.from_char(char.det_from_int(C))). main(!IO) :- io.write_string(#{p1ms}, !IO).)))
  def check(prev)
    raise "Mercury: non-printable byte" if prev =~ /[^\n\x20-\x7e]/
  end
end

class MaximaLang < CodeGen
  Name = "Maxima"
  File = "QR.mac"
  Cmd = "maxima -q --init-mac=QR.mac > OUTFILE"
  Apt = "maxima"
  Code = %q(%(linel:99999;printf(true,sconcat(ascii(126),"a"),sconcat(#{PREV.split(/(["\n])/).map{|x|x==?"?"ascii(34)":x==N ? "ascii(10)":%("#{x}")}*?,}));quit();))
  def check(prev)
    raise "Maxima: backslash in the payload" if prev.include?("\\")
  end
end

class Mathics < CodeGen
  Name = "Mathics"
  File = "QR.wl"
  Cmd = "mathics -q --no-completion -f QR.wl < /dev/null > OUTFILE"
  Apt = [nil]                # pip mathics3==10.0.1, see src/extra-installs/
  Code = %q((require"zlib";%(WriteString["stdout",Uncompress["#{[Object.const_get("Zlib")::Deflate.deflate(%("#{e[PREV]}"),9)].pack("m0").gsub("//","/\x22<>\x22/")}"]])))
  def check(prev)
    raise "Mathics: non-printable byte" if prev =~ /[^\n\x20-\x7e]/
  end
end

class Macaulay2_Makefile_MalbolgeUnshackled < CodeGen
  Name = ["Macaulay2", "Makefile", "Malbolge Unshackled"]
  File = ["QR.m2", "QR.mk", "QR.mb"]
  Cmd = [
    "M2 --script QR.m2 > OUTFILE",
    "make -f QR.mk > OUTFILE",
    "unshackled QR.mb < /dev/null > OUTFILE"
  ]
  Apt = ["macaulay2", "make", nil]
  def code
    require "base64"
    require "zlib"
    boot = ::File.read(::File.join(__dir__, "malbolge-boot.dat")).strip
    w = Zlib::Inflate.inflate(Base64.decode64(boot))
    w1 = w[0, 861].b
    w2 = w[861, 112].b
    rg = (0...100).map { |i| w.getbyte(973 + i) + (w.getbyte(1073 + i) << 8) }.join(",")
    m2 = <<-'END'
s=///PAYLOAD///;
w1=ascii ///W1///;
w2=ascii ///W2///;
co=apply(94,i->33+(35-i)%94);
cp=apply(94,i->33+(29-i)%94);
cr=apply(94,i->33+(6-i)%94);
cj=apply(94,i->33+(7-i)%94);
cu=apply(94,i->33+(66-i)%94);
cv=apply(94,i->33+(48-i)%94);
rg=new MutableList from {RG};
<< "MAKEFLAGS += -s\ndefine M\n";
buf=new MutableList from apply(25100,i->0);
bp=0;
c=0;
fls=()->(
  if bp>0 then (
    << ascii apply(bp,i->buf#i) << "\n";
    bp=0;
  );
);
emit=(x)->(buf#bp=x;bp=bp+1;c=c+1;if bp>=25000 and x!=92 then fls(););
for i from 0 to #w1-1 do emit(w1#i);
for i from 0 to 597 do emit(co#((861+i)%94));
for i from 0 to #w2-1 do emit(w2#i);
cz={{1,0,0},{1,0,2},{2,2,1}};
c2=new MutableList from apply(9,y->apply(9,x->cz#(y//3)#(x//3)*3+cz#(y%3)#(x%3)));
c4=new MutableList from apply(81,y->apply(81,x->(c2#(y//9))#(x//9)*9+(c2#(y%9))#(x%9)));
c5=new MutableList from apply(243,y->new MutableList from apply(243,x->0));
for y from 0 to 242 do (
  cy:=c5#y;cyq:=c4#(y//3);czr:=cz#(y%3);
  for x from 0 to 242 do cy#x=(cyq#(x//3))*3+czr#(x%3);
);
oc=new MutableList from apply(486,d->new MutableList from apply(486,a->0));
rt=new MutableList from apply(486,i->-1);
m2=new MutableList from apply(486,i->0);
m0=new MutableList from apply(486,i->0);
for d from 0 to 485 do (
  dh:=d//243;dl:=d%243;
  if dl%3==dh then rt#d=dh*243+dl//3+dh*81;
  q2:=0;q0:=0;u:=dl;
  for k from 0 to 4 do (t0:=u%3;u=u//3;if t0==2 then q2=q2+(1<<k);if t0==0 then q0=q0+(1<<k););
  m2#d=q2;m0#d=q0;cl:=oc#d;cy:=c5#dl;h0:=cz#dh#0*243;h1:=cz#dh#1*243;
  for a from 0 to 242 do (cl#a=h0+cy#a;cl#(a+243)=h1+cy#a;);
);
n=100;a=116;d=6;
sv=new MutableList from apply(486,i->0);
ps=new MutableList from apply(486,i->0);
pp=new MutableList from apply(486,i->0);
po=new MutableList from apply(486,i->0);
fr=new MutableList from apply(486,i->0);
ds=new MutableList from apply(105,i->0);
op=new MutableList from apply(105,i->0);
vr=0;
tw=new MutableList from apply(5,k->sum(100,i->((m2#(rg#i))>>k)&1));
zr=new MutableList from apply(5,k->sum(100,i->((m0#(rg#i))>>k)&1));
upd=(u,nw)->(
  ol:=rg#u;
  if ol!=nw then (
    a2:=m2#ol;b2:=m2#nw;a0:=m0#ol;b0:=m0#nw;rg#u=nw;
    if a2!=b2 then (df:=a2+b2-2*(a2&b2);for k from 0 to 4 do if ((df>>k)&1)!=0 then tw#k=tw#k+(if ((b2>>k)&1)!=0 then 1 else -1););
    if a0!=b0 then (df2:=a0+b0-2*(a0&b0);for k from 0 to 4 do if ((df2>>k)&1)!=0 then zr#k=zr#k+(if ((b0>>k)&1)!=0 then 1 else -1););
  );
);
bs=ascii s;
for bi from 0 to #bs-1 do (
  b:=bs#bi;mt:=20;fb:=0;
  while a!=b do (
    n2:=(if tw#0<=mt then 1 else 0)+(if tw#1<=mt then 2 else 0)+(if tw#2<=mt then 4 else 0)+(if tw#3<=mt then 8 else 0)+(if tw#4<=mt then 16 else 0);
    n0:=(if zr#0<=mt then 1 else 0)+(if zr#1<=mt then 2 else 0)+(if zr#2<=mt then 4 else 0)+(if zr#3<=mt then 8 else 0)+(if zr#4<=mt then 16 else 0);
    fcap:=if fb==0 then 64 else 486;
    vr=vr+1;sv#a=vr;fr#0=a;flen:=1;dlen:=0;cd:=d;vs:=0;fd:=false;hp:=0;ho:=0;si:=0;
    while vs<n do (
      if cd==n then (ds#dlen=n;dlen=dlen+1;cd=0;si=si+1;continue);
      md:=rg#cd;p2:=n2&(m2#md);p0:=n0&(m0#md);
      rv:=if (p2|p0)==0 then rt#md else -1;
      if rv==b then (hp=a;ho=2;ds#dlen=cd;dlen=dlen+1;fd=true;break);
      fl:=flen;cl:=oc#md;
      if (p2|p0)==0 then (
        for i from 0 to fl-1 do (
          v:=fr#i;z:=cl#v;
          if z==b then (hp=v;ho=1;ds#dlen=cd;dlen=dlen+1;fd=true;break);
          if flen<fcap and sv#z!=vr then (sv#z=vr;ps#z=si;pp#z=v;po#z=1;fr#flen=z;flen=flen+1);
        );
      ) else (
        for i from 0 to fl-1 do (
          v:=fr#i;
          if ((m2#v)&p2)==0 and ((m0#v)&p0)==0 then (
            z:=cl#v;
            if z==b then (hp=v;ho=1;ds#dlen=cd;dlen=dlen+1;fd=true;break);
            if flen<fcap and sv#z!=vr then (sv#z=vr;ps#z=si;pp#z=v;po#z=1;fr#flen=z;flen=flen+1);
          );
        );
      );
      if fd then break;
      if flen<fcap and rv!=-1 and sv#rv!=vr then (sv#rv=vr;ps#rv=si;pp#rv=a;po#rv=2;fr#flen=rv;flen=flen+1);
      ds#dlen=cd;dlen=dlen+1;cd=cd+1;vs=vs+1;si=si+1;
    );
    if fd then (
      for i from 0 to dlen-2 do op#i=0;
      op#(dlen-1)=ho;v:=hp;
      while v!=a do (s0:=ps#v;op#s0=po#v;v=pp#v);
      for i from 0 to dlen-1 do (
        u:=ds#i;
        if u==n then (emit(cj#(c%94));d=0)
        else if op#i==0 then (emit(co#(c%94));d=d+1)
        else (nw:=0;if op#i==1 then (emit(cp#(c%94));nw=(oc#(rg#u))#a) else (emit(cr#(c%94));nw=rt#(rg#u));upd(u,nw);a=nw;d=d+1;);
      );
    ) else (
      fb=fb+1;mt=max(0,mt-6);
      if mt==0 and fb>4 then (if d==n then (emit(cj#(c%94));d=0);nw:=(oc#(rg#d))#a;emit(cp#(c%94));upd(d,nw);a=nw;d=d+1;);
    );
  );
  if d==n then (emit(cj#(c%94));d=0);
  emit(cu#(c%94));d=d+1;
);
emit(cv#(c%94));
while (c+2)%564!=34 do emit(co#(c%94));
emit(36);emit(101);
fls();
<< "endef\n$(info $(value M))\na:;\n";
END
    m2 = m2.lines.map(&:strip).join("\n")
    m2 = m2.sub("W1") { w1 }.sub("W2") { w2 }.sub("RG") { rg }
    esc = m2.gsub("\\", "\\\\\\\\").gsub('"', '\\"').gsub("#", '\\#').gsub("(", '\\x28').gsub(")", '\\x29').gsub("\n", "\\n")
    '"' + esc.sub("PAYLOAD") { '#{PREV}' } + '"'
  end

  def check(prev)
    raise "Macaulay2_Makefile_MalbolgeUnshackled: non-ASCII or ///" if !prev.ascii_only? || prev.include?("///")
  end
end

class M4 < CodeGen
  File = "QR.m4"
  Cmd = "m4 QR.m4 > OUTFILE"
  Apt = "m4"
  Code = %q((p5m4=(PREV);p5ml,p5mr=[["<@","@>"],["<%","%>"],["<#","#>"],["<[","]>"],["<{","}>"]].find{|p5a,p5b|p5m4.index(p5a)==nil&&p5m4.index(p5b)==nil};"changequote(#{p5ml},#{p5mr})#{p5ml}#{p5m4}#{p5mr}"))
  def check(prev)
    raise "M4: no free quote pair" if [["<@","@>"],["<%","%>"],["<#","#>"],["<[","]>"],["<{","}>"]].none? { |a, b| !prev.include?(a) && !prev.include?(b) }
  end
end

class Lua < CodeGen
  File = "QR.lua"
  Cmd = "lua5.3 QR.lua > OUTFILE"
  Apt = "lua5.3"
  Code = %q((p5ls=(PREV);p5le="="*((1..10).find{|p5lk|p5ls.index("]"+"="*p5lk+"]")==nil});"io.write([#{p5le}[#{N}#{p5ls}]#{p5le}])"))
  def check(prev)
    raise "Lua: CR" if prev.include?("\r")
  end
end

class LOLCODE < CodeGen
  File = "QR.lol"
  Cmd = "lci QR.lol > OUTFILE"
  Apt = [nil]
  Code = %q("HAI 1\n"+(PREV).scan(/.{1,10000}/m).map{|p3lc|"VISIBLE \""+p3lc.gsub(/[:"]/){":"+ $&}.gsub(N,":#{41.chr}")+"\"!"}.join(N)+"\nKTHXBYE\n")
  def check(prev)
    raise "LOLCODE: CR or NUL" if prev.include?("\r") || prev.include?("\0")
  end
end

class Lobster < CodeGen
  Name = "Lobster"
  File = "QR.lobster"
  Cmd = "lobster QR.lobster > OUTFILE"
  Apt = [nil]
  Code = %q(((PREV).chomp.split(N,-1).each_slice(3).map{|a|%(print """#{a*N}""")}*N+N))
  def check(prev)
    raise "Lobster: payload holds triple quote" if prev.chomp.include?('"""')
    raise "Lobster: NUL or CR" if prev.include?("\0") || prev.include?("\r")
    prev.chomp.split("\n", -1).each_slice(3) do |a|
      s = a.join("\n")
      raise "Lobster: chunk >= 90KB (truncates at 100KB)" if s.bytesize >= 90_000
      raise "Lobster: chunk ends with quote" if s.end_with?('"')
    end
  end
end

class LLVMAsm < CodeGen
  Name = "LLVM asm"
  File = "QR.ll"
  Cmd = "llvm-as QR.ll && lli QR.bc > OUTFILE"
  Apt = "llvm"
  Backup = "QR.bc"
  def code
    <<-'END'.lines.map {|l| l.strip }.join
      %(
        @s=global[#{(s=PREV).size+1}x i8]
          c"#{s.gsub(/[\\"\n\t]/){"\\%02x"%$&.ord}}\\00"
        declare i32@puts(ptr)
        define i32@main(){
          call i32@puts(ptr@s)
          ret i32 0
        }
      )
    END
  end

  def check(prev)
    raise if prev.include?("\0") # @s is a NUL-terminated C string printed by puts
  end
end

class LiveScriptLang < CodeGen
  Name = "LiveScript"
  File = "QR.ls"
  Cmd = "lsc QR.ls > OUTFILE"
  Apt = "livescript"
  Backup = "QR.c"
  Code = %q("console.log#{Q[E[PREV],?#]}")
  def check(prev)
    raise "LiveScript: non-ASCII" unless prev.ascii_only?
  end
end

class Lisaac < CodeGen
  File = "qr.li"
  Cmd = "lisaac -gcc -Wno-implicit-function-declaration qr.li > /dev/null && ./qr > OUTFILE"
  Apt = [nil] # noble lisaac 0.39~rc1 .debs, see src/extra-installs/
  # a source line must stay under 255 columns, so print 88-char pieces, one per line
  Code = %q(%(Section Header+name:=QR;Section Public-main<-(#{(PREV).scan(/.{1,88}/m).map{|c|N+%("#{e[c]}".print;)}*""}#{N});))
  def check(prev); raise if prev =~ /[^\t\n -~]/; end
end

class Lily < CodeGen
  Name = "Lily"
  File = "QR.lily"
  Cmd = "lily QR.lily > OUTFILE"
  Apt = [nil]
  # Chunked 16KB/line: well under lily_lexer.c's uint16_t line-offset limit (<=32KB escaped) and under __main__'s literal cap.
  Code = %q(((PREV).scan(/.{1,16000}/m).map{|s|%(stdout.write("#{e[s]}"))}*N+N))

  def check(prev)
    raise "Lily: NUL, CR, or non-ASCII" if prev.include?("\0") || prev.include?("\r") || !prev.ascii_only?
  end
end

class LFE < CodeGen
  Name = "LFE"
  File = "QR.lfe"
  Cmd = "lfe QR.lfe > OUTFILE"
  Apt = "erlang-nox"
  Code = %q("(io:put_chars \"#{e[PREV]}\")\n(erlang:halt 0)\n")
  def check(prev)
    raise "LFE: non-ASCII" unless prev.ascii_only?
  end
end

class Lean4 < CodeGen
  Name = "Lean 4"
  File = "QR.lean"
  Cmd = "lean --run QR.lean > OUTFILE"
  Apt = [nil]
  Code = %q(%(def main : IO Unit := IO.print r###"#{PREV}"###\n))
  def check(prev)
    raise "Lean 4: payload holds the raw-string end mark" if prev.include?(%("###))
    raise "Lean 4: non-ASCII byte" if prev =~ /[^\x00-\x7f]/n
  end
end

class Ksh_LazyK < CodeGen
  Name = ["ksh", "Lazy K"]
  File = ["QR.ksh", "QR.lazy"]
  Cmd = [
    "ksh QR.ksh > OUTFILE",
    "!lazyk QR.lazy > OUTFILE",
  ]
  Apt = ["ksh", nil]
  def code
    lazyk = ::File.read(::File.join(__dir__, "lazyk-boot.dat"))
    lazyk = lazyk.tr("ski`","0123")
    lazyk += "0" * (-lazyk.size % 3)
    lazyk = lazyk.scan(/.{3}/).map do |n|
      [*93..124,*42..73][n.to_i(4)]
    end.pack("C*")
    lazyk = lazyk.gsub(/[ZHJK\^`~X]/) {|c| "\\x%02x" % c.ord }
    <<-'END'.lines.map {|l| l.strip }.join.sub("LAZYK"){lazyk}
      %(
        p(){ print -rn -- "$1";};
        f(){ typeset -i i n=${#1} j x;typeset c;
          for((i=0;i<n;i++));do;
            c=${1:i:1};x=${ printf %d "'$c";};
            p $4;
            for((j=$3;j--;));do;
              h $2 $x $j;
            done;
          done;
        };
        p k\\`;
        h(){ p \\`${1:$2>>$3&1:2};};
        f '#{(PREV).gsub(?',%('"'"'))}' kki 7 '#{"``s"*8}i';
        h(){ p ${1:$2%83-10>>$3*2&3:1};};
        f 'LAZYK' ski\\` 3
      )
    END
  end

  def check(prev)
    raise "ksh/Lazy K: non-ASCII" unless prev.ascii_only?
  end
end

class Koto < CodeGen
  File = "QR.koto"
  Cmd = "koto QR.koto > OUTFILE"
  Apt = [nil] # cargo install koto_cli
  Code = %q(%(io.stdout().write r#'#{PREV}'#))

  def check(prev)
    raise if prev.include?("'#")
  end
end

class Kotlin < CodeGen
  File = "QR.kt"
  Cmd = "kotlinc QR.kt -include-runtime -d QR.jar && kotlin QR.jar > OUTFILE"
  Apt = "kotlin"
  Code = %q("fun main(){"+(PREV).scan(/.{1,15000}/m).map{|p6c|"print(\"#{Q[e[p6c]]}\");"}*""+"}")
  def check(prev)
    raise "Kotlin: non-ASCII or CR" if prev.include?("\r") || !prev.ascii_only?
  end
end

class Koka < CodeGen
  Name = "Koka"
  File = "qr.kk"
  Cmd = "koka -v0 -o qrkoka qr.kk && chmod +x qrkoka && ./qrkoka > OUTFILE"
  Apt = [nil]
  Code = %q((p6kp=(PREV);p6kh="##";p6kh+="#" while p6kp.include?('"'+p6kh);%(fun main(){print(r#{p6kh}"#{p6kp}"#{p6kh})})))
  def check(prev)
    raise "Koka: control character" if prev =~ /[\x00-\x08\x0b-\x1f\x7f]/
    raise "Koka: not UTF-8" unless prev.dup.force_encoding("UTF-8").valid_encoding?
  end
end

class Klong < CodeGen
  Name = "Klong"
  File = "QR.kg"
  Cmd = "kg QR.kg < /dev/null > OUTFILE"
  Apt = [nil]                # Klong 20221212 source build, see src/extra-installs/
  Code = %q(%(.d(#{PREV.scan(/.{1,128}/m).map{|s|?"+d[s]+?"}*?,})#{N}))
  def check(prev)
    raise "Klong: non-printable byte" if prev =~ /[^\n\x20-\x7e]/
  end
end

class Kipple < CodeGen
  Name = "Kipple"
  File = "QR.kpl"
  Cmd = "cipple QR.kpl > OUTFILE"
  Apt = [nil]
  Code = %q(((PREV).scan(/[\x00-\x09\x0b-\x21\x23-\x5a\x5e-\x7f]+|./m).map{|p3kc|p3kc.size==1&&"\x0a\x22\x5b\x5c\x5d".index(p3kc) ? "#{p3kc.ord}>i" : "i<\x22#{p3kc}\x22"}*" "+" (i i>o)"))
  def check(prev)
    raise "Kipple: non-ASCII" unless prev.ascii_only?
  end
end

class K < CodeGen
  Name = "K (ngn/k)"
  File = "QR.k.k"
  Cmd = "ngnk QR.k.k < /dev/null > OUTFILE"
  Apt = [nil]
  Code = %q(%(#{(PREV).b.scan(/[\n\x20-\x7e]{1,250}|[\x00-\x09\x0b-\x1f\x7f-\xff]{1,80}/n).map{|p4k|p4k.match?(/\A[\n\x20-\x7e]+\z/n) ? "`1:"+?"+e[p4k]+?" : "`1:`c$"+(p4k.bytesize==1 ? ","+p4k.ord.to_s : p4k.bytes*" ")}*N}#{N+B+B+N}))
end

class JuliaLang < CodeGen
  Name = "Julia"
  File = "QR.jl"
  Cmd = "julia QR.jl > OUTFILE"
  Apt = [nil]   # src/extra-installs/
  def code
    <<-'END'.lines.map {|l| l.strip }.join
      (
        p1js=PREV;
        p1jn=p1js.bytesize;
        p1je=->(x){(x<54 ? x+37 : x+40).chr};
        p1jh=Array.new(256,-1);
        p1jp=Array.new(p1jn,-1);
        p1jb=+"";
        p1jl=+"";
        p1jf=->{
          while p1jb.bytesize>0;
            p1ju=p1jb.byteslice(0,20);
            p1jb=p1jb.byteslice(20,p1jb.bytesize)||+"";
            p1jl<<p1je[p1ju.bytesize-1]<<p1ju;
          end
        };
        p1jsk=0;
        p1jn.times{|p1ji|
          p1jc=p1js.getbyte(p1ji);
          if p1jsk>0;
            p1jsk-=1;
          else;
            p1jbk=0;p1jbj=0;
            if p1jc!=91&&p1jc!=93;
              p1jj=p1jh[p1jc];
              while p1jj>=0&&(p1ji-p1jj)<=5829;
                p1jk=0;
                while p1jk<90&&p1ji+p1jk<p1jn&&(p1jy=p1js.getbyte(p1ji+p1jk))!=91&&p1jy!=93&&p1jy==p1js.getbyte(p1jj+p1jk);
                  p1jk+=1;
                end;
                if p1jk>p1jbk;
                  p1jbk=p1jk;p1jbj=p1jj;
                  break if p1jk==90;
                end;
                p1jj=p1jp[p1jj];
              end;
            end;
            if p1jbk>=4;
              p1jf.call;
              p1jd=p1ji-p1jbj-1;
              p1jl<<p1je[20+p1jd/87]<<p1je[p1jd%87]<<p1je[p1jbk-4];
              p1jsk=p1jbk-1;
            else;
              p1jb<<p1jc;
            end;
          end;
          p1jp[p1ji]=p1jh[p1jc];
          p1jh[p1jc]=p1ji;
        };
        p1jf.call;
        p1jq=e[p1jl].gsub("$",B+"$");
        %(function q();p=codeunits("#{p1jq}");o=UInt8[];i=1;n=length(p);g(k)=(x=Int(p[k]);x-(x>93 ? 40 : 37));while i<=n;c=g(i);if c<20;m=c+1;append!(o,@view p[i+1:i+m]);i+=m+1;else;d=(c-20)*87+g(i+1)+1;m=g(i+2)+4;for _ in 1:m;push!(o,o[end-d+1]);end;i+=3;end;end;write(stdout,o);end;q()\n)
      )
    END
  end
  def check(prev)
    raise "Julia: non-printable or non-ASCII byte" if prev =~ /[^\n\x20-\x7e]/
  end
end

class JavaScript_Jq_JSFuck < CodeGen
  Name = ["JavaScript", "Jq", "JSFuck"]
  File = ["QR.js", "QR.jq", "QR.jsfuck"]
  Cmd = [
    "$(JAVASCRIPT) QR.js > OUTFILE",
    "jq -r -n -f QR.jq > OUTFILE",
    "!$(JAVASCRIPT) --stack_size=100000 QR.jsfuck > OUTFILE",
  ]
  Apt = ["nodejs", "jq", "nodejs"]
  Code = %q(%(P={0:'[+[]]'};for(R of('![]@!![]@'+(A="[]['at']")+"@([]+[])['link']()@(+('11e20')+[])['split']([])@(+[])"+(C="['constructor']")).split('@'))for(E in D=eval(G='('+R+'+[])'))P[D[E]]||=G+"['"+E+"']";for(G='[',B=0;++B<36;)P[D=B.toString(36)]=B<10?(G+='+!+[]')+']':P[D]||"(+('"+B+"'))['to'+([]+[])"+C+"['name']]('36')";E=(s)=>{for(let r=8;r--;)s=s.replace(/'(.*?)'/g,(_,d)=>[...d].map(x=>P[x]).join('+'));return s};PE={};for(k of Object.keys(P))PE[k]=E(P[k]);bt=(a,l,r)=>{if(r-l<2)return a[l];let m=(l+r)>>1;return'('+bt(a,l,m)+'+'+bt(a,m,r)+')'};H='0123456789abcdef';T=[];for(c of'console.log(unescape("')T.push(PE[c]);for(c of"#{e[PREV.chomp]}"){v=c.charCodeAt(0);h1=PE[H[v>>4]];h2=PE[H[v&15]];if(v!=37&&v!=34&&v!=92&&v!=102&&PE[c]&&PE[c].length<5+h1.length+h2.length)T.push(PE[c]);else T.push('![]',h1,h2)}for(c of'".replace(/false/g,escape(" ")[0])))')T.push(PE[c]);console.log(JSON.stringify(E(A+C)+'('+bt(T,0,T.length)+')()'))\n))
  def check(prev)
    raise "JavaScript_Jq_JSFuck: must end with single newline" unless prev.end_with?("\n") && !prev.chomp.include?("\n")
    raise "JavaScript_Jq_JSFuck: non-printable ASCII" if prev.chomp =~ /[^\x20-\x7e]/
  end
end

class Java_ < CodeGen
  Name = "Java"
  File = "QR.java"
  Cmd = "javac QR.java && java QR > OUTFILE"
  Apt = "openjdk-25-jdk"
  Code = %q("class QR{#$L void main(String[]a){"+(PREV).scan(/.{1,15000}/m).map{|p6c|"System.out.print(\"#{e[p6c]}\");"}*""+"}}")
  def check(prev)
    raise "Java: non-ASCII or CR" if prev.include?("\r") || !prev.ascii_only?
  end
end

class Jasmin < CodeGen
  File = "QR.j"
  Cmd = "jasmin QR.j && java QR > OUTFILE"
  Apt = "jasmin-sable"
  def code
    <<-'END'.lines.map {|l| l.strip }.join
      %(
        .class QR\n
        .super #{S="java/lang/"}Object\n
        .method #$L main()V\n
        .limit stack 1\n
        #{PREV.scan(/.{1,20000}/m).map{|c|%(ldc "#{e[c]}"\ninvokestatic #{S}IO/print(L#{S}Object;)V\n)}*""}
        return\n
        .end method\n
      )
    END
  end

  def check(prev)
    # every piece becomes one CONSTANT_Utf8 via ldc
    prev.scan(/.{1,20000}/m) { raise if escape($&).bytesize > 65000 }
    # the dc stage carries the whole program inside a [...] string, which counts nesting
    raise unless prev.match?(BRACKETS)
  end
end

class Janet < CodeGen
  Name = "Janet"
  File = "QR.janet"
  Cmd = "janet QR.janet > OUTFILE"
  Apt = [nil]                # source build v1.43.0, see src/extra-installs/
  Code = %q(%((prin "#{e[PREV]}")))
  def check(prev)
    raise "Janet: non-printable byte" if prev =~ /[^\n\x20-\x7e]/
  end
end

class J < CodeGen
  Name = "J"
  File = "QR.ijs"
  Cmd = "ijconsole QR.ijs < /dev/null > OUTFILE"
  Apt = [nil]                # jsoftware j9.7 Linux tarball, see src/extra-installs/
  Code = %q(%(exit 0[('#{d[PREV,?'].gsub(N,"',(10{a.),'")}')1!:2(4)))
  def check(prev)
    raise "J: non-printable byte" if prev =~ /[^\n\x20-\x7e]/
  end
end

class IonShell < CodeGen
  Name = "Ion"
  File = "QR.ion"
  Cmd = "ion QR.ion > OUTFILE"
  Apt = [nil]
  Code = %q(("let q = \"'\"\nlet b = \"#{B*2}\"\nlet d = '$'\nlet a = '@'\nlet l = '['\nlet r = ']'\nlet o = '{'\nlet c = '}'\nlet p = '('\nlet k = ')'\nlet x = ''\n"+PREV.scan(/.{1,4000}/m).map{|i9c|"let x ++= '"+i9c.gsub(/[#{B*2}'$@\[\]{}()]/,{"'"=>"'$q'",B=>"'$b'","$"=>"'$d'","@"=>"'$a'","["=>"'$l'","]"=>"'$r'","{"=>"'$o'","}"=>"'$c'","("=>"'$p'",")"=>"'$k'"})+"'"}*N+"\necho -n $x\n"))
  def check(prev)
    raise if prev.include?("\0") || prev.include?("\r") || prev.start_with?("-")
  end
end

class IoLang < CodeGen
  Name = "Io"
  File = "QR.io"
  Cmd = "io QR.io > OUTFILE"
  Apt = [nil]                # source build (tag 2019.05.22-alpha, CMake), see src/extra-installs/
  Code = %q(%("#{e[PREV]}" print))
  def check(prev)
    raise "Io: non-printable byte" if prev =~ /[^\n\x20-\x7e]/
  end
end

class Inko_INTERCAL < CodeGen
  Name = ["Inko", "INTERCAL"]
  File = ["QR.inko", "QR.i"]
  Cmd = [
    "inko run QR.inko > OUTFILE",
    "ick -bfOc QR.i && gcc -std=c99 -static QR.c -I /usr/include/ick-* -o QR -lick && ./QR > OUTFILE"
  ]
  Backup = [nil, "QR.c"]
  Apt = [nil, "intercal"]
  Code = %q(%(import std.stdio (Stdout)#{N}import std.string (StringBuffer)#{N}type async Main {#{N}fn async main {#{N}let s = '#{(PREV).gsub(?@,"@A").gsub(B,"@D").gsub(?',"@C").gsub(?$,"@E")}'.replace('@D', '#{B+B}').replace('@C', '#{B}'').replace('@E', '#{B}$').replace('@A', '@') + '#{B}n'#{N}let b = StringBuffer.new#{N}let mut c = 0#{N}let mut n = 0#{N}let mut k = 0#{N}while k < s.size {#{N}let mut e = k + 60000#{N}if e > s.size { e = s.size }#{N}b.push('DO,1<-#')#{N}b.push((e - k).to_string)#{N}b.push('#{B}n')#{N}let mut i = 0#{N}let mut j = k#{N}while j < e {#{N}let mut t = s.get(j).or(0)#{N}i = i + 1#{N}n = n + 1#{N}let mut u = 0 - n#{N}let mut q = 0#{N}while q < 8 {#{N}u = (u * 2) + (t % 2)#{N}t = t / 2#{N}q = q + 1#{N}}#{N}if (i % 4) == 3 { b.push('PLEASE#{B}n') }#{N}b.push('DO,1SUB#')#{N}b.push(i.to_string)#{N}b.push('<-#')#{N}b.push(((c - u) % 256).to_string)#{N}b.push('#{B}n')#{N}c = u#{N}j = j + 1#{N}}#{N}b.push('PLEASEREADOUT,1#{B}n')#{N}k = e#{N}}#{N}b.push('PLEASEGIVEUP#{B}n')#{N}let _ = Stdout.new.write(b.into_string)#{N}}#{N}}#{N}))
  def check(prev)
    raise "Inko: not UTF-8" unless prev.dup.force_encoding("UTF-8").valid_encoding?
    raise "Inko: NUL" if prev.include?("\0")
  end
end

class Idris2 < CodeGen
  Name = "Idris 2"
  File = "QR.idr"
  Cmd = "idris2 --exec main QR.idr > OUTFILE"
  Apt = [nil]
  Code = %q(%(module Main\nmain : IO ()\nmain = putStr ##"""\n#{PREV}\n"""##\n))
  def check(prev)
    raise "Idris 2: payload holds the raw-string end mark" if prev.include?(%("##)) || prev.include?('\##')
    raise "Idris 2: non-ASCII byte" if prev =~ /[^\x00-\x7f]/n
  end
end

class IconLang < CodeGen
  Name = "Icon"
  File = "QR.icn"
  Cmd = "icont -s QR.icn && ./QR > OUTFILE"
  Apt = [["icont", "iconx"]]
  Code = %q(%(procedure main();#{(PREV).scan(/.{1,2000}/m).map{|a16c|"writes(\""+e[a16c].gsub(/[\x00-\x1f\x7f]/){B+"x%02x"%$&.ord}+"\");"}*""}end))
end

class Hy < CodeGen
  File = "QR.hy"
  Cmd = "hy QR.hy > OUTFILE"
  Apt = "hy"
  Code = %q(%((print "#{e[PREV]}" :end "")))
end

class Hope < CodeGen
  Name = "Hope"
  File = "QR.hop"
  Cmd = "hope -f QR.hop > OUTFILE"
  Apt = [nil]
  Code = %q((p9hps=(PREV);p9hpo=[];p9hpb=+"";p9hps.each_char{|p9hph|p9hpq=p9hph==B ? B+B : p9hph=="\"" ? B+"\"" : p9hph==N ? B+"n" : p9hph=="\t" ? B+"t" : p9hph;if p9hpb.bytesize+p9hpq.bytesize>94 then p9hpo<<%(write "#{p9hpb}";\n);p9hpb=+"" end;p9hpb<<p9hpq};p9hpo<<%(write "#{p9hpb}";\n) unless p9hpb.empty?;p9hpo*""))
  def check(prev)
    raise "Hope: non-printable or non-ASCII byte" if prev =~ /[^\t\n\x20-\x7e]/
  end
end

class HOC < CodeGen
  Name = "HOC"
  File = "QR.hoc"
  Cmd = "/usr/lib/plan9/bin/hoc QR.hoc > OUTFILE"
  Apt = "9base"
  Code = %q((p9hcs=(PREV);p9hco=[];p9hcb=+"";p9hcs.each_char{|p9hch|p9hcq=p9hch==B ? B+B : p9hch=="\"" ? B+"\"" : p9hch==N ? B+"n" : p9hch;if p9hcb.bytesize+p9hcq.bytesize>95 then p9hco<<%(print "#{p9hcb}");p9hcb=+"" end;p9hcb<<p9hcq};p9hco<<%(print "#{p9hcb}") unless p9hcb.empty?;p9hco*N+N))
  def check(prev)
    raise "HOC: NUL, CR, or non-ASCII" if prev.include?("\0") || prev.include?("\r") || !prev.ascii_only?
  end
end

class Haxe_Hexagony < CodeGen
  Name = ["Haxe", "Hexagony"]
  File = ["QR.hx", "QR.hxg"]
  Cmd = [
    "haxe -main QR -neko QR.n && neko QR.n > OUTFILE",
    "ruby /opt/hexagony/interpreter.rb QR.hxg > OUTFILE"
  ]
  Apt = ["haxe", nil]
  Code = %q(%(class QR{#$L function main(){var u=new StringBuf();#{(PREV).scan(/.{1,4000}/m).map{|p07s|"u.add#{E[p07s]};"}*""}var s=u.toString();var v=0;var t:Array<String>=[];var z=1;for(i in 0...s.length){var b:Int=s.charCodeAt(i);var d=b==v?"":b==v+1?"\x29":b==v-1?"\x28":(b>64&&b<91)||(b>96&&b<123)?String.fromCharCode(b):"-"+b;v=b;var tok=d+";";t.push(tok);z+=tok.length;}t.push("@");var m=4;while(3*m*(m-1)-14*m<z)m++;var p=0;var o=new StringBuf();for(i in 0...2*m-1){var l=2*m-1-(m-1-i<0?i-(m-1):m-1-i);var c=(i==0||i==2*m-2)?l-1:(i%2==1)?l-2:(i==m-1)?l-4:l-3;var r=new StringBuf();var rl=0;while(p<t.length&&rl+t[p].length<=c){r.add(t[p]);rl+=t[p].length;p++;}while(rl<c){r.add(".");rl++;}var rs=r.toString();if(i==0){o.add(rs);o.add("<");}else if(i==2*m-2){o.add(">");o.add(rs);}else if(i%2==0){o.add(i<m?".>":">");o.add(rs);o.add(i<m-1?"<":"<.");}else{o.add("/");var j=rs.length-1;while(j>=0){o.add(rs.charAt(j));j--;}o.add("/");}}Sys.print(o.toString());}}))
  def check(prev)
    raise "Haxe_Hexagony: non-ASCII or NUL" if !prev.ascii_only? || prev.include?("\0")
  end
end

class Haskell < CodeGen
  File = "QR.hs"
  Cmd = "rm -f QR.o && ghc QR.hs && ./QR > OUTFILE"
  Apt = "ghc"
  Code = %q(%(f('@':'D':s)='#{B+B}':f s;f('@':'C':s)='"':f s;f('@':'N':s)='#{B}n':f s;f('@':'A':s)='@':f s;f(c:s)=c:f s;f[]=[];main=putStr(f"#{(PREV).gsub(?@,"@A").gsub(B,"@D").gsub(?","@C").gsub(N,"@N")}")))
  def check(prev)
    raise "Haskell: non-printable byte" if prev =~ /[^\n\x20-\x7e]/
  end
end

class Hare < CodeGen
  Name = "Hare"
  File = "QR.ha"
  Cmd = "hare build -q -o QR QR.ha && ./QR > OUTFILE"
  Apt = "hare"
  Code = %q(%(use fmt;export fn main()void={fmt::print(`#{(PREV).gsub(96.chr,%(`"`"`))}`)!;};))
  def check(prev)
    raise if prev.include?("\0") || prev.include?("\r") || !prev.ascii_only?
  end
end

class Groovy_Gzip < CodeGen
  Name = ["Groovy", "Gzip"]
  File = ["QR.groovy", "QR.gz"]
  Cmd = [
    "groovy QR.groovy > OUTFILE",
    "gzip -cd QR.gz > OUTFILE",
  ]
  Apt = ["groovy", "gzip"]
  Code = %q((require"zlib";%(new java.util.zip.GZIPOutputStream(System.out).withCloseable{z->new java.util.zip.InflaterInputStream(new java.io.ByteArrayInputStream(java.util.Base64.decoder.decode(#{N}#{[Object.const_get("Zlib")::Deflate.deflate(PREV,9)].pack("m0").scan(/.{1,1000}/).map{|p15g|"'#{p15g}'"}*("+"+N)}#{N}))).transferTo(z)}#{N})))
end

class GriLang < CodeGen
  Name = "Gri"
  File = "QR.gri"
  Cmd = "gri -output QR.gri.ps QR.gri > OUTFILE"
  Apt = "gri"
  Code = %q(%(#{PREV.split(N).map{|l|%(show "#{l}")}*N}\n))
  def check(prev)
    raise "Gri: quote or backslash in the payload" if prev =~ /["\\]/
    raise "Gri: line over 32000" if prev.split("\n").any? { |l| l.size + 7 > 32000 }
  end
end

class Gravity < CodeGen
  Name = "Gravity"
  File = "QR.gravity"
  Cmd = "gravity -q QR.gravity > OUTFILE"
  Apt = [nil]
  Code = %q("func main(){"+(PREV).scan(/.{1,20000}/m).map{|b18v|"System.put(\"#{e[b18v]}\");"}*""+"}")
  def check(prev)
    raise "Gravity: non-printable byte" if prev =~ /[^\n\x20-\x7e]/
  end
end

class Grain_Grass < CodeGen
  Name = ["Grain", "Grass"]
  File = ["QR.gr", "QR.grass"]
  Cmd = [
    "grain QR.gr > OUTFILE",
    "ruby vendor/grass.rb QR.grass > OUTFILE",
  ]
  Apt = [nil, nil]
  def code
    mod, pro, epi = ::File.read(::File.join(__dir__, "grass-boot.dat")).lines
    mod = mod.to_i
    dec = ->(s) {
      i = 119
      out = +""
      s.chomp[1..-2].each_byte { |c| i = 206 - i; out << (c < 43 ? (c + 76).chr : i.chr * (c - 43)) }
      out
    }
    p_str = dec[pro]
    e_str = dec[epi]
    base = 119 + mod - 1
    %Q(("module Main\\nfrom \\"string\\" include String\\nfrom \\"bytes\\" include Bytes\\nfrom \\"uint8\\" include Uint8\\nlet mut j = #{base}\\nlet emit = (s: String) => {\\n  let b = Bytes.fromString(s)\\n  let n = Bytes.length(b)\\n  for (let mut i = 0; i < n; i += 1) {\\n    let c = Uint8.toNumber(Bytes.getUint8(i, b))\\n    j += 1\\n    let mut k = (j - c) % #{mod}\\n    if (k < 0) k += #{mod}\\n    print(\\"W\\", suffix=\\"\\")\\n    print(String.repeat(k + 1, \\"w\\"), suffix=\\"\\")\\n  }\\n}\\nprint(\\"#{p_str}\\", suffix=\\"\\")\\n"+(PREV).scan(/.{1,1000}/m).map{|s|%(emit("\#{e[s].gsub(9.chr,B+?t)}")\\n)}.join+"print(\\"#{e_str}\\", suffix=\\"\\")\\n"))
  end

  def check(prev)
    raise "Grain > Grass: non-printable or non-ASCII byte" if prev =~ /[^\t\n\x20-\x7e]/
  end
end

class GPortugol < CodeGen
  Name = "G-Portugol"
  File = "QR.gpt"
  Cmd = "mv QR.c QR.c.bak && gpt -t QR.c QR.gpt && gcc -o QR QR.c && ./QR > OUTFILE && mv QR.c.bak QR.c"
  Apt = "gpt"
  Code = %q("algoritmo A;in\u00edcio "+(PREV).lines.map{|l|"imprima("+(l.chomp.empty? ? '""' : l.chomp.scan(/.{1,500}/m).map{|c|?"+e[c].gsub(9.chr,B+?t)+?"}*?,)+");"}*""+"fim"+N)

  def check(prev)
    raise "G-Portugol: needs trailing newline" unless prev.end_with?("\n")
    raise "G-Portugol: non-printable or non-ASCII byte" if prev =~ /[^\t\n\x20-\x7e]/
  end
end

class Gosu < CodeGen
  Name = "Gosu"
  File = "QR.gsp"
  Cmd = "gosu QR.gsp > OUTFILE"
  Apt = [nil]
  Code = %q((PREV).dup.force_encoding("UTF-8").split([237].pack("U"),-1).map{|g11x|g11x.scan(/.{1,15000}/m).map{|b04c|"System.out.print("+Q[E[b04c]].gsub("<%","<\"+\"%")+");"}*""}*"System.out.write(195);System.out.write(173);")

  def check(prev)
    prev.dup.force_encoding("UTF-8").scan(/.{1,15000}/m) { raise if escape($&).bytesize + $&.count("$") + 10 > 65000 }
  end
end

class Golo < CodeGen
  File = "QR.golo"
  Cmd = "golo golo --files QR.golo > OUTFILE"
  Apt = [nil]
  Code = %q("module QR function main=|a|{foreach s in array["+(PREV).scan(/.{1,15000};|.+/m).map{|b04c|34.chr*3+b04c+34.chr*3}*"," +"]{print(s)}}")

  def check(prev)
    raise if prev.include?('"""') || prev.end_with?('"')
    prev.scan(/.{1,15000};|.+/m) { raise if $&.bytesize > 65000 || $&.start_with?('"') || $&.end_with?('"') }
  end
end

class GolfScript < CodeGen
  Name = "GolfScript"
  File = "QR.gs"
  Cmd = "ruby vendor/golfscript.rb QR.gs > OUTFILE"
  Apt = [nil]
  Code = %q((p6gp=(PREV);%("#{e[p6gp.end_with?(N) ? p6gp.chomp : p6gp].gsub(?#,B+?#).b.gsub(/[\x80-\xff]/n){B+"x%02x"%$&.ord}}")))
  def check(prev)
    raise "GolfScript: NUL" if prev.include?("\0")
  end
end

class Go < CodeGen
  File = "QR.go"
  Cmd = "go run QR.go > OUTFILE"
  Apt = "golang"
  Code = %q((require"zlib";%(package main;import("bytes";"compress/zlib";"encoding/base64";"io";"os");func main(){b,_:=base64.StdEncoding.DecodeString("#{[Object.const_get("Zlib")::Deflate.deflate(PREV,9)].pack("m0")}");r,_:=zlib.NewReader(bytes.NewReader(b));io.Copy(os.Stdout,r)})))
end

class GNUSmalltalk < CodeGen
  Name = "GNU Smalltalk"
  File = "QR.st"
  Cmd = "gst QR.st > OUTFILE"
  Apt = [nil]   # src/extra-installs/
  # only ' is special in a Smalltalk string, and it is doubled
  Code = %q(%(Transcript show: '#{d[PREV,?']}'))

  def check(prev)
    raise if prev.bytes.any? {|b| b < 1 || b > 126 } # Java's LZ78 dictionary upstream
  end
end

class Gnuplot < CodeGen
  File = "QR.plt"
  Cmd = "gnuplot QR.plt > OUTFILE"
  Apt = "gnuplot"
  Code = %q('set print"-";print"'+e[PREV].gsub(/[\x00-\x09\x0b-\x1f\x60\x7f]/){B+"%03o"%$&.ord}+'"')
  def check(prev)
    raise "Gnuplot: NUL" if prev.include?("\0")
  end
end

class GNUAPL < CodeGen
  Name = "GNU APL"
  File = "QR.apl"
  Cmd = "apl --script --OFF -s -f QR.apl > OUTFILE"
  Apt = [nil]
  Code = %q(((PREV).chomp.scan(/.{1,30000}/m).map{|s|"\u235e\u2190"+s.split(/([\x00-\x1f\x7f])/).reject(&:empty?).map{|t|t.match?(/\A[\x00-\x1f\x7f]\z/) ? "(\u2395UCS #{t.ord})" : ?'+d[t,?']+?'}.join(",")+"\n"}.join+41.chr+"OFF\n"))
  def check(prev)
    raise "GNU APL: not UTF-8" unless prev.dup.force_encoding("UTF-8").valid_encoding?
    raise "GNU APL: NUL" if prev.include?("\0")
  end
end

class Gluon < CodeGen
  Name = "Gluon"
  File = "QR.glu"
  Cmd = "gluon QR.glu > OUTFILE"
  Apt = [nil]
  Code = %q((p4gp=(PREV);p4gh=p4gp.include?('"###') ? "####" : "###";%(let io = import! std.io#{N}io.print r#{p4gh}"#{p4gp}"#{p4gh}#{N})))
  def check(prev)
    raise "Gluon: payload blocks both raw delimiters" if prev.include?('"###') && prev.include?('"####')
    raise "Gluon: NUL or invalid UTF-8" if prev.include?("\0") || !prev.dup.force_encoding("UTF-8").valid_encoding?
  end
end

class Gleam < CodeGen
  Name = "Gleam"
  File = "qrgleam/src/qr.gleam"
  Cmd = "(cd qrgleam; gleam run --no-print-progress) > OUTFILE"
  Apt = [nil]
  Code = %q(%(type W{All}#{N}@external(erlang,"string","replace")fn r(s:String,p:String,t:String,w:W)->String#{N}@external(erlang,"io","put_chars")fn p(s:String)->Nil#{N}pub fn main(){p(r(r(r("#{(PREV).dup.force_encoding("UTF-8").gsub(?%,"%A").gsub(B,"%D").gsub(?","%C").chars.map{|p6gc|p6gc.ord>127 ? "#{B}u{#{p6gc.ord.to_s(16)}}" : p6gc}.join}","%D","#{B+B}",All),"%C","#{B}"",All),"%A","%",All))}))
  def check(prev)
    raise "Gleam: not UTF-8" unless prev.dup.force_encoding("UTF-8").valid_encoding?
    raise "Gleam: NUL or CR (the lexer folds CRLF)" if prev.include?("\0") || prev.include?("\r")
  end
end

class Glass < CodeGen
  Name = "Glass"
  File = "QR.glass"
  Cmd = "glass QR.glass > OUTFILE"
  Apt = [nil]
  Code = %q("{M[m(_o)O\x21(_s)S\x21(q)<34>(_s)(ns).?=#{(PREV).split(?",-1).map{|b20g|b20g.empty? ? "" : "\x22"+Q[b20g,B].gsub(N,B+?n)+"\x22(_o)o.?"}*"(q)*(_o)o.?"}]}")
  def check(prev)
    raise "Glass: NUL or invalid UTF-8" if prev.include?("\0") || !prev.dup.force_encoding("UTF-8").valid_encoding?
  end
end

class GeneratorScriptingLanguage < CodeGen
  Name = "Generator Scripting Language"
  File = "QR.gsl"
  Cmd = "gsl -q QR.gsl > OUTFILE"
  Apt = "generator-scripting-language"
  Code = %q(".template 1"+N+".bs = string.substr(\""+B+B+"\", 0, 1)"+N+(PREV).split(N,-1).map{|p4gl|p4gc=p4gl.scan(/.{1,200}/).flat_map{|p4g|p4g.split(/(#{B+B}|"|\$)/).reject(&:empty?).map{|p4t|p4t==B ? "bs" : p4t==?" ? "'\"'" : "\""+p4t+"\""}};p4gc.empty? ? ".s = \"\""+N+"$(s:no)" : ".s = "+p4gc[0]+(p4gc[1..].map{|p4x|N+".s += "+p4x}*"")+N+"$(s:no)"}*N+N+".endtemplate")
  def check(prev)
    raise "GSL: CR or NUL" if prev.include?("\r") || prev.include?("\0")
    raise "GSL: trailing whitespace on a line (gsl strips trailing whitespace)" if prev =~ /[ \t]$/
  end
end

class GEL < CodeGen
  Name = "GEL (Genius)"
  File = "QR.gel"
  Cmd = "genius QR.gel > OUTFILE"
  Apt = "genius"
  Code = %q(f(PREV,61){"printn#$S;"})

  def check(prev)
    # genius is flex-based and its scanner overflows above 16383 bytes per token
    prev.scan(/.{1,#{61*255}}/m) do |s|
      raise if s.size + s.scan(/[\\"\n]/).size + 2 > 16383
    end
  end
end

class GDB < CodeGen
  File = "QR.gdb"
  Cmd = "gdb -q -x QR.gdb > OUTFILE"
  Apt = "gdb"
  Code = %q('echo '+e[PREV]+"\nquit")
end

class GAP < CodeGen
  File = "QR.g"
  Cmd = "gap -q QR.g > OUTFILE"
  Apt = "gap"
  Code = %q("WriteAll(OutputTextUser(),#{E[PREV]});QUIT;")
end

class Gambas < CodeGen
  Name = "Gambas script"
  File = "QR.gbs"
  Cmd = "$(GBS) QR.gbs > OUTFILE"
  Apt = [["gambas3-scripter", "gambas3-gb-pcre"]]
  Code = %q(%(print"#{e[PREV]}"))
end

class Frege < CodeGen
  File = "QR.fr"
  Cmd = "mkdir -p frege-out && frege -d frege-out QR.fr && java -cp frege-out:/usr/local/lib/frege.jar QR > OUTFILE"
  Apt = [nil]
  Code = %q("module QR where main args = do {"+(PREV).scan(/.{1,15000}/m).map{|b04c|"putStr"+E[b04c]}*";"+"}")

  def check(prev)
    prev.scan(/.{1,15000}/m) { raise if escape($&).bytesize > 65000 }
  end
end

class Forth_FORTRAN77_Fortran90 < CodeGen
  Name = ["Forth", "FORTRAN77", "Fortran90"]
  File = ["QR.fs", "QR.f", "QR.f90"]
  Cmd = [
    "gforth QR.fs > OUTFILE",
    "gfortran -o QR QR.f && ./QR > OUTFILE",
    "gfortran -o QR QR.f90 && ./QR > OUTFILE",
  ]
  Apt = ["gforth", "gfortran", "gfortran"]
  Code = %q("VARIABLE Q1 VARIABLE Q2 VARIABLE Q3\n: HS .\"       subroutine f\" Q2 @ 0 .R CR .\"       print '(a)','subroutine s\" Q2 @ 0 .R .\" '\" CR 0 Q1 ! ;\n: HE .\"       print '(a)','end'\" CR .\"       end\" CR 1 Q2 +! ;\n: BK Q1 @ 400 >= IF HE HS THEN 1 Q1 +! ;\n: FL Q3 @ IF .\" '\x29\" CR 0 Q3 ! THEN ;\n: CH FL BK .\"       call c\x28\" 0 .R .\" \x29\" CR ;\n: PR DUP 32 < OVER 125 > OR OVER 34 = OR OVER 39 = OR OVER 92 = OR IF CH ELSE Q3 @ 44 >= IF FL THEN Q3 @ 0= IF BK .\"       call p\x28'\" THEN EMIT 1 Q3 +! THEN ;\n: GO BOUNDS ?DO I C@ PR LOOP FL ;\n: FIN HE .\"       program q\" CR Q2 @ 0 ?DO .\"       call f\" I 0 .R CR LOOP .\"       do 10 i=0,\" Q2 @ 1 - 0 .R CR .\"       if\x28i.lt.10\x29write\x28*,'\x28a,i1\x29'\x29'call s',i\" CR .\"       if\x28i.ge.10.and.i.lt.100\x29write\x28*,'\x28a,i2\x29'\x29'call s',i\" CR .\"       if\x28i.ge.100\x29write\x28*,'\x28a,i3\x29'\x29'call s',i\" CR .\" 10    continue\" CR .\"       print '\x28a\x29','end'\" CR .\"       print '\x28a\x29','subroutine p\x28s\x29'\" CR .\"       print '\x28a\x29','character\x28*\x29s'\" CR .\"       print '\x28a\x29','write\x28*,''\x28a\x29'',advance=''no''\x29s'\" CR .\"       print '\x28a\x29','end'\" CR .\"       print '\x28a\x29','subroutine c\x28n\x29'\" CR .\"       print '\x28a\x29','write\x28*,''\x28a\x29'',advance=''no''\x29char\x28n\x29'\" CR .\"       print '\x28a\x29','end'\" CR .\"       end\" CR .\"       subroutine p\x28s\x29\" CR .\"       character*\x28*\x29 s\" CR .\"       write\x28*,'\x28a\x29'\x29 'call p\x28'''//s//'''\x29'\" CR .\"       end\" CR .\"       subroutine c\x28n\x29\" CR .\"       if\x28n.lt.10\x29write\x28*,'\x28a,i1,a\x29'\x29 'call c\x28',n,'\x29'\" CR .\"       if\x28n.ge.10.and.n.lt.100\x29write\x28*,'\x28a,i2,a\x29'\x29 'call c\x28',n,'\x29'\" CR .\"       if\x28n.ge.100\x29write\x28*,'\x28a,i3,a\x29'\x29 'call c\x28',n,'\x29'\" CR .\"       end\" CR BYE ;\nHS\n"+(PREV).scan(/.{1,4000}/m).map{|p6c|"S\x5c\" #{e[p6c]}\" GO\n"}*""+"FIN\n")
  def check(prev)
    raise "Forth_FORTRAN77_Fortran90: non-ASCII or CR" if prev.include?("\r") || !prev.ascii_only?
  end
end

class Flix < CodeGen
  Name = "Flix"
  File = "QR.flix"
  Cmd = "java -XX:TieredStopAtLevel=1 -jar /opt/flix/flix.jar QR.flix > OUTFILE"
  Apt = [nil]
  Code = %q("import java.lang.System\ndef main(): Unit \\\\ IO = {\nlet out = System.out;\n"+(PREV).scan(/.{1,12000}/m).map{|p4f|"out.print(\""+e[p4f].gsub(9.chr,B+?t).gsub(13.chr,B+?r).gsub(/\$(?=\{)/,B+"$").gsub(/%(?=\{)/,B+"%")+"\")"}*";\n"+"\n}\n")
  def check(prev)
    raise "Flix: non-ASCII or NUL" if prev.include?("\0") || !prev.ascii_only?
  end
end

class Flex < CodeGen
  File = "QR.fl"
  Cmd = "flex -o QR.fl.c QR.fl && gcc -o QR QR.fl.c && ./QR > OUTFILE"
  Apt = "flex"
  Code = %q("%option noyywrap\n int main(){puts#{E[PREV]};}\n%%")

  def check(prev)
    raise if prev.include?("\0") # it becomes a C string literal printed by puts
  end
end

class Fish < CodeGen
  File = "QR.fish"
  Cmd = "fish QR.fish > OUTFILE"
  Apt = "fish"
  Code = %q("echo '#{Q[PREV,/['\\\\]/]}'")
end

class FishEsolang < CodeGen
  Name = "><> (Fish)"
  File = "QR.fish.fish"
  Cmd = "python3 /opt/fish/fish.py QR.fish.fish > OUTFILE"
  Apt = "python3"
  Code = %q((b19f=(PREV);b19q=b19f.bytesize%64;B+N+b19f.reverse.scan(/.{1,1000}/m).map{|b19w|B+?"+b19w.gsub(Regexp.union(N,34.chr)){$&==N ? %("a") : %("b3*1+")}+?"}*N+N+(b19q>0 ? B+"o"*b19q+N : "")+">l?\x21;"+"o"*64))
  def check(prev)
    raise "Fish: non-ASCII byte" unless prev.ascii_only?
  end
end

class Fennel < CodeGen
  File = "QR.fnl"
  Cmd = "fennel QR.fnl > OUTFILE"
  Apt = "fennel"
  Code = %q("(io.write \"#{e[PREV]}\")")
end

class Fantom < CodeGen
  File = "QR.fan"
  Cmd = "fan QR.fan > OUTFILE"
  Apt = [nil]
  Code = %q("class QR{static Void main(){o:=Env.cur.out;"+(PREV).scan(/.{1,20000}/m).map{|b04c|"o.print(Str<|"+b04c.gsub("|>","||>+Str<|>")+ "|>);"}*""+"o.flush} }")

  def check(prev)
    raise if prev =~ /[\r\n]/
  end
end

class FALSELang < CodeGen
  Name = "FALSE"
  File = "QR.false"
  Cmd = "ruby vendor/false.rb QR.false > OUTFILE"
  Apt = [nil]
  Code = %q(?"+PREV.gsub(?",'"34,"')+?")
end

class Falcon < CodeGen
  File = "QR.fal"
  Cmd = "falcon QR.fal > OUTFILE"
  Apt = [nil] # trusty falconpl 0.9.6.9 .debs, see src/extra-installs/
  # single-quoted strings take no escapes; a quote is written twice
  Code = %q(">> '"+(PREV).gsub(?',"''")+"'")
  def check(prev)
    raise if prev =~ /[^\t\n -~]/
    raise "Falcon: newline in the payload (falcon: New line in literal string)" if prev.include?("\n")
  end
end

class Factor < CodeGen
  Name = "Factor"
  File = "QR.factor"
  Cmd = "/opt/factor/factor QR.factor > OUTFILE"
  Apt = [nil]
  Code = %q("USING: io ;\n"+(PREV).scan(/.{1,15000}/m).map{|p6c|"\"#{e[p6c]}\" write\n"}*"")
  def check(prev)
    raise "Factor: non-ASCII or CR" if prev.include?("\r") || !prev.ascii_only?
  end
end

class FSharp < CodeGen
  Name = "F#"
  File = "QR.fsx"
  Cmd = "DOTNET_NOLOGO=1 dotnet fsi --quiet --exec QR.fsx > OUTFILE"
  Apt = "dotnet-sdk-10.0"
  Code = %q((require"zlib";%(open System#{N}open System.IO#{N}open System.IO.Compression#{N}(new DeflateStream(new MemoryStream(Convert.FromBase64String("#{[Object.const_get("Zlib")::Deflate.deflate(PREV,9)[2..-5]].pack("m0")}")),CompressionMode.Decompress)).CopyTo(Console.OpenStandardOutput())#{N})))
end

class Execline < CodeGen
  File = "QR.e"
  Cmd = "execlineb QR.e > OUTFILE"
  Apt = "execline"
  Code = %q(%(#{PREV.scan(/.{1,50000}/m).map{|c|%(foreground { echo -n "#{e[c]}" } )}*""}echo ""))

  def check(prev)
    # MAX_ARG_STRLEN, the Linux limit on one argument; every piece is one argument
    prev.scan(/.{1,50000}/m) { raise if escape($&).bytesize >= 131000 }
  end
end

class Euphoria < CodeGen
  Name = "Euphoria"
  File = "QR.ex"
  Cmd = "eui QR.ex > OUTFILE"
  Apt = [nil]
  Code = %q((PREV).scan(/.{1,1000}/m).map{|neu|"puts(1,\x22"+neu.gsub(/[\x22\\\\\n\t]/){{"\x22"=>B+"\x22",B=>B+B,N=>B+"n","\t"=>B+"t"}[$&]}+"\x22)"}*N+N)

  def check(prev)
    raise unless prev.ascii_only?
    raise if prev.include?("\r")
  end
end

class Erlang < CodeGen
  File = "QR.erl"
  Cmd = "escript QR.erl > OUTFILE"
  Apt = "erlang"
  Code = %q((p1em={?@=>"@0",B=>"@1",?"=>"@2",?'=>"@3",N=>"@4",?$=>"@5"};p1es=%(<<"#{(PREV).gsub(Regexp.union(*p1em.keys),p1em)}">>);[[1,92],[2,34],[3,39],[4,10],[5,36],[0,64]].each{|p1ei,p1ec|p1es=%(r(#{p1es},<<"@#{p1ei}">>,<<#{p1ec}>>))};"#{N}r(S,P,C)->binary:replace(S,P,C,[global]).#{N}main(_)->io:put_chars(#{p1es}).#{N}"))
  def check(prev)
    raise "Erlang: non-ASCII byte" if prev =~ /[^\x00-\x7f]/n
  end
end

class EmacsLisp < CodeGen
  Name = "Emacs Lisp"
  File = "QR.el"
  Cmd = "emacs -Q --script QR.el > OUTFILE"
  Apt = "emacs-nox"
  Code = %q(%((princ "#{e[PREV]}")))
  def check(prev)
    raise "EmacsLisp: non-ASCII or NUL" if !prev.ascii_only? || prev.include?("\0")
  end
end

class Elvish < CodeGen
  File = "QR.elv"
  Cmd = "elvish QR.elv > OUTFILE"
  Apt = "elvish"
  Code = %q(%(print '#{(PREV).gsub(?',%(''))}'))
end

class Elixir < CodeGen
  File = "QR.exs"
  Cmd = "elixir QR.exs > OUTFILE"
  Apt = "elixir"
  Code = %q((require"zlib";%(IO.write(:zlib.uncompress(:base64.decode("#{[Object.const_get("Zlib")::Deflate.deflate(PREV,9)].pack("m0")}"))))))
end

class Effekt < CodeGen
  Name = "Effekt"
  File = "QR.effekt"
  Cmd = "rm -rf qr_effekt_out && effekt --backend js --out qr_effekt_out QR.effekt > OUTFILE && rm -rf qr_effekt_out"
  Apt = [nil]
  # Triple-quoted raw string (zero backslash escaping; guards against """, ${, and trailing quote).
  Code = %q(%(def main() = print("""#{PREV}""")#{N}))

  def check(prev)
    raise "Effekt: payload contains \"\"\", ${, or ends with quote" if prev.include?('"""') || prev.include?('${') || prev.end_with?('"')
    raise "Effekt: NUL, CR, or non-ASCII" if prev.include?("\0") || prev.include?("\r") || !prev.ascii_only?
  end
end

class EC < CodeGen
  Name = "eC"
  File = "QR_ec.ec"
  Cmd = "ecp -c QR_ec.ec -o QR_ec.sym && ecc -c QR_ec.ec -o QR_ec.c && ecs -console QR_ec.sym QR_ec.imp -o QR_ec.main.ec && ecp -c QR_ec.main.ec -o QR_ec.main.sym && ecc -c QR_ec.main.ec -o QR_ec.main.c && gcc -std=gnu17 -w -o QR_ec QR_ec.c QR_ec.main.c -lecereCOM && ./QR_ec > OUTFILE"
  Apt = [nil] # focal ecere-sdk 0.44.15 .debs, see src/extra-installs/
  # mame's eC class (retired at Ubuntu 20.10): runs of backslashes print from a loop
  def code
    <<-'END'.lines.map {|l| l.strip }.join
      %(
        class QR:Application{
          void f(String const s,int n){for(Print(s);n;n--)Print("\\\\");}
          void Main(){#{f(PREV,15){"f(#{V[$S[1..-2],'",',');f("']},0);"}}} }
      )
    END
  end
end

class Dyon < CodeGen
  Name = "Dyon"
  File = "QR.dyon"
  Cmd = "dyonrun QR.dyon > OUTFILE"
  Apt = [nil]
  Code = %q(%(fn main() { print("#{e[PREV]}") }#{N}))

  def check(prev)
    raise "Dyon: NUL, CR, or non-ASCII" if prev.include?("\0") || prev.include?("\r") || !prev.ascii_only?
  end
end

class Dc_Dhall < CodeGen
  Name = ["dc", "Dhall"]
  File = ["QR.dc", "QR.dhall"]
  Cmd = [
    "dc QR.dc > OUTFILE || true", # XXX
    "dhall text --file QR.dhall > OUTFILE",
  ]
  Apt = ["dc", "dhall"]
  Code = %q("[''\n#{PREV}'']p")

  def check(prev)
    raise unless prev.match?(BRACKETS) # dc reads the whole program as a [...] string
    raise if prev.include?("''") # it ends the Dhall multi-line string
    raise if prev.include?("${") # Dhall interpolates it
    raise if prev.start_with?(" ", "\t") # Dhall strips the common indentation
  end
end

class Dart < CodeGen
  Name = "Dart"
  File = "QR.dart"
  Cmd = "dart run QR.dart > OUTFILE"
  Apt = [nil]
  Code = %q(%(import 'dart:io';void main(){stdout.write(r'#{PREV.gsub(/['#{N}]/){$&==?' ? %('"'"r') : %('"#{B}n"r')}}');}))
  def check(prev)
    raise "Dart: invalid UTF-8 or CR" if prev.include?("\r") || !prev.dup.force_encoding("UTF-8").valid_encoding?
  end
end

class DafnyLang < CodeGen
  Name = "Dafny"
  File = "QR.dfy"
  Cmd = "dafny build -o dafny-out/QR QR.dfy && DOTNET_ROLL_FORWARD=Major dotnet dafny-out/QR.dll > OUTFILE"
  Apt = [nil]
  Code = %q(%(method Main(){print @"#{d[PREV]}";}))
end

class D < CodeGen
  File = "QR.d"
  Cmd = "gdc -o QR QR.d && ./QR > OUTFILE"
  Apt = "gdc"
  Code = %q("import std;void main(){"+(PREV).scan(/.{1,15000}/m).map{|p15d|"write(\"#{e[p15d]}\");"}*""+"}")
  def check(prev)
    raise "D: NUL or CR" if prev.include?("\0") || prev.include?("\r")
  end
end

class Cyber < CodeGen
  Name = "Cyber"
  File = "QR.cy"
  Cmd = "cyber QR.cy > OUTFILE"
  Apt = [nil]
  # Cyber 0.3 uses import os, os.stdout.write (no LF), and $( interpolation (escaped as \$( ).
  Code = %q(%(import os#{N}os.stdout.write("#{e[PREV].gsub("$"+40.chr,B+"$"+40.chr)}")#{N}))

  def check(prev)
    raise "Cyber: NUL, CR, or non-ASCII" if prev.include?("\0") || prev.include?("\r") || !prev.ascii_only?
  end
end

class Crystal < CodeGen
  Name = "Crystal"
  File = "QR.cr"
  Cmd = "crystal QR.cr > OUTFILE"
  Apt = [["crystal", "libevent-dev"]]
  Code = %q("print#{E[PREV]}")

  def check(prev)
    raise if prev.include?('#{') # Crystal interpolates it in a "" string
  end
end

class CommonLisp < CodeGen
  Name = "Common Lisp"
  File = "QR.lisp"
  Cmd = "clisp QR.lisp > OUTFILE"
  Apt = "clisp"
  Code = %q((PREV).scan(/.{1,50000}/m).map{|m00c|%((princ"#{e[m00c]}"))}*"")

  def check(prev)
    raise if prev.include?("\n")
  end
end

class CoffeeScript < CodeGen
  File = "QR.coffee"
  Cmd = "coffee --nodejs --stack_size=100000 QR.coffee > OUTFILE"
  Apt = "coffeescript"
  Code = %q((require"zlib";%(process.stdout.write require("zlib").inflateSync Buffer.from "#{[Object.const_get("Zlib")::Deflate.deflate(PREV,9)].pack("m0")}","base64")))
end

class Clojure_CMake_Cobol < CodeGen
  File = ["QR.clj", "QR.cmake", "QR.cob"]
  Cmd = [
    "clojure QR.clj > OUTFILE",
    "cmake -P QR.cmake > OUTFILE",
    "cobc -O2 -x QR.cob && ./QR > OUTFILE",
  ]
  Apt = ["clojure", "cmake", "gnucobol4"]
  def code
    <<-'END'.lines.map {|l| l.strip }.join
      %(
        (doseq[s
          (concat
            ["program-id. q. procedure division. display"]
             (map #(str \\"
                  (.replace %"\\"""\\"\\"")
                  \\")
               (re-seq #".{1,31}"
                  (str #{(PREV).scan(/.{1,15000}/m).map{|m00k|"\""+e[m00k]+"\""}*" "})))
             ["."])]
          (println"message(STATUS \\"    \\""(pr-str s)")"))
        )
    END
  end

  def check(prev)
    raise if prev.include?("\n")
    prev.scan(/.{1,15000}/m) { raise if escape($&).bytesize > 65000 }
  end
end

class CLIPS < CodeGen
  Name = "CLIPS"
  File = "QR.clp"
  Cmd = "clips -f2 QR.clp > OUTFILE"
  Apt = "clips"
  Code = %q(%((printout t "#{Q[Q[PREV,B],?"]}")\n(exit)\n))
  def check(prev)
    raise "CLIPS: non-printable byte" if prev =~ /[^\n\x20-\x7e]/
  end
end

class Clean < CodeGen
  Name = "Clean"
  File = "QR.icl"
  Cmd = "clm -nt -nr QR -o QR > /dev/null && ./QR > OUTFILE"
  Apt = [nil]
  Code = %q(("module QR\nimport StdEnv\nStart w\n # (c,w)=stdio w\n"+(PREV).scan(/.{1,500}/m).map{|s|%( # c=fwrites "#{e[s].gsub(9.chr,B+?t)}" c\n)}.join+" # (_,w)=fclose c w\n = w\n"))

  def check(prev)
    raise "Clean: non-printable or non-ASCII byte" if prev =~ /[^\t\n\x20-\x7e]/
  end
end

class CJam < CodeGen
  Name = "CJam"
  File = "QR.cjam"
  Cmd = "java -jar /opt/cjam/cjam-0.6.5.jar QR.cjam > OUTFILE"
  Apt = "default-jdk-headless"
  Code = %q(%("#{Q[Q[PREV,B],?"]}"))
end

class Chapel_Chef < CodeGen
  Name = ["Chapel", "Chef"]
  File = ["QR.chpl", "QR.chef"]
  Cmd = [
    "chpl -o qrchpl QR.chpl && ./qrchpl > OUTFILE",
    "PERL5LIB=vendor/local/lib/perl5 compilechef QR.chef QR.chef.pl && perl QR.chef.pl > OUTFILE"
  ]
  Apt = [nil, nil]
  Code = %q((a15p=(PREV);a15q=(a15p.include?(39.chr*3)||a15p.end_with?(39.chr)) ? 34.chr*3 : 39.chr*3;%(use IO;const s=#{a15q}#{a15p}#{a15q};stdout.write("Quine Relay Coffee.#{B}n#{B}nIngredients.#{B}n");for i in 10..126 do stdout.write(i," l ",i,"#{B}n");stdout.write("#{B}nMethod.#{B}n");for i in 0..<s.numBytes by -1 do stdout.write("Put ",s.byte(i),".");stdout.write("Pour contents of the mixing bowl into the baking dish.#{B}n#{B}nServes 1.");)))
  def check(prev)
    raise "Chef: only bytes 10..126 are ingredients" unless prev.bytes.all? {|b| (10..126).cover?(b) }
    raise "Chapel: payload blocks both triple quotes" if (prev.include?("'''") || prev.end_with?("'")) && (prev.include?('"""') || prev.end_with?('"'))
  end
end

class ChaiScript < CodeGen
  Name = "ChaiScript"
  File = "QR.chai"
  Cmd = "chai QR.chai > OUTFILE"
  Apt = [nil]
  # C++-style raw string R"Q(...)Q" (zero escaping, puts omits trailing LF).
  Code = %q(%(puts(R"Q(#{PREV})Q");#{N}))

  def check(prev)
    raise "ChaiScript: payload contains raw delimiter )Q\"" if prev.include?(')Q"')
    raise "ChaiScript: NUL or non-ASCII" if prev.include?("\0") || !prev.ascii_only?
  end
end

class CDuce < CodeGen
  File = "QR.cd"
  Cmd = "cduce QR.cd > OUTFILE"
  Apt = [nil] # xenial cduce 0.6.0 .deb (native binary), see src/extra-installs/
  # strings take \\ and \" escapes; one long literal overflows the parser's stack, so print 2000-char pieces
  Code = %q((PREV).scan(/.{1,2000}/m).map{|c|%(print "#{e[c]}";;)}*"")
  def check(prev); raise if prev =~ /[^\t\n -~]/; end
end

class C3 < CodeGen
  Name = "C3"
  File = "QR.c3"
  Cmd = "c3c compile QR.c3 -o QR && ./QR > OUTFILE"
  Apt = [nil]
  Code = %q(%(import std::io;fn void main(){io::print(`#{d[PREV,?`]}`);}))
  def check(prev)
    raise if prev.include?("\0") || prev.include?("\r")
  end
end

class CSharpLang < CodeGen
  Name = "C#"
  File = "qr_cs/QR.cs"
  Cmd = "DOTNET_NOLOGO=1 dotnet run --project qr_cs > OUTFILE"
  Apt = "dotnet-sdk-10.0"
  Code = %q((require"zlib";%(using System;using System.IO;using System.IO.Compression;using var d=new DeflateStream(new MemoryStream(Convert.FromBase64String("#{[Object.const_get("Zlib")::Deflate.deflate(PREV,9)[2..-5]].pack("m0")}")),CompressionMode.Decompress);d.CopyTo(Console.OpenStandardOutput());)))
end

class Cplusplus < CodeGen
  Name = "C++"
  File = "QR.cpp"
  Cmd = "$(CXX) -o QR QR.cpp && ./QR > OUTFILE"
  Apt = "g++"
  Code = %q("#include<cstdio>\nint main(){const char*p="+((PREV).scan(/.{1,15000}/m).map{|p6c|"\"#{p6c.gsub(?%,"%A").gsub(B,"%D").gsub(?","%C").gsub(N,"%N")}\""}*"\n")+";for(;*p;p++)if(*p=='%'){p++;putchar(*p=='D'?92:*p=='C'?34:*p=='N'?10:37);}else putchar(*p);}\n")
  def check(prev)
    raise "C++: non-ASCII or CR" if prev.include?("\r") || !prev.ascii_only?
  end
end

class C < CodeGen
  File = "QR.c"
  Cmd = "$(CC) -o QR QR.c && ./QR > OUTFILE"
  Apt = "gcc"
  Code = %q("#include<stdio.h>\nint main(){"+(PREV).scan(/.{1,15000}/m).map{|p6c|"fputs(\"#{e[p6c]}\",stdout);"}*""+"return 0;}\n")
  def check(prev)
    raise "C: NUL or CR" if prev.include?("\0") || prev.include?("\r")
  end
end

class BQN_BrainFlak_Brainfuck < CodeGen
  Name = ["BQN", "Brain-Flak", "Brainfuck"]
  File = ["QR.bqn", "QR.bflk", "QR.bf"]
  Cmd = ["bqn QR.bqn > OUTFILE", "craneflak -A QR.bflk > OUTFILE", "ruby vendor/bf.rb QR.bf > OUTFILE"]
  Apt = [nil, nil, nil]
  def code
    # Pure BQN -> Brain-Flak RLE -> Brainfuck delta encoder. Zero file-reads, zero self-reads.
    hdr = "T\u2190{\u{1d569}<6?\u223e\u{1d569}\u294a\u27e8\"()\"\u27e9;\"(\"\u223e(\u{1d54a}\u230a\u{1d569}\u00f72)\u223e\"){}\"\u223e\u223e(2|\u{1d569})\u294a\u27e8\"()\"\u27e9}\n" +
          "P\u2190{\"(\"\u223e(T \u{1d569})\u223e\")\"}\n" +
          "a\u2190P\u00a8\u2195128\n" +
          "q\u2190(1\u2291a)\u223e46\u2291a\n" +
          "b\u2190\""
    ftr = "\"-@\n\u2022term.OutRaw(\u223e{\u{1d569}=0?q;((|\u{1d569})\u2291a)\u223e((43+2\u00d7\u{1d569}<0)\u2291a)\u223eq}\u00a8b-0\u00bbb)\u223e\"{({}<>)<>{({}[()])<>(({}))<>}{}<>{}<>}<>\"\n"
    h_cps = hdr.codepoints.join(",")
    f_cps = ftr.codepoints.join(",")
    "%(\#{[#{h_cps}].pack(\"U*\")}\#{d[PREV]}\#{[#{f_cps}].pack(\"U*\")})"
  end
  def check(prev)
    raise "BQN_BrainFlak_Brainfuck: non-printable byte" if prev =~ /[^\n\x20-\x7e]/
  end
end

class Boron < CodeGen
  Name = "Boron"
  File = "QR.boron"
  Cmd = "boron QR.boron > OUTFILE"
  Apt = [nil]
  Code = %q(%(prin "#{(PREV).gsub("^","^^").gsub(?",94.chr+?").gsub(N,"^/").gsub("\t","^-")}"#{N}))
  def check(prev)
    raise "Boron: NUL, CR, or invalid UTF-8" if prev.include?("\0") || prev.include?("\r") || !prev.dup.force_encoding("UTF-8").valid_encoding?
  end
end

class Boo < CodeGen
  Name = "Boo"
  File = "QR.boo"
  Cmd = "booi QR.boo > OUTFILE"
  Apt = [nil]
  Code = %q("import System\nConsole.OutputEncoding=System.Text.UTF8Encoding(false)\n"+(PREV).dup.force_encoding("UTF-8").scan(/.{1,15000}/m).map{|p6c|"Console.Write(\"#{p6c.gsub(?#,"#A").gsub(B,"#D").gsub(?","#C").gsub(?$,"#S").gsub(N,"#N").chars.map{|p6bc|p6bc.ord>127 ? (p6bc.ord<=0xffff ? "#{B}u%04x"%p6bc.ord : (p6bp=p6bc.ord-0x10000;"#{B}u%04x#{B}u%04x"%[0xd800+(p6bp>>10),0xdc00+(p6bp&0x3ff)])) : p6bc}.join}\".Replace(\"#D\",\"#{B+B}\").Replace(\"#C\",\"#{B}\"\").Replace(\"#S\",\"$\").Replace(\"#N\",\"#{B}n\").Replace(\"#A\",\"#\"))\n"}*"")
  def check(prev)
    raise "Boo: NUL, CR, or invalid UTF-8" if prev.include?("\0") || prev.include?("\r") || !prev.dup.force_encoding("UTF-8").valid_encoding?
  end
end

class Berry_BLC8 < CodeGen
  Name = ["Berry", "BLC8"]
  File = ["QR.be", "QR.Blc"]
  Cmd = ["berry QR.be > OUTFILE", "ruby vendor/blc.rb < QR.Blc > OUTFILE"]
  Apt = [nil, nil]
  Code = %q(%(import string#{N}var s=""#{(PREV).scan(/.{1,2000}/m).map{|p12e|"+\"#{e[p12e]}\""}*""}#{N}var tbl=[]#{N}for c: 0..255#{N} var b=bytes()#{N} b.add(22)#{N} var m=128#{N} while m>0#{N}  b.add(22);b.add(4);b.add((c/m)%2==1?222:226)#{N}  m/=2#{N} end#{N} b.add(4);b.add(222)#{N} tbl.push(b.asstring())#{N}end#{N}var parts=[bytes("12").asstring()]#{N}for i: 0..size(s)-1#{N} parts.push(tbl[string.byte(s[i])])#{N}end#{N}parts.push(bytes("04de").asstring())#{N}print(parts.concat())#{N}))
  def check(prev)
    raise "Berry_BLC8: non-printable byte" if prev =~ /[^\n\x20-\x7e]/
  end
end

class BefungeLang < CodeGen
  Name = "Befunge"
  File = "QR.bef"
  Cmd = "cfunge QR.bef > OUTFILE"
  Apt = [nil]
  Code = %q(((PREV).scan(/[\x21\x23-\x7e]+|./m).map{|p12f|p12f.size==1 ? (p12f==N ? "a," : "'#{p12f},") : p12f.scan(/.{1,226}/m).map{|p12u|p12u.size==1 ? "'#{p12u}," : (p12m=p12u.size-1;p12n=p12m<16 ? p12m.to_s(16) : (p12m%15==0 ? "#{(p12m/15).to_s(16)}f*" : "#{(p12m/15).to_s(16)}f*#{(p12m%15).to_s(16)}+");"\"#{p12u.reverse}\"#{p12n}k,")}*""}*""+"@"))
  def check(prev)
    raise "Befunge: non-printable byte" if prev =~ /[^\n\x20-\x7e]/
  end
end

class BeanShell < CodeGen
  Name = "BeanShell"
  File = "QR.bsh"
  Cmd = "bsh QR.bsh > OUTFILE"
  Apt = "bsh"
  Code = %q((PREV).scan(/.{1,15000}/m).map{|p12b|"System.out.print#{E[p12b]};"}*"")
  def check(prev)
    raise "BeanShell: NUL or non-ASCII" if prev.include?("\0") || !prev.ascii_only?
  end
end

class Bash_Bc < CodeGen
  Name = ["bash", "bc"]
  File = ["QR.bash", "QR.bc"]
  Cmd = [
    "bash QR.bash > OUTFILE",
    "BC_LINE_LENGTH=4000000 bc -q QR.bc > OUTFILE",
  ]
  Apt = ["bash", "bc"]
  Code = %q(%(IFS= read -r -d '' s <<'E' || :#{N}#{PREV}#{N}E#{N}s=${s%$'#{B}n'}#{N}s=${s//#{B*2}/#{B*4}}#{N}s=${s//#{B}"/#{B*2}q}#{N}printf 'print "%s"#{B}nquit#{B}n' "$s"#{N}))
  def check(prev)
    raise "Bash_Bc: CR or EOF line" if prev.include?("\r") || prev.lines.any? { |l| l.chomp == "E" }
  end
end

class Ballerina < CodeGen
  File = "QR.bal"
  Cmd = "bal run --offline QR.bal > OUTFILE"
  Apt = [nil]
  Code = %q("import ballerina/io;public function main(){"+(PREV).scan(/.{1,15000}/m).map{|b04c|"io:print"+E[b04c]+";"}*""+" }")

  def check(prev)
    prev.scan(/.{1,15000}/m) { raise if escape($&).bytesize > 65000 }
  end
end

class Awk < CodeGen
  Name = "Awk"
  File = "QR.awk"
  Cmd = "awk -f QR.awk > OUTFILE"
  Apt = "gawk"
  Code = %q("BEGIN{"+(PREV).scan(/.{1,15000}/m).map{|p6c|"printf\"%s\",\"#{e[p6c]}\";"}*""+"}")
  def check(prev)
    raise "Awk: non-ASCII or CR" if prev.include?("\r") || !prev.ascii_only?
  end
end

class Austral < CodeGen
  Name = "Austral"
  File = "QR.aum"
  Cmd = "austral compile QR.aum --entrypoint=QR:main --output=qr_austral && ./qr_austral > OUTFILE && rm -f qr_austral"
  Apt = [nil]
  Code = %q(%(module body QR is function main(): ExitCode is #{(PREV).scan(/.{0,7999}[\x00-\x5b\x5d-\x7f]|.{1,8000}/m).map{|s|%(print("#{e[s]}");)}*""} return ExitSuccess(); end; end module body.#{N}))

  def check(prev)
    raise "Austral: NUL, CR, or non-ASCII" if prev.include?("\0") || prev.include?("\r") || !prev.ascii_only?
    raise "Austral: payload ends with backslash" if prev.end_with?("\\")
  end
end

class ATS < CodeGen
  File = "QR.dats"
  Cmd = "patscc -o QR QR.dats && ./QR > OUTFILE"
  Apt = "ats2-lang"
  Code = %q("implement main0()=(#{PREV.split(/(?<=\?)(?=\?)/).map{|x|"print#{E[x]}"}*?;})")
end

class Asymptote < CodeGen
  File = "QR.asy"
  Cmd = "asy QR.asy > OUTFILE"
  Apt = "asymptote"
  Code = %q("write('#{Q[e[PREV],?']}');")
end

class AspectJ < CodeGen
  Name = "AspectJ"
  File = "QR.aj"
  Cmd = "ajc -source 1.8 -target 1.8 -nowarn QR.aj && java -Xmx2g -cp .:/usr/share/java/aspectjrt.jar QR > OUTFILE"
  Apt = "aspectj"
  Code = nil
end

load "code-gen-pool.rb" if ENV["ALL"]

GenSteps = CodeGen::List.map {|s| s.gen_step }
RunSteps = CodeGen::List.reverse.flat_map {|s| s.run_steps }
