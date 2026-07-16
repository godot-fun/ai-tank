"""
Remove Gemini / Veo video watermarks via Allen Kuo VeoWatermarkRemover.

Uses reverse alpha blending with optional ML intensity assist (--ml).
The wrapper only handles paths and batching; pixel processing stays in GWT-Video.

Run via manifest gemini-watermark-video.bin — see SKILL.md and skill-dependency-manager.
Never use host python outside .dependency/ for this skill.

Usage
-----
    .dependency/python/python.exe \\
        .cursor/skills/video-remove-watermark-gemini/scripts/remove_watermark.py video/foo.mp4

Default output: ``<source-dir>/no-watermark/`` beside each input file.
"""

from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from pathlib import Path

DEFAULT_DIR = "video"
DEFAULT_PATTERN = "*.mp4"
DEFAULT_OUTPUT_SUBDIR = "no-watermark"
DEFAULT_EXCLUDES: tuple[str, ...] = (
    "*_processed.mp4",
    f"{DEFAULT_OUTPUT_SUBDIR}/*",
    f"**/{DEFAULT_OUTPUT_SUBDIR}/**",
)
VIDEO_EXTENSIONS = {".mp4", ".mkv", ".mov", ".webm"}

SKIP_RE = re.compile(r"\bSKIP\b", re.IGNORECASE)
OK_RE = re.compile(r"\bOK\b|\bdone\b|\bprocessed\b|\bsaved\b", re.IGNORECASE)
VARIANT_CHOICES = ("720p-1", "720p-2")


def find_repo_root(start: Path) -> Path | None:
    for parent in [start.resolve(), *start.resolve().parents]:
        if (parent / ".dependency" / "manifest.json").is_file():
            return parent
    return None


def resolve_input_path(directory: str) -> Path:
    return Path(directory).expanduser().resolve()


def collect_videos(
    target_dir: Path,
    pattern: str,
    excludes: tuple[str, ...],
    recursive: bool,
) -> list[Path]:
    excluded: set[Path] = set()
    for exclude in excludes:
        excluded.update(target_dir.rglob(exclude) if recursive else target_dir.glob(exclude))

    globber = target_dir.rglob if recursive else target_dir.glob
    patterns = {pattern}
    if pattern == "*.mp4":
        patterns.update({"*.mkv", "*.mov", "*.webm"})

    videos: list[Path] = []
    seen: set[Path] = set()
    for pat in patterns:
        for path in globber(pat):
            resolved = path.resolve()
            if resolved in seen or resolved in excluded or not path.is_file():
                continue
            if path.suffix.lower() not in VIDEO_EXTENSIONS:
                continue
            seen.add(resolved)
            videos.append(resolved)
    return sorted(videos)


def resolve_input(
    input_path: Path,
    pattern: str,
    excludes: tuple[str, ...],
    recursive: bool,
) -> tuple[Path | None, list[Path]]:
    if input_path.is_file():
        if input_path.suffix.lower() not in VIDEO_EXTENSIONS:
            print(f"Unsupported video type: {input_path}", file=sys.stderr)
            return None, []
        return input_path.parent, [input_path]

    if not input_path.is_dir():
        print(f"Path not found: {input_path}", file=sys.stderr)
        return None, []

    videos = collect_videos(input_path, pattern, excludes, recursive)
    return input_path, videos


def resolve_output_dir(
    input_root: Path,
    output_dir: Path | None,
    output_subdir: str,
) -> Path | None:
    if output_dir is None:
        return None
    if output_dir.is_absolute():
        return output_dir.resolve()
    return (input_root / output_dir).resolve()


def resolve_dest(
    video_path: Path,
    input_root: Path,
    output_dir: Path | None,
    output_subdir: str,
) -> Path:
    if output_dir is not None:
        try:
            rel = video_path.relative_to(input_root)
        except ValueError:
            rel = Path(video_path.name)
        dest = output_dir / rel
    else:
        dest = video_path.parent / output_subdir / video_path.name
    dest.parent.mkdir(parents=True, exist_ok=True)
    return dest.resolve()


def resolve_gwt_video(project_root: Path) -> Path:
    base = project_root / ".dependency/gemini-watermark-video-tool"
    for name in ("GeminiWatermarkTool-Video.exe", "GeminiWatermarkTool-Video"):
        candidate = base / name
        if candidate.is_file():
            return candidate.resolve()
    raise FileNotFoundError(
        "GeminiWatermarkTool-Video not found. Download v0.6.4-demo release into "
        ".dependency/gemini-watermark-video-tool/ (see SKILL.md)."
    )


def parse_gwt_output(stdout: str, stderr: str) -> dict:
    combined = f"{stdout}\n{stderr}"
    meta: dict = {"applied": False}

    if SKIP_RE.search(combined):
        meta["skipReason"] = "no watermark detected"
        return meta

    if OK_RE.search(combined) or "100%" in combined:
        meta["applied"] = True

    variant_match = re.search(r"variant[:\s]+(\S+)", combined, re.IGNORECASE)
    if variant_match:
        meta["variant"] = variant_match.group(1)

    legacy_match = re.search(r"legacy", combined, re.IGNORECASE)
    if legacy_match:
        meta["legacy"] = True

    return meta


def run_gwt_video(
    gwt_bin: Path,
    input_path: Path,
    output_path: Path,
    *,
    legacy: bool,
    ml: bool,
    variant: str | None,
    sigma: int | None,
    verbose: bool,
) -> tuple[int, dict]:
    command = [
        str(gwt_bin),
        "-i",
        str(input_path),
        "-o",
        str(output_path),
    ]
    if legacy:
        command.append("--legacy")
    if ml:
        command.append("--ml")
    if variant:
        command.extend(["--variant", variant])
    if sigma is not None:
        command.extend(["--sigma", str(sigma)])
    if verbose:
        command.append("--verbose")

    result = subprocess.run(
        command,
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
        check=False,
    )
    combined = f"{result.stdout}\n{result.stderr}".strip()
    meta = parse_gwt_output(result.stdout, result.stderr)
    meta["exitCode"] = result.returncode
    if combined:
        meta["log"] = combined
    if result.returncode == 0 and output_path.is_file():
        meta["applied"] = True
    elif result.returncode == 1:
        meta["applied"] = False
        meta.setdefault("skipReason", "no watermark detected")
    return result.returncode, meta


def format_meta(meta: dict) -> str:
    if not meta.get("applied"):
        reason = meta.get("skipReason") or "skipped"
        return f"  Skipped: {reason}"

    parts: list[str] = []
    if meta.get("legacy"):
        parts.append("legacy profile")
    variant = meta.get("variant")
    if variant:
        parts.append(f"variant {variant}")
    return f"  {'; '.join(parts)}" if parts else "  Processed"


def process_video(
    gwt_bin: Path,
    video_path: Path,
    dest_path: Path,
    *,
    legacy: bool,
    ml: bool,
    variant: str | None,
    sigma: int | None,
    json_output: bool,
) -> dict:
    exit_code, meta = run_gwt_video(
        gwt_bin,
        video_path,
        dest_path,
        legacy=legacy,
        ml=ml,
        variant=variant,
        sigma=sigma,
        verbose=True,
    )

    if exit_code == 2:
        log = meta.get("log", "unknown error")
        raise RuntimeError(log)
    if exit_code == 1:
        meta["applied"] = False
        meta.setdefault("skipReason", "no watermark detected")

    if json_output:
        print(json.dumps({"file": str(video_path), "output": str(dest_path), "meta": meta}))

    detail = format_meta(meta)
    if detail:
        print(detail)
    if meta.get("applied"):
        print(f"  Saved {dest_path}")
    else:
        print(f"  No output written for {video_path.name}")
    return meta


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Remove Gemini / Veo video watermarks (GeminiWatermarkTool-Video).",
    )
    parser.add_argument(
        "directory",
        nargs="?",
        default=DEFAULT_DIR,
        help=f"Video file or directory (default: {DEFAULT_DIR})",
    )
    parser.add_argument("--pattern", default=DEFAULT_PATTERN, help="Input glob pattern")
    parser.add_argument("--recursive", action="store_true", help="Search subdirectories")
    parser.add_argument("--exclude", action="append", default=[], help="Extra glob excludes")
    parser.add_argument(
        "--output-dir",
        type=Path,
        help=f"Shared output directory (default: <source-dir>/{DEFAULT_OUTPUT_SUBDIR}/ per file)",
    )
    parser.add_argument(
        "--output-subdir",
        default=DEFAULT_OUTPUT_SUBDIR,
        help=f"Subfolder beside each source file when --output-dir is omitted (default: {DEFAULT_OUTPUT_SUBDIR})",
    )
    parser.add_argument(
        "--legacy",
        action="store_true",
        help="Pre-Gemini-3.5 larger Veo text watermark profile",
    )
    parser.add_argument(
        "--ml",
        action="store_true",
        help="Opt-in ML intensity assist for clips with varying intensity",
    )
    parser.add_argument(
        "--variant",
        choices=VARIANT_CHOICES,
        help="Force 720p geometry when auto-detect fails (720p-1 standard, 720p-2 compact)",
    )
    parser.add_argument(
        "--sigma",
        type=int,
        help="AI denoise sigma (lower for anime/illustration, e.g. 15; higher for photo, e.g. 25)",
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Print structured metadata for each processed video",
    )
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv or sys.argv[1:])

    project_root = find_repo_root(Path(__file__))
    if project_root is None:
        print(
            "Could not find .dependency/manifest.json. "
            "Run from a repo that follows .cursor/rules/skill-dependency-manager.md.",
            file=sys.stderr,
        )
        return 1

    try:
        gwt_bin = resolve_gwt_video(project_root)
    except FileNotFoundError as exc:
        print(str(exc), file=sys.stderr)
        return 1

    input_path = resolve_input_path(args.directory)
    input_root, video_paths = resolve_input(
        input_path,
        args.pattern,
        tuple(DEFAULT_EXCLUDES) + tuple(args.exclude),
        args.recursive,
    )
    if input_root is None:
        return 1
    if not video_paths:
        print(f"No videos found under {input_root} (pattern: {args.pattern})")
        return 1

    output_dir = resolve_output_dir(input_root, args.output_dir, args.output_subdir)
    if output_dir is not None:
        output_dir.mkdir(parents=True, exist_ok=True)

    print(f"Input: {input_path}")
    print(f"Videos: {len(video_paths)}")
    print("Engine: GeminiWatermarkTool-Video v0.6.4 (reverse alpha, audio passthrough)")
    if args.legacy:
        print("Profile: legacy (pre-Gemini 3.5 Veo text)")
    if args.ml:
        print("ML assist: enabled")
    if args.variant:
        print(f"Variant: {args.variant}")
    if args.sigma is not None:
        print(f"Sigma: {args.sigma}")
    if output_dir is not None:
        print(f"Output folder: {output_dir}")
    else:
        print(f"Output: <each-source-dir>/{args.output_subdir}/")

    errors = 0
    skipped = 0
    for video_path in video_paths:
        dest = resolve_dest(video_path, input_root, output_dir, args.output_subdir)
        print(f"Processing {video_path.name} ...")
        try:
            meta = process_video(
                gwt_bin,
                video_path,
                dest,
                legacy=args.legacy,
                ml=args.ml,
                variant=args.variant,
                sigma=args.sigma,
                json_output=args.json,
            )
            if not meta.get("applied"):
                skipped += 1
        except RuntimeError as exc:
            print(f"  ERROR {video_path.name}: {exc}", file=sys.stderr)
            errors += 1

    if errors:
        print(f"Done with {errors} error(s).", file=sys.stderr)
        return 1

    if output_dir is not None:
        print(f"Done. Processed {len(video_paths)} video(s) in {output_dir}")
    else:
        print(f"Done. Processed {len(video_paths)} video(s) beside their sources")
    if skipped:
        print(f"Skipped {skipped} video(s) without detectable watermark.")
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except KeyboardInterrupt:
        sys.exit(130)
