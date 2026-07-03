---
name: audio-fade
description: Applies fade-in and fade-out at the start and end of audio files using FFmpeg. Use when the user wants audio fade, fade in/out, smooth attack/release, crossfade prep, batch SFX envelope shaping, or mentions afade.
---

# Audio Fade

Apply **fade-in** at the start and **fade-out** at the end without changing clip length.

## Rules

When this skill applies, read and follow [skill-dependency-manager](../../rules/skill-dependency-manager.md) — run scripts as documented, install missing tools into `.dependency/`.

## Quick Start

Default: **1 s** fade-in and fade-out, output to `faded/`:

```bash
.dependency/python/python .cursor/skills/audio-fade/scripts/fade.py path/to/audio_or_folder
```

Fade-in only (keep full end level):

```bash
.dependency/python/python .cursor/skills/audio-fade/scripts/fade.py path/to/audio.wav --no-fade-out
```

Custom durations (seconds):

```bash
.dependency/python/python .cursor/skills/audio-fade/scripts/fade.py Audio/SFX -fi 0.05 -fo 0.15 -r
```

## Duration Guidelines

| Asset | Fade-in | Fade-out |
|-------|---------|----------|
| UI clicks / ticks | 0.01–0.05 s | 0.02–0.08 s |
| Impacts / weapons | 0.02–0.08 s | 0.05–0.15 s |
| Voice lines | 0.05–0.15 s | 0.1–0.25 s |
| Ambience beds | 0.3–1.0 s | 0.5–2.0 s |
| BGM one-shots | 0.2–0.5 s | 0.3–1.0 s |

Fade-in + fade-out must stay **shorter than file duration**. Very short clips need smaller values.

## Common Flags

`-fi` / `--fade-in` · `-fo` / `--fade-out` · `--no-fade-in` · `--no-fade-out` · `-c` / `--curve` · `-r` · `-o` / `--output-dir` · `--dry-run` · `--overwrite`

```bash
.dependency/python/python .cursor/skills/audio-fade/scripts/fade.py Audio/SFX -fi 0.03 -fo 0.08 -c exp -r --dry-run
```

Originals are never modified. Supported: `.wav`, `.mp3`, `.ogg`, `.flac`, `.aac`, `.m4a`, `.wma`.

## Agent Notes

1. Use the bundled script, not hand-written `afade` filters.
2. **Looping BGM** — avoid fade-out on loop assets; use `--no-fade-out` or fade-in only for one-shot intros.
3. Clicks with instant attack → `--no-fade-in` or lower `-fi` (e.g. `0.01`).
4. Tail cut off abruptly after fade → increase `-fo`; tail too soft → decrease `-fo`.
5. FFmpeg filter details and curves: [reference.md](reference.md)
