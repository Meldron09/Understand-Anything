---
name: quiz
description: "Internal learn-anything step, not for direct use: write quiz or flashcard items for a lesson unit. Runs in a unit subagent; spawns none."
user-invocable: false
compatibility: No binaries needed; a headless Chromium only upgrades verification.
---

# quiz

Write one quiz unit as a self-contained HTML page. Spawn nothing. Write only the artifact, its sidecar and `work/<unit-id>/`.

Your brief gives paths: `brief`, `plan`, `unit`, `slices`, `work`, `artifact`. Use the paths exactly as given and never `cd`. Never ask the learner anything.

Item schema: ${CLAUDE_PLUGIN_ROOT}/shared/items.md. Shaping: ${CLAUDE_PLUGIN_ROOT}/shared/shaping.md. Footer: ${CLAUDE_PLUGIN_ROOT}/shared/footer.md. Checker: `sh ${CLAUDE_PLUGIN_ROOT}/scripts/verify-html <file>`.

## Procedure

1. Read `brief.md` (depth, level, core, goal, `## Level evidence`) and your unit's block in `plan.md` (`focus`, `slices`, `size`). Read the chunk text file of each slice, one chunk at a time, never a whole source. A slice with no chunk file (an ungrounded topic) is taught from general knowledge.
2. Write `work/<unit-id>/items.json` and nothing else yet. `size` is `N items` (0.5 minute each): write N items.
   - Every `core:` concept named in `focus` gets at least two items, on different rungs, and `concept` is that exact name. That floor beats N when they collide; say so with `short=` only if you wrote fewer than N.
   - Concepts outside `focus` are never added. Use `other` only for an item that tests no core concept.
   - Shaping: `advanced` skips the `define` rung. Concepts the ladder rated `shaky` or `missed` get more items; `solid` ones get the two-item minimum. Depth changes the rungs used (gist: `define`, `why`; working adds `apply`; mastery adds `edge`), never N.
   - Types: `mcq` where one answer is clearly right, `short` for explain and apply, `flip` for definitions and facts.
3. Build the page: `cat ${CLAUDE_PLUGIN_ROOT}/skills/quiz/quiz-head.html <work>/items.json ${CLAUDE_PLUGIN_ROOT}/skills/quiz/quiz-tail.html > <artifact>` (create `lesson/` if needed). Copy `items.json` to the sidecar next to the artifact: `<artifact minus .html>.items.json`, e.g. `lesson/u1-quiz.items.json`. Keep the sidecar even when degraded.
4. Verify: `sh ${CLAUDE_PLUGIN_ROOT}/scripts/verify-html <artifact>`. On any violation, fix `items.json` (never the head or tail files), rebuild and verify once more. Pass the lesson's `preflight.md` as a second argument when it exists. Add `not browser-tested` to the notes unless it reports a headless Chromium.
5. Still failing: write `lesson/<unit-id>-quiz.md` with every item (`q`, and `choices` for `mcq`) and a trailing `## Answers` section with each `answer`. Return `status: degraded`, `artifact:` the `.md`, `reason:` the violation. The unit stays `mode: quiz`.
6. Return the footer. (Run inline, the conductor continues after it; the footer is not the end of the lesson.)

## Page behaviour

`mcq` is auto-checked; `short` is type, reveal, self-rate; `flip` is a self-rated flashcard. The page ends with a per-concept `solid | shaky | missed` summary; nothing is persisted.

## Footer notes

`items=<n>` always. If `items.json` cannot be written, return `status: failed` with `reason:` (the conductor re-dispatches to text).

## Check flavor

A brief with `flavor: check` (plus `exclude`, `size`, `slices`, `work`; no `unit`, no `artifact`) asks for the comprehension check's items instead. Do the procedure above only as far as reading the brief, the plan's slices and the chunk text, then:

- Write only `<work>/items.json`: `short` items only, plus one `explain` when `size` says so. No HTML, no sidecar, no verify. Every item has `rubric` and `alt`.
- `size` is exact. Tag items with the `core:` concepts, spread over them and weighted to the ladder's `shaky` and `missed` ones; `other` only when nothing core fits.
- Follow the ladder's shape (`define`, `why`, `apply`, `edge`), lowest rung first, at the brief's `level`; `advanced` skips `define`.
- `exclude` is a file of lines `"q":"<text>"`. No `q` or `alt` may equal or paraphrase any of them.
- Footer: `artifact:` the items file, `notes: items=<n>`.
