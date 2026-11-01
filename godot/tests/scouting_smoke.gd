extends SceneTree
var failures := 0

func expect(value: bool, label: String) -> void:
 if value: print("PASS: " + label)
 else:
  failures += 1
  push_error(label)

func _initialize() -> void:
 call_deferred("_run")

func _run() -> void:
 var world = load("res://scenes/skirmish.tscn").instantiate()
 root.add_child(world)
 world.set_physics_process(false)
 world.paused = true
 var unit = world._spawn("a_sentinel", 0, Vector2(350, 600))
 world._refresh_fog()
 world._set_selected([unit])
 world.paused = false
 world._on_toolbar("SCOUT")
 world.paused = true
 expect(world.scouting.orders.has(unit) and unit.moving, "Scout button starts a reachable exploration route")
 expect(not world.fog.explored(0, unit.destination), "Scout destination uses unexplored terrain")
 var first_goal: Vector2 = unit.destination
 var enemy = world.structures[0]
 var enemy_position: Vector2 = enemy.position
 enemy.position = Vector2(1800, 100)
 world.scouting.start(world, unit)
 expect(unit.destination == first_goal, "Hidden enemy relocation does not influence exploration")
 enemy.position = enemy_position
 var explored_before: int = world.fog.explored_cells[0].size()
 for frame in range(2400):
  if unit.moving: unit._step_movement(1.0 / 60.0)
  if frame % 10 == 0:
   world._refresh_fog()
   world.scouting.tick(world)
 expect(world.fog.explored_cells[0].size() > explored_before, "Physical scouting expands team exploration")
 unit.order_stop()
 world.scouting.tick(world)
 expect(not world.scouting.orders.has(unit) and not unit.moving, "Stop cancels auto-scout without restarting it")
 world.scouting.start(world, unit)
 unit.order_move(Vector2(350, 600))
 world.scouting.tick(world)
 expect(not world.scouting.orders.has(unit), "Manual movement overrides scouting")
 world.scouting.start(world, world.units[0])
 expect(not world.scouting.orders.has(world.units[0]), "MCVs remain outside automatic combat scouting")
 for y in range(world.ROWS):
  for x in range(world.COLS): world.fog.explored_cells[0][Vector2i(x,y)] = true
 world.scouting.start(world, unit)
 expect(not world.scouting.orders.has(unit) and not unit.moving, "Completed exploration stops cleanly")
 var enemy_scout = world._spawn("a_sentinel", 1, Vector2(1500, 600))
 world._refresh_fog()
 world._ai_decide()
 expect(world.scouting.orders.has(enemy_scout), "Idle AI combat units use team exploration")
 world.scouting.orders.clear()
 # Leave only one unknown cell, separated from the scout by an impassable wall.
 world.obstacles.assign([Rect2(900, 0, 80, 1200)])
 world._rebuild_navigation()
 unit.position = Vector2(350, 600)
 world.fog.explored_cells[0].erase(Vector2i(32, 12))
 world.scouting.start(world, unit)
 expect(not world.scouting.orders.has(unit) and not unit.moving, "Unreachable unexplored terrain is skipped without wall clipping")
 world.reset_battle()
 expect(world.scouting.orders.is_empty(), "Restart clears scout assignments")
 world.queue_free()
 await process_frame
 print("SCOUTING_SMOKE: %d failures" % failures)
 quit(1 if failures else 0)
