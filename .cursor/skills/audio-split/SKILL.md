---
name: audio-split
description: Splits audio files into two segments (part 1 before the split point, part 2 after) using FFmpeg. Use when the user wants to split audio, divide a clip into two parts, cut at a timestamp, separate intro from body, or batch-split SFX at a fixed time.
---

# Audio Split

Split one audio file into **part 1** (start → split point) and **part 2** (split point → end).

## Rules

When this skill applies, read and follow [skill-dependency-manager](../../rules/skill-dependency-manager.md) — run scripts as documented, install missing tools into `.dependency/`.

## Quick Start

Default: split at **50%** of duration, output to `split/`:

```bash
.dependency/python/python .cursor/skills/audio-split/scripts/split.py path/to/audio.wav
```

Split at a specific time (seconds):

```bash
.dependency/python/python .cursor/skills/audio-split/scripts/split.py path/to/audio.wav -s 1.25
```

Outputs: `basename_part1.ext` and `basename_part2.ext`.

## Split Point

Provide **one** of:

| Flag | Meaning |
|------|---------|
| `-s` / `--split-at` | Time in seconds (e.g. `1.25`, `90`) |
| `-p` / `--percent` | Position as percent of duration (e.g. `50` = midpoint) |
| *(none)* | Defaults to **50%** |

If both `-s` and `-p` are given, `-s` wins.

## Common Flags

`-s` / `--split-at` · `-p` / `--percent` · `-r` · `-o` / `--output-dir` · `--dry-run` · `--overwrite`

```bash
.dependency/python/python .cursor/skills/audio-split/scripts/split.py Audio/SFX -s 0.4 -r --dry-run
```

Originals are never modified. Supported: `.wav`, `.mp3`, `.ogg`, `.flac`, `.aac`, `.m4a`, `.wma`.

## Agent Notes

1. Use the bundled script, not hand-written `-ss`/`-to` commands.
2. **Looping BGM** — splitting breaks the loop; prefer two source assets or manual crossfade planning.
3. Split point at `0` or at/after duration → script errors with a clear message.
4. FFmpeg details and manual fallback: [reference.md](reference.md)
