#!/usr/bin/env bash
# Uploads compressed audio to the R2 bucket "gita-audio" under <prefix>/.
# Usage: BUCKET=<name> tool/audio/upload.sh <dir> <prefix>   (needs: npx wrangler login)
# Use prefix "." for the bucket root.
set -euo pipefail
dir="$1"; prefix="$2"; bucket="${BUCKET:-gita-audio}"
for f in "$dir"/*; do
  [ -f "$f" ] || continue
  key="$prefix/$(basename "$f")"; key="${key#./}"
  case "$f" in *.json) type=application/json;; *.mp3) type=audio/mpeg;; *) type=audio/mp4;; esac
  npx --yes wrangler r2 object put "$bucket/$key" \
    --file "$f" --content-type "$type" --remote >/dev/null
  echo "up $(basename "$f")"
done
