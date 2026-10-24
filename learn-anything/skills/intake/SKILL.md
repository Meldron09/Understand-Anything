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

Not built yet: source questions (URL, PDF, file) and preflight. Until they land, every lesson is a bare topic.

1. **Goal and why.** Take the argument as the topic if given, else ask what the learner wants to understand. Ask once why they want it. Narrow a too-broad goal once.
2. **Slug.** 2-4 kebab-case words from the topic. If `./learn-anything/<slug>/` exists, use `<slug>-2`, then `-3`. Create the folder now.
3. **Ladder, then self-rating.** Rungs, grading, level mapping, skip and evidence format: ${CLAUDE_PLUGIN_ROOT}/skills/intake/ladder.md. Keep the graded rungs for the brief.
4. **Core concepts.** Propose 3-5 noun phrases from the goal and the ladder's gaps (general knowledge); the learner confirms or edits.
5. **Depth** `gist | working | mastery`, then **budget** as one integer of minutes including the comprehension check (presets 5 / 15 / 30 / 60).
6. **Mode.** Only `text` exists so far; offer it as the one option.
7. **Write `brief.md`** once, then read the key fields back in two lines (not a gate).

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
