# Video renderers

Read by the router (never `refs/`) and kept with the video skill. Five rows. A fallback is never a higher tier than its pick; a unit takes the dominant row and is never split across renderers. Match on the concept's wording, then run `scripts/renderer-pick` with the row number: it applies the tier rules against `preflight.md`.

| # | Concept type | Pick | Fallback | Tier | Ref |
|---|---|---|---|---|---|
| 1 | math, geometry, simple 3D, hand-sketch-style reasoning | manim | none | 2 | `refs/manim.md` |
| 2 | algorithm and data-structure traces | manim | none | 2 | `refs/manim.md` |
| 3 | processes, mechanisms, diagrams, definitions, comparisons, narrative explainers | hyperframes | manim | 3 | `refs/hyperframes.md` |
| 4 | data and charts | hyperframes | manim | 3 | `refs/hyperframes.md` |
| 5 | code walkthroughs, diffs, terminal sessions | hyperframes | manim | 3 | `refs/hyperframes.md` |

Narration (`narrate.md`), captions and assembly (`assemble.md`) are shared by both renderers.
