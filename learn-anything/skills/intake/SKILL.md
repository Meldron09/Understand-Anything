---
name: intake
description: "Internal learn-anything step, not for direct use: interview the learner and write brief.md. Runs inline."
user-invocable: false
compatibility: No binaries needed.
---

# intake

Runs inline in the main thread (subagents lose `AskUserQuestion`). Interview rules: ${CLAUDE_PLUGIN_ROOT}/skills/intake/protocol.md. Never read a source.

Input: the conductor's first input (a topic, or nothing). Output: `./learn-anything/<slug>/brief.md`, written once, and the slug.

## Flow

1. **Classify the argument.** A URL (`http://` or `https://`) or an existing file path is a source: record it for step 3 and ask for the topic in plain words. Anything else is the topic. Then **goal and why.** Take the topic if given, else ask what the learner wants to understand. Ask once why they want it. Narrow a too-broad goal once.
2. **Slug.** 2-4 kebab-case words from the topic. If `./learn-anything/<slug>/` exists, use `<slug>-2`, then `-3`. Create the folder now.
3. **Sources**, asked once ("Any sources: URLs, files? None means I teach from general knowledge"), several allowed, kept in the order given. Cheap checks only, never open a file: a path must exist (`test -f`), a URL must start with `http://` or `https://`. Accepted: `.md`, `.txt`, `.html`, code, `.pdf`. Refuse `.docx`, `.epub` and images, naming the export hint: Word, save as PDF or paste into a `.md`; EPUB, convert to PDF or text; image, give the text or a PDF. A missing path: say so and ask once more. For OneNote, say: export one page at a time to PDF and give me the file (Windows desktop: File > Export > PDF; Mac: File > Save as PDF; web: Export as PDF on Mac, Print to PDF on Windows; the web app cannot export a whole notebook or section). No sources: `sources: [topic]`.
4. **Ladder, then self-rating.** Rungs, grading, level mapping, skip and evidence format: ${CLAUDE_PLUGIN_ROOT}/skills/intake/ladder.md. Keep the graded rungs for the brief.
5. **Core concepts.** Propose 3-5 noun phrases from the goal and the ladder's gaps (general knowledge, never the sources); the learner confirms or edits.
6. **Depth** `gist | working | mastery`, then **budget** as one integer of minutes including the comprehension check (presets 15 / 30 / 60 / 120).
7. **Preflight, then modes.** Run `sh ${CLAUDE_PLUGIN_ROOT}/scripts/preflight ./learn-anything/<slug>` (writes `preflight.md`; JSON on stdout; never installs). Then ask the modes as a multi-select of `text`, `slides`, `video`, `interactive`, `quiz` (a mix is several values; `modes` lists every pick). Annotate every mode by this rule, which amend mode reuses: a mode whose tier or tool is missing in the JSON stays selectable, with its need appended. `text` and `quiz` need nothing; `interactive` when `chromium` is false (`not browser-tested without a headless Chromium`); `slides` when `marp` and `npx` are both false (`the deck is still written; rendering needs marp or npx`); `video` when tier 2 is false (`needs uv, ffmpeg, cairo and pkg-config`; HyperFrames also needs Node 22+ and Chromium). If the script is missing, errors or prints nothing, say "preflight unavailable" once and skip annotations; never block on it.
8. **Write `brief.md`** once, then read the key fields back in two lines (not a gate).

## `brief.md`

```markdown
---
lesson: <slug>
goal: <one line>
sources: [topic]        # paths, URLs, or the literal topic, in the order given
level: novice            # novice | intermediate | advanced
depth: working           # gist | working | mastery
budget: 30               # minutes, including the comprehension check
modes: [text, quiz]      # one or more of text | slides | video | interactive | quiz
core: [concept one, concept two, concept three]
assumed: []              # set by default, not by the learner; [level] if the ladder was skipped
---
## Why
<the learner's reason, a few lines>

## Level evidence
define | What is a SYN packet? | solid | defined correctly
why | Why does SYN-ACK carry two flags? | shaky | knew the flags, not the reason
apply | ... | missed | could not trace the exchange
self-rating: intermediate (ladder says novice)
```

Skipped ladder: the evidence is `none (ladder skipped; level assumed)` and `assumed: [level]`.

`core` entries are the exact names every later skill matches on. `sources` entries are paths, URLs, or the literal `topic`.

## Amend mode

Invoked only by the conductor from the plan gate, with the lesson folder and the learner's change. Input says "amend".

1. **Refuse once anything has run.** Read `./learn-anything/<slug>/plan.md`: if any unit's `status:` is not `pending`, change nothing and reply that a change now starts a new lesson with a full intake (nothing seeded).
2. **Edit `brief.md` in place**, only the touched fields (`depth`, `budget`, `modes`, `sources`, `level` with its evidence, or `core` if the learner names it); never rewrite the file or re-ask settled fields. A topic change is not an amend: reply that it starts a new lesson.
3. A new mode re-runs preflight (step 7) and annotates as before. Added or removed `sources` are validated as in step 3 and only edit the field; the conductor re-ingests.
4. **A claim of a higher level** resumes the ladder where evidence stopped: from the first rung not yet asked, or re-ask the rung that was graded `missed` (new wording) when the ladder stopped there; if the ladder was skipped, from rung 1 and drop `level` from `assumed`. Grade and stop as in `ladder.md`, edit those evidence lines in place (replacing the `missed` line or the `none (...)` line, appending new ones), recompute `level` from all `solid` rungs, and update the `(ladder says ...)` part of the self-rating line. A complete ladder has nothing to resume: keep the level and say so. A claim never sets `level` without evidence.
5. Reply with one line listing the fields changed. Do not write `plan.md`.
