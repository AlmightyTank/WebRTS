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
var dragging := false

func _ready() -> void:
	_build_terrain()
	camera = Camera2D.new()
	camera.name = "RTSCamera"
	add_child(camera)
	camera.enabled = true
	camera.position = tile_to_world(Vector2i(WIDTH / 2, HEIGHT / 2))
	camera.zoom = Vector2(0.75, 0.75)

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
			terrain.set_cell(Vector2i(x, y), 0, Vector2i(index % 3, floori(float(index) / 3.0)))
	# Generated image can be exported as PNG for artists to replace.
	# The game uses the in-memory atlas, so packaged builds do not write files.

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

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_MIDDLE or event.button_index == MOUSE_BUTTON_RIGHT:
			dragging = event.pressed
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_UP:
			set_zoom(camera.zoom.x * 1.12)
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			set_zoom(camera.zoom.x / 1.12)
	elif event is InputEventMouseMotion and dragging:
		camera.position -= event.relative / camera.zoom
		clamp_camera()
	elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		dragging = false

func set_zoom(value: float) -> void:
	var z: float = clampf(value, 0.4, 2.0)
	camera.zoom = Vector2(z, z)
	clamp_camera()

func clamp_camera() -> void:
	var max_x := WIDTH * TILE_W * 0.5
	var max_y := HEIGHT * TILE_H
	camera.position.x = clampf(camera.position.x, -max_x, max_x)
	camera.position.y = clampf(camera.position.y, 0.0, max_y)

func _process(delta: float) -> void:
	var movement := Vector2.ZERO
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		movement.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		movement.x += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		movement.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		movement.y += 1.0
	if movement != Vector2.ZERO:
		camera.position += movement.normalized() * 700.0 * delta / camera.zoom.x
		clamp_camera()
