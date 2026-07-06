---
name: audio-loudness-normalization
description: Batch-normalizes audio files to consistent LUFS loudness and exports 16-bit PCM WAV using FFmpeg. Use when the user wants loudness normalization, volume matching, unified audio levels, batch SFX/UI/BGM processing, or mentions LUFS, true peak, loudnorm, or inconsistent game audio.
---

# Audio Loudness Normalization

Batch-normalize audio to consistent LUFS with true-peak limiting. **Outputs 16-bit PCM WAV** at **44100 or 48000 Hz** only.

## Rules

When this skill applies, read and follow [skill-dependency-manager](../../rules/skill-dependency-manager.md) — run scripts as documented, install missing tools into `.dependency/`.

## Quick Start

Default: **-14 LUFS**, **-1.5 dBTP**, **16-bit PCM WAV** (44100 / 48000 Hz), output to a sibling `normalized/` folder (source files are read-only):

```bash
.dependency/python/python .cursor/skills/audio-loudness-normalization/scripts/normalize.py path/to/audio_or_folder
```

Example: `audio/sfx/tank/tank_move.mp3` → `audio/sfx/tank/normalized/tank_move.wav`

## LUFS Targets

| Category | LUFS | True peak |
|----------|------|-----------|
| UI / clicks | -18 to -14 | -1.5 dBTP |
| Gameplay SFX | -16 to -12 | -1.5 dBTP |
| Explosions | -12 to -8 | -1.5 dBTP |
| Ambience | -22 to -18 | -3.0 dBTP |
| BGM / voice | -16 to -14 | -1.5 dBTP |

One category per folder. Mixed folders: split first, then batch with matching `-t`.

## Output Format

| Setting | Default |
|---------|---------|
| Format | 16-bit PCM WAV |
| Sample rate | **44100 or 48000 Hz only** — source ≤ 44100 Hz → 44100; source > 44100 Hz → 48000 |
| Channels | Preserved from source |

### Allowed sample rates

| Rate | Typical use |
|------|-------------|
| 44100 Hz | Music, games, CD |
| 48000 Hz | Games, film, video |

## Common Flags

`-t` / `--target-lufs` · `-tp` / `--true-peak` · `-r` (recursive) · `-o` / `--output-dir` · `--dry-run` · `--overwrite`

```bash
.dependency/python/python .cursor/skills/audio-loudness-normalization/scripts/normalize.py Audio/SFX -t -14 -r --dry-run
```

**Never overwrite source files.** The script writes only to `normalized/` (or `-o`). All outputs are `.wav` regardless of input format. Supported inputs: `.wav`, `.mp3`, `.ogg`, `.flac`, `.aac`, `.m4a`, `.wma`.

## Agent Notes

1. Use the bundled script (two-pass `loudnorm`), not hand-written FFmpeg.
2. **Default output is 16-bit PCM WAV at 44100 or 48000 Hz** — input format and extension are not preserved; no other sample rates are emitted.
3. Missing Python/FFmpeg → populate `.dependency/` per skill-dependency-manager, retry same command.
4. **Do not copy, move, or replace the source with the normalized output** — even after a successful run. Tell the user where `normalized/` files are; they swap assets manually when ready.
5. Do not use `-o` pointing at the source folder; the script refuses output paths that would overwrite inputs.
6. Do not fix uneven levels with per-asset volume in game code — re-normalize sources.
7. Need format conversion without loudness normalization → use `audio-to-wav`.
8. Engine bus defaults and rationale: [reference.md](reference.md)
