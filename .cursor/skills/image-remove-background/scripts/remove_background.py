"""
Batch background removal via rembg (U2Net / BiRefNet matting).

Exports RGBA PNG with transparent background. Run via manifest rembg.bin
(.dependency/rembg/.venv/) — see SKILL.md and skill-dependency-manager.
Never use host python/py.

Usage
-----
    .dependency/rembg/.venv/Scripts/python \\
        .cursor/skills/image-remove-background/scripts/remove_background.py image/foo.png

    .dependency/rembg/.venv/Scripts/python \\
        .cursor/skills/image-remove-background/scripts/remove_background.py image/sprites -r \\
        --model birefnet-general --output-dir image/sprites_cutout
"""

from __future__ import annotations

import argparse
import json
import sys
from io import BytesIO
from pathlib import Path

from PIL import Image

IMAGE_EXTENSIONS = {".png", ".jpg", ".jpeg", ".webp"}
DEFAULT_PATTERN = "*.png"
DEFAULT_MODEL = "u2net"
DEFAULT_EXCLUDES: tuple[str, ...] = ("*_sheet.png", "*_mask.png", "transparent/*")
MAX_INPUT_SIDE = 4096

MODEL_CHOICES = (
    "u2net",
    "u2netp",
    "u2net_human_seg",
    "silueta",
    "isnet-general-use",
    "birefnet-general",
    "birefnet-portrait",
)


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
        patterns.update("*.jpg", "*.jpeg", "*.webp")

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


def maybe_downscale(image: Image.Image, max_side: int) -> Image.Image:
    w, h = image.size
    longest = max(w, h)
    if longest <= max_side:
        return image
    scale = max_side / longest
    new_size = (max(1, int(w * scale)), max(1, int(h * scale)))
    return image.resize(new_size, Image.Resampling.LANCZOS)


def crop_transparent(image: Image.Image) -> Image.Image:
    if image.mode != "RGBA":
        image = image.convert("RGBA")
    alpha = image.split()[3]
    bbox = alpha.getbbox()
    if bbox is None:
        return image
    return image.crop(bbox)


def remove_background(
    source: Path,
    session,
    *,
    alpha_matting: bool,
    alpha_matting_foreground_threshold: int,
    alpha_matting_background_threshold: int,
    alpha_matting_erode_size: int,
    crop: bool,
) -> Image.Image:
    from rembg import remove

    with Image.open(source) as img:
        img = img.convert("RGBA")
        img = maybe_downscale(img, MAX_INPUT_SIDE)
        buffer = BytesIO()
        img.save(buffer, format="PNG")
        input_bytes = buffer.getvalue()

    output_bytes = remove(
        input_bytes,
        session=session,
        alpha_matting=alpha_matting,
        alpha_matting_foreground_threshold=alpha_matting_foreground_threshold,
        alpha_matting_background_threshold=alpha_matting_background_threshold,
        alpha_matting_erode_size=alpha_matting_erode_size,
    )
    result = Image.open(BytesIO(output_bytes)).convert("RGBA")
    if crop:
        result = crop_transparent(result)
    return result


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Remove image backgrounds with rembg and export transparent PNGs."
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
        "--model",
        default=DEFAULT_MODEL,
        choices=MODEL_CHOICES,
        help=f"rembg model (default: {DEFAULT_MODEL})",
    )
    parser.add_argument(
        "--alpha-matting",
        action="store_true",
        help="Enable alpha matting for softer edges (slower)",
    )
    parser.add_argument(
        "--alpha-matting-foreground-threshold",
        type=int,
        default=240,
        help="Alpha matting foreground threshold (default: 240)",
    )
    parser.add_argument(
        "--alpha-matting-background-threshold",
        type=int,
        default=10,
        help="Alpha matting background threshold (default: 10)",
    )
    parser.add_argument(
        "--alpha-matting-erode-size",
        type=int,
        default=10,
        help="Alpha matting erode size (default: 10)",
    )
    parser.add_argument(
        "--crop",
        action="store_true",
        help="Crop transparent borders after matting",
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

    resolve_tool_bin(repo_root, "rembg")

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
        for source, dest in planned:
            print(f"{source} -> {dest}")
        print(f"{len(planned)} file(s)")
        return

    from rembg import new_session

    session = new_session(args.model)
    processed = 0
    skipped = 0

    for source, dest in planned:
        if dest.exists() and not args.overwrite:
            print(f"Skip (exists): {dest}")
            skipped += 1
            continue

        dest.parent.mkdir(parents=True, exist_ok=True)
        print(f"Processing: {source}")
        result = remove_background(
            source,
            session,
            alpha_matting=args.alpha_matting,
            alpha_matting_foreground_threshold=args.alpha_matting_foreground_threshold,
            alpha_matting_background_threshold=args.alpha_matting_background_threshold,
            alpha_matting_erode_size=args.alpha_matting_erode_size,
            crop=args.crop,
        )
        result.save(dest, format="PNG")
        processed += 1
        print(f"  -> {dest}")

    print(f"Done: {processed} processed, {skipped} skipped, {len(planned)} total")


if __name__ == "__main__":
    main()
