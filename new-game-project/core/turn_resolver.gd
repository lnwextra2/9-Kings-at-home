class_name TurnResolver
extends RefCounted
## จบเทิร์น (ก่อนเข้าสนามรบ) — ยิง EffectData ที่ trigger = END_TURN ของทุกการ์ดบนกระดาน
## engine รู้จักแค่ EffectData ไม่รู้จักชื่อการ์ด (กฎเหล็ก)


static func resolve(state: GameState) -> void:
    for idx in state.board.size():
        var c = state.board[idx]
        if not (c is Dictionary):
            continue
        var d: CardData = Content.card(c.data_id)
        for e in d.effects:
            if e.trigger == EffectData.Trigger.END_TURN:
                _fire(state, idx, e)


static func _fire(state: GameState, idx: int, e: EffectData) -> void:
    var source: Dictionary = state.board[idx]
    var mult: int = int(source.level) if e.scales_with_level else 1
    match e.action:
        EffectData.Action.GRANT_GOLD:
            state.gold += int(e.value * mult)          # ตลาด: +value × level
        EffectData.Action.MODIFY_STAT:
            for t in _targets(state, idx, e):
                _apply_stat(t, e, mult)                # ฟาร์ม: +count ให้เพื่อนบ้าน ฯลฯ


## แปลง target → รายการ card instance ที่โดนผล
static func _targets(state: GameState, idx: int, e: EffectData) -> Array:
    match e.target:
        EffectData.Target.SELF:
            return [state.board[idx]]
        EffectData.Target.NEIGHBORS_4:
            return _neighbor_cards(state, idx, e)
        EffectData.Target.RANDOM_NEIGHBOR:
            var ns: Array = _neighbor_cards(state, idx, e)
            if ns.is_empty():
                return []
            return [state.rng.pick(ns)]
    return []


## การ์ดในช่องเพื่อนบ้าน; ถ้าเป็น effect count → เอาเฉพาะทหาร (ตาม reference "ทหารข้างเคียง")
static func _neighbor_cards(state: GameState, idx: int, e: EffectData) -> Array:
    var out: Array = []
    var count_only: bool = e.stat_name == &"count"
    for n in Board.neighbors_4(state, idx):
        var c = state.board[n]
        if not (c is Dictionary):
            continue
        if count_only and Content.card(c.data_id).kind != CardData.Kind.SOLDIER:
            continue
        out.append(c)
    return out


static func _apply_stat(card: Dictionary, e: EffectData, mult: int) -> void:
    if e.is_percent:
        Stats.apply_pct(card, e.stat_name, e.value)    # % ปกติไม่คูณ level (ทบต้นทุกเทิร์นเอง)
    else:
        Stats.apply_flat(card, e.stat_name, e.value * mult)
