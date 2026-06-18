---
name: process-tank-sprites
description: >-
  Batch-process AI-generated tank images into 512x512 transparent PNG sprites:
  remove checkerboard background, crop transparent margins, resize with contain
  fit. Use when the user asks to cut out tanks, remove backgrounds, resize
  character sprites to 512x512, or process files in image/characters/.
---

# Process Tank Sprites

将 `image/characters/` 中的 AI 坦克原图批量转为 **512×512 RGBA 透明精灵**。

## Quick Start

1. 确认依赖已安装（首次运行）：

```bash
py -m pip install pillow rembg onnxruntime
```

2. **运行前备份**：脚本会原地覆盖 PNG。有 git 时先 `git status`，必要时 `git restore` 可恢复。

3. 执行批处理：

```bash
py .cursor/skills/process-tank-sprites/scripts/process_tank_sprites.py
```

4. 验收：抽查输出是否为 512×512 RGBA，炮管、车尾是否完整。

## 处理范围

默认匹配 `image/characters/` 下：

- `tank_*.png`
- `blue_tank_*.png`
- `red_tank_*.png`
- `self.png`

跳过精灵图集（如 `player_tank_sheet.png`），除非用户明确要求。

## 流水线原理

```
原图 (棋盘格/白色背景)
  → ① rembg 抠图 (u2net 语义分割)
  → ② 裁透明边 (Alpha 包围盒，不裁坦克像素)
  → ③ contain 等比缩放 + 居中到 512×512
```

详细实现见 [scripts/process_tank_sprites.py](scripts/process_tank_sprites.py)。

## 缩放模式（重要）

| 模式 | 行为 | 何时使用 |
|------|------|----------|
| **contain**（默认） | 完整保留坦克，左右可能留透明边 | 默认；用户未明确要求铺满裁切 |
| **cover** | 铺满四边，会裁掉炮管/车尾 | 仅当用户明确接受裁切 |
| **stretch** | 非等比拉满 512×512 | 仅当用户明确接受变形 |

**不要擅自改用 cover**。此前 cover 会切掉坦克内容，已改为 contain。

若用户要改模式，修改本 Skill 下 `scripts/process_tank_sprites.py` 中的 `resize_contain_fit`，不要临时手写一次性脚本。

## Agent 执行清单

```
- [ ] 确认目标目录与文件匹配规则
- [ ] 提醒用户脚本会原地覆盖（或已备份）
- [ ] 检查/安装依赖
- [ ] 运行 py .cursor/skills/process-tank-sprites/scripts/process_tank_sprites.py
- [ ] 验证输出尺寸为 512×512
- [ ] 抽查 1–2 张：炮管、车尾是否完整
```

## 故障排查

| 问题 | 处理 |
|------|------|
| `Python was not found` | 用 `py` 而非 `python` |
| rembg 首次很慢 | 正常，需下载 u2net 模型 (~176MB) |
| `no visible tank content found` | 抠图失败，检查原图或单张手动处理 |
| 用户要恢复原版 | `git restore image/characters/*.png` |

## 相关资源

- 生成坦克原图提示词：`skill/tank/tank-simple.md`、`skill/tank/tank-full.md`
- 输出目录：`image/characters/`
