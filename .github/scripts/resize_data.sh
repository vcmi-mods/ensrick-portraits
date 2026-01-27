#!/usr/bin/env bash
set -euo pipefail

echo "Searching for Data4x directories..."
found=false

# Move a temp image into place only if pixel data differs (ignores metadata)
# Arguments: tmpfile, destfile
move_if_pixels_differ() {
  local tmpfile="$1"
  local destfile="$2"
  if [ -f "$destfile" ]; then
    if command -v compare >/dev/null 2>&1; then
      diff_pixels=$(compare -metric AE "$tmpfile" "$destfile" null: 2>&1 || true)
    else
      diff_pixels=$(magick compare -metric AE "$tmpfile" "$destfile" null: 2>&1 || true)
    fi
    diff_pixels="${diff_pixels%%[^0-9]*}"
    if [ "$diff_pixels" = "0" ]; then
      echo "   $destfile unchanged (pixel-identical)"
      rm -f "$tmpfile"
    else
      mv "$tmpfile" "$destfile"
      echo "   $destfile updated (different pixels: $diff_pixels)"
    fi
    else
    mv "$tmpfile" "$destfile"
    echo "   $destfile created"
  fi
  return 0
}

while IFS= read -r -d '' data4_dir; do
  found=true
  parent_dir="$(dirname "${data4_dir}")"
  out3_dir="$parent_dir/Data3x"
  out2_dir="$parent_dir/Data2x"
  mkdir -p "$out3_dir" "$out2_dir"
  echo "Processing: $data4_dir -> $out3_dir, $out2_dir"

  while IFS= read -r -d '' img; do
    name="$(basename "$img")"
    out3="$out3_dir/$name"
    out2="$out2_dir/$name"
    echo " - Resizing $img -> $out3 (75%) and $out2 (50%)"

    # Create temp files for outputs
    tmp3=$(mktemp --suffix=.png)
    tmp2=$(mktemp --suffix=.png)

    convert "$img" -filter Lanczos -resize 75% -quality 100 "$tmp3"
    convert "$img" -filter Lanczos -resize 50% -quality 100 "$tmp2"

    # Install logic: move temps into place only when pixels differ (metadata ignored)
    move_if_pixels_differ "$tmp3" "$out3"
    move_if_pixels_differ "$tmp2" "$out2"

  done < <(find "$data4_dir" -type f -iname '*.png' -print0)

done < <(find . -type d -name 'Data4x' -print0)

if [ "$found" = false ]; then
  echo "No Data4x directories found."
fi

echo "Done."
