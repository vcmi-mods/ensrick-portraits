#!/usr/bin/env bash
set -euo pipefail

echo "Searching for Data4x directories..."
found=false

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
    convert "$img" -filter Lanczos -resize 75% -quality 100 "$out3"
    convert "$img" -filter Lanczos -resize 50% -quality 100 "$out2"
  done < <(find "$data4_dir" -type f -iname '*.png' -print0)

done < <(find . -type d -name 'Data4x' -print0)

if [ "$found" = false ]; then
  echo "No Data4x directories found."
fi

echo "Done."
