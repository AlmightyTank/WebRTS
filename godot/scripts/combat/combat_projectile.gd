extends Node2D
## Real moving projectile: segment-circle collision avoids high-speed tunnelling.
var arena
var shooter
var owner_team := 0
var target
var damage := 0.0
var weapon_kind := "SMALL_ARMS"
var speed := 520.0
var expire := 3.0
var anti_air := false
var target_air := false
var source_air := false
var is_homing := false
var destination := Vector2.ZERO
var velocity := Vector2.ZERO
var _drawn_velocity := Vector2.INF
var _scan_hit
var _scan_t := INF

func configure(world: Node2D, origin: Vector2, source, enemy, profile: Dictionary) -> void:
 arena = world
 position = origin
 shooter = source
 owner_team = source.team
 target = enemy
 damage = float(profile.get("damage",10.0))
 weapon_kind = str(profile.get("type","SMALL_ARMS"))
 speed = float(profile.get("projectile_speed",520.0))
 anti_air = bool(profile.get("anti_air",false))
 target_air = enemy.air
 source_air = source.air
 is_homing = bool(profile.get("homing",false))
 destination = enemy.position
 velocity = (destination-position).normalized()*speed

func _physics_process(delta: float) -> void:
 if arena.paused or arena.battle_over:
  return
 expire -= delta
 if expire <= 0.0:
  queue_free()
  return
 if is_homing and is_instance_valid(target) and target.hp>0.0 and target.team!=owner_team:
  destination = target.position
  var desired := (destination-position).normalized()*speed
  velocity = velocity.lerp(desired,minf(1.0,6.0*delta)).normalized()*speed
 var next_position := position+velocity*delta
 if not arena.clear_shot(position,next_position,source_air,target_air,target):
  queue_free()
  return
 var path := next_position-position
 var travel_squared := maxf(0.0001,path.length_squared())
 _scan_hit = null
 _scan_t = INF
 _scan_hits(arena.units, path, travel_squared)
 var buildings: Variant = arena.get("structures")
 if buildings is Array:
  _scan_hits(buildings, path, travel_squared)
 if _scan_hit != null:
  var amount = damage*arena.armor_multiplier(weapon_kind,_scan_hit.armor)
  if amount > 0.0:
   _scan_hit.receive_damage(amount,shooter if is_instance_valid(shooter) else null)
   arena.register_hit(shooter,_scan_hit,amount)
  queue_free()
  return
 position = next_position
 if not velocity.is_equal_approx(_drawn_velocity):
  _drawn_velocity = velocity
  queue_redraw()

func _scan_hits(list: Array, path: Vector2, travel_squared: float) -> void:
 for unit in list:
  if not is_instance_valid(unit) or unit.hp<=0.0 or unit.team==owner_team:
   continue
  # A dual-purpose weapon's shot uses the layer it was actually fired at.
  if unit.air != target_air:
   continue
  var t := clampf((unit.position-position).dot(path)/travel_squared,0.0,1.0)
  var closest := position+path*t
  if closest.distance_to(unit.position) <= unit.radius+5.0 and t<_scan_t:
   _scan_t=t
   _scan_hit=unit

func _draw() -> void:
 var missile := is_homing or weapon_kind in ["MISSILE", "ROCKET"]
 var heavy := weapon_kind not in ["SMALL_ARMS", "SNIPER"]
 var tint := Color("#8be2ff") if target_air else Color("#f3d49b")
 var back := -velocity.normalized()
 draw_line(Vector2.ZERO, back * (18.0 if missile else (10.0 if heavy else 6.0)), Color(tint, 0.45), 4.0 if heavy else 2.0)
 draw_line(Vector2.ZERO, back * (8.0 if heavy else 4.0), tint, 2.0)
 draw_circle(Vector2.ZERO, 3.0 if heavy else 1.6, Color("#fff0cd"))
