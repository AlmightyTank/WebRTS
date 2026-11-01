extends Node2D
## Isometric battlefield rendered from a serialized map document.
const MAP_DOCUMENT := preload("res://scripts/map_document.gd")
const MAP_GENERATOR := preload("res://scripts/map_generator.gd")
const OBSTACLE_SCRIPT := preload("res://scripts/terrain_obstacle.gd")
const COMMAND_CENTER_SCENE: PackedScene = preload("res://scenes/buildings/command_center.tscn")
const TILE_W := 128
const TILE_H := 64
const NEIGHBORS: Array[Vector2i] = [Vector2i(-1, 0), Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1)]
const TILE_COLORS := [
	Color("#58764a"), Color("#638051"), Color("#718658"),
	Color("#806c4d"), Color("#858583"), Color("#596d4d")
]

@export var map_path := "res://maps/procedural-skirmish.map.json"
var camera: Camera2D
var terrain: TileMapLayer
var transitions: TileMapLayer
var actors: Node2D
var headquarters: Node2D
var map_data
var obstacle_nodes: Dictionary = {}
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
	terrain.clear()
	transitions.clear()
	for y in range(map_data.height):
		for x in range(map_data.width):
			_apply_cell(Vector2i(x, y))
	_rebuild_obstacles()
	_place_headquarters()
	_ensure_camera(recenter_camera)


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
	if map_data.obstacle_at(cell) >= 0:
		return true
	return map_data.headquarters_covers(cell)


func tile_to_world(tile: Vector2i) -> Vector2:
	return terrain.map_to_local(tile)


func world_to_tile(point: Vector2) -> Vector2i:
	return terrain.local_to_map(point)


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
	terrain = TileMapLayer.new()
	terrain.name = "Terrain"
	add_child(terrain)
	var tileset := TileSet.new()
	tileset.tile_shape = TileSet.TILE_SHAPE_ISOMETRIC
	tileset.tile_size = Vector2i(TILE_W, TILE_H)
	var source := TileSetAtlasSource.new()
	source.texture = ImageTexture.create_from_image(_make_atlas_image())
	source.texture_region_size = Vector2i(TILE_W, TILE_H)
	for index in range(TILE_COLORS.size()):
		source.create_tile(Vector2i(index % 3, floori(float(index) / 3.0)))
	tileset.add_source(source, 0)
	terrain.tile_set = tileset
	_build_transition_layer()


func _make_atlas_image() -> Image:
	var atlas := Image.create(TILE_W * 3, TILE_H * 2, false, Image.FORMAT_RGBA8)
	atlas.fill(Color.TRANSPARENT)
	for index in range(TILE_COLORS.size()):
		var ox: int = (index % 3) * TILE_W
		var oy: int = floori(float(index) / 3.0) * TILE_H
		for y in range(TILE_H):
			for x in range(TILE_W):
				var normalized: float = absf(float(x) - TILE_W * 0.5) / (TILE_W * 0.5) + absf(float(y) - TILE_H * 0.5) / (TILE_H * 0.5)
				if normalized <= 1.0:
					atlas.set_pixel(ox + x, oy + y, TILE_COLORS[index])
	return atlas


## Overlay tiles are feathered along exposed diamond edges. A 4-bit neighbor
## mask identifies matching terrain across NW, NE, SE and SW map neighbors.
## The underlying TileMapLayer remains authoritative for map coordinates.
func _build_transition_layer() -> void:
	transitions = TileMapLayer.new()
	transitions.name = "TerrainTransitions"
	add_child(transitions)
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
	transitions.tile_set = transition_set


func _apply_cell(cell: Vector2i) -> void:
	var kind: int = map_data.terrain_at(cell)
	var base_index := kind
	if kind == 2 or kind == 3 or kind == 4:
		base_index = posmod(cell.x * 3 + cell.y * 5, 2)
	terrain.set_cell(cell, 0, Vector2i(base_index % 3, floori(float(base_index) / 3.0)))
	var overlay_kind := -1
	if kind == 3:
		overlay_kind = 0
	elif kind == 4:
		overlay_kind = 1
	elif kind == 2:
		overlay_kind = 2
	if overlay_kind == -1:
		transitions.erase_cell(cell)
		return
	var mask := 0
	for edge in range(NEIGHBORS.size()):
		var adjacent: Vector2i = cell + NEIGHBORS[edge]
		if map_data.in_bounds(adjacent) and map_data.terrain_at(adjacent) == kind:
			mask |= 1 << edge
	transitions.set_cell(cell, 0, Vector2i(mask, overlay_kind))


func _refresh_cell_and_neighbors(cell: Vector2i) -> void:
	_apply_cell(cell)
	for offset in NEIGHBORS:
		var adjacent: Vector2i = cell + offset
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
	if headquarters == null or not is_instance_valid(headquarters):
		headquarters = COMMAND_CENTER_SCENE.instantiate()
		actors.add_child(headquarters)
	headquarters.call("place_on_grid", terrain, map_data.headquarters)


func _ensure_camera(recenter_camera: bool) -> void:
	if camera == null:
		camera = Camera2D.new()
		camera.set_script(preload("res://scripts/rts_camera.gd"))
		camera.name = "RTSCamera"
		add_child(camera)
		camera.enabled = true
		recenter_camera = true
	if recenter_camera:
		camera.call("configure", _world_bounds(), tile_to_world(map_data.headquarters))


func _world_bounds() -> Rect2:
	var horizontal_extent := float(map_data.width + map_data.height) * TILE_W * 0.25
	var vertical_extent := float(map_data.width + map_data.height) * TILE_H * 0.5
	return Rect2(-horizontal_extent, -TILE_H * 0.5, horizontal_extent * 2.0, vertical_extent + TILE_H)
