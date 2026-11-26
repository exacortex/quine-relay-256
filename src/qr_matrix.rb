# Pure-Ruby ISO 18004 QR Code matrix generator (Version 3, 29x29, EC-L, mask 0).
# Encodes QR_URL without external gems; exports QR_N, QR_MW, QR_MH, and qr_matrix_str.

QR_URL = "https://github.com/exacortex/quine-relay-256"
QR_N   = 29
QR_MW  = 18
QR_MH  = 9

def qr_gf_mul(a, b)
  r = 0
  8.times do
    r ^= a if (b & 1) != 0
    a <<= 1
    a ^= 0x11d if (a & 0x100) != 0
    b >>= 1
  end
  r
end

def qr_rs_rem(data, deg)
  g = [1]
  p = 1
  deg.times do
    ng = Array.new(g.length + 1, 0)
    g.each_with_index do |c, i|
      ng[i] ^= c
      ng[i + 1] ^= qr_gf_mul(c, p)
    end
    g = ng
    p = qr_gf_mul(p, 2)
  end
  rem = Array.new(deg, 0)
  data.each do |b|
    f = b ^ rem.shift
    rem << 0
    if f != 0
      deg.times { |i| rem[i] ^= qr_gf_mul(g[i + 1], f) }
    end
  end
  rem
end

def qr_matrix_str(url = QR_URL)
  n = QR_N
  tot_cw = 70
  ec_cw = 15
  data_cw = tot_cw - ec_cw
  ec_bits = 0b01 # EC-L
  mask_id = 0    # (r + c) % 2 == 0

  raw = url.encode("UTF-8").bytes
  bits = []
  put = lambda { |v, k| (k - 1).downto(0) { |i| bits << ((v >> i) & 1) } }
  put.call(0b0100, 4) # Byte mode
  put.call(raw.length, 8)
  raw.each { |b| put.call(b, 8) }
  term = [4, data_cw * 8 - bits.length].min
  put.call(0, term) if term > 0
  bits << 0 while (bits.length % 8) != 0
  cw = bits.each_slice(8).map { |sl| sl.each_with_index.sum { |bit, j| bit << (7 - j) } }
  pad = [0xec, 0x11]
  cw << pad[cw.length % 2] while cw.length < data_cw
  final_cw = cw + qr_rs_rem(cw, ec_cw)
  dbits = final_cw.flat_map { |b| (0..7).map { |j| (b >> (7 - j)) & 1 } }

  mat = Array.new(n) { Array.new(n, nil) }
  func = Array.new(n) { Array.new(n, false) }
  setf = lambda do |r, c, v|
    mat[r][c] = v
    func[r][c] = true
  end

  # Three 7x7 finder patterns + 1-module white separators
  [[0, 0], [0, n - 7], [n - 7, 0]].each do |fr, fc|
    (-1..7).each do |dr|
      (-1..7).each do |dc|
        r = fr + dr
        c = fc + dc
        next unless r >= 0 && r < n && c >= 0 && c < n
        in7 = (0..6).cover?(dr) && (0..6).cover?(dc)
        v = in7 && (dr == 0 || dr == 6 || dc == 0 || dc == 6 || (dr.between?(2, 4) && dc.between?(2, 4)))
        setf.call(r, c, v ? 1 : 0)
      end
    end
  end

  # Alignment pattern at (22, 22) for Version 3
  [6, 22].each do |ar|
    [6, 22].each do |ac|
      next if func[ar][ac]
      (-2..2).each do |dr|
        (-2..2).each do |dc|
          v = [dr.abs, dc.abs].max != 1
          setf.call(ar + dr, ac + dc, v ? 1 : 0)
        end
      end
    end
  end

  # Timing patterns
  (8...(n - 8)).each do |i|
    setf.call(6, i, 1 - (i % 2)) unless func[6][i]
    setf.call(i, 6, 1 - (i % 2)) unless func[i][6]
  end

  # Fixed dark module & reserve format areas
  setf.call(4 * 3 + 9, 8, 1)
  9.times do |i|
    setf.call(8, i, 0) unless func[8][i]
    setf.call(i, 8, 0) unless func[i][8]
  end
  8.times do |i|
    setf.call(8, n - 1 - i, 0)
    setf.call(n - 1 - i, 8, 0) if i < 7
  end

  # Zigzag data bit placement
  idx = 0
  up = true
  col = n - 1
  while col > 0
    col -= 1 if col == 6
    rows = up ? (n - 1).downto(0) : 0.upto(n - 1)
    rows.each do |r|
      [0, -1].each do |dc|
        unless func[r][col + dc]
          mat[r][col + dc] = idx < dbits.length ? dbits[idx] : 0
          idx += 1
        end
      end
    end
    up = !up
    col -= 2
  end

  # Apply mask 0: (r + c) % 2 == 0
  g = Array.new(n) do |r|
    Array.new(n) do |c|
      flip = (!func[r][c] && ((r + c) % 2 == 0)) ? 1 : 0
      mat[r][c] ^ flip
    end
  end

  # Format info BCH(15, 5)
  d = (ec_bits << 3) | mask_id
  rem = d << 10
  14.downto(10) { |i| rem ^= 0x537 << (i - 10) if ((rem >> i) & 1) != 0 }
  fb = ((d << 10) | rem) ^ 0x5412

  6.times { |i| g[8][i] = (fb >> (14 - i)) & 1 }
  g[8][7] = (fb >> 8) & 1
  g[8][8] = (fb >> 7) & 1
  g[7][8] = (fb >> 6) & 1
  6.times { |i| g[5 - i][8] = (fb >> (5 - i)) & 1 }
  7.times { |i| g[n - 1 - i][8] = (fb >> (14 - i)) & 1 }
  8.times { |i| g[8][n - 8 + i] = (fb >> (7 - i)) & 1 }

  g.flatten.join
end
