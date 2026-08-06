extends Node
## Autoload "Content" — สแกนโหลด CardData ทั้งหมดจาก data/cards ตอนเปิดเกม
## เพิ่มการ์ด = วางไฟล์ .tres ในโฟลเดอร์ แล้วเกมเห็นเอง ไม่ต้องลงทะเบียน

const CARDS_DIR := "res://data/cards"

var _cards: Dictionary = {}   # StringName -> CardData


func _ready() -> void:
    _scan(CARDS_DIR)
    print("[Content] loaded %d cards" % _cards.size())


func card(id: StringName) -> CardData:
    return _cards.get(id)


func all() -> Array:
    return _cards.values()


func by_color(c: StringName) -> Array:
    var out: Array = []
    for d in _cards.values():
        if d.color == c:
            out.append(d)
    return out


func by_kind(k: int) -> Array:
    var out: Array = []
    for d in _cards.values():
        if d.kind == k:
            out.append(d)
    return out


func _scan(dir_path: String) -> void:
    var dir := DirAccess.open(dir_path)
    if dir == null:
        return
    dir.list_dir_begin()
    var entry := dir.get_next()
    while entry != "":
        var full := dir_path + "/" + entry
        if dir.current_is_dir():
            if not entry.begins_with("."):
                _scan(full)
        elif entry.ends_with(".tres"):
            var res := load(full)
            if res is CardData:
                _cards[res.id] = res
        entry = dir.get_next()
    dir.list_dir_end()
