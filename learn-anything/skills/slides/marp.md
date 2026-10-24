# Marp deck conventions, counting and render

## Deck shape

```markdown
---
marp: true
paginate: true
---

# <the brief's goal, as a title>
<!-- speaker notes: the actual teaching, 3-6 sentences, citations here -->

---

## <one concept>
- short line (at most about 5, each a few words)
<!-- notes -->

---

## Takeaways
- ...
<!-- notes -->
```

Slides are separated by a line of exactly `---`; use `---` nowhere else in the body (not as a rule, not in tables). The front matter holds the only other two.

## Count and limits

- Slide count: `grep -c '^---$' <deck>` minus 1. It must equal the plan's `size` exactly, goal slide and takeaways included.
- Per slide, outside HTML comments: a heading plus at most about 5 non-blank lines. Split or trim any slide that runs over.

## Render (step 4)

Work from the deck's folder; the output sits beside it as `uN-slides.html` / `uN-slides.pdf`.

1. Pick the runner (the `- marp: true|false; npx: true|false` line of `preflight.md` if the lesson folder has one, else probe): `marp` if `command -v marp` succeeds, else `npx --yes @marp-team/marp-cli` if `command -v npx` succeeds, else none: stop with `rendered=none`.
2. HTML (needs no browser): `<runner> <deck>.md -o <deck>.html`. It succeeded only if the exit code is 0 and the file exists and is non-empty.
3. PDF, only when Chrome, Chromium or Edge is found (the `- headless chromium: true|false` line of `preflight.md` if the lesson folder has one, else `command -v google-chrome chromium chromium-browser`, else `/Applications/Google Chrome.app`): `<runner> <deck>.md --pdf -o <deck>.pdf`. A failed PDF leaves the HTML in place.
4. Footer `rendered=` is `pdf` if the PDF was written, else `html` if the HTML was, else `none`.

A failed or missing render is `done` with `rendered=none`, never `degraded` or `failed`. Retry at most once; never install anything.

## Verify at build (not confirmed from the Marp Core README)

Three flags: math on by default in the CLI, Mermaid on by default, KaTeX fonts working offline. After a render, check the HTML:

- the deck holds `$` math but the HTML has no `katex` class: footer `math=raw`;
- the deck holds a `mermaid` fence and the HTML still has `language-mermaid`: footer `diagrams=raw`.

The `.html` still ships. These are footer notes only, not a degradation, and the conductor does not surface them.
