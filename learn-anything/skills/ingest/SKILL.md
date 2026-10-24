---
name: ingest
description: "Internal learn-anything step, not for direct use: normalize one source (topic, URL, PDF, file) into a source doc with a chunk index. Spawns subagents."
user-invocable: false
compatibility: Topic and local text, Markdown or code files need shasum, date and python3. URLs, local HTML and PDFs also need uv; URLs need curl. pdftotext is optional.
---

# ingest

Normalize one source of `brief.md`'s `sources` into `./learn-anything/<slug>/sources/<source-id>/`. Ids are `s1`, `s2` in brief order, never merged. Input from the conductor: the lesson folder, the source entry and its id (`sN`). Never `cd`. Scratch files go in `work/ingest-<sN>/`, deleted when the source is `ok`.

## Routing

Decide from the entry, then follow the matching section:

- literal `topic`: topic source.
- starts with `http://` or `https://`: URL source.
- otherwise a path. Missing or unreadable: `failed` (`file not found`). Check the extension, case-insensitively:
  - `.docx`, `.doc`, `.epub`, `.png`, `.jpg`, `.jpeg`, `.gif`, `.webp`, `.heic`, `.tiff`: `failed`, reason `unsupported <ext>` plus the export hint below.
  - `.pdf`: PDF source.
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

## PDF source

Referenced in place, hashed, cut by `chunk-pdf` (pypdf, pinned): outline, else printed contents page, else windows of about 15 pages. Every chunk has a page range; a text layer also gets a `pdftotext -layout` cache per chunk (pypdf text when poppler is missing); a scanned PDF gets page pointers only and prefilled summaries, so it still plans.

```
uv run --script ${CLAUDE_PLUGIN_ROOT}/skills/ingest/scripts/chunk-pdf <path> ./learn-anything/<slug>/sources/<sN> --origin <path>
```

Exit 1 is `failed` with the script's message (`encrypted PDF`, `unreadable PDF: ...`). No `uv`: `failed`, `uv missing`.

## Summaries

`chunk` and `chunk-pdf` leave a line `SUMMARY` after each chunk entry to fill with at most 25 words. They print the totals; a source is small when `tokens` is at most about 20000 and it has at most about 15 pages, else large.

- **Small:** read each chunk file once, replace each slot in `index.md` in place. Afterwards `grep -c '^SUMMARY$' index.md` must print 0.
- **Large (two phases):** the cut above is phase 1 and is done. Write no summaries, spawn nothing; you are not the one to fan out. Reply `<sN>: cut <index path> - <k> chunks to summarize` (phase 2 is the conductor's, see `${CLAUDE_PLUGIN_ROOT}/skills/learn/dispatch.md`). Nothing but `merge-summaries` touches `index.md` after the cut. A large source with no `SUMMARY` slots (scanned PDF) is simply `ok`.

## Failure

On any `failed`, remove a half-written `sources/<sN>/` and write only this `index.md`, so resume does not retry it, then continue to the reply:

```markdown
---
kind: <topic|url|file|pdf>
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

One line: `<sN>: ok <index path>`, `<sN>: failed - <reason>`, or the large-source `cut` line. On `ok`, `rm -rf` the `work/ingest-<sN>` folder.
