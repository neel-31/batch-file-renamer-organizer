#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT="$ROOT/src/renamer.sh"
TMP="$(mktemp -d)"
trap 'rm -rf -- "$TMP"' EXIT
pass=0
check() { if eval "$2"; then printf 'PASS: %s\n' "$1"; ((pass+=1)); else printf 'FAIL: %s\n' "$1"; exit 1; fi; }
mkdir -p "$TMP/a"
printf 'hello\n' > "$TMP/a/My Report.txt"
preview="$(bash "$SCRIPT" --directory "$TMP/a" --pattern '*.txt' --prefix 'final_' --mode extension)"
check 'preview does not move file' '[[ -f "$TMP/a/My Report.txt" && ! -d "$TMP/a/txt" ]]'
bash "$SCRIPT" --directory "$TMP/a" --pattern '*.txt' --prefix 'final_' --mode extension --log "$TMP/log.tsv" --apply >/dev/null
check 'extension grouping + prefix' '[[ -f "$TMP/a/txt/final_My Report.txt" ]]'
check 'logging contains old/new path' 'grep -q "My Report.txt" "$TMP/log.tsv" && grep -q "final_My Report.txt" "$TMP/log.tsv"'
printf x > "$TMP/a/old:name?.csv"
bash "$SCRIPT" --directory "$TMP/a" --pattern '*.csv' --mode none --apply --log "$TMP/log.tsv" >/dev/null
check 'invalid characters sanitized' '[[ -f "$TMP/a/old_name_.csv" ]]'
printf x > "$TMP/a/alpha.txt"; mkdir -p "$TMP/a/txt"; printf x > "$TMP/a/txt/alpha.txt"
if bash "$SCRIPT" --directory "$TMP/a" --pattern 'alpha.txt' --mode extension --apply --log "$TMP/log.tsv" > "$TMP/collision.txt"; then exit 1; fi
check 'existing-target collision skipped' '[[ -f "$TMP/a/alpha.txt" && -f "$TMP/a/txt/alpha.txt" ]]'
printf x > "$TMP/a/one.txt"; printf x > "$TMP/a/two.txt"
if bash "$SCRIPT" --directory "$TMP/a" --pattern '*.txt' --find 'one' --replace 'two' --mode extension > "$TMP/preview_collision.txt"; then :; fi
check 'preview shows a target collision' 'grep -q COLLISION "$TMP/preview_collision.txt"'
printf x > "$TMP/a/report.pdf"
bash "$SCRIPT" --directory "$TMP/a" --pattern '*.pdf' --mode date --apply --log "$TMP/log.tsv" > "$TMP/date.txt"
check 'date grouping' 'compgen -G "$TMP/a/????-??-??/report.pdf" >/dev/null'
printf x > "$TMP/a/keep.md"
bash "$SCRIPT" --directory "$TMP/a" --pattern '*.pdf' --mode none --apply --log "$TMP/log.tsv" >/dev/null
check 'pattern excludes other extensions' '[[ -f "$TMP/a/keep.md" ]]'
printf 'TOTAL: %s tests passed\n' "$pass"
