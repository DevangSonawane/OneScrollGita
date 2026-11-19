"""Builds one AAC file per mapping block (joined WAVs, mono, loudness
normalised) named after the block's first verse id, and writes
shlokas.json: {first_entry_id: {file, entries, ms, bytes, sha256}}.

  ~/versescroll_audio/.venv/bin/python -I tool/audio/build_shlokas.py \
      ~/versescroll_audio/mapping.json ~/versescroll_audio/wav \
      ~/versescroll_audio/out 96
"""
import hashlib
import json
import pathlib
import subprocess
import sys

mapping, wav, out = map(pathlib.Path, sys.argv[1:4])
br = sys.argv[4] if len(sys.argv) > 4 else "96"
index = {}
for b in json.loads(mapping.read_text()):
    first = b["entries"][0]
    ch = first.split("-")[1]
    rel = f"ch{ch}/{first}.sa.m4a"
    dst = out / rel
    dst.parent.mkdir(parents=True, exist_ok=True)
    if not dst.exists():
        ins = []
        for r in b["recordings"]:
            ins += ["-i", str(wav / f"{r}.wav")]
        n = len(b["recordings"])
        flt = "".join(f"[{k}:a]" for k in range(n)) + f"concat=n={n}:v=0:a=1,loudnorm=I=-18:TP=-1.5:LRA=11[a]"
        subprocess.run(["ffmpeg", "-nostdin", "-loglevel", "error", "-y", *ins,
                        "-filter_complex", flt, "-map", "[a]", "-ac", "1", "-ar", "44100",
                        "-c:a", "aac", "-b:a", f"{br}k", "-movflags", "+faststart", str(dst)], check=True)
    ms = round(float(subprocess.run(["ffprobe", "-v", "error", "-show_entries", "format=duration",
                                     "-of", "csv=p=0", str(dst)], capture_output=True, text=True,
                                    check=True).stdout) * 1000)
    data = dst.read_bytes()
    index[first] = {"file": rel, "entries": b["entries"], "ms": ms, "bytes": len(data),
                    "sha256": hashlib.sha256(data).hexdigest()}
(out / "shlokas.json").write_text(json.dumps(index, indent=1))
total = sum(v["bytes"] for v in index.values())
print(f"{len(index)} files, {total / 1e6:.0f} MB, {sum(v['ms'] for v in index.values()) / 3.6e6:.1f} hours")
