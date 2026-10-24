# `slides`

**Runs** in a unit subagent; spawns none. **Tier** 0, with an optional render upgrade. Hidden.

**Description:** `Internal learn-anything step, not for direct use: write a slide deck lesson unit as a Marp deck. Runs in a unit subagent; spawns none.`

**Files:** `SKILL.md` (about 60 lines), `marp.md` (deck conventions, the three verify-at-build flags, render command and fallback). Shaping from `shared/shaping.md`. Slidev is dropped from v1.

## Procedure

1. Read the brief, the unit and its slice chunks as in [text.md](text.md) (same chunk-at-a-time rule and native-PDF triggers, cap 3).
2. Write `lesson/uN-slides.md`, a valid Marp deck readable as plain text: **always written**.
3. If `marp` or `npx` is found, also render `uN-slides.html` (self-contained, no browser needed); PDF only when Chrome is found.
4. Return the footer.

## Artifact

- A slide is a title plus at most about 5 short lines, or one figure plus a caption. Depth and level shape the speaker notes and the slide mix, not the per-slide line limit.
- **Speaker notes** (HTML comments) carry the actual teaching; citations go in the notes only.
- The first slide states the brief's goal, the last is takeaways; both count toward `size`. The slide count equals the planned number exactly.
- Math as `$...$` / `$$...$$`, diagrams as fenced `mermaid` in the deck source. No hand-drawn SVG in v1.

## `marp.md` verify-at-build flags (not confirmed from the Marp Core README)

Math on by default in the CLI; Mermaid on by default; KaTeX fonts working offline. If the render leaves math or Mermaid as raw source, the `.html` is still written and the footer says `math=raw` or `diagrams=raw`; this is not a degradation.

## Footer notes

`slides=<n>`, `rendered=html|pdf|none`, `math=raw`, `diagrams=raw`.

## Degradation

Missing `marp`, or a failed render: `done` with `artifact:` the `.md` and `rendered=none`; the conductor tells the learner once at the end how to render it. `degraded` to text only when the deck itself cannot be written well, via the conductor's one text re-dispatch. The router writes `predicted: unrendered` when preflight shows `marp` missing and offers no install-or-downgrade choice for slides.
