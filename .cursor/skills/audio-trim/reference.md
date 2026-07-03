# Audio Trim — Reference

## FFmpeg Filter

The bundled scripts use `silenceremove`:

```
# Both sides (default)
silenceremove=start_periods=1:start_duration=0:start_threshold=-50dB:stop_periods=1:stop_duration=0:stop_threshold=-50dB

# Trim start only (Remove leading silence)
silenceremove=start_periods=1:start_duration=0:start_threshold=-50dB

# Trim end only (Remove trailing silence)
silenceremove=stop_periods=1:stop_duration=0:stop_threshold=-50dB
```

| Parameter | Meaning |
|-----------|---------|
| `start_periods=1` | Trim one silence run from the beginning |
| `stop_periods=1` | Trim one silence run from the end |
| `start_duration=0` / `stop_duration=0` | No minimum non-silence before trimming begins |
| `start_threshold` / `stop_threshold` | Levels at or below this are treated as silence (use `dB` suffix) |

## Trim vs Silence Removal

| Term | Role |
|------|------|
| **Trim / Audio Trimming** | General edit action — crop boundaries at start or end |
| **Silence Removal** | Automated batch strategy — detect silence, then delete it |

## Manual Trim (when automation is wrong)

For precise in/out points, use sample-accurate trim instead of silence detection:

```bash
ffmpeg -i input.wav -af "atrim=start=0.05:end=1.2" -y output.wav
```

Or time-based cut:

```bash
ffmpeg -ss 0.05 -to 1.2 -i input.wav -c copy -y output.wav
```

Prefer `silenceremove` for batch folders; use `atrim` or `-ss`/`-to` for single files with known boundaries.

## Category Guidance

| Category | Trim start | Trim end | Threshold |
|----------|------------|----------|-----------|
| UI clicks | Yes | Yes | -50 dB |
| Impacts / weapons | Yes | Often yes | -50 to -45 dB |
| Voice lines | Yes | Yes | -50 dB (watch breath) |
| BGM loops | Rarely | **Avoid** | N/A — manual |
| Ambience beds | Careful | Careful | -60 dB or skip |

## Chaining with Loudness Normalization

```powershell
# 1. Trim silence at start/end
powershell -ExecutionPolicy Bypass -File .cursor/skills/audio-trim/scripts/trim.ps1 -Input "Audio/SFX"

# 2. Normalize trimmed output
powershell -ExecutionPolicy Bypass -File .cursor/skills/audio-loudness-normalization/scripts/normalize.ps1 -Input "Audio/SFX/trimmed"
```
