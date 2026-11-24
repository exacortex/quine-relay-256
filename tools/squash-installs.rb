# squash-installs.rb FILE... -> groups consecutive RUN instructions from each installs file
# into a single subshell-isolated RUN layer so the generated Dockerfile stays well below
# Docker's overlay2 layer limit while keeping `cd` / `export` scoped cleanly per group.
out = []
ARGV.each do |f|
  insns = []; cur = nil
  File.read(f).each_line do |l|
    l = l.chomp
    if cur
      cur << "\n" << l
    else
      next if l.strip.empty? || l.lstrip.start_with?("#")
      cur = l.dup
    end
    if cur.end_with?("\\") then next else insns << cur; cur = nil end
  end
  insns << cur if cur
  group = []
  flush = lambda do
    next if group.empty?
    out << "RUN " + group.map { |b| "( #{b} )" }.join(" && \\\n    ")
    group.clear
  end
  insns.each do |i|
    if i =~ /\ARUN\s+(.*)\z/m
      body = $1
      raise "#{f}: RUN in exec (JSON) form can't be squashed: #{i[0, 60]}" if body.start_with?("[")
      group << body
    else
      flush.call; out << i
    end
  end
  flush.call
end
puts out
