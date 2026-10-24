# Research: code-walkthrough videos (issue #5)

Question: which free/OSS, local tools produce code-walkthrough videos (animated code, step highlighting, typing/diff animation)? Checked 2026-10-24 against primary sources only (official docs, source repos, GitHub API, license files). Nothing was installed or rendered. "Not verified locally" marks sample-quality claims taken from a project's own docs or gallery. "Unknown" means primary sources did not establish it.

## Comparison table

| Item | Revideo | Manim Community | Motion Canvas | Remotion | VHS (terminal only) |
|---|---|---|---|---|---|
| Maintenance (vs 2026-10-24) | Active. Last commit 2026-07-15; tag v0.11.0 on 2026-07-10 [1][2] | Very active. Last push 2026-10-24; v0.22.0 on 2026-10-08 [3] | Stalled. Last release v3.17.2 on 2024-12-14; last non-docs commit 2025-02-16 [4] | Very active. v4.0.538 on 2026-10-22 [5] | Active. v0.12.1 on 2026-09-24 [6] |
| License | MIT [1] | MIT [3] | MIT [4] | Custom source-available, not OSI. Free for individuals, for-profits up to 3 employees, and non-profits; larger for-profits need a paid license [7] | MIT [6] |
| Fits "free/OSS"? | Yes | Yes | Yes | Conditional: fails for larger companies and for redistribution as a derivative [7] | Yes |
| Install friction (macOS) | `npm init @revideo@latest`, Node 16+ [8]. Puppeteer (`^25.3.0`) downloads Chrome into `~/.cache/puppeteer` [9][10]. ffmpeg comes via the `@ffmpeg-installer/ffmpeg` npm dep [11] | `brew install cairo pkg-config`, then `uv add manim`. Python >=3.11 [12][13]. ffmpeg not needed (depends on `av`). LaTeX and Typst optional [12][13] | npm project. Chrome-based. Rendering is documented only through the editor UI [14] | npm project. Auto-downloads Chrome Headless Shell into `node_modules` [15] | `brew install vhs`. Needs `ttyd` and `ffmpeg` on PATH, or use Docker [16] |
| Headless CLI render | Yes. `renderVideo()` (Node API) drives headless Puppeteer plus WebCodecs. It also runs serverless [8][17][18][29] | Yes. `manim <file> <Scene>` writes MP4. Live preview is OpenGL-only, so the Cairo renderer needs no window (my inference from [19]) | Not documented. The rendering page describes only the editor Render button, which writes PNG/JPEG/WebP frames [14]. Revideo is the headless fork [20] | Yes. `npx remotion render <id>` [21] | Yes. `vhs file.tape`, also in CI and Docker [16] |
| Restricted-sandbox flag | Unknown. Needs a Chrome launch; source forces `--single-process` [18] | Unknown. No browser needed, but needs native cairo | Unknown | Unknown. Needs a Chrome launch | Unknown. Needs ttyd and ffmpeg |
| Native code animation | Yes. `<Code>` supports `replace`/`prepend`/`append` edits, animated diffs and `selection` highlight; Lezer grammars give syntax colours [22]. Typing effect: unknown (a `streaming-text` docs page exists [23], contents not read; `append` is the likely route) | Partial. `Code` is a static highlighted listing (Pygments, line numbers, window or rectangle background). The docs list no highlight or diff animation. Step highlighting needs hand-built shapes or `.animate` [24] | Yes. Same Code component: animated edits, `insert`/`remove`/`edit`, selection with desaturated rest. Docs do not mention typing [25] | Via the Code Hike template. It animates between snippets and supports TypeScript error annotations. Docs do not say whether the animation is diff-style [26][27] | Typing is native (`Type@500ms`). No code diff or highlighting, only the shell [16] |
| Sample quality | Docs embed a live preview of the Code example [22]. Not verified locally | The gallery shows stills, not video. I found no Code example in the first 100k characters of the page [28]. Not verified locally | Docs embed live examples [25]. Not verified locally | The template page links to a live Studio preview, no rendered video [26]. Not verified locally | None judged. Output is a terminal GIF/MP4/WebM [16]. Not verified locally |
| Best-fit concept types | Code-edit narratives, before/after refactors, API call walkthroughs, step-by-step build-ups | Math, algorithms, data structures and diagrams, with code as a side panel | Same as Revideo | Same as Revideo, with a React component ecosystem | CLI demos, shell workflows, install steps |
| Render time per minute of output | Docs claim faster than real-time since v0.4.6; no numbers [29]. Not verified locally | Unknown. Quality presets: `-ql` 854x480 at 15 fps, `-qm` 720p at 30 fps, `-qh` 1080p at 60 fps [19] | Unknown | Unknown. Docs give no per-minute numbers [30] | Unknown |
| Cost per minute | $0, local | $0, local | $0, local | $0 locally (license permitting) [7] | $0, local |
| Scenes render independently? | Yes, within one video. `workers` splits frame ranges across workers and concatenates. `renderPartialVideo()` plus `concatenateMedia()` is the documented route for parallel renders. Docs warn this is memory-hungry [29][31] | Yes. Each `Scene` class is rendered by name per CLI call [32]. `-a` renders all in one process. `--max-inflight-encoders` overlaps encoding only [19]. No built-in cross-scene parallelism | Unknown | Yes. `--frames` ranges and `--concurrency` (browser tabs in parallel) [21][33] | Yes. One tape is one file |

## Per-candidate notes

**Revideo.**
- A fork of Motion Canvas that adds headless rendering, audio and a library-first API [20].
- Rendering is a Node process. The Puppeteer browser draws each frame to a canvas and encodes through WebCodecs. ffmpeg only handles audio and merging [29].
- Its Code component is the most complete fit for "animated code": diff-style replace/prepend/append and selection highlighting [22].
- The repo moved from `redotvideo/revideo` to `midrender/revideo`. Update any hard-coded URL [1].
- Maintenance is moderate. Commits are still dated July 2026 and the last tag is 2026-07-10, about 3.5 months before today. That is fine, but it is a small team's project (about 4k stars).
- Telemetry counts rendered videos anonymously. Set `DISABLE_TELEMETRY=true` to turn it off [17].
- It needs Chrome (via Puppeteer), so a restricted sandbox may block it. Not established.

**Manim Community.**
- Mature, large community, still actively released [3].
- Everything is Python. Installing it needs only brew's cairo and pkg-config, plus uv [12].
- `Code` gives syntax-coloured listings, but animated highlight or diff has no documented API [24]. Line spotlight and edit animation would have to be hand-built from generic mobjects.
- Strongest where the walkthrough is mostly diagrams, math or algorithm visuals, with code as context.
- Rendering uses no browser, which is the likeliest to survive a restricted sandbox. Not verified.

**Motion Canvas.**
- Best-in-class Code animation [25], but no documented headless path [14] and no release since 2024-12 [4]. Revideo supersedes it for our use.
- Only a docs change landed in 2026 (2026-07-02).

**Remotion.**
- Fastest-moving project, and headless is first-class [15][21]. The Code Hike template covers snippet-to-snippet animation [26].
- The license is the blocker. It is source-available with a company-size gate [7], and the license file says terms change in Remotion 5.0 [7]. That conflicts with "free/OSS" for a marketplace plugin whose users may be at larger companies.
- Do not pick. A paid path may be noted in passing.

**VHS.**
- Does one thing: terminal sessions to GIF/MP4/WebM [16]. Useful as a supplement for CLI-shaped lessons, not as the code-walkthrough renderer.
- Not a code-editor animation tool.

**Not evaluated in depth.**
- 3b1b/manim (ManimGL): last release 2024-12-13 [35]. The Community fork is the documented, packaged option.
- Slidev and Code Hike used alone are not video tools.

## Pick and Fallback

**Pick: Revideo.** It is the only MIT, headless, actively maintained tool that ships first-class animated code (replace/prepend/append diffs and selection highlight) and a documented parallel render path [22][29][31].

**Fallback: Manim Community.** It is MIT, very actively maintained and browser-free (Python + cairo). Code highlight animation must be built by hand [3][12][24].

**Best-fit concept types:**
- Revideo: code-edit narratives, refactors and before/after, API and step-by-step build-ups.
- Manim CE: algorithms, data structures, math, system diagrams (as fallback).
- VHS: CLI and shell demos (optional supplement).

## Caveats for the spec

- Sample quality was not verified locally. Revideo, Motion Canvas and Remotion offer only live in-docs previews. Manim's gallery was stills only in the section read [22][25][26][28].
- Render speed and cost per minute are unknown for everyone except Revideo's own "faster than real-time" claim [29]. Plan a benchmark in the build phase.
- Restricted-sandbox headless viability is unknown for all candidates. Browser-based tools need a Chrome download and launch (Puppeteer or Remotion). Manim needs native cairo. A graceful-degradation-to-text path is required either way.
- Revideo is Node plus Chrome; Manim needs Python 3.11+, brew and uv. Two toolchains are a real cost if both are supported, so the spec should decide whether to ship the fallback in v1.

## Sources

1. https://github.com/midrender/revideo (MIT; commits and tags read via `gh api` 2026-10-24; formerly redotvideo/revideo)
2. https://github.com/midrender/revideo/tags
3. https://github.com/ManimCommunity/manim (MIT; `gh api` repo and `releases/latest`: v0.22.0, 2026-10-08)
4. https://github.com/motion-canvas/motion-canvas (MIT; `releases/latest` v3.17.2, 2024-12-14; commit list)
5. https://github.com/remotion-dev/remotion/releases (v4.0.538, 2026-10-22)
6. https://github.com/charmbracelet/vhs (MIT; v0.12.1, 2026-09-24)
7. https://github.com/remotion-dev/remotion/blob/main/LICENSE.md
8. https://github.com/midrender/revideo/blob/main/packages/docs/src/content/guide/installation-and-setup.mdx
9. https://github.com/midrender/revideo/blob/main/packages/renderer/package.json
10. https://pptr.dev/guides/configuration
11. https://github.com/midrender/revideo/blob/main/packages/ffmpeg/package.json
12. https://docs.manim.community/en/stable/installation/uv.html
13. https://github.com/ManimCommunity/manim/blob/main/pyproject.toml
14. https://motioncanvas.io/docs/rendering
15. https://www.remotion.dev/docs/chrome-headless-shell
16. https://github.com/charmbracelet/vhs/blob/main/README.md
17. https://github.com/midrender/revideo/blob/main/README.md
18. https://github.com/midrender/revideo/blob/main/packages/renderer/server/render-video.ts
19. https://docs.manim.community/en/stable/guides/configuration.html
20. https://midrender.com/revideo
21. https://www.remotion.dev/docs/render and https://www.remotion.dev/docs/cli/render
22. https://github.com/midrender/revideo/blob/main/packages/docs/src/content/animations/code-animations.mdx
23. https://github.com/midrender/revideo/blob/main/packages/docs/src/content/code-snippets/streaming-text.mdx
24. https://docs.manim.community/en/stable/reference/manim.mobject.text.code_mobject.Code.html
25. https://motioncanvas.io/docs/code-block
26. https://www.remotion.dev/templates/code-hike
27. https://github.com/remotion-dev/template-code-hike (package.json: `codehike` 1.0.4)
28. https://docs.manim.community/en/stable/examples.html
29. https://github.com/midrender/revideo/blob/main/packages/docs/src/content/guide/rendering-videos.mdx
30. https://www.remotion.dev/docs/performance
31. https://github.com/midrender/revideo/pull/74 and https://github.com/midrender/revideo/blob/main/packages/docs/src/content/common-issues/slow-rendering.mdx
32. https://docs.manim.community/en/stable/tutorials/quickstart.html
33. https://www.remotion.dev/docs/terminology/concurrency
35. https://github.com/3b1b/manim (`releases/latest` v1.7.2, 2024-12-13)
