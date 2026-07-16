---
name: video-remove-watermark-gemini
description: >-
  Remove Gemini / Veo visible watermarks from videos using reverse alpha
  blending via GeminiWatermarkTool-Video (VeoWatermarkRemover). Supports
  1080p/720p diamond and Veo text watermarks, audio passthrough, optional ML
  assist. Use when the user wants to remove Gemini video watermarks, Veo
  watermarks, clean Google Flow / Veo / Gemini 3.5 generated MP4s — not general
  watermarks or SynthID.
---

# Video Remove Gemini Watermark

Remove **Gemini / Veo visible watermarks** from video with **[VeoWatermarkRemover](https://github.com/allenk/VeoWatermarkRemover)** (`GeminiWatermarkTool-Video`) — the video build of [GeminiWatermarkTool](https://github.com/allenk/GeminiWatermarkTool). Uses reverse alpha blending, adaptive per-frame intensity, and audio passthrough.

**Scope:** Gemini diamond, small "Veo" text (Google Flow), and legacy pre-Gemini-3.5 Veo text watermarks. Does **not** remove SynthID (invisible watermark), arbitrary logos, or non-Gemini marks.

## Rules

When this skill applies, read and follow [skill-dependency-manager](../../rules/skill-dependency-manager.md) — run scripts as documented, install missing tools into `.dependency/`.

- Run `remove_watermark.py` through **`.dependency/python/python.exe`**. The script calls the bundled **GeminiWatermarkTool-Video** binary only. Never use host `python` or tools outside `.dependency/`.
- **Do not customize removal.** No custom alpha tuning — the wrapper handles paths/batch; pixel processing is delegated to GeminiWatermarkTool-Video.
- `populated: false` is not a reason to skip. Install first, set `populated: true`, retry the same command.
- **Never overwrite sources.** Output goes into a `no-watermark/` subfolder beside each source video (same directory as the input file).
- **Never copy or move input videos.** Pass the user's actual file or directory path (absolute paths are fine).
- **Never use Cursor attachment cache paths.** Chat-attached files under `.cursor/projects/.../assets/` are not the user's source. Use the path the user provides or ask if unclear.

## Setup (first run)

From project root, download [VeoWatermarkRemover v0.6.4-demo](https://github.com/allenk/VeoWatermarkRemover/releases/tag/v0.6.4-demo) for your platform and extract to `.dependency/gemini-watermark-video-tool/`:

| Platform | Release asset |
|----------|---------------|
| Windows | `GeminiWatermarkTool-Windows-x64-Video.zip` → `GeminiWatermarkTool-Video.exe` |
| Linux | `GeminiWatermarkTool-Linux-x64-Video.zip` → `GeminiWatermarkTool-Video` |
| macOS | `GeminiWatermarkTool-macOS-Universal-Video.zip` → `GeminiWatermarkTool-Video` |

Register in `.dependency/manifest.json`:

```json
"gemini-watermark-video": {
  "populated": true,
  "bin": ".dependency/gemini-watermark-video-tool/GeminiWatermarkTool-Video.exe"
}
```

Use `GeminiWatermarkTool-Video` (no `.exe`) on Unix. Dependencies: portable **GeminiWatermarkTool-Video** binary only (separate from the image `GeminiWatermarkTool` binary).

## Quick Start

**Default: create `<source-dir>/no-watermark/` next to each input file** (never overwrites sources):

```bash
# Single file — output beside the source
# C:\Users\...\Downloads\clip.mp4 → C:\Users\...\Downloads\no-watermark\clip.mp4
.dependency/python/python.exe .cursor/skills/video-remove-watermark-gemini/scripts/remove_watermark.py C:\Users\...\Downloads\clip.mp4

# Project-relative path
.dependency/python/python.exe .cursor/skills/video-remove-watermark-gemini/scripts/remove_watermark.py video/intro.mp4
# → video/no-watermark/intro.mp4

# Directory batch (flat)
.dependency/python/python.exe .cursor/skills/video-remove-watermark-gemini/scripts/remove_watermark.py video/cutscenes

# Recursive batch
.dependency/python/python.exe .cursor/skills/video-remove-watermark-gemini/scripts/remove_watermark.py video --recursive
```

Custom output folder name:

```bash
.dependency/python/python.exe .cursor/skills/video-remove-watermark-gemini/scripts/remove_watermark.py video/intro.mp4 \
  --output-subdir clean
```

Shared output directory:

```bash
.dependency/python/python.exe .cursor/skills/video-remove-watermark-gemini/scripts/remove_watermark.py video/cutscenes \
  --output-dir out
```

## Detection

GeminiWatermarkTool-Video auto-detects the watermark type per file — no flags needed for current outputs:

| Watermark | Resolution | Notes |
|-----------|------------|-------|
| Gemini 3.5 diamond | 1080p, 720p (landscape + portrait) | Default profile; standard + compact 720p variants |
| Small "Veo" text | 1080p, 720p (Google Flow) | Auto-detected alongside diamond |
| Legacy "Veo" text | Pre-Gemini-3.5 | Use `--legacy` |

Multi-frame probe (12 frames) prevents false SKIP on intro fade-ins. Tick-exact transcoder timing preserves frame count, duration, and FPS.

## Options

| Option | Default | Notes |
|--------|---------|-------|
| Output folder | `<source-dir>/no-watermark/` per video | Sibling folder beside each input file |
| `--output-subdir` | `no-watermark` | Subfolder name beside each source file |
| `--output-dir` | *(none)* | Shared output root under input path |
| `--legacy` | off | Pre-Gemini-3.5 larger Veo text watermark |
| `--ml` | off | Opt-in ML intensity assist for tricky clips |
| `--variant` | auto | Force `720p-1` (48×48) or `720p-2` (44×44) when auto-detect fails |
| `--sigma` | engine default | AI denoise sigma — lower for anime/illustration (e.g. 15), higher for photo (e.g. 25) |
| `--json` | off | Print structured metadata per video |
| `--pattern` | `*.mp4` | Also matches `.mkv`, `.mov`, `.webm` |
| `--recursive` | off | Search subdirectories |

```bash
# Default — auto-detect diamond or small Veo text, audio preserved
.dependency/python/python.exe .cursor/skills/video-remove-watermark-gemini/scripts/remove_watermark.py video/clip.mp4

# Pre-Gemini-3.5 legacy Veo text watermark
.dependency/python/python.exe .cursor/skills/video-remove-watermark-gemini/scripts/remove_watermark.py video/old.mp4 --legacy

# ML assist for clips with varying intensity (opt-in since v0.6.4)
.dependency/python/python.exe .cursor/skills/video-remove-watermark-gemini/scripts/remove_watermark.py video/clip.mp4 --ml

# Anime / illustration content (lighter AI denoise)
.dependency/python/python.exe .cursor/skills/video-remove-watermark-gemini/scripts/remove_watermark.py video/clip.mp4 --sigma 15

# Force 720p variant when auto-detect fails (rare)
.dependency/python/python.exe .cursor/skills/video-remove-watermark-gemini/scripts/remove_watermark.py video/clip.mp4 --variant 720p-2
```

Direct CLI equivalent (single file):

```bash
.dependency/gemini-watermark-video-tool/GeminiWatermarkTool-Video.exe -i input.mp4 -o output.mp4
```

## Agent workflow

1. **Confirm source** — inputs should be Gemini / Veo / Google Flow generated videos with a visible corner watermark.
2. **Use the user's real path** — e.g. `C:\Users\...\Downloads\clip.mp4`. Do **not** use Cursor chat attachment paths under `.cursor/projects/.../assets/`.
3. **Run on the user's path directly** — do not copy videos into `video/` or other folders.
4. **Inspect output** — cleaned files appear in `<source-dir>/no-watermark/` beside the originals.
5. **Skipped videos** — exit code 1 means no watermark detected; check `--json` for `applied: false`.
6. **Residual frames** — some clips with heavy motion may leave residue on a few frames; see [manual touch-up workflow](https://github.com/allenk/VeoWatermarkRemover#manual-touch-up-workflow-for-difficult-clips) (ffmpeg decompose → image GWT GUI fix → ffmpeg recompose).
7. **Revert** — delete the output folder; sources are never modified.

## Troubleshooting

| Issue | Fix |
|-------|-----|
| `GeminiWatermarkTool-Video not found` | Download v0.6.4-demo release into `.dependency/gemini-watermark-video-tool/` |
| Watermark not removed (legacy clip) | Re-run with `--legacy` |
| Legacy clip damaged by default mode | Pre-Gemini-3.5 needs `--legacy`; diamond and legacy text are different profiles |
| Auto-detect SKIP on 720p | Try `--variant 720p-1` or `--variant 720p-2` |
| Output too blurry (anime/illustration) | `--sigma 15` |
| Intensity varies across clip | `--ml` |
| Windows SmartScreen blocks exe | More info → Run anyway, or `Unblock-File` |
| Watermark not removed | Video may not be a Gemini/Veo visible watermark, or unsupported resolution (4K, square, etc.) |

## Related

- Script: [scripts/remove_watermark.py](scripts/remove_watermark.py)
- Video engine: [allenk/VeoWatermarkRemover](https://github.com/allenk/VeoWatermarkRemover)
- Image engine: [image-remove-watermark-gemini](../image-remove-watermark-gemini/SKILL.md)
- Parent project: [allenk/GeminiWatermarkTool](https://github.com/allenk/GeminiWatermarkTool)
- Algorithm write-up: [Reverse Alpha Blending (Medium)](https://allenkuo.medium.com/removing-gemini-ai-watermarks-a-deep-dive-into-reverse-alpha-blending-bbbd83af2a3f)
