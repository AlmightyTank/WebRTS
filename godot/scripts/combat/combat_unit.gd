extends Node2D
## Code-drawn combat actor. Physics state, weapons and orders are independent of rendering.
signal destroyed(unit: Node2D)

var arena
var unit_id := ""
var display_name := ""
var team := 0
var air := false
var armor := "PERSONNEL"
var max_hp := 100.0
var hp := 100.0
var move_speed := 90.0
var radius := 13.0
var selected := false
var weapon: Dictionary = {}
var facing := 0.0
var turret_angle := 0.0
var cooldown := 0.0
var scan_timer := 0.0
var target
var destination := Vector2.ZERO
var moving := false
var aggressive := false
# Attack-move retains the intended rally destination while targets are engaged.
var attack_move_goal := Vector2.ZERO
var has_attack_move_goal := false
var route := PackedVector2Array()
var route_index := 0
var profile_name := "infantry"
var accuracy := 1.0 # fixed until accuracy model is tested
var capture_target = null
var capture_approach_point := Vector2.ZERO
var capture_progress := 0.0
var capture_pause := 0.0

func configure(world: Node2D, unit_data: Dictionary, side: int, pos: Vector2, gun: Dictionary, flying: bool = false) -> void:
	arena = world
	unit_id = str(unit_data.get("id", ""))
	display_name = str(unit_data.get("name", unit_id))
	team = side
	position = pos
	armor = str(unit_data.get("armor", "PERSONNEL"))
	max_hp = float(unit_data.get("hp", 100))
	hp = max_hp
	move_speed = float(unit_data.get("speed", 80))
	weapon = gun.duplicate(true)
	air = flying
	profile_name = "air" if air else ("infantry" if armor == "PERSONNEL" else "vehicle")
	radius = 15.0 if air else (9.0 if armor == "PERSONNEL" else 18.0)
	name = "%s_%s" % ["Ally" if side == 0 else "Enemy", unit_id]
	cooldown = 0.15 + float((side + unit_id.length()) % 5) * 0.13
	queue_redraw()

func can_hit(other) -> bool:
	if other == null or not is_instance_valid(other) or other.team == team or other.hp <= 0.0:
		return false
	var factor = arena.armor_multiplier(str(weapon.get("type", "SMALL_ARMS")), other.armor)
	return factor > 0.0 and (bool(weapon.get("anti_air", false)) if other.air else bool(weapon.get("anti_ground", true)))

func order_move(point: Vector2, attack_move: bool = false) -> void:
	capture_target = null
	capture_progress = 0.0
	target = null
	aggressive = attack_move
	has_attack_move_goal = attack_move
	attack_move_goal = arena.clamp_point(point) if attack_move else Vector2.ZERO
	_begin_route(point)

func order_attack(enemy) -> void:
	capture_target = null
	capture_progress = 0.0
	if not can_hit(enemy):
		return
	target = enemy
	has_attack_move_goal = false
	moving = false
	route.clear()
	route_index = 0
	aggressive = true

func order_stop() -> void:
	capture_target = null
	capture_progress = 0.0
	target = null
	moving = false
	aggressive = false
	has_attack_move_goal = false
	route.clear()

func order_capture(building) -> void:
	if unit_id not in ["a_engineer", "r_engineer"] or not is_instance_valid(building) or building.team == team:
		return
	capture_target = building
	has_attack_move_goal = false
	capture_progress = 0.0
	capture_pause = 0.0
	target = null
	aggressive = false
	capture_approach_point = arena.capture_approach(building, position)
	_begin_route(capture_approach_point)

func _tick_capture(delta: float) -> bool:
	if unit_id not in ["a_engineer", "r_engineer"] or capture_target == null:
		return false
	if not is_instance_valid(capture_target) or capture_target.hp <= 0.0 or capture_target.team == team:
		capture_target = null
		capture_progress = 0.0
		return false
	if capture_pause > 0.0:
		capture_pause = maxf(0.0,capture_pause - delta)
	if position.distance_to(capture_approach_point) > 27.0:
		if not moving:
			_begin_route(capture_approach_point)
		if moving:
			_step_movement(delta)
		return true
	moving = false
	route.clear()
	if capture_pause <= 0.0:
		capture_progress += delta
	if capture_progress >= (0.7 if capture_target.team == -1 else 3.0):
		var claimed = capture_target
		capture_target = null
		arena.capture_structure(self,claimed)
	return true

func _begin_route(point: Vector2) -> void:
	destination = arena.clamp_point(point)
	route = arena.find_route(position, destination, air)
	route_index = 0
	moving = not route.is_empty()
	if not moving and position.distance_to(destination) > 12.0:
		# A blocked destination is rejected rather than clipping through a wall.
		destination = position

func _physics_process(delta: float) -> void:
	if arena.paused or arena.battle_over or hp <= 0.0:
		return
	if _tick_capture(delta):
		queue_redraw()
		return
	cooldown = maxf(0.0, cooldown - delta)
	scan_timer -= delta
	if target != null and (not is_instance_valid(target) or target.hp <= 0.0):
		target = null
	if scan_timer <= 0.0:
		scan_timer = 0.35 + float(unit_id.length() % 3) * 0.12
		if team == 1 or aggressive or (not moving):
			var new_target = arena.find_target(self, 330.0)
			if new_target != null and (target == null or position.distance_to(new_target.position) + 35.0 < position.distance_to(target.position)):
				target = new_target
	if target == null and has_attack_move_goal and not moving and position.distance_to(attack_move_goal) > 18.0:
		_begin_route(attack_move_goal)
	if target != null:
		var distance: float = position.distance_to(target.position)
		if distance <= float(weapon.get("range", 0.0)) and distance >= float(weapon.get("min_range", 0.0)) and arena.clear_shot(position, target.position, air, target.air, target):
			moving = false
			turret_angle = lerp_angle(turret_angle, (target.position - position).angle(), minf(1.0, 8.0 * delta))
			if cooldown <= 0.0:
				fire(target)
		elif distance > float(weapon.get("range", 0.0)) * 0.87 or not arena.clear_shot(position, target.position, air, target.air, target):
			if not moving or destination.distance_to(target.position) > 60.0:
				_begin_route(target.position)
		elif distance < float(weapon.get("min_range", 0.0)):
			_begin_route(position + (position - target.position).normalized() * 110.0)
	if moving:
		_step_movement(delta)
	queue_redraw()

func _step_movement(delta: float) -> void:
	if route_index >= route.size():
		moving = false
		return
	var waypoint: Vector2 = route[route_index]
	if position.distance_to(waypoint) <= maxf(7.0, move_speed * delta * 1.2):
		route_index += 1
		if route_index >= route.size():
			moving = false
			return
		waypoint = route[route_index]
	var direction := (waypoint - position).normalized()
	var separation := Vector2.ZERO
	if not air:
		for other in arena.units:
			if other == self or not is_instance_valid(other) or other.hp <= 0.0 or other.air:
				continue
			var offset: Vector2 = position - other.position
			var gap = radius + other.radius + 5.0
			if offset.length_squared() > 0.001 and offset.length() < gap:
				separation += offset.normalized() * (gap - offset.length()) / gap
	var steering := (direction + separation * 1.5).normalized()
	if steering.length_squared() < 0.01:
		steering = direction
	var next_position := position + steering * minf(move_speed * delta, position.distance_to(waypoint))
	if arena.can_occupy(next_position, radius, air, self):
		position = next_position
		facing = lerp_angle(facing, steering.angle(), minf(1.0, delta * (4.5 if profile_name == "vehicle" else 7.0)))
	else:
		# A congested waypoint may clear next frame; path through static terrain never clips.
		pass

func fire(enemy) -> void:
	cooldown = float(weapon.get("interval", 1.0))
	arena.spawn_projectile(self, enemy, weapon)

func receive_damage(value: float, attacker) -> void:
	if hp <= 0.0:
		return
	if capture_target != null:
		capture_progress = 0.0
		capture_pause = 1.0
	hp = maxf(0.0, hp - value)
	if team == 1 and attacker != null and is_instance_valid(attacker) and can_hit(attacker):
		target = attacker
	if hp <= 0.0:
		destroyed.emit(self)
		queue_free()
	else:
		queue_redraw()

func _draw() -> void:
	var main_color := Color("#78b6da") if team == 0 else Color("#d98b79")
	var dark := Color("#244f67") if team == 0 else Color("#693b32")
	if selected:
		draw_arc(Vector2.ZERO, radius + 8.0, 0.0, TAU, 36, Color("#e1f39e"), 2.2)
	if air:
		draw_circle(Vector2(0.0, 18.0), 14.0, Color(0, 0, 0, 0.23))
		draw_set_transform(Vector2.ZERO, facing)
		draw_colored_polygon(PackedVector2Array([Vector2(20, 0), Vector2(-8, -14), Vector2(-4, -4), Vector2(-20, -5), Vector2(-20, 5), Vector2(-4, 4), Vector2(-8, 14)]), main_color)
		draw_rect(Rect2(-7, -4, 16, 8), dark)
	elif profile_name == "infantry":
		if unit_id in ["a_engineer","r_engineer"]:
			draw_arc(Vector2.ZERO,10.0,0,TAU,20,Color("#f3d991"),2.0)
		draw_circle(Vector2(1, 3), radius, Color(0, 0, 0, 0.25))
		draw_circle(Vector2.ZERO, 7.0, main_color)
		draw_circle(Vector2(-1, -2), 3.2, dark)
		draw_line(Vector2(0, 0), Vector2.RIGHT.rotated(turret_angle) * 14.0, Color("#ded9c9"), 2.8)
	else:
		draw_set_transform(Vector2.ZERO, facing)
		draw_rect(Rect2(-19, -15, 38, 30), dark)
		draw_rect(Rect2(-14, -17, 28, 34), main_color)
		draw_rect(Rect2(-9, -10, 18, 20), dark)
		draw_set_transform(Vector2.ZERO, turret_angle)
		if weapon.get("type", "") == "AA":
			draw_rect(Rect2(0, -12, 23, 8), Color("#d8d9c5"))
			draw_rect(Rect2(0, 4, 23, 8), Color("#d8d9c5"))
			draw_rect(Rect2(-7, -13, 20, 26), main_color)
		else:
			draw_line(Vector2.ZERO, Vector2(31, 0), Color("#d6d6c5"), 5.0)
			draw_circle(Vector2.ZERO, 10.0, main_color)
	draw_set_transform(Vector2.ZERO, 0.0)
	if capture_target != null and is_instance_valid(capture_target):
		draw_rect(Rect2(-19,-radius-23,38,4),Color("#182c25"))
		draw_rect(Rect2(-19,-radius-23,38 * minf(1.0,capture_progress / (0.7 if capture_target.team==-1 else 3.0)),4),Color("#efcd76"))
	var amount := hp / maxf(1.0, max_hp)
	draw_rect(Rect2(-19, -radius - 15, 38, 4), Color("#1d2524"))
	draw_rect(Rect2(-19, -radius - 15, 38 * amount, 4), Color("#94d889") if amount > 0.4 else Color("#e2a052"))
