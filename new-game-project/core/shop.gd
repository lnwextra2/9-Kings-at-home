class_name Shop
extends RefCounted
## ร้านค้า — สุ่มการ์ดขาย, ซื้อ (ใช้ gold → เข้ามือ), reroll ทั้งแถว

const SLOTS := 4
const REROLL_COST := 2


## pool ที่ขาย = การ์ดผู้เล่นทุกสี (เว้นการ์ดศัตรู debug)
static func pool() -> Array:
    var out: Array = []
    for d in Content.all():
        if d.id != WaveGen.ENEMY_ID:
            out.append(d)
    return out


static func roll(state: GameState) -> void:
    var p: Array = pool()
    state.shop.clear()
    if p.is_empty():
        return
    for i in SLOTS:
        state.shop.append(state.rng.pick(p).id)


## ราคาจริงหลังพรลดราคา (ปัดลง)
static func price(state: GameState, d: CardData) -> int:
    return int(round(d.cost * Blessing.shop_price_mult(state)))


static func buy(state: GameState, index: int) -> bool:
    if index < 0 or index >= state.shop.size():
        return false
    var data_id = state.shop[index]
    if not (data_id is StringName) or data_id == &"":
        return false
    var d: CardData = Content.card(data_id)
    var cost: int = price(state, d)   # พร ลดราคาร้าน
    if state.gold < cost:
        return false
    state.gold -= cost
    state.hand.append(data_id)
    state.shop[index] = &""   # ช่องว่างหลังซื้อ
    return true


static func reroll(state: GameState) -> bool:
    if state.gold < REROLL_COST:
        return false
    state.gold -= REROLL_COST
    roll(state)
    return true
