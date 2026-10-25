---
name: video
description: "Internal learn-anything step, not for direct use: produce a narrated video lesson unit from scene scripts. Runs in a unit subagent; spawns none."
user-invocable: false
compatibility: uv and ffmpeg (narration, assembly); Manim also needs cairo and pkg-config. say is the fallback voice.
---

# video

Produce one narrated video lesson unit: a storyboard of about 20-second scenes, shared narration, silent Manim clips, shared assembly. Spawn nothing (scenes are bounded Bash jobs, not subagents). Write only the artifact, its `.srt` and `work/<unit-id>/`.

Your brief gives paths: `brief`, `plan`, `unit`, `slices`, `work`, `artifact`. Use them exactly as given and never `cd`. Never ask the learner anything. Never install anything: a missing tool is printed as its command in your `reason:`.

Scripts: `S=${CLAUDE_PLUGIN_ROOT}/skills/video/scripts` (`plan`, `narrate`, `render`, `assemble`; run each as `sh $S/<name>`). `<data>` is `${CLAUDE_PLUGIN_DATA}`. Shaping: ${CLAUDE_PLUGIN_ROOT}/shared/shaping.md. Footer: ${CLAUDE_PLUGIN_ROOT}/shared/footer.md. Narration: ${CLAUDE_PLUGIN_ROOT}/skills/video/narrate.md. Assembly: ${CLAUDE_PLUGIN_ROOT}/skills/video/assemble.md. Renderer: ${CLAUDE_PLUGIN_ROOT}/skills/video/refs/manim.md (read it now; Manim is the only renderer so far).

## Procedure (all under `work/`)

1. **Gate.** `sh $S/plan gate`. `failed: <why>` (ffmpeg missing, or Manim needs uv, cairo, pkg-config): stop with `status: failed`, `reason:` the line plus the install command from `preflight.md`; the conductor re-dispatches the unit to text. Keep its `captions=` line for step 7.
2. **Read** `brief.md` (depth, level, core, goal, `## Level evidence`) and your `## <unit>` block in `plan.md` (`focus`, `slices`, `size` such as `2 min`), then each slice's chunk text one chunk at a time as `text` does (cap 3 chunks, no whole source; an ungrounded topic is taught from general knowledge).
3. **Storyboard.** Write `work/storyboard.md`, one block per scene: `## s01`, `idea:` one idea, `visual:` one line, `narration:` about 45 words in plain spoken sentences (no markup, digits spelled when read aloud). The count is `sh $S/plan scenes "<size>"`, i.e. `round(seconds / 20)`, min 2, max 15. Shape by depth x level via shaping.md; scene 1 states the goal, the last recaps. Validate: `sh $S/plan storyboard work/storyboard.md "<size>"`; fix until it prints `scenes=<n>`.
4. **Narrate** per narrate.md: `sh $S/narrate work/storyboard.md work --data-dir <data>` (all scenes in one process, one voice, writes `timing.json`). Then `sh $S/plan check "<size>" work/timing.json`; on `resync`, rewrite the narration of every scene longer or shorter (not just some) toward the target and run narrate once more; never a third time. Keep each `degraded:` line it printed.
5. **Scene scripts.** Write `work/scenes/sNN.py` from the skeleton in refs/manim.md (under 30 lines, `DURATION = 0` placeholder, the style block below), one per storyboard scene, drawn from its `visual:` line only. Bake the measured times: `sh $S/plan bake work/timing.json work/scenes`.
6. **Render.** Re-run `sh $S/plan gate` (preflight again). Then `sh $S/render clips work py '<render command from refs/manim.md>'`: it renders `s01` alone first (`smoke-failed=s01`, exit 3: return `failed`, reason `smoke render failed`), then the rest `min(2, cores/4)` at a time. Any other `failed=sNN`: fix that script once from `clips/sNN.log` and re-render only it with `sh $S/render one work py '<cmd>' sNN`; still failing: return `failed`, reason `scene sNN failed to render` (blank scenes are not built yet).
7. **Check.** `sh $S/render sheet work` prints `work/contact.png`; `Read` it. If a scene shows clipped text, overlap, or an empty frame, make one repair pass: edit just those scripts, re-render just those, no second pass.
8. **Assemble** per assemble.md into `artifact` (`lesson/uN-video.mp4`; create `lesson/`): `sh $S/assemble work <artifact> --preflight preflight.md --script <artifact minus .mp4>.narration.md`. It trims or holds every clip to its D, concatenates and writes `<artifact minus .mp4>.srt`.
9. **Footer.** `notes: scenes=<n>, seconds=<n>, captions=sidecar|soft, narration=kokoro|say|none` copied from assemble's last line. `status: done` when narration is kokoro; `status: degraded` with `reason:` the narrate `degraded:` line otherwise (say, or silent video plus the narration script, which is then also a lesson artifact beside the mp4). (Run inline, the conductor continues after it.)

## Style block (every scene script, one look)

Background `#111827`, text `#F9FAFB`, accents `#60A5FA` and `#FBBF24` (nothing else), font `Helvetica Neue`, 0.6 unit margin from the frame edge, at most 3 lines of on-screen text, 1280x720 at 30 fps. The clip is silent and its length is a hint: the assembler normalizes every clip to its D.

## Degradation

- No kokoro (no `uv`, or it fails): `say` for all scenes (one voice), `degraded: ... narrated with say`.
- No TTS at all: silent video with durations estimated at 2.5 words per second and a narration script file.
- No ffmpeg, no Manim prerequisites, a failed smoke render or an unrenderable scene: `failed` at once; the conductor re-dispatches to text, never retried here.
- All of it is in `reason:` and the notes; nothing is silent.
