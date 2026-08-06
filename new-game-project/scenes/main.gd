extends Control
## Planning controller (M1) — เลือกการ์ดในมือ แล้วคลิกช่องเพื่อวาง/merge ผ่าน GameSim

@onready var _top: Label = $TopBar
@onready var _board = $BoardView
@onready var _hand = $HandView

var _selected: int = -1


func _ready() -> void:
    _hand.connect("card_selected", _on_card_selected)
    _board.connect("slot_clicked", _on_slot_clicked)
    _refresh_all()


func _on_card_selected(i: int) -> void:
    _selected = i


func _on_slot_clicked(idx: int) -> void:
    if _selected < 0:
        return
    var action := {"type": &"place_card", "hand_index": _selected, "slot": idx}
    if GameSim.step(Game.state, action):
        _selected = -1
        _refresh_all()


func _refresh_all() -> void:
    _board.refresh()
    _hand.refresh()
    _update_top()


func _update_top() -> void:
    var st: GameState = Game.state
    _top.text = "ชั้น %d  ·  gold %d  ·  HP %d  ·  การ์ดในมือ %d   —   เลือกการ์ด → คลิกช่อง (วางฐานก่อน)" % [
        st.floor_num, st.gold, st.base_hp, st.hand.size()
    ]
