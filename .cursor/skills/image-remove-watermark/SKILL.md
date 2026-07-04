---
name: image-remove-watermark
description: >-
  Remove single corner image watermarks via LaMa/IOPaint inpainting. Auto-detects
  top-left or bottom-right watermark placement, generates masks, batch-runs iopaint CLI.
  Use when the user asks to remove watermarks, logo overlays, text stamps, corner
  marks, or inpaint masked regions with LaMa/IOPaint.
---

# Image Remove Watermark (IOPaint / LaMa)

Remove a **single small corner watermark** with LaMa semantic inpainting via IOPaint.

图片的水印只有一处，这个位置一般不是非常大，一般是左上角或者右下角。如果我没有告诉你是在左上角或者右下角，你需要自己去检测一下。

## Rules

When this skill applies, read and follow [skill-dependency-manager](../../rules/skill-dependency-manager.md) — run scripts as documented, install missing tools into `.dependency/`.

- Run `remove_watermark.py` and every `iopaint` invocation through the **`iopaint` manifest entry** (`.dependency/iopaint/.venv/`). Never use host `python`, `py`, `python3`, or any interpreter outside `.dependency/`.
- Do not hand-write `iopaint run` — use the bundled script.
- `populated: false` for `iopaint` is not a reason to skip. Install first, set `populated: true`, retry the same command.

## Setup (first run)

IOPaint needs **Python 3.11 or 3.12** (not the default 3.14 runtime). From project root:

```bash
git clone https://github.com/Sanster/IOPaint.git .dependency/iopaint
.dependency/python-3.11/python -m venv .dependency/iopaint/.venv
.dependency/iopaint/.venv/Scripts/python -m pip install torch torchvision --index-url https://download.pytorch.org/whl/cu118
.dependency/iopaint/.venv/Scripts/python -m pip install .dependency/iopaint
```

Register in `.dependency/manifest.json`:

```json
"iopaint": {
  "populated": true,
  "bin": ".dependency/iopaint/.venv/Scripts/python.exe"
}
```

Use `bin/python` on Unix. LaMa model downloads on first run (~hundreds of MB). GPU strongly recommended.

## Quick Start

**Default: auto-detect watermark corner** (top-left or bottom-right), then inpaint:

```bash
# Single file → writes to --output-dir (recommended for trials)
.dependency/iopaint/.venv/Scripts/python .cursor/skills/image-remove-watermark/scripts/remove_watermark.py image/title-screens/tank-battle-1.png --output-dir image/title-screens_clean

# Directory batch
.dependency/iopaint/.venv/Scripts/python .cursor/skills/image-remove-watermark/scripts/remove_watermark.py image/title-screens --output-dir image/title-screens_clean
```

No `--corner` needed — the script compares top-left vs bottom-right edge/contrast scores and picks the stronger candidate.

## When the user specifies the corner

```bash
.dependency/iopaint/.venv/Scripts/python .cursor/skills/image-remove-watermark/scripts/remove_watermark.py image/foo \
  --corner bottom-right --width 0.28 --height 0.10 --margin 0.02
```

## Other mask sources

| Method | Use case |
|--------|----------|
| *(none — default)* | Auto-detect top-left / bottom-right |
| `--corner top-left` etc. | User told you the corner |
| `--rect x,y,w,h` | Known pixel or percentage rectangle |
| `--mask path.png` / `--mask-dir masks/` | Hand-drawn mask (white = repair) |

```bash
# Percentage rectangle
.dependency/iopaint/.venv/Scripts/python .cursor/skills/image-remove-watermark/scripts/remove_watermark.py image/foo \
  --rect 80%,90%,18%,8% --output-dir image/foo_clean

# Preview masks only (verify auto-detect before inpainting)
.dependency/iopaint/.venv/Scripts/python .cursor/skills/image-remove-watermark/scripts/remove_watermark.py image/foo \
  --masks-only --output-dir image/foo
```

## Defaults

| Option | Default | Notes |
|--------|---------|-------|
| Mask | auto-detect | top-left vs bottom-right |
| `--width` / `--height` | 0.28 / 0.10 | Corner box as fraction of image |
| `--margin` | 0.02 | Inset from edge |
| `--expand` | 8 | Mask dilation px for edge blending |
| Model | `lama` | `--model mat` for alternate erase model |
| Device | `auto` | CUDA / MPS / CPU |
| Output | overwrite source | Use `--output-dir` for safe copies |

## Agent workflow

1. **Trial first** — run on 1 image with `--output-dir`, inspect result before batch.
2. **Corner unknown** — omit `--corner`; script auto-detects between top-left and bottom-right.
3. **Corner known** — pass `--corner top-left` or `--corner bottom-right`.
4. **Mask too tight / ghosting** — increase `--width`, `--height`, or `--expand`.
5. **Auto-detect wrong** — use `--masks-only`, inspect `_masks/`, then pass `--corner` or `--rect`.
6. **Transparent PNGs** — script preserves alpha outside the mask.
7. **Revert** — `git restore <path>` if overwriting originals.

## Troubleshooting

| Issue | Fix |
|-------|-----|
| `iopaint` missing | Follow **Setup**; update manifest |
| Very slow | `--device cuda`; CPU for single-image trials only |
| CUDA OOM | `--hd-limit 1536` or `--hd-limit 1024` |
| Wrong corner detected | Pass explicit `--corner`; or `--rect` |
| Repair area too small/large | Adjust `--width` / `--height` |

## Related

- Script: [scripts/remove_watermark.py](scripts/remove_watermark.py)
- IOPaint batch docs: https://www.iopaint.com/batch_process
