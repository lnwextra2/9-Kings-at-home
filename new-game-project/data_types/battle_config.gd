class_name BattleConfig
extends Resource
## ค่าสนามรบ + การ map กระดาน→ตำแหน่งในสนาม — จูนใน editor (default_battle.tres)

@export_group("Field")
@export var width: float = 1000.0
@export var height: float = 560.0

@export_group("Our Side (board -> field)")
@export var our_x0: float = 120.0        # x ของ column 0
@export var our_col_dx: float = 70.0     # ระยะ x ต่อ column
@export var our_y0: float = 90.0         # y ของ row 0
@export var our_row_dy: float = 92.0     # ระยะ y ต่อ row
@export var soldier_spread: float = 18.0 # กระจายทหารรอบจุด spawn

@export_group("Enemy Spawn")
@export var enemy_x: float = 940.0
@export var enemy_y_margin: float = 40.0
@export var enemy_spread: float = 26.0

@export_group("Our Formation (soldiers + wall)")
@export var front_x: float = 520.0       # แนวหน้าสุดของทหาร (แถวแรก)
@export var col_dx: float = 24.0         # ระยะห่างระหว่างแถว (ลึกไปทางฐาน)
@export var row_dy: float = 24.0         # ระยะห่างระหว่างตัวในแถวเดียวกัน
@export var max_cols: int = 6            # จำนวนแถวสูงสุด (กันสปอว์นไกลไปฝั่งศัตรู; เกินแล้วบีบระยะ)
@export var wall_x: float = 380.0        # ตำแหน่งกำแพง (หลังทหาร)
@export var bomb_scatter: float = 55.0   # Trapper วางระเบิดกระจายรอบตัวรัศมีนี้
@export var form_duration: float = 2.0   # ทหารเดินจากช่องมาตั้งแถวใช้เวลา (วิ) ถึงพร้อมกัน ก่อนเริ่มสู้

@export_group("Combat")
@export var base_touch_radius: float = 28.0   # ศัตรูเข้าใกล้ฐานเท่านี้ = แตะ (จบเวฟ)
@export var retarget_interval: float = 0.2
@export var projectile_speed: float = 600.0   # เร็วขึ้น (ballistic เส้นตรง)
@export var projectile_hit_radius: float = 10.0   # กระสุนปกติตก = โดนศัตรูในรัศมีนี้ (ถ้าไม่มี splash)
@export var projectile_pierce_radius: float = 12.0 # ความกว้างเส้นกระสุนทะลุ (บาริสต้า)
@export var ranged_min_range: float = 60.0    # attack_range เกินนี้ = ยิง projectile (ranged)
@export var hash_cell: float = 64.0           # ขนาด cell ของ spatial hash (หาเป้า)
@export var crit_mult: float = 2.0            # โจมตีคริ = ดาเมจ × ค่านี้
