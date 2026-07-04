"""
Batch watermark removal via LaMa / IOPaint deep-learning inpainting.

Semantically repaints watermark regions defined by a mask.
Mask convention: white (255) = repair, black (0) = keep.

Run via manifest iopaint.bin (.dependency/iopaint/.venv/) — see SKILL.md and
skill-dependency-manager. Never use host python/py.

Usage
-----
    .dependency/iopaint/.venv/Scripts/python \\
        .cursor/skills/image-remove-watermark/scripts/remove_watermark.py image/foo \\
        --corner bottom-right --width 0.28 --height 0.10 --margin 0.02

Default output: overwrite each source file at its original path. Use --output-dir
for copies elsewhere. Commit or back up before running.
"""

from __future__ import annotations

import argparse
import json
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

DEFAULT_DIR = "image"
DEFAULT_PATTERN = "*.png"
DEFAULT_MODEL = "lama"
DEFAULT_DEVICE = "auto"
DEFAULT_EXPAND = 8
DEFAULT_EXCLUDES: tuple[str, ...] = ("*_sheet.png", "*_mask.png")

# IOPaint HD strategy — auto-selected from image size + device (see resolve_iopaint_config)
HD_DEFAULT_MAX_SIDE = 1280  # at or below: IOPaint built-in defaults, no config file
HD_CUDA_LIMIT = 2048
HD_MPS_LIMIT = 1536
HD_CPU_LIMIT = 1024

CORNER_CHOICES = ("bottom-right", "bottom-left", "top-right", "top-left", "center")


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


def resolve_iopaint_python() -> Path:
    repo_root = find_repo_root(Path(__file__))
    if repo_root is None:
        print(
            "Could not find .dependency/manifest.json by walking up from this script. "
            "Run from a repo that follows .cursor/rules/skill-dependency-manager.md.",
            file=sys.stderr,
        )
        sys.exit(1)
    return resolve_tool_bin(repo_root, "iopaint")


def find_project_root() -> Path:
    current = Path(__file__).resolve()
    for parent in current.parents:
        if (parent / "project.godot").exists():
            return parent
    raise RuntimeError("Could not find project root (project.godot)")


def detect_device(requested: str) -> str:
    if requested != "auto":
        return requested
    try:
        import torch

        if torch.cuda.is_available():
            return "cuda"
        if hasattr(torch.backends, "mps") and torch.backends.mps.is_available():
            return "mps"
    except ImportError:
        pass
    return "cpu"


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
    images = sorted(
        path.resolve()
        for path in globber(pattern)
        if path not in excluded and path.is_file()
    )
    return images


def resolve_input(
    project_root: Path,
    directory: str,
    pattern: str,
    excludes: tuple[str, ...],
    recursive: bool,
) -> tuple[Path | None, list[Path]]:
    """Return (search_root, image_paths). search_root is the directory arg or file's parent."""
    input_path = (project_root / directory).resolve()
    if input_path.is_file():
        suffix = input_path.suffix.lower()
        if suffix not in {".png", ".jpg", ".jpeg", ".webp"}:
            print(f"Unsupported image type: {input_path}")
            return None, []
        return input_path.parent, [input_path]

    if not input_path.is_dir():
        print(f"Path not found: {input_path}")
        return None, []

    images = collect_images(input_path, pattern, excludes, recursive)
    return input_path, images


def mask_key(image_path: Path, search_root: Path) -> str:
    """Unique mask filename; preserves subpaths when batching under a parent directory."""
    try:
        rel = image_path.relative_to(search_root)
        if rel.parent == Path("."):
            return rel.name
        return "__".join(rel.parts)
    except ValueError:
        return image_path.name


def resolve_dest(image_path: Path, search_root: Path, output_dir: Path | None) -> Path:
    """Default: overwrite the source file. --output-dir keeps relative layout under search_root."""
    if output_dir is None:
        return image_path.resolve()
    dest = output_dir / image_path.relative_to(search_root)
    dest.parent.mkdir(parents=True, exist_ok=True)
    return dest.resolve()


def parse_fraction(value: str, name: str, *, allow_zero: bool = False) -> float:
    text = value.strip()
    if text.endswith("%"):
        number = float(text[:-1]) / 100.0
    else:
        number = float(text)
        if number > 1.0:
            raise ValueError(f"{name} must be a fraction (0-1) or percentage, got {value!r}")
    if allow_zero:
        if not 0.0 <= number <= 1.0:
            raise ValueError(f"{name} must be in [0, 1], got {number}")
    elif not 0.0 < number <= 1.0:
        raise ValueError(f"{name} must be in (0, 1], got {number}")
    return number


def parse_rect(value: str, image_size: tuple[int, int]) -> tuple[int, int, int, int]:
    """Parse x,y,w,h where each component is int pixels or percentage."""
    parts = [part.strip() for part in value.split(",")]
    if len(parts) != 4:
        raise ValueError(f"--rect expects 4 comma-separated values, got {value!r}")

    width, height = image_size

    def to_px(part: str, axis: str) -> int:
        if part.endswith("%"):
            fraction = float(part[:-1]) / 100.0
            limit = width if axis == "x" else height
            return int(round(limit * fraction))
        return int(round(float(part)))

    x = to_px(parts[0], "x")
    y = to_px(parts[1], "y")
    w = to_px(parts[2], "x")
    h = to_px(parts[3], "y")
    if w <= 0 or h <= 0:
        raise ValueError(f"Rect width/height must be positive: {value!r}")
    return x, y, w, h


def corner_rect(
    image_size: tuple[int, int],
    corner: str,
    width_frac: float,
    height_frac: float,
    margin_frac: float,
) -> tuple[int, int, int, int]:
    img_w, img_h = image_size
    box_w = max(1, int(round(img_w * width_frac)))
    box_h = max(1, int(round(img_h * height_frac)))
    margin_x = int(round(img_w * margin_frac))
    margin_y = int(round(img_h * margin_frac))

    if corner == "bottom-right":
        x0 = img_w - box_w - margin_x
        y0 = img_h - box_h - margin_y
    elif corner == "bottom-left":
        x0 = margin_x
        y0 = img_h - box_h - margin_y
    elif corner == "top-right":
        x0 = img_w - box_w - margin_x
        y0 = margin_y
    elif corner == "top-left":
        x0 = margin_x
        y0 = margin_y
    elif corner == "center":
        x0 = (img_w - box_w) // 2
        y0 = (img_h - box_h) // 2
    else:
        raise ValueError(f"Unknown corner: {corner}")

    x0 = max(0, min(x0, img_w - 1))
    y0 = max(0, min(y0, img_h - 1))
    box_w = min(box_w, img_w - x0)
    box_h = min(box_h, img_h - y0)
    return x0, y0, box_w, box_h


def make_rect_mask(image_size: tuple[int, int], rect: tuple[int, int, int, int]) -> Image.Image:
    x, y, w, h = rect
    mask = Image.new("L", image_size, 0)
    draw = ImageDraw.Draw(mask)
    draw.rectangle([x, y, x + w, y + h], fill=255)
    return mask


def dilate_mask(mask: Image.Image, expand: int) -> Image.Image:
    if expand <= 0:
        return mask
    size = expand * 2 + 1
    return mask.filter(ImageFilter.MaxFilter(size=size))


def resolve_mask_path(
    image_path: Path,
    mask_file: Path | None,
    mask_dir: Path | None,
    search_root: Path | None = None,
    generated_masks: dict[Path, Path] | None = None,
) -> Path | None:
    if generated_masks is not None:
        candidate = generated_masks.get(image_path)
        if candidate is not None:
            return candidate
    if mask_file is not None:
        return mask_file
    if mask_dir is None:
        return None
    if search_root is not None:
        keyed = mask_dir / mask_key(image_path, search_root)
        if keyed.is_file():
            return keyed
    candidate = mask_dir / image_path.name
    if candidate.is_file():
        return candidate
    stem_candidate = mask_dir / f"{image_path.stem}_mask{image_path.suffix}"
    if stem_candidate.is_file():
        return stem_candidate
    return None


def generate_masks(
    image_paths: list[Path],
    mask_dir: Path,
    search_root: Path,
    *,
    rect_spec: str | None,
    corner: str | None,
    width_frac: float | None,
    height_frac: float | None,
    margin_frac: float,
    expand: int,
) -> dict[Path, Path]:
    mask_dir.mkdir(parents=True, exist_ok=True)
    mask_by_image: dict[Path, Path] = {}

    for image_path in image_paths:
        with Image.open(image_path) as image:
            size = image.size

        if rect_spec is not None:
            rect = parse_rect(rect_spec, size)
        elif corner is not None:
            if width_frac is None or height_frac is None:
                raise ValueError("--corner requires --width and --height")
            rect = corner_rect(size, corner, width_frac, height_frac, margin_frac)
        else:
            raise RuntimeError("generate_masks called without rect or corner")

        mask = make_rect_mask(size, rect)
        mask = dilate_mask(mask, expand)
        out_path = mask_dir / mask_key(image_path, search_root)
        mask.save(out_path)
        mask_by_image[image_path] = out_path

    return mask_by_image


def max_image_dimension(image_paths: list[Path]) -> int:
    largest = 0
    for image_path in image_paths:
        with Image.open(image_path) as image:
            width, height = image.size
        largest = max(largest, width, height)
    return largest


def resolve_iopaint_config(
    image_paths: list[Path],
    device: str,
    *,
    override_path: Path | None = None,
    hd_limit: int | None = None,
) -> tuple[Path | None, Path | None]:
    """Return (config path for iopaint, temp file to delete after run)."""
    if override_path is not None:
        print(f"HD config: {override_path} (manual override)")
        return override_path, None

    max_side = max_image_dimension(image_paths)
    if max_side <= HD_DEFAULT_MAX_SIDE:
        print(f"HD config: auto default (max side {max_side}px)")
        return None, None

    if hd_limit is not None:
        limit = hd_limit
    elif device == "cpu":
        limit = min(max_side, HD_CPU_LIMIT)
    elif device == "mps":
        limit = min(max_side, HD_MPS_LIMIT)
    else:
        limit = min(max_side, HD_CUDA_LIMIT)

    payload = {"hd_strategy": "Resize", "hd_strategy_resize_limit": limit}
    temp = tempfile.NamedTemporaryFile(
        mode="w",
        suffix=".json",
        prefix="iopaint_hd_",
        delete=False,
        encoding="utf-8",
    )
    json.dump(payload, temp)
    temp.close()
    temp_path = Path(temp.name)
    print(f"HD config: auto Resize limit={limit} (max side {max_side}px, device={device})")
    return temp_path, temp_path


def iopaint_cmd_prefix() -> list[str]:
    python_bin = resolve_iopaint_python()
    return [str(python_bin), "-m", "iopaint"]


def run_iopaint(
    *,
    model: str,
    device: str,
    image_path: Path,
    mask_path: Path,
    output_dir: Path,
    config: Path | None,
) -> None:
    """Run IOPaint. --output must be a directory, not a file path."""
    output_dir.mkdir(parents=True, exist_ok=True)
    cmd = [
        *iopaint_cmd_prefix(),
        "run",
        "--model",
        model,
        "--device",
        device,
        "--image",
        str(image_path),
        "--mask",
        str(mask_path),
        "--output",
        str(output_dir),
    ]
    if config is not None:
        cmd.extend(["--config", str(config)])

    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        message = result.stderr.strip() or result.stdout.strip() or "unknown error"
        raise RuntimeError(f"iopaint failed for {image_path.name}: {message}")


def merge_inpaint_result(
    original_path: Path,
    inpainted_path: Path,
    mask_path: Path,
    output_path: Path,
) -> None:
    """Keep original RGBA outside mask; apply inpainted RGB only inside mask."""
    with Image.open(original_path) as original:
        orig = np.array(original.convert("RGBA"))
    with Image.open(inpainted_path) as inpainted:
        inp_rgb = np.array(inpainted.convert("RGB"))
    with Image.open(mask_path) as mask_image:
        mask = np.array(mask_image.convert("L")) > 127

    result = orig.copy()
    result[mask, :3] = inp_rgb[mask]
    Image.fromarray(result).save(output_path)


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Remove watermarks with LaMa/IOPaint inpainting.",
    )
    parser.add_argument(
        "directory",
        nargs="?",
        default=DEFAULT_DIR,
        help=f"Image file or directory relative to project root (default: {DEFAULT_DIR})",
    )
    parser.add_argument("--pattern", default=DEFAULT_PATTERN, help="Input glob pattern")
    parser.add_argument("--recursive", action="store_true", help="Search subdirectories")
    parser.add_argument("--exclude", action="append", default=[], help="Extra glob excludes")
    parser.add_argument("--model", default=DEFAULT_MODEL, help="IOPaint model (default: lama)")
    parser.add_argument(
        "--device",
        default=DEFAULT_DEVICE,
        choices=("auto", "cpu", "cuda", "mps"),
        help="Compute device (default: auto)",
    )
    parser.add_argument("--expand", type=int, default=DEFAULT_EXPAND, help="Mask dilation px")
    parser.add_argument(
        "--config",
        type=Path,
        help="Optional IOPaint config JSON override (HD strategy is auto by default)",
    )
    parser.add_argument(
        "--hd-limit",
        type=int,
        help="Override auto resize limit for large images (CUDA OOM workaround)",
    )
    parser.add_argument(
        "--output-dir",
        type=Path,
        help="Write copies here instead of overwriting each source file at its original path",
    )
    parser.add_argument("--masks-only", action="store_true", help="Only generate masks, skip inpaint")

    mask_group = parser.add_mutually_exclusive_group()
    mask_group.add_argument("--mask", type=Path, help="Single mask PNG for all images")
    mask_group.add_argument("--mask-dir", type=Path, help="Directory of per-image mask PNGs")
    mask_group.add_argument("--rect", help="Mask rectangle x,y,w,h (pixels or percent)")
    mask_group.add_argument(
        "--corner",
        choices=CORNER_CHOICES,
        help="Preset corner watermark region",
    )

    parser.add_argument(
        "--width",
        help="Corner mask width as fraction or percent (with --corner)",
    )
    parser.add_argument(
        "--height",
        help="Corner mask height as fraction or percent (with --corner)",
    )
    parser.add_argument(
        "--margin",
        default="0",
        help="Corner margin from edge as fraction or percent (default: 0)",
    )
    return parser.parse_args(argv)


def validate_mask_source(args: argparse.Namespace) -> None:
    sources = [args.mask, args.mask_dir, args.rect, args.corner]
    if not any(sources):
        raise SystemExit(
            "Mask source required: use --mask, --mask-dir, --rect, or --corner "
            "(see SKILL.md)."
        )


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv or sys.argv[1:])
    validate_mask_source(args)

    project_root = find_project_root()
    search_root, image_paths = resolve_input(
        project_root,
        args.directory,
        args.pattern,
        tuple(DEFAULT_EXCLUDES) + tuple(args.exclude),
        args.recursive,
    )
    if search_root is None:
        return 1
    if not image_paths:
        print(f"No images found under {search_root} (pattern: {args.pattern})")
        return 1

    width_frac = parse_fraction(args.width, "--width") if args.width else None
    height_frac = parse_fraction(args.height, "--height") if args.height else None
    margin_frac = (
        parse_fraction(args.margin, "--margin", allow_zero=True) if args.corner else 0.0
    )

    device = detect_device(args.device)
    output_dir = (project_root / args.output_dir).resolve() if args.output_dir else None
    if output_dir is not None:
        output_dir.mkdir(parents=True, exist_ok=True)

    print(f"Target: {search_root}")
    print(f"Images: {len(image_paths)}, Model: {args.model}, Device: {device}")
    print(f"Output: {output_dir if output_dir else 'original file path (overwrite)'}")

    generated_mask_dir: Path | None = None
    generated_masks: dict[Path, Path] | None = None
    temp_ctx = None
    inpaint_ctx = None
    config_temp_path: Path | None = None

    try:
        if args.rect or args.corner:
            temp_ctx = tempfile.TemporaryDirectory(prefix="iopaint_masks_")
            generated_mask_dir = Path(temp_ctx.name)
            print(f"Generating masks in {generated_mask_dir} ...")
            generated_masks = generate_masks(
                image_paths,
                generated_mask_dir,
                search_root,
                rect_spec=args.rect,
                corner=args.corner,
                width_frac=width_frac,
                height_frac=height_frac,
                margin_frac=margin_frac,
                expand=args.expand,
            )
            if args.masks_only:
                persist = (output_dir or search_root) / "_masks"
                persist.mkdir(parents=True, exist_ok=True)
                for image_path, mask_path in generated_masks.items():
                    dest = persist / mask_key(image_path, search_root)
                    shutil.copy2(mask_path, dest)
                print(f"Masks saved to {persist}")
                return 0

        mask_file = (project_root / args.mask).resolve() if args.mask else None
        mask_dir = None
        if args.mask_dir:
            mask_dir = (project_root / args.mask_dir).resolve()
        elif generated_mask_dir is not None:
            mask_dir = generated_mask_dir

        if mask_file is not None and not mask_file.is_file():
            print(f"Mask file not found: {mask_file}")
            return 1
        if mask_dir is not None and not mask_dir.is_dir():
            print(f"Mask directory not found: {mask_dir}")
            return 1

        override_config = (project_root / args.config).resolve() if args.config else None
        config_path, config_temp_path = resolve_iopaint_config(
            image_paths,
            device,
            override_path=override_config,
            hd_limit=args.hd_limit,
        )

        if output_dir is None:
            inpaint_ctx = tempfile.TemporaryDirectory(prefix="iopaint_out_")
            inpaint_dir = Path(inpaint_ctx.name)
        else:
            inpaint_dir = output_dir

        for image_path in image_paths:
            mask_path = resolve_mask_path(
                image_path,
                mask_file,
                mask_dir,
                search_root=search_root,
                generated_masks=generated_masks,
            )
            if mask_path is None:
                print(f"  SKIP {image_path.name}: no matching mask")
                continue

            if mask_file is None and args.expand > 0 and generated_mask_dir is None:
                with Image.open(mask_path) as mask_image:
                    dilated = dilate_mask(mask_image.convert("L"), args.expand)
                with tempfile.NamedTemporaryFile(
                    suffix=".png", delete=False, dir=tempfile.gettempdir()
                ) as tmp:
                    dilated.save(tmp.name)
                    mask_path = Path(tmp.name)

            print(f"Processing {image_path.name} ...")
            run_iopaint(
                model=args.model,
                device=device,
                image_path=image_path,
                mask_path=mask_path,
                output_dir=inpaint_dir,
                config=config_path,
            )
            dest = resolve_dest(image_path, search_root, output_dir)
            merge_inpaint_result(
                image_path,
                inpaint_dir / image_path.name,
                mask_path,
                dest,
            )
            print(f"  Saved {dest} (alpha preserved)")

    finally:
        if temp_ctx is not None:
            temp_ctx.cleanup()
        if inpaint_ctx is not None:
            inpaint_ctx.cleanup()
        if config_temp_path is not None:
            config_temp_path.unlink(missing_ok=True)

    print(f"Done. Processed {len(image_paths)} image(s).")
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except KeyboardInterrupt:
        sys.exit(130)
