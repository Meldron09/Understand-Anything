# `router`

**Runs** inline. **Tier** 0. Hidden. Decision records: [ADR 0002](../../adr/0002-conductor-with-hidden-steps-and-plan-file-seam.md), [ADR 0003](../../adr/0003-depth-one-subagents-with-single-writer-plan.md).

**Description:** `Internal learn-anything step, not for direct use: turn the learner brief and chunk indexes into plan.md. Runs inline.`

**Files:** `SKILL.md` (at most 120 lines).

**Reads:** `brief.md`, each source's `index.md` (never chunk text or the full source), `preflight.md`, and `${CLAUDE_PLUGIN_ROOT}/shared/renderers.md` (never `refs/`). **Writes:** the content of `plan.md`; the conductor is its only writer.

## `plan.md`

```markdown
---
lesson: eigenvalues-basics
budget: 30            # minutes, from the brief
planned: 27           # minutes planned (at most 90% of budget)
inputs: {brief: sha256:..., s1: sha256:..., s2: sha256:...}   # hashes of brief.md and each index.md
---
## u1
mode: text
focus: Explain eigenvectors and the characteristic polynomial with one worked 2x2 example.
slices: [s1#c01-c02, s2#c04]
size: 900 words
tier: 0
status: pending

## u2
mode: video
renderer: hyperframes
focus: Walk through diagonalization of a 2x2 matrix step by step.
slices: [s1#c03]
size: 2 min
tier: 3
status: pending
predicted: node missing
downgraded: renderer manim (hyperframes needs node)
artifact: lesson/u2-video.mp4        # added after the run
```

One `## uN` block per unit, in presentation order, ids never renumbered. Fields: `mode`, `renderer` (video only), `focus` (one sentence, the router's instruction to the unit), `slices` (a list, possibly across sources), `size` (`900 words` / `12 slides` / `5 widgets` / `10 items` / `2 min`), `tier`, `status`; optional `predicted:`, `downgraded:`, `artifact:`. Artifacts are `lesson/<unit-id>-<mode>.<ext>`.

## Rules

- **Mode is binding.** Every mode in `brief.modes` gets at least one unit; never add or drop a mode; no suggested extras.
- **Sizing.** Plan to 90% of `budget` (the rest is the check) with fixed rates: text 200 words/min, slides 1.5 min/slide, interactive 5 min/widget (up to 5 widgets per unit), quiz 0.5 min/item, video minutes 1:1. Caps: 8 units, 5 video minutes. If the cap would be exceeded, write the plan anyway marked `over-cap` in a one-line note to the conductor, which refuses it at the gate until the learner cuts; never silently shrink. The budget is split equally across all units and the sizes and order are computed by `scripts/plan-size` (see [shared.md](../shared.md)), not by the model.
- **Slicing.** Name slices from the chunk summaries so the unit's `focus` is covered and every `core:` concept appears in some unit's `focus` for each chosen mode. Units are independent by construction: no unit consumes another's artifact; no dependency graph. A video unit takes the dominant row of `renderers.md` and is never split across renderers.
- **Order.** Explainer modes first (text, slides, interactive, video), then quiz; within a mode, source order. The check is not a unit and never appears in the plan.
- **Tier prediction.** From `preflight.md`: if the pick's tier is missing and the fallback's tier is present, use the fallback and write `downgraded:`; if neither is available, write `predicted: <what is missing>` and keep the pick (the gate offers install or downgrade once). Slides are tier 0 with an optional render: write `predicted: unrendered` when `marp` is missing; no install-or-downgrade choice is offered for slides.
- **Ungrounded sources** (`grounded: false`) plan as one chunk; units teach from general knowledge and the footer notes `ungrounded=true`.
- **Plan gate input.** The conductor prints one line per unit plus totals; the router supplies `tier` and flags, nothing else.
