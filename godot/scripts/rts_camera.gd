extends Camera2D
## RTS camera: smooth keyboard/edge pan, drag, cursor-anchored zoom, touch pan/pinch.
@export var pan_speed := 950.0
@export var edge_margin := 18.0
@export var smoothing := 12.0
@export var min_zoom := 0.45
@export var max_zoom := 1.8
@export var allow_edge_scroll := true
var world_bounds := Rect2(-4096, 0, 8192, 4096)
var target_position := Vector2.ZERO
var target_zoom := 0.75
var dragging := false
var touch_points: Dictionary = {}
var pinch_distance := 0.0

func configure(bounds: Rect2, initial_position: Vector2) -> void:
	world_bounds = bounds
	target_position = initial_position
	position = initial_position
	zoom = Vector2.ONE * target_zoom
	_clamp_target()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_MIDDLE or event.button_index == MOUSE_BUTTON_RIGHT:
			dragging = event.pressed
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom_at(event.position, 1.12)
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom_at(event.position, 1.0 / 1.12)
	elif event is InputEventMouseMotion and dragging:
		target_position -= event.relative / target_zoom
		_clamp_target()
	elif event is InputEventScreenTouch:
		if event.pressed:
			touch_points[event.index] = event.position
		else:
			touch_points.erase(event.index)
		pinch_distance = _touch_distance() if touch_points.size() == 2 else 0.0
	elif event is InputEventScreenDrag:
		touch_points[event.index] = event.position
		if touch_points.size() == 1:
			target_position -= event.relative / target_zoom
			_clamp_target()
		elif touch_points.size() == 2:
			var distance := _touch_distance()
			if pinch_distance > 0.0:
				_zoom_at(get_viewport_rect().size * 0.5, distance / pinch_distance)
			pinch_distance = distance
	elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		dragging = false

func _touch_distance() -> float:
	var points := touch_points.values()
	return (points[0] as Vector2).distance_to(points[1] as Vector2)

func _zoom_at(screen_point: Vector2, factor: float) -> void:
	var next_zoom := clampf(target_zoom * factor, min_zoom, max_zoom)
	var center := get_viewport_rect().size * 0.5
	# Preserve the world location under the pointer when zooming.
	target_position += (screen_point - center) * (1.0 / target_zoom - 1.0 / next_zoom)
	target_zoom = next_zoom
	_clamp_target()

func _clamp_target() -> void:
	var half_view := get_viewport_rect().size * 0.5 / target_zoom
	var low := world_bounds.position + half_view
	var high := world_bounds.end - half_view
	target_position.x = (world_bounds.position.x + world_bounds.end.x) * 0.5 if low.x > high.x else clampf(target_position.x, low.x, high.x)
	target_position.y = (world_bounds.position.y + world_bounds.end.y) * 0.5 if low.y > high.y else clampf(target_position.y, low.y, high.y)

func _process(delta: float) -> void:
	var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if Input.is_key_pressed(KEY_A):
		direction.x -= 1.0
	if Input.is_key_pressed(KEY_D):
		direction.x += 1.0
	if Input.is_key_pressed(KEY_W):
		direction.y -= 1.0
	if Input.is_key_pressed(KEY_S):
		direction.y += 1.0
	if allow_edge_scroll and touch_points.is_empty() and not dragging and Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
		var cursor := get_viewport().get_mouse_position()
		var size := get_viewport_rect().size
		if Rect2(Vector2.ZERO, size).has_point(cursor):
			if cursor.x <= edge_margin:
				direction.x -= 1.0
			elif cursor.x >= size.x - edge_margin:
				direction.x += 1.0
			if cursor.y <= edge_margin:
				direction.y -= 1.0
			elif cursor.y >= size.y - edge_margin:
				direction.y += 1.0
	if direction != Vector2.ZERO:
		target_position += direction.normalized() * pan_speed * delta / target_zoom
		_clamp_target()
	var blend := 1.0 - exp(-smoothing * delta)
	position = position.lerp(target_position, blend)
	var z := lerpf(zoom.x, target_zoom, blend)
	zoom = Vector2.ONE * z
