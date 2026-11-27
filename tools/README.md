# Helper Tools

Small standalone utilities used alongside `src/`:

- `relay_ui.py` — Live ANSI terminal visualizer (`CMD` entrypoint in `Dockerfile` and `make watch` target). Renders an animated ExaCortex ring-and-dot mark, spinning 256-step A–Z dial, log-scale payload sparkline, milestone badges, live generated-source peek, and bold `256` completion card when interactive (`-it`); hands off cleanly via `os.execvp` to unmodified `make check -j 10000` (detaching interactive TTY stdin to `/dev/null`) in non-TTY / `CI=true` / `NO_COLOR` / `--plain` mode. Supports `--demo` for a fast preview.
- `langs_png.py` — Renders `langs.png` (`256-Language Strict A–Z Uroboros Wheel`) from `LANGUAGES.md` using pure Python `PIL` (`mame/quine-relay` in near-black, additions in this fork in rust, centered on the ExaCortex mark).
- `render_payload_chart.py` — Renders `assets/payload-curve.png` from measured 256-step byte sizes (log scale, `< 64 KiB` ROM ceiling shaded).
- `render_demo_gif.py` — Renders `assets/terminal-demo.gif` previewing the live terminal visualizer across key A–Z milestones.
- `dupcheck.rb` — Static check on `src/code-gen.rb` verifying that every `CodeGen` class has a unique class name and unique intermediate source filename (`QR.*`, never colliding with `QR.rb`/`QR2.rb`) so `make` never silently drops a dependency.
- `zonemap.rb` — Evaluates the composed relay generator in a single pass (run inside `src/` after the `*-boot.dat` files exist) and writes CSV to stdout (`run,class,languages,bytes,backslashes,dquotes,squotes,newlines,max_line`) showing the payload each step must embed.
- `gen_uroboros_txt.py` — Pure-stdlib Python 3 SVG rasterizer that builds the scaled `src/uroboros.txt` ASCII template directly from `src/uroboros.svg`.
- `squash-installs.rb` — Squashes consecutive `RUN` directives from `src/extra-installs/*.txt` into subshell-isolated `( ... )` chains per file (leaving `ENV`/`COPY` intact) so `Dockerfile` stays well below Docker's overlay2 layer limit.
