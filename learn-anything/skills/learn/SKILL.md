---
name: learn
description: "Teach one learner a concept from a topic, URL, PDF or file as a lesson in text, slides, video, interactive HTML or quiz, then check understanding. Not for quick factual questions. Runs inline and spawns subagents."
disable-model-invocation: true
argument-hint: "[topic | URL | file path | lesson slug]"
---

# learn (conductor)

Invariants first.

- You hold only paths, unit statuses and the brief's fields, never source text or artifact content. The plan on disk is the only seam between steps.
- You are the only writer of `plan.md` once the router has written it. Status vocabulary: `pending`, `done`, `degraded: <reason>`, `failed: <reason>`. No `running`.
- Mode choice is binding: never add or drop a mode.
- Never install system tools; print the command and let the learner run it.
- An inline step skill's footer is input to you, not your reply: when it returns, continue with the next step. Only step 9 ends the run.
- Never `cd`; paths are relative to the learner's working directory.
- Lesson folder: `./learn-anything/<lesson-slug>/` (brief.md, sources/, plan.md, lesson/, work/<unit-id>/).

Brief template and footer parsing: ${CLAUDE_PLUGIN_ROOT}/skills/learn/dispatch.md. Footer format: ${CLAUDE_PLUGIN_ROOT}/shared/footer.md.

## Tracer scope

Built so far: topic in, one text unit out. Not built yet (later tickets): the diagnostic ladder, preflight, other modes, the plan gate and amend pass, subagent dispatch, the failure re-dispatch, hash-change archiving, the comprehension check. Where a step below says "later", skip it and say nothing.

## Sequence

1. **Classify the argument.** An exact folder-name match under `./learn-anything/` resumes that lesson (step 2). Anything else (topic, URL, path, or nothing) starts a new lesson: invoke `learn-anything:intake` with the argument as first input.
2. **Resume.** State is the files. Continue at the first missing artifact, in order: `brief.md` (restart intake), `sources/sN/index.md` for each source in the brief, `plan.md`, units still `pending`. A `done` or `degraded` unit is never re-run; a `pending` unit re-runs from scratch (clear its `work/<unit-id>/` first).
3. **Ingest.** For each source in the brief's `sources` (in order, ids `s1`, `s2`), invoke `learn-anything:ingest` with the lesson folder, the source entry and its id; it replies `sN: ok` or `sN: failed - <reason>`. A reply `sN: cut <index> ...` is a large source, not a final reply: your very next tool call starts its summary phase (dispatch.md, "Large-source ingest"), then continue with the next source. A failed source is noted (id, entry, reason) and the others continue. If every source failed, stop and tell the learner each reason; never fall back to an ungrounded topic and never run the router.
4. **Router.** Invoke `learn-anything:router` with the lesson folder; it writes `plan.md`.
5. **Plan gate.** Skip it when the plan is exactly one unit at tier 0 (always, in the tracer). Otherwise later.
6. **Dispatch units** in plan order. A one-unit plan runs inline: invoke `learn-anything:text` (the unit's mode skill) yourself with the brief from `dispatch.md` as its args. Subagents later. Parse the footer; set the unit's `status:` in `plan.md` from `status`, add `artifact: <path>` to its block, print one progress line. Delete `work/<unit-id>/` on `done` (`rm -rf`). The skill's result is not a reply: your very next tool call is the `plan.md` edit, then steps 7 to 9; never answer with the footer.
7. **Failure.** On `failed` or a missing footer, record `failed: <reason>` in the plan and report it. Re-dispatch straight to text comes later.
8. **Check.** Later.
9. **Close.** List the artifacts by path, any failed sources with reasons, and any `degraded` or `failed` units with reasons. Surface footer notes only for `short=`, `rendered=none` and `ungrounded=true` (say the lesson is written from general knowledge, not a source).
