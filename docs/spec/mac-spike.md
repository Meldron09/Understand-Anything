# Mac spike runbook (pending a human run)

Status: **not run.** Ticket 49 was built on a machine with no ffmpeg, Manim or kokoro, and no number below was estimated. Until a run records data, every default stays as in [SPEC.md](SPEC.md) section 4. Do the run on a Mac with all three tiers installed (`brew install ffmpeg cairo pkg-config node uv` and Chrome), a plain terminal, from the repository root. Record results in the tables at the bottom and update the files each section names.

## Harness

```
R=$PWD/learn-anything; S=$R/skills/video/scripts
DATA=$(mktemp -d)                       # stands in for ${CLAUDE_PLUGIN_DATA}
sh $R/scripts/preflight | tee $DATA/preflight.json    # expect tiers 1, 2, 3 true; note ffmpeg_subtitles
sysctl -n hw.ncpu hw.memsize; ffmpeg -version | head -1

# the render commands exactly as the refs print them, with <data> filled in
MANIM_CMD=$(sed -n '/^UV_CACHE_DIR/p' $R/skills/video/refs/manim.md | sed "s|<data>|$DATA|")
HF_CMD=$(sed -n '/^HYPERFRAMES_NO_TELEMETRY/p' $R/skills/video/refs/hyperframes.md | sed "s|<data>|$DATA|")

# mk <manim|hyperframes> <scenes> <seconds each> <workdir>: N copies of the ref's skeleton, DURATION baked
mk() {
  ext=py; fence=python; [ "$1" = hyperframes ] && ext=html && fence=html
  mkdir -p "$4/scenes"; : > "$4/t"
  awk -v f="\`\`\`$fence" '$0==f{on=1;next} /^```/{if(on)exit} on' $R/skills/video/refs/$1.md > "$4/skel.$ext"
  i=1; while [ $i -le $2 ]; do id=$(printf s%02d $i); cp "$4/skel.$ext" "$4/scenes/$id.$ext"; echo "$id $3" >> "$4/t"; i=$((i+1)); done
  sh $S/plan timing kokoro af_bella < "$4/t" > "$4/timing.json"; sh $S/plan bake "$4/timing.json" "$4/scenes"
}
```

Output minutes of a run are `scenes x seconds each / 60`. The skeletons are the only content, so render time is the renderer's, not the model's.

## 1. Render time per output minute (both renderers)

```
for r in manim hyperframes; do
  W=$(mktemp -d)/$r; mk $r 6 20 $W; ext=py; [ $r = hyperframes ] && ext=html
  C=$MANIM_CMD; [ $r = hyperframes ] && C=$HF_CMD
  df -k / > $W/df.before
  /usr/bin/time -l sh $S/render one $W $ext "$C" s01 2> $W/cold.txt    # cold: first run builds the environment / fetches the browser
  rm -rf $W/clips; ( time sh $S/render clips $W $ext "$C" ) 2> $W/warm.txt   # warm: 6 x 20 s = 2 output minutes
  df -k / > $W/df.after; du -sk $W; echo $W
done
```

Record per renderer: cold seconds for `s01`, warm wall seconds for 6 scenes, seconds per output minute (`warm / 2`), peak resident memory (`cold.txt`, `maximum resident set size`), disk used (`df` before/after, `du`), and for HyperFrames whether disk grows by gigabytes during the render (the frame-spill risk; the commands already carry `HF_CAPTURE_PARALLEL_STREAM=true --workers 1`). Repeat HyperFrames once with `HF_CAPTURE_PARALLEL_STREAM` unset only if you want to measure the spill that the consent text claims (about 25 GB per output minute); stop it if free disk drops below 30 GB.

Updates: the router's video sizing is by output minutes, not render time, so nothing in `plan` changes; the results go to the plan-gate consent text (`scripts/plan-gate`: add an expected render time per minute if the numbers justify it), `refs/manim.md` and `refs/hyperframes.md` (replace "Unknowns pending a Mac spike" with the measured numbers), and SPEC.md section 4 (a sentence with the measured times).

## 2. Scene parallelism (`plan jobs` = `min(2, cores/4)`, workers 1)

Using the warm Manim and HyperFrames work dirs from section 1:

```
for J in 1 2 3 4; do rm -rf $W/clips
  echo "jobs=$J"; ( time ls $W/scenes | sed 's/\..*//' | xargs -P $J -I{} sh $S/render one $W $ext "$C" {} ) 2>&1
done
```

Record wall time per `J` and whether any scene failed or the machine swapped (`memory_pressure | tail -3` during a run). Pick the `J` after which wall time stops falling by a clear margin, per renderer, and per core count if you have two Macs. Updates: the formula in `skills/video/scripts/plan` (`jobs`), the `plan jobs` cases in `tests/video/run.sh`, SPEC.md section 4 (`video scene jobs min(2, cores/4); renderer workers 1`), ADR 0003, `refs/hyperframes.md` pitfalls (`--workers 1` and Chrome per worker).

## 3. Scene length (default 20 s, about 45 words, `round(seconds / 20)` scenes)

```
for D in 10 20 30 40; do W=$(mktemp -d)/len$D; mk manim 3 $D $W; ( time sh $S/render clips $W py "$MANIM_CMD" ) 2>&1; done   # repeat with hyperframes / $HF_CMD / html
```

Fit seconds against `D`: the intercept is fixed cost per scene, the slope the cost per output second. Also record what one idea needs (`D` x 2.5 words per second of narration) by narrating a real storyboard at each length. Choose the length where fixed cost is a small share and one idea still fits; the 20 s default stays unless the fit says otherwise. Updates: the `20` in `plan scenes` and `plan check`, "about 45 words" in `skills/video/SKILL.md` and `narrate.md`, `docs/spec/skills/video.md`, ADR 0005, SPEC.md sections 4 and 9, and the `plan scenes` cases in `tests/video/run.sh`.

## 4. Blank-scene threshold (more than half blank, or `s01` failing, makes the unit `failed`)

Run the full conductor on at least 10 video units across both renderer rows and a few topics (`/learn-anything:learn`, video only, 2 minutes, one unit each). For each, keep `work/<unit>/blank.txt`, `clips/*.log` for failures, the footer and whether the finished video was acceptable. Record the per-scene failure rate by renderer, how often the fallback rewrite rescued a scene, and the largest blank share you still judged acceptable (the work dir is deleted on `done`, so copy it before the unit finishes or read `degraded:` lines from `plan.md`). Updates: the condition `k * 2 -gt n` in `skills/video/scripts/render` (`verdict`), the "exactly half" and "more than half" cases in `tests/video/run.sh`, `skills/video/SKILL.md` step 6, `docs/spec/skills/video.md`, ADR 0005.

## 5. Other unverified items

Each is a pass/fail check; on failure fix the named file and record what changed.

| Item | How to check | If it fails, fix |
|---|---|---|
| kokoro API call shape (`Kokoro(model, voices).create(text, voice=, speed=, lang=)`) and real-time factor | `sh $S/narrate $W/storyboard.md $W --data-dir $DATA` on a 6-scene storyboard; expect `engine=kokoro`, no `degraded:`, playable wavs; time it for the real-time factor | `skills/video/scripts/kokoro.py` (release URLs and `kokoro-onnx==0.6.1` already verified) |
| `manim[typst]==0.22.0` installs and `MathTypst` exists | `UV_CACHE_DIR=$DATA/uv uv run --python 3.12 --with "manim[typst]==0.22.0" python -c "from manim import MathTypst"` (PyPI shows the pin and the `typst` extra; imports are untested) | `refs/manim.md` pin and the "use `MathTypst`" advice |
| Manim output layout under `--media_dir` | after section 1, `find $W/media -name '*.mp4'`; the render command's `find ... ! -path '*partial_movie_files*' \| head -n 1` must pick the final 1280x720 30 fps clip | the render command in `refs/manim.md` |
| Contact-sheet frame time `-ss 0.5` | `sh $S/render sheet $W`, open `$W/contact.png`; if the 0.5 s frames look empty (fade-in) every scene would trigger the repair pass | `render sheet` (`-ss`), `video/SKILL.md` step 7 |
| `mov_text` needs the `subtitles` filter? | on an ffmpeg without libass (`ffmpeg -filters \| grep subtitles` empty) run `sh $S/assemble $W out.mp4 --preflight <file containing "subtitles filter: true">` and play captions in QuickTime/VLC | if it muxes fine, soft captions need no probe: drop the gate in `scripts/assemble`, `preflight`, `assemble.md`, README, SPEC.md |
| `libx264`, loudness across scenes | `ffmpeg -encoders \| grep libx264`; listen to a 6-scene assembly | `assemble.md` (loudness is unhandled today) |
| `say` voice `Samantha` | `say -v '?' \| grep Samantha` | `scripts/narrate` |
| HyperFrames skeleton: root attributes (`data-composition-id`, `data-start`, `data-duration`, `data-width`, `data-height`) and `render --composition scenes/s01.html` run from `work/` with no `[DIR]` | section 1 smoke render; also `npx hyperframes@0.8.193 check --json scenes/s01.html`. Flag names are confirmed against `render --help`, the attributes are only present in the package source | `refs/hyperframes.md` skeleton and render command |
| Headless/sandbox behaviour of both renderers, offline after first cache | run the smoke render inside a Claude Code session with Bash sandboxing on, then with the network off | the `Headless` sections of both refs |
| `${CLAUDE_PLUGIN_ROOT}` / `${CLAUDE_PLUGIN_DATA}` substitution reaching a subagent after a marketplace install (ticket 33 tested `--plugin-dir` only) | `/plugin install learn-anything --marketplace Meldron09/Understand-Anything`, then run a two-unit lesson and look for literal `${CLAUDE_` in a subagent's commands | SPEC.md section 2 scripts paragraph; ADR 0006 |
| Plan-gate treats kokoro as missing when `--data-dir` is omitted | by design, not a bug: the conductor always passes `--data-dir ${CLAUDE_PLUGIN_DATA}` (`learn/gate.md`), and the variable is not in the Bash environment, so a script cannot find the data folder on its own. A manual run without the flag overstates the download by about 350 MB | none; pass `--data-dir` when running it by hand |

## Results (fill in)

| Measure | Manim | HyperFrames | Machine |
|---|---|---|---|
| cold `s01` seconds | | | |
| warm seconds per output minute | | | |
| peak memory | | | |
| disk spill (GB) | | | |
| best parallel jobs | | | |
| fixed cost per scene / best scene length | | | |
| scenes failed / blank (of N) | | | |

Once filled, tick the spike criteria on issue 49, update SPEC.md section 4 and the files named above, and replace the `Status` line at the top.
