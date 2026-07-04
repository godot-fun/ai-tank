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

External CLIs, language runtimes, and skill-only toolchains install into `.dependency/`. Do not put **project/business** packages here (Godot addons, game server deps, app `requirements.txt`, etc.).

| Kind | Name examples | Install location |
|------|---------------|------------------|
| Language runtime | `python`, `python-3.11`, `node-20`, `rust-1.75`, `go-1.22` | `.dependency/<name>/` |
| CLI tool (standalone binary) | `ffmpeg`, `git`, `jq`, `curl`, `imagemagick` | `.dependency/<name>/` |
| Python third-party tool | `iopaint`, `rembg`, cloned GitHub projects | `.dependency/<name>/.venv/` |

**Root:** `.dependency/`  
**Manifest:** `.dependency/manifest.json`

Each manifest name maps to a dedicated directory under `.dependency/`. After populating, set `populated: true` and correct `bin` paths in the manifest.

`populated: false` in `.dependency/manifest.json` is not a reason to skip a skill script. Install the missing tool here first, then run the same skill command again.

### Language runtimes — `.dependency/` only

**Never** use a language runtime from outside `.dependency/`.

This applies to every runtime in the table above (`python`, `python-3.11`, `node-20`, `rust-1.75`, `go-1.22`, etc.).

**Forbidden** — do not invoke, discover, or fall back to any of these:

- Commands on the host PATH or version managers — e.g. `python`, `py`, `python3`, `node`, `npm`, `cargo`, `go`, `pyenv`, `nvm`, `rustup`
- **Any absolute path** to an interpreter outside `.dependency/` — e.g. `C:\Python314\python.exe`, `/usr/bin/python3`, `~/miniconda3/python`
- **Host virtual environments** anywhere on disk — `.venv/`, `venv/`, `env/` under the user profile, other repos, Desktop, Downloads, `AppData`, `Program Files`, `~/.local`, etc.
- **Conda / Miniconda / Anaconda** base or named envs
- **IDE- or editor-bundled** runtimes (Cursor, VS Code, PyCharm, etc.)
- **Other projects'** Python/Node installs, even if they already have the package you need

The **only** allowed interpreter paths are `bin` values in `.dependency/manifest.json` (which must live under `.dependency/`). For Python third-party tools, that includes venvs at `.dependency/<tool-name>/.venv/` only.

- Resolve the runtime from `manifest.json` → `<entry>.bin`.
- If `populated: false`, install that runtime under `.dependency/` first — do **not** fall back to any host install.
- Skill docs may show shorthand (`python`, `py`, `node`); always substitute the manifest `bin` path when running commands.
- If a command fails, fix the `.dependency/` install — never retry with a different host Python or venv.

### Python default version

When a skill does **not** specify a Python version, assume **Python 3.14** as the default runtime.

- Install to `.dependency/python/` and register as the `python` entry in `manifest.json`.
- Skills that only reference `python` (no version suffix) rely on this default.
- If a skill explicitly requires another version (e.g. `python-3.11`), use a separate manifest entry and install directory instead.

The `python` runtime is for **stdlib-only** skill scripts (e.g. audio wrappers). Do **not** `pip install` into `.dependency/python/` itself.

### Python third-party tools (`.venv`)

When a skill depends on a Python package or a GitHub project with pip dependencies (e.g. IOPaint, PyTorch, rembg), follow this order:

1. **Clone the upstream project** into `.dependency/<tool-name>/`:

   ```bash
   git clone https://github.com/example/iopaint .dependency/iopaint
   ```

   The clone root is `.dependency/<tool-name>/`; `.venv` is created as a sibling inside that directory.

2. **Determine the required Python version** from the cloned project — check `pyproject.toml`, `.python-version`, `setup.py`, `setup.cfg`, `requirements.txt`, or `README`. If the project does not pin a version, fall back to the skill docs; if still unspecified, use the default `python` entry (**3.14**).

3. **Ensure that Python runtime exists** — look up the matching entry in `manifest.json` (e.g. `python` or `python-3.11`). If missing or `populated: false`, install it under `.dependency/` first (see **Python default version**). Use only that entry's `bin` (see **Language runtimes — `.dependency/` only**).

4. **Create `.venv`** at `.dependency/<tool-name>/.venv/` with that runtime:

   ```bash
   # default — Python 3.14
   .dependency/python/python -m venv .dependency/iopaint/.venv

   # project requires Python 3.11
   .dependency/python-3.11/python -m venv .dependency/iopaint/.venv
   ```

5. **Install dependencies** only inside that venv — never into system Python or the bare runtime:

   ```bash
   # from cloned repo
   .dependency/iopaint/.venv/Scripts/python.exe -m pip install .
   .dependency/iopaint/.venv/Scripts/python.exe -m pip install -r requirements.txt

   # extra packages named by the skill
   .dependency/iopaint/.venv/Scripts/python.exe -m pip install torch torchvision
   ```

   On Unix, use `.dependency/iopaint/.venv/bin/python` instead of `Scripts/python.exe`.

6. **Register** in `manifest.json` with `bin` pointing at the venv's Python interpreter. On Windows use `Scripts/python.exe`, on Unix use `bin/python`.

7. **Run** skill scripts and tool CLIs through the venv interpreter:

   ```bash
   .dependency/iopaint/.venv/Scripts/python.exe .cursor/skills/image-remove-watermark/scripts/remove_watermark.py ...
   .dependency/iopaint/.venv/Scripts/python.exe -m iopaint run ...
   ```

   Prefer the venv's `python -m <module>` when a console script is missing.

### manifest.json

Top-level keys match install directory names. Each entry:

| Field | Type | Description |
|-------|------|-------------|
| `populated` | boolean | Whether the install directory contains a valid upstream toolchain |
| `bin` | string | Executable path, relative to repo root |

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
  },
  "iopaint": {
    "populated": true,
    "bin": ".dependency/iopaint/.venv/Scripts/python.exe"
  }
}
```
