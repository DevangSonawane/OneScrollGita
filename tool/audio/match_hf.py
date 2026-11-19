"""Maps Hugging Face shloka recordings to the app's verse ids by comparing
Devanagari text (the editions number some verses differently, so numbers
alone would misalign). Writes mapping.json and prints a report.

  ~/versescroll_audio/.venv/bin/python -I tool/audio/match_hf.py \
      ~/versescroll_audio/raw/hf assets/scripture ~/versescroll_audio/mapping.json
"""
import difflib
import json
import pathlib
import re
import sys

import pyarrow.parquet as pq

src, scripture, out = map(pathlib.Path, sys.argv[1:4])
keep = re.compile(r"[ऀ-ॣॱ-ॿ]")  # letters/signs, not dandas or digits


def norm(s):
    return "".join(keep.findall(s or ""))


rec = []  # (chapter, verse, id, text)
for f in sorted(src.glob("*.parquet")):
    t = pq.read_table(f, columns=["shloka_id", "sanskrit"])
    for sid, sa in zip(t.column("shloka_id").to_pylist(), t.column("sanskrit").to_pylist()):
        ch, v = (int(x) for x in str(sid).split("_")[:2])
        rec.append((ch, v, str(sid), norm(sa)))
rec.sort()

blocks, report = [], []
for chf in sorted(scripture.glob("chapter_*.json")):
    data = json.loads(chf.read_text())
    ch = data["chapter"]
    ents = [(e["id"], norm("".join(e["sanskrit"]))) for e in data["entries"]]
    recs = [r for r in rec if r[0] == ch]
    n, m = len(ents), len(recs)
    NEG = float("-inf")
    best = [[NEG] * (m + 1) for _ in range(n + 1)]
    back = [[None] * (m + 1) for _ in range(n + 1)]
    best[0][0] = 0.0
    # Monotonic alignment: each step pairs a entries with b recordings
    # (1..6 entries, 1..7 recordings); score weighted by text length.
    for i in range(n + 1):
        for j in range(m + 1):
            if best[i][j] == NEG:
                continue
            # Stay near the diagonal (editions differ by a few verses at most).
            if abs(j - i * m / max(n, 1)) > 8:
                continue
            for a in range(1, 7):
                for b in range(1, 8):
                    if i + a > n or j + b > m:
                        continue
                    t1 = "".join(x[1] for x in ents[i : i + a])
                    t2 = "".join(x[3] for x in recs[j : j + b])
                    r = difflib.SequenceMatcher(None, t1, t2, autojunk=False).ratio()
                    sc = best[i][j] + r * (len(t1) + len(t2)) - 12 * (a + b - 2)
                    if sc > best[i + a][j + b]:
                        best[i + a][j + b] = sc
                        back[i + a][j + b] = (i, j, r)
    i, j, path = n, m, []
    while i or j:
        pi, pj, r = back[i][j]
        path.append(([e[0] for e in ents[pi:i]], [x[2] for x in recs[pj:j]], round(r, 3)))
        i, j = pi, pj
    for e_ids, r_ids, r in reversed(path):
        blocks.append({"entries": e_ids, "recordings": r_ids, "score": r})
        if r < 0.9 or len(e_ids) > 1:
            report.append(f"{'LOW ' if r < 0.9 else ''}{e_ids} <- {r_ids} ({r})")

out.write_text(json.dumps(blocks, indent=1))
print(f"{len(blocks)} blocks; {sum(len(b['entries']) for b in blocks)} entries; "
      f"{sum(len(b['recordings']) for b in blocks)} recordings")
print("\n".join(report) or "all clean")
