---
name: text
description: "Internal learn-anything step, not for direct use: write a text explainer lesson unit. Runs in a unit subagent; spawns none."
user-invocable: false
compatibility: No binaries needed; native PDF page reads need uv.
---

# text

Write one text lesson unit. It accepts a unit of any mode and does not know whether it is a degradation. Spawn nothing. Write only the artifact and `work/<unit-id>/`.

Your brief gives paths: `brief`, `plan`, `unit`, `slices`, `work`, `artifact`. Use the paths exactly as given and never `cd`. Never ask the learner anything.

Shaping: ${CLAUDE_PLUGIN_ROOT}/shared/shaping.md. Footer: ${CLAUDE_PLUGIN_ROOT}/shared/footer.md.

## Procedure

1. Read `brief.md` (depth, level, core, goal, `## Level evidence`) and your unit's `## <unit>` block in `plan.md` (`focus`, `slices`, `size`). Read the chunk text file of each slice (the entry's path in that source's `index.md`, relative to the source folder `sources/<sN>/`), one chunk at a time, never a whole source. A slice with no chunk file in a `grounded: false` source (a topic) is taught from general knowledge; in a grounded PDF source it is a scan, read natively (below). Read pages natively only as the next section allows.
2. Write `artifact` (create `lesson/` if needed), shaped by depth x level, to `size`: a target of ±15%. Count words before finishing; write less and say so with `short=<why>` rather than pad. `size` is the whole file, headings included.
3. Return the footer. (Run inline, the conductor continues after it; the footer is not the end of the lesson.)

## Native page reads (PDF slices)

A chunk of a source with `kind: pdf` has a page range in its entry (`pp. 7-14`) and the PDF path in the source's `origin`. Read pages natively only when one of three triggers holds:

1. the chunk has no text file (a scanned PDF);
2. its cached text looks broken where its summary or the text mentions an equation, table or figure (lost fractions, split symbols, scrambled columns);
3. the unit's `focus` names a figure, chart, diagram, equation or table.

Cap: 3 pages per unit in total, chosen to cover the trigger (the cache separates pages with form feeds, so find the page by counting them). Copy them out, then `Read` the copy whole (no `pages` argument, so no poppler is needed):

```
${CLAUDE_PLUGIN_ROOT}/scripts/pdf-pages <origin> <first>-<last> ./learn-anything/<slug>/work/<unit-id>/pages-<n>.pdf
```

Beyond the cap continue from the cache and say so in `notes`. If the copy or the read fails, continue without it and return `status: degraded` with `reason: native page read failed`. A scan with no pages read has nothing to teach from: `failed`.

## Artifact

GitHub-flavoured Markdown, no front matter:

- a title and one line "what this covers";
- an ungrounded source (`grounded: false` in its `index.md`) gets one italic line directly under the title: `*Not grounded in a source: written from general knowledge.*`;
- one `##` section per concept in the unit's `focus` (every `core:` concept in the slice gets its own `##` section, named with the exact `core` wording; give sections for concepts a `shaky` or `missed` evidence rung touches clearly more words than `solid` ones);
- a closing `## Takeaways` list;
- optional inline chunk citations such as `(s2#c03)`;
- diagrams only as fenced ASCII or Mermaid.

## Footer notes

`words=<n>` always (count with `wc -w`), `native_pages=<n>` whenever you read pages natively (at most 3), `ungrounded=true` when the source is ungrounded, `short=<why>` when under size. If you cannot write the artifact, return `status: failed` with `reason:`.
