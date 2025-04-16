#!/bin/bash

set -e

DEFAULT_PROJECTS_DIR="$HOME/dev/projects"
PROJECTS_DIR="${1:-$DEFAULT_PROJECTS_DIR}"

echo "🧹 Starting Git housekeeping in: $PROJECTS_DIR"

if [[ ! -d "$PROJECTS_DIR" ]]; then
  echo "❌ Directory not found: $PROJECTS_DIR"
  exit 1
fi

for dir in "$PROJECTS_DIR"/*/
do
  dir=${dir%*/}
  echo "📁 Checking: ${dir}"

  if [[ -d "$dir/.git" ]]; then
    echo "🔧 Running git gc in ${dir}"
    (cd "$dir" && git gc --prune=now)
    echo "✅ Finished cleaning: ${dir}"
  else
    echo "⚠️ Skipped (not a Git repo): ${dir}"
  fi
done

echo "🏁 Git housekeeping complete!"
