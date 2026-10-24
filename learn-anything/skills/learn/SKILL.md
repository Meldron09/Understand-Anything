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

Brief template and footer parsing: ${CLAUDE_PLUGIN_ROOT}/skills/learn/dispatch.md. Plan gate and adjustments: ${CLAUDE_PLUGIN_ROOT}/skills/learn/gate.md. Footer format: ${CLAUDE_PLUGIN_ROOT}/shared/footer.md.

## Tracer scope

Built so far: topic in, one text, quiz or slides unit out, the plan gate and adjustments. Not built yet (later tickets): the diagnostic ladder, PDF sources and large-source ingest, other modes, subagent dispatch, the failure re-dispatch, the comprehension check. Where a step below says "later", skip it and say nothing.

## Sequence

1. **Classify the argument.** `sh ${CLAUDE_PLUGIN_ROOT}/scripts/resume-check match "<arg>"` exits 0 only when the argument is exactly a folder name under `./learn-anything/`: that resumes the lesson (step 2). Anything else (topic, URL, path, or nothing) starts a new lesson: invoke `learn-anything:intake` with the argument as first input. With no argument, run `sh ${CLAUDE_PLUGIN_ROOT}/scripts/resume-check list`; if it prints unfinished lessons, offer them and resume the one the learner picks, else start a new lesson.
2. **Resume.** Run `sh ${CLAUDE_PLUGIN_ROOT}/scripts/resume-check ./learn-anything/<slug>`; never compare hashes or move files yourself. It archives `plan.md` and `lesson/` as `plan.N.md` / `lesson.N/` when the brief or any source index changed (or a local source file was edited), marks a local source whose file moved `failed`, clears `work/<unit-id>/` of every `pending` unit, and ends with `resume: <next>`. Tell the learner each `archived:`, `moved:` and `reingest:` line in one sentence (a new plan starts with nothing carried over). Then continue: `intake` (step 1's intake), `ingest sN ..` (step 3 for just those sources), `router` (step 4), `units uN ..` (step 6, those units only; skip the gate when any unit is already past `pending`, else step 5), `done` (step 9). A `done` or `degraded` unit is never re-run. Report `moved:` sources as failed sources at step 9.
3. **Ingest.** For each source in the brief's `sources` (in order, ids `s1`, `s2`), invoke `learn-anything:ingest` with the lesson folder, the source entry and its id; it replies `sN: ok` or `sN: failed - <reason>`. A failed source is noted (id, entry, reason) and the others continue. If every source failed, stop and tell the learner each reason; never fall back to an ungrounded topic and never run the router.
4. **Router.** Invoke `learn-anything:router` with the lesson folder; it writes `plan.md`.
5. **Plan gate.** Follow `gate.md`: it decides skip, show or refuse, and routes each learner adjustment. Never dispatch a refused plan or one the learner has not confirmed.
6. **Dispatch units** in plan order. A one-unit plan runs inline: invoke the unit's mode skill (`learn-anything:text`, `learn-anything:quiz` or `learn-anything:slides`) yourself with the brief from `dispatch.md` as its args. Subagents later. Parse the footer; set the unit's `status:` in `plan.md` from `status`, add `artifact: <path>` to its block, print one progress line. Delete `work/<unit-id>/` on `done` (`rm -rf`). The skill's result is not a reply: your very next tool call is the `plan.md` edit, then steps 7 to 9; never answer with the footer.
7. **Failure.** On `failed` or a missing footer, record `failed: <reason>` in the plan and report it. Re-dispatch straight to text comes later.
8. **Check.** Later.
9. **Close.** List the artifacts by path, any failed sources with reasons, and any `degraded` or `failed` units with reasons. Surface footer notes only for `short=`, `rendered=none` and `ungrounded=true` (say the lesson is written from general knowledge, not a source). For `rendered=none`, tell the learner once, however many slides units: the deck is plain Markdown and renders with `npx @marp-team/marp-cli <deck>.md -o <deck>.html` (or `brew install marp-cli`, then `marp <deck>.md`); never run the install. Say nothing about `math=raw` or `diagrams=raw`.
