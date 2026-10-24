# `ingest`

**Runs** inline for a small source; a large source is run in two conductor-driven phases with subagents (the source subagent cannot fan out, so the conductor spawns the summary batches). **Tier** 1 (`uv`) for URLs and PDFs; local text files need none. Hidden. Decision record: [ADR 0004](../../adr/0004-one-source-doc-per-source-with-pointer-chunks.md).

**Description:** `Internal learn-anything step, not for direct use: normalize one source (topic, URL, PDF, file) into a source doc with a chunk index. Spawns subagents.`

**Files:** `SKILL.md` (at most 120 lines) and `scripts/` (single-file Python, pinned PEP 723 dependencies, run with `uv run`): `fetch-url`, `chunk`, `merge-summaries`, plus `shasum` for hashes.

## Inputs accepted

A bare topic; one URL (no crawl, one page); a PDF (OneNote arrives as an exported PDF); local `.md`, `.txt`, `.html` or code. `.docx`, `.epub` and images are refused with an export hint. A bare topic becomes a one-chunk source with `kind: topic` and `grounded: false`; ingest does no research for it.

## One source doc per source

`./learn-anything/<lesson-slug>/sources/<source-id>/` with ids `s1`, `s2` in the order the learner gave them, never merged. A slice is written `s2#c03-c05` (a contiguous run of chunks within one source); a lesson unit may list slices from several sources.

```markdown
---
kind: pdf               # pdf | url | file | topic
origin: ./notes/ch5.pdf # path or URL
hash: sha256:...        # of the original
fetched: 2026-10-25T10:00:00Z
grounded: true
tokens: 18400
chunking: outline       # headings | outline | contents | window
status: ok              # ok | partial | failed
links: []               # outbound links found in a URL source, for the plan gate to mention
---
c01 | Introduction | pp. 1-6 | 2100 | chunks/c01.md
Why eigenvalues matter and what the chapter covers.
c02 | Characteristic polynomial | pp. 7-14 | 3900 | chunks/c02.md
Deriving det(A - λI) = 0 and solving it for 2x2 and 3x3 matrices.
```

Per chunk: `id | title | origin (heading path or pages) | token estimate | optional text path`, then a summary of at most about 25 words. Token estimate is characters / 4. No combined manifest: the router reads each source's index.

## Chunking

- Markdown and HTML: by headings.
- PDF: the outline (pypdf), else headings, else the contents page, else windows of about 15 pages. A PDF chunk always records its page range, plus a `pdftotext -layout` text cache when the PDF has a text layer; a scanned PDF gets the page pointer only. Mode skills read the cache by default and the pages natively when a slice needs figures or equations.
- Anything else: windows of about 2-3k tokens.
- Originals are referenced in place and hashed, not copied.

## URL conversion

`curl` the page to disk, then `uv run scripts/fetch-url` converts it with **trafilatura 2.3.1** (Apache-2.0; pin at least 1.8.0, earlier versions were GPLv3+), fallback readability-lxml plus markdownify. Before conversion strip the line-number anchors from `<code>` blocks. A result under about 250 characters is `failed` (JS shells do not reliably come back empty, so the minimum-length rule, not emptiness, is the test). Outbound links are recorded in `links`; the URL is not re-fetched unless the learner asks. Size is known on disk before any content enters the main thread.

## Running it

- **Small** (at most about 15 PDF pages or 20k tokens): inline; the main thread writes the summaries itself.
- **Large**: phase 1, one source subagent cuts the source and writes chunks and an index without summaries. Phase 2, the conductor spawns `haiku` batches of about 5 chunks, each writing its summaries under `work/ingest-<source-id>/`; `merge-summaries` merges them into `index.md`. No agent writes an index concurrently.

## Failure and resume

Partial failure continues without that source and the plan gate lists it (`status: partial` or `failed`). Total failure (every source the learner gave) stops and says so. Local files are re-ingested only on a hash change; a moved file makes that source `failed` on resume.
