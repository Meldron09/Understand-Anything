# HyperFrames renderer

Loaded only when the unit's renderer is `hyperframes` (Apache-2.0, HeyGen). It produces one silent 1280x720, 30 fps clip per scene from a small HTML composition; narration, captions and assembly are shared (`narrate.md`, `assemble.md`). Its fallback is Manim (`refs/manim.md`), used per scene, never per unit.

## Fit

Processes and mechanisms (pipelines, request lifecycles, state changes), kinetic-type definitions and recaps, diagram reveals, comparisons, data and chart stories, code walkthroughs and diffs (a terminal session is a styled block in a scene). Poor fit: equation derivations (Manim), hand-drawn whiteboard style, long prose.

## Install and probes (tier 3)

Needs `ffmpeg`, Node 22+ and a headless Chromium; `scripts/preflight` reports `node22` and `chromium`, and `plan gate hyperframes` refuses without them. Never install: print `brew install node` (about 80 MB) and `brew install --cask google-chrome` (about 250 MB), plus `brew install ffmpeg`. HyperFrames itself is fetched by `npx` on first render at the exact pin `hyperframes@0.8.193` (never `latest`: it is pre-1.0 with several releases a day), with the npm cache in `<data>/npm`, never the plugin dir or the lesson folder. Its own browser helper may cache a Chrome under `~/.cache/hyperframes`; that is outside our control.

## Switches (every render command carries all three)

- Telemetry off: `HYPERFRAMES_NO_TELEMETRY=1 DO_NOT_TRACK=1` (it is on by default and reports the agent name).
- Frame streaming on: `HF_CAPTURE_PARALLEL_STREAM=true`. On macOS multi-worker capture writes raw frames to disk, about 25 GB per minute at 1080p30, unless streaming is on or there is one worker. The consent text names this; we also pass `--workers 1`.
- Offline: no network fetches in a scene (no CDN script, font or image URL).

## Headless

Unknown. The CLI is headless by design but needs a Chrome binary; behaviour in a restricted Claude Code sandbox is not documented. A flag, not a gate: the smoke render of `s01` finds out.

## Scene script (`work/scenes/sNN.html`, under 30 lines)

```html
<!doctype html>
<html><head><meta charset="utf-8"><style>
  html, body { margin: 0; width: 1280px; height: 720px; background: #111827; color: #F9FAFB; font-family: "Helvetica Neue", sans-serif; }
  #stage { position: relative; width: 1280px; height: 720px; padding: 0.6in; box-sizing: border-box; }
  h1 { font-size: 56px; margin: 0; animation: in 1s both; }
  .box { position: absolute; top: 300px; width: 240px; height: 120px; border: 4px solid #60A5FA; animation: in 1s 1.5s both; }
  @keyframes in { from { opacity: 0; transform: translateY(24px) } to { opacity: 1; transform: none } }
</style></head><body>
<div id="stage" data-composition-id="clip" data-start="0" data-duration="0" data-width="1280" data-height="720">
  <h1>Three-way handshake</h1>
  <div class="box" style="left: 120px"></div><div class="box" style="left: 920px; border-color: #FBBF24"></div>
</div>
<script>
DURATION = 0
</script>
</body></html>
```

CSS animations and WAAPI only, no GSAP (it is loaded from a CDN in HyperFrames' own examples) and no `Date.now()`, unseeded `Math.random()`, timers, `repeat: -1` or fetches: everything visible is a function of timeline time. The two baked spots are `data-duration="0"` on the root only and the exact line `DURATION = 0` (`plan bake` rewrites both). One idea per scene from the storyboard's `visual:` line; never paste the narration. Style block as in SKILL.md, at most 3 lines of text, 0.6 inch margin.

## Render command (one scene to one clip)

Run by `render clips` under `sh -c` in `work/`, with `$ID`, `$SCENE`, `$OUT` set; pass it as one quoted argument (replace `<data>`), with `html` as the scene extension:

```
HYPERFRAMES_NO_TELEMETRY=1 DO_NOT_TRACK=1 HF_CAPTURE_PARALLEL_STREAM=true npm_config_cache=<data>/npm npx --yes hyperframes@0.8.193 render --composition $SCENE --workers 1 --output $OUT
```

`clips/$ID.log` keeps the output; when a scene fails, read it (`npx hyperframes@0.8.193 check --json $SCENE` lints the contract).

## Pitfalls

- A scene that renders only a blank frame usually broke the contract (an unseeded random, a timer, a network URL): read the log, then let the fallback take it.
- Do not use the vendor's slideshow (a live deck; `render` keeps only its first slide) or the `/hyperframes:hyperframes` plugin skills: they ask a HeyGen sign-in question and own narration.
- `--low-memory-mode` turns on by itself at 8 GB RAM or less; renders are slower, not wrong.
- Each worker is a separate Chrome (about 256 MB); scene jobs run `min(2, cores/4)` at a time on top of `--workers 1`.

## Unknowns pending a Mac spike

Checked without rendering (ticket 49): `hyperframes@0.8.193` exists on npm (Apache-2.0), `render --help` lists `--composition`, `--workers` and `--output` (and says `render [DIR]` renders a project folder, `--composition` a file in it), `HF_CAPTURE_PARALLEL_STREAM` is read by the package, and the root attributes appear in its source. Not run: that the scene skeleton renders with those attributes (`check` and the smoke render are the authority); real render time and peak disk per minute of output; whether a sandboxed run works offline after the browser is cached; whether a CSS-only scene loses anything against GSAP (the GSAP licence is moot while scenes use no GSAP); scene-by-scene renders sharing one npm cache.
