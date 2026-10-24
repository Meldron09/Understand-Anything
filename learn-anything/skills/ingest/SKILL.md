---
name: ingest
description: "Internal learn-anything step, not for direct use: normalize one source (topic, URL, PDF, file) into a source doc with a chunk index. Spawns subagents."
user-invocable: false
compatibility: No binaries needed for a topic; shasum and date.
---

# ingest

Normalize one source of `brief.md`'s `sources` into `./learn-anything/<slug>/sources/<source-id>/`. Ids are `s1`, `s2` in brief order, never merged. Input from the conductor: the lesson folder, the source entry and its id.

## Tracer scope

Only the literal `topic` is handled. A URL, PDF or file is not built yet: report that source as `failed` (`not supported yet`) and stop. Large-source subagent phases and chunk summaries by `haiku` also land later; spawn nothing.

## Topic source

A bare topic becomes a one-chunk source with `kind: topic` and `grounded: false`. Do no research and write no chunk file. Write `sources/s1/index.md`:

```markdown
---
kind: topic
origin: <the brief's goal topic, one line>
hash: sha256:<hex of the origin text: printf '%s' "<origin>" | shasum -a 256>
fetched: <date -u +%Y-%m-%dT%H:%M:%SZ>
grounded: false
tokens: 0
chunking: window
status: ok
links: []
---
c01 | <topic> | general knowledge | 0
<one line of at most about 25 words on what the lesson will cover>
```

Chunk entry: `id | title | origin | token estimate | optional text path` (omitted here), then a summary line. Reply with `s1: ok` and the index path.
