"""
地图块批处理脚本
================

将 AI 生成的 tile 原图（带棋盘格/白边/黑边等不规则 padding）批量处理为
RGBA 透明正方形地图块。不使用 rembg 语义抠图。

处理原理（三步流水线）
--------------------

    原图 (2048×2048，四周有不规则 AI padding)
        │
        ▼  ① 魔棒式标记 padding（颜色相似度 + 从边界 flood-fill）
    padding 区域（与边界连通）
        │
        ▼  ② 裁切内容包围盒 → padding Alpha=0，tile Alpha=255
    紧凑 RGBA tile
        │
        ▼  ③ NEAREST 缩放回 N×N 正方形
    游戏可用透明 tile

与 process-sprites 的区别
-------------------------
- **不用 rembg**：tile 整块都是内容，语义分割会把砖块/水纹/草地误当背景。
- **魔棒而非 AI 抠图**：按颜色相似度 + 连通性识别 padding，类似 Photoshop 魔棒。
- **裁切 + 透明**：裁切保证尺寸正确；透明化去掉 padding 像素。

依赖
----
    pip install pillow numpy

用法
----
    py .cursor/skills/process-tiles/scripts/process_tiles.py
    py .cursor/skills/process-tiles/scripts/process_tiles.py image/tiles
    py .cursor/skills/process-tiles/scripts/process_tiles.py image/tiles --pattern "ground_*.png"
    py .cursor/skills/process-tiles/scripts/process_tiles.py image/tiles --dry-run
    py .cursor/skills/process-tiles/scripts/process_tiles.py image/tiles --output-dir image/tiles_clean

    默认原地覆盖。运行前建议 git commit 或备份。
"""

from __future__ import annotations

import argparse
import sys
from collections import Counter, deque
from pathlib import Path

import numpy as np
from PIL import Image

DEFAULT_DIR = "image/tiles"
DEFAULT_PATTERN = "*.png"
DEFAULT_SIZE = 0  # 0 = keep original square dimension
DEFAULT_TOLERANCE = 42
MIN_CROP_PX = 4  # skip crop if all sides remove fewer than this many pixels


def find_project_root() -> Path:
    """向上查找含 project.godot 的目录作为项目根。"""
    current = Path(__file__).resolve()
    for parent in current.parents:
        if (parent / "project.godot").exists():
            return parent
    raise RuntimeError("Could not find project root (project.godot)")


def color_dist(c1: tuple[int, int, int], c2: tuple[int, int, int]) -> float:
    return float(np.sqrt(sum((a - b) ** 2 for a, b in zip(c1, c2))))


def learn_checkerboard_colors(
    rgb: np.ndarray,
    margin: int = 48,
    sat_threshold: int = 22,
) -> tuple[tuple[int, int, int], tuple[int, int, int]] | None:
    """从四边采样，学习棋盘格的两色（AI 假透明背景）。"""
    h, w = rgb.shape[:2]
    m = min(margin, h // 4, w // 4)
    if m < 8:
        return None

    samples: list[tuple[int, int, int]] = []
    strips = (
        rgb[:m, :].reshape(-1, 3),
        rgb[-m:, :].reshape(-1, 3),
        rgb[:, :m].reshape(-1, 3),
        rgb[:, -m:].reshape(-1, 3),
    )
    for strip in strips:
        for pixel in strip:
            r, g, b = int(pixel[0]), int(pixel[1]), int(pixel[2])
            if max(r, g, b) - min(r, g, b) <= sat_threshold:
                samples.append((r, g, b))

    if len(samples) < 64:
        return None

    quantized = [((r // 16) * 16, (g // 16) * 16, (b // 16) * 16) for r, g, b in samples]
    ranked = Counter(quantized).most_common(8)
    if len(ranked) < 2:
        return None

    ca = ranked[0][0]
    for entry in ranked[1:]:
        cb = entry[0]
        if color_dist(ca, cb) >= 18:
            return ca, cb
    return None


def build_padding_mask(
    rgb: np.ndarray,
    cb_colors: tuple[tuple[int, int, int], tuple[int, int, int]] | None,
    tolerance: int,
) -> np.ndarray:
    """魔棒候选：padding 色（棋盘格、近白 halo、浅灰过渡边）。不含 tile 黑色描边。"""
    r = rgb[:, :, 0].astype(np.int16)
    g = rgb[:, :, 1].astype(np.int16)
    b = rgb[:, :, 2].astype(np.int16)
    max_c = np.maximum(np.maximum(r, g), b)
    min_c = np.minimum(np.minimum(r, g), b)
    sat = max_c - min_c

    padding = np.zeros(rgb.shape[:2], dtype=bool)

    # 近白 / 浅灰 halo（AI 白边、抗锯齿边）
    padding |= (r > 235) & (g > 235) & (b > 235)

    # 浅色低饱和：棋盘格、浅灰 padding、棕褐过渡边
    padding |= (sat <= 24) & (max_c >= 108)

    # 学习的棋盘格两色（魔棒容差匹配）
    if cb_colors:
        ca, cc = cb_colors
        ca_arr = np.array(ca, dtype=np.int16)
        cc_arr = np.array(cc, dtype=np.int16)
        stack = np.stack([r, g, b], axis=-1)
        dist_a = np.linalg.norm(stack - ca_arr, axis=-1)
        dist_c = np.linalg.norm(stack - cc_arr, axis=-1)
        padding |= (dist_a <= tolerance) | (dist_c <= tolerance)

    return padding


def flood_from_border(mask: np.ndarray) -> np.ndarray:
    """魔棒连通：只保留与图像边界连通的 padding（不侵入 tile 内部）。"""
    h, w = mask.shape
    reachable = np.zeros((h, w), dtype=bool)
    queue: deque[tuple[int, int]] = deque()

    for x in range(w):
        for y in (0, h - 1):
            if mask[y, x]:
                reachable[y, x] = True
                queue.append((y, x))
    for y in range(h):
        for x in (0, w - 1):
            if mask[y, x] and not reachable[y, x]:
                reachable[y, x] = True
                queue.append((y, x))

    while queue:
        y, x = queue.popleft()
        for dy, dx in ((-1, 0), (1, 0), (0, -1), (0, 1)):
            ny, nx = y + dy, x + dx
            if 0 <= ny < h and 0 <= nx < w and mask[ny, nx] and not reachable[ny, nx]:
                reachable[ny, nx] = True
                queue.append((ny, nx))

    return reachable


def content_bbox(content: np.ndarray) -> tuple[int, int, int, int] | None:
    ys, xs = np.where(content)
    if len(xs) == 0:
        return None
    return int(xs.min()), int(ys.min()), int(xs.max()) + 1, int(ys.max()) + 1


def crop_margin(original: tuple[int, int], bbox: tuple[int, int, int, int]) -> tuple[int, int, int, int]:
    ow, oh = original
    left, top, right, bottom = bbox
    return left, top, ow - right, oh - bottom


def resize_square_nearest(image: Image.Image, size: int) -> Image.Image:
    if image.width == size and image.height == size:
        return image
    return image.resize((size, size), Image.Resampling.NEAREST)


def apply_magic_wand(rgba: np.ndarray, padding: np.ndarray) -> np.ndarray:
    """padding 区域 Alpha → 0，tile 本体 Alpha → 255。"""
    rgba[:, :, 3] = np.where(padding, 0, 255).astype(np.uint8)
    return rgba


def process_image(
    image: Image.Image,
    *,
    tolerance: int = DEFAULT_TOLERANCE,
    target_size: int = DEFAULT_SIZE,
) -> tuple[Image.Image, dict]:
    rgb = np.array(image.convert("RGB"))
    ow, oh = image.size

    cb_colors = learn_checkerboard_colors(rgb)
    padding_candidates = build_padding_mask(rgb, cb_colors, tolerance)
    padding = flood_from_border(padding_candidates)
    content = ~padding

    bbox = content_bbox(content)
    if bbox is None:
        raise ValueError("no visible content found")

    left, top, right, bottom = bbox
    margins = crop_margin((ow, oh), bbox)
    cropped_w, cropped_h = right - left, bottom - top

    rgba = np.dstack([rgb, np.full((oh, ow), 255, dtype=np.uint8)])
    rgba = apply_magic_wand(rgba, padding)

    info = {
        "original": (ow, oh),
        "bbox": bbox,
        "margins": margins,
        "cropped": (cropped_w, cropped_h),
        "cb_colors": cb_colors,
        "padding_pct": 100.0 * padding.sum() / (ow * oh),
        "changed": margins != (0, 0, 0, 0),
    }

    if not info["changed"] or all(m < MIN_CROP_PX for m in margins):
        result = Image.fromarray(rgba, "RGBA")
        info["skipped_crop"] = True
    else:
        result = Image.fromarray(rgba[top:bottom, left:right], "RGBA")
        info["skipped_crop"] = False

    out_size = target_size if target_size > 0 else ow
    if result.width != out_size or result.height != out_size:
        result = resize_square_nearest(result, out_size)
        info["output"] = (out_size, out_size)
    else:
        info["output"] = result.size

    return result, info


def collect_images(target_dir: Path, pattern: str) -> list[Path]:
    return sorted(target_dir.glob(pattern))


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Crop AI padding and magic-wand transparency for tile images (no rembg).",
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
        help=f"Glob pattern (default: {DEFAULT_PATTERN})",
    )
    parser.add_argument(
        "--size",
        type=int,
        default=DEFAULT_SIZE,
        help="Output square size (default: same as original width)",
    )
    parser.add_argument(
        "--tolerance",
        type=int,
        default=DEFAULT_TOLERANCE,
        help=f"Magic-wand color tolerance (default: {DEFAULT_TOLERANCE})",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Print crop info without writing files",
    )
    parser.add_argument(
        "--output-dir",
        default="",
        help="Write to this directory instead of overwriting sources",
    )
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv or sys.argv[1:])
    project_root = find_project_root()
    target_dir = project_root / args.directory

    if not target_dir.is_dir():
        print(f"Directory not found: {target_dir}")
        return 1

    output_dir = project_root / args.output_dir if args.output_dir else None
    if output_dir and not args.dry_run:
        output_dir.mkdir(parents=True, exist_ok=True)

    image_paths = collect_images(target_dir, args.pattern)
    if not image_paths:
        print(f"No images found in {target_dir} (pattern: {args.pattern})")
        return 1

    print(f"Target: {target_dir}")
    print(f"Pattern: {args.pattern}, Size: {args.size or 'original'}")
    if args.dry_run:
        print("Mode: dry-run (no files written)")

    changed = 0
    for image_path in image_paths:
        image = Image.open(image_path)
        try:
            result, info = process_image(
                image,
                tolerance=args.tolerance,
                target_size=args.size,
            )
        except ValueError as exc:
            print(f"  SKIP {image_path.name}: {exc}")
            continue

        l, t, r, b = info["margins"]
        crop_status = "unchanged" if info.get("skipped_crop") else "cropped"
        print(
            f"  {image_path.name}: {info['original']} -> {info['output']} "
            f"[{crop_status}] margins LTRB=({l},{t},{r},{b}) padding={info['padding_pct']:.1f}%"
        )

        if not info.get("skipped_crop"):
            changed += 1

        if args.dry_run:
            continue

        dest = (output_dir / image_path.name) if output_dir else image_path
        result.save(dest)

    print(f"Done. {changed}/{len(image_paths)} image(s) cropped.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
