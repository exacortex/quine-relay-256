# Helper Tools

Small standalone utilities used alongside `src/`:

- `langs_png.py` — Renders `langs.png` (`256-Language Uroboros Quine`) from `src/code-gen.rb` and `src/uroboros.svg` using Python `pycairo` and `rsvg-convert`, without needing the Ruby `cairo`/`rsvg2` gems. Languages inherited from `mame/quine-relay` are drawn in black; languages added in this fork are drawn in red.
- `dupcheck.rb` — Static check on `src/code-gen.rb` verifying that every `CodeGen` class has a unique class name and unique intermediate source filename (`QR.*`, never colliding with `QR.rb`/`QR2.rb`) so `make` never silently drops a dependency.
- `zonemap.rb` — Evaluates the composed relay generator in a single pass (run inside `src/` after the `*-boot.dat` files exist) and writes CSV to stdout (`run,class,languages,bytes,backslashes,dquotes,squotes,newlines,max_line`) showing the payload each step must embed.
- `gen_uroboros_txt.py` — Pure-stdlib Python 3 SVG rasterizer that builds the scaled `src/uroboros.txt` ASCII template (`#` code cells, ` ` dragon silhouette) directly from `src/uroboros.svg`.
- `squash-installs.rb` — Squashes consecutive `RUN` directives from `src/extra-installs/*.txt` into subshell-isolated `( ... )` chains per file (leaving `ENV`/`COPY` intact) so `Dockerfile` stays well below Docker's overlay2 layer limit.
