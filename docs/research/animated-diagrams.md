# Research: animated diagrams and flowcharts (issue #4)

Question: which tools produce animated diagrams and flowcharts as video? Free/OSS and local only. Researched 2026-10-24 from primary sources only (repos, official docs, package registries, license files). Nothing was installed or rendered, so every claim about sample-output quality is **not verified locally**. Where a primary source is silent the cell says **unknown**.

Vocabulary follows `CONTEXT.md`: a **renderer** turns a lesson plan into a **lesson artifact**; this ticket picks the renderer for the animated-diagram category.

## Candidates

1. **Manim Community Edition** (ManimCE), Python.
2. **ManimGL** (3b1b/manim), Python, OpenGL.
3. **Motion Canvas**, TypeScript, editor-driven.
4. **Revideo**, TypeScript, Motion Canvas derivative with a headless API.
5. **Remotion**, React.
6. **D2** (diagram language that exports animated SVG/GIF), included as a flowchart-specific tool rather than a general animation engine.

Mermaid was not evaluated: it is a static diagram renderer and D2's docs contrast it with D2 on browser dependence ([D2 exports](https://d2lang.com/tour/exports/)).

## Comparison table

| | Manim CE | ManimGL | Motion Canvas | Revideo | Remotion | D2 |
|---|---|---|---|---|---|---|
| Latest release | v0.22.0, 2026-10-08 | v1.7.2, 2024-12-13 | v3.17.2, 2024-12-14 (alpha 3.18.0, 2025-02-16) | 0.11.0, 2026-07-10 | v4.0.538, 2026-10-22 | v0.9.0, 2026-09-07 |
| Last commit | 2026-10-24 | 2026-09-09 | 2026-07-02 (docs refactor) | 2026-07-15 | 2026-10-24 | 2026-10-11 |
| License | MIT | MIT | MIT | MIT | **Source-available, not OSS** (free only for individuals, up to 3-person for-profits, non-profits; company license otherwise) | MPL-2.0 |
| Maintenance verdict | Active | Slow: releases stalled, commits continue | Stale: no stable release in ~22 months | Active, small (4.1k stars), now vendor-backed (Midrender) | Very active | Active |
| Install on macOS | `brew install cairo pkg-config` + `uv add manim`; LaTeX (MacTeX) optional | `brew install ffmpeg` + `pip install manimgl` | Node 16+, `npm init @motion-canvas@latest`, `npm install` | Node, `npm init @revideo@latest`; puppeteer dependency | Node, `npm i remotion @remotion/cli`; Chrome Headless Shell auto-downloaded on first use | Single Go binary (install method not checked) |
| Headless CLI render | Yes in practice: default Cairo renderer, no window flag needed, official Docker image and Jupyter | **Unknown**; docs mention OpenGL, nothing on headless | **Not documented**; render is the editor's RENDER button, headless is open issues #415, #1218 | **Yes**, `renderVideo()` in Node via headless browser | **Yes**, `npx remotion render` | Yes, CLI |
| Output | mp4, webm, mov, gif, png sequence | mp4 (per docs ffmpeg required) | PNG/JPEG/WebP sequence; ffmpeg plugin for video | mp4 | mp4 and others | SVG, GIF (animated), PNG, PDF, PPTX; **no mp4** |
| Animation model | Full tweened animation | Same, OpenGL | Generator-based tweens | Generator-based tweens | React frame-by-frame | Board-to-board steps at fixed interval; `animated` edge style |
| Best-fit sample quality | Math/geometry gallery; **no flowchart examples in the gallery** (not verified locally) | Same family | Unknown: homepage has no showcase videos | Unknown: one README GIF (Rubik's cube) | Unknown for diagrams | Static diagram quality good by design; animation is coarse (not verified locally) |
| Render time / cost per minute of output | **Unknown** (no primary figures); `-ql` is 854x480 at 15 fps up to 4K60 | Unknown | Unknown | Unknown; docs say a laptop is "probably fastest with one worker" | Unknown; docs give no figures | Unknown; fast static layout |
| Scenes render independently | Yes: name a Scene class on the CLI, `-a` for all, `--save_sections` | Unknown | Per scene inside one project; no CLI to do so | Yes: `range` option and `workers` split by time; one project per scene also possible | Yes: per composition, `--frames` ranges, `--concurrency` | Yes: each file/board is independent |
| Cost | Free | Free | Free | Free; anonymous PostHog render counter (disable with `DISABLE_TELEMETRY=true`) | Free for small users, paid otherwise | Free |

## Sources per candidate

### Manim CE
- Repo and license: MIT, 41.8k stars, not archived ([repo](https://github.com/ManimCommunity/manim)); `pyproject.toml` says version 0.22.0, `requires-python >=3.11`, license MIT ([pyproject](https://github.com/ManimCommunity/manim/blob/main/pyproject.toml)). Release v0.22.0 on 2026-10-08 ([releases](https://github.com/ManimCommunity/manim/releases)); PyPI lists 0.22.0 uploaded 2026-10-08 ([PyPI](https://pypi.org/project/manim/)).
- Install on macOS: Homebrew `cairo` and `pkg-config`, then `uv init`/`uv add manim`. LaTeX is optional and only needed for typeset formulas; plain text works without it ([install guide](https://github.com/ManimCommunity/manim/blob/main/docs/source/installation/uv.md)). The guide has no ffmpeg step and `pyproject.toml` depends on `av` (PyAV). I did not verify whether PyAV's wheels fully replace a system ffmpeg, so treat that as **unknown**.
- Headless: the config docs never say "headless" and only offer `--dry_run` for no-window runs ([configuration](https://docs.manim.community/en/stable/guides/configuration.html)). Evidence it runs without a display is indirect: the default Cairo renderer, the official Docker image and the hosted Jupyter/Binder badges ([README](https://github.com/ManimCommunity/manim/blob/main/README.md), [docker guide](https://github.com/ManimCommunity/manim/blob/main/docs/source/installation/docker.rst)). Restricted-sandbox behaviour is **unknown**; flag it, do not gate on it.
- CLI: `-q` l/m/h/p/k = 854x480@15 up to 3840x2160@60, `--fps`, `--format mp4|webm|mov|gif|png`, `-t` transparent, `-a` render all scenes, name a scene to render one, `--save_sections` ([configuration](https://docs.manim.community/en/stable/guides/configuration.html)).
- Diagram building blocks: `Graph`/`DiGraph` ([DiGraph](https://docs.manim.community/en/stable/reference/manim.mobject.graph.DiGraph.html)) and `Code` ([Code](https://docs.manim.community/en/stable/reference/manim.mobject.text.code_mobject.Code.html)) exist. The gallery has Basic Concepts, Animations, Plotting and Special Camera Settings, and is mostly math/geometry with no flowchart or tree examples in the portion I could read ([gallery](https://docs.manim.community/en/stable/examples.html)). The last ~23k characters of that page were not read.
- Boxes-and-arrows layout is manual (no flexbox or auto layout in what I read), so flowcharts mean Claude computing coordinates. Inference, not stated by the docs.

### ManimGL
- MIT, 95.6k stars, v1.7.2 2024-12-13, last push 2026-09-09 ([repo](https://github.com/3b1b/manim), [PyPI](https://pypi.org/project/manimgl/)). Install: Python 3.10+, `brew install ffmpeg`, `pip install manimgl`; PyOpenGL; no headless mention ([install](https://3b1b.github.io/manim/getting_started/installation.html)). The community README says the two projects are separate forks and their install steps must not be mixed ([README](https://github.com/ManimCommunity/manim/blob/main/README.md)). Not a good plugin dependency: stalled releases and an OpenGL path with unknown headless support.

### Motion Canvas
- MIT, 19.5k stars ([repo](https://github.com/motion-canvas/motion-canvas)); npm `latest` is 3.17.2 (2024-12-14), `alpha` 3.18.0-alpha.0 (2025-02-16) ([npm registry](https://registry.npmjs.org/@motion-canvas/core)). Most recent commit is a docs refactor on 2026-07-02.
- Rendering is through the editor UI: RENDER saves frames to `/output`, and you convert with ffmpeg yourself or use the `@motion-canvas/ffmpeg` exporter ([rendering](https://motioncanvas.io/docs/rendering), [video exporter](https://motioncanvas.io/docs/rendering/video)). The docs mention no CLI or headless mode; users ask for one in open issues ([#415](https://github.com/motion-canvas/motion-canvas/issues/415), [#1218](https://github.com/motion-canvas/motion-canvas/issues/1218)).
- Strength: a flexbox `Layout` system ([layouts](https://motioncanvas.io/docs/layouts)) that suits boxes-and-arrows. Weakness: stale and not scriptable. Revideo exists to fix this.

### Revideo
- MIT, v0.11.0 on 2026-07-10, last commit 2026-07-15, repo now at `midrender/revideo`, docs redirect to midrender.com ([repo](https://github.com/midrender/revideo), [npm](https://www.npmjs.com/package/@revideo/core), [README](https://github.com/midrender/revideo/blob/main/README.md)).
- README: "headless render API", parallelized rendering, "runs anywhere Node and a headless browser run", and scenes are plain TypeScript. Telemetry is a PostHog render counter, off with `DISABLE_TELEMETRY=true` ([README](https://github.com/midrender/revideo/blob/main/README.md)).
- `renderVideo()` takes `workers` (a 100 s video with 10 workers means 10 processes at 10 s each), `range`, `puppeteer.args` (for example `--no-sandbox`) and `ffmpeg.ffmpegPath` defaulting to `ffmpeg` ([renderVideo](https://github.com/midrender/revideo/blob/main/packages/docs/src/content/api-reference/renderer/renderVideo.mdx)). Frames are drawn on a canvas in the browser and encoded with WebCodecs into a silent mp4; ffmpeg handles audio only ([rendering guide](https://github.com/midrender/revideo/blob/main/packages/docs/src/content/guide/rendering-videos.mdx)). `puppeteer` is a dependency ([renderer package.json](https://github.com/midrender/revideo/blob/main/packages/renderer/package.json)); whether a system ffmpeg is mandatory for silent diagram videos is **unknown**.
- Risks: pre-1.0 (0.x), small community, ownership moved to a vendor (Midrender), docs hosting migrated. Browser download via puppeteer and the `--no-sandbox` hint suggest sandbox friction; flag, not verified.

### Remotion
- License file: free for individuals, for-profits with up to 3 employees, non-profits and evaluation; "a company license is required for for-profit organizations of a certain size"; deriving and re-selling Remotion is forbidden ([LICENSE.md](https://github.com/remotion-dev/remotion/blob/main/LICENSE.md)). GitHub reports `NOASSERTION`. This is not OSS, so it conflicts with the map's "free/OSS" constraint and would push licence obligations onto marketplace users. Disqualified as a pick.
- Technically strong: `npx remotion render <entry> <comp> out.mp4`, `--concurrency`, `--frames` ranges ([CLI render](https://www.remotion.dev/docs/cli/render)); Chrome Headless Shell auto-installed into `node_modules/.remotion/` on macOS x64/arm64 ([chrome-headless-shell](https://www.remotion.dev/docs/miscellaneous/chrome-headless-shell)); official agent skills `npx skills add remotion-dev/skills` ([skills](https://www.remotion.dev/docs/ai/skills)). No render-time figures published ([performance](https://www.remotion.dev/docs/performance)). v4.0.538 released 2026-10-22 ([releases](https://github.com/remotion-dev/remotion/releases)). The licence file also notes it changes slightly in Remotion 5.0.

### D2
- MPL-2.0, v0.9.0 on 2026-09-07, repo now `d2lang/d2` ([repo](https://github.com/d2lang/d2), [releases](https://github.com/d2lang/d2/releases)). Exports SVG, PNG, PDF, PPTX, GIF; PNG needs no external deps, unlike Mermaid; **mp4 is not listed** ([exports](https://d2lang.com/tour/exports/)).
- Animation is board stepping: `--animate-interval` packages multiple boards as one SVG or GIF that transitions at the interval in ms, GIF defaulting to 1000 ms ([d2cli source](https://github.com/terrastruct/d2/blob/master/d2cli/main.go)). The style docs list an `animated` keyword taking `true`/`false` but do not say where it applies ([style](https://d2lang.com/tour/style/)). Release notes say PNG/GIF/PDF/PPTX now use a built-in renderer, so no browser ([changelog](https://github.com/d2lang/d2/blob/master/ci/release/changelogs/next.md)).
- Output is GIF/SVG, not video, so a video lesson artifact would need an extra ffmpeg step (not researched) and has no tweened motion. Good for step-through flowcharts only.

## Notes on the checklist items the sources could not settle
- **Sample-output quality:** none judged locally. From galleries and READMEs alone: Manim's gallery is math-oriented and has no flowchart sample; Motion Canvas shows no showcase videos; Revideo shows one GIF; Remotion and D2 galleries were not reviewed. A one-hour prototype render of one box-and-arrow flow in the top two candidates is the cheapest way to close this.
- **Render time and cost per minute:** no primary source gives figures for any candidate. All are free of money cost (local CPU only).
- **Parallelism:** scene-level independence is first-class in Manim CE (one Scene class per CLI call) and Remotion (compositions, frame ranges), time-sliced in Revideo. Concatenating the resulting clips needs a separate tool (for example ffmpeg); not researched.

## Pick

**Manim Community Edition.** MIT, released 16 days ago, installs with one brew line plus `uv add manim`, renders mp4 from a plain Python CLI with no browser, and each Scene renders on its own for parallel jobs.

## Fallback

**Revideo.** MIT with a documented headless `renderVideo()` and a flexbox layout inherited from Motion Canvas, better for box-and-arrow diagrams, but pre-1.0, vendor-owned and needs Node plus a puppeteer-managed browser.

## Best-fit concept types

- Manim CE: math and equations, algorithms and data structures (graphs, trees, array/step traces), geometry, code walk-throughs, step-by-step transformations ("A becomes B").
- Revideo (fallback): layout-driven system, architecture and process flowcharts, UI-like diagrams.
- D2 (not a video pick): static or step-through flowcharts and architecture diagrams when GIF/SVG is acceptable.
- Remotion: strongest for general video composition, but excluded on licence.

## Open points for the orchestrator
- Whether the plugin should accept a manual-layout burden for flowcharts in Manim, or treat flowchart-heavy lessons as the fallback's job.
- Remotion's licence would need a legal read if it were ever reconsidered.
