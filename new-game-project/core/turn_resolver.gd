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
                _fire(state, c, e)


static func _fire(state: GameState, card: Dictionary, e: EffectData) -> void:
    var mult: int = int(card.level) if e.scales_with_level else 1
    match e.action:
        EffectData.Action.GRANT_GOLD:
            state.gold += int(e.value * mult)
        EffectData.Action.MODIFY_STAT:
            # รองรับ target SELF (บัฟตัวเอง); target อื่น (NEIGHBORS/SAME_COLOR) เพิ่มเมื่อมีการ์ดที่ใช้
            if e.target == EffectData.Target.SELF:
                if e.is_percent:
                    Stats.apply_pct(card, e.stat_name, e.value)
                else:
                    Stats.apply_flat(card, e.stat_name, e.value)
