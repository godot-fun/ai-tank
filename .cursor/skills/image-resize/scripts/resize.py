#!/usr/bin/env python3
"""Batch resize image files using ImageMagick."""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
from pathlib import Path

IMAGE_EXTENSIONS = {
    ".jpg",
    ".jpeg",
    ".png",
    ".webp",
    ".gif",
    ".bmp",
    ".tif",
    ".tiff",
    ".avif",
    ".ico",
}

RESIZE_MODES = ("fit", "fill", "exact")


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


def resolve_magick() -> Path:
    repo_root = find_repo_root(Path(__file__))
    if repo_root is None:
        print(
            "Could not find .dependency/manifest.json by walking up from this script. "
            "Run from a repo that follows .cursor/rules/skill-dependency-manager.md.",
            file=sys.stderr,
        )
        sys.exit(1)
    return resolve_tool_bin(repo_root, "imagemagick")


def get_image_files(path: Path, recurse: bool) -> list[Path]:
    if path.is_file():
        if path.suffix.lower() not in IMAGE_EXTENSIONS:
            print(f"Not a supported image file: {path}", file=sys.stderr)
            sys.exit(1)
        return [path.resolve()]

    if not path.is_dir():
        print(f"Input path not found: {path}", file=sys.stderr)
        sys.exit(1)

    candidates = path.rglob("*") if recurse else path.iterdir()
    files = [
        item.resolve()
        for item in candidates
        if item.is_file() and item.suffix.lower() in IMAGE_EXTENSIONS
    ]
    return sorted(files)


def relative_path(file_path: Path, input_root: Path) -> str:
    try:
        return file_path.relative_to(input_root).as_posix()
    except ValueError:
        return file_path.name


def filter_output_files(files: list[Path], output_dir: Path) -> list[Path]:
    out = output_dir.resolve()
    kept: list[Path] = []
    for file_path in files:
        try:
            file_path.resolve().relative_to(out)
        except ValueError:
            kept.append(file_path)
    return kept


def find_source_collisions(
    files: list[Path], input_root: Path, output_dir: Path
) -> list[tuple[Path, Path]]:
    collisions: list[tuple[Path, Path]] = []
    for file_path in files:
        rel = relative_path(file_path, input_root)
        out_path = output_dir / rel
        if out_path.resolve() == file_path.resolve():
            collisions.append((file_path, out_path))
    return collisions


def build_resize_geometry(width: int, height: int, mode: str) -> str:
    size = f"{width}x{height}"
    if mode == "exact":
        return f"{size}!"
    if mode == "fill":
        return f"{size}^"
    return size


def build_magick_args(
    magick: Path,
    file_path: Path,
    out_path: Path,
    width: int,
    height: int,
    mode: str,
) -> list[str]:
    geometry = build_resize_geometry(width, height, mode)
    cmd = [
        str(magick),
        str(file_path),
        "-resize",
        geometry,
    ]
    if mode == "fill":
        cmd.extend(["-gravity", "center", "-extent", f"{width}x{height}"])
    cmd.append(str(out_path))
    return cmd


def describe_mode(mode: str, width: int, height: int) -> str:
    labels = {
        "fit": f"fit within {width}x{height} (preserve aspect)",
        "fill": f"fill {width}x{height} (crop center)",
        "exact": f"force {width}x{height} (ignore aspect)",
    }
    return labels[mode]


def resize_file(
    magick: Path,
    file_path: Path,
    out_path: Path,
    width: int,
    height: int,
    mode: str,
) -> None:
    out_path.parent.mkdir(parents=True, exist_ok=True)
    cmd = build_magick_args(magick, file_path, out_path, width, height, mode)
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        detail = result.stderr.strip() or result.stdout.strip()
        raise RuntimeError(
            f"ImageMagick resize failed for: {file_path}"
            + (f"\n{detail}" if detail else "")
        )


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Batch resize image files using ImageMagick."
    )
    parser.add_argument("input", help="Path to a single image file or directory")
    parser.add_argument(
        "-W",
        "--width",
        type=int,
        required=True,
        help="Target width in pixels (required)",
    )
    parser.add_argument(
        "-H",
        "--height",
        type=int,
        required=True,
        help="Target height in pixels (required)",
    )
    parser.add_argument(
        "--mode",
        choices=RESIZE_MODES,
        default="fit",
        help="Resize mode: fit (default), fill, exact",
    )
    parser.add_argument(
        "-o",
        "--output-dir",
        default="",
        help="Output directory (default: <input>/resized)",
    )
    parser.add_argument(
        "-r", "--recurse", action="store_true", help="Process subdirectories"
    )
    parser.add_argument(
        "--overwrite", action="store_true", help="Replace existing output files"
    )
    parser.add_argument(
        "--dry-run", action="store_true", help="Preview without writing files"
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()

    if args.width <= 0 or args.height <= 0:
        print("Width and height must be positive integers.", file=sys.stderr)
        return 1

    magick = resolve_magick()

    input_path = Path(args.input)
    if not input_path.exists():
        print(f"Input path not found: {args.input}", file=sys.stderr)
        return 1

    input_path = input_path.resolve()
    files = get_image_files(input_path, args.recurse)
    if not files:
        print(f"No supported image files found under: {args.input}")
        return 0

    input_root = input_path.parent if input_path.is_file() else input_path
    output_dir = (
        Path(args.output_dir).resolve()
        if args.output_dir
        else input_root / "resized"
    )

    initial_count = len(files)
    files = filter_output_files(files, output_dir)
    if not files:
        if initial_count:
            print(
                "No source files to process: all inputs lie under the output directory. "
                "Choose a separate output directory (default: resized/).",
                file=sys.stderr,
            )
            return 1
        print(f"No supported image files found under: {args.input}")
        return 0

    collisions = find_source_collisions(files, input_root, output_dir)
    if collisions:
        print(
            "Refusing to overwrite source files. Use a separate output directory "
            "(default: resized/).",
            file=sys.stderr,
        )
        for source, dest in collisions:
            print(f"  {source} -> {dest}", file=sys.stderr)
        return 1

    mode_desc = describe_mode(args.mode, args.width, args.height)
    print(f"Input:  {args.input}")
    print(f"Files:  {len(files)}")
    print(f"Size:   {args.width}x{args.height}")
    print(f"Mode:   {mode_desc}")
    print(f"Output: {output_dir}")
    if args.dry_run:
        print("Run:    DRY RUN")
    print()

    ok = 0
    skip = 0
    fail = 0

    for file_path in files:
        rel = relative_path(file_path, input_root)
        out_path = output_dir / rel

        if out_path.exists() and not args.overwrite and not args.dry_run:
            print(f"[skip] {rel}")
            skip += 1
            continue

        if args.dry_run:
            print(f"[plan] {rel} -> {rel} ({mode_desc})")
            ok += 1
            continue

        try:
            print(f"[run]  {rel} -> {rel} ({mode_desc})")
            resize_file(
                magick, file_path, out_path, args.width, args.height, args.mode
            )
            ok += 1
        except RuntimeError as exc:
            print(f"[fail] {rel}")
            print(exc)
            fail += 1

    print()
    print(f"Done. processed={ok} skipped={skip} failed={fail}")
    return 1 if fail else 0


if __name__ == "__main__":
    sys.exit(main())
