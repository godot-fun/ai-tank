#!/usr/bin/env python3
"""Batch apply fade-in and/or fade-out to audio files using FFmpeg afade."""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
from pathlib import Path

AUDIO_EXTENSIONS = {".wav", ".mp3", ".ogg", ".flac", ".aac", ".m4a", ".wma"}
VALID_CURVES = {
    "tri",
    "qsin",
    "hsin",
    "esin",
    "log",
    "ipar",
    "qua",
    "cub",
    "squ",
    "cbr",
    "par",
    "exp",
    "iqsin",
    "deci",
    "des",
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
    probe = ffmpeg.parent / name
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


def validate_fades(
    duration: float,
    fade_in: float,
    fade_out: float,
    fade_in_enabled: bool,
    fade_out_enabled: bool,
) -> None:
    total = 0.0
    if fade_in_enabled:
        if fade_in <= 0:
            raise ValueError("Fade-in duration must be greater than 0.")
        total += fade_in
    if fade_out_enabled:
        if fade_out <= 0:
            raise ValueError("Fade-out duration must be greater than 0.")
        total += fade_out
    if total >= duration:
        raise ValueError(
            f"Combined fade duration ({total:.3f}s) must be less than file duration "
            f"({duration:.3f}s)."
        )


def build_filter(
    duration: float,
    fade_in: float,
    fade_out: float,
    curve: str,
    fade_in_enabled: bool,
    fade_out_enabled: bool,
) -> str:
    parts: list[str] = []
    if fade_in_enabled:
        parts.append(f"afade=t=in:st=0:d={fade_in:.6f}:curve={curve}")
    if fade_out_enabled:
        start = max(0.0, duration - fade_out)
        parts.append(f"afade=t=out:st={start:.6f}:d={fade_out:.6f}:curve={curve}")
    if not parts:
        raise ValueError("At least one of fade-in or fade-out must be enabled.")
    return ",".join(parts)


def fade_file(
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
        raise RuntimeError(f"FFmpeg fade failed for: {file_path}")


def relative_path(file_path: Path, input_root: Path) -> str:
    try:
        return file_path.relative_to(input_root).as_posix()
    except ValueError:
        return file_path.name


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Batch apply fade-in and/or fade-out to audio files."
    )
    parser.add_argument("input", help="Path to a single audio file or directory")
    parser.add_argument(
        "-fi",
        "--fade-in",
        type=float,
        default=1.0,
        help="Fade-in duration in seconds (default: 1.0)",
    )
    parser.add_argument(
        "-fo",
        "--fade-out",
        type=float,
        default=1.0,
        help="Fade-out duration in seconds (default: 1.0)",
    )
    parser.add_argument(
        "--no-fade-in", action="store_true", help="Do not apply fade-in"
    )
    parser.add_argument(
        "--no-fade-out", action="store_true", help="Do not apply fade-out"
    )
    parser.add_argument(
        "-c",
        "--curve",
        default="tri",
        choices=sorted(VALID_CURVES),
        help="Fade curve (default: tri)",
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


def main() -> int:
    args = parse_args()
    ffmpeg = resolve_ffmpeg()
    ffprobe = resolve_ffprobe(ffmpeg)

    fade_in_enabled = not args.no_fade_in
    fade_out_enabled = not args.no_fade_out
    if not fade_in_enabled and not fade_out_enabled:
        print(
            "At least one of fade-in or fade-out must remain enabled.",
            file=sys.stderr,
        )
        return 1

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

    output_dir = Path(args.output_dir).resolve() if args.output_dir else input_root / "faded"

    fade_sides = []
    if fade_in_enabled:
        fade_sides.append(f"in {args.fade_in}s")
    if fade_out_enabled:
        fade_sides.append(f"out {args.fade_out}s")

    print(f"Input:  {args.input}")
    print(f"Files:  {len(files)}")
    print(f"Fade:   {', '.join(fade_sides)}")
    print(f"Curve:  {args.curve}")
    print(f"Output: {output_dir}")
    if args.dry_run:
        print("Mode:   DRY RUN")
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

        try:
            duration = get_duration(ffprobe, file_path)
            validate_fades(
                duration,
                args.fade_in,
                args.fade_out,
                fade_in_enabled,
                fade_out_enabled,
            )
            filter_str = build_filter(
                duration,
                args.fade_in,
                args.fade_out,
                args.curve,
                fade_in_enabled,
                fade_out_enabled,
            )
        except (RuntimeError, ValueError) as exc:
            print(f"[fail] {rel}")
            print(exc)
            fail += 1
            continue

        if args.dry_run:
            print(f"[plan] {rel} ({duration:.3f}s)")
            print(f"       filter: {filter_str}")
            print(f"       -> {out_path}")
            ok += 1
            continue

        try:
            print(f"[run]  {rel} ({duration:.3f}s)")
            fade_file(ffmpeg, file_path, out_path, filter_str)
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
