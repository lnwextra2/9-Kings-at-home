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
        &"sell_card":
            return _sell_card(state, action.hand_index)
        &"resolve_turn":
            return _resolve_turn(state)
        &"begin_combat":
            return _begin_combat(state)
        &"end_turn":
            _resolve_turn(state)
            return _begin_combat(state)
        &"buy":
            return Shop.buy(state, action.shop_index)
        &"reroll_shop":
            return Shop.reroll(state)
        &"shop_continue":
            if state.phase != &"shop":
                return false
            _advance_station(state)
            return true
        &"pick_blessing":
            return _pick_blessing(state, action.index)
        &"reroll_blessing":
            return _reroll_blessing(state)
        &"reroll_color":
            return _reroll_color(state)
        &"dbg_give":
            state.hand.append(action.data_id)
            return true
        &"dbg_gold":
            var amt: int = int(action.get("amount", 100))
            state.gold += amt
            state.gold_earned += amt
            return true
        &"dbg_skip_floor":
            state.floor_num += int(action.get("amount", 1))
            WaveGen.ensure_track(state, state.floor_num)
            _enter_station(state)
            return true
        &"dbg_spawn_enemies":
            _dbg_spawn_enemies(state, int(action.get("count", 20)))
            return true
        &"dbg_clear_enemies":
            for u in state.units:
                if u.team == 1 and u.alive:
                    u.alive = false
            return true
    return false


static func _dbg_spawn_enemies(state: GameState, count: int) -> void:
    var cfg: BattleConfig = state.battle_cfg
    var scale: float = WaveGen.scale_for(state.floor_num)
    for i in count:
        var y: float = float(state.rng.randi_range(int(cfg.enemy_y_margin), int(cfg.height - cfg.enemy_y_margin)))
        var x: float = cfg.enemy_x + float(state.rng.randi_range(-20, 40))
        state.units.append(Unit.from_data_scaled(1, WaveGen.ENEMY_ID, x, y, scale))


static func _sell_card(state: GameState, hand_index: int) -> bool:
    if hand_index < 0 or hand_index >= state.hand.size():
        return false
    state.hand.remove_at(hand_index)
    state.gold += state.sell_value
    state.gold_earned += state.sell_value
    return true


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


## จบเทิร์น: ยิง END_TURN effects (ฟาร์ม/ตลาด ฯลฯ) → ปล่อย buff_events ให้ view เล่นก่อน
## phase ยัง planning อยู่ (board ค้างโชว์เลขบัฟ) — combat เริ่มตอน view สั่ง begin_combat
static func _resolve_turn(state: GameState) -> bool:
    state.buff_events = []
    TurnResolver.resolve(state)
    return true


## เข้าสนามรบจริง (สปอว์นเรา+ศัตรูจากกระดานที่บัฟแล้ว)
static func _begin_combat(state: GameState) -> bool:
    var cfg: BattleConfig = state.battle_cfg
    state.units = Spawner.spawn_player(state, cfg)
    state.units.append_array(WaveGen.make_wave(state, cfg))
    state.base_unit = _find_base_unit(state)
    state.projectiles = []
    state.damage_events = []
    state.buff_events = []
    state.combat_time = 0.0
    state.result = &""
    state.phase = &"combat"
    return true


static func _find_base_unit(state: GameState) -> int:
    for i in state.units.size():
        if state.units[i].is_base:
            return i
    return -1


## จบการรบ (view เรียกเมื่อ state.result != "") — แพ้ −1 HP; แล้วไปสถานีถัดไป
## บอส (floor 30): ชนะ = จบเกม (ชนะ), แพ้ = เล่นบอสใหม่
static func end_combat(state: GameState) -> void:
    if state.result == &"lose":
        state.base_hp -= 1
    state.units = []
    state.projectiles = []
    state.base_unit = -1
    if state.base_hp <= 0:
        state.phase = &"gameover"
        return
    if WaveGen.is_boss_floor(state.floor_num):
        if state.result == &"win":
            state.phase = &"won"       # ชนะบอส = ชนะเกม
        else:
            _enter_station(state)      # แพ้บอส (ยังมี HP) → เล่นบอสใหม่
        return
    _advance_station(state)            # เวฟปกติ ชนะ/แพ้ก็ไปสถานีถัดไป


## เข้าสถานีปัจจุบัน — ตั้ง phase ตามชนิดสถานี
static func _enter_station(state: GameState) -> void:
    match WaveGen.station_type(state.floor_num):
        &"shop":
            Shop.roll(state)
            state.phase = &"shop"
        &"blessing":
            state.blessing_choices = Blessing.roll_choices(state, 3)
            state.blessing_reroll_cost = 10
            state.phase = &"blessing"
        _:   # combat / boss
            state.wave_color = state.wave_track[state.floor_num - 1].color
            var g: int = Blessing.gold_per_wave(state)   # พร: +ทองทุกเวฟ
            if g > 0:
                state.gold += g
                state.gold_earned += g
            state.phase = &"planning"


## ไปสถานีถัดไป (floor+1) แล้วเข้าสถานีนั้น
static func _advance_station(state: GameState) -> void:
    state.floor_num += 1
    WaveGen.ensure_track(state, state.floor_num)
    _enter_station(state)


## เลือกพร 1 อัน (stack) → ไปสถานีถัดไป
static func _pick_blessing(state: GameState, index: int) -> bool:
    if state.phase != &"blessing" or index < 0 or index >= state.blessing_choices.size():
        return false
    Blessing.pick(state, state.blessing_choices[index])
    state.blessing_choices = []
    _advance_station(state)
    return true


static func _reroll_blessing(state: GameState) -> bool:
    if state.gold < state.blessing_reroll_cost:
        return false
    state.gold -= state.blessing_reroll_cost
    state.blessing_reroll_cost += 10
    state.blessing_choices = Blessing.roll_choices(state, 3)
    return true


## รีโรลสีศัตรู — แพงขึ้นถาวรครั้งละ 10g (เฉพาะสถานี combat)
static func _reroll_color(state: GameState) -> bool:
    if state.gold < state.enemy_reroll_cost:
        return false
    state.gold -= state.enemy_reroll_cost
    state.enemy_reroll_cost += 10
    state.wave_color = WaveGen.roll_color(state.rng)
    state.wave_track[state.floor_num - 1]["color"] = state.wave_color   # อัพเดตสถานีปัจจุบัน
    return true
