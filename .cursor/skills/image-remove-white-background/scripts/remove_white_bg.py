"""
Remove solid-color backgrounds (white, green, magenta) via color key + border flood fill.

Exports RGBA PNG with transparent background. Run via manifest image-remove-white-background.bin
(.dependency/image-remove-white-background/.venv/) — see SKILL.md and skill-dependency-manager.
Never use host python/py.

Usage
-----
    .dependency/image-remove-white-background/.venv/Scripts/python \\
        .cursor/skills/image-remove-white-background/scripts/remove_white_bg.py image/foo.png

    .dependency/image-remove-white-background/.venv/Scripts/python \\
        .cursor/skills/image-remove-white-background/scripts/remove_white_bg.py image/sprites -r \\
        --preset green --tolerance 30
"""

from __future__ import annotations

import argparse
import json
import sys
from collections import deque
from pathlib import Path

from PIL import Image

IMAGE_EXTENSIONS = {".png", ".jpg", ".jpeg", ".webp", ".bmp"}
DEFAULT_PATTERN = "*.png"
DEFAULT_PRESET = "white"
DEFAULT_TOLERANCE = 25
DEFAULT_FEATHER = 2
DEFAULT_MODE = "global"
DEFAULT_EXCLUDES: tuple[str, ...] = ("*_sheet.png", "*_mask.png", "transparent/*")

PRESETS: dict[str, tuple[int, int, int]] = {
    "white": (255, 255, 255),
    "green": (0, 255, 0),
    "magenta": (255, 0, 255),
}

PRESET_DEFAULT_TOLERANCE: dict[str, int] = {
    "white": 25,
    "green": 40,
    "magenta": 40,
}


def find_repo_root(start: Path) -> Path | None:
    for parent in [start.resolve(), *start.resolve().parents]:
        if (parent / ".dependency" / "manifest.json").is_file():
            return parent
    return None


def resolve_executable(path: Path) -> Path:
    if path.is_file():
        return path
    if sys.platform == "win32" and path.suffix.lower() != ".exe":
        candidate = path.with_name(f"{path.name}.exe")
        if candidate.is_file():
            return candidate
    raise FileNotFoundError(path)


def resolve_tool_bin(repo_root: Path, tool_name: str) -> Path:
    manifest_path = repo_root / ".dependency" / "manifest.json"
    entry = json.loads(manifest_path.read_text(encoding="utf-8")).get(tool_name)
    if not entry:
        print(
            f"Tool '{tool_name}' not found in .dependency/manifest.json. "
            "See .cursor/rules/skill-dependency-manager.md",
            file=sys.stderr,
        )
        sys.exit(1)
    if not entry.get("populated", False):
        print(
            f"Tool '{tool_name}' is not populated. "
            f"Install it under {repo_root / '.dependency' / tool_name} and set populated: true "
            "in .dependency/manifest.json.",
            file=sys.stderr,
        )
        sys.exit(1)

    bin_rel = entry["bin"]
    if isinstance(bin_rel, list):
        bin_rel = bin_rel[0]
    try:
        return resolve_executable(repo_root / bin_rel)
    except FileNotFoundError:
        print(
            f"Executable for '{tool_name}' not found at {repo_root / bin_rel}. "
            "Check .dependency/manifest.json bin path.",
            file=sys.stderr,
        )
        sys.exit(1)


def parse_color(value: str) -> tuple[int, int, int]:
    cleaned = value.strip().lstrip("#")
    if len(cleaned) != 6:
        raise ValueError(f"Expected 6-digit hex color, got: {value!r}")
    try:
        r = int(cleaned[0:2], 16)
        g = int(cleaned[2:4], 16)
        b = int(cleaned[4:6], 16)
    except ValueError as exc:
        raise ValueError(f"Invalid hex color: {value!r}") from exc
    return r, g, b


def collect_images(
    target: Path,
    pattern: str,
    excludes: tuple[str, ...],
    recursive: bool,
) -> list[Path]:
    if target.is_file():
        if target.suffix.lower() not in IMAGE_EXTENSIONS:
            print(f"Unsupported image type: {target}", file=sys.stderr)
            sys.exit(1)
        return [target.resolve()]

    if not target.is_dir():
        print(f"Input path not found: {target}", file=sys.stderr)
        sys.exit(1)

    excluded: set[Path] = set()
    for exclude in excludes:
        excluded.update(target.rglob(exclude) if recursive else target.glob(exclude))

    globber = target.rglob if recursive else target.glob
    patterns = {pattern}
    if pattern == "*.png":
        patterns.update(["*.jpg", "*.jpeg", "*.webp", "*.bmp"])

    images: list[Path] = []
    seen: set[Path] = set()
    for pat in patterns:
        for path in globber(pat):
            resolved = path.resolve()
            if resolved in seen or resolved in excluded or not path.is_file():
                continue
            if path.suffix.lower() not in IMAGE_EXTENSIONS:
                continue
            seen.add(resolved)
            images.append(resolved)
    return sorted(images)


def resolve_output_path(
    source: Path,
    input_root: Path,
    output_dir: Path | None,
) -> Path:
    try:
        rel = source.relative_to(input_root)
    except ValueError:
        rel = Path(source.name)

    base = output_dir if output_dir is not None else input_root / "transparent"
    return (base / rel).with_suffix(".png")


def is_key_pixel(
    r: int,
    g: int,
    b: int,
    key: tuple[int, int, int],
    tolerance: int,
    *,
    white_mode: bool,
) -> bool:
    if white_mode:
        floor = 255 - tolerance
        return r >= floor and g >= floor and b >= floor
    kr, kg, kb = key
    return max(abs(r - kr), abs(g - kg), abs(b - kb)) <= tolerance


def build_flood_mask(
    pixels: list[tuple[int, ...]],
    width: int,
    height: int,
    key: tuple[int, int, int],
    tolerance: int,
    *,
    white_mode: bool,
    seeds: list[tuple[int, int]],
) -> bytearray:
    def matches(idx: int) -> bool:
        r, g, b = pixels[idx][:3]
        return is_key_pixel(r, g, b, key, tolerance, white_mode=white_mode)

    remove = bytearray(width * height)
    visited = bytearray(width * height)
    queue: deque[int] = deque()

    for x, y in seeds:
        if not 0 <= x < width or not 0 <= y < height:
            continue
        idx = y * width + x
        if not visited[idx] and matches(idx):
            visited[idx] = 1
            queue.append(idx)

    while queue:
        idx = queue.popleft()
        remove[idx] = 1
        x = idx % width
        y = idx // width
        if x > 0:
            nidx = idx - 1
            if not visited[nidx] and matches(nidx):
                visited[nidx] = 1
                queue.append(nidx)
        if x + 1 < width:
            nidx = idx + 1
            if not visited[nidx] and matches(nidx):
                visited[nidx] = 1
                queue.append(nidx)
        if y > 0:
            nidx = idx - width
            if not visited[nidx] and matches(nidx):
                visited[nidx] = 1
                queue.append(nidx)
        if y + 1 < height:
            nidx = idx + width
            if not visited[nidx] and matches(nidx):
                visited[nidx] = 1
                queue.append(nidx)

    return remove


def border_seeds(width: int, height: int) -> list[tuple[int, int]]:
    seeds: list[tuple[int, int]] = []
    for x in range(width):
        seeds.append((x, 0))
        seeds.append((x, height - 1))
    for y in range(1, height - 1):
        seeds.append((0, y))
        seeds.append((width - 1, y))
    return seeds


def center_seeds(width: int, height: int) -> list[tuple[int, int]]:
    return [(width // 2, height // 2)]


def build_border_mask(
    pixels: list[tuple[int, ...]],
    width: int,
    height: int,
    key: tuple[int, int, int],
    tolerance: int,
    *,
    white_mode: bool,
) -> bytearray:
    return build_flood_mask(
        pixels,
        width,
        height,
        key,
        tolerance,
        white_mode=white_mode,
        seeds=border_seeds(width, height),
    )


def build_center_mask(
    pixels: list[tuple[int, ...]],
    width: int,
    height: int,
    key: tuple[int, int, int],
    tolerance: int,
    *,
    white_mode: bool,
) -> bytearray:
    return build_flood_mask(
        pixels,
        width,
        height,
        key,
        tolerance,
        white_mode=white_mode,
        seeds=center_seeds(width, height),
    )


def build_both_mask(
    pixels: list[tuple[int, ...]],
    width: int,
    height: int,
    key: tuple[int, int, int],
    tolerance: int,
    *,
    white_mode: bool,
) -> bytearray:
    border = build_border_mask(
        pixels, width, height, key, tolerance, white_mode=white_mode
    )
    center = build_center_mask(
        pixels, width, height, key, tolerance, white_mode=white_mode
    )
    return bytearray(1 if border[i] or center[i] else 0 for i in range(len(border)))


def build_global_mask(
    pixels: list[tuple[int, ...]],
    key: tuple[int, int, int],
    tolerance: int,
    *,
    white_mode: bool,
) -> bytearray:
    remove = bytearray(len(pixels))
    for idx, pixel in enumerate(pixels):
        r, g, b = pixel[:3]
        if is_key_pixel(r, g, b, key, tolerance, white_mode=white_mode):
            remove[idx] = 1
    return remove


def apply_feather(alpha: list[int], width: int, height: int, radius: int) -> None:
    if radius <= 0:
        return

    from PIL import ImageFilter

    alpha_img = Image.new("L", (width, height))
    alpha_img.putdata(alpha)
    blurred = alpha_img.filter(ImageFilter.GaussianBlur(radius=radius))
    alpha[:] = list(blurred.getdata())


def crop_transparent(image: Image.Image) -> Image.Image:
    if image.mode != "RGBA":
        image = image.convert("RGBA")
    bbox = image.split()[3].getbbox()
    if bbox is None:
        return image
    return image.crop(bbox)


def remove_solid_background(
    source: Path,
    *,
    key: tuple[int, int, int],
    tolerance: int,
    feather: int,
    mode: str,
    crop: bool,
) -> Image.Image:
    with Image.open(source) as img:
        rgb = img.convert("RGB")
        width, height = rgb.size
        pixels = list(rgb.getdata())
        white_mode = key == (255, 255, 255)

        if mode == "border":
            remove = build_border_mask(
                pixels, width, height, key, tolerance, white_mode=white_mode
            )
        elif mode == "center":
            remove = build_center_mask(
                pixels, width, height, key, tolerance, white_mode=white_mode
            )
        elif mode == "both":
            remove = build_both_mask(
                pixels, width, height, key, tolerance, white_mode=white_mode
            )
        else:
            remove = build_global_mask(pixels, key, tolerance, white_mode=white_mode)

        alpha = [0 if remove[idx] else 255 for idx in range(len(pixels))]
        if feather > 0:
            apply_feather(alpha, width, height, feather)

        alpha_img = Image.new("L", (width, height))
        alpha_img.putdata(alpha)
        result = rgb.convert("RGBA")
        result.putalpha(alpha_img)

        if crop:
            result = crop_transparent(result)
        return result


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Remove solid-color backgrounds (white/green/magenta) and export transparent PNGs."
    )
    parser.add_argument(
        "input",
        help="Image file or directory containing images",
    )
    parser.add_argument(
        "-r",
        "--recursive",
        action="store_true",
        help="Recurse into subdirectories when input is a directory",
    )
    parser.add_argument(
        "-o",
        "--output-dir",
        help="Output directory (default: <input-path>/transparent/)",
    )
    parser.add_argument(
        "--pattern",
        default=DEFAULT_PATTERN,
        help=f"Glob pattern for directory input (default: {DEFAULT_PATTERN})",
    )
    parser.add_argument(
        "--preset",
        choices=sorted(PRESETS),
        default=DEFAULT_PRESET,
        help=f"Background color preset (default: {DEFAULT_PRESET})",
    )
    parser.add_argument(
        "--color",
        help="Custom key color as RRGGBB hex (overrides --preset)",
    )
    parser.add_argument(
        "--tolerance",
        type=int,
        help="Color match tolerance 0-255 (default depends on preset)",
    )
    parser.add_argument(
        "--feather",
        type=int,
        default=DEFAULT_FEATHER,
        help=f"Gaussian blur radius on alpha edges (default: {DEFAULT_FEATHER}, 0=off)",
    )
    parser.add_argument(
        "--mode",
        choices=("border", "center", "both", "global"),
        default=DEFAULT_MODE,
        help=(
            "global: remove all matching pixels (default); both: union of border and center; "
            "border: flood-fill from edges; center: flood-fill from image center"
        ),
    )
    parser.add_argument(
        "--crop",
        action="store_true",
        help="Crop transparent borders after keying",
    )
    parser.add_argument(
        "--overwrite",
        action="store_true",
        help="Overwrite existing output files",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Print planned outputs without processing",
    )
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    repo_root = find_repo_root(Path(__file__))
    if repo_root is None:
        print(
            "Could not find .dependency/manifest.json. "
            "Run from a repo that follows .cursor/rules/skill-dependency-manager.md.",
            file=sys.stderr,
        )
        sys.exit(1)

    resolve_tool_bin(repo_root, "image-remove-white-background")

    if args.color:
        try:
            key = parse_color(args.color)
        except ValueError as exc:
            print(str(exc), file=sys.stderr)
            sys.exit(1)
        preset = "custom"
    else:
        preset = args.preset
        key = PRESETS[preset]

    tolerance = (
        args.tolerance
        if args.tolerance is not None
        else PRESET_DEFAULT_TOLERANCE.get(preset, DEFAULT_TOLERANCE)
    )
    if not 0 <= tolerance <= 255:
        print("--tolerance must be between 0 and 255", file=sys.stderr)
        sys.exit(1)
    if args.feather < 0:
        print("--feather must be >= 0", file=sys.stderr)
        sys.exit(1)

    input_path = Path(args.input).resolve()
    images = collect_images(input_path, args.pattern, DEFAULT_EXCLUDES, args.recursive)
    if not images:
        print(f"No images found under {input_path}", file=sys.stderr)
        sys.exit(1)

    input_root = input_path if input_path.is_dir() else input_path.parent
    output_dir = Path(args.output_dir).resolve() if args.output_dir else None

    planned: list[tuple[Path, Path]] = []
    for source in images:
        dest = resolve_output_path(source, input_root, output_dir)
        planned.append((source, dest))

    if args.dry_run:
        print(f"preset={preset} key={key} tolerance={tolerance} mode={args.mode} feather={args.feather}")
        for source, dest in planned:
            print(f"{source} -> {dest}")
        print(f"{len(planned)} file(s)")
        return

    processed = 0
    skipped = 0

    for source, dest in planned:
        if dest.exists() and not args.overwrite:
            print(f"Skip (exists): {dest}")
            skipped += 1
            continue

        dest.parent.mkdir(parents=True, exist_ok=True)
        print(f"Processing: {source}")
        result = remove_solid_background(
            source,
            key=key,
            tolerance=tolerance,
            feather=args.feather,
            mode=args.mode,
            crop=args.crop,
        )
        result.save(dest, format="PNG")
        processed += 1
        print(f"  -> {dest}")

    print(f"Done: {processed} processed, {skipped} skipped, {len(planned)} total")


if __name__ == "__main__":
    main()
