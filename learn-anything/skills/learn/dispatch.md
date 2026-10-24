# Dispatch: unit brief and footer parsing

## Unit brief

About 10 lines of paths plus one task sentence; never paste content. The same text is the args of an inline Skill call or the prompt of a subagent. `<mode>` is the unit's `mode`; paths are relative to the learner's working directory.

```
Invoke skill learn-anything:<mode> for one lesson unit.
lesson: ./learn-anything/<slug>
brief: ./learn-anything/<slug>/brief.md
plan: ./learn-anything/<slug>/plan.md
unit: u1
slices: [s1#c01]
work: ./learn-anything/<slug>/work/u1
artifact: ./learn-anything/<slug>/lesson/u1-<mode>.<ext>
Task: <the unit's focus sentence>. Write only the artifact and the work dir, spawn nothing, reply in at most 150 words ending with the footer.
```

`slices` and `focus` are copied from the unit's block in `plan.md`; `.<ext>` is `md` for text and slides, `html` for quiz (a slides render lands beside the `.md` as `.html` / `.pdf`; only the `.md` is `artifact:`).

## Subagent dispatch

One `Agent` call per unit: `subagent_type: general-purpose`, `description: "<unit-id> <mode>"`, `prompt:` the brief above, verbatim. Briefs hold paths and the task sentence only, never pasted source, plan or artifact text. Never set `run_in_background`: calls sent in one message run together and the message returns when all have finished.

A round is the next up-to-3 `pending` units in plan order (never more than 3 calls in one message, and never a call while a round is open). After the round, parse the footers one unit at a time in plan order and write each unit's status and artifact into `plan.md` yourself; subagents write only their artifact and `work/<unit-id>/`, never the plan. A subagent that returns without a footer is `failed` (`no footer`) and the round still completes. Loop until `plan.md` has no `pending` unit, then go on to step 7 to 9.

## Footer parsing

The footer is the last block of the result (format in the shared footer file): lines `status:`, `artifact:`, optional `reason:`, `notes:`. Take `status` (`done | degraded | failed`) and `artifact`. No `status:` line means a missing footer, treated as `failed` with reason `no footer`. If `status` is `done` but the artifact file does not exist, treat it as `failed` with reason `artifact missing`.

## Size to words (for re-dispatch, later)

Original size x the router's rate for the original mode gives minutes, then x 200 words per minute.
