extends Node2D
## Slice A: procedural isometric terrain. No external art required.
const WIDTH := 64
const HEIGHT := 64
const TILE_W := 128.0
const TILE_H := 64.0
const COLORS := [
	Color("#58764a"), Color("#638051"), Color("#718658"),
	Color("#806c4d"), Color("#858583"), Color("#596d4d")
]
var camera: Camera2D
var dragging := false
var drag_last := Vector2.ZERO

func _ready() -> void:
	camera = Camera2D.new()
	camera.name = "RTSCamera"
	add_child(camera)
	camera.enabled = true
	camera.position = tile_to_world(Vector2i(WIDTH / 2, HEIGHT / 2))
	camera.zoom = Vector2(0.75, 0.75)
	queue_redraw()

func tile_to_world(tile: Vector2i) -> Vector2:
	return Vector2((tile.x - tile.y) * TILE_W * 0.5, (tile.x + tile.y) * TILE_H * 0.5)

func world_to_tile(point: Vector2) -> Vector2i:
	var x := point.x / TILE_W + point.y / TILE_H
	var y := point.y / TILE_H - point.x / TILE_W
	return Vector2i(roundi(x), roundi(y))

func terrain_kind(x: int, y: int) -> int:
	if abs(x - y - 9) <= 1:
		return 4
	if x > 17 and x < 35 and y > 19 and y < 33:
		return 3 if (x + y) % 7 == 0 else 2
	return posmod(x * 13 + y * 7 + x * y, 4) if (x + y) % 11 == 0 else posmod(x * 3 + y * 5, 3)

func _draw() -> void:
	for y in range(HEIGHT):
		for x in range(WIDTH):
			var center := tile_to_world(Vector2i(x, y))
			var corners := PackedVector2Array([
				center + Vector2(0, -TILE_H / 2),
				center + Vector2(TILE_W / 2, 0),
				center + Vector2(0, TILE_H / 2),
				center + Vector2(-TILE_W / 2, 0)
			])
			draw_colored_polygon(corners, COLORS[terrain_kind(x, y)])
			draw_polyline(PackedVector2Array([corners[0], corners[1], corners[2], corners[3], corners[0]]), Color(0.1, 0.15, 0.12, 0.14), 1.0)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_MIDDLE or event.button_index == MOUSE_BUTTON_RIGHT:
			dragging = event.pressed
			drag_last = event.position
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
