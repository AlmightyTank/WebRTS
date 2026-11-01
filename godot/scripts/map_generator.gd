extends RefCounted
## Rebuilds the original v0.1 procedural battlefield as a map document.
const MAP_DOCUMENT := preload("res://scripts/map_document.gd")
const WIDTH := 64
const HEIGHT := 64


static func procedural_terrain_kind(x: int, y: int) -> int:
	if abs(x - y - 9) <= 1:
		return 4
	if x > 17 and x < 35 and y > 19 and y < 33:
		return 3 if (x + y) % 7 == 0 else 2
	return posmod(x * 13 + y * 7 + x * y, 4) if (x + y) % 11 == 0 else posmod(x * 3 + y * 5, 3)


static func procedural_skirmish():
	var document = MAP_DOCUMENT.new()
	document.setup(WIDTH, HEIGHT, "procedural-skirmish")
	document.headquarters = Vector2i(WIDTH / 2, HEIGHT / 2)
	for y in range(HEIGHT):
		for x in range(WIDTH):
			document.set_terrain(Vector2i(x, y), procedural_terrain_kind(x, y))
	for y in range(2, HEIGHT - 2):
		for x in range(2, WIDTH - 2):
			if abs(x - WIDTH / 2) <= 3 and abs(y - HEIGHT / 2) <= 3:
				continue
			if procedural_terrain_kind(x, y) == 4:
				continue
			var hash_value: int = posmod(x * 73856093 ^ y * 19349663, 997)
			if hash_value >= 22:
				continue
			document.set_obstacle(Vector2i(x, y), hash_value % 3)
	return document
