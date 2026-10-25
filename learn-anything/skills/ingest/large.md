# Large-source ingest (phase 2)

Phase 1 is the cut by `chunk` or `chunk-pdf`: it wrote the chunks and an `index.md` whose entries still have a `SUMMARY` slot. Phase 2 runs in the conductor's thread, because this skill runs inline there and a subagent cannot spawn (ADR 0003). No agent but the merge ever writes `index.md` after the cut; batch agents write only under `work/ingest-<sN>/`.

1. `python3 ${CLAUDE_PLUGIN_ROOT}/skills/ingest/scripts/merge-summaries ./learn-anything/<slug>/sources/<sN> --batches` prints one line per batch, up to 5 chunk ids each. No output: no slots, nothing to do (a scanned PDF).
2. Spawn one `Agent` per line with `model: haiku`, at most 3 at a time, in a single message per wave. Prompt, with the real paths and ids:

```
Summarize chunks of one source, nothing else.
index: ./learn-anything/<slug>/sources/<sN>/index.md
chunks: c01 c02 c03 c04 c05
For each id, find its entry in the index and read its text file (path relative to the source folder) with `head -c 3000`, never the whole file.
Write ./learn-anything/<slug>/work/ingest-<sN>/summaries-b<k>.txt, one line per id: `cNN | <summary, at most 25 words>`. Never edit index.md. Reply `done`.
```

3. When every agent has returned (a failed agent only loses its own summaries), run `python3 ${CLAUDE_PLUGIN_ROOT}/skills/ingest/scripts/merge-summaries ./learn-anything/<slug>/sources/<sN> ./learn-anything/<slug>/work/ingest-<sN>`. It fills each slot with at most 25 words and uses the chunk title for a missing one; the source is still `ok`.
4. `grep -c '^SUMMARY$' index.md` must print 0, then reply as usual.
