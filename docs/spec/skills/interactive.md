# `interactive`

**Runs** in a unit subagent; spawns none. **Tier** 0. Hidden.

**Description:** `Internal learn-anything step, not for direct use: write an interactive HTML explainer lesson unit. Runs in a unit subagent; spawns none.`

**Files:** `SKILL.md` (at most 100 lines), `patterns.md`, `shell-head.html` and `shell-tail.html` (the CSS and the small fixed runtime that sets `data-ready`). Shaping from `shared/shaping.md`; checker `scripts/verify-html`.

## Artifact

One `lesson/uN-interactive.html` holding up to **5 widgets**. A widget is one manipulable demo with a short lead-in and a one-line takeaway. The plan's `size` is `N widgets` (5 minutes each). Chunk ids are listed in a footer inside the page. Self-contained: no external URLs.

## Procedure

1. Read the brief, the unit and its slice chunks as in [text.md](text.md).
2. Choose a pattern per widget from `patterns.md`; write **only** `work/uN/body.html`.
3. Build: `cat shell-head.html body.html shell-tail.html > lesson/uN-interactive.html`.
4. Verify with `scripts/verify-html`; repair once; otherwise return `failed`. No partial files.
5. Return the footer.

## `patterns.md`

Six patterns, vanilla JS plus inline SVG/CSS only: step-through; parameter slider with SVG plot; clickable state or flow diagram; A/B toggle; hover-annotated diagram; predict-then-reveal. A concept fitting no pattern falls to diagram plus text. No D3 in v1 (documented upgrade: D3 v7 inlined).

## Shaping

Every `core:` concept in the unit's `focus` gets a widget; concepts outside `focus` are never added. `novice` leads with predict-then-reveal and defined terms; `intermediate` skips definitions; `advanced` uses only apply and edge-case widgets. Depth changes widget count only within the router's `size`. Ungrounded sources teach from general knowledge and note `ungrounded=true`.

## Verification

`scripts/verify-html` (tier 0): no external URLs, balanced scripts, `getElementById` targets exist, the ready marker present. When `preflight.md` reports a headless Chromium it also dumps the DOM and requires `data-ready` on `<body>`; otherwise the footer notes `not browser-tested`.

## Degradation

Verify, repair once, else `failed`; the conductor re-dispatches once straight to text (an explainer of the same slices and `focus`), recorded `degraded: <reason>`.
