---
name: image-trim
description: >-
  Trims invalid border regions (transparent or solid-color padding) from images
  using Pillow. Default crop preserves the source aspect ratio. Use when the user
  wants image trim, crop empty borders, remove transparent margins, trim white
  padding, auto-crop sprites, or tighten cutouts before Godot import.
---

# Image Trim

Remove **invalid border padding** — transparent margins, flat white/green edges, or unused canvas space — with **Pillow**. **Default: preserve the source aspect ratio** so trimmed sprites stay proportionally consistent with the original frame.

Unlike `--crop` on [image-remove-white-background](../image-remove-white-background/SKILL.md) (tight alpha bbox only), this skill expands the crop box to match the original width:height ratio while removing as much empty area as possible.

## Rules

When this skill applies, read and follow [skill-dependency-manager](../../rules/skill-dependency-manager.md) — run scripts as documented, install missing tools into `.dependency/`.

- Run `trim.py` through the **`image-trim` manifest entry** (`.dependency/image-trim/.venv/`). Never use host `python`, `py`, `python3`, or any interpreter outside `.dependency/`.
- Do not hand-write ImageMagick / FFmpeg crop commands — use the bundled script.
- `populated: false` for `image-trim` is not a reason to skip. Install first, set `populated: true`, retry the same command.
- Pass the input path as-is. Output goes to `<input>/trimmed/` by default — no path rewriting; **never overwrite sources**.
- **Crop only** — preserve source pixel data and alpha; never composite onto black/white or fill background colors.
- Output filenames keep the **original asset name** (e.g. `bullet_speed.png`). Cursor chat attachment paths like `empty-window_images_bullet_speed-<uuid>.png` are shortened automatically.

## Setup (first run)

From project root:

```bash
.dependency/python/python -m venv .dependency/image-trim/.venv
.dependency/image-trim/.venv/Scripts/python -m pip install Pillow
```

Register in `.dependency/manifest.json`:

```json
"image-trim": {
  "populated": true,
  "bin": ".dependency/image-trim/.venv/Scripts/python.exe"
}
```

Use `bin/python` on Unix.

## Quick Start

**Default: create a `trimmed/` folder under the input path** and write outputs there:

```bash
# Auto-detect transparent or solid-color borders (default)
.dependency/image-trim/.venv/Scripts/python .cursor/skills/image-trim/scripts/trim.py image/sprites/hero.png

# Directory batch
.dependency/image-trim/.venv/Scripts/python .cursor/skills/image-trim/scripts/trim.py image/sprites -r

# Preview without writing
.dependency/image-trim/.venv/Scripts/python .cursor/skills/image-trim/scripts/trim.py image/sprites --dry-run
```

Custom output directory:

```bash
.dependency/image-trim/.venv/Scripts/python .cursor/skills/image-trim/scripts/trim.py image/sprites \
  --output-dir image/sprites_trimmed
```

## Detection Modes

| Mode | Behavior |
|------|----------|
| `auto` *(default)* | Use alpha when the image has transparency; otherwise sample corner color and trim solid borders |
| `alpha` | Trim only by alpha — pixels above `--alpha-threshold` count as content |
| `color` | Trim pixels matching `--color` (or corner sample) within `--tolerance` |

```bash
# Force alpha-only trim on RGBA cutouts
.dependency/image-trim/.venv/Scripts/python .cursor/skills/image-trim/scripts/trim.py image/cutout.png --mode alpha

# Trim white padding on opaque JPG/PNG
.dependency/image-trim/.venv/Scripts/python .cursor/skills/image-trim/scripts/trim.py image/foo.jpg --mode color --color FFFFFF
```

## Defaults

| Option | Default | Notes |
|--------|---------|-------|
| Output | `<input-path>/trimmed/` | Use `--output-dir` for a custom path |
| Aspect ratio | **Preserve source** | Pass `--tight` for tight bbox crop (no aspect lock) |
| `--mode` | `auto` | `alpha` for transparent PNGs; `color` for flat backgrounds |
| `--alpha-threshold` | `10` | Lower = stricter transparency detection |
| `--tolerance` | `25` | Color distance for solid-border trim |
| `--padding` | `0` | Extra pixels kept around detected content |
| `--pattern` | `*.png` | Also matches `.jpg`, `.jpeg`, `.webp`, `.bmp` |
| Overwrite | off | Pass `--overwrite` to replace existing outputs |

## Aspect Ratio Behavior

**Default (preserve source):** After detecting the content bounding box, the script expands the crop rectangle to the **same width:height ratio as the source image**, centered on the content. This removes empty borders while keeping frame proportions stable for animation sheets and UI assets.

**Tight crop (`--tight`):** Crop exactly to the content bbox (plus `--padding`) — same behavior as `--crop` on background-removal skills.

```bash
# Tight crop — smallest rectangle around content
.dependency/image-trim/.venv/Scripts/python .cursor/skills/image-trim/scripts/trim.py image/sprites/hero.png --tight

# Keep 4 px breathing room, still preserve aspect ratio
.dependency/image-trim/.venv/Scripts/python .cursor/skills/image-trim/scripts/trim.py image/sprites -r --padding 4
```

## Agent Workflow

1. **Pick skill** — remove padding/margins → this skill; remove backgrounds → [image-remove-white-background](../image-remove-white-background/SKILL.md) or [image-remove-background](../image-remove-background/SKILL.md).
2. **Paths** — Pass whatever path the user gives. Output lands in `trimmed/` next to that input.
3. **Trial first** — run on 1 image, inspect dimensions before batch.
4. **After background removal** — run on `transparent/` outputs to drop excess transparent canvas.
5. **Revert** — delete output folder or `git restore`; sources are never modified.

## Troubleshooting

| Issue | Fix |
|-------|-----|
| `image-trim` missing in manifest | Follow **Setup**; update manifest |
| Nothing trimmed | Content may already fill the canvas; try `--mode color` with `--color` |
| Too much removed | Lower `--tolerance` or `--alpha-threshold`; add `--padding` |
| Borders remain | Raise `--tolerance`; use `--mode color` with explicit `--color` |
| Distorted proportions after trim | Do **not** pass `--tight` unless user wants tight bbox |
| JPEG saved with wrong mode | Script converts RGBA → RGB automatically for `.jpg` output |
| Output has black instead of transparency | Source may be JPEG data saved with a `.png` extension (Cursor attachments) — re-supply the original RGBA PNG |
| Long Cursor attachment filenames | Script auto-renames to the embedded asset name (`bullet_speed.png`, etc.) |

