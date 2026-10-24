---
name: text
description: "Internal learn-anything step, not for direct use: write a text explainer lesson unit. Runs in a unit subagent; spawns none."
user-invocable: false
compatibility: No binaries needed.
---

# text

Write one text lesson unit. It accepts a unit of any mode and does not know whether it is a degradation. Spawn nothing. Write only the artifact and `work/<unit-id>/`.

Your brief gives paths: `brief`, `plan`, `unit`, `slices`, `work`, `artifact`. Use the paths exactly as given and never `cd`. Never ask the learner anything.

Shaping: ${CLAUDE_PLUGIN_ROOT}/shared/shaping.md. Footer: ${CLAUDE_PLUGIN_ROOT}/shared/footer.md.

## Procedure

1. Read `brief.md` (depth, level, core, goal, `## Level evidence`) and your unit's `## <unit>` block in `plan.md` (`focus`, `slices`, `size`). Read the chunk text file of each slice (the entry's path in that source's `index.md`, relative to the source folder `sources/<sN>/`), one chunk at a time, never a whole source. A slice with no chunk file (an ungrounded topic) is taught from general knowledge.
2. Write `artifact` (create `lesson/` if needed), shaped by depth x level, to `size`: a target of ±15%. Count words before finishing; write less and say so with `short=<why>` rather than pad. `size` is the whole file, headings included.
3. Return the footer. (Run inline, the conductor continues after it; the footer is not the end of the lesson.)

## Artifact

GitHub-flavoured Markdown, no front matter:

- a title and one line "what this covers";
- an ungrounded source (`grounded: false` in its `index.md`) gets one italic line directly under the title: `*Not grounded in a source: written from general knowledge.*`;
- one `##` section per concept in the unit's `focus` (every `core:` concept in the slice gets its own `##` section, named with the exact `core` wording; give sections for concepts a `shaky` or `missed` evidence rung touches clearly more words than `solid` ones);
- a closing `## Takeaways` list;
- optional inline chunk citations such as `(s2#c03)`;
- diagrams only as fenced ASCII or Mermaid.

## Footer notes

`words=<n>` always (count with `wc -w`), `ungrounded=true` when the source is ungrounded, `short=<why>` when under size. If you cannot write the artifact, return `status: failed` with `reason:`.
