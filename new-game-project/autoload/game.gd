extends Node
## Autoload singleton "Game" — ถือ GameState + สัญญาณให้ view รู้ว่า state เปลี่ยน
## (บางๆ เท่านั้น — logic เกมอยู่ใน core/)

signal state_changed

const DEFAULT_CONFIG := "res://data/config/default_run.tres"

var config: RunConfig
var state: GameState


func _ready() -> void:
    config = load(DEFAULT_CONFIG) as RunConfig
    if config == null:
        push_warning("โหลด default_run.tres ไม่ได้ — ใช้ค่า default")
        config = RunConfig.new()
    state = GameState.new_run(config)


func notify_changed() -> void:
    state_changed.emit()
