# Research: math/science animation libraries (issue #2)

Date: 2026-10-24. Scope: free/OSS, local only, macOS primary. Sources are primary only (project docs, repos, GitHub API, license files). "Not verified locally" = judged from the project's own gallery/docs; nothing was installed or rendered. "Unknown" = not established by primary sources.

## Candidates

1. **Manim Community Edition (CE)** - Python, `manim` on PyPI.
2. **ManimGL** (3b1b/manim) - Python, `manimgl` on PyPI.
3. **Motion Canvas** - TypeScript, browser editor.
4. **Revideo** - TypeScript, headless video renderer sharing the Motion Canvas-style generator model.
5. **Remotion** - React/TypeScript, headless Chrome. Source-available, not OSS (see notes).

## Comparison table

| Item | Manim CE | ManimGL | Motion Canvas | Revideo | Remotion |
|---|---|---|---|---|---|
| Latest release | v0.22.0, 2026-10-08 [1] | v1.7.2, 2024-12-13 [2] | v3.17.2, 2024-12-14 (3.18.0-alpha.0 tag 2025-02-16) [3] | v0.11.0, 2026-07-10 (release commit) [4] | v4.0.538, 2026-10-22 [5] |
| Last commit | 2026-10-24 [1] | 2026-09-09 [2] | 2026-07-02, a docs-domain edit; prior commit 2025-02-16 [3] | 2026-07-15 [4] | 2026-10-24 [5] |
| Maintenance verdict (vs 2026-10-24) | Active | Active but personal-project cadence; no release for ~22 months | Effectively dormant: no feature commit since Feb 2025 | Active (3 months) | Very active |
| License | MIT (LICENSE + LICENSE.community) [6] | MIT [2] | MIT [3] | MIT [4] | Custom "Remotion License"; free only for individuals, orgs of <=3 employees, non-profits, evaluation; company license otherwise [7] |
| Language / runtime | Python >=3.11 [6] | Python >=3.10 [8] | Node >=16 [9] | Node + headless browser [10] | Node + bundled Chrome Headless Shell [11] |
| macOS install | `brew install cairo pkg-config`, `uv add manim`, `uv run manim checkhealth` [12]. ffmpeg comes via the `av` wheel dependency [6], not Homebrew. LaTeX optional (MacTeX); Typst via `manim[typst]` needs no system install [12][13] | `pip install manimgl`; `brew install ffmpeg mactex` (or BasicTeX); on ARM also `pkg-config cairo`; needs OpenGL [8] | `npm init @motion-canvas@latest` [9]; FFmpeg exporter npm package bundles ffmpeg [14] | `npm init @revideo@latest` [10]; ffmpeg required for audio merge [15] | npm; Chrome and FFmpeg binaries shipped with it [11] |
| Headless CLI render | Documented: `manim -qh file.py Scene` [16], no window under the default renderer. A "headless" mode is not documented, and sandbox behaviour is **unknown**. `--dry_run` disables the window [17] | `-w` writes the file and does not open a window (source: `show_in_window=not args.write_file`) [18]. An OpenGL context is still needed; works in a restricted sandbox: **unknown** | **No.** Rendering is driven from the browser editor's Render button; frames land in `/output` [19]. Headless is an unmerged PR and an open help-needed issue [20] | **Yes.** `renderVideo()` runs a headless browser in Node; `puppeteer.args: ['--no-sandbox']` is a documented setting [21] | **Yes.** `npx remotion render`; Linux needs shared libs [11]; `--no-sandbox` is not mentioned there: **unknown** |
| Math fit | Best. Axes, plots, vectors, transforms, `MathTex`, Typst [13][22] | Best (the 3b1b engine); 3D/OpenGL-oriented [2][8] | Good for 2D vector diagrams; LaTeX node exists in the repo (Latex.ts) [23]; no plot/axes primitives found in the sources read | Same 2D component set as Motion Canvas (Latex, Code, Line, Spline) [23] | General web; math only via your own React/SVG/KaTeX code |
| Sample output (not verified locally) | Official gallery: SinAndCosFunctionPlot, GraphAreaPlot, ArgMinExample, PolygonOnAxes, VectorArrow, FollowingGraphCamera [22]. Home page: LaTeX formula morphs, grid warp, streamlines [24] | 3Blue1Brown channel is "almost all" made with it; clips edited together later [25] | Homepage shows a code snippet only, no rendered video [26] | Docs show no gallery in the pages read: **unknown** | Showcase not reviewed: **unknown** |
| Render time / cost per min of output | Unknown: no primary benchmark. Compute is local, cost 0. Quality presets 480p15 to 4K60 [17]. Per-animation caching of partial movie files [27] | Unknown | Unknown | Docs claim faster than real time since v0.4.6 (first-party claim, not verified locally) [28]; `resolutionScale` 0.5 about 2x faster [29] | Unknown: no numbers; `npx remotion benchmark` tunes concurrency [30] |
| Parallelizable scenes | Each `Scene` class renders independently: name one, or `-a` for all [27]. No built-in multi-scene parallel flag found. Separate `manim` processes per scene is an inference, not a documented feature. `--max-inflight-encoders` overlaps encoding with rendering [17] | Per-scene CLI; parallelism: unknown | Unknown | Built in: `workers` splits one video across processes; docs note a laptop is probably fastest with 1 [21] | Built in: `--concurrency` tabs [31]; `--frames` ranges [32] |

## Per-candidate notes

**Manim CE.** Purpose-built for explanatory math (package description: "Animation engine for explanatory math videos") [6], co-credited to Grant Sanderson. The 3b1b FAQ recommends CE to newcomers because it is more stable, documented and tested [25]. Biggest install friction is LaTeX: `MathTex` and `Tex` need a TeX distribution, but `Text` (Pango) does not and `Typst`/`MathTypst` is a no-system-install alternative [13]. On macOS the doc-listed system deps are only cairo and pkg-config [12]. Output is `media/videos/<file>/<quality>/<Scene>.mp4` with silent partial files stitched per scene, audio mixed in separately, which suits lean subagent handoffs (one file path back) [27]. Gaps: no documented headless/sandbox statement, no render-time benchmark.

**ManimGL.** Same lineage, author's own testing ground; the README warns that code from older videos may break and that its instructions must not be mixed with CE's [2][25]. Needs OpenGL and ffmpeg and a bigger LaTeX install (mactex or BasicTeX) [8]. Both packages expose a `manim` executable and can overwrite each other [33]. Little reason to prefer it over CE for a marketplace plugin: no release since Dec 2024 and a stability disclaimer.

**Motion Canvas.** Nice generator-based animation model aimed at vector animation synced to voice-over [26], but rendering is bound to the browser editor [19]. The dedicated ffmpeg exporter is a Vite plugin used from that editor [14]. Headless rendering is requested but not merged [20]. Maintenance is stalled (last feature commit Feb 2025, last stable Dec 2024) [3]. Not a fit for an automated CLI renderer.

**Revideo.** Uses a Motion Canvas-style TypeScript generator model (lineage inferred from the shared 2D component set [23], not stated in sources read) and adds exactly what a CLI renderer needs: `renderVideo()` in Node, parameterized videos via `variables`, partial-range render via `renderPartialVideo`, worker-based parallelism, WebCodecs-based encoding [10][15][21][28]. MIT, maintained (release 2026-07-10) [4]. Note the docs moved to midrender.com (the commercial host behind the project) [10]; the OSS repo is unaffected. Weaknesses: no math-specific primitives beyond Latex/Line/Spline [23]; installing needs Node and a headless Chromium via Puppeteer (not verified locally); sample gallery not found in primary pages read.

**Remotion.** Strongest headless story and a huge ecosystem [5][11][31], but the license is custom: free for individuals and <=3-person companies, a company licence for larger for-profit orgs [7]. GitHub reports the SPDX as NOASSERTION [5]. This violates the "free/OSS" constraint for marketplace distribution of other people's use, so it is noted, never a pick or fallback.

## Not-chosen others

- Browser/SVG tools (D3, Mafs, JSXGraph) fit the *interactive explainer* mode rather than video; out of scope for this ticket and not researched here.
- Paid or hosted paths (Midrender platform, Remotion Lambda, generative video) are excluded by the map's constraints.

## Pick

**Manim Community Edition.** The only candidate designed for math/science explainers, actively maintained (release 2026-10-08, commits today), MIT, per-scene CLI render with bundled ffmpeg and a documented macOS path [1][6][12][27].

## Fallback

**Revideo.** MIT, maintained, documented headless Node render with sandbox flag and parallel workers [4][21]; use it if Manim CE's Python/LaTeX/cairo install proves too heavy or its sandbox behaviour (unknown) fails.

## Best-fit concept types

- Manim CE: function plots, calculus and linear algebra transforms, geometry, vector fields, equation derivations, algorithm/data-structure step-throughs, physics diagrams.
- Revideo (fallback): 2D process/flow diagrams, code walkthroughs, parameterized templated explainers, text-and-shape narrations.

## Open items for downstream tickets

- Verify locally on a clean macOS: `manim checkhealth` time, install size with and without MacTeX/Typst, and a 1-minute scene's render time at `-qm` (no primary benchmark exists).
- Verify Manim CE behaviour in a restricted sandbox (no display, no network); the docs are silent.
- Decide whether plugin dependency docs recommend Typst (`manim[typst]`) over LaTeX to cut install friction.

## Sources

[1] https://github.com/ManimCommunity/manim (GitHub API: releases/latest v0.22.0 2026-10-08; pushed 2026-10-24; license MIT)
[2] https://github.com/3b1b/manim (API: tags v1.7.2; release 2024-12-13; pushed 2026-09-09; MIT)
[3] https://github.com/motion-canvas/motion-canvas (API: releases/latest v3.17.2 2024-12-14; tags v3.18.0-alpha.0, release 2025-02-16; commits: 2026-07-02 docs domain, then 2025-02-16)
[4] https://github.com/redotvideo/revideo (API: tags v0.11.0; commits 2026-07-10 "chore: release 0.11.0", latest 2026-07-15; MIT)
[5] https://github.com/remotion-dev/remotion (API: releases/latest v4.0.538 2026-10-22; license NOASSERTION)
[6] https://github.com/ManimCommunity/manim/blob/main/pyproject.toml
[7] https://github.com/remotion-dev/remotion/blob/main/LICENSE.md
[8] https://github.com/3b1b/manim (README: install, OpenGL/ffmpeg, macOS steps, Python 3.10+)
[9] https://motioncanvas.io/docs/quickstart
[10] https://github.com/redotvideo/revideo (README); docs redirect: https://docs.re.video/ -> https://midrender.com/revideo/docs
[11] https://www.remotion.dev/docs/miscellaneous/linux-dependencies
[12] https://docs.manim.community/en/stable/installation/uv.html
[13] https://docs.manim.community/en/stable/guides/using_text.html
[14] https://github.com/motion-canvas/motion-canvas/blob/main/packages/docs/docs/getting-started/rendering/video.mdx
[15] https://github.com/redotvideo/revideo/blob/main/packages/docs/src/content/guide/rendering-videos.mdx
[16] https://docs.manim.community/en/stable/tutorials/output_and_config.html
[17] https://docs.manim.community/en/stable/guides/configuration.html
[18] https://github.com/3b1b/manim/blob/main/manimlib/config.py (line: `show_in_window=not args.write_file`)
[19] https://motioncanvas.io/docs/rendering
[20] https://github.com/motion-canvas/motion-canvas/pull/1055 and https://github.com/motion-canvas/motion-canvas/issues/1218
[21] https://github.com/redotvideo/revideo/blob/main/packages/docs/src/content/api-reference/renderer/renderVideo.mdx
[22] https://docs.manim.community/en/stable/examples.html
[23] https://github.com/redotvideo/revideo/tree/main/packages/2d/src/lib/components (Latex.ts, Code.ts, Line.ts, Spline.ts; Motion Canvas ships the same 2D package)
[24] https://www.manim.community/
[25] https://www.3blue1brown.com/faq
[26] https://motioncanvas.io/
[27] https://docs.manim.community/en/stable/tutorials/output_and_config.html
[28] https://github.com/redotvideo/revideo/blob/main/packages/docs/src/content/guide/rendering-videos.mdx ("Rendering Speeds")
[29] https://github.com/redotvideo/revideo/blob/main/packages/docs/src/content/common-issues/slow-rendering.mdx
[30] https://www.remotion.dev/docs/performance
[31] https://www.remotion.dev/docs/terminology/concurrency
[32] https://www.remotion.dev/docs/cli/render
[33] https://docs.manim.community/en/stable/faq/general.html
