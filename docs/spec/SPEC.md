# learn-anything: build spec

A Claude Code plugin that helps one learner understand any concept from any source: it interviews the learner, ingests their sources, plans a lesson, produces it in the modes they chose, and closes with a comprehension check. This spec is the destination of the wayfinding map (issue 1); building the plugin is a separate effort. Terms are those of [`CONTEXT.md`](../../CONTEXT.md), used exactly. Locked architecture lives in [`docs/adr/`](../adr/); per-skill detail in [`skills/`](skills/).

**Hard constraints:** free/OSS and local only (no paid APIs, no generative text-to-video); no machine-specific paths; every mode degrades to text; context efficiency is first-class (minimal subagent briefs, large artifacts on disk by path, lean `SKILL.md`).

**Out of scope (v1):** building anything beyond the spec; multi-session learning (learner model, progress, spaced repetition; the seam is moving `brief.md` up one level and `check.md`'s stable path); paid APIs; generative video; crawling; Anki export; D3; Revideo, handanim, Blender renderers.

## 1. Flow

```
/learn-anything:learn [topic | URL | file | lesson-slug]          conductor, main thread
  resume?  exact folder match -> state is the files, continue at first missing artifact
  intake   (inline)  interview -> brief.md, preflight.md
  ingest   (inline, or subagents for large sources) -> sources/sN/index.md + chunks
  router   (inline)  brief + indexes + preflight + renderers.md -> plan.md
  plan gate  one confirm/adjust (skipped for a one-unit plan)
  units    one subagent per unit, max 3 concurrent (a one-unit plan runs inline) -> lesson/uN-<mode>.<ext>
  check    (inline) after every unit is done/degraded -> check.md, at most one re-explain loop
```

The conductor holds only paths, unit statuses and the brief's fields. The plan on disk is the only seam between steps; whether a unit runs inline or in a subagent is invisible to it (ADR 0002).

## 2. Plugin layout (relative to the plugin root)

```
.claude-plugin/plugin.json     name learn-anything, version (only here), description, license MIT, keywords
README.md                      canonical tier table and per-mode degradation
shared/                        read by 2+ skills
  shaping.md  footer.md  items.md  renderers.md
scripts/                       run by 2+ skills, tier-0 POSIX sh
  preflight  verify-html  lint-skills
skills/
  learn/        SKILL.md <=150 + dispatch.md      conductor, the only user-invocable skill
  intake/       SKILL.md <=150 + protocol.md + ladder.md
  ingest/       SKILL.md <=120 + scripts/
  router/       SKILL.md <=120
  check/        SKILL.md <=80
  text/         SKILL.md ~60
  slides/       SKILL.md ~60 + marp.md
  interactive/  SKILL.md <=100 + patterns.md + shell-head.html + shell-tail.html
  quiz/         SKILL.md <=100 + quiz-head.html + quiz-tail.html
  video/        SKILL.md <=120 + narrate.md + assemble.md + refs/<renderer>.md
```

Placement rule: anything read or run by two or more skills lives in `shared/` (documents) or `scripts/` (executables); single-owner files stay beside their skill. No `agents/`, `hooks/`, `bin/` or `CLAUDE.md`. The conductor spawns a general-purpose subagent whose brief starts "invoke skill `learn-anything:<mode>`".

**Budgets** (defaults): line caps as in the tree, hard ceiling 200 for any `SKILL.md`; references at most about 120 lines (table of contents above 100); hidden descriptions at most 250 characters, starting `Internal learn-anything step, not for direct use:` and ending with exactly one of `Runs inline.` / `Spawns subagents.` / `Runs in a unit subagent; spawns none.`; the conductor's description puts the trigger first, carries a "not for" clause (quick factual questions) and ends `Runs inline and spawns subagents.`; invariants go in the first 5,000 tokens of a file (only that much of an invoked skill survives compaction). Each mode skill states its binary needs in one `compatibility` line. `user-invocable: false` on all hidden skills (not `disable-model-invocation`, which would hide them from the conductor); `disable-model-invocation: true` on `learn` only. `scripts/lint-skills` checks line caps, description lengths and template phrases; CI also runs `claude plugin validate --strict`.

**Scripts:** tier-0 ones (`preflight`, `verify-html`, `lint-skills`, hash checks) are POSIX `sh` using only `grep`, `shasum`, `command -v`. Tier 1+ ones (URL fetch, PDF chunking, summary merge, narration) are single-file Python with pinned PEP 723 inline dependencies, run as `uv run`. No Node scripts; Node appears only as printed commands in `refs/hyperframes.md`. `${CLAUDE_PLUGIN_ROOT}` and `${CLAUDE_PLUGIN_DATA}` are substituted in `SKILL.md` text but absent from the Bash environment, so every command line carries the substituted path, and scripts take `--data-dir`. Large downloads (kokoro weights, HyperFrames install) and the pinned `uv` environment live in `${CLAUDE_PLUGIN_DATA}`, never in the plugin directory or the lesson folder.

## 3. The lesson folder (learner's machine)

```
./learn-anything/<lesson-slug>/
  brief.md                      intake; written once (amend pass edits fields in place)
  preflight.md                  scripts/preflight, rewritten each run
  sources/s1/index.md           ingest: frontmatter + chunk entries
  sources/s1/chunks/c01.md ...  text chunks (PDF chunks: page pointers + pdftotext cache)
  plan.md                       router writes content; the conductor is its only writer
  lesson/u1-text.md  u2-slides.md [+ .html]  u3-interactive.html  u4-quiz.html [+ .items.json]  u5-video.mp4 [+ .srt]
  work/<unit-id>/               subagent scratch; deleted on done, kept otherwise, cleared before re-dispatch
  check.md  reexplain.md        comprehension check result and the one targeted re-explanation
  plan.1.md  lesson.1/          archived by a changed brief or source hash
```

Slug: 2-4 kebab-case topic words, `-2` on collision. Originals are referenced in place and hashed, never copied.

## 4. Cross-cutting contracts

**Handoff (ADR 0003).** Brief in: about 10 lines of paths (brief, plan, unit id, slices, work dir, artifact path) plus one task sentence, never pasted content. Result out: at most about 150 words ending in the footer in [`shared/footer.md`](#footer); over about 100 words goes to disk and returns as a path. Subagents write only their artifact and `work/<unit-id>/`, and spawn none (depth 1).

<a id="footer"></a>**Footer** (`shared/footer.md`):

```
status: done | degraded | failed
artifact: <path>
reason: <only on degraded/failed>
notes: <key=value list; the conductor surfaces only short=, rendered=none, ungrounded=true>
```

The conductor copies `status` into `plan.md`. On `failed` or a missing footer it re-dispatches the unit once, straight to text, recorded `degraded: <reason>`; `done` and `degraded` units are never re-run.

**Dependency tiers (ADR 0001).** 0 none (text, slides as `.md`, interactive, quiz) · 1 `uv` (kokoro-onnx, pypdf, trafilatura) · 2 plus ffmpeg, cairo and pkg-config (narrated video via Manim CE) · 3 opt-in Node 22+ and Chromium (HyperFrames; Chromium also upgrades `verify-html`). `uv` is the only hard bootstrap; LaTeX never required; poppler soft. The plugin never installs system tools (it prints the command). Preflight capabilities include the ffmpeg `subtitles` filter, a headless Chromium, `marp`/`npx`, cairo/pkg-config, Node version. `scripts/preflight` runs before the modes question and again before each render, writes `preflight.md`, no SessionStart hook, no cache.

**Degradation** is per lesson unit and always announced and recorded, never silent: picked renderer, its fallback, silent video plus narration script, a non-video mode, text as the floor. A failure predicted at plan time is offered once (install or downgrade); render-time failure falls back automatically and keeps partials. Per-skill ladders are in the skill files.

**Sizing and caps** (untested defaults, retune after a Mac spike). Router plans to 90% of the time budget (the rest is the check) using: text 200 words/min, slides 1.5 min/slide, interactive 5 min/widget, quiz 0.5 min/item, video `size` in minutes. Plan capped at 8 units and 5 minutes of video; an over-cap plan goes back to the learner to cut, never silently shrunk. 3 concurrent subagents, one per unit; video scene jobs `min(2, cores/4)`; renderer workers 1. Chunk summaries use the `haiku` alias, everything else the session model; no model ids hard-coded. Cost is shown at the plan gate (units, subagents, video minutes, tier, download size), not metered.

**Mode is binding.** The router chooses slicing, order, size and renderer, never adds or drops a mode. Every `core:` concept in a unit's `focus` is taught (text: own section; interactive: a widget; quiz: at least two items); concepts outside `focus` are never added.

## 5. Skill index

| Skill | Runs | Tier | Spec |
|---|---|---|---|
| `learn` | inline + spawns subagents | 0 | [skills/learn.md](skills/learn.md) |
| `intake` | inline | 0 (preflight) | [skills/intake.md](skills/intake.md) |
| `ingest` | inline / subagents | 1 | [skills/ingest.md](skills/ingest.md) |
| `router` | inline | 0 | [skills/router.md](skills/router.md) |
| `text` | unit subagent | 0 | [skills/text.md](skills/text.md) |
| `slides` | unit subagent | 0 (+render) | [skills/slides.md](skills/slides.md) |
| `interactive` | unit subagent | 0 | [skills/interactive.md](skills/interactive.md) |
| `quiz` | unit subagent | 0 | [skills/quiz.md](skills/quiz.md) |
| `video` | unit subagent | 1-3 | [skills/video.md](skills/video.md) |
| `check` | inline | 0 | [skills/check.md](skills/check.md) |

Shared files and scripts: [shared.md](shared.md).

## 6. Dependencies and pins

| Need | Pick | Fallback / note |
|---|---|---|
| URL to Markdown | trafilatura 2.3.1 (Apache-2.0; pin at least 1.8.0, earlier were GPLv3+) | readability-lxml + markdownify |
| PDF | Claude native page reading (20 pages/call) + poppler `pdftotext -layout` + pypdf outlines | Docling (MIT) is a documented upgrade, not v1; PyMuPDF excluded (AGPL) |
| OneNote | learner exports the page to PDF | Graph OneNote API (delegated auth) is a documented upgrade; the Microsoft 365 connector cannot read OneNote |
| Static slides | Marp CLI (`.md` always, `.html` when `marp` or `npx` exists, PDF only with Chrome) | Slidev dropped |
| Interactive | vanilla JS + inline SVG/CSS | D3 v7 inlined is a documented upgrade; Pyodide needs a server, Three.js a bundler |
| Quiz | self-contained HTML (`mcq`/`short`/`flip`) | plain Markdown Q/A |
| Video renderers | Manim CE (tier 2), HyperFrames (tier 3, exact pin, telemetry off, frame streaming on) | HyperFrames rows fall back to Manim; Manim rows have none |
| TTS / captions / assembly | kokoro-onnx; sentence-level SRT from measured durations; ffmpeg CLI | macOS `say`; whisper.cpp; MoviePy 2.x |

Research findings live on the `research/*` branches linked from the map; superseded picks (Revideo, handanim, Blender) are recorded in ADR 0005.

## 7. Testing

Two seams, no more (see the spec issue for the full testing decisions). **Seam 1:** the lesson folder after running the conductor on fixture sources with a canned `brief.md`: assert on files, frontmatter schemas, statuses, footers and degradation records, not prose. **Seam 2:** each script's CLI with fixtures (`preflight` under controlled `PATH`, `verify-html` on good and bad HTML, `lint-skills` on the plugin tree, ingest fetch/chunk/merge, narration timing). Skill wording is tested only through seam 1. Greenfield: no prior art in this repo; `claude plugin validate --strict` is the existing check for the manifest.

## 8. Choices made while assembling this spec (not grilled; change freely)

- `preflight.md` lives at `./learn-anything/<lesson-slug>/preflight.md` (the folder exists before the modes question).
- Comprehension-check size by depth: gist 2 items, working 4, mastery 6 plus one `explain`; each `short` item costs 0.5 min inside the 10% the router leaves.
- `check.md` and `reexplain.md` formats (check skill file).
- `intake/protocol.md` and `intake/ladder.md` split; `learn/dispatch.md` for the brief template and footer parsing.
- Outbound links found in a fetched URL are recorded in the source's `index.md` frontmatter and mentioned at the plan gate; adding one goes through the amend pass.
- Interactive and quiz HTML shells are plain files `cat`-ed around subagent output, living beside their skill.
- The plan gate is skipped when the plan is exactly one unit at tier 0 (ADR 0002 said "a single text unit", ADR 0003 "exactly one unit"; this reconciles them so a lone video unit still shows its cost and consent).
- Plan status `failed: <reason>` exists for a unit whose text re-dispatch also fails; the router writes an over-cap plan marked for refusal rather than shrinking it; units are ordered explainers first, quiz last, source order within a mode.
- The cells of `shaping.md`'s depth x level table are composed from the rules the text-and-slides ticket decided; the rules are decided, the exact cell wording is not.
- Footer note keys for interactive, quiz and video are listed in `shared.md`; only text and slides keys were decided in grilling.

## 9. Unknowns to verify at build time

- A subagent can invoke a `user-invocable: false` skill (unverified in the plugin-constraints research); if not, add one `agents/learn-unit.md` that preloads the mode skill.
- Marp: math on by default in the CLI, Mermaid on by default, KaTeX fonts offline (three flags in `marp.md`).
- Render time and cost per minute of output for both renderers, scene parallelism, the 20 s scene length, the blank-scene threshold: a Mac spike.
- HyperFrames exact version to pin; GSAP licence terms; ffmpeg `subtitles` filter availability (Homebrew ffmpeg lacks libass).
- Whether `${CLAUDE_PLUGIN_ROOT}` substitution reaches a subagent that loads the skill (expected, per the research).

## 10. Decision log

ADRs: [0001 local rendering](../adr/0001-local-rendering-with-tiered-dependencies.md), [0002 conductor and plan seam](../adr/0002-conductor-with-hidden-steps-and-plan-file-seam.md), [0003 subagents and handoff](../adr/0003-depth-one-subagents-with-single-writer-plan.md), [0004 source docs and chunks](../adr/0004-one-source-doc-per-source-with-pointer-chunks.md), [0005 video renderers](../adr/0005-two-video-renderers-with-shared-narration-and-assembly.md). Smaller decisions are in the resolution comments of the map's tickets.
