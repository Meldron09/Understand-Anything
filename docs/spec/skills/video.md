# `video`

**Runs** in a unit subagent; spawns none (scenes are bounded Bash jobs, not subagents). **Tier** 1-3 (narration `uv`; Manim 2; HyperFrames 3). Hidden. Decision record: [ADR 0005](../../adr/0005-two-video-renderers-with-shared-narration-and-assembly.md).

**Description:** `Internal learn-anything step, not for direct use: produce a narrated video lesson unit from scene scripts. Runs in a unit subagent; spawns none.`

**Files:** `SKILL.md` (at most 120 lines: the flow, a shared style block, degradation), `narrate.md`, `assemble.md`, `refs/manim.md`, `refs/hyperframes.md`, and `scripts/` (`plan`, `narrate`, `render`, `assemble`: tier-2 POSIX `sh`; `kokoro.py`: PEP 723 Python, pinned `kokoro-onnx`), each run by its full `${CLAUDE_PLUGIN_ROOT}/skills/video/scripts/<name>` path. `plan gate <renderer> <lesson>` re-runs `scripts/preflight` on the lesson folder before each render. `timing.json` records the `voice` (`kokoro | say | none`) and its `speaker`. The renderer table is [`shared/renderers.md`](../shared.md).

## Concepts

A **scene** is one idea, about 20 seconds, with its own narration and its own silent clip. A **storyboard** is the unit's scene list (idea, narration, a one-line visual intent): the one place the narration lives, so a different renderer can redraw a scene without re-authoring it.

## Subagent flow (all under `work/<unit>/`)

1. Read the brief, the unit and its slice chunks as in [text.md](text.md).
2. Write `storyboard.md`. Scene count is `round(size_seconds / 20)`, minimum 2, maximum 15 under the 5-minute cap; about 45 words of narration per scene; one fixed voice for the lesson.
3. Narrate every scene in **one** `uv` process (kokoro-onnx; fallback `say`), producing `timing.json` of measured wav durations. Real length is the summed durations and must be within ±25% of `size`, else re-synthesize once before rendering.
4. Write scene scripts `scenes/sNN.<ext>` from the renderer's skeleton (under 30 lines), with `DURATION = <s>` baked in from `timing.json`.
5. Re-run `scripts/preflight`. Smoke-render `s01`, then render the rest `min(2, cores/4)` at a time, one silent 1280x720 at 30 fps `clips/sNN.mp4` each.
6. Contact-sheet frame check with one cosmetic repair pass (not a render retry).
7. Assemble (`assemble.md`): trim or hold each clip to its D, concatenate, write sentence-level SRT from the measured durations; sidecar `.srt` plus a soft `mov_text` track when the preflight probe allows; no burn-in in v1.
8. Return the footer (`scenes=`, `seconds=`, `captions=`, `narration=`).

Renderers emit **silent clips only**; narration, captions and assembly are shared. `SKILL.md` carries one style block (background, three colors, one font, margin) so both renderers look coherent, and the rule that the assembler normalizes every clip to D.

## Reference file template (`refs/<renderer>.md`, about 120 lines, loaded only when picked)

Fit; install and probes (printed commands, pinned version); headless flag (yes / no / unknown, a flag not a gate); scene script format and skeleton; render command (one scene to one clip); pitfalls; unknowns pending a Mac spike. Manim CE: Python via `uv` plus cairo, pkg-config and ffmpeg (Typst replaces LaTeX). HyperFrames: Node 22+ and Chromium, **exact version pinned**, telemetry off, frame streaming on (otherwise macOS multi-worker rendering can spill about 25 GB per minute of raw frames; name this at consent).

## Degradation (per scene, then per unit)

- A scene that fails on the picked renderer is rewritten once with the row's fallback, then becomes a **blank scene** (flat clip; audio and caption intact), recorded `degraded: sNN blank`.
- More than half the scenes blank, or `s01` failing on both renderers: return `failed`; the conductor re-dispatches once to text.
- TTS: kokoro, then `say` (all scenes re-synthesized so the voice is one), then silent video with estimated durations (2.5 words per second) plus a narration script file.
- Missing ffmpeg: `failed` at once, to text.
- The unit is `done` with no blank scenes, `degraded` otherwise.

## Untested defaults (retune after a Mac spike)

20 s scenes, the blank-scene threshold, render times, scene parallelism: still untested (ticket 49 could not measure them here; the runbook is [mac-spike.md](../mac-spike.md)).
