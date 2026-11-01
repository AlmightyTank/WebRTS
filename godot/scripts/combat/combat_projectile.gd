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
var is_homing := false
var destination := Vector2.ZERO
var velocity := Vector2.ZERO

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
 if is_homing and is_instance_valid(target) and target.hp>0.0:
  destination = target.position
  var desired := (destination-position).normalized()*speed
  velocity = velocity.lerp(desired,minf(1.0,6.0*delta)).normalized()*speed
 var next_position := position+velocity*delta
 if not anti_air and not arena.clear_shot(position,next_position,false,false):
  queue_free()
  return
 var nearest
 var nearest_t := INF
 var path := next_position-position
 var travel_squared := maxf(0.0001,path.length_squared())
 for unit in arena.units:
  if not is_instance_valid(unit) or unit.hp<=0.0 or unit.team==owner_team:
   continue
  # Anti-air missiles cannot strike ground units; conventional projectiles cannot strike flying units.
  if unit.air and not anti_air:
   continue
  if not unit.air and anti_air:
   continue
  var t := clampf((unit.position-position).dot(path)/travel_squared,0.0,1.0)
  var closest := position+path*t
  if closest.distance_to(unit.position) <= unit.radius+5.0 and t<nearest_t:
   nearest_t=t
   nearest=unit
 if nearest != null:
  var amount = damage*arena.armor_multiplier(weapon_kind,nearest.armor)
  if amount > 0.0:
   nearest.receive_damage(amount,shooter if is_instance_valid(shooter) else null)
   arena.register_hit(shooter,nearest,amount)
  queue_free()
  return
 position = next_position
 queue_redraw()

func _draw() -> void:
 var tint := Color("#f3d49b") if not anti_air else Color("#8be2ff")
 draw_line(Vector2.ZERO,-velocity.normalized()*(10.0 if anti_air else 5.0),tint,3.0)
 draw_circle(Vector2.ZERO,3.3 if anti_air else 2.2,tint)
