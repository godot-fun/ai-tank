---
name: video-to-ogv
description: Converts video files to OGV (Theora + Vorbis in Ogg container) using FFmpeg for Godot-ready playback assets. Default pipeline exports FFV1+FLAC lossless MKV intermediates then encodes Theora q=10 OGV for maximum fidelity. Use when the user wants to convert video to OGV, transcode MP4/MKV/MOV/WebM to OGV, batch-export cutscenes or UI video, or mentions Theora, libtheora, VideoStreamTheora, or Godot video import.
---

# Video to OGV

Convert supported video formats to **OGV** (Theora video + Vorbis audio in an Ogg container) via FFmpeg.

**Default (no flags):** lossy sources always go through a lossless intermediate first, then OGV — to minimize generation loss.

1. Export **FFV1 + FLAC** lossless MKV to `lossless/`
2. Encode **Theora q=10 + Vorbis q=10** OGV to `ogv/`

Only Theora encoding is lossy; the intermediate decode is bit-perfect. Use `--fast` or `--no-lossless` only when the user explicitly prioritizes speed or file size over quality.

## Rules

When this skill applies, read and follow [skill-dependency-manager](../../rules/skill-dependency-manager.md) — run scripts as documented, install missing tools into `.dependency/`.

## Quick Start

Convert a file or folder:

```bash
.dependency/python/python .cursor/skills/video-to-ogv/scripts/convert.py path/to/video_or_folder
```

Example:

```
assets/video/intro.mp4
  → assets/video/lossless/intro.mkv   (FFV1+FLAC intermediate)
  → assets/video/ogv/intro.ogv        (final Godot asset)
```

Batch with subfolders:

```bash
.dependency/python/python .cursor/skills/video-to-ogv/scripts/convert.py Video/Cutscenes -r
```

## Format Defaults

| Setting | Default | Notes |
|---------|---------|-------|
| Pipeline | Lossless → OGV | Skipped when source is already lossless |
| Intermediate | FFV1 + FLAC (`.mkv`) | Written to `lossless/`; large but bit-perfect decode |
| Final container | OGG (`.ogv`) | Godot `VideoStreamTheora` format |
| Final video | Theora q=10 | Single-pass from lossless intermediate |
| Final audio | Vorbis q=10 | Preserves source rate unless overridden |
| Resolution / frame rate | Preserve source | Never downscaled by default |
| Existing Theora+Vorbis OGV | Stream copy | Bit-perfect when no overrides |

## Disk Usage

Lossless intermediates are **much larger** than source MP4s (720p ≈ 50–200 MB per 10 s clip). They are kept in `lossless/` for re-encoding. Delete manually when done, or pass **`--clean-lossless`** to remove after each successful OGV export.

## Common Flags

`-r` · `-o` / `--output-dir` · `--lossless-dir` · `--clean-lossless` · `-s` / `--sample-rate` · `--fast` · `--no-lossless` · `-vq` / `-aq` · `--standardize` · `--mono` · `--stereo` · `--dry-run` · `--overwrite`

Skip lossless intermediate (direct 2-pass from lossy source; faster, lower quality):

```bash
.dependency/python/python .cursor/skills/video-to-ogv/scripts/convert.py Video/Cutscenes --no-lossless
```

Smaller/faster encode (no intermediate, fixed q=6):

```bash
.dependency/python/python .cursor/skills/video-to-ogv/scripts/convert.py Video/UI --fast -vq 4 -aq 4
```

Re-encode OGV from existing lossless MKV only (after deleting `ogv/` output):

```bash
.dependency/python/python .cursor/skills/video-to-ogv/scripts/convert.py Video/Cutscenes --overwrite
```

**Never overwrite source files.** Supported inputs: `.mp4`, `.mkv`, `.mov`, `.avi`, `.webm`, `.wmv`, `.flv`, `.m4v`, `.mpeg`, `.mpg`, `.ts`, `.mts`, `.m2ts`, `.3gp`, `.ogv`, `.ogg`.

## Agent Notes

1. Use the bundled script, not hand-written `ffmpeg -i …` commands.
2. **Always use the default pipeline** (lossless MKV → OGV) — run with no quality flags. Never pass `--no-lossless` or `--fast` unless the user explicitly asks for speed/size over quality.
3. **Do not downscale or change frame rate** unless the user explicitly asks.
4. **Do not resample audio** unless the user explicitly asks — omit `-s` and `--standardize`.
5. **Already Theora+Vorbis OGV?** Stream-copied by default (no generation loss).
6. Tell the user where `lossless/` and `ogv/` outputs are; they swap assets manually when ready.
7. Missing Python/FFmpeg → populate `.dependency/` per skill-dependency-manager, retry same command.
8. Need **48 kHz audio batch** → pass `--standardize`.
9. FFmpeg pipeline details: [reference.md](reference.md)
