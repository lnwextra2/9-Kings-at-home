extends Control
## แผง debug (เปิด/ปิดด้วยปุ่ม DEV) — cheat + โชว์จำนวนยูนิต 2 ฝ่าย
signal give_card(data_id: StringName)
signal give_gold
signal skip_floor
signal spawn_enemies
signal clear_enemies

@onready var _count: Label = $Panel/VBox/CountLabel
@onready var _cards: GridContainer = $Panel/VBox/Cards


func _ready() -> void:
    ($Panel/VBox/GoldBtn as Button).pressed.connect(func(): give_gold.emit())
    ($Panel/VBox/FloorBtn as Button).pressed.connect(func(): skip_floor.emit())
    ($Panel/VBox/SpawnBtn as Button).pressed.connect(func(): spawn_enemies.emit())
    ($Panel/VBox/ClearBtn as Button).pressed.connect(func(): clear_enemies.emit())
    for d in Content.all():
        var did: StringName = d.id
        var b := Button.new()
        b.text = d.display_name
        b.focus_mode = Control.FOCUS_NONE
        b.add_theme_font_size_override("font_size", 11)
        b.pressed.connect(func(): give_card.emit(did))
        _cards.add_child(b)


func _process(_dt: float) -> void:
    if not visible:
        return
    var us := 0
    var en := 0
    for u in Game.state.units:
        if not u.alive:
            continue
        if u.team == 0 and Unit.can_die(u):
            us += 1
        elif u.team == 1:
            en += 1
    _count.text = "เรา %d   /   ศัตรู %d" % [us, en]
