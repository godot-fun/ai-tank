# Audio Split — Reference

## Output Naming

For `Audio/SFX/click.wav` with default output dir:

```
Audio/SFX/split/click_part1.wav   # start → split point
Audio/SFX/split/click_part2.wav   # split point → end
```

| Segment | Range | Typical use |
|---------|-------|-------------|
| **part 1** | `0` → split point | Intro, wind-up, attack |
| **part 2** | split point → end | Tail, decay, loop body |

## FFmpeg Commands (manual fallback)

The bundled script runs equivalent commands:

```bash
# Part 1 — from start up to (not including) split point
ffmpeg -i input.wav -t 1.25 -y input_part1.wav

# Part 2 — from split point to end (-ss after -i for sample accuracy)
ffmpeg -ss 1.25 -i input.wav -y input_part2.wav
```

Sample-accurate alternative with `atrim`:

```bash
ffmpeg -i input.wav -af "atrim=end=1.25" -y input_part1.wav
ffmpeg -i input.wav -af "atrim=start=1.25" -y input_part2.wav
```

Prefer the bundled script for batch folders; use manual `atrim` when you need filter-chain control on a single file.

## Category Guidance

| Category | Split strategy |
|----------|----------------|
| Long SFX with distinct attack/tail | `-s` at the visual or gameplay cue |
| Dialogue with pause | `-s` at silence gap, or trim first then split |
| BGM loops | Avoid — breaks seamless loop; use two source files |
| Ambience beds | `-p 50` only when halves are interchangeable |

## Validation

- Split point must be **> 0** and **< file duration**.
- Very short part 2 (< ~50 ms) may be inaudible; check in-engine before shipping.
