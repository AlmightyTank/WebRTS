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
  # Ordinary moves may stop within six pixels when the last step is blocked.
  if crowd[i].position.distance_to(goals[i]) <= 6.0:
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
 world.selected.clear()
 world.obstacles.clear()
 world._create_navigation()
 world.formation = "GROUP"
 world.invalidate_occupancy()
 var file: Array = []
 for i in range(5):
  var marcher = load("res://scripts/combat/combat_unit.gd").new()
  marcher.arena = world
  marcher.radius = 18.0
  marcher.team = 0
  marcher.move_speed = 90.0
  marcher.position = Vector2(180.0 + float(i % 3) * 36.0, 376.0 + float(i / 3) * 36.0)
  world.units.append(marcher)
  world.selected.append(marcher)
  file.append(marcher)
 var march_goal := Vector2(1000, 400)
 world.issue_order(march_goal)
 world.issue_order(Vector2(1280, 400), false, true)
 var slots: Array[Vector2] = []
 var goal: Vector2 = file[0].column_goal
 var deferred := 0
 for marcher in file:
  slots.append(marcher.column_slot)
  expect(marcher.column_move and marcher.pending_orders.size() == 1 and marcher.pending_orders[0].has("column_spine"), "Group order files to the destination before the queued spread")
  expect(marcher.route[marcher.route.size() - 1].distance_to(goal) < 4.0, "March route ends at the shared destination")
  if marcher.column_slot.distance_to(goal) > 30.0:
   deferred += 1
   expect(marcher.route[marcher.route.size() - 1].distance_to(marcher.column_slot) > 30.0, "Spread cell stays off the march route")
 expect(deferred >= 3, "The group keeps distinct spread cells for after arrival")
 var origin := Vector2.ZERO
 for marcher in file:
  origin += marcher.position
 origin /= float(file.size())
 var axis: Vector2 = goal - origin
 var axis_dir := axis.normalized()
 var saw_file := false
 var broke_file := false
 var released_early := false
 var closest: Array[float] = []
 var second_slots: Array[Vector2] = []
 var captured_second: Array[bool] = []
 var crossed_second: Array[bool] = []
 var cross_y: Array[float] = []
 for _i in file.size():
  closest.append(10000.0)
  second_slots.append(Vector2.ZERO)
  captured_second.append(false)
  crossed_second.append(false)
  cross_y.append(0.0)
 var packed := false
 for frame in range(4800):
  var moving_now := false
  for marcher in file:
   marcher._physics_process(1.0 / 60.0)
   if marcher.moving or marcher.pending_orders.size() > 0:
    moving_now = true
  var band: Array = []
  for i in range(file.size()):
   var marcher = file[i]
   closest[i] = minf(closest[i], marcher.position.distance_to(slots[i]))
   if not marcher.column_move and marcher.position.distance_to(goal) > 180.0 and not captured_second[i]:
    released_early = true
   if marcher.pending_orders.is_empty() and marcher.column_move and marcher.column_goal.distance_to(goal) > 80.0 and not captured_second[i]:
    captured_second[i] = true
    second_slots[i] = marcher.column_slot
   if not marcher.column_move:
    continue
   if marcher.column_goal.distance_to(goal) < 80.0:
    var offset: Vector2 = marcher.position - origin
    var along := offset.dot(axis_dir)
    var lateral := (offset - axis_dir * along).length()
    if along > 220.0 and along < axis.length() - 120.0:
     band.append(marcher)
     if lateral > 28.0:
      broke_file = true
   elif not crossed_second[i] and marcher.position.distance_to(goal) > 40.0 and marcher.position.distance_to(marcher.column_goal) < marcher.column_goal.distance_to(goal) * 0.55:
    crossed_second[i] = true
    cross_y[i] = marcher.position.y
  if band.size() >= 3:
   saw_file = true
  var arrived_now := true
  for i in range(file.size()):
   if closest[i] > 16.0:
    arrived_now = false
  if arrived_now:
   packed = true
  if packed and not moving_now:
   break
 expect(saw_file, "Units travel single file before the destination")
 expect(not broke_file, "The file does not walk abreast")
 expect(not released_early, "Units keep the file until they reach the destination")
 var arrived_slots := 0
 for i in range(file.size()):
  if closest[i] < 16.0:
   arrived_slots += 1
  else:
   print("Spread ", i, " closest ", closest[i], " slot ", slots[i], " at ", file[i].position)
 expect(arrived_slots == file.size(), "Units occupy their spread cells after the march: " + str(arrived_slots))
 var second_arrived := 0
 for i in range(file.size()):
  if captured_second[i] and file[i].position.distance_to(second_slots[i]) < 16.0:
   second_arrived += 1
  else:
   print("Queued spread ", i, " at ", file[i].position, " slot ", second_slots[i], " captured ", captured_second[i], " moving ", file[i].moving)
 expect(second_arrived == file.size(), "Queued order spreads after its own destination: " + str(second_arrived))
 var cross_span := 0.0
 var crossed := 0
 for i in range(file.size()):
  if not crossed_second[i]:
   continue
  crossed += 1
  for j in range(i):
   if crossed_second[j]:
    cross_span = maxf(cross_span, absf(cross_y[i] - cross_y[j]))
 expect(crossed == file.size() and cross_span < 36.0, "Queued march stays single file: " + str(crossed) + " span " + str(cross_span))
 var spread_out := true
 for i in range(file.size()):
  for j in range(i):
   if file[i].position.distance_to(file[j].position) < file[i].radius + file[j].radius:
    spread_out = false
 expect(spread_out, "Spread cells do not leave the group stacked")
 for marcher in file:
  marcher.free()
 world.units.clear()
 actor.free()
 world.free()
 if failures.is_empty():
  print("MOVEMENT_ORDERS_SMOKE_PASS")
 quit(0 if failures.is_empty() else 1)
