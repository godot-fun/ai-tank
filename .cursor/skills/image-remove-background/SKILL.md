---
name: image-remove-background
description: >-
  Removes image backgrounds and exports transparent PNGs using rembg (U2Net / BiRefNet).
  Use when the user wants background removal, matting, cutout, 抠图, transparent sprites,
  alpha PNG export, or batch-remove backgrounds from game/UI assets.
---

# Image Remove Background (rembg)

Remove image backgrounds with AI matting via **rembg**. Output is **RGBA PNG** with transparent background — ready for Godot sprites and UI.

## Rules

When this skill applies, read and follow [skill-dependency-manager](../../rules/skill-dependency-manager.md) — run scripts as documented, install missing tools into `.dependency/`.

- Run `remove_background.py` through the **`rembg` manifest entry** (`.dependency/rembg/.venv/`). Never use host `python`, `py`, `python3`, or any interpreter outside `.dependency/`.
- Do not hand-write `rembg i` / `rembg p` — use the bundled script.
- `populated: false` for `rembg` is not a reason to skip. Install first, set `populated: true`, retry the same command.
- Pass the input path as-is (chat attachment path, `Downloads/foo.png`, project folder, etc.). Output goes to `<input>/transparent/` by default — no path rewriting.

## Setup (first run)

From project root:

```bash
.dependency/python/python -m venv .dependency/rembg/.venv
.dependency/rembg/.venv/Scripts/python -m pip install "rembg[cpu]"
```

GPU (CUDA) — faster batch processing:

```bash
.dependency/rembg/.venv/Scripts/python -m pip install "rembg[gpu]"
```

Register in `.dependency/manifest.json`:

```json
"rembg": {
  "populated": true,
  "bin": ".dependency/rembg/.venv/Scripts/python.exe"
}
```

Use `bin/python` on Unix. Model weights download on first run (~hundreds of MB).

## Quick Start

**Default: create a `transparent/` folder under the input path** and write outputs there (never overwrites sources):

```bash
# Single file → image/sprites/transparent/hero.png
.dependency/rembg/.venv/Scripts/python .cursor/skills/image-remove-background/scripts/remove_background.py image/sprites/hero.png

# Directory batch → image/sprites/hero/transparent/<relative-path>.png
.dependency/rembg/.venv/Scripts/python .cursor/skills/image-remove-background/scripts/remove_background.py image/sprites/hero -r
# e.g. image/sprites/hero/sub/foo.png → image/sprites/hero/transparent/sub/foo.png
```

Custom output directory:

```bash
.dependency/rembg/.venv/Scripts/python .cursor/skills/image-remove-background/scripts/remove_background.py image/sprites/hero \
  --output-dir image/sprites/hero_cutout
```

## Model selection

| Model | Use case |
|-------|----------|
| `u2net` *(default)* | General objects, icons, props |
| `u2netp` | Faster / lighter; smaller assets |
| `isnet-general-use` | Higher quality general matting |
| `birefnet-general` | Best general quality (slower) |
| `birefnet-portrait` | Characters / portraits |
| `u2net_human_seg` | Human figures only |

```bash
.dependency/rembg/.venv/Scripts/python .cursor/skills/image-remove-background/scripts/remove_background.py image/characters \
  --model birefnet-portrait --output-dir image/characters_cutout
```

## Edge quality (alpha matting)

For hair, fur, or soft edges, enable alpha matting:

```bash
.dependency/rembg/.venv/Scripts/python .cursor/skills/image-remove-background/scripts/remove_background.py image/portrait.png \
  --alpha-matting --output-dir image/portrait_cutout
```

## Defaults

| Option | Default | Notes |
|--------|---------|-------|
| Output | `<input-path>/transparent/` | Folder is auto-created under the file or directory you pass; use `--output-dir` for a custom path |
| `--model` | `u2net` | See table above |
| `--pattern` | `*.png` | Also matches `.jpg`, `.jpeg`, `.webp` |
| `--alpha-matting` | off | Enable for fine edge detail |
| `--crop` | off | Trim transparent borders after matting |
| Overwrite | off | Pass `--overwrite` to replace existing outputs |

## Agent workflow

1. **Paths** — Pass whatever path the user gives or the chat `<image_files>` path directly. Output lands in `transparent/` next to that input.
2. **Trial first** — run on 1 image, inspect the `transparent/` or `--output-dir` result before batch.
3. **Pick model** — `u2net` for generic assets; `birefnet-portrait` for characters; `birefnet-general` when quality matters.
4. **Soft edges** — try `--alpha-matting` if halos or jagged hair/fur appear.
5. **Sprite sheets** — skip `*_sheet.png` by default; process individual frames unless the user asks otherwise.
6. **Already transparent** — script still runs; rembg re-mats from visible RGB. Warn user if source already has alpha.
7. **Revert** — delete output folder or `git restore` if needed; sources are never modified.

## Troubleshooting

| Issue | Fix |
|-------|-----|
| `rembg` missing | Follow **Setup**; update manifest |
| Very slow | Install `rembg[gpu]`; try `--model u2netp` |
| Jagged edges | `--alpha-matting` |
| Wrong subject removed | Switch model; try `birefnet-general` |
| Leftover background color | Re-run with `--alpha-matting`; check source contrast |
| OOM on large images | Script auto-downscales inputs above 4096 px longest side |

## Related

- Flat white/green/magenta AI backgrounds: [image-remove-white-background](../image-remove-white-background/SKILL.md) (prefer over rembg)
- rembg docs: https://github.com/danielgatis/rembg
