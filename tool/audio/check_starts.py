"""Checks where each verse starts in a new narration by comparing it with an
earlier recording of the same verse (same voice, same opening words).

  python3 -I tool/audio/check_starts.py <narration.mp3> <key.txt> <old_dir> <ids.json>

For every verse after the first, the first 2 s of the old recording is
compared (log-mel features, dynamic time warping) with the new audio starting
at each pause end within 8 s of either side; the best few are printed. ids.json maps
each key label to its old file, e.g. {"1.8": "ch01/bg-01-008.en.m4a"}.
Signal analysis only: it tells where the opening sounds most alike.
"""
import json
import pathlib
import re
import subprocess
import sys

import numpy as np

SR = 16000


def pcm(path, ss=None, t=None):
    cmd = ["ffmpeg", "-nostdin", "-loglevel", "error"]
    if ss is not None:
        cmd += ["-ss", f"{ss:.3f}"]
    if t is not None:
        cmd += ["-t", f"{t:.3f}"]
    cmd += ["-i", str(path), "-ac", "1", "-ar", str(SR), "-f", "s16le", "-"]
    return np.frombuffer(subprocess.run(cmd, capture_output=True, check=True).stdout, np.int16) / 32768.0


def mel_filters(n_fft=512, n_mels=40):
    def hz2mel(f): return 2595 * np.log10(1 + f / 700)
    def mel2hz(m): return 700 * (10 ** (m / 2595) - 1)
    pts = mel2hz(np.linspace(hz2mel(80), hz2mel(7600), n_mels + 2))
    bins = np.floor((n_fft + 1) * pts / SR).astype(int)
    fb = np.zeros((n_mels, n_fft // 2 + 1))
    for i in range(n_mels):
        a, b, c = bins[i], bins[i + 1], bins[i + 2]
        fb[i, a:b] = (np.arange(a, b) - a) / max(b - a, 1)
        fb[i, b:c] = (c - np.arange(b, c)) / max(c - b, 1)
    return fb


FB = mel_filters()


def feats(x):
    win, hop = 400, 160
    n = 1 + max(0, (len(x) - win) // hop)
    frames = np.stack([x[i * hop:i * hop + win] * np.hanning(win) for i in range(n)])
    spec = np.abs(np.fft.rfft(frames, 512)) ** 2
    m = np.log(spec @ FB.T + 1e-8)
    m -= m.mean(axis=0)
    return m / (np.linalg.norm(m, axis=1, keepdims=True) + 1e-8)


def dtw(a, b):
    """Template a against the start of b, open end on b. Mean cost per step."""
    cost = 1 - a @ b.T
    D = np.full((len(a) + 1, len(b) + 1), np.inf)
    D[0, 0] = 0
    for i in range(1, len(a) + 1):
        for j in range(1, len(b) + 1):
            D[i, j] = cost[i - 1, j - 1] + min(D[i - 1, j], D[i, j - 1], D[i - 1, j - 1])
    return D[len(a), 1:].min() / len(a)


audio, key, old_dir, ids = sys.argv[1], pathlib.Path(sys.argv[2]), pathlib.Path(sys.argv[3]), sys.argv[4]
ids = json.loads(pathlib.Path(ids).read_text())
labels = re.findall(r"^TEXT ([\d.\-–]+): ", key.read_text(), re.M)
log = subprocess.run(["ffmpeg", "-nostdin", "-hide_banner", "-i", audio, "-af",
                      "silencedetect=noise=-40dB:d=0.2", "-f", "null", "-"], capture_output=True, text=True).stderr
ends = [float(x) for x in re.findall(r"silence_end: ([\d.]+)", log)]
full = pcm(audio)
cuts = json.loads(sys.stdin.read())  # the splitter's verse start times, by label

starts = [float(x) for x in re.findall(r"silence_start: ([\d.]+)", log)]


def trim_end(x, thr=0.01):
    env = np.convolve(np.abs(x), np.ones(400) / 400, "same")
    idx = np.nonzero(env > thr)[0]
    return x[:idx[-1] + 1] if len(idx) else x


if "--ends" in sys.argv:
    # Where does each verse END? Old recording's last 2 s (reversed) against
    # the new audio just before each pause start.
    nxt = dict(zip(labels, labels[1:]))
    for label in labels[:-1]:
        old = trim_end(pcm(old_dir / ids[label]))
        tmpl = feats(old[-2 * SR:])[::-1]
        guess = cuts[nxt[label]]
        scores = []
        for st in starts:
            if abs(st - guess) <= 8 and st > 3:
                seg = full[int((st - 2.8) * SR):int(st * SR)]
                scores.append((dtw(tmpl, feats(seg)[::-1]), st))
        scores.sort()
        best = scores[0][1]
        mark = "same" if abs(best - guess) < 0.9 else f"MOVE {guess:.2f} -> {best:.2f}"
        top = ", ".join(f"{e:.2f}:{s:.3f}" for s, e in scores[:3])
        print(f"{label:>7} ends before {guess:7.2f}  best end {best:7.2f}  {mark:24}  [{top}]")
    sys.exit()

for label in labels[1:]:
    tmpl = feats(pcm(old_dir / ids[label], t=2.0))
    guess = cuts[label]
    scores = []
    for e in ends:
        if abs(e - guess) <= 8:
            seg = full[int(e * SR):int((e + 2.8) * SR)]
            scores.append((dtw(tmpl, feats(seg)), e))
    scores.sort()
    best = scores[0][1]
    mark = "same" if abs(best - guess) < 0.6 else f"MOVE {guess:.2f} -> {best:.2f}"
    top = ", ".join(f"{e:.2f}:{s:.3f}" for s, e in scores[:3])
    print(f"{label:>7} cut {guess:7.2f}  best start {best:7.2f}  {mark:24}  [{top}]")
