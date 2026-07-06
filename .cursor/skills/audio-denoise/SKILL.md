---
name: audio-denoise
description: Reduces background noise and optionally repairs clipped peaks in audio files using FFmpeg afftdn and adeclip. Use when the user wants audio denoise, noise reduction, hiss removal, room noise cleanup, de-clip, declipping, or batch SFX/voice cleanup before normalization.
---

# Audio Denoise

Reduce background noise via FFmpeg `afftdn`. Optionally repair clipped peaks with `adeclip`.

## Rules

When this skill applies, read and follow [skill-dependency-manager](../../rules/skill-dependency-manager.md) — run scripts as documented, install missing tools into `.dependency/`.

## Quick Start

Default: **denoise only** (`afftdn`), output to `denoised/`:

```bash
.dependency/python/python .cursor/skills/audio-denoise/scripts/denoise.py path/to/audio_or_folder
```

Clipped source (de-clip then denoise):

```bash
.dependency/python/python .cursor/skills/audio-denoise/scripts/denoise.py path/to/audio.wav --declip
```

De-clip only:

```bash
.dependency/python/python .cursor/skills/audio-denoise/scripts/denoise.py path/to/audio.wav --declip-only
```

## Defaults

| Setting | Default | Notes |
|---------|---------|-------|
| Denoise | On (`afftdn`) | `nr=10` dB, `nf=-25` dB — conservative for SFX |
| De-clip | Off | Pass `--declip` or `--declip-only` when needed |

## Common Flags

`--declip` · `--declip-only` · `--no-denoise` · `--nr` · `--nf` · `-r` · `-o` / `--output-dir` · `--dry-run` · `--overwrite`

```bash
.dependency/python/python .cursor/skills/audio-denoise/scripts/denoise.py Audio/SFX -r --dry-run
.dependency/python/python .cursor/skills/audio-denoise/scripts/denoise.py Audio/Voice -nr 8 --declip
```

Originals are never modified. Supported: `.wav`, `.mp3`, `.ogg`, `.flac`, `.aac`, `.m4a`, `.wma`.

## Agent Notes

1. Use the bundled script, not hand-written `afftdn` / `adeclip` filters.
2. **Default is light denoise** — do not raise `--nr` unless the user asks; heavy denoise dulls transients.
3. **Use `--declip`** only when peaks are visibly or audibly clipped; skip for clean recordings.
4. Missing Python/FFmpeg → populate `.dependency/` per skill-dependency-manager, retry same command.
5. **Do not copy, move, or replace the source with denoised output** — tell the user where `denoised/` files are; they swap assets manually when ready.
6. FFmpeg filter details: [reference.md](reference.md)
