class_name Rng
extends RefCounted
## seeded RNG — ทุกการสุ่มใน sim ต้องผ่านตัวนี้ (deterministic; seedable เต็มตอน M5)

var _rng := RandomNumberGenerator.new()


func seed_with(s: int) -> void:
    _rng.seed = s


func randi_range(a: int, b: int) -> int:
    return _rng.randi_range(a, b)


func randf() -> float:
    return _rng.randf()


func pick(arr: Array) -> Variant:
    return arr[_rng.randi_range(0, arr.size() - 1)]


func shuffle(arr: Array) -> Array:
    var a := arr.duplicate()
    for i in range(a.size() - 1, 0, -1):
        var j := _rng.randi_range(0, i)
        var tmp = a[i]
        a[i] = a[j]
        a[j] = tmp
    return a
