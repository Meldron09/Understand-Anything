# Research: narration, captions and assembly (issue #10)

Date of research: 2026-10-24. Constraints: free/OSS and local only; primary target is local macOS Claude Code. Nothing was installed or run; sample-quality statements come from each project's own claims and are marked "not verified locally". "Unknown" means it could not be established from a primary source.

Maintenance dates are from the GitHub API (`pushed_at`, latest release) and PyPI JSON, fetched 2026-10-24.

## Key design insight (read this first)

The audio is generated from text we already hold, so we do not need to transcribe it. Synthesise each scene's narration separately, measure the resulting WAV duration, and use that duration to (a) set the scene's video length, and (b) emit sentence-level captions directly. Alignment tools are only needed if we want word-level highlighting. This makes scenes independent and parallelisable after the TTS step, which is a cheap serial step.

## 1. TTS candidates

| Item | Kokoro via kokoro-onnx | Kokoro via `kokoro` (hexgrad, PyTorch) | Piper (piper-tts) | macOS `say` | mlx-audio (runner for Kokoro, others) |
|---|---|---|---|---|---|
| Maintenance | push 2026-09-01; PyPI 0.6.1 2026-08-19 | push 2025-08-06; PyPI 0.9.4 2025-04-05 (stale, ~14 months) | push 2026-10-23; PyPI 1.8.0 2026-09-04; README says it "needs maintainers" | OS component | push 2026-10-24; v0.6.1 2026-10-20 |
| Code license | MIT | Apache-2.0 | GPL-3.0 (repo is `OHF-Voice/piper1-gpl`; `rhasspy/piper` MIT repo is archived) | Apple proprietary, ships with macOS | MIT |
| Model/voice license | Kokoro weights Apache-2.0; CC-BY components (Koniwa, SIWIS) in training data have their own terms | same | Per-voice. Piper docs: "intended for personal use and text to speech research only"; `en_US-lessac-medium` is trained on the Lessac/Blizzard 2013 dataset, whose license bars commercial use and redistribution | Apple voices, system license; no redistribution terms stated in the man page | Per model; page states none. Unknown per model |
| Install friction (macOS) | `pip install kokoro-onnx` + download `kokoro-v1.0.onnx` and `voices-v1.0.bin` (about 300 MB, about 80 MB quantized); Python 3.10-3.13; deps onnxruntime, espeakng-loader (no torch) | `pip install kokoro`; pulls torch + transformers; needs espeak-ng for OOV; PyPI Python <3.13 | `pip install piper-tts` (prebuilt macOS arm64 and x86_64 wheels), then `python3 -m piper.download_voices <voice>` | None; preinstalled | `pip install mlx-audio` or `uv tool install`; Apple Silicon only; Python 3.10+ |
| Headless CLI / sandbox | Yes, pure Python, CPU. First-run model download needs network. | Same, heavier | Yes, CLI `python3 -m piper -m <voice> -f out.wav -- 'text'`. Voice download needs network | `say -o out.aiff`; macOS only, absent in Linux sandbox | Yes on Apple Silicon only; needs HF model download |
| Sample quality | Own claim: "comparable quality to larger models", 82M params; 54 voices, 8 languages. Voice grades A-D in VOICES.md (af_bella A, am_michael B). Not verified locally | same | Own samples at rhasspy.github.io/piper-samples. Not verified locally | Not documented; voice quality depends on installed voice. Not verified locally | Model-dependent. Not verified locally |
| Word timing | None | English only (`a`, `b`): tokens get `start_ts`/`end_ts` from `pred_dur` (source `pipeline.py`) | None documented | None (man page lists only `-i` word highlighting on a TTY, no timing output) | Only via separate aligner models (Qwen3-ForcedAligner) |
| Render time / cost per min | "Near real-time on macOS M1" (README); no numbers. $0 | No numbers | No numbers | Unknown; no numbers | No numbers |
| Best-fit concepts | Narrated explainers, slide and animation scenes (neutral English narrator) | same | Offline narration where license is acceptable | Draft previews, last-resort fallback | Apple-Silicon users who want bigger models (Qwen3-TTS, Chatterbox, etc.) |
| Parallel across scenes | Yes (one process per scene; model load cost per process) | Yes | Yes | Yes | Yes (memory-bound on unified RAM; unknown) |

### Notes per candidate

- **kokoro-onnx** is the best balance: permissive code and weights, no torch, one pip package plus two model files, and a maintained repo. Weakness: no word timestamps, and the `kokoro-v1.0.onnx` release asset is dated 2025-03-01 (the model files release, not the code). Sources: https://github.com/thewh1teagle/kokoro-onnx, https://raw.githubusercontent.com/thewh1teagle/kokoro-onnx/main/README.md, https://pypi.org/pypi/kokoro-onnx/json, https://huggingface.co/hexgrad/Kokoro-82M.
- **hexgrad/kokoro** is the reference implementation. Only route in this set with built-in English word timestamps, but it needs torch and its last push was 2025-08. Sources: https://github.com/hexgrad/kokoro, https://raw.githubusercontent.com/hexgrad/kokoro/main/kokoro/pipeline.py, https://pypi.org/pypi/kokoro/json.
- **Piper** is active again under the Open Home Foundation but is the weakest on licensing for a marketplace plugin: GPL-3.0 engine (fine to run as a separate pip-installed tool, copyleft applies if we bundle it) and voices whose terms vary and are sometimes non-commercial. Its own voices doc limits it to "personal use and text to speech research only". Sources: https://github.com/OHF-Voice/piper1-gpl, https://raw.githubusercontent.com/OHF-Voice/piper1-gpl/main/docs/VOICES.md, https://huggingface.co/rhasspy/piper-voices/raw/main/en/en_US/lessac/medium/MODEL_CARD, https://www.cstr.ed.ac.uk/projects/blizzard/2013/lessac_blizzard2013/license.html, https://pypi.org/pypi/piper-tts/json.
- **macOS `say`** needs zero install and writes AIFF (`-o`), and further formats are possible via audio-format options. Better voices are a download in System Settings > Accessibility > Read & Speak, which needs internet. No timing output. Sources: `man say` (local macOS 26 man page), https://support.apple.com/guide/mac-help/change-the-voice-your-mac-uses-to-speak-text-mchlp2290/mac.
- **mlx-audio** is a model runner, not a voice. Useful as an Apple-Silicon upgrade path, not a baseline: Apple Silicon only, per-model licenses unstated on its page. Source: https://raw.githubusercontent.com/Blaizzy/mlx-audio/main/README.md.
- **Considered and rejected on license or fit** (all free to run but not safe defaults):
  - F5-TTS weights are CC BY-NC 4.0 (https://huggingface.co/SWivid/F5-TTS), code MIT.
  - Chatterbox is MIT with 500M params but its README examples assume CUDA and every output carries a Resemble "Perth" watermark (https://huggingface.co/ResembleAI/chatterbox).
  - KittenTTS code is Apache-2.0, but the flagship 2 weights are under the "Stellon Labs Community License", terms unread, so unknown (https://raw.githubusercontent.com/KittenML/KittenTTS/main/README.md).

## 2. Caption and alignment candidates

| Item | TTS-measured sentence timing (no aligner) | whisper.cpp | WhisperX | mlx-whisper | ctc-forced-aligner | Montreal Forced Aligner | stable-ts | aeneas |
|---|---|---|---|---|---|---|---|---|
| Maintenance | n/a (our code) | push 2026-10-19; v1.9.5 2026-10-06 | push 2026-10-22; v3.8.6 2026-05-25 | PyPI 0.4.3 2025-08-29 (stale) | push 2026-09-07; no releases noted | push 2026-10-22; v3.4.3 2026-10-08 | "indefinitely paused" (README); pushed 2026-05-30, repo archived | Last version listed 1.7.3 (2017); AGPL; pushed 2026-07-25 |
| License | n/a | MIT; Whisper weights MIT | BSD-2-Clause; wav2vec2 models vary; pyannote diarization model CC-BY-4.0 (diarization not needed) | MIT | Code BSD-2; default MMS aligner model is CC-BY-NC 4.0 | MIT code; acoustic model license not established | MIT | AGPL-3.0 |
| Install friction (macOS) | None | No brew formula found; build from source with CMake (Core ML optional); models via `download-ggml-model.sh`; input must be 16 kHz WAV | `pip install whisperx`; pins torch~=2.8, pyannote, faster-whisper; Python 3.10-3.13; README says CPU supported on macOS (`--device cpu`) | `pip install mlx-whisper`, Apple Silicon (MLX); pulls torch | pip from GitHub; needs ffmpeg | Conda + Kaldi + pynini is the main route; heaviest | pip, needs ffmpeg and torch | pip + numpy, needs eSpeak and ffmpeg; C extensions |
| Headless CLI | n/a | Yes, `whisper-cli` | Yes, CLI | Yes, `mlx_whisper` | Yes | Yes | Yes | Yes |
| Aligns known text (no ASR)? | n/a | No: it transcribes | Yes at API level: `align()` takes segments with `text`, `start`, `end` | No documented | Yes (text file + audio) | Yes (transcript + audio) | Yes (`align()`) | Yes (DTW against its own eSpeak synthesis) |
| Granularity | Sentence (we choose the split) | Word via `-ml 1` (README calls it experimental); `-ojf`, `-dtw` token timestamps | Word (wav2vec2); fails on tokens outside dictionary such as "£13.60" | Word via `word_timestamps=True` | Sentence, word or character | Word and phone | Word | Sentence; "not designed for word-level" |
| Output | We write SRT/WebVTT | `-osrt`, `-ovtt`, `-oj`, `-ojf` | Unknown (formats not read); `align()` returns word dicts | `-f` selects format (list not read); word dicts via Python | JSON with start/end | Unknown (not read) | Unknown (not read) | Unknown (not read) |
| Languages | Any language the TTS supports | Whisper languages | en, fr, de, es, it by default; others from HF | Whisper languages | 1100+ via MMS | Per acoustic model | Whisper | eSpeak languages |
| Time/cost per min | Zero | Unknown (no numbers on README); Core ML encoder >3x faster than CPU per README | Unknown | Unknown | Unknown | Unknown | Unknown | Unknown |

### Notes per candidate

- **TTS-measured timing**: each scene's sentences are synthesised separately, so sentence start/end are known to the sample. Exact by construction, no dependency. Gives sentence-level captions only. English word timing is also available as a by-product if we choose hexgrad `kokoro` (see TTS table).
- **whisper.cpp**: best maintained and lightest ASR route (MIT, Metal/Core ML on Apple Silicon; "Apple Silicon is a first-class citizen"). Run on the finished narration to get word timestamps. Friction is the source build. Sources: https://github.com/ggml-org/whisper.cpp, https://raw.githubusercontent.com/ggml-org/whisper.cpp/master/README.md, https://raw.githubusercontent.com/ggml-org/whisper.cpp/master/examples/cli/README.md, https://raw.githubusercontent.com/openai/whisper/main/README.md (weights MIT). FFmpeg also documents a `whisper` filter, but only when FFmpeg is configured with `--enable-whisper`; whether Homebrew builds it is unknown (https://ffmpeg.org/ffmpeg-filters.html).
- **WhisperX**: most accurate documented word alignment and can align supplied text, but the dependency stack (torch 2.8, pyannote, faster-whisper) is large for a plugin. Sources: https://github.com/m-bain/whisperX, https://raw.githubusercontent.com/m-bain/whisperX/main/whisperx/alignment.py, https://pypi.org/pypi/whisperx/json.
- **ctc-forced-aligner**: right shape (text + audio in, timings out) but its default model is non-commercial; a different wav2vec2 model must be chosen. Source: https://raw.githubusercontent.com/MahmoudAshraf97/ctc-forced-aligner/main/README.md.
- **MFA**: high quality but conda/Kaldi install is too heavy for a marketplace dependency. Source: https://montreal-forced-aligner.readthedocs.io/en/latest/installation.html.
- **stable-ts**: development "indefinitely paused", so not a new dependency. Source: https://raw.githubusercontent.com/jianfch/stable-ts/main/README.md.
- **aeneas**: AGPL-3.0 and stale versioning; not recommended. Source: https://raw.githubusercontent.com/readbeyond/aeneas/master/README.md.
- **mlx-whisper**: simple on Apple Silicon but last release is 14 months old and torch is a dependency; Apple-only. Source: https://raw.githubusercontent.com/ml-explore/mlx-examples/main/whisper/README.md, https://pypi.org/pypi/mlx-whisper/json.

## 3. Assembly candidates

| Item | ffmpeg CLI | MoviePy 2.x |
|---|---|---|
| Maintenance | Push 2026-10-24 (active) | Push 2026-08-26; latest release v2.2.1 2025-05-21 (17 months; unreleased changes pending) |
| License | LGPL-2.1+ by default; GPL if built with GPL parts (https://ffmpeg.org/legal.html). Homebrew formula `ffmpeg` 9.0.2 is GPL-3.0-or-later (https://formulae.brew.sh/formula/ffmpeg) | MIT |
| Install friction (macOS) | `brew install ffmpeg` (Apple Silicon bottles exist); invoked as a subprocess so its license does not bind our plugin | `pip install moviepy`; depends on `imageio_ffmpeg`, pillow, numpy; Python version bound not stated on PyPI |
| Headless | Yes | Yes (shells out to ffmpeg) |
| Sync features | `adelay` (per-channel ms/s delay), `apad` (`pad_dur`, `whole_dur`; "used together with `-shortest`" to match audio to video length), concat demuxer with `duration`/`inpoint`/`outpoint` | `AudioFileClip`, `CompositeVideoClip`, `TextClip` (Pillow-based in v2) as Python objects |
| Per-scene independence | Natural: one ffmpeg process per scene, then concat. Concat demuxer needs identical codecs, time base and streams; otherwise use the concat filter or re-encode | Possible but in-process; memory-heavy for long clips (not stated in docs, unknown) |
| Captions | `subtitles`/`ass` burn-in filters need FFmpeg built with `--enable-libass`; Homebrew's direct dependency list for 9.0.2 (dav1d, lame, libvmaf, libvpx, openssl@4, opus, sdl2-compat, svt-av1, x264, x265, xz) does not show libass or freetype, so burn-in availability is unknown and must be probed at runtime (`ffmpeg -filters`) | `TextClip` renders captions with Pillow, no libass dependency |
| Render time / cost per min | Unknown; encode cost is dominated by the video codec (x264/x265 present in Homebrew build) | Unknown, same encoder underneath |

Sources: https://ffmpeg.org/ffmpeg-filters.html, https://ffmpeg.org/ffmpeg-formats.html, https://ffmpeg.org/legal.html, https://formulae.brew.sh/formula/ffmpeg, https://zulko.github.io/moviepy/index.html, https://raw.githubusercontent.com/Zulko/moviepy/master/CHANGELOG.md, https://pypi.org/pypi/moviepy/json.

### Recommended sync model (audio-first)

1. Per scene, in narration order: synthesise WAV, read its duration D.
2. Pass D to the scene renderer as the target length (the renderer category is another ticket). Scenes now render independently and in parallel.
3. Mux each scene: video + audio, `apad` then `-shortest` if the video is slightly longer than the audio; `adelay` to add lead-in silence; concatenate scene files.
4. Captions: write SRT/WebVTT from known sentence offsets (cumulative sum of D). Offer burn-in only if `ffmpeg -filters` shows `subtitles`; otherwise ship the sidecar file, or draw captions in the renderer. Soft-embedding captions into MP4 was not verified from a primary source.
5. Loudness matching across scenes (`loudnorm`) is available in ffmpeg (listed in the filter index) but its options were not read here; unknown.

## Cross-cutting flags

- **Sandbox**: everything except `say` is cross-platform and CPU-only, but first run needs network for model downloads (HF/GitHub). In a restricted sandbox, models must be pre-fetched. `say` is macOS-only.
- **Graceful degradation**: if no TTS is installed, ship captions-only or text; if ffmpeg is missing, stop at per-scene files.
- **Licence caution**: do not default to anything with CC BY-NC (F5-TTS weights, ctc-forced-aligner default model) or per-voice non-commercial terms (Piper voices such as Lessac).

## Pick and Fallback

### TTS
- **Pick: kokoro-onnx (Kokoro-82M).** MIT code plus Apache-2.0 weights, no torch, about 80-300 MB model, maintained (push 2026-09-01), documented "near real-time" on M1.
- **Fallback: macOS `say`.** Zero install and offline after voice download; lower, unverified quality and macOS-only; use when Kokoro is not installable.

### Captions / alignment
- **Pick: sentence-level captions from measured per-sentence TTS durations, written as SRT/WebVTT by our own code.** No dependency, exact, parallel-safe.
- **Fallback: whisper.cpp (`-ml 1 -ojf`, MIT) on the narration for word-level timing.** Maintained, Metal/Core ML on Apple Silicon; costs a CMake build and its word mode is labelled experimental. (Heavier alternative if aligning known text matters: WhisperX `align()`.)

### Assembly
- **Pick: ffmpeg CLI via subprocess (`brew install ffmpeg`).** One process per scene, `apad`/`adelay`/`-shortest` for sync, concat for joining; active upstream; license does not bind us as an external tool.
- **Fallback: MoviePy 2.x (MIT).** Pip-only with Pillow-based captions that avoid libass, at the cost of a stale release line (v2.2.1, 2025-05-21) and in-process memory use.
