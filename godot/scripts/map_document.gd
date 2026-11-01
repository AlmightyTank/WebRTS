extends RefCounted
## Versioned battlefield map. Terrain rows are digit strings so files stay diffable.
const FORMAT := "meridian-warfront-map"
const VERSION := 1
const TILE_W := 128
const TILE_H := 64
const TERRAIN_KIND_COUNT := 10
const TERRAIN_WATER := 6
const TERRAIN_SAND := 7
const TERRAIN_ORE := 8
const TERRAIN_GEM := 9
const ELEVATION_LEVELS := 4
const ELEVATION_RISE := 24
const MIN_SIZE := 3
const MAX_SIZE := 256
const OBSTACLE_NAMES: PackedStringArray = ["tree", "rock", "debris", "derrick"]
const REQUIRED_KEYS: PackedStringArray = [
	"format", "version", "name", "width", "height", "tile_size", "terrain", "obstacles", "headquarters"
]
const OPTIONAL_KEYS: PackedStringArray = ["elevation", "starts", "camera"]

var map_name := "untitled"
var width := 64
var height := 64
var terrain := PackedInt32Array()
var elevation := PackedInt32Array()
var headquarters := Vector2i(32, 32)
var starts: Array = []
var camera_focus := Vector2i(-1, -1)
var last_error := ""
var _obstacles: Dictionary = {}


func setup(map_width: int, map_height: int, next_name: String, fill: int = 0) -> void:
	map_name = next_name
	width = map_width
	height = map_height
	terrain = PackedInt32Array()
	terrain.resize(width * height)
	terrain.fill(fill)
	elevation = PackedInt32Array()
	elevation.resize(width * height)
	elevation.fill(0)
	_obstacles = {}
	headquarters = Vector2i(width / 2, height / 2)
	starts = []
	camera_focus = Vector2i(-1, -1)
	last_error = ""


func in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < width and cell.y < height


func terrain_at(cell: Vector2i) -> int:
	return terrain[cell.y * width + cell.x]


func set_terrain(cell: Vector2i, kind: int) -> bool:
	last_error = ""
	if not in_bounds(cell):
		last_error = "Cell is outside the map."
		return false
	if kind < 0 or kind >= TERRAIN_KIND_COUNT:
		last_error = "Terrain kind must be 0 through %d." % [TERRAIN_KIND_COUNT - 1]
		return false
	terrain[cell.y * width + cell.x] = kind
	return true


func elevation_at(cell: Vector2i) -> int:
	return elevation[cell.y * width + cell.x]


func set_elevation(cell: Vector2i, level: int) -> bool:
	last_error = ""
	if not in_bounds(cell):
		last_error = "Cell is outside the map."
		return false
	if level < 0 or level >= ELEVATION_LEVELS:
		last_error = "Elevation must be 0 through 3."
		return false
	elevation[cell.y * width + cell.x] = level
	return true


func obstacle_at(cell: Vector2i) -> int:
	if not _obstacles.has(cell):
		return -1
	return int(_obstacles[cell])


func set_obstacle(cell: Vector2i, kind: int) -> bool:
	last_error = ""
	if not in_bounds(cell):
		last_error = "Cell is outside the map."
		return false
	if headquarters_covers(cell):
		last_error = "That cell is inside the headquarters footprint."
		return false
	if spawn_covers(cell):
		last_error = "That cell is inside a starting footprint."
		return false
	if kind == -1:
		_obstacles.erase(cell)
		return true
	if kind < 0 or kind >= OBSTACLE_NAMES.size():
		last_error = "Unknown obstacle kind."
		return false
	_obstacles[cell] = kind
	return true


func headquarters_covers(cell: Vector2i) -> bool:
	return _footprint_covers(headquarters, cell)


func all_spawns() -> Array:
	var cells: Array = [headquarters]
	for start in starts:
		var cell := start as Vector2i
		if cell != headquarters:
			cells.append(cell)
	return cells


func spawn_covers(cell: Vector2i) -> bool:
	for start in all_spawns():
		if _footprint_covers(start as Vector2i, cell):
			return true
	return false


func focus_cell() -> Vector2i:
	if camera_focus.x >= 0:
		return camera_focus
	return headquarters


func _footprint_covers(center: Vector2i, cell: Vector2i) -> bool:
	return absi(cell.x - center.x) <= 1 and absi(cell.y - center.y) <= 1


func _footprints_overlap(a: Vector2i, b: Vector2i) -> bool:
	return absi(a.x - b.x) <= 2 and absi(a.y - b.y) <= 2


func headquarters_fits(cell: Vector2i) -> bool:
	return cell.x >= 1 and cell.y >= 1 and cell.x <= width - 2 and cell.y <= height - 2


func set_headquarters(cell: Vector2i) -> bool:
	last_error = ""
	if not headquarters_fits(cell):
		last_error = "Headquarters footprint must stay inside the map."
		return false
	headquarters = cell
	for y in range(cell.y - 1, cell.y + 2):
		for x in range(cell.x - 1, cell.x + 2):
			_obstacles.erase(Vector2i(x, y))
	return true


func obstacle_records() -> Array:
	var records: Array = []
	for cell in _obstacles.keys():
		var grid_cell := cell as Vector2i
		records.append({"x": grid_cell.x, "y": grid_cell.y, "kind": int(_obstacles[cell])})
	records.sort_custom(_obstacle_before)
	return records


func terrain_rows() -> PackedStringArray:
	return _digit_rows(terrain)


func elevation_rows() -> PackedStringArray:
	return _digit_rows(elevation)


func _digit_rows(values: PackedInt32Array) -> PackedStringArray:
	var rows := PackedStringArray()
	for y in range(height):
		var row := ""
		for x in range(width):
			row += str(values[y * width + x])
		rows.append(row)
	return rows


func matches(other) -> bool:
	if map_name != other.map_name or width != other.width or height != other.height:
		return false
	if headquarters != other.headquarters or camera_focus != other.camera_focus:
		return false
	if terrain != other.terrain or elevation != other.elevation:
		return false
	if all_spawns() != other.all_spawns():
		return false
	return obstacle_records() == other.obstacle_records()


func to_dictionary() -> Dictionary:
	var exported_obstacles: Array = []
	for record in obstacle_records():
		exported_obstacles.append({
			"x": record.x,
			"y": record.y,
			"kind": OBSTACLE_NAMES[int(record.kind)],
		})
	var rows: Array = []
	for row in terrain_rows():
		rows.append(row)
	var heights: Array = []
	for row in elevation_rows():
		heights.append(row)
	var payload := {
		"format": FORMAT,
		"version": VERSION,
		"name": map_name,
		"width": width,
		"height": height,
		"tile_size": [TILE_W, TILE_H],
		"terrain": rows,
		"elevation": heights,
		"obstacles": exported_obstacles,
		"headquarters": {"x": headquarters.x, "y": headquarters.y},
	}
	if not starts.is_empty():
		var exported_starts: Array = []
		for start in starts:
			var cell := start as Vector2i
			exported_starts.append({"x": cell.x, "y": cell.y})
		payload["starts"] = exported_starts
	if camera_focus.x >= 0:
		payload["camera"] = {"x": camera_focus.x, "y": camera_focus.y}
	return payload


func save_to_file(path: String) -> Error:
	last_error = ""
	var payload := to_dictionary()
	var check: Dictionary = from_dictionary(payload)
	if not bool(check.ok):
		last_error = str(check.error)
		return ERR_INVALID_DATA
	var directory := path.get_base_dir()
	if not directory.is_empty() and DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory)) != OK:
		last_error = "Could not create the map directory."
		return ERR_CANT_CREATE
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		last_error = "Could not write %s (%s)." % [path, error_string(FileAccess.get_open_error())]
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(payload, "\t", true) + "\n")
	return OK


static func load_from_file(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return _invalid("Map file does not exist.")
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return _invalid("Could not read the map file.")
	return from_json(file.get_as_text())


static func from_json(text: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(text)
	if parsed == null:
		return _invalid("Map file is not valid JSON.")
	return from_dictionary(parsed)


static func from_dictionary(data: Variant) -> Dictionary:
	if typeof(data) != TYPE_DICTIONARY:
		return _invalid("Map root must be an object.")
	var root: Dictionary = data
	for key in root.keys():
		var field_name := String(key)
		if not REQUIRED_KEYS.has(field_name) and not OPTIONAL_KEYS.has(field_name):
			return _invalid("Unknown map field '%s'." % field_name)
	for key in REQUIRED_KEYS:
		if not root.has(key):
			return _invalid("Map is missing '%s'." % key)
	if str(root.format) != FORMAT:
		return _invalid("Unsupported map format.")
	var version: Variant = _whole_number(root.version)
	if version == null or int(version) != VERSION:
		return _invalid("Unsupported map version.")
	if typeof(root.name) != TYPE_STRING or not _valid_name(str(root.name)):
		return _invalid("Map name must be 1-48 letters, numbers, spaces, hyphens, or underscores.")
	var map_width = _whole_number(root.width)
	var map_height = _whole_number(root.height)
	if map_width == null or map_height == null:
		return _invalid("Map width and height must be whole numbers.")
	if int(map_width) < MIN_SIZE or int(map_height) < MIN_SIZE or int(map_width) > MAX_SIZE or int(map_height) > MAX_SIZE:
		return _invalid("Map width and height must be from %d to %d." % [MIN_SIZE, MAX_SIZE])
	if typeof(root.tile_size) != TYPE_ARRAY or root.tile_size.size() != 2:
		return _invalid("Tile size must be [%d, %d]." % [TILE_W, TILE_H])
	var tile_w = _whole_number(root.tile_size[0])
	var tile_h = _whole_number(root.tile_size[1])
	if tile_w == null or tile_h == null or int(tile_w) != TILE_W or int(tile_h) != TILE_H:
		return _invalid("Tile size must be [%d, %d]." % [TILE_W, TILE_H])
	if typeof(root.headquarters) != TYPE_DICTIONARY:
		return _invalid("Headquarters must be an object with x and y.")
	var hq: Dictionary = root.headquarters
	for key in hq.keys():
		if String(key) != "x" and String(key) != "y":
			return _invalid("Unknown headquarters field '%s'." % String(key))
	if not hq.has("x") or not hq.has("y"):
		return _invalid("Headquarters must include x and y.")
	var hq_x = _whole_number(hq.x)
	var hq_y = _whole_number(hq.y)
	if hq_x == null or hq_y == null:
		return _invalid("Headquarters coordinates must be whole numbers.")
	var document := new()
	document.setup(int(map_width), int(map_height), str(root.name))
	if not document.headquarters_fits(Vector2i(int(hq_x), int(hq_y))):
		return _invalid("Headquarters footprint must stay inside the map.")
	document.headquarters = Vector2i(int(hq_x), int(hq_y))
	if root.has("starts"):
		var starts_error := _read_starts(document, root.starts)
		if starts_error != "":
			return _invalid(starts_error)
	var terrain_count := _sequence_size(root.terrain)
	if terrain_count != document.height:
		return _invalid("Terrain must have one row string per map row.")
	for y in range(document.height):
		var row: Variant = root.terrain[y]
		if typeof(row) != TYPE_STRING or str(row).length() != document.width:
			return _invalid("Terrain row %d must be a %d-character digit string." % [y, document.width])
		var digits := str(row)
		for x in range(document.width):
			var code := digits.unicode_at(x)
			if code < 48 or code > 48 + TERRAIN_KIND_COUNT - 1:
				return _invalid("Terrain row %d column %d must be a digit 0-%d." % [y, x, TERRAIN_KIND_COUNT - 1])
			document.terrain[y * document.width + x] = code - 48
	if typeof(root.obstacles) != TYPE_ARRAY:
		return _invalid("Obstacles must be an array.")
	for index in range(root.obstacles.size()):
		var entry: Variant = root.obstacles[index]
		if typeof(entry) != TYPE_DICTIONARY:
			return _invalid("Obstacle %d must be an object." % index)
		var obstacle: Dictionary = entry
		for key in obstacle.keys():
			var field := String(key)
			if field != "x" and field != "y" and field != "kind":
				return _invalid("Obstacle %d has unknown field '%s'." % [index, field])
		if not obstacle.has("x") or not obstacle.has("y") or not obstacle.has("kind"):
			return _invalid("Obstacle %d must include x, y, and kind." % index)
		var cell_x = _whole_number(obstacle.x)
		var cell_y = _whole_number(obstacle.y)
		if cell_x == null or cell_y == null:
			return _invalid("Obstacle %d coordinates must be whole numbers." % index)
		if typeof(obstacle.kind) != TYPE_STRING or OBSTACLE_NAMES.find(str(obstacle.kind)) == -1:
			return _invalid("Obstacle %d kind must be tree, rock, debris, or derrick." % index)
		var cell := Vector2i(int(cell_x), int(cell_y))
		if not document.in_bounds(cell):
			return _invalid("Obstacle %d is outside the map." % index)
		if document.headquarters_covers(cell):
			return _invalid("Obstacle %d overlaps the headquarters footprint." % index)
		if document.spawn_covers(cell):
			return _invalid("Obstacle %d overlaps a starting footprint." % index)
		if document._obstacles.has(cell):
			return _invalid("Obstacle %d duplicates another obstacle cell." % index)
		document._obstacles[cell] = OBSTACLE_NAMES.find(str(obstacle.kind))
	if root.has("camera"):
		var camera_error := _read_camera(document, root.camera)
		if camera_error != "":
			return _invalid(camera_error)
	if root.has("elevation"):
		var elevation_error := _read_digit_rows(document, root.elevation, 0, ELEVATION_LEVELS - 1, "Elevation")
		if elevation_error != "":
			return _invalid(elevation_error)
	return {"ok": true, "error": "", "document": document}


static func _invalid(message: String) -> Dictionary:
	return {"ok": false, "error": message, "document": null}


static func _read_starts(document, value: Variant) -> String:
	if typeof(value) != TYPE_ARRAY:
		return "Starts must be an array."
	var seen: Array = []
	for index in range(value.size()):
		var entry: Variant = value[index]
		if typeof(entry) != TYPE_DICTIONARY:
			return "Start %d must be an object." % index
		var start: Dictionary = entry
		for key in start.keys():
			var field := String(key)
			if field != "x" and field != "y" and field != "team":
				return "Start %d has unknown field '%s'." % [index, field]
		if not start.has("x") or not start.has("y"):
			return "Start %d must include x and y." % index
		var cell_x = _whole_number(start.x)
		var cell_y = _whole_number(start.y)
		if cell_x == null or cell_y == null:
			return "Start %d coordinates must be whole numbers." % index
		var cell := Vector2i(int(cell_x), int(cell_y))
		if not document.headquarters_fits(cell):
			return "Start %d footprint must stay inside the map." % index
		if document._footprints_overlap(document.headquarters, cell) or _seen_overlap(document, seen, cell):
			return "Start %d overlaps another starting footprint." % index
		seen.append(cell)
		document.starts.append(cell)
	return ""


static func _seen_overlap(document, seen: Array, cell: Vector2i) -> bool:
	for prior in seen:
		if document._footprints_overlap(prior as Vector2i, cell):
			return true
	return false


static func _read_camera(document, value: Variant) -> String:
	if typeof(value) != TYPE_DICTIONARY:
		return "Camera must be an object with x and y."
	var camera: Dictionary = value
	for key in camera.keys():
		if String(key) != "x" and String(key) != "y":
			return "Unknown camera field '%s'." % String(key)
	if not camera.has("x") or not camera.has("y"):
		return "Camera must include x and y."
	var cell_x = _whole_number(camera.x)
	var cell_y = _whole_number(camera.y)
	if cell_x == null or cell_y == null:
		return "Camera coordinates must be whole numbers."
	var cell := Vector2i(int(cell_x), int(cell_y))
	if not document.in_bounds(cell):
		return "Camera target is outside the map."
	document.camera_focus = cell
	return ""


static func _read_digit_rows(document, rows_value: Variant, min_digit: int, max_digit: int, label: String) -> String:
	var row_count := _sequence_size(rows_value)
	if row_count != document.height:
		return "%s must have one row string per map row." % label
	for y in range(document.height):
		var row: Variant = rows_value[y]
		if typeof(row) != TYPE_STRING or str(row).length() != document.width:
			return "%s row %d must be a %d-character digit string." % [label, y, document.width]
		var digits := str(row)
		for x in range(document.width):
			var code := digits.unicode_at(x)
			if code < 48 + min_digit or code > 48 + max_digit:
				return "%s row %d column %d must be a digit %d-%d." % [label, y, x, min_digit, max_digit]
			document.elevation[y * document.width + x] = code - 48
	return ""


static func _sequence_size(value: Variant) -> int:
	var kind := typeof(value)
	if kind == TYPE_ARRAY or kind == TYPE_PACKED_STRING_ARRAY:
		return value.size()
	return -1


static func _whole_number(value: Variant) -> Variant:
	if typeof(value) == TYPE_INT:
		return value
	if typeof(value) == TYPE_FLOAT and is_equal_approx(float(value), floor(float(value))):
		return int(value)
	return null


static func _valid_name(value: String) -> bool:
	if value.length() < 1 or value.length() > 48:
		return false
	if value.begins_with(" ") or value.ends_with(" "):
		return false
	for i in range(value.length()):
		var code := value.unicode_at(i)
		var allowed := (code >= 48 and code <= 57) or (code >= 65 and code <= 90) or (code >= 97 and code <= 122) or code == 32 or code == 45 or code == 95
		if not allowed:
			return false
	return true


static func _obstacle_before(a: Dictionary, b: Dictionary) -> bool:
	if int(a.y) == int(b.y):
		return int(a.x) < int(b.x)
	return int(a.y) < int(b.y)
