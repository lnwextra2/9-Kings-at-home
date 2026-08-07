class_name EffectData
extends Resource
## Tier 1 — declarative effect (คลิกใน editor ไม่ต้องเขียนโค้ด)

enum Trigger { END_TURN, ON_DEATH, ON_SPAWN, ON_UPGRADE, ON_KILL }
enum Action { GRANT_GOLD, MODIFY_STAT, UPGRADE_RANDOM, SPAWN_EXTRA, DAMAGE_AREA, LEVEL_UP }
enum Target { SELF, NEIGHBORS_4, DIAGONALS_4, RANDOM_CARD, ALL_CARDS, SAME_COLOR, RANDOM_NEIGHBOR }

@export var trigger: Trigger = Trigger.END_TURN
@export var action: Action = Action.GRANT_GOLD
@export var target: Target = Target.SELF
@export var value: float = 3.0
@export var scales_with_level: bool = true   # value × level
@export var stat_name: StringName = &""      # ใช้เมื่อ action = MODIFY_STAT
@export var is_percent: bool = true          # MODIFY_STAT: true = ×(1+value) ทบต้น, false = +value flat
