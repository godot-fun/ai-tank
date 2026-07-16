---
name: image-remove-watermark-gemini
description: >-
  Remove Gemini AI sparkle watermarks from images using reverse alpha blending.
  Fast local batch processing for Google Gemini / Imagen / Nano Banana corner
  logos. Use when the user wants to remove Gemini watermarks, sparkle marks,
  or clean Gemini-generated images — not general watermarks.
---

# Image Remove Gemini Watermark

Remove the **Gemini sparkle logo** (bottom-right corner) with **[GeminiWatermarkTool](https://github.com/allenk/GeminiWatermarkTool)** — reverse alpha blending plus optional library cleanup (`--denoise soft/ai/...`) for residual sparkle edges on dark or textured backgrounds.

**Scope:** Gemini visible corner watermark only. Does **not** remove SynthID (invisible watermark), arbitrary logos, or non-Gemini marks.

## Rules

When this skill applies, read and follow [skill-dependency-manager](../../rules/skill-dependency-manager.md) — run scripts as documented, install missing tools into `.dependency/`.

- Run `remove_watermark.py` through **`.dependency/python/python.exe`**. The script calls the bundled **GeminiWatermarkTool** binary only. Never use host `python` or tools outside `.dependency/`.
- **Do not customize removal.** No custom alpha tuning — the wrapper handles paths/batch; pixel processing is delegated to GeminiWatermarkTool.
- `populated: false` is not a reason to skip. Install first, set `populated: true`, retry the same command.
- **Never overwrite sources.** Output goes into a `no-watermark/` subfolder beside each source image (same directory as the input file).
- **Never copy or move input images.** Pass the user's actual file or directory path (absolute paths are fine).
- **Never use Cursor attachment cache paths.** Chat-attached images are copied to `.cursor/projects/.../assets/` — that is not the user's source. Use the path the user provides (e.g. `C:\Users\...\Downloads\foo.png`) or ask if unclear.

## Setup (first run)

From project root, download [GeminiWatermarkTool v0.3.1](https://github.com/allenk/GeminiWatermarkTool/releases/tag/v0.3.1) for your platform and extract to `.dependency/gemini-watermark-tool/`:

| Platform | Release asset |
|----------|---------------|
| Windows | `GeminiWatermarkTool-Windows-x64.zip` → `GeminiWatermarkTool.exe` |
| Linux | `GeminiWatermarkTool-Linux-x64.zip` → `GeminiWatermarkTool` |
| macOS | `GeminiWatermarkTool-macOS-Universal.zip` → `GeminiWatermarkTool` |

Register in `.dependency/manifest.json`:

```json
"gemini-watermark": {
  "populated": true,
  "bin": ".dependency/gemini-watermark-tool/GeminiWatermarkTool.exe"
}
```

Use `GeminiWatermarkTool` (no `.exe`) on Unix. Dependencies: portable **GeminiWatermarkTool** binary only.

## Quick Start

**Default: create `<source-dir>/no-watermark/` next to each input file** (never overwrites sources):

```bash
# Single file — output beside the source
# C:\Users\...\Downloads\foo.png → C:\Users\...\Downloads\no-watermark\foo.png
.dependency/python/python.exe .cursor/skills/image-remove-watermark-gemini/scripts/remove_watermark.py C:\Users\...\Downloads\foo.png

# Project-relative path
.dependency/python/python.exe .cursor/skills/image-remove-watermark-gemini/scripts/remove_watermark.py image/title-screens/tank-battle-1.png
# → image/title-screens/no-watermark/tank-battle-1.png

# Directory batch (flat)
.dependency/python/python.exe .cursor/skills/image-remove-watermark-gemini/scripts/remove_watermark.py image/title-screens

# Recursive batch — each image gets its own sibling folder
.dependency/python/python.exe .cursor/skills/image-remove-watermark-gemini/scripts/remove_watermark.py image --recursive
```

Custom output folder name:

```bash
.dependency/python/python.exe .cursor/skills/image-remove-watermark-gemini/scripts/remove_watermark.py image/title-screens \
  --output-subdir clean
```

Shared output directory:

```bash
.dependency/python/python.exe .cursor/skills/image-remove-watermark-gemini/scripts/remove_watermark.py image/title-screens \
  --output-dir out
```

## Detection

GeminiWatermarkTool uses three-stage NCC detection with confidence scoring:

1. **Spatial / gradient / variance** — confidence threshold (default 25%)
2. **Profile selection** — V2 (Gemini 3.5+) by default; automatic V1 legacy fallback
3. **Optional cleanup** — gradient-masked inpaint or AI denoise on residual sparkle edges

| Profile | Small logo | Large logo | Notes |
|---------|------------|------------|-------|
| V2 (default) | 36×36 | 96×96 | Gemini 3.5+ shifted margins |
| V1 (legacy) | 48×48 | 96×96 | Pre-Gemini 3.5 outputs |

High-resolution example: 2752×1536 → 96×96 at (2464, 1248), profile V2.

## Options

| Option | Default | Notes |
|--------|---------|-------|
| Output folder | `<source-dir>/no-watermark/` per image | Sibling folder beside each input file |
| `--output-subdir` | `no-watermark` | Subfolder name beside each source file |
| `--output-dir` | *(none)* | Shared output root under input path |
| `--denoise` | `soft` | Cleanup: `ai`, `ns`, `telea`, `soft`, `off` |
| `--legacy` | off | Pin V1 profile only (pre-Gemini 3.5) |
| `--no-legacy` | off | Disable V2→V1 automatic fallback |
| `--json` | off | Print structured metadata per image |
| `--pattern` | `*.png` | Also matches `.jpg`, `.jpeg`, `.webp`, `.bmp` |
| `--recursive` | off | Search subdirectories |

```bash
# Default: reverse alpha + soft inpaint cleanup (CPU, no GPU required)
.dependency/python/python.exe .cursor/skills/image-remove-watermark-gemini/scripts/remove_watermark.py image/foo.png

# GPU-accelerated AI denoise (FDnCNN; falls back to ns without Vulkan)
.dependency/python/python.exe .cursor/skills/image-remove-watermark-gemini/scripts/remove_watermark.py image/foo.png --denoise ai

# Reverse alpha only, no cleanup pass
.dependency/python/python.exe .cursor/skills/image-remove-watermark-gemini/scripts/remove_watermark.py image/foo.png --denoise off

# Verbose metadata
.dependency/python/python.exe .cursor/skills/image-remove-watermark-gemini/scripts/remove_watermark.py image/foo.png --json
```

Direct CLI equivalent (single file):

```bash
.dependency/gemini-watermark-tool/GeminiWatermarkTool.exe -i input.png -o output.png --denoise soft --no-banner
```

## Agent workflow

1. **Confirm source** — inputs should be Gemini-generated images with the sparkle logo.
2. **Use the user's real path** — e.g. `C:\Users\...\Downloads\image.png`. Do **not** use Cursor chat attachment paths under `.cursor/projects/.../assets/`.
3. **Run on the user's path directly** — do not copy images into `image/` or other folders.
4. **Inspect output** — cleaned files appear in `<source-dir>/no-watermark/` beside the originals.
5. **Skipped images** — GWT exit code 1 means no watermark detected; check `--json` for `applied: false`.
6. **Revert** — delete the output folder; sources are never modified.

## Troubleshooting

| Issue | Fix |
|-------|-----|
| `GeminiWatermarkTool not found` | Download v0.3.1 release into `.dependency/gemini-watermark-tool/` |
| Watermark faint or halo | Try `--denoise ai` (GPU) or `--denoise telea` |
| Dark patch in corner | Use default `--denoise soft` (already on); avoid `--denoise off` on dark backgrounds |
| Legacy Gemini image skipped | Re-run with `--legacy` |
| Watermark not removed | Image may not be a Gemini visible watermark |

## Related

- Script: [scripts/remove_watermark.py](scripts/remove_watermark.py)
- Engine: [allenk/GeminiWatermarkTool](https://github.com/allenk/GeminiWatermarkTool)
- Algorithm write-up: [Reverse Alpha Blending (Medium)](https://allenkuo.medium.com/removing-gemini-ai-watermarks-a-deep-dive-into-reverse-alpha-blending-bbbd83af2a3f)
