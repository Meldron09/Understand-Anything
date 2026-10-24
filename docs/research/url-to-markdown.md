# Research: URL-to-Markdown extractor for learn-anything

Ticket: Meldron09/Understand-Anything#25 (map #1). Date checked: 2026-10-24.
Constraints: free/OSS and local only; local macOS Claude Code is the primary target; marketplace-grade (documented deps, graceful degradation). Context: ADR 0004 says a URL is one page fetched to disk with `curl` and converted by a `uv run` script; no crawl.
Method: primary sources (project READMEs, docs, LICENSE/COPYRIGHT files, PyPI and GitHub API metadata), plus **a local run** of three candidates on five saved pages (this Mac, one run each, `uv run` with pinned versions, pages fetched with `curl` on 2026-10-24). Sample quality below is my reading of those outputs. Single page per type, so it is a spot check, not a benchmark. Scripts and outputs lived in the scratchpad and are not committed.

## 1. Candidates

| Tool | Role | Licence (as stated) | Latest / activity (2026-10-24) | Install under `uv` |
|---|---|---|---|---|
| **trafilatura** | Main-content extractor with native Markdown output (`output_format="markdown"`) | Apache-2.0. README: "Versions prior to v1.8.0 are under GPLv3+ license." | v2.3.1, 2026-10-06; repo pushed 2026-10-23; not archived | Pure-Python wheel (`py3-none-any`), requires Python >=3.10; hard deps courlan, htmldate, justext, lxml, charset_normalizer, certifi, urllib3 |
| **readability-lxml** + **markdownify** | Readability-port boilerplate stripper returns HTML; markdownify converts it | readability-lxml: Apache-2.0. markdownify: MIT (GitHub licence field; PyPI classifier "MIT License") | readability-lxml 0.9, 2026-08-27, pushed 2026-08-27. markdownify 1.2.3, 2026-06-30 | Both pure-Python wheels. readability-lxml needs lxml, chardet, cssselect; markdownify needs beautifulsoup4 and six |
| **pandoc** | Format converter (HTML to GFM); does **not** extract main content | COPYRIGHT file: "released under the GPL, version 2 or later" (GitHub field: GPL-2.0), with exceptions noted in the file | 3.12.1, 2026-10-08; pushed 2026-10-24 | Native binary. Not on PATH on this Mac. I ran 3.9 via the `pypandoc_binary` wheel (MIT wrapper, 24.4 MiB with macOS arm64/x86_64 wheels); `brew install pandoc` also exists (not tried) |

Not evaluated: Mozilla Readability (Apache-2.0, JavaScript, needs Node; the repo has no GitHub release), html2text (GPL-3.0 per GitHub, not a main-content extractor).

Licence notes for the pick, from PyPI metadata (`license_expression` or classifiers): courlan Apache-2.0, htmldate Apache-2.0, justext "The BSD 2-Clause License", lxml BSD-3-Clause, charset-normalizer MIT, urllib3 MIT, certifi MPL-2.0. Licences of the transitive deps of courlan/htmldate (babel, tld, dateparser, python-dateutil) were **not checked**. trafilatura's PyPI `license` text field is empty; the licence comes from its LICENSE file (Apache License 2.0), README and `license_expression`.

Sources: https://github.com/adbar/trafilatura (README, LICENSE) ; https://pypi.org/project/trafilatura/ ; https://github.com/buriy/python-readability ; https://github.com/matthewwithanm/python-markdownify ; https://github.com/jgm/pandoc (COPYRIGHT) ; https://pypi.org/project/pypandoc-binary/ ; api.github.com repo and release endpoints; pypi.org JSON metadata for each package.

## 2. Sample output (local run)

Pages: docs = https://docs.astral.sh/uv/concepts/projects/init/ (mkdocs, 24 `<pre>` blocks); blog = https://www.joelonsoftware.com/2000/08/09/the-joel-test-12-steps-to-better-code/; wiki = https://en.wikipedia.org/wiki/Markdown (8 `<pre>`, tables); js = https://quotes.toscrape.com/js/ (content injected by JS); spa = https://todomvc.com/examples/react/dist/ (645-byte shell). trafilatura called with `include_links`, `include_images`, `include_tables`; its Markdown output enables formatting itself (docs).

| Page | trafilatura (chars) | readability-lxml + markdownify | pandoc (`-t gfm-raw_html`) |
|---|---|---|---|
| docs | 6,056; 7 headings; **0 code blocks**; headings come out wrapped in permalink links | 8,500; 23 of 24 code blocks as fences (one tabbed block missing); **0 headings** (all section headings lost) | 16,440; includes site nav, header links and an inline base64 SVG |
| blog | 21,210; no `#` heading (title dropped from body, available via metadata) | 21,220; same, title dropped | 22,889; keeps title, author line, category links, author bio, "Post navigation" |
| wiki | 39,595; 17 headings, 8 code fences, 33 table rows (infobox + comparison table), 376 links | 34,724; starts at "History", **lead section lost**; 13 headings, 6 table rows | 45,911; begins with 33 language-switcher links, ends with category links; 0 `\|` table rows (not investigated) |
| js | 29 (site nav only) | 0 (empty) | 173 (nav and footer text) |
| spa | 0 (`extract` returns `None`) | 0 | 96 ("Double-click to edit a todo", footer) |

Findings:

- **Code blocks.** trafilatura dropped every code block on the mkdocs page. Cause: mkdocs-material wraps each code line start in an empty `<a id="__codelineno-..." href="#...">` inside `<code>`. Stripping those anchors from the HTML before extraction (a one-line regex) restored all 24 fences (8,915 chars). `favor_recall` and `fast` modes did not help. Code blocks that live inside table cells (the Wikipedia Markdown-syntax table) are flattened to one line inside a pipe cell by both trafilatura and readability+markdownify.
- **Nav and footers.** trafilatura and readability+markdownify both drop nav, sidebars and footers on all three real pages. Pandoc drops nothing, so it would need a separate stripper and fails the "drops nav and footers" test.
- **Outbound links.** trafilatura with `include_links=True` gave 376 links on the Wikipedia page. Relative links resolve only when the page URL is passed as `url=`; I passed a placeholder, so in-page anchors came out as `https://example.com#...`. A real run must pass the fetched URL.
- **Images.** trafilatura with `include_images=True` emits `![alt](src)`; alt text survives where the source has it (checked on a code sample inside the page). I did not check alt text on real Wikipedia thumbnails (the one thumbnail came out with empty alt).
- **Metadata.** trafilatura with `with_metadata=True` prepends YAML frontmatter (title, author, url, hostname, description, sitename...), which suits ADR 0004's source doc frontmatter and recovers the blog title.
- **Speed (one run, this Mac).** trafilatura 0.01-0.10 s per page; readability+markdownify 0.00-0.10 s; pandoc 0.14-0.44 s except a 10.15 s first call on the blog page (cause not investigated).

## 3. JS-rendered pages

trafilatura's own docs: "Trafilatura works on raw HTML. If a page uses JavaScript to render its content, render it first with a browser automation library" (Troubleshooting, "Page requires JavaScript"); it is "geared towards article pages, blog posts, and main text content"; results "vary on link lists, galleries, or catalogs"; and a document whose extracted text is too short is discarded (log message "discarding document", `MIN_OUTPUT_SIZE`; `MIN_EXTRACTED_SIZE` default 250 triggers fallbacks).

Observed: `None` on the empty SPA shell (95 chars with `favor_recall=True`), and 29 chars (nav only) on the JS-injected quotes page. It does **not** reliably return `None`, so ingest should treat `None` or fewer than a threshold of characters (for example 250, matching trafilatura's own `MIN_EXTRACTED_SIZE`; not tuned) as `failed`. readability+markdownify returned empty strings on both, pandoc returned fragments of nav text and would never signal failure.

## 4. Pick and fallback

**Pick: trafilatura 2.3.1 (Apache-2.0), pinned exactly in a PEP 723 `uv run` script header.**

- Best sample on the three real pages: keeps headings, tables, links, images, most code, and drops boilerplate; native Markdown plus metadata frontmatter in one call.
- Pure-Python wheels, so the only native piece is lxml, which ships macOS wheels. No system install, no browser.
- Pre-clean the HTML with the line-anchor regex above before calling `extract`, or code blocks on mkdocs-material sites vanish. This is the one known sharp edge.
- Apply a minimum-length rule so JS shells become `failed` (section 3).
- Pin `>=1.8.0` at minimum for the Apache-2.0 licence (earlier versions are GPLv3+); an exact pin is better.
- Their own benchmark (https://trafilatura.readthedocs.io/en/latest/evaluation.html, 990 documents, results dated 2026-10-02) puts trafilatura "standard" at F-score 0.926 against readability-lxml 0.853, justext (custom) 0.862, magic-html 0.889. This is the **author's own benchmark**, not independent; it measures text extraction, not Markdown fidelity.

**Fallback: readability-lxml 0.9 (Apache-2.0) + markdownify 1.2.3 (MIT).** Use when trafilatura returns too little on a page that visibly has content. Costs seen: lost every heading on the docs page, the Wikipedia lead section and one code block, drops the page title (take it from `Document.title()`), and no metadata. Its README also reports a self-run benchmark (F1 0.975 over 181 saved pages, second overall); not verified.

**Not recommended: pandoc.** It converts faithfully but does not strip boilerplate (nav, language lists, inline SVG, post navigation all kept), signals no failure on JS pages, is a native binary not on PATH here, and is GPL-2.0-or-later. A hybrid (strip first, then pandoc) adds a dependency for no gain over trafilatura's own Markdown writer.

## 5. Not verified

- Only one page per type, one run each; no sample from a paywalled, forum, or non-English page.
- Whether `favor_precision` or the `prune_xpath` option removes the permalink wrapper around trafilatura headings on mkdocs pages (docs name `prune_xpath`; not tried).
- Real-URL behaviour of relative-link resolution (placeholder URL used) and image alt text on real Wikipedia thumbnails.
- Why pandoc rendered zero pipe tables on Wikipedia and took 10 s on its first call.
- Python and chip details of this run (`uv` provisioned the interpreter; I did not record which, nor arm64 versus x86_64).
- Licences of trafilatura's transitive dependencies beyond the direct ones listed; whether certifi's MPL-2.0 matters for a marketplace plugin (legal question, flagged not decided).
- Whether the benchmark claims of trafilatura and readability-lxml hold; both are the projects' own.
- Headless/sandbox flag: trafilatura and readability+markdownify are plain local Python processes with no browser, expected to work in a restricted sandbox (not tried); `curl` does the fetch, so trafilatura's optional network extras (pycurl, brotli) are not needed.
