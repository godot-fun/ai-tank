class_name AudioConfig

const BGM_OPENING_DEMO_PART1 := "res://audio/bgm/ninja/remake/01-光奪われし世界-(オープニングデモ-前半).ogg"
const BGM_OPENING_DEMO_PART2 := "res://audio/bgm/ninja/remake/02-闇の仕事人現る-(オープニングデモ-後半).ogg"
const BGM_STAGE_START := "res://audio/bgm/ninja/remake/03-ステージスタート.ogg"
const BGM_BOSS_BATTLE := "res://audio/bgm/ninja/remake/05-強敵出現-(ボス戦).ogg"
const BGM_STAGE_CLEAR := "res://audio/bgm/ninja/remake/06-ステージクリア.ogg"
const BGM_PREPARATION := "res://audio/bgm/ninja/remake/07-仕事支度.ogg"
const BGM_STAGE_1 := "res://audio/bgm/ninja/remake/04-沿岸防衛ライン-(ステージ1).ogg"
const BGM_STAGE_2 := "res://audio/bgm/ninja/remake/08-地下世界-(ステージ2).ogg"
const BGM_STAGE_3 := "res://audio/bgm/ninja/remake/09-支配下の摩天楼-(ステージ3).ogg"
const BGM_STAGE_4 := "res://audio/bgm/ninja/remake/10-兵器工場-(ステージ4).ogg"
const BGM_STAGE_5 := "res://audio/bgm/ninja/remake/11-天空の機動要塞-(ステージ5).ogg"
const BGM_STAGE_6 := "res://audio/bgm/ninja/remake/12-悪鬼の牙城-(ステージ6).ogg"
const BGM_STAGE_6_BOSS := "res://audio/bgm/ninja/remake/13-最終決戦・皇帝ガルダ-(ステージ6ボス戦).ogg"
const BGM_STAGE_6_BOSS_PHASE_2 := "res://audio/bgm/ninja/remake/14-終焉の時-(ステージ6ボス戦-第2段階).ogg"
const BGM_ENDING := "res://audio/bgm/ninja/remake/15-闇に生きる忍び-(エンディング~スタッフロール).ogg"
const BGM_GAME_OVER := "res://audio/bgm/ninja/remake/16-ゲームオーバー.ogg"

const BGM_FC_STAGE_1 := "res://audio/bgm/ninja/04-Stage-1.ogg"
const BGM_FC_STAGE_2 := "res://audio/bgm/ninja/05-Stage-2.ogg"
const BGM_FC_STAGE_3 := "res://audio/bgm/ninja/06-Stage-3.ogg"
const BGM_FC_STAGE_4 := "res://audio/bgm/ninja/07-Stage-4.ogg"
const BGM_FC_STAGE_5 := "res://audio/bgm/ninja/08-Stage-5.ogg"

static var UI_SELECT := SoundEffect.new("res://audio/sfx/ui-select/01.wav")
static var UI_CONFIRM := SoundEffect.new("res://audio/sfx/ui-confirm/01.wav")
static var STAGE_START := SoundEffect.new(BGM_STAGE_START)
static var STAGE_CLEAR := SoundEffect.new(BGM_STAGE_CLEAR)

static var TANK_FIRE := SoundEffect.new("res://audio/sfx/tank/tank-fire.wav", 0.5)
static var TANK_DEATH := SoundEffect.new("res://audio/sfx/tank/tank_explosion.wav")
static var TANK_DEATH_ENEMY := SoundEffect.new("res://audio/sfx/tank/explosion-medium.wav")
static var TANK_MOVE := "res://audio/sfx/tank/tank_move_fade.wav"

static var BULLET_HIT_BULLET := SoundEffect.new("res://audio/sfx/tank/explosion-small.wav")
static var BULLET_HIT_TANK := SoundEffect.new("res://audio/sfx/tank/bullet_hit_steel.wav")
static var BULLET_HIT_STEEL := SoundEffect.new("res://audio/sfx/tank/bullet_hit_steel.wav", 0.3)
static var BULLET_HIT_BRICK := SoundEffect.new("res://audio/sfx/tank/bullet_hit_brick.wav", 0.4)


static var BUFF_LEVEL_UP := SoundEffect.new("res://audio/sfx/buff/level-up.wav")
static var BUFF_AIR_STRIKE := SoundEffect.new("res://audio/sfx/buff/air-strike.wav")
static var AIR_RAID_ALARM := SoundEffect.new("res://audio/sfx/buff/air-raid-alarm.wav")