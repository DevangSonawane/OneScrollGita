#!/usr/bin/env bash
# WAV → AAC .m4a for the app (PRD_v4 section 2). Mono, loudness-normalised.
# Usage: tool/audio/compress.sh <in_dir> <out_dir> [bitrate_k, default 96]
set -euo pipefail
in="$1"; out="$2"; br="${3:-96}"
mkdir -p "$out"
for f in "$in"/*.wav; do
  name="$(basename "${f%.wav}")"
  [ -s "$out/$name.m4a" ] && continue
  ffmpeg -nostdin -loglevel error -y -i "$f" -ac 1 -ar 44100 \
    -af loudnorm=I=-18:TP=-1.5:LRA=11 -c:a aac -b:a "${br}k" \
    -movflags +faststart "$out/$name.m4a"
done
echo "done: $(ls "$out" | wc -l | tr -d ' ') files, $(du -sh "$out" | cut -f1)"
