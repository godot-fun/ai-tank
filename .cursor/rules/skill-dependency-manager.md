---
description: Skill dependency manager — run skill scripts, install missing tools into .dependency/
alwaysApply: false
---

# Skill Dependency Manager

## Run skill scripts

When a skill has scripts, run them from the project root as the skill docs say. Do not use your own commands unless the skill says the script is for reference only.

### No bypass

Even when a skill script wraps FFmpeg or another CLI, call it through the skill script — do not hand-write equivalent commands.

### Workflow

1. Find the script and command in the skill docs.
2. Run it. If something is missing, install it (see **Dependencies** below or skill setup steps), then run the same command again.
3. If it fails, fix the setup or inputs and try again. Ask before using a different approach.

After installing anything, say what you installed and which command you ran.

## Dependencies

External CLIs and language runtimes install into `.dependency/`. Do not put project/business packages (pip/npm/cargo) here.

| Kind | Name examples |
|------|---------------|
| Language runtime | `python`, `python-3.11`, `node-20`, `rust-1.75`, `go-1.22` |
| CLI tool | `ffmpeg`, `git`, `jq`, `curl`, `imagemagick` |

**Root:** `.dependency/`  
**Manifest:** `.dependency/manifest.json`

Each name is a dedicated install directory under `.dependency/`. After populating, set `populated: true` and correct `bin` paths in the manifest.

`populated: false` in `.dependency/manifest.json` is not a reason to skip a skill script. Install the missing tool here first, then run the same skill command again.

### Python default version

When a skill does **not** specify a Python version, assume **Python 3.14** as the default runtime.

- Install to `.dependency/python/` and register as the `python` entry in `manifest.json`.
- Skills that only reference `python` (no version suffix) rely on this default.
- If a skill explicitly requires another version (e.g. `python-3.11`), use a separate manifest entry and install directory instead.

### manifest.json

Top-level keys match install directory names. Each entry:

| Field | Type | Description |
|-------|------|-------------|
| `populated` | boolean | Whether the install directory contains a valid upstream toolchain |
| `bin` | string \| string[] | Executable path(s), relative to repo root |

Example:

```json
{
  "python": {
    "populated": false,
    "bin": ".dependency/python/python"
  },
  "ffmpeg": {
    "populated": true,
    "bin": ".dependency/ffmpeg/bin/ffmpeg"
  }
}
```
