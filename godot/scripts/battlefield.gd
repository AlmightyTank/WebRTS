extends Node2D
## Isometric battlefield rendered from a serialized map document.
const MAP_DOCUMENT := preload("res://scripts/map_document.gd")
const MAP_GENERATOR := preload("res://scripts/map_generator.gd")
const OBSTACLE_SCRIPT := preload("res://scripts/terrain_obstacle.gd")
const COMMAND_CENTER_SCENE: PackedScene = preload("res://scenes/buildings/command_center.tscn")
const TILE_W := 128
const TILE_H := 64
const NEIGHBORS: Array[Vector2i] = [Vector2i(-1, 0), Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1)]
const SHOWCASE_MAPS: PackedStringArray = [
	"res://maps/procedural-skirmish.map.json",
	"res://maps/mercy-bay.map.json",
	"res://maps/elevation-escarpment.map.json",
	"res://maps/elevation-basin.map.json",
	"res://maps/elevation-hill.map.json",
]
const TILE_COLORS := [
	Color("#58764a"), Color("#638051"), Color("#718658"),
	Color("#806c4d"), Color("#858583"), Color("#596d4d"),
	Color("#2e86b5"), Color("#d2bc84"), Color("#c6a04a"), Color("#3fbfa8")
]
const ATLAS_TILE_COUNT := 12
const ATLAS_SHALLOWS := 10
const ATLAS_WATER_ALT := 11

@export var map_path := "res://maps/mercy-bay.map.json"
var camera: Camera2D
var terrain: TileMapLayer
var transitions: TileMapLayer
var actors: Node2D
var headquarters: Node2D
var extra_spawns: Array = []
var map_data
var obstacle_nodes: Dictionary = {}
var level_terrain: Array = []
var level_transitions: Array = []
var cliff_layers: Array = []
var showcase_index := 0
var _layers_ready := false


func _ready() -> void:
	var loaded: Dictionary = MAP_DOCUMENT.load_from_file(map_path)
	var document = loaded.document if bool(loaded.ok) else MAP_GENERATOR.procedural_skirmish()
	if not bool(loaded.ok):
		push_warning("Falling back to the procedural map because %s (%s)" % [map_path, loaded.error])
	apply_map(document)


func apply_map(document, recenter_camera: bool = true) -> void:
	map_data = document
	_ensure_layers()
	for layer in level_terrain:
		layer.clear()
	for layer in level_transitions:
		layer.clear()
	for y in range(map_data.height):
		for x in range(map_data.width):
			_apply_cell(Vector2i(x, y))
	_rebuild_obstacles()
	_place_headquarters()
	_ensure_camera(recenter_camera)
	_queue_cliff_redraw()
	_apply_backdrop()


func paint_elevation(cell: Vector2i, level: int) -> bool:
	if map_data == null or not map_data.set_elevation(cell, level):
		return false
	_apply_cell(cell)
	_queue_cliff_redraw()
	if obstacle_nodes.has(cell):
		obstacle_nodes[cell].position = tile_to_world(cell)
	if map_data.headquarters_covers(cell):
		headquarters.position = tile_to_world(map_data.headquarters)
	return true


func paint_terrain(cell: Vector2i, kind: int) -> bool:
	if map_data == null or not map_data.set_terrain(cell, kind):
		return false
	_refresh_cell_and_neighbors(cell)
	return true


func paint_obstacle(cell: Vector2i, kind: int) -> bool:
	if map_data == null or not map_data.set_obstacle(cell, kind):
		return false
	if kind < 0:
		_remove_obstacle_node(cell)
	else:
		_spawn_obstacle(cell, kind)
	return true


func place_headquarters(cell: Vector2i) -> bool:
	if map_data == null or not map_data.set_headquarters(cell):
		return false
	_rebuild_obstacles()
	_place_headquarters()
	return true


func is_cell_blocked(cell: Vector2i) -> bool:
	if map_data == null or not map_data.in_bounds(cell):
		return true
	if map_data.terrain_at(cell) == MAP_DOCUMENT.TERRAIN_WATER:
		return true
	if map_data.obstacle_at(cell) >= 0:
		return true
	return map_data.spawn_covers(cell)


func tile_to_world(tile: Vector2i) -> Vector2:
	var lifted := 0
	if map_data != null and map_data.in_bounds(tile):
		lifted = map_data.elevation_at(tile) * MAP_DOCUMENT.ELEVATION_RISE
	return terrain.map_to_local(tile) + Vector2(0, -lifted)


func world_to_tile(point: Vector2) -> Vector2i:
	var flat: Vector2i = terrain.local_to_map(point)
	var shifted: Vector2i = terrain.local_to_map(point + Vector2(0, (MAP_DOCUMENT.ELEVATION_LEVELS - 1) * MAP_DOCUMENT.ELEVATION_RISE))
	var best := flat
	var best_score := 1000.0
	var best_level := -1
	var found := false
	for origin in [flat, shifted]:
		for dy in range(-3, 4):
			for dx in range(-3, 4):
				var cell: Vector2i = origin + Vector2i(dx, dy)
				if map_data == null or not map_data.in_bounds(cell):
					continue
				var rel: Vector2 = point - tile_to_world(cell)
				var diamond := absf(rel.x) / (TILE_W * 0.5) + absf(rel.y) / (TILE_H * 0.5)
				var level: int = map_data.elevation_at(cell)
				if diamond <= 1.0 and (not found or diamond < best_score - 0.001 or (absf(diamond - best_score) <= 0.001 and level > best_level)):
					best = cell
					best_score = diamond
					best_level = level
					found = true
	return best if found else flat


func _ensure_layers() -> void:
	if _layers_ready:
		return
	_build_terrain_layers()
	_create_actor_layer()
	_layers_ready = true


func _create_actor_layer() -> void:
	actors = Node2D.new()
	actors.name = "WorldActors"
	actors.y_sort_enabled = true
	actors.z_index = 1
	add_child(actors)


func _build_terrain_layers() -> void:
	var tileset := _make_ground_tileset()
	var transition_set := _make_transition_tileset()
	for level in range(MAP_DOCUMENT.ELEVATION_LEVELS):
		var ground := TileMapLayer.new()
		ground.name = "Terrain" if level == 0 else "Terrain_%d" % level
		ground.tile_set = tileset
		ground.position = Vector2(0, -level * MAP_DOCUMENT.ELEVATION_RISE)
		add_child(ground)
		level_terrain.append(ground)
		var overlay := TileMapLayer.new()
		overlay.name = "TerrainTransitions" if level == 0 else "TerrainTransitions_%d" % level
		overlay.tile_set = transition_set
		overlay.position = ground.position
		add_child(overlay)
		level_transitions.append(overlay)
		var cliffs := Node2D.new()
		cliffs.name = "Cliffs_%d" % level
		cliffs.draw.connect(_draw_cliffs.bind(level))
		add_child(cliffs)
		cliff_layers.append(cliffs)
	terrain = level_terrain[0]
	transitions = level_transitions[0]


func _make_ground_tileset() -> TileSet:
	var tileset := TileSet.new()
	tileset.tile_shape = TileSet.TILE_SHAPE_ISOMETRIC
	tileset.tile_size = Vector2i(TILE_W, TILE_H)
	var source := TileSetAtlasSource.new()
	source.texture = ImageTexture.create_from_image(_make_atlas_image())
	source.texture_region_size = Vector2i(TILE_W, TILE_H)
	for index in range(ATLAS_TILE_COUNT):
		source.create_tile(Vector2i(index % 3, floori(float(index) / 3.0)))
	tileset.add_source(source, 0)
	return tileset


func _make_atlas_image() -> Image:
	var rows := int(ceil(float(ATLAS_TILE_COUNT) / 3.0))
	var atlas := Image.create(TILE_W * 3, TILE_H * rows, false, Image.FORMAT_RGBA8)
	atlas.fill(Color.TRANSPARENT)
	for index in range(ATLAS_TILE_COUNT):
		_paint_diamond(atlas, index)
	return atlas


func _paint_diamond(atlas: Image, index: int) -> void:
	var origin_x := (index % 3) * TILE_W
	var origin_y := floori(float(index) / 3.0) * TILE_H
	for y in range(TILE_H):
		for x in range(TILE_W):
			var nx := (float(x) + 0.5) / (float(TILE_W) * 0.5) - 1.0
			var ny := (float(y) + 0.5) / (float(TILE_H) * 0.5) - 1.0
			if absf(nx) + absf(ny) > 1.0:
				continue
			atlas.set_pixel(origin_x + x, origin_y + y, _atlas_color(index, nx, ny, x, y))


func _atlas_color(index: int, nx: float, ny: float, x: int, y: int) -> Color:
	if index == MAP_DOCUMENT.TERRAIN_WATER or index == ATLAS_WATER_ALT:
		var color := Color("#2e86b5").lerp(Color("#1c6794"), clampf(-ny, 0.0, 1.0) * 0.65)
		var phase := 0.0 if index == MAP_DOCUMENT.TERRAIN_WATER else 0.55
		if absf(sin(ny * 7.0 + phase + nx * 1.4)) < 0.22:
			color = color.lightened(0.1)
		return color
	if index == ATLAS_SHALLOWS:
		var shallows := Color("#67b7d6")
		var rim := 1.0 - (absf(nx) + absf(ny))
		if rim < 0.18:
			return Color("#e4f3f1").lerp(shallows, rim / 0.18)
		return shallows
	if index == MAP_DOCUMENT.TERRAIN_SAND:
		var sand := Color("#d2bc84")
		if ny > 0.0:
			sand = sand.darkened(0.06 * ny)
		if (x * 13 + y * 7) % 19 == 0:
			sand = sand.darkened(0.1)
		return sand
	if index == MAP_DOCUMENT.TERRAIN_ORE:
		var nugget := (x * 17 + y * 13) % 11
		if nugget == 0:
			return Color("#f2d48a")
		if nugget == 1:
			return Color("#6d4e1c")
		return Color("#c6a04a")
	if index == MAP_DOCUMENT.TERRAIN_GEM:
		if nx * nx + ny * ny < 0.1:
			return Color("#e8fff8")
		if absf(nx) + absf(ny) < 0.42:
			return Color("#5fd4c4")
		return Color("#1f8f86")
	return TILE_COLORS[index]


## Overlay tiles are feathered along exposed diamond edges. A 4-bit neighbor
## mask identifies matching terrain across NW, NE, SE and SW map neighbors.
## The underlying TileMapLayer remains authoritative for map coordinates.
func _make_transition_tileset() -> TileSet:
	var transition_set := TileSet.new()
	transition_set.tile_shape = TileSet.TILE_SHAPE_ISOMETRIC
	transition_set.tile_size = Vector2i(TILE_W, TILE_H)
	var source := TileSetAtlasSource.new()
	var atlas := Image.create(TILE_W * 16, TILE_H * 3, false, Image.FORMAT_RGBA8)
	atlas.fill(Color.TRANSPARENT)
	for kind in range(3):
		for mask in range(16):
			var color: Color = TILE_COLORS[[3, 4, 2][kind]]
			for py in range(TILE_H):
				for px in range(TILE_W):
					var nx := (float(px) + 0.5) / (float(TILE_W) * 0.5) - 1.0
					var ny := (float(py) + 0.5) / (float(TILE_H) * 0.5) - 1.0
					if absf(nx) + absf(ny) > 1.0:
						continue
					var edges := [1.0 + nx + ny, 1.0 - nx + ny, 1.0 - nx - ny, 1.0 + nx - ny]
					var alpha := 1.0
					for edge in range(4):
						if (mask & (1 << edge)) == 0:
							alpha = minf(alpha, smoothstep(0.0, 0.28, edges[edge]))
					var pixel := color
					pixel.a = alpha
					atlas.set_pixel(mask * TILE_W + px, kind * TILE_H + py, pixel)
	source.texture = ImageTexture.create_from_image(atlas)
	source.texture_region_size = Vector2i(TILE_W, TILE_H)
	for kind in range(3):
		for mask in range(16):
			source.create_tile(Vector2i(mask, kind))
	transition_set.add_source(source, 0)
	return transition_set


func _apply_cell(cell: Vector2i) -> void:
	var kind: int = map_data.terrain_at(cell)
	var level: int = map_data.elevation_at(cell)
	var base_index := kind
	if kind == MAP_DOCUMENT.TERRAIN_WATER:
		if _coastal_water(cell):
			base_index = ATLAS_SHALLOWS
		elif (cell.x + cell.y) % 2 == 0:
			base_index = MAP_DOCUMENT.TERRAIN_WATER
		else:
			base_index = ATLAS_WATER_ALT
	elif kind == 2 or kind == 3 or kind == 4:
		base_index = posmod(cell.x * 3 + cell.y * 5, 2)
	var atlas := Vector2i(base_index % 3, floori(float(base_index) / 3.0))
	var overlay_kind := -1
	if kind == 3:
		overlay_kind = 0
	elif kind == 4:
		overlay_kind = 1
	elif kind == 2:
		overlay_kind = 2
	var mask := 0
	if overlay_kind != -1:
		for edge in range(NEIGHBORS.size()):
			var adjacent: Vector2i = cell + NEIGHBORS[edge]
			if map_data.in_bounds(adjacent) and map_data.terrain_at(adjacent) == kind:
				mask |= 1 << edge
	for index in range(level_terrain.size()):
		if index == level:
			level_terrain[index].set_cell(cell, 0, atlas)
			if overlay_kind == -1:
				level_transitions[index].erase_cell(cell)
			else:
				level_transitions[index].set_cell(cell, 0, Vector2i(mask, overlay_kind))
		else:
			level_terrain[index].erase_cell(cell)
			level_transitions[index].erase_cell(cell)


func _queue_cliff_redraw() -> void:
	for node in cliff_layers:
		node.queue_redraw()


func _draw_cliffs(level: int) -> void:
	if map_data == null or level >= cliff_layers.size():
		return
	var layer: Node2D = cliff_layers[level]
	var rise := float(MAP_DOCUMENT.ELEVATION_RISE)
	for y in range(map_data.height):
		for x in range(map_data.width):
			var cell := Vector2i(x, y)
			if map_data.elevation_at(cell) != level or level == 0:
				continue
			var center := tile_to_world(cell)
			_draw_cliff_face(layer, center, Vector2(TILE_W * 0.5, 0), Vector2(0, TILE_H * 0.5), _cliff_drop(cell, Vector2i(1, 0)), Color("#7d6b56"))
			_draw_cliff_face(layer, center, Vector2(-TILE_W * 0.5, 0), Vector2(0, TILE_H * 0.5), _cliff_drop(cell, Vector2i(0, 1)), Color("#56493c"))


func _cliff_drop(cell: Vector2i, offset: Vector2i) -> int:
	var neighbor := cell + offset
	var neighbor_level := 0
	if map_data.in_bounds(neighbor):
		neighbor_level = map_data.elevation_at(neighbor)
	return maxi(map_data.elevation_at(cell) - neighbor_level, 0)


func _draw_cliff_face(layer: Node2D, center: Vector2, edge_a: Vector2, edge_b: Vector2, drop: int, base_color: Color) -> void:
	var rise := float(MAP_DOCUMENT.ELEVATION_RISE)
	for step in range(drop):
		var top := step * rise
		var bottom := (step + 1) * rise
		var color := base_color.darkened(0.08 * float(step))
		layer.draw_colored_polygon(PackedVector2Array([
			center + edge_a + Vector2(0, top),
			center + edge_b + Vector2(0, top),
			center + edge_b + Vector2(0, bottom),
			center + edge_a + Vector2(0, bottom),
		]), color)
		layer.draw_line(center + edge_a + Vector2(0, top), center + edge_b + Vector2(0, top), color.lightened(0.18), 2.0)


func _coastal_water(cell: Vector2i) -> bool:
	for y in range(cell.y - 2, cell.y + 3):
		for x in range(cell.x - 2, cell.x + 3):
			var neighbor := Vector2i(x, y)
			if neighbor == cell or not map_data.in_bounds(neighbor):
				continue
			if map_data.terrain_at(neighbor) != MAP_DOCUMENT.TERRAIN_WATER:
				return true
	return false


func _refresh_cell_and_neighbors(cell: Vector2i) -> void:
	for y in range(cell.y - 2, cell.y + 3):
		for x in range(cell.x - 2, cell.x + 3):
			var adjacent := Vector2i(x, y)
			if map_data.in_bounds(adjacent):
				_apply_cell(adjacent)


func _rebuild_obstacles() -> void:
	for node in obstacle_nodes.values():
		node.free()
	obstacle_nodes.clear()
	for record in map_data.obstacle_records():
		_spawn_obstacle(Vector2i(int(record.x), int(record.y)), int(record.kind))


func _spawn_obstacle(cell: Vector2i, kind: int) -> void:
	_remove_obstacle_node(cell)
	var obstacle := Node2D.new()
	obstacle.set_script(OBSTACLE_SCRIPT)
	obstacle.name = "Obstacle_%d_%d" % [cell.x, cell.y]
	actors.add_child(obstacle)
	obstacle.call("configure", kind, cell, tile_to_world(cell))
	obstacle_nodes[cell] = obstacle


func _remove_obstacle_node(cell: Vector2i) -> void:
	if not obstacle_nodes.has(cell):
		return
	var node: Node = obstacle_nodes[cell]
	obstacle_nodes.erase(cell)
	node.free()


func _place_headquarters() -> void:
	for node in extra_spawns:
		node.free()
	extra_spawns.clear()
	var spawns: Array = map_data.all_spawns()
	if headquarters == null or not is_instance_valid(headquarters):
		headquarters = COMMAND_CENTER_SCENE.instantiate()
		actors.add_child(headquarters)
	_seat_spawn(headquarters, spawns[0])
	for index in range(1, spawns.size()):
		var spawn := COMMAND_CENTER_SCENE.instantiate()
		spawn.name = "Start_%d" % index
		actors.add_child(spawn)
		_seat_spawn(spawn, spawns[index])
		extra_spawns.append(spawn)


func _seat_spawn(spawn: Node2D, cell: Vector2i) -> void:
	spawn.call("place_on_grid", terrain, cell)
	spawn.position = tile_to_world(cell)


func _ensure_camera(recenter_camera: bool) -> void:
	if camera == null:
		camera = Camera2D.new()
		camera.set_script(preload("res://scripts/rts_camera.gd"))
		camera.name = "RTSCamera"
		add_child(camera)
		camera.enabled = true
		recenter_camera = true
	if map_data.map_name == "mercy-bay":
		camera.set("target_zoom", 0.18)
	elif map_data.width >= 48:
		camera.set("target_zoom", 0.48)
	else:
		camera.set("target_zoom", 0.75)
	if recenter_camera:
		camera.call("configure", _world_bounds(), tile_to_world(map_data.focus_cell()))


func _apply_backdrop() -> void:
	var color := Color("#4d4d4d")
	if map_data != null and map_data.map_name == "mercy-bay":
		color = Color("#2e86b5")
	RenderingServer.set_default_clear_color(color)


func _world_bounds() -> Rect2:
	# Godot's stacked isometric layout steps a full tile across and half a tile down.
	var half := Vector2(TILE_W * 0.5, TILE_H * 0.5)
	var first := half
	var last := Vector2(float(map_data.width - 1) * TILE_W + half.x, float(map_data.height - 1) * half.y)
	var min_point := first - half
	var max_point := first + last + half
	var rise_pad := float(MAP_DOCUMENT.ELEVATION_LEVELS - 1) * MAP_DOCUMENT.ELEVATION_RISE
	# The stacked map is much wider than it is tall, so the overview zoom needs room above and below the tiles.
	min_point.y -= rise_pad + 1200.0
	max_point.y += 1200.0
	return Rect2(min_point, max_point - min_point)


func _unhandled_input(event: InputEvent) -> void:
	if get_parent() != null and get_parent().name == "MapEditor":
		return
	if event is InputEventKey and event.pressed and not event.echo and not event.ctrl_pressed and not event.alt_pressed and not event.meta_pressed:
		if event.keycode == KEY_BRACKETRIGHT:
			_cycle_showcase(1)
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_BRACKETLEFT:
			_cycle_showcase(-1)
			get_viewport().set_input_as_handled()


func _cycle_showcase(step: int) -> void:
	var current := 0
	if map_data != null:
		for index in range(SHOWCASE_MAPS.size()):
			var map_file := String(SHOWCASE_MAPS[index]).get_file().trim_suffix(".map.json")
			if map_file == map_data.map_name:
				current = index
				break
	showcase_index = posmod(current + step, SHOWCASE_MAPS.size())
	var loaded: Dictionary = MAP_DOCUMENT.load_from_file(SHOWCASE_MAPS[showcase_index])
	if bool(loaded.ok):
		apply_map(loaded.document)
	else:
		push_warning(str(loaded.error))
