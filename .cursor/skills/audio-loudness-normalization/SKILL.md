---
name: audio-loudness-normalization
description: Batch-normalizes audio files to consistent LUFS loudness with true-peak limiting using FFmpeg. Use when the user wants loudness normalization, volume matching, unified audio levels, batch SFX/UI/BGM processing, or mentions LUFS, true peak, loudnorm, or inconsistent game audio.
---

# Audio Loudness Normalization

Batch-normalize audio to consistent LUFS with true-peak limiting. **Preserves input format** — same extension and sample rate as the source.

## Rules

When this skill applies, read and follow [skill-dependency-manager](../../rules/skill-dependency-manager.md) — run scripts as documented, install missing tools into `.dependency/`.

## Quick Start

Default: **-14 LUFS**, **-1.5 dBTP**, output to a sibling `normalized/` folder (source files are read-only):

```bash
.dependency/python/python .cursor/skills/audio-loudness-normalization/scripts/normalize.py path/to/audio_or_folder
```

Example: `audio/sfx/tank/tank_move.wav` → `audio/sfx/tank/normalized/tank_move.wav`

## LUFS Targets

| Category | LUFS | True peak |
|----------|------|-----------|
| UI / clicks | -18 to -14 | -1.5 dBTP |
| Gameplay SFX | -16 to -12 | -1.5 dBTP |
| Explosions | -12 to -8 | -1.5 dBTP |
| Ambience | -22 to -18 | -3.0 dBTP |
| BGM / voice | -16 to -14 | -1.5 dBTP |

One category per folder. Mixed folders: split first, then batch with matching `-t`.

## Common Flags

`-t` / `--target-lufs` · `-tp` / `--true-peak` · `-r` (recursive) · `-o` / `--output-dir` · `--dry-run` · `--overwrite`

```bash
.dependency/python/python .cursor/skills/audio-loudness-normalization/scripts/normalize.py Audio/SFX -t -14 -r --dry-run
```

**Never overwrite source files.** The script writes only to `normalized/` (or `-o`). Supported inputs: `.wav`, `.mp3`, `.ogg`, `.flac`, `.aac`, `.m4a`, `.wma`.

## Agent Notes

1. Use the bundled script (two-pass `loudnorm`), not hand-written FFmpeg.
2. **Preserves input format** — does not resample or change container extension.
3. Missing Python/FFmpeg → populate `.dependency/` per skill-dependency-manager, retry same command.
4. **Do not copy, move, or replace the source with the normalized output** — tell the user where `normalized/` files are; they swap assets manually when ready.
5. Do not use `-o` pointing at the source folder; the script refuses output paths that would overwrite inputs.
6. Do not fix uneven levels with per-asset volume in game code — re-normalize sources.
7. Engine bus defaults and rationale: [reference.md](reference.md)
