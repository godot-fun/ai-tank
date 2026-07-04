---
name: audio-to-ogg
description: Converts audio files to OGG Vorbis using FFmpeg for Godot-ready compressed assets. Use when the user wants to convert audio to OGG, transcode WAV/MP3/FLAC/AAC to OGG, batch-export game SFX/BGM, or mentions Vorbis, libvorbis, or Godot audio import.
---

# Audio to OGG

Convert supported audio formats to **OGG Vorbis** via FFmpeg. **Defaults preserve source sample rate** and encode at **Vorbis quality 6** — a balanced preset for game SFX and BGM.

## Rules

When this skill applies, read and follow [skill-dependency-manager](../../rules/skill-dependency-manager.md) — run scripts as documented, install missing tools into `.dependency/`.

## Quick Start

Convert a file or folder, output to `ogg/`:

```bash
.dependency/python/python .cursor/skills/audio-to-ogg/scripts/convert.py path/to/audio_or_folder
```

Example: `audio/sfx/tank/tank_move.wav` → `audio/sfx/tank/ogg/tank_move.ogg`

Batch with subfolders:

```bash
.dependency/python/python .cursor/skills/audio-to-ogg/scripts/convert.py Audio/SFX -r
```

## Format Defaults

| Setting | Default | Notes |
|---------|---------|-------|
| Codec | OGG Vorbis (`libvorbis`) | Godot-native compressed format |
| Sample rate | Preserve source | No resampling unless `-s` or `--standardize` |
| Quality | `6` (`-q 6`) | ~192 kbps VBR; use `-q` to adjust |
| Channels | Preserve source | Use `--mono` or `--stereo` to force |
| Existing Vorbis OGG | Stream copy | Bit-perfect when no overrides |

## Quality Guide

| `-q` | Approx. bitrate | Typical use |
|------|-----------------|-------------|
| 3–4 | ~96–128 kbps | Short UI clicks, ambient loops |
| 5–6 | ~160–192 kbps | Gameplay SFX, BGM (default) |
| 7–8 | ~224–256 kbps | Music masters, voice dialogue |
| 9–10 | ~320–500 kbps | Archival; rarely needed in games |

## Common Flags

`-r` · `-o` / `--output-dir` · `-s` / `--sample-rate` · `-q` / `--quality` · `--standardize` · `--mono` · `--stereo` · `--dry-run` · `--overwrite`

Project batch preset (48 kHz Vorbis):

```bash
.dependency/python/python .cursor/skills/audio-to-ogg/scripts/convert.py Audio/SFX -r --standardize
```

Lower quality for UI sounds:

```bash
.dependency/python/python .cursor/skills/audio-to-ogg/scripts/convert.py Audio/UI -q 4 --dry-run
```

**Never overwrite source files.** The script writes only to `ogg/` (or `-o`). Supported inputs: `.mp3`, `.ogg`, `.flac`, `.aac`, `.m4a`, `.wma`, `.wav`.

## Agent Notes

1. Use the bundled script, not hand-written `ffmpeg -i …` commands.
2. **Do not resample** unless the user explicitly asks — omit `-s` and `--standardize`.
3. **Already Vorbis OGG?** Stream-copied by default (no generation loss).
4. Missing Python/FFmpeg → populate `.dependency/` per skill-dependency-manager, retry same command.
5. **Do not copy, move, or replace the source with converted output** — tell the user where `ogg/` files are; they swap assets manually when ready.
6. Need **48 kHz project batch** → pass `--standardize`.
7. Need **level matching before or after conversion** → use `audio-loudness-normalization`.
8. Need **lossless intermediates** → use `audio-to-wav` first, then normalize, then convert to OGG.
9. FFmpeg codec and quality details: [reference.md](reference.md)
