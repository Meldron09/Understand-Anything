# Research: unlisted video approaches (issue #11)

Date of research: 2026-10-24. Scope: free/OSS, local, concept-explainer video, beyond the seed list (manim, Remotion, Motion Canvas, Revideo, Marp, Slidev, reveal.js, ffmpeg, MoviePy) and beyond what the sibling tickets cover (math/science animation, programmatic video, animated diagrams, code walkthroughs, data/chart animation, whiteboard/explainer, slides-to-video, 3D/physics, narration/captions/assembly).

Nothing was installed or run. Every "sample quality" statement is **not verified locally**; it rests on the project's own docs/showcase. "Unknown" means the primary source did not say.

## Verdicts

| # | Candidate / category | Verdict |
|---|---|---|
| 1 | HTML + seekable animation (GSAP/CSS/WAAPI/Lottie) captured by headless Chrome: **HyperFrames** | **Worth its own ticket** |
| 2 | Terminal tape recorders: **VHS** (and asciinema + agg) | **Fold into** the code-walkthroughs ticket |
| 3 | Agent-authored vector animation runtimes: **Rive** (RML + CLI) | **Drop** for v1 (watch) |
| 4 | **Lottie / dotLottie** renderers | **Drop** (fold in as a HyperFrames frame adapter) |
| 5 | Real-time browser screen recording: **Playwright `recordVideo` / Puppeteer screencast** | **Drop** (fold into #1 as the naive baseline) |

Also swept and dismissed without a full run: timecut (stale), Editly (ffmpeg wrapper, one maintainer, stale). See "Dismissed".

**Pick (for this sweep): HyperFrames.** **Fallback: VHS**, but only for terminal/CLI concepts. It is not a general fallback; for the general case fall back to the seed-list picks (e.g. the programmatic-video ticket's winner).

## 1. HyperFrames (HTML to deterministic MP4) -- own ticket

Why it is a new category: the seed list has React-based (Remotion, Revideo) and canvas-based (Motion Canvas) renderers. HyperFrames renders *plain HTML/CSS + any seekable browser animation*, so an LLM writes the thing it is best at (HTML, SVG, CSS, GSAP), and it ships Claude Code skills and a marketplace plugin.

- **Maintenance:** very active. Last push 2026-10-24; release v0.8.193 published 2026-10-24; repo created 2026-03-10; ~71k stars. https://github.com/heygen-com/hyperframes (API: `gh api repos/heygen-com/hyperframes`). Young (about 7 months), versioning is 0.x with several releases per day, so API churn risk is real.
- **License:** Apache-2.0, "no per-render fees or commercial-use thresholds". https://github.com/heygen-com/hyperframes/blob/main/LICENSE ; README https://github.com/heygen-com/hyperframes. Contrast (per its own doc): Remotion "free for individuals and companies up to three people, paid above that" https://github.com/heygen-com/hyperframes/blob/main/docs/guides/hyperframes-vs-remotion.mdx . Caveats: (a) GSAP, the default animation lib in its examples, is not OSI open source: it uses GreenSock's "Standard 'no charge' license" (free incl. commercial, plugins included) https://github.com/greensock/GSAP/blob/main/README.md ; CSS/WAAPI/Anime.js/Lottie/Three.js are also listed as supported, so GSAP is avoidable. (b) one third-party dep is MPL-2.0 (mediabunny, studio only) https://github.com/heygen-com/hyperframes/blob/main/CREDITS.md . (c) The vendor (HeyGen) has optional paid/cloud paths (HeyGen voices, avatars, AWS Lambda). The media skill requires an auth preflight that offers a local-only continue option https://github.com/heygen-com/hyperframes/blob/main/skills/media-use/audio/references/tts.md . The spec must pin the free local path.
- **Install friction (macOS):** Node.js 22+ and FFmpeg; `npx hyperframes init/preview/render` (README). Claude Code plugin: `claude plugin marketplace add heygen-com/hyperframes` then `claude plugin install hyperframes@hyperframes` (README). Uses a bundled `chrome-headless-shell` (https://github.com/heygen-com/hyperframes/blob/main/docs/packages/cli.mdx). A native Mac/Linux app is also mentioned (README). Local TTS option: `npx hyperframes tts` uses Kokoro on device, needs Python 3.10+ and `pip install kokoro-onnx soundfile` (https://github.com/heygen-com/hyperframes/blob/main/skills/media-use/SKILL.md). Local transcription: Parakeet if installed, else Whisper (https://github.com/heygen-com/hyperframes/blob/main/docs/guides/voice-and-audio.mdx).
- **Headless in CLI / restricted sandbox:** CLI-first and agent-driven ("Use it locally with the CLI, from AI coding agents with skills", README). It drives headless Chrome. Whether a restricted sandbox (no Chrome download, no network, locked-down subprocess) works is **unknown**; Docker rendering is mentioned (a `Dockerfile.test` exists) but not documented in the README. Flag only, not a gate.
- **Sample quality:** unknown locally (not verified locally). The project hosts a "faceless explainer" guide with demo video (kinetic type, abstract graphic, diagram, data viz from text) and a showcase https://github.com/heygen-com/hyperframes/blob/main/docs/guides/faceless-explainer.mdx ; https://hyperframes.heygen.com/showcase . That guide explicitly targets "turn notes, an article, or a difficult idea into a visual explanation". These are vendor-chosen demos.
- **Best-fit concept types:** process/mechanism explainers, kinetic-type and diagram-led explanations, data charts/chart races/maps (catalog block `data-chart`), PR/code-diff walkthroughs, docs-to-video (README "What You Can Build"). Weak fit (my inference, not stated): equation-heavy math (no manim-style LaTeX morphing; KaTeX via HTML would be hand-wired). About 450 registry blocks (transitions, titles, captions, charts, maps, 3D) per README.
- **Determinism:** time = floor(frame)/fps; all animations seeked, never played; capture via Chrome `HeadlessExperimental.beginFrame`; encode with FFmpeg https://github.com/heygen-com/hyperframes/blob/main/docs/concepts/determinism.mdx . On macOS and Windows, multi-worker capture is screenshot-based rather than BeginFrame (BeginFrame streaming is Linux on `chrome-headless-shell`), per https://github.com/heygen-com/hyperframes/blob/main/docs/packages/cli.mdx . Implication: the primary target (macOS) is on the slower/less-mature capture path. Magnitude **unknown**.
- **Render time / cost per minute:** the only published number is one perf demo: 25.0 s vs 9.8 s median of three runs, 1920x1080, 300 frames, on an unnamed machine https://github.com/heygen-com/hyperframes/blob/main/docs/guides/performance.mdx . That is about 30 fps at best, so roughly 1 to 2.5 min wall-clock per 1 minute of 30 fps output on that unnamed machine (my arithmetic, not verified locally). Cost: no per-render fee; each worker is a separate Chrome, about 256 MB (https://github.com/heygen-com/hyperframes/blob/main/docs/packages/cli.mdx : `--workers` 1-24, auto).
- **Parallelizable:** yes at the frame-range level within one render (`--workers`; Lambda/Cloud Run fan-out is a cloud path, not a free one). Caveat from its own docs: parallel workers are not bit-identical to each other (a handful of +/-1 pixel level differences at 30-frame chunk boundaries); use `--workers 1` for bit-exactness https://github.com/heygen-com/hyperframes/blob/main/docs/prompting/rules-and-anti-patterns.mdx . Per-scene independent rendering (one MP4 per scene, concat later) is plausible since it is just separate compositions, but is not documented as a feature: **unknown**.
- **Open questions for its ticket:** run it headless on a real Mac and time 1-minute output; check sample explainer quality; check sandbox behavior; check whether a lesson artifact (HTML) can be reused directly as a composition (the "interactive explainer" and "video" renderers might share assets); decide GSAP vs CSS/WAAPI only; decide whether it overlaps/replaces the programmatic-video ticket pick. It also ships `/slideshow` and `/remotion-to-hyperframes` skills (README), so check overlap with the slides-to-video ticket.

## 2. VHS and terminal recorders -- fold into code walkthroughs

- **Maintenance:** VHS: MIT, last push 2026-10-01, ~21k stars (`gh api repos/charmbracelet/vhs`). asciinema `agg`: GPL-3.0(+), last push 2026-08-14 (`gh api repos/asciinema/agg`).
- **Install:** VHS needs `ttyd` and `ffmpeg` on PATH; Homebrew on macOS; Docker image bundles deps https://github.com/charmbracelet/vhs . `agg` needs Rust 1.86+ (cargo install) or Docker; GIF-only, no MP4 per its README https://github.com/asciinema/agg .
- **Headless:** VHS is scripted via `.tape` files (Type/Enter/Sleep/Wait, Hide/Show), is used in CI (vhs-action), and outputs GIF/MP4/WebM or a PNG sequence (VHS README). How it obtains a browser: not stated in README (**unknown**).
- **Fit:** shell, git, CLI-tool, and REPL concepts only. Not a general explainer renderer; no narration/diagram support. Sample quality: not verified locally (README shows GIFs).
- **Render time / parallel:** unknown for both; each tape is an independent run, so scenes as separate tapes are trivially parallel (inference).
- **Verdict:** fold into the code-walkthroughs ticket as a terminal-scene option. agg is dropped (GIF-only, GPL).

## 3. Rive (RML text format + CLI) -- drop for v1, watch

- **Why it surfaced:** Rive docs describe RML, "the XML format that describes a Rive scene as text", explicitly for use "as code" with coding agents, compiled by the Rive CLI https://rive.app/docs/runtimes/advanced-topic/rml.md . The CLI renders a headless PNG frame (`--screenshot`, `--advance` time, `--viewport`) and needs no account except to publish https://rive.app/docs/cli/examples.md .
- **Blocking gaps:** video export is not documented in the CLI docs (screenshots only; one would script frames then ffmpeg, which is DIY); CLI license, install method, and free-tier limits are **unknown** from the pages read; RML maturity status is **unknown**. The runtime (`rive-runtime`, C++) is MIT, last push 2026-10-24 https://github.com/rive-app/rive-runtime , but the editor ecosystem is a commercial product.
- **Fit:** interactive UI-style motion, not concept narration.
- **Verdict:** drop for v1; too many unknowns and poor fit to explainers. Revisit if its CLI gains video output.

## 4. Lottie / dotLottie -- drop

- `lottie-web`: MIT, last push 2025-09-01 (13 months stale vs today) https://github.com/airbnb/lottie-web . `dotlottie-rs`: MIT, last push 2026-10-06, ThorVG renderer; README documents a C API and wasm bindings but no CLI and no documented frame/video export (https://github.com/LottieFiles/dotlottie-rs).
- Lottie is a playback format for designer-authored (After Effects) assets; an LLM hand-writing Lottie JSON for a concept is impractical (my judgment, unverified). Its useful role is already covered: HyperFrames lists Lottie as a supported seekable runtime (README).
- **Verdict:** drop.

## 5. Real-time browser recording (Playwright / Puppeteer) -- drop

- Playwright: `recordVideo` saves video on context close; default size is viewport scaled to fit 800x800; the doc does not state format, frame rate, or real-time behavior https://playwright.dev/docs/videos . Puppeteer `page.screencast()` is marked obsolete (use `page.record()`), outputs WebM/VP9 at 30 FPS, needs ffmpeg, Chrome 153+ https://pptr.dev/api/puppeteer.page.screencast .
- Both record wall-clock playback, not seeked frames, so dropped frames and timing jitter are possible (inference; not stated in the sources). The only plus: it can record an existing interactive lesson artifact as-is.
- **Verdict:** drop; fold into #1 as the naive baseline it should be compared against.

## Dismissed (not worth a ticket)

- **Editly** (MIT; JSON-declarative ffmpeg editing with transitions/titles): last push 2025-05-12, README says maintained by one person https://github.com/mifi/editly . It is an assembly tool, covered by the ffmpeg/assembly tickets.
- **timecut** (BSD-3; Puppeteer frame capture): last push 2023-07-18, stale https://github.com/tungs/timecut . HyperFrames supersedes it.
- **Blender**: left to the 3D/physics ticket.

## Sources not independently checked

Third-party blogs about HyperFrames (mindstudio, noqta, etc.) turned up in search; none of their claims are used here. Everything above comes from the repos, docs sites, and license/README files linked inline.
