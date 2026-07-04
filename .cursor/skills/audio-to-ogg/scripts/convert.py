#!/usr/bin/env python3
"""Batch convert audio files to OGG Vorbis using FFmpeg."""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
from pathlib import Path

AUDIO_EXTENSIONS = {".wav", ".mp3", ".ogg", ".flac", ".aac", ".m4a", ".wma"}

DEFAULT_QUALITY = 6
GAME_STANDARD_SAMPLE_RATE = 48000
VORBIS_CODEC = "libvorbis"


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
        out_rel = Path(rel).with_suffix(".ogg").as_posix()
        out_path = output_dir / out_rel
        if out_path.resolve() == file_path.resolve():
            collisions.append((file_path, out_path))
    return collisions


def output_rel_path(file_path: Path, input_root: Path) -> str:
    rel = relative_path(file_path, input_root)
    return Path(rel).with_suffix(".ogg").as_posix()


def probe_audio(ffprobe: Path, file_path: Path) -> dict:
    result = subprocess.run(
        [
            str(ffprobe),
            "-v",
            "quiet",
            "-print_format",
            "json",
            "-show_streams",
            "-select_streams",
            "a:0",
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
    sample_rate = stream.get("sample_rate")
    try:
        sample_rate = int(sample_rate) if sample_rate else None
    except (TypeError, ValueError):
        sample_rate = None

    channels = stream.get("channels")
    try:
        channels = int(channels) if channels is not None else None
    except (TypeError, ValueError):
        channels = None

    return {
        "codec": stream.get("codec_name", ""),
        "sample_rate": sample_rate,
        "channels": channels,
    }


def can_stream_copy(
    file_path: Path,
    probe: dict,
    sample_rate: int | None,
    channels: int | None,
) -> bool:
    if sample_rate is not None or channels is not None:
        return False
    if file_path.suffix.lower() != ".ogg":
        return False
    return probe.get("codec", "") == "vorbis"


def build_ffmpeg_args(
    ffmpeg: Path,
    file_path: Path,
    out_path: Path,
    sample_rate: int | None,
    quality: int,
    channels: int | None,
    stream_copy: bool,
) -> list[str]:
    cmd = [
        str(ffmpeg),
        "-hide_banner",
        "-nostats",
        "-y",
        "-i",
        str(file_path),
    ]
    if stream_copy:
        cmd.extend(["-c:a", "copy", str(out_path)])
        return cmd

    if sample_rate is not None:
        cmd.extend(["-ar", str(sample_rate)])
    if channels is not None:
        cmd.extend(["-ac", str(channels)])
    cmd.extend(["-c:a", VORBIS_CODEC, "-q:a", str(quality), str(out_path)])
    return cmd


def convert_file(
    ffmpeg: Path,
    file_path: Path,
    out_path: Path,
    sample_rate: int | None,
    quality: int,
    channels: int | None,
    stream_copy: bool,
) -> None:
    out_path.parent.mkdir(parents=True, exist_ok=True)
    cmd = build_ffmpeg_args(
        ffmpeg, file_path, out_path, sample_rate, quality, channels, stream_copy
    )
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        detail = result.stderr.strip() or result.stdout.strip()
        raise RuntimeError(
            f"FFmpeg convert failed for: {file_path}"
            + (f"\n{detail}" if detail else "")
        )


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Batch convert audio files to OGG Vorbis."
    )
    parser.add_argument("input", help="Path to a single audio file or directory")
    parser.add_argument(
        "-o",
        "--output-dir",
        default="",
        help="Output directory (must not overwrite sources; default: <input>/ogg)",
    )
    parser.add_argument(
        "-r", "--recurse", action="store_true", help="Process subdirectories"
    )
    parser.add_argument(
        "-s",
        "--sample-rate",
        type=int,
        help="Force output sample rate in Hz (default: preserve source)",
    )
    parser.add_argument(
        "-q",
        "--quality",
        type=int,
        choices=range(0, 11),
        default=DEFAULT_QUALITY,
        help=f"Vorbis quality 0-10 (default: {DEFAULT_QUALITY})",
    )
    parser.add_argument(
        "--standardize",
        action="store_true",
        help="Resample to 48 kHz Vorbis (project batch preset)",
    )
    channel_group = parser.add_mutually_exclusive_group()
    channel_group.add_argument(
        "--mono", action="store_true", help="Force mono output"
    )
    channel_group.add_argument(
        "--stereo", action="store_true", help="Force stereo output"
    )
    parser.add_argument(
        "--overwrite", action="store_true", help="Replace existing output files"
    )
    parser.add_argument(
        "--dry-run", action="store_true", help="Preview without writing files"
    )
    return parser.parse_args()


def resolve_channels(args: argparse.Namespace) -> int | None:
    if args.mono:
        return 1
    if args.stereo:
        return 2
    return None


def resolve_forced_sample_rate(args: argparse.Namespace) -> int | None:
    if args.standardize:
        return GAME_STANDARD_SAMPLE_RATE
    return args.sample_rate


def describe_file_plan(
    probe: dict,
    forced_rate: int | None,
    quality: int,
    forced_channels: int | None,
    stream_copy: bool,
) -> str:
    if stream_copy:
        rate = probe.get("sample_rate")
        ch = probe.get("channels") or "?"
        return f"stream copy ({rate} Hz, {ch} ch)"

    rate = f"{forced_rate} Hz" if forced_rate else "source rate"
    ch = {1: "mono", 2: "stereo"}.get(forced_channels, "preserve")
    return f"{rate}, Vorbis q={quality}, {ch}"


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

    output_dir = (
        Path(args.output_dir).resolve()
        if args.output_dir
        else input_root / "ogg"
    )

    forced_rate = resolve_forced_sample_rate(args)
    forced_channels = resolve_channels(args)

    initial_count = len(files)
    files = filter_output_files(files, output_dir)
    if not files:
        if initial_count:
            print(
                "No source files to process: all inputs lie under the output directory. "
                "Choose a separate output directory (default: ogg/).",
                file=sys.stderr,
            )
            return 1
        print(f"No supported audio files found under: {args.input}")
        return 0

    collisions = find_source_collisions(files, input_root, output_dir)
    if collisions:
        print(
            "Refusing to overwrite source files. Use a separate output directory "
            "(default: ogg/).",
            file=sys.stderr,
        )
        for source, dest in collisions:
            print(f"  {source} -> {dest}", file=sys.stderr)
        return 1

    mode = (
        f"standardize (48 kHz, q={args.quality})"
        if args.standardize
        else f"Vorbis q={args.quality}, preserve sample rate"
    )
    print(f"Input:  {args.input}")
    print(f"Files:  {len(files)}")
    print(f"Mode:   {mode}")
    print(f"Output: {output_dir}")
    if args.dry_run:
        print("Run:    DRY RUN")
    print()

    ok = 0
    skip = 0
    fail = 0

    for file_path in files:
        rel = output_rel_path(file_path, input_root)
        out_path = output_dir / rel
        src_rel = relative_path(file_path, input_root)

        if out_path.exists() and not args.overwrite and not args.dry_run:
            print(f"[skip] {rel}")
            skip += 1
            continue

        probe = probe_audio(ffprobe, file_path)
        stream_copy = can_stream_copy(
            file_path, probe, forced_rate, forced_channels
        )
        plan = describe_file_plan(
            probe, forced_rate, args.quality, forced_channels, stream_copy
        )

        if args.dry_run:
            print(f"[plan] {src_rel} -> {rel} ({plan})")
            ok += 1
            continue

        try:
            print(f"[run]  {src_rel} -> {rel} ({plan})")
            convert_file(
                ffmpeg,
                file_path,
                out_path,
                forced_rate,
                args.quality,
                forced_channels,
                stream_copy,
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
