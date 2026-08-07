class_name Board
extends RefCounted
## กระดาน: วาง / merge / กฎการ์ดฐาน — core ล้วน ห้ามรู้จัก Node
## กฎอ้าง kind (เช่น BASE) ได้ แต่ห้ามอ้างชื่อการ์ด (card.id == "...")


## index เพื่อนบ้าน 4 ทิศ (บน/ล่าง/ซ้าย/ขวา) ที่อยู่ในกระดาน
static func neighbors_4(state: GameState, idx: int) -> Array:
    var col: int = idx % state.cols
    var row: int = idx / state.cols
    var out: Array = []
    if col > 0:
        out.append(idx - 1)
    if col < state.cols - 1:
        out.append(idx + 1)
    if row > 0:
        out.append(idx - state.cols)
    if row < state.rows - 1:
        out.append(idx + state.cols)
    return out


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


## ใช้ buff/tome กับการ์ดเป้าหมายบนกระดาน — คืน true ถ้าสำเร็จ
static func use_card(state: GameState, data_id: StringName, slot: int) -> bool:
    var d: CardData = Content.card(data_id)
    if d == null or slot < 0 or slot >= state.board.size():
        return false
    if d.hooks_script != null:                     # tier 2: การ์ดพิเศษตัดสินเป้า/กติกาเอง
        var hook: CardHooks = d.hooks_script.new()
        return hook.on_use(state, data_id, slot)
    var target = state.board[slot]
    if not (target is Dictionary):
        return false   # ต้องมีการ์ดเป้าหมาย (tier-1 buff/tome)
    match d.kind:
        CardData.Kind.BUFF:
            var td: CardData = Content.card(target.data_id)
            if td.kind != CardData.Kind.SOLDIER:
                return false   # บัฟใช้กับทหารเท่านั้น
            for k in d.abilities:
                target.abilities[k] = int(target.abilities.get(k, 0)) + int(d.abilities[k])
                state.buff_events.append({"slot": slot, "kind": &"ability", "ability": k, "stacks": int(d.abilities[k])})
            return true
        CardData.Kind.TOME:
            # กันใช้ตำราอัพเกรดตอนเลเวลเต็ม (Lv3) — ไม่กินการ์ด
            for e in d.effects:
                if e.action == EffectData.Action.LEVEL_UP and int(target.level) >= 3:
                    return false
            for e in d.effects:
                _apply_effect(target, e)
                match e.action:
                    EffectData.Action.MODIFY_STAT:
                        state.buff_events.append({"slot": slot, "kind": &"stat", "stat": e.stat_name, "amount": e.value, "is_percent": e.is_percent})
                    EffectData.Action.LEVEL_UP:
                        state.buff_events.append({"slot": slot, "kind": &"level"})
            return true
    return false


static func _apply_effect(card: Dictionary, e: EffectData) -> void:
    match e.action:
        EffectData.Action.MODIFY_STAT:
            if e.is_percent:
                Stats.apply_pct(card, e.stat_name, e.value)
            else:
                Stats.apply_flat(card, e.stat_name, e.value)
        EffectData.Action.LEVEL_UP:
            Stats.level_up(card)
