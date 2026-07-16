# Skills

Batch asset tools — run from repo root; use each skill's script; never overwrite sources. Dependencies: [skill-dependency-manager](../rules/skill-dependency-manager.md). Commands and flags: see each skill's `SKILL.md`.

## Categories

| Category | Pipeline | Skills |
|----------|----------|--------|
| [Audio](#audio) | Trim → denoise → normalize → export | 9 skills |
| [Image](#image) | PNG → watermark → split → background → trim → resize | 7 skills |
| [Video](#video) | Watermark → OGV → extract audio | 3 skills |
| [Other](#other) | Naming, commits | 2 skills |

## Audio

```
Source audio
    ↓
① Convert to working format (WAV recommended)
    ↓
② Trim leading/trailing silence
    ↓
③ Edit (cut, splice)
    ↓
④ Denoise / de-clip (if needed)
    ↓
⑤ Fade in/out (if needed)
    ↓
⑥ Adjust volume / loudness (normalize)
    ↓
⑦ Standardize sample rate (44100 / 48000 Hz WAV)
    ↓
⑧ Export final format (OGG / WAV)
```

| Skill | Purpose |
|-------|---------|
| [audio-to-wav](audio-to-wav/SKILL.md) | Audio → WAV |
| [audio-trim](audio-trim/SKILL.md) | Trim leading/trailing silence |
| [audio-split](audio-split/SKILL.md) | Split at a timestamp |
| [audio-denoise](audio-denoise/SKILL.md) | Denoise / de-clip |
| [audio-fade](audio-fade/SKILL.md) | Fade in/out |
| [audio-loudness-normalization](audio-loudness-normalization/SKILL.md) | LUFS loudness normalize |
| [audio-volume-adjust](audio-volume-adjust/SKILL.md) | Fixed dB gain (alternative) |
| [audio-sample-rate-standardize](audio-sample-rate-standardize/SKILL.md) | Standardize to 44100 / 48000 Hz WAV |
| [audio-to-ogg](audio-to-ogg/SKILL.md) | Audio → OGG (BGM) |

## Image

```
Source image (AI art / sprite sheet)
    ↓
① Convert to PNG (if needed)
    ↓
② Remove Gemini watermark (if needed)
    ↓
③ Split sprite sheet grid → frames (if sheet)
    ↓
④ Remove background
   · flat white / green / magenta → color key (this skill)
   · complex / photo backgrounds → AI matting (rembg)
    ↓
⑤ Trim invalid borders / transparent padding (optional)
    ↓
⑥ Resize to target width × height (optional)
    ↓
⑦ Filename normalization (optional)
```

| Skill | Purpose |
|-------|---------|
| [image-to-png](image-to-png/SKILL.md) | Image → PNG |
| [image-remove-watermark-gemini](image-remove-watermark-gemini/SKILL.md) | Remove Gemini sparkle watermark |
| [image-sprite-sheet-split](image-sprite-sheet-split/SKILL.md) | Split sprite sheet grid → individual frame PNGs |
| [image-remove-white-background](image-remove-white-background/SKILL.md) | Remove flat white / green / magenta backgrounds (color key; default `global` mode; also `border` / `center` / `both`) |
| [image-remove-background](image-remove-background/SKILL.md) | Remove background / image → transparent PNG (AI matting) |
| [image-trim](image-trim/SKILL.md) | Trim transparent or solid-color borders (preserve aspect ratio by default) |
| [image-resize](image-resize/SKILL.md) | Resize to explicit width × height (fit / fill / exact; ImageMagick) |

## Video

Veo / Gemini generated cutscenes and UI clips — remove the visible corner watermark, export Godot-ready OGV, optionally rip the audio track.

```
Source video (Veo / Gemini generated)
    ↓
① Remove Gemini / Veo watermark (if needed)
    ↓
② Convert to OGV (for Godot)
    ↓
③ Extract audio track → WAV (optional)
```

| Skill | Purpose |
|-------|---------|
| [video-remove-watermark-gemini](video-remove-watermark-gemini/SKILL.md) | Remove Gemini / Veo visible watermark (reverse alpha; audio passthrough) |
| [video-to-ogv](video-to-ogv/SKILL.md) | Video → OGV |
| [video-to-wav](video-to-wav/SKILL.md) | Extract audio track → WAV |

## Other

| Skill | Purpose                                     |
|-------|---------------------------------------------|
| [file-naming-normalization](file-naming-normalization/SKILL.md) | Filename → kebab-case                       |
| [git-commit-message](git-commit-message/SKILL.md) | Commit message                              |
