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

Not built yet: source questions (URL, PDF, file), the diagnostic ladder, and self-rating. Until they land, every lesson is a bare topic at `novice` level.

1. **Goal and why.** Take the argument as the topic if given, else ask what the learner wants to understand. Ask once why they want it. Narrow a too-broad goal once.
2. **Slug.** 2-4 kebab-case words from the topic. If `./learn-anything/<slug>/` exists, use `<slug>-2`, then `-3`. Create the folder now.
3. **Core concepts.** Propose 3-5 noun phrases from the goal (general knowledge); the learner confirms or edits.
4. **Depth** `gist | working | mastery`, then **budget** as one integer of minutes including the comprehension check (presets 5 / 15 / 30 / 60).
5. **Preflight, then mode.** Run `sh ${CLAUDE_PLUGIN_ROOT}/scripts/preflight ./learn-anything/<slug>` (writes `preflight.md`; JSON on stdout; never installs). Then ask the mode. Only `text` exists so far, so annotate by this rule, which later modes reuse: a mode whose tier or tool is missing in the JSON stays selectable, with its need appended (`video` needs `uv`, `ffmpeg`, cairo and `pkg-config`; `slides` render needs `marp` or `npx`). If the script is missing, errors or prints nothing, say "preflight unavailable" once and skip annotations; never block on it.
6. **Write `brief.md`** once, then read the key fields back in two lines (not a gate).

If the argument looks like a URL or a file path, say that sources arrive in a later version and take its words as the topic.

## `brief.md`

```markdown
---
lesson: <slug>
goal: <one line>
sources: [topic]
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
