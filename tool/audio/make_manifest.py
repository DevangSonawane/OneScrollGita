"""Writes manifest.json for the app from shlokas.json (and translations.json
when it exists). Usage: python3 -I tool/audio/make_manifest.py <out_dir>"""
import json
import pathlib
import sys

out = pathlib.Path(sys.argv[1])
sa = json.loads((out / "shlokas.json").read_text())
en_file = out / "translations.json"
en = json.loads(en_file.read_text()) if en_file.exists() else {}
import hashlib
import subprocess

summaries = {}
for f in sorted((out / "summaries").glob("summary-*.mp3")):
    ch = int(f.stem.split("-")[1])  # 0 = introduction
    ms = round(float(subprocess.run(["ffprobe", "-v", "error", "-show_entries", "format=duration",
                                     "-of", "csv=p=0", str(f)], capture_output=True, text=True,
                                    check=True).stdout) * 1000)
    data = f.read_bytes()
    summaries[str(ch)] = {"file": f"summaries/{f.name}", "ms": ms, "bytes": len(data),
                          "sha256": hashlib.sha256(data).hexdigest(), "entries": []}
(out / "manifest.json").write_text(json.dumps({"version": 1, "sa": sa, "en": en, "summaries": summaries}))
print(f"manifest: {len(sa)} recitations, {len(en)} translations, {len(summaries)} narrations")
