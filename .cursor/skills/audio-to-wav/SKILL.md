---
name: audio-to-wav
description: Converts audio files to WAV (PCM) using FFmpeg while preserving source quality. Use when the user wants to convert audio to WAV, transcode MP3/OGG/FLAC/AAC to WAV without downgrading sample rate or bit depth, or batch-export lossless WAV source assets.
---

# Audio to WAV

Convert supported audio formats to **PCM WAV** via FFmpeg. **Defaults preserve source quality** — no resampling, bit depth matched from the source (32-bit float for lossy inputs), channels preserved.

## Rules

When this skill applies, read and follow [skill-dependency-manager](../../rules/skill-dependency-manager.md) — run scripts as documented, install missing tools into `.dependency/`.

## Quick Start

Convert a file or folder, output to `wav/`:

```bash
.dependency/python/python .cursor/skills/audio-to-wav/scripts/convert.py path/to/audio_or_folder
```

Example: `audio/sfx/tank/tank_move.flac` → `audio/sfx/tank/wav/tank_move.wav` (same rate/depth)

Batch with subfolders:

```bash
.dependency/python/python .cursor/skills/audio-to-wav/scripts/convert.py Audio/SFX -r
```

## Format Defaults

| Setting | Default | Notes |
|---------|---------|-------|
| Sample rate | Preserve source | No resampling unless `-s` or `--standardize` |
| Bit depth | Match source | Probed per file; lossy → 32-bit float PCM |
| Channels | Preserve source | Use `--mono` or `--stereo` to force |
| Existing PCM WAV | Stream copy | Bit-perfect when no overrides |

## Common Flags

`-r` · `-o` / `--output-dir` · `-s` / `--sample-rate` · `-b` / `--bit-depth` · `--standardize` · `--mono` · `--stereo` · `--dry-run` · `--overwrite`

Downconvert for project batch preset (48 kHz / 16-bit):

```bash
.dependency/python/python .cursor/skills/audio-to-wav/scripts/convert.py Audio/SFX -r --standardize
```

Force specific output:

```bash
.dependency/python/python .cursor/skills/audio-to-wav/scripts/convert.py Audio/BGM -s 48000 -b 16 --dry-run
```

**Never overwrite source files.** The script writes only to `wav/` (or `-o`). Supported inputs: `.mp3`, `.ogg`, `.flac`, `.aac`, `.m4a`, `.wma`, `.wav`.

## Agent Notes

1. Use the bundled script, not hand-written `ffmpeg -i …` commands.
2. **Do not downsample or reduce bit depth** unless the user explicitly asks — omit `-s`, `-b`, and `--standardize`.
3. **Already PCM WAV?** Stream-copied by default (no generation loss).
4. Missing Python/FFmpeg → populate `.dependency/` per skill-dependency-manager, retry same command.
5. **Do not copy, move, or replace the source with converted output** — tell the user where `wav/` files are; they swap assets manually when ready.
6. Need **48 kHz / 16-bit project batch** → pass `--standardize`.
7. FFmpeg codec and probing details: [reference.md](reference.md)
