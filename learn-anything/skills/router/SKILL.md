---
name: router
description: "Internal learn-anything step, not for direct use: turn the learner brief and chunk indexes into plan.md. Runs inline."
user-invocable: false
compatibility: shasum.
---

# router

Turn `brief.md` and each source's `index.md` into the content of `plan.md`. Read only those (never chunk text, never a full source). Write `./learn-anything/<slug>/plan.md` as the conductor's delegate, once, when it does not exist yet; afterwards the conductor is its only writer.

## Tracer scope

Not built yet: other modes, renderers and `renderers.md`, tier prediction, caps and over-cap marking, multi-unit slicing, preflight. Plan exactly one text unit, whose slices may come from several sources.

## Rules

- **Mode is binding.** Every mode in `brief.modes` gets a unit; never add or drop one. A mode other than `text` is not supported yet: stop and tell the conductor.
- **Sizing.** `planned` = 90% of `budget` in minutes (the rest is the check). Text rate is 200 words per minute, so `size` = `budget` x 180 words.
- **Sources.** Read every `sources/sN/index.md`; ignore one whose `status` is `failed` (it has no chunks, and the conductor reports it). Never read chunk text.
- **Slices.** Name them from the chunk entries and their summaries (`s1#c01`, a contiguous run `s1#c01-c02` within one source). A unit lists slices from every source that covers its `focus`, as one list: `slices: [s1#c01-c02, s2#c04]`. Pick the fewest chunks that cover every `core:` concept, about 20000 tokens at most (the entries' token estimates). `focus` is one sentence covering every `core:` concept.
- **Ungrounded sources** (`grounded: false`) plan as one chunk; the unit teaches from general knowledge.
- **Hashes.** `inputs` holds the sha256 hex of `brief.md` and of each `index.md` (failed sources included): `shasum -a 256 <file> | cut -d' ' -f1`.

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

One `## uN` block per unit in presentation order; ids are never renumbered. Optional fields (`renderer`, `predicted:`, `downgraded:`, `artifact:`) come later. Artifacts are `lesson/<unit-id>-<mode>.<ext>`, here `lesson/u1-text.md`.
