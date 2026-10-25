---
name: slides
description: "Internal learn-anything step, not for direct use: write a slide deck lesson unit as a Marp deck. Runs in a unit subagent; spawns none."
user-invocable: false
compatibility: No binaries needed to write the deck; marp or npx renders it to HTML, Chrome to PDF.
---

# slides

Write one slide-deck lesson unit as a Marp deck. Spawn nothing. Write only the artifact, its render and `work/<unit-id>/`.

Your brief gives paths: `brief`, `plan`, `unit`, `slices`, `work`, `artifact`. Use the paths exactly as given and never `cd`. Never ask the learner anything.

Shaping: ${CLAUDE_PLUGIN_ROOT}/shared/shaping.md. Footer: ${CLAUDE_PLUGIN_ROOT}/shared/footer.md. Deck conventions, counting and render: ${CLAUDE_PLUGIN_ROOT}/skills/slides/marp.md.

## Procedure

1. Read `brief.md` (depth, level, core, goal) and your unit's `## <unit>` block in `plan.md` (`focus`, `slices`, `size`, e.g. `6 slides`). Read the chunk text file of each slice, one chunk at a time, never a whole source (cap 3 chunks). A slice with no chunk file (an ungrounded topic) is taught from general knowledge.
2. Write `artifact` (`lesson/uN-slides.md`, create `lesson/` if needed): a valid Marp deck, readable as plain text, with exactly `size` slides. **Always write it**, whatever tools exist.
3. Count the slides and check each against the limits (marp.md). Fix the deck until the count equals `size` exactly.
4. Render per marp.md: HTML when `marp` or `npx` is found, PDF only when Chrome is found. A missing tool or a failed render never fails the unit.
5. Return the footer. (Run inline, the conductor continues after it; the footer is not the end of the lesson.)

## Artifact

- A slide is a title plus at most about 5 short lines, or one figure plus a caption. Depth and level shape the speaker notes and the slide mix (via shaping.md), never the per-slide line limit.
- The teaching is in the speaker notes: an HTML comment `<!-- ... -->` on every slide. Citations such as `(s2#c03)` go in the notes only.
- Slide 1 states the brief's goal; the last slide is `Takeaways`. Both count toward `size`; every `core:` concept in your `focus` gets a slide.
- Math as `$...$` or `$$...$$`; diagrams as fenced `mermaid` blocks in the deck. No hand-drawn SVG.
- An ungrounded source (`grounded: false`) gets one line in slide 1's notes: `Not grounded in a source: written from general knowledge.`

## Footer notes

`slides=<n>` and `rendered=html|pdf|none` always; `math=raw` or `diagrams=raw` when the render left them as source (not a degradation); `ungrounded=true` when ungrounded; `short=<why>` if you could not reach `size`. Status is `done` even when `rendered=none`, with `artifact:` the `.md`. Return `status: failed` with `reason:` only if the deck itself cannot be written.
