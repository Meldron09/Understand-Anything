# `text`

**Runs** in a unit subagent; spawns none. **Tier** 0. Hidden. The floor of every degradation: it accepts a unit of any mode and does not know it is a degradation.

**Description:** `Internal learn-anything step, not for direct use: write a text explainer lesson unit. Runs in a unit subagent; spawns none.`

**Files:** `SKILL.md` (about 60 lines, procedure only). Shaping comes from `${CLAUDE_PLUGIN_ROOT}/shared/shaping.md`, the footer from `shared/footer.md`.

## Procedure

1. Read `brief.md`, the unit's block in `plan.md`, and the chunk text files of its slices, **one chunk at a time**, never a whole source. Read pages natively (20 pages per call) only when the chunk has no text cache, the cached text looks broken where the summary mentions an equation, table or figure, or the `focus` names a figure, chart, diagram, equation or table. At most 3 native calls per unit; beyond that say so in `notes` and continue from the cache.
2. Write `lesson/uN-text.md`, shaped by depth x level, to `size` (a target of ±15%; write less and say so with `short=` rather than pad).
3. Return the footer.

## Artifact

GitHub-flavoured Markdown, no front matter:

- a title and one line "what this covers";
- one `##` section per concept in the unit's `focus` (a `core:` concept in the slice gets its own section);
- a closing "Takeaways" list;
- optional inline chunk citations such as `(s2#c03)`;
- diagrams only as fenced ASCII or Mermaid;
- an ungrounded source (`grounded: false`) gets one italic "not grounded in a source" line under the title.

## Footer notes

`words=<n>`, `ungrounded=true`, `native_pages=<n>`, `short=<why>`.

## Degradation

None below text. If it cannot write the artifact, it returns `failed` and the conductor reports it (no further fallback).
