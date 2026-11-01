extends Camera2D
## Orthographic top-down camera; right mouse button remains available for RTS orders.
@export var pan_speed := 860.0
@export var min_zoom := 0.54
@export var max_zoom := 1.45
var bounds := Rect2(0,0,1920,1200)
var destination := Vector2.ZERO
var zoom_goal := 0.78
var middle_drag := false
var touches: Dictionary = {}
var last_pinch := 0.0

func configure(world_rect: Rect2, start: Vector2) -> void:
 bounds = world_rect
 destination = start
 position = start
 zoom = Vector2.ONE * zoom_goal
 _clamp()

func _unhandled_input(event: InputEvent) -> void:
 if event is InputEventMouseButton:
  if event.button_index == MOUSE_BUTTON_MIDDLE:
   middle_drag = event.pressed
  elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_UP:
   _zoom_at(event.position, 1.12)
  elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
   _zoom_at(event.position, 1.0/1.12)
 elif event is InputEventMouseMotion and middle_drag:
  destination -= event.relative / zoom_goal
  _clamp()
 elif event is InputEventScreenTouch:
  if event.pressed: touches[event.index] = event.position
  else: touches.erase(event.index)
  last_pinch = _pinch_distance() if touches.size() == 2 else 0.0
 elif event is InputEventScreenDrag:
  touches[event.index] = event.position
  if touches.size() == 2:
   var d := _pinch_distance()
   if last_pinch > 0.0: _zoom_at(get_viewport_rect().size*0.5, d/last_pinch)
   last_pinch = d
  # Touch pan uses two fingers; single-finger tap gives units and move commands.
  elif touches.size() == 1:
   destination -= event.relative / zoom_goal
   _clamp()

func _pinch_distance() -> float:
 var points := touches.values()
 return (points[0] as Vector2).distance_to(points[1] as Vector2)

func _zoom_at(point: Vector2, factor: float) -> void:
 var z := clampf(zoom_goal*factor,min_zoom,max_zoom)
 var center := get_viewport_rect().size*0.5
 destination += (point-center)*(1.0/zoom_goal-1.0/z)
 zoom_goal = z
 _clamp()

func _clamp() -> void:
 var half := get_viewport_rect().size*0.5/zoom_goal
 destination.x = bounds.get_center().x if half.x>bounds.size.x*0.5 else clampf(destination.x,bounds.position.x+half.x,bounds.end.x-half.x)
 destination.y = bounds.get_center().y if half.y>bounds.size.y*0.5 else clampf(destination.y,bounds.position.y+half.y,bounds.end.y-half.y)

func _process(delta: float) -> void:
 var dir := Input.get_vector("ui_left","ui_right","ui_up","ui_down")
 if Input.is_key_pressed(KEY_A) and not Input.is_key_pressed(KEY_SHIFT):
  # A is reserved for attack-move; use arrow keys or WASD except A.
  pass
 if Input.is_key_pressed(KEY_W): dir.y -= 1.0
 if Input.is_key_pressed(KEY_S): dir.y += 1.0
 if Input.is_key_pressed(KEY_D): dir.x += 1.0
 if Input.is_key_pressed(KEY_Q): dir.x -= 1.0
 if dir != Vector2.ZERO:
  destination += dir.normalized()*pan_speed*delta/zoom_goal
  _clamp()
 var t := 1.0-exp(-12.0*delta)
 position = position.lerp(destination,t)
 zoom = Vector2.ONE*lerpf(zoom.x,zoom_goal,t)
