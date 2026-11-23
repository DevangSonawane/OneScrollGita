"""Writes manifest.json for the app from shlokas.json (and translations.json
when it exists). Usage:
  python3 -I tool/audio/make_manifest.py <out_dir> [assets/scripture]

With the scripture folder, a recording keyed to a verse id the dataset no
longer has (e.g. bg-17-008-010 after the dataset split it into 8, 9, 10) is
re-keyed to the first dataset id it covers, with all covered ids in
"entries", like the other multi-verse blocks. Every dataset id must end up
covered, or nothing is written."""
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
def rekey(tracks, ids):
    def covers(old):
        p = old.split("-")
        ch, a, b = int(p[1]), int(p[2]), int(p[-1])
        return [i for i in ids if int(i.split("-")[1]) == ch and a <= int(i.split("-")[2]) and int(i.split("-")[-1]) <= b]
    fixed = {}
    for key, t in tracks.items():
        entries = [n for e in t["entries"] for n in ([e] if e in ids else covers(e))]
        if not entries:
            sys.exit(f"{key}: covers no dataset verse")
        fixed[entries[0]] = dict(t, entries=entries)
        if entries[0] != key:
            print(f"re-keyed {key} -> {entries[0]} {entries}")
    missing = set(ids) - {e for t in fixed.values() for e in t["entries"]}
    if missing:
        sys.exit(f"no recording covers: {sorted(missing)}")
    return fixed


if len(sys.argv) > 2:
    ids = [e["id"] for f in sorted(pathlib.Path(sys.argv[2]).glob("chapter_*.json"))
           for e in json.loads(f.read_text())["entries"]]
    sa = rekey(sa, ids)
    if en:
        en = rekey(en, ids)
en = {k: {f: v[f] for f in ("file", "entries", "ms", "bytes", "sha256")} for k, v in en.items()}
(out / "manifest.json").write_text(json.dumps({"version": 1, "sa": sa, "en": en, "summaries": summaries}))
print(f"manifest: {len(sa)} recitations, {len(en)} translations, {len(summaries)} narrations")
