#!/usr/bin/env bash
# hartlapse — render a Gource animation of a git repo's history.
#
# Usage:
#   ./timelapse.sh <repo-path> [output.mp4]
#
# Env overrides (optional):
#   WIDTH=1920 HEIGHT=1080 SECONDS_PER_DAY=1 FPS=60
#   HIDE="filenames,mouse,progress"   # gource --hide values, comma-separated
#   TITLE="My Project"                # shown in the gource header

set -euo pipefail

REPO="${1:-}"
OUT="${2:-timelapse.mp4}"

if [ -z "$REPO" ] || [ ! -d "$REPO/.git" ]; then
  echo "usage: $0 <repo-path> [output.mp4]" >&2
  echo "       <repo-path> must be a git repository" >&2
  exit 1
fi

command -v gource >/dev/null || { echo "gource not installed" >&2; exit 1; }
command -v ffmpeg >/dev/null || { echo "ffmpeg not installed" >&2; exit 1; }

WIDTH="${WIDTH:-1920}"
HEIGHT="${HEIGHT:-1080}"
SECONDS_PER_DAY="${SECONDS_PER_DAY:-1}"
FPS="${FPS:-60}"
HIDE="${HIDE:-filenames,mouse,progress}"
TITLE="${TITLE:-$(basename "$REPO")}"

echo ">>> hartlapse: $TITLE"
echo "    repo:   $REPO"
echo "    output: $OUT  (${WIDTH}x${HEIGHT} @ ${FPS}fps)"

gource "$REPO" \
  --title "$TITLE" \
  -"${WIDTH}"x"${HEIGHT}" \
  --seconds-per-day "$SECONDS_PER_DAY" \
  --auto-skip-seconds 1 \
  --hide "$HIDE" \
  --key \
  --highlight-users \
  --output-framerate "$FPS" \
  --output-ppm-stream - \
  | ffmpeg -y -r "$FPS" -f image2pipe -vcodec ppm -i - \
      -vcodec libx264 -preset medium -pix_fmt yuv420p -crf 18 \
      -threads 0 -bf 0 "$OUT"

echo ">>> done: $OUT"
