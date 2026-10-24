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

`slices` and `focus` are copied from the unit's block in `plan.md`; `.<ext>` is `md` for text.

## Footer parsing

The footer is the last block of the result (format in the shared footer file): lines `status:`, `artifact:`, optional `reason:`, `notes:`. Take `status` (`done | degraded | failed`) and `artifact`. No `status:` line means a missing footer, treated as `failed` with reason `no footer`. If `status` is `done` but the artifact file does not exist, treat it as `failed` with reason `artifact missing`.

## Size to words (for re-dispatch, later)

Original size x the router's rate for the original mode gives minutes, then x 200 words per minute.

## Large-source ingest (phase 2)

Ingest cut the source (phase 1) and replied `sN: cut <index> - <k> chunks to summarize`. You spawn the summary agents; nothing else may write that `index.md` until the merge.

1. `python3 ${CLAUDE_PLUGIN_ROOT}/skills/ingest/scripts/merge-summaries ./learn-anything/<slug>/sources/<sN> --batches` prints one line of up to 5 chunk ids per batch.
2. Spawn one `Agent` per line with `model: haiku`, at most 3 at a time. Prompt, with the real paths and ids:

```
Summarize chunks of one source, nothing else.
index: ./learn-anything/<slug>/sources/<sN>/index.md
chunks: c01 c02 c03 c04 c05
For each id, find its entry in the index and read its text file (path relative to the source folder) with `head -c 3000`, never the whole file; with no text file use the title and pages.
Write ./learn-anything/<slug>/work/ingest-<sN>/summaries-b<k>.txt, one line per id: `cNN | <summary, at most 25 words>`. Never edit index.md. Reply `done`.
```

3. When every agent has returned (a failed agent only loses its summaries), run `python3 ${CLAUDE_PLUGIN_ROOT}/skills/ingest/scripts/merge-summaries <source folder> ./learn-anything/<slug>/work/ingest-<sN>`, then `rm -rf` that work folder. Chunks without a summary get their title; the source is still `ok`.
