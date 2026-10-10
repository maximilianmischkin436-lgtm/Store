extends StaticBody3D
# Ein Objekt, das auf Treffer reagiert (z.B. Easter Eggs)
var on_hit: Callable

func hit(_dmg: int, _dir: Vector3) -> void:
	if on_hit.is_valid():
		on_hit.call()
