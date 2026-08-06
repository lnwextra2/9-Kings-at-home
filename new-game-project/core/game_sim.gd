class_name GameSim
extends RefCounted
## planning actions — input (view) → action dict → step() (turn-based, ไม่มี dt)
## view ห้ามแก้ state เอง ต้องผ่านที่นี่เท่านั้น


static func step(state: GameState, action: Dictionary) -> bool:
    match action.type:
        &"place_card":
            return _place_card(state, action.hand_index, action.slot)
    return false


static func _place_card(state: GameState, hand_index: int, slot: int) -> bool:
    if hand_index < 0 or hand_index >= state.hand.size():
        return false
    var data_id: StringName = state.hand[hand_index]
    if Board.place(state, data_id, slot):
        state.hand.remove_at(hand_index)
        return true
    return false
