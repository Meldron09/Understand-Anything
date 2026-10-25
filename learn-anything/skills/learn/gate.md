# Plan gate

Run `sh ${CLAUDE_PLUGIN_ROOT}/scripts/plan-gate ./learn-anything/<slug> --data-dir ${CLAUDE_PLUGIN_DATA}`. It prints one line per unit (`id | mode | renderer | size | tier`, plus `predicted:` / `downgraded:` flags), a `totals:` line (units, subagents, video minutes, highest tier, download size, failed sources), a `links:` line when ingest recorded outbound links, a `consent:` line when the plan has video (the download size, kokoro weights included, and for HyperFrames the macOS frame-spill risk), and a last line `gate: skip | show | refuse (<why>)`. Never compute totals or the verdict yourself.

- `skip`: exactly one unit at tier 0. Show nothing; go to dispatch.
- `refuse`: the plan is over 8 units or 5 video minutes (or the router marked it `over-cap:`). Print the unit lines and the reason, ask the learner what to cut, and dispatch nothing. Never drop, merge or shrink units yourself; the plan stays as written until the learner's adjustment arrives.
- `show`: print the script's lines verbatim (add outbound links to the learner's attention in one sentence), then ask confirm or adjust. If the download size is above 0 MB, name it and the `preflight.md` install commands and take the one consent (print the `consent:` line verbatim; never reword the frame-spill risk away) for the pinned downloads here; record `consent: <N> MB` in `plan.md` frontmatter and ask again only if a later plan needs more. For a `predicted:` flag, offer install-or-downgrade once (a downgrade is a router re-run with that note). Confirm goes to dispatch.

## Adjustments

Classify the learner's request, take exactly its route, then re-run the script and show the gate again. `plan.md` is only ever written by you (edit) or by the router at your invocation (overwrite); intake and ingest never write it.

| Request | Route |
|---|---|
| drop or reorder units | Edit `plan.md` yourself: delete or move whole `## uN` blocks, never renumber; update `planned:` from the remaining sizes. It is the learner's choice, so `brief.md` keeps its modes. |
| slicing, size or renderer | Invoke `learn-anything:router` with the lesson folder and the learner's words as `note:`; it overwrites `plan.md`. Keep `consent:` if the new plan needs no more. |
| mode, depth, time (budget) or level | Invoke `learn-anything:intake` in amend mode (lesson folder plus the change); it edits `brief.md` in place. Then ingest again any source whose entry or position changed (clear `sources/sN` of one that left the brief), then the router (overwrites `plan.md`). |
| add or remove a source | As above (amend edits `sources`). |
| a different topic | A new lesson: start from step 1 with the new topic. |

Amend is allowed only while every unit in `plan.md` is `pending`. If any unit is `done`, `degraded` or `failed`, do not invoke it: tell the learner a change now starts a new lesson with a full intake (nothing seeded).
