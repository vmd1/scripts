#!/bin/bash
# Linux Script Menu for sc.vmd1.dev
set -e

SCRIPTS_URL="https://sc.vmd1.dev/scripts.json"
TMP_JSON="/tmp/scripts.json.$$"

# Download scripts.json
curl -s "$SCRIPTS_URL" -o "$TMP_JSON"
if [ ! -s "$TMP_JSON" ]; then
  echo "Failed to download scripts.json or file is empty."
  exit 1
fi

# Parse and filter for Linux scripts
mapfile -t NAMES < <(jq -r '.[] | select(.oses[] | test("linux"; "i")) | .name' "$TMP_JSON")
mapfile -t URLS < <(jq -r '.[] | select(.oses[] | test("linux"; "i")) | .url' "$TMP_JSON")
COUNT=${#NAMES[@]}

if [ "$COUNT" -eq 0 ]; then
  echo "No Linux scripts available."
  rm "$TMP_JSON"
  exit 0
fi

while true; do
  echo "Available Linux Scripts:"
  for i in "${!NAMES[@]}"; do
    echo "$((i+1)). ${NAMES[$i]}"
  done
  echo "q. Quit"
  read -p "Select a script to view details or run (number or comma-separated list): " CHOICE
  if [[ "$CHOICE" == "q" ]]; then
    break
  fi

  # Remove whitespace and split comma-separated selections
  CHOICE="${CHOICE//[[:space:]]/}"
  IFS=',' read -ra SEL <<< "$CHOICE"

  VALID_IDX=()
  for item in "${SEL[@]}"; do
    if [[ "$item" =~ ^[0-9]+$ ]] && [ "$item" -ge 1 ] && [ "$item" -le "$COUNT" ]; then
      VALID_IDX+=( $((item-1)) )
    else
      echo "Invalid selection: $item"
    fi
  done

  if [ ${#VALID_IDX[@]} -eq 0 ]; then
    echo "Invalid selection."
    echo ""
    continue
  fi

  printf "\nSelected scripts:\n"
  for idx in "${VALID_IDX[@]}"; do
    echo "$((idx+1)). ${NAMES[$idx]}"
    printf "   URL: %s\n" "${URLS[$idx]}"
  done

  read -p "Run the selected script(s) now? (y/n): " RUN
  if [[ "$RUN" == "y" ]]; then
    for idx in "${VALID_IDX[@]}"; do
      NAME="${NAMES[$idx]}"
      URL="${URLS[$idx]}"
      echo "Running $NAME..."
      curl -s "$URL" | bash
    done
  fi
  echo ""
done
rm "$TMP_JSON"
