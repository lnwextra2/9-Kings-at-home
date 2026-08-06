extends Control
## ตัวสลับ phase — planning (วางการ์ด) ↔ combat (สนามรบ) + ผลแพ้/ชนะ

@onready var _top: Label = $TopBar
@onready var _planning: Control = $Planning
@onready var _board = $Planning/BoardView
@onready var _hand = $Planning/HandView
@onready var _fight: Button = $Planning/FightButton
@onready var _battle = $Battlefield
@onready var _overlay: Control = $ResultOverlay
@onready var _result_label: Label = $ResultOverlay/Panel/VBox/ResultLabel
@onready var _continue: Button = $ResultOverlay/Panel/VBox/ContinueButton

var _selected: int = -1
var _gameover_pending: bool = false


func _ready() -> void:
    _hand.connect("card_selected", _on_card_selected)
    _board.connect("slot_clicked", _on_slot_clicked)
    _fight.pressed.connect(_on_fight)
    _battle.connect("combat_ended", _on_combat_ended)
    _continue.pressed.connect(_on_continue)
    _refresh_planning()
    _update_phase()


func _on_card_selected(i: int) -> void:
    _selected = i


func _on_slot_clicked(idx: int) -> void:
    if _selected < 0:
        return
    if GameSim.step(Game.state, {"type": &"place_card", "hand_index": _selected, "slot": idx}):
        _selected = -1
        _refresh_planning()


func _on_fight() -> void:
    GameSim.step(Game.state, {"type": &"end_turn"})
    _battle.start()
    _update_phase()


func _on_combat_ended() -> void:
    var r: StringName = Game.state.result
    _result_label.text = "ชนะเวฟ! 🎉" if r == &"win" else "แพ้เวฟ — บ้าน −1 HP"
    _overlay.visible = true


func _on_continue() -> void:
    if _gameover_pending:
        _gameover_pending = false
        Game.restart()
        _refresh_planning()
        _update_phase()
        return
    GameSim.end_combat(Game.state)
    if Game.state.phase == &"gameover":
        _gameover_pending = true
        _result_label.text = "GAME OVER — ไปถึงชั้น %d\n(กด 'ต่อไป' เพื่อเริ่มใหม่)" % Game.state.floor_num
        return
    _selected = -1
    _refresh_planning()
    _update_phase()


func _update_phase() -> void:
    var ph: StringName = Game.state.phase
    _planning.visible = ph == &"planning"
    _battle.visible = ph == &"combat"
    _overlay.visible = false
    _update_top()


func _refresh_planning() -> void:
    _board.refresh()
    _hand.refresh()
    _fight.disabled = Board.find_base(Game.state) == -1   # บังคับวางฐานก่อนเริ่มรบ
    _update_top()


func _update_top() -> void:
    var st: GameState = Game.state
    var ph: String = "วางแผน"
    if st.phase == &"combat":
        ph = "สู้!"
    elif st.phase == &"gameover":
        ph = "จบเกม"
    _top.text = "ชั้น %d  ·  gold %d  ·  HP %d  ·  [%s]" % [st.floor_num, st.gold, st.base_hp, ph]
