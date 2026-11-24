require_relative "code-gen"

apts = RunSteps.flat_map {|s| s.apt }
other_packages = %w(cmake unzip clang brotli libpng-dev libgd-dev libfl-dev flex bison curl git ca-certificates)

apts = [*apts.flatten.compact.uniq, *other_packages].uniq.sort

def squash_installs(files)
  out = []
  files.each do |f|
    insns = []
    cur = nil
    File.read(f, encoding: "UTF-8").each_line do |l|
      l = l.chomp
      if cur
        cur << "\n" << l
      else
        next if l.strip.empty? || l.lstrip.start_with?("#")
        cur = l.dup
      end
      if cur.end_with?("\\")
        next
      else
        insns << cur
        cur = nil
      end
    end
    insns << cur if cur
    group = []
    flush = lambda do
      next if group.empty?
      out << "RUN " + group.map {|b| "( #{ b } )" }.join(" && \\\n    ")
      group.clear
    end
    insns.each do |i|
      if i =~ /\ARUN\s+(.*)\z/m
        body = $1
        raise "#{ f }: RUN in exec form cannot be squashed" if body.start_with?("[")
        group << body
      else
        flush.call
        out << i
      end
    end
    flush.call
  end
  out
end

dockerfile = []
ubuntu_ver = File.exist?("/etc/os-release") ? File.read("/etc/os-release")[/^VERSION_ID="?([^"\n]+)"?/, 1] : nil
ubuntu_ver = "26.04" if ubuntu_ver.nil? || ubuntu_ver.empty?
dockerfile << "FROM ubuntu:#{ ubuntu_ver }"
dockerfile << "ENV DEBIAN_FRONTEND=noninteractive CARGO_HTTP_MULTIPLEXING=false CARGO_NET_RETRY=10"
dockerfile << "RUN dpkg-divert --quiet --local --rename --add /usr/bin/sync && ln -sf /bin/true /usr/bin/sync && apt-get update && apt-get upgrade -y && apt-get -qq install -y apt-utils moreutils > /dev/null && apt-get clean"
apts.each_slice(20) do |apt|
  dockerfile << "RUN chronic apt-get -qq install -y #{ apt.join(" ") } && chronic apt-get clean"
end
# Non-apt toolchains (pinned versions)
dockerfile << "RUN chronic apt-get -qq install -y python3-pip golang-go cargo && chronic apt-get clean"
dockerfile << "RUN GOBIN=/usr/local/bin go install github.com/d5/tengo/v2/cmd/tengo@v2.17.0 && GOBIN=/usr/local/bin go install github.com/mattn/anko@v0.1.15"
dockerfile << "RUN cargo install --locked --root /usr/local rhai@1.27.0 --features bin-features --bin rhai-run && cargo install --locked --root /usr/local koto_cli@0.16.1"
# Grouped toolchain installs (keeps layer count well below Docker's overlay2 limit)
dockerfile.concat(squash_installs(Dir[File.join(__dir__, "extra-installs", "*.txt")].sort))
dockerfile << <<~'NONROOT'.chomp
  RUN useradd -m -s /bin/bash qr \
      && for d in .arturo .ballerina .cache .cargo .config .dotnet .local .mirarc .npm .nuget .texlive2025 go; do \
           [ -e "/root/$d" ] && mv "/root/$d" "/home/qr/$d"; \
         done \
      && chown -R qr:qr /home/qr \
      && for d in /opt/clean /opt/yottadb /opt/roc /opt/flix /opt/grain /opt/vale /opt/purs /opt/mirth /opt/v /opt/factor; do \
           [ -d "$d" ] && chown -R qr:qr "$d"; \
         done
NONROOT
dockerfile << "ADD . /usr/local/share/quine-relay"
dockerfile << "WORKDIR /usr/local/share/quine-relay"
dockerfile << "RUN make -C vendor && rm -f /usr/bin/sync && dpkg-divert --quiet --local --rename --remove /usr/bin/sync && chown -R qr:qr /usr/local/share/quine-relay"
dockerfile << "USER qr"
dockerfile << "ENV HOME=/home/qr DOTNET_CLI_HOME=/home/qr/.dotnet NUGET_PACKAGES=/home/qr/.nuget/packages XDG_CACHE_HOME=/home/qr/.cache GOCACHE=/home/qr/.cache/go-build"
dockerfile << 'CMD ["make", "check", "-j", "10000"]'

File.binwrite(File.join(__dir__, "../Dockerfile"), dockerfile.join("\n") + "\n")
