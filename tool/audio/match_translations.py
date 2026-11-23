"""Sorts the owner's English translation clips into the app's verse ids,
then builds one AAC file per verse and writes translations.json for
make_manifest.py.

  python3 -I tool/audio/match_translations.py <VIDAUDIO dir> <assets/scripture> <out_dir> [bitrate_k]

The recordings follow a different edition of the translation than the app's
text, so the verse id comes from the clip's verse numbers (file name) and the
chapter from its folder; a folder without a chapter ("unknown 1") takes the
chapter its clips' text matches best. Every clip's text is then checked
against the dataset: when the expected verse is not the best match within its
chapter the clip is flagged. Ids not in the dataset, duplicates and missing
verses are flagged too and written to <out_dir>/translations_report.txt;
nothing is guessed.
"""
import difflib
import hashlib
import json
import pathlib
import re
import subprocess
import sys

src, scripture, out = map(pathlib.Path, sys.argv[1:4])
br = sys.argv[4] if len(sys.argv) > 4 else "96"


def words(s):
    s = re.sub(r"^\s*TEXTS?\s+[\d\-–]+\s*:\s*", "", s)
    s = s.lower().replace("–", " ").replace("—", " ")
    return re.findall(r"[a-zāīūṛṝḷṅñṭḍṇśṣṁḥ']+", s)


entries = []
for f in sorted(scripture.glob("chapter_*.json")):
    for e in json.loads(f.read_text())["entries"]:
        entries.append((e["id"], words(e["translation"]["en"])))

by_id = dict(entries)
clips = sorted(src.glob("*/verses/*.mp3"))
best = {}  # id -> (score, clip)
report = []


def score(w, vid):
    return difflib.SequenceMatcher(None, w, by_id[vid], autojunk=False).ratio()


def folder_chapter(folder):
    m = re.match(r"chapter (\d+)", folder.name)
    if m:
        return int(m.group(1))
    votes = {}
    for mp3 in folder.glob("verses/*.mp3"):
        w = words(mp3.with_suffix(".txt").read_text())
        vid = max(by_id, key=lambda i: score(w, i))
        votes[int(vid.split("-")[1])] = votes.get(int(vid.split("-")[1]), 0) + 1
    ch = max(votes, key=votes.get)
    report.append(f"FOLDER {folder.name} -> chapter {ch} (text votes {votes})")
    return ch


def label(text):
    m = re.match(r"\s*TEXTS?\s+(\d+)(?:\s*[-–]\s*(\d+))?\s*:?", text)
    return (int(m.group(1)), int(m.group(2) or m.group(1))) if m else None


def entry_for(ch, start, end):
    """The dataset entry covering verses start..end of ch, if one does."""
    for i in by_id:
        p = i.split("-")
        if int(p[1]) == ch and int(p[2]) <= start and end <= int(p[-1]):
            return i
    return None


chapters = {}
parts = {}  # id -> [(verse start, clip, text)]
for mp3 in clips:
    folder = mp3.parent.parent
    if folder not in chapters:
        chapters[folder] = folder_chapter(folder)
    ch = chapters[folder]
    rel = mp3.relative_to(src)
    txt = mp3.with_suffix(".txt")
    m = re.search(r"_verse_(\d+)(?:-(\d+))?$", mp3.stem)
    start, end = int(m.group(1)), int(m.group(2) or m.group(1))
    if not txt.exists():
        # The owner sent the recording alone: placed by its number, and the
        # app keeps its current text for this verse.
        vid = entry_for(ch, start, end)
        report.append(f"NO TEXT {vid}: {rel} placed by its number; app text unchanged")
        parts.setdefault(vid, []).append((start, mp3, None))
        continue
    text = txt.read_text()
    w = words(text)
    own = [i for i in by_id if i.startswith(f"bg-{ch:02d}-")]
    top = max(own, key=lambda i: score(w, i))
    lab = label(text)
    if lab and lab != (start, end):
        report.append(f"LABEL {rel}: file says {start}-{end}, text says TEXT {lab[0]}-{lab[1]}; using the text")
        start, end = lab
    elif not lab and score(w, top) >= 0.8 and top != entry_for(ch, start, end):
        # No verse label in the clip and the text is unmistakably another verse.
        p = top.split("-")
        report.append(f"RENUMBERED {rel}: no TEXT label, file says {start}, text is {top} ({score(w, top):.2f})")
        start, end = int(p[2]), int(p[-1])
    vid = entry_for(ch, start, end)
    if vid is None:
        report.append(f"NO SUCH VERSE {ch}.{start}-{end}: {rel}")
        continue
    if top != vid:
        report.append(f"EDITION {vid}: {rel} text is closer to {top} ({score(w, top):.2f} vs {score(w, vid):.2f}); kept by its verse number")
    parts.setdefault(vid, []).append((start, mp3, text))

best = {}
texts = {}
for vid, ps in parts.items():
    ps.sort()
    starts = [x[0] for x in ps]
    if len(set(starts)) != len(starts):
        report.append(f"DUPLICATE {vid}: " + ", ".join(str(x[1].relative_to(src)) for x in ps))
        continue
    if len(ps) > 1:
        report.append(f"JOINED {vid}: " + " + ".join(x[1].name for x in ps))
    best[vid] = (0, [x[1] for x in ps])
    # Verbatim text: the "TEXT n:" label is dropped, nothing else changes.
    if any(x[2] is None for x in ps):
        continue
    texts[vid] = " ".join(re.sub(r"^\s*TEXTS?\s+[\d\s\-–]+:?\s*", "", x[2]).strip() for x in ps)

missing = [i for i, _ in entries if i not in best]
for i in missing:
    report.append(f"MISSING {i}")

index = {}
for vid, (_, mp3s) in sorted(best.items()):
    ch = vid.split("-")[1]
    rel = f"ch{ch}/{vid}.en.m4a"
    dst = out / rel
    dst.parent.mkdir(parents=True, exist_ok=True)
    if not dst.exists():
        ins = [a for f in mp3s for a in ("-i", str(f))]
        n = len(mp3s)
        flt = "".join(f"[{k}:a]" for k in range(n)) + f"concat=n={n}:v=0:a=1,loudnorm=I=-18:TP=-1.5:LRA=11[a]"
        subprocess.run(["ffmpeg", "-nostdin", "-loglevel", "error", "-y", *ins,
                        "-filter_complex", flt, "-map", "[a]", "-ac", "1", "-ar", "44100",
                        "-c:a", "aac", "-b:a", f"{br}k", "-movflags", "+faststart", str(dst)], check=True)
    ms = round(float(subprocess.run(["ffprobe", "-v", "error", "-show_entries", "format=duration",
                                     "-of", "csv=p=0", str(dst)], capture_output=True, text=True,
                                    check=True).stdout) * 1000)
    data = dst.read_bytes()
    index[vid] = {"file": rel, "entries": [vid], "ms": ms, "bytes": len(data),
                  "sha256": hashlib.sha256(data).hexdigest(),
                  "source": [str(f.relative_to(src)) for f in mp3s]}

(out / "translations.json").write_text(json.dumps(index, indent=1))
(out / "translations_text.json").write_text(json.dumps(texts, indent=1, ensure_ascii=False) + "\n")
(out / "translations_report.txt").write_text("\n".join(report) + "\n")
print("\n".join(report))
total = sum(v["bytes"] for v in index.values())
print(f"{len(index)}/{len(entries)} verses matched, {len(missing)} missing, "
      f"{total / 1e6:.0f} MB, {sum(v['ms'] for v in index.values()) / 3.6e6:.1f} hours")
