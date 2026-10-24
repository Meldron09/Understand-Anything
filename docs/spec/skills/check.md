# `check` (the comprehension check)

**Runs** inline (graded in the main thread so the result is in hand for the feedback loop). **Tier** 0. Hidden. Not a mode and never in the plan: the learner did not pick it. Closes every lesson.

**Description:** `Internal learn-anything step, not for direct use: run the closing comprehension check and the one re-explain loop. Runs inline.`

**Files:** `SKILL.md` (at most 80 lines). Items from `${CLAUDE_PLUGIN_ROOT}/shared/items.md`.

## Procedure

1. **Offer.** Ask once; the learner can decline (then write `check.md` with `declined: true`).
2. **Size** from `brief.depth`: gist 2 items, working 4, mastery 6 plus one `explain` (spec defaults; the router's 10% reserve is the time budget).
3. **Items.** The conductor dispatches one quiz-skill subagent in check flavor with the brief, the plan, the taught slices and an exclude list of every quiz artifact's `q`; it writes `work/check/items.json`. Always a subagent. Items follow the ladder's shape (define, why, apply, edge) at the level the lesson targeted, so results compare with the brief's level evidence.
4. **Ask and grade inline**, one item at a time, against each item's `rubric` as `solid | shaky | missed`. A subagent grades only the `explain` prompt (long answer) and returns a gap list and a file path.
5. **Result.** Per-concept gap list; **no numeric pass mark**. A miss on a concept the brief marks `core:` is flagged.
6. **One loop.** If a core concept was missed, offer a targeted text re-explanation of the missed concepts: a text-skill subagent handoff on the relevant slices, from a different angle than the first explanation, written to `reexplain.md`. The learner may instead ask for another mode (a new lesson, no amend). After it, re-ask only the missed items using their `alt` variants. Anything still missed is reported as "still shaky, study X first". **No further loops.**

## `check.md` (overwritten per run, not aggregated across lessons)

```markdown
---
lesson: eigenvalues-basics
declined: false
items: 4
reexplained: true
---
## Gap list
eigenvector | solid |
characteristic polynomial | shaky | core | could not state why det(A - λI) = 0
diagonalization | missed | core | still missed after re-explain: study s1#c03 first
```

The stable path `./learn-anything/<lesson-slug>/check.md` is the only seam for a future learner-model effort. The brief's `level` is not rewritten by the check.
