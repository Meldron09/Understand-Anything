---
name: interactive
description: "Internal learn-anything step, not for direct use: write an interactive HTML explainer lesson unit. Runs in a unit subagent; spawns none."
user-invocable: false
compatibility: No binaries needed; a headless Chromium only upgrades verification.
---

# interactive

Write one interactive unit as a self-contained offline HTML page of up to 5 widgets. Spawn nothing. Write only the artifact and `work/<unit-id>/`.

Your brief gives paths: `lesson`, `brief`, `plan`, `unit`, `slices`, `work`, `artifact`. Use the paths exactly as given and never `cd`. Never ask the learner anything.

Patterns and widget skeleton: ${CLAUDE_PLUGIN_ROOT}/skills/interactive/patterns.md. Shaping: ${CLAUDE_PLUGIN_ROOT}/shared/shaping.md. Footer: ${CLAUDE_PLUGIN_ROOT}/shared/footer.md. Checker: `sh ${CLAUDE_PLUGIN_ROOT}/scripts/verify-html <file>`.

## Procedure

1. Read `brief.md` (depth, level, core, goal, `## Level evidence`) and your unit's block in `plan.md` (`focus`, `slices`, `size`). Read the chunk text file of each slice, one chunk at a time, never a whole source. A slice with no chunk file (an ungrounded topic) is taught from general knowledge.
2. Read `patterns.md`. Choose one pattern per widget. `size` is `N widgets`: write N, never more than 5.
   - Every `core:` concept named in `focus` gets a widget, and a widget teaches one concept. That floor beats N (still at most 5); with more than 5 concepts merge the closest. Say so with `short=` when you wrote fewer than N or merged. Never add a concept outside `focus`.
   - Only the six patterns; a concept that fits none is a diagram plus text.
   - Shaping per `patterns.md`; concepts rated `shaky` or `missed` get the richer patterns, `solid` ones a simple one.
3. Write `work/<unit-id>/body.html` and nothing else yet: the widgets and the closing `<footer>` of chunk ids only, no `<html>`, `<head>` or `<body>`.
4. Build: `cat ${CLAUDE_PLUGIN_ROOT}/skills/interactive/shell-head.html <work>/body.html ${CLAUDE_PLUGIN_ROOT}/skills/interactive/shell-tail.html > <artifact>` (create `lesson/` if needed).
5. Verify: `sh ${CLAUDE_PLUGIN_ROOT}/scripts/verify-html <artifact>`, passing `<lesson>/preflight.md` as a second argument when it exists. Add `not browser-tested` to the notes unless that file reports a headless Chromium. On any violation fix `body.html` (never the shell files), rebuild and verify once more.
6. Still failing: `rm -f <artifact>` so no partial file is left, and return `status: failed`, `reason:` the violation. Never `degraded`; the conductor re-dispatches to text.
7. Return the footer. (Run inline, the conductor continues after it; the footer is not the end of the lesson.)

## Footer notes

`widgets=<n>` always, `not browser-tested` per step 5, `ungrounded=true` when the source is ungrounded, `short=<why>` when under N or merged.
