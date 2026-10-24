# Research: whiteboard and explainer-style video (issue #7)

Researched 2026-10-24 against primary sources only (GitHub repo metadata via the GitHub API, READMEs, LICENSE files, PyPI JSON, official docs). Constraints: free/OSS, local only, no generative text-to-video, macOS Claude Code primary. Nothing was installed or rendered; every quality or speed claim comes from the project's own examples and is **not verified locally**. Where a primary source is silent the cell says **unknown**.

## Verdict

- **Pick: handanim** (Python, MIT). Only candidate that natively draws hand-drawn shapes, flowcharts, tables and handwriting-font text from a script Claude can write, with no raster input and no browser.
- **Fallback: Manim Community Edition** (Python, MIT). Far more mature and maintained, but not hand-drawn; it gives clean explainer animation, not a whiteboard look.
- **Best-fit concept types:** handanim for diagrams, flows, step-by-step proofs, small tables, labelled relationships and "draw it as I explain it" ideas; Manim for math, formulas, graphs and plots.

## Comparison table

"Today" = 2026-10-24. Dates are from the sources linked in the notes.

| | handanim | Manim CE | whiteboard-animator | Remotion | Motion Canvas | excalidraw-animate | OpenDoodler |
|---|---|---|---|---|---|---|---|
| Maintenance | Last commit 2026-06-12 (about 4.4 months ago); PyPI 0.1.0 released 2026-06-12; no GitHub releases; 3 contributors, 82 of ~105 commits by one person | Very active: push 2026-10-24, v0.22.0 on 2026-10-08, 41.8k stars | Brand new: created 2026-09-08, one push, PyPI 0.1.1; 3 open issues | Very active: v4.0.538 on 2026-10-22 | Last release v3.17.2 on 2024-12-14; last push 2026-07-02 | Active: push 2026-10-22, v0.7.2 | Last push 2026-08-26, 79 stars |
| License | MIT | MIT (plus a community licence file) | MIT | Remotion License: free only for individuals, for-profits of 3 or fewer employees, non-profits, evaluation; larger for-profits need a paid company licence. Source-available, not OSI open source | MIT | MIT | AGPL-3.0 |
| macOS install | Python 3.11+; `brew install cairo`, FFmpeg on PATH; Poetry path is "most tested", pip `requirements.txt` "may need updating" | Python 3.11+; `brew install cairo pkg-config`, then `uv add manim`; LaTeX (MacTeX) optional, only for typeset formulas; no separate FFmpeg step documented | Python 3.10+; `brew install ffmpeg`; pip pulls an ~83 MB bundled text-detection model plus OpenCV | Node project; Remotion downloads Chrome Headless Shell into `node_modules` | Node/Vite project plus `@motion-canvas/ffmpeg` exporter | Browser app (Vite/React) | Windows only (WPF, .NET 10): not usable on Mac |
| Headless CLI / sandbox | Yes in principle: `scene.render("x.mp4")` from a script; Cairo draws offscreen and needs no display (README requires only Cairo and FFmpeg). Sandbox: flag, needs native Cairo and FFmpeg binaries | Yes: `manim -ql file.py Scene` writes MP4; docs mention an optional live preview only. Sandbox: flag, needs Cairo/Pango libs | Yes: `whiteboard-animate in.png -o out.mp4`, CPU only, no GPU or API key. Sandbox: flag, needs FFmpeg | Yes: `npx remotion render`; headless Chrome is the documented default. Sandbox: flag, downloads a browser | Docs show a UI "Video Settings" exporter; a headless path is **unknown** | No documented CLI; app is UI driven; repo has Playwright e2e only | No |
| Hand-drawn look | Yes, core feature: sketchy strokes, hatching fills, handwriting fonts (Hershey, TTF), eraser | No native sketch style | Yes, but only reveals an existing image | Only via extra libraries (for example rough.js), not built in | Same | Yes (Excalidraw's own style) | Yes |
| Input | Python script building scenes (SVG and PNG import supported) | Python script | A finished raster "ink on white" image | React/TypeScript | TypeScript | `.excalidraw` JSON | GUI project |
| Parallel scenes | Each `Scene` is its own timeline and writes its own file, so one process per scene is structurally possible; not documented. Inference | Each Scene class renders on its own, so a process per scene is structurally possible; not documented. Inference. Sections are within one scene | Multi-scene input is concatenated; per-scene independence is structural. Inference | `--concurrency` flag documented for in-render parallelism | **Unknown** | **Unknown** | No |
| Render time and cost per minute | **Unknown**, no benchmarks published; $0 local CPU | **Unknown**, no numbers in the sources read; `-ql` preset documented as faster. $0 local CPU | **Unknown**; presets 20, 24, 24 fps; $0 local CPU | **Unknown** in sources read; $0 local | **Unknown** | **Unknown** | n/a |
| Sample quality (not verified locally) | Gallery GIFs: Pythagoras, (a+b)^2 proof, ML flowchart, solar system; simple, clean, a little rough | Polished math animation, but a different aesthetic | Sample scenes look like marker-style cartoon art; engine is credited as the render core of a commercial product | n/a | n/a | README itself says WebM export "is not perfect" | n/a |

## Per-candidate notes

### handanim (pick)
- Repo: https://github.com/subroy13/handanim. MIT per the repo and `pyproject.toml`; PyPI 0.1.0, requires Python `>=3.11,<4.0` (https://pypi.org/pypi/handanim/json).
- Primitives cover what a concept explainer needs: lines, arrows, polygons, ellipses, text, math, `Flowchart`, `Table`, `VectorSVG`, `RasterImage`, `Eraser`; animations include sketch reveal, fade, zoom, translate, camera. Source: `repo_overview.md` at https://github.com/subroy13/handanim/blob/master/repo_overview.md.
- API is a short Python script: `Scene(...)`, `scene.add(SketchAnimation(start_time, end_time), drawable=...)`, `scene.render("out.mp4", fps=30)`. Source: https://github.com/subroy13/handanim/blob/master/README.md. Good fit for a mode skill where Claude writes the script itself.
- Math is rendered through matplotlib, not LaTeX (dependencies list: https://github.com/subroy13/handanim/blob/master/pyproject.toml), so no TeX install is needed for formulas.
- Repo ships a `CLAUDE.md`, and the repo overview calls it "AI-scriptable". An optional `handanim_ai` module uses OpenRouter (a paid API); a learner-side mode skill should not use it.
- Risks: pre-1.0 (README classifier "Beta"), one main maintainer, no tagged releases, last commit about 4.4 months old, `todo.md` shows PyPI publication and CI test workflow items still unchecked, and the README warns requirements may need adjusting per platform. Output quality was judged only from README GIFs: https://github.com/subroy13/handanim/tree/master/examples/output.
- Needs two native binaries on a Mac (Cairo, FFmpeg) that a marketplace plugin must document and degrade gracefully when missing.

### Manim Community Edition (fallback)
- Repo: https://github.com/ManimCommunity/manim, MIT, v0.22.0 on 2026-10-08, requires Python `>=3.11` (https://github.com/ManimCommunity/manim/blob/main/pyproject.toml, https://pypi.org/pypi/manim/json).
- macOS: `brew install cairo pkg-config`, then `uv add manim`; LaTeX optional (https://github.com/ManimCommunity/manim/blob/main/docs/source/installation/uv.md). Video encoding uses the `av` Python package, which is a listed dependency, so no separate FFmpeg step appears in the install docs.
- Cleanest, most reliable and best documented option; the largest community. Weakness for this ticket: no whiteboard or hand-drawn style.
- Best for formulas, graphs and geometry; weak for "hand sketching a concept map".
- A related 3Blue1Brown fork exists (https://github.com/3b1b/manim, MIT, push 2026-09-09) but is the original author's separate tool (not evaluated further; community edition is the documented, packaged one).

### whiteboard-animator (not picked)
- Repo: https://github.com/masihsultani/whiteboard-animator. MIT, PyPI 0.1.1 (2026-09-08). Created 2026-09-08, so no track record.
- It only animates an image you already have ("ink on white", flat colours), then reveals it as if drawn. It does not draw anything itself. The README's own sample scenes are cleaner than a bare script could produce, but they come from the commercial product's image generator (the README table lists "Generate the scene images" as hosted-only). Without a generative image step Claude would have to produce raster art itself (for example SVG rendered to PNG); the README lists "SVG input" as a wanted contribution, not a feature.
- Text recognition uses a bundled 83 MB CRAFT ONNX model; optional narration planning needs a Gemini key (paid API, skip).
- Possible later combination: pair it with a script-to-image step for photo-like scenes. Not needed for v1.

### Remotion (not picked: licence)
- https://github.com/remotion-dev/remotion; licence text at https://github.com/remotion-dev/remotion/blob/main/LICENSE.md. Free only for individuals, for-profits of 3 or fewer people, non-profits; others need a company licence. That is not OSI open source and fails the "free/OSS" test for general marketplace users.
- Technically strong: headless CLI render (https://www.remotion.dev/docs/cli/render), Chrome Headless Shell installed automatically (https://www.remotion.dev/docs/miscellaneous/chrome-headless-shell), `--concurrency`. No built-in hand-drawn style.

### Motion Canvas (not picked)
- https://github.com/motion-canvas/motion-canvas, MIT. Latest release v3.17.2 is from 2024-12-14. Export is documented through the editor's Video Settings tab (https://motioncanvas.io/docs/rendering/video); a headless path is unknown. Vector animation, not hand-drawn.

### excalidraw-animate (not picked)
- https://github.com/dai-shi/excalidraw-animate, MIT, active. Animates Excalidraw drawings into SVG/WebM through a web app; no documented CLI; README says "Exporting WebM feature is not perfect" and suggests screen capture. Real Excalidraw sketch look, but would require browser automation to turn into video. Possible secondary format (animated SVG for the interactive explainer mode), not a video renderer.

### OpenDoodler (rejected)
- https://github.com/Rsverma/OpenDoodler: AGPL-3.0 and "Windows only", built with WPF (.NET 10). Not usable on macOS.

### Other names seen, not evaluated
Inkplainer-OS (https://github.com/NadirWeb-App/Inkplainer-OS, browser app, licence reported as NOASSERTION) and sujay46/whiteboard (https://github.com/sujay46/whiteboard, no licence in repo metadata, created 2026-10-13). Neither has a clear licence, so neither was evaluated further.

## Recommendations for the spec

1. Treat handanim as the whiteboard renderer: the mode skill writes one Python scene script per lesson scene, so scenes stay independent files. If scenes are rendered one process each, parallelism needs a smoke test before the spec promises it (unverified).
2. Dependencies to document: Python 3.11+, `brew install cairo ffmpeg`, handanim. Degrade to text/slide output when missing.
3. Pin to the PyPI 0.1.0 version, and because it has one active maintainer, keep Manim CE as the fallback renderer behind the same lesson-artifact contract.
4. Before locking the decision, a follow-up spike should run the repo's `examples/pythagoras.py` and `examples/ml_workflow_demo.py` on a Mac and record render time per minute of output (unknown today).

## Pick
**handanim**: the only free, MIT, scriptable tool that draws hand-drawn diagrams, flows, tables and handwritten text natively, with no raster input, browser or paid API.

## Fallback
**Manim Community Edition**: mature, actively released, MIT, headless CLI, simple macOS install; trades the whiteboard look for reliability.

**Best-fit concept types:** handanim: processes, flows, relationships, step-by-step reasoning and small proofs; Manim: formulas, graphs, geometry and numeric intuition.
