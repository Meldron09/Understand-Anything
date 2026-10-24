---
name: ingest
description: "Internal learn-anything step, not for direct use: normalize one source (topic, URL, PDF, file) into a source doc with a chunk index. Spawns subagents."
user-invocable: false
compatibility: Topic and local text, Markdown or code files need shasum, date and python3. URLs and local HTML also need uv and curl.
---

# ingest

Normalize one source of `brief.md`'s `sources` into `./learn-anything/<slug>/sources/<source-id>/`. Ids are `s1`, `s2` in brief order, never merged. Input from the conductor: the lesson folder, the source entry and its id (`sN`). Never `cd`. Scratch files go in `work/ingest-<sN>/`, deleted when the source is `ok`.

## Tracer scope

Not built yet: PDFs (report `failed`, reason `pdf not supported yet`), the large-source subagent phases and chunk summaries by `haiku`; spawn nothing.

## Routing

Decide from the entry, then follow the matching section:

- literal `topic`: topic source.
- starts with `http://` or `https://`: URL source.
- otherwise a path. Missing or unreadable: `failed` (`file not found`). Check the extension, case-insensitively:
  - `.docx`, `.doc`, `.epub`, `.png`, `.jpg`, `.jpeg`, `.gif`, `.webp`, `.heic`, `.tiff`: `failed`, reason `unsupported <ext>` plus the export hint below.
  - `.pdf`: `failed` (tracer scope).
  - `.html`, `.htm`: HTML file source.
  - anything else (`.md`, `.txt`, code): text file source.

Export hint: Word, send a PDF (File > Save as PDF) or paste the text into a `.md` file; EPUB, convert it to PDF or text first; image, give the text itself or a PDF.

## Topic source

One chunk, `kind: topic`, `grounded: false`, no research, no chunk file. Write `sources/<sN>/index.md`:

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

## Text file source

Originals are referenced in place and hashed, never copied.

```
python3 ${CLAUDE_PLUGIN_ROOT}/skills/ingest/scripts/chunk <path> ./learn-anything/<slug>/sources/<sN> --kind file --origin <path>
```

It writes `index.md` and `chunks/cNN.md|txt`, cutting Markdown by headings and everything else into windows of about 2.5k tokens. A non-zero exit (empty or binary file) is `failed` with the script's message. Then write the summaries.

## HTML file source

Convert, then chunk the result; the hash is of the original `.html`.

```
mkdir -p ./learn-anything/<slug>/work/ingest-<sN>
uv run --script ${CLAUDE_PLUGIN_ROOT}/skills/ingest/scripts/fetch-url <path> file://<absolute path> ./learn-anything/<slug>/work/ingest-<sN>/page.md
python3 ${CLAUDE_PLUGIN_ROOT}/skills/ingest/scripts/chunk ./learn-anything/<slug>/work/ingest-<sN>/page.md ./learn-anything/<slug>/sources/<sN> --kind file --origin <path> --hash-of <path> --links ./learn-anything/<slug>/work/ingest-<sN>/page.md.links
```

Exit 3 from `fetch-url` means under about 250 characters came out: `failed`, reason `page too short after extraction`.

## URL source

One page, no crawl, fetched to disk before any content enters the main thread.

```
mkdir -p ./learn-anything/<slug>/work/ingest-<sN>
curl -fsSL --max-time 30 --max-filesize 10000000 -A "Mozilla/5.0 learn-anything" -o ./learn-anything/<slug>/work/ingest-<sN>/page.html <url>
uv run --script ${CLAUDE_PLUGIN_ROOT}/skills/ingest/scripts/fetch-url ./learn-anything/<slug>/work/ingest-<sN>/page.html <url> ./learn-anything/<slug>/work/ingest-<sN>/page.md
python3 ${CLAUDE_PLUGIN_ROOT}/skills/ingest/scripts/chunk ./learn-anything/<slug>/work/ingest-<sN>/page.md ./learn-anything/<slug>/sources/<sN> --kind url --origin <url> --hash-of ./learn-anything/<slug>/work/ingest-<sN>/page.html --links ./learn-anything/<slug>/work/ingest-<sN>/page.md.links
```

A `curl` error is `failed` with its message. `fetch-url` strips line-number anchors from code blocks, converts with trafilatura, and exits 3 when under about 250 characters remain (a JS shell): `failed`, reason `page too short after extraction (needs JavaScript?)`. Outbound links land in the index's `links`. No `uv`: `failed`, reason `uv missing`; the conductor prints the install command, never run it.

## Summaries

`chunk` leaves a line `SUMMARY` after each chunk entry. Replace each with a summary of at most 25 words, edited in `index.md` in place. Small source (`tokens` up to about 20000): read each chunk file once and summarize it. Larger: read only the first 600 characters of each chunk (`head -c 600`) and its title; this is a known ceiling until the batch phases land. Afterwards `grep -c '^SUMMARY$' index.md` must print 0.

## Failure

On any `failed`, remove a half-written `sources/<sN>/` and write only this `index.md`, so resume does not retry it, then continue to the reply:

```markdown
---
kind: <topic|url|file>
origin: <entry>
hash: none
fetched: <date -u +%Y-%m-%dT%H:%M:%SZ>
grounded: false
tokens: 0
chunking: none
status: failed
links: []
---
reason: <why, with the export hint when it applies>
```

## Reply

One line: `<sN>: ok <index path>` or `<sN>: failed - <reason>`. On `ok`, `rm -rf` the `work/ingest-<sN>` folder.
