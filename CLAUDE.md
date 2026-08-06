# Kingdom Battle — Project Instructions

เกม 2D roguelite deckbuilder + auto-battler บน **Godot 4.x / GDScript**
สร้างใหม่จาก prototype HTML/JS ที่เล่นได้จริงแล้ว (บทเรียน: prototype เดิมโค้ดเละเพราะ logic การ์ดกระจายทั่ว engine)

**อ่านก่อนเริ่มงานเสมอ:**
- `docs/01_GAME_DESIGN.md` — เกมเล่นยังไง (source of truth ของกฎเกม)
- `docs/02_ARCHITECTURE.md` — โค้ดจัดโครงยังไง (source of truth ของสถาปัตยกรรม)
- `docs/03_MILESTONES.md` — ทำอะไรก่อนหลัง

---

## 🔴 กฎเหล็ก 4 ข้อ

1. **`core/` ห้ามรู้จัก Node** — ห้าม `get_node`, `preload(scene)`, `Input`, `Time`, `randi()`
2. **`core/` ห้ามรู้จักชื่อการ์ด** — ห้ามมี `if card.id == "farm"` เด็ดขาด ใช้ `EffectData` หรือ hook script
3. **View ห้ามแก้ state** — view อ่าน state แล้ววาด, input → action dict → `GameSim.step()`
4. **สุ่มผ่าน `state.rng` เท่านั้น** — determinism คือสิ่งที่ทำให้ save/replay/test ทำได้

> ถ้าเจอกรณีที่รู้สึกว่า "ต้องแหก 1 ใน 4 ข้อนี้แหละ" → **หยุด ถามก่อน** อย่าแหกเอง

---

## GDScript Conventions

- **Static typing ทุกที่** — `var hp: float = 20.0`, `func attack_of(card: Dictionary) -> float:`
- ชื่อไฟล์ `snake_case.gd` / `class_name PascalCase`
- `StringName` (`&"..."`) สำหรับ id/key ที่เทียบบ่อย — เร็วกว่า String มาก
- `@export` เฉพาะค่าที่อยากจูนใน editor
- `_private_method()` ขึ้นต้น underscore
- ค่าคงที่สมดุล **ห้าม hardcode ในสคริปต์** → อยู่ใน `.tres` หรือ `RunConfig`
- ใช้ `Array[Type]` typed array เมื่อทำได้
- ยูนิตในสนามรบเป็น **Dictionary ไม่ใช่ Node** (performance — ดู architecture ข้อ 7)

```gdscript
# ✅ ถูก
static func attack_of(card: Dictionary) -> float:
    var d: CardData = Content.card(card.data_id)
    return d.attack * pow(1.0 + d.growth_attack, card.level - 1)

# ❌ ผิด — hardcode, ไม่ typed, engine รู้จักชื่อการ์ด
static func attack_of(card):
    if card.data_id == "swordsman": return 4.0 * card.level
```

---

## ⚠️ Performance Budget (ข้อจำกัดที่กำหนดสถาปัตยกรรม)

ท้ายเกมมี **300+ ยูนิตพร้อมกัน** ต้องได้ 60 FPS

- ❌ ห้ามสร้าง Node ต่อ 1 ยูนิต → วาดทุกตัวใน `_draw()` ตัวเดียว
- ❌ ห้ามหาเป้าแบบ O(n²) ทุก tick → spatial hash + cache เป้า retarget ทุก 0.2 วิ
- ❌ ห้าม allocate array ใหม่ใน hot loop

---

## Workflow

### ทำงานทีละ Milestone
- ดู `docs/03_MILESTONES.md` — ทำ **ทีละ M** จบแล้วให้ผมกดรันดูก่อน
- **ห้ามทำ M ถัดไปล่วงหน้า** ห้ามเพิ่มฟีเจอร์ที่ยังไม่ถึงคิว
- ถ้า M ไหนใหญ่ ให้ซอยเป็นขั้นย่อยแล้วบอกว่าอยู่ขั้นไหน

### ก่อนส่งงานทุกครั้ง
1. รัน `godot --headless --check-only --script <ไฟล์ที่แก้>` หรือเปิด project ตรวจ parse error
2. ถ้ามีเทสต์ (GUT) ให้รันเทสต์ที่เกี่ยวข้อง
3. ระบุชัดว่า **ทดสอบยังไง** และ **ของเดิมพังไหม**

### สิ่งที่ต้องบอกผมเสมอ
- **ขั้นตอนที่ต้องทำใน Godot editor** (สร้าง scene, ผูก node, ตั้ง main scene, สร้าง `.tres`) — เพราะบางอย่างทำในโค้ดไม่ได้
- path เต็ม `res://...` ทุกไฟล์
- ถ้าต้องตัดสินใจดีไซน์ที่เอกสารไม่ได้ระบุ → เสนอ 2 ทางสั้นๆ แล้วแนะนำมา 1

---

## Delivery Format

```
## ✅ ทำอะไรไป
- ...

## 🖱️ ต้องทำใน Godot editor
- ...

## 🔍 ตรวจแล้ว
- parse: OK
- ทดสอบ: ...
- ของเดิมที่เช็คว่าไม่พัง: ...

## ⚠️ ข้อสมมติ / ตัดสินใจเอง
- ...

## 🐛 เจอปัญหานอก scope (ไม่ได้แก้)
- ...
```

---

## ❌ ห้ามทำเด็ดขาด

- ห้าม refactor ส่วนที่ไม่ได้ขอ
- ห้ามเพิ่มฟีเจอร์ "เผื่อไว้" ที่ยังไม่มีใครขอ
- ห้าม rewrite ไฟล์ทั้งไฟล์ในเมื่อแก้ไม่กี่บรรทัดก็พอ
- ห้ามส่งโค้ดที่ยังไม่ได้ตรวจ parse
- ห้ามใส่ logic เกมใน `scenes/*.gd`
- ห้าม hardcode ตัวเลขสมดุลในสคริปต์

---

## ภาษา
คุยกับผมเป็น **ไทยผสมอังกฤษ** (ไทยอธิบาย, อังกฤษสำหรับศัพท์เทคนิค/โค้ด)
อธิบายโค้ดสั้นๆ พร้อมเหตุผล — ไม่ต้องอธิบายพื้นฐาน Godot ทั่วไป แต่ **2D-specific ช่วยอธิบายหน่อย** (ผมเคยทำแต่ 3D)

เวลาสร้าง .tres ของการ์ด ให้ยึด stat และความสามารถจาก docs/04_CARD_REFERENCE.md เป๊ะ ถ้าไม่ตรงให้ถามก่อน"