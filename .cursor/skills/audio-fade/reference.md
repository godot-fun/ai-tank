# Audio Fade — Reference

## FFmpeg Filter

The bundled script chains one or two `afade` filters:

```
# Fade in + fade out (default 1 s each)
afade=t=in:st=0:d=1,afade=t=out:st=4.0:d=1

# Fade in only
afade=t=in:st=0:d=0.05

# Fade out only (st = duration - d)
afade=t=out:st=2.85:d=0.15
```

| Parameter | Meaning |
|-----------|---------|
| `t=in` / `t=out` | Fade direction |
| `st` | Start time in seconds (`0` for fade-in; `duration - d` for fade-out) |
| `d` | Fade duration in seconds |
| `curve` | Envelope shape (default `tri`) |

## Curve Options

| Curve | Character |
|-------|-----------|
| `tri` | Linear (default) — predictable, good for most SFX |
| `exp` | Exponential — softer tail, natural decay |
| `log` | Logarithmic — slower start, faster finish |
| `qsin` | Quarter sine — smooth S-curve |
| `hsin` | Half sine — gentle swell |
| `des` | Double-exponential S-curve |

Use `tri` or `exp` for gameplay SFX; `qsin`/`hsin` for ambience and music beds.

## Fade vs Trim vs Crossfade

| Term | Role |
|------|------|
| **Fade in/out** | Shape volume envelope at boundaries; clip length unchanged |
| **Trim** | Remove silence or crop boundaries (see `audio-trim` skill) |
| **Crossfade** | Overlap two clips with complementary fades — not covered here |

## Manual Fallback (single file)

When you need a one-off tweak outside batch processing:

```bash
ffmpeg -i input.wav -af "afade=t=in:st=0:d=1,afade=t=out:st=4.0:d=1" -y output.wav
```

Replace `4.0` with `duration - fade_out_seconds`. Prefer the bundled script for folders and duration probing.

## Category Notes

| Category | Fade-in | Fade-out | Notes |
|----------|---------|----------|-------|
| UI clicks | Optional / very short | Short | Preserve click attack |
| Loops | Short in only | **Skip** | Fade-out breaks seamless loop |
| Voice | Moderate | Moderate | Avoid masking breath at tail |
| Stingers / hits | Minimal | Longer | Let reverb tail fade naturally |
