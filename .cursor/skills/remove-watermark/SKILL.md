---
name: remove-watermark
description: >-
  Remove image watermarks via LaMa/IOPaint deep-learning inpainting. Generates
  or accepts masks, batch-runs iopaint CLI. Use when the user asks to remove
  watermarks, logo overlays, text stamps, or inpaint masked regions with LaMa/MAT.
---

# Remove Watermark (LaMa / IOPaint)

用 **LaMa** 等 inpainting 模型，根据 mask 语义级重绘水印区域。质量上限高，适合大水印、压在细节上的半透明 logo。

| 优点 | 缺点 |
|------|------|
| 大水印、压细节处效果更好 | 需 GPU 才实用；模型体积大 |
| IOPaint 有 CLI，可脚本化 | 依赖重（PyTorch 等） |
| | 批处理慢，环境难统一 |

**与 `process-sprites` 的区别**：process-sprites 用 rembg 抠整图背景；本 skill 只修复 mask 标记的小块区域，保留原图其余像素。

## Quick Start

### 1. 安装依赖（建议独立 venv）

```bash
# CPU（慢，仅适合单张试跑）
py -m pip install iopaint pillow numpy

# GPU（推荐，CUDA 11.8 示例；按本机 CUDA 版本选 wheel）
py -m pip install torch torchvision --index-url https://download.pytorch.org/whl/cu118
py -m pip install iopaint pillow numpy
```

首次运行会自动下载 LaMa 模型（约数百 MB）。

### 2. 确定 mask 来源（三选一）

| 方式 | 适用场景 |
|------|----------|
| `--corner bottom-right` 等 | 角落固定 logo / 文字水印 |
| `--rect x,y,w,h` | 已知像素或百分比矩形 |
| `--mask path.png` 或 `--mask-dir masks/` | 手动绘制 mask（白=修复，黑=保留） |

交互式画 mask：`iopaint start --model=lama --device=cuda --port=8080`，浏览器中涂抹后导出 mask。

### 3. 批处理

```bash
# 角落水印（宽 28%、高 10%，距右下各 2% 边距）
py .cursor/skills/remove-watermark/scripts/remove_watermark.py image/_src/bullets/basic \
  --corner bottom-right --width 0.28 --height 0.10 --margin 0.02

# 固定矩形（像素）
py .cursor/skills/remove-watermark/scripts/remove_watermark.py image/foo \
  --rect 820,900,180,80

# 百分比矩形（相对各图尺寸）
py .cursor/skills/remove-watermark/scripts/remove_watermark.py image/foo \
  --rect 80%,90%,18%,8%

# 已有 mask 目录（文件名与原图一致）
py .cursor/skills/remove-watermark/scripts/remove_watermark.py image/foo \
  --mask-dir image/foo/_masks

# 单张 mask 套用到全部图片
py .cursor/skills/remove-watermark/scripts/remove_watermark.py image/foo \
  --mask path/to/watermark_mask.png

# 覆盖原图（默认输出到 <目录>_clean/）
py .cursor/skills/remove-watermark/scripts/remove_watermark.py image/foo \
  --corner bottom-right --in-place

# 仅生成 mask，不跑模型
py .cursor/skills/remove-watermark/scripts/remove_watermark.py image/foo \
  --corner bottom-right --masks-only
```

## 默认行为

| 参数 | 默认值 | 说明 |
|------|--------|------|
| 目录 | `image` | 相对项目根 |
| 匹配 | `*.png` | glob |
| 模型 | `lama` | 也可 `mat` 等 IOPaint 支持的 erase 模型 |
| 设备 | `auto` | 有 CUDA/MPS 则自动选用 |
| 输出 | `<目录>_clean/` | `--in-place` 时覆盖原图 |
| `--expand` | `8` | mask 外扩像素，改善边缘融合 |

## 流水线

```
原图 + mask 定义（角落/矩形/外部 PNG）
  → ① 按图尺寸生成 per-image mask（白=inpaint）
  → ② 可选 dilate 扩展 mask
  → ③ iopaint run --model=lama 语义重绘
  → ④ 写入 _clean/ 或原地覆盖
```

Mask 约定：**白色 (255) = 待修复区域，黑色 (0) = 保留**。

**透明背景**：IOPaint 输出 RGB，会丢失 Alpha。脚本会在 inpaint 后**仅替换 mask 内 RGB**，mask 外保留原图 RGBA（透明区域不会被填成黑色）。

## 模型与质量

- **默认 `lama`**：速度快、擦除效果好，批处理首选。
- 大图可传 `--config` JSON 调整 HD 策略，例如：

```json
{"hd_strategy": "Resize", "hd_strategy_resize_limit": 2048}
```

```bash
py .cursor/skills/remove-watermark/scripts/remove_watermark.py image/foo \
  --corner bottom-right --config .cursor/skills/remove-watermark/hd_config.json
```

## Agent 执行清单

```
- [ ] 确认水印位置：角落 preset / 矩形 / 已有 mask
- [ ] 提醒：GPU 推荐；首次会下载模型；批处理较慢
- [ ] 检查/安装 iopaint + torch（按是否有 GPU）
- [ ] 先用 1 张图 + 默认 _clean 输出试跑，目视验收
- [ ] mask 不够时调 --expand 或扩大 --width/--height
- [ ] 满意后再 --in-place 或整批处理
- [ ] 验收：水印消失、纹理连续、无明显涂抹块
```

## 故障排查

| 问题 | 处理 |
|------|------|
| `iopaint not found` | `py -m pip install iopaint`，脚本会用 `py -m iopaint` |
| 极慢 | 换 `--device cuda`；CPU 仅适合单张 |
| CUDA OOM | `--config` 降低 `hd_strategy_resize_limit` |
| 边缘有残影 | 增大 `--expand` 或 mask 矩形 |
| 修复区域过大/过小 | 调整 `--corner` / `--rect` / 手动 mask |
| 自动 mask 不准 | `--masks-only` 生成 mask 后手动修，再 `--mask-dir` |
| 要恢复原版 | `git restore <目录>` |

## 相关资源

- IOPaint 批处理文档：https://www.iopaint.com/batch_process
- 实现脚本：[scripts/remove_watermark.py](scripts/remove_watermark.py)
- 整图抠背景（非水印）：`process-sprites` skill
