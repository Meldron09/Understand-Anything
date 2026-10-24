# Research: 3D, physics and simulation video (issue #9)

Date checked: 2026-10-24. Constraint: free/OSS, local only, primary target local macOS Claude Code (Apple Silicon). Terms: renderer, mode skill, lesson artifact, handoff.
Method: primary sources only (official docs, repos, PyPI/npm registries, release pages, license files). Nothing was installed or run, so every "sample quality" and "render time" claim is **not verified locally**. "unknown" = not established from primary sources.

## Comparison table

| Candidate | Maintenance (as of 2026-10-24) | License | macOS install friction | Headless CLI / sandbox | Sample quality (gallery, not verified locally) | Render cost per min of output | Scenes independent? |
|---|---|---|---|---|---|---|---|
| **Blender** (CLI or `bpy`) | v5.2.3, repo pushed today [1][2] | GPL-2.0+ / GPLv3 for binaries; Cycles Apache-2.0; output is yours [3] | Low: one app download; or `pip install bpy` (245 MB arm64 wheel, Python pinned to 3.13) [2][4]. Needs Apple Silicon, macOS 13+ [5] | Yes: `blender -b file.blend -a`, no display needed [6]; `bpy` module ~= `--background` [7]. EEVEE/Cycles-Metal on a restricted GPU-less sandbox: unknown | Highest of the set: official demo files include Physics and Simulation categories [8] | unknown (no primary figure). Path tracing is heavy; EEVEE is rasterized and faster [9]. Own estimate: minutes per second of output at 1080p | Yes by frame range `-s/-e`, or per `.blend`/scene `-S` [10]; physics must be baked first (own inference, see [11]) |
| **Manim CE** `ThreeDScene` (+ `manim-physics`) | v0.22.0, 2026-10-08, pushed today [12] | MIT [12] | Low-medium: `brew install cairo pkg-config`, then `uv add manim`; LaTeX optional [13] | Yes: `manim render file.py Scene`, writes mp4/gif/png, no window needed [14]. Sandbox: unknown (Cairo is CPU) | Gallery has `ThreeDSurfacePlot` etc. [15]; 3D is surfaces/axes/camera moves, not shaded scenes (own reading of the gallery) | unknown | Yes: one process per scene class; `-n` animation ranges [14] |
| **three.js + Rapier** in headless Chromium (Puppeteer) | three r186 (2026-09-24, MIT); Rapier JS 0.21.0 (2026-09-25, Apache-2.0); Puppeteer 25.16.0 (2026-10-22) [16][17][18] | MIT / Apache-2.0 | Medium: needs Node, an npm install, Puppeteer's browser download and ffmpeg [19] | Yes: headless is Puppeteer's default [20]; three.js runs its own e2e tests under Puppeteer [21]. Without a GPU, software WebGL needs `--enable-unsafe-swiftshader`, deprecated by Chromium [22] | three.js ships Rapier/Ammo/Jolt physics demos (`physics_rapier_*`) [23]. Game-like look | unknown | Yes: one page/URL per scene; frame-stepped capture is deterministic (own design inference) |
| **MuJoCo** (Python) | 3.17.0, 2026-10-22 [24] | Apache-2.0 [25] | Low: `pip install mujoco`, arm64 macOS wheels on PyPI [24][26] | Offscreen `mujoco.GLContext` exists [27]. Headless on macOS and in a sandbox: unknown (docs only say passive viewer needs `mjpython`) [27] | Accurate robotics/contact physics, utilitarian look; gallery quality not checked | unknown | Yes: independent processes per model |
| **PyBullet** (Bullet) | PyPI 3.2.7, 2025-01-30; repo pushed 2026-10-09; last GitHub release 3.25 (2022) [24][28] | zlib [29] | Medium: PyPI has an sdist only, no wheels, so it compiles on macOS [26] | unknown (the Quickstart Guide on Google Docs was not extractable here) | Basic | unknown | Yes |
| **Genesis** | v1.4.5, 2026-10-22 [30] | Apache-2.0 [31] | High: pure-Python wheel but needs PyTorch (MPS) and Quadrants/Metal; Nyx renderer extra [31] | Camera sensors with Pyrender/Luisa/Nyx backends; macOS headless: unknown [31] | README GIFs show good multi-physics (rigid, FEM, MPM, SPH) [31] | unknown | Yes |
| **Godot 4** movie mode | 4.7.2, 2026-08-18; pushed 2026-10-23 [32] | MIT [32] | Medium: app download, project scaffolding | `--write-movie out.avi --fixed-fps 30` is offline/non-real-time [33]; `--headless` swaps in a dummy display driver, so whether it can render a movie: unknown [34] | Real-time-engine look; the docs say Cycles/EEVEE look better but render slower [33] | unknown | Yes: one project/scene per run |
| **ManimGL** (3b1b) | PyPI/GitHub release v1.7.2, 2024-12-13; pushed 2026-09-09 [35] | MIT [35] | Needs OpenGL window, FFmpeg, optional LaTeX [35] | Needs an OpenGL context; headless: unknown | Same author's videos, not checked | unknown | Yes |
| **Taichi** | v1.7.4, 2025-07-31; repo pushed 2026-10-05 [30] | Apache-2.0 | arm64 macOS wheels exist [26] | It is a compute kernel language, not a video renderer; skipped | n/a | n/a | n/a |

## Per-candidate notes

**Blender.** The only candidate with a production-grade renderer plus built-in rigid body, cloth, fluid, soft body and particle systems; physics docs [11]. Headless use is the documented CLI path: arguments run in order and `-a`/`-f` must come last [6]. Python scripts (`-P`) or the `bpy` wheel cover the generative path a mode skill would use [7]. Caveats: `bpy` only edits one `.blend` per process, but multiple processes are fine [7]; the `bpy` wheel is not on the official download page and is pinned to Python 3.13 [2][7]; Metal GPU rendering is supported on Apple Silicon with macOS 13+ [9][5]. Biggest cost is authoring: scripts are verbose, and on-screen labels/equations are harder than in Manim (own assessment). Output files are yours; only published scripts that use the API must be GPL-compatible [3].

**Manim CE.** Healthiest of the Python scene libraries: released 2026-10-08, requires Python >=3.11 [12][13]. 3D is `ThreeDScene` with camera orientation/rotation, `Surface` and `ThreeDAxes` [15][36]. Very good for labelled explainers (MathTex, text), weak for photoreal or heavy physics. `manim-physics` 0.4.0 was last published 2024-04-17 and caps Python at <3.13, which conflicts with Manim's >=3.11 floor on 3.13+ [26]. Its repo was pushed 2026-10-15 (MIT) [37], so the PyPI package lags the repo. The OpenGL renderer is selectable (`--renderer=opengl`) but its docs are admittedly thin [14][38].

**three.js + Rapier + Puppeteer.** Web-native, interactive-friendly, so the same scene could double as an interactive explainer mode (own observation). Puppeteer `Page.screencast()` records WebM/VP9 at 30 fps but needs ffmpeg and is real-time, hence non-deterministic [19]; frame-stepped `screenshot()` plus ffmpeg is the repeatable route (own inference). Chromium deprecated automatic SwiftShader WebGL fallback and gates it behind a flag [22]; on a Mac with a GPU this matters less, in a GPU-less sandbox it does. Rapier JS 0.21.0 is Apache-2.0 [17]. `cannon-es` last published 2022-08-12, avoid [16].

**MuJoCo.** Best-maintained physics engine here and trivial to install on macOS [24][26]. Rendering is a means to inspect simulations, not to make polished video; use only if accuracy of contact dynamics matters. Headless on macOS: unknown.

**PyBullet.** Source-only on PyPI, last release Jan 2025, upstream issue tracker closed [26][28]. Dominated by MuJoCo.

**Genesis.** Impressive multi-physics but heavy dependency stack (PyTorch, Quadrants compiler, extra renderer package) and young; fails the "documented, low-friction dependencies" marketplace bar [31].

**Godot.** Movie Maker mode is genuinely offline and deterministic with `--fixed-fps`, but output is AVI/MJPEG then ffmpeg, and it is a game engine to author for [33]. No advantage over Blender for this plugin.

## Checks that stay unknown

- Real render seconds per minute of output on Apple Silicon for any candidate (no primary figures found; Blender Open Data has benchmark scores but its pages are script-rendered and were not extractable here, https://opendata.blender.org/).
- Whether EEVEE/Metal, MuJoCo GL, Godot or Chromium WebGL work inside a restricted, GPU-less sandbox. Treated as a flag: Blender CPU Cycles and Manim Cairo are the only ones whose design does not need a GPU context (own inference, not tested).

## Pick

**Blender, driven headless via `blender -b -P scene.py` (or `bpy`).** Only candidate with a real renderer and real physics, documented headless CLI, frame-range parallelism, free GPL app with output rights, and active (v5.2.3 this month).

## Fallback

**Manim CE `ThreeDScene` (with `pymunk`-style physics hand-rolled in Python).** Pure `pip`/`uv` plus Cairo, MIT, released 2026-10-08, labels/math for free, and likely already needed by the 2D/math video ticket, so zero extra dependency. Use it when Blender is absent or the concept needs only simple 3D (surfaces, vectors, camera moves). Runner-up for interactive overlap: three.js + Rapier.

## Best-fit concept types

Blender: rigid-body collisions, cloth/fluid/smoke, orbital and mechanical systems, anatomy/architecture fly-throughs. Manim 3D: surfaces, vector fields, geometry, linear algebra, wave plots. three.js + Rapier: browser-interactive mechanics. MuJoCo/Genesis: robotics and contact dynamics only.

## Sources

1. https://github.com/blender/blender (pushed 2026-10-24; tag v5.2.3; license reported as NOASSERTION by GitHub API, see [3])
2. https://pypi.org/project/bpy/ (5.2.3, GPL-3.0, `==3.13.*`, macOS arm64 wheel 245 MB, uploaded 2026-10-22)
3. https://www.blender.org/about/license/
4. https://docs.blender.org/api/current/info_advanced_blender_as_bpy.html
5. https://www.blender.org/download/requirements/
6. https://docs.blender.org/manual/en/latest/advanced/command_line/render.html
7. https://docs.blender.org/api/current/info_advanced_blender_as_bpy.html (single-.blend restriction, factory startup, multiprocessing)
8. https://www.blender.org/download/demo-files/ (Physics, Simulation, Rendering categories)
9. https://docs.blender.org/manual/en/latest/render/cycles/gpu_rendering.html and https://docs.blender.org/manual/en/latest/render/eevee/index.html
10. https://docs.blender.org/manual/en/latest/advanced/command_line/arguments.html (`-S`, `-s`, `-e`, `-f` ranges)
11. https://docs.blender.org/manual/en/latest/physics/rigid_body/world.html (cache/bake) and https://docs.blender.org/manual/en/latest/physics/introduction.html
12. https://github.com/ManimCommunity/manim (v0.22.0, 2026-10-08, MIT) and https://raw.githubusercontent.com/ManimCommunity/manim/main/pyproject.toml
13. https://docs.manim.community/en/stable/installation/uv.html
14. https://docs.manim.community/en/stable/guides/configuration.html (CLI flags, `--renderer`, `-n`, formats)
15. https://docs.manim.community/en/stable/examples.html
16. https://registry.npmjs.org/three, https://registry.npmjs.org/cannon-es
17. https://registry.npmjs.org/@dimforge%2Frapier3d and https://github.com/dimforge/rapier.js
18. https://registry.npmjs.org/puppeteer
19. https://pptr.dev/api/puppeteer.page.screencast
20. https://pptr.dev/guides/headless-modes
21. https://raw.githubusercontent.com/mrdoob/three.js/dev/test/e2e/puppeteer.js and package.json (`--mode=headless`)
22. https://chromium.googlesource.com/chromium/src/+/da170c2267b2201954efe1c8fa5d2d89ab09f7bf/docs/gpu/swiftshader.md
23. https://raw.githubusercontent.com/mrdoob/three.js/dev/examples/files.json
24. https://pypi.org/project/mujoco/ ; https://github.com/google-deepmind/mujoco/releases (3.17.0, 2026-10-22)
25. https://raw.githubusercontent.com/google-deepmind/mujoco/main/LICENSE
26. PyPI JSON metadata: https://pypi.org/pypi/{mujoco,pybullet,manim-physics,genesis-world,taichi}/json (wheel lists, dates, python bounds)
27. https://mujoco.readthedocs.io/en/stable/python.html
28. https://raw.githubusercontent.com/bulletphysics/bullet3/master/README.md
29. https://raw.githubusercontent.com/bulletphysics/bullet3/master/LICENSE.txt
30. https://github.com/Genesis-Embodied-AI/Genesis/releases ; https://github.com/taichi-dev/taichi/releases
31. https://raw.githubusercontent.com/Genesis-Embodied-AI/Genesis/main/README.md
32. https://github.com/godotengine/godot/releases (4.7.2-stable, 2026-08-18)
33. https://raw.githubusercontent.com/godotengine/godot-docs/master/tutorials/animation/creating_movies.rst
34. https://raw.githubusercontent.com/godotengine/godot-docs/master/tutorials/editor/command_line_tutorial.rst (`--headless` = headless display driver)
35. https://github.com/3b1b/manim ; https://raw.githubusercontent.com/3b1b/manim/master/README.md
36. https://docs.manim.community/en/stable/reference/manim.scene.three_d_scene.ThreeDScene.html
37. https://github.com/Matheart/manim-physics (MIT, pushed 2026-10-15)
38. https://docs.manim.community/en/stable/faq/opengl.html
