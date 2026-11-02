extends Node2D
## Code-drawn combat actor. Physics state, weapons and orders are independent of rendering.
const IndustrialArt = preload("res://scripts/ui/industrial_art.gd")
const GroundOrders = preload("res://scripts/combat/ground_orders.gd")
var pending_orders: Array = []

func queue_move(point: Vector2, attack_move: bool = false, column_spine = null, column_slot: Vector2 = Vector2.ZERO) -> void:
    GroundOrders.enqueue(self, point, attack_move, column_spine, column_slot)
signal destroyed(unit: Node2D)

var arena
var unit_id := ""
var display_name := ""
var team := 0
var air := false
# -1 is unlimited. Skirmish aircraft receive a sortie count and cannot fire at 0.
var ammo := -1
var ammo_max := -1
var rearming := false
var rearm_left := 0.0
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
var explicit_attack := false
var hold_position := false
var blocked_time := 0.0
var traffic_wait := 0.0
var column_move := false
var column_goal := Vector2.ZERO
var column_slot := Vector2.ZERO
var column_spine: PackedVector2Array = PackedVector2Array()
var unit_xp := 0.0
var salvage_tier := 0
var stationary_time := 0.0
var last_combat_position := Vector2.ZERO
var _visual_pose := -1

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
    if not arena.entity_visible_to(team, other):
        return false
    var factor = arena.armor_multiplier(str(weapon.get("type", "SMALL_ARMS")), other.armor)
    return factor > 0.0 and (bool(weapon.get("anti_air", false)) if other.air else bool(weapon.get("anti_ground", true)))

var order_revision := 0
var fire_feedback := 0.0
var hit_feedback := 0.0

func order_move(point: Vector2, attack_move: bool = false) -> void:
    hold_position = false
    order_revision += 1
    pending_orders.clear()
    explicit_attack = false
    capture_target = null
    capture_progress = 0.0
    target = null
    aggressive = attack_move
    has_attack_move_goal = attack_move
    attack_move_goal = arena.clamp_point(point) if attack_move else Vector2.ZERO
    column_move = false
    _begin_route(point)

func order_attack(enemy) -> void:
    if not can_hit(enemy):
        return
    explicit_attack = true
    hold_position = false
    order_revision += 1
    pending_orders.clear()
    capture_target = null
    capture_progress = 0.0
    if not can_hit(enemy):
        return
    target = enemy
    has_attack_move_goal = false
    moving = false
    column_move = false
    column_goal = Vector2.ZERO
    column_slot = Vector2.ZERO
    column_spine = PackedVector2Array()
    route.clear()
    route_index = 0
    aggressive = true

func order_stop() -> void:
    hold_position = false
    order_revision += 1
    pending_orders.clear()
    explicit_attack = false
    capture_target = null
    capture_progress = 0.0
    target = null
    moving = false
    aggressive = false
    has_attack_move_goal = false
    column_move = false
    column_goal = Vector2.ZERO
    column_slot = Vector2.ZERO
    column_spine = PackedVector2Array()
    route.clear()

func order_hold() -> void:
    order_stop()
    hold_position = true

func order_capture(building) -> void:
    if unit_id not in ["a_engineer", "r_engineer", "g_tech"] or not is_instance_valid(building) or building.team == team:
        return
    # Walls and gates stay with the faction that built them.
    if str(building.get("kind")) in ["wall", "gate"]:
        return
    if not arena.entity_visible_to(team, building):
        return
    capture_target = building
    hold_position = false
    order_revision += 1
    pending_orders.clear()
    explicit_attack = false
    has_attack_move_goal = false
    capture_progress = 0.0
    capture_pause = 0.0
    target = null
    aggressive = false
    capture_approach_point = arena.capture_approach(building, position)
    _begin_route(capture_approach_point)

func _tick_capture(delta: float) -> bool:
    if unit_id not in ["a_engineer", "r_engineer", "g_tech"] or capture_target == null:
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
    blocked_time = 0.0
    traffic_wait = 0.0
    column_move = false
    column_goal = Vector2.ZERO
    column_slot = Vector2.ZERO
    column_spine = PackedVector2Array()
    destination = arena.clamp_point(point)
    route = arena.find_route(position, destination, air, self, false)
    route_index = 0
    moving = not route.is_empty()
    if not moving and position.distance_to(destination) > 12.0:
        # A blocked destination is rejected rather than clipping through a wall.
        destination = position

func _physics_process(delta: float) -> void:
    if arena.paused or arena.battle_over or hp <= 0.0:
        return
    fire_feedback = maxf(0.0, fire_feedback - delta)
    hit_feedback = maxf(0.0, hit_feedback - delta)
    if _tick_capture(delta):
        queue_redraw()
        return
    if air and ammo == 0:
        target = null
        explicit_attack = false
        if arena.has_method("service_aircraft"):
            arena.service_aircraft(self, delta)
        if moving:
            _step_movement(delta)
        _publish_visual()
        return
    cooldown = maxf(0.0, cooldown - delta)
    stationary_time = stationary_time + delta if position.distance_to(last_combat_position) < 0.1 else 0.0
    last_combat_position = position
    scan_timer -= delta
    if target != null and not can_hit(target):
        target = null
        explicit_attack = false
        moving = false
        route.clear()
        if has_attack_move_goal:
            _begin_route(attack_move_goal)
    if scan_timer <= 0.0:
        scan_timer = 0.35 + float(unit_id.length() % 3) * 0.12
        if not explicit_attack and (aggressive or not moving):
            var new_target = arena.find_target(self, float(weapon.get("range", 0.0)) if hold_position else 330.0)
            if new_target != null and (target == null or position.distance_to(new_target.position) + 35.0 < position.distance_to(target.position)):
                target = new_target
    if target == null and has_attack_move_goal and not moving and position.distance_to(attack_move_goal) > 18.0:
        _begin_route(attack_move_goal)
    if target != null:
        var distance: float = position.distance_to(target.position)
        var effective_range: float = arena.commander.weapon_range(self,target) if arena.get("commander")!=null else float(weapon.get("range",0.0))
        if distance <= effective_range and distance >= float(weapon.get("min_range", 0.0)) and arena.clear_shot(position, target.position, air, target.air, target):
            moving = false
            if cooldown <= 0.0 and stationary_time >= float(weapon.get("brace",0.0)):
                fire(target)
        elif not hold_position and distance < float(weapon.get("min_range", 0.0)):
            var retreat: Vector2 = position - target.position
            if retreat.length_squared() < 0.01:
                retreat = Vector2.RIGHT
            if not moving or destination.distance_to(target.position) < float(weapon.get("min_range", 0.0)):
                _begin_route(position + retreat.normalized() * (float(weapon.get("min_range", 0.0)) - distance + 30.0))
        elif not hold_position and (distance > effective_range * 0.87 or not arena.clear_shot(position, target.position, air, target.air, target)):
            if not moving or destination.distance_to(target.position) > 60.0:
                _begin_route(target.position)
    if moving:
        _step_movement(delta)
    if not moving and target == null and capture_target == null:
        GroundOrders.advance(self)
    var desired_turret_angle := facing
    if target != null and is_instance_valid(target) and target.hp > 0.0:
        desired_turret_angle = (target.position - position).angle()
    turret_angle = lerp_angle(turret_angle, desired_turret_angle, minf(1.0, (9.0 if target != null else 4.0) * delta))
    _publish_visual()

func _publish_visual() -> void:
    # Position rides the node transform. Meshes are already quantized to 64 headings,
    # so a steady hull/turret can keep the previous canvas commands.
    var effects := fire_feedback > 0.0 or hit_feedback > 0.0 or (capture_target != null and is_instance_valid(capture_target))
    if effects or (selected and moving):
        _visual_pose = -1
        queue_redraw()
        return
    var hull := posmod(int(round(facing / TAU * 64.0)), 64)
    var aim := posmod(int(round(turret_angle / TAU * 64.0)), 64)
    var hp_steps := int(round((hp / maxf(1.0, max_hp)) * 38.0))
    var pose := hull | (aim << 6) | (hp_steps << 12)
    if selected:
        pose |= 1 << 18
    if hold_position:
        pose |= 1 << 19
    if unit_xp >= 100.0:
        pose |= 1 << 20
    if not pending_orders.is_empty():
        pose |= 1 << 21
    if pose != _visual_pose:
        _visual_pose = pose
        queue_redraw()

func _step_movement(delta: float) -> void:
    if arena.begin_column_spread(self) and not moving:
        return
    if route_index >= route.size():
        if not arena.begin_column_spread(self, true):
            moving = false
        return
    var waypoint: Vector2 = route[route_index]
    if position.distance_to(waypoint) <= 2.0:
        route_index += 1
        if route_index >= route.size():
            if not arena.begin_column_spread(self, true):
                moving = false
            return
        waypoint = route[route_index]
    if arena.same_direction_holds_cell(self, waypoint):
        traffic_wait += delta
        if traffic_wait < 3.5:
            return
        traffic_wait = 0.0
    var direction := (waypoint - position).normalized()
    var separation := Vector2.ZERO
    var neighbors: Array = []
    if not air:
        # Cover every steering/lateral endpoint, plus separation/repath checks.
        # Other actors cannot move during this actor's synchronous step.
        var reach := Vector2.ONE * minf(move_speed * 1.2 * delta, maxf(8.0,position.distance_to(waypoint)))
        neighbors = arena.nearby_units(position-reach, position+reach, radius + 8.0)
        for other in neighbors:
            if column_move or other == self or not is_instance_valid(other) or other.hp <= 0.0 or other.air:
                continue
            var offset: Vector2 = position - other.position
            var gap = radius + other.radius + 5.0
            if offset.length_squared() > 0.001 and offset.length() < gap:
                separation += offset.normalized() * (gap - offset.length()) / gap
    var steering := (direction + separation * 1.5).normalized()
    if steering.length_squared() < 0.01:
        steering = direction
    var speed_factor := 1.0
    if arena.get("commander") != null and arena.commander.buff_at(team, "breakthrough_order", position) and armor == "HEAVY":
        speed_factor = 1.2
    elif arena.get("commander") != null and armor == "LIGHT" and arena.commander.buff_at(team, "scavenger_convoy", position):
        speed_factor = 1.1
    var next_position := position + steering * minf(move_speed * speed_factor * delta, position.distance_to(waypoint))
    if arena.can_traverse(position, next_position, radius, air, self, neighbors):
        position = next_position
        arena.update_unit_occupancy(self)
        blocked_time = 0.0
        traffic_wait = 0.0
        facing = lerp_angle(facing, steering.angle(), minf(1.0, delta * (4.5 if profile_name == "vehicle" else 7.0)))
    else:
        # A blocked final few pixels are acceptable for ordinary move orders only.
        # Captures and combat approaches retain their exact arrival rules.
        if route_index == route.size() - 1 and position.distance_to(destination) <= 6.0 and capture_target == null and target == null and not explicit_attack:
            if not arena.begin_column_spread(self, true):
                moving = false
            return
        # Try a lateral step around traffic without cutting through static corners.
        # In a file, only a step that still gets closer to the shared waypoint counts.
        blocked_time += delta
        traffic_wait += delta
        var waypoint_distance := position.distance_squared_to(waypoint)
        var best_slide := Vector2.INF
        var best_progress := -INF
        var slid := false
        # A file that is already touching needs a longer nudge than one frame of speed.
        var slide_distance := maxf(move_speed * delta, 6.0) if column_move else minf(move_speed * delta, 8.0)
        slide_distance = minf(slide_distance, 8.0)
        for angle in [0.0, 0.52, -0.52, 1.05, -1.05, 1.57, -1.57]:
            var lateral := direction.rotated(angle)
            var candidate := position + lateral * slide_distance
            if not arena.can_traverse(position, candidate, radius, air, self, neighbors):
                continue
            if not column_move:
                position = candidate
                arena.update_unit_occupancy(self)
                slid = true
                break
            var progress := waypoint_distance - candidate.distance_squared_to(waypoint)
            if progress > best_progress:
                best_progress = progress
                best_slide = candidate
                slid = true
        if column_move and slid and best_slide != Vector2.INF:
            position = best_slide
            arena.update_unit_occupancy(self)
            blocked_time = 0.0
            traffic_wait = 0.0
        if blocked_time >= 0.75 + float(get_instance_id() % 7) * 0.06:
            blocked_time = 0.0
            # Keep the route while nearby traffic is still moving; retry later.
            var waiting_for_traffic := false
            for other in neighbors:
                if is_instance_valid(other) and other != self and other.hp > 0.0 and other.moving and position.distance_to(other.position) < radius + other.radius + 8.0:
                    waiting_for_traffic = true
                    break
            if waiting_for_traffic and traffic_wait < 2.5:
                return
            traffic_wait = 0.0
            var alternative: PackedVector2Array = arena.column_route(position, column_spine, air, self) if column_move and not column_spine.is_empty() else arena.find_route(position, destination, air, null if column_move else self)
            if not alternative.is_empty():
                route = alternative
                route_index = 0

func fire(enemy) -> void:
    if ammo == 0:
        return
    fire_feedback = 0.12
    cooldown = float(weapon.get("interval", 1.0))
    var shot := weapon.duplicate(true)
    if bool(weapon.get("grid_energy", false)):
        if arena.power_ok(team): shot.damage *= 1.1
        else: cooldown *= 2.0
    if arena.get("commander")!=null: cooldown=arena.commander.modify_shot(self,enemy,shot,cooldown)
    arena.spawn_projectile(self, enemy, shot)
    if ammo > 0:
        ammo -= 1

func receive_damage(value: float, attacker) -> void:
    if hp <= 0.0:
        return
    if capture_target != null:
        capture_progress = 0.0
        capture_pause = 1.0
    if arena.get("commander")!=null and armor=="HEAVY" and arena.commander.buff_at(team,"breakthrough_order",position): value*=0.8
    if unit_id=="r_jugger" and is_instance_valid(attacker) and absf(angle_difference(facing,(attacker.position-position).angle()))<PI/3.0: value*=0.8
    if unit_id=="a_tempest" and arena.get("commander")!=null and arena.commander.has_research(team,"countermeasures") and is_instance_valid(attacker):
        var attacker_weapon: Variant = attacker.get("weapon")
        if attacker_weapon is Dictionary and str(attacker_weapon.get("type",""))=="AA": value*=0.85
    hp = maxf(0.0, hp - value)
    if value > 0.0: hit_feedback = 0.16
    if team == 1 and not explicit_attack and not moving and attacker != null and is_instance_valid(attacker) and can_hit(attacker):
        target = attacker
    if hp <= 0.0:
        destroyed.emit(self)
        queue_free()
    else:
        queue_redraw()

func _draw() -> void:
    GroundOrders.draw_route(self)
    if selected:
        draw_arc(Vector2.ZERO,radius+8.0,0.0,TAU,36,Color("#e1f39e"),2.2)
        if hold_position:
            draw_string(ThemeDB.fallback_font,Vector2(-15,28),"HOLD",HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color("#e1f39e"))
    var artwork := unit_id
    if unit_id == "g_junker" and salvage_tier > 0:
        artwork = "g_junker_salvage_%d" % salvage_tier
    if not IndustrialArt.has_asset(artwork):
        artwork = "gunship" if air else ("rifleman" if profile_name == "infantry" else "tank")
    # Recoil is visual only: collision, aim and navigation keep their exact transforms.
    draw_set_transform(-Vector2.from_angle(turret_angle) * 3.0 * fire_feedback / 0.12)
    IndustrialArt.draw_asset(self,artwork,team,facing,turret_angle)
    draw_set_transform(Vector2.ZERO)
    if hit_feedback > 0.0:
        draw_arc(Vector2.ZERO, radius + 3.0, 0, TAU, 20, Color(1.0, 0.65, 0.3, hit_feedback / 0.16), 2.0)
    if capture_target != null and is_instance_valid(capture_target):
        draw_rect(Rect2(-19,-radius-23,38,4),Color("#182c25"))
        draw_rect(Rect2(-19,-radius-23,38 * minf(1.0,capture_progress / (0.7 if capture_target.team==-1 else 3.0)),4),Color("#efcd76"))
    var amount := hp / maxf(1.0, max_hp)
    var bar_y = -51.0 if profile_name=="infantry" else -64.0
    if unit_xp>=100.0: draw_string(ThemeDB.fallback_font,Vector2(-18,bar_y-5),"VET",HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color("#efcd76"))
    draw_rect(Rect2(-19, bar_y, 38, 4), Color("#1d2524"))
    draw_rect(Rect2(-19, bar_y, 38 * amount, 4), Color("#94d889") if amount > 0.4 else Color("#e2a052"))
