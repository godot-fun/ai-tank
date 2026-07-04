#!/usr/bin/env python3
"""Normalize filenames: split on common separators, clean segments, join with hyphens."""

from __future__ import annotations

import argparse
import re
import shutil
import sys
from pathlib import Path

SPLIT_PATTERN = re.compile(r"[_\-\s.]+")
LEADING_DIGITS = re.compile(r"^\d+")
TRAILING_DIGITS = re.compile(r"\d+$")
ALL_DIGITS = re.compile(r"^\d+$")
ID_DIGIT_MIN_LEN = 4


def clean_segment(part: str) -> str | None:
    if ALL_DIGITS.match(part):
        return None if len(part) >= ID_DIGIT_MIN_LEN else part
    segment = LEADING_DIGITS.sub("", part)
    segment = TRAILING_DIGITS.sub("", segment)
    return segment.strip() or None


def normalize_stem(stem: str, strip_strings: list[str], strip_case_insensitive: bool) -> str:
    parts = [p for p in SPLIT_PATTERN.split(stem) if p]
    cleaned: list[str] = []

    for part in parts:
        segment = clean_segment(part)
        if segment is None:
            continue

        for text in strip_strings:
            if strip_case_insensitive:
                segment = re.sub(re.escape(text), "", segment, flags=re.IGNORECASE)
            else:
                segment = segment.replace(text, "")

        if segment:
            cleaned.append(segment)

    return "-".join(cleaned)


def target_name(path: Path, strip_strings: list[str], strip_case_insensitive: bool) -> str | None:
    new_stem = normalize_stem(path.stem, strip_strings, strip_case_insensitive)
    if not new_stem:
        return None
    new_name = f"{new_stem}{path.suffix}"
    return new_name if new_name != path.name else None


def collect_files(root: Path, recursive: bool) -> list[Path]:
    if root.is_file():
        return [root]
    if not root.is_dir():
        raise FileNotFoundError(root)

    if recursive:
        return sorted(p for p in root.rglob("*") if p.is_file())
    return sorted(p for p in root.iterdir() if p.is_file())


def resolve_destination(src: Path, input_path: Path, new_name: str, output_dir: Path | None) -> Path:
    if output_dir is None:
        return src.with_name(new_name)

    if input_path.is_file():
        return output_dir / new_name

    relative_parent = src.parent.relative_to(input_path)
    return output_dir / relative_parent / new_name


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Normalize filenames by splitting, cleaning segments, and joining with hyphens."
    )
    parser.add_argument("path", type=Path, help="File or directory to process")
    parser.add_argument("-r", "--recursive", action="store_true", help="Process files in subdirectories")
    parser.add_argument(
        "--strip",
        action="append",
        default=[],
        metavar="TEXT",
        help="Remove this substring from each segment (repeatable)",
    )
    parser.add_argument(
        "--strip-case-insensitive",
        action="store_true",
        help="Match --strip strings case-insensitively",
    )
    parser.add_argument("-o", "--output-dir", type=Path, help="Write renamed copies here instead of in-place rename")
    parser.add_argument("--dry-run", action="store_true", help="Print planned renames without changing files")
    parser.add_argument("--overwrite", action="store_true", help="Overwrite existing destination files")
    args = parser.parse_args()

    try:
        files = collect_files(args.path, args.recursive)
    except FileNotFoundError:
        print(f"Path not found: {args.path}", file=sys.stderr)
        return 1

    if not files:
        print("No files to process.", file=sys.stderr)
        return 1

    plans: list[tuple[Path, Path]] = []
    seen_targets: dict[tuple[Path, str], Path] = {}

    for src in files:
        new_name = target_name(src, args.strip, args.strip_case_insensitive)
        if new_name is None:
            continue

        dst = resolve_destination(src, args.path, new_name, args.output_dir)
        key = (dst.parent.resolve(), dst.name)
        if key in seen_targets and seen_targets[key] != src:
            print(
                f"Name collision: '{src}' and '{seen_targets[key]}' both map to '{dst}'",
                file=sys.stderr,
            )
            return 1
        seen_targets[key] = src
        plans.append((src, dst))

    if not plans:
        print("All filenames already normalized.")
        return 0

    for src, dst in plans:
        print(f"{src} -> {dst}")

    if args.dry_run:
        print(f"\nDry run: {len(plans)} file(s) would be renamed.")
        return 0

    for src, dst in plans:
        dst.parent.mkdir(parents=True, exist_ok=True)
        if dst.exists() and not args.overwrite:
            print(f"Destination exists (use --overwrite): {dst}", file=sys.stderr)
            return 1
        if args.output_dir:
            shutil.copy2(src, dst)
        else:
            src.rename(dst)

    print(f"\nRenamed {len(plans)} file(s).")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
