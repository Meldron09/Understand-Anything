# Narration (shared by every renderer)

Narration is audio-first: synthesise, measure, and only then draw. The storyboard is the one place the narration lives; renderers never see it.

## Storyboard format

```
## s01
idea: what a TCP handshake is for
visual: two boxes, three arrows labelled SYN, SYN-ACK, ACK
narration: Before two computers talk, they agree on a starting point. ...
```

Ids are `s01`, `s02`, ... in order. `narration:` may run over several lines until the next `idea:`, `visual:` or `##`. About 45 words per scene (about 20 seconds of speech); write for the ear: short sentences, spell out symbols and numbers as spoken, no markdown, no parentheses. The scene count is fixed by the unit's `size` (`round(seconds / 20)`, min 2, max 15), never by how much there is to say.

## Engines (`scripts/narrate`)

One voice for the whole lesson, whatever the engine.

| Engine | When | How |
|---|---|---|
| `kokoro` | `uv` found and the run succeeds | `kokoro.py`, one `uv` process for every scene (the model loads once), voice `af_bella`, weights fetched once into `<data>/kokoro/` (about 300 MB; the plan gate's consent covers it) |
| `say` | kokoro absent or failed, and `say`, `ffmpeg` and `ffprobe` found | every scene re-synthesised (never a mix), voice `Samantha`, converted to wav, measured with `ffprobe` |
| `none` | no voice at all | no audio; durations estimated at 2.5 words per second; assembly writes a narration script beside the mp4 |

The script prints `engine=<name>` and, for anything but kokoro, a `degraded: <reason>` line. Keep that line for the footer `reason:` and tell nobody to install anything beyond printing the command.

## Outputs (under `work/`)

`narration/sNN.txt` (one scene each), `audio/sNN.wav`, and `timing.json`:

```
{"engine":"kokoro","voice":"af_bella","scenes":[
{"id":"s01","seconds":18.42},
{"id":"s02","seconds":21.07}
]}
```

`seconds` is the measured wav duration D. It is the scene's length everywhere after this: baked into the scene script, the clip's trim or hold length, and the caption clock.

## Length check

The sum of D must be within 25% of the unit's `size` in seconds: `sh $S/plan check "<size>" work/timing.json`. Outside it, rewrite the narration of every scene toward the target (about 2.5 words per second) and narrate once more. A second miss is accepted as is; never loop. Unknowns pending a Mac spike: the kokoro release URLs, real-time factor and download size.
