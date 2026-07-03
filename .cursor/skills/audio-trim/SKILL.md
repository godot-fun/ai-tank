---
name: audio-trim
description: Trims leading and trailing silence from audio files using FFmpeg. Use when the user wants audio trim, trim silence at start/end, remove leading/trailing silence, batch SFX cleanup, or voice dialogue preprocessing.
---

# Audio Trim

Trim silence at the start and/or end of audio files — remove dead air before the hit or after the tail. Pair with [audio-loudness-normalization](../audio-loudness-normalization/SKILL.md) for a full game-audio prep pipeline.

## Terminology

**Trim / Audio Trimming** — the most standard, general term for cutting invalid or silent parts at the boundaries of a clip:

- Trim silence at start
- Trim silence at end

In Audacity this is **Crop Boundaries**.

**Silence Removal** — common in game audio; emphasizes automatic silence detection and deletion:

- Remove leading silence
- Remove trailing silence

Typical use cases: batch SFX processing, voice/dialogue preprocessing.

## Prerequisites

1. **FFmpeg** must be installed and on `PATH`.
   - Windows: `winget install Gyan.FFmpeg` or https://ffmpeg.org/download.html
   - macOS: `brew install ffmpeg`
   - Linux: `sudo apt install ffmpeg`
2. Verify: `ffmpeg -version`

## Quick Start

**Default:** trim start and end silence, threshold **-50 dB**, output to `<input>/trimmed/`:

```powershell
# Windows — file or folder
powershell -ExecutionPolicy Bypass -File scripts/trim.ps1 -Input "path/to/audio_or_folder"
```

```bash
# macOS / Linux — file or folder
bash scripts/trim.sh path/to/audio_or_folder
```

Scripts live in this skill directory: `.cursor/skills/audio-trim/scripts/`.

## When to Apply This Skill

- SFX exports have dead air before the hit or after the tail
- Voice lines need leading/trailing silence stripped before import
- Batch-cleaning a folder of clips before loudness normalization
- User mentions audio trim, trim, silence removal, leading silence, or trailing silence

## Recommended Pipeline

```
Audio Trim → Loudness Normalization → Export / Import
```

Run this skill first, then `audio-loudness-normalization` on the `trimmed/` output.

## Workflow

```
Task Progress:
- [ ] Confirm FFmpeg is available
- [ ] Identify input (single file or folder)
- [ ] Choose threshold and trim sides (start/end/both)
- [ ] Run trim script with -DryRun if user wants a preview
- [ ] Verify output in trimmed/ folder
- [ ] Spot-check 3–5 files — attacks and tails should feel tight, not clipped
- [ ] (Optional) Run loudness normalization on trimmed output
```

### Step 1 — Pick threshold and sides

| Asset type | Threshold | Notes |
|------------|-----------|-------|
| UI / SFX hits | -50 to -40 dB | Tighter threshold removes more room noise |
| Voice / dialogue | -50 dB | Default; lower if breath/noise gets trimmed |
| Ambience / loops | -60 dB | Be careful — long fades may look like silence |

**Default:** `-50 dB`, trim **both** start and end.

Use `-TrimStart $false` / `-TrimEnd $false` (PowerShell) or `--no-start` / `--no-end` (bash) to trim one side only.

### Step 2 — Run batch trim

**Windows (PowerShell):**

```powershell
# Single folder
powershell -ExecutionPolicy Bypass -File scripts/trim.ps1 `
  -Input "Audio/SFX" -Threshold -50

# Trim start only (remove leading silence)
powershell -ExecutionPolicy Bypass -File scripts/trim.ps1 `
  -Input "Audio/Voice" -TrimEnd $false

# Trim end only (remove trailing silence)
powershell -ExecutionPolicy Bypass -File scripts/trim.ps1 `
  -Input "Audio/SFX" -TrimStart $false

# Recursive subfolders
powershell -ExecutionPolicy Bypass -File scripts/trim.ps1 `
  -Input "Audio" -Recurse

# Custom output directory
powershell -ExecutionPolicy Bypass -File scripts/trim.ps1 `
  -Input "Audio/SFX" -OutputDir "Audio/SFX_trimmed"

# Preview without writing files
powershell -ExecutionPolicy Bypass -File scripts/trim.ps1 `
  -Input "Audio/SFX" -DryRun
```

**macOS / Linux (bash):**

```bash
bash scripts/trim.sh Audio/SFX
bash scripts/trim.sh Audio/Voice --no-end
bash scripts/trim.sh Audio/SFX --no-start
bash scripts/trim.sh Audio -r -t -45
bash scripts/trim.sh Audio/SFX -o Audio/SFX_trimmed
bash scripts/trim.sh Audio/SFX --dry-run
```

### Step 3 — Validate

- Confirm each output file exists and is shorter than (or equal to) the source
- Replay trimmed SFX — attack should start immediately; tail should not cut off reverb unnaturally
- For looping BGM, **do not** batch-trim without checking loop points

## Script Behavior

| Behavior | Detail |
|----------|--------|
| Input | Single audio file or directory |
| Supported formats | `.wav`, `.mp3`, `.ogg`, `.flac`, `.aac`, `.m4a`, `.wma` |
| Method | FFmpeg `silenceremove` filter |
| Output | Preserves relative paths under `trimmed/` (or `-OutputDir`) |
| Originals | Never modified — outputs are copies |
| Skip | Leaves existing output unchanged unless `-Overwrite` |

## Agent Instructions

1. **Prefer the bundled scripts** over ad-hoc one-liners — consistent defaults and batch layout.
2. If FFmpeg is missing, install it first; do not fall back to manual `-ss`/`-to` unless the user accepts imprecise cuts.
3. Recommend **Audio Trim before Loudness Normalization** when both are needed.
4. For **looping assets**, warn that end trim can break loop seams — trim manually or skip.
5. If clips sound clipped or breath is removed from voice, raise threshold (e.g. `-45` or `-40` dB) or trim one side only.

## Troubleshooting

| Issue | Fix |
|-------|-----|
| `ffmpeg` not found | Install FFmpeg and restart the terminal |
| Attack feels cut off | Threshold too aggressive — use `-40` or `-35` dB |
| Tail/reverb chopped | Disable end trim (`-TrimEnd $false` / `--no-end`) or raise threshold |
| File unchanged after trim | Source may already have no silence above threshold — expected |
| Loop click after trim | Re-check zero-crossing at loop point; do not batch-trim loops blindly |

## Additional Resources

- FFmpeg `silenceremove` parameters and category notes: [reference.md](reference.md)
