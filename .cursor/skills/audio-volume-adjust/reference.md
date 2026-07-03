# Audio Volume Adjust — Reference

## FFmpeg Filter

The bundled script applies a single `volume` filter with uniform gain:

```
# Reduce by 6 dB
volume=-6dB

# Boost by 3 dB
volume=3dB

# Linear multiplier
volume=0.5
volume=2.0
```

| Mode | Filter | Effect |
|------|--------|--------|
| dB | `volume=-6dB` | Multiply amplitude by 10^(-6/20) ≈ 0.50 |
| dB | `volume=3dB` | Multiply amplitude by 10^(3/20) ≈ 1.41 |
| Gain | `volume=0.5` | Multiply amplitude by 0.50 |
| Gain | `volume=2.0` | Multiply amplitude by 2.00 |

Negative dB / gain < 1 reduces level; positive dB / gain > 1 increases it.

## dB vs Linear Gain

| dB | Linear gain | Relative amplitude |
|----|-------------|-------------------|
| -6 | 0.501 | ~50% |
| -3 | 0.708 | ~71% |
| +3 | 1.413 | ~141% |
| +6 | 2.000 | ~200% |
| +12 | 3.981 | ~398% |

Formula: `gain = 10^(dB / 20)`

## Volume Adjust vs Other Skills

| Skill | Role |
|-------|------|
| **Volume adjust** (this) | Fixed dB/gain offset on every sample |
| **Loudness normalization** | Target integrated LUFS across heterogeneous assets |
| **Fade** | Shape envelope at start/end only |
| **Trim** | Remove silence or crop boundaries |

## Clipping When Boosting

Boosting raises all samples proportionally. If the source already peaks near 0 dBFS, a +6 dB boost will clip. Prefer small boosts (+3 dB or less) or use `audio-loudness-normalization` for level matching with true-peak limiting.

## Manual Fallback (single file)

When you need a one-off tweak outside batch processing:

```bash
ffmpeg -i input.wav -af "volume=-6dB" -y output.wav
ffmpeg -i input.wav -af "volume=3dB" -y output.wav
```

Prefer the bundled script for folders and output safety checks.

## Category Notes

| Category | Typical adjustment | Notes |
|----------|-------------------|-------|
| UI clicks | -3 to -6 dB | Keep attack; avoid over-attenuating short ticks |
| Quiet source fix | +3 to +6 dB | Watch for clipping; prefer loudnorm for mixed folders |
| Gameplay SFX | -6 to -12 dB | Tune against in-game bus mix |
| Ambience beds | -9 to -15 dB | Layer under foreground SFX |

After adjustment, re-check peak levels in the engine mixer.
