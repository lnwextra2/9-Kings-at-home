extends Node
## Autoload singleton "Game" — ถือ GameState + สัญญาณให้ view รู้ว่า state เปลี่ยน
## (บางๆ เท่านั้น — logic เกมอยู่ใน core/)

signal state_changed

const DEFAULT_CONFIG := "res://data/config/default_run.tres"
const DEFAULT_BATTLE := "res://data/config/default_battle.tres"

var config: RunConfig
var battle_cfg: BattleConfig
var state: GameState


func _ready() -> void:
    config = load(DEFAULT_CONFIG) as RunConfig
    if config == null:
        push_warning("โหลด default_run.tres ไม่ได้ — ใช้ค่า default")
        config = RunConfig.new()
    battle_cfg = load(DEFAULT_BATTLE) as BattleConfig
    if battle_cfg == null:
        push_warning("โหลด default_battle.tres ไม่ได้ — ใช้ค่า default")
        battle_cfg = BattleConfig.new()
    state = GameState.new_run(config)
    state.battle_cfg = battle_cfg
    _fill_debug_hand()   # TEMP M1 — แทนด้วยร้าน/รางวัล ตอน M3


func notify_changed() -> void:
    state_changed.emit()


func _fill_debug_hand() -> void:   # TEMP M1
    state.hand = [
        &"base_castle", &"base_castle",
        &"swordsman", &"swordsman", &"swordsman",
        &"archer", &"ballista", &"wall", &"farm",
        &"buff_lifesteal", &"tome_sharpen",
    ]
