---
name: router
description: "Internal learn-anything step, not for direct use: turn the learner brief and chunk indexes into plan.md. Runs inline."
user-invocable: false
compatibility: shasum.
---

# router

Turn `brief.md` and each source's `index.md` into the content of `plan.md`. Read only those (never chunk text, never a full source). Write `./learn-anything/<slug>/plan.md` as the conductor's delegate, when it does not exist yet or when the conductor re-invokes you (a plan-gate adjustment or amend); a `note:` in the input is the learner's change (slicing, size, renderer) and wins over your defaults. Overwrite the whole file then. At any other time the conductor is its only writer.

## Rules

- **Mode is binding.** Every mode in `brief.modes` gets at least one unit; never add or drop a mode, no suggested extras. A mode other than `text`, `quiz`, `slides`, `interactive` or `video` is not supported: stop and tell the conductor.
- **Units.** One unit per mode by default; plan more units of a mode only when its `focus` would need more than about 20000 tokens of slices or the learner's `note:` asks for it (several units of a mode cover different `core:` concepts). Units are independent: none consumes another's artifact.
- **Caps.** At most 8 units and 5 video minutes. Never shrink, merge or drop to fit: write the plan as sized and add frontmatter `over-cap: <units/minutes, one line>`; the conductor refuses it until the learner cuts.
- **Sizing and order.** Never compute these yourself: run `sh ${CLAUDE_PLUGIN_ROOT}/scripts/plan-size <budget> <mode>...` with one `<mode>` per planned unit. It prints `planned: N` (90% of `budget`, the rest is the check; the budget is split equally across all units, not given whole to each), then `uN <mode> <size>` lines in the order to write: explainer modes first (text, slides, interactive, video), then quiz, same-mode units in the order you listed them (list them in source order of their slices). Copy `planned` into the frontmatter, write one block per line in that order with that `size` (`artifact` ends `.html` for quiz and interactive, `.mp4` for video), and copy its `over-cap:` line into the frontmatter when it prints one. The video skill makes `round(60 x N / 20)` scenes for `N min`; a video unit also gets its renderer from the next rules.
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
