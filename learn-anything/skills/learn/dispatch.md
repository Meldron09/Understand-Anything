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

`slices` and `focus` are copied from the unit's block in `plan.md`; `.<ext>` is `md` for text and slides, `html` for quiz and interactive (a slides render lands beside the `.md` as `.html` / `.pdf`; only the `.md` is `artifact:`).

## Footer parsing

The footer is the last block of the result (format in the shared footer file): lines `status:`, `artifact:`, optional `reason:`, `notes:`. Take `status` (`done | degraded | failed`) and `artifact`. No `status:` line means a missing footer, treated as `failed` with reason `no footer`. If `status` is `done` but the artifact file does not exist, treat it as `failed` with reason `artifact missing`.

## Size to words (for re-dispatch, later)

Original size x the router's rate for the original mode gives minutes, then x 200 words per minute.
