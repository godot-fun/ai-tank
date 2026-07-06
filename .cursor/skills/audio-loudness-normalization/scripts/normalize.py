#!/usr/bin/env python3
"""Batch loudness-normalize audio files to a target LUFS using FFmpeg two-pass loudnorm."""

from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from pathlib import Path

AUDIO_EXTENSIONS = {".wav", ".mp3", ".ogg", ".flac", ".aac", ".m4a", ".wma"}

SAMPLE_RATE_44100 = 44100
SAMPLE_RATE_48000 = 48000
ALLOWED_SAMPLE_RATES = (SAMPLE_RATE_44100, SAMPLE_RATE_48000)
OUTPUT_CODEC = "pcm_s16le"


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


def probe_sample_rate(ffprobe: Path, file_path: Path) -> int | None:
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
        return None

    try:
        payload = json.loads(result.stdout)
    except json.JSONDecodeError:
        return None

    streams = payload.get("streams") or []
    if not streams:
        return None

    sample_rate = streams[0].get("sample_rate")
    try:
        return int(sample_rate) if sample_rate else None
    except (TypeError, ValueError):
        return None


def resolve_output_sample_rate(source_rate: int | None) -> int:
    """Snap output to 44100 or 48000 Hz only."""
    if source_rate is None or source_rate <= SAMPLE_RATE_44100:
        return SAMPLE_RATE_44100
    return SAMPLE_RATE_48000


def describe_output_format(source_rate: int | None, output_rate: int) -> str:
    if source_rate is None:
        return f"{output_rate} Hz, 16-bit PCM WAV"
    if source_rate == output_rate:
        return f"{output_rate} Hz (preserved), 16-bit PCM WAV"
    return f"{output_rate} Hz (from {source_rate} Hz), 16-bit PCM WAV"


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


def output_rel_path(file_path: Path, input_root: Path) -> str:
    rel = relative_path(file_path, input_root)
    return Path(rel).with_suffix(".wav").as_posix()


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
        out_rel = output_rel_path(file_path, input_root)
        out_path = output_dir / out_rel
        if out_path.resolve() == file_path.resolve():
            collisions.append((file_path, out_path))
    return collisions


def measure_loudnorm(
    ffmpeg: Path, file_path: Path, target_lufs: float, true_peak: float
) -> dict:
    result = subprocess.run(
        [
            str(ffmpeg),
            "-hide_banner",
            "-nostats",
            "-i",
            str(file_path),
            "-af",
            f"loudnorm=I={target_lufs}:TP={true_peak}:LRA=11:print_format=json",
            "-f",
            "null",
            "-",
        ],
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        raise RuntimeError(
            f"FFmpeg analysis failed for: {file_path}\n{result.stderr.strip()}"
        )

    match = re.search(r"\{[\s\S]*\}", result.stderr)
    if not match:
        raise RuntimeError(f"Could not parse loudnorm JSON for: {file_path}")

    return json.loads(match.group(0))


def normalize_file(
    ffmpeg: Path,
    file_path: Path,
    out_path: Path,
    target_lufs: float,
    true_peak: float,
    measured: dict,
    sample_rate: int,
    codec: str,
) -> None:
    out_path.parent.mkdir(parents=True, exist_ok=True)
    filter_str = (
        f"loudnorm=I={target_lufs}:TP={true_peak}:LRA=11"
        f":measured_I={measured['input_i']}"
        f":measured_LRA={measured['input_lra']}"
        f":measured_TP={measured['input_tp']}"
        f":measured_thresh={measured['input_thresh']}"
        f":offset={measured['target_offset']}"
        ":linear=true"
    )
    cmd = [
        str(ffmpeg),
        "-hide_banner",
        "-nostats",
        "-y",
        "-i",
        str(file_path),
        "-af",
        filter_str,
        "-ar",
        str(sample_rate),
        "-c:a",
        codec,
        str(out_path),
    ]
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        detail = result.stderr.strip() or result.stdout.strip()
        raise RuntimeError(
            f"FFmpeg normalize failed for: {file_path}"
            + (f"\n{detail}" if detail else "")
        )


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Batch loudness-normalize audio files to a target LUFS."
    )
    parser.add_argument("input", help="Path to a single audio file or directory")
    parser.add_argument(
        "-t",
        "--target-lufs",
        type=float,
        default=-14,
        help="Target integrated loudness in LUFS (default: -14)",
    )
    parser.add_argument(
        "-tp",
        "--true-peak",
        type=float,
        default=-1.5,
        help="True peak limit in dBTP (default: -1.5)",
    )
    parser.add_argument(
        "-o",
        "--output-dir",
        default="",
        help="Output directory (must not overwrite sources; default: <input>/normalized)",
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
        else input_root / "normalized"
    )

    initial_count = len(files)
    files = filter_output_files(files, output_dir)
    if not files:
        if initial_count:
            print(
                "No source files to process: all inputs lie under the output directory. "
                "Choose a separate output directory (default: normalized/).",
                file=sys.stderr,
            )
            return 1
        print(f"No supported audio files found under: {args.input}")
        return 0

    collisions = find_source_collisions(files, input_root, output_dir)
    if collisions:
        print(
            "Refusing to overwrite source files. Use a separate output directory "
            "(default: normalized/).",
            file=sys.stderr,
        )
        for source, dest in collisions:
            print(f"  {source} -> {dest}", file=sys.stderr)
        return 1

    print(f"Input:       {args.input}")
    print(f"Files:       {len(files)}")
    print(f"Target LUFS: {args.target_lufs}")
    print(f"True Peak:   {args.true_peak} dBTP")
    print(f"Format:      {SAMPLE_RATE_44100} / {SAMPLE_RATE_48000} Hz, 16-bit PCM WAV")
    print(f"Output:      {output_dir}")
    if args.dry_run:
        print("Mode:        DRY RUN")
    print()

    ok = 0
    skip = 0
    fail = 0

    for file_path in files:
        src_rel = relative_path(file_path, input_root)
        out_rel = output_rel_path(file_path, input_root)
        out_path = output_dir / out_rel

        if out_path.exists() and not args.overwrite and not args.dry_run:
            print(f"[skip] {out_rel}")
            skip += 1
            continue

        source_rate = probe_sample_rate(ffprobe, file_path)
        output_rate = resolve_output_sample_rate(source_rate)
        format_plan = describe_output_format(source_rate, output_rate)

        if args.dry_run:
            print(f"[plan] {src_rel} -> {out_rel} ({format_plan})")
            ok += 1
            continue

        try:
            print(f"[run]  {src_rel} -> {out_rel} ({format_plan})")
            measured = measure_loudnorm(
                ffmpeg, file_path, args.target_lufs, args.true_peak
            )
            normalize_file(
                ffmpeg,
                file_path,
                out_path,
                args.target_lufs,
                args.true_peak,
                measured,
                output_rate,
                OUTPUT_CODEC,
            )
            ok += 1
        except RuntimeError as exc:
            print(f"[fail] {out_rel}")
            print(exc)
            fail += 1

    print()
    print(f"Done. processed={ok} skipped={skip} failed={fail}")
    return 1 if fail else 0


if __name__ == "__main__":
    sys.exit(main())
