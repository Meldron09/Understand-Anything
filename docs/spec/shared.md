# Shared files (`shared/`) and shared scripts (`scripts/`)

Read or run by two or more skills (placement rule in [SPEC.md](SPEC.md#2-plugin-layout-relative-to-the-plugin-root)). Referenced from each `SKILL.md` as `${CLAUDE_PLUGIN_ROOT}/shared/<file>`, one level deep.

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

## `scripts/pdf-pages` (text, slides)

Tier-1 `uv` script (pypdf): `pdf-pages <pdf> <first>-<last> <out.pdf>` copies at most 3 pages into a small PDF, which the skill then reads natively whole. This enforces the cap of 3 native pages per unit and needs no poppler (a `Read` with `pages` does).

## `scripts/lint-skills`

Tier-0 `sh` run in CI and before release: SKILL.md line caps (table in SPEC.md), 200 hard ceiling, reference files over about 120 lines, hidden-description length (at most 250 characters), the `Internal learn-anything step, not for direct use:` prefix and the closing phrase, `user-invocable: false` on hidden skills and `disable-model-invocation: true` on `learn` only, and that every `${CLAUDE_PLUGIN_ROOT}/...` path named in a `SKILL.md` exists.
