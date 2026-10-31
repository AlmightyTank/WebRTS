extends Node2D
## v0.1 Slice B: isometric TileMapLayer with a generated PNG-compatible tile atlas.
const WIDTH := 64
const HEIGHT := 64
const TILE_W := 128
const TILE_H := 64
const TILE_COLORS := [
	Color("#58764a"), Color("#638051"), Color("#718658"),
	Color("#806c4d"), Color("#858583"), Color("#596d4d")
]
var camera: Camera2D
var terrain: TileMapLayer
var transitions: TileMapLayer
const COMMAND_CENTER_SCENE: PackedScene = preload("res://scenes/buildings/command_center.tscn")

func _ready() -> void:
	_build_terrain()
	_spawn_initial_command_center()
	camera = Camera2D.new()
	camera.set_script(preload("res://scripts/rts_camera.gd"))
	camera.name = "RTSCamera"
	add_child(camera)
	camera.enabled = true
	# Diamond map bounds from the four extreme tile corners.
	var horizontal_extent := float(WIDTH + HEIGHT) * TILE_W * 0.25
	var vertical_extent := float(WIDTH + HEIGHT) * TILE_H * 0.5
	camera.call("configure", Rect2(-horizontal_extent, -TILE_H * 0.5, horizontal_extent * 2.0, vertical_extent + TILE_H), tile_to_world(Vector2i(WIDTH / 2, HEIGHT / 2)))

func _spawn_initial_command_center() -> void:
	# Initial static headquarters preview; interactive placement is scheduled for v0.3.
	var headquarters := COMMAND_CENTER_SCENE.instantiate()
	add_child(headquarters)
	headquarters.place_on_grid(terrain, Vector2i(WIDTH / 2, HEIGHT / 2))

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

func _build_terrain() -> void:
	terrain = TileMapLayer.new()
	terrain.name = "Terrain"
	add_child(terrain)
	var tileset := TileSet.new()
	tileset.tile_shape = TileSet.TILE_SHAPE_ISOMETRIC
	tileset.tile_size = Vector2i(TILE_W, TILE_H)
	var source := TileSetAtlasSource.new()
	var atlas_image := _make_atlas_image()
	source.texture = ImageTexture.create_from_image(atlas_image)
	source.texture_region_size = Vector2i(TILE_W, TILE_H)
	for index in range(TILE_COLORS.size()):
		source.create_tile(Vector2i(index % 3, floori(float(index) / 3.0)))
	tileset.add_source(source, 0)
	terrain.tile_set = tileset
	for y in range(HEIGHT):
		for x in range(WIDTH):
			var index := terrain_kind(x, y)
			if index == 2 or index == 3 or index == 4:
				index = posmod(x * 3 + y * 5, 2)
			terrain.set_cell(Vector2i(x, y), 0, Vector2i(index % 3, floori(float(index) / 3.0)))
	_build_transitions()
	# Generated image can be exported as PNG for artists to replace.
	# The game uses the in-memory atlas, so packaged builds do not write files.


## Overlay tiles are feathered along exposed diamond edges. A 4-bit neighbor
## mask identifies matching terrain across NW, NE, SE and SW map neighbors.
## The underlying TileMapLayer remains authoritative for map coordinates.
func _build_transitions() -> void:
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
					# Distance from each of four diagonal diamond edges.
					var edges := [1.0 + nx + ny, 1.0 - nx + ny, 1.0 - nx - ny, 1.0 + nx - ny]
					var alpha := 1.0
					for edge in range(4):
						if (mask & (1 << edge)) == 0:
							alpha = minf(alpha, smoothstep(0.0, 0.28, edges[edge]))
					var pixel := color
					pixel.a = alpha
					atlas.set_pixel(mask * TILE_W + px, kind * TILE_H + py, pixel)
			source.create_tile(Vector2i(mask, kind))
	source.texture = ImageTexture.create_from_image(atlas)
	source.texture_region_size = Vector2i(TILE_W, TILE_H)
	transition_set.add_source(source, 0)
	transitions.tile_set = transition_set
	# Overlay only non-grass terrain. Base grass shows through feathered edges.
	for y in range(HEIGHT):
		for x in range(WIDTH):
			var kind := terrain_kind(x, y)
			var overlay_kind := -1
			if kind == 3:
				overlay_kind = 0
			elif kind == 4:
				overlay_kind = 1
			elif kind == 2:
				overlay_kind = 2
			if overlay_kind == -1:
				continue
			var neighbors := [Vector2i(-1, 0), Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1)]
			var mask := 0
			for edge in range(4):
				var adjacent: Vector2i = Vector2i(x, y) + neighbors[edge]
				if adjacent.x >= 0 and adjacent.y >= 0 and adjacent.x < WIDTH and adjacent.y < HEIGHT and terrain_kind(adjacent.x, adjacent.y) == kind:
					mask |= 1 << edge
			transitions.set_cell(Vector2i(x, y), 0, Vector2i(mask, overlay_kind))

func tile_to_world(tile: Vector2i) -> Vector2:
	return terrain.map_to_local(tile)

func world_to_tile(point: Vector2) -> Vector2i:
	return terrain.local_to_map(point)

func terrain_kind(x: int, y: int) -> int:
	if abs(x - y - 9) <= 1:
		return 4
	if x > 17 and x < 35 and y > 19 and y < 33:
		return 3 if (x + y) % 7 == 0 else 2
	return posmod(x * 13 + y * 7 + x * y, 4) if (x + y) % 11 == 0 else posmod(x * 3 + y * 5, 3)

