---
name: image-to-png
description: Converts image files to PNG using FFmpeg while preserving dimensions and alpha. Use when the user wants to convert images to PNG, transcode JPG/WebP/GIF/BMP/TIFF to PNG, batch-export game/UI textures, or mentions PNG conversion without background removal.
---

# Image to PNG

Convert supported image formats to **lossless PNG** via FFmpeg. **Defaults preserve source quality** — dimensions unchanged, alpha channel kept when present.

## Rules

When this skill applies, read and follow [skill-dependency-manager](../../rules/skill-dependency-manager.md) — run scripts as documented, install missing tools into `.dependency/`.

## Quick Start

Convert a file or folder, output to `png/`:

```bash
.dependency/python/python .cursor/skills/image-to-png/scripts/convert.py path/to/image_or_folder
```

Example: `assets/ui/icon.webp` → `assets/ui/png/icon.png`

Batch with subfolders:

```bash
.dependency/python/python .cursor/skills/image-to-png/scripts/convert.py assets/textures -r
```

## Format Defaults

| Setting | Default | Notes |
|---------|---------|-------|
| Dimensions | Preserve source | No resize unless user asks separately |
| Alpha | Preserve | RGBA when source has transparency |
| Already PNG | Stream copy | Bit-perfect when no overrides |
| Animated GIF | First frame | Multi-frame GIF export not supported |

## Common Flags

`-r` · `-o` / `--output-dir` · `--strip-alpha` · `--dry-run` · `--overwrite`

Strip alpha (RGB output):

```bash
.dependency/python/python .cursor/skills/image-to-png/scripts/convert.py assets/sprites -r --strip-alpha
```

Custom output directory:

```bash
.dependency/python/python .cursor/skills/image-to-png/scripts/convert.py assets/ui -o assets/ui_png --dry-run
```

**Never overwrite source files.** The script writes only to `png/` (or `-o`). Supported inputs: `.jpg`, `.jpeg`, `.png`, `.webp`, `.gif`, `.bmp`, `.tif`, `.tiff`, `.avif`, `.ico`.

## Agent Notes

1. Use the bundled script, not hand-written `ffmpeg -i …` commands.
2. **Do not resize or recompress** unless the user explicitly asks — omit quality/size overrides.
3. **Already PNG?** Stream-copied by default (no generation loss).
4. Missing Python/FFmpeg → populate `.dependency/` per skill-dependency-manager, retry same command.
5. **Do not copy, move, or replace the source with converted output** — tell the user where `png/` files are; they swap assets manually when ready.
6. Need **transparent cutouts** → use [image-remove-background](../image-remove-background/SKILL.md), not this skill.
7. FFmpeg codec and probing details: [reference.md](reference.md)
