class_name RunConfig
extends Resource
## ค่าสมดุลรวมของ 1 run — จูนใน editor (default_run.tres) ห้าม hardcode ในสคริปต์

@export_group("Board")
@export var board_cols: int = 5
@export var board_rows: int = 5
@export var unlocked_cols: int = 3   # บล็อกกลางที่ปลดล็อกตอนเริ่ม (กว้าง)
@export var unlocked_rows: int = 3   # บล็อกกลางที่ปลดล็อกตอนเริ่ม (สูง)

@export_group("Run Start")
@export var start_gold: int = 30
@export var base_hp: int = 3         # ชีวิตบ้าน — แพ้เวฟ −1, Boss −3, 0 = จบ Run
