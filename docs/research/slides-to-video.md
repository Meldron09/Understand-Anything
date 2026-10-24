# Research: slides-to-video (issue #8)

Date: 2026-10-24. Constraints: free/OSS, local only, macOS Claude Code primary. Terms per `CONTEXT.md` (renderer, mode skill, lesson artifact, handoff).
Sample-output quality is judged from each project's own gallery/docs only and is **not verified locally** (nothing was installed). "Unknown" = not established from primary sources.

Maintenance data: GitHub REST API (`https://api.github.com/repos/<owner>/<repo>`, `/releases/latest`, `/commits`), queried 2026-10-24. Repos: [heygen-com/hyperframes](https://github.com/heygen-com/hyperframes), [remotion-dev/remotion](https://github.com/remotion-dev/remotion), [redotvideo/revideo](https://github.com/redotvideo/revideo), [motion-canvas/motion-canvas](https://github.com/motion-canvas/motion-canvas), [ManimCommunity/manim](https://github.com/ManimCommunity/manim), [marp-team/marp-cli](https://github.com/marp-team/marp-cli), [slidevjs/slidev](https://github.com/slidevjs/slidev), [hakimel/reveal.js](https://github.com/hakimel/reveal.js), [astefanutti/decktape](https://github.com/astefanutti/decktape).

Key finding: none of the three classic slide tools (Marp, Slidev, reveal.js) produces video. They export PDF/PPTX/PNG/HTML only. A slide tool becomes a video renderer only through a DIY pipeline (slide PNGs + narration audio + ffmpeg). The tools that natively emit MP4 are code-to-video engines (HyperFrames, Remotion, Revideo, Manim; Motion Canvas emits an image sequence).

## Comparison table

| | HyperFrames | Remotion | Revideo | Motion Canvas | Manim CE | Marp CLI (+DIY) | Slidev (+DIY) | reveal.js (+DeckTape, DIY) |
|---|---|---|---|---|---|---|---|---|
| Native video out | MP4/MOV/WebM/GIF/HLS | MP4 etc. | MP4 | PNG sequence (ffmpeg yourself) | MP4 | No | No | No |
| Latest release / activity | v0.8.193, 2026-10-24; pushed 2026-10-24; repo created 2026-03-10 | v4.0.538, 2026-10-22; pushed 2026-10-24 | no GitHub Releases; tag v0.11.0 2026-07-10; pushed 2026-07-15 | v3.17.2 stable 2024-12-14 (3.18.0-alpha tag exists); last commit 2026-07-02 | v0.22.0, 2026-10-08; pushed 2026-10-24 | v4.5.1, 2026-09-06; pushed 2026-09-08 | v53.0.0, 2026-09-16; pushed 2026-10-23 | reveal 6.0.2, 2026-09-10; DeckTape v3.17.0, 2026-10-19 |
| License | Apache-2.0 | Custom "Remotion License", NOT OSI: free for individuals, for-profits with up to 3 employees, non-profits; company license above that | MIT | MIT | MIT | MIT | MIT | MIT (both) |
| Install friction (macOS) | Node 22+, FFmpeg (`brew install ffmpeg`); `npx hyperframes init`; also a Claude Code plugin. Browser acquisition: unknown | npm + headless Chrome (details not on fetched pages) | `npm init @revideo@latest` | npm, editor-driven | pip or conda; Cairo/Pango; LaTeX needed only for Tex/MathTex | npm/brew/Docker/standalone binary; needs Chrome, Edge or Firefox for PDF/PPTX/PNG (HTML needs none) | npm, Node 22.12+, `playwright-chromium` for export | npm; DeckTape needs Node 22.12+, bundles Chromium |
| Headless CLI / sandbox | Yes: `hyperframes render` drives headless Chrome + FFmpeg; `--docker` option. No-sandbox guidance: unknown | Yes (`remotion render` CLI, `--chrome-mode`); sandbox flags: unknown | Yes: "headless render API" | No documented headless path (render button in editor) | Yes: CLI render, Docker image `manimcommunity/manim` | Yes (CLI; Chrome via CDP/BiDi) | Yes (`slidev export`) | Yes (DeckTape, Docker image) |
| Static slide output quality (docs/gallery; not verified locally) | Not a slide tool; `slideshow` skill makes an interactive deck, not MP4; `snapshot` gives per-slide stills | Not a slide tool | n/a | n/a | n/a | Three built-in themes (default, gaia, uncover), KaTeX/MathJax plugins, PDF/PPTX/PNG/HTML | Richest: Shiki code, Monaco, KaTeX, Mermaid, animations, theme gallery, PDF/PPTX/PNG | Strong HTML decks; PDF via print CSS (Chrome only) or DeckTape |
| Sample video quality | Showcase page with kinetic type, diagram, dataviz, 4K launch film; "faceless explainer" demo MP4 (not verified locally) | Not reviewed | Unknown | Unknown | Not reviewed | n/a | n/a | n/a |
| Best-fit concept types | Explainers: processes, data/charts, kinetic text, diagrams, narrated stories | Same as HyperFrames, React-based | Programmatic/parameterized 2D animation | Vector/process animation | Math, algorithms, geometry, plots | Linear conceptual/overview slides | Code-heavy and diagram-heavy technical talks | Rich interactive HTML decks |
| Render time / cost per minute | $0 (local CPU). One page-reported benchmark: 300 frames at 1080p took 25.0 s vs 9.8 s depending on technique; fps and clip length not stated, so per-minute figure: unknown. Raw-frame disk path costs ~25 GB per minute at 1080p30 (macOS multi-worker default) | $0 local; per-minute figure: unknown | Unknown | Unknown | Unknown | DIY: not measured | Same | Same |
| Scenes render independently | Yes by design: `render --composition <path>` renders a standalone composition (so scenes can be rendered separately and concatenated; concatenation is our inference); also `--workers` 1-24 Chrome processes, ~256 MB each | Yes: `--frames` ranges, `--concurrency` | Unknown (`renderPartialVideo` exists in API reference) | Unknown | Unknown | Yes: per-slide PNGs | Yes: `--range` | Yes: DeckTape screenshots per slide |

## Per-candidate notes

**HyperFrames (HeyGen).** HTML/CSS + seekable animations (GSAP etc.) rendered frame-by-frame in headless Chrome, encoded with FFmpeg; Apache-2.0 with "no per-render fees or commercial-use thresholds" ([README](https://github.com/heygen-com/hyperframes)). Ships agent skills and a Claude Code plugin (`claude plugin marketplace add heygen-com/hyperframes`). Local free narration: `hyperframes tts` uses Kokoro-82M, "No API key, nothing leaves the machine", voices in 9 locales; `hyperframes transcribe` uses Parakeet or Whisper for word timing ([CLI reference](https://hyperframes.heygen.com/packages/cli), [voice guide](https://hyperframes.heygen.com/guides/voice-and-audio)). `hyperframes doctor` checks the setup. Has a faceless-explainer guide (script to kinetic type + diagram + dataviz; [guide](https://hyperframes.heygen.com/guides/faceless-explainer)) and about 450 catalog blocks.
Caveats:
1. Young and fast-moving: created 2026-03-10, still 0.x with ~190 releases, so interfaces may shift.
2. Authors must follow determinism rules (paused timeline, no wall clock, no unseeded randomness) or it "breaks quietly" ([vs Remotion](https://hyperframes.heygen.com/guides/hyperframes-vs-remotion)).
3. `render` on a slideshow deck silently renders only the first slide ([slideshow guide](https://hyperframes.heygen.com/guides/slideshow)); a video must be authored as a video composition, not a deck.
4. On macOS multi-worker capture is screenshot-based and writes raw frames to disk unless `HF_CAPTURE_PARALLEL_STREAM=true`; low-memory mode (one worker) is automatic at 8 GB RAM or less ([CLI reference](https://hyperframes.heygen.com/packages/cli)).
5. Model downloads land in `~/.cache/hyperframes` (Parakeet ~640 MB; Kokoro size: unknown).
6. Restricted-sandbox flag: Chrome acquisition and no-sandbox behavior are not documented on the pages read, so unknown; `--docker` is the documented controlled path ([rendering guide](https://hyperframes.heygen.com/guides/rendering)).

**Remotion.** React-based, very mature, but the license is [custom](https://github.com/remotion-dev/remotion/blob/main/LICENSE.md): free only for individuals, for-profits of up to 3 employees, non-profits, or evaluation; a Company License is required otherwise, and the file says the license changes in Remotion 5.0. That fails "free/OSS" for general marketplace users, so it is never a pick (a paid path may be noted in passing). Technically strong (`--frames` ranges, `--concurrency`; [render CLI](https://www.remotion.dev/docs/cli/render)).

**Revideo.** MIT, TypeScript, "headless render API" plus React player; README says scenes are plain TypeScript that Claude or Codex can generate ([README](https://github.com/redotvideo/revideo)). Now backed by Midrender (docs moved to midrender.com). No GitHub Releases; last tag v0.11.0 (2026-07-10), last push 2026-07-15. Audio: `Audio` component and `mergeAudioWithVideo()` listed ([docs](https://midrender.com/revideo/docs)). Local TTS integration, render speed, parallelism: unknown. Viable code-to-video backup, with less agent-oriented tooling than HyperFrames.

**Motion Canvas.** MIT, 19k stars, but last stable release is v3.17.2 (2024-12-14); only an alpha tag since, last commit 2026-07-02. Docs describe rendering as an editor "RENDER" button that writes an image sequence you convert with ffmpeg; no headless CLI documented ([rendering docs](https://motioncanvas.io/docs/rendering)). Poor fit for unattended Claude Code runs.

**Manim Community.** MIT, actively released (v0.22.0, 2026-10-08), pip/conda install, Docker image available ([install](https://docs.manim.community/en/stable/installation.html)). `Text()` uses Pango; `Tex`/`MathTex` need a LaTeX distribution ([text guide](https://docs.manim.community/en/stable/guides/using_text.html)). Best for math/algorithm/geometry concepts. A voiceover plugin exists ([manim-voiceover](https://github.com/ManimCommunity/manim-voiceover), MIT, pushed 2026-06-15; TTS engine options not checked). Python plus LaTeX install weight is the friction.

**Marp CLI.** MIT; outputs HTML, PDF, PPTX, PNG/JPEG (`--images`), notes as text; no video ([README](https://github.com/marp-team/marp-cli)). Needs Chrome, Edge or Firefox for PDF/PPTX/image output; HTML output needs no browser. Standalone macOS binary bundles Node. Themes: [default, gaia, uncover](https://github.com/marp-team/marp-core/tree/main/themes); math via [KaTeX/MathJax plugins](https://github.com/marp-team/marp-core).

**Slidev.** MIT, 49k stars, very active. Exports PDF, PPTX, PNG, MD; needs `playwright-chromium`; no video export described ([export docs](https://sli.dev/guide/exporting)). Features: Shiki, Monaco, KaTeX, Mermaid, built-in recording via RecordRTC; Node 22.12+ ([guide](https://sli.dev/guide/)). Theme gallery and showcases in [docs/resources](https://github.com/slidevjs/slidev/tree/main/docs/resources).

**reveal.js + DeckTape.** reveal.js PDF needs Chrome/Chromium print mode and points to DeckTape for CLI; no video ([PDF export](https://revealjs.com/pdf-export/)). DeckTape (MIT, v3.17.0 2026-10-19) supports reveal.js, impress.js and others; outputs PDF or per-slide PNG/JPG; Docker image ([README](https://github.com/astefanutti/decktape)).

## Pick and Fallback

**Pick: HyperFrames.** The only candidate that is free (Apache-2.0), local, headless, native MP4, agent-oriented (Claude Code plugin and skills), and ships a local-TTS and word-timing path in one CLI.

**Fallback: DIY "stills + narration + ffmpeg" built on Marp CLI** (Marp PNG per slide, local TTS audio, ffmpeg stitch). Lowest risk, stable dependencies, independent scenes, no animation. Revideo (MIT, headless API) is the code-to-video backup if animation is needed and HyperFrames proves unstable. Remotion is excluded by license.

**Best-fit concept types.** HyperFrames: processes and mechanisms, data/chart-backed explanations, definitions with kinetic text, narrative explainers. Marp-stills fallback: linear overviews, definitions, comparisons. Math/algorithm concepts: Manim is the specialist if a further renderer is ever wanted (not a pick here).

## Static slides pick

**Pick: Marp CLI.** MIT, mature, single Markdown file, outputs HTML (no browser needed, good graceful degradation), PDF, PPTX and PNG; math plugins; three built-in themes. Lean for a mode skill.
**Step-up: Slidev** when concepts are code-, diagram- or animation-heavy (Mermaid, Shiki, Monaco), at the cost of Node 22.12+ and a Playwright Chromium download. Quality judged from docs only (not verified locally).
Not picked: reveal.js (needs DeckTape or Chrome print for PDF) and the HyperFrames `slideshow` skill (interactive deck only; "cannot be exported as one linear MP4 yet").
Open design question for the spec: if the video pick is HyperFrames, should slides mode share its toolchain (one dependency) at the cost of a 0.x project? This note recommends keeping Marp for static slides to preserve graceful degradation.

## Unknowns to close before building

- HyperFrames: Chrome acquisition and sandbox behavior in a restricted environment; Kokoro model size; real render minutes per output minute on an M-series Mac.
- Remotion, Revideo, Motion Canvas, Manim: render-time numbers and gallery quality.
- macOS built-in `say` as a zero-install TTS fallback: not researched here.
