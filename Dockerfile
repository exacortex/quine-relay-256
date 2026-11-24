FROM ubuntu:26.04
ENV DEBIAN_FRONTEND=noninteractive CARGO_HTTP_MULTIPLEXING=false CARGO_NET_RETRY=10
RUN dpkg-divert --quiet --local --rename --add /usr/bin/sync && ln -sf /bin/true /usr/bin/sync && apt-get update && apt-get upgrade -y && apt-get -qq install -y apt-utils moreutils > /dev/null && apt-get clean
RUN chronic apt-get -qq install -y 9base afnix algol68g aspectc++ aspectj asymptote ats2-lang bash bc bison brotli bsh ca-certificates cc65 clang clips clisp clojure cmake coffeescript && chronic apt-get clean
RUN chronic apt-get -qq install -y crystal curl dc default-jdk-headless dhall dotnet-sdk-10.0 elixir elvish emacs-nox erlang erlang-nox execline fennel fish flex fp-compiler g++ gambas3-gb-pcre gambas3-scripter gap && chronic apt-get clean
RUN chronic apt-get -qq install -y gawk gcc gcc-aarch64-linux-gnu gcc-riscv64-linux-gnu gdb gdc generator-scripting-language genius gforth gfortran ghc ghdl ghostscript git gm2 gnat gnucobol4 gnuplot gobjc golang && chronic apt-get clean
RUN chronic apt-get -qq install -y gpt gri groovy guile-3.0 gzip hare haxe hy icont iconx intercal iverilog jasmin-sable jq kotlin ksh libevent-dev libfl-dev libgd-dev libpng-dev && chronic apt-get clean
RUN chronic apt-get -qq install -y libpolyml-dev livescript llvm lua5.3 m4 macaulay2 make maxima minizinc mono-devel nasm neko newlisp nickle nim node-typescript nodejs ocaml octave openjdk-25-jdk && chronic apt-get clean
RUN chronic apt-get -qq install -y pari-gp parser3-cgi perl php-cli picolisp pike8.0 polyml python3 qbe qemu-user r-base racket rakudo ratfor rc regina-rexx rep ruby ruby-mustache rustc && chronic apt-get clean
RUN chronic apt-get -qq install -y scala scilab-cli sed singular slsh spin squirrel3 surgescript swi-prolog swiftlang tcl tcsh unzip valac vim wabt xa65 xsltproc yabasic yorick && chronic apt-get clean
RUN chronic apt-get -qq install -y z80asm zoem zsh && chronic apt-get clean
RUN chronic apt-get -qq install -y python3-pip golang-go cargo && chronic apt-get clean
RUN GOBIN=/usr/local/bin go install github.com/d5/tengo/v2/cmd/tengo@v2.17.0 && GOBIN=/usr/local/bin go install github.com/mattn/anko@v0.1.15
RUN cargo install --locked --root /usr/local rhai@1.27.0 --features bin-features --bin rhai-run && cargo install --locked --root /usr/local koto_cli@0.16.1
RUN ( chronic apt-get -qq install -y autoconf automake autoconf-archive libncurses-dev libgmp-dev libffi-dev libltdl-dev libreadline-dev zlib1g-dev gawk pkg-config unzip && chronic apt-get clean ) && \
    ( curl --retry 3 -fsSL -o /tmp/ucb.tgz https://github.com/jrincayc/ucblogo-code/archive/refs/tags/version_6.2.5.tar.gz && echo "668734c775d4f8eddb999094941572c55aaa1951b6936df2ba1f376427bedb3c  /tmp/ucb.tgz" | sha256sum -c && tar xzf /tmp/ucb.tgz -C /tmp && cd /tmp/ucblogo-code-version_6.2.5 && mkdir shim && echo '#include <termios.h>' > shim/termio.h && sed -i 's/struct termio /struct termios /; s/ioctl(0,TCGETA,(char \*)(&tty_cooked))/tcgetattr(0,\&tty_cooked)/; s/ioctl(0,TCSETA,(char \*)(&tty_cbreak))/tcsetattr(0,TCSANOW,\&tty_cbreak)/; s/ioctl(0,TCSETA,(char \*)(&tty_cooked))/tcsetattr(0,TCSANOW,\&tty_cooked)/' term.c && ! grep -q 'TCGETA\|TCSETA' term.c && chronic autoreconf -fi && chronic ./configure --disable-docs CFLAGS="-O2 -std=gnu17" CPPFLAGS="-I/tmp/ucblogo-code-version_6.2.5/shim" ac_cv_header_sgtty_h=no && chronic make -j8 && chronic make install && cd / && rm -rf /tmp/ucblogo-code-version_6.2.5 /tmp/ucb.tgz ) && \
    ( curl --retry 5 -fsSL -o /tmp/st.tgz https://mirrors.kernel.org/gnu/smalltalk/smalltalk-3.2.5.tar.gz && echo "06e574e818ec49f0555d948ae53b1453d8c1df59ef597dad911a4fd1ffba1cce  /tmp/st.tgz" | sha256sum -c && tar xzf /tmp/st.tgz -C /tmp && cd /tmp/smalltalk-3.2.5 && chronic ./configure --disable-generational-gc --without-emacs --without-tk --without-x CFLAGS="-O2 -std=gnu11 -fcommon -Wno-error -Wno-implicit-function-declaration -Wno-incompatible-pointer-types -Wno-int-conversion" && chronic make -j8 && chronic make install && cd / && rm -rf /tmp/smalltalk-3.2.5 /tmp/st.tgz ) && \
    ( curl --retry 3 -fsSL https://julialang-s3.julialang.org/bin/linux/x64/1.13/julia-1.13.4-linux-x86_64.tar.gz | tar xz -C /opt && ln -s /opt/julia-1.13.4/bin/julia /usr/local/bin/julia ) && \
    ( curl --retry 3 -fsSL -o /tmp/dafny.zip https://github.com/dafny-lang/dafny/releases/download/v4.11.0/dafny-4.11.0-x64-ubuntu-22.04.zip && echo "a46a9ff7cdd720f7955854c78e95df13f4cfe6b80691b05f8654fe19e8267179  /tmp/dafny.zip" | sha256sum -c && unzip -q /tmp/dafny.zip -d /opt && rm /tmp/dafny.zip && printf '#!/bin/sh\nexec /opt/dafny/dafny "$@"\n' > /usr/local/bin/dafny && chmod +x /usr/local/bin/dafny ) && \
    ( cd /tmp && echo 'method Main(){print "ok";}' > w.dfy && dafny build -o w/w w.dfy && DOTNET_ROLL_FORWARD=Major dotnet w/w.dll && rm -rf /tmp/w /tmp/w.dfy )
RUN ( cd /tmp && U=http://archive.ubuntu.com/ubuntu/pool/universe && curl -fsSO $U/a/aplus-fsf/aplus-fsf_4.22.1-12_amd64.deb && curl -fsSO "$U/l/lisaac/lisaac_0.39~rc1-3.1_amd64.deb" && curl -fsSO "$U/l/lisaac/lisaac-common_0.39~rc1-3.1_all.deb" && apt-get update -qq && apt-get install -y -qq ./aplus-fsf_*.deb ./lisaac_*.deb ./lisaac-common_*.deb libcurl3t64-gnutls libexpat1 && apt-get clean && rm -f /tmp/*.deb ) && \
    ( mkdir -p /opt/falcon && cd /tmp && U=http://archive.ubuntu.com/ubuntu/pool && curl -fsSO $U/universe/f/falconpl/falconpl_0.9.6.9-git20120606-2_amd64.deb && curl -fsSO $U/universe/f/falconpl/libfalcon-engine1_0.9.6.9-git20120606-2_amd64.deb && curl -fsSO $U/main/o/openssl/libssl1.0.0_1.0.1f-1ubuntu2_amd64.deb && curl -fsSO $U/main/p/pcre3/libpcre3_8.31-2ubuntu2_amd64.deb && for d in *.deb; do dpkg -x $d /opt/falcon; done && rm -f /tmp/*.deb && printf '#!/bin/sh\nLD_LIBRARY_PATH=/opt/falcon/usr/lib:/opt/falcon/lib/x86_64-linux-gnu exec /opt/falcon/usr/bin/falcon "$@"\n' > /usr/local/bin/falcon && chmod +x /usr/local/bin/falcon ) && \
    ( mkdir -p /opt/boo && cd /tmp && U=http://archive.ubuntu.com/ubuntu/pool/universe/b/boo && curl -fsSO "$U/boo_0.9.5~git20110729.r1.202a430-2_all.deb" && curl -fsSO "$U/libboo2.0.9-cil_0.9.5~git20110729.r1.202a430-2_all.deb" && for d in *.deb; do dpkg -x $d /opt/boo; done && rm -f /tmp/*.deb && cp /opt/boo/usr/lib/cli/*/*.dll /opt/boo/usr/lib/boo/ && printf '#!/bin/sh\nexec mono /opt/boo/usr/lib/boo/booi.exe "$@"\n' > /usr/local/bin/booi && chmod +x /usr/local/bin/booi ) && \
    ( mkdir -p /opt/ecere && cd /tmp && U=http://archive.ubuntu.com/ubuntu/pool/universe/e/ecere-sdk && for p in ecere-dev libecc0 libecerecom0 libecere0; do curl -fsSO $U/${p}_0.44.15-1build3_amd64.deb; done && for d in *.deb; do dpkg -x $d /opt/ecere; done && rm -f /tmp/*.deb && for t in ecp ecc ecs; do printf '#!/bin/sh\nLD_LIBRARY_PATH=/opt/ecere/usr/lib/x86_64-linux-gnu:/opt/ecere/usr/lib/x86_64-linux-gnu/ec exec /opt/ecere/usr/bin/%s "$@"\n' $t > /usr/local/bin/$t && chmod +x /usr/local/bin/$t; done && ln -s /opt/ecere/usr/lib/x86_64-linux-gnu/libecereCOM.so /usr/local/lib/libecereCOM.so && echo /opt/ecere/usr/lib/x86_64-linux-gnu > /etc/ld.so.conf.d/ecere.conf && ldconfig ) && \
    ( mkdir -p /opt/cduce && cd /tmp && U=http://archive.ubuntu.com/ubuntu/pool && curl -fsSO $U/universe/c/cduce/cduce_0.6.0-5_amd64.deb && curl -fsSO $U/main/p/pcre3/libpcre3_8.31-2ubuntu2_amd64.deb && for d in *.deb; do dpkg -x $d /opt/cduce; done && rm -f /tmp/*.deb && printf '#!/bin/sh\nLD_LIBRARY_PATH=/opt/cduce/lib/x86_64-linux-gnu exec /opt/cduce/usr/bin/cduce "$@"\n' > /usr/local/bin/cduce && chmod +x /usr/local/bin/cduce )
RUN ( apt-get update -qq && apt-get -qq install -y git curl autoconf automake bison flex libx11-dev libncurses-dev && apt-get clean ) && \
    ( git clone -q --depth 1 -b RELEASE_8_1_0 https://github.com/parrot/parrot.git /opt/parrot-src && cd /opt/parrot-src && perl Configure.pl --prefix=/opt/parrot --optimize && (make -j"$(nproc)" || make) && make install && ln -s /opt/parrot/bin/parrot /usr/local/bin/parrot ) && \
    ( git clone -q --depth 1 -b Seed7_release_2026-07-11 https://github.com/ThomasMertes/seed7.git /opt/seed7 && cd /opt/seed7/src && make -f mk_linux.mak depend && make -f mk_linux.mak -j"$(nproc)" && make -f mk_linux.mak install ) && \
    ( apt-get -qq install -y gperf gcc-14 && apt-get clean && git clone -q --depth 1 -b v1.4.0 https://github.com/tinyos/nesc.git /opt/nesc && cd /opt/nesc && ./Bootstrap && ./configure CFLAGS='-O2 -std=gnu17 -Wno-error=incompatible-pointer-types -Wno-error=int-conversion -Wno-error=implicit-function-declaration' && make && make install )
RUN ( chronic apt-get -qq install -y unzip ant && chronic apt-get clean ) && \
    ( curl -fsSL -o /tmp/fan.zip https://github.com/fantom-lang/fantom/releases/download/v1.0.84/fantom-1.0.84.zip && unzip -q /tmp/fan.zip -d /opt && rm /tmp/fan.zip && chmod +x /opt/fantom-1.0.84/bin/* && printf '#!/bin/sh\nexec /opt/fantom-1.0.84/bin/fan "$@"\n' > /usr/local/bin/fan && chmod +x /usr/local/bin/fan ) && \
    ( curl -fsSL -o /tmp/golo.zip https://github.com/eclipse-archived/golo-lang/releases/download/release/3.4.0/golo-3.4.0.zip && unzip -q /tmp/golo.zip -d /opt && rm /tmp/golo.zip && chmod +x /opt/golo-3.4.0/bin/* && printf '#!/bin/sh\nexec /opt/golo-3.4.0/bin/golo "$@"\n' > /usr/local/bin/golo && chmod +x /usr/local/bin/golo ) && \
    ( curl -fsSL -o /tmp/yeti.tgz https://github.com/mth/yeti/archive/45f939babffacf73f6c3980867f6ca94e14b093f.tar.gz && tar xzf /tmp/yeti.tgz -C /opt && mv /opt/yeti-45f939babffacf73f6c3980867f6ca94e14b093f /opt/yeti && rm /tmp/yeti.tgz && cd /opt/yeti && ant -q jar && printf '#!/bin/sh\nexec java -jar /opt/yeti/yeti.jar "$@"\n' > /usr/local/bin/yeti && chmod +x /usr/local/bin/yeti ) && \
    ( curl -fsSL -o /tmp/bal.deb https://github.com/ballerina-platform/ballerina-distribution/releases/download/v2201.14.1/ballerina-2201.14.1-swan-lake-linux-x64.deb && dpkg -i /tmp/bal.deb && rm /tmp/bal.deb && bal pull ballerina/io:1.8.3 ) && \
    ( curl -fsSL -o /tmp/gosu.zip https://repo1.maven.org/maven2/org/gosu-lang/gosu/gosu/1.18.14/gosu-1.18.14-full.zip && unzip -q /tmp/gosu.zip -d /opt && rm /tmp/gosu.zip && chmod +x /opt/gosu-1.18.14/bin/* && printf '#!/bin/sh\nexec /opt/gosu-1.18.14/bin/gosu "$@"\n' > /usr/local/bin/gosu && chmod +x /usr/local/bin/gosu ) && \
    ( curl -fsSL -o /usr/local/lib/frege.jar https://github.com/Frege/frege/releases/download/3.25alpha/frege3.25.84.jar && printf '#!/bin/sh\nexec java -Xss32m -jar /usr/local/lib/frege.jar "$@"\n' > /usr/local/bin/frege && chmod +x /usr/local/bin/frege )
RUN ( chronic apt-get -qq install -y npm && chronic apt-get clean ) && \
    ( npm install --prefix /opt/b05 --no-fund --no-audit rescript@12.3.1 purescript@0.15.17 pyret-npm@0.1.29 && for b in bsc purs; do ln -s /opt/b05/node_modules/.bin/$b /usr/local/bin/$b; done ) && \
    ( for p in prelude:v6.0.2 effect:v4.0.0 console:v6.1.0; do mkdir -p /opt/purs/lib/${p%%:*} && curl -fsSL https://github.com/purescript/purescript-${p%%:*}/archive/refs/tags/${p#*:}.tar.gz | tar -xz --strip-components=1 -C /opt/purs/lib/${p%%:*} || exit 1; done ) && \
    ( printf '#!/bin/sh\n# pyretc IN.arr OUT.jarr: compile one Pyret program to a standalone node file\n# (the same compiler call the pyret CLI makes, without its background compile server)\nI=$(realpath "$1"); O=$(realpath -m "$2")\ncd %s && exec node --max-old-space-size=8192 --stack-size=8192 build/phaseA/pyret.jarr --build-runnable "$I" --outfile "$O" --builtin-js-dir src/js/trove/ --builtin-arr-dir src/arr/trove --require-config src/scripts/standalone-configA.json --standalone-file src/js/base/handalone.js --compiled-dir /opt/pyret-compiled -no-check-mode < /dev/null\n' /opt/b05/node_modules/pyret-npm/pyret-lang > /usr/local/bin/pyretc && chmod +x /usr/local/bin/pyretc && printf 'print("ok")' > /tmp/w.arr && pyretc /tmp/w.arr /tmp/w.jarr && NODE_PATH=/opt/b05/node_modules node /tmp/w.jarr && rm -f /tmp/w.arr /tmp/w.jarr && chmod -R a+rwX /opt/pyret-compiled )
RUN ( mkdir -p /opt/pwsh && curl -fsSL https://github.com/PowerShell/PowerShell/releases/download/v7.4.6/powershell-7.4.6-linux-x64.tar.gz | tar -xz -C /opt/pwsh && chmod +x /opt/pwsh/pwsh && ln -sf /opt/pwsh/pwsh /usr/local/bin/pwsh ) && \
    ( mkdir -p /opt/nu && curl -fsSL https://github.com/nushell/nushell/releases/download/0.101.0/nu-0.101.0-x86_64-unknown-linux-gnu.tar.gz | tar -xz -C /opt/nu --strip-components=1 && ln -sf /opt/nu/nu /usr/local/bin/nu ) && \
    ( cargo install --git https://github.com/redox-os/ion.git --rev e9b3ca48b7ab6444498d5c3aa902d471ce29f759 ion-shell --root /usr/local ) && \
    ( mkdir -p /tmp/oils && curl -fsSL https://www.oilshell.org/download/oils-for-unix-0.24.0.tar.gz | tar -xz -C /tmp/oils --strip-components=1 && (cd /tmp/oils && ./configure && _build/oils.sh && ./install) && rm -rf /tmp/oils ) && \
    ( git clone --branch v7.4.2002 --depth 1 https://github.com/lmorg/murex.git /tmp/murex && (cd /tmp/murex && go build -o /usr/local/bin/murex .) && rm -rf /tmp/murex )
RUN ( curl -fsSL https://ziglang.org/download/0.13.0/zig-linux-x86_64-0.13.0.tar.xz | tar -xJ -C /opt && ln -sf /opt/zig-linux-x86_64-0.13.0/zig /usr/local/bin/zig ) && \
    ( mkdir -p /usr/local/lib/odin && curl -fsSL https://github.com/odin-lang/Odin/releases/download/dev-2026-10/odin-linux-amd64-dev-2026-10.tar.gz | tar -xz -C /usr/local/lib/odin --strip-components=1 && ln -sf /usr/local/lib/odin/odin /usr/local/bin/odin ) && \
    ( curl -fsSL https://github.com/vlang/v/releases/download/0.4.12/v_linux.zip -o /tmp/v_linux.zip && unzip -q /tmp/v_linux.zip -d /opt && ln -sf /opt/v/v /usr/local/bin/v && rm -f /tmp/v_linux.zip ) && \
    ( curl -fsSL https://github.com/c3lang/c3c/releases/download/v0.7.0/c3-linux.tar.gz | tar -xz -C /opt && ln -sf /opt/c3/c3c /usr/local/bin/c3c && ln -sf /usr/lib/x86_64-linux-gnu/libxml2.so.16 /usr/lib/x86_64-linux-gnu/libxml2.so.2 ) && \
    ( mkdir -p /tmp/nelua && curl -fsSL https://github.com/edubart/nelua-lang/archive/9840cc8e.tar.gz | tar -xz -C /tmp/nelua --strip-components=1 && make -C /tmp/nelua install PREFIX=/usr/local && rm -rf /tmp/nelua )
RUN ( curl -fsSL -o /tmp/gleam.tgz https://github.com/gleam-lang/gleam/releases/download/v1.19.2/gleam-v1.19.2-x86_64-unknown-linux-musl.tar.gz && \
    echo "2ba2afb66ca9f6dcc01a4a6e9169b6942963bad6483bec9571ddc078cfe6f41f  /tmp/gleam.tgz" | sha256sum -c && \
    tar -xzf /tmp/gleam.tgz -C /usr/local/bin gleam && rm -f /tmp/gleam.tgz && \
    gleam --version; erl -noshell -eval 'io:format("~s~n",[erlang:system_info(otp_release)]),halt().' ) && \
    ( curl -fsSL -o /tmp/roc.tgz https://github.com/roc-lang/roc/releases/download/0.0.0-alpha1/roc-linux_x86_64-0-alpha1.tar.gz && \
    echo "81a7a74aba79b5633da87490aed01d040c69459d2fc2d7e9b638df417d980adf  /tmp/roc.tgz" | sha256sum -c && \
    mkdir -p /opt/roc /opt/roc/basic-cli && tar -xzf /tmp/roc.tgz -C /opt/roc --strip-components=1 && rm -f /tmp/roc.tgz && \
    ln -sf /opt/roc/roc /usr/local/bin/roc && \
    curl -fsSL -o /tmp/bcli.tar.br https://github.com/roc-lang/basic-cli/releases/download/0.18.0/0APbwVN1_p1mJ96tXjaoiUCr8NBGamr8G8Ac_DrXR-o.tar.br && \
    echo "fd9a76574953e6eb60cf25a9a0a75239f0041a48602395d6bb65a2ffd4a85651  /tmp/bcli.tar.br" | sha256sum -c && \
    brotli -dc /tmp/bcli.tar.br | tar -x -C /opt/roc/basic-cli && rm -f /tmp/bcli.tar.br && \
    roc version ) && \
    ( apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y -qq llvm-18-dev libpolly-18-dev libzstd-dev zlib1g-dev && \
    apt-get clean && \
    curl -fsSL -o /tmp/inko.tgz https://github.com/inko-lang/inko/archive/refs/tags/v0.21.1.tar.gz && \
    echo "6d73f93a7331ef9111d7bf8a3665059ccda25a33a6f2bd723a7aa2ab83b22259  /tmp/inko.tgz" | sha256sum -c && \
    tar -xzf /tmp/inko.tgz -C /tmp && rm -f /tmp/inko.tgz && \
    cd /tmp/inko-0.21.1 && LLVM_SYS_181_PREFIX=/usr/lib/llvm-18 make build PREFIX=/usr/local && make install PREFIX=/usr/local && \
    cd / && rm -rf /tmp/inko-0.21.1 && \
    inko --version ) && \
    ( curl -fsSL -o /tmp/koka.tgz https://github.com/koka-lang/koka/releases/download/v3.2.9/koka-v3.2.9-linux-x64.tar.gz && \
    echo "310459831a7c6fa6a0cd8e0e02d6b5b3b36441d5e7ce24168bda016cd2e95eee  /tmp/koka.tgz" | sha256sum -c && \
    mkdir -p /opt/koka && tar -xzf /tmp/koka.tgz -C /opt/koka && rm -f /tmp/koka.tgz && \
    ln -sf /opt/koka/bin/koka /usr/local/bin/koka && \
    koka --version ) && \
    ( apt-get update -qq && \
    curl -fsSL -o /tmp/chapel.deb https://github.com/chapel-lang/chapel/releases/download/2.10.0/chapel-2.10.0-1.ubuntu26.amd64.deb && \
    echo "9af4153bea3cd225f5f3e90ddc215e15fcf1c7fa8ce2246108415b6da1c27d11  /tmp/chapel.deb" | sha256sum -c && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y -qq /tmp/chapel.deb && apt-get clean && rm -f /tmp/chapel.deb && \
    chpl --version ) && \
    ( curl -fsSL -o /tmp/ponyc.tgz https://github.com/ponylang/ponyc/releases/download/0.78.2/ponyc-x86-64-unknown-linux-ubuntu26.04.tar.gz && \
    echo "69f9dae95da5eb4a1abe411f011a18e819f677cd33f10bbd8e44f36fd46f5103  /tmp/ponyc.tgz" | sha256sum -c && \
    mkdir -p /opt/ponyc && tar -xzf /tmp/ponyc.tgz -C /opt/ponyc --strip-components=1 && rm -f /tmp/ponyc.tgz && \
    ln -sf /opt/ponyc/bin/ponyc /usr/local/bin/ponyc && \
    ponyc --version )
RUN ( cd /opt && curl -fsSL -o lean.zip https://github.com/leanprover/lean4/releases/download/v4.35.0/lean-4.35.0-linux.zip && unzip -q lean.zip && rm -f lean.zip && ln -s /opt/lean-4.35.0-linux/bin/lean /usr/local/bin/lean && lean --version ) && \
    ( apt-get update -qq && apt-get install -y -qq chezscheme libgmp-dev > /dev/null && apt-get clean && git clone -q --depth 1 -b v0.8.0 https://github.com/idris-lang/Idris2 /tmp/idris2src && cd /tmp/idris2src && make bootstrap SCHEME=chezscheme PREFIX=/opt/idris2 > /tmp/idris2-build.log 2>&1 && make install PREFIX=/opt/idris2 >> /tmp/idris2-build.log 2>&1 && ln -s /opt/idris2/bin/idris2 /usr/local/bin/idris2 && cd / && rm -rf /tmp/idris2src /tmp/idris2-build.log && idris2 --version )
RUN ( cd /opt && curl -fsSL -o dart.zip https://storage.googleapis.com/dart-archive/channels/stable/release/3.14.0/sdk/dartsdk-linux-x64-release.zip && unzip -q dart.zip && rm -f dart.zip && ln -s /opt/dart-sdk/bin/dart /usr/local/bin/dart && dart --version ) && \
    ( cd /opt && curl -fsSL https://picat-lang.org/download/picat39_12_linux64.tar.gz | tar -xz && ln -s /opt/Picat/picat /usr/local/bin/picat && picat --version ) && \
    ( echo "deb [trusted=yes] https://dl.mercurylang.org/deb/ trixie main" > /etc/apt/sources.list.d/mercury.list && apt-get update -qq && DEBIAN_FRONTEND=noninteractive apt-get install -y -qq mercury-recommended=22.01.8-1~trixie > /dev/null && rm -f /etc/apt/sources.list.d/mercury.list && apt-get clean && mmc --version | head -1 )
RUN ( cargo install uiua --version 0.19.1 --locked --root /opt/uiua > /tmp/uiua-build.log 2>&1 && rm -f /tmp/uiua-build.log && ln -s /opt/uiua/bin/uiua /usr/local/bin/uiua && uiua --version ) && \
    ( git clone -q --depth 1 -b v0.9.0 https://github.com/dzaima/CBQN /opt/cbqn && make -C /opt/cbqn CC=/usr/bin/clang > /tmp/cbqn-build.log 2>&1 && rm -f /tmp/cbqn-build.log && ln -s /opt/cbqn/BQN /usr/local/bin/bqn && bqn -p 1+1 ) && \
    ( curl -fsSL -o /tmp/j97.tgz https://www.jsoftware.com/download/j9.7/install/j9.7_linux64.tar.gz && echo "1c0cf450b45f563d7408a6c93563006782da8b422e0769781eb8731c465ffd06  /tmp/j97.tgz" | sha256sum -c && tar -xzf /tmp/j97.tgz -C /opt && rm -f /tmp/j97.tgz && ln -s /opt/j9.7/bin/jconsole /usr/local/bin/ijconsole )
COPY vendor/ngnk-b9eeb91e.tar.gz /tmp/ngnk.tgz
RUN ( echo "3e0072b2a61e1247b58f424c1b818f94618aea87f5dc4bdbe94cbae766e9f7ac  /tmp/ngnk.tgz" | sha256sum -c && ( (git clone -q https://codeberg.org/ngn/k /opt/ngnk && cd /opt/ngnk && git checkout -q b9eeb91e0343ef6029f59d55dd98f82667b9bd59) || (rm -rf /opt/ngnk && mkdir -p /opt/ngnk && tar -xzf /tmp/ngnk.tgz -C /opt/ngnk) ) && rm -f /tmp/ngnk.tgz && make -C /opt/ngnk a N=k R=k O=-O3 L='-lm -ldl' CC=/usr/bin/clang > /tmp/ngnk-build.log 2>&1 && rm -f /tmp/ngnk-build.log && ln -s /opt/ngnk/k /usr/local/bin/ngnk ) && \
    ( curl -fsSL -o /tmp/klong.tgz https://t3x.org/klong/klong20221212.tgz && echo "5e1a4877228a3c643a99dbfd2d73e60bc3fa856e2615ac2fe78c80370e7f96b4  /tmp/klong.tgz" | sha256sum -c && mkdir -p /opt/klong && tar -xzf /tmp/klong.tgz -C /opt/klong --strip-components=1 && rm -f /tmp/klong.tgz && make -C /opt/klong > /tmp/klong-build.log 2>&1 && rm -f /tmp/klong-build.log && ln -s /opt/klong/kg /usr/local/bin/kg ) && \
    ( git clone -q https://github.com/niallang/Nial_Development /opt/nial && cd /opt/nial && git checkout -q cdd6e8158814e96d063b921715de91e038191ead && CMAKE_POLICY_VERSION_MINIMUM=3.5 CFLAGS=-std=gnu17 make nialcore > /tmp/nial-build.log 2>&1 && rm -f /tmp/nial-build.log && ln -s /opt/nial/nialcore /usr/local/bin/nial )
RUN ( pip install --break-system-packages -q mathics3==10.0.1 && mathics --version | head -1 ) && \
    ( cargo install numbat-cli --version 1.24.0 --locked --root /opt/numbat > /tmp/numbat-build.log 2>&1 && rm -f /tmp/numbat-build.log && ln -s /opt/numbat/bin/numbat /usr/local/bin/numbat && numbat --version )
RUN ( cd /opt && git clone -q --depth 1 -b v1.43.0 https://github.com/janet-lang/janet && make -C janet -j4 > /tmp/janet.log 2>&1 && rm -f /tmp/janet.log && ln -s /opt/janet/build/janet /usr/local/bin/janet && echo '(prin "janet ok")' > /tmp/t.janet && janet /tmp/t.janet && rm -f /tmp/t.janet ) && \
    ( cd /opt && git clone -q --depth 1 -b v1.1.0 https://github.com/berry-lang/berry && make -C berry -j4 > /tmp/berry.log 2>&1 && rm -f /tmp/berry.log && ln -s /opt/berry/berry /usr/local/bin/berry && echo 'print("berry ok")' > /tmp/t.be && berry /tmp/t.be && rm -f /tmp/t.be ) && \
    ( cd /opt && git clone -q --depth 1 -b 0.9.9 https://github.com/marcobambini/gravity && make -C gravity -j4 > /tmp/gravity.log 2>&1 && rm -f /tmp/gravity.log && ln -s /opt/gravity/gravity /usr/local/bin/gravity && echo 'func main(){System.print("gravity ok")}' > /tmp/t.gravity && gravity -q /tmp/t.gravity && rm -f /tmp/t.gravity ) && \
    ( cd /opt && git clone -q --depth 1 -b v1.5.7 https://github.com/vtereshkov/umka-lang && make -C umka-lang -j4 > /tmp/umka.log 2>&1 && rm -f /tmp/umka.log && ln -s /opt/umka-lang/build/umka /usr/local/bin/umka && echo 'fn main(){printf("umka ok")}' > /tmp/t.um && umka /tmp/t.um && rm -f /tmp/t.um ) && \
    ( cd /opt && git clone -q --depth 1 -b 0.4.0 https://github.com/wren-lang/wren-cli && sed -i 's/static void write(/static void cliWrite(/; s/= write;/= cliWrite;/' wren-cli/src/cli/vm.c && make -C wren-cli/projects/make -j4 > /tmp/wren.log 2>&1 && rm -f /tmp/wren.log && ln -s /opt/wren-cli/bin/wren_cli /usr/local/bin/wren_cli && echo 'System.print("wren ok")' > /tmp/t.wren && wren_cli /tmp/t.wren && rm -f /tmp/t.wren ) && \
    ( cd /opt && git clone -q --depth 1 -b 2019.05.22-alpha --recurse-submodules --shallow-submodules https://github.com/IoLanguage/io && sed -i 's|^# include <sys/sysctl.h>|/* sys/sysctl.h dropped */|' io/libs/iovm/source/IoSystem.c && mkdir io/build && cd io/build && (cmake .. -DCMAKE_BUILD_TYPE=Release -DCMAKE_POLICY_VERSION_MINIMUM=3.5 '-DCMAKE_C_FLAGS=-std=gnu11 -Wno-error=implicit-function-declaration -Wno-error=incompatible-pointer-types -Wno-error=int-conversion' > /tmp/io.log 2>&1 && make -j4 io_static >> /tmp/io.log 2>&1 || (grep -n -i -m20 -B2 'error' /tmp/io.log; tail -15 /tmp/io.log; exit 1)) && cp _build/binaries/io_static /usr/local/bin/io && rm -f /tmp/io.log && echo '"io ok" println' > /tmp/t.io && io /tmp/t.io && rm -f /tmp/t.io )
RUN ( cd /opt && curl -fsSL --retry 6 --retry-delay 10 --retry-all-errors https://www.kylheku.com/cgit/txr/snapshot/txr-302.tar.bz2 | tar -xj && cd txr-302 && ./configure > /tmp/txr.log 2>&1 && make -j4 >> /tmp/txr.log 2>&1 && make install >> /tmp/txr.log 2>&1 && rm -f /tmp/txr.log && echo '(put-string "txr ok")' > /tmp/t.tl && txr /tmp/t.tl && rm -f /tmp/t.tl ) && \
    ( mkdir -p /opt/arturo && cd /opt/arturo && curl -fsSL --retry 6 --retry-delay 10 --retry-all-errors https://github.com/arturo-lang/arturo/releases/download/v0.10.0/arturo-0.10.0-linux-amd64-mini.zip -o a.zip && unzip -q a.zip && rm -f a.zip && ln -s /opt/arturo/arturo /usr/local/bin/arturo && echo 'prints {:arturo ok:}' > /tmp/t.art && arturo /tmp/t.art && rm -f /tmp/t.art ) && \
    ( cd /opt && git clone -q --depth 1 --filter=blob:none --sparse -b v1.27 https://github.com/ring-lang/ring && cd ring && git sparse-checkout set language > /dev/null && cd language/src && gcc -O2 $(ls *.c | grep -v ringw) -I ../include -lm -ldl -o /usr/local/bin/ring > /tmp/ring.log 2>&1 && rm -f /tmp/ring.log && echo 'see "ring ok"' > /tmp/t.ring && ring /tmp/t.ring && rm -f /tmp/t.ring )
RUN ( apt-get update -qq && apt-get install -y -qq --no-install-recommends \
    gcc libc6-dev libgc-dev m4 make git curl ca-certificates && apt-get clean \
    && curl --retry 5 --retry-all-errors -fsSL https://ftp.regressive.org/snobol/snobol4-2.3.3.tar.gz -o /tmp/sno.tgz \
    && echo "bfd53071d69283776f5b2764f7865d354b89d372569854a18878e59f57388ed2  /tmp/sno.tgz" | sha256sum -c \
    && mkdir -p /tmp/sno && tar -xzf /tmp/sno.tgz -C /tmp/sno --strip-components=1 \
    && cd /tmp/sno && CC="gcc -std=gnu17 -fcommon -Wno-implicit-int -Wno-implicit-function-declaration -Wno-return-type" ./configure --prefix=/usr/local \
    && make && make install && cd / && rm -rf /tmp/sno /tmp/sno.tgz \
    && (curl --retry 5 --retry-all-errors -fsSL https://mirrors.kernel.org/gnu/cim/cim-5.1.tar.gz -o /tmp/cim.tar.gz \
        || curl --retry 5 -fsSL http://ftpmirror.gnu.org/cim/cim-5.1.tar.gz -o /tmp/cim.tar.gz \
        || curl --retry 5 -fsSL https://ftp.gnu.org/gnu/cim/cim-5.1.tar.gz -o /tmp/cim.tar.gz) \
    && mkdir -p /tmp/cim && tar -xzf /tmp/cim.tar.gz -C /tmp/cim --strip-components=1 \
    && cd /tmp/cim && sed -i 's|\.\./\.\./lib/cim\.h|cim.h|g' lib/*.c \
    && ./configure --prefix=/usr/local CC="gcc -std=gnu89" CFLAGS="-O2 -fcommon -std=gnu89 -Wno-implicit-int -Wno-implicit-function-declaration -Wno-return-type" \
    && make && make install && ldconfig \
    && cd / && rm -rf /tmp/cim /tmp/cim.tar.gz \
    && (curl --retry 5 --retry-all-errors -fsSL https://miasap.se/obnc/downloads/obnc_0.17.2.tar.gz -o /tmp/obnc.tgz \
        || curl --retry 5 -fsSL http://miasap.se/obnc/downloads/obnc_0.17.2.tar.gz -o /tmp/obnc.tgz) \
    && mkdir -p /tmp/obnc && tar -xzf /tmp/obnc.tgz -C /tmp/obnc --strip-components=1 \
    && cd /tmp/obnc && sed -i 's/strlen("\\0")/1/g' src/*.c \
    && CC="gcc -std=gnu17 -U_FORTIFY_SOURCE -D_FORTIFY_SOURCE=0" CFLAGS="-O2 -U_FORTIFY_SOURCE -D_FORTIFY_SOURCE=0 -Wno-error" ./build --prefix=/usr/local && ./install && ldconfig \
    && cd / && rm -rf /tmp/obnc /tmp/obnc.tgz \
    && curl --retry 5 --retry-all-errors -fsSL https://github.com/OpenEuphoria/euphoria/releases/download/4.1.0/euphoria-4.1.0-Linux-x64-57179171dbed.tar.gz -o /tmp/euphoria.tar.gz \
    && tar -xzf /tmp/euphoria.tar.gz -C /opt \
    && ln -sf /opt/euphoria-4.1.0-Linux-x64/bin/eui /usr/local/bin/eui \
    && ln -sf /opt/euphoria-4.1.0-Linux-x64/bin/euc /usr/local/bin/euc \
    && rm -f /tmp/euphoria.tar.gz \
    && (curl --retry 5 --retry-all-errors -fsSL https://mirrors.kernel.org/gnu/marst/marst-2.8.tar.gz -o /tmp/marst.tgz \
        || curl --retry 5 -fsSL http://ftpmirror.gnu.org/marst/marst-2.8.tar.gz -o /tmp/marst.tgz \
        || curl --retry 5 -fsSL https://ftp.gnu.org/gnu/marst/marst-2.8.tar.gz -o /tmp/marst.tgz) \
    && mkdir -p /tmp/marst && tar -xzf /tmp/marst.tgz -C /tmp/marst --strip-components=1 \
    && cd /tmp/marst && sed -i 's/append(code, t_image);/append(code, "%s", t_image);/g' marst.c \
    && CC="gcc -std=gnu17" ./configure --prefix=/usr/local && make && make install && ldconfig \
    && cd / && rm -rf /tmp/marst /tmp/marst.tgz )
RUN ( apt-get update -qq && apt-get install -y -qq --no-install-recommends \
    erlang-nox erlang-dev default-jdk-headless python3 gcc libc6-dev libgc-dev make git curl ca-certificates && apt-get clean \
    && curl --retry 5 --retry-all-errors -fsSL https://downloads.factorcode.org/releases/0.100/factor-linux-x86-64-0.100.tar.gz -o /tmp/factor.tar.gz \
    && tar -xzf /tmp/factor.tar.gz -C /opt \
    && ln -sf /opt/factor/factor /usr/local/bin/factor-vm \
    && rm -f /tmp/factor.tar.gz \
    && git clone -q --branch 2.1.4 --depth 1 https://github.com/lfe/lfe.git /opt/lfe \
    && make -C /opt/lfe compile \
    && ln -sf /opt/lfe/bin/lfe /usr/local/bin/lfe \
    && ln -sf /opt/lfe/bin/lfec /usr/local/bin/lfec \
    && ln -sf /opt/lfe/bin/lfescript /usr/local/bin/lfescript \
    && curl --retry 5 --retry-all-errors -fsSL https://lhartikk.github.io/ArnoldC.jar -o /opt/ArnoldC.jar \
    && echo "c26b0342d352e69838bc7dab67305484edaca702002cf793f61f817d9dc1c31d  /opt/ArnoldC.jar" | sha256sum -c \
    && curl --retry 5 --retry-all-errors -fsSL -o /tmp/pyth.tgz https://github.com/isaacg1/pyth/archive/97cdf30d749d2a0d6ec1bb4b9bc417c34cce05bb.tar.gz \
    && echo "2cd8aebaa1549b10f5139f8115036c03ee271cdf760cfe4f0e67b963f2309093  /tmp/pyth.tgz" | sha256sum -c \
    && mkdir -p /opt/pyth && tar -xzf /tmp/pyth.tgz -C /opt/pyth --strip-components=1 && rm -f /tmp/pyth.tgz )
RUN ( curl --retry 5 -fsSL -o /tmp/mmix.tgz https://github.com/theartofcomputerprogramming/mmixware/archive/8a5ce829ebea15f6910bd31b83f601f71cc08a0f.tar.gz && \
    echo "a9282ae0926bdf2eb250830f51b4f0175ab7da38936ff3bfbbc89b7d58b1ac31  /tmp/mmix.tgz" | sha256sum -c && \
    mkdir -p /opt/mmixware && tar -xzf /tmp/mmix.tgz -C /opt/mmixware --strip-components=1 && rm -f /tmp/mmix.tgz && \
    make -C /opt/mmixware CFLAGS="-O2 -std=gnu89 -Wno-implicit-int -Wno-implicit-function-declaration -Wno-return-type" mmixal mmix && \
    install -m 755 /opt/mmixware/mmixal /opt/mmixware/mmix /usr/local/bin/ && rm -rf /opt/mmixware && \
    printf ' LOC #100\nMain GETA $255,S\n TRAP 0,Fputs,StdOut\n TRAP 0,Halt,0\nS BYTE "ok",0\n' > /tmp/t.mms && mmixal -o /tmp/t.mmo /tmp/t.mms && test "$(mmix /tmp/t.mmo)" = "ok" && rm -f /tmp/t.mms /tmp/t.mmo ) && \
    ( curl --retry 5 -fsSL -o /tmp/uxn.tgz https://github.com/kivutar/uxn/archive/9e483ae8b129029152a2b3e1ebb6762078378e65.tar.gz && \
    echo "3bcb2b27bbe90c0f503644a73153c1cb9bb9a448652e1c890cf0ade002489082  /tmp/uxn.tgz" | sha256sum -c && \
    mkdir -p /opt/uxn && tar -xzf /tmp/uxn.tgz -C /opt/uxn --strip-components=1 && rm -f /tmp/uxn.tgz && \
    gcc -O2 -Wno-error /opt/uxn/src/uxnasm.c -o /usr/local/bin/uxnasm && \
    gcc -O2 -Wno-error /opt/uxn/src/uxn.c /opt/uxn/src/uxncli.c -o /usr/local/bin/uxncli && \
    rm -rf /opt/uxn && \
    printf '|0100 #6f #18 DEO #6b #18 DEO #800f DEO BRK\n' > /tmp/t.tal && uxnasm /tmp/t.tal /tmp/t.rom >/dev/null && test "$(uxncli /tmp/t.rom)" = "ok" && rm -f /tmp/t.tal /tmp/t.rom ) && \
    ( curl --retry 5 -fsSL -o /tmp/tnylpo.tgz https://gitlab.com/gbrein/tnylpo/-/archive/1.2.2/tnylpo-1.2.2.tar.gz && \
    echo "151ee9cc130b7d22ec242165301eeb1cb15c698cd30742467e352f4f0070e5a8  /tmp/tnylpo.tgz" | sha256sum -c && \
    mkdir -p /tmp/tnylpo && tar -xzf /tmp/tnylpo.tgz -C /tmp/tnylpo --strip-components=1 && \
    (cd /tmp/tnylpo && sh build.sh && install -m 755 tnylpo /usr/local/bin/tnylpo) && \
    rm -rf /tmp/tnylpo /tmp/tnylpo.tgz )
RUN ( mkdir -p /opt/hexagony && curl --retry 5 -fsSL https://github.com/m-ender/hexagony/archive/b674f59a0c9e10c1867bd9cf34f676ba89f0fc1c.tar.gz | tar -xz -C /opt/hexagony --strip-components=1 && printf 'o;k;@' > /tmp/t.hxg && test "$(ruby /opt/hexagony/interpreter.rb /tmp/t.hxg)" = "ok" && rm -f /tmp/t.hxg ) && \
    ( mkdir -p /opt/cjam && \
    curl --retry 5 -fsSL -o /opt/cjam/cjam-0.6.5.jar https://downloads.sourceforge.net/project/cjam/cjam-0.6.5/cjam-0.6.5.jar && \
    echo "e7444a9ac3cab491053df2bd625217906ba07ab091ace9aa52e54f700db9e3a7  /opt/cjam/cjam-0.6.5.jar" | sha256sum -c && \
    printf '"ok"' > /tmp/t.cjam && test "$(java -jar /opt/cjam/cjam-0.6.5.jar /tmp/t.cjam)" = "ok" && rm -f /tmp/t.cjam ) && \
    ( mkdir -p /opt/fish && \
    curl --retry 5 -fsSL -o /opt/fish/fish.py https://gist.githubusercontent.com/anonymous/6392418/raw/3b16018cb47f2f9ad1fa085c155cc5c0dc448b2d/fish.py && \
    echo "8d14253215c02acc8eacc8f2af7598edd7aa213bb6d3d7a5d8f4fedf023bcbe2  /opt/fish/fish.py" | sha256sum -c && \
    printf '"ko"oo;' > /tmp/t.fish && test "$(python3 /opt/fish/fish.py /tmp/t.fish)" = "ok" && rm -f /tmp/t.fish ) && \
    ( curl --retry 5 -fsSL -o /tmp/craneflak.tgz https://github.com/Flakheads/CraneFlak/archive/049f09ea980d9bd037a9f32d5ca6b00f88792328.tar.gz && \
    echo "b3aaed7b48b488a8898ead68ee1a2c71a183519bd3a2f91d9dab83930d593542  /tmp/craneflak.tgz" | sha256sum -c && \
    mkdir -p /tmp/craneflak && tar -xzf /tmp/craneflak.tgz -C /tmp/craneflak --strip-components=1 && \
    gcc -O3 -fcommon /tmp/craneflak/main.c /tmp/craneflak/stack.c /tmp/craneflak/interpreter.c -o /usr/local/bin/craneflak && \
    rm -rf /tmp/craneflak /tmp/craneflak.tgz && \
    printf '((((((()()()){}){}()){}){}()){}())((((((()()()){}){}()){}()){}()){}())' > /tmp/t.bflk && test "$(craneflak -A /tmp/t.bflk)" = "ok" && rm -f /tmp/t.bflk )
RUN ( mkdir -p /opt/taxi && curl --retry 5 -fsSL https://github.com/BigZaphod/Taxi/archive/61383585546668901e77287334ab454426e6f148.tar.gz | tar -xz -C /opt/taxi --strip-components=1 && g++ -O2 -std=gnu++14 -DNO_GREETINGS -include cstring -include cstdlib -include cstdint -include ctime -o /usr/local/bin/taxi /opt/taxi/source/taxi.cpp && rm -rf /opt/taxi && printf '%s\n' '"ok" is waiting at the Writer'\''s Depot.' 'Go to Writer'\''s Depot: west 1st left, 2nd right, 1st left, 2nd left.' 'Pickup a passenger going to the Post Office.' 'Go to the Post Office: north 1st right, 2nd right, 1st left.' 'Go to the Taxi Garage: north 1st right, 1st left, 1st right.' > /tmp/t.taxi && test "$(taxi /tmp/t.taxi)" = "ok" && rm -f /tmp/t.taxi ) && \
    ( mkdir -p /tmp/rail && curl --retry 5 -fsSL https://github.com/TryItOnline/rail/archive/04b7259fc19cceba2f06dfdc8431f683c81c80dd.tar.gz | tar -xz -C /tmp/rail --strip-components=1 && (cd /tmp/rail && bash compile.sh && install -m 755 /tmp/rail/rail /usr/local/bin/rail) && rm -rf /tmp/rail && printf "\$ 'main'\n \\\\\n  \\\\-[ok]o#\n" > /tmp/t.rail && test "$(rail /tmp/t.rail)" = "ok" && rm -f /tmp/t.rail ) && \
    ( curl --retry 5 -fsSL -o /tmp/cipple.c https://raw.githubusercontent.com/graue/esofiles/07dce2dbff3325ced047f080b4c9b9f433b3c72b/kipple/impl/cipple-0.2.1.c && gcc -O3 -w /tmp/cipple.c -o /usr/local/bin/cipple && rm -f /tmp/cipple.c && printf '107>o 111>o\n' > /tmp/t.kpl && test "$(cipple /tmp/t.kpl)" = "ok" && rm -f /tmp/t.kpl ) && \
    ( curl --retry 5 -fsSL -o /tmp/rock.tgz https://github.com/RockstarLang/rockstar/releases/download/v2.0.15/rockstar-v2.0.15-linux-x64.tar.gz && echo "cae38e48214f6512a593f8832e4905e11a4d2d218810a36641c1ac8f7eabfa74  /tmp/rock.tgz" | sha256sum -c && mkdir -p /tmp/rock && tar -xzf /tmp/rock.tgz -C /tmp/rock --strip-components=1 && install -m 755 /tmp/rock/rockstar /usr/local/bin/rockstar && rm -rf /tmp/rock /tmp/rock.tgz && printf 'shout "ok"\n' > /tmp/t.rock && test "$(rockstar /tmp/t.rock)" = "ok" && rm -f /tmp/t.rock ) && \
    ( curl --retry 5 -fsSL -o /tmp/glass-0.12.tar.bz2 https://raw.githubusercontent.com/graue/esofiles/07dce2dbff3325ced047f080b4c9b9f433b3c72b/glass/impl/glass-0.12.tar.bz2 && \
    echo "656745252fe077c88229b4057a34d832c8c2af985cdc913e532179fb0c43112c  /tmp/glass-0.12.tar.bz2" | sha256sum -c && \
    mkdir -p /tmp/glass && tar -xjf /tmp/glass-0.12.tar.bz2 -C /tmp/glass --strip-components=1 && \
    make -C /tmp/glass CXX="g++ -include cstring" CXXFLAGS="-O2" && \
    install -m 755 /tmp/glass/glass /usr/local/bin/glass && \
    rm -rf /tmp/glass /tmp/glass-0.12.tar.bz2 && \
    printf '{M[m(_o)O!"ok"(_o)o.?]}' > /tmp/t.glass && test "$(glass /tmp/t.glass)" = "ok" && rm -f /tmp/t.glass )
RUN ( curl --retry 3 -fsSL -o /tmp/ydb.tgz https://github.com/YottaDB/YDB/releases/download/r2.06/yottadb_r206_x8664_ubuntu2404_pro.tgz && echo "9414a0e3e0f9cf60b4464307fcbd07681229444572f246ef93de8b0ff78d4575  /tmp/ydb.tgz" | sha256sum -c - && mkdir -p /opt/yottadb && tar -xzf /tmp/ydb.tgz -C /opt/yottadb --strip-components=1 && rm -f /tmp/ydb.tgz ) && \
    ( mkdir -p /tmp/mira_build && cd /tmp/mira_build && curl --retry 3 -fsSL -o mira-2066-src.tgz https://www.cs.kent.ac.uk/people/staff/dat/miranda/src/mira-2066-src.tgz && echo "521c281e8c2fde87a2cd7c41d9677daa09514debb71435efc08ff3a7c20016eb  mira-2066-src.tgz" | sha256sum -c - && tar -xzf mira-2066-src.tgz && cd miranda && chronic make CC="gcc -std=gnu17 -fcommon -w" && cp mira /usr/local/bin/mira && mkdir -p /usr/lib/miralib && cp -a miralib/. /usr/lib/miralib/ && cd / && rm -rf /tmp/mira_build ) && \
    ( mkdir -p /tmp/hope_build && cd /tmp/hope_build && curl --retry 3 -fsSL -o hope.tar.gz https://github.com/dmbaturin/hope/archive/94fc5a09ff1e01ad0a8b6a4ee999414a5bad7f15.tar.gz && echo "772a882b90170202a46075f853458cbbdd274c7503e8f9d9277ad2fb63abc718  hope.tar.gz" | sha256sum -c - && tar -xzf hope.tar.gz && cd hope-94fc5a09ff1e01ad0a8b6a4ee999414a5bad7f15 && CC="gcc -std=gnu17 -Wno-implicit-int -Wno-implicit-function-declaration -Wno-incompatible-pointer-types" chronic ./configure --prefix=/usr/local && chronic make CC="gcc -std=gnu17 -Wno-implicit-int -Wno-implicit-function-declaration -Wno-incompatible-pointer-types" && chronic make install && cd / && rm -rf /tmp/hope_build ) && \
    ( curl --retry 3 -fsSL -o /tmp/clean.tar.gz https://ftp.cs.ru.nl/Clean/Clean31/linux/clean3.1_64.tar.gz && echo "ffb03e65798246215a8c217cdbaf33fa29ae5b110cc54b144e989bb9537b3fbb  /tmp/clean.tar.gz" | sha256sum -c - && tar -xzf /tmp/clean.tar.gz -C /opt && chronic make -C /opt/clean && rm -f /tmp/clean.tar.gz ) && \
    ( curl --retry 3 -fsSL -o /tmp/grain.tar.gz https://github.com/grain-lang/grain/releases/download/grain-v0.7.3/grain-linux-x64.tar.gz && echo "0a62fd9ae4b24c6fbd365717396246049ede0a88702c9c975b06e5070a2304c7  /tmp/grain.tar.gz" | sha256sum -c - && mkdir -p /opt/grain && tar -xzf /tmp/grain.tar.gz -C /opt/grain && ln -sf /opt/grain/grain /usr/local/bin/grain && rm -f /tmp/grain.tar.gz ) && \
    ( mkdir -p /tmp/mirth_build && cd /tmp/mirth_build && curl --retry 3 -fsSL -o mirth.tar.gz https://github.com/mirth-lang/mirth/archive/b6d5e9c0ecde71f3711a1c1d5d87ac97f4543fa6.tar.gz && echo "7af6d8dd3871a9851a73c32810870096bea2f0675223acb9a7fc2eb812a06dde  mirth.tar.gz" | sha256sum -c - && tar -xzf mirth.tar.gz && mv mirth-b6d5e9c0ecde71f3711a1c1d5d87ac97f4543fa6 /opt/mirth && gcc -O2 -o /usr/local/bin/mirth /opt/mirth/bin/mirth0.c && cd / && rm -rf /tmp/mirth_build ) && \
    ( mkdir -p /tmp/lob_build && cd /tmp/lob_build && curl --retry 3 -fsSL -o lobster.tar.gz https://github.com/aardappel/lobster/archive/refs/tags/v2026.9.tar.gz && echo "4f1de38fb65faf654092c407b2420411a6bfae0cdce186a97844e5f200a399ac  lobster.tar.gz" | sha256sum -c - && tar -xzf lobster.tar.gz && cd lobster-2026.9/dev && mkdir build && cd build && chronic cmake -DCMAKE_BUILD_TYPE=Release -DLOBSTER_ENGINE=OFF .. && chronic make -j"$(nproc)" && mkdir -p /opt/lobster/bin && cp /tmp/lob_build/lobster-2026.9/bin/lobster /opt/lobster/bin/lobster && cp -a /tmp/lob_build/lobster-2026.9/modules /opt/lobster/modules && cd / && rm -rf /tmp/lob_build ) && \
    ( mkdir -p /tmp/apl_build && cd /tmp/apl_build && curl --retry 3 -fsSL -o apl-2.0.tar.gz https://mirrors.kernel.org/gnu/apl/apl-2.0.tar.gz && echo "24bbb744fce47e62837234a053bdeecee51b9ea61c82c79f7cc191bc6a54c0a1  apl-2.0.tar.gz" | sha256sum -c - && tar -xzf apl-2.0.tar.gz && cd apl-2.0 && chronic ./configure --prefix=/usr/local --without-gtk3 --without-sqlite3 --without-postgresql --without-pcre && chronic make -j"$(nproc)" && chronic make install && cd / && rm -rf /tmp/apl_build ) && \
    ( mkdir -p /opt/flix && curl --retry 3 -fsSL -o /opt/flix/flix.jar https://github.com/flix/flix/releases/download/v0.80.0/flix.jar && echo "0e9dec1e93071ada5eaba2e187499f0880b574e7e4ef62937d6f31c661c1fda0  /opt/flix/flix.jar" | sha256sum -c - )
ENV PATH=/opt/clean/bin:/opt/lobster/bin:$PATH
RUN ( git clone -q --depth 1 -b v2.0.8 https://github.com/0branch/boron.git /tmp/boron && \
    cd /tmp/boron && make -j4 > /tmp/boron.log 2>&1 && make install >> /tmp/boron.log 2>&1 && ldconfig && \
    cd / && rm -rf /tmp/boron /tmp/boron.log && \
    printf 'prin "boron ok"\n' > /tmp/t.b && test "$(boron /tmp/t.b)" = "boron ok" && rm -f /tmp/t.b ) && \
    ( git clone -q https://github.com/ChaiScript/ChaiScript.git /tmp/chaiscript && \
    cd /tmp/chaiscript && git checkout -q f635b51e3f8e95868210edfc66fdbd8e475710f5 && \
    mkdir build && cd build && \
    cmake .. -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTING=OFF -DBUILD_SAMPLES=OFF -DCMAKE_POLICY_VERSION_MINIMUM=3.5 > /tmp/chai.log 2>&1 && \
    make -j4 chai >> /tmp/chai.log 2>&1 && \
    install -m 755 chai /usr/local/bin/chai && cd / && rm -rf /tmp/chaiscript /tmp/chai.log && \
    printf 'puts(R"Q(chai ok)Q");\n' > /tmp/t.chai && test "$(chai /tmp/t.chai)" = "chai ok" && rm -f /tmp/t.chai ) && \
    ( curl --retry 5 -fsSL -o /tmp/miniscript.tgz https://github.com/JoeStrout/miniscript2/releases/download/v2.0.0/miniscript-linux.tar.gz && \
    echo "97ddd3bb88e3287745818e29d809d3fc69e65159eda23d9e80ed02bb08a4f966  /tmp/miniscript.tgz" | sha256sum -c && \
    mkdir -p /opt/miniscript && tar -xzf /tmp/miniscript.tgz -C /opt/miniscript 2>/dev/null && rm -f /tmp/miniscript.tgz && \
    chmod +x /opt/miniscript/miniscript-linux/miniscript && \
    ln -sf /opt/miniscript/miniscript-linux/miniscript /usr/local/bin/miniscript && \
    printf 'print "miniscript ok",""\n' > /tmp/t.ms && test "$(miniscript /tmp/t.ms)" = "miniscript ok" && rm -f /tmp/t.ms ) && \
    ( cargo install gluon_repl --version 0.18.4 --locked --root /opt/gluon > /tmp/gluon-build.log 2>&1 && rm -f /tmp/gluon-build.log && \
    ln -sf /opt/gluon/bin/gluon /usr/local/bin/gluon && gluon --version ) && \
    ( curl --retry 5 -fsSL -o /tmp/effekt.tgz https://github.com/effekt-lang/effekt/releases/download/v0.85.0/effekt.tgz && \
    echo "aa2502af4a2d91e8ed974580d0e3bf04141d3f0325cc97ad7a09c81203db39bb  /tmp/effekt.tgz" | sha256sum -c && \
    mkdir -p /opt/effekt && tar -xzf /tmp/effekt.tgz -C /opt/effekt && rm -f /tmp/effekt.tgz && \
    chmod +x /opt/effekt/package/bin/effekt && ln -sf /opt/effekt/package/bin/effekt /usr/local/bin/effekt && effekt --version ) && \
    ( git clone -q --depth 1 -b v2.6 https://github.com/FascinatedBox/lily.git /tmp/lily && \
    mkdir -p /tmp/lily/build && cd /tmp/lily/build && \
    cmake .. -DCMAKE_BUILD_TYPE=Release > /tmp/lily.log 2>&1 && \
    make -j4 >> /tmp/lily.log 2>&1 && make install >> /tmp/lily.log 2>&1 && ldconfig && \
    cd / && rm -rf /tmp/lily /tmp/lily.log && \
    printf 'stdout.write("lily ok")\n' > /tmp/t.lily && test "$(lily /tmp/t.lily)" = "lily ok" && rm -f /tmp/t.lily ) && \
    ( git clone -q https://github.com/ThakeeNathees/pocketlang.git /tmp/pocket && \
    cd /tmp/pocket && git checkout -q cc73ca61b113d48ee130d837a7a8b145e41de5ce && \
    make -j4 release > /tmp/pocket.log 2>&1 && \
    install -m 755 build/Release/bin/pocket /usr/local/bin/pocket && cd / && rm -rf /tmp/pocket /tmp/pocket.log && \
    printf 'import io\nio.write(io.stdout,"pocket ok")\n' > /tmp/t.pk && test "$(pocket /tmp/t.pk)" = "pocket ok" && rm -f /tmp/t.pk ) && \
    ( curl --retry 5 -fsSL -o /tmp/cyber.tgz https://github.com/fubark/cyber/releases/download/0.3/cyber-linux-x64.tar.gz && \
    echo "24343c64e6c249fc2c081d11d959ad0e1db612f534e0a891c96db6111d9a3e1d  /tmp/cyber.tgz" | sha256sum -c && \
    mkdir -p /opt/cyber && tar -xzf /tmp/cyber.tgz -C /opt/cyber && rm -f /tmp/cyber.tgz && \
    chmod +x /opt/cyber/cyber && ln -sf /opt/cyber/cyber /usr/local/bin/cyber && cyber version ) && \
    ( cargo install dyon --version 0.51.3 --example dyonrun --locked --root /opt/dyon > /tmp/dyon-build.log 2>&1 && rm -f /tmp/dyon-build.log && \
    ln -sf /opt/dyon/bin/dyonrun /usr/local/bin/dyonrun && \
    printf 'fn main() { print("dyon ok") }\n' > /tmp/t.dyon && test "$(dyonrun /tmp/t.dyon)" = "dyon ok" && rm -f /tmp/t.dyon ) && \
    ( curl --retry 5 -fsSL -o /tmp/rye.tgz https://github.com/refaktor/rye/releases/download/v0.2.82/rye_Linux_x86_64.tar.gz && \
    echo "d357699ee093365962813640d44b79f2b59050b43c463adebc231ab1f807900e  /tmp/rye.tgz" | sha256sum -c && \
    mkdir -p /opt/rye && tar -xzf /tmp/rye.tgz -C /opt/rye && rm -f /tmp/rye.tgz && \
    chmod +x /opt/rye/rye && ln -sf /opt/rye/rye /usr/local/bin/rye && \
    printf 'prn "rye ok"\n' > /tmp/t.rye && test "$(rye /tmp/t.rye)" = "rye ok" && rm -f /tmp/t.rye ) && \
    ( git clone -q --depth 1 -b v4.1.7152 https://github.com/compuphase/pawn.git /tmp/pawn && \
    mkdir -p /tmp/pawn/build && cd /tmp/pawn/build && \
    cmake .. -DCMAKE_BUILD_TYPE=Release -DCMAKE_POLICY_VERSION_MINIMUM=3.5 -DHAVE_CURSES_H=0 -DCMAKE_C_FLAGS="-O2 -std=gnu11 -Wno-error" > /tmp/pawn.log 2>&1 && \
    make -j4 >> /tmp/pawn.log 2>&1 && \
    mkdir -p /opt/pawn/bin /opt/pawn/include && \
    cp /tmp/pawn/include/*.inc /opt/pawn/include/ && \
    install -m 755 pawncc pawnrun /opt/pawn/bin/ && \
    (cp -a libpawnc.so* libamx.so* /usr/local/lib/ 2>/dev/null || true) && ldconfig && \
    printf '#!/bin/sh\nexec /opt/pawn/bin/pawncc -i/opt/pawn/include "$@"\n' > /usr/local/bin/pawncc && \
    chmod +x /usr/local/bin/pawncc && ln -sf /opt/pawn/bin/pawnrun /usr/local/bin/pawnrun && \
    cd / && rm -rf /tmp/pawn /tmp/pawn.log && \
    printf '#include <console>\nmain(){printf("%%s","pawn ok");}\n' > /tmp/t.pawn && \
    pawncc -C64 /tmp/t.pawn -o/tmp/t.amx >/dev/null && test "$(pawnrun /tmp/t.amx)" = "pawn ok" && rm -f /tmp/t.pawn /tmp/t.amx ) && \
    ( mkdir -p /opt/austral && \
    curl --retry 5 -fsSL -o /opt/austral/austral-linux https://github.com/austral/austral/releases/download/v0.2.0/austral-linux && \
    echo "ab0c8e5f24261360a8064c992b019867edd6dc2b05001c4a21f71b863b4beed3  /opt/austral/austral-linux" | sha256sum -c && \
    chmod +x /opt/austral/austral-linux && \
    printf '#!/bin/sh\nexec /lib64/ld-linux-x86-64.so.2 /opt/austral/austral-linux "$@"\n' > /usr/local/bin/austral && \
    chmod +x /usr/local/bin/austral && austral --version ) && \
    ( curl --retry 5 -fsSL -o /tmp/vale.zip https://github.com/ValeLang/Vale/releases/download/v0.2.0/Vale-Ubuntu-0.2.0.28.zip && \
    echo "cfb0a46d493dc60210c1aa612836afa7ddc3423868c2dab48ccea9c39a03e893  /tmp/vale.zip" | sha256sum -c && \
    mkdir -p /opt/vale && unzip -q /tmp/vale.zip -d /opt/vale && rm -f /tmp/vale.zip && \
    chmod +x /opt/vale/valec && \
    printf '#!/bin/sh\nexec /opt/vale/valec "$@"\n' > /usr/local/bin/valec && \
    chmod +x /usr/local/bin/valec )
RUN useradd -m -s /bin/bash qr \
    && for d in .arturo .ballerina .cache .cargo .config .dotnet .local .mirarc .npm .nuget .texlive2025 go; do \
         [ -e "/root/$d" ] && mv "/root/$d" "/home/qr/$d"; \
       done \
    && chown -R qr:qr /home/qr \
    && for d in /opt/clean /opt/yottadb /opt/roc /opt/flix /opt/grain /opt/vale /opt/purs /opt/mirth /opt/v /opt/factor; do \
         [ -d "$d" ] && chown -R qr:qr "$d"; \
       done
ADD . /usr/local/share/quine-relay
WORKDIR /usr/local/share/quine-relay
RUN make -C vendor && rm -f /usr/bin/sync && dpkg-divert --quiet --local --rename --remove /usr/bin/sync && chown -R qr:qr /usr/local/share/quine-relay
USER qr
ENV HOME=/home/qr DOTNET_CLI_HOME=/home/qr/.dotnet NUGET_PACKAGES=/home/qr/.nuget/packages XDG_CACHE_HOME=/home/qr/.cache GOCACHE=/home/qr/.cache/go-build
CMD ["make", "check", "-j", "10000"]
