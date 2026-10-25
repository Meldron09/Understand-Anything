# learn-anything

Claude Code plugin: one command, `/learn-anything:learn [topic | URL | file | lesson-slug]`, teaches you a concept from your sources and checks that it worked. Free and local: no paid APIs, no generative video.

## Install

```
/plugin install learn-anything --marketplace Meldron09/Understand-Anything
```

Or try it from a checkout: `claude --plugin-dir ./learn-anything`. Marketplace packaging is recorded in [ADR 0006](../docs/adr/0006-marketplace-packaging.md).

## What it does

`/learn-anything:learn` interviews you (depth, level, goal, time, modes), ingests your sources, plans a lesson sized to your time, produces one artifact per unit and ends with a short comprehension check (`check.md`). Everything lands in `./learn-anything/<lesson-slug>/`; rerunning the same slug resumes from the files on disk. The plugin never installs system tools: it prints the command and you run it.

## Dependency tiers

`scripts/preflight` reports these before the modes question and again before each render, and writes `preflight.md` in the lesson folder.

| Tier | Needs | Unlocks |
|---|---|---|
| 0 | nothing | text, slides (`.md`), interactive, quiz |
| 1 | `uv` | URL, local HTML and PDF sources; kokoro narration |
| 2 | tier 1 plus `ffmpeg`, cairo and `pkg-config` | narrated video, Manim renderer |
| 3 | tier 2 plus Node 22+ and a headless Chromium (opt-in) | HyperFrames renderer; Chromium also upgrades HTML verification |

Soft extras: `marp` or `npx` (renders slides to HTML), Chrome (slides PDF), `pdftotext` (PDF text), an `ffmpeg` with the `subtitles` filter (soft captions), `say` (fallback voice on macOS). Topic, text, Markdown and code sources need only `shasum`, `date` and `python3`; a URL also needs `curl`.

## Modes: requirements and degradation

Degradation is per lesson unit, always announced and recorded as `degraded: <reason>` in `plan.md` and the closing summary, never silent. A unit that fails is re-run once as a text explainer with the same time budget; text is the floor.

| Mode | Needs | What it degrades to |
|---|---|---|
| text | nothing (a scanned PDF read natively needs `uv`) | the floor. If it fails too, the unit is `failed: <reason>` and you are told |
| slides | nothing to write the Marp deck | no `marp`/`npx`: the `.md` deck ships with `rendered=none` (still `done`). No Chrome: HTML only, no PDF. Mermaid diagrams ship as source (`diagrams=raw`, measured with marp-cli 4.5.1); that is noted, not a degradation |
| interactive | nothing; a headless Chromium only adds a DOM check | a page that fails verification is deleted and the unit becomes a text explainer. Without Chromium the footer says `not browser-tested` |
| quiz | nothing; Chromium only adds a DOM check | a page that fails verification becomes a Markdown quiz with an answers section (`degraded`, still a quiz) |
| video | `uv` and `ffmpeg`; Manim also needs cairo and `pkg-config`; HyperFrames needs Node 22+ and Chromium | see below |

### Video

The router picks a renderer per unit from `shared/renderers.md`: Manim for math, geometry, simple 3D and algorithm traces (no fallback); HyperFrames for processes, diagrams, definitions, data charts and code walkthroughs (falls back to Manim). A fallback is never a higher tier than its pick.

- Renderer tier missing at plan time: the unit is downgraded to the fallback with a note, or, when neither renderer is usable, flagged `predicted:` and offered once at the plan gate (install, or downgrade).
- A scene that fails is rewritten once with the fallback renderer, then becomes a blank scene (flat clip, audio and caption intact, `degraded: sNN blank`). More than half the scenes blank, or the first scene failing on both renderers: the unit is `failed` and re-runs as text.
- Narration: kokoro (`uv`, about 350 MB of weights fetched once into the plugin data folder, covered by the plan gate's consent), then macOS `say` (every scene re-synthesised, so one voice), then silent video with a narration script file beside the mp4.
- No `ffmpeg`: the unit fails at once to text.
- Captions: a sidecar `.srt` always; also a soft track when the ffmpeg `subtitles` probe passes (`captions=soft`). No burn-in.
- Cost: the plan gate shows units, subagents, video minutes, tier and download size. HyperFrames runs name the macOS frame-spill risk (about 25 GB of raw frames per output minute unless frame streaming is on, which the skill turns on).

Caps: at most 8 units and 5 minutes of video per plan; an over-cap plan goes back to you to cut, never silently shrunk.

## Development

```
sh learn-anything/scripts/lint-skills learn-anything     # line caps, descriptions, paths
claude plugin validate --strict learn-anything           # plugin manifest
claude plugin validate --strict .                        # marketplace manifest
for t in lint-skills preflight plan-gate verify-html ingest resume degrade video router; do sh tests/$t/run.sh; done
```

CI (`.github/workflows/ci.yml`) runs exactly these. The suites that call `claude` (check, interactive, quiz, slides, tracer, the ingest end-to-end scripts) are run by hand. Open items and the Mac measurement runbook: [`docs/spec/mac-spike.md`](../docs/spec/mac-spike.md).
