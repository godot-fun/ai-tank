# Skills

Batch asset tools — run from repo root; use each skill's script; never overwrite sources. Dependencies: [skill-dependency-manager](../rules/skill-dependency-manager.md). Commands and flags: see each skill's `SKILL.md`.

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

## Video

| Skill | Purpose |
|-------|---------|
| [video-to-ogv](video-to-ogv/SKILL.md) | Video → OGV |
| [video-to-wav](video-to-wav/SKILL.md) | Extract audio track → WAV |

## Other

| Skill | Purpose |
|-------|---------|
| [image-remove-watermark](image-remove-watermark/SKILL.md) | Remove corner watermark |
| [file-naming-normalization](file-naming-normalization/SKILL.md) | Filename → kebab-case |
| [git-commit-message](git-commit-message/SKILL.md) | Commit message |
