class_name Board
extends RefCounted
## กระดาน: วาง / merge / กฎการ์ดฐาน — core ล้วน ห้ามรู้จัก Node
## กฎอ้าง kind (เช่น BASE) ได้ แต่ห้ามอ้างชื่อการ์ด (card.id == "...")


## หา slot ของฐานบนกระดาน (-1 = ยังไม่มี)
static func find_base(state: GameState) -> int:
    for i in state.board.size():
        var c = state.board[i]
        if c is Dictionary and Content.card(c.data_id).kind == CardData.Kind.BASE:
            return i
    return -1


## วางการ์ด (หรือ merge อัปเลเวล) — คืน true ถ้าสำเร็จ
static func place(state: GameState, data_id: StringName, slot: int) -> bool:
    var d: CardData = Content.card(data_id)
    if d == null:
        return false
    if d.kind == CardData.Kind.BASE:
        return _place_base(state, data_id, slot)
    if slot < 0 or slot >= state.board.size():
        return false
    if state.is_locked(slot):
        return false
    if state.is_empty(slot):
        state.board[slot] = Stats.make_instance(data_id)
        return true
    return _try_merge(state, slot, data_id)


## การ์ดฐาน: ใบแรกวางลงช่องว่าง / ใบถัดไปบังคับอัปเลเวลฐานเดิมเสมอ
static func _place_base(state: GameState, data_id: StringName, slot: int) -> bool:
    var b: int = find_base(state)
    if b == -1:
        if slot < 0 or slot >= state.board.size():
            return false
        if state.is_locked(slot) or not state.is_empty(slot):
            return false
        state.board[slot] = Stats.make_instance(data_id)
        return true
    return _try_merge(state, b, data_id)   # ไม่สนช่องที่เลือก


static func _try_merge(state: GameState, slot: int, data_id: StringName) -> bool:
    var c = state.board[slot]
    if not (c is Dictionary):
        return false
    if c.data_id != data_id:
        return false
    if c.level >= 3:
        return false
    Stats.level_up(c)
    return true
