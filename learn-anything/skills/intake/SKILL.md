---
name: intake
description: "Internal learn-anything step, not for direct use: interview the learner and write brief.md. Runs inline."
user-invocable: false
compatibility: No binaries needed.
---

# intake

Runs inline in the main thread (subagents lose `AskUserQuestion`). Interview rules: ${CLAUDE_PLUGIN_ROOT}/skills/intake/protocol.md. Never read a source.

Input: the conductor's first input (a topic, or nothing). Output: `./learn-anything/<slug>/brief.md`, written once, and the slug.

## Flow (tracer scope)

Not built yet: the diagnostic ladder, self-rating and preflight. Until they land, every lesson is at `novice` level.

1. **Classify the argument.** A URL (`http://` or `https://`) or an existing file path is a source: record it for step 3 and ask for the topic in plain words. Anything else is the topic. Then **goal and why.** Take the topic if given, else ask what the learner wants to understand. Ask once why they want it. Narrow a too-broad goal once.
2. **Slug.** 2-4 kebab-case words from the topic. If `./learn-anything/<slug>/` exists, use `<slug>-2`, then `-3`. Create the folder now.
3. **Sources**, asked once ("Any sources: URLs, files? None means I teach from general knowledge"), several allowed, kept in the order given. Cheap checks only, never open a file: a path must exist (`test -f`), a URL must start with `http://` or `https://`. Accepted: `.md`, `.txt`, `.html`, code, `.pdf`. Refuse `.docx`, `.epub` and images, naming the export hint: Word, save as PDF or paste into a `.md`; EPUB, convert to PDF or text; image, give the text or a PDF. A missing path: say so and ask once more. For OneNote, say: export one page at a time to PDF and give me the file (Windows desktop: File > Export > PDF; Mac: File > Save as PDF; web: Export as PDF on Mac, Print to PDF on Windows; the web app cannot export a whole notebook or section). No sources: `sources: [topic]`.
4. **Core concepts.** Propose 3-5 noun phrases from the goal (general knowledge, never the sources); the learner confirms or edits.
5. **Depth** `gist | working | mastery`, then **budget** as one integer of minutes including the comprehension check (presets 5 / 15 / 30 / 60).
6. **Mode.** Only `text` exists so far; offer it as the one option.
7. **Write `brief.md`** once, then read the key fields back in two lines (not a gate).

## `brief.md`

```markdown
---
lesson: <slug>
goal: <one line>
sources: [topic]        # paths, URLs, or the literal topic, in the order given
level: novice            # novice | intermediate | advanced
depth: working           # gist | working | mastery
budget: 30               # minutes, including the comprehension check
modes: [text]
core: [concept one, concept two, concept three]
assumed: [level]         # fields set by default rather than by the learner
---
## Why
<the learner's reason, a few lines>

## Level evidence
none (no ladder yet; level assumed)
```

`core` entries are the exact names every later skill matches on. `sources` entries are paths, URLs, or the literal `topic`.
