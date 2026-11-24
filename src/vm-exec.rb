#!/usr/bin/env ruby
# Assembles and executes Asm6502, Z80Asm, and Uxntal on the payloads generated from QR.aj,
# verifying exact output and enforcing the < 64,000 B ROM size limit.
require "fileutils"
require_relative "code-gen"
qr_path = ARGV[0] || File.expand_path("../QR.aj", __dir__)
ROM_GUARD = (ENV["ROM_GUARD"] || 64000).to_i

cur = File.binread(qr_path).force_encoding("UTF-8")
aj_idx = GenSteps.index { |st| st.name == "AspectJ" }
ordered = (GenSteps[(aj_idx + 1)..] + GenSteps[0...aj_idx]).reject { |st| st.code.nil? }

work = "/tmp/vm_exec"
FileUtils.rm_rf(work)
FileUtils.mkdir_p(work)

ordered[0, 30].each do |st|
  st.check.call(cur)
  nxt = Object.new.instance_eval(GenPrologue + ";" + st.code.sub("PREV") { cur.dump })
  if %w[Asm6502 Z80Asm Uxntal].include?(st.name)
    rs = st.run_steps.first
    src_file = File.join(work, rs.src)
    out_file = File.join(work, "out_#{st.name}")
    File.binwrite(src_file, nxt.encode("UTF-8").b)
    cmd = rs.cmd_raw.gsub("OUTFILE", out_file).sub(/\s*&&\s*rm -f\s+[^\s&;]+\s*\z/, "")
    if st.name == "Z80Asm" && Process.uid == 0 && !cmd.include?("setpriv")
      cmd = cmd.sub("tnylpo ", "chmod a+r qr.com && setpriv --reuid=nobody --regid=nogroup --clear-groups tnylpo ")
    end
    t0 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    ok = system("cd #{work} && #{cmd}")
    dt = Process.clock_gettime(Process::CLOCK_MONOTONIC) - t0
    raise "#{st.name} execution FAILED!" unless ok
    got = File.binread(out_file)
    exp = cur.encode("UTF-8").b
    raise "#{st.name} output MISMATCH (#{got.bytesize} vs #{exp.bytesize})!" unless got == exp
    bin_path = case st.name
               when "Asm6502" then Dir.glob(File.join(work, "QR*")).find { |f| f != src_file && !f.end_with?(".s") }
               when "Z80Asm"  then File.join(work, "qr.com")
               when "Uxntal"  then File.join(work, "QR.rom")
               end
    bin_sz = bin_path && File.exist?(bin_path) ? File.size(bin_path) : -1
    limit = case st.name
            when "Asm6502" then 65012
            when "Z80Asm"  then 64991
            when "Uxntal"  then 65280
            end
    spare = bin_sz > 0 ? limit - bin_sz : -1
    printf "[PASS] %-8s exact=true time=%.2fs pay=%6d B bin=%6d B / %d B (spare=%d B)\n",
      st.name, dt, exp.bytesize, bin_sz, limit, spare
    if bin_sz >= ROM_GUARD
      raise "#{st.name} ROM GUARD FAILED: bin=#{bin_sz} B >= #{ROM_GUARD} B (spare=#{spare} B)!"
    end
  end
  cur = nxt
end
FileUtils.rm_rf(work)
