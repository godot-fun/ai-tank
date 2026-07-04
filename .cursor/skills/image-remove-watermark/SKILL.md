---
name: image-remove-watermark
description: >-
  Remove image watermarks via LaMa/IOPaint deep-learning inpainting. Generates
  or accepts masks, batch-runs iopaint CLI. Use when the user asks to remove
  watermarks, logo overlays, text stamps, or inpaint masked regions with LaMa/MAT.
---

# Image Remove Watermark (LaMa / IOPaint)

Use **LaMa** and other inpainting models to semantically repaint watermark regions defined by a mask. Best quality ceiling for large watermarks and semi-transparent logos over fine detail.

| Pros | Cons |
|------|------|
| Better on large watermarks and detail-heavy areas | GPU strongly recommended; models are large |
| IOPaint has a CLI for scripting | Heavy deps (PyTorch, etc.) |
| | Slow batch runs; first-time setup is heavy |

**vs whole-image background removal**: this skill only repairs small masked regions and keeps the rest of the image intact.

## Rules

When this skill applies, read and follow [skill-dependency-manager](../../rules/skill-dependency-manager.md) — run scripts as documented, install missing tools into `.dependency/`.

Additional constraints for this skill:

- Run `remove_watermark.py` and every `iopaint` invocation through the **`iopaint` manifest entry** (`.dependency/iopaint/.venv/`). Never use host `python`, `py`, `python3`, or any interpreter outside `.dependency/`.
- Resolve executable paths from `.dependency/manifest.json` → `iopaint.bin`. Skill examples use shorthand; substitute the manifest path when running.
- Do not hand-write `iopaint run` or other equivalent bypasses — use the bundled script unless the skill marks the script as reference-only.
- `populated: false` for `iopaint` is not a reason to skip the script. Install first, set `populated: true`, then retry the **same** command. After installing, say what you installed and which command you ran.

## Setup (first run)

IOPaint is a **Python third-party tool**. Follow skill-dependency-manager **Python third-party tools (.venv)**; IOPaint-specific notes below.

### Python version

IOPaint pins older Pillow and depends on PyTorch wheels. Use **Python 3.11 or 3.12** — install as `.dependency/python-3.11/` (or `python-3.12`) and register a separate manifest entry. Do **not** use the default `python` (3.14) runtime for this venv.

Check the cloned repo (`setup.py`, `requirements.txt`) if upstream changes; when still unspecified, prefer `python-3.11`.

### Install

From the project root:

```bash
# 1. Clone upstream (clone root = .dependency/iopaint/)
git clone https://github.com/Sanster/IOPaint.git .dependency/iopaint

# 2. Create venv with the manifest Python runtime (3.11 example)
.dependency/python-3.11/python -m venv .dependency/iopaint/.venv

# 3. GPU — install CUDA PyTorch first, then IOPaint from the clone (recommended)
.dependency/iopaint/.venv/Scripts/python -m pip install torch torchvision --index-url https://download.pytorch.org/whl/cu118
.dependency/iopaint/.venv/Scripts/python -m pip install .dependency/iopaint

# CPU — single-image trials only
.dependency/iopaint/.venv/Scripts/python -m pip install torch torchvision
.dependency/iopaint/.venv/Scripts/python -m pip install .dependency/iopaint
```

On Unix, use `.dependency/iopaint/.venv/bin/python` instead of `Scripts/python`.

Register in `.dependency/manifest.json`:

```json
"iopaint": {
  "populated": true,
  "bin": ".dependency/iopaint/.venv/Scripts/python.exe"
}
```

Use `bin/python` on Unix. The LaMa model downloads automatically on first run (~hundreds of MB).

## Quick Start

Pick a mask source, then run from the project root. The first argument may be a **directory or a single image file**:

```bash
# Directory batch
.dependency/iopaint/.venv/Scripts/python .cursor/skills/image-remove-watermark/scripts/remove_watermark.py image/_watermark_trial \
  --corner bottom-right --width 0.28 --height 0.10 --margin 0.02

# Single file (writes back to the same file path)
.dependency/iopaint/.venv/Scripts/python .cursor/skills/image-remove-watermark/scripts/remove_watermark.py image/_watermark_trial/tank.png \
  --rect 12%,76%,76%,22%

# Recursive subdirectories (-r)
.dependency/iopaint/.venv/Scripts/python .cursor/skills/image-remove-watermark/scripts/remove_watermark.py image -r \
  --corner bottom-right --width 0.05 --height 0.10
```

Default output: **overwrite each source file at its original path** (same directory, same filename). Use `--output-dir` only when you want copies elsewhere (keeps relative subpaths under the input directory).

## Mask sources (pick one)

| Method | Use case |
|--------|----------|
| `--corner bottom-right` etc. | Fixed corner logo / text watermark |
| `--rect x,y,w,h` | Known pixel or percentage rectangle |
| `--mask path.png` or `--mask-dir masks/` | Hand-drawn mask (white = repair, black = keep) |

Interactive mask painting (through the iopaint venv):

```bash
.dependency/iopaint/.venv/Scripts/python -m iopaint start --model=lama --device=cuda --port=8080
```

Paint in the browser, export the mask, then pass `--mask` or `--mask-dir`.

## Examples

```bash
# Fixed rectangle (pixels)
.dependency/iopaint/.venv/Scripts/python .cursor/skills/image-remove-watermark/scripts/remove_watermark.py image/foo \
  --rect 820,900,180,80

# Percentage rectangle (relative to each image size)
.dependency/iopaint/.venv/Scripts/python .cursor/skills/image-remove-watermark/scripts/remove_watermark.py image/foo \
  --rect 80%,90%,18%,8%

# Existing mask directory (filenames match source images)
.dependency/iopaint/.venv/Scripts/python .cursor/skills/image-remove-watermark/scripts/remove_watermark.py image/foo \
  --mask-dir image/foo/_masks

# Single mask applied to all images
.dependency/iopaint/.venv/Scripts/python .cursor/skills/image-remove-watermark/scripts/remove_watermark.py image/foo \
  --mask path/to/watermark_mask.png

# Write to a separate directory instead
.dependency/iopaint/.venv/Scripts/python .cursor/skills/image-remove-watermark/scripts/remove_watermark.py image/foo \
  --corner bottom-right --output-dir image/foo_clean

# Generate masks only, skip the model
.dependency/iopaint/.venv/Scripts/python .cursor/skills/image-remove-watermark/scripts/remove_watermark.py image/foo \
  --corner bottom-right --masks-only
```

## Defaults

| Option | Default | Notes |
|--------|---------|-------|
| Directory | `image` | Relative to project root |
| Pattern | `*.png` | glob |
| Model | `lama` | Also `mat` and other IOPaint erase models |
| Device | `auto` | Uses CUDA/MPS when available |
| Output | original file path | Overwrites in place; `--output-dir` writes copies elsewhere |
| `--expand` | `8` | Mask dilation in pixels for edge blending |
| HD strategy | auto | By image size + device; `--hd-limit` / `--config` to override |

## Pipeline

```
Source image + mask definition (corner / rect / external PNG)
  → Generate per-image mask sized to each image (white = inpaint)
  → Optional dilate to expand mask
  → iopaint run --model=lama semantic repaint
  → Overwrite each source file at its original path (or --output-dir for copies)
```

Mask convention: **white (255) = region to repair, black (0) = keep**.

**Transparent backgrounds**: IOPaint outputs RGB and drops alpha. The script **replaces RGB only inside the mask** after inpainting; pixels outside the mask keep the original RGBA (transparent areas are not filled with black).

## Models and quality

- **Default `lama`**: Fast with strong erase quality; best for batch work.
- **HD strategy is automatic** — the script picks IOPaint settings from image size and device:
  - Max side ≤ 1280px: IOPaint defaults (no config file)
  - Max side > 1280px: `Resize` with limit 2048 (CUDA), 1536 (MPS), or 1024 (CPU)
- **CUDA OOM** on large images: pass `--hd-limit 1536` or `--hd-limit 1024`
- **Manual override** (rare): `--config path/to/custom.json`

## Agent Notes

1. Use the bundled script — not hand-written `iopaint run` or host Python.
2. Missing or unpopulated `iopaint` → follow **Setup**, update manifest, retry the same command.
3. GPU recommended; first run downloads the model; batch runs are slow on CPU.
4. Trial on **1 image** before full batch; use `git restore` if results need reverting.
5. If the mask is tight, increase `--expand` or `--width` / `--height`.
6. Verify: watermark gone, texture continuous, no obvious smear blocks.
7. Restore originals: `git restore <directory>`.

## Troubleshooting

| Issue | Fix |
|-------|-----|
| `iopaint` missing or `populated: false` | Follow **Setup**; set `populated: true`, retry same command |
| Used host Python / wrong venv | Use only manifest `iopaint.bin` under `.dependency/` |
| Very slow | `--device cuda`; CPU is for single-image trials only |
| CUDA OOM | Pass `--hd-limit 1536` or `--hd-limit 1024` |
| Edge ghosting | Increase `--expand` or enlarge the mask rectangle |
| Repair area too large/small | Adjust `--corner` / `--rect` / hand-drawn mask |
| Auto mask inaccurate | `--masks-only`, edit masks manually, then `--mask-dir` |
| Pillow / torch install fails | Confirm Python 3.11 or 3.12 runtime, not 3.14 |

## Related

- IOPaint batch docs: https://www.iopaint.com/batch_process
- Script: [scripts/remove_watermark.py](scripts/remove_watermark.py)
