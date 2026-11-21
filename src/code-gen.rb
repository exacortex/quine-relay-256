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
END

class Python_MalbolgeUnshackled_R_Ratfor_Rc_REXX < CodeGen
  Name = ["Python", "Malbolge Unshackled", "R", "Ratfor", "rc", "REXX"]
  File = ["QR.py", "QR.mb", "QR.R", "QR.ratfor", "QR.rc", "QR.rexx"]
  Cmd = [
    "python3 QR.py > OUTFILE",
    "unshackled QR.mb < /dev/null > OUTFILE",
    "R --slave -f QR.R > OUTFILE",
    "ratfor -o QR.ratfor.f QR.ratfor && gfortran -o QR QR.ratfor.f && ./QR > OUTFILE",
    "rc QR.rc > OUTFILE",
    "rexx ./QR.rexx > OUTFILE"
  ]
  Apt = ["python3", nil, "r-base", "ratfor", "rc", "regina-rexx"]
  def code
    boot = ::File.read(::File.join(__dir__, "malbolge-boot.dat")).strip
    %q(%(import sys,zlib,base64#{N}def g():#{N} s=#{E[PREV]}#{N} t=s.replace("'","''''")#{N} cs=[t[i:i+1500].replace("#{B}#{B}","#{B}#{B}#{B}#{B}").replace("#{B}"","#{B}#{B}#{B}"").replace("#{B}n","#{B}#{B}n")for i in range(0,max(1,len(t)),1500)]#{N} r="s<-paste0("+",".join('"'+c+'"'for c in cs)+")#{B}nl<-strsplit(s,#{B}"#{B}#{B}n#{B}",fixed=TRUE)[[1]]#{B}nif(endsWith(s,#{B}"#{B}#{B}n#{B}"))l<-c(l,#{B}"#{B}")#{B}nv<-as.integer(charToRaw(paste0(#{B}"echo 'say ''#{B}",l,#{B}"'''#{B}#{B}n#{B}",collapse=#{B}"#{B}")))#{B}nn<-length(v);k<-201L;m<-(n+k-1L)%/%k#{B}ng<-split(paste0(#{B}"r=fput(char(#{B}",v,#{B}"))#{B}"),(seq_len(n)-1L)%/%k)#{B}ncat(paste0(#{B}"subroutine s#{B}",0:(m-1L),#{B}"#{B}#{B}n#{B}",vapply(g,paste,#{B}"#{B}",collapse=#{B}"#{B}#{B}n#{B}"),#{B}"#{B}#{B}nend#{B}#{B}n#{B}"),paste0(#{B}"call s#{B}",0:(m-1L),#{B}"#{B}#{B}n#{B}"),#{B}"end#{B}#{B}n#{B}",sep=#{B}"#{B}")#{B}n"#{N} w=zlib.decompress(base64.b64decode("MALBOLGE_BOOT"))#{N} co,cp,cr,cj,cu,cv=[[33+(q-i)%94 for i in range(94)]for q in(35,29,6,7,66,48)]#{N} rg=[w[973+i]+(w[1073+i]<<8)for i in range(100)]#{N} out=bytearray(w[:861]+bytes(co[i%94]for i in range(861,1459))+w[861:973])#{N} cz=((1,0,0),(1,0,2),(2,2,1));oc=[[0]*486 for _ in range(486)];oi=[[[]for _ in range(128)]for _ in range(486)];rt=[-1]*486;m2=[0]*486;m0=[0]*486#{N} for d in range(486):#{N}  dh,dl=divmod(d,243);q2=q0=0;u=dl#{N}  if dl%3==dh:rt[d]=dh*243+dl//3+dh*81#{N}  for k in range(5):t0=u%3;u//=3;q2|=(t0==2)<<k;q0|=(t0==0)<<k#{N}  m2[d]=q2;m0[d]=q0;cl=oc[d];iv=oi[d]#{N}  for a in range(486):#{N}   ah,al=divmod(a,243);rl=0;pw=1;x=al;y=dl#{N}   for _ in range(5):rl+=cz[y%3][x%3]*pw;x//=3;y//=3;pw*=3#{N}   z=cz[dh][ah]*243+rl;cl[a]=z#{N}   if z<128:iv[z].append(a)#{N} n=100;a=116;d=6;c=len(out);ap=out.append;sv=[0]*486;ps=[0]*486;pp=[0]*486;po=[0]*486;vr=0#{N} tw=[sum(m2[x]>>k&1 for x in rg)for k in range(5)];zr=[sum(m0[x]>>k&1 for x in rg)for k in range(5)]#{N} def upd(u,nw):#{N}  ol=rg[u]#{N}  if ol!=nw:#{N}   a2,b2,a0,b0=m2[ol],m2[nw],m0[ol],m0[nw];rg[u]=nw#{N}   if a2!=b2:#{N}    df=a2^b2#{N}    for k in range(5):#{N}     if df>>k&1:tw[k]+=1 if b2>>k&1 else-1#{N}   if a0!=b0:#{N}    df=a0^b0#{N}    for k in range(5):#{N}     if df>>k&1:zr[k]+=1 if b0>>k&1 else-1#{N} for b in r.encode():#{N}  mt=20;fb=0#{N}  while a!=b:#{N}   n2=(tw[0]<=mt)|((tw[1]<=mt)<<1)|((tw[2]<=mt)<<2)|((tw[3]<=mt)<<3)|((tw[4]<=mt)<<4)#{N}   n0=(zr[0]<=mt)|((zr[1]<=mt)<<1)|((zr[2]<=mt)<<2)|((zr[3]<=mt)<<3)|((zr[4]<=mt)<<4)#{N}   vr+=1;sv[a]=vr;fr=[a];ds=[];cd=d;vs=fd=hp=ho=si=0#{N}   while vs<n:#{N}    if cd==n:ds.append(n);cd=0;si+=1;continue#{N}    md=rg[cd];p2=n2&m2[md];p0=n0&m0[md];rv=rt[md]if(p2|p0)==0 else-1#{N}    if rv==b:hp=fr[0];ho=2;ds.append(cd);fd=1;break#{N}    for v in oi[md][b]:#{N}     if sv[v]==vr and(m2[v]&p2)==0 and(m0[v]&p0)==0:hp=v;ho=1;ds.append(cd);fd=1;break#{N}    if fd:break#{N}    fl=len(fr);cl=oc[md]#{N}    if rv!=-1 and sv[rv]!=vr:sv[rv]=vr;ps[rv]=si;pp[rv]=fr[0];po[rv]=2;fr.append(rv)#{N}    if(p2|p0)==0:#{N}     for i in range(fl):#{N}      v=fr[i];z=cl[v]#{N}      if sv[z]!=vr:sv[z]=vr;ps[z]=si;pp[z]=v;po[z]=1;fr.append(z)#{N}    else:#{N}     for i in range(fl):#{N}      v=fr[i]#{N}      if(m2[v]&p2)==0 and(m0[v]&p0)==0:#{N}       z=cl[v]#{N}       if sv[z]!=vr:sv[z]=vr;ps[z]=si;pp[z]=v;po[z]=1;fr.append(z)#{N}    ds.append(cd);cd+=1;vs+=1;si+=1#{N}   if fd:#{N}    ns=len(ds);op=[0]*ns;op[ns-1]=ho;v=hp#{N}    while v!=a:s0=ps[v];op[s0]=po[v];v=pp[v]#{N}    for i in range(ns):#{N}     u=ds[i]#{N}     if u==n:ap(cj[c%94]);c+=1;d=0#{N}     elif op[i]==0:ap(co[c%94]);c+=1;d+=1#{N}     else:#{N}      if op[i]==1:ap(cp[c%94]);nw=oc[rg[u]][a]#{N}      else:ap(cr[c%94]);nw=rt[rg[u]]#{N}      c+=1;upd(u,nw);a=nw;d+=1#{N}   else:#{N}    fb+=1;mt=max(0,mt-6)#{N}    if mt==0 and fb>4:#{N}     if d==n:ap(cj[c%94]);c+=1;d=0#{N}     nw=oc[rg[d]][a];ap(cp[c%94]);c+=1;upd(d,nw);a=nw;d+=1#{N}  if d==n:ap(cj[c%94]);c+=1;d=0#{N}  ap(cu[c%94]);c+=1;d+=1#{N} ap(cv[c%94]);c+=1#{N} while(c+2)%564!=34:ap(co[c%94]);c+=1#{N} out.extend((36,101));sys.stdout.buffer.write(out)#{N}g())).sub("MALBOLGE_BOOT", boot)
  end

  def check(prev)
    raise unless prev.bytes.all? {|c| c < 128 }
  end
end

class BeanShell_Befunge_BLC8_Brainfuck < CodeGen
  File = ["QR.bsh", "QR.bef", "QR.Blc", "QR.bf"]
  Cmd = [
    "bsh QR.bsh > OUTFILE",
    "cfunge QR.bef > OUTFILE",
    "ruby vendor/blc.rb < QR.Blc > OUTFILE",
    "ruby vendor/bf.rb QR.bf > OUTFILE",
  ]
  Apt = ["bsh", nil, nil, nil]
  def code
    blc = ::File.read(::File.join(__dir__, "blc-boot.dat"))
    <<-'END'.lines.map {|l| l.strip }.join.sub("BLC", [blc].pack("m0"))
      %(
        f(s){System.out.print(s);}
        s="ef*c+45*,";
        for(c:#{E[PREV]}){
          s+="d9+,";
          for(m=1;m<256;m*=2)
            s+="d9+,4,:"+c/m%2*4+"+,";
          f(s);
          s="4,:,";
        }
        f(s+s);
        for(c:Base64.getDecoder().decode("BLC")){
          c&=255;
          f(""+c%8+c/8%8+c/64+"8*+8*+,");
        }
        f("@");
      )
    END
  end

  def check(prev)
    raise unless prev.ascii_only?
  end
end

class Ksh_LazyK_LiveScript < CodeGen
  Name = ["ksh", "Lazy K", "LiveScript"]
  File = ["QR.ksh", "QR.lazy", "QR.ls"]
  Cmd = [
    "ksh QR.ksh > OUTFILE",
    "!lazyk QR.lazy > OUTFILE",
    "lsc QR.ls > OUTFILE",
  ]
  Apt = ["ksh", nil, "livescript"]
  Backup = [nil, nil, "QR.c"]
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
        f(){ for x in $(p "$1"|od -vAn -tu1);do;
            p $4;
            for((j=$3;j--;));do;
              h $2 $x $j;
            done;
          done;
        };
        p k\\`;
        h(){ p \\`${1:$2>>$3&1:2};};
        f 'console.log#{Q[E[PREV],?#].gsub(?',%('"'"'))}' kki 7 '#{"``s"*8}i';
        h(){ p ${1:$2%83-10>>$3*2&3:1};};
        f 'LAZYK' ski\\` 3
      )
    END
  end

  def check(prev)
    raise "Lazy K: payload over 95,000 bytes (lazyk segfaults on the C stack)" if prev.bytesize > 95_000
    raise unless prev.ascii_only?
  end
end

class Scilab_Sed_Shakespeare_SLang < CodeGen
  Name = ["Scilab", "sed", "Shakespeare", "S-Lang"]
  File = ["QR.sci", "QR.sed", "QR.spl", "QR.sl"]
  Cmd = [
    "scilab-cli -nb -f QR.sci > OUTFILE",
    "sed -E -f QR.sed QR.sed > OUTFILE",
    "spl2c < QR.spl > QR.spl.c && gcc -z muldefs -o QR -I ./vendor/local/include -L ./vendor/local/lib QR.spl.c -lspl -lm && ./QR > OUTFILE",
    "slsh QR.sl > OUTFILE",
  ]
  Apt = ["scilab-cli", "sed", nil, "slsh"]
  def code
    <<-'END'.lines.map {|l| l.strip }.join
      %(
        #{
          s,v=rp[PREV,127..255];
          c=->x{x.gsub(/.{1,99}/m){"+\n"+E[$&]}};
          f(
            "1d;
            s/.//;
            s/1/ the sum of a son and0/g;
            s/0/ twice/g\n
            #The Relay of Quine.\n
            #Ajax, a man.\n
            #Ford, a man.\n
            #Act i: Quine.\n
            #Scene i: Relay.\n
            #[Enter Ajax and Ford]\n
            #Ajax:\n
            #"+
            %(
              variable s=""#{c[s]},v=""#{c[v]},i;
              _for i(0,128,1)
                s=strreplace(s,pack("C",255-i),v[[i*2:i*2+1]]);
              printf("%s",s)
            ).bytes.map{|b|"You are as bad as"+("%b"%b)[1..].reverse+" a son.Speak thy mind."}*""+
            "\n#[Exeunt]",7
          ){
            "printf#$S\n"
          }
        }
        quit
      )
    END
  end

  def check(prev)
    raise if prev.bytes.max.to_i > 126
  end
end

class Z80Asm < CodeGen
  Name = "Z80 asm"
  File = "QR.z80"
  Cmd = "z80asm QR.z80 -o qr.com && chmod a+r qr.com && if [ $$(id -u) = 0 ]; then setpriv --reuid=nobody --regid=nogroup --clear-groups tnylpo -b qr.com; else tnylpo -b qr.com; fi < /dev/null > OUTFILE && rm -f qr.com"
  Apt = "z80asm"
  Code = %q((b18u,b18y=rp[PREV,128..255];b18q=b18y.scan(/../m).reverse;b18g=b18q.map{|b18x|b18x.getbyte(0)};b18h=b18q.map{|b18x|b18x.getbyte(1)};" org 0100h\n ld hl, msg\nloop:\n ld a, (hl)\n or a\n jr z, done\n push hl\n call emit\n pop hl\n inc hl\n jr loop\ndone:\n jp 0\nemit:\n cp 128\n jr nc, pair\n ld e, a\n ld c, 6\n jp 5\npair:\n sub 128\n ld e, a\n ld d, 0\n ld hl, dict1\n add hl, de\n ld b, (hl)\n push bc\n ld hl, dict0\n add hl, de\n ld a, (hl)\n call emit\n pop af\n jp emit\ndict0:\n"+b18g.each_slice(32).map{|b18a|" db "+b18a*","}*N+"\ndict1:\n"+b18h.each_slice(32).map{|b18a|" db "+b18a*","}*N+"\nmsg:\n"+(b18u.bytes+[0]).each_slice(32).map{|b18a|" db "+b18a*","}*N+N))
  def check(prev)
    raise "Z80 asm: NUL or non-ASCII" if prev.include?("\0") || !prev.ascii_only?
  end
end

class Uxntal < CodeGen
  Name = "Uxntal"
  File = "QR.tal"
  Cmd = "uxnasm QR.tal QR.rom && uxncli QR.rom > OUTFILE && rm -f QR.rom"
  Apt = [nil]
  Code = %q((b18s,b18v=rp[PREV,[*127..255,*1..9,*11..31]];b18d=b18v.scan(/../m).reverse.insert(138,"\0\0")*"";"|0100 ;s @loop LDAk DUP #00 EQU ;done JCN2 ;emit JSR2 INC2 ;loop JMP2 @done POP POP2 #800f DEO BRK @emit DUP #0a EQU ;out JCN2 DUP #20 LTH ;lo JCN2 DUP #7f LTH ;out JCN2 #7f SUB ;go JMP2 @lo #80 ADD @go #00 SWP DUP2 ADD2 ;dict ADD2 LDAk ;emit JSR2 INC2 LDA ;emit JMP2 @out #18 DEO JMP2r\n@dict\n"+b18d.unpack1("H*").scan(/../).each_slice(120).map{|b18a|b18a*" "}*N+"\n@s\n"+b18s.unpack1("H*").scan(/../).each_slice(120).map{|b18a|b18a*" "}*N+" 00\n"))
  def check(prev)
    raise "Uxntal: unsupported control or non-ASCII byte" if prev =~ /[^\n\x20-\x7e]/
  end
end

class Asm6502 < CodeGen
  Name = "6502 asm"
  File = "QR.s65"
  Cmd = "xa -o QR.o65 QR.s65 && sim65 QR.o65 > OUTFILE && rm -f QR.o65"
  Apt = [["xa65", "cc65"]]
  Code = %q((b18t,b18w=rp[PREV,[*127..255,*1..9,*11..31]];b18p=b18w.scan(/../m).reverse.insert(138,"\0\0");b18e=b18p.map{|b18x|b18x.getbyte(0)};b18f=b18p.map{|b18x|b18x.getbyte(1)};" .byt \"sim65\",2,0,2,$00,$02,$00,$02\n* = $0200\n ldx \#$ff\n txs\n lda \#$80\n sta $20\n lda #0\n sta $21\n sta $23\n sta 4\n lda #1\n sta $22\n lda #<msg\n sta 0\n lda #>msg\n sta 1\nloop:\n ldy #0\n lda (0),y\n beq done\n jsr emit\n inc 0\n bne loop\n inc 1\n jmp loop\ndone:\n jsr flush\n lda #0\n jmp $fff9\nflush:\n lda 4\n beq flret\n pha\n lda \#$20\n sta 2\n lda #0\n sta 3\n sta 4\n tax\n pla\n jsr $fff7\nflret:\n rts\nemit:\n cmp #10\n beq lit\n cmp #32\n bcc pair_lo\n cmp #127\n bcs pair_hi\nlit:\n ldx 4\n sta $80,x\n inx\n stx 4\n cpx #128\n beq flush\n rts\npair_lo:\n clc\n adc #128\n bne pair_go\npair_hi:\n sec\n sbc #127\npair_go:\n tax\n lda dict1,x\n pha\n lda dict0,x\n jsr emit\n pla\n jmp emit\ndict0:\n"+b18e.each_slice(32).map{|b18a|" .byt "+b18a*","}*N+"\ndict1:\n"+b18f.each_slice(32).map{|b18a|" .byt "+b18a*","}*N+"\nmsg:\n"+(b18t.bytes+[0]).each_slice(32).map{|b18a|" .byt "+b18a*","}*N+N))
  def check(prev)
    raise "6502 asm: unsupported control or non-ASCII byte" if prev =~ /[^\n\x20-\x7e]/
  end
end

class Austral < CodeGen
  Name = "Austral"
  File = "QR.aum"
  Cmd = "austral compile QR.aum --entrypoint=QR:main --output=qr_austral && ./qr_austral > OUTFILE && rm -f qr_austral"
  Apt = [nil]
  # Chunk into 8KB print() calls so OCaml's recursive string parser in austral never hits Stack overflow.
  Code = %q(%(module body QR is function main(): ExitCode is #{(PREV).scan(/.{1,8000}/m).map{|s|%(print("#{e[s]}");)}*""} return ExitSuccess(); end; end module body.#{N}))

  def check(prev)
    raise "Austral: NUL, CR, or non-ASCII" if prev.include?("\0") || prev.include?("\r") || !prev.ascii_only?
  end
end

class Hope < CodeGen
  Name = "Hope"
  File = "QR.hop"
  Cmd = "hope -f QR.hop > OUTFILE"
  Apt = [nil]
  Code = %q((PREV).scan(/.{1,60}/m).map{|s|%(write "#{e[s].gsub(9.chr,B+?t)}";\n)}.join)

  def check(prev)
    raise "Hope: non-printable or non-ASCII byte" if prev =~ /[^\t\n\x20-\x7e]/
  end
end

class Flix < CodeGen
  Name = "Flix"
  File = "QR.flix"
  Cmd = "java -XX:TieredStopAtLevel=1 -jar /opt/flix/flix.jar QR.flix > OUTFILE"
  Apt = [nil]
  # Flix interpolates "${...}" and "%{...}" in "..." strings; chunked <=100 lines/println to stay under JVM 64KB CONSTANT_Utf8.
  Code = %q(("def main(): Unit \\\\ IO = {\n"+(PREV).chomp.split(N,-1).each_slice(100).map{|a|"println(\""+e[a*N].gsub(9.chr,B+?t).gsub(/\$(?=\{)/,B+"$").gsub(/%(?=\{)/,B+"%")+"\")"}*";\n"+"\n}\n"))

  def check(prev)
    raise "Flix: needs trailing newline" unless prev.end_with?("\n")
    raise "Flix: non-printable or non-ASCII byte" if prev =~ /[^\t\n\x20-\x7e]/
    prev.chomp.split("\n", -1).each_slice(100) do |a|
      raise "Flix: chunk too big for JVM CONSTANT_Utf8" if a.join("\n").bytesize > 25_000
    end
  end
end

class HOC < CodeGen
  Name = "HOC"
  File = "QR.hoc"
  Cmd = "/usr/lib/plan9/bin/hoc QR.hoc > OUTFILE"
  Apt = "9base"
  # Plan 9 hoc6: chunked <=80 B per line (sbuf[100] limit; per-line statement resets prog[2000]).
  Code = %q(((PREV).scan(/.{1,80}/m).map{|s|%(print "#{e[s]}")}*N+N))

  def check(prev)
    raise "HOC: NUL, CR, or non-ASCII" if prev.include?("\0") || prev.include?("\r") || !prev.ascii_only?
  end
end

class Grain < CodeGen
  Name = "Grain"
  File = "QR.gr"
  Cmd = "grain QR.gr > OUTFILE"
  Apt = [nil]
  Code = %q(("module Main\n"+(PREV).scan(/.{1,1000}/m).map{|s|%(print("#{e[s].gsub(9.chr,B+?t)}",suffix="")\n)}.join))

  def check(prev)
    raise "Grain: non-printable or non-ASCII byte" if prev =~ /[^\t\n\x20-\x7e]/
  end
end

class LibRep < CodeGen
  Name = "rep (librep)"
  File = "QR.rep"
  Cmd = "rep QR.rep > OUTFILE"
  Apt = "rep"
  Code = %q(%((princ "#{e[PREV]}")))
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

class Perl5 < CodeGen
  Name = "Perl 5"
  File = "QR.pl"
  Cmd = "perl QR.pl > OUTFILE"
  Apt = "perl"
  def code
    <<-'END'.lines.map {|l| l.strip }.join
      (
        p="eval";
        %(
          $_="#{
            s,v=rp[PREV,128..287];
            ["
              $_='#{Q[s,c=/['\\\\]/]}';
              $n=32;
              for$a(unpack'(a2)*','#{Q[v,c]}'){
                $b=chr(--$n&255);
                s/$b/$a/g
              }
              print
            "].pack("u").tr(" -a",",-:A-Za-y")
          }";
          tr/,-:A-Za-y/ -a/;
          eval unpack u
        ).scan(/[ ,-:A-z]+|(.)/m){p="s++#{$1?"chr #{$1.ord}+e":$&+?+};"+p};
        p
      )
    END
  end

  def check(prev)
    # rp[] allocates its Re-Pair codewords from bytes 0-31 and 128-255
    raise unless prev.bytes.all? {|c| (0x20..0x7f).cover?(c) }
  end
end

class Pascal < CodeGen
  File = "QR.pas"
  Cmd = "fpc QR.pas && ./QR > OUTFILE"
  Apt = "fp-compiler"
  Code = %q("begin write('#{PREV}')end.")

  def check(prev)
    # it goes into a '...' literal unescaped, and the literal cannot span lines
    raise if prev =~ /['\n]/
  end
end

class Taxi < CodeGen
  Name = "Taxi"
  File = "QR.taxi"
  Cmd = "taxi QR.taxi > OUTFILE"
  Apt = [nil]
  Code = %q(%("#{Q[PREV,B].gsub(N,B+?n)}" is waiting at the Writer\x27s Depot. Go to Writer\x27s Depot: west 1st left, 2nd right, 1st left, 2nd left. Pickup a passenger going to the Post Office. Go to the Post Office: north 1st right, 2nd right, 1st left. Go to the Taxi Garage: north 1st right, 1st left, 1st right.))
  def check(prev)
    raise "Taxi: quote or non-printable" if prev.index(34.chr) || prev =~ /[^\n\x20-\x7e]/
  end
end

class Glass < CodeGen
  Name = "Glass"
  File = "QR.glass"
  Cmd = "glass QR.glass > OUTFILE"
  Apt = [nil]
  Code = %q("{M[m(_o)O\x21(_s)S\x21(q)<34>(_s)(ns).?=#{(PREV).split(?",-1).map{|b20g|b20g.empty? ? "" : "\x22"+Q[b20g,B].gsub(N,B+?n)+"\x22(_o)o.?"}*"(q)*(_o)o.?"}]}")
  def check(prev)
    raise "Glass: NUL or non-ASCII" if prev.include?("\0") || !prev.ascii_only?
  end
end

class Parser3 < CodeGen
  Name = "Parser 3"
  File = "QR.p"
  Cmd = "parser3 QR.p > OUTFILE"
  Apt = "parser3-cgi"
  # Appends a trailing newline (ignored by parser3 after $console:line[...]) so upstream line-oriented steps can emit LF cleanly.
  Code = %q("$console:line[#{PREV.gsub(?;,"^;")}]#{N}")

  def check(prev)
    # "$" starts a variable reference and "^" is the escape character, but only ";" is escaped here
    raise if prev =~ /[$^]/
    raise if prev.include?("\r") # parser3 turns it into a newline
    # it is placed inside $console:line[...], and brackets cannot be escaped
    raise unless prev.match?(BRACKETS)
  end
end

class Rockstar < CodeGen
  Name = "Rockstar"
  File = "QR.rock"
  Cmd = "rockstar QR.rock > OUTFILE"
  Apt = [nil]
  Code = %q((b20c=(PREV).chomp.split(34.chr,-1).map{|b20g|34.chr+b20g+34.chr}*" + q + ";"let q be 34#{N}burn q#{N}shout #{b20c}#{N}"))
  def check(prev)
    raise "Rockstar: expected trailing newline and no backslash/inner newline" if !prev.end_with?(10.chr) || prev[0..-2].index(92.chr) || prev[0..-2].index(10.chr)
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

class Icon_INTERCAL < CodeGen
  File = ["QR.icn", "QR.i"]
  Cmd = [
    "icont -s QR.icn && ./QR > OUTFILE",
    "ick -bfOc QR.i && gcc -std=c99 -static QR.c -I /usr/include/ick-* -o QR -lick && ./QR > OUTFILE"
  ]
  Backup = [nil, "QR.c"]
  Apt = [["icont", "iconx"], "intercal"]
  def code
    <<-'END'.lines.map {|l| l.strip }.join
      %(
        procedure main();
          c:=n:=0;
          s:=#{E[PREV+N]};
          every k:=1to*s by 60000do{
            r:=s[k:(*s+1>k+60000)|*s+1];
            i:=0;
            write("DO,1<-#",*r);
            every t:=ord(!r)do{
              i+:=1;
              u:=-(n+:=1);
              every 0to 7do{u:=u*2+t%2;t/:=2};
              write("PLEASE")\\(i%4/3);
              write("DO,1SUB#",i,"<-#",(c-u)%256);
              c:=u;
            };
            write("PLEASEREADOUT,1");
          };
          write("PLEASEGIVEUP");
        end
      )
    END
  end

  def check(prev)
    # each piece is dimensioned with a 16-bit INTERCAL constant; the pieces are 60,000 chars
  end
end

class M4 < CodeGen
  File = "QR.m4"
  Cmd = "m4 QR.m4 > OUTFILE"
  Apt = "m4"
  Code = %q("changequote(<@,@>)<@#{PREV}@>")

  def check(prev)
    # they are the quote delimiters set by changequote, and m4 quotes nest
    raise if prev.include?("<@") || prev.include?("@>")
  end
end

class Beatnik < CodeGen
  Name = "Beatnik"
  File = "QR.beatnik"
  Cmd = "ruby vendor/beatnik.rb QR.beatnik > OUTFILE"
  Apt = [nil]
  Code = %q((PREV).bytes.map{|b20b|"#{75.chr} #{"E"*b20b} #{74.chr}A "}*""+"#{74.chr}AC#{75.chr}")
  def check(prev)
    raise "Beatnik: NUL or non-ASCII" if prev.include?("\0") || !prev.ascii_only?
  end
end

class Kipple < CodeGen
  Name = "Kipple"
  File = "QR.kpl"
  Cmd = "cipple QR.kpl > OUTFILE"
  Apt = [nil]
  Code = %q((b20s=(PREV).scan(/E+/).map{|b20x|b20x.size.chr}*"";b20p=b20s.scan(/[\x00-\x09\x0b-\x21\x23-\x5a\x5e-\x7f]+|./m).map{|b20c|b20c.size==1&&"\x0a\x22\x5b\x5c\x5d".index(b20c) ? "#{b20c.ord}>i" : "i<\x22#{b20c}\x22"}*" ";"75>o 67>o 65>o 74>o #{b20p} (i i>b 32>o 65>o 74>o 32>o (b 69>o b-1 b?) 32>o 75>o)"))
  def check(prev)
    raise "Kipple: unexpected Beatnik" unless prev.end_with?("JACK")
  end
end

class Rail < CodeGen
  Name = "Rail"
  File = "QR.rail"
  Cmd = "rail QR.rail > OUTFILE"
  Apt = [nil]
  Code = %q(%($ 'main'#{N} #{B}#{N}  #{B}-[#{(PREV)}]o#))
  def check(prev)
    raise "Rail: bracket or backslash or newline" if prev.index(92.chr) || prev.index("[") || prev.index("]") || prev.index(10.chr)
  end
end

class Promela < CodeGen
  Name = "Promela (Spin)"
  File = "QR.pr"
  Cmd = "spin -T QR.pr > OUTFILE"
  Apt = "spin"
  Code = %q("init{#{f(PREV,6){"printf#{d[$S,?%]};"}}}")

  def check(prev)
    # spin appends "1 process created" to stdout on the same line, and the "#" comments it out
    raise unless prev.end_with?(?#)
  end
end

class PHP_Piet < CodeGen
  File = ["QR.php", "QR.png"]
  Cmd = ["php QR.php > OUTFILE", "npiet QR.png > OUTFILE"]
  Apt = ["php-cli", nil]
  def code
    <<-'END'.lines.map {|l| l.strip }.join
      %(
        <?php ini_set("memory_limit","-1");$z=3+$w=strlen($s=#{Q[E[PREV]]})*3;
          echo"\\x89PNG\\r\\n\\32\\n";
          $m="";
          $t="\\xc0\\0\\xff";
          for($i=-1;++$i<$z<<7;
              $m.=$c--?
                (($w-$c||$i>$z)?$i/$z<($c<$w?ord($s[$c/3|0]):$c--%3+2):0)?
                  $t[2].$t[$c%3%2].$t[$c%3]:"\\0\\0\\0":"\\0"
          )
            $c=$i%$z;
          foreach([
            "IHDR".pack("NNCV",$w+2,128,8,2),
            "IDAT".gzcompress($m),
            "IEND"
          ]as$d)
            echo pack("NA*N",strlen($d)-4,$d,crc32($d));
      )
    END
  end

  def check(prev)
    raise unless prev.bytes.all? {|c| c == 10 || (0x20..0x7e).cover?(c) }
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

class GolfScript_GPortugol_Grass < CodeGen
  Name = ["GolfScript", "G-Portugol", "Grass"]
  File = ["QR.gs", "QR.gpt", "QR.grass"]
  Cmd = ["ruby vendor/golfscript.rb QR.gs > OUTFILE", "mv QR.c QR.c.bak && gpt -t QR.c QR.gpt && gcc -o QR QR.c && ./QR > OUTFILE && mv QR.c.bak QR.c", "ruby vendor/grass.rb QR.grass > OUTFILE"]
  Apt = [nil, "gpt", nil]
  def code
    r = <<-'END'.lines.map {|l| l.strip }.join
      %(
        @@BASE@@:j;
        {
          119:i;
          {
            206i-:i;
            .43<{76+}{[i]\\43-*}if
          }%
        }:t;
        "algoritmo A;in\\u00edcio imprima(\\""
        @@PROLOGUE@@
        "#{e[PREV]}"
        {
          "W""w"@j 1+:j\\- @@MOD@@%1+*
        }%
        @@EPILOGUE@@
        '");fim'
      )
    END
    mod, prologue, epilogue = ::File.read(::File.join(__dir__, "grass-boot.dat")).lines
    prologue += "t"
    epilogue += "t"
    prologue = prologue.gsub(/(\*,-,\.,)+/) { "\"t\"*,-,.,\"#{ $&.size / 6 }*t\"" }
    mod = mod.to_i
    r.gsub(/@@\w+@@/, {
      "@@PROLOGUE@@" => prologue.chomp,
      "@@EPILOGUE@@" => epilogue.chomp,
      "@@BASE@@" => 119 + mod - 1,
      "@@MOD@@" => mod,
    })
  end

  def check(prev)
    # vendor/golfscript.rb passes a "..." literal to Ruby's eval, so these would interpolate
    raise if prev =~ /#[{$@]/
  end
end

class Seed7 < CodeGen
  File = "QR.sd7"
  Cmd = "s7 -q QR.sd7 > OUTFILE"
  Apt = [nil] # built from source in src/extra-installs/
  # (PREV) in parens: unhooked, PREV is an expression like "a"+E[..], and .scan must take all of it
  # Emit "..." & "..." chunks (one per line, <= 200 chars) to keep source line lengths small.
  Code = %q(%($ include "seed7_05.s7i";\nconst proc: main is func begin write(#{(PREV).scan(/.{1,200}/m).map{|s|?"+e[s]+?"}*"&\n"}); end func;))

  def check(prev)
    raise if prev =~ /[^\n -~]/ # e[] only escapes \ " and newline
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

class SNOBOL4 < CodeGen
  Name = "SNOBOL4"
  File = "QR.sno"
  Cmd = "snobol4 -b QR.sno > OUTFILE"
  Apt = [nil]
  Code = %q((PREV).lines.map{|ncs|"  OUTPUT = "+((ncu=ncs.chomp.split(/(\x27+)/).reject(&:empty?).map{|nct|nct[0]=="\x27" ? "\x22"+nct+"\x22" : "\x27"+nct+"\x27"}*" ").empty? ? "\x27\x27" : ncu)}*N+N+"END"+N)

  def check(prev)
    raise unless prev.ascii_only? && prev.end_with?("\n")
    raise if prev.include?("\r")
    raise if prev.lines.any? { |l| l.size > 380 }
  end
end

class BrainFlak < CodeGen
  Name = "Brain-Flak"
  File = "QR.bflk"
  Cmd = "craneflak -A QR.bflk > OUTFILE"
  Apt = [nil]
  Code = %q((b19p=(PREV);b19t=->b19x{b19x<6 ? "()"*b19x : "(#{b19t[b19x/2]}){}#{"()"*(b19x%2)}"};b19p.reverse.bytes.map{|b19b|"(#{b19t[b19b]})"}*""))
  def check(prev)
    raise "Brain-Flak: non-ASCII" unless prev.ascii_only?
  end
end

class Underload < CodeGen
  Name = "Underload"
  File = "QR.ul"
  Cmd = "ruby vendor/underload.rb QR.ul > OUTFILE"
  Apt = [nil]
  Code = %q(%((#{PREV})S))
  def check(prev)
    raise "Underload: unbalanced parens" unless prev.match?(PARENS)
  end
end

class CJam < CodeGen
  Name = "CJam"
  File = "QR.cjam"
  Cmd = "java -jar /opt/cjam/cjam-0.6.5.jar QR.cjam > OUTFILE"
  Apt = "default-jdk-headless"
  Code = %q(%("#{PREV}"))
  def check(prev)
    raise "CJam: quote or backslash" if prev =~ /["\\]/
  end
end

class Slashes < CodeGen
  Name = "///"
  File = "QR.slashes"
  Cmd = "ruby vendor/slashes.rb QR.slashes > OUTFILE"
  Apt = [nil]
  Code = %q((b19s=(PREV).tr("\x22",33.chr);b19r=[*48..82,*84..90,*97..122];b19r.map{|b19c|b19o={};b19s[0,4000].scan(/../){b19o[$&]=b19o[$&].to_i+1};b19n=b19o.key(b19o.values.max)||"()";b19s=b19s.gsub(b19n,b19c.chr);"/#{b19c.chr}/#{b19n}/"}.reverse*""+"/#{33.chr}/"+34.chr+"/"+b19s))
  def check(prev)
    raise "Slashes: unexpected char" if prev =~ /[^"S(){}]/
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

class Elvish < CodeGen
  File = "QR.elv"
  Cmd = "elvish QR.elv > OUTFILE"
  Apt = "elvish"
  Code = %q(%(print '#{(PREV).gsub(?',%(''))}'))
end

class PicoLisp < CodeGen
  File = "QR.l"
  Cmd = "pil QR.l > OUTFILE"
  Apt = "picolisp"
  # backslash, double quote and ^ (control-char prefix) are escaped with a backslash
  Code = %q(%((prin "#{Q[PREV,/[\\\\"^]/]}")(bye)))
end

class Arturo < CodeGen
  Name = "Arturo"
  File = "QR.art"
  Cmd = "arturo QR.art < /dev/null > OUTFILE"
  Apt = [nil]                # release zip v0.10.0 (mini), see src/extra-installs/
  Code = %q(%(prints {:#{PREV}:}))
  def check(prev)
    raise "Arturo: payload holds :}" if prev.include?(":}")
    raise "Arturo: non-printable byte" if prev =~ /[^\n\x20-\x7e]/
  end
end

class Odin < CodeGen
  Name = "Odin"
  File = "QR.odin"
  Cmd = "odin run QR.odin -file > OUTFILE"
  Apt = [nil]
  Code = %q(%(package main;import"core:fmt";main::proc(){fmt.print("#{e[PREV]}")}))
  def check(prev)
    raise if prev.bytesize > 1_000_000 || prev.include?("\0") || !prev.ascii_only?
  end
end

class Mercury < CodeGen
  Name = "Mercury"
  File = "qr_mercury.m"
  Cmd = "mmc --make qr_mercury > /dev/null && ./qr_mercury > OUTFILE"
  Apt = [nil]                # see src/extra-installs/
  Code = %q(%(:- module qr_mercury. :- interface. :- import_module io. :- pred main(io::di, io::uo) is det. :- implementation. main(!IO) :- io.write_string("#{e[PREV]}", !IO).))
  def check(prev)
    raise "Mercury: non-printable byte" if prev =~ /[^\n\x20-\x7e]/
  end
end

class Perl6 < CodeGen
  Name = "Perl 6"
  File = "QR.pl6"
  Cmd = "perl6 QR.pl6 > OUTFILE"
  Apt = "rakudo"
  # the delimiters are built as ?[*3 / ?]*3 so QR.rb's own source (which every payload contains) never holds them
  Code = %q("print Q#{?[*3}#{PREV}#{?]*3}")

  def check(prev)
    # it goes raw into Q[[[...]]], and Perl 5's Re-Pair takes bytes 0-31 and 128-255
    raise unless prev.bytes.all? {|c| (0x20..0x7e).cover?(c) }
    raise if prev.include?("[[[") || prev.include?("]]]") || prev.start_with?("[") || prev.end_with?("]")
  end
end

class Pony < CodeGen
  Name = "Pony"
  File = "QR.pony"
  Cmd = "mkdir -p qrpony && cp QR.pony qrpony/main.pony && ponyc -V0 -b qrpony.out -o . qrpony && ./qrpony.out > OUTFILE"
  Apt = [nil]
  Code = %q(%(actor Main new create(e:Env)=>e.out.write("""#{PREV}""")))
  def check(prev)
    raise "Pony: payload holds a triple quote" if prev.include?('"""')
    raise "Pony: payload must be one line" if prev.include?("\n") || prev.include?("\r")
    raise "Pony: NUL" if prev.include?("\0")
  end
end

class Chapel < CodeGen
  Name = "Chapel"
  File = "QR.chpl"
  Cmd = "chpl -o qrchpl QR.chpl && ./qrchpl > OUTFILE"
  Apt = [nil]
  Code = %q(%(use IO;stdout.write('''#{PREV}''');))
  def check(prev)
    raise "Chapel: payload holds three single quotes" if prev.include?("'''")
    raise "Chapel: payload ends with a single quote" if prev.end_with?("'")
    raise "Chapel: NUL" if prev.include?("\0")
  end
end

class OCaml < CodeGen
  File = "QR.ml"
  Cmd = "ocaml QR.ml > OUTFILE"
  Apt = "ocaml"
  Code = %q("print_string#{E[PREV]}")
end

class Octave < CodeGen
  File = "QR.octave"
  Cmd = "mv QR.m QR.m.bak && octave -qf QR.octave > OUTFILE && mv QR.m.bak QR.m"
  Apt = "octave"
  Code = %q("puts#{E[PREV]};")

  def check(prev)
    raise if prev =~ /[^\n\x20-\x7e]/
  end
end

class ObjC < CodeGen
  Name = "Objective-C"
  File = "QR.m"
  Cmd = "gcc -o QR QR.m -lobjc && ./QR > OUTFILE"
  Apt = "gobjc"
  Code = %q("#import<stdio.h>#{N}#import<objc/Object.h>#{N}@interface Q:Object#{N}+(void)p;#{N}@end#{N}@implementation Q#{N}+(void)p{puts#{E[PREV]};}#{N}@end#{N}int main(){[Q p]#{R}}")
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

class Vale < CodeGen
  Name = "Vale"
  File = "QR.vale"
  Cmd = "rm -rf qr_vale_out && valec build qr=QR.vale --output_dir qr_vale_out > /dev/null && ./qr_vale_out/main > OUTFILE && rm -rf qr_vale_out"
  Apt = [nil]
  # Escapes { and } to disable string interpolation; print(...) omits LF.
  Code = %q(%(import stdlib.*;#{N}exported func main() { print("#{Q[e[PREV],/[{}]/]}"); }#{N}))

  def check(prev)
    raise "Vale: NUL, CR, or non-ASCII" if prev.include?("\0") || prev.include?("\r") || !prev.ascii_only?
  end
end

class GNUAPL < CodeGen
  Name = "GNU APL"
  File = "QR.apl"
  Cmd = "apl --script --OFF -s -f QR.apl > OUTFILE"
  Apt = [nil]
  # APL '...' has no backslash escapes (only '' for '). )OFF flushes the chomped trailing newline.
  Code = %q(((PREV).chomp.scan(/.{1,120}/m).map{|s|"\u235e\u2190"+s.split(/(\n|\t)/).reject(&:empty?).map{|t|(t==N)?"(\u2395UCS 10)":(t==9.chr)?"(\u2395UCS 9)":?'+d[t,?']+?'}.join(",")+"\n"}.join+41.chr+"OFF\n"))

  def check(prev)
    raise "GNU APL: needs trailing newline" unless prev.end_with?("\n")
    raise "GNU APL: non-printable or non-ASCII byte" if prev =~ /[^\t\n\x20-\x7e]/
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

class Inko < CodeGen
  Name = "Inko"
  File = "QR.inko"
  Cmd = "inko run QR.inko > OUTFILE"
  Apt = [nil]
  Code = %q(%(import std.stdio (Stdout)#{N}type async Main {#{N}fn async main {#{N}let _ = Stdout.new.write('#{(PREV).gsub(?@,"@A").gsub(B,"@D").gsub(?',"@C").gsub(?$,"@E")}'.replace('@D', '#{B+B}').replace('@C', '#{B}'').replace('@E', '#{B}$').replace('@A', '@'))#{N}}#{N}}#{N}))
  def check(prev)
    raise "Inko: not UTF-8" unless prev.dup.force_encoding("UTF-8").valid_encoding?
    raise "Inko: NUL" if prev.include?("\0")
  end
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

class PARIGP < CodeGen
  Name = "PARI/GP"
  File = "QR.gp"
  Cmd = "gp -f -q QR.gp > OUTFILE"
  Apt = "pari-gp"
  Code = %q("print#{E[PREV]};quit")
end

class Vala_Velato < CodeGen
  File = ["QR.vala", "QR.mid"]
  Cmd = [
    "valac QR.vala && ./QR > OUTFILE",
    "mono vendor/local/bin/Vlt.exe /s QR.mid && mono QR.exe > OUTFILE",
  ]
  Apt = ["valac", nil]
  def code
    <<-'END'.lines.map {|l| l.strip }.join
      %(
        void p(int[]c){
          foreach(int v in c){
            stdout.putc((char)(v>>8));
            stdout.putc((char)v);
          };
        }
        void main(){
          int[]a;
          p({19796,26724,0,6,0,1,480,19796,29291,#{s=PREV;(s.size*72+4).divmod(65536)*?,}});
          foreach(int c in#{E[s]}.data)
            foreach(int v in a={0,9,7,4,5,c/100*7/6+1,(c-c/100*100)/10*7/6+1,(c-c/10*10)*7/6+1,7})
              p({144,v=15450+v*256,384,v});
          p({255,12032});
        }
      )
    END
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

class Nim < CodeGen
  File = "QR.nim"
  Cmd = "nim compile QR.nim && ./QR > OUTFILE"
  Apt = "nim"
  Code = %q("echo#{E[PREV]}")
end

class Neko < CodeGen
  File = "QR.neko"
  Cmd = "nekoc QR.neko && neko QR.n > OUTFILE"
  Apt = "neko"
  Code = %q((PREV).scan(/.{1,20000}/m).map{|m00n|"$print#{E[m00n]};"}*"")
end

class ALGOL68_Ante < CodeGen
  Name = ["ALGOL 68", "Ante"]
  File = ["QR.a68", "QR.ante"]
  Cmd = [
    "a68g --heap 512M QR.a68 > OUTFILE",
    "ruby vendor/ante.rb QR.ante > OUTFILE",
  ]
  Apt = ["algol68g", nil]
  def code
    <<-'end'.lines.map {|l| l.strip }.join
      %W[
        STRINGz:= 226+ 153,a:=z+ 166,b:=a+"2"+z+ 160,c:=b+"8"+z+ 165;\n
        PROCp=(STRINGt)VOID:FORiTO\ UPBtDO\ INTn:=ABSt[i];
          print( (50+n%64)+c+ (50+n%8%*8)+c+ (50+nMOD8)+b+ 74+a)
        OD;\n#{(PREV).scan(/.{1,1000}/m).map{|m00a|"p(\""+d[m00a]+"\")"}*(";"+N)}
      ]*"REPR"
    end
  end

  def check(prev)
    raise if prev.include?("\n")
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

class Gleam < CodeGen
  Name = "Gleam"
  File = "QR.gleam"
  Cmd = "mkdir -p qrgleam/src && cp QR.gleam qrgleam/src/qr.gleam && printf 'name = \"qr\"\\nversion = \"1.0.0\"\\n' > qrgleam/gleam.toml && (cd qrgleam; gleam run --no-print-progress) > OUTFILE"
  Apt = [nil]
  Code = %q(%(type W{All}#{N}@external(erlang,"string","replace")fn r(s:String,p:String,t:String,w:W)->String#{N}@external(erlang,"io","put_chars")fn p(s:String)->Nil#{N}pub fn main(){p(r(r(r("#{(PREV).gsub(?@,"@A").gsub(B,"@D").gsub(?","@C")}","@D","#{B+B}",All),"@C","#{B}"",All),"@A","@",All))}))
  def check(prev)
    raise "Gleam: not UTF-8" unless prev.dup.force_encoding("UTF-8").valid_encoding?
    raise "Gleam: NUL or CR (the lexer folds CRLF)" if prev.include?("\0") || prev.include?("\r")
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

class VisualBasic_WebAssemblyText_Whitespace < CodeGen
  Name = ["Visual Basic", "WebAssembly (Text format)", "Whitespace"]
  File = ["QR.vb", "QR.wat", "QR.ws"]
  vbproj = <<-END
    <Project Sdk="Microsoft.NET.Sdk">
      <PropertyGroup>
        <OutputType>Exe</OutputType>
        <TargetFramework>net10.0</TargetFramework>
        <EnableDefaultCompileItems>false</EnableDefaultCompileItems>
      </PropertyGroup>
      <ItemGroup>
        <Compile Include="QR.vb" />
      </ItemGroup>
    </Project>
  END
  Cmd = [
    %(echo '#{ vbproj.lines.map {|s| s.strip }.join }' > tmp.vbproj && DOTNET_NOLOGO=1 dotnet run --project tmp.vbproj > OUTFILE),
    "wat2wasm QR.wat -o QR.wat.wasm && $(WASI_RUNTIME) QR.wat.wasm > OUTFILE",
    "ruby vendor/whitespace.rb QR.ws > OUTFILE"
  ]
  Apt = ["dotnet-sdk-10.0", "wabt", nil]
  def code
    <<-'END'.lines.map {|l| l.strip }.join
      %(Module QR\nSub main()\nDim b=CStr(Chr(92)),q=CStr(Chr(34)),s="#{s=PREV;d[s].gsub N,'"& VbLf &"'}"\n#$C("(module(import ""wasi_snapshot_preview1"" ""fd_write""(func $w(param i32 i32 i32 i32)(result i32)))(memory #{(s.bytesize+4200)/65536+1})(export ""memory""(memory 0))(data(i32.const 0)"+q+b+"10"+b+"00"+b+"00"+b+"00"+q+")(data(i32.const 4112)"+q+s.Replace(b,b+b).Replace(q,b+q).Replace(VbLf,b+"n")+q+")(global $p(mut i32)(i32.const 0))(func $f i32.const 4 global.get $p i32.store i32.const 1 i32.const 0 i32.const 1 i32.const 8 call $w drop i32.const 0 global.set $p)(func $o(param i32)global.get $p i32.const 16 i32.add local.get 0 i32.store8 global.get $p i32.const 1 i32.add global.set $p global.get $p i32.const 4096 i32.eq(if(then call $f)))(func(export ""_start"")(local $i i32)(local $b i32)i32.const 4112 local.set $i(loop i32.const 32 call $o i32.const 32 call $o i32.const 32 call $o i32.const 8 local.set $b(loop i32.const 32 local.get $i i32.load8_u local.get $b i32.const 1 i32.sub local.tee $b i32.shr_u i32.const 1 i32.and i32.const 23 i32.mul i32.sub call $o local.get $b br_if 0)i32.const 10 call $o i32.const 9 call $o i32.const 10 call $o i32.const 32 call $o i32.const 32 call $o local.get $i i32.const 1 i32.add local.tee $i i32.load8_u br_if 0)i32.const 10 call $o i32.const 10 call $o i32.const 10 call $o call $f))")\nEnd Sub\nEnd Module)
    END
  end

  def check(prev)
    raise if prev.empty? || prev =~ /[^\n\x20-\x7e]/
  end
end

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

class Yeti < CodeGen
  File = "QR.yeti"
  Cmd = "yeti QR.yeti > OUTFILE"
  Apt = [nil]
  Code = %q((PREV).scan(/.{1,15000}/m).map{|b04c|"print"+E[b04c]}*";")

  def check(prev)
    prev.scan(/.{1,15000}/m) { raise if escape($&).bytesize > 65000 }
  end
end

class MiniZinc < CodeGen
  File = "QR.mzn"
  Cmd = "minizinc --solver COIN-BC --soln-sep '' QR.mzn > OUTFILE"
  Apt = "minizinc"
  Code = %q("output#{E[PREV]}")
end

class RISCVAsm < CodeGen
  Name = "RISC-V asm"
  File = "QR.rv.s"
  Cmd = "rm -f QR && riscv64-linux-gnu-gcc -nostdlib -static -o QR QR.rv.s && qemu-riscv64 ./QR > OUTFILE && rm -f QR"
  Apt = [["gcc-riscv64-linux-gnu", "qemu-user"]]
  Code = %q((b18z=(PREV);".global _start\n.text\n_start:\n li a0, 1\n la a1, msg\n li a2, #{b18z.bytesize}\n li a7, 64\n ecall\n li a0, 0\n li a7, 93\n ecall\n.data\nmsg:\n"+b18z.scan(/[\x20\x21\x23-\x5b\x5d-\x7e]{1,60}|./m).map{|b18r|b18r=="\x22"||b18r==B||b18r==N ? ".byte #{b18r.ord}" : %(.ascii "#{b18r}")}*N+N))
  def check(prev)
    raise "RISC-V asm: bad byte" if !prev.ascii_only? || prev =~ /[\x00-\x09\x0b-\x1f\x7f]/
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

class SQL < CodeGen
  Name = "SQL (SQLite)"
  File = "QR.sql"
  Cmd = "sqlite3 < QR.sql > OUTFILE"
  Apt = "sqlite3"
  Code = %q(%(SELECT'#{d[PREV,?']}';))
end

class ARM64Asm < CodeGen
  Name = "ARM64 asm"
  File = "QR.arm64.s"
  Cmd = "rm -f QR && aarch64-linux-gnu-gcc -nostdlib -static -o QR QR.arm64.s && qemu-aarch64 ./QR > OUTFILE && rm -f QR"
  Apt = [["gcc-aarch64-linux-gnu", "qemu-user"]]
  Code = %q(".global _start\n.text\n_start:\n mov x0, #1\n ldr x1, =msg\n ldr x2, =len\n mov x8, #64\n svc #0\n mov x0, #0\n mov x8, #93\n svc #0\n.data\nmsg:\n"+(PREV).scan(/[\x20\x21\x23-\x5b\x5d-\x7e]{1,60}|./m).map{|b18n|b18n=="\x22"||b18n==B||b18n==N ? ".byte #{b18n.ord}" : %(.ascii "#{b18n}")}*N+"\n.equ len, . - msg\n")
  def check(prev)
    raise "ARM64 asm: bad byte" if !prev.ascii_only? || prev =~ /[\x00-\x09\x0b-\x1f\x7f]/
  end
end

class Kotlin < CodeGen
  File = "QR.kt"
  Cmd = "kotlinc QR.kt -include-runtime -d QR.jar && kotlin QR.jar > OUTFILE"
  Apt = "kotlin"
  def code
    <<-'END'.lines.map {|l| l.strip }.join
      %(
        fun main(){
          val s=arrayOf(#{
            m00z=m00t=(0..m00r=m00q=127).map{|m00n|[m00n,[]]};
            m00a="";
            m00b=->m00n{m00a<<(m00n%78+55)%84+42};
            (PREV).bytes{|m00n|
              m00r,m00z=m00z[m00n]||(
                m00b[m00r/6084];m00b[m00r/78];m00b[m00r];
                m00q<474551&&m00z[m00n]=[m00q+=1,[]];
                m00t[m00n])
            };
            m00b[m00r/6084];m00b[m00r/78];m00b[m00r];
            m00a.scan(/.{1,15000}/m).map{|m00k|Q[E[m00k]]}*?,
          }).joinToString("");
          val c=arrayOfNulls<String>(999999);
          val o=StringBuilder();
          var z="";
          var n=0;
          var q=0;
          while(++n<127)c[n]=""+n.toChar();
          for(i in s.indices){
            q=q*78+(s[i].toInt()-13)%84;
            if(i%3>1){
              c[n]=z+(if(q<n++)c[q]!!else z)[0];
              z=c[q]!!;
              o.append(z);
              q=0
            }
          };
          print(o)
        }
      )
    END
  end

  def check(prev)
    raise if prev.bytes.any? {|b| b < 1 || b > 126 }
  end
end

class Aplus < CodeGen
  Name = "A+"
  File = "QR.aplus.a"
  Cmd = "a+ QR.aplus.a > OUTFILE 2> /dev/null < /dev/null"
  Apt = [nil] # noble aplus-fsf 4.22.1 .deb, see src/extra-installs/
  # '...' takes no escapes (a quote is written twice). A line holds ~64 KB, so long
  # payloads are glued from 30000-char pieces (needs ASCII mode for :=). Prints a trailing newline.
  Code = %q((s=(PREV).scan(/.{1,30000}/m).map{|c|?'+c.gsub(?',"''")+?'}).size<2 ? s[0]+N+"sys.exit 0" : "$mode ascii"+N+"x:="+s*(N+"x:=x,")+N+"x"+N+"sys.exit 0")
  def check(prev); raise if prev.include?("\n") || prev =~ /[^ -~]/; end
end

class RacketLang < CodeGen
  Name = "Racket"
  File = "QR.rkt"
  Cmd = "racket QR.rkt > OUTFILE"
  Apt = "racket"
  Code = %q("#lang racket/base\n(display \"#{e[PREV]}\")")
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

class JavaScript_Jq < CodeGen
  File = ["QR.js", "QR.jq"]
  Cmd = [
    "$(JAVASCRIPT) QR.js > OUTFILE",
    "jq -j -n -f QR.jq > OUTFILE",
  ]
  Apt = ["nodejs", "jq"]
  Code = %q("console.log(JSON.stringify#{E[PREV]})")

  def check(prev)
    raise if prev =~ /[^\n\x20-\x7e]/
  end
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

class CDuce < CodeGen
  File = "QR.cd"
  Cmd = "cduce QR.cd > OUTFILE"
  Apt = [nil] # xenial cduce 0.6.0 .deb (native binary), see src/extra-installs/
  # strings take \\ and \" escapes; one long literal overflows the parser's stack, so print 2000-char pieces
  Code = %q((PREV).scan(/.{1,2000}/m).map{|c|%(print "#{e[c]}";;)}*"")
  def check(prev); raise if prev =~ /[^\t\n -~]/; end
end

class Boo < CodeGen
  File = "QR.boo"
  Cmd = "booi QR.boo > OUTFILE"
  Apt = [nil] # trusty boo 0.9.5 .debs on mono, see src/extra-installs/
  # Single-quoted Boo string literal (no raw newlines or CRs).
  Code = %q("System.Console.Write(\x27"+(PREV).gsub(/[\x27\\\\]/){B+$&}+"\x27)")
  def check(prev); raise if prev =~ /[\r\n]/; end
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

class Lua < CodeGen
  File = "QR.lua"
  Cmd = "lua5.3 QR.lua > OUTFILE"
  Apt = "lua5.3"
  Code = %q("print((#{V[E[PREV],?&,?&]}:gsub('&(%d+)&',load[[return('\\\\\\\\'):rep(...)]])))")

  def check(prev)
    raise if prev.include?(?&) # it delimits the backslash run-length encoding "&n&"
  end
end

class LOLCODE < CodeGen
  File = "QR.lol"
  Cmd = "lci QR.lol > OUTFILE"
  Apt = [nil]
  def code
    <<-'END'.lines.map {|l| l.strip }.join
      %(
        HAI 1,
        VISIBLE "#{
          PREV.gsub(/[:"]/,":\\0")
        }",
        KTHXBYE
      )
    END
  end

  def check(prev)
    raise if prev.include?("\n") # lci's VISIBLE "..." cannot span lines
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

class Koka < CodeGen
  Name = "Koka"
  File = "qr.kk"   # Koka needs a lowercase file name (it is the module name)
  Cmd = "koka -v0 -o qrkoka qr.kk && chmod +x qrkoka && ./qrkoka > OUTFILE"
  Apt = [nil]
  Code = %q(%(fun main(){print(r##"#{PREV}"##)}))
  def check(prev)
    raise "Koka: payload holds the raw-string end mark" if prev.include?('"##')
    raise "Koka: control character" if prev =~ /[\x00-\x08\x0b-\x1f\x7f]/
    raise "Koka: not UTF-8" unless prev.dup.force_encoding("UTF-8").valid_encoding?
  end
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

class Lisaac < CodeGen
  File = "qr.li"
  Cmd = "lisaac -gcc -Wno-implicit-function-declaration qr.li > /dev/null && ./qr > OUTFILE"
  Apt = [nil] # noble lisaac 0.39~rc1 .debs, see src/extra-installs/
  # a source line must stay under 255 columns, so print 88-char pieces, one per line
  Code = %q(%(Section Header+name:=QR;Section Public-main<-(#{(PREV).scan(/.{1,88}/m).map{|c|N+%("#{e[c]}".print;)}*""}#{N});))
  def check(prev); raise if prev =~ /[^\t\n -~]/; end
end

class CSharp_Chef < CodeGen
  Name = ["C#", "Chef"]
  File = ["QR.cs", "QR.chef"]
  csproj = <<-END
    <Project Sdk="Microsoft.NET.Sdk">
      <PropertyGroup>
        <OutputType>Exe</OutputType>
        <TargetFramework>net10.0</TargetFramework>
        <EnableDefaultCompileItems>false</EnableDefaultCompileItems>
      </PropertyGroup>
      <ItemGroup>
        <Compile Include="QR.cs" />
      </ItemGroup>
    </Project>
  END
  Cmd = [
    %(echo '#{ csproj.lines.map {|s| s.strip }.join }' > tmp.csproj && DOTNET_NOLOGO=1 dotnet run --project tmp.csproj > OUTFILE),
    "PERL5LIB=vendor/local/lib/perl5 compilechef QR.chef QR.chef.pl && perl QR.chef.pl > OUTFILE"
  ]
  Apt = ["dotnet-sdk-10.0", nil]
  def code
    <<-'END'.lines.map {|l| l.strip }.join
      %(
        #$C("Quine Relay Coffee.\\n\\nIngredients.\\n");
        for(int i=9;i++<126;)#$C($"{i} l {i}\\n");
        #$C("\\nMethod.\\n");
        foreach(int c in#{E[PREV.reverse]})#$C($"Put {c}.");
        #$C("Pour contents of the mixing bowl into the baking dish.\\n\\nServes 1.");
      )
    END
  end

  def check(prev)
    # the Chef recipe declares no other ingredient
    raise unless prev.bytes.all? {|b| (10..126).cover?(b) }
  end
end

class Macaulay2 < CodeGen
  Name = "Macaulay2"
  File = "QR.m2"
  Cmd = "M2 --script QR.m2 > OUTFILE"
  Apt = "macaulay2"
  # /// ... /// is a raw string: no escaping, so it adds no backslashes
  Code = %q(%(<< ///#{PREV}///))
  def check(prev); raise if prev.include?("///"); end
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

class Miranda < CodeGen
  Name = "Miranda"
  File = "QR.mira"
  Cmd = "mira -exec QR.mira > OUTFILE"
  Apt = [nil]
  Code = %q(("main=["+(PREV).scan(/.{1,500}/m).map{|s|%(Stdout "#{e[s].gsub(9.chr,B+?t)}")}*","+"]\n"))

  def check(prev)
    raise "Miranda: non-printable or non-ASCII byte" if prev =~ /[^\t\n\x20-\x7e]/
  end
end

class Java_ < CodeGen
  Name = "Java"
  File = "QR.java"
  Cmd = "javac QR.java && java QR > OUTFILE"
  Apt = "openjdk-25-jdk"
  def code
    <<-'END'.lines.map {|l| l.strip }.join
      %(
        void main(){
            String c[]=new String[999999],z="",s=String.join("",new String[]{#{
              z=t=(0..r=q=127).map{|n|[n,[]]};
              a="";
              b=->n{a<<(n%78+55)%84+42};
              (PREV).bytes{|n|
                r,z=z[n]||(
                  b[r/78];b[r];
                  q<6083&&z[n]=[q+=1,[]];
                  t[n])
              };
              b[r/78];b[r];
              a.scan(/.{1,30000}/m).map{|m00j|"\""+m00j+"\""}*?,
            }});
            int i=0,n=0,q=0;
            for(;++n<127;)c[n]=""+(char)n;
            for(;i<#{a.size};){
              q=q*78+(s.charAt(i)-13)%84;
              if(i++%2>0){
                c[n]=z+(q<n++?c[q]:z).charAt(0);
                IO.print(z=c[q]);
                q=0;
              }
            }
          }
      )
    END
  end

  def check(prev)
    raise if prev.bytes.any? {|b| b < 1 || b > 126 }
  end
end

class UCBLogo < CodeGen
  Name = "UCBLogo"
  File = "QR.logo"
  Cmd = "ucblogo QR.logo > OUTFILE"
  Apt = [nil]   # src/extra-installs/ (built without wx, so it needs no display)
  # FIRST [|...|] is a word that keeps every character as it is; " and | are written as CHAR 34 and
  # CHAR 124 so the source contains neither " nor |; split into TYPE lines <= 24 KB to stay under upstream line limits.
  Code = %q(%(#{PREV.scan(/.{1,12000}/m).flat_map{|y|y.split(/(["|])/)}.reject(&:empty?).map{|x|x==?"?"CHAR 34":x==?|?"CHAR 124":"FIRST [|#{x}|]"}.inject([[]]){|g,x|g[-1][0]&&g[-1].sum(&:size)+x.size>24000?g<<[x]:g[-1]<<x;g}.map{|l|"TYPE (WORD #{l*" "})"}*N} BYE))

  def check(prev)
    # \ is still an escape inside |...|, and a newline would split a word
    raise if prev =~ /[\\\n]/
    raise if prev =~ /[$&'^_]/ # upstream: Groovy refuses ' & _, D refuses $, AspectJ refuses ^
  end
end

class GriLang < CodeGen
  Name = "Gri"
  File = "QR.gri"
  Cmd = "gri -output QR.gri.ps QR.gri > OUTFILE"
  Apt = "gri"
  # Emit one show per line so each line stays well under Gri's 32,767-byte line limit.
  Code = %q(%(#{PREV.split(N).map{|l|%(show "#{l}")}*N}\n)) # Gri warns on stdout if the last line has no newline

  def check(prev)
    # Gri ends the string at the first " (even after a \) and parses the rest as an expression,
    # \ starts a synonym, and one show prints one line
    raise if prev =~ /["\\]/
    raise if prev =~ /[$&'^_]/ # upstream: Groovy refuses ' & _, D refuses $, AspectJ refuses ^
    raise if prev.split("\n").any? { |l| l.size + 7 > 32000 } # Gri's line limit (32767 fails)
  end
end

class MaximaLang < CodeGen
  Name = "Maxima"
  File = "QR.mac"
  Cmd = "maxima -q --init-mac=QR.mac > OUTFILE"
  Apt = "maxima"
  # the payload is cut at each " and newline and glued back with ascii(34) / ascii(10), so no \ is
  # needed and the source is one line; linel stops Maxima wrapping long lines.
  # Build "~a" via sconcat(ascii(126),"a") so the source contains no literal ~ character.
  Code = %q(%(linel:99999;printf(true,sconcat(ascii(126),"a"),sconcat(#{PREV.split(/(["\n])/).map{|x|x==?"?"ascii(34)":x==N ? "ascii(10)":%("#{x}")}*?,}));quit();))

  def check(prev)
    # \ is the escape character in Maxima strings
    raise if prev.include?("\\")
    raise if prev =~ /[$&'^_]/ # upstream: Groovy refuses ' & _, D refuses $, AspectJ refuses ^
  end
end

class JuliaLang < CodeGen
  Name = "Julia"
  File = "QR.jl"
  Cmd = "julia QR.jl > OUTFILE"
  Apt = [nil]   # src/extra-installs/
  # triple-quoted raw string: no $ interpolation, and a lone " needs no escape
  Code = %q(%(print(raw"""#{PREV}""")))

  def check(prev)
    # """ would close it, \ before " is still special in a raw string, a " at the end would merge
    # into the closing """, and a newline would start the dedent rules
    raise if prev =~ /"""|\\|"\z|\n/
    raise if prev =~ /[$&'^_]/ # upstream: Groovy refuses ' & _, D refuses $, AspectJ refuses ^
  end
end

class DafnyLang < CodeGen
  Name = "Dafny"
  File = "QR.dfy"
  # dafny run would print the verifier's summary into OUTFILE, so verify+build first, then run the dll;
  # -o keeps its QR.cs / QR.dll out of the way of the C# step's files
  Cmd = "dafny build -o dafny-out/QR QR.dfy && DOTNET_ROLL_FORWARD=Major dotnet dafny-out/QR.dll > OUTFILE"
  Apt = [nil]   # src/extra-installs/
  # verbatim string: only " is special, and it is doubled
  Code = %q(%(method Main(){print @"#{d[PREV]}";}))

  def check(prev)
    raise if prev =~ /[$&'^_]/ # upstream: Groovy refuses ' & _, D refuses $, AspectJ refuses ^
  end
end

class ReScript < CodeGen
  File = "QR.res"
  Cmd = "bsc QR.res > QR.res.js && node QR.res.js > OUTFILE"
  Apt = [nil] # npm rescript (src/extra-installs/)
  # every " is carried as ~ and put back with String.fromCharCode(34), so nothing is escaped;
  # Console.log appends a trailing newline
  Code = %q(%[Console.log(String.replaceAll("#{PREV.tr(?",?~)}", "~", String.fromCharCode(34)))])
  def check(prev)
    raise if prev =~ /[~\\\n\r]/
  end
end

class Prolog < CodeGen
  File = "QR.prolog"
  Cmd = "swipl -q -t qr -f QR.prolog > OUTFILE"
  Apt = "swi-prolog"
  Code = %q("qr:-write#{E[PREV]}.")
end

class PostScript < CodeGen
  Name = "PostScript"
  File = "QR.ps"
  Cmd = "gs -dNODISPLAY -q QR.ps > OUTFILE"
  Apt = "ghostscript"
  Code = %q("(#{Q[PREV,B]})print quit")

  def check(prev)
    # a PostScript (...) literal counts nested parens, and only the backslash is escaped here
    raise unless prev.match?(PARENS)
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

class Haskell < CodeGen
  File = "QR.hs"
  Cmd = "rm -f QR.o && ghc QR.hs && ./QR > OUTFILE"
  Apt = "ghc"
  Code = %q("main=putStr"+E[PREV])

  def check(prev)
    # only \, " and newline are escaped, and GHC rejects a raw control character in a literal
    raise if prev =~ /[^\n\x20-\x7e]/
  end
end

class Pyret < CodeGen
  File = "QR.arr"
  Cmd = "pyretc QR.arr QR.jarr && NODE_PATH=/opt/b05/node_modules node QR.jarr > OUTFILE"
  Apt = [nil] # npm pyret-npm; pyretc runs its compiler without the background server (src/extra-installs/)
  Code = %q(%(print("#{e[PREV]}")))
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

class Zig < CodeGen
  Name = "Zig"
  File = "QR.zig"
  Cmd = "zig run QR.zig > OUTFILE"
  Apt = [nil]
  Code = %q(%(pub fn main()!void{try @import("std").io.getStdOut().writeAll(\n#{B*2+(PREV).gsub(N){N+B*2}}\n);}))
  def check(prev)
    raise if prev =~ /[\x00-\x09\x0b-\x1f\x7f]/ || !prev.ascii_only?
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

class Groovy < CodeGen
  File = "QR.groovy"
  Cmd = "groovy QR.groovy > OUTFILE"
  Apt = "groovy"
  def code
    <<-'END'.lines.map {|l| l.strip }.join
      %(
        #{(PREV).tr(?"+B,"&_").scan(/.{1,20000}/m).map{|m00g|"print'#{m00g}'.tr('_&','"+B*2+?\"+"');"}*""}
      )
    END
  end

  def check(prev)
    raise if prev.include?(?')
    raise if prev =~ /[&_]/
    raise if prev.include?("\n")
  end
end

class TypeScript_Unlambda < CodeGen
  File = ["QR.ts", "QR.unl"]
  Cmd = ["tsc --outFile QR.ts.js QR.ts && $(JAVASCRIPT) QR.ts.js > OUTFILE", "ruby vendor/unlambda.rb QR.unl > OUTFILE"]
  Apt = ["node-typescript", nil]
  def code
    <<-'END'.lines.map {|l| l.strip }.join
      "let t:string='k',c:string;for(c of#{E[PREV]})t='\\x60.'+c+t;console.log(t)"
    END
  end

  def check(prev)
    raise if prev.include?("\n") # `.<newline> is not a valid token
  end
end

class Gambas < CodeGen
  Name = "Gambas script"
  File = "QR.gbs"
  Cmd = "$(GBS) QR.gbs > OUTFILE"
  Apt = [["gambas3-scripter", "gambas3-gb-pcre"]]
  Code = %q(%(print"#{e[PREV]}"))
end

class Gnuplot < CodeGen
  File = "QR.plt"
  Cmd = "gnuplot QR.plt > OUTFILE"
  Apt = "gnuplot"
  Code = %q('set print"-";print'+E[PREV])

  def check(prev)
    raise "Gnuplot: backquote in the payload (gnuplot runs `...` as a shell command)" if prev.include?("`")
  end
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

class Koto < CodeGen
  File = "QR.koto"
  Cmd = "koto QR.koto > OUTFILE"
  Apt = [nil] # cargo install koto_cli
  Code = %q(%(io.stdout().write r#'#{PREV}'#))

  def check(prev)
    raise if prev.include?("'#")
  end
end

class Swift < CodeGen
  File = "QR.swift"
  Cmd = "swiftc QR.swift && ./QR > OUTFILE"
  Apt = "swiftlang"
  Code = %q("print"+E[PREV])
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

class Singular < CodeGen
  Name = "Singular"
  File = "QR.sing"
  Cmd = "Singular -q QR.sing > OUTFILE"
  Apt = "singular"
  Code = %q(%(string s="";\n#{PREV.chomp.scan(/.{1,2000}/m).map{|c|%(s=s+"#{Q[Q[c,B],?"]}";\n)}*""}s;quit;))
  def check(prev)
    raise "Singular: payload must end with one newline" unless prev.end_with?("\n") && !prev.end_with?("\n\n")
    raise "Singular: non-printable byte" if prev =~ /[^\n\x20-\x7e]/
  end
end

class VLang < CodeGen
  Name = "V"
  File = "QR.vlang.v"
  Cmd = "v run QR.vlang.v > OUTFILE"
  Apt = [nil]
  Code = %q(%(fn main(){#{(PREV).split(?',-1).map{|s|%(print(r'#{s}');)}*%(print("'");)}}))
  def check(prev)
    raise if prev.include?("\0") || prev.include?("\r")
  end
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

class FSharp < CodeGen
  Name = "F#"
  File = "QR.fsx"
  Cmd = "DOTNET_NOLOGO=1 dotnet fsi --quiet --exec QR.fsx > OUTFILE"
  Apt = "dotnet-sdk-10.0"
  Code = %q(%(#$C """#{PREV} """))

  def check(prev)
    raise if prev.include?('"""') # it closes the triple-quoted string
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

class Go < CodeGen
  File = "QR.go"
  Cmd = "go run QR.go > OUTFILE"
  Apt = "golang"
  def code
    <<-'END'.lines.map {|l| l.strip }.join
      %(
        package main;
        import"fmt";
        func main(){
          fmt.Print#{E[PREV]}
        }
      )
    END
  end

  def check(prev)
    # the Go compiler rejects a source file that is not valid UTF-8
    raise unless prev.dup.force_encoding("UTF-8").valid_encoding?
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

class FALSELang < CodeGen
  Name = "FALSE"
  File = "QR.false"
  Cmd = "ruby vendor/false.rb QR.false > OUTFILE"
  Apt = [nil]
  Code = %q(?"+PREV.gsub(?",'"34,"')+?")
end

class Fish < CodeGen
  File = "QR.fish"
  Cmd = "fish QR.fish > OUTFILE"
  Apt = "fish"
  Code = %q("echo '#{Q[PREV,/['\\\\]/]}'")
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

class Forth_Fortran90 < CodeGen
  File = ["QR.fs", "QR.f90"]
  Cmd = [
    "gforth QR.fs > OUTFILE",
    "gfortran -o QR QR.f90 && ./QR > OUTFILE"
  ]
  Apt = ["gforth", "gfortran"]
  Code = %q((m00s=0;m00b=(PREV).scan(/[\x20\x21\x23-\x26\x28-\x5b\x5d-\x7d]{1,38}|./m).map{|m00t|m00o=m00t.ord;m00o<32||m00o>125||m00o==34||m00o==39||m00o==92 ? [1,m00o.to_s] : [0,m00t]};m00c=m00b.each_slice(500).flat_map{|m00g|m00i=m00s;m00s+=1;[[2,"subroutine s#{m00i}"]]+m00g+[[2,"end"]]};m00m=(0...m00s).map{|m00i|[2,"call s#{m00i}"]}+[[2,"end"],[2,"subroutine p(s)"],[2,"character(*)s"],[2,"write(*,'(a)',advance='no')s"],[2,"end"],[2,"subroutine c(n)"],[2,"write(*,'(a)',advance='no')char(n)"],[2,"end"]];%(: L 126 PARSE TYPE CR ; : P ." call p('" 126 PARSE TYPE ." ')" CR ; : C ." call c(" 126 PARSE TYPE ." )" CR ; )+(m00c+m00m).map{|m00k,m00v|(m00k==0 ? "P " : m00k==1 ? "C " : "L ")+m00v+126.chr}*" "+%( BYE)))
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

class GDB < CodeGen
  File = "QR.gdb"
  Cmd = "gdb -q -x QR.gdb > OUTFILE"
  Apt = "gdb"
  Code = %q('echo '+e[PREV]+"\nquit")
end

class Squirrel < CodeGen
  File = "QR.nut"
  Cmd = "squirrel QR.nut > OUTFILE"
  Apt = "squirrel3"
  Code = %q("print"+E[PREV])
end

class Zsh < CodeGen
  Name = "zsh"
  File = "QR.zsh"
  Cmd = "zsh QR.zsh > OUTFILE"
  Apt = "zsh"
  Code = %q("cat<<\\\\Q\n#{PREV}\nQ")
end

class GAP < CodeGen
  File = "QR.g"
  Cmd = "gap -q QR.g > OUTFILE"
  Apt = "gap"
  Code = %q("WriteAll(OutputTextUser(),#{E[PREV]});QUIT;")
end

class Haxe < CodeGen
  File = "QR.hx"
  Cmd = "haxe -main QR -neko QR.n && neko QR.n > OUTFILE"
  Apt = "haxe"
  Code = %q("class QR{#$L function main()Sys.print#{E[PREV]};}")
end

class Tcsh_Thue < CodeGen
  Name = ["tcsh", "Thue"]
  File = ["QR.tcsh", "QR.t"]
  Cmd = ["tcsh QR.tcsh > OUTFILE", "ruby vendor/thue.rb QR.t > OUTFILE"]
  Apt = ["tcsh", nil]
  Code = %q(%(cat<<\\\\E\na::=~#{PREV}\n::=\na\n\\\\E))

  def check(prev)
    raise if prev.include?("\n") # a Thue rule is one line
  end
end

class Fennel < CodeGen
  File = "QR.fnl"
  Cmd = "fennel QR.fnl > OUTFILE"
  Apt = "fennel"
  Code = %q("(io.write \"#{e[PREV]}\")")
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

class Erlang < CodeGen
  File = "QR.erl"
  Cmd = "escript QR.erl > OUTFILE"
  Apt = "erlang"
  Code = %q("\nmain(_)->io:put_chars#{E[PREV]}.")
end

class Elixir < CodeGen
  File = "QR.exs"
  Cmd = "elixir QR.exs > OUTFILE"
  Apt = "elixir"
  Code = %q("IO.write#{E[PREV]}")

  def check(prev)
    raise if prev.include?('#{') # Elixir interpolates it in a "" string
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

class EmacsLisp < CodeGen
  Name = "Emacs Lisp"
  File = "QR.el"
  Cmd = "emacs -Q --script QR.el > OUTFILE"
  Apt = "emacs-nox"
  Code = %q(%((princ"#{e[PREV]}")))
end

class Anko < CodeGen
  File = "QR.ank"
  Cmd = "anko QR.ank > OUTFILE"
  Apt = [nil] # go install github.com/mattn/anko
  Code = %q(%(fmt=import("fmt");fmt.Print(`#{(PREV).gsub("`",%(`+"`"+`))}`)))
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
  def code
    <<-'END'.lines.map {|l| l.strip }.join
      "
        console.log#{V[E[PREV],'"+"\\\\".repeat(',')+"']}
      "
    END
  end
end

class Tengo < CodeGen
  File = "QR.tengo"
  Cmd = "tengo QR.tengo > OUTFILE"
  Apt = [nil] # go install github.com/d5/tengo/v2/cmd/tengo
  # raw back-tick string; each back-tick is spliced in as "`"
  Code = %q(%(fmt:=import("fmt");fmt.print(`#{(PREV).gsub("`",%(`+"`"+`))}`)))
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

class Gosu < CodeGen
  File = "QR.gsp"
  Cmd = "gosu QR.gsp > OUTFILE"
  Apt = [nil]
  Code = %q((PREV).scan(/.{1,15000}/m).map{|b04c|"System.out.print("+Q[E[b04c]].gsub("<%","<\"+\"%")+");"}*"")

  def check(prev)
    prev.scan(/.{1,15000}/m) { raise if escape($&).bytesize + $&.count("$") + 10 > 65000 }
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

class D < CodeGen
  File = "QR.d"
  Cmd = "gdc -o QR QR.d && ./QR > OUTFILE"
  Apt = "gdc"
  Code = %q(%(import std;void main(){write(q"$#{PREV}$");}))

  def check(prev)
    raise if prev.include?("$") # it delimits the q"$...$" string
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

class LFE < CodeGen
  Name = "LFE"
  File = "QR.lfe"
  Cmd = "lfe QR.lfe > OUTFILE"
  Apt = "erlang-nox"
  Code = %q("(lists:foreach\n (lambda (s) (io:put_chars (base64:decode (tl (atom_to_list s)))))\n \x27(\n"+[PREV].pack("m0").scan(/.{1,248}/).map{|b16f|"a"+b16f}.join(N)+"\n))\n(erlang:halt 0)\n")

  def check(prev)
    raise unless prev.ascii_only?
  end
end

class ArnoldC < CodeGen
  Name = "ArnoldC"
  File = "QR.arnoldc"
  Cmd = "rm -f QR.class && java -jar /opt/ArnoldC.jar QR.arnoldc && java QR > OUTFILE && rm -f QR.class"
  Apt = "default-jdk-headless"
  Code = %q((b16g=(PREV).lines.map{|b16e|"TALK TO THE HAND \""+b16e.chomp+"\x22"}.each_slice(2000).to_a;"IT\x27S SHOWTIME\n"+b16g.each_index.map{|b16i|"DO IT NOW m#{b16i}\n"}*""+"YOU HAVE BEEN TERMINATED\n"+b16g.each_with_index.map{|b16s,b16i|"LISTEN TO ME VERY CAREFULLY m#{b16i}\n"+b16s*N+"\nHASTA LA VISTA, BABY\n"}*""))

  def check(prev)
    raise unless prev.ascii_only? && prev.end_with?("\n")
    raise if prev =~ /["\\\r]/
  end
end

class GeneratorScriptingLanguage < CodeGen
  Name = "GSL (Generator Scripting Language)"
  File = "QR.gsl"
  Cmd = "gsl -q QR.gsl > OUTFILE"
  Apt = "generator-scripting-language"
  Code = %q(".template 1\n#{d[PREV,B]}\n.endtemplate")

  def check(prev)
    raise if prev =~ /^\./        # a template line starting with "." is a GSL command
    raise if prev.include?("$(")  # $( ... ) is a GSL substitution
    raise if prev.include?("\r")
    raise "GSL: backslash then two spaces on one line (gsl re-pads the space run)" if prev =~ /\\[^\n]*  /
    raise "GSL: backslash in the payload (gsl drops some of them)" if prev.include?(92.chr)
    raise "GSL: trailing space on a line (gsl strips trailing spaces)" if prev =~ / $/
    raise "GSL: line >= 1024 B containing '.' (gsl 1024-byte chunk dot-command hazard)" if prev.lines.any? { |l| l.bytesize >= 1024 && l.include?(".") }
  end
end

class IonShell < CodeGen
  Name = "Ion"
  File = "QR.ion"
  Cmd = "ion QR.ion > OUTFILE"
  Apt = [nil]
  Code = %q(%(echo -n '#{(PREV).gsub(?',%('"'"'))}'))
  def check(prev)
    raise if prev.include?("\0") || prev.include?("\r") || prev.start_with?("-")
  end
end

class Factor < CodeGen
  Name = "Factor"
  File = "QR.factor"
  Cmd = "/opt/factor/factor QR.factor > OUTFILE"
  Apt = [nil]
  Code = %q(("USE: io\n"+(PREV).scan(/[\x20\x21\x23-\x5b\x5d-\x7e]{1,60}|./m).map{|b16v|(b16v.size>1||("\x22"+B+N).index(b16v)==nil) ? ("\x22"+b16v+"\" write") : "#{b16v.ord} write1"}.each_slice(6).map{|b16w|b16w.join(" ")}.join(N)+N))

  def check(prev)
    raise unless prev.ascii_only?
    raise if prev.include?("\r")
  end
end

class Lobster < CodeGen
  Name = "Lobster"
  File = "QR.lobster"
  Cmd = "lobster QR.lobster > OUTFILE"
  Apt = [nil]
  # Triple-quoted """...""" is a multiline raw string (no backslash escapes).
  # Chunked <=40 lines per print to stay well below Lobster ToString's 100,000-byte truncation cap.
  Code = %q(((PREV).chomp.split(N,-1).each_slice(40).map{|a|%(print """#{a*N}""")}*N+N))

  def check(prev)
    raise "Lobster: needs trailing newline" unless prev.end_with?("\n")
    raise "Lobster: payload holds triple quote" if prev.chomp.include?('"""')
    raise "Lobster: NUL or CR" if prev.include?("\0") || prev.include?("\r")
    prev.chomp.split("\n", -1).each_slice(40) do |a|
      s = a.join("\n")
      raise "Lobster: chunk >= 90KB (truncates at 100KB)" if s.bytesize >= 90_000
      raise "Lobster: chunk ends with quote" if s.end_with?('"')
    end
  end
end

class Emmental < CodeGen
  Name = "Emmental"
  File = "QR.emmental"
  Cmd = "ruby vendor/emmental.rb QR.emmental > OUTFILE"
  Apt = [nil]
  Code = %q((b16p=(PREV);b16b="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz :\x27+/=-";b16c=[["@",34],["$",10]]+"&*\x5e_|".chars.each_with_index.map{|b16d,b16i|[b16d,48+b16i]};b16h=[];b16m={};b16b.each_byte{|b16x|b16s="##{b16x}.";b16h<<";"+b16s.bytes.map{|b16k|"##{b16k}"}.join+"##{b16x}\x21";b16m[b16x]=b16x.chr};b16c.each{|b16y,b16t|b16o=b16y.ord;b16s="##{b16t}.";b16h<<";"+b16s.bytes.map{|b16k|"##{b16k}"}.join+"##{b16o}\x21";b16m[b16t]=b16y};(b16h+b16p.bytes.map{|b16x|b16m[b16x]||"##{b16x}."}).join+N))

  def check(prev)
    raise unless prev.ascii_only?
  end
end

class Pyth < CodeGen
  Name = "Pyth"
  File = "QR.pyth"
  Cmd = "python3 /opt/pyth/pyth.py -n QR.pyth > OUTFILE"
  Apt = "python3"
  Code = %q("\x22"+(PREV).chomp+"\x22")

  def check(prev)
    raise unless prev.ascii_only? && prev.end_with?("\n")
    raise if prev =~ /["\\\r]/
  end
end

class MMIX < CodeGen
  Name = "MMIX"
  File = "QR.mms"
  Cmd = "mmixal -b 2000000 -o QR.mmo QR.mms && mmix QR.mmo > OUTFILE && rm -f QR.mmo"
  Apt = [nil]
  Code = %q(" LOC #100\nMain GETA $255,S\n TRAP 0,Fputs,StdOut\n SET $255,0\n TRAP 0,Halt,0\nS BYTE "+(PREV).scan(/[\x20\x21\x23-\x7e]{1,60}|./m).map{|b18m|b18m=="\x22"||b18m==N ? b18m.ord : %("#{b18m}")}.join("\n BYTE ")+",0\n")
  def check(prev)
    raise "MMIX: bad byte" if !prev.ascii_only? || prev =~ /[\x00-\x09\x0b-\x1f\x7f]/
  end
end

class Cplusplus < CodeGen
  Name = "C++"
  File = "QR.cpp"
  Cmd = "$(CXX) -o QR QR.cpp && ./QR > OUTFILE"
  Apt = "g++"
  def code
    <<-'END'.lines.map {|l| l.strip }.join
      "
        #include<cstdio>\n
        int main(){{
          puts#{E[PREV]};;;;;
        };;;;;}
      "
    END
  end
end

class C < CodeGen
  File = "QR.c"
  Cmd = "$(CC) -o QR QR.c && ./QR > OUTFILE"
  Apt = "gcc"
  def code
    # LZ77-like compression
    <<-'END'.lines.map {|l| l.strip.gsub(/^_+/) { " " * $&.size } }.join
    (
      s=PREV;
      t={};b="";L="";n=i=0;D=->n{L<<(n+62)%92+35;D};
      s.bytes{|c|
        u=t[c]||=[];
        n>0?
          n-=1:
          (u.shift while u[0]&&(u.size>24||u[0]<i-3560);
           w=4;v=0;
           u.each{|j|k=0;k+=1 while k<91&&s.getbyte(i+1+k)==s.getbyte(j+k)&&s.getbyte(j+k);if k>4&&(k>w||(k==w&&j>v)) then w=k;v=j end};
           v>0)?
          (
            n=w;j=v;
            b.gsub(/.{1,3999}/m){|q|D[(z=q.size)%87][z/87];L<<q};b="";
            x=4001+i-j;D[x%87][x/87][n-5]
          ):b<<c;
        u<<(i+=1)
      };
      "
        #include<stdio.h>\n
        char*p=#{E[L]},s[4999999],*q=s;
        int main(){
          for(int n,m;*p;){
            n=(*p-5)%92+(p[1]-5)%92*87;
            p+=2;
            for(m=n>3999?(*p++-5)%92+6:n;m--;q++)*q=n>3999?q[4000-n]:*p++;
          }
          puts(s);
        }\n
      "
    )
    END
  end

  def check(prev)
    raise if prev.bytesize >= 4999999 # the decoder buffer is char s[4999999]
    raise unless prev[-6..] == prev[-12..-7] # the LZ77 encoder drops the trailing literals
  end
end

class PureScript < CodeGen
  File = "QR.purs"
  Cmd = "purs compile -o purs_out QR.purs '/opt/purs/lib/*/src/**/*.purs' && node purs_out/QR/index.js > OUTFILE && rm -rf purs_out"
  Apt = [nil]
  # """...""" is a raw string: no escapes at all; log restores the chomped trailing newline
  Code = %q(%(module QR where\nimport Prelude\nimport Effect.Console (log)\nimport Effect.Unsafe (unsafePerformEffect)\no :: Unit\no = unsafePerformEffect (log """#{(PREV).chomp}""")\n))
  def check(prev)
    raise "PureScript: needs trailing newline" unless prev.end_with?("\n")
    raise if prev.chomp.include?('"""') || prev.chomp.end_with?('"')
  end
end

class Gluon < CodeGen
  Name = "Gluon"
  File = "QR.glu"
  Cmd = "gluon QR.glu > OUTFILE"
  Apt = [nil]
  # Rust-style raw string r###"..."###; io.print omits trailing LF.
  Code = %q(%(let io = import! std.io#{N}io.print r###"#{PREV}"####{N}))

  def check(prev)
    raise "Gluon: payload contains raw end mark \"###" if prev.include?('"###')
    raise "Gluon: NUL or non-ASCII" if prev.include?("\0") || !prev.ascii_only?
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

class Berry < CodeGen
  Name = "Berry"
  File = "QR.be"
  Cmd = "berry QR.be > OUTFILE"
  Apt = [nil]                # source build v1.1.0, see src/extra-installs/
  Code = %q(%(print("#{e[(PREV).chomp]}")))
  def check(prev)
    raise "Berry: non-printable byte" if prev =~ /[^\n\x20-\x7e]/
    raise "Berry: expected trailing newline" unless prev.end_with?("\n")
  end
end

class Hy < CodeGen
  File = "QR.hy"
  Cmd = "hy QR.hy > OUTFILE"
  Apt = "hy"
  Code = %q(%((print "#{e[PREV]}" :end "")))
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

class Awk < CodeGen
  Name = "Awk"
  File = "QR.awk"
  Cmd = "awk -f QR.awk > OUTFILE"
  Apt = "gawk"
  Code = %q("BEGIN{print#{E[PREV]}}")
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

class Mathics < CodeGen
  Name = "Mathics"
  File = "QR.wl"
  Cmd = "mathics -q --no-completion -f QR.wl < /dev/null > OUTFILE"
  Apt = [nil]                # pip mathics3==10.0.1, see src/extra-installs/
  Code = %q(%(WriteString["stdout","#{e[PREV]}"]))
  def check(prev)
    raise "Mathics: non-printable byte" if prev =~ /[^\n\x20-\x7e]/
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

class Rust < CodeGen
  File = "QR.rs"
  Cmd = "rustc QR.rs && ./QR > OUTFILE"
  Apt = "rustc"
  Code = %q(%(fn main(){print!("{}",#{E[PREV]})}))
end

class Bash_Bc < CodeGen
  Name = ["bash", "bc"]
  File = ["QR.bash", "QR.bc"]
  Cmd = [
    "bash QR.bash > OUTFILE",
    "BC_LINE_LENGTH=4000000 bc -q QR.bc > OUTFILE",
  ]
  Apt = ["bash", "bc"]
  def code
    <<-'END'.lines.map {|l| l.strip }.join
      %(sed 's/\\\\/\\\\\\\\/g;s/"/\\\\q/g;s/.*/print "&"\\nquit/'<<\\E\n#{PREV}\nE)
    END
  end

  def check(prev)
    raise if prev.include?("\n") # sed appends "quit" to each line
  end
end

class VHDL < CodeGen
  File = "QR.vhdl"
  Cmd = "ghdl -a QR.vhdl && ghdl -e qr && ghdl -r qr > OUTFILE"
  Apt = "ghdl"
  # "" for a quote; control characters are spliced in with character'val
  Code = %q(%(use std.textio.all;entity QR is end;architecture A of QR is begin process begin write(output,"#{(PREV).gsub(?",%("")).gsub(/[\x00-\x1f\x7f]/){%("&character'val(#{$&.ord})&")}}");wait;end process;end;))
end

class Scheme < CodeGen
  File = "QR.scm"
  Cmd = "$(SCHEME) QR.scm > OUTFILE"
  Apt = "guile-3.0"
  Code = %q((nsx=(PREV).gsub(":",":c").gsub(34.chr,":q");9.downto(0){|nsi|nsx=nsx.gsub(B*(1<<nsi),":#{nsi}")};%((define s "#{nsx}")(define n (string-length s))(let l ((i 0)) (if (< i n) (let ((c (string-ref s i))) (if (char=? c (integer->char 58)) (let ((d (char->integer (string-ref s (+ i 1))))) (display (cond ((= d 99) ":") ((= d 113) (string (integer->char 34))) (else (make-string (expt 2 (- d 48)) (integer->char 92))))) (l (+ i 2))) (begin (write-char c) (l (+ i 1))))))))))
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

class Asymptote < CodeGen
  File = "QR.asy"
  Cmd = "asy QR.asy > OUTFILE"
  Apt = "asymptote"
  Code = %q("write('#{Q[e[PREV],?']}');")
end

class AspectJ < CodeGen
  File = "QR.aj"
  Cmd = "ajc QR.aj && java -cp .:/usr/share/java/aspectjrt.jar QR > OUTFILE"
  Apt = "aspectj"
  def code
    <<-'END'.lines.map {|l| l.strip }.join
      %(
        class QR{#$L void main(String[]a){}}
        aspect Q{
          before():execution(void QR.main(..)){
            String[]a=String.join("",new String[]{#{PREV.gsub(Regexp.union(94.chr,/\\+/)){"^#{94.chr==$&?0:$&.size}^"}.scan(/.{1,15000}/m).map{|c|E[c]}*?,}}).split("\\\\^",-1);
            StringBuilder o=new StringBuilder(a[0]);
            for(int i=1;i<a.length;o.append(a[i+1]),i+=2){
              int n=Integer.parseInt(a[i]);
              o.append(n<1?"^":"\\\\".repeat(n));
            }
            System.out.print(o);
          }
        }
      )
    END
  end

  def check(prev)
    # every 15,000-char RLE chunk stays well below JVM's 65,535-byte CONSTANT_Utf8 limit
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

class Mirth < CodeGen
  Name = "Mirth"
  File = "QR.mth"
  Cmd = "mirth -p std:/opt/mirth/lib/std -p qr:. ./QR.mth -o QR.mth.c > /dev/null && $(CC) -O2 -Wno-trigraphs -o QR QR.mth.c && ./QR > OUTFILE"
  Apt = [nil]
  Code = %q(("module qr.QR\nimport std.prelude\nimport std.world\ndef main{\n"+(PREV).scan(/.{1,500}/m).map{|s|%( "#{e[s].gsub(9.chr,B+?t)}" print-\n)}.join+"}\n"))

  def check(prev)
    raise "Mirth: non-printable or non-ASCII byte" if prev =~ /[^\t\n\x20-\x7e]/
  end
end

class Makefile < CodeGen
  File = "QR.mk"
  Cmd = "make -f QR.mk > OUTFILE"
  Apt = "make"
  Code = %q(("a:\n"+(PREV).split(N,-1).map{|m00l|m00l.scan(/.{1,25000}/).map{|m00s|"\t@printf '%s' '#{d[m00s,?$].gsub(?'){"'#{B}''"}}'\n"}*""}*"\t@printf '#{B}n'\n"))

  def check(prev)
    raise "Makefile: NUL byte" if prev.include?("\0")
    prev.split("\n", -1).each do |line|
      line.scan(/.{1,25000}/) do |chunk|
        raise "Makefile: chunk exceeds MAX_ARG_STRLEN" if chunk.bytesize + chunk.count("'") * 3 + 20 >= 131072
      end
    end
  end
end

class Boron < CodeGen
  Name = "Boron"
  File = "QR.boron"
  Cmd = "boron QR.boron > OUTFILE"
  Apt = [nil]
  # Rebol/Urlan family: ^ is the escape char (^^, ^", ^/, ^-), so \ is literal. 94.chr avoids ABBREV key ^.
  Code = %q(%(prin "#{(PREV).gsub("^","^^").gsub(?",94.chr+?").gsub(N,"^/").gsub("\t","^-")}"#{N}))

  def check(prev)
    raise "Boron: NUL, CR, or non-ASCII" if prev.include?("\0") || prev.include?("\r") || !prev.ascii_only?
  end
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

class MUMPS < CodeGen
  Name = "MUMPS"
  File = "QRMUMPS.m"
  Cmd = "ydb_dist=/opt/yottadb ydb_routines=. /opt/yottadb/yottadb -run QRMUMPS > OUTFILE"
  Apt = [nil]
  # MUMPS "..." has no backslash escapes (only "" for "). U 0:NOWRAP prevents column wrapping.
  Code = %q(("QRMUMPS\n U 0:NOWRAP\n"+(PREV).scan(/.{1,120}/m).map{|s|" W "+s.split(/(\n|\t)/).reject(&:empty?).map{|t|(t==N)?"!":(t==9.chr)?"$C(9)":?"+d[t]+?"}.join(",")+"\n"}.join+" Q\n"))

  def check(prev)
    raise "MUMPS: needs trailing newline" unless prev.end_with?("\n")
    raise "MUMPS: non-printable or non-ASCII byte" if prev =~ /[^\t\n\x20-\x7e]/
  end
end

class PowerShell < CodeGen
  Name = "PowerShell"
  File = "QR.ps1"
  Cmd = "DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=1 POWERSHELL_TELEMETRY_OPTOUT=1 pwsh -NoProfile -NonInteractive -File QR.ps1 > OUTFILE"
  Apt = [nil]
  Code = %q(%([Console]::Out.Write('#{(PREV).gsub('@','@A').gsub(?', '@B').gsub('"','@C').gsub(B,'@D')}'.Replace('@D',[string][char]92).Replace('@C',[string][char]34).Replace('@B',[string][char]39).Replace('@A','@'))))
  def check(prev)
    raise if !prev.ascii_only? || prev.include?("\0") || prev.include?("\r")
  end
end

class ATS < CodeGen
  File = "QR.dats"
  Cmd = "patscc -o QR QR.dats && ./QR > OUTFILE"
  Apt = "ats2-lang"
  Code = %q("implement main0()=(#{PREV.split(/(?<=\?)(?=\?)/).map{|x|"print#{E[x]}"}*?;})")
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

class Frege < CodeGen
  File = "QR.fr"
  Cmd = "mkdir -p frege-out && frege -d frege-out QR.fr && java -cp frege-out:/usr/local/lib/frege.jar QR > OUTFILE"
  Apt = [nil]
  Code = %q("module QR where main args = do {"+(PREV).scan(/.{1,15000}/m).map{|b04c|"putStr"+E[b04c]}*";"+"}")

  def check(prev)
    prev.scan(/.{1,15000}/m) { raise if escape($&).bytesize > 65000 }
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

class Umka < CodeGen
  Name = "Umka"
  File = "QR.um"
  Cmd = "umka QR.um > OUTFILE"
  Apt = [nil]                # source build v1.5.7, see src/extra-installs/
  Code = %q(%(fn main(){printf("#{d[e[PREV],"%"]}")}))
  def check(prev)
    raise "Umka: non-printable byte" if prev =~ /[^\n\x20-\x7e]/
  end
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

class BQN < CodeGen
  Name = "BQN"
  File = "QR.bqn"
  Cmd = "bqn QR.bqn > OUTFILE"
  Apt = [nil]                # CBQN v0.9.0 source build, see src/extra-installs/
  Code = %q(%(#{[8226].pack("U")}term.OutRaw "#{d[PREV]}"))
  def check(prev)
    raise "BQN: non-printable byte" if prev =~ /[^\n\x20-\x7e]/
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

class Zoem < CodeGen
  File = "QR.azm"
  Cmd = "zoem -i QR.azm > OUTFILE"
  Apt = "zoem"
  Code = %q("\\\\write{-}{txt}{#{Q[PREV,/[\\\\{}]/]}}#{N}")
end

class K < CodeGen
  Name = "K (ngn/k)"
  File = "QR.k.k"
  Cmd = "ngnk QR.k.k < /dev/null > OUTFILE"
  Apt = [nil]                # ngn/k source build (pinned commit), see src/extra-installs/
  Code = %q(%(#{PREV.scan(/.{1,250}/m).each_slice(60).map{|g|"`1:"+([""]+g).map{|s|?"+e[s]+?"}*?,}*N}#{N+B+B+N}))
  def check(prev)
    raise "K: non-printable byte" if prev =~ /[^\n\x20-\x7e]/
  end
end

class Hexagony < CodeGen
  Name = "Hexagony"
  File = "QR.hxg"
  Cmd = "ruby /opt/hexagony/interpreter.rb QR.hxg > OUTFILE"
  Apt = [nil]
  Code = %q((b19u=(PREV);b19v=0;b19t=b19u.bytes.map{|b19b|b19d=b19b==b19v ? "" : b19b==b19v+1 ? ")" : b19b==b19v-1 ? "(" : b19b>64&&b19b<91||b19b>96&&b19b<123 ? (b19v=b19b).chr : "-#{b19v=b19b}";b19v=b19b if b19d.size<2;b19d+";"}+["@"];b19z=b19t.sum(&:size);b19m=4;b19m+=1 while 3*b19m*(b19m-1)-14*b19m<b19z;b19p=0;(0...2*b19m-1).map{|b19i|b19l=2*b19m-1-(b19m-1-b19i).abs;b19c=b19i==0||b19i==2*b19m-2 ? b19l-1 : b19i.odd? ? b19l-2 : b19i==b19m-1 ? b19l-4 : b19l-3;b19s=+"";(b19s<<b19t[b19p];b19p+=1) while b19p<b19t.size&&b19s.size+b19t[b19p].size<=b19c;b19s=b19s.ljust(b19c,".");b19i==0 ? b19s+"<" : b19i==2*b19m-2 ? ">"+b19s : b19i.even? ? (b19i<b19m ? ".>" : ">")+b19s+(b19i<b19m-1 ? "<" : "<.") : "/"+b19s.reverse+"/"}*""))
  def check(prev)
    raise "Hexagony: non-ASCII" unless prev.ascii_only?
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

class Dart < CodeGen
  Name = "Dart"
  File = "QR.dart"
  Cmd = "dart run QR.dart > OUTFILE"
  Apt = [nil]                # official SDK zip, see src/extra-installs/
  # Raw single-quoted string; any ' in payload closes r'...', splices "'", and
  # reopens r'...' via Dart's adjacent string literal concatenation.
  Code = %q(%(import 'dart:io';void main(){stdout.write(r'#{PREV.gsub(?',%('"'"r'))}');}))
  def check(prev)
    raise "Dart: payload holds a newline (one-line raw string)" if prev =~ /\n/
    raise "Dart: non-ASCII byte" if prev =~ /[^\x00-\x7f]/n
  end
end

class Rhai < CodeGen
  File = "QR.rhai"
  Cmd = "rhai-run QR.rhai > OUTFILE"
  Apt = [nil] # cargo install rhai --features bin-features --bin rhai-run
  # back-tick strings take no escapes; print appends a trailing newline
  Code = %q(%(print(`#{PREV}`);))

  def check(prev)
    raise if prev.include?("`") || prev.include?("${")
  end
end

class Tcl < CodeGen
  File = "QR.tcl"
  Cmd = "tclsh QR.tcl > OUTFILE"
  Apt = "tcl"
  Code = %q(%(puts "#{Q[PREV,/["$\[\\\\]/]}"))
end

class SurgeScript < CodeGen
  File = "QR.ss"
  Cmd = "surgescript QR.ss > OUTFILE"
  Apt = "surgescript"
  Code = %q(%(object"Application"{state"main"{#{f(PREV,4){%(Console.write#$S;)}}exit();}}))
end

class Verilog < CodeGen
  File = "QR.v"
  Cmd = "iverilog -o QR QR.v && ./QR -vcd-none > OUTFILE"
  Apt = "iverilog"
  Code = %q(%(module QR;initial begin #{f(PREV,3){%($write("%s",#$S);)}}end endmodule))
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

class Oberon < CodeGen
  Name = "Oberon"
  File = "QR.obn"
  Cmd = "rm -rf QR .obnc && obnc QR.obn >/dev/null && ./QR > OUTFILE && rm -rf QR .obnc"
  Apt = [nil]
  Code = %q((nop=[];(PREV).lines.each{|nol|nol.chomp.split(/([\x22\t])/).flat_map{|noq|noq=="\x22"||noq=="\t" ? [noq] : noq.scan(/.{1,2000}/)}.each{|noc|nop<<(noc=="\x22" ? "Out.Char(22X);" : noc=="\t" ? "Out.Char(9X);" : "Out.String(\x22"+noc+"\x22);")};nop<<"Out.Ln;" if nol.end_with?(N)};nog=nop.each_slice(400).to_a;"MODULE QR;IMPORT Out;"+N+nog.each_with_index.map{|nox,noi|nor=[];nox.each{|nos|nor[-1]&&nor[-1].size+nos.size<4000 ? nor[-1]<<nos : nor<<nos.dup};"PROCEDURE P#{noi};BEGIN"+N+nor*N+N+"END P#{noi};"}*N+N+"BEGIN"+N+(0...nog.size).map{|noi|"P#{noi};"}.each_slice(20).map(&:join)*N+N+"END QR."+N))

  def check(prev)
    raise unless prev.ascii_only?
    raise if prev.include?("\r")
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

class Ruby_ < CodeGen
  Name = "Ruby"
  File = "QR.rb"
  Cmd = "ruby QR.rb > OUTFILE"
  Apt = "ruby"
  Code = nil
end

load "code-gen-pool.rb" if ENV["ALL"]

GenSteps = CodeGen::List.map {|s| s.gen_step }
RunSteps = CodeGen::List.reverse.flat_map {|s| s.run_steps }
