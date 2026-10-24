# `learn` (the conductor)

**Runs** inline in the main thread and spawns subagents. **Tier** 0. The only user-invocable skill: `/learn-anything:learn [topic | URL | file path | lesson slug]`. Frontmatter `disable-model-invocation: true`.

**Description** (trigger first): `Teach one learner a concept from a topic, URL, PDF or file as a lesson in text, slides, video, interactive HTML or quiz, then check understanding. Not for quick factual questions. Runs inline and spawns subagents.`

**Files:** `SKILL.md` (at most 150 lines: the sequence, plan-gate rules, resume rules, invariants first) and `dispatch.md` (the unit and batch brief templates, footer parsing, the size-to-words conversion).

**Holds** only paths, unit statuses and the brief's fields; never source text or artifact content. It is the **only writer of `plan.md`**.

## Procedure

1. **Classify the argument.** An exact folder-name match under `./learn-anything/` resumes that lesson; anything else (topic, URL, file path, or nothing) starts a new lesson and is passed to `intake` as the first input.
2. **Resume.** State is the files. The resume point is the first missing artifact, in order: `brief.md`, source indexes, `plan.md`, units still `pending`, `check.md`. With no argument and an unfinished lesson on disk, list unfinished lessons and offer them. Compare the hashes in `plan.md` frontmatter `inputs` with the current `brief.md` and each `index.md`: any change archives `plan.md` as `plan.1.md` and `lesson/` as `lesson.1/` and starts a new plan with nothing carried over (finished video units are lost; carry-over is v2). A local source whose file moved is `failed` on resume. A `done` or `degraded` unit is never re-run; an in-flight unit that died is still `pending` and re-runs from scratch (its `work/<unit-id>/` is cleared first).
3. **Intake.** Invoke `intake` (inline; subagents cannot ask the learner questions).
4. **Ingest.** Per source in the brief's `sources`, invoke `ingest`. Small sources run inline; a large source (more than about 15 PDF pages or 20k tokens) runs as phase 1 in one source subagent (cut and chunk, no summaries), then the conductor spawns `haiku` batches of about 5 chunks to write summaries under `work/`, then runs the merge script that writes them into `index.md`. Partial failure continues and is listed at the plan gate; if every source fails, stop and say so (never fall back to an ungrounded topic).
5. **Router.** Invoke `router`; it writes `plan.md`.
6. **Plan gate.** Show one line per unit (`id`, mode, renderer, size, tier, `predicted:`/`downgraded:` flags) plus totals: units, subagents, video minutes, highest tier, download size, failed sources, outbound links recorded by ingest. Ask the learner to confirm or adjust, and take the one-time consent for pinned downloads here, stating the size. Adjustments:
   - drop or reorder units: edit `plan.md` directly;
   - slicing, size or renderer change: re-run `router` with the learner's note;
   - mode, depth, time or level change, or adding or removing a source: send back to `intake`'s amend pass, then re-ingest if needed and re-run `router` (overwrites `plan.md`);
   - an over-cap plan (more than 8 units or 5 video minutes) is refused until the learner cuts.
   Offer install-or-downgrade once for any `predicted:` flag. **Skip the gate** when the plan is exactly one unit at tier 0.
7. **Dispatch units** in plan order, at most 3 subagents at once; a one-unit plan runs inline. Each brief is the template in `dispatch.md` (about 10 lines of paths plus one task sentence). Set a unit's `status` from its footer, add `artifact:` to its block, and print one progress line per finished unit. `work/<unit-id>/` is deleted on `done`.
8. **Failure.** On `failed` or a missing footer, re-dispatch the unit once, straight to the `text` skill, recorded `degraded: <reason>`. The plan block keeps its original `mode`; `artifact:` points at the text file. A re-dispatch that also fails is recorded `failed: <reason>` and reported. Convert the unit's size first: original size x the router's rate for the original mode (to minutes), then x 200 words per minute (`2 min` of video = 400 words, `12 slides` = 3,600 words, `10 quiz items` = 1,000 words). The learner's time budget is preserved, not the word count. A degraded quiz or interactive unit becomes an explainer of the same slices and `focus`, not prose questions.
9. **Check.** Once every unit is `done`, `degraded` or `failed`, invoke `check` (see [check.md](check.md)).
10. **Close.** List the artifacts by path, any degraded or failed units with reasons, and surface footer notes only for `short=`, `rendered=none` (tell the learner once how to render the deck) and `ungrounded=true`.

## Invariants

- Plan on disk is the only seam; units are independent by construction (no unit reads another's artifact, no dependency graph).
- Subagents write only their artifact and `work/<unit-id>/`; they spawn none.
- Mode choice is binding; the conductor never adds or drops a mode.
- Status vocabulary in `plan.md`: `pending`, `done`, `degraded: <reason>`, `failed: <reason>`. No `running`.
- Never install system tools; print the command and let the learner run it.
