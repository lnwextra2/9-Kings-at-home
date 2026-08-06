class_name Shop
extends RefCounted
## ร้านค้า — สุ่มการ์ดขาย, ซื้อ (ใช้ gold → เข้ามือ), reroll ทั้งแถว

const SLOTS := 4
const REROLL_COST := 2


## pool ที่ขาย (M3 = สีฟ้าทั้งหมด; M4 อาจอิงสี/floor)
static func pool() -> Array:
    return Content.by_color(&"blue")


static func roll(state: GameState) -> void:
    var p: Array = pool()
    state.shop.clear()
    if p.is_empty():
        return
    for i in SLOTS:
        state.shop.append(state.rng.pick(p).id)


static func buy(state: GameState, index: int) -> bool:
    if index < 0 or index >= state.shop.size():
        return false
    var data_id = state.shop[index]
    if not (data_id is StringName) or data_id == &"":
        return false
    var d: CardData = Content.card(data_id)
    if state.gold < d.cost:
        return false
    state.gold -= d.cost
    state.hand.append(data_id)
    state.shop[index] = &""   # ช่องว่างหลังซื้อ
    return true


static func reroll(state: GameState) -> bool:
    if state.gold < REROLL_COST:
        return false
    state.gold -= REROLL_COST
    roll(state)
    return true
