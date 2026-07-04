---
name: file-naming-normalization
description: Normalizes asset filenames by splitting on common separators, stripping asset IDs and optional user strings from each segment, then joining with hyphens. Use when normalizing asset filenames, batch-renaming SFX/UI textures, file naming normalization, asset naming convention, slug normalization, or kebab-case asset names.
---

# File Naming Normalization

Normalize asset filenames: split → clean each segment → join with `-`.

## Rules

When this skill applies, read and follow [skill-dependency-manager](../../rules/skill-dependency-manager.md) — run scripts as documented, install missing tools into `.dependency/`.

## Quick Start

Default: split on `_`, `-`, `.`, and spaces; strip leading/trailing digits from each segment; join with `-`:

```bash
.dependency/python/python .cursor/skills/file-naming-normalization/scripts/normalize.py path/to/file_or_folder
```

Preview without renaming:

```bash
.dependency/python/python .cursor/skills/file-naming-normalization/scripts/normalize.py Audio/SFX --dry-run
```

## Workflow

1. **Split** the filename stem (extension is preserved) on common separators: `_`, `-`, `.`, whitespace.
2. **Clean** each segment:
   - Drop pure-digit segments with 4+ digits (asset IDs like `38126`)
   - Keep short pure-digit segments as variant indices (`1`, `2`, `01`)
   - Remove leading digits from mixed segments (`001Hero` → `Hero`)
   - Remove trailing digits from mixed segments (`Attack02` → `Attack`, `foisal72` → `foisal`)
   - Remove user-given strings (see `--strip`)
3. **Drop** empty segments after cleaning.
4. **Join** remaining segments with `-`.
5. **Rename** in place (or write to `--output-dir`).

## Examples

| Input | Output |
|-------|--------|
| `001_Hero_Attack_02.wav` | `Hero-Attack.wav` |
| `sfx-button-click.mp3` | `sfx-button-click.mp3` (already hyphenated; digits only stripped per segment) |
| `UI 12 Panel Open.png` | `UI-Panel-Open.png` |
| `freesound_community-shoot-1-81135.wav` | `freesound-community-shoot-1.wav` |
| `SFX_001_button.wav` with `--strip SFX` | `button.wav` |

```bash
# Strip custom strings (repeatable)
.dependency/python/python .cursor/skills/file-naming-normalization/scripts/normalize.py Assets --strip SFX --strip UI

# Recursive folder
.dependency/python/python .cursor/skills/file-naming-normalization/scripts/normalize.py Assets -r

# Copy normalized files to another folder (originals unchanged)
.dependency/python/python .cursor/skills/file-naming-normalization/scripts/normalize.py Assets -o normalized/ -r
```

## Common Flags

`-r` / `--recursive` · `--strip TEXT` (repeatable) · `--strip-case-insensitive` · `-o` / `--output-dir` · `--dry-run` · `--overwrite`

## Agent Notes

1. Use the bundled script; do not hand-write rename loops unless the script cannot cover the case.
2. Always run `--dry-run` first when normalizing many files; show the user the preview.
3. `--strip` removes the given substring anywhere inside each segment (not only at edges). Pass one `--strip` per string.
4. Segments that become empty after cleaning are dropped (`001` alone → skipped).
5. Collisions (two files mapping to the same name) abort with an error — resolve manually or normalize in smaller batches.
6. Only renames files; does not rename directories.
