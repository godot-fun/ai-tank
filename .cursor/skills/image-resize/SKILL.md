---
name: image-resize
description: Resizes images to explicit width and height using ImageMagick. Use when the user wants image resize, scale sprites/textures, batch-resize UI assets, set icon dimensions, or mentions ImageMagick resize — target size must be specified before running.
---

# Image Resize

Resize images to a **user-specified width and height** via **ImageMagick**. **Both dimensions are required** — do not run this skill until the user (or task) provides target pixel size.

## Rules

When this skill applies, read and follow [skill-dependency-manager](../../rules/skill-dependency-manager.md) — run scripts as documented, install missing tools into `.dependency/`.

- **Require target size first.** If width/height are missing, ask the user before running.
- Run `resize.py` through the bundled script — do not hand-write `magick -resize` commands.
- **Never overwrite source files.** Output goes to `resized/` (or `-o`) by default.
- `populated: false` for `imagemagick` is not a reason to skip. Install first, set `populated: true`, retry the same command.

## Setup (first run)

1. Download ImageMagick portable build from [imagemagick.org](https://imagemagick.org/script/download.php) and extract to `.dependency/imagemagick/`.

   Windows result example: `.dependency/imagemagick/magick.exe`

2. Register in `.dependency/manifest.json`:

```json
"imagemagick": {
  "populated": true,
  "bin": ".dependency/imagemagick/magick.exe"
}
```

Use `bin/magick` on Unix (no `.exe`).

## Quick Start

**Both `--width` and `--height` are required:**

```bash
.dependency/python/python .cursor/skills/image-resize/scripts/resize.py assets/sprites/hero.png --width 128 --height 128
```

Example: `assets/ui/icon.png` → `assets/ui/resized/icon.png` at 64×64

Batch with subfolders:

```bash
.dependency/python/python .cursor/skills/image-resize/scripts/resize.py assets/textures -r --width 256 --height 256
```

Preview without writing:

```bash
.dependency/python/python .cursor/skills/image-resize/scripts/resize.py assets/ui -r --width 32 --height 32 --dry-run
```

Custom output directory:

```bash
.dependency/python/python .cursor/skills/image-resize/scripts/resize.py assets/icons -o assets/icons_64 --width 64 --height 64
```

## Resize Modes

| Mode | Flag | Behavior |
|------|------|----------|
| `fit` *(default)* | `--mode fit` | Fit inside WxH, preserve aspect ratio (letterbox area unused) |
| `fill` | `--mode fill` | Cover WxH, center-crop overflow |
| `exact` | `--mode exact` | Force WxH, ignore aspect ratio |

```bash
# Fit within 128×128 (default — no distortion)
.dependency/python/python .cursor/skills/image-resize/scripts/resize.py assets/hero.png --width 128 --height 128

# Cover 128×128, crop center
.dependency/python/python .cursor/skills/image-resize/scripts/resize.py assets/hero.png --width 128 --height 128 --mode fill

# Stretch to exactly 128×128
.dependency/python/python .cursor/skills/image-resize/scripts/resize.py assets/hero.png --width 128 --height 128 --mode exact
```

## Defaults

| Option | Default | Notes |
|--------|---------|-------|
| `--width` / `--height` | **Required** | Must be positive integers |
| `--mode` | `fit` | `fill` or `exact` when user needs crop or stretch |
| Output | `<input-path>/resized/` | Use `--output-dir` for custom path |
| Overwrite | off | Pass `--overwrite` to replace existing outputs |
| Format | Same as source | Extension preserved (`.png`, `.jpg`, etc.) |

Supported inputs: `.jpg`, `.jpeg`, `.png`, `.webp`, `.gif`, `.bmp`, `.tif`, `.tiff`, `.avif`, `.ico`.

## Agent Workflow

1. **Confirm size** — get explicit width and height from the user (e.g. "128×128", "64 wide and 64 tall"). Do not guess from context unless the user already stated dimensions.
2. **Pick mode** — default `fit`; use `fill` for square thumbnails from non-square art; use `exact` only when the user accepts distortion.
3. **Trial first** — run on one image, verify dimensions before batch (`-r`).
4. **Paths** — pass whatever path the user gives; output lands in `resized/` next to that input.
5. **Revert** — delete output folder or `git restore`; sources are never modified.

## Agent Notes

1. Use the bundled script, not hand-written ImageMagick commands.
2. Missing Python/ImageMagick → populate `.dependency/` per skill-dependency-manager, retry same command.
3. **Do not copy, move, or replace the source with resized output** — tell the user where `resized/` files are.
4. Need **format conversion only** (no resize) → [image-to-png](../image-to-png/SKILL.md).
5. Need **trim borders** after resize → [image-trim](../image-trim/SKILL.md).

## Troubleshooting

| Issue | Fix |
|-------|-----|
| `imagemagick` missing in manifest | Follow **Setup**; update manifest |
| Missing `--width` / `--height` | Ask user for target size; both flags are required |
| Output larger/smaller than expected | Check `--mode` — `fit` preserves aspect inside the box |
| Distorted sprite | Switch from `exact` to `fit` or `fill` |
| Animated GIF | Only first frame is processed by default ImageMagick behavior |

