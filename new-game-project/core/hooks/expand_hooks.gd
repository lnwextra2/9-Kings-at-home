extends CardHooks
## ➕ ขยาย (โทม สีเทา, ใช้ครั้งเดียว) — hook tier-2 ตัวแรก
## ใช้บนช่องที่มีการ์ด: ทำลายการ์ดในช่อง → รับการ์ด 1×Lv ใบ → ปลดล็อกช่องรอบๆ (8 ทิศ)


func on_use(state: GameState, _data_id: StringName, slot: int) -> bool:
	var target = state.board[slot]
	if not (target is Dictionary):
		return false   # ต้องมีการ์ดในช่องให้ทำลาย (ช่องว่าง/ล็อก ใช้ไม่ได้)
	if Content.card(target.data_id).kind == CardData.Kind.BASE:
		return false   # ฐานทำลายไม่ได้
	var lv: int = int(target.level)

	# 1) ทำลายการ์ดในช่อง → ช่องกลับเป็นว่าง (ยังปลดล็อกอยู่)
	state.board[slot] = null

	# 2) รับการ์ด 1×Lv ใบ — สุ่มจาก pool สีเวฟ (อยากเปลี่ยน pool ที่มา ปรับตรงนี้)
	var pool: Array = Content.by_color(state.wave_color)
	if pool.is_empty():
		pool = Shop.pool()
	if not pool.is_empty():
		for _i in lv:
			state.hand.append(state.rng.pick(pool).id)

	# 3) ปลดล็อกช่องแนว + (4 ทิศตั้งฉาก) ที่ยังล็อกอยู่ (ขยายดินแดนออกจากช่องที่ใช้)
	for n in Board.neighbors_4(state, slot):
		if state.is_locked(n):
			state.board[n] = null
	return true
