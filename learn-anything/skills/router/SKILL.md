---
name: router
description: "Internal learn-anything step, not for direct use: turn the learner brief and chunk indexes into plan.md. Runs inline."
user-invocable: false
compatibility: shasum.
---

# router

Turn `brief.md` and each source's `index.md` into the content of `plan.md`. Read only those (never chunk text, never a full source). Write `./learn-anything/<slug>/plan.md` as the conductor's delegate, once, when it does not exist yet; afterwards the conductor is its only writer.

## Tracer scope

Not built yet: modes beyond text and slides, renderers and `renderers.md`, video tier prediction, caps and over-cap marking, multi-unit slicing. Plan exactly one unit (text or slides) over the first source's one chunk.

## Rules

- **Mode is binding.** Every mode in `brief.modes` gets a unit; never add or drop one. A mode other than `text` or `slides` is not supported yet: stop and tell the conductor.
- **Sizing.** `planned` = 90% of `budget` in minutes (the rest is the check). Text rate is 200 words per minute, so `size` = `budget` x 180 words. Slides run 1.5 minutes per slide, so `size` = `budget` x 0.6 slides rounded down, at least 3 (goal slide, one concept, takeaways), written `6 slides`.
- **Slides prediction.** Slides are tier 0 with an optional render. If `preflight.md` exists and its `marp`/`npx` probe shows `marp` missing, add `predicted: unrendered` to the unit. Offer no install-or-downgrade choice for slides and never change the mode. No `preflight.md`: write no prediction.
- **Slices.** Name them from the chunk entries (`s1#c01`, a contiguous run `s1#c01-c02` within one source). `focus` is one sentence covering every `core:` concept.
- **Ungrounded sources** (`grounded: false`) plan as one chunk; the unit teaches from general knowledge.
- **Hashes.** `inputs` holds the sha256 hex of `brief.md` and of each `index.md`: `shasum -a 256 <file> | cut -d' ' -f1`.

## `plan.md`

```markdown
---
lesson: <slug>
budget: 10            # minutes, from the brief
planned: 9            # minutes planned (at most 90% of budget)
inputs: {brief: sha256:<hex>, s1: sha256:<hex>}
---
## u1
mode: text
focus: <one sentence naming the core concepts to teach>
slices: [s1#c01]
size: 1800 words
tier: 0
status: pending
```

One `## uN` block per unit in presentation order; ids are never renumbered. Optional fields (`renderer`, `downgraded:`, `artifact:`) come later; `predicted:` is written for slides only. Artifacts are `lesson/<unit-id>-<mode>.<ext>`, here `lesson/u1-text.md` (slides: `lesson/u1-slides.md`).
