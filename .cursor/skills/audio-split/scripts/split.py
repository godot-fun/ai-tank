#!/usr/bin/env python3
"""Split audio files into part 1 (before split) and part 2 (after split) using FFmpeg."""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
from pathlib import Path

AUDIO_EXTENSIONS = {".wav", ".mp3", ".ogg", ".flac", ".aac", ".m4a", ".wma"}


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
    probe = ffmpeg.parent / ("ffprobe.exe" if sys.platform == "win32" else "ffprobe")
    if probe.is_file():
        return probe
    print(
        f"ffprobe not found next to ffmpeg at {ffmpeg.parent}. "
        "Install a full FFmpeg build that includes ffprobe.",
        file=sys.stderr,
    )
    sys.exit(1)


def get_audio_files(path: Path, recurse: bool) -> list[Path]:
    if path.is_file():
        if path.suffix.lower() not in AUDIO_EXTENSIONS:
            print(f"Not a supported audio file: {path}", file=sys.stderr)
            sys.exit(1)
        return [path.resolve()]

    if not path.is_dir():
        print(f"Input path not found: {path}", file=sys.stderr)
        sys.exit(1)

    if recurse:
        candidates = path.rglob("*")
    else:
        candidates = path.iterdir()

    files = [
        item.resolve()
        for item in candidates
        if item.is_file() and item.suffix.lower() in AUDIO_EXTENSIONS
    ]
    return sorted(files)


def get_duration(ffprobe: Path, file_path: Path) -> float:
    result = subprocess.run(
        [
            str(ffprobe),
            "-v",
            "error",
            "-show_entries",
            "format=duration",
            "-of",
            "default=noprint_wrappers=1:nokey=1",
            str(file_path),
        ],
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        raise RuntimeError(f"Could not read duration for: {file_path}")
    try:
        return float(result.stdout.strip())
    except ValueError as exc:
        raise RuntimeError(f"Invalid duration for: {file_path}") from exc


def resolve_split_seconds(
    duration: float, split_at: float | None, percent: float | None
) -> float:
    if split_at is not None:
        point = split_at
    elif percent is not None:
        point = duration * (percent / 100.0)
    else:
        point = duration * 0.5

    if point <= 0:
        raise ValueError("Split point must be after the start ( > 0 seconds ).")
    if point >= duration:
        raise ValueError(
            f"Split point ({point:.3f}s) must be before file end ({duration:.3f}s)."
        )
    return point


def output_paths(out_dir: Path, file_path: Path, input_root: Path) -> tuple[Path, Path]:
    rel = relative_path(file_path, input_root)
    rel_parent = Path(rel).parent
    stem = Path(rel).stem
    suffix = file_path.suffix
    base = out_dir / rel_parent / stem
    return Path(f"{base}_part1{suffix}"), Path(f"{base}_part2{suffix}")


def split_file(
    ffmpeg: Path, file_path: Path, part1: Path, part2: Path, split_at: float
) -> None:
    part1.parent.mkdir(parents=True, exist_ok=True)
    part2.parent.mkdir(parents=True, exist_ok=True)

    result1 = subprocess.run(
        [
            str(ffmpeg),
            "-hide_banner",
            "-nostats",
            "-y",
            "-i",
            str(file_path),
            "-t",
            f"{split_at:.6f}",
            str(part1),
        ],
        capture_output=True,
        text=True,
    )
    if result1.returncode != 0:
        raise RuntimeError(f"FFmpeg part 1 failed for: {file_path}")

    result2 = subprocess.run(
        [
            str(ffmpeg),
            "-hide_banner",
            "-nostats",
            "-y",
            "-ss",
            f"{split_at:.6f}",
            "-i",
            str(file_path),
            str(part2),
        ],
        capture_output=True,
        text=True,
    )
    if result2.returncode != 0:
        raise RuntimeError(f"FFmpeg part 2 failed for: {file_path}")


def relative_path(file_path: Path, input_root: Path) -> str:
    try:
        return file_path.relative_to(input_root).as_posix()
    except ValueError:
        return file_path.name


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Split audio into part 1 (before split) and part 2 (after split)."
    )
    parser.add_argument("input", help="Path to a single audio file or directory")
    split = parser.add_mutually_exclusive_group()
    split.add_argument(
        "-s",
        "--split-at",
        type=float,
        help="Split time in seconds (part 1 ends here; part 2 starts here)",
    )
    split.add_argument(
        "-p",
        "--percent",
        type=float,
        help="Split position as percent of duration (default: 50)",
    )
    parser.add_argument("-o", "--output-dir", default="", help="Output directory")
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


def format_split_label(
    split_at: float | None, percent: float | None, resolved: float
) -> str:
    if split_at is not None:
        return f"{resolved:.3f}s (from -s {split_at})"
    if percent is not None:
        return f"{resolved:.3f}s ({percent}% of duration)"
    return f"{resolved:.3f}s (50% default)"


def main() -> int:
    args = parse_args()
    ffmpeg = resolve_ffmpeg()
    ffprobe = resolve_ffprobe(ffmpeg)

    input_path = Path(args.input)
    if not input_path.exists():
        print(f"Input path not found: {args.input}", file=sys.stderr)
        return 1

    input_path = input_path.resolve()
    files = get_audio_files(input_path, args.recurse)
    if not files:
        print(f"No supported audio files found under: {args.input}")
        return 0

    if input_path.is_file():
        input_root = input_path.parent
    else:
        input_root = input_path

    output_dir = Path(args.output_dir).resolve() if args.output_dir else input_root / "split"

    print(f"Input:  {args.input}")
    print(f"Files:  {len(files)}")
    print(f"Output: {output_dir}")
    if args.dry_run:
        print("Mode:   DRY RUN")
    print()

    ok = 0
    skip = 0
    fail = 0

    for file_path in files:
        rel = relative_path(file_path, input_root)
        part1, part2 = output_paths(output_dir, file_path, input_root)

        if (
            (part1.exists() or part2.exists())
            and not args.overwrite
            and not args.dry_run
        ):
            print(f"[skip] {rel}")
            skip += 1
            continue

        try:
            duration = get_duration(ffprobe, file_path)
            split_seconds = resolve_split_seconds(duration, args.split_at, args.percent)
            label = format_split_label(args.split_at, args.percent, split_seconds)
        except (RuntimeError, ValueError) as exc:
            print(f"[fail] {rel}")
            print(exc)
            fail += 1
            continue

        if args.dry_run:
            print(f"[plan] {rel} @ {label}")
            print(f"       -> {part1.name}")
            print(f"       -> {part2.name}")
            ok += 1
            continue

        try:
            print(f"[run]  {rel} @ {label}")
            split_file(ffmpeg, file_path, part1, part2, split_seconds)
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
