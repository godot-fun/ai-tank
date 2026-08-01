## 2D 物理碰撞层级规划
##
## 与 Project Settings → Layer Names → 2D Physics 一一对应。
##
## 【layer / mask 规则】
## - collision_layer：我「属于」哪些层（别人能不能扫到我）。
## - collision_mask：我「会去扫」哪些层（我主动碰谁）。
## - 检测成立条件：A.mask 与 B.layer 有交集（ShapeCast / Area 信号同理）。
## - collision_mask = 0：不主动检测任何层；仍可被别人扫到（只要对方 mask 开了本物体的 layer）。
## - 本项目坦克 / 实心砖 / 水 / 草冰 一律 mask = 0：移动靠格子逻辑，无需物理推挤；
##   能否被子弹打中、被射线扫到，只取决于对方的 mask。
## - 水 / 草 / 冰：有 layer，但当前无人 mask 指向 → 物理上「隐身」（子弹与射线碰不到）。
##
## 【设计原则】
## 1. 坦克移动 / A* / 挡路由格子逻辑（TileHelper / TankHelper）完成，不依赖物理推挤。
## 2. 物理主要用于：子弹 Area2D、Buff 拾取、僚机 ShapeCast2D。
## 3. 水 / 草 / 冰单独成层且无人 mask → 子弹与射线天然忽略；挡坦克仍走 blocks_tank()。
## 4. 子弹拆敌我两层；同阵营互伤/对射用 mask 表达，代码里可保留 faction 双保险。
##
## 【层定义】
## | Bit | 常量           | 层名           | 放谁 |
## | 1   | PLAYER_TANK    | player_tank    | MyTank、Partner* |
## | 2   | ENEMY_TANK     | enemy_tank     | Enemy* |
## | 3   | SOLID_TILE     | solid_tile     | BrickWall、BrickWallEagle、SteelWall、Eagle |
## | 4   | WATER_TILE     | water_tile     | Water |
## | 5   | SOFT_TILE      | soft_tile      | Forest、Ice |
## | 6   | PLAYER_BULLET  | player_bullet  | 玩家阵营子弹 |
## | 7   | ENEMY_BULLET   | enemy_bullet   | 敌方阵营子弹 |
## | 8   | BUFF           | buff           | Buff |
##
## 【各物体 layer / mask】
## | 物体           | layer                          | mask |
## | 玩家/僚机坦克  | PLAYER_TANK                    | 0 |
## | 敌方坦克       | ENEMY_TANK                     | 0 |
## | 砖/钢/基地     | SOLID_TILE                     | 0 |
## | 水             | WATER_TILE                     | 0（暂无任何 mask 指向） |
## | 草/冰          | SOFT_TILE                      | 0（暂无任何 mask 指向） |
## | 玩家弹         | PLAYER_BULLET                  | PLAYER_BULLET_MASK |
## | 敌方弹         | ENEMY_BULLET                   | ENEMY_BULLET_MASK |
## | Buff           | BUFF                           | PLAYER_TANK |
## | 僚机 ShapeCast | —                              | PARTNER_RAY_MASK |
##
## 【交互】
## - 玩家弹 → 敌坦 + 实心砖 + 敌弹（不打友军、不碰水草冰/Buff）
## - 敌方弹 → 玩家坦 + 实心砖 + 玩家弹
## - Buff 只扫玩家/僚机；敌人碰不到
## - 僚机射线只看敌坦 + 实心砖 + 敌弹（不扫友军，避免占满 max_count）
##
## 【创建入口】
## Tank / Tile / BasicBullet / Buff 的 setup_physics_layers()；
## PartnerTank.set_up_ray() 设置 ShapeCast collision_mask。
class_name PhysicsLayers

const PLAYER_TANK := 1 << 0
const ENEMY_TANK := 1 << 1
const SOLID_TILE := 1 << 2
const WATER_TILE := 1 << 3
const SOFT_TILE := 1 << 4
const PLAYER_BULLET := 1 << 5
const ENEMY_BULLET := 1 << 6
const BUFF := 1 << 7

## 僚机前方 ShapeCast：敌坦 + 实心砖/基地 + 敌弹
const PARTNER_RAY_MASK := ENEMY_TANK | SOLID_TILE | ENEMY_BULLET
## 玩家阵营子弹
const PLAYER_BULLET_MASK := ENEMY_TANK | SOLID_TILE | ENEMY_BULLET
## 敌方阵营子弹
const ENEMY_BULLET_MASK := PLAYER_TANK | SOLID_TILE | PLAYER_BULLET
