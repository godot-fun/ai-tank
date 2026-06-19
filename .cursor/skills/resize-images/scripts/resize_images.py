"""
图片批处理：按指定长宽比调整尺寸
================================

将目录中的 PNG 批量缩放到目标长宽比画布上，支持 contain / cover / stretch 三种适配模式。

依赖
----
    pip install pillow numpy

用法
----
    py .cursor/skills/resize-images/scripts/resize_images.py image/bullets --aspect 2:1 --width 128
    py .cursor/skills/resize-images/scripts/resize_images.py image/bullets --aspect 16:9 --long-edge 512
    py .cursor/skills/resize-images/scripts/resize_images.py image/bullets --width 64 --height 128
    py .cursor/skills/resize-images/scripts/resize_images.py image/bullets --aspect 1:1 --width 512 --fit cover
    py .cursor/skills/resize-images/scripts/resize_images.py image/bullets --aspect 1:1 --width 512 --output-dir image/bullets_resized
    py .cursor/skills/resize-images/scripts/resize_images.py image/bullets --aspect 1:1 --width 512 --recursive --dry-run

默认原地覆盖保存。运行前建议 git commit 或备份原图。
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

from PIL import Image

DEFAULT_DIR = "image"
DEFAULT_PATTERN = "*.png"
DEFAULT_FIT = "contain"
DEFAULT_EXCLUDES: tuple[str, ...] = ("*_sheet.png",)


def find_project_root() -> Path:
    """向上查找含 project.godot 的目录作为项目根。"""
    current = Path(__file__).resolve()
    for parent in current.parents:
        if (parent / "project.godot").exists():
            return parent
    raise RuntimeError("Could not find project root (project.godot)")


def parse_aspect_ratio(value: str) -> tuple[int, int]:
    """解析长宽比，支持 16:9、16/9、16x9。"""
    normalized = value.strip().lower().replace("x", ":").replace("/", ":")
    match = re.fullmatch(r"(\d+(?:\.\d+)?)\s*:\s*(\d+(?:\.\d+)?)", normalized)
    if not match:
        raise ValueError(f"Invalid aspect ratio: {value!r} (expected e.g. 16:9, 2:1, 1:1)")

    width_ratio = float(match.group(1))
    height_ratio = float(match.group(2))
    if width_ratio <= 0 or height_ratio <= 0:
        raise ValueError(f"Aspect ratio values must be positive: {value!r}")

    scale = 1000
    return int(round(width_ratio * scale)), int(round(height_ratio * scale))


def compute_target_size(
    aspect: tuple[int, int] | None,
    width: int | None,
    height: int | None,
    long_edge: int | None,
    short_edge: int | None,
) -> tuple[int, int]:
    """根据长宽比与尺寸参数计算输出宽高。"""
    if width is not None and height is not None:
        if aspect is not None:
            aw, ah = aspect
            if width * ah != height * aw:
                raise ValueError(
                    f"Width {width} and height {height} do not match aspect "
                    f"{aw}:{ah} (expected height {width * ah // aw})"
                )
        return width, height

    if aspect is None:
        raise ValueError("Provide --aspect with one size flag, or both --width and --height")

    aw, ah = aspect
    if width is not None:
        return width, int(round(width * ah / aw))
    if height is not None:
        return int(round(height * aw / ah)), height
    if long_edge is not None:
        if aw >= ah:
            return long_edge, int(round(long_edge * ah / aw))
        return int(round(long_edge * aw / ah)), long_edge
    if short_edge is not None:
        if aw >= ah:
            return int(round(short_edge * aw / ah)), short_edge
        return short_edge, int(round(short_edge * ah / aw))

    raise ValueError(
        "Specify output size with one of: --width, --height, --long-edge, --short-edge "
        "(or both --width and --height)"
    )


def resize_contain(image: Image.Image, target_w: int, target_h: int) -> Image.Image:
    """等比缩放至目标画布内完整显示，透明边填充。"""
    width, height = image.size
    scale = min(target_w / width, target_h / height)
    resized = image.resize(
        (max(1, int(round(width * scale))), max(1, int(round(height * scale)))),
        Image.Resampling.LANCZOS,
    )
    canvas = Image.new("RGBA", (target_w, target_h), (0, 0, 0, 0))
    left = (target_w - resized.width) // 2
    top = (target_h - resized.height) // 2
    canvas.paste(resized, (left, top), resized if resized.mode == "RGBA" else None)
    return canvas


def resize_cover(image: Image.Image, target_w: int, target_h: int) -> Image.Image:
    """等比放大后居中裁剪，铺满目标画布。"""
    width, height = image.size
    scale = max(target_w / width, target_h / height)
    resized = image.resize(
        (max(1, int(round(width * scale))), max(1, int(round(height * scale)))),
        Image.Resampling.LANCZOS,
    )
    left = (resized.width - target_w) // 2
    top = (resized.height - target_h) // 2
    cropped = resized.crop((left, top, left + target_w, top + target_h))
    return cropped.convert("RGBA")


def resize_stretch(image: Image.Image, target_w: int, target_h: int) -> Image.Image:
    """非等比拉伸至目标尺寸。"""
    return image.resize((target_w, target_h), Image.Resampling.LANCZOS).convert("RGBA")


def resize_image(
    image: Image.Image,
    target_w: int,
    target_h: int,
    fit: str,
) -> Image.Image:
    """按指定适配模式调整单张图片。"""
    rgba = image.convert("RGBA")
    if fit == "contain":
        return resize_contain(rgba, target_w, target_h)
    if fit == "cover":
        return resize_cover(rgba, target_w, target_h)
    if fit == "stretch":
        return resize_stretch(rgba, target_w, target_h)
    raise ValueError(f"Unknown fit mode: {fit!r}")


def collect_images(
    target_dir: Path,
    pattern: str,
    excludes: tuple[str, ...],
    recursive: bool,
) -> list[Path]:
    """收集待处理图片，排除匹配 exclude 模式的文件。"""
    excluded: set[Path] = set()
    for exclude in excludes:
        excluded.update(target_dir.rglob(exclude) if recursive else target_dir.glob(exclude))

    globber = target_dir.rglob if recursive else target_dir.glob
    images = sorted(path for path in globber(pattern) if path.is_file() and path not in excluded)
    return images


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Batch resize images to a target aspect ratio and pixel size.",
    )
    parser.add_argument(
        "directory",
        nargs="?",
        default=DEFAULT_DIR,
        help=f"Target directory relative to project root (default: {DEFAULT_DIR})",
    )
    parser.add_argument(
        "--pattern",
        default=DEFAULT_PATTERN,
        help=f"Glob pattern for input files (default: {DEFAULT_PATTERN})",
    )
    parser.add_argument(
        "--aspect",
        "-a",
        help="Target aspect ratio, e.g. 16:9, 2:1, 1:1",
    )
    parser.add_argument(
        "--width",
        "-W",
        type=int,
        help="Output width in pixels",
    )
    parser.add_argument(
        "--height",
        "-H",
        type=int,
        help="Output height in pixels",
    )
    parser.add_argument(
        "--long-edge",
        type=int,
        help="Set the longer canvas edge (requires --aspect)",
    )
    parser.add_argument(
        "--short-edge",
        type=int,
        help="Set the shorter canvas edge (requires --aspect)",
    )
    parser.add_argument(
        "--fit",
        choices=("contain", "cover", "stretch"),
        default=DEFAULT_FIT,
        help=f"How to fit source into target canvas (default: {DEFAULT_FIT})",
    )
    parser.add_argument(
        "--output-dir",
        help="Write results here instead of overwriting source files",
    )
    parser.add_argument(
        "--recursive",
        "-r",
        action="store_true",
        help="Search subdirectories for matching files",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Print planned operations without writing files",
    )
    parser.add_argument(
        "--exclude",
        action="append",
        default=[],
        help="Additional glob patterns to skip (can be repeated)",
    )
    return parser.parse_args(argv)


def resolve_output_path(
    image_path: Path,
    target_dir: Path,
    output_dir: Path | None,
) -> Path:
    """计算输出路径；--output-dir 时保留相对目录结构。"""
    if output_dir is None:
        return image_path
    relative = image_path.relative_to(target_dir)
    return output_dir / relative


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv or sys.argv[1:])
    project_root = find_project_root()
    target_dir = project_root / args.directory

    if not target_dir.is_dir():
        print(f"Directory not found: {target_dir}")
        return 1

    try:
        aspect = parse_aspect_ratio(args.aspect) if args.aspect else None
        target_w, target_h = compute_target_size(
            aspect,
            args.width,
            args.height,
            args.long_edge,
            args.short_edge,
        )
    except ValueError as exc:
        print(f"Error: {exc}")
        return 1

    output_dir: Path | None = None
    if args.output_dir:
        output_dir = project_root / args.output_dir
        if not args.dry_run:
            output_dir.mkdir(parents=True, exist_ok=True)

    excludes = tuple(DEFAULT_EXCLUDES) + tuple(args.exclude)
    image_paths = collect_images(target_dir, args.pattern, excludes, args.recursive)

    if not image_paths:
        print(f"No images found in {target_dir} (pattern: {args.pattern})")
        return 1

    aspect_text = f"{args.aspect} " if args.aspect else ""
    print(f"Target: {target_dir}")
    print(f"Pattern: {args.pattern}, Output: {target_w}x{target_h} ({aspect_text}fit={args.fit})")
    if args.recursive:
        print("Recursive: yes")
    if output_dir:
        print(f"Output dir: {output_dir}")
    if excludes:
        print(f"Excludes: {', '.join(excludes)}")
    if args.dry_run:
        print("Dry run: no files will be written")

    for image_path in image_paths:
        output_path = resolve_output_path(image_path, target_dir, output_dir)
        with Image.open(image_path) as source:
            source_size = source.size
            result = resize_image(source, target_w, target_h, args.fit)

        action = "Would save" if args.dry_run else "Saved"
        print(
            f"Processing {image_path.relative_to(project_root)} "
            f"({source_size[0]}x{source_size[1]} -> {target_w}x{target_h})"
        )
        if not args.dry_run:
            output_path.parent.mkdir(parents=True, exist_ok=True)
            result.save(output_path)
        print(f"  {action} {output_path.relative_to(project_root)}")

    print(f"Done. Processed {len(image_paths)} image(s).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
