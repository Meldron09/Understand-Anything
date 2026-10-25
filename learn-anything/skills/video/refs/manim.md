# Manim Community Edition renderer

Loaded only when the unit's renderer is `manim`. It produces one silent 1280x720, 30 fps clip per scene; narration, captions and assembly are shared (`narrate.md`, `assemble.md`).

## Fit

Math, geometry, simple 3D, hand-sketch-style reasoning, algorithm and data-structure traces: axes and plots, vectors, transforms, equations, arrays and trees stepping through states. Poor fit: long prose, code diffs, dense diagrams (a later renderer takes those).

## Install and probes (tier 2)

Needs `uv`, `ffmpeg`, cairo and pkg-config. `scripts/preflight` reports all four (`cairo`, `pkg_config`, `ffmpeg`, `uv`) and `plan gate` refuses without them. Never install: print `brew install cairo pkg-config` (about 60 MB) and `brew install ffmpeg`. Manim itself is provisioned by `uv` on first render, pinned `manim[typst]==0.22.0` (Typst for math, so LaTeX is never required), into `<data>/uv`, never the plugin dir or the lesson folder. Use `Text` for words and the Typst-based `MathTypst` for formulas.

## Headless

Unknown. Manim's default renderer opens no window, but the docs say nothing about a restricted sandbox. This is a flag, not a gate: try the smoke render and let it fail if it will.

## Scene script (`work/scenes/sNN.py`, under 30 lines)

```python
from manim import *

DURATION = 0  # baked from timing.json by `plan bake`; leave this exact line shape
config.background_color = "#111827"
INK, A, B, FONT = "#F9FAFB", "#60A5FA", "#FBBF24", "Helvetica Neue"


class Clip(Scene):  # the class is always called Clip
    def construct(self):
        title = Text("Three-way handshake", font=FONT, color=INK).scale(0.9).to_edge(UP, buff=0.6)
        client = Square(color=A).shift(LEFT * 4)
        server = Square(color=B).shift(RIGHT * 4)
        self.play(Write(title), Create(client), Create(server), run_time=2)
        arrow = Arrow(client.get_right(), server.get_left(), color=INK)
        self.play(GrowArrow(arrow), run_time=1.5)
        self.wait(max(0.1, DURATION - self.renderer.time))  # hold to D; assembly trims or holds anyway
```

One idea per script, built from the storyboard's `visual:` line only; never paste the narration on screen. Total animation time should land near `DURATION`; a mismatch is fine, assembly corrects it. Keep text inside the 0.6 unit margin and at most 3 lines.

## Render command (one scene to one clip)

Run by `render clips` under `sh -c` in `work/`, with `$ID`, `$SCENE`, `$OUT` set. Pass it as one quoted argument (replace `<data>`):

```
UV_CACHE_DIR=<data>/uv uv run --python 3.12 --with "manim[typst]==0.22.0" manim -r 1280,720 --fps 30 --disable_caching --media_dir media/$ID $SCENE Clip && cp "$(find media/$ID/videos -name '*.mp4' ! -path '*partial_movie_files*' | head -n 1)" $OUT
```

`clips/$ID.log` keeps the output; read it to repair a failing script.

## Pitfalls

- Fonts: a missing `Helvetica Neue` falls back silently to Pango's default; the look stays coherent only on macOS.
- `MathTex` and `Tex` need LaTeX; do not use them. Spell formulas with Typst or plain `Text`.
- The first render per machine downloads and builds the Manim environment (minutes); `s01` pays it, which is why it renders alone first.
- Do not name two scene classes in one file; `Clip` only.
- 3D scenes (`ThreeDScene`) render several times slower; keep them to one idea.

## Unknowns pending a Mac spike

Sandbox behaviour, real render time per minute of output, the `manim[typst]` extra name at this pin, the output folder layout under `--media_dir`, parallel scene jobs sharing one `uv` cache.
