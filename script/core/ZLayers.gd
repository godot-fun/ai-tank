## 2D 绘制层级（z_index）规划
##
## Godot CanvasItem.z_index 合法范围约 -4096 … 4096；同层再比树序。
## 未列出的物体（坦克、砖/钢墙等）保持默认 0。
##
## 【自下而上】
## | z     | 常量                | 谁用 |
## | -10   | ASSIST_MAP          | AssistMap 调试网格 |
## | -8    | WATER / ICE         | Water、Ice（坦克驶过其上） |
## | -4    | BULLET              | BasicBullet |
## | 0     | （默认）            | 坦克、砖/钢/基地碰撞格 |
## | 1     | EAGLE               | Eagle 独立 Sprite |
## | 8     | FOREST              | Forest（遮挡坦克） |
## | 64    | RELOAD_INDICATOR    | ReloadIndicator |
## | 128   | BUFF                | Buff 拾取物 |
## | 512   | AIR_STRIKE          | 空袭飞机 Sprite |
## | 2048  | RESPAWN_COUNTDOWN   | RespawnCountdown |
## | 4096  | STAGE_OVERLAY       | StageClearEffect、GameOverEffect |
##
## 【创建入口】各节点 _ready() / start() 内 `z_index = ZLayers.XXX`。
class_name ZLayers

const ASSIST_MAP := -10
const WATER := -8
const ICE := -8
const BULLET := -4
const EAGLE := 1
const FOREST := 8
const RELOAD_INDICATOR := 64
const BUFF := 128
const AIR_STRIKE := 512
const RESPAWN_COUNTDOWN := 2048
const STAGE_OVERLAY := 4096
