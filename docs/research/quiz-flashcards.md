# Research: quiz and flashcard formats (issue #16)

Date: 2026-10-24. Constraints: free/OSS, local only, local macOS Claude Code primary (map #1).
Method: primary sources only (Anki manual, Anki and genanki repos/PyPI, MDN, KaTeX docs). Nothing was installed or run; every quality claim is **not verified locally**.

## Comparison

| Criterion | Anki .apkg | Anki text/CSV import | Self-contained HTML quiz | Plain Markdown |
|---|---|---|---|---|
| How an agent generates it | Needs a library: genanki (Python, MIT) writes a zip holding a SQLite `collection.anki2` plus a `media` JSON map [1][2]. Hand-writing the SQLite is impractical. | Write a text file: UTF-8, one note per line, optional `#separator:`/`#html:`/`#notetype:`/`#deck:` header lines (Anki 2.1.54+) [3]. Plain `Write`, no library. | Write one `.html` file (native skill for an agent). `<details>` gives show/hide answers with no JS [7]. | Write `.md`. Trivial. |
| Extra install needed | To generate: genanki + Python >=3.6 [8]. To use: Anki desktop (free, AGPL-3.0+) [5][9]. | To use: Anki desktop only [3][9]. To generate: none. | None: any browser opens it. | None. |
| Works offline | Yes once Anki is installed (sync is optional) [9]. genanki install needs network once (pip); beyond that unknown. | Same as .apkg. | Yes if no CDN links; all CSS/JS inline. | Yes. |
| Answer checking | None automatic. Anki is self-rated recall: the learner rates how well they remembered [10]. Type-in-answer cards exist in Anki but were not researched (unknown). | Same as .apkg (import only creates notes). | Yes, if the agent writes it: MCQ and exact/normalised-match checks in inline JS. Not verified locally. | None. At most answers hidden in `<details>` (viewer support unknown). |
| Spaced repetition | Yes, Anki scheduler; FSRS is an opt-in alternative to legacy SM-2 [11]. | Yes, same. Re-import updates by first field or GUID, keeping scheduling [3]. | No (would need custom persistence; out of v1 scope per map #1). | No. |
| Math / code rendering | MathJax is bundled, needs no extra software; `\( \)` and `\[ \]` [4]. LaTeX `[latex]` tags need an external LaTeX install plus dvipng and are off by default [4]. Fields are HTML so code works via `<pre><code>`; the docs I fetched do not mention syntax highlighting [4][6]. | Same as .apkg, but only with `#html:true`; escape `<`, `>`, `&` [3]. | Math needs KaTeX or MathJax. KaTeX self-hosting needs JS + CSS + a `fonts/` dir kept next to the CSS [12], so a true single file means inlining/base64 (size unknown, not verified). Code: `<pre><code>` works natively; highlighting would need a bundled lib (unknown). | Depends entirely on the viewer (not researched, unknown). Code fences are standard Markdown. |

## Per-format facts

### Anki .apkg
- An `.apkg` is a packaged deck: cards, notes, note types and media in one file. Importing merges into the collection; for an existing note the newer modification time wins [5].
- genanki: MIT, Python 3 library, PyPI latest 0.13.1 released 2023-11-12 [8]. Last commit on `main` 2024-12-30, repo not archived, 37 open issues (GitHub API, queried 2026-10-24) [2]. So about 22 months without commits: **stable but not actively maintained**.
- API: `genanki.Model(id, name, fields, templates)`, `Note`, `Deck(id, name)`, `Package(deck).write_to_file('x.apkg')`. Model and deck IDs must be unique and hardcoded; default note GUID is a hash of the fields, so regenerating the same content re-imports as an update [1].
- Fields are HTML, so literal `<`, `>`, `&` (including in LaTeX) must be escaped with `html.escape` [1].
- Package write path confirmed in source: `zipfile` + `sqlite3` writing `collection.anki2` and a `media` JSON [2].
- Anki itself is very active: release 26.09.3 on 2026-09-23, last push 2026-10-23, macOS dmgs for Apple silicon and Intel [9a]. Site says macOS 13+ [9].
- genanki writes the older `collection.anki2` layout. The manual says Anki can export a "legacy" package for older clients versus a newer, faster, compressed format [5]. Whether current Anki imports genanki output cleanly: **not verified locally** (unknown).

### Anki text/CSV import
- Plain text, comma/semicolon/tab separated, UTF-8; quote fields containing newlines or separators, double the `"` to escape [3].
- Header lines (2.1.54+): `#separator`, `#html`, `#notetype`, `#deck`, `#tags column`, `#guid column`, `#columns`, `#notetype column`, `#deck column`, `#tags` [3].
- HTML must be enabled (`#html:true`); use `<br>` rather than quoted newlines, especially for multi-line cloze [3].
- Duplicates are detected on the first field; by default the existing note is updated and keeps its deck and scheduling; a supplied GUID that already exists does not duplicate [3].
- Media must be copied manually into `collection.media` (no subfolders) [3]. This is the main weakness versus .apkg, which bundles media [1][5].
- The import page documents no Markdown import [3]. Whether an add-on does: **unknown** (not researched; it would add an install).

### Self-contained HTML quiz
- `<details>/<summary>` works without JS; Baseline "widely available" since January 2020 [7].
- Answer checking, scoring, shuffling and flip cards are ordinary inline JS the agent can write. No sample was run (not verified locally).
- KaTeX is MIT. Browser use needs the HTML5 doctype, `katex.min.css`, `katex.min.js` and the `fonts/` directory next to the CSS; auto-render is a separate `contrib` file [12]. The KaTeX page does not explicitly address fully offline use [12]. Shipping those files from the plugin would make a multi-file artifact, not a single file.
- Graceful degradation: without KaTeX, show raw LaTeX in `<code>`; the quiz still works.

### Plain Markdown
- No tooling at all, the universal degrade target. No checking, no SR; rendering is viewer dependent (not researched).

## Pick and fallback

**Pick: self-contained HTML quiz** (one inline `.html`: flip cards plus MCQ/short-answer with in-page checking, `<details>` for answers; math as KaTeX only if bundled, otherwise readable LaTeX text).
- Only option with zero install, offline, and real answer checking, which is what a one-lesson v1 needs (map #1 excludes spaced repetition and progress tracking).
- Generation is the agent's native skill, with no dependency to document.

**Fallback: plain Markdown** Q/A (answers in `<details>` or a trailing "Answers" section). Meets "graceful degradation to text".

**Optional add-on, not the pick:** an Anki text import file (`.txt` with `#separator:tab`, `#html:true`, `#deck:`, `#guid column:`). It costs the agent no library and gives spaced repetition to learners who already use Anki [3][11]. Prefer it over `.apkg`, which needs genanki (a Python install, no commits since 2024-12-30) mainly to bundle media [1][2][8]. Choose `.apkg` only if a mode needs bundled images.

## Open items (unknown / not verified)
- Whether KaTeX inlines into a single HTML file at acceptable size.
- Whether current Anki imports genanki `.apkg` cleanly; any syntax-highlighting story in Anki.
- How Markdown viewers render math and `<details>`.

## Sources
1. https://github.com/kerrickstaley/genanki (README: API, GUIDs, escaping, media)
2. https://github.com/kerrickstaley/genanki/blob/master/genanki/package.py and the GitHub API for the repo (commits, license, issues)
3. https://docs.ankiweb.net/importing/text-files.html
4. https://docs.ankiweb.net/math.html
5. https://docs.ankiweb.net/exporting.html and https://docs.ankiweb.net/importing/packaged-decks.html
6. https://docs.ankiweb.net/editing.html (HTML editor; no highlighting mentioned)
7. https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Elements/details
8. https://pypi.org/project/genanki/ (JSON API: 0.13.1, 2023-11-12, Python >=3.6, MIT)
9. https://apps.ankiweb.net/ (free desktop, macOS 13+); 9a. https://github.com/ankitects/anki (AGPL-3.0+ LICENSE, release 26.09.3 on 2026-09-23)
10. https://docs.ankiweb.net/getting-started.html (recall rating, scheduling)
11. https://docs.ankiweb.net/deck-options.html (FSRS opt-in vs legacy SM-2)
12. https://katex.org/docs/browser
