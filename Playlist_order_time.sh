#!/usr/bin/env bash
#
# Playlist_order_time.sh
#
# Usage:
#   ./reorder_playlists.sh [playlist_directory]
#
# Finds all .m3u, .m3u8 &.pls files in the given (or current) directory,
# lists them oldest→newest, lets you reorder by entering a sequence
# of indices, then retouches them so they again sort oldest→newest
# in that chosen order.

set -euo pipefail
ORDER_FILE="playlist_order.txt"

apply_order () {
  local -n playlists=$1
  # Retouch in order: first gets now-(N-1)*60s, last gets now
  NOW=$(( $(date +%s) - $(date +%s) % 60 ))
  N=${#playlists[@]}
  echo
  echo "Re‑touching files in your chosen order (1-minute gaps)..."
  for i in "${!playlists[@]}"; do
    file="${playlists[i]}"
    offset=$(( i + 1 ))
    ts=$(( NOW + offset * 60 ))  # 1 minute apart
    touch -d "@$ts" "$file"
    # printf "  → %s  (set to %s)\n" "$file" "$(date -d "@$ts" +"%Y-%m-%d %H:%M:%S")"
  done
  # Save current playlist order
  echo
  echo "Saving current order..."
  printf '%s\n' "${playlists[@]}" > "${TARGET_DIR}/${ORDER_FILE}"
  echo
  echo "✅ Done. Files are now spaced one minute apart in your chosen order."
}

print_playlists () {
local -n playlists=$1
  for index_dok in "${!playlists[@]}"; do
    printf "  %2d) %s\n" "$((index_dok+1))" "${playlists[index_dok]}"
  done
}

# Directory to scan (default = current dir)
TARGET_DIR="${1:-.}"
echo "$TARGET_DIR"

# Gather playlist files, sorted by modification time (oldest first)
FILE_EXTS=("m3u" "pls" "m3u8")

# Build conditions for find command
find_conditions=()
for ext in "${FILE_EXTS[@]}"; do
    find_conditions+=(-iname "*.${ext}")
    find_conditions+=(-o)
done
unset 'find_conditions[${#find_conditions[@]}-1]'  # Remove last -o

# Find playlist files, sort by modtime, extract paths
mapfile -t PLAYLISTS < <(
  find "$TARGET_DIR" -maxdepth 1 \( -type f \( "${find_conditions[@]}" \) \) \
    -printf '%T@ %p\n' \
    | sort -n \
    | awk '{sub(/^[^ ]* /, ""); print}'
)

if [ "${#PLAYLISTS[@]}" -eq 0 ]; then
  echo "❌ No .m3u , .m3u8 or .pls files found in '$TARGET_DIR'."
  exit 1
fi

# Restore handling
ORDER_FILE_PATH="${TARGET_DIR}/${ORDER_FILE}"
if [ -f "$ORDER_FILE_PATH" ]; then
  echo "Do you want to restore the last order? (y/n)"
  read -ra bool_restore
else
  echo "No backup found"
  bool_restore="n"
fi

if [ "${bool_restore}" = "y" ]; then
  # Restore last order
  mapfile -t RESTORED_ORDER < "${TARGET_DIR}/${ORDER_FILE}"
  # echo "${RESTORED_ORDER}"
  # echo "RESTORED_ORDER count: ${#RESTORED_ORDER[@]}"
  # printf "'%s'
  # " "${RESTORED_ORDER[@]}" | sort
  # echo "PLAYLISTS count: ${#PLAYLISTS[@]}"
  # printf "'%s'
  #" "${PLAYLISTS[@]}" | sort

  # Exclude map
  declare -A exclude
  for item in "${RESTORED_ORDER[@]}"; do
    exclude["$item"]=1
  done

  # Filter PLAYLISTS
  new_playlists=()
  for item in "${PLAYLISTS[@]}"; do
    [[ -z "${exclude[$item]-}" ]] && new_playlists+=("$item")
  done
  NEW_PLAYLISTS=("${new_playlists[@]}")

  # Test for new playlists
  if [ ${#NEW_PLAYLISTS[@]} -eq 0 ]; then
    echo
    echo "no new playlists"
    apply_order RESTORED_ORDER
  else
    echo
    echo "Saved playlists:"
    # echo "!new playlists b4: ${!NEW_PLAYLISTS[@]}"
    for i in "${!NEW_PLAYLISTS[@]}"; do
      if [ "$i" != 0 ]; then
        echo
        echo "Current order:"
      fi
       print_playlists RESTORED_ORDER
      # echo "new playlists: ${NEW_PLAYLISTS[@]}"
      echo "i: ${i}"
      echo
      echo "($((i+1))/${#NEW_PLAYLISTS[@]}) New playlist: \"${NEW_PLAYLISTS[i]}\" After which playlist should it go?"
      read -r pos
      pos=${pos:-0}  # Default to 0 if empty [web:16]

      # Insert: slice before pos + item + slice from pos onward [web:14][web:21]
      RESTORED_ORDER=(
        "${RESTORED_ORDER[@]:0:$pos}"
        "${NEW_PLAYLISTS[i]}"
        "${RESTORED_ORDER[@]:$pos}"
      )
    done
    echo
    echo "Final order:"
    print_playlists RESTORED_ORDER
    apply_order RESTORED_ORDER
  fi
else

  # Show numbered list
  echo "Found ${#PLAYLISTS[@]} playlist file(s):"
  for i in "${!PLAYLISTS[@]}"; do
    printf "  %2d) %s\n" "$((i+1))" "${PLAYLISTS[i]}"
  done

  # Prompt for new order
  echo
  echo "Enter the new order as space‑separated numbers (e.g. '3 1 2 …'):"
  read -ra ORDER

  # Validate count matches
  if [ "${#ORDER[@]}" -ne "${#PLAYLISTS[@]}" ]; then
    echo "❌ You entered ${#ORDER[@]} indices, but there are ${#PLAYLISTS[@]} files."
    exit 1
  fi

  # Build reordered array
  declare -a NEW_ORDERED
  for idx in "${ORDER[@]}"; do
    if ! [[ "$idx" =~ ^[0-9]+$ ]] \
       || [ "$idx" -lt 1 ] || [ "$idx" -gt "${#PLAYLISTS[@]}" ]; then
      echo "❌ Invalid index: '$idx'"
      exit 1
    fi
    NEW_ORDERED+=("${PLAYLISTS[$((idx-1))]}")
  done

  apply_order NEW_ORDERED
fi
