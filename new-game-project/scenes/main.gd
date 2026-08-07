extends Control
## ตัวสลับ phase — planning (วาง+ร้าน) ↔ combat (สนามรบ) ↔ reward ↔ gameover
## UI ทั้งหมดเป็น node ใน main.tscn (จัดใน editor ได้) — สคริปต์แค่ wire signal + refresh

@onready var _top: Label = $TopBar
@onready var _planning: Control = $Planning
@onready var _board = $Planning/BoardView
@onready var _hand = $Planning/HandView
@onready var _fight: Button = $Planning/FightButton
@onready var _color_btn: Button = $Planning/ColorButton
@onready var _panel = $Planning/CardPanel
@onready var _shop = $Planning/ShopView
@onready var _battle = $Battlefield
@onready var _devbtn: Button = $DevButton
@onready var _reward = $RewardView
@onready var _debug = $DebugView
@onready var _overlay: Control = $ResultOverlay
@onready var _result_label: Label = $ResultOverlay/Panel/VBox/ResultLabel
@onready var _continue: Button = $ResultOverlay/Panel/VBox/ContinueButton

var _color_sb: StyleBoxFlat
var _sel_hand: int = -1
var _sel_slot: int = -1


func _ready() -> void:
    _hand.connect("card_selected", _on_card_selected)
    _board.connect("slot_clicked", _on_slot_clicked)
    _fight.pressed.connect(_on_fight)
    _battle.connect("combat_ended", _on_combat_ended)
    _continue.pressed.connect(_on_gameover_continue)
    _panel.connect("sell_pressed", _on_sell)
    _panel.clear()
    _shop.connect("buy", _on_buy)
    _shop.connect("reroll_pressed", _on_shop_reroll)
    _reward.connect("picked", _on_reward_pick)
    _reward.connect("reroll_pressed", _on_reward_reroll)
    _reward.visible = false
    _debug.connect("give_card", _on_dbg_give)
    _debug.connect("give_gold", _on_dbg_gold)
    _debug.connect("skip_floor", _on_dbg_skip)
    _debug.connect("spawn_enemies", _on_dbg_spawn)
    _debug.connect("clear_enemies", _on_dbg_clear)
    _debug.visible = false
    _devbtn.pressed.connect(func(): _debug.visible = not _debug.visible)
    _color_btn.pressed.connect(_on_reroll_color)
    _color_sb = StyleBoxFlat.new()   # พื้นปุ่มสีเวฟ (เปลี่ยนสีตามเวฟใน _update_top)
    _color_sb.set_corner_radius_all(6)
    for _cs in ["normal", "hover", "pressed", "disabled"]:
        _color_btn.add_theme_stylebox_override(_cs, _color_sb)
    _refresh_planning()
    _update_phase()


func _on_reroll_color() -> void:
    if GameSim.step(Game.state, {"type": &"reroll_color"}):
        _refresh_planning()


## สีพื้นปุ่มสีเวฟ (โทนกลาง อ่านตัวหนังสือขาวออก) — เพิ่มสีใหม่ที่นี่
func _wave_btn_color(c: StringName) -> Color:
    match c:
        &"blue": return Color(0.24, 0.40, 0.66)
        &"red": return Color(0.62, 0.24, 0.22)
        &"green": return Color(0.24, 0.50, 0.30)
        &"gold": return Color(0.58, 0.48, 0.16)
        &"mint": return Color(0.22, 0.52, 0.46)
        _: return Color(0.30, 0.32, 0.36)


func _color_name(c: StringName) -> String:
    match c:
        &"blue": return "ฟ้า"
        &"red": return "แดง"
        &"green": return "เขียว"
        &"gold": return "ทอง"
        &"mint": return "มินต์"
        _: return str(c)


func _on_dbg_give(id: StringName) -> void:
    GameSim.step(Game.state, {"type": &"dbg_give", "data_id": id})
    _refresh_planning()


func _on_dbg_gold() -> void:
    GameSim.step(Game.state, {"type": &"dbg_gold", "amount": 100})
    _refresh_planning()


func _on_dbg_skip() -> void:
    GameSim.step(Game.state, {"type": &"dbg_skip_floor", "amount": 1})
    _refresh_planning()
    _update_phase()


func _on_dbg_spawn() -> void:
    GameSim.step(Game.state, {"type": &"dbg_spawn_enemies", "count": 20})


func _on_dbg_clear() -> void:
    GameSim.step(Game.state, {"type": &"dbg_clear_enemies"})


# --- planning: place / inspect ---
func _on_card_selected(i: int) -> void:
    _sel_hand = i
    _sel_slot = -1
    _panel.show_base(Game.state.hand[i])


func _on_slot_clicked(idx: int) -> void:
    if _sel_hand >= 0:
        var d: CardData = Content.card(Game.state.hand[_sel_hand])
        var act: StringName = &"use_card" if (d.kind == CardData.Kind.BUFF or d.kind == CardData.Kind.TOME) else &"place_card"
        if GameSim.step(Game.state, {"type": act, "hand_index": _sel_hand, "slot": idx}):
            _sel_hand = -1
            _hand.set_selected(-1)
            _refresh_planning()
            var occ = Game.state.board[idx]
            if occ is Dictionary:
                _panel.show_current(occ)
            else:
                _panel.clear()
        return
    _hand.set_selected(-1)
    var target = Game.state.board[idx]
    if target is Dictionary:
        _sel_slot = idx
        _panel.show_current(target)
    else:
        _sel_slot = -1
        _panel.clear()


func _on_sell() -> void:
    if _sel_hand < 0:
        return
    if GameSim.step(Game.state, {"type": &"sell_card", "hand_index": _sel_hand}):
        _sel_hand = -1
        _hand.set_selected(-1)
        _panel.clear()
        _refresh_planning()


# --- shop ---
func _on_buy(index: int) -> void:
    if GameSim.step(Game.state, {"type": &"buy", "shop_index": index}):
        _refresh_planning()


func _on_shop_reroll() -> void:
    if GameSim.step(Game.state, {"type": &"reroll_shop"}):
        _refresh_planning()


# --- combat ---
func _on_fight() -> void:
    GameSim.step(Game.state, {"type": &"end_turn"})
    _battle.start()
    _update_phase()


func _on_combat_ended() -> void:
    GameSim.end_combat(Game.state)
    _battle.visible = false
    if Game.state.phase == &"gameover":
        var st: GameState = Game.state
        _result_label.text = "GAME OVER\nไปถึงชั้น %d    ฆ่าศัตรู %d    ทองสะสม %d\n\n(กด 'ต่อไป' เพื่อเริ่มใหม่)" % [st.floor_num, st.kills, st.gold_earned]
        _overlay.visible = true
    else:
        _reward.refresh()
        _reward.visible = true
    _update_top()


# --- reward ---
func _on_reward_pick(index: int) -> void:
    if GameSim.step(Game.state, {"type": &"pick_reward", "index": index}):
        _reward.visible = false
        _reset_selection()
        _refresh_planning()
        _update_phase()


func _on_reward_reroll() -> void:
    if GameSim.step(Game.state, {"type": &"reroll_reward"}):
        _reward.refresh()


# --- gameover ---
func _on_gameover_continue() -> void:
    Game.restart()
    _overlay.visible = false
    _reset_selection()
    _refresh_planning()
    _update_phase()


# --- shared ---
func _update_phase() -> void:
    var ph: StringName = Game.state.phase
    _planning.visible = ph == &"planning"
    _battle.visible = ph == &"combat"
    if ph != &"reward":
        _reward.visible = false
    if ph != &"gameover":
        _overlay.visible = false
    _update_top()


func _refresh_planning() -> void:
    _board.refresh()
    _hand.refresh()
    _fight.disabled = Board.find_base(Game.state) == -1   # บังคับวางฐานก่อนรบ
    _shop.refresh()
    _update_top()


func _reset_selection() -> void:
    _sel_hand = -1
    _sel_slot = -1
    _hand.set_selected(-1)
    _panel.clear()


func _update_top() -> void:
    var st: GameState = Game.state
    var ph: String = "วางแผน"
    if st.phase == &"combat":
        ph = "สู้!"
    elif st.phase == &"reward":
        ph = "รางวัล"
    elif st.phase == &"gameover":
        ph = "จบเกม"
    _top.text = "ชั้น %d  ·  gold %d  ·  HP %d  ·  [%s]" % [st.floor_num, st.gold, st.base_hp, ph]
    _color_btn.text = "ศัตรูเวฟนี้: สี%s   ·   รีโรล %dg" % [_color_name(st.wave_color), st.enemy_reroll_cost]
    _color_btn.disabled = st.gold < st.enemy_reroll_cost
    _color_sb.bg_color = _wave_btn_color(st.wave_color)
