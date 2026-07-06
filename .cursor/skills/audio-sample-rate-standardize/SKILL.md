---
name: audio-sample-rate-standardize
description: Standardizes audio sample rate to 44100 or 48000 Hz and exports 16-bit PCM WAV using FFmpeg. Use when the user wants sample rate standardization, resample to 44.1 kHz or 48 kHz, batch WAV export at project sample rates, or mentions 44100, 48000, or PCM WAV conversion without loudness normalization.
---

# Audio Sample Rate Standardize

Export **16-bit PCM WAV** at **44100 or 48000 Hz** only. No loudness processing.

## Rules

When this skill applies, read and follow [skill-dependency-manager](../../rules/skill-dependency-manager.md) — run scripts as documented, install missing tools into `.dependency/`.

## Quick Start

Output to a sibling `standardized/` folder (source files are read-only):

```bash
.dependency/python/python .cursor/skills/audio-sample-rate-standardize/scripts/standardize.py path/to/audio_or_folder
```

Example: `audio/sfx/tank/tank_move.mp3` → `audio/sfx/tank/standardized/tank_move.wav`

## Sample Rate Rule

| Source rate | Output |
|-------------|--------|
| ≤ 44100 Hz | 44100 Hz |
| > 44100 Hz | 48000 Hz |

| Rate | Typical use |
|------|-------------|
| 44100 Hz | Music, games, CD |
| 48000 Hz | Games, film, video |

## Common Flags

`-r` (recursive) · `-o` / `--output-dir` · `--dry-run` · `--overwrite`

```bash
.dependency/python/python .cursor/skills/audio-sample-rate-standardize/scripts/standardize.py Audio/SFX -r --dry-run
```

**Never overwrite source files.** The script writes only to `standardized/` (or `-o`). All outputs are `.wav` regardless of input format. Supported inputs: `.wav`, `.mp3`, `.ogg`, `.flac`, `.aac`, `.m4a`, `.wma`.

## Agent Notes

1. Use the bundled script, not hand-written `-ar` / `-c:a` commands.
2. **No loudness normalization** — LUFS targeting is a separate step in the audio pipeline.
3. Missing Python/FFmpeg → populate `.dependency/` per skill-dependency-manager, retry same command.
4. **Do not copy, move, or replace the source with standardized output** — tell the user where `standardized/` files are; they swap assets manually when ready.
5. Do not use `-o` pointing at the source folder; the script refuses output paths that would overwrite inputs.
6. FFmpeg details: [reference.md](reference.md)
