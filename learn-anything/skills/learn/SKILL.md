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
- A step skill's or subagent's footer is input to you, not your reply: when it returns, continue with the next step. Only step 9 ends the run. Never end a turn while `plan.md` has a `pending` unit: before any reply that is not step 9's, re-read `plan.md`, and if a unit is `pending`, dispatch it.
- Never `cd`; paths are relative to the learner's working directory.
- Lesson folder: `./learn-anything/<lesson-slug>/` (brief.md, sources/, plan.md, lesson/, work/<unit-id>/).

Brief template and footer parsing: ${CLAUDE_PLUGIN_ROOT}/skills/learn/dispatch.md. Footer format: ${CLAUDE_PLUGIN_ROOT}/shared/footer.md.

## Tracer scope

Built so far: topic in, one text, quiz or slides unit out. Not built yet (later tickets): the diagnostic ladder, PDF sources and large-source ingest, other modes, the plan gate and amend pass, the failure re-dispatch, hash-change archiving, the comprehension check. Where a step below says "later", skip it and say nothing.

## Sequence

1. **Classify the argument.** An exact folder-name match under `./learn-anything/` resumes that lesson (step 2). Anything else (topic, URL, path, or nothing) starts a new lesson: invoke `learn-anything:intake` with the argument as first input.
2. **Resume.** State is the files. Continue at the first missing artifact, in order: `brief.md` (restart intake), `sources/sN/index.md` for each source in the brief, `plan.md`, units still `pending`. A `done` or `degraded` unit is never re-run; a `pending` unit re-runs from scratch (clear its `work/<unit-id>/` first).
3. **Ingest.** For each source in the brief's `sources` (in order, ids `s1`, `s2`), invoke `learn-anything:ingest` with the lesson folder, the source entry and its id; it replies `sN: ok` or `sN: failed - <reason>`. A failed source is noted (id, entry, reason) and the others continue. If every source failed, stop and tell the learner each reason; never fall back to an ungrounded topic and never run the router.
4. **Router.** Invoke `learn-anything:router` with the lesson folder; it writes `plan.md`.
5. **Plan gate.** Skip it when the plan is exactly one unit at tier 0 (always, in the tracer). Otherwise later.
6. **Dispatch units** in plan order, briefs from `dispatch.md`. A one-unit plan runs inline: invoke the unit's mode skill (`learn-anything:text`, `learn-anything:quiz` or `learn-anything:slides`) yourself with the brief as its args. A plan of several units runs each `pending` unit in its own subagent, at most 3 at once, in rounds: take the next up-to-3 `pending` units, send all their `Agent` calls in one message (general-purpose, prompt = the brief), wait for all results, then for each unit in plan order parse the footer, set its `status:` in `plan.md` from `status`, add `artifact: <path>` to its block, print one progress line (`u2 quiz: done -> lesson/u2-quiz.html`) and `rm -rf work/<unit-id>/` on `done` (kept on `degraded` or `failed`). Only you edit `plan.md`; briefs never ask a subagent to. Then the next round, until no unit is `pending`. A result is not a reply: after a round your very next tool call is the first `plan.md` edit, and after the last edit the next round or steps 7 to 9; never answer with a footer.
7. **Failure.** On `failed` or a missing footer, record `failed: <reason>` in the plan and report it. Re-dispatch straight to text comes later.
8. **Check.** Later.
9. **Close.** List the artifacts by path, any failed sources with reasons, and any `degraded` or `failed` units with reasons. Surface footer notes only for `short=`, `rendered=none` and `ungrounded=true` (say the lesson is written from general knowledge, not a source). For `rendered=none`, tell the learner once, however many slides units: the deck is plain Markdown and renders with `npx @marp-team/marp-cli <deck>.md -o <deck>.html` (or `brew install marp-cli`, then `marp <deck>.md`); never run the install. Say nothing about `math=raw` or `diagrams=raw`.
