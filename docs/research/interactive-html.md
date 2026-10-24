# Research: interactive HTML explainer tooling (issue #15)

Question: which approach fits a self-contained interactive-HTML **lesson artifact** (one file, works offline, opens by double-click)? Constraints from the map (#1): free/OSS, local only, local macOS Claude Code primary. Researched 2026-10-24 against primary sources only (repo metadata via GitHub API, release pages, official docs, MDN). Nothing was installed or run; rendering quality and agent authoring effort are **not verified locally** and are marked as my assessment.

## The portability rule that decides most of this

Opening an `.html` by double-click gives a `file://` page. Browsers treat local files as opaque origins and limit CORS requests to HTTP(S) ([MDN: CORS request not HTTP](https://developer.mozilla.org/en-US/docs/Web/HTTP/Guides/CORS/Errors/CORSRequestNotHttp)). Consequences:

- Anything that `fetch()`es a sibling file (wasm, data, textures, ES module `src=`) is at risk. MDN lists `fetch()`, XHR, web fonts and WebGL textures among CORS-governed requests.
- Inline code is safe: a `<script>` whose body contains the whole library needs no network or extra request. So "can the lib be inlined as one text blob?" is the portability test. Inlined libs add to file size and carry their license notice.
- MDN does not mention module scripts specifically; an inline `<script type="module">` with no imports is the unaffected case (my inference, not verified locally).

## Comparison

Sizes are minified file sizes from the npm package file listing on the [jsDelivr data API](https://data.jsdelivr.com/v1/packages/npm/d3@7.9.0?structure=flat) (a CDN mirror of the npm tarball, not the project itself; same endpoint with each package name/version), uncompressed. Maintenance = latest release and last push as seen via the GitHub API on 2026-10-24.

| Approach | Single-file portability (offline, double-click) | License | Size (min, uncompressed) | Maintenance (2026-10-24) | Agent authoring effort (my assessment) | Best-fit concept types |
|---|---|---|---|---|---|---|
| **Vanilla JS + inline SVG/CSS** (no library) | Best. Nothing to fetch, no CDN, nothing to inline. Pure browser APIs. | n/a (no third-party code) | 0 KB library | n/a (web platform) | Low for simple widgets (sliders, step-through, toggles, state machines, flowcharts); rises for chart axes/scales and layout, which the agent must hand-code. | Algorithm step-through, state machines, process flows, parameter sliders, quizzes, simple function plots, diagrams with hover/click. |
| **D3 v7** | Good. Ships a prebuilt UMD `dist/d3.min.js` (package.json `jsdelivr`/`unpkg` entry); inline it in a `<script>`. No fetches at runtime. | ISC ([repo](https://github.com/d3/d3)) | `d3.min.js` 279,706 B (~273 KB) | v7.9.0 released 2024-03-12 ([release](https://github.com/d3/d3/releases/tag/v7.9.0)); repo pushed 2026-10-21, not archived. Mature, slow release cadence. | Medium. Agents know D3 well, but the data-join/scale API has more ways to go wrong than plain SVG; no built-in widgets. | Data viz, scales/axes, force graphs, trees/hierarchies, treemaps, geo maps, animated transitions, distributions. |
| **Observable Plot** | Fair. UMD build `dist/plot.umd.min.js` needs a `d3` global (its file header `require`s `d3@7.9.0/dist/d3.min.js`), so D3 must be inlined too. | ISC ([repo](https://github.com/observablehq/plot)) | 209,183 B + D3 279,706 B = ~478 KB | v0.6.17 released 2025-02-14 ([releases](https://github.com/observablehq/plot/releases)); repo pushed 2026-09-01. Pre-1.0, slow cadence. | Low-medium for tabular charts (concise API); less control than D3. | Quick statistical charts from tabular data (scatter, histogram, line). Not for custom diagrams. |
| **JSXGraph** | Good. `jsxgraphcore.js` + `jsxgraph.css` can be local copies instead of a CDN, per its [README](https://github.com/jsxgraph/jsxgraph); no dependencies. The CSS must be inlined too. | Dual LGPL or MIT per README (GitHub's detector shows LGPL-3.0) | `jsxgraphcore.js` 995,055 B (~972 KB) | v1.14.1 released 2026-10-21 ([releases](https://github.com/jsxgraph/jsxgraph/releases)); repo pushed 2026-10-24. Very active. | Medium. Specialised API (`JXG.JSXGraph.initBoard`); depth of agent knowledge unknown. | Interactive geometry, function plotting, draggable constructions, calculus and linear-algebra visuals. |
| **p5.js** | Good. The [download page](https://p5js.org/download/) offers a single-file `p5.min.js` ("No additional contents are included") loaded by script tag, so it can be inlined. p5.sound is listed there only as a CDN link, so avoid sound. | LGPL-2.1 (GitHub-detected on the [repo](https://github.com/processing/p5.js)). Inlining obligations not assessed. | `p5.min.js` 990,638 B (~967 KB) | v2.3.4 released 2026-09-25 ([releases](https://github.com/processing/p5.js/releases)); repo pushed 2026-10-24. Very active. | Low-medium. Simple `setup()/draw()` model; canvas output is not selectable/accessible text. | Physics/particle sims, visual-intuition toys, cellular automata, random walks, frame-loop animation. |
| **Three.js** | Weak. Current builds are ES modules and split: `build/three.module.js` plus `build/three.core.js`; `build/` has no minified or UMD file (GitHub API listing, r186). The [installation doc](https://github.com/mrdoob/three.js/blob/dev/manual/pages/installation.html) recommends npm plus a build tool, or CDN/import maps. Single-file therefore needs a bundler step (e.g. esbuild) to inline: plausible, **not verified locally**, adds Node tooling. | MIT ([LICENSE](https://github.com/mrdoob/three.js/blob/dev/LICENSE)) | `three.module.js` 662,772 B + `three.core.js` 1,458,113 B = ~2.1 MB unminified (tree-shaken bundle size: unknown) | r186 released 2026-09-24 ([releases](https://github.com/mrdoob/three.js/releases)); repo pushed 2026-10-24. Very active. | High. Scene, camera, renderer, lights, loop, resize; more room for black-screen failures the agent cannot see. | True 3D only: molecules, 3D geometry, orbits, 3D vector fields. Overkill for nearly everything else. |
| **Pyodide** (CPython in WASM) | Poor. Its [FAQ](https://pyodide.org/en/stable/usage/faq.html) says browser JS is not allowed to load local data files (`file:///...`) and you get network errors from the Same Origin Policy; its [deployment doc](https://pyodide.org/en/stable/usage/downloading-and-deploying.html) says "You will need to serve these files yourself", suggesting `python -m http.server`. So double-click opening is **not** supported; a local server breaks the double-click requirement. Inlining the runtime into one HTML: unknown (not documented). | MPL-2.0 ([repo](https://github.com/pyodide/pyodide)) | Full distribution tarball 337,536,678 B (~322 MB); `pyodide-core` tarball 6,757,104 B (~6.4 MB) ([release 314.0.7](https://github.com/pyodide/pyodide/releases/tag/314.0.7)); the doc says the distribution is "quite large (200+ megabytes)" | 314.0.7 released 2026-09-14; Python 3.14.2 since 314.0.0 ([changelog](https://pyodide.org/en/stable/project/changelog.html)); repo pushed 2026-10-23. Very active. | Medium-high: reproducible Python, but load/startup handling, package loading, and a server requirement. | Live Python/numerical computation, "edit and run this code" lessons, numpy/scipy. Only when a local server is acceptable. |

## Findings by criterion

- **Offline / no CDN:** vanilla, D3, JSXGraph and p5 can all be one HTML with the library inlined (D3 and p5 ship a single prebuilt file; JSXGraph ships a JS file plus a CSS file). Three.js and Pyodide cannot without extra steps.
- **Size budget:** inlining D3 adds ~0.27 MB; p5 or JSXGraph ~1 MB. Fine for a local file. Design note for the mode skill: have a template/script splice the library into the file so the model never emits it, keeping tokens low.
- **Licensing:** all candidates are free/OSS. p5 (LGPL-2.1) and JSXGraph (LGPL or MIT) carry copyleft options that apply to the library. Whether inlining triggers notice obligations was not assessed; keep each library's license header in the file.
- **Maintenance:** all active as of 2026-10-24. D3's last release is ~2.6 years old though its repo is still pushed; Plot's last release is 2025-02-14.

## Gaps / not verified

- No sample output was rendered or screenshotted for any candidate: quality "not verified locally".
- Whether Pyodide can be inlined into a single file, and Three.js bundle size after tree-shaking: **unknown**.
- Browser differences (Chrome/Safari/Firefox) for inline module scripts on `file://`: not verified.
- Agent authoring effort ratings are my judgment from API surface, not a measured benchmark.
- p5's `LICENSE` file could not be read through the API; license taken from the repo's detected license.

## Pick

**Vanilla JS + inline SVG/CSS** as the default renderer for the interactive-explainer mode skill. Zero dependencies and nothing to inline, so it meets the double-click, offline, no-CDN constraint by construction. It covers the step-through, slider and diagram concept types that dominate learning use, and keeps the lesson artifact small and inspectable.

Add-on rule for the mode skill: when a concept needs data scales/axes, hierarchies or force layouts, inline `d3.min.js` (ISC, ~273 KB) instead of hand-coding them.

## Fallback

**D3 v7 inlined (`dist/d3.min.js`)** if vanilla proves too laborious or error-prone for data-heavy concepts in agent testing. Next tiers by concept type: p5.js (frame-loop simulations, LGPL-2.1), JSXGraph (math/geometry). Three.js and Pyodide are not defaults: Three.js needs a bundler to be single-file, and Pyodide fails the double-click requirement (needs a local server). A mode skill could offer Pyodide as an explicit opt-in that launches `python -m http.server`, with a text fallback.
