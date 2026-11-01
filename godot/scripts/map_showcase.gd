extends RefCounted
## Authored elevation layouts. Camera-facing cliffs drop toward larger map Y.
const MAP_DOCUMENT := preload("res://scripts/map_document.gd")
const SIZE := 24


static func escarpment():
	var document = MAP_DOCUMENT.new()
	document.setup(SIZE, SIZE, "elevation-escarpment")
	document.headquarters = Vector2i(12, 4)
	for y in range(SIZE):
		for x in range(SIZE):
			var level := 2 if y < 8 else (1 if y < 12 else 0)
			document.set_elevation(Vector2i(x, y), level)
			var kind := 0
			if y >= 16 and y <= 17:
				kind = 4
			elif level == 2 and (x + y) % 8 == 0:
				kind = 3
			elif (x + y) % 4 == 0:
				kind = 1
			document.set_terrain(Vector2i(x, y), kind)
	document.set_obstacle(Vector2i(4, 18), 0)
	document.set_obstacle(Vector2i(18, 20), 1)
	document.set_obstacle(Vector2i(7, 3), 0)
	document.set_obstacle(Vector2i(18, 5), 2)
	return document


static func basin():
	var document = MAP_DOCUMENT.new()
	document.setup(SIZE, SIZE, "elevation-basin")
	document.headquarters = Vector2i(12, 12)
	for y in range(SIZE):
		for x in range(SIZE):
			var distance := maxi(absi(x - 12), absi(y - 12))
			var level := 2 if distance >= 9 else (1 if distance >= 6 else 0)
			document.set_elevation(Vector2i(x, y), level)
			var kind := 3 if level == 1 else (1 if level == 0 and (x + y) % 5 == 0 else 0)
			document.set_terrain(Vector2i(x, y), kind)
	document.set_obstacle(Vector2i(2, 12), 0)
	document.set_obstacle(Vector2i(12, 2), 1)
	document.set_obstacle(Vector2i(21, 16), 2)
	return document


static func mercy_bay():
	var document = MAP_DOCUMENT.new()
	document.setup(64, 64, "mercy-bay")
	for y in range(64):
		for x in range(64):
			_paint_mercy_land(document, x, y)
	_paint_mercy_beaches(document)
	var pads: Array = []
	for seed in [Vector2i(16, 30), Vector2i(22, 16), Vector2i(44, 16), Vector2i(50, 30), Vector2i(44, 36), Vector2i(20, 36)]:
		var pad: Vector2i = _find_pad(document, seed, pads)
		if pad.x < 0:
			continue
		pads.append(pad)
	if pads.is_empty():
		document.headquarters = Vector2i(32, 30)
	else:
		document.headquarters = pads[0]
		for index in range(1, pads.size()):
			document.starts.append(pads[index])
	document.camera_focus = Vector2i(32, 30)
	_stamp_field(document, Vector2i(24, 22), Vector2i(4, 3), MAP_DOCUMENT.TERRAIN_ORE)
	_stamp_field(document, Vector2i(36, 28), Vector2i(4, 3), MAP_DOCUMENT.TERRAIN_ORE)
	_stamp_field(document, Vector2i(28, 32), Vector2i(5, 2), MAP_DOCUMENT.TERRAIN_ORE)
	_stamp_field(document, Vector2i(40, 20), Vector2i(3, 3), MAP_DOCUMENT.TERRAIN_ORE)
	_stamp_field(document, Vector2i(20, 26), Vector2i(3, 2), MAP_DOCUMENT.TERRAIN_ORE)
	_stamp_field(document, Vector2i(44, 32), Vector2i(3, 2), MAP_DOCUMENT.TERRAIN_ORE)
	_stamp_field(document, Vector2i(30, 16), Vector2i(3, 2), MAP_DOCUMENT.TERRAIN_ORE)
	_stamp_field(document, Vector2i(34, 36), Vector2i(4, 2), MAP_DOCUMENT.TERRAIN_ORE)
	_stamp_field(document, Vector2i(16, 22), Vector2i(2, 3), MAP_DOCUMENT.TERRAIN_ORE)
	_stamp_field(document, Vector2i(48, 22), Vector2i(2, 3), MAP_DOCUMENT.TERRAIN_ORE)
	_stamp_field(document, Vector2i(31, 17), Vector2i(2, 2), MAP_DOCUMENT.TERRAIN_GEM)
	_stamp_field(document, Vector2i(28, 20), Vector2i(2, 2), MAP_DOCUMENT.TERRAIN_GEM)
	_stamp_field(document, Vector2i(35, 20), Vector2i(2, 2), MAP_DOCUMENT.TERRAIN_GEM)
	_stamp_field(document, Vector2i(32, 23), Vector2i(2, 2), MAP_DOCUMENT.TERRAIN_GEM)
	_stamp_clearing(document, Vector2i(14, 27), Vector2i(6, 2))
	_stamp_clearing(document, Vector2i(40, 25), Vector2i(6, 2))
	_dress_mercy_bay(document, pads)
	return document


static func _paint_mercy_land(document, x: int, y: int) -> void:
	var cell := Vector2i(x, y)
	if not _mercy_island(x, y) or _mercy_inlet(x, y):
		document.set_terrain(cell, MAP_DOCUMENT.TERRAIN_WATER)
		document.set_elevation(cell, 0)
		return
	if _mercy_highland(x, y):
		document.set_elevation(cell, 2)
		document.set_terrain(cell, 1 if (x + y) % 5 == 0 else 0)
		return
	document.set_elevation(cell, 1)
	document.set_terrain(cell, 0)


static func _mercy_island(x: int, y: int) -> bool:
	var nx := (float(x) - 31.5) / 26.5
	var ny := (float(y) - 26.0) / 21.5
	var wobble := 0.035 * sin(float(x) * 0.55) + 0.025 * sin(float(y) * 0.72)
	var limit := 1.0 + wobble
	return nx * nx + ny * ny <= limit * limit


static func _mercy_inlet(x: int, y: int) -> bool:
	if y < 33:
		return false
	var along := (float(y) - 33.0) / 22.0
	var half := 2.2 + along * along * 12.0
	var center := 32.0 + 1.2 * sin((float(y) - 33.0) * 0.18)
	return absf(float(x) - center) <= half


static func _mercy_highland(x: int, y: int) -> bool:
	var zones: Array[Vector4] = [
		Vector4(32.0, 18.0, 8.5, 6.0),
		Vector4(18.0, 24.0, 4.5, 3.2),
		Vector4(46.0, 24.0, 4.5, 3.2),
	]
	for index in zones.size():
		var zone: Vector4 = zones[index]
		var hx := (float(x) - zone.x) / zone.z
		var hy := (float(y) - zone.y) / zone.w
		if hx * hx + hy * hy <= 1.0:
			return true
	return false


static func _paint_mercy_beaches(document) -> void:
	for y in range(64):
		for x in range(64):
			var cell := Vector2i(x, y)
			if document.terrain_at(cell) == MAP_DOCUMENT.TERRAIN_WATER or document.elevation_at(cell) >= 2:
				continue
			if _mercy_near_water(document, cell, 2):
				document.set_elevation(cell, 0)
				document.set_terrain(cell, MAP_DOCUMENT.TERRAIN_SAND)


static func _mercy_near_water(document, cell: Vector2i, reach: int) -> bool:
	for y in range(cell.y - reach, cell.y + reach + 1):
		for x in range(cell.x - reach, cell.x + reach + 1):
			var neighbor := Vector2i(x, y)
			if not document.in_bounds(neighbor) or document.terrain_at(neighbor) == MAP_DOCUMENT.TERRAIN_WATER:
				return true
	return false


static func _stamp_clearing(document, origin: Vector2i, size: Vector2i) -> void:
	for y in range(size.y):
		for x in range(size.x):
			var cell := origin + Vector2i(x, y)
			if not _open_land(document, cell) or document.elevation_at(cell) == 0:
				continue
			var kind: int = document.terrain_at(cell)
			if kind == 0 or kind == 1:
				document.set_terrain(cell, 4)


static func _dress_mercy_bay(document, pads: Array) -> void:
	for pad in pads:
		var center := pad as Vector2i
		for offset in [Vector2i(4, 0), Vector2i(-4, 1), Vector2i(0, 4), Vector2i(3, -3)]:
			var cell: Vector2i = center + offset
			if _prop_site(document, cell, true):
				document.set_obstacle(cell, 3)
				break
	var derricks := 0
	for y in range(64):
		for x in range(64):
			if (x * 5 + y * 3) % 19 != 0:
				continue
			var cell := Vector2i(x, y)
			if not _prop_site(document, cell, true):
				continue
			if not _mercy_near_water(document, cell, 3):
				continue
			document.set_obstacle(cell, 3)
			derricks += 1
			if derricks >= 16:
				break
		if derricks >= 16:
			break
	var groves: Array[Vector2i] = [
		Vector2i(26, 12), Vector2i(38, 12), Vector2i(22, 20), Vector2i(42, 18),
		Vector2i(26, 28), Vector2i(18, 34), Vector2i(46, 34), Vector2i(34, 14),
	]
	var clump: Array[Vector2i] = [Vector2i(0, 0), Vector2i(2, 0), Vector2i(1, 1), Vector2i(0, 2)]
	for grove in groves:
		for offset in clump:
			var spot: Vector2i = grove + offset
			if _prop_site(document, spot, false):
				document.set_obstacle(spot, 0)
	var rocks := 0
	for y in range(64):
		for x in range(64):
			if document.elevation_at(Vector2i(x, y)) != 2 or (x * 2 + y) % 7 != 0:
				continue
			var cell := Vector2i(x, y)
			if _cliff_rim(document, cell) and _prop_site(document, cell, false):
				document.set_obstacle(cell, 1)
				rocks += 1
			if rocks >= 12:
				break
		if rocks >= 12:
			break
	for wreck in [Vector2i(12, 34), Vector2i(52, 34), Vector2i(30, 40), Vector2i(36, 40)]:
		if _prop_site(document, wreck, true):
			document.set_obstacle(wreck, 2)


static func _prop_site(document, cell: Vector2i, allow_sand: bool) -> bool:
	if not _open_land(document, cell):
		return false
	var kind: int = document.terrain_at(cell)
	if kind == MAP_DOCUMENT.TERRAIN_ORE or kind == MAP_DOCUMENT.TERRAIN_GEM or kind == 4:
		return false
	if kind == MAP_DOCUMENT.TERRAIN_SAND:
		return allow_sand
	return kind == 0 or kind == 1 or kind == 3


static func _cliff_rim(document, cell: Vector2i) -> bool:
	for offset in [Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1)]:
		var neighbor: Vector2i = cell + offset
		if not document.in_bounds(neighbor) or document.elevation_at(neighbor) < document.elevation_at(cell):
			return true
	return false


static func _find_pad(document, seed: Vector2i, pads: Array) -> Vector2i:
	for radius in range(0, 10):
		for y in range(seed.y - radius, seed.y + radius + 1):
			for x in range(seed.x - radius, seed.x + radius + 1):
				if maxi(absi(x - seed.x), absi(y - seed.y)) != radius:
					continue
				var cell := Vector2i(x, y)
				if _pad_ok(document, cell, pads):
					return cell
	return Vector2i(-1, -1)


static func _pad_ok(document, center: Vector2i, pads: Array) -> bool:
	if not document.headquarters_fits(center):
		return false
	for prior in pads:
		if document._footprints_overlap(prior as Vector2i, center):
			return false
	var level := -1
	for y in range(-1, 2):
		for x in range(-1, 2):
			var cell := center + Vector2i(x, y)
			if document.terrain_at(cell) == MAP_DOCUMENT.TERRAIN_WATER:
				return false
			var height: int = document.elevation_at(cell)
			if level == -1:
				level = height
			elif height != level:
				return false
	return true


static func _stamp_field(document, origin: Vector2i, size: Vector2i, kind: int) -> void:
	for y in range(size.y):
		for x in range(size.x):
			var cell := origin + Vector2i(x, y)
			if _open_land(document, cell) and document.elevation_at(cell) > 0:
				document.set_terrain(cell, kind)


static func _open_land(document, cell: Vector2i) -> bool:
	if not document.in_bounds(cell):
		return false
	if document.terrain_at(cell) == MAP_DOCUMENT.TERRAIN_WATER:
		return false
	if document.spawn_covers(cell):
		return false
	return document.obstacle_at(cell) < 0


static func hill():
	var document = MAP_DOCUMENT.new()
	document.setup(SIZE, SIZE, "elevation-hill")
	document.headquarters = Vector2i(2, 12)
	for y in range(SIZE):
		for x in range(SIZE):
			var distance := maxi(absi(x - 12), absi(y - 12))
			var level := 3 if distance <= 2 else (2 if distance <= 5 else (1 if distance <= 8 else 0))
			document.set_elevation(Vector2i(x, y), level)
			var kind := 5 if level == 3 else (2 if level == 2 else (3 if level == 1 and (x + y) % 3 == 0 else 0))
			document.set_terrain(Vector2i(x, y), kind)
	document.set_obstacle(Vector2i(12, 4), 0)
	document.set_obstacle(Vector2i(20, 12), 1)
	document.set_obstacle(Vector2i(12, 20), 2)
	return document
