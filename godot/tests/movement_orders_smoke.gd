extends SceneTree
## Deterministic fixtures, independent of AI, scenery and frame timing.
var failures: Array[String] = []

func expect(value: bool, label: String) -> void:
 if value:
  print("PASS: " + label)
 else:
  failures.append(label)
  push_error(label)

func _initialize() -> void:
 var world = load("res://scripts/combat/combat_arena.gd").new()
 world.obstacles.assign([Rect2(400, 0, 60, 2000)])
 world._create_navigation()
 expect(world.find_route(Vector2(200, 200), Vector2(700, 200), false).is_empty(), "Unreachable goals do not append a direct wall-crossing waypoint")
 expect(not world.can_traverse(Vector2(300, 200), Vector2(550, 200), 18, false), "Swept ground movement rejects tunneling through a wall")
 expect(world.can_traverse(Vector2(300, 200), Vector2(550, 200), 18, true), "Aircraft retain obstacle bypass")
 world.obstacles.assign([Rect2(400, 100, 60, 300)])
 world._create_navigation()
 expect(not world.find_route(Vector2(200, 200), Vector2(700, 200), false).is_empty(), "Reachable goals route around a wall")
 var actor = load("res://scripts/combat/combat_unit.gd").new()
 actor.arena = world
 actor.position = Vector2(200, 200)
 actor.move_speed = 90
 world.units.append(actor)
 actor.order_move(Vector2(700, 200))
 for frame in range(1800):
  if not actor.moving:
   break
  actor._step_movement(1.0 / 60.0)
  if world.obstacles[0].grow(actor.radius).has_point(actor.position):
   expect(false, "Movement stays outside wall")
   break
 expect(actor.position.distance_to(Vector2(700, 200)) <= 3.0, "Ground actor arrives around obstacle")
 world.obstacles.clear()
 world._create_navigation()
 actor.position = Vector2(200, 200)
 actor.order_move(Vector2(600, 200))
 actor._step_movement(10.0)
 expect(actor.position.x < 600, "Large delta does not skip route waypoints")
 actor.order_move(Vector2(500, 500), true)
 actor.order_stop()
 expect(not actor.moving and actor.route.is_empty() and not actor.has_attack_move_goal and actor.target == null, "Stop cancels route and attack-move intent")
 actor.order_move(Vector2(500, 500), true)
 actor.order_move(Vector2(300, 300))
 expect(not actor.aggressive and not actor.has_attack_move_goal, "Move replaces attack-move intent")
 var enemy = load("res://scripts/combat/combat_unit.gd").new()
 enemy.team = 1
 enemy.position = Vector2(350, 300)
 world.registry = {"weapon_armor_multipliers": {"SMALL_ARMS": {"PERSONNEL": 1.0}}}
 actor.order_attack(enemy)
 expect(actor.target == enemy and actor.explicit_attack and not actor.moving, "Explicit attack replaces movement and locks commanded target")
 actor.order_attack(actor)
 expect(actor.target == enemy and actor.explicit_attack, "Invalid attack leaves current order intact")
 actor.order_stop()
 expect(not actor.explicit_attack and actor.target == null, "Stop clears explicit target lock")
 enemy.free()
 actor.position = Vector2(200, 200)
 actor.order_move(Vector2(320, 200))
 actor.queue_move(Vector2(320, 360))
 actor.queue_move(Vector2(520, 360))
 expect(actor.pending_orders.size() == 2 and actor.destination == Vector2(320, 200), "Queued waypoints preserve active destination")
 for frame in range(1800):
  actor._physics_process(1.0 / 60.0)
 expect(actor.pending_orders.is_empty() and actor.position.distance_to(Vector2(520, 360)) < 3.0, "FIFO waypoints physically complete")
 actor.queue_move(Vector2(800, 400))
 actor.queue_move(Vector2(800, 600))
 actor.order_stop()
 expect(actor.pending_orders.is_empty(), "Stop clears queued waypoints")
 world.units.clear()
 var vehicle = load("res://scripts/economy/economy_vehicle.gd").new()
 vehicle.arena = world
 vehicle.position = Vector2(200, 200)
 world.units.append(vehicle)
 vehicle.order_move(Vector2(320, 200))
 vehicle.queue_move(Vector2(320, 360))
 for frame in range(1200):
  vehicle._physics_process(1.0 / 60.0)
 expect(vehicle.pending_orders.is_empty() and vehicle.position.distance_to(Vector2(320, 360)) < 3.0, "Economy vehicles complete queued waypoints")
 vehicle.queue_move(Vector2(700, 400))
 vehicle.queue_move(Vector2(800, 400))
 vehicle.set_harvest()
 expect(vehicle.pending_orders.is_empty(), "Harvest command replaces queued movement")
 world.units.clear()
 vehicle.free()
 world.obstacles.assign([Rect2(600, 0, 96, 240), Rect2(600, 624, 96, 576)])
 world._create_navigation()
 var crowd: Array = []
 var goals = world.formation_targets(Vector2(250, 400), 25, Vector2(1000, 400), "LINE")
 for i in range(25):
  var unit = load("res://scripts/combat/combat_unit.gd").new()
  unit.arena = world
  unit.radius = 18.0
  unit.position = Vector2(180 + (i % 5) * 48, 200 + (i / 5) * 48)
  world.units.append(unit)
  crowd.append(unit)
  unit.order_move(goals[i])
 for frame in range(3600):
  for unit in crowd:
   if unit.moving:
    unit._step_movement(1.0 / 60.0)
 var arrived := 0
 for i in range(crowd.size()):
  if crowd[i].position.distance_to(goals[i]) < 3.0:
   arrived += 1
  else:
   print("Crowd ", i, " at ", crowd[i].position, " goal ", goals[i], " moving ", crowd[i].moving)
 expect(arrived == 25, "All 25 vehicles pass a chokepoint and converge on distinct slots: " + str(arrived))
 var separated := true
 for i in range(crowd.size()):
  for j in range(i):
   if crowd[i].position.distance_to(crowd[j].position) < crowd[i].radius + crowd[j].radius:
    separated = false
 expect(separated, "Arriving vehicles do not overlap")
 for unit in crowd:
  unit.free()
 world.units.clear()
 world.selected.clear()
 world.obstacles.assign([Rect2(576, 0, 48, 408), Rect2(576, 504, 48, 700)])
 world._create_navigation()
 world.formation = "GROUP"
 world.invalidate_occupancy()
 var column: Array = []
 for i in range(6):
  var tanker = load("res://scripts/combat/combat_unit.gd").new()
  tanker.arena = world
  tanker.radius = 18.0
  tanker.team = 0
  tanker.position = Vector2(220.0 + float(i % 3) * 52.0, 400.0 + float(i / 3) * 52.0)
  world.units.append(tanker)
  world.selected.append(tanker)
  column.append(tanker)
 world.issue_order(Vector2(980, 456))
 var top_wall: Rect2 = world.obstacles[0]
 var bottom_wall: Rect2 = world.obstacles[1]
 for tanker in column:
  expect(tanker.destination.x > 700.0, "Group order keeps the arrival cell beyond the wall")
  var previous: Vector2 = tanker.position
  var crosses := false
  for waypoint in tanker.route:
   if world._segment_hits_rect(previous, waypoint, top_wall) or world._segment_hits_rect(previous, waypoint, bottom_wall):
    crosses = true
   previous = waypoint
  expect(not crosses, "Column route follows the gap instead of the wall")
 var max_in_one_cell := 0
 for frame in range(2400):
  var occupants := {}
  for tanker in column:
   if tanker.moving:
    tanker._step_movement(1.0 / 60.0)
   var cell: Vector2i = world.world_cell(tanker.position)
   if cell.x == 12:
    var key := cell.y
    occupants[key] = int(occupants.get(key, 0)) + 1
    max_in_one_cell = maxi(max_in_one_cell, int(occupants[key]))
 var through := 0
 for tanker in column:
  if tanker.position.x > 650.0:
   through += 1
  else:
   print("Column unit at ", tanker.position, " moving ", tanker.moving)
 expect(through == column.size(), "Column files through a one-cell gap: " + str(through))
 expect(max_in_one_cell <= 1, "Only one vehicle occupies the gap cell at a time")
 for tanker in column:
  tanker.free()
 world.units.clear()
 actor.free()
 world.free()
 if failures.is_empty():
  print("MOVEMENT_ORDERS_SMOKE_PASS")
 quit(0 if failures.is_empty() else 1)
