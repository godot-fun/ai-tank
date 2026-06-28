# Audio Attribution

Game SFX are **procedurally generated** from recipes in `prompt/audio/` using `scripts/generate_sfx.py`.

Each category folder contains 5 stereo variants (`01.wav`–`05.wav`) at 44.1 kHz / 16-bit.

Regenerate with: `py scripts/generate_sfx.py`

## Optional CC0 Source Packs

Raw CC0 downloads used by the alternate `scripts/download_sfx.py` pipeline are cached in `audio/_sources/` (Kenney / OpenGameArt). Not used by the default procedural generator.
