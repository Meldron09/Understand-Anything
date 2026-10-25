---
name: check
description: "Internal learn-anything step, not for direct use: run the closing comprehension check and the one re-explain loop. Runs inline."
user-invocable: false
compatibility: No binaries needed.
---

# check

The closing comprehension check. Not a mode, never in the plan: the learner did not pick it. Runs in the main thread; spawns subagents only for item writing, `explain` grading and the re-explanation. Writes only `check.md`, `reexplain.md` and `work/check/`.

Your args: the lesson folder. Paths are relative to the learner's working directory; never `cd`. Item schema: ${CLAUDE_PLUGIN_ROOT}/shared/items.md. Footer: ${CLAUDE_PLUGIN_ROOT}/shared/footer.md. Grades: `solid | shaky | missed`.

Invariants:

- **No numeric score or pass mark, ever**: not "3 of 4", not a percentage. Say the grade words only.
- **At most one loop.** Never offer a second re-explanation or a third ask.
- Overwrite per run: first `rm -rf <lesson>/check.md <lesson>/reexplain.md <lesson>/work/check`, then `mkdir -p <lesson>/work/check`. Never delete `work/check/` afterwards: the next run clears it, and its `items.json` is the record of what was asked.

## Procedure

1. **Offer.** Run only if at least one unit is `done` or `degraded` (otherwise return `status: failed`, `reason: nothing taught`). Ask once, in one line, whether to take a short check; the learner may decline. Declined: write `check.md` with `declined: true`, `items: 0`, `reexplained: false` and an empty `## Gap list`, then step 7.
2. **Size** from `brief.md` `depth`: `gist` 2 items, `working` 4, `mastery` 6 plus one `explain`.
3. **Items.** Build the exclude list mechanically, never by reading quiz questions yourself:
   `grep -hoE '"(q|alt)" *: *"([^"\\]|\\.)*"' <lesson>/lesson/*.items.json | sed 's/" *: *"/":"/' | sort -u > <lesson>/work/check/exclude.txt` (it may stay empty).
   Spawn one `Agent` (general-purpose) with this brief, paths only; `slices` is every slice of every `done` or `degraded` unit in `plan.md`:
   ```
   Invoke skill learn-anything:quiz in check flavor.
   flavor: check
   brief: ./learn-anything/<slug>/brief.md
   plan: ./learn-anything/<slug>/plan.md
   slices: [s1#c01, ...]
   exclude: ./learn-anything/<slug>/work/check/exclude.txt
   work: ./learn-anything/<slug>/work/check
   size: <N> short items [plus 1 explain]
   Task: write only work/check/items.json, spawn nothing, reply in at most 150 words ending with the footer.
   ```
   Then verify the exclude list: `grep -hoE '"(q|alt)" *: *"([^"\\]|\\.)*"' <work>/items.json | sed 's/" *: *"/":"/' | grep -Fxf <work>/exclude.txt`. Any output is a repeated question: re-dispatch once; if lines still match, drop those items. No `items.json`: write `check.md` (`items: 0`, empty gap list) and return `status: failed`, `reason: no items`.
4. **Ask and grade inline**, one item at a time: show only `q`, take the answer, grade it against the item's `rubric` as `solid | shaky | missed` (no answer or "I don't know" is `missed`; never grade by length). Reply with one line: the grade and, unless `solid`, the reference `answer`. For `explain`, save the answer to `work/check/explain.md` and spawn one `Agent` to grade it against the rubric; it writes `work/check/explain-grade.md` (a grade and one gap line) and replies with that path.
5. **Result.** Show a per-concept gap list: each concept's worst grade, with a one-line gap note when not `solid`. A concept named in the brief's `core:` that is not `solid` is flagged `core`; `other` is never core.
6. **One loop.** Only if a core concept has an item graded `missed`: offer a targeted text re-explanation of the missed concepts. The learner may instead ask for another mode: say that is a new lesson (`/learn-anything:learn`), amend nothing, and go to step 7. If accepted, spawn one `Agent` with this brief, `slices` being those of the missed items:
   ```
   Invoke skill learn-anything:text for one re-explanation.
   brief: ./learn-anything/<slug>/brief.md
   slices: [s1#c03, ...]
   focus: <the missed concepts, exact core wording>
   size: <150 x number of missed concepts> words
   work: ./learn-anything/<slug>/work/check/reexplain
   artifact: ./learn-anything/<slug>/reexplain.md
   Task: re-explain these concepts from a different angle than the lesson in ./learn-anything/<slug>/lesson/ (a new analogy and a fresh worked example). There is no plan.md block for it: use the focus and size above. Reply in at most 150 words ending with the footer.
   ```
   Give the learner the path and wait until they say they are ready. Then re-ask only the missed items, each item's `alt` as the question, graded as in step 4; the new grade replaces the old. A concept still `missed` is reported as "still shaky, study <slice> first" (the item's `slice`). If the subagent fails, skip the re-explanation, say so, and keep the first-round grades. Never loop again.
7. **Write `check.md`** and return the footer (`status: done`, `artifact: <lesson>/check.md`). The conductor continues; the footer is not the end of the lesson.

## `check.md`

```markdown
---
lesson: <slug>
declined: false
items: 4
reexplained: true
---
## Gap list
eigenvector | solid |
characteristic polynomial | shaky | core | could not state why det(A - λI) = 0
diagonalization | missed | core | still missed after re-explain: study s1#c03 first
```

One row per concept: `concept | grade | core or empty | note`. `items` counts the first-round items (the `explain` included). `reexplained: true` only when `reexplain.md` was written; that file exists only when a core concept was missed and the learner accepted. The brief's `level` is not rewritten.
