# Research: data and chart animation (issue #6)

Question: which tools animate data and charts as video (free/OSS, local only)? Checked 2026-10-24 against primary sources only (GitHub API/repos, official docs). Nothing was installed or run: all "sample quality" and speed statements are **not verified locally**. "unknown" = not established from primary sources.

## Comparison

| | Remotion | Revideo | Manim Community | Motion Canvas | matplotlib animation | bar_chart_race |
|---|---|---|---|---|---|---|
| Latest release / activity | v4.0.538, 2026-10-22; pushed 2026-10-24 [1] | v0.11.0, 2026-07-10; last commit 2026-07-15 [2] | v0.22.0, 2026-10-08; pushed 2026-10-24 [3] | v3.17.2, 2024-12-14; last real feature 2025-02, last commit 2026-07 (docs) [4] | v3.11.2, 2026-09-11 [5] | Dormant: last default-branch commit 2020-07 [6] |
| License | Custom "source-available": free for individuals, for-profit orgs up to 3 employees, non-profits; paid Company License above that [7] | MIT [2] | MIT [3] | MIT [4] | matplotlib License (BSD-style, PSF-derived; name per LICENSE file) [5] | MIT [6] |
| Install friction (macOS) | `npx create-video@latest`; needs Node or Bun, **macOS 15+** [8]; auto-downloads Chrome Headless Shell into `node_modules` [9]; ffmpeg bundled via `@remotion/compositor-*` packages [10] | `npm init @revideo@latest` [2]; Node >=22.12 [11]; depends on `puppeteer` (browser download) and `@ffmpeg-installer/ffmpeg` (bundled) [12] | `uv add manim` plus `brew install cairo pkg-config`; LaTeX (MacTeX) **optional**, only for formulas [13]; Python >=3.11, ffmpeg via PyAV (`av>=15`) dependency [14] | `npm init @motion-canvas@latest`, Node >=16 [15]; video export is an editor-UI button [16] | `pip install matplotlib`; GIF via Pillow needs nothing else; mp4 needs a separate ffmpeg (docs suggest `imageio_ffmpeg`) [17] | `pip install bar_chart_race` [6]; also needs matplotlib and ffmpeg for mp4 (ffmpeg note: unknown from README) |
| Headless CLI / sandbox | Yes: `npx remotion render <id> [out]` [18]; Node API `bundle`/`renderMedia` [19]. Drives Chrome Headless Shell; Linux needs extra system libs [20]. Sandbox: unknown (no Chrome sandbox-flag guidance found) | Yes: `renderVideo()` headless API, runs "anywhere Node and a headless browser run" [2]; code forces Puppeteer `--single-process` [21]. Sandbox: unknown | Cairo renderer is the default; the CLI has `--dry_run` that "disables the window" [22]; no GPU or window needed is not stated explicitly (unknown); Docker image exists [23] | Docs describe only editor-driven rendering, frames written as PNG/JPEG/WebP to `/output` [16]; no first-party headless path found. Flag: **no** | Yes: `Animation.save()` writes files directly [17]; explicit headless/Agg statement not read from primary docs (unknown) | Yes in principle (matplotlib `save`) [6] |
| Sample output quality (**not verified locally**) | Official showcase is mostly marketing/product video [24]; data examples exist: D3, bar-race, GitHub Unwrapped, weather [25] | Examples folder in repo; quality unknown | Docs gallery has plots, `ValueTracker`, area-under-curve, `BarChart` with rendered PNGs [26][27]; embedded video quality unknown | Editor-first; no gallery link on quickstart [15]; quality unknown | Plain scientific-style charts; GIF/mp4 [17] | README promises bar/line "races" (GIF/mp4) [6] |
| Best-fit concept types | Dashboards, bar races, KPI/time-series, D3 charts, maps, text+chart explainers (any React/web lib) | Vector explainers, simple data motion, voice-synced scenes | Math, functions/plots, algorithms, geometry, graphs; simple bar charts | Vector explainers synced to voice-over [4] | Time series, distributions, simple curve/field animation | Ranked-category change over time only |
| Render time / cost per minute of output | unknown (docs say performance depends on code and hardware; `--concurrency`, `npx remotion benchmark` exist) [28]; frame count = fps x 60; Chrome screenshot per frame | unknown; slow-rendering page exists but not read | unknown; presets l=854x480@15fps, m=720p@30, h=1080p@60 so `-ql` is cheap for drafts [29] | unknown | unknown | unknown |
| Scenes render independently? | **Yes**: `--frames=0-99,150-199` ranges [30]; documented chunk render + `combineChunks()` with identical options and equal-length non-final chunks [31]. Warns against rendering >1 video at once in one process [32] | **Yes**: `workers` option splits the video across Puppeteer+Vite workers and concatenates; `renderPartialVideo` returns per-worker pieces [21] | **Yes, by design**: one Scene class per `manim` invocation; partial movie files are cached per animation [29]. Cross-scene concat is the caller's job (ffmpeg) | Unknown | Yes (each script/figure independent) | Single call per chart |

## Candidate notes

**Remotion.** Strongest ecosystem fit: React components, so D3 and any web charting library work; official D3 example and community bar-race/data-video templates [25]. Official Agent Skills (`npx skills add remotion-dev/skills`, slash commands incl. `/remotion-render`) explicitly target Claude Code [33], which fits the **mode skill** / **renderer** model well. Friction: macOS 15+ [8], Chrome Headless Shell download on first render [9], Node/Bun. **License caveat**: not OSI open source; free only for individuals, up to 3-employee for-profits and non-profits [7]. A learner at a larger company would need a paid Company License. Remotion 5.0 (unreleased) will change the license: contractors will count toward team size and terms are rewritten [34]. Document this in the plugin's dependency notes and degrade to the fallback if the user opts out.

**Revideo.** Fork-in-spirit of Motion Canvas built for headless server rendering; MIT [2]. Repo has moved to `midrender/revideo` (docs now at midrender.com) [2][12]; commercially backed by Midrender, small community (4.1k stars) and fewer releases than Remotion. Built-in `workers` parallelism and `renderPartialVideo` give the best "scenes render independently" story in the JS group [21]. Needs Node >=22.12 [11]. API is a TypeScript scene graph (generators), not a React/D3 workflow, so charts need hand-building.

**Manim Community.** Mature, MIT, very actively released [3]. Python only, no browser. Best for math/algorithm/graph concepts; has `Axes`, plotting and `BarChart` [27] but it is not a data-dashboard tool. LaTeX is optional (needed only for formulas) [13]. Likely belongs primarily to a sibling math-animation ticket; here it is a relevant fallback for chart-plus-equation scenes. 3b1b/manim (ManimGL) is a separate project: last release v1.7.2 in 2024-12 though commits continue [35]; not recommended for marketplace use (OpenGL window).

**Motion Canvas.** MIT, editor-centric; rendering is a button in the browser editor that writes image sequences [16]. No first-party headless path found; feature development appears paused (last feature commit 2025-02, v3.17.2 from 2024-12 and an alpha tag) [4]. Rejected for a CLI renderer.

**matplotlib animation.** Zero new ecosystem if the learner already has Python. `FuncAnimation` + `PillowWriter` gives GIF with no extra binary; mp4 needs ffmpeg installed separately [17]. Good as a lightweight graceful-degradation tier (also `HTMLWriter`), not for polished video.

**bar_chart_race.** Dormant since 2020 [6]; single chart type. Rejected on maintenance.

## Pick and fallback

**Pick: Remotion.** Only candidate with a first-party D3/data-video path, an official Claude Code skill set, bundled ffmpeg, frame-range/chunk rendering, and daily releases; caveat is its source-available license (free for individuals), which the plugin must document and which makes the fallback matter.

**Fallback: Revideo** (MIT, headless `renderVideo` with built-in parallel `workers`, active as of July 2026), with **matplotlib animation (Pillow GIF)** as the zero-dependency last tier before text. If the map later requires strict OSI-OSS, promote Revideo (or Manim CE for math-leaning content) to pick.

**Best-fit concept types:** time series and KPI/dashboard explainers, ranked/bar-race comparisons, D3-style charts, map/geo data, and chart-plus-narration segments (Remotion); equation/function/algorithm visuals go to Manim CE.

## Open items (unknown from primary sources)

- Render time and cost per minute of output for every candidate.
- Whether Remotion and Revideo render inside Claude Code's restricted sandbox (Chrome sandbox flags, network for the Chrome download).
- Actual gallery video quality for each tool (not verified locally).
- Manim Community's explicit headless statement and ffmpeg handling beyond the `av` dependency.

## Sources

1. https://github.com/remotion-dev/remotion (GitHub API: releases/latest v4.0.538 2026-10-22; `pushed_at` 2026-10-24; license field NOASSERTION)
2. https://github.com/midrender/revideo (API: MIT, v0.11.0 tag, last commits 2026-07; README https://raw.githubusercontent.com/redotvideo/revideo/main/README.md)
3. https://github.com/ManimCommunity/manim (API: MIT; releases v0.22.0 2026-10-08)
4. https://github.com/motion-canvas/motion-canvas (API: MIT; latest release v3.17.2 2024-12-14; commits listing 2026-07-02 docs, 2025-02-16 feature) and https://raw.githubusercontent.com/motion-canvas/motion-canvas/main/README.md
5. https://github.com/matplotlib/matplotlib (API: release v3.11.2 2026-09-11) and https://raw.githubusercontent.com/matplotlib/matplotlib/main/LICENSE/LICENSE
6. https://github.com/dexplo/bar_chart_race (API: MIT, last commit 2020-07-30, no releases) and https://raw.githubusercontent.com/dexplo/bar_chart_race/master/README.md
7. https://raw.githubusercontent.com/remotion-dev/remotion/main/LICENSE.md
8. https://raw.githubusercontent.com/remotion-dev/remotion/main/packages/docs/docs/getting-started.mdx
9. https://www.remotion.dev/docs/miscellaneous/chrome-headless-shell
10. https://github.com/remotion-dev/remotion/blob/main/packages/renderer/package.json (`@remotion/compositor-*` deps) and https://www.remotion.dev/docs/miscellaneous/linux-dependencies (nixOS section: ships own Chrome and FFmpeg binaries)
11. https://github.com/midrender/revideo/blob/main/package.json (`engines.node >=22.12.0`)
12. https://github.com/midrender/revideo/blob/main/packages/renderer/package.json and `packages/ffmpeg/package.json`
13. https://docs.manim.community/en/stable/installation/uv.html and https://docs.manim.community/en/stable/installation/conda.html
14. https://raw.githubusercontent.com/ManimCommunity/manim/main/pyproject.toml (`requires-python >=3.11`, `av>=15.0`; PyAV-bundles-ffmpeg link is an inference)
15. https://motioncanvas.io/docs/quickstart
16. https://motioncanvas.io/docs/rendering
17. https://matplotlib.org/stable/users/explain/animations/animations.html (writers, "ffmpeg and imagemagick need to be separately installed"); Agg/headless remark is from general knowledge, not the page
18. https://www.remotion.dev/docs/render
19. https://raw.githubusercontent.com/remotion-dev/remotion/main/packages/docs/docs/ssr.mdx and https://raw.githubusercontent.com/remotion-dev/remotion/main/packages/docs/docs/dataset-render.mdx
20. https://www.remotion.dev/docs/miscellaneous/linux-dependencies
21. https://raw.githubusercontent.com/redotvideo/revideo/main/packages/renderer/server/render-video.ts
22. https://docs.manim.community/en/stable/guides/configuration.html
23. https://docs.manim.community/en/stable/installation.html
24. https://www.remotion.dev/showcase
25. https://www.remotion.dev/docs/resources
26. https://docs.manim.community/en/stable/examples.html
27. https://docs.manim.community/en/stable/reference/manim.mobject.graphing.probability.BarChart.html
28. https://raw.githubusercontent.com/remotion-dev/remotion/main/packages/docs/docs/performance.mdx
29. https://docs.manim.community/en/stable/guides/configuration.html (quality presets, caching of video segments)
30. https://raw.githubusercontent.com/remotion-dev/remotion/main/packages/docs/docs/cli/render.mdx
31. https://raw.githubusercontent.com/remotion-dev/remotion/main/packages/docs/docs/distributed-rendering.mdx
32. https://raw.githubusercontent.com/remotion-dev/remotion/main/packages/docs/docs/dataset-render.mdx
33. https://raw.githubusercontent.com/remotion-dev/remotion/main/packages/docs/docs/ai/skills.mdx
34. https://raw.githubusercontent.com/remotion-dev/remotion/main/packages/docs/docs/5-0-migration.mdx
35. https://github.com/3b1b/manim (API: MIT, release v1.7.2 2024-12-13, last commit 2026-09-09)
