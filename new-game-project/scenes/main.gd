extends Control
## ตัวสลับ phase — M0: โชว์ board + top bar พิสูจน์ว่า config/.tres โหลดได้

const SAMPLE_CARD := "res://data/cards/blue/base_castle.tres"

@onready var _top: Label = $TopBar


func _ready() -> void:
    var st: GameState = Game.state
    var card: CardData = load(SAMPLE_CARD) as CardData
    var card_name: String = card.display_name if card != null else "(โหลดไม่ได้)"
    _top.text = "ชั้น %d  ·  gold %d  ·  HP %d  ·  sample card: %s" % [
        st.floor_num, st.gold, st.base_hp, card_name
    ]
