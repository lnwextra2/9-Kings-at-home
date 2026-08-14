# Soldier Passives — spec (ยังไม่ implement, จดไว้กันลืม 2026-08-13)

ทหาร "plain 9 ใบ" ที่สร้างไว้ (stat-only) จริงๆ มี passive skill ประจำตัว — ต่อไปนี้คือ spec
ที่ผู้ใช้ให้มา — ต้องอธิบายก่อนทำทีละใบ (process rule เดิม)

**สถานะ ทำแล้ว:**
- ✅ #2 sniper (BACKLINE) + #5 executioner (LOWEST_HP) — `CardData.target_mode` → bake ลง unit → `Combat._acquire_target`
- ✅ #4 mercenary — `CardData.count_per_gold` (>0 = fix count = 1 + gold/ค่านี้, ไม่ขึ้นกับ level) คิดตอน `Spawner.spawn_player`
- ✅ #6 ant (+9 count จบเทิร์น) — data ล้วน: EffectData END_TURN/MODIFY_STAT/SELF/count/flat/ไม่ scale level
- ✅ #9 slime — `EffectData.Action.CLONE_SELF` (สุ่ม 1 ช่องว่างแนว + ที่ไม่ล็อก, ก็อป stat/level ปัจจุบัน)
  - แถม: `TurnResolver.resolve` ใช้ snapshot ต้นเทิร์นแล้ว → การ์ดที่เกิดใหม่ไม่ทำงานซ้ำในเทิร์นเดียวกัน (กัน cascade)

- ✅ #7 orc (บัฟ **ถาวร** +5% all stat/ช่องว่าง) — `EffectData.Action.GROW_ALL_PER_EMPTY` (value=0.05, END_TURN)
  จบเทิร์นคูณ cur_hp/cur_attack/cur_aspd/cur_crit/cur_move_mult ×(1+v)^(ช่องว่างแนว + ) **ถาวรบน instance** สะสมทบทุกเทิร์น (ค้างข้าม combat)
  - เพิ่ม `cur_move_mult` ใน instance (move_speed เดิมอ่านจาก CardData ตรงๆ ไม่มีที่เก็บบัฟถาวร) → `Unit.from_instance` คูณให้
  - buff_event kind=&"grow" → main.gd โชว์ "+N% ALL" (ส้มแดง)

- ✅ #3 goblin — `CardData.warp_backline` (bool): **เดินตั้งแถวปกติก่อน** แล้ว **กระโดด** ข้ามไป `cfg.warp_x` (985 หลังแนวศัตรู)
  - forming มี 2 เฟส: march (form_duration) → leap (leap_duration) — freeze การสู้ทั้ง 2 เฟส
  - unit fields: will_leap/leaping/leap_fx,fy/leap_tx,ty/leap_prog; state.leaping/leap_t
  - `Combat._tick_leaping` lerp leap_from→leap_to; view ยก sprite เป็น arc `sin(leap_prog·π)·leap_height`
  - ลงแล้ว targeting ปกติจับศัตรูรั้งท้ายเอง (ตีจากด้านหลัง)

- ✅ #8 crystal — `CardData.double_buff_stacks` (bool): ตอน `Board.use_card` BUFF branch คูณ ability stack ×2
  ถ้าเป้าเป็น crystal (block/lifesteal ฯลฯ ×2); TOME (stat/level) branch ไม่แตะ = บัฟ stat เท่าเดิม

**✅ ครบทั้ง 9 ใบแล้ว** (imp ไม่ต้องมี passive) — passive plain soldiers เสร็จสมบูรณ์

## นิยามกลาง (ใช้ร่วมทุกใบ)
- **"รอบตัว" = แนว + เท่านั้น** (บน/ล่าง/ซ้าย/ขวา) — ไม่นับแนวทแยง
- **"ช่องว่าง" = ช่องที่วางการ์ดได้ แต่ยังไม่มีการ์ด** — ไม่นับช่องที่ยัง "ล็อก" อยู่
- **"All stat" = dmg, hp, speed, atkCd, crit chance** — ปรับแบบ **คูณ** (ไม่ใช่บวกตรงๆ)

## Passive ต่อใบ
1. **imp (ปีศาจจิ๋ว)** — ตรงตัว เน้นจำนวนอย่างเดียว (ไม่มี passive พิเศษ)
2. **sniper (พลซุ่มยิง)** — เล็งยิงศัตรู **แนวหลังก่อน** (target priority = ศัตรูที่อยู่ไกลสุด/หลังสุด)
3. **goblin (ก็อปลิน)** — เมื่อเริ่มสู้ **วาร์ปไปแนวหลังศัตรูทันที**
4. **mercenary (ทหารรับจ้าง)** — เก่ง แต่ **fix count**: +1 ตัวทุกๆ 15 gold (เริ่มต้น 1 ตัว) — count ไม่ขึ้นกับ level ปกติ
5. **executioner (นักประหาร)** — โจมตีศัตรูที่ **HP เหลือน้อยที่สุดในระยะ** ก่อน
6. **ant (มด)** — จบเทิร์นได้ **+9 count** ให้ตัวเอง
7. **orc (ออร์ค)** — **+3% All stat ต่อ 1 ช่องว่างรอบตัว** (แนว + ) ให้ตัวเอง
8. **crystal (คริสตัล)** — ได้ **stack ×2 จากการ์ดบัฟ** (พวกบัฟที่ให้ stack) — แต่บัฟ stat ตรงๆ ได้เท่าเดิมไม่เปลี่ยน
9. **slime (สไลม์)** — จบเทิร์น **ก็อปปี้ตัวเองไปช่องว่างรอบตัว 1 ช่อง** (แนว + )

## Group B — special soldiers (stat-only, กลไกทยอยทำ)
- ✅ **goat (rainbow) — goldOnDeath**: `CardData.gold_on_death` (=3, ต่อ level) → bake `u.gold_on_death = ค่า×inst.level`
  ใน `Unit.from_instance` → `Combat._cleanup_deaths` ทหารฝั่งเราตาย +ทอง (ระหว่างสู้ ใช้ตอน planning ถัดไป)
  - ยังไม่มี popup ทองในสนาม (เพิ่มทีหลังได้)
- ✅ **bomber (red) — kamikaze**: `CardData.kamikaze` + `bomb_radius` (=48) เป็นรัศมีระเบิด (ไม่ใช้ splash_radius กันชนกับ projectile)
  ในสนามถึงระยะประชิด → `Combat._detonate` = `_damage_area(dmg=attack, r=bomb_radius)` แล้ว hp=0 (ตายเป็นศพ)
  - ระเบิดเฉพาะตอนถึงเป้า (ถ้าโดนฆ่าก่อนไม่ระเบิด) — พอสำหรับตอนนี้
- ยังไม่ทำ: protector (reflect) · boar/raptor (mount) · mob (addCount) · labrat (level-spread) · demon (summon)
- tier-2 `on_death` hooks_script ยัง**ไม่ wire** (ตอนนี้ goat ใช้ data-flag พอ) — ถ้ามีกลไก death ซับซ้อนค่อย wire dispatch ใน `_cleanup_deaths`

## หมายเหตุ implement (คิดคร่าวๆ ไว้ทีหลัง)
- 2,3,5 = ระบบ target/positioning ในสนามรบ (combat.gd)
- 6,9 = END_TURN บนกระดาน (แต่เป็น per-card hook ไม่ใช่ EffectData ธรรมดา — 9 ต้องหาช่องว่างรอบตัว)
- 4 = count ผูกกับ gold (คิดตอน spawn)
- 7 = ปรับ stat ตอน spawn ตามช่องว่างรอบช่องตัวเอง (คูณ)
- 8 = คริสตัลต้องรู้ว่า buff/tome ที่ตกใส่ตัวเองให้ ×2 (แตะ TurnResolver/effect apply)
