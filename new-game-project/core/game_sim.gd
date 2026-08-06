class_name GameSim
extends RefCounted
## planning actions — input (view) → action dict → step() (turn-based, ไม่มี dt)
## view ห้ามแก้ state เอง ต้องผ่านที่นี่เท่านั้น


static func step(state: GameState, action: Dictionary) -> bool:
    match action.type:
        &"place_card":
            return _place_card(state, action.hand_index, action.slot)
        &"use_card":
            return _use_card(state, action.hand_index, action.slot)
        &"end_turn":
            return _start_combat(state)
    return false


static func _use_card(state: GameState, hand_index: int, slot: int) -> bool:
    if hand_index < 0 or hand_index >= state.hand.size():
        return false
    var data_id: StringName = state.hand[hand_index]
    if Board.use_card(state, data_id, slot):
        state.hand.remove_at(hand_index)
        return true
    return false


static func _place_card(state: GameState, hand_index: int, slot: int) -> bool:
    if hand_index < 0 or hand_index >= state.hand.size():
        return false
    var data_id: StringName = state.hand[hand_index]
    if Board.place(state, data_id, slot):
        state.hand.remove_at(hand_index)
        return true
    return false


## จบเทิร์น → เข้าสนามรบ (TurnResolver on_end_turn = M3)
static func _start_combat(state: GameState) -> bool:
    var cfg: BattleConfig = state.battle_cfg
    state.units = Spawner.spawn_player(state, cfg)
    state.units.append_array(WaveGen.make_wave(state, cfg))
    state.base_unit = _find_base_unit(state)
    state.projectiles = []
    state.combat_time = 0.0
    state.result = &""
    state.phase = &"combat"
    return true


static func _find_base_unit(state: GameState) -> int:
    for i in state.units.size():
        if state.units[i].is_base:
            return i
    return -1


## จบการรบ (view เรียกเมื่อ state.result != "") — M2: แพ้ −1 HP แล้วไป floor ถัดไป
## (reward/ร้าน = M3, boss −3 = M5)
static func end_combat(state: GameState) -> void:
    if state.result == &"lose":
        state.base_hp -= 1
    state.units = []
    state.projectiles = []
    state.base_unit = -1
    if state.base_hp <= 0:
        state.phase = &"gameover"
    else:
        state.floor_num += 1
        state.phase = &"planning"
