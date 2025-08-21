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
NAMES=( $(jq -r '.[] | select(.oses[] | test("linux"; "i")) | .name' "$TMP_JSON") )
URLS=( $(jq -r '.[] | select(.oses[] | test("linux"; "i")) | .url' "$TMP_JSON") )
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
  read -p "Select a script to view details or run (number): " CHOICE
  if [[ "$CHOICE" == "q" ]]; then
    break
  fi
  if [[ "$CHOICE" =~ ^[0-9]+$ ]] && [ "$CHOICE" -ge 1 ] && [ "$CHOICE" -le "$COUNT" ]; then
    IDX=$((CHOICE-1))
    NAME="${NAMES[$IDX]}"
    URL="${URLS[$IDX]}"
    echo "\nName: $NAME"
    echo "URL: $URL"
    read -p "Run this script now? (y/n): " RUN
    if [[ "$RUN" == "y" ]]; then
      echo "Running $NAME..."
      curl -s "$URL" | bash
    fi
  else
    echo "Invalid selection."
  fi
  echo ""
done
rm "$TMP_JSON"
