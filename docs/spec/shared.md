# Shared files (`shared/`) and plugin-level scripts (`scripts/`)

Read or run by two or more skills, or run by the conductor and router on `plan.md` (placement rule in [SPEC.md](SPEC.md#2-plugin-layout-relative-to-the-plugin-root)). Referenced from each `SKILL.md` as `${CLAUDE_PLUGIN_ROOT}/shared/<file>`, one level deep.

## `shared/shaping.md` (text, slides, interactive, quiz)

One depth x level table. Size is a target of ±15%; write less and say so (`short=<why>` in the footer) rather than pad.

| | `novice` | `intermediate` | `advanced` |
|---|---|---|---|
| **`gist`** | the idea, one example, no edge cases; define each term on first use; one analogy | the idea and one example; skip anything the ladder rated `solid` | the idea in a few lines; drop basics |
| **`working`** | gist plus a worked example and a "when it goes wrong" line; terms defined; analogy | worked example and the failure line; skip `solid` rungs | worked example and failure line only; no definitions |
| **`mastery`** | working plus edge cases, why-not-the-alternative, and a derivation or proof sketch where one exists; terms defined; analogy | mastery content, skip `solid` rungs | edge cases, alternatives and derivation only |

Rungs graded `shaky` or `missed` in `brief.md`'s `## Level evidence` get extra space; `solid` rungs get a pointer. Mode-specific effects (which widgets or items to use) are in the skill files. Depth changes content within the router's `size`, never the size.

## `shared/footer.md` (every unit skill, and the conductor's parser)

```
status: done | degraded | failed
artifact: <path to the lesson artifact>
reason: <only on degraded or failed>
notes: <comma-separated key=value; keys below>
```

Notes keys: text `words=<n>`, `ungrounded=true`, `native_pages=<n>`, `short=<why>`; slides `slides=<n>`, `rendered=html|pdf|none`, `math=raw`, `diagrams=raw`; interactive `widgets=<n>`, `not browser-tested`, `ungrounded=true`; quiz `items=<n>`; video `scenes=<n>`, `seconds=<n>`, `captions=sidecar|soft|none`, `narration=kokoro|say|none`. The conductor surfaces notes to the learner only for `short=`, `rendered=none`, `ungrounded=true`. The result message is at most about 150 words including the footer.

## `shared/items.md` (quiz, check; single source of truth for items)

An item is one object in `items.json`:

| Field | Meaning |
|---|---|
| `id` | `i01`... unique within the file |
| `type` | `mcq` (auto-checked) · `short` (type an answer, reveal, self-rate) · `flip` (flashcard, self-rated) · `explain` (check only, mastery depth) |
| `concept` | the exact `core:` name from `brief.md`, or `other` |
| `rung` | `define` · `why` · `apply` · `edge` |
| `q` | the question or card front |
| `answer` | the reference answer or card back |
| `rubric` | what a `solid` answer contains, one or two lines (used for grading) |
| `choices` | `mcq` only: options, the correct one marked |
| `alt` | a fresh variant of the item testing the same thing (serves the check's one re-ask) |
| `slice` | the slice the item draws from, e.g. `s2#c03` |

Grades vocabulary everywhere: `solid | shaky | missed`.

## `shared/renderers.md` (router, video)

Maintained with the video skill, read by the router, which matches on concept wording and never opens `refs/`. Five rows; a fallback is never a higher tier than its pick; a unit takes the dominant row; the router never splits a unit.

| Concept type | Pick | Fallback | Tier | Ref |
|---|---|---|---|---|
| math, geometry, simple 3D, hand-sketch-style reasoning | manim | none | 2 | `refs/manim.md` |
| algorithm and data-structure traces | manim | none | 2 | `refs/manim.md` |
| processes, mechanisms, diagrams, definitions, comparisons, narrative explainers | hyperframes | manim | 3 | `refs/hyperframes.md` |
| data and charts | hyperframes | manim | 3 | `refs/hyperframes.md` |
| code walkthroughs, diffs, terminal sessions | hyperframes | manim | 3 | `refs/hyperframes.md` |

Footer line: narration (`narrate.md`), captions and assembly (`assemble.md`) are shared by both renderers.

## `scripts/preflight`

Tier-0 `sh`. Prints a compact JSON to stdout and writes `preflight.md` (to the lesson folder passed as an argument) with: tiers available (0 always; 1 `uv`; 2 ffmpeg + cairo + pkg-config; 3 Node 22+ and a headless Chromium), capability probes (ffmpeg `subtitles` filter, `marp`/`npx`, `pdftotext`, Chrome for slide PDF, `say`), the exact install command for each missing piece, and the download size to state at consent. Never installs anything. Exit code 0 even when pieces are missing; a failure to run is reported by the caller as "preflight unavailable" (intake then skips mode annotations).

## `scripts/verify-html` (interactive, quiz)

Tier-0 `sh` taking an HTML path. Rules: no external URLs (`http://` or `https://` in `src`/`href`/`url()`), balanced `<script>` tags, every `getElementById` target exists, the ready marker (`data-ready` attribute set by the runtime) is present in the source. Prints one line per violation; non-zero exit on any. When `preflight.md` reports a headless Chromium, also runs `--dump-dom` and requires `data-ready` on `<body>`; otherwise the caller adds `not browser-tested` to the footer notes.

## `scripts/pdf-pages` (text)

Tier-1 `uv` script (pypdf): `pdf-pages <pdf> <first>-<last> <out.pdf>` copies at most 3 pages into a small PDF, which the skill then reads natively whole. This enforces the cap of 3 native pages per unit and needs no poppler (a `Read` with `pages` does).

## `scripts/lint-skills`

Tier-0 `sh` run in CI and before release: SKILL.md line caps (table in SPEC.md), 200 hard ceiling, reference files over about 120 lines, hidden-description length (at most 250 characters), the `Internal learn-anything step, not for direct use:` prefix and the closing phrase, `user-invocable: false` on hidden skills and `disable-model-invocation: true` on `learn` only, and that every `${CLAUDE_PLUGIN_ROOT}/...` path named in a `SKILL.md` exists.

## Conductor and router scripts

All tier-0 `sh` (POSIX utilities only, see SPEC.md section 2), printing plain lines the caller copies or acts on, so the model never computes them. Their tests are in `tests/<name>/run.sh`.

- **`scripts/plan-gate <lesson-dir> [--data-dir <dir>]`** (conductor): one line per unit, a `totals:` line, `links:` and `consent:` lines, and a last line `gate: skip | show | refuse (<why>)`. Refuses more than 8 units or 5 video minutes or a plan marked `over-cap:`; skips exactly one tier-0 unit; sums download size from `preflight.md` plus the kokoro weights.
- **`scripts/plan-unit set <plan.md> <unit> <status> [artifact]` / `report <plan.md>` / `next <plan.md>`** (conductor, the only writer of `plan.md`): records a unit's status, lists degraded or failed units for the close, and prints the next dispatch round (the first at most 3 `pending` ids in plan order). `set` collapses a repeated `degraded: ` so a video reason that already carries it is recorded once.
- **`scripts/plan-size <budget> <mode>...`** (router): one `<mode>` argument per planned unit. Prints `planned: N` (90% of the budget, the rest is the check), then `uN <mode> <size>` in plan order (explainer modes first in the order text, slides, interactive, video, then quiz; same-mode units in input order) and `over-cap: <why>` for more than 8 units or 5 video minutes. The budget is split equally across units (never given whole to each) at the rates text 200 words/min, slides 1.5 min/slide (at least 3), interactive 5 min/widget (1 to 5), quiz 0.5 min/item, video 1 min per minute (at least 1); a tiny budget can overshoot through the minimums.
- **`scripts/renderer-pick <renderers.md> <row> [preflight.md]`** (router): the `renderer:` and `tier:` lines for a video unit, plus `downgraded:` or `predicted:` from the preflight probes.
- **`scripts/resume-check match <arg> | list | <lesson-dir>`** (conductor): classifies the argument, lists unfinished lessons (no plan yet, a pending unit, or every unit finished with `check.md` missing), and on resume archives a stale plan, clears pending work and prints `resume: intake | ingest sN.. | router | units uN.. | done`.
- **`scripts/degrade-words "<size>"`** (conductor): converts a unit's size to the words of its text re-dispatch (`2 min` is 400 words).
