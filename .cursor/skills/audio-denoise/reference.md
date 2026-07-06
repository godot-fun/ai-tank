# Audio Denoise — Reference

## FFmpeg Filters

Default chain (denoise only):

```bash
ffmpeg -i input.wav -af "afftdn=nr=10:nf=-25" -y output.wav
```

De-clip + denoise:

```bash
ffmpeg -i input.wav -af "adeclip,afftdn=nr=10:nf=-25" -y output.wav
```

De-clip only:

```bash
ffmpeg -i input.wav -af "adeclip" -y output.wav
```

## afftdn (noise reduction)

| Param | Meaning | Default in script |
|-------|---------|-----------------|
| `nr` | Noise reduction amount (dB) | 10 |
| `nf` | Noise floor (dB) | -25 |

Higher `nr` removes more noise but can sound metallic on SFX. Start at 8–12 for game assets.

## adeclip (de-clip)

Repairs hard-clipped peaks by interpolating the waveform. Use when the source was recorded or exported too hot.

| When to use | When to skip |
|-------------|--------------|
| Visible flat tops on the waveform | Clean peaks, no distortion |
| Audible crackle on loud hits | Already limited/normalized sources |

## Category Guidance

| Category | Denoise | De-clip | `--nr` hint |
|----------|---------|---------|-------------|
| UI / SFX | Light or skip | Rare | 6–10 |
| Voice / dialogue | Often yes | If clipped | 8–12 |
| Room-tone ambience | Yes | Rare | 10–15 |
| Music / BGM | Careful | If clipped | 6–8 or skip |

Run `--dry-run` on one file before batch folders. Compare against the source — if transients sound dull, lower `--nr` or skip denoise for that asset.
