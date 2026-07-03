#!/usr/bin/env python3
"""Batch trim leading and/or trailing silence from audio files using FFmpeg silenceremove."""

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


def build_filter(threshold: float, trim_start: bool, trim_end: bool) -> str:
    if not trim_start and not trim_end:
        print(
            "At least one of --no-start or --no-end must remain enabled (trim start and/or end).",
            file=sys.stderr,
        )
        sys.exit(1)

    parts: list[str] = []
    if trim_start:
        parts.extend(
            [
                "start_periods=1",
                "start_duration=0",
                f"start_threshold={threshold}dB",
            ]
        )
    if trim_end:
        parts.extend(
            [
                "stop_periods=1",
                "stop_duration=0",
                f"stop_threshold={threshold}dB",
            ]
        )
    return "silenceremove=" + ":".join(parts)


def trim_file(
    ffmpeg: Path, file_path: Path, out_path: Path, filter_str: str
) -> None:
    out_path.parent.mkdir(parents=True, exist_ok=True)
    result = subprocess.run(
        [
            str(ffmpeg),
            "-hide_banner",
            "-nostats",
            "-y",
            "-i",
            str(file_path),
            "-af",
            filter_str,
            str(out_path),
        ],
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        raise RuntimeError(f"FFmpeg trim failed for: {file_path}")


def relative_path(file_path: Path, input_root: Path) -> str:
    try:
        return file_path.relative_to(input_root).as_posix()
    except ValueError:
        return file_path.name


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Batch trim leading and/or trailing silence from audio files."
    )
    parser.add_argument("input", help="Path to a single audio file or directory")
    parser.add_argument(
        "-t",
        "--threshold",
        type=float,
        default=-50,
        help="Silence threshold in dB (default: -50)",
    )
    parser.add_argument("--no-start", action="store_true", help="Do not trim start")
    parser.add_argument("--no-end", action="store_true", help="Do not trim end")
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


def main() -> int:
    args = parse_args()
    ffmpeg = resolve_ffmpeg()

    trim_start = not args.no_start
    trim_end = not args.no_end
    filter_str = build_filter(args.threshold, trim_start, trim_end)

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

    output_dir = Path(args.output_dir).resolve() if args.output_dir else input_root / "trimmed"

    trim_sides = []
    if trim_start:
        trim_sides.append("start")
    if trim_end:
        trim_sides.append("end")

    print(f"Input:     {args.input}")
    print(f"Files:     {len(files)}")
    print(f"Threshold: {args.threshold} dB")
    print(f"Trim:      {', '.join(trim_sides)}")
    print(f"Filter:    {filter_str}")
    print(f"Output:    {output_dir}")
    if args.dry_run:
        print("Mode:      DRY RUN")
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
            print(f"[plan] {rel} -> {out_path}")
            ok += 1
            continue

        try:
            print(f"[run]  {rel}")
            trim_file(ffmpeg, file_path, out_path, filter_str)
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
