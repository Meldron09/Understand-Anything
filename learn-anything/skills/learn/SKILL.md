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

Brief template and footer parsing: ${CLAUDE_PLUGIN_ROOT}/skills/learn/dispatch.md. Plan gate and adjustments: ${CLAUDE_PLUGIN_ROOT}/skills/learn/gate.md. Footer format: ${CLAUDE_PLUGIN_ROOT}/shared/footer.md.

## Tracer scope

Built so far: topic in, one text, quiz, slides, interactive or video unit out, the plan gate and adjustments, the comprehension check, PDF sources and large-source ingest. Not built yet (later tickets): the diagnostic ladder, other modes. Where a step below says "later", skip it and say nothing.

## Sequence

1. **Classify the argument.** `sh ${CLAUDE_PLUGIN_ROOT}/scripts/resume-check match "<arg>"` exits 0 only when the argument is exactly a folder name under `./learn-anything/`: that resumes the lesson (step 2). Anything else (topic, URL, path, or nothing) starts a new lesson: invoke `learn-anything:intake` with the argument as first input. With no argument, run `sh ${CLAUDE_PLUGIN_ROOT}/scripts/resume-check list`; if it prints unfinished lessons, offer them and resume the one the learner picks, else start a new lesson.
2. **Resume.** Run `sh ${CLAUDE_PLUGIN_ROOT}/scripts/resume-check ./learn-anything/<slug>`; never compare hashes or move files yourself. It archives `plan.md` and `lesson/` as `plan.N.md` / `lesson.N/` when the brief or any source index changed (or a local source file was edited), marks a local source whose file moved `failed`, clears `work/<unit-id>/` of every `pending` unit, and ends with `resume: <next>`. Tell the learner each `archived:`, `moved:` and `reingest:` line in one sentence (a new plan starts with nothing carried over). Then continue: `intake` (step 1's intake), `ingest sN ..` (step 3 for just those sources), `router` (step 4), `units uN ..` (step 6, those units only; skip the gate when any unit is already past `pending`, else step 5), `done` (step 8 when `check.md` is missing or an `archived:` line printed, else step 9). A `done` or `degraded` unit is never re-run. Report `moved:` sources as failed sources at step 9.
3. **Ingest.** For each source in the brief's `sources` (in order, ids `s1`, `s2`), invoke `learn-anything:ingest` with the lesson folder, the source entry and its id; it replies `sN: ok` or `sN: failed - <reason>`. A failed source is noted (id, entry, reason) and the others continue. If every source failed, stop and tell the learner each reason; never fall back to an ungrounded topic and never run the router.
4. **Router.** Invoke `learn-anything:router` with the lesson folder; it writes `plan.md`.
5. **Plan gate.** Follow `gate.md`: it decides skip, show or refuse, and routes each learner adjustment. Never dispatch a refused plan or one the learner has not confirmed.
6. **Dispatch units** in plan order, briefs from `dispatch.md`. A one-unit plan runs inline: invoke the unit's mode skill (`learn-anything:text`, `learn-anything:quiz`, `learn-anything:slides`, `learn-anything:interactive` or `learn-anything:video`) yourself with the brief as its args. A plan of several units runs each `pending` unit in its own subagent, at most 3 at once, in rounds: take the next up-to-3 `pending` units, send all their `Agent` calls in one message (general-purpose, prompt = the brief), wait for all results, then for each unit in plan order parse the footer; on `failed` or a missing footer leave the unit `pending` and do step 7 for it now, else record its `status` (a `degraded` footer is recorded as `degraded: <the footer's reason>`) and `artifact` with `sh ${CLAUDE_PLUGIN_ROOT}/scripts/plan-unit set plan.md <unit> <status> <path>`, print one progress line (`u2 quiz: done -> lesson/u2-quiz.html`) and `rm -rf work/<unit-id>/` on `done` (kept on `degraded` or `failed`). Only you edit `plan.md`; briefs never ask a subagent to. Then the next round, until no unit is `pending`. A result is not a reply: after a round your very next tool call is the first `plan.md` edit, and after the last edit the next round or steps 7 to 9; never answer with a footer.
7. **Failure.** A unit whose footer is `failed` or missing is re-dispatched once, straight to text, never twice and never for a `done` or `degraded` footer. Size first: `sh ${CLAUDE_PLUGIN_ROOT}/scripts/degrade-words "<size from its plan block>"` (the time budget carries over, not the word count). Run `learn-anything:text` with the text brief from `dispatch.md` (inline for a one-unit plan, else one `Agent` call), with the unit's own `slices` and `focus`: a degraded quiz or interactive unit becomes an explainer, not prose questions. On `done` or `degraded` record `plan-unit set plan.md <unit> "degraded: <the original failure's reason>" lesson/<unit>-text.md`; the block keeps its `mode` and `size`. If that also fails or returns no footer, record `plan-unit set plan.md <unit> "failed: <reason>"` and tell the learner. Print one line either way (`u2 quiz: degraded -> lesson/u2-text.md (<reason>)`).
8. **Check.** Once every unit is `done`, `degraded` or `failed`, invoke `learn-anything:check` with the lesson folder. It is never a plan unit and never in the plan; keep `work/check/`. Its footer is input: continue at step 9.
9. **Close.** List the artifacts by path (including `check.md`, and `reexplain.md` when it exists), any failed sources with reasons, and every `degraded` or `failed` unit with its reason (`sh ${CLAUDE_PLUGIN_ROOT}/scripts/plan-unit report plan.md` lists them; print its lines, or say none). Surface footer notes only for `short=`, `rendered=none` and `ungrounded=true` (say the lesson is written from general knowledge, not a source). For `rendered=none`, tell the learner once, however many slides units: the deck is plain Markdown and renders with `npx @marp-team/marp-cli <deck>.md -o <deck>.html` (or `brew install marp-cli`, then `marp <deck>.md`); never run the install. Say nothing about `math=raw` or `diagrams=raw`.
