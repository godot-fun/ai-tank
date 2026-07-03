# Audio to WAV — Reference

## Default Command Shape (preserve quality)

Per file, the script probes with `ffprobe` then builds:

```bash
# Lossless source — match bit depth, keep sample rate
ffmpeg -i input.flac -c:a pcm_s24le output.wav

# Lossy source — keep rate, 32-bit float PCM (no 16-bit truncation)
ffmpeg -i input.mp3 -c:a pcm_f32le output.wav

# Already PCM WAV — stream copy (bit-perfect)
ffmpeg -i input.wav -c:a copy output.wav
```

## Optional Downconvert

Use only when the user wants a smaller/project-standard batch:

```bash
ffmpeg -i input.flac -ar 48000 -c:a pcm_s16le output.wav
# or: --standardize
```

| Flag | Effect |
|------|--------|
| (default) | Preserve sample rate and bit depth |
| `-s 48000` | Force resample |
| `-b 16` / `-b 24` / `-b 32` | Force PCM bit depth |
| `--standardize` | Shorthand for 48 kHz + 16-bit |
| `--mono` / `--stereo` | Force channel layout |

## Bit Depth Resolution

| Source | Output codec |
|--------|--------------|
| 16-bit PCM / FLAC | `pcm_s16le` |
| 24-bit PCM / FLAC | `pcm_s24le` |
| 32-bit integer PCM | `pcm_s32le` |
| Float PCM | `pcm_f32le` |
| Lossy (MP3, AAC, OGG, …) | `pcm_f32le` |

Lossy sources cannot exceed their encoded quality, but 32-bit float PCM avoids truncating the decoder output.

## PCM Codec Selection

| Bit depth | FFmpeg codec | Typical use |
|-----------|--------------|-------------|
| 16 | `pcm_s16le` | Project batch (`--standardize`) |
| 24 | `pcm_s24le` | Source masters |
| 32 int | `pcm_s32le` | High-resolution PCM |
| 32 float | `pcm_f32le` | Lossy decode, float sources |

## Supported Input Formats

`.mp3`, `.ogg`, `.flac`, `.aac`, `.m4a`, `.wma`, `.wav`

## Output Layout

For `Audio/SFX/click.mp3` with default output dir:

```
Audio/SFX/wav/click.wav
```

Batch with `-r` preserves subdirectory structure under the output root.

## Related Skills

| Skill | When to use after conversion |
|-------|------------------------------|
| **Loudness normalization** | Match levels across mixed assets |
| **Trim** | Remove leading/trailing silence |
| **Fade** | Shape attack/release |
| **Volume adjust** | Fixed dB offset |
