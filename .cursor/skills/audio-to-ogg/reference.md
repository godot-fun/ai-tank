# Audio to OGG — Reference

## Default Command Shape

Per file, the script probes with `ffprobe` then builds:

```bash
# Lossless or lossy source — preserve rate, Vorbis q=6
ffmpeg -i input.wav -c:a libvorbis -q:a 6 output.ogg

# Already Vorbis OGG — stream copy (no generation loss)
ffmpeg -i input.ogg -c:a copy output.ogg
```

## Optional Resample

Use only when the user wants a project-standard batch:

```bash
ffmpeg -i input.wav -ar 48000 -c:a libvorbis -q:a 6 output.ogg
# or: --standardize
```

| Flag | Effect |
|------|--------|
| (default) | Preserve sample rate, Vorbis q=6 |
| `-q 4` | Lower quality (~128 kbps) |
| `-q 8` | Higher quality (~256 kbps) |
| `-s 48000` | Force resample |
| `--standardize` | Shorthand for 48 kHz |
| `--mono` / `--stereo` | Force channel layout |

## Vorbis Quality Scale

FFmpeg `-q:a` maps to libvorbis quality 0–10 (higher = larger files, better fidelity).

| Quality | Approx. stereo bitrate |
|---------|------------------------|
| 0 | ~64 kbps |
| 3 | ~96 kbps |
| 4 | ~128 kbps |
| 5 | ~160 kbps |
| 6 | ~192 kbps |
| 7 | ~224 kbps |
| 8 | ~256 kbps |
| 10 | ~500 kbps |

Actual bitrate varies by content (VBR).

## Supported Input Formats

`.mp3`, `.ogg`, `.flac`, `.aac`, `.m4a`, `.wma`, `.wav`

## Output Layout

For `Audio/SFX/click.wav` with default output dir:

```
Audio/SFX/ogg/click.ogg
```

Batch with `-r` preserves subdirectory structure under the output root.

## Godot Notes

- Godot imports `.ogg` as `AudioStreamOggVorbis` without extra import settings.
- Prefer OGG for shipped game assets; keep WAV/FLAC as source masters.
- Loop points and streaming are configured in Godot import metadata, not during FFmpeg conversion.

## Related Skills

| Skill | When to use |
|-------|-------------|
| **audio-to-wav** | Lossless source export or intermediate editing |
| **Loudness normalization** | Match levels across mixed assets before/after OGG export |
| **Trim** | Remove leading/trailing silence before encoding |
| **Fade** | Shape attack/release before encoding |
| **Volume adjust** | Fixed dB offset on sources |
