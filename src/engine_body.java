// AspectJ Quine Relay Engine body (Java 8 compatible, pure stdout, zero file/CLI/shell access)
static final java.nio.charset.Charset U = java.nio.charset.StandardCharsets.UTF_8;
static byte[] D;
static int P;
static String E;

static int ri() {
  int v = 0, k = 0, b;
  do { b = D[P++] & 255; v |= (b & 127) << k; k += 7; } while ((b & 128) != 0);
  return v;
}

static String rs() {
  int n = ri();
  String r = new String(D, P, n, U);
  P += n;
  return r;
}

static StringBuilder sb() { return new StringBuilder(); }
static StringBuilder sb(String s) { return new StringBuilder(s); }
static ArrayList<String> al() { return new ArrayList<String>(); }
static Matcher mt(String p, String s) { return Pattern.compile(p, Pattern.DOTALL).matcher(s); }
static void byt(StringBuilder r, byte[] b, int n) {
  for (int i = 0; i < n; i++) {
    if (i % 32 == 0) { if (i > 0) r.append('\n'); r.append(" .byt "); } else r.append(',');
    r.append(i < b.length ? (b[i] & 255) : 0);
  }
}

static String procs(ArrayList<String> ac, int sz, String hdr, String pp, String pm, String pe, String mid, String cp, String end, int w) {
  StringBuilder r = sb(hdr);
  int g = (ac.size() + sz - 1) / sz;
  for (int i = 0; i < g; i++) {
    if (i > 0 && w >= 0) r.append('\n');
    r.append(pp).append(i).append(pm);
    int e = Math.min(ac.size(), (i + 1) * sz), cl = 0;
    boolean fl = true;
    for (int j = i * sz; j < e; j++) {
      String st = ac.get(j);
      if (w > 0 && !fl && cl + st.length() < w) { r.append(st); cl += st.length(); }
      else { if (!fl) r.append('\n'); r.append(st); cl = st.length(); fl = false; }
    }
    r.append(pe).append(w == 4000 ? i + ";" : "");
  }
  r.append(mid);
  for (int i = 0; i < g; i++) {
    if (w >= 0 && i > 0 && i % 20 == 0) r.append('\n');
    r.append(cp).append(i).append(w < 0 ? "\n" : ";");
  }
  return r.append(end).toString();
}

static String esc(String s) {
  StringBuilder r = sb();
  for (int i = 0; i < s.length(); i++) {
    char c = s.charAt(i);
    if (c == '\\') r.append("\\\\");
    else if (c == '"') r.append("\\\"");
    else if (c == '\n') r.append("\\n");
    else r.append(c);
  }
  return r.toString();
}

static String dbl(String s, char q) {
  StringBuilder r = sb();
  for (int i = 0; i < s.length(); i++) {
    char c = s.charAt(i);
    if (c == q) r.append(q);
    r.append(c);
  }
  return r.toString();
}

static String rep(String s, String[] k, String[] v) {
  if (k.length == 0) return s;
  StringBuilder r = sb();
  int n = s.length(), m = k.length;
  for (int i = 0; i < n; ) {
    boolean hit = false;
    for (int j = 0; j < m; j++) {
      if (s.startsWith(k[j], i)) {
        r.append(v[j]);
        i += k[j].length();
        hit = true;
        break;
      }
    }
    if (!hit) r.append(s.charAt(i++));
  }
  return r.toString();
}

static String xf(String s, int f) {
  if ((f & 262144) != 0) s = chomp(s);
  if ((f & 1) != 0) s = esc(s);
  if ((f & 2) != 0) s = dbl(s, '"');
  if ((f & 4) != 0) s = dbl(s, '\'');
  if ((f & 8) != 0) s = dbl(s, '`');
  if ((f & 48) != 0) {
    char q = (f & 16) != 0 ? '"' : '\'';
    StringBuilder r = sb();
    for (int i = 0; i < s.length(); i++) { char c = s.charAt(i); if (c == '\\' || c == q) r.append('\\'); r.append(c); }
    s = r.toString();
  }
  if ((f & 64) != 0) s = s.replace("\t", "\\t");
  if ((f & 128) != 0) s = s.replace("\r", "\\r");
  if ((f & 256) != 0) s = s.replace("$", "\\$");
  if ((f & 512) != 0) s = s.replace("%", "\\%");
  if ((f & 1024) != 0) s = s.replace("%", "%%");
  if ((f & 2048) != 0) s = s.replace("#", "\\#");
  if ((f & 4096) != 0) s = s.replace("?", "\\?");
  if ((f & 8192) != 0) s = s.replace("'", "\\'");
  if ((f & 16384) != 0) s = s.replace("{", "{{").replace("}", "}}");
  if ((f & 32768) != 0) s = s.replace("{", "\\{").replace("}", "\\}");
  if ((f & 2293760) != 0) {
    StringBuilder r = sb();
    for (int i = 0; i < s.length(); i++) {
      char c = s.charAt(i);
      if ((f & 65536) != 0 && (c < 32 || c == 127)) r.append(String.format("\\x%02x", (int) c));
      else if ((f & 131072) != 0 && (c < 10 || (c > 10 && c < 32) || c == 96 || c == 127)) r.append(String.format("\\%03o", (int) c));
      else if ((f & 2097152) != 0 && c > 127) r.append(String.format("\\u%04x", (int) c));
      else r.append(c);
    }
    s = r.toString();
  }
  if ((f & 524288) != 0) {
    StringBuilder r = sb();
    for (byte b : s.getBytes(U)) { int u = b & 255; r.append(u >= 128 ? String.format("\\x%02x", u) : String.valueOf((char) u)); }
    s = r.toString();
  }
  if ((f & 4194304) != 0) {
    StringBuilder r = sb();
    for (int i = 0; i < s.length(); ) {
      int cp = s.codePointAt(i);
      if (cp > 127) r.append("\\u{").append(Integer.toHexString(cp)).append('}');
      else r.append((char) cp);
      i += Character.charCount(cp);
    }
    s = r.toString();
  }
  return s;
}

static String[] lines(String s) {
  ArrayList<String> l = al();
  int n = s.length(), i = 0;
  while (i < n) {
    int j = s.indexOf('\n', i);
    if (j < 0) { l.add(s.substring(i)); break; }
    l.add(s.substring(i, j + 1));
    i = j + 1;
  }
  return l.toArray(new String[0]);
}

static String chomp(String s) {
  return s.endsWith("\n") ? s.substring(0, s.length() - 1) : s;
}

static String bsl(String s, String a, String z) {
  Matcher m = Pattern.compile("(?:\\\\\\\\)+").matcher(s);
  StringBuffer r = new StringBuffer();
  while (m.find()) {
    m.appendReplacement(r, Matcher.quoteReplacement(a + (m.group().length() / 2) + z));
  }
  m.appendTail(r);
  return r.toString();
}

static byte[][] rp(byte[] s, int[] rng) {
  byte[] cur = s;
  byte[] v = new byte[rng.length * 2];
  int vp = v.length;
  int[] cnt = new int[65536];
  int[] seen = new int[65536];
  int sn = 0;
  for (int j : rng) {
    int len = cur.length;
    int maxC = 0, bestP = 0;
    for (int i = 0; i < len - 1; i++) {
      int p = ((cur[i] & 255) << 8) | (cur[i + 1] & 255);
      int c = ++cnt[p];
      if (c == 1) seen[sn++] = p;
      if (c > maxC) { maxC = c; bestP = p; }
    }
    for (int i = 0; i < sn; i++) cnt[seen[i]] = 0;
    sn = 0;
    byte b0 = (byte) (bestP >> 8), b1 = (byte) (bestP & 255);
    v[--vp] = b1;
    v[--vp] = b0;
    byte repB = (byte) (j & 255);
    byte[] nxt = new byte[len];
    int np = 0;
    for (int i = 0; i < len; ) {
      if (i + 1 < len && cur[i] == b0 && cur[i + 1] == b1) {
        nxt[np++] = repB;
        i += 2;
      } else {
        nxt[np++] = cur[i++];
      }
    }
    cur = Arrays.copyOf(nxt, np);
  }
  return new byte[][]{ cur, v };
}

static String step(String s) throws Exception {
  int op = D[P++] & 255;
  switch (op) {
    case 2: { // CHUNK/WRAP/MAP_WRAP (cl==0 => whole string)
      String pre = rs(), suf = rs(), cp = rs(), cs = rs(), jn = rs();
      int cl = ri(), pf = ri(), qf = ri(), mn = ri();
      String[] k = new String[mn], v = new String[mn];
      for (int i = 0; i < mn; i++) { k[i] = rs(); v[i] = rs(); }
      if ((pf & 262144) != 0) { s = chomp(s); pf &= ~262144; }
      if (cl == 0) {
        String t = pf != 0 ? xf(s, pf) : s;
        if (mn > 0) t = rep(t, k, v);
        if (qf != 0) t = xf(t, qf);
        return pre + t + suf;
      }
      StringBuilder r = sb(pre);
      int n = s.length();
      for (int i = 0; i < n; ) {
        if (i > 0) r.append(jn);
        int e = (qf & 2097152) != 0 ? s.offsetByCodePoints(i, Math.min(cl, s.codePointCount(i, n))) : Math.min(n, i + cl);
        if ((pf & 1048576) != 0 && e < n) { int e0 = e; while (e > i && s.charAt(e - 1) == '\\') e--; if (e == i) e = e0; }
        String c = s.substring(i, e);
        i = e;
        if (pf != 0) c = xf(c, pf);
        if (mn > 0) c = rep(c, k, v);
        if (qf != 0) c = xf(c, qf);
        r.append(cp).append(c).append(cs);
      }
      return r.append(suf).toString();
    }
    case 3: { // ZLIB_WRAP(pre, suf, mode)
      String pre = rs(), suf = rs();
      int m = ri();
      String in = m == 2 ? "\"" + esc(s) + "\"" : s;
      byte[] ib = in.getBytes(U);
      Deflater df = new Deflater(9, m == 1);
      df.setInput(ib);
      df.finish();
      ByteArrayOutputStream bo = new ByteArrayOutputStream();
      byte[] buf = new byte[8192];
      while (!df.finished()) bo.write(buf, 0, df.deflate(buf));
      df.end();
      String b64 = Base64.getEncoder().encodeToString(bo.toByteArray());
      if (m == 2) b64 = b64.replace("//", "/\"<>\"/");
      if (m == 3) {
        StringBuilder r = sb(pre);
        for (int i = 0; i < b64.length(); i += 1000) {
          if (i > 0) r.append("+\n");
          r.append('\'').append(b64, i, Math.min(b64.length(), i + 1000)).append('\'');
        }
        return r.append(suf).toString();
      }
      return pre + b64 + suf;
    }
    case 4: { // TOK_CHUNK(cl, dblq, pre, cp, cs, cj, tj, qch, suf, sp, toks...) - Rockstar, Pyth, Pascal, MUMPS
      int cl = ri(), dq = ri();
      String pre = rs(), cp = rs(), cs = rs(), cj = rs(), tj = rs(), qc = rs(), suf = rs(), sp = rs();
      int m = sp.length();
      String[] tk = new String[m];
      for (int i = 0; i < m; i++) tk[i] = rs();
      StringBuilder r = sb(pre);
      int n = s.length();
      if (n == 0) return r.append(qc).append(qc).append(suf).toString();
      int step = cl > 0 ? cl : n;
      char q = qc.charAt(0);
      for (int i = 0; i < n; i += step) {
        if (i > 0) r.append(cj);
        r.append(cp);
        String c = s.substring(i, Math.min(n, i + step));
        for (int j = 0; j < c.length(); ) {
          if (j > 0) r.append(tj);
          int idx = sp.indexOf(c.charAt(j));
          if (idx >= 0) { r.append(tk[idx]); j++; }
          else {
            int k = j;
            while (k < c.length() && sp.indexOf(c.charAt(k)) < 0) k++;
            String sub = c.substring(j, k);
            r.append(q).append(dq != 0 ? dbl(sub, q) : sub).append(q);
            j = k;
          }
        }
        r.append(cs);
      }
      return r.append(suf).toString();
    }
    case 5: { // RISCVAsm(pre1, pre2)
      String p1 = rs(), p2 = rs();
      StringBuilder r = sb(p1);
      r.append(s.getBytes(U).length).append(p2);
      for (int i = 0; i < s.length(); i += 16000) {
        if (i > 0) r.append('\n');
        r.append(".ascii \"").append(esc(s.substring(i, Math.min(s.length(), i + 16000)))).append('"');
      }
      return r.append('\n').toString();
    }
    case 6: { // LineChunk(clen, mode, pre, lpre, cpre, csuf, nl, suf) - REXXLang, ScilabLang, Singular, RcLang
      int cl = ri(), dd = ri();
      String pre = rs(), lp = rs(), cp = rs(), cs = rs(), nl = rs(), suf = rs();
      String[] ls = (dd == 2 ? chomp(s) : s).split("\n", -1);
      StringBuilder r = sb(pre);
      for (int i = 0; i < ls.length; i++) {
        String x = ls[i];
        r.append(lp);
        if (dd == 3) {
          int m = Math.max(1, (x.length() + cl - 1) / cl);
          for (int j = 0; j < m; j++) {
            String y = x.isEmpty() ? "" : x.substring(j * cl, Math.min(x.length(), (j + 1) * cl));
            r.append(i < ls.length - 1 && j == m - 1 ? nl : cp).append(dbl(y, '\'')).append(cs);
          }
        } else {
          for (int j = 0; j < x.length(); j += cl) {
            String c = x.substring(j, Math.min(x.length(), j + cl));
            if (dd == 2) c = xf(c, 16);
            else { if (dd != 0) c = dbl(c, '"'); c = dbl(c, '\''); }
            r.append(cp).append(c).append(cs);
          }
          if (dd == 2 || i < ls.length - 1) r.append(nl);
        }
      }
      return r.append(suf).toString();
    }
    case 8: { // RatforLang(hdr, p1, p2, p3, p4, p5)
      String hdr = rs(), p1 = rs(), p2 = rs(), p3 = rs(), p4 = rs(), p5 = rs();
      String[] ls = s.split("\n", -1);
      ArrayList<String> ac = al();
      for (int i = 0; i < ls.length; i++) {
        String x = ls[i];
        StringBuilder b = sb();
        for (int j = 0; j < x.length(); j++) {
          char h = x.charAt(j);
          String q = h == '\'' ? "''" : String.valueOf(h);
          if (b.length() + q.length() > 122) { ac.add(p1 + b + "')"); b.setLength(0); }
          b.append(q);
        }
        if (b.length() > 0) ac.add(p1 + b + "')");
        if (i < ls.length - 1) ac.add(p2);
      }
      return procs(ac, 200, hdr, p3, "\n", p4, "", p5, "end\n", -1);
    }
    case 9: { // QBE(pre, suf)
      String pre = rs(), suf = rs();
      byte[] bs = s.getBytes(U);
      StringBuilder r = sb(pre);
      for (int i = 0; i < bs.length; ) {
        if (i > 0) r.append(',');
        int u = bs[i] & 255;
        if (u > 126) { r.append("b ").append(u); i++; }
        else {
          int j = i;
          while (j < bs.length && j - i < 500) { int c = bs[j] & 255; if ((c >= 32 && c <= 126) || c == 9 || c == 10) j++; else break; }
          r.append("b \"").append(esc(new String(bs, i, j - i, U)).replace("\t", "\\t")).append('"');
          i = j;
        }
      }
      return r.append(suf).toString();
    }
    case 12: { // Oberon
      String h = rs(), pp = rs(), pm = rs(), pe = rs(), md = rs(), en = rs(), c1 = rs(), c2 = rs(), c3 = rs(), c4 = rs();
      ArrayList<String> o = al();
      for (String l : lines(s)) {
        String c = chomp(l);
        for (int i = 0; i < c.length(); ) {
          char x = c.charAt(i);
          if (x == '"') { o.add(c1); i++; }
          else if (x == '\t') { o.add(c2); i++; }
          else {
            int j = i;
            while (j < c.length() && c.charAt(j) != '"' && c.charAt(j) != '\t') j++;
            for (int k = i; k < j; k += 2000) o.add(c3 + c.substring(k, Math.min(j, k + 2000)) + "\");");
            i = j;
          }
        }
        if (l.endsWith("\n")) o.add(c4);
      }
      return procs(o, 400, h, pp, pm, pe, md, "P", en, 4000);
    }
    case 13: { // Murex
      String a = rs(), b = rs(), c = rs();
      return c + s.replace("'", a).replaceAll("\\{(?=[A-Za-z0-9_+-]+\\})", b) + "'";
    }
    case 15: { // Modula2
      String a = rs(), b = rs(), c = rs();
      StringBuilder r = sb(a);
      Matcher m = Pattern.compile("()[^\"]+|[^']+").matcher(s);
      while (m.find()) {
        char q = m.group(1) != null ? '"' : '\'';
        r.append(b).append(q).append(m.group()).append(q).append(");");
      }
      return r.append(c).toString();
    }
    case 16: { // ScanByteOrStr(pre, re, bad, bp, bs, sp, ss, jn, suf) - MMIX, Z80Asm, ARM64Asm, Kipple, Golo
      String pre = rs(), re = rs(), bad = rs(), bp = rs(), bs = rs(), sp = rs(), ss = rs(), jn = rs(), suf = rs();
      StringBuilder r = sb(pre);
      Matcher m = mt(re, s);
      boolean f = true;
      while (m.find()) {
        if (!f) r.append(jn);
        f = false;
        String g = m.group();
        if (g.length() == 1 && bad.indexOf(g.charAt(0)) >= 0) r.append(bp).append((int) g.charAt(0)).append(bs);
        else r.append(sp).append(g).append(ss);
      }
      return r.append(suf).toString();
    }
    case 17: { // MiniScript
      String[] ls = lines(s);
      StringBuilder r = sb();
      for (int i = 0; i < ls.length; i++) {
        if (i > 0) r.append('\n');
        if (ls[i].endsWith("\n")) r.append("print \"").append(dbl(chomp(ls[i]), '"')).append('"');
        else r.append("print \"").append(dbl(ls[i], '"')).append("\",\"\"");
      }
      r.append('\n');
      return r.toString();
    }
    case 18: { // MaximaLang
      String a = rs(), b = rs(), c = rs(), d = rs();
      StringBuilder r = sb(a);
      int n = s.length();
      ArrayList<String> parts = al();
      int i = 0;
      while (i < n) {
        int j = i;
        while (j < n && s.charAt(j) != '"' && s.charAt(j) != '\n') j++;
        if (j > i || (j < n && (parts.isEmpty() || parts.get(parts.size() - 1).equals("\"") || parts.get(parts.size() - 1).equals("\n")))) {
          if (j > i) parts.add(s.substring(i, j));
          else if (j < n) parts.add("");
        }
        if (j < n) { parts.add(String.valueOf(s.charAt(j))); i = j + 1; }
        else break;
      }
      for (int k = 0; k < parts.size(); k++) {
        if (k > 0) r.append(',');
        String x = parts.get(k);
        if (x.equals("\"")) r.append(b);
        else if (x.equals("\n")) r.append(c);
        else r.append('"').append(x).append('"');
      }
      return r.append(d).toString();
    }
    case 19: { // M4
      String[] ps = rs().split(",");
      for (int i = 0; i < ps.length; i += 2) {
        if (s.indexOf(ps[i]) < 0 && s.indexOf(ps[i + 1]) < 0)
          return "changequote(" + ps[i] + "," + ps[i + 1] + ")" + ps[i] + s + ps[i + 1];
      }
      return s;
    }
    case 20: { // Lua
      String eq = "=";
      while (s.indexOf("]" + eq + "]") >= 0) eq += "=";
      return "io.write([" + eq + "[\n" + s + "]" + eq + "])";
    }
    case 21: { // Lobster
      String[] ls = chomp(s).split("\n", -1);
      StringBuilder r = sb();
      for (int i = 0; i < ls.length; i += 3) {
        if (i > 0) r.append('\n');
        r.append("print \"\"\"");
        for (int j = i; j < Math.min(ls.length, i + 3); j++) {
          if (j > i) r.append('\n');
          r.append(ls[j]);
        }
        r.append("\"\"\"");
      }
      r.append('\n');
      return r.toString();
    }
    case 22: { // LLVMAsm(pre, suf)
      String pre = rs(), suf = rs();
      int bsz = s.getBytes(U).length;
      StringBuilder r = sb();
      r.append("@s=global[").append(bsz + 1).append(pre);
      for (int i = 0; i < s.length(); i++) {
        char c = s.charAt(i);
        if (c == '\\' || c == '"' || c == '\n' || c == '\t') r.append(String.format("\\%02x", (int) c));
        else r.append(c);
      }
      r.append(suf);
      return r.toString();
    }
    case 23: { // HashDelim(pre, suf, initH, maxOne) - Koka & Gluon
      String pre = rs(), suf = rs(), h = rs();
      int m = ri();
      if (m == 0) { while (s.indexOf("\"" + h) >= 0) h += "#"; }
      else if (s.indexOf("\"" + h) >= 0) h += "#";
      return pre + h + "\"" + s + "\"" + h + suf;
    }
    case 25: { // K
      byte[] bs = s.getBytes(U);
      StringBuilder r = sb();
      for (int i = 0; i < bs.length; ) {
        if (i > 0) r.append('\n');
        int u = bs[i] & 255;
        boolean ok = u == 10 || (u >= 32 && u <= 126);
        int j = i, lim = ok ? 250 : 80;
        while (j < bs.length && j - i < lim) {
          int c = bs[j] & 255;
          if ((c == 10 || (c >= 32 && c <= 126)) == ok) j++;
          else break;
        }
        if (ok) r.append("`1:\"").append(esc(new String(bs, i, j - i, U))).append('"');
        else {
          r.append("`1:`c$");
          if (j - i == 1) r.append(',').append(bs[i] & 255);
          else for (int k = i; k < j; k++) r.append(k > i ? " " : "").append(bs[k] & 255);
        }
        i = j;
      }
      return r.append("\n\\\\\n").toString();
    }
    case 26: { // EscLineWrap(cpre, csuf, join, suf, maxLen, escTab) - Hope & HOC
      String cp = rs(), cs = rs(), jn = rs(), suf = rs();
      int ml = ri(), et = ri();
      StringBuilder r = sb(), b = sb();
      boolean f = true;
      for (int i = 0; i < s.length(); i++) {
        char c = s.charAt(i);
        String q = c == '\\' ? "\\\\" : c == '"' ? "\\\"" : c == '\n' ? "\\n" : (et != 0 && c == '\t') ? "\\t" : String.valueOf(c);
        if (b.length() + q.length() > ml) { if (!f) r.append(jn); f = false; r.append(cp).append(b).append(cs); b.setLength(0); }
        b.append(q);
      }
      if (b.length() > 0) { if (!f) r.append(jn); r.append(cp).append(b).append(cs); }
      return r.append(suf).toString();
    }
    case 27: { // GPortugol
      String pre = rs();
      StringBuilder r = sb(pre);
      for (String l : lines(s)) {
        String c = chomp(l);
        r.append("imprima(");
        if (c.isEmpty()) r.append("\"\"");
        else {
          for (int i = 0; i < c.length(); i += 500) {
            if (i > 0) r.append(',');
            r.append('"').append(esc(c.substring(i, Math.min(c.length(), i + 500))).replace("\t", "\\t")).append('"');
          }
        }
        r.append(");");
      }
      r.append("fim\n");
      return r.toString();
    }
    case 28: { // Gosu
      String a = rs(), b = rs();
      String[] ps = s.split("\u00ed", -1);
      StringBuilder r = sb();
      for (int i = 0; i < ps.length; i++) {
        if (i > 0) r.append(a);
        String x = ps[i];
        for (int j = 0; j < x.length(); j += 15000) {
          r.append(b).append(esc(x.substring(j, Math.min(x.length(), j + 15000))).replace("$", "\\$").replace("<%", "<\"+\"%")).append("\"));");
        }
      }
      return r.toString();
    }
    case 31: { // GNUAPL
      String t = chomp(s);
      StringBuilder r = sb();
      for (int i = 0; i < t.length(); i += 30000) {
        String c = t.substring(i, Math.min(t.length(), i + 30000));
        r.append("\u235e\u2190");
        boolean first = true;
        for (int j = 0; j < c.length(); ) {
          if (!first) r.append(',');
          first = false;
          char h = c.charAt(j);
          if (h < 32 || h == 127) {
            r.append("(\u2395UCS ").append((int) h).append(')');
            j++;
          } else {
            int k = j;
            while (k < c.length() && c.charAt(k) >= 32 && c.charAt(k) != 127) k++;
            r.append('\'').append(dbl(c.substring(j, k), '\'')).append('\'');
            j = k;
          }
        }
        r.append('\n');
      }
      r.append(")OFF\n");
      return r.toString();
    }
    case 32: { // GeneratorScriptingLanguage
      String h = rs(), e0 = rs(), s0 = rs(), s1 = rs(), ft = rs();
      String[] ls = s.split("\n", -1);
      StringBuilder r = sb(h);
      for (int i = 0; i < ls.length; i++) {
        if (i > 0) r.append('\n');
        String l = ls[i];
        ArrayList<String> gc = al();
        for (int j = 0; j < l.length(); j += 200) {
          String g = l.substring(j, Math.min(l.length(), j + 200));
          for (int k = 0; k < g.length(); ) {
            char x = g.charAt(k);
            if (x == '\\') { gc.add("bs"); k++; }
            else if (x == '"') { gc.add("'\"'"); k++; }
            else if (x == '$') { gc.add("\"$\""); k++; }
            else {
              int u = k;
              while (u < g.length() && g.charAt(u) != '\\' && g.charAt(u) != '"' && g.charAt(u) != '$') u++;
              gc.add("\"" + g.substring(k, u) + "\"");
              k = u;
            }
          }
        }
        if (gc.isEmpty()) r.append(e0);
        else {
          r.append(s0).append(gc.get(0));
          for (int k = 1; k < gc.size(); k++) r.append(s1).append(gc.get(k));
          r.append("\n$(s:no)");
        }
      }
      return r.append(ft).toString();
    }
    case 33: { // FishEsolang
      int q = s.getBytes(U).length % 64;
      String rev = sb(s).reverse().toString();
      StringBuilder r = sb("\\\n");
      String[] k = {"\n", "\""}, v = {"\"a\"", "\"b3*1+\""};
      for (int i = 0; i < rev.length(); i += 1000) {
        if (i > 0) r.append('\n');
        r.append("\\\"").append(rep(rev.substring(i, Math.min(rev.length(), i + 1000)), k, v)).append('"');
      }
      r.append('\n');
      if (q > 0) { r.append('\\'); for (int i = 0; i < q; i++) r.append('o'); r.append('\n'); }
      r.append(">l?!;");
      for (int i = 0; i < 64; i++) r.append('o');
      return r.toString();
    }
    case 34: { // EC & Yabasic (V[s, a, z])
      String pre = rs(), suf = rs(), a = rs(), z = rs();
      int cl = ri();
      if (cl == 0) {
        return pre + bsl(esc(s), a, z) + suf;
      }
      StringBuilder r = sb(pre);
      for (int i = 0; i < s.length(); i += cl) {
        String c = "\"" + esc(s.substring(i, Math.min(s.length(), i + cl))) + "\"";
        r.append("f(").append(bsl(c, a, z)).append(",0);");
      }
      r.append(suf);
      return r.toString();
    }
    case 35: { // Chapel_Chef(pre, suf)
      String pre = rs(), suf = rs();
      String q = (s.contains("'''") || s.endsWith("'")) ? "\"\"\"" : "'''";
      return pre + q + s + q + suf;
    }
    case 37: { // BefungeLang
      StringBuilder r = sb();
      Matcher m = mt("[\\x21\\x23-\\x7e]+|.",s);
      while (m.find()) {
        String f = m.group();
        if (f.length() == 1) {
          r.append(f.equals("\n") ? "a," : "'" + f + ",");
        } else {
          for (int i = 0; i < f.length(); i += 226) {
            String u = f.substring(i, Math.min(f.length(), i + 226));
            if (u.length() == 1) r.append('\'').append(u).append(',');
            else {
              int mm = u.length() - 1;
              String nn = mm < 16 ? Integer.toHexString(mm)
                : (mm % 15 == 0 ? Integer.toHexString(mm / 15) + "f*"
                : Integer.toHexString(mm / 15) + "f*" + Integer.toHexString(mm % 15) + "+");
              r.append('"').append(sb(u).reverse()).append('"').append(nn).append("k,");
            }
          }
        }
      }
      r.append('@');
      return r.toString();
    }
    case 39: { // ATS
      String[] ps = s.split("(?<=\\?)(?=\\?)", -1);
      StringBuilder r = sb(rs());
      for (int i = 0; i < ps.length; i++) {
        if (i > 0) r.append(';');
        r.append("print(\"").append(esc(ps[i])).append("\")");
      }
      return r.append(')').toString();
    }
    case 40: { // ArnoldC
      String a = rs(), b = rs(), c = rs(), d = rs(), e0 = rs(), f0 = rs();
      String[] ls = lines(s);
      int g = (ls.length + 1999) / 2000;
      StringBuilder r = sb(a);
      for (int i = 0; i < g; i++) r.append(b).append(i).append('\n');
      r.append(c);
      for (int i = 0; i < g; i++) {
        r.append(d).append(i).append('\n');
        int e = Math.min(ls.length, (i + 1) * 2000);
        for (int j = i * 2000; j < e; j++) {
          if (j > i * 2000) r.append('\n');
          r.append(e0).append(chomp(ls[j])).append('"');
        }
        r.append(f0);
      }
      return r.toString();
    }
    case 42: { // ALGOL60
      String a = rs(), b = rs(), c = rs(), d = rs(), e = rs(), f = rs();
      ArrayList<String> ap = al();
      Matcher m = mt(a, s);
      while (m.find()) ap.add(b + esc(m.group()).replace("\t", "\\t") + "\");");
      return procs(ap, 400, c, d, e, f, "\n", "p", "\nend\n", 0);
    }
    case 43: { // Aplus
      String a = rs(), b = rs(), c = rs();
      StringBuilder r = sb(a);
      int n = s.length();
      boolean f = true;
      for (int i = 0; i < n; ) {
        if (s.charAt(i) == '\n') { if (!f) r.append(b); f = false; r.append("\"\\n\""); i++; }
        else {
          int j = i;
          while (j < n && s.charAt(j) != '\n') j++;
          for (int k = i; k < j; k += 30000) { if (!f) r.append(b); f = false; r.append('\'').append(dbl(s.substring(k, Math.min(j, k + 30000)), '\'')).append('\''); }
          i = j;
        }
      }
      return r.append(c).toString();
    }
    case 44: { // RePair VMs: mode 0=Asm6502, 2=Uxntal
      int mode = ri();
      String hdr = rs();
      int[] rng = new int[159];
      int k = 0;
      for (int i = 127; i <= 255; i++) rng[k++] = i;
      for (int i = 1; i <= 9; i++) rng[k++] = i;
      for (int i = 11; i <= 31; i++) rng[k++] = i;
      byte[][] res = rp(s.getBytes(U), rng);
      byte[] t = res[0], w = res[1];
      int np = w.length / 2, dp = np + 1;
      byte[] d0 = new byte[dp], d1 = new byte[dp];
      for (int i = 0; i < np; i++) {
        int idx = i >= 138 ? i + 1 : i;
        d0[idx] = w[(np - 1 - i) * 2];
        d1[idx] = w[(np - 1 - i) * 2 + 1];
      }
      StringBuilder r = sb(hdr);
      if (mode == 2) {
        for (int i = 0; i < dp; i++) {
          if (i > 0 && (i * 2) % 120 == 0) r.append('\n');
          else if (i > 0) r.append(' ');
          r.append(String.format("%02x %02x", d0[i] & 255, d1[i] & 255));
        }
        r.append("\n@s\n");
        for (int i = 0; i < t.length; i++) {
          if (i > 0 && i % 120 == 0) r.append('\n');
          else if (i > 0) r.append(' ');
          r.append(String.format("%02x", t[i] & 255));
        }
        r.append(" 00\n");
      } else {
        byt(r, d0, dp);
        r.append("\ndict1:\n");
        byt(r, d1, dp);
        r.append("\nmsg:\n");
        byt(r, t, t.length + 1);
        r.append('\n');
      }
      return r.toString();
    }
    case 45: { // VisualBasic_WebAssemblyText_Whitespace(p1, p2, p3)
      String p1 = rs(), p2 = rs(), p3 = rs();
      int pages = (s.getBytes(U).length + 4200) / 65536 + 1;
      return p1 + dbl(s, '"').replace("\n", "\"& VbLf &\"") + p2 + pages + p3;
    }
    case 46: { // Underload_Unlambda
      int n = s.length(), b = 32 - Integer.numberOfLeadingZeros(n);
      StringBuilder r = sb("(`)");
      for (int i = 0; i < b; i++) {
        if (((n >> i) & 1) == 1) r.append(":S");
        if (i + 1 < b) r.append(":*");
      }
      r.append("!(");
      for (int i = 0; i < n; i++) {
        char c = s.charAt(i);
        if (c == '\n') r.append('r');
        else r.append('.').append(c);
      }
      r.append("k)S");
      return r.toString();
    }
    case 47: { // UCBLogo
      String a = rs(), b = rs(), c0 = rs(), d = rs();
      ArrayList<String> o = al();
      int n = s.length();
      for (int i = 0; i < n; i += 12000) {
        String y = s.substring(i, Math.min(n, i + 12000));
        for (int j = 0; j < y.length(); ) {
          char c = y.charAt(j);
          if ("\"|\\\n".indexOf(c) >= 0) { o.add(a + (int) c); j++; }
          else {
            int k = j;
            while (k < y.length() && "\"|\\\n".indexOf(y.charAt(k)) < 0) k++;
            o.add(b + y.substring(j, k) + "|]");
            j = k;
          }
        }
      }
      StringBuilder r = sb();
      int sum = 0;
      boolean f = true;
      for (String x : o) {
        if (!f && sum + x.length() > 24000) { r.append(")\n"); f = true; sum = 0; }
        r.append(f ? c0 : " ").append(x);
        f = false;
        sum += x.length();
      }
      if (!f) r.append(')');
      return r.append(d).toString();
    }
    case 48: { // Taxi(d1, d2, r0, r1, r2, r3, r4)
      String d1 = rs(), d2 = rs(), r0 = rs(), r1 = rs(), r2 = rs(), r3 = rs(), r4 = rs();
      ArrayList<String> tp = al();
      int n = s.length();
      for (int i = 0; i < n; ) {
        if (s.charAt(i) == '"') { tp.add("\""); i++; }
        else {
          int j = i;
          while (j < n && s.charAt(j) != '"') j++;
          tp.add(s.substring(i, j));
          i = j;
        }
      }
      StringBuilder r = sb();
      for (int i = 0; i < tp.size(); i++) {
        if (i > 0) r.append('\n');
        String x = tp.get(i);
        if (x.equals("\"")) r.append(d1);
        else r.append('"').append(xf(x, 193)).append('"').append(d2);
      }
      r.append('\n').append(r0).append('\n');
      for (int i = 0; i < tp.size(); i++) {
        if (i > 0) r.append('\n');
        r.append(tp.get(i).equals("\"") ? r1 : r2);
        if (i < tp.size() - 1) r.append(r3);
      }
      r.append('\n').append(r4);
      return r.toString();
    }
    case 49: { // SNOBOL4
      String a = rs(), b = rs(), c0 = rs(), d = rs(), e = rs();
      String[] ls = lines(s);
      StringBuilder r = sb();
      for (int i = 0; i < ls.length; i++) {
        if (i > 0) r.append('\n');
        String c = chomp(ls[i]);
        ArrayList<String> sc = al();
        for (int j = 0; j < c.length(); j += 200) {
          String p = c.substring(j, Math.min(c.length(), j + 200));
          for (int k = 0; k < p.length(); ) {
            boolean q = p.charAt(k) == '\'';
            int u = k;
            while (u < p.length() && (p.charAt(u) == '\'') == q) u++;
            char g = q ? '"' : '\'';
            sc.add(g + p.substring(k, u) + g);
            k = u;
          }
        }
        if (sc.isEmpty()) r.append(a);
        else {
          r.append(b);
          for (int k = 0; k < sc.size(); k++) { if (k > 0) r.append('\n'); r.append(c0).append(sc.get(k)); }
          r.append(d);
        }
      }
      return r.append(e).toString();
    }
    case 50: { // Simula
      String a = rs(), b = rs(), c = rs(), d = rs(), e = rs(), f = rs(), g = rs(), h = rs();
      ArrayList<String> cp = al();
      for (String l : lines(s)) {
        String x = chomp(l);
        for (int i = 0; i < x.length(); ) {
          if (x.charAt(i) == '\t') { cp.add(a); i++; }
          else {
            int j = i;
            while (j < x.length() && x.charAt(j) != '\t') j++;
            for (int k = i; k < j; k += 2000) cp.add(b + dbl(x.substring(k, Math.min(j, k + 2000)), '"') + "\");");
            i = j;
          }
        }
        cp.add(c);
      }
      return procs(cp, 400, d, e, f, g, h, "P", "\nEnd\n", 0);
    }
    case 53: { // Scheme(suf)
      String suf = rs();
      String t = s.replace(":", ":c").replace("\"", ":q");
      for (int i = 9; i >= 0; i--) {
        char[] bs = new char[1 << i];
        Arrays.fill(bs, '\\');
        t = t.replace(new String(bs), ":" + i);
      }
      return "(define s \"" + t + suf;
    }
    case 54: { // Glass
      String a = rs(), b = rs(), c = rs();
      String[] ps = s.split("\"", -1);
      StringBuilder r = sb(a);
      for (int i = 0; i < ps.length; i++) {
        if (i > 0) r.append(b);
        if (!ps[i].isEmpty()) r.append('"').append(ps[i].replace("\\", "\\\\").replace("\n", "\\n")).append(c);
      }
      return r.append("]}").toString();
    }
    default: throw new RuntimeException("bad op " + op);
  }
}

static void init() throws Exception {
  int[] t = new int[128];
  for (int i = 33, k = 0; i <= 126; i++) if (i != 34 && i != 92 && i != 58) t[i] = k++;
  ByteArrayOutputStream bo = new ByteArrayOutputStream();
  int v = -1, b = 0, nb = 0;
  for (String x : B) for (int i = 0; i < x.length(); i++) {
    int c = t[x.charAt(i)];
    if (v < 0) v = c;
    else {
      v += c * 91; b |= v << nb; nb += (v & 8191) > 88 ? 13 : 14;
      do { bo.write(b & 255); b >>= 8; nb -= 8; } while (nb > 7);
      v = -1;
    }
  }
  if (v >= 0) bo.write((b | v << nb) & 255);
  InflaterInputStream in = new InflaterInputStream(new ByteArrayInputStream(bo.toByteArray()));
  ByteArrayOutputStream out = new ByteArrayOutputStream();
  byte[] buf = new byte[8192];
  int n;
  while ((n = in.read(buf)) > 0) out.write(buf, 0, n);
  D = out.toByteArray();
  P = 0;
  E = rs();
}

static String self() {
  StringBuilder q = sb();
  q.append("import java.io.*;import java.util.*;import java.util.regex.*;import java.util.zip.*;\npublic class QR{public static void main(String[]a){}}\naspect Q{\nstatic String[]B={\n");
  for (int i = 0; i < B.length; i++) {
    if (i > 0) q.append(",\n");
    q.append('"').append(B[i]).append('"');
  }
  q.append("\n};\n").append(E);
  return q.toString();
}

before():execution(void QR.main(..)){
  try {
    init();
    String s = self();
    int steps = ri();
    for (int i = 0; i < steps; i++) s = step(s);
    System.out.write(s.getBytes(U));
    System.out.flush();
  } catch (Exception e) { throw new RuntimeException(e); }
}
}
