---
name: resize-images
description: >-
  Batch resize PNG images to a user-specified aspect ratio and pixel dimensions.
  Supports contain, cover, and stretch fit modes. Use when the user asks to
  resize images, set aspect ratio, batch scale sprites, or normalize image
  dimensions in image/ directories.
---

# Resize Images

按用户指定的 **长宽比** 和 **像素尺寸**，批量调整目录中的 PNG 图片大小。

不做抠图、不裁透明边——只负责缩放与画布适配。适用于子弹帧、UI 图、已抠好的精灵等。

## Quick Start

1. 确认依赖（仅 Pillow，**不需要 rembg**）：

```bash
py -m pip install pillow
```

2. **运行前备份**：默认原地覆盖 PNG。有 git 时先 `git status`，必要时 `git restore` 可恢复。

3. 先 dry-run 确认参数：

```bash
py .cursor/skills/resize-images/scripts/resize_images.py image/bullets --aspect 2:1 --width 128 --recursive --dry-run
```

4. 确认无误后执行：

```bash
# 长宽比 2:1，宽 128 → 输出 128×64
py .cursor/skills/resize-images/scripts/resize_images.py image/bullets --aspect 2:1 --width 128

# 长宽比 16:9，长边 512 → 输出 512×288
py .cursor/skills/resize-images/scripts/resize_images.py image/effects --aspect 16:9 --long-edge 512

# 长宽比 1:2，短边 64 → 输出 32×64
py .cursor/skills/resize-images/scripts/resize_images.py image/bullets/basic/red --aspect 1:2 --short-edge 64

# 直接指定宽高（须与长宽比一致，或不传 --aspect）
py .cursor/skills/resize-images/scripts/resize_images.py image/ui --width 256 --height 256

# 递归处理子目录 + 输出到新目录（不覆盖原图）
py .cursor/skills/resize-images/scripts/resize_images.py image/bullets --aspect 1:1 --width 512 --recursive --output-dir image/bullets_resized
```

5. 验收：抽查输出尺寸、RGBA 模式，确认主体未被意外裁切（contain 模式）或变形（stretch 模式）。

## 尺寸参数（必选一组合）

用户提供 **长宽比** 后，还需指定一个尺寸约束来计算最终像素：

| 参数 | 说明 | 示例 |
|------|------|------|
| `--aspect` / `-a` | 长宽比，支持 `16:9`、`2:1`、`1:1` | `--aspect 2:1` |
| `--width` / `-W` | 输出宽度，高度按比例推算 | `--aspect 16:9 --width 640` → 640×360 |
| `--height` / `-H` | 输出高度，宽度按比例推算 | `--aspect 2:1 --height 64` → 128×64 |
| `--long-edge` | 长边像素（需配合 `--aspect`） | `--aspect 16:9 --long-edge 512` → 512×288 |
| `--short-edge` | 短边像素（需配合 `--aspect`） | `--aspect 1:2 --short-edge 64` → 32×64 |
| `--width` + `--height` | 同时指定；若传了 `--aspect` 会校验是否匹配 | `--width 128 --height 64 --aspect 2:1` |

**Agent 执行时**：从用户消息中提取长宽比和尺寸，填入命令行参数，不要硬编码默认值。

## 默认行为

| 参数 | 默认值 | 说明 |
|------|--------|------|
| 目录 | `image` | 相对项目根 |
| 匹配 | `*.png` | glob 模式 |
| 适配 | `contain` | 等比缩放 + 透明边居中 |
| 排除 | `*_sheet.png` | 跳过精灵图集 |
| 递归 | 否 | `--recursive` 处理子目录 |

用户指定目录、`--pattern`、`--aspect`、尺寸参数时，以用户参数为准。

## 适配模式

| 模式 | 行为 | 何时使用 |
|------|------|----------|
| **contain**（默认） | 完整保留主体，非目标比例时留透明边 | 默认；用户未明确要求铺满裁切 |
| **cover** | 铺满画布，会裁掉超出部分 | 仅当用户明确接受裁切 |
| **stretch** | 非等比拉满目标尺寸 | 仅当用户明确接受变形 |

**不要擅自改用 cover**。cover 会切掉主体内容，已确认 contain 更安全。

若用户要改模式，使用 `--fit cover` 或 `--fit stretch`，不要临时手写一次性脚本。

## 流水线原理

```
原图 (任意尺寸 RGB/RGBA)
  → ① 解析长宽比 + 计算目标像素 (W×H)
  → ② 按 fit 模式缩放/裁剪/拉伸
  → ③ 输出 W×H RGBA PNG
```

详细实现见 [scripts/resize_images.py](scripts/resize_images.py)。

## Agent 执行清单

```
- [ ] 从用户消息确认：目标目录、长宽比、尺寸（宽/高/长边/短边）
- [ ] 确认 --pattern / --recursive / --fit / --output-dir
- [ ] 提醒用户脚本默认原地覆盖（或已 --output-dir / 备份）
- [ ] 先 --dry-run 确认输出尺寸与文件数量
- [ ] 运行 resize_images.py（带用户指定参数）
- [ ] 验证输出尺寸与 RGBA 模式
- [ ] 抽查 1–2 张：主体是否完整、比例是否正确
```

## 故障排查

| 问题 | 处理 |
|------|------|
| `Python was not found` | 用 `py` 而非 `python` |
| `Invalid aspect ratio` | 检查格式，应为 `16:9` 或 `2:1` 等 |
| `do not match aspect` | `--width` 与 `--height` 和 `--aspect` 不一致，修正其一 |
| `Specify output size` | 传了 `--aspect` 但未给 `--width`/`--height`/`--long-edge`/`--short-edge` |
| 子目录图片未处理 | 加 `--recursive` |
| 用户要恢复原版 | `git restore <目录>/**/*.png` |

## 与 process-sprites 的区别

| | process-sprites | resize-images |
|--|-----------------|---------------|
| 用途 | AI 原图抠图 + 正方形精灵 | 已就绪图片按长宽比批量缩放 |
| 抠图 | rembg 语义分割 | 无 |
| 长宽比 | 固定 1:1 | 用户指定任意比例 |
| 依赖 | pillow + rembg + onnxruntime | 仅 pillow |
| 典型目录 | `image/characters/` | `image/bullets/`、`image/ui/` 等 |

## 相关资源

- 精灵抠图（AI 原图 → 透明正方形）：`.cursor/skills/process-sprites/SKILL.md`
- 地图块处理：`.cursor/skills/process-tiles/SKILL.md`
