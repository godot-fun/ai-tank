# 《AI TANK》开场动画 — 生成流程

先生成参考图，再以参考图做 Image-to-Video，可降低视频生成成本并稳定角色颜色与构图。

1. 从下方【参考图 Prompt】任选一种风格出图 → 保存为 `assets/video/tank-opening-ref.png`（或同类路径）。
2. 将参考图作为首帧 / 风格参考，再用【视频 Prompt】生成 10～12 秒开场。
3. 成片转 OGV，放入 `assets/video/tank-opening-N.ogv`。

---

## 参考图 Prompt（多风格）

构图、单位配色、俯视视角一致；仅美术风格不同。择一生成即可。

| 文件 | 风格 |
|------|------|
| [opening-image-modern-pixel.md](./opening-image-modern-pixel.md) | 高精度现代像素风（推荐默认） |
| [opening-image-classic-8bit.md](./opening-image-classic-8bit.md) | 经典 8-bit《坦克大战》复古风 |
| [opening-image-soft-indie.md](./opening-image-soft-indie.md) | 柔和独立游戏像素风 |
| [opening-image-military-scifi.md](./opening-image-military-scifi.md) | 军事硬表面科幻像素风 |
| [opening-image-painterly.md](./opening-image-painterly.md) | 手绘厚涂俯视战场风 |

---

## 视频 Prompt

见 [opening-video.md](./opening-video.md)。必须基于已选定的参考图做 Image-to-Video，锁定构图与涂装。
