# Batch File Renamer and Organizer

A beginner-friendly **Unix Shell Programming (USP)** project written in **Bash**. It renames files according to configurable rules and sorts them into folders based on **extension**, **last-modified date**, or **no organization**.

## Features

- Safe **preview mode** (default). Nothing changes until you add `--apply`.
- Filename matching using a shell **glob**, such as `*.txt` or `report*`.
- Prefix, suffix, and literal find/replace rules.
- Organization by extension (`txt/`, `pdf/`) or modification date (`YYYY-MM-DD/`).
- Detects collisions with existing destinations and destinations already planned in the batch.
- Replaces filename characters that are unsafe on Windows (`<>:"/\|?*`) and tabs/newlines with `_`.
- Creates a tab-separated **old path → new path** log during actual moves.
- Handles filenames with spaces by quoting path variables.
- Only processes **top-level regular files** inside the chosen folder; it does not recurse.

## Requirements

- Linux or **WSL (Ubuntu)** recommended; Bash 4+ and GNU `mv`, `date`, `basename`, `dirname`.
- On Windows, use WSL for predictable behavior; plain Command Prompt / PowerShell cannot directly run the Bash script.
- The script changes files; test with `demo_workspace`, not personal files.

## Quick start

```bash
# From the repository root:
bash demo_setup.sh
bash src/renamer.sh --directory demo_workspace --pattern '*.txt' --prefix 'USP_' --mode extension
# Read the PREVIEW output. Then execute:
bash src/renamer.sh --directory demo_workspace --pattern '*.txt' --prefix 'USP_' --mode extension --apply
# Examine log:
cat logs/operations.tsv
```

**Never add `--apply` unless the preview is correct.** Reset the demonstration with `bash demo_setup.sh`.

## More examples

```bash
# Organize all files by extension, with names unchanged
bash src/renamer.sh --directory demo_workspace --mode extension --apply

# Sort by modification date
bash demo_setup.sh
bash src/renamer.sh --directory demo_workspace --mode date --apply

# Rename only CSV files without creating subfolders
bash demo_setup.sh
bash src/renamer.sh --directory demo_workspace --pattern '*.csv' --find ' ' --replace '_' --suffix '_final' --mode none --apply

# Preview only PDFs
bash src/renamer.sh --directory demo_workspace --pattern '*.pdf' --mode none
```

## Command options

| Option | Meaning |
|---|---|
| `--directory PATH` | Required input folder |
| `--pattern GLOB` | Match top-level filenames; default `*` |
| `--mode extension\|date\|none` | Organization; default `extension` |
| `--prefix TEXT` | Text added before stem |
| `--suffix TEXT` | Text added before extension |
| `--find TEXT` | Literal text to replace in stem |
| `--replace TEXT` | Replacement; use with `--find` |
| `--log PATH` | Custom TSV output log; default `logs/operations.tsv` |
| `--apply` | Actually perform moves (omission means preview) |
| `--help` | Show help |

## Workflow

`Read arguments → Select matching files → Build safe target names → Choose folder → Detect collision → Preview or move → Log move`

### Example

Before: `Project Notes.txt`, `Invoice 01.pdf`  
Command: `bash src/renamer.sh --directory demo_workspace --prefix 'USP_' --mode extension --apply`  
After: `txt/USP_Project Notes.txt`, `pdf/USP_Invoice 01.pdf`.

## Testing

```bash
bash tests/test_renamer.sh
```

The tests cover preview safety, prefix + extension grouping, TSV logging, invalid filename cleaning, existing-target collisions, collision messages, date grouping, and glob matching.

## Known limitations

- Linux-focused; relies on GNU `mv -n -T` and GNU `date -r`.
- Operates on one folder level. It will not scan nested directories.
- Does not roll back completed moves automatically; the log helps identify changes.
- `--find` modifies the filename stem, not the extension.
- Matching uses case-sensitive Bash globs; extension folder labels are lowercased.
- Existing files are **never intentionally overwritten**. Concurrent filesystem changes may produce an error and should be rechecked.

## Course mapping

**CO2, CO3, CO5 | PO2, PO3, PO5 | SDG 9, SDG 12.** Shell concepts: globbing, parameter expansion, `basename`, `dirname`, `case`, loops, quoting, and `mv`.

## Submitted files

- `src/renamer.sh` — project implementation
- `demo_setup.sh` — resettable live demo input
- `tests/test_renamer.sh` — automated tests
- `docs/Project_Report.docx` / `.pdf` — detailed report
- `docs/Project_Presentation.pptx` — presentation
- `docs/Lecturer_Explanation_Guide.txt` — speaking guide and viva questions

Author details on report/slide title page can be filled in before submitting.