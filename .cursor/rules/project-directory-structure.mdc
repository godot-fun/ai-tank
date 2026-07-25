---
description: Project directory layout — resources by type, scenes and scripts at root
alwaysApply: true
---

# Project Directory Structure

Separate **framework**, **resources (by type)**, and **game code**. Do not mix them.

```
project-root/
├── zfoo/          # Framework only — sync/upgrade; no game business logic
├── assets/        # Extra assets (video, fonts, 3D, …)
├── audio/         # Audio assets
├── image/         # Image assets
├── config/        # CSV/JSON tables (optional)
├── shader/        # Custom shaders (optional)
├── scene/         # Runnable and instanced .tscn scenes
├── script/        # Game scripts (.gd), systems, data models
├── test/          # Unit tests (UnitTest.gd scenes)
└── project.godot
```

## Resource directories (no `.gd` logic)

**`image/`** — textures and sprites:

```
image/
├── ui/            # Buttons, panels, icons
├── characters/    # Character sprites and portraits
├── backgrounds/   # Scene backgrounds
├── tiles/         # Tilemap tiles
└── effects/       # VFX and particle textures
```

**`audio/`** — use with zfoo `Audio` API:

```
audio/
├── bgm/           # Looping background music
├── sfx/           # Short one-shot sound effects
└── voice/         # Voice-over and narration
```

**`assets/`** — video, fonts, 3D, and other extra binary assets:

```
assets/
├── video/         # Cutscenes, trailers, background video
├── font/          # Font files (.ttf, .otf, …)
├── 3d/            # Models, meshes, materials, animations
└── …              # Other misc assets as needed
```

**Other resource roots** (add when needed): `config/`, `shader/`.

## Game code — `scene/` and `script/`

```
scene/
├── boot/
├── main/
├── gameplay/
└── ui/

script/
├── autoload/      # Game Autoloads (after GodotFramework)
├── core/          # Constants, ResPath, shared base classes
├── data/          # Resource classes and .tres instances
├── systems/       # Pure logic (inventory, save, quest, …)
└── network/       # Packets and codec (zfoo Router)
```
