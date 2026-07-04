# Video to WAV — Reference

## Default Command Shape (preserve quality)

Per file, the script probes the selected audio stream with `ffprobe`, then builds:

```bash
# Lossy embedded audio (AAC, Opus, AC-3, …) — keep rate, 32-bit float PCM
ffmpeg -i input.mp4 -vn -c:a pcm_f32le output.wav

# Lossless PCM in container — bit-perfect stream copy
ffmpeg -i input.mov -vn -map 0:a:0 -c:a copy output.wav

# Alternate track
ffmpeg -i input.mkv -vn -map 0:a:1 -c:a pcm_f32le output.wav
```

## Optional Downconvert

Use only when the user wants a smaller/project-standard batch:

```bash
ffmpeg -i input.mp4 -vn -ar 48000 -c:a pcm_s16le output.wav
# or: --standardize
```

| Flag | Effect |
|------|--------|
| (default) | Preserve sample rate and bit depth |
| `--track N` | Select audio stream index (0-based) |
| `-s 48000` | Force resample |
| `-b 16` / `-b 24` / `-b 32` | Force PCM bit depth |
| `--standardize` | Shorthand for 48 kHz + 16-bit |
| `--mono` / `--stereo` | Force channel layout |

## Bit Depth Resolution

| Embedded audio | Output codec |
|----------------|--------------|
| 16-bit PCM | `pcm_s16le` |
| 24-bit PCM | `pcm_s24le` |
| 32-bit integer PCM | `pcm_s32le` |
| Float PCM | `pcm_f32le` |
| Lossy (AAC, Opus, AC-3, MP3, …) | `pcm_f32le` |

Lossy sources cannot exceed their encoded quality, but 32-bit float PCM avoids truncating the decoder output.

## Supported Input Formats

`.mp4`, `.mkv`, `.mov`, `.avi`, `.webm`, `.wmv`, `.flv`, `.m4v`, `.mpeg`, `.mpg`, `.ts`, `.mts`, `.m2ts`, `.3gp`

## Output Layout

For `Video/Clips/intro.mp4` with default output dir:

```
Video/Clips/wav/intro.wav
```

Batch with `-r` preserves subdirectory structure under the output root.

## Related Skills

| Skill | When to use after extraction |
|-------|------------------------------|
| **audio-loudness-normalization** | Match levels across mixed assets |
| **audio-trim** | Remove leading/trailing silence |
| **audio-fade** | Shape attack/release |
| **audio-volume-adjust** | Fixed dB offset |
| **audio-to-wav** | Convert standalone audio files (no video) |
