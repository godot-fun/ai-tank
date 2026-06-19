---
name: process-tiles
description: >-
  Batch-process AI-generated tile map images: crop edge padding, then magic-wand
  style color+connectivity transparency (not rembg). Use for terrain tiles in
  image/tiles, map blocks, or when rembg fails because the tile texture is the
  content. Use when the user asks to remove checkerboard edges, make padding
  transparent, or magic-wand cutout on tiles.
---

# Process Tiles

将 AI 生成的 **地图块 tile** 批量处理为游戏可用的 **RGBA 透明正方形贴图**。

适用于草地、水面、砖墙、森林等地形块。整块 tile 都是内容，**不要用 rembg**。

## 目标

1. **裁切尺寸正确**：去掉 AI 在边缘画上去的棋盘格 / 白边 / 浅灰 halo，得到紧凑的 tile 包围盒，再缩回原尺寸。
2. **边缘无关区域变透明**：裁切之外、或与 tile 本体不连通的 padding 区域，最终 Alpha = 0。

两步本质都是抠图，但方法和 rembg 不同——更接近 **Photoshop 魔棒工具（Magic Wand）**。

## Quick Start

1. 安装依赖（仅 Pillow + numpy，**不需要 rembg**）：

```bash
py -m pip install pillow numpy
```

2. **运行前备份**：脚本会原地覆盖 PNG。

3. 先 dry-run 看裁切量：

```bash
py .cursor/skills/process-tiles/scripts/process_tiles.py image/tiles --dry-run
```

4. 确认无误后执行：

```bash
py .cursor/skills/process-tiles/scripts/process_tiles.py image/tiles
py .cursor/skills/process-tiles/scripts/process_tiles.py image/tiles --pattern "ground_*.png"
py .cursor/skills/process-tiles/scripts/process_tiles.py image/tiles --output-dir image/tiles_clean
py .cursor/skills/process-tiles/scripts/process_tiles.py image/tiles --size 512
```

5. 验收：输出为 RGBA；tile 纹理完整；边缘无棋盘格；padding 区域透明。

## 默认行为

| 参数 | 默认值 | 说明 |
|------|--------|------|
| 目录 | `image/tiles` | 相对项目根 |
| 匹配 | `*.png` | glob 模式 |
| 尺寸 | 原图宽度 | `--size 512` 可改 |
| 容差 | `42` | 魔棒/棋盘格颜色匹配 `--tolerance` |

## 流水线原理

```
原图 (tile + AI 棋盘格/白边/过渡色 padding)
  │
  ▼  ① 边缘 padding 裁切（flood-fill from border）
  紧凑 tile，尺寸正确（已验证）
  │
  ▼  ② 魔棒式透明化（color similarity + connectivity）
  padding 区域 Alpha → 0，tile 本体保留
  │
  ▼  ③ NEAREST 缩放回 N×N 正方形 RGBA
  游戏可用透明 tile
```

### ① 边缘 padding 裁切

- 从四边采样，学习棋盘格两色（AI 假透明背景）。
- 标记 padding：棋盘格色 + 近白/浅灰低饱和边 + 棕褐过渡边。
- **只从图像边界 flood-fill**，只删与边界连通的 padding，不侵入 tile 内部。
- 取内容包围盒裁切，NEAREST 缩回原尺寸。

裁切量已验证正确（如 `ground_*` 四边约 60–122px，`brick_wall_2` 居中小 tile 约 573px 外框）。

### ② 魔棒式透明化（Magic Wand）

类似 Photoshop 魔棒，**不是** rembg 语义分割：

| | rembg | 魔棒式（本 skill） |
|--|-------|-------------------|
| 原理 | 深度学习语义分割「前景 vs 背景」 | 颜色相似度 + 连通区域 |
| 对 tile | 会把砖缝、水纹、草叶当背景误删 | 只选与 border 连通的 padding 色 |
| 适用 | 角色、道具等前景明确物体 | AI 棋盘格/白边等可预测 padding |

魔棒逻辑：

1. **种子**：图像四边（或四角）像素，或已学习的棋盘格两色。
2. **容差（Tolerance）**：与种子颜色距离 ≤ `--tolerance` 的像素视为「同类 padding」。
3. **连通性**：只 flood-fill 与边界连通的区域（与裁切步骤同一原则）。
4. **输出**：匹配区域 Alpha = 0；tile 本体像素 Alpha = 255。
5. **不把纯黑当 padding**：像素风 tile 常用黑色描边；纯黑若参与魔棒，会沿描边侵入本体。

### 为什么不用 rembg？

Tile 的「背景」就是地形纹理本身。rembg 做对象级分割，会把纹理内部误判为背景。魔棒只删 **颜色可预测、且与边缘连通** 的 AI padding。

## 与 process-sprites 的区别

| | process-sprites | process-tiles |
|--|-----------------|---------------|
| 用途 | 角色、道具、特效 | 地图块、地形 tile |
| 抠图方式 | rembg 语义分割 | 魔棒（颜色 + 连通性） |
| 前置步骤 | 无 | 边缘 padding 裁切（尺寸校正） |
| 输出 | RGBA 透明精灵 | RGBA 透明正方形 tile |
| 目录 | `image/characters/` 等 | `image/tiles/` |

## Agent 执行清单

```
- [ ] 确认目标目录与 --pattern / --size / --tolerance
- [ ] 先 --dry-run，检查 margins 是否合理
- [ ] 提醒用户脚本会原地覆盖（或已 --output-dir）
- [ ] 运行 process_tiles.py
- [ ] 验证输出为 RGBA、尺寸正确
- [ ] 抽查 1–2 张：tile 纹理完整、padding 透明、无棋盘格残留
- [ ] 若个别 tile 未变化（如全幅水纹），属正常，勿强行 rembg
```

## 故障排查

| 问题 | 处理 |
|------|------|
| `unchanged` 但原图明显有棋盘格 | 提高 `--tolerance 50`；或 padding 未与边界连通 |
| 裁太多 / 切到 tile | 降低 `--tolerance 35`；用 `--output-dir` 对比原图 |
| 魔棒侵入 tile 内部 | 降低容差；检查是否误含纯黑/深色描边 |
| 128×128 小图 unchanged | 可能已处理过或本身无 padding |
| 全幅水 tile 不变 | 正常：水纹贴满画布，无 padding |
| 恢复原版 | `git restore image/tiles/*.png` |

## 相关资源

- 精灵抠图（角色/道具，rembg）：`.cursor/skills/process-sprites/SKILL.md`
- 脚本实现： [scripts/process_tiles.py](scripts/process_tiles.py)
- 常见目录：`image/tiles/`
