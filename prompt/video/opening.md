# 《AI TANK》开场动画 — 生成流程

先生成参考图锁定风格与高潮构图，再生成视频；参考图不作 I2V 首帧。

1. 从下方【参考图 Prompt】任选一种风格出图 → 保存为 `assets/video/tank-opening-ref.png`（或同类路径）。
2. （推荐）另出一张同场景、无单位的空旷战场图作 I2V 首帧 → `assets/video/tank-opening-start.png`。
3. 用【视频 Prompt】生成 10～12 秒开场：空场首帧起势 → 交火推进 → 定格到接近参考图构图 → 标题。
4. 成片转 OGV，放入 `assets/video/tank-opening-N.ogv`。

**参考图用法：** 只作风格 / 配色 / 单位造型 / 尾段高潮构图锁定。不要把高潮参考图当作 start frame；否则 0～1 秒已是满场交火，与空场起势割裂。

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

见 [opening-video.md](./opening-video.md)。基于参考图锁定风格与涂装；首帧用空场图，勿用高潮参考图。
