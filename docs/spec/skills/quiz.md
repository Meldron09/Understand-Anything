# `quiz`

**Runs** in a unit subagent; spawns none. **Tier** 0. Hidden. Also generates the comprehension check's items (check flavor), so [`shared/items.md`](../shared.md) is its schema.

**Description:** `Internal learn-anything step, not for direct use: write quiz or flashcard items for a lesson unit. Runs in a unit subagent; spawns none.`

**Files:** `SKILL.md` (at most 100 lines), `quiz-head.html`, `quiz-tail.html`. Item schema from `${CLAUDE_PLUGIN_ROOT}/shared/items.md`; shaping from `shared/shaping.md`; checker `scripts/verify-html`.

## Quiz unit

1. Read the brief, the unit and its slice chunks as in [text.md](text.md).
2. Write **only** `work/uN/items.json` (item types `mcq`, `short`, `flip`; each tagged `concept` and `rung`).
3. Build `lesson/uN-quiz.html` with `cat quiz-head.html items.json quiz-tail.html`; keep the sidecar `lesson/uN-quiz.items.json`.
4. Verify with `scripts/verify-html`; repair once.
5. Return the footer (`items=<n>`).

The HTML is self-contained. `mcq` is auto-checked; `short` is type, reveal, self-rate; `flip` is a self-rated flashcard. The end summary is a per-concept `solid|shaky|missed` gap list; nothing is persisted. Size is `N items` at 0.5 minute each. Anki export is out of v1 (`items.json` is the seam).

## Shaping

Every `core:` concept in `focus` gets at least two items; concepts outside `focus` are never added. `advanced` skips the `define` rung. Depth sets the item count only within the router's `size`.

## Check flavor

After the last unit settles, the conductor dispatches one quiz-skill subagent for the comprehension check (see [check.md](check.md)): brief, plan, taught slices, and an **exclude list** of every quiz artifact's `q` values, writing `work/check/items.json`. Always a subagent, even at gist depth. Check items are `short` only, plus one `explain` at mastery depth; each carries a `rubric` and an `alt`. Items follow the ladder's shape (define, why, apply, edge) and are tagged with the core concepts they test.

## Degradation

- HTML verification still failing after one repair: write `lesson/uN-quiz.md` (the same items, trailing Answers section) and return `degraded`; the unit stays `mode: quiz`.
- Item generation failure: `failed`; the conductor re-dispatches to text, as an explainer of the same slices and `focus`, not prose questions.
