"""Extracts the Hugging Face shloka WAVs (JDhruv14/Bhagavad-Gita_Audio,
Apache-2.0) from parquet into one file per shloka_id.

Run with the audio venv:
  ~/versescroll_audio/.venv/bin/python -I tool/audio/extract_hf.py \
      ~/versescroll_audio/raw/hf ~/versescroll_audio/wav
"""
import pathlib
import sys

import pyarrow.parquet as pq

src, out = pathlib.Path(sys.argv[1]), pathlib.Path(sys.argv[2])
out.mkdir(parents=True, exist_ok=True)
n = 0
for f in sorted(src.glob("*.parquet")):
    t = pq.read_table(f, columns=["shloka_id", "audio"])
    for sid, audio in zip(t.column("shloka_id").to_pylist(), t.column("audio").to_pylist()):
        safe = "".join(ch if ch.isalnum() or ch in "-._" else "_" for ch in str(sid))
        (out / f"{safe}.wav").write_bytes(audio["bytes"])
        n += 1
print(f"extracted {n} files to {out}")
