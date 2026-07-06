#!/usr/bin/env python3
"""Batch denoise and optionally de-clip audio files using FFmpeg."""

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


def relative_path(file_path: Path, input_root: Path) -> str:
    try:
        return file_path.relative_to(input_root).as_posix()
    except ValueError:
        return file_path.name


def build_filter(declip: bool, denoise: bool, nr: float, nf: float) -> str:
    if not declip and not denoise:
        print(
            "Nothing to apply: enable denoise (default) and/or --declip / --declip-only.",
            file=sys.stderr,
        )
        sys.exit(1)

    parts: list[str] = []
    if declip:
        parts.append("adeclip")
    if denoise:
        parts.append(f"afftdn=nr={nr}:nf={nf}")
    return ",".join(parts)


def describe_mode(declip: bool, denoise: bool) -> str:
    if declip and denoise:
        return "de-clip + denoise"
    if declip:
        return "de-clip only"
    return "denoise only"


def denoise_file(
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
        detail = result.stderr.strip() or result.stdout.strip()
        raise RuntimeError(
            f"FFmpeg denoise failed for: {file_path}"
            + (f"\n{detail}" if detail else "")
        )


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Batch denoise and optionally de-clip audio files."
    )
    parser.add_argument("input", help="Path to a single audio file or directory")
    parser.add_argument(
        "--declip",
        action="store_true",
        help="Apply adeclip before denoise (clipped peaks)",
    )
    parser.add_argument(
        "--declip-only",
        action="store_true",
        help="Apply adeclip only (skip afftdn denoise)",
    )
    parser.add_argument(
        "--no-denoise",
        action="store_true",
        help="Skip afftdn denoise (use with --declip)",
    )
    parser.add_argument(
        "--nr",
        type=float,
        default=10,
        help="afftdn noise reduction in dB (default: 10)",
    )
    parser.add_argument(
        "--nf",
        type=float,
        default=-25,
        help="afftdn noise floor in dB (default: -25)",
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


def resolve_modes(args: argparse.Namespace) -> tuple[bool, bool]:
    if args.declip_only:
        return True, False
    declip = args.declip
    denoise = not args.no_denoise
    if not declip and not denoise:
        denoise = True
    return declip, denoise


def main() -> int:
    args = parse_args()
    if args.declip_only and (args.declip or args.no_denoise):
        print("--declip-only cannot be combined with --declip or --no-denoise", file=sys.stderr)
        return 1

    declip, denoise = resolve_modes(args)
    filter_str = build_filter(declip, denoise, args.nr, args.nf)
    mode_label = describe_mode(declip, denoise)

    ffmpeg = resolve_ffmpeg()

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
        Path(args.output_dir).resolve() if args.output_dir else input_root / "denoised"
    )

    print(f"Input:  {args.input}")
    print(f"Files:  {len(files)}")
    print(f"Mode:   {mode_label}")
    if denoise:
        print(f"afftdn: nr={args.nr} dB, nf={args.nf} dB")
    print(f"Filter: {filter_str}")
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
            print(f"[plan] {rel} -> {out_path}")
            ok += 1
            continue

        try:
            print(f"[run]  {rel}")
            denoise_file(ffmpeg, file_path, out_path, filter_str)
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
