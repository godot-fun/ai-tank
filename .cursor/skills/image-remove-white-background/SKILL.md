---
name: image-remove-white-background
description: >-
  Removes solid-color backgrounds (white, green #00FF00, magenta #FF00FF) from
  AI-generated images using color key and border flood fill — not AI matting.
  Use when rembg over-removes foreground, for flat white/green/magenta backgrounds,
  color key cutout, 白底抠图, 绿幕, or chroma key before Godot sprite import.
---

# Image Remove White / Chroma Background

Remove **flat solid-color backgrounds** with **color key + border flood fill**. Output is **RGBA PNG** with transparency — ready for Godot sprites and UI.

Unlike [image-remove-background](../image-remove-background/SKILL.md) (rembg AI matting), this skill **only removes pixels that match the key color**. It does not guess what is "subject" vs "background", so white clothing, props, and effects are preserved unless they touch the outer background through matching pixels.

## Rules

When this skill applies, read and follow [skill-dependency-manager](../../rules/skill-dependency-manager.md) — run scripts as documented, install missing tools into `.dependency/`.

- Run `remove_white_bg.py` through the **`image-remove-white-background` manifest entry** (`.dependency/image-remove-white-background/.venv/`). Never use host `python`, `py`, `python3`, or any interpreter outside `.dependency/`.
- Do not hand-write FFmpeg `colorkey` / ImageMagick commands — use the bundled script.
- `populated: false` for `image-remove-white-background` is not a reason to skip. Install first, set `populated: true`, retry the same command.
- Pass the input path as-is (chat attachment path, `Downloads/foo.png`, project folder, etc.). Output goes to `<input>/transparent/` by default — no path rewriting.

## Setup (first run)

From project root:

```bash
.dependency/python/python -m venv .dependency/image-remove-white-background/.venv
.dependency/image-remove-white-background/.venv/Scripts/python -m pip install Pillow
```

Register in `.dependency/manifest.json`:

```json
"image-remove-white-background": {
  "populated": true,
  "bin": ".dependency/image-remove-white-background/.venv/Scripts/python.exe"
}
```

Use `bin/python` on Unix.

## Quick Start

**Default: create a `transparent/` folder under the input path** and write outputs there (never overwrites sources):

```bash
# White AI background (default preset)
.dependency/image-remove-white-background/.venv/Scripts/python .cursor/skills/image-remove-white-background/scripts/remove_white_bg.py image/sprites/hero.png

# Green screen (#00FF00) — recommended for future AI generation
.dependency/image-remove-white-background/.venv/Scripts/python .cursor/skills/image-remove-white-background/scripts/remove_white_bg.py image/sprites/hero.png --preset green

# Magenta screen (#FF00FF)
.dependency/image-remove-white-background/.venv/Scripts/python .cursor/skills/image-remove-white-background/scripts/remove_white_bg.py image/sprites/hero.png --preset magenta

# Directory batch
.dependency/image-remove-white-background/.venv/Scripts/python .cursor/skills/image-remove-white-background/scripts/remove_white_bg.py image/sprites -r
```

Custom output directory:

```bash
.dependency/image-remove-white-background/.venv/Scripts/python .cursor/skills/image-remove-white-background/scripts/remove_white_bg.py image/sprites \
  --output-dir image/sprites_cutout
```

## Presets

| Preset | Key color | Default tolerance | Best for |
|--------|-----------|-------------------|----------|
| `white` *(default)* | `#FFFFFF` | 25 | AI images with pure/near-white backgrounds |
| `green` | `#00FF00` | 40 | Green-screen AI prompts (recommended) |
| `magenta` | `#FF00FF` | 40 | Magenta-screen AI prompts |

Custom key color:

```bash
.dependency/image-remove-white-background/.venv/Scripts/python .cursor/skills/image-remove-white-background/scripts/remove_white_bg.py image/foo.png \
  --color F0F0F0 --tolerance 20
```

## Modes

| Mode | Behavior |
|------|----------|
| `global` *(default)* | Removes **all** pixels matching the key color. Best when the subject has no same-color interior details to preserve. |
| `both` | Union of `border` and `center` — removes background connected to edges **or** to the center. |
| `border` | Flood fill from image edges only — keeps isolated white areas not reachable from edges or center (e.g. white shirt interior). |
| `center` | Flood fill from the **image center** outward — removes key-color regions reachable from the middle. |

```bash
# Center-out flood (interior white holes)
... remove_white_bg.py image/foo.png --mode center

# Edge + center without removing every white pixel
... remove_white_bg.py image/foo.png --mode both
```

## Defaults

| Option | Default | Notes |
|--------|---------|-------|
| Output | `<input-path>/transparent/` | Use `--output-dir` for a custom path |
| `--preset` | `white` | `green` / `magenta` for chroma-screen AI art |
| `--mode` | `global` | Use `border` or `both` when same-color interior details must be preserved |
| `--tolerance` | preset-specific | Raise if background remnants remain; lower if foreground edges erode |
| `--feather` | 2 | Gaussian soft edge on alpha; `0` for hard edges |
| `--pattern` | `*.png` | Also matches `.jpg`, `.jpeg`, `.webp`, `.bmp` |
| `--crop` | off | Trim transparent borders after keying |
| Overwrite | off | Pass `--overwrite` to replace existing outputs |

## Agent workflow

1. **Pick skill** — flat solid background → this skill; complex/photo backgrounds → [image-remove-background](../image-remove-background/SKILL.md).
2. **Paths** — Pass whatever path the user gives or the chat `<image_files>` path directly. Output lands in `transparent/` next to that input.
3. **Trial first** — run on 1 image, inspect result before batch.
4. **Preset** — `white` for existing white-bg AI art; tell user to switch AI prompts to `--preset green` or `--preset magenta` going forward.
5. **Tolerance** — if halos remain, increase `--tolerance` by 5–10; if subject edges eat away, decrease it.
6. **Revert** — delete output folder or `git restore`; sources are never modified.

## Troubleshooting

| Issue | Fix |
|-------|-----|
| `image-remove-white-background` missing | Follow **Setup**; update manifest |
| Background remnants (gray fringe) | Increase `--tolerance`; try `--feather 3` |
| Subject edges eroded | Decrease `--tolerance`; ensure `--mode border` |
| White clothing removed | Switch to `--mode border` or `--mode both`; avoid `global` for characters with white details |
| Green spill on subject edges | Lower `--tolerance`; increase `--feather` slightly |
| Interior holes stay opaque | Try `--mode center` if the hole matches the key color at the image center; try `--mode both` for edge + center; otherwise `--mode global` only if safe, or fix in an editor |
| Center mode does nothing | Center pixel is not key color (subject sits in the middle) — use `border`, `both`, or split sprite sheets per frame |
| Wrong colors in JPEG | Prefer PNG from AI export; raise tolerance slightly for compression artifacts |

## Related

- AI matting (complex backgrounds): [image-remove-background](../image-remove-background/SKILL.md)
