extends SceneTree
var failures := 0

func expect(value: bool, label: String) -> void:
 if value:
  print("PASS: " + label)
 else:
  failures += 1
  push_error(label)

func _initialize() -> void:
 var world = load("res://scripts/combat/combat_arena.gd").new()
 world._create_navigation()
 world.registry = {"weapon_armor_multipliers": {"SMALL_ARMS": {"PERSONNEL": 1.0}}}
 var actor = load("res://scripts/combat/combat_unit.gd").new()
 var enemy = load("res://scripts/combat/combat_unit.gd").new()
 actor.arena = world
 enemy.arena = world
 actor.position = Vector2(500, 500)
 enemy.position = Vector2(550, 500)
 enemy.team = 1
 actor.weapon = {"range": 200.0, "min_range": 100.0, "anti_air": true, "anti_ground": true, "damage": 10.0, "projectile_speed": 500.0}
 actor.cooldown = 100.0
 world.units.assign([actor, enemy])
 actor.order_attack(enemy)
 actor._physics_process(0.1)
 expect(actor.position.x < 500.0, "Minimum-range weapons retreat rather than advance into their dead zone")
 actor.order_move(Vector2(900, 500), true)
 actor.target = enemy
 actor._begin_route(Vector2(550, 500))
 enemy.hp = 0.0
 actor._physics_process(0.1)
 expect(actor.target == null and actor.destination == Vector2(900, 500), "Attack-move immediately resumes its original goal after target death")
 enemy.hp = 100.0
 actor.order_attack(enemy)
 actor._begin_route(enemy.position)
 enemy.team = actor.team
 actor._physics_process(0.1)
 expect(actor.target == null and not actor.moving and not actor.explicit_attack, "Captured targets cancel explicit pursuit")
 enemy.team = 1
 actor.position = Vector2(500, 500)
 var shot = load("res://scripts/combat/combat_projectile.gd").new()
 shot.configure(world, actor.position, actor, enemy, actor.weapon)
 shot._physics_process(0.1)
 expect(enemy.hp == 90.0, "Dual-purpose projectiles damage ground targets")
 enemy.air = true
 var air_shot = load("res://scripts/combat/combat_projectile.gd").new()
 air_shot.configure(world, actor.position, actor, enemy, actor.weapon)
 air_shot._physics_process(0.1)
 expect(enemy.hp == 80.0, "Dual-purpose projectiles also damage air targets")
 # queue_free is deferred even for standalone fixture nodes.
 actor.free()
 enemy.free()
 world.free()
 print("COMBAT_RELIABILITY_SMOKE: %d failures" % failures)
 quit(1 if failures else 0)
