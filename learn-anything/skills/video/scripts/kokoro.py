#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.10,<3.14"
# dependencies = ["kokoro-onnx==0.6.1"]
# ///
"""kokoro.py <work-dir> --data-dir <dir> [--voice af_bella]

Narrate every <work>/narration/sNN.txt in this ONE process (the model loads once) into
<work>/audio/sNN.wav and write <work>/timing.json (same format as `plan timing`). Model files
are fetched once into <data-dir>/kokoro/ (consent at the plan gate). Exit 1 on any failure so
`narrate` falls back to `say`. Release URLs verified (ticket 49); the Kokoro API call shape is unverified until a Mac spike.
"""
import argparse, json, urllib.request, wave
from pathlib import Path

import numpy as np
from kokoro_onnx import Kokoro

BASE = "https://github.com/thewh1teagle/kokoro-onnx/releases/download/model-files-v1.0/"
FILES = ("kokoro-v1.0.onnx", "voices-v1.0.bin")

ap = argparse.ArgumentParser()
ap.add_argument("work")
ap.add_argument("--data-dir", required=True)
ap.add_argument("--voice", default="af_bella")
a = ap.parse_args()
work, mdir = Path(a.work), Path(a.data_dir) / "kokoro"
mdir.mkdir(parents=True, exist_ok=True)
for f in FILES:
    if not (mdir / f).exists():
        urllib.request.urlretrieve(BASE + f, mdir / f)
engine = Kokoro(str(mdir / FILES[0]), str(mdir / FILES[1]))
(work / "audio").mkdir(exist_ok=True)
scenes = []
for t in sorted((work / "narration").glob("s*.txt")):
    samples, rate = engine.create(t.read_text().strip(), voice=a.voice, speed=1.0, lang="en-us")
    with wave.open(str(work / "audio" / f"{t.stem}.wav"), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(rate)
        w.writeframes((np.clip(samples, -1, 1) * 32767).astype("<i2").tobytes())
    scenes.append({"id": t.stem, "seconds": round(len(samples) / rate, 2)})
body = ",\n".join(json.dumps(s, separators=(",", ":")) for s in scenes)
(work / "timing.json").write_text('{"engine":"kokoro","voice":"%s","scenes":[\n%s\n]}\n' % (a.voice, body))
