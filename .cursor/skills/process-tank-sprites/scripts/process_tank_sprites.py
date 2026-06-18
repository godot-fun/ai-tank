"""
坦克精灵图批处理脚本
==================

将 AI 生成的坦克原图（带棋盘格/白色背景）批量处理为游戏可用的 512×512 透明 PNG 精灵。

处理原理（三步流水线）
--------------------

    原图 (如 1024×1024，不透明棋盘格背景)
        │
        ▼  ① AI 抠图 (rembg / u2net)
    透明背景抠图 (RGBA，坦克主体保留，背景变透明)
        │
        ▼  ② 裁切透明边 (crop_to_content)
    紧凑包围盒 (去掉四周透明空白，不裁坦克像素)
        │
        ▼  ③ 等比缩放 + 居中 (resize_contain_fit, contain 模式)
    512×512 输出 (坦克完整保留，透明画布居中)

① AI 抠图
    AI 原图通常把棋盘格直接画进像素里（并非真透明），无法用简单取色分离。
    rembg 使用 u2net 深度学习模型做语义分割，识别前景（坦克）与背景，
    输出带 Alpha 通道的 RGBA 图，背景像素 Alpha 为 0。

② 裁切透明边
    抠图结果往往仍有大块透明留白（坦克只占画面一部分）。
    扫描 Alpha 通道，找到所有不透明像素的轴对齐包围盒 (AABB)，
    裁到该矩形。只去掉透明区域，不会切到坦克本体。

③ 等比缩放 + 居中（contain 模式）
    将包围盒缩放到能完整放进 512×512 的最大尺寸：

        scale = min(512 / width, 512 / height)

    然后居中贴到 512×512 透明画布上。

    为什么用 contain 而不是 cover？
    - cover（放大后居中裁剪）能让坦克铺满四边，但会切掉炮管、车尾等超出部分。
    - contain 保证坦克完整可见，代价是竖长形坦克左右可能留少量透明边。

    缩放使用 LANCZOS 重采样，适合像素风素材放大/缩小时保持边缘清晰。

依赖
----
    pip install pillow rembg onnxruntime

用法
----
    py .cursor/skills/process-tank-sprites/scripts/process_tank_sprites.py

    默认处理 image/characters/ 下匹配 tank_*.png 与 self.png 的文件，
    并原地覆盖保存。运行前建议先 git commit 或备份原图。
"""

from __future__ import annotations

import sys
from io import BytesIO
from pathlib import Path

import numpy as np
from PIL import Image
from rembg import remove

# 输出画布边长（像素）
TARGET_SIZE = 512

# Alpha 阈值：高于此值视为不透明像素，用于计算内容包围盒。
# 略大于 0 可忽略抠图边缘的抗锯齿半透明像素，避免包围盒被噪点撑大。
ALPHA_THRESHOLD = 10


def find_project_root() -> Path:
    """向上查找含 project.godot 的目录作为项目根。"""
    current = Path(__file__).resolve()
    for parent in current.parents:
        if (parent / "project.godot").exists():
            return parent
    raise RuntimeError("Could not find project root (project.godot)")


def crop_to_content(image: Image.Image) -> Image.Image:
    """裁掉透明边，返回紧凑包围盒内的图像。

    原理：把 RGBA 转 numpy 数组，用 Alpha 通道生成布尔掩码，
    取所有 True 像素的 min/max 行列坐标即为内容边界。
    """
    rgba = np.array(image.convert("RGBA"))
    mask = rgba[:, :, 3] > ALPHA_THRESHOLD
    ys, xs = np.where(mask)
    if len(xs) == 0:
        raise ValueError("no visible tank content found")
    return image.crop((int(xs.min()), int(ys.min()), int(xs.max()) + 1, int(ys.max()) + 1))


def resize_contain_fit(image: Image.Image, size: int = TARGET_SIZE) -> Image.Image:
    """等比缩放至 size×size 画布内完整显示（contain 模式）。

    原理：
    1. 用较短边计算缩放比，保证缩放后宽、高均 ≤ size；
    2. LANCZOS 重采样得到缩放图；
    3. 创建 size×size 全透明画布，将缩放图居中粘贴。
    """
    width, height = image.size
    scale = min(size / width, size / height)
    resized = image.resize(
        (int(round(width * scale)), int(round(height * scale))),
        Image.Resampling.LANCZOS,
    )
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    left = (size - resized.width) // 2
    top = (size - resized.height) // 2
    canvas.paste(resized, (left, top), resized)
    return canvas


def remove_background(image_path: Path) -> Image.Image:
    """调用 rembg 去除背景，返回 RGBA 抠图结果。"""
    with image_path.open("rb") as file:
        output = remove(file.read())
    return Image.open(BytesIO(output)).convert("RGBA")


def process_image(image_path: Path) -> Image.Image:
    """对单张图片执行完整流水线：抠图 → 裁透明边 → 缩放居中。"""
    cutout = remove_background(image_path)
    cropped = crop_to_content(cutout)
    return resize_contain_fit(cropped)


def main() -> int:
    characters_dir = find_project_root() / "image" / "characters"
    patterns = ("tank_*.png", "blue_tank_*.png", "red_tank_*.png", "self.png")
    image_paths: list[Path] = []
    for pattern in patterns:
        image_paths.extend(sorted(characters_dir.glob(pattern)))

    if not image_paths:
        print("No tank images found.")
        return 1

    for image_path in image_paths:
        print(f"Processing {image_path.name}...")
        result = process_image(image_path)
        result.save(image_path)
        print(f"  Saved {image_path}")

    print(f"Done. Processed {len(image_paths)} image(s).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
