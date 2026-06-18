---
name: process-sprites
description: >-
  Batch-process AI-generated images into square transparent PNG sprites: remove
  checkerboard background, crop transparent margins, resize with contain fit.
  Use when the user asks to cut out sprites, remove backgrounds, resize images
  to 512x512, or batch-process PNG files in image/ directories.
---

# Process Sprites

将指定目录中的 AI 原图批量转为 **正方形 RGBA 透明精灵**（默认 512×512）。

适用于角色、道具、特效等任意前景明确的 PNG，不限于坦克。

## Quick Start

1. 确认依赖已安装（首次运行）：

```bash
py -m pip install pillow rembg onnxruntime
```

2. **运行前备份**：脚本会原地覆盖 PNG。有 git 时先 `git status`，必要时 `git restore` 可恢复。

3. 执行批处理：

```bash
# 默认：image/characters/ 下所有 *.png（排除 *_sheet.png）
py .cursor/skills/process-sprites/scripts/process_sprites.py

# 指定目录
py .cursor/skills/process-sprites/scripts/process_sprites.py image/characters

# 指定匹配模式
py .cursor/skills/process-sprites/scripts/process_sprites.py image/characters --pattern "blue_tank_*.png"

# 指定输出尺寸
py .cursor/skills/process-sprites/scripts/process_sprites.py image/effects --size 256
```

4. 验收：抽查输出尺寸与 RGBA 模式，确认主体边缘（如炮管、装饰）完整。

## 默认行为

| 参数 | 默认值 | 说明 |
|------|--------|------|
| 目录 | `image/characters` | 相对项目根 |
| 匹配 | `*.png` | glob 模式 |
| 尺寸 | `512` | 输出正方形边长 |
| 排除 | `*_sheet.png` | 跳过精灵图集 |

用户指定目录或 `--pattern` 时，以用户参数为准。

## 流水线原理

```
原图 (棋盘格/白色背景)
  → ① rembg 抠图 (u2net 语义分割)
  → ② 裁透明边 (Alpha 包围盒，不裁主体像素)
  → ③ contain 等比缩放 + 居中到 N×N
```

详细实现见 [scripts/process_sprites.py](scripts/process_sprites.py)。

## 缩放模式（重要）

| 模式 | 行为 | 何时使用 |
|------|------|----------|
| **contain**（默认） | 完整保留主体，非正方形时可能留透明边 | 默认；用户未明确要求铺满裁切 |
| **cover** | 铺满四边，会裁掉超出部分 | 仅当用户明确接受裁切 |
| **stretch** | 非等比拉满 N×N | 仅当用户明确接受变形 |

**不要擅自改用 cover**。cover 会切掉主体内容，已确认 contain 更安全。

若用户要改模式，修改 `scripts/process_sprites.py` 中的 `resize_contain_fit`，不要临时手写一次性脚本。

## Agent 执行清单

```
- [ ] 确认目标目录与 --pattern / --size 参数
- [ ] 提醒用户脚本会原地覆盖（或已备份）
- [ ] 检查/安装依赖
- [ ] 运行 process_sprites.py（带用户指定参数）
- [ ] 验证输出尺寸与 RGBA 模式
- [ ] 抽查 1–2 张：主体是否完整、背景是否去除
```

## 故障排查

| 问题 | 处理 |
|------|------|
| `Python was not found` | 用 `py` 而非 `python` |
| rembg 首次很慢 | 正常，需下载 u2net 模型 (~176MB) |
| `no visible content found` | 抠图失败，检查原图或单张手动处理 |
| 用户要恢复原版 | `git restore <目录>/*.png` |

## 相关资源

- 坦克原图生成提示词：`skill/tank/tank-simple.md`、`skill/tank/tank-full.md`
- 常见输出目录：`image/characters/`、`image/effects/`、`image/ui/`
