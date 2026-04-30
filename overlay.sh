#!/usr/bin/env bash
# hartlapse — burn captions onto a timelapse video.
#
# Reads captions.txt:  unix_timestamp|caption text
# The first timestamp anchors t=0 in the video; later captions appear at
# (timestamp - first_timestamp) * VIDEO_SECONDS_PER_DAY / REAL_SECONDS_PER_DAY.
#
# Usage:
#   ./overlay.sh <input.mp4> <captions.txt> [output.mp4]
#
# Env overrides:
#   SECONDS_PER_DAY=1        # must match what timelapse.sh used
#   HOLD=4                   # seconds each caption stays on screen
#   FONT_SIZE=42
#   FONT_COLOR=white
#   BOX_OPACITY=0.55         # 0 = no background box, 1 = solid

set -euo pipefail

IN="${1:-}"
CAPS="${2:-captions.txt}"
OUT="${3:-${IN%.*}_captioned.mp4}"

if [ -z "$IN" ] || [ ! -f "$IN" ]; then
  echo "usage: $0 <input.mp4> <captions.txt> [output.mp4]" >&2
  exit 1
fi
[ -f "$CAPS" ] || { echo "captions file not found: $CAPS" >&2; exit 1; }
command -v ffmpeg >/dev/null || { echo "ffmpeg not installed" >&2; exit 1; }

SECONDS_PER_DAY="${SECONDS_PER_DAY:-1}"
HOLD="${HOLD:-4}"
FONT_SIZE="${FONT_SIZE:-42}"
FONT_COLOR="${FONT_COLOR:-white}"
BOX_OPACITY="${BOX_OPACITY:-0.55}"

# Build an SRT from captions.txt. Each caption: start = (ts - first_ts) scaled
# by SECONDS_PER_DAY / 86400, end = start + HOLD.
SRT="$(mktemp -t hartlapse.XXXXXX.srt)"
trap 'rm -f "$SRT"' EXIT

awk -F'|' -v spd="$SECONDS_PER_DAY" -v hold="$HOLD" '
  function fmt(t,   h,m,s,ms) {
    h = int(t/3600); t -= h*3600
    m = int(t/60);   t -= m*60
    s = int(t);      ms = int((t-s)*1000 + 0.5)
    return sprintf("%02d:%02d:%02d,%03d", h, m, s, ms)
  }
  /^[[:space:]]*$/ || /^#/ { next }
  {
    ts = $1 + 0
    sub(/^[^|]*\|/, "")
    text = $0
    if (NR == 1 || first == 0) first = ts
    start = (ts - first) * spd / 86400
    end   = start + hold
    n++
    print n
    print fmt(start) " --> " fmt(end)
    print text
    print ""
  }
' "$CAPS" > "$SRT"

echo ">>> hartlapse: burning captions"
echo "    input:    $IN"
echo "    captions: $CAPS  ($(grep -c '^[0-9]' "$SRT") entries)"
echo "    output:   $OUT"

# ffmpeg's subtitles filter wants forward slashes and escaped colons on Windows.
SRT_ESC=$(echo "$SRT" | sed -e 's|\\|/|g' -e 's|:|\\:|g')

ffmpeg -y -i "$IN" \
  -vf "subtitles='${SRT_ESC}':force_style='FontName=Arial,FontSize=${FONT_SIZE},PrimaryColour=&H00FFFFFF&,BorderStyle=3,Outline=1,Shadow=0,BackColour=&H$(printf '%02X' $(awk "BEGIN{print int($BOX_OPACITY*255)}"))000000&,MarginV=60'" \
  -c:a copy -c:v libx264 -preset medium -crf 18 -pix_fmt yuv420p \
  "$OUT"

echo ">>> done: $OUT"
