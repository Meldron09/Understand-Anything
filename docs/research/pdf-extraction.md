# Research: robust PDF extraction for learn-anything

Ticket: Meldron09/Understand-Anything#13 (map #1). Date checked: 2026-10-24.
Constraints: free/OSS and local only; local macOS Claude Code is the primary target; marketplace-grade (documented deps, graceful degradation).
Method: primary sources only (vendor docs, repos, release pages, Homebrew formula pages). **Nothing was installed or run.** Every "quality" statement is **not verified locally** (it is the project's own claim or a missing claim). "unknown" means no primary source answered it.

## 1. What Claude reads natively

| Fact | Source |
|---|---|
| Claude Code `Read` reads short PDFs whole; for PDFs longer than 10 pages it reads ranges via a `pages` parameter (e.g. `"1-5"`), up to 20 pages at a time. | https://code.claude.com/docs/en/tools-reference (Read tool section) |
| Page-range reads render pages with `pdftoppm` from poppler; on macOS `brew install poppler`; without it a page-range read fails with `pdftoppm is not installed`. | same |
| Images, PDFs and notebooks keep their per-read limits even with `allow_large`. | same ("Large files") |
| API PDF support: each page is converted to an image and its extracted text is provided alongside; Claude sees text + image per page, so charts, tables and diagrams are visible. | https://platform.claude.com/docs/en/build-with-claude/pdf-support ("How PDF support works") |
| API limits: 32 MB request, 600 pages per request (100 when the context window is under 1M tokens); no passwords/encryption. | same ("Check PDF requirements") |
| Cost: about 1,500-3,000 text tokens per page plus image-token cost per page. | same ("Estimate your costs") |
| Dense PDFs can fill the context window before the page limit; docs advise splitting into sections. | same (Tip under limits) |

Implication: in Claude Code, a subagent can already read any PDF slice (text, tables, equations, scans) visually, 20 pages per call, with no extraction library. The costs are tokens (images) and a hard dependency on poppler. Whether native reading OCRs a scan accurately is **not verified locally**; the docs describe page-as-image vision, not an OCR step.

## 2. Candidate tools

Maintenance as of 2026-10-24 (GitHub API / release pages).

| Tool | Licence | Latest / activity | Source |
|---|---|---|---|
| poppler (pdftotext, pdftoppm) | GPL-2.0-only OR GPL-3.0-only (Homebrew) | 26.10.0, released 2026-10-04 | https://poppler.freedesktop.org/ ; https://formulae.brew.sh/formula/poppler |
| PyMuPDF (+ PyMuPDF4LLM, merged into 2.x) | AGPL-3.0, or paid commercial licence from Artifex | 2.0, 2026-10-19; pushed today | https://github.com/pymupdf/PyMuPDF ; https://pypi.org/project/pymupdf4llm/ |
| pdfplumber | MIT | v0.11.10, 2026-06-15; pushed 2026-10-15 | https://github.com/jsvine/pdfplumber |
| pypdf | BSD-style (LICENSE file, Mathieu Fenniak) | 6.21.2, 2026-10-21 | https://github.com/py-pdf/pypdf |
| Docling | MIT code; individual models follow their own licences | v2.142.1, 2026-10-23 | https://github.com/docling-project/docling |
| Marker | Code Apache-2.0; **weights under a modified AI Pubs Open RAIL-M**: free for research, personal use, startups under $5M funding/revenue; beyond that paid | v2.0.0, 2026-07-20; pushed 2026-10-22 | https://github.com/datalab-to/marker |
| MinerU | custom "MinerU Open Source License" (Apache-2.0 plus extra conditions; GitHub shows NOASSERTION) | pushed 2026-10-23 | https://github.com/opendatalab/MinerU |
| OCRmyPDF | MPL-2.0 | 17.13.0, 2026-09-28 | https://formulae.brew.sh/formula/ocrmypdf ; https://github.com/ocrmypdf/OCRmyPDF |
| Tesseract | Apache-2.0 | 5.5.3, 2026-07-24 | https://github.com/tesseract-ocr/tesseract |

All are actively maintained; none archived.

## 3. Comparison table

"NV" = not verified locally.

| Tool | Text PDFs | Tables | Equations | Scanned (OCR) | macOS install friction | Licence | Speed |
|---|---|---|---|---|---|---|---|
| **Claude native Read** (page ranges) | Yes; text + page image | Seen as image; NV accuracy | Seen as image; NV | Page image seen; no documented OCR step; NV | Needs poppler (`brew install poppler`) for ranges >10 pages | n/a (Claude itself) | Token-bound: ~1.5-3k text tokens/page + image tokens |
| **pdftotext** (poppler) | Yes; `-f/-l` page range, `-layout` keeps physical layout, `-bbox-layout` / `-tsv` give boxes | Only by layout-preserved text; no table model | Plain glyph text only; no LaTeX | None. Man page: no way "short of OCR" for mangled fonts | `brew install poppler`, arm64 bottles | GPL-2/3 | unknown (no figures published) |
| **PyMuPDF / PyMuPDF4LLM** | Yes; Markdown, JSON, TXT; header detection via font size or from the ToC | `Page.find_tables()`, "high table detection precision" (project claim, NV) | `formula` box class detected in layout analysis; LaTeX output not documented on pages read | OCR via RapidOCR (recommended) or Tesseract; the pages read do not say how it triggers | `pip install pymupdf`; wheels for macOS x86_64 and arm64; Python 3.11-3.15 | **AGPL-3.0** (commercial option) | unknown (no figures read) |
| **pdfplumber** | Yes, best on machine-generated PDFs | Strongest: `find_tables`, strategies lines/text/explicit | None | **None** (README lists OCR as not provided) | pip, pure Python | MIT | unknown |
| **pypdf** | Basic text; outline/bookmarks via `outline`, `get_destination_page_number`, `page_labels` | No | No | No | pip, pure Python | BSD-style | unknown |
| **Docling** | Yes; layout, reading order, Markdown/JSON export | Table-structure model (TableFormer, per the 2408.09869 abstract) | Formulas listed as a feature; quality NV | "Extensive OCR support"; engines named in docs: Tesseract, RapidOCR, Surya | `pip install docling`; macOS arm64 and x86_64 supported; Python 3.10+; model downloads, size unknown | MIT (models vary) | Paper: Apple M3 Max, 225 pages, OCR off: 0.41-0.79 s/page, 2.5-6.2 GB peak RAM. EasyOCR on CPU "upwards of 30 seconds per page" |
| **Marker** | Yes; Markdown/JSON/HTML/chunks | Rebuilt from text layer with VLM fallback (project claim, NV) | VLM to LaTeX (project claim, NV) | Yes, multilingual | `pip install marker-pdf`, PyTorch, plus llama.cpp (`brew install llama.cpp`) for CPU/Apple Silicon | Code Apache-2.0; **weights restricted** (see sec. 2) | Own table: ~0.3 pages/s single-stream "balanced" on a B200 GPU host; CPU/MPS default is `fast`; Mac figure unknown |
| **MinerU** | Yes | Yes | Yes (LaTeX is one rendering target) | Yes | `pip`; Apple Silicon default install includes torch; 16 GB RAM for the PyTorch + llama.cpp tier | Custom licence | No figures; "flash" fastest, "advanced" slowest |
| **OCRmyPDF** (+ Tesseract) | n/a (adds a text layer, then pair with pdftotext) | No | No | Yes; Tesseract, PDF/A output | `brew install ocrmypdf` pulls ~16 deps (tesseract 5.5.3, ghostscript, qpdf, unpaper...) | MPL-2.0; Ghostscript dep is AGPLv3 (not strictly required since v17) | unknown |

Sources for the table: tools reference and PDF-support pages in sec. 1; https://manpages.debian.org/unstable/poppler-utils/pdftotext.1.en.html ; https://pymupdf.readthedocs.io/en/latest/recipes-text.html ; https://github.com/pymupdf/PyMuPDF ; https://github.com/jsvine/pdfplumber ; https://pypdf.readthedocs.io/en/stable/modules/PdfReader.html ; https://github.com/docling-project/docling ; https://arxiv.org/abs/2408.09869 and https://arxiv.org/html/2408.09869v5 (speed) ; https://github.com/datalab-to/marker ; https://github.com/opendatalab/MinerU ; https://ocrmypdf.readthedocs.io/en/latest/introduction.html ; https://formulae.brew.sh/formula/ocrmypdf .

### Reading the table

- **Licence trap 1: PyMuPDF is AGPL.** Calling it from a plugin script on the learner's own machine is a different case from redistributing it. Whether that is a problem for a marketplace plugin is a legal call; flagged, not decided.
- **Licence trap 2: Marker's weights are not free for all commercial use.** This fails a plain "free/OSS" reading above $5M funding/revenue. Do not pick it.
- **Equations are the weak spot of every text-layer tool.** Only the ML pipelines (Docling, Marker, MinerU) claim LaTeX; their quality is NV and they are heavy installs. Claude's own page-image reading is the only zero-extra-install path to equations and charts.
- **Scans:** only Tesseract-based (OCRmyPDF, Docling, PyMuPDF) or ML tools OCR. Claude's native vision may suffice for short scans; unknown for long ones.

## 4. Structure-based chunking: one slice per subagent

Goal: each subagent gets a page range it can read within the 20-page `Read` ceiling (or a trimmed text file), cut at structural boundaries, not blind N-page windows.

**Step 0: probe (cheap, local).** Get page count and whether a text layer exists. Run `pdftotext -f N -l N` on a few sample pages: near-empty output on pages that visibly have content means a scan. Poppler documents `-f/-l` and the OCR caveat (pdftotext man page above).

**Step 1: cut points, best signal first.**

1. **PDF outline (bookmarks).** `PyMuPDF Document.get_toc()` returns `[lvl, title, page]` (page is 1-based; `-1` if no destination): https://pymupdf.readthedocs.io/en/latest/document.html . pypdf (`outline` + `get_destination_page_number`) does the same with a BSD licence: https://pypdf.readthedocs.io/en/stable/modules/PdfReader.html . What an absent outline returns is not stated in the pages read (empty list is likely, unverified). Poppler's tools do not provide an outline listing in the pages I read, so a ToC needs one of these two libraries.
2. **Font-size headings.** PyMuPDF4LLM `IdentifyHeaders(doc, pages, body_limit=11, max_levels=6)` derives heading levels from font sizes; `TocHeaders(doc)` derives them from the ToC; `page_chunks=True` returns per-page boxes with classes such as `section-header`, `table`, `formula`, `picture`: https://pymupdf.readthedocs.io/en/latest/pymupdf4llm/api.html .
3. **Printed contents page.** Have one subagent read the first 10-20 pages (one `Read` call) and return chapter titles and page numbers. Printed page numbers differ from PDF page indexes: the PDF-support docs say to use viewer page numbers in prompts, and pypdf `page_labels` / PyMuPDF `get_page_labels()` map labels to indexes. Uses only native Claude, no library.
4. **Model-based document tree (optional heavy tier).** Docling `HierarchicalChunker` makes one chunk per detected element with heading metadata; `HybridChunker` splits oversize chunks to a tokenizer limit and merges undersized neighbours with the same headings, repeating table headers across splits: https://docling-project.github.io/docling/concepts/chunking/ . Marker's `chunks` output is a flat list of top-level blocks per page: https://github.com/datalab-to/marker . These give blocks, not chapters.
5. **Fallback: fixed windows.** If none of the above yields structure, cut every ~15 pages with 1 page of overlap.

**Step 2: turn cut points into slices.**

- Top-level entries (level 1) define candidate slices. Merge short neighbours; split any slice over 20 pages at level-2 entries, else at fixed windows. A slice that is one huge table or formula-dense chapter should stay under ~10 pages because images cost tokens (cost basis in sec. 1).
- Slice = `{id, title, first_page, last_page, has_text_layer}`. The handoff passes this record plus the PDF path, not the text (subagent brief stays minimal; context efficiency is a first-class requirement in the map notes).
- Each subagent reads its own range (`Read` with `pages`) or a pre-extracted `pdftotext -layout -f A -l B` file, writes a **source doc** to disk, and returns a short summary plus the file path.
- Slices are independent, so they parallelise. Cross-references between slices are not resolved by this scheme; that is for the assembly step (out of scope here).

**Recommended cut order:** outline, then font-size headings, then printed contents, then fixed windows.

## 5. Pick and fallback

**Pick: Claude's native PDF reading, backed by poppler, with pypdf (outline) for structure.**

- Reading: each subagent uses Claude Code `Read` with `pages` (<=20 per call). This covers text, tables, equations, charts and likely short scans visually, with no extraction model to install. Quality is NV.
- Cheap text pass: `pdftotext -layout -f A -l B` (same poppler package already required for page-range reads) when a slice is text-only, to save image tokens.
- Structure: pypdf for outline and page labels (pure Python, BSD-style, actively released). Fixed windows when no outline.
- One mandatory dependency (poppler via Homebrew), which is already Claude Code's own requirement for this feature. Degrade gracefully: no poppler means short PDFs (10 pages or fewer) still read whole; longer ones fail with a documented error, so the plugin should check `pdftoppm` up front and tell the learner what to install.
- Free/OSS and local: yes (GPL poppler used as an external CLI, BSD pypdf). No AGPL code, no restricted weights.

**Fallback: Docling (MIT).** Use when native reading fails or is too expensive: image-heavy PDFs that blow the token budget, equation-heavy or scanned long documents, or when a structured element tree is wanted. It gives reading order, TableFormer tables, formulas, OCR, Markdown/JSON, and structure-aware chunking in one `pip install docling`, macOS arm64 supported, and 0.4-0.8 s/page with OCR off on an M3 Max (vendor paper). Costs: heavy model downloads (size unknown), 2.5-6 GB RAM, OCR much slower (EasyOCR on CPU "upwards of 30 seconds per page" in the paper). Equation quality is NV.

**Not recommended**

- Marker: weights licence restricts commercial use above $5M; needs PyTorch plus llama.cpp on Mac.
- MinerU: custom licence; 16 GB RAM tier.
- PyMuPDF: AGPL; would be the best single library (outline, tables, headings, OCR hooks, Markdown), so revisit if the project accepts AGPL as a dependency installed by the learner, or buys a licence.
- pdfplumber: MIT, strongest table API, but no OCR and no equation help; useful as an add-on for table-heavy text PDFs.

**Scanned PDFs, minimum path:** native vision first. If a text layer is absent and long, `brew install ocrmypdf` (MPL-2.0, Tesseract 5.5.3) adds a text layer, then continue as for text PDFs. It pulls about 16 runtime dependencies including Ghostscript (AGPL).

## 6. Open questions (unknown, need a local test later)

- Native Read accuracy on scanned pages, dense tables and equations, and token cost per page in Claude Code (docs give API figures only).
- Docling model download size and first-run time on a Mac; equation (LaTeX) quality.
- What `get_toc()` / pypdf `outline` return on a PDF with no bookmarks (likely empty; not documented in the pages read).
- Throughput of pdftotext, PyMuPDF and Marker on Apple Silicon (no primary figures found).
- Whether PyMuPDF's AGPL matters for a user-installed marketplace plugin (legal question).
- Headless/sandbox flag (the map asks video tickets for this; here): poppler CLIs and pypdf are plain local processes, expected to work in a restricted sandbox; Docling downloads models over the network on first use (assumed, not confirmed in the pages read), so it may not.
