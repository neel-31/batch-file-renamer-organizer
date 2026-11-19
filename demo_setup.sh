#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
WORK="$ROOT/demo_workspace"
# Only reset a workspace with this exact project-local name.
rm -rf -- "$WORK"
mkdir -p -- "$WORK"
printf 'Monthly project notes\n' > "$WORK/Project Notes.txt"
printf 'Invoice example\n' > "$WORK/Invoice 01.pdf"
printf 'Student list\n' > "$WORK/student data.csv"
printf 'Draft document\n' > "$WORK/draft:report?.txt"
printf 'No-extension sample\n' > "$WORK/README_sample"
printf 'Another note\n' > "$WORK/meeting notes.txt"
printf 'A photo placeholder for demonstration\n' > "$WORK/holiday.jpg"
printf 'Demo workspace recreated. Files: %s\n' "$WORK"
ls -1 -- "$WORK"
