# Loudness Normalization Reference

## Why LUFS, Not Peak

Peak normalization only aligns maximum sample amplitude. Two files with the same peak can sound very different. **LUFS** (ITU-R BS.1770) measures perceived loudness and is the standard for batch game-audio leveling.

## Category LUFS Targets

| Category | Integrated LUFS (I) | True Peak (TP) | Notes |
|----------|-------------------|----------------|-------|
| UI / menu clicks | -18 to -14 | ≤ -1.5 dBTP | Short transients; batch as one group |
| Gameplay SFX | -16 to -12 | ≤ -1.5 dBTP | Weapons, pickups, abilities |
| Explosions / heavy impacts | -12 to -8 | ≤ -1.5 dBTP | Loudest category; keep separate |
| Ambience / footsteps | -22 to -18 | ≤ -3.0 dBTP | Bed layers; stay under gameplay |
| BGM | -16 to -14 | ≤ -1.5 dBTP | Duck under voice at runtime |
| Voice / dialogue | -16 to -14 | ≤ -1.5 dBTP | Usually pre-mixed; normalize lightly |

Keep assets within **±2 LUFS** inside each category.

## FFmpeg loudnorm Parameters

| Param | Meaning | Typical value |
|-------|---------|---------------|
| `I` | Target integrated loudness (LUFS) | -14 |
| `TP` | True peak limit (dBTP) | -1.5 |
| `LRA` | Loudness range | 11 (default) |

Two-pass flow:
1. **Pass 1** — measure `measured_I`, `measured_LRA`, `measured_TP`, `measured_thresh`, `offset`
2. **Pass 2** — apply with measured values for accurate normalization

## Export Format (Default Output)

All normalized files are written as **16-bit PCM WAV** (`pcm_s16le`), regardless of input format or extension. Output sample rate is **44100 or 48000 Hz only**.

| Setting | Default output |
|---------|----------------|
| Sample rate | 44100 Hz if source ≤ 44100 Hz; 48000 Hz if source > 44100 Hz |
| Bit depth | 16-bit PCM |
| Format | WAV |
| Channels | Preserved from source |

| Rate | Typical use |
|------|-------------|
| 44100 Hz | Music, games, CD |
| 48000 Hz | Games, film, video |

Pass 2 encode shape:

```bash
# Source ≤ 44100 Hz
ffmpeg -i input.mp3 -af loudnorm=... -ar 44100 -c:a pcm_s16le output.wav

# Source > 44100 Hz
ffmpeg -i input.flac -af loudnorm=... -ar 48000 -c:a pcm_s16le output.wav
```

## Export Format Recommendations

| Setting | Recommendation |
|---------|----------------|
| Sample rate | 44100 or 48000 Hz only |
| Bit depth | 16-bit (default output) or 24-bit (PC/console masters) |
| Format | WAV for source; compress at build time |
| Channels | Mono for most SFX; stereo for BGM |

## Game Engine Defaults (Post-Import)

Normalization fixes **source** levels. Engine buses handle **category** balance.

### Player settings (first launch)

| Slider | Default |
|--------|---------|
| Master | 100% |
| SFX | 100% |
| BGM | 85% |
| Voice | 100% |

Map sliders internally: 100% = 0 dB, 50% ≈ -6 dB, 0% = mute.

### Bus gains (relative to Master)

| Bus | Gain |
|-----|------|
| SFX | 0 dB |
| UI | +1 dB (or under SFX) |
| BGM | -4 dB |
| Voice | 0 dB |
| Ambience | -8 dB |

### Ducking (when voice plays)

- BGM: -10 dB
- Ambience: -6 dB
- Release: 0.3–0.5 s

### Master limiter

- True peak ceiling: **-1 dBTP** (mobile: **-1.5 dBTP**)

## Starter Preset (Action / RPG)

```
Player:  Master 100% | SFX 100% | BGM 85% | Voice 100%
Buses:   SFX 0 dB | BGM -4 dB | Ambience -8 dB
Sources: SFX -14 LUFS | BGM -15 LUFS | UI -16 LUFS | Ambience -20 LUFS
```

Adjust BGM bus (-3 to -6 dB) first if music masks gameplay audio.
