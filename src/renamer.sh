#!/usr/bin/env bash
# Batch File Renamer & Organizer — beginner-friendly USP mini project.
# Requires Bash 4+ and common GNU/Linux tools (mv, basename, dirname, date).
set -u
shopt -s nullglob dotglob

usage() {
  cat <<'HELP'
Batch File Renamer and Organizer
Usage: bash src/renamer.sh --directory PATH [OPTIONS]

Required:
  --directory PATH       Folder whose top-level files will be processed
Options:
  --pattern GLOB         Match filenames (default: *). Quote the pattern.
  --mode MODE            extension | date | none (default: extension)
  --prefix TEXT          Add text before the filename
  --suffix TEXT          Add text before the file extension
  --find TEXT            Replace this literal text in the filename
  --replace TEXT         Replacement for --find (default: empty)
  --log PATH             TSV log for changes made by --apply
  --apply                Move files; without this flag, preview ONLY
  --help                 Show help

Examples:
  bash src/renamer.sh --directory sample_files --pattern '*.txt' --prefix 'new_'
  bash src/renamer.sh --directory sample_files --pattern '*.txt' --prefix 'new_' --apply
  bash src/renamer.sh --directory sample_files --mode date --apply
HELP
}

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname -- "$SCRIPT_DIR")"
directory=''
pattern='*'
mode='extension'
prefix=''
suffix=''
find_text=''
replace_text=''
apply=0
log_path="$PROJECT_DIR/logs/operations.tsv"

while (($#)); do
  case "$1" in
    --directory|--pattern|--mode|--prefix|--suffix|--find|--replace|--log)
      option="$1"
      if (($# < 2)); then echo "ERROR: Missing value for $option" >&2; exit 2; fi
      case "$option" in
        --directory) directory="$2";;
        --pattern) pattern="$2";;
        --mode) mode="$2";;
        --prefix) prefix="$2";;
        --suffix) suffix="$2";;
        --find) find_text="$2";;
        --replace) replace_text="$2";;
        --log) log_path="$2";;
      esac
      shift 2;;
    --apply) apply=1; shift;;
    --help|-h) usage; exit 0;;
    *) echo "ERROR: Unknown option: $1" >&2; usage >&2; exit 2;;
  esac
done

if [[ -z "$directory" || ! -d "$directory" ]]; then
  echo 'ERROR: Provide a valid folder with --directory.' >&2; exit 2
fi
case "$mode" in extension|date|none) ;; *) echo 'ERROR: --mode must be extension, date or none.' >&2; exit 2;; esac
# Bash string substitution requires a non-empty search string.
if [[ -z "$find_text" && -n "$replace_text" ]]; then
  echo 'ERROR: --replace requires a non-empty --find.' >&2; exit 2
fi
# Convert the folder to an absolute path to make move/log output unambiguous.
directory="$(cd -- "$directory" && pwd -P)"

# Convert characters unsafe on Windows into underscores for portable names.
# Do not use external sed; demonstrate Bash parameter expansion and loops.
sanitize() {
  local raw="$1" result='' ch i
  for ((i=0; i<${#raw}; i++)); do
    ch="${raw:i:1}"
    case "$ch" in
      '<'|'>'|':'|'"'|'/'|'\'|'|'|'?'|'*') result+='_' ;;
      $'\t'|$'\n'|$'\r') result+='_' ;;
      *) result+="$ch" ;;
    esac
  done
  # Avoid trailing spaces/dots that are invalid in Windows paths.
  while [[ "$result" == *' ' || "$result" == *'.' ]]; do result="${result%?}"; done
  [[ -n "$result" && "$result" != '.' && "$result" != '..' ]] || result='unnamed'
  printf '%s' "$result"
}

# Keep logs readable if a filename contains special whitespace.
log_safe() { local value="$1"; value="${value//$'\t'/ }"; value="${value//$'\n'/ }"; value="${value//$'\r'/ }"; printf '%s' "$value"; }

# Avoid processing the log itself if it is stored inside the input directory.
log_parent="$(dirname -- "$log_path")"
mkdir_log=0
if ((apply)); then
  if ! mkdir -p -- "$log_parent"; then echo 'ERROR: Cannot create log folder.' >&2; exit 2; fi
  log_path="$(cd -- "$log_parent" && pwd -P)/$(basename -- "$log_path")"
  if [[ ! -f "$log_path" ]]; then printf 'timestamp\told_path\tnew_path\tstatus\n' > "$log_path" || exit 2; fi
fi

declare -A planned_targets=()
matched=0; ready=0; collisions=0; skipped=0; moved=0; errors=0
printf 'MODE: %s | ORGANIZE: %s | FOLDER: %s\n' "$([[ $apply -eq 1 ]] && echo APPLY || echo PREVIEW)" "$mode" "$directory"

for source in "$directory"/*; do
  [[ -f "$source" && ! -L "$source" ]] || continue
  [[ "$source" != "$log_path" ]] || continue
  name="$(basename -- "$source")"
  [[ "$name" == $pattern ]] || continue  # glob pattern matching (not regex)
  ((matched+=1))

  # Split a name into stem and extension, preserving the extension.
  stem="$name"; ext=''
  if [[ "$name" == *.* && "$name" != .* ]]; then
    stem="${name%.*}"
    ext=".${name##*.}"
  fi
  if [[ -n "$find_text" ]]; then stem="${stem//"$find_text"/$replace_text}"; fi
  clean_stem="$(sanitize "${prefix}${stem}${suffix}")"
  # Extension characters are also cleaned; extension case is preserved in filename.
  clean_ext=''
  [[ -z "$ext" ]] || clean_ext=".$(sanitize "${ext#.}")"
  new_name="$clean_stem$clean_ext"

  case "$mode" in
    extension)
      if [[ -z "$ext" ]]; then folder='no_extension'
      else folder="$(sanitize "${ext#.}")"; folder="${folder,,}"; fi;;
    date) folder="$(date -r "$source" '+%Y-%m-%d')" || { echo "ERROR: Cannot read date: $name" >&2; ((errors+=1)); continue; };;
    none) folder='';;
  esac
  if [[ -n "$folder" ]]; then target="$directory/$folder/$new_name"
  else target="$directory/$new_name"; fi

  # Prevent overwrites, including two input files resolving to one destination.
  if [[ "$target" == "$source" ]]; then
    printf 'SKIP      %s (already has target name)\n' "$name"; ((skipped+=1)); continue
  fi
  if [[ -e "$target" || -L "$target" || -n "${planned_targets[$target]+yes}" ]]; then
    printf 'COLLISION %s -> %s (not changed)\n' "$name" "$target"
    ((collisions+=1)); continue
  fi
  planned_targets["$target"]=1
  ((ready+=1))
  if (( !apply )); then
    printf 'PREVIEW   %s -> %s\n' "$name" "$target"
    continue
  fi
  if [[ -n "$folder" ]] && ! mkdir -p -- "$directory/$folder"; then
    printf 'ERROR     Could not create destination folder: %s\n' "$folder" >&2
    ((errors+=1)); continue
  fi
  # -n: never overwrite an existing destination. -T: treat target as file.
  # Verify after move because `mv -n` can report success even if it skipped.
  if mv -n -T -- "$source" "$target" && [[ ! -e "$source" && -f "$target" ]]; then
    printf 'MOVED     %s -> %s\n' "$name" "$target"
    printf '%s\t%s\t%s\tMOVED\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$(log_safe "$source")" "$(log_safe "$target")" >> "$log_path"
    ((moved+=1))
  else
    printf 'ERROR     Could not move %s (source unchanged or destination appeared)\n' "$name" >&2
    ((errors+=1))
  fi
done
printf 'SUMMARY: matched=%d ready=%d moved=%d collisions=%d skipped=%d errors=%d\n' "$matched" "$ready" "$moved" "$collisions" "$skipped" "$errors"
if ((apply)); then printf 'LOG: %s\n' "$log_path"; fi
((errors == 0 && collisions == 0))