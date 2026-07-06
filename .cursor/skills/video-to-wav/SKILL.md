---
name: video-to-wav
description: Extracts audio tracks from video files to PCM WAV using FFmpeg while preserving source quality. Use when the user wants to extract audio from video, rip sound from MP4/MKV/MOV/WebM, export video audio to WAV, or batch-convert video soundtracks without quality loss.
---

# Video to WAV

Extract the first audio track from supported video files to **PCM WAV** via FFmpeg. **Defaults preserve source quality** — no resampling, bit depth matched from the embedded audio (32-bit float for lossy codecs), channels preserved, video stream discarded (`-vn`).

## Rules

When this skill applies, read and follow [skill-dependency-manager](../../rules/skill-dependency-manager.md) — run scripts as documented, install missing tools into `.dependency/`.

## Quick Start

Extract a file or folder, output to `wav/`:

```bash
.dependency/python/python .cursor/skills/video-to-wav/scripts/extract.py path/to/video_or_folder
```

Example: `assets/clip.mp4` → `assets/wav/clip.wav` (same rate/depth as embedded audio)

Batch with subfolders:

```bash
.dependency/python/python .cursor/skills/video-to-wav/scripts/extract.py Video/Clips -r
```

## Format Defaults

| Setting | Default | Notes |
|---------|---------|-------|
| Audio track | First (`a:0`) | Use `--track N` for alternate tracks (0-based) |
| Sample rate | Preserve source | No resampling unless `-s` or `--standardize` |
| Bit depth | Match source | Probed per file; lossy → 32-bit float PCM |
| Channels | Preserve source | Use `--mono` or `--stereo` to force |
| Lossless PCM in container | Stream copy | Bit-perfect when no overrides |

## Common Flags

`-r` · `-o` / `--output-dir` · `--track` · `-s` / `--sample-rate` · `-b` / `--bit-depth` · `--standardize` · `--mono` · `--stereo` · `--dry-run` · `--overwrite`

Alternate audio track:

```bash
.dependency/python/python .cursor/skills/video-to-wav/scripts/extract.py clip.mkv --track 1
```

Downconvert for project batch preset (48 kHz / 16-bit):

```bash
.dependency/python/python .cursor/skills/video-to-wav/scripts/extract.py Video/Clips -r --standardize
```

**Never overwrite source files.** The script writes only to `wav/` (or `-o`). Supported inputs: `.mp4`, `.mkv`, `.mov`, `.avi`, `.webm`, `.wmv`, `.flv`, `.m4v`, `.mpeg`, `.mpg`, `.ts`, `.mts`, `.m2ts`, `.3gp`.

## Agent Notes

1. Use the bundled script, not hand-written `ffmpeg -i …` commands.
2. **Do not downsample or reduce bit depth** unless the user explicitly asks — omit `-s`, `-b`, and `--standardize`.
3. **No audio track** — script reports failure; confirm the file has an audio stream.
4. Missing Python/FFmpeg → populate `.dependency/` per skill-dependency-manager, retry same command.
5. **Do not copy, move, or replace the source with extracted output** — tell the user where `wav/` files are; they swap assets manually when ready.
6. Need **48 kHz / 16-bit project batch** → pass `--standardize`.
7. This skill is for video containers only; standalone audio files are out of scope.
8. FFmpeg codec and probing details: [reference.md](reference.md)
