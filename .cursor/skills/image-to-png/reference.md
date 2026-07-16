# Image to PNG — Reference

## Default Command Shape (preserve quality)

Per file, the script probes with `ffprobe` then builds:

```bash
# JPEG / WebP / BMP — lossless PNG encode, dimensions preserved
ffmpeg -i input.webp -c:v png output.png

# PNG source — stream copy (bit-perfect)
ffmpeg -i input.png -c:v copy output.png

# GIF — first frame only (default)
ffmpeg -i input.gif -frames:v 1 -c:v png output.png
```

## Optional Flags

| Flag | Effect |
|------|--------|
| (default) | Preserve dimensions and alpha |
| `--strip-alpha` | Force RGB24 output (no alpha channel) |
| `-o` / `--output-dir` | Custom output root |
| `-r` / `--recurse` | Process subdirectories |

## Alpha Handling

| Source | Default output |
|--------|----------------|
| JPEG / BMP (no alpha) | RGB PNG |
| WebP / PNG with alpha | RGBA PNG |
| `--strip-alpha` | RGB24 PNG |

## Supported Input Formats

`.jpg`, `.jpeg`, `.png`, `.webp`, `.gif`, `.bmp`, `.tif`, `.tiff`, `.avif`, `.ico`

## Output Layout

For `assets/ui/icon.webp` with default output dir:

```
assets/ui/png/icon.png
```

Batch with `-r` preserves subdirectory structure under the output root.
