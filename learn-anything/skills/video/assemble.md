# Assembly and captions (shared by every renderer)

`scripts/assemble <work> <out.mp4> [--preflight preflight.md] [--script <narration-script.md>]` does all of it; this file says what it guarantees and what to check.

## What it does

1. For each scene in `timing.json`, one ffmpeg call: scale the silent clip to 1280x720 at 30 fps, hold its last frame if it is shorter than D (`tpad`), cut it at D (`-t`), pad or cut the narration to exactly D (`apad`), encode H.264 plus AAC. A renderer that ran long or short therefore never moves the audio.
2. Concatenate the parts with the concat demuxer (identical codecs by construction).
3. Write `<out>.srt`, the sidecar: sentence-level captions, each scene's D shared among its sentences in proportion to words, scene offsets the running sum of D. No aligner, no burn-in.
4. Soft captions: when `preflight.md` says `subtitles filter: true`, the SRT is also muxed as a `mov_text` track (`captions=soft`); otherwise the sidecar alone ships (`captions=sidecar`). The probe is the spec's gate for soft captions; whether `mov_text` also needs it is unknown pending a Mac spike.
5. With engine `none` there is no audio track; `--script` writes the narration text per scene as `<out minus .mp4>.narration.md`, which is the learner's way to read what would have been said.

## Output line

`scenes=<n> seconds=<n> captions=soft|sidecar narration=<engine>`: copy it into the footer notes. Exit 1 names a missing clip; exit 4 means ffmpeg vanished since the gate (return `failed`).

## Checks

- `seconds` is within 25% of the unit's `size` in seconds, or the narration check already accepted a second miss.
- `<out>.srt` exists and has one numbered cue per sentence; cue times end at the last scene's end.
- Both the mp4 and its `.srt` sit in `lesson/`, named `uN-video.mp4` and `uN-video.srt`. `artifact:` is the mp4.

Unknowns pending a Mac spike: loudness matching across scenes (not done), `libx264` availability in the learner's build (a build without it fails the unit to text).
