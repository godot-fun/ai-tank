# Video Remove Audio — Reference

## Default Command Shape (stream copy)

Per file, the script probes for audio streams, then builds:

```bash
# Drop all audio; copy video bitstream unchanged
ffmpeg -i input.mp4 -map 0:v -c:v copy -an output.mp4
```

`-map 0:v` keeps every video stream. `-an` discards all audio. Subtitles/data streams are not mapped by default (video-only mute export).

## Optional Re-encode

Use only when stream copy fails for the container or the user asks:

```bash
# libx264 + CRF 18 (high quality), no audio
ffmpeg -i input.mp4 -map 0:v -c:v libx264 -crf 18 -preset medium -an output.mp4
```

| Flag | Effect |
|------|--------|
| (default) | `-c:v copy -an` |
| `--reencode` | H.264 CRF 18, no audio |

## Already Silent

If `ffprobe` finds no audio streams, the file is skipped (`[skip]`) unless `--overwrite` would still write — silent sources are always skipped to avoid pointless copies.

## Notes

- Stream copy is bit-perfect for the video track; container remux may still change muxer metadata.
- Some players show a “no audio” track list; that is expected.
- For extracting (not removing) audio, see **video-to-wav**.
