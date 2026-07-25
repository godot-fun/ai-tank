---
name: video-remove-audio
description: Removes all audio and music tracks from video files using FFmpeg, keeping the video stream (stream copy by default). Use when the user wants to mute a video, strip audio, remove soundtrack/BGM/music from MP4/MKV/MOV/WebM, export silent video, or batch-remove audio from cutscenes.
---

# Video Remove Audio

Strip **all audio tracks** (music, voice, SFX) from supported video files via FFmpeg. **Defaults preserve the video bitstream** — stream-copy video (`-c:v copy`), drop audio (`-an`), no re-encode.

## Rules

When this skill applies, read and follow [skill-dependency-manager](../../rules/skill-dependency-manager.md) — run scripts as documented, install missing tools into `.dependency/`.

## Quick Start

Mute a file or folder, output to `silent/`:

```bash
.dependency/python/python .cursor/skills/video-remove-audio/scripts/remove_audio.py path/to/video_or_folder
```

Example: `assets/intro.mp4` → `assets/silent/intro.mp4` (same video codec/container, no audio)

Batch with subfolders:

```bash
.dependency/python/python .cursor/skills/video-remove-audio/scripts/remove_audio.py Video/Cutscenes -r
```

## Format Defaults

| Setting | Default | Notes |
|---------|---------|-------|
| Video | Stream copy | No quality loss; same codec/resolution/fps |
| Audio | Removed (`-an`) | Drops every audio stream |
| Container | Same as source | Extension preserved |
| Already silent | Skipped | Reports `[skip]` when no audio streams |

## Common Flags

`-r` · `-o` / `--output-dir` · `--reencode` · `--dry-run` · `--overwrite`

Force video re-encode (only if stream copy fails for the container):

```bash
.dependency/python/python .cursor/skills/video-remove-audio/scripts/remove_audio.py clip.mp4 --reencode
```

**Never overwrite source files.** The script writes only to `silent/` (or `-o`). Supported inputs: `.mp4`, `.mkv`, `.mov`, `.avi`, `.webm`, `.wmv`, `.flv`, `.m4v`, `.mpeg`, `.mpg`, `.ts`, `.mts`, `.m2ts`, `.3gp`, `.ogv`, `.ogg`.

## Agent Notes

1. Use the bundled script, not hand-written `ffmpeg -i … -an` commands.
2. **Prefer stream copy** — omit `--reencode` unless FFmpeg fails or the user asks to re-encode.
3. This removes **all** audio; it does **not** isolate or mute music while keeping dialogue (no stem separation).
4. Missing Python/FFmpeg → populate `.dependency/` per skill-dependency-manager, retry same command.
5. **Do not copy, move, or replace the source with muted output** — tell the user where `silent/` files are; they swap assets manually when ready.
6. Need audio extracted instead of removed → use **video-to-wav**.
7. FFmpeg details: [reference.md](reference.md)
