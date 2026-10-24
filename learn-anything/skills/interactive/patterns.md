# Interactive patterns

Vanilla JS and inline SVG/CSS only. No libraries, no `<script src>`, no `<link>`, no `fetch`, no `http://` or `https://` anywhere (inline SVG needs no `xmlns`). A concept that fits none of these six becomes a diagram plus text: an inline SVG and a short paragraph, still inside a widget.

## Widget skeleton

Every widget is one `<section class="widget" id="wN">` (N = 1..5, at most 5) inside the body fragment:

```html
<section class="widget" id="w1">
  <h2>Concept name</h2>
  <p class="lead">One or two sentences: what to try and why it matters.</p>
  <div class="demo"> ...demo markup... </div>
  <p class="takeaway">One line: what the learner should now know.</p>
  <script>(function () { /* this widget's logic only */ })();</script>
</section>
```

Rules: every element id is unique and prefixed with its widget (`w1-out`); one IIFE script per widget; set text with `textContent`; use `getElementById('wN-...')` only for ids you wrote. The last element is `<footer>Sources: s1#c01, s1#c02</footer>` listing the unit's chunk ids. Shell classes available: `.demo .out .tip .hidden .hot`, `button.on`, `input[type=range]`.

## The six patterns

1. **Step-through** (algorithms, processes, derivations): an array of steps, Back and Next buttons, an index, and `render()` showing the step text plus its state in `.out` or SVG.
2. **Parameter slider with SVG plot** (quantities, trade-offs): an `<input type=range>`, a `<polyline>` or `<rect>` whose attributes are recomputed on `input`, and a live numeric readout.
3. **Clickable state or flow diagram** (state machines, pipelines, protocols): SVG `<g>` nodes with a click handler that highlights the node (`.hot`) and writes what happens there into `.out`.
4. **A/B toggle** (compare two approaches): two buttons switching `.on` and swapping the demo between variant A and B, with one line saying what changed.
5. **Hover-annotated diagram** (anatomy, architecture): SVG parts with `mouseover` and `mouseout` writing the part's explanation into `.tip`; also bind `click` so it works on touch.
6. **Predict-then-reveal** (misconceptions, surprising results): the learner picks or types a guess first; a Reveal button, enabled only after the guess, shows the true result and compares it.

## Shaping

`novice`: lead with predict-then-reveal and define each term in the lead-in. `intermediate`: no definitions. `advanced`: only apply and edge-case widgets (step-through on an edge case, A/B on a trade-off, predict on a surprising case).
