#!/usr/bin/env bash
# Batch trim leading and/or trailing silence from audio files using FFmpeg silenceremove.
#
# Usage:
#   bash trim.sh <file_or_dir> [-t DB] [-o OUT_DIR] [-r] [--no-start] [--no-end] [--overwrite] [--dry-run]
#
# Examples:
#   bash trim.sh Audio/SFX
#   bash trim.sh Audio/Voice --no-end
#   bash trim.sh click.wav -t -45
#   bash trim.sh Audio -r -o Audio/out
#   bash trim.sh Audio/SFX --dry-run

set -euo pipefail

THRESHOLD="-50"
OUTPUT_DIR=""
RECURSE=0
TRIM_START=1
TRIM_END=1
OVERWRITE=0
DRY_RUN=0
INPUT=""

usage() {
  sed -n '2,12p' "$0" | tail -n +2
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -t) THRESHOLD="$2"; shift 2 ;;
    -o) OUTPUT_DIR="$2"; shift 2 ;;
    -r) RECURSE=1; shift ;;
    --no-start) TRIM_START=0; shift ;;
    --no-end) TRIM_END=0; shift ;;
    --overwrite) OVERWRITE=1; shift ;;
    --dry-run) DRY_RUN=1; shift ;;
    -h|--help) usage ;;
    *)
      if [[ -z "$INPUT" ]]; then
        INPUT="$1"
        shift
      else
        echo "Unknown argument: $1" >&2
        usage
      fi
      ;;
  esac
done

[[ -n "$INPUT" ]] || usage

if [[ "$TRIM_START" -eq 0 && "$TRIM_END" -eq 0 ]]; then
  echo "At least one of --no-start or --no-end must remain enabled (trim start and/or end)." >&2
  exit 1
fi

if ! command -v ffmpeg >/dev/null 2>&1; then
  echo "FFmpeg not found on PATH. Install ffmpeg and retry." >&2
  exit 1
fi

is_audio() {
  case "${1,,}" in
    *.wav|*.mp3|*.ogg|*.flac|*.aac|*.m4a|*.wma) return 0 ;;
    *) return 1 ;;
  esac
}

build_filter() {
  local parts=()
  if [[ "$TRIM_START" -eq 1 ]]; then
    parts+=("start_periods=1")
    parts+=("start_duration=0")
    parts+=("start_threshold=${THRESHOLD}dB")
  fi
  if [[ "$TRIM_END" -eq 1 ]]; then
    parts+=("stop_periods=1")
    parts+=("stop_duration=0")
    parts+=("stop_threshold=${THRESHOLD}dB")
  fi

  local joined=""
  local part
  for part in "${parts[@]}"; do
    if [[ -z "$joined" ]]; then
      joined="$part"
    else
      joined="${joined}:${part}"
    fi
  done
  printf 'silenceremove=%s' "$joined"
}

trim_file() {
  local file="$1"
  local out="$2"
  local filter
  filter="$(build_filter)"

  mkdir -p "$(dirname "$out")"
  ffmpeg -hide_banner -nostats -y -i "$file" -af "$filter" "$out" >/dev/null 2>&1
}

collect_files() {
  if [[ -f "$INPUT" ]]; then
    is_audio "$INPUT" || { echo "Not a supported audio file: $INPUT" >&2; exit 1; }
    printf '%s\n' "$INPUT"
    return
  fi

  if [[ ! -d "$INPUT" ]]; then
    echo "Input path not found: $INPUT" >&2
    exit 1
  fi

  if [[ "$RECURSE" -eq 1 ]]; then
    find "$INPUT" -type f | while read -r f; do
      is_audio "$f" && printf '%s\n' "$f"
    done
  else
    find "$INPUT" -maxdepth 1 -type f | while read -r f; do
      is_audio "$f" && printf '%s\n' "$f"
    done
  fi
}

INPUT_ROOT="$INPUT"
if [[ -f "$INPUT" ]]; then
  INPUT_ROOT="$(cd "$(dirname "$INPUT")" && pwd)"
else
  INPUT_ROOT="$(cd "$INPUT" && pwd)"
fi

if [[ -z "$OUTPUT_DIR" ]]; then
  OUTPUT_DIR="${INPUT_ROOT}/trimmed"
fi

FILTER="$(build_filter)"
TRIM_LABEL=""
[[ "$TRIM_START" -eq 1 ]] && TRIM_LABEL="start"
[[ "$TRIM_END" -eq 1 ]] && TRIM_LABEL="${TRIM_LABEL:+$TRIM_LABEL, }end"

mapfile -t FILES < <(collect_files)
if [[ "${#FILES[@]}" -eq 0 ]]; then
  echo "No supported audio files found under: $INPUT"
  exit 0
fi

echo "Input:     $INPUT"
echo "Files:     ${#FILES[@]}"
echo "Threshold: $THRESHOLD dB"
echo "Trim:      $TRIM_LABEL"
echo "Filter:    $FILTER"
echo "Output:    $OUTPUT_DIR"
[[ "$DRY_RUN" -eq 1 ]] && echo "Mode:      DRY RUN"
echo

ok=0
skip=0
fail=0

for file in "${FILES[@]}"; do
  abs_file="$(cd "$(dirname "$file")" && pwd)/$(basename "$file")"
  rel="${abs_file#"$INPUT_ROOT"/}"
  [[ "$rel" == "$abs_file" ]] && rel="$(basename "$abs_file")"
  out="${OUTPUT_DIR}/${rel}"

  if [[ -f "$out" && "$OVERWRITE" -eq 0 && "$DRY_RUN" -eq 0 ]]; then
    echo "[skip] $rel"
    skip=$((skip + 1))
    continue
  fi

  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "[plan] $rel -> $out"
    ok=$((ok + 1))
    continue
  fi

  echo "[run]  $rel"
  if trim_file "$abs_file" "$out"; then
    ok=$((ok + 1))
  else
    echo "[fail] $rel"
    fail=$((fail + 1))
  fi
done

echo
echo "Done. processed=$ok skipped=$skip failed=$fail"
[[ "$fail" -gt 0 ]] && exit 1
