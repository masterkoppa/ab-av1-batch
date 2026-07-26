#!/usr/bin/env bash
set -euo pipefail

ENCODE_DIR="/encode-targets"
OUTPUT_DIR="/output"
TARGET_CODEC="${TARGET_CODEC:-AV1}"
MIN_VMAF="${MIN_VMAF:-95}"

# Map target to ab-av1 encoder name and codec detection name
case "${TARGET_CODEC^^}" in
  AV1)
    ENCODER="libsvtav1"
    SKIP_CODEC="av1"
    ;;
  HEVC)
    ENCODER="libx265"
    SKIP_CODEC="hevc"
    ;;
  *)
    echo "ERROR: TARGET_CODEC must be AV1 or HEVC (got: $TARGET_CODEC)"
    exit 1
    ;;
esac

echo "=== ab-av1 batch encoder ==="
echo "Target codec: $TARGET_CODEC ($ENCODER)"
echo "Min VMAF:     $MIN_VMAF"
echo "Source:       $ENCODE_DIR"
echo "Output:       $OUTPUT_DIR"
echo ""

TOTAL=0
SKIPPED=0
ENCODED=0
FAILED=0

while IFS= read -r -d '' file; do
  rel_path="${file#"$ENCODE_DIR"/}"
  out_file="$OUTPUT_DIR/$rel_path"
  out_dir="$(dirname "$out_file")"

  TOTAL=$((TOTAL + 1))

  # Skip if output already exists
  if [[ -f "$out_file" ]]; then
    echo "SKIP (exists): $rel_path"
    SKIPPED=$((SKIPPED + 1))
    continue
  fi

  # Probe current video codec
  codec=$(ffprobe -v error -select_streams v:0 \
    -show_entries stream=codec_name -of csv=p=0 "$file" 2>/dev/null || true)

  echo "ENCODE: $rel_path ($codec -> $TARGET_CODEC)"
  mkdir -p "$out_dir"

  if ab-av1 auto-encode -i "$file" -o "$out_file" \
    --encoder "$ENCODER" --min-vmaf "$MIN_VMAF" --acodec copy; then
    ENCODED=$((ENCODED + 1))
    orig_size=$(stat -c%s "$file")
    new_size=$(stat -c%s "$out_file")
    savings=$(( (orig_size - new_size) * 100 / orig_size ))
    echo "  Done: ${savings}% size reduction"
  else
    FAILED=$((FAILED + 1))
    echo "  FAILED: $rel_path"
    # Clean up partial output
    rm -f "$out_file"
  fi

done < <(find "$ENCODE_DIR" -type f \( -iname '*.mkv' -o -iname '*.mp4' -o -iname '*.avi' -o -iname '*.ts' -o -iname '*.wmv' \) -print0 | sort -z)

echo ""
echo "=== Complete ==="
echo "Total: $TOTAL | Encoded: $ENCODED | Skipped: $SKIPPED | Failed: $FAILED"
