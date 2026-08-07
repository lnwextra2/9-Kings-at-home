class_name TurnResolver
extends RefCounted
## จบเทิร์น (ก่อนเข้าสนามรบ) — ยิง EffectData ที่ trigger = END_TURN ของทุกการ์ดบนกระดาน
## engine รู้จักแค่ EffectData ไม่รู้จักชื่อการ์ด (กฎเหล็ก)
## ปล่อย buff_events พร้อม "burst" (ลำดับ) → view เล่นเรียง: burst เดียวกัน = เด้งพร้อมกัน (บัฟหมู่),
## ต่างกัน = เด้งเป็นสเต็ป (ตามลำดับสิ่งก่อสร้าง / บัฟหลายครั้ง = รัวๆ)


static func resolve(state: GameState) -> void:
    var burst: Array = [0]   # ตัวนับลำดับ (ห่อ array เพื่อส่งต่อแบบแก้ค่าได้)
    for idx in state.board.size():
        var c = state.board[idx]
        if not (c is Dictionary):
            continue
        var d: CardData = Content.card(c.data_id)
        for e in d.effects:
            if e.trigger == EffectData.Trigger.END_TURN:
                _fire(state, idx, e, burst)


static func _fire(state: GameState, idx: int, e: EffectData, burst: Array) -> void:
    var source: Dictionary = state.board[idx]
    # สิ่งก่อสร้างสายบัฟ = "ทำงานเดิมซ้ำ level ครั้ง" (ไม่ใช่คูณค่าทีเดียว)
    # → ฟาร์ม Lv3 = +1 count สุ่มเพื่อนบ้าน 3 ครั้ง (กระจายโดนหลายตัวได้), ตลาด Lv3 = +3g สามครั้ง
    var procs: int = int(source.level) if e.scales_with_level else 1
    for _p in procs:
        match e.action:
            EffectData.Action.GRANT_GOLD:
                var g: int = int(e.value)              # ต่อครั้ง = value (level = จำนวนครั้ง)
                state.gold += g
                state.gold_earned += g
                state.buff_events.append({"slot": idx, "kind": &"gold", "amount": g, "burst": burst[0]})
                burst[0] += 1
            EffectData.Action.MODIFY_STAT:
                var slots: Array = _target_slots(state, idx, e)   # re-roll ทุกครั้ง → สุ่มกระจาย
                if slots.is_empty():
                    continue                           # ครั้งนี้ไม่มีเป้า → ข้าม (ไม่กินลำดับ)
                for s in slots:
                    _apply_stat(state.board[s], e)     # ต่อครั้ง = value (ไม่คูณ level)
                    state.buff_events.append({
                        "slot": s, "kind": &"stat", "stat": e.stat_name,
                        "amount": e.value, "is_percent": e.is_percent, "burst": burst[0],
                    })
                burst[0] += 1                          # เป้าของครั้งนี้ = burst เดียว (หมู่=พร้อมกัน), ครั้งถัดไป=burst ใหม่ (รัวๆ)


## target → รายการ "slot index" ที่โดนผล (คืน index เพื่อให้ view เด้งเลขถูกช่อง)
static func _target_slots(state: GameState, idx: int, e: EffectData) -> Array:
    match e.target:
        EffectData.Target.SELF:
            return [idx]
        EffectData.Target.NEIGHBORS_4:
            return _neighbor_slots(state, idx, e)
        EffectData.Target.RANDOM_NEIGHBOR:
            var ns: Array = _neighbor_slots(state, idx, e)
            if ns.is_empty():
                return []
            return [state.rng.pick(ns)]
    return []


## ช่องเพื่อนบ้านที่มีการ์ด; ถ้าเป็น effect count → เอาเฉพาะทหาร (ตาม reference "ทหารข้างเคียง")
static func _neighbor_slots(state: GameState, idx: int, e: EffectData) -> Array:
    var out: Array = []
    var count_only: bool = e.stat_name == &"count"
    for n in Board.neighbors_4(state, idx):
        var c = state.board[n]
        if not (c is Dictionary):
            continue
        if count_only and Content.card(c.data_id).kind != CardData.Kind.SOLDIER:
            continue
        out.append(n)
    return out


static func _apply_stat(card: Dictionary, e: EffectData) -> void:
    if e.is_percent:
        Stats.apply_pct(card, e.stat_name, e.value)    # ทบต้น (ซ้ำหลายครั้ง = compound)
    else:
        Stats.apply_flat(card, e.stat_name, e.value)   # +value ต่อครั้ง
