# `intake`

**Runs** inline, in the main thread (subagents lose `AskUserQuestion`). **Tier** 0 (it runs `scripts/preflight`). Hidden.

**Description:** `Internal learn-anything step, not for direct use: interview the learner and write brief.md. Runs inline.`

**Files:** `SKILL.md` (at most 150 lines), `protocol.md` (the vendored interview protocol), `ladder.md` (rung templates, grading rules, level mapping). No dependency on `grilling`, `grill-with-docs` or `domain-modeling` (personal skills; plugin dependencies are plugin-to-plugin only).

## Interview protocol (vendored)

One question at a time, each with a recommended answer; wait for the answer; look facts up instead of asking; stop when the brief's fields are filled. "You pick" takes the recommended answer. Closed sets use `AskUserQuestion` (recommended option first); the goal and ladder answers are plain chat; fall back to plain text if `AskUserQuestion` is unavailable. Intake never reads a source.

## Flow

1. **Classify the argument** (URL, file path or topic) and skip any field it already states.
2. **Goal and why.** What the learner wants to understand and why. The lesson folder is created now; slug from the learner's topic words (2-4 words, `-2` on collision). Narrow a too-broad goal once.
3. **Sources**, asked once. Cheap checks only: the path exists, the extension is accepted (`.md`, `.txt`, `.html`, code, `.pdf`), a URL has an `http(s)` scheme. `.docx`, `.epub` and images are refused with an export hint. For OneNote, give export-to-PDF steps and take the PDF. No sources means a bare topic (an ungrounded source).
4. **Diagnostic ladder**, built on the fly from the learner's own topic words (never the source). Four rungs, asked one at a time, graded inline: **define**, **explain why**, **apply**, **edge case**. Short answer, never multiple choice. Grade each `solid | shaky | missed`; stop at the first `missed`. Level: 0-1 `solid` rungs is `novice`, 2-3 `intermediate`, 4 `advanced`. The learner may skip: level is then `novice`, marked in `assumed`.
5. **Self-rating**, asked after the ladder, recorded for comparison only; it never sets the level.
6. **Core concepts.** Propose 3-5 noun phrases from the goal and the ladder's gaps (general knowledge, not sources); the learner confirms or edits.
7. **Depth**: `gist | working | mastery`. **Budget**: one integer of minutes including the check (presets 15 / 30 / 60 / 120).
8. **Preflight** runs here, writing `preflight.md`. Then **modes**: multi-select of `text`, `slides`, `video`, `interactive`, `quiz` (a mix is several values). Unavailable modes are annotated with what they need but remain selectable; if preflight cannot run, say so and skip annotations.
9. **Write `brief.md` once**, then a non-blocking read-back (not a gate).

## `brief.md`

```markdown
---
lesson: eigenvalues-basics
goal: understand eigenvalues well enough to follow a linear-algebra course
sources: [./notes/ch5.pdf, https://example.org/eigen, topic]
level: novice            # novice | intermediate | advanced
depth: working           # gist | working | mastery
budget: 30               # minutes, including the comprehension check
modes: [text, quiz]
core: [eigenvector, characteristic polynomial, diagonalization]
assumed: []              # fields set by default rather than by the learner, e.g. [level]
---
## Why
<the learner's reason, a few lines>

## Level evidence
define | What is an eigenvector? | solid | defined correctly
why | Why does det(A - λI) = 0 give eigenvalues? | shaky | knew the formula, not the reason
apply | ... | missed | could not set up the equation
self-rating: intermediate (ladder says novice)
```

`sources` entries are paths, URLs, or the literal `topic`. `core` entries are the exact names every later skill matches on.

## Amend pass

Invoked only from the plan gate, and only before any unit has run. Edit only the touched fields in place. A new mode re-runs preflight. Added or removed sources just edit `sources` (the conductor re-ingests). A claim of a higher level resumes the ladder from where evidence stopped. A topic change starts a new lesson. The conductor then re-routes and overwrites `plan.md`. Once any unit has run there is no amend: a change starts a new lesson with a full intake and no seeding.
