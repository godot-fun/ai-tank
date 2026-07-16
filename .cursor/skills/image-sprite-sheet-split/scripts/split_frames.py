"""
Split uniform sprite sheet grids into individual frame PNGs via FFmpeg crop.

Preserves source dimensions per cell and alpha channel. Run via manifest
python.bin ? see SKILL.md and skill-dependency-manager.
Never use host python/py.

Usage
-----
    .dependency/python/python \\
        .cursor/skills/image-sprite-sheet-split/scripts/split_frames.py sheet.png --grid 4x4

    .dependency/python/python \\
        .cursor/skills/image-sprite-sheet-split/scripts/split_frames.py assets/effects -r \\
        --cols 4 --rows 4 --output-dir assets/effects/frames
"""

from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from pathlib import Path

IMAGE_EXTENSIONS = {".png", ".jpg", ".jpeg", ".webp", ".bmp", ".gif"}
DEFAULT_OUTPUT_SUBDIR = "frames"
GRID_RE = re.compile(r"^(\d+)x(\d+)$", re.IGNORECASE)


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


def resolve_ffmpeg() -> Path:
    repo_root = find_repo_root(Path(__file__))
    if repo_root is None:
        print(
            "Could not find .dependency/manifest.json by walking up from this script. "
            "Run from a repo that follows .cursor/rules/skill-dependency-manager.md.",
            file=sys.stderr,
        )
        sys.exit(1)
    return resolve_tool_bin(repo_root, "ffmpeg")


def resolve_ffprobe(ffmpeg: Path) -> Path:
    name = "ffprobe.exe" if sys.platform == "win32" else "ffprobe"
    candidate = ffmpeg.with_name(name)
    if candidate.is_file():
        return candidate
    raise FileNotFoundError(candidate)


def get_image_files(path: Path, recurse: bool) -> list[Path]:
    if path.is_file():
        if path.suffix.lower() not in IMAGE_EXTENSIONS:
            print(f"Not a supported image file: {path}", file=sys.stderr)
            sys.exit(1)
        return [path.resolve()]

    if not path.is_dir():
        print(f"Input path not found: {path}", file=sys.stderr)
        sys.exit(1)

    globber = path.rglob if recurse else path.glob
    files = sorted(
        item.resolve()
        for item in globber("*")
        if item.is_file() and item.suffix.lower() in IMAGE_EXTENSIONS
    )
    return files


def probe_image(ffprobe: Path, file_path: Path) -> dict:
    result = subprocess.run(
        [
            str(ffprobe),
            "-v",
            "quiet",
            "-print_format",
            "json",
            "-show_streams",
            "-select_streams",
            "v:0",
            str(file_path),
        ],
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        return {}

    try:
        payload = json.loads(result.stdout)
    except json.JSONDecodeError:
        return {}

    streams = payload.get("streams") or []
    if not streams:
        return {}

    stream = streams[0]
    try:
        width = int(stream.get("width") or 0)
        height = int(stream.get("height") or 0)
    except (TypeError, ValueError):
        width = height = 0

    return {"width": width, "height": height}


def parse_grid(value: str) -> tuple[int, int]:
    match = GRID_RE.match(value.strip())
    if not match:
        raise argparse.ArgumentTypeError(
            f"Invalid grid '{value}'. Expected format like 4x4."
        )
    cols, rows = int(match.group(1)), int(match.group(2))
    if cols < 1 or rows < 1:
        raise argparse.ArgumentTypeError("Grid columns and rows must be >= 1.")
    return cols, rows


def compute_layout(
    width: int,
    height: int,
    cols: int,
    rows: int,
    offset_x: int,
    offset_y: int,
    gutter_x: int,
    gutter_y: int,
    cell_width: int | None,
    cell_height: int | None,
    trim: int,
) -> tuple[int, int, list[tuple[int, int, int, int]], list[str]]:
    grid_w = width - offset_x
    grid_h = height - offset_y
    if grid_w <= 0 or grid_h <= 0:
        raise ValueError(
            f"Offset ({offset_x}, {offset_y}) exceeds image size ({width}x{height})."
        )

    if cell_width is None:
        if cols == 1:
            cell_width = grid_w
        else:
            cell_width = (grid_w - gutter_x * (cols - 1)) // cols
    if cell_height is None:
        if rows == 1:
            cell_height = grid_h
        else:
            cell_height = (grid_h - gutter_y * (rows - 1)) // rows

    if cell_width <= 0 or cell_height <= 0:
        raise ValueError("Computed cell size is zero or negative.")

    warnings: list[str] = []
    used_w = cell_width * cols + gutter_x * max(cols - 1, 0)
    used_h = cell_height * rows + gutter_y * max(rows - 1, 0)
    if used_w < grid_w:
        warnings.append(
            f"{grid_w - used_w}px unused horizontally inside grid area."
        )
    elif used_w > grid_w:
        warnings.append(
            f"Grid width exceeds available area by {used_w - grid_w}px."
        )
    if used_h < grid_h:
        warnings.append(f"{grid_h - used_h}px unused vertically inside grid area.")
    elif used_h > grid_h:
        warnings.append(
            f"Grid height exceeds available area by {used_h - grid_h}px."
        )

    crops: list[tuple[int, int, int, int]] = []
    for row in range(rows):
        for col in range(cols):
            x = offset_x + col * (cell_width + gutter_x) + trim
            y = offset_y + row * (cell_height + gutter_y) + trim
            w = cell_width - 2 * trim
            h = cell_height - 2 * trim
            if w <= 0 or h <= 0:
                raise ValueError(
                    f"Trim {trim}px is too large for cell size "
                    f"{cell_width}x{cell_height}."
                )
            if x + w > width or y + h > height:
                raise ValueError(
                    f"Cell ({col}, {row}) crop {w}x{h} at ({x}, {y}) "
                    f"extends beyond image {width}x{height}."
                )
            crops.append((x, y, w, h))

    return cell_width, cell_height, crops, warnings


def crop_frame(
    ffmpeg: Path,
    file_path: Path,
    out_path: Path,
    x: int,
    y: int,
    w: int,
    h: int,
) -> None:
    out_path.parent.mkdir(parents=True, exist_ok=True)
    cmd = [
        str(ffmpeg),
        "-hide_banner",
        "-nostats",
        "-loglevel",
        "error",
        "-y",
        "-i",
        str(file_path),
        "-vf",
        f"crop={w}:{h}:{x}:{y}",
        "-frames:v",
        "1",
        "-c:v",
        "png",
        str(out_path),
    ]
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        detail = result.stderr.strip() or result.stdout.strip()
        raise RuntimeError(
            f"FFmpeg crop failed for: {file_path}"
            + (f"\n{detail}" if detail else "")
        )


def output_dir_for_sheet(
    input_root: Path,
    file_path: Path,
    output_dir: Path | None,
    output_subdir: str,
) -> Path:
    if output_dir is not None:
        base = output_dir
    else:
        base = file_path.parent / output_subdir
    return base / file_path.stem


def frame_name(stem: str, index: int, digits: int) -> str:
    return f"{stem}_{index:0{digits}d}.png"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Split uniform sprite sheet grids into individual PNG frames."
    )
    parser.add_argument("input", help="Path to a sprite sheet file or directory")
    grid = parser.add_mutually_exclusive_group(required=True)
    grid.add_argument(
        "--grid",
        type=parse_grid,
        metavar="COLSxROWS",
        help="Grid layout, e.g. 4x4 or 3x6",
    )
    grid.add_argument("--cols", type=int, help="Number of columns (use with --rows)")
    parser.add_argument("--rows", type=int, help="Number of rows (required with --cols)")
    parser.add_argument(
        "-o",
        "--output-dir",
        default="",
        help="Shared output root (default: <source-dir>/frames/<sheet-stem>/)",
    )
    parser.add_argument(
        "--output-subdir",
        default=DEFAULT_OUTPUT_SUBDIR,
        help=f"Subfolder beside each sheet when --output-dir is omitted (default: {DEFAULT_OUTPUT_SUBDIR})",
    )
    parser.add_argument(
        "-r", "--recurse", action="store_true", help="Process subdirectories"
    )
    parser.add_argument(
        "--offset-x",
        type=int,
        default=0,
        help="Pixels from left edge before the grid starts (default: 0)",
    )
    parser.add_argument(
        "--offset-y",
        type=int,
        default=0,
        help="Pixels from top edge before the grid starts (default: 0)",
    )
    parser.add_argument(
        "--gutter-x",
        type=int,
        default=0,
        help="Horizontal spacing between columns in pixels (default: 0)",
    )
    parser.add_argument(
        "--gutter-y",
        type=int,
        default=0,
        help="Vertical spacing between rows in pixels (default: 0)",
    )
    parser.add_argument(
        "--gutter",
        type=int,
        default=None,
        help="Set both --gutter-x and --gutter-y",
    )
    parser.add_argument(
        "--cell-width",
        type=int,
        default=None,
        help="Force cell width in pixels (default: auto from image size)",
    )
    parser.add_argument(
        "--cell-height",
        type=int,
        default=None,
        help="Force cell height in pixels (default: auto from image size)",
    )
    parser.add_argument(
        "--trim",
        type=int,
        default=0,
        help="Crop this many pixels from each cell edge to skip grid lines (default: 0)",
    )
    parser.add_argument(
        "--start-index",
        type=int,
        default=1,
        help="First frame number in filenames (default: 1)",
    )
    parser.add_argument(
        "--overwrite", action="store_true", help="Replace existing frame files"
    )
    parser.add_argument(
        "--dry-run", action="store_true", help="Preview crops without writing files"
    )
    args = parser.parse_args()

    if args.grid is not None:
        args.cols, args.rows = args.grid
    elif args.rows is None:
        parser.error("--rows is required when using --cols")

    if args.cols < 1 or args.rows < 1:
        parser.error("--cols and --rows must be >= 1")

    if args.gutter is not None:
        args.gutter_x = args.gutter
        args.gutter_y = args.gutter

    return args


def main() -> int:
    args = parse_args()
    ffmpeg = resolve_ffmpeg()
    ffprobe = resolve_ffprobe(ffmpeg)

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
    shared_output = Path(args.output_dir).resolve() if args.output_dir else None
    digits = max(3, len(str(args.start_index + args.cols * args.rows - 1)))

    print(f"Input:  {args.input}")
    print(f"Files:  {len(files)}")
    print(f"Grid:   {args.cols}x{args.rows} ({args.cols * args.rows} frames per sheet)")
    if shared_output:
        print(f"Output: {shared_output}/<sheet-stem>/")
    else:
        print(f"Output: <source-dir>/{args.output_subdir}/<sheet-stem>/")
    if args.dry_run:
        print("Run:    DRY RUN")
    print()

    ok = 0
    skip = 0
    fail = 0

    for file_path in files:
        probe = probe_image(ffprobe, file_path)
        width = probe.get("width") or 0
        height = probe.get("height") or 0
        if width <= 0 or height <= 0:
            print(f"[fail] {file_path.name}: could not read image dimensions")
            fail += 1
            continue

        try:
            cell_w, cell_h, crops, warnings = compute_layout(
                width,
                height,
                args.cols,
                args.rows,
                args.offset_x,
                args.offset_y,
                args.gutter_x,
                args.gutter_y,
                args.cell_width,
                args.cell_height,
                args.trim,
            )
        except ValueError as exc:
            print(f"[fail] {file_path.name}: {exc}")
            fail += 1
            continue

        out_dir = output_dir_for_sheet(
            input_root, file_path, shared_output, args.output_subdir
        )
        print(
            f"Sheet: {file_path.name} ({width}x{height}) "
            f"-> cell {cell_w}x{cell_h}, {len(crops)} frames"
        )
        for warning in warnings:
            print(f"  warn: {warning}")

        sheet_ok = 0
        sheet_skip = 0
        sheet_fail = 0

        for index, (x, y, w, h) in enumerate(crops, start=args.start_index):
            out_name = frame_name(file_path.stem, index, digits)
            out_path = out_dir / out_name

            if out_path.exists() and not args.overwrite and not args.dry_run:
                sheet_skip += 1
                continue

            if args.dry_run:
                print(f"  [plan] {out_name} crop={w}x{h} at ({x},{y})")
                sheet_ok += 1
                continue

            try:
                crop_frame(ffmpeg, file_path, out_path, x, y, w, h)
                print(f"  [ok]   {out_name} ({w}x{h})")
                sheet_ok += 1
            except RuntimeError as exc:
                print(f"  [fail] {out_name}")
                print(f"         {exc}")
                sheet_fail += 1

        ok += sheet_ok
        skip += sheet_skip
        fail += sheet_fail
        print()

    print(f"Done. frames={ok} skipped={skip} failed={fail}")
    return 1 if fail else 0


if __name__ == "__main__":
    sys.exit(main())
