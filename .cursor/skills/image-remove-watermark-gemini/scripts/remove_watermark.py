"""
Remove Gemini sparkle watermarks via Allen Kuo GeminiWatermarkTool.

Uses reverse alpha blending with optional library cleanup (--denoise soft/ai/...).
The wrapper only handles paths and batching; pixel processing stays in GWT.

Run via manifest gemini-watermark.bin — see SKILL.md and skill-dependency-manager.
Never use host python outside .dependency/ for this skill.

Usage
-----
    .dependency/python/python.exe \\
        .cursor/skills/image-remove-watermark-gemini/scripts/remove_watermark.py image/foo.png

Default output: ``<source-dir>/no-watermark/`` beside each input file.
"""

from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from pathlib import Path

DEFAULT_DIR = "image"
DEFAULT_PATTERN = "*.png"
DEFAULT_OUTPUT_SUBDIR = "no-watermark"
DEFAULT_DENOISE = "soft"
DENOISE_CHOICES = ("ai", "ns", "telea", "soft", "off")
DEFAULT_EXCLUDES: tuple[str, ...] = (
    "*_sheet.png",
    "*_mask.png",
    f"{DEFAULT_OUTPUT_SUBDIR}/*",
    f"**/{DEFAULT_OUTPUT_SUBDIR}/**",
)
IMAGE_EXTENSIONS = {".png", ".jpg", ".jpeg", ".webp", ".bmp"}

DETECTED_RE = re.compile(
    r"Detected\s+\((\d+)%\),\s+region:\s+\((\d+),(\d+)\)\s+(\d+)x(\d+)\s+\[profile\s+(V\d+)\]",
    re.IGNORECASE,
)
DENOISE_RE = re.compile(r"Denoise:\s+(\w+)", re.IGNORECASE)


def find_repo_root(start: Path) -> Path | None:
    for parent in [start.resolve(), *start.resolve().parents]:
        if (parent / ".dependency" / "manifest.json").is_file():
            return parent
    return None


def resolve_input_path(directory: str) -> Path:
    return Path(directory).expanduser().resolve()


def collect_images(
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
    if pattern == "*.png":
        patterns.update({"*.jpg", "*.jpeg", "*.webp", "*.bmp"})

    images: list[Path] = []
    seen: set[Path] = set()
    for pat in patterns:
        for path in globber(pat):
            resolved = path.resolve()
            if resolved in seen or resolved in excluded or not path.is_file():
                continue
            if path.suffix.lower() not in IMAGE_EXTENSIONS:
                continue
            seen.add(resolved)
            images.append(resolved)
    return sorted(images)


def resolve_input(
    input_path: Path,
    pattern: str,
    excludes: tuple[str, ...],
    recursive: bool,
) -> tuple[Path | None, list[Path]]:
    if input_path.is_file():
        if input_path.suffix.lower() not in IMAGE_EXTENSIONS:
            print(f"Unsupported image type: {input_path}", file=sys.stderr)
            return None, []
        return input_path.parent, [input_path]

    if not input_path.is_dir():
        print(f"Path not found: {input_path}", file=sys.stderr)
        return None, []

    images = collect_images(input_path, pattern, excludes, recursive)
    return input_path, images


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
    image_path: Path,
    input_root: Path,
    output_dir: Path | None,
    output_subdir: str,
) -> Path:
    if output_dir is not None:
        try:
            rel = image_path.relative_to(input_root)
        except ValueError:
            rel = Path(image_path.name)
        dest = output_dir / rel
    else:
        dest = image_path.parent / output_subdir / image_path.name
    dest.parent.mkdir(parents=True, exist_ok=True)
    return dest.resolve()


def resolve_gwt(project_root: Path) -> Path:
    base = project_root / ".dependency/gemini-watermark-tool"
    for name in ("GeminiWatermarkTool.exe", "GeminiWatermarkTool"):
        candidate = base / name
        if candidate.is_file():
            return candidate.resolve()
    raise FileNotFoundError(
        "GeminiWatermarkTool not found. Download v0.3.1 release into "
        ".dependency/gemini-watermark-tool/ (see SKILL.md)."
    )


def parse_gwt_output(stdout: str, stderr: str, *, denoise: str) -> dict:
    combined = f"{stdout}\n{stderr}"
    meta: dict = {"applied": False, "denoise": denoise}

    if "Skipped" in combined or "skipped" in combined.lower():
        meta["skipReason"] = "no watermark detected"
        return meta

    match = DETECTED_RE.search(combined)
    if match:
        confidence_pct, x, y, width, height, profile = match.groups()
        meta.update(
            {
                "applied": True,
                "confidence": int(confidence_pct) / 100.0,
                "profile": profile,
                "position": {
                    "x": int(x),
                    "y": int(y),
                    "width": int(width),
                    "height": int(height),
                },
            }
        )
    elif "[OK]" in combined:
        meta["applied"] = True

    denoise_match = DENOISE_RE.search(combined)
    if denoise_match:
        meta["denoiseMethod"] = denoise_match.group(1).lower()
    if "+inpaint" in combined.lower():
        meta["inpaint"] = True

    return meta


def run_gwt(
    gwt_bin: Path,
    input_path: Path,
    output_path: Path,
    *,
    denoise: str,
    legacy: bool,
    no_legacy: bool,
    verbose: bool,
) -> tuple[int, dict]:
    command = [
        str(gwt_bin),
        "-i",
        str(input_path),
        "-o",
        str(output_path),
        "--no-banner",
        "--denoise",
        denoise,
    ]
    if legacy:
        command.append("--legacy")
    if no_legacy:
        command.append("--no-legacy")
    command.append("-v" if verbose else "-q")

    result = subprocess.run(
        command,
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
        check=False,
    )
    combined = f"{result.stdout}\n{result.stderr}".strip()
    meta = parse_gwt_output(result.stdout, result.stderr, denoise=denoise)
    meta["exitCode"] = result.returncode
    if combined and verbose:
        meta["log"] = combined
    return result.returncode, meta


def format_meta(meta: dict) -> str:
    if not meta.get("applied"):
        reason = meta.get("skipReason") or "skipped"
        return f"  Skipped: {reason}"

    parts: list[str] = []
    position = meta.get("position") or {}
    x = position.get("x")
    y = position.get("y")
    width = position.get("width")
    height = position.get("height")
    if x is not None and y is not None and width and height:
        parts.append(f"region ({x}, {y}) {width}x{height}")
    profile = meta.get("profile")
    if profile:
        parts.append(f"profile {profile}")
    confidence = meta.get("confidence")
    if confidence is not None:
        parts.append(f"conf {confidence:.0%}")
    denoise_method = meta.get("denoiseMethod") or meta.get("denoise")
    if denoise_method and denoise_method != "off":
        parts.append(f"denoise {denoise_method}")
    if meta.get("inpaint"):
        parts.append("inpaint")
    return f"  {'; '.join(parts)}" if parts else ""


def process_image(
    gwt_bin: Path,
    image_path: Path,
    dest_path: Path,
    *,
    denoise: str,
    legacy: bool,
    no_legacy: bool,
    json_output: bool,
) -> dict:
    exit_code, meta = run_gwt(
        gwt_bin,
        image_path,
        dest_path,
        denoise=denoise,
        legacy=legacy,
        no_legacy=no_legacy,
        verbose=True,
    )

    if exit_code == 2:
        log = meta.get("log", "unknown error")
        raise RuntimeError(log)
    if exit_code == 1:
        meta["applied"] = False
        meta.setdefault("skipReason", "no watermark detected")

    if json_output:
        print(json.dumps({"file": str(image_path), "output": str(dest_path), "meta": meta}))

    detail = format_meta(meta)
    if detail:
        print(detail)
    if meta.get("applied"):
        print(f"  Saved {dest_path}")
    else:
        print(f"  No output written for {image_path.name}")
    return meta


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Remove Gemini sparkle watermarks (GeminiWatermarkTool + cleanup).",
    )
    parser.add_argument(
        "directory",
        nargs="?",
        default=DEFAULT_DIR,
        help=f"Image file or directory (default: {DEFAULT_DIR})",
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
        "--denoise",
        choices=DENOISE_CHOICES,
        default=DEFAULT_DENOISE,
        help=(
            "GWT cleanup after reverse alpha (default: soft). "
            "Use ai for GPU-accelerated FDnCNN (falls back to ns without Vulkan)."
        ),
    )
    parser.add_argument(
        "--legacy",
        action="store_true",
        help="Pin to pre-Gemini 3.5 watermark profile (V1 only)",
    )
    parser.add_argument(
        "--no-legacy",
        action="store_true",
        help="Disable automatic V2→V1 profile fallback",
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Print structured metadata for each processed image",
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
        gwt_bin = resolve_gwt(project_root)
    except FileNotFoundError as exc:
        print(str(exc), file=sys.stderr)
        return 1

    input_path = resolve_input_path(args.directory)
    input_root, image_paths = resolve_input(
        input_path,
        args.pattern,
        tuple(DEFAULT_EXCLUDES) + tuple(args.exclude),
        args.recursive,
    )
    if input_root is None:
        return 1
    if not image_paths:
        print(f"No images found under {input_root} (pattern: {args.pattern})")
        return 1

    output_dir = resolve_output_dir(input_root, args.output_dir, args.output_subdir)
    if output_dir is not None:
        output_dir.mkdir(parents=True, exist_ok=True)

    print(f"Input: {input_path}")
    print(f"Images: {len(image_paths)}")
    print("Engine: GeminiWatermarkTool v0.3.1 (reverse alpha + cleanup)")
    print(f"Denoise: {args.denoise}")
    if output_dir is not None:
        print(f"Output folder: {output_dir}")
    else:
        print(f"Output: <each-source-dir>/{args.output_subdir}/")

    errors = 0
    skipped = 0
    for image_path in image_paths:
        dest = resolve_dest(image_path, input_root, output_dir, args.output_subdir)
        print(f"Processing {image_path.name} ...")
        try:
            meta = process_image(
                gwt_bin,
                image_path,
                dest,
                denoise=args.denoise,
                legacy=args.legacy,
                no_legacy=args.no_legacy,
                json_output=args.json,
            )
            if not meta.get("applied"):
                skipped += 1
        except RuntimeError as exc:
            print(f"  ERROR {image_path.name}: {exc}", file=sys.stderr)
            errors += 1

    if errors:
        print(f"Done with {errors} error(s).", file=sys.stderr)
        return 1

    if output_dir is not None:
        print(f"Done. Processed {len(image_paths)} image(s) in {output_dir}")
    else:
        print(f"Done. Processed {len(image_paths)} image(s) beside their sources")
    if skipped:
        print(f"Skipped {skipped} image(s) without detectable watermark.")
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except KeyboardInterrupt:
        sys.exit(130)
