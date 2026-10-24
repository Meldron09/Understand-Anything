# Research: programmatic video libraries (issue #3)

Researched 2026-10-24 against primary sources only (GitHub API/READMEs/source, official docs, license files). Constraint from map #1: free/OSS and local only; local macOS Claude Code is the primary target; headless-in-sandbox is a flag, not a gate. Nothing was installed or rendered; every "sample quality" claim is **not verified locally** and rests on the project's own gallery or README.

"unknown" means the primary sources do not establish it.

## Candidates

1. **HyperFrames** (HeyGen) - HTML/CSS/GSAP compositions rendered by headless Chrome + FFmpeg.
2. **Remotion** - React components rendered by headless Chrome + FFmpeg.
3. **Revideo** - TypeScript generator scenes (Motion Canvas lineage) rendered by Puppeteer + FFmpeg.
4. **Manim Community** - Python, math/science animation.
5. **Motion Canvas** - TypeScript, editor-driven.
6. Briefly dismissed: Editly, Diffusion Studio Core, MoviePy, ManimGL.

## Comparison table

| Item | HyperFrames | Remotion | Revideo | Manim CE | Motion Canvas |
|---|---|---|---|---|---|
| Latest release / activity | v0.8.193 on 2026-10-24; pushed same day; repo created 2026-03-10 [1] | v4.0.538 on 2026-10-22; pushed 2026-10-24 [2] | npm 0.11.0, tag 2026-07-10; last push 2026-07-15 [3][4] | v0.22.0 on 2026-10-08; pushed 2026-10-24 [5] | Last stable v3.17.2 (2024-12-14); last feature commit 2025-02-16; only a docs-domain commit 2026-07-02 [6][7] |
| License | Apache-2.0 [8] | Remotion License: source-available, not OSS; free for individuals and for-profit orgs of up to 3 people, non-profits; company license required otherwise [9][10] | MIT [3] | MIT, copyright 3Blue1Brown LLC [11] | MIT [6] |
| Install friction (macOS) | `npx hyperframes ...`; needs Node 22+ and system FFmpeg; Chrome Headless Shell fetched via `hyperframes browser ensure` [12][13] | `npx create-video`; Node; Chrome Headless Shell auto-downloaded into `node_modules`; macOS arm64 and x64 supported [14][15] | `npm init @revideo@latest`; Node >=22.12; depends on Puppeteer (downloads Chrome) and bundled `@ffmpeg-installer/ffmpeg` [3][16][17] | Python >=3.11; `uv add manim`; video via PyAV (`av` dep); LaTeX optional (MacTeX for `MathTex`) [18][19] | Node project + editor; FFmpeg exporter installed with plugin [20] |
| Headless CLI render | Yes: `npx hyperframes render` [21] | Yes: `npx remotion render` [22] | Yes: `renderVideo()` API and CLI render endpoint; launches Puppeteer with `headless: true` and forces `--single-process` [3][16] | Yes by CLI (`manim render file.py Scene`); the docs never describe headless operation explicitly, so treat as probable, unverified [23][24] | Official docs describe only the editor's Video Settings tab; no CLI render documented [20] |
| Restricted-sandbox flag | Chromium sandbox kept on macOS; Linux has a container-compat exception; Docker mode exists (`--docker`); site-capture does not work through HTTP proxies (applies to `capture`, not to rendering local HTML) [21][25] | Needs Chrome Headless Shell download on first use; sandbox flags not documented; Linux needs shared libs, Alpine/nixOS unsupported [14][26] | Needs Puppeteer Chrome plus a local Vite server; runs on Cloud Run per README [3] | No browser needed; pure Python + native libs; sandbox behaviour unknown | Needs a browser/editor; unknown |
| Sample output quality (not verified locally) | Showcase: product launch films, "SpaceX explainer ... data and motion at scale", PR-to-video, faceless explainer guide with kinetic type, diagram, data-vis [27][28] | Showcase lists tutorials, launch videos, creative tools; page names no specific projects and is closed to new submissions [29] | README shows one Rubik's-cube scramble GIF; docs offer small code snippets only [3][30] | Gallery: formula animations, function plots, shaded areas, camera moves [31] | Not assessed (stagnant) |
| Best-fit concepts | Explainers, kinetic text, diagrams, data charts, code-diff walkthroughs, process/mechanism reveals | React-style motion graphics, data-driven templates | Vector/2D programmatic animation, same niche as Motion Canvas | Mathematics, geometry, function graphs, algorithm and physics animation | Same as Revideo, but editor-driven |
| Render time / cost per minute of output | Only data point: 1080p, 300 frames (10 s at 30 fps) in 25.0 s unoptimized vs 9.8 s optimized, median of 3, machine unspecified [32]. Linear extrapolation is about 2.5 min vs 1 min per output minute (our arithmetic, not a vendor claim). `--experimental-fast-capture` claims ~2x faster capture [21]. Compute cost $0 locally [33] | unknown (docs say run `npx remotion benchmark`; default concurrency is half the CPU threads) [34][35] | unknown | unknown (docs give quality presets 480p15 / 720p30 / 1080p60 only) [36] | unknown |
| Scenes render independently / parallel | Yes, three ways: `--composition` renders any standalone composition [37]; `--workers 1-24` parallelises frames (about 256 MB per Chrome) [21]; AWS Lambda distributed render [1]. Catch: on macOS, multi-worker capture writes raw frames to disk (about 25 GB per minute at 1080p30) unless `HF_CAPTURE_PARALLEL_STREAM=true` [21] | Yes: separate compositions, `--frames` ranges, `--concurrency`; `frameRange` concatenates sections into one video; scene-level stitching of separate renders is not documented on the pages read [22][35] | Yes: `workers` setting and `renderPartialVideo({workerId, numWorkers})` [16] | Each `Scene` class renders independently by name; concatenation is external (our inference) [24] | unknown |
| Telemetry | On by default (anonymous, opt-out via `HYPERFRAMES_NO_TELEMETRY=1` / `DO_NOT_TRACK=1`) [21] | Server-side telemetry voluntary on Free and Creators; mandatory for the paid Automators tier from v5.0 [10] | Anonymous PostHog render counts; `DISABLE_TELEMETRY=true` [3] | None found | None found |

## Per-candidate notes

### HyperFrames - recommended
- Apache-2.0, no per-render fees or commercial-use thresholds; README states this explicitly [8].
- Very active: 71k stars, release v0.8.193 on the day of research, but **pre-1.0 with 302 open issues** (churn risk) [1].
- Ships as a Claude Code plugin (`claude plugin marketplace add heygen-com/hyperframes`) plus skills (`/hyperframes`, `/hyperframes-cli`, `/hyperframes-registry`, `/media-use`) and about 450 catalog blocks (charts, captions, transitions, maps) [8]. A learn-anything renderer can either depend on that plugin or drive the CLI.
- Authoring is plain HTML + data attributes + seekable GSAP/CSS/Lottie/Three.js/D3, so a lesson plan's scene list maps to files an agent already writes well [8][28].
- Has a first-party "faceless explainer" workflow: topic or notes in, kinetic type, diagrams and data viz out, "each body scene advances one mechanism, step, example" [28]. Closest fit to the "any concept from any source" goal.
- Friction: system FFmpeg is required (`doctor` checks ffmpeg/ffprobe/Node); Chrome is fetched separately [12][21].
- Render output: MP4, WebM/MOV with alpha, GIF, PNG sequence, HLS [21].
- `/media-use` mentions "HeyGen or free local tools" for voiceover/music. The free-local TTS path was not verified; any HeyGen path is paid/hosted and must not be a pick [8].

### Remotion - strongest ecosystem, wrong license shape
- Technically strong and very active (v4.0.538 on 2026-10-22) [2]. Has Claude Code instructions and `npx remotion skills add` [38].
- **License is the blocker for a marketplace plugin.** It is "source-available software, but it is not open source software" [10]. Free only for individuals, for-profit orgs up to 3 people, and non-profits [9]. Any user in a 4+ person company needs a paid Company License: Creators $25/seat/month or Automators $0.01/render with $100/month minimum [39]. The FAQ says headcount is aggregated across contractors and partner companies [10].
- The terms say end-users with direct code access "must obtain their own Company License if they qualify" [40]. A plugin that makes every installer run Remotion pushes that obligation onto them, which conflicts with "free/OSS" as a distribution default. Fine for a solo learner, not safe to bake into a marketplace-standard plugin.
- The 5.0 terms add mandatory telemetry for Automators and apply to "version 5.0 and all subsequent versions" [10][40]. Whether a free-tier plugin user is affected is unknown.
- Render details otherwise match HyperFrames: headless Chrome, `--concurrency`, `--frames` ranges [22].

### Revideo
- MIT, but small and slower: last release 0.11.0 (July 2026), 63 open issues, project now maintained under the `midrender` org as the engine behind a commercial product (Midrender) [3][4].
- README explicitly says "A scene is plain TypeScript, so Claude or Codex can produce one from a prompt" [3].
- Real headless pipeline with worker parallelism, but the renderer forces Chrome `--single-process`, and docs pages are heavy navigation with thin API prose (fetch returned nav only) [16].
- Sample quality evidence is one README GIF [3].

### Manim Community - specialist for math/science
- MIT, very active (commit on research day, v0.22.0 2026-10-08) [5][11].
- Python >=3.11; no system FFmpeg (PyAV); LaTeX only needed for `Tex`/`MathTex`; docs recommend `uv` and MacTeX on macOS, and the optional Typst path exists [18][19][41]. MacTeX download size: unknown.
- Gallery is math/plots/geometry; it is not designed for generic slides, prose explainers, or UI mockups [31].
- Each `Scene` class is rendered by name, so scenes are independent units [24]. Render speed: unknown.

### Motion Canvas
- MIT but effectively stagnant: no stable release since Dec 2024, feature commits stopped Feb 2025 [6][7]. Official video export is via the editor UI; headless is the reason Revideo forked [20][3]. Not recommended.

### Dismissed
- **Editly** (MIT): last push 2025-05-12, latest tag is an rc, needs system FFmpeg and headless-gl; editing-oriented, not an animation framework [42].
- **Diffusion Studio Core** (MPL-2.0): browser-only WebCodecs engine for building editors, last push 2025-11-18, requires special HTTP headers; not a CLI renderer [43].
- **MoviePy** (MIT, v2.2.1, 2025-05-21): clip compositing in Python, no scene/animation model; useful only for muxing [44]. Not examined further.
- **ManimGL** (3b1b, MIT, pushed 2026-09-09, release v1.7.2 2024-12-13): interactive OpenGL variant; headless story not established, so Manim CE is preferred [45].

## Pick and fallback

**Pick: HyperFrames.** Apache-2.0, local, headless CLI, actively maintained, Claude-Code-native, and HTML scenes suit agents and cover most lesson concepts.

**Fallback: Manim Community (MIT)** for math/science-heavy concepts, or Remotion if the learner is eligible for the free tier and the team accepts the license (single-user installs only; never a default).

**Best-fit concept types:** HyperFrames for explainers, mechanisms/processes, data and charts, kinetic text, code/PR walkthroughs; Manim CE for mathematical, geometric, function-graph and algorithm animation.

## Risks and open items for the spec

- HyperFrames is pre-1.0 and fast-moving: pin a version in the plugin's documented dependencies.
- Telemetry is on by default in HyperFrames and Revideo; document the opt-out env var for the local-only constraint.
- macOS multi-worker rendering writes frames to disk by default (about 25 GB per minute at 1080p30); the renderer should default to a single worker or set `HF_CAPTURE_PARALLEL_STREAM=true`, to be validated.
- Render time per minute for every tool except one vendor-reported HyperFrames number is **unknown**; measure before promising a budget.
- Free local TTS/voiceover for narration was not established from primary sources; narration may need to be text/captions only, or a separate research ticket.
- Graceful degradation: when Node, FFmpeg or Chrome is missing, fall back to a text/slides mode skill.

## Sources

[1] https://github.com/heygen-com/hyperframes (GitHub API: pushed 2026-10-24, release v0.8.193, 302 open issues; README stack table lists AWS Lambda rendering)
[2] https://github.com/remotion-dev/remotion/releases (API: v4.0.538, 2026-10-22)
[3] https://github.com/midrender/revideo/blob/main/README.md (formerly redotvideo/revideo)
[4] https://github.com/midrender/revideo/commits/main (API: 0.11.0 release commit 2026-07-10, last push 2026-07-15)
[5] https://github.com/ManimCommunity/manim/releases (API: v0.22.0, 2026-10-08)
[6] https://github.com/motion-canvas/motion-canvas (API: MIT; latest release v3.17.2)
[7] https://github.com/motion-canvas/motion-canvas/commits/main (API: 2025-02-16 and 2026-07-02 docs-domain commits)
[8] https://github.com/heygen-com/hyperframes/blob/main/README.md and https://github.com/heygen-com/hyperframes/blob/main/LICENSE
[9] https://github.com/remotion-dev/remotion/blob/main/LICENSE.md
[10] https://www.remotion.dev/docs/license/faq
[11] https://github.com/ManimCommunity/manim/blob/main/LICENSE
[12] https://github.com/heygen-com/hyperframes/blob/main/docs/quickstart.mdx
[13] https://github.com/heygen-com/hyperframes/blob/main/docs/packages/cli.mdx (section `browser`: `browser ensure`)
[14] https://www.remotion.dev/docs/miscellaneous/chrome-headless-shell
[15] https://www.remotion.dev/docs/ai/claude-code
[16] https://github.com/midrender/revideo/blob/main/packages/renderer/server/render-video.ts (workers, renderPartialVideo, headless, `--single-process`)
[17] https://github.com/midrender/revideo/blob/main/package.json and packages/ffmpeg/package.json
[18] https://github.com/ManimCommunity/manim/blob/main/pyproject.toml
[19] https://github.com/ManimCommunity/manim/blob/main/docs/source/installation/uv.md
[20] https://motioncanvas.io/docs/rendering/video
[21] https://github.com/heygen-com/hyperframes/blob/main/docs/packages/cli.mdx (render flags, workers, fast capture, streaming/disk path, sandbox, telemetry)
[22] https://www.remotion.dev/docs/cli/render and https://www.remotion.dev/docs/renderer/render-media
[23] https://docs.manim.community/en/stable/guides/configuration.html
[24] https://docs.manim.community/en/stable/tutorials/quickstart.html
[25] https://github.com/heygen-com/hyperframes/blob/main/docs/guides/rendering.mdx (local vs `--docker`)
[26] https://www.remotion.dev/docs/miscellaneous/linux-dependencies
[27] https://hyperframes.heygen.com/showcase
[28] https://github.com/heygen-com/hyperframes/blob/main/docs/guides/faceless-explainer.mdx
[29] https://www.remotion.dev/showcase
[30] https://midrender.com/revideo/docs (nav lists code snippets and rendering guides)
[31] https://docs.manim.community/en/stable/examples.html
[32] https://github.com/heygen-com/hyperframes/blob/main/docs/guides/performance.mdx
[33] https://github.com/heygen-com/hyperframes/blob/main/docs/quickstart.mdx ("local rendering does not use HeyGen credits")
[34] https://www.remotion.dev/docs/performance
[35] https://www.remotion.dev/docs/renderer/render-media (default concurrency half of CPU threads)
[36] https://docs.manim.community/en/stable/guides/configuration.html (-q presets)
[37] https://github.com/heygen-com/hyperframes/blob/main/docs/guides/rendering.mdx ("Render another composition")
[38] https://www.remotion.dev/docs/ai/claude-code
[39] https://www.remotion.pro/license
[40] https://www.remotion.dev/docs/license/terms
[41] https://docs.manim.community/en/stable/guides/using_text.html
[42] https://github.com/mifi/editly (README; API: pushed 2025-05-12, latest release v0.15.0-rc.1)
[43] https://github.com/diffusionstudio/core (README; API: MPL-2.0, pushed 2025-11-18)
[44] https://github.com/Zulko/moviepy (API: MIT, v2.2.1)
[45] https://github.com/3b1b/manim (API: MIT, pushed 2026-09-09; latest release v1.7.2)
