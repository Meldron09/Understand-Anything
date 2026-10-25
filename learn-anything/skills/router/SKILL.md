---
name: router
description: "Internal learn-anything step, not for direct use: turn the learner brief and chunk indexes into plan.md. Runs inline."
user-invocable: false
compatibility: shasum.
---

# router

Turn `brief.md` and each source's `index.md` into the content of `plan.md`. Read only those (never chunk text, never a full source). Write `./learn-anything/<slug>/plan.md` as the conductor's delegate, when it does not exist yet or when the conductor re-invokes you (a plan-gate adjustment or amend); a `note:` in the input is the learner's change (slicing, size, renderer) and wins over your defaults. Overwrite the whole file then. At any other time the conductor is its only writer.

## Tracer scope

Not built yet: multi-unit slicing. Plan exactly one unit (text, quiz, slides, interactive or video), whose slices may come from several sources.

## Rules

- **Mode is binding.** Every mode in `brief.modes` gets a unit; never add or drop one. A mode other than `text`, `quiz`, `slides`, `interactive` or `video` is not supported yet: stop and tell the conductor.
- **Caps.** At most 8 units and 5 video minutes. Never shrink, merge or drop to fit: write the plan as sized and add frontmatter `over-cap: <units/minutes, one line>`; the conductor refuses it until the learner cuts.
- **Sizing.** `planned` = 90% of `budget` in minutes (the rest is the check). Text rate is 200 words per minute, so `size` = `budget` x 180 words. Quiz rate is 0.5 minute per item, so `size` = `budget` x 1.8 items, rounded, written `N items` (`artifact` ends `.html`). Slides run 1.5 minutes per slide, so `size` = `budget` x 0.6 slides rounded down, at least 3 (goal slide, one concept, takeaways), written `6 slides`. Interactive rate is 5 minutes per widget, so `size` = `N widgets`, N = `planned` / 5 rounded down, at least 1, at most 5 (`artifact` ends `.html`). Video size is in minutes, so `size` = `planned` rounded down, at least 1, written `3 min` (the skill makes `round(60 x N / 20)` scenes); the unit also gets an `artifact` ending `.mp4` and its renderer from the next rule.
- **Slides prediction.** Slides are tier 0 with an optional render. If `preflight.md` exists and its `- marp: false; npx: false` probe line shows both missing (the script writes `- marp: <true|false>; npx: <true|false>`), add `predicted: unrendered` to the unit. Offer no install-or-downgrade choice for slides and never change the mode. No `preflight.md` or no such line: write no prediction.
- **Video renderer.** Read ${CLAUDE_PLUGIN_ROOT}/shared/renderers.md (never its `refs/`), match the unit's `focus` to the concept row it is mostly about (the unit never splits), and run `sh ${CLAUDE_PLUGIN_ROOT}/scripts/renderer-pick ${CLAUDE_PLUGIN_ROOT}/shared/renderers.md <row> ./learn-anything/<slug>/preflight.md`. Copy its lines into the unit block as printed: `renderer:` and `tier:` always, `downgraded:` when the pick's tier is missing and the fallback's is there (a note from the learner naming a renderer wins: run the script with that renderer's row), `predicted:` when neither is usable (the gate offers install or downgrade). Never judge tiers yourself.
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

One `## uN` block per unit in presentation order; ids are never renumbered. Optional fields (`renderer`, `downgraded:`, `artifact:`) come later; `predicted:` is written for slides and video only. Artifacts are `lesson/<unit-id>-<mode>.<ext>`, here `lesson/u1-text.md` (slides: `lesson/u1-slides.md`; video: `lesson/u1-video.mp4`).
