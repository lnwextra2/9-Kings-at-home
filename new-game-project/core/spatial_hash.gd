class_name SpatialHash
extends RefCounted
## หาเป้าเร็ว — แบ่งสนามเป็นตาราง cell เทียบเฉพาะช่องข้างเคียง (แทน brute-force O(n²))
## เก็บเฉพาะยูนิต alive + targetable (ทั้ง 2 ทีม); query กรอง team ตอนหา
## key เป็น int (เลี่ยง Vector2i alloc ใน hot loop); ไม่ใช้ range() (เลี่ยง array alloc)

const OFS := 512
const STRIDE := 4096

var _cell: float
var _b: Dictionary = {}   # int key -> Array[int]


func _init(cell_size: float) -> void:
    _cell = cell_size


static func _key(kx: int, ky: int) -> int:
    return (kx + OFS) * STRIDE + (ky + OFS)


static func build(units: Array, cell_size: float) -> SpatialHash:
    var h := SpatialHash.new(cell_size)
    var b := h._b
    for i in units.size():
        var u: Dictionary = units[i]
        if not u.alive or not u.targetable:
            continue
        var key := _key(int(floor(u.x / cell_size)), int(floor(u.y / cell_size)))
        var arr = b.get(key)
        if arr == null:
            arr = []
            b[key] = arr
        arr.append(i)
    return h


## index ศัตรู (team ตรงข้าม) ที่ใกล้สุด — ขยาย ring จนเจอ แล้วเผื่ออีก 1 ring
func nearest_enemy(units: Array, u: Dictionary) -> int:
    var cx := int(floor(u.x / _cell))
    var cy := int(floor(u.y / _cell))
    var team: int = u.team
    var ux: float = u.x
    var uy: float = u.y
    var best := -1
    var best_d := INF
    var found_at := -1
    var ring := 0
    while ring <= 64:
        var lo_x := cx - ring
        var hi_x := cx + ring
        var lo_y := cy - ring
        var hi_y := cy + ring
        var gx := lo_x
        while gx <= hi_x:
            var on_x_edge := gx == lo_x or gx == hi_x
            var gy := lo_y
            while gy <= hi_y:
                if on_x_edge or gy == lo_y or gy == hi_y:
                    var arr = _b.get((gx + OFS) * STRIDE + (gy + OFS))
                    if arr != null:
                        for i in arr:
                            var o: Dictionary = units[i]
                            if o.team != team:
                                var dx: float = o.x - ux
                                var dy: float = o.y - uy
                                var d2: float = dx * dx + dy * dy
                                if d2 < best_d:
                                    best_d = d2
                                    best = i
                gy += 1
            gx += 1
        if best != -1 and found_at == -1:
            found_at = ring
        if found_at != -1 and ring >= found_at + 1:
            break
        ring += 1
    return best
