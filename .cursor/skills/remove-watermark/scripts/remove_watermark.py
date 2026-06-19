"""
水印批处理：LaMa / IOPaint 深度学习 inpainting
==============================================

根据 mask 语义级重绘水印区域。Mask 约定：白色 (255) = 待修复，黑色 (0) = 保留。

依赖
----
    pip install iopaint pillow numpy
    # GPU 推荐先装 CUDA 版 torch，见 SKILL.md

用法
----
    py .cursor/skills/remove-watermark/scripts/remove_watermark.py image/foo \\
        --corner bottom-right --width 0.28 --height 0.10 --margin 0.02

    py .cursor/skills/remove-watermark/scripts/remove_watermark.py image/foo \\
        --rect 820,900,180,80

    py .cursor/skills/remove-watermark/scripts/remove_watermark.py image/foo \\
        --mask-dir image/foo/_masks

默认输出到 <目录>_clean/。--in-place 覆盖原图。运行前建议 git commit 或备份。
"""

from __future__ import annotations

import argparse
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

CORNER_CHOICES = ("bottom-right", "bottom-left", "top-right", "top-left", "center")


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
    images = sorted(path for path in globber(pattern) if path not in excluded and path.is_file())
    return images


def parse_fraction(value: str, name: str) -> float:
    text = value.strip()
    if text.endswith("%"):
        number = float(text[:-1]) / 100.0
    else:
        number = float(text)
        if number > 1.0:
            raise ValueError(f"{name} must be a fraction (0-1) or percentage, got {value!r}")
    if not 0.0 < number <= 1.0:
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
) -> Path | None:
    if mask_file is not None:
        return mask_file
    if mask_dir is None:
        return None
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
    *,
    rect_spec: str | None,
    corner: str | None,
    width_frac: float | None,
    height_frac: float | None,
    margin_frac: float,
    expand: int,
) -> list[Path]:
    mask_dir.mkdir(parents=True, exist_ok=True)
    mask_paths: list[Path] = []

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
        out_path = mask_dir / image_path.name
        mask.save(out_path)
        mask_paths.append(out_path)

    return mask_paths


def iopaint_cmd_prefix() -> list[str]:
    if shutil.which("iopaint"):
        return ["iopaint"]
    return [sys.executable, "-m", "iopaint"]


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


def run_iopaint_batch(
    *,
    model: str,
    device: str,
    image_dir: Path,
    mask_path: Path,
    output_dir: Path,
    config: Path | None,
) -> None:
    """Batch-run IOPaint on a folder of images."""
    output_dir.mkdir(parents=True, exist_ok=True)
    cmd = [
        *iopaint_cmd_prefix(),
        "run",
        "--model",
        model,
        "--device",
        device,
        "--image",
        str(image_dir),
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
        raise RuntimeError(f"iopaint batch failed: {message}")


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


def finalize_outputs(
    image_paths: list[Path],
    *,
    inpaint_dir: Path,
    mask_dir: Path | None,
    mask_file: Path | None,
    output_dir: Path,
    in_place: bool,
) -> int:
    saved = 0
    for image_path in image_paths:
        inpainted = inpaint_dir / image_path.name
        if not inpainted.is_file():
            print(f"  SKIP {image_path.name}: no inpaint output")
            continue

        mask_path = resolve_mask_path(image_path, mask_file, mask_dir)
        if mask_path is None:
            print(f"  SKIP {image_path.name}: no mask for alpha merge")
            continue

        original_path = image_path
        dest = image_path if in_place else output_dir / image_path.name
        merge_inpaint_result(original_path, inpainted, mask_path, dest)
        print(f"  Saved {dest} (alpha preserved)")
        saved += 1
    return saved


def default_output_dir(target_dir: Path, in_place: bool) -> Path:
    if in_place:
        return target_dir
    return target_dir.parent / f"{target_dir.name}_clean"


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Remove watermarks with LaMa/IOPaint inpainting.",
    )
    parser.add_argument(
        "directory",
        nargs="?",
        default=DEFAULT_DIR,
        help=f"Target directory relative to project root (default: {DEFAULT_DIR})",
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
    parser.add_argument("--config", type=Path, help="IOPaint config JSON path")
    parser.add_argument("--output-dir", type=Path, help="Output directory (default: <dir>_clean)")
    parser.add_argument("--in-place", action="store_true", help="Overwrite original images")
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
    target_dir = project_root / args.directory
    if not target_dir.is_dir():
        print(f"Directory not found: {target_dir}")
        return 1

    excludes = tuple(DEFAULT_EXCLUDES) + tuple(args.exclude)
    image_paths = collect_images(target_dir, args.pattern, excludes, args.recursive)
    if not image_paths:
        print(f"No images found in {target_dir} (pattern: {args.pattern})")
        return 1

    width_frac = parse_fraction(args.width, "--width") if args.width else None
    height_frac = parse_fraction(args.height, "--height") if args.height else None
    margin_frac = parse_fraction(args.margin, "--margin")

    device = detect_device(args.device)
    output_dir = (
        (project_root / args.output_dir).resolve()
        if args.output_dir
        else default_output_dir(target_dir, args.in_place)
    )
    if not args.in_place:
        output_dir.mkdir(parents=True, exist_ok=True)

    print(f"Target: {target_dir}")
    print(f"Images: {len(image_paths)}, Model: {args.model}, Device: {device}")
    print(f"Output: {output_dir}")

    generated_mask_dir: Path | None = None
    temp_ctx = None
    inpaint_ctx = None

    try:
        if args.rect or args.corner:
            temp_ctx = tempfile.TemporaryDirectory(prefix="iopaint_masks_")
            generated_mask_dir = Path(temp_ctx.name)
            print(f"Generating masks in {generated_mask_dir} ...")
            generate_masks(
                image_paths,
                generated_mask_dir,
                rect_spec=args.rect,
                corner=args.corner,
                width_frac=width_frac,
                height_frac=height_frac,
                margin_frac=margin_frac,
                expand=args.expand,
            )
            if args.masks_only:
                persist = output_dir / "_masks"
                persist.mkdir(parents=True, exist_ok=True)
                for mask_path in generated_mask_dir.glob("*"):
                    shutil.copy2(mask_path, persist / mask_path.name)
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

        config_path = (project_root / args.config).resolve() if args.config else None

        if args.in_place:
            inpaint_ctx = tempfile.TemporaryDirectory(prefix="iopaint_out_")
            inpaint_dir = Path(inpaint_ctx.name)
        else:
            inpaint_dir = output_dir

        if mask_dir is not None and len(image_paths) > 1 and mask_file is None:
            print("Running batch inpaint ...")
            run_iopaint_batch(
                model=args.model,
                device=device,
                image_dir=target_dir,
                mask_path=mask_dir,
                output_dir=inpaint_dir,
                config=config_path,
            )
            print("Merging inpaint results with original alpha ...")
            saved = finalize_outputs(
                image_paths,
                inpaint_dir=inpaint_dir,
                mask_dir=mask_dir,
                mask_file=mask_file,
                output_dir=output_dir,
                in_place=args.in_place,
            )
            print(f"Done. Processed {saved} image(s).")
            return 0 if saved else 1

        for image_path in image_paths:
            mask_path = resolve_mask_path(image_path, mask_file, mask_dir)
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
            dest = image_path if args.in_place else output_dir / image_path.name
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

    print(f"Done. Processed {len(image_paths)} image(s).")
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except KeyboardInterrupt:
        sys.exit(130)
