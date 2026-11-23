"""Splits one narration of several verses (read in a known order, one pause
between verses) into one MP3 per verse, without speech recognition.

  python3 -I tool/audio/split_by_text.py <narration.mp3> <key.txt> <out_dir> [expected.json]

key.txt lists the verses in reading order as "TEXT <chapter>.<verse>: text"
paragraphs (docs/re-voice-list.txt). Cut points are chosen among the pauses
so each verse's length best fits its text length (dynamic programming), with
a small preference for longer pauses. Writes out_dir/<n>_<label>.mp3 (stream
copy) and prints each verse's speaking rate and the pause it was cut at, so
a bad fit stands out. Check the result by ear: this is signal analysis only.
"""
import math
import pathlib
import re
import subprocess
import sys

audio, key, out = sys.argv[1], pathlib.Path(sys.argv[2]), pathlib.Path(sys.argv[3])
verses = re.findall(r"^TEXT ([\d.\-–]+): (.+)$", key.read_text(), re.M)
n = len(verses)
chars = [len(t) for _, t in verses]
# Optional: expected seconds per verse (e.g. from an earlier recording of
# nearly the same text, same voice) as a JSON {label: seconds}; it replaces
# the character count as the length model.
if len(sys.argv) > 4:
    import json
    exp = json.loads(pathlib.Path(sys.argv[4]).read_text())
    chars = [exp[label] for label, _ in verses]

dur = float(subprocess.run(["ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0",
                            audio], capture_output=True, text=True, check=True).stdout)
log = subprocess.run(["ffmpeg", "-nostdin", "-hide_banner", "-i", audio, "-af",
                      "silencedetect=noise=-40dB:d=0.2", "-f", "null", "-"],
                     capture_output=True, text=True).stderr
starts = [float(x) for x in re.findall(r"silence_start: ([\d.]+)", log)]
ends = [float(x) for x in re.findall(r"silence_end: ([\d.]+)", log)]
gaps = [(s, e) for s, e in zip(starts, ends) if s > 0.5 and e < dur - 0.5]
cuts = [(s + e) / 2 for s, e in gaps]
plen = [e - s for s, e in gaps]

rate = dur / sum(chars)  # seconds per character, refined below
for _ in range(3):
    m = len(cuts)
    INF = float("inf")
    # best[v][j]: verses 0..v end at cut j (j = m means end of file).
    best = [[INF] * (m + 1) for _ in range(n)]
    back = [[-1] * (m + 1) for _ in range(n)]
    pos = cuts + [dur]

    def cost(a, b, v, p):
        d = b - a
        return math.log(d / (rate * chars[v])) ** 2 - 0.5 * p

    for j in range(m + 1):
        best[0][j] = cost(0.0, pos[j], 0, plen[j] if j < m else 0)
    for v in range(1, n):
        for j in range(m + 1):
            p = plen[j] if j < m else 0
            for i in range(j):
                if best[v - 1][i] == INF:
                    continue
                c = best[v - 1][i] + cost(pos[i], pos[j], v, p)
                if c < best[v][j]:
                    best[v][j], back[v][j] = c, i
    path = [m]
    for v in range(n - 1, 0, -1):
        path.append(back[v][path[-1]])
    path.reverse()  # path[v] = index of the cut ending verse v
    bounds = [0.0] + [pos[j] for j in path]
    rate = sum(bounds[v + 1] - bounds[v] for v in range(n)) / sum(chars)

out.mkdir(parents=True, exist_ok=True)
for v, (label, _) in enumerate(verses):
    a, b = bounds[v], bounds[v + 1]
    r = (b - a) / (rate * chars[v])
    p = plen[path[v]] if path[v] < len(plen) else 0
    flag = "" if 0.85 <= r <= 1.15 else "  <-- check"
    print(f"{v + 1:2d} {label:>7} {a:7.2f}-{b:7.2f}  len {b - a:5.1f}s  fit {r:4.2f}  pause {p:4.2f}s{flag}")
    subprocess.run(["ffmpeg", "-nostdin", "-loglevel", "error", "-y", "-ss", f"{a:.3f}", "-to", f"{b:.3f}",
                    "-i", audio, "-c", "copy", str(out / f"{v + 1:02d}_{label}.mp3")], check=True)
