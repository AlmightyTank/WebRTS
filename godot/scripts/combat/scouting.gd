extends RefCounted
## Exploration uses only team exploration and static terrain, never hidden actors.
var orders: Dictionary = {}

func start(world, unit) -> void:
 if not world.fog_enabled or world.fog == null or unit.hp <= 0: return
 if unit.get("order_revision") == null: return # Keep harvesters on their economy jobs.
 unit.order_stop()
 orders[unit] = {"revision": unit.order_revision, "failed": {}}
 _next(world, unit)

func tick(world) -> void:
 for unit in orders.keys():
  if not is_instance_valid(unit):
   orders.erase(unit)
   continue
  if unit.hp <= 0 or unit.order_revision != orders[unit].revision:
   orders.erase(unit)
  elif not unit.moving and unit.target == null:
   _next(world, unit)

func _next(world, unit) -> void:
 var candidates: Array[Vector2] = []
 var failed: Dictionary = orders[unit].failed
 for y in range(world.ROWS):
  for x in range(world.COLS):
   var cell := Vector2i(x, y)
   var point: Vector2 = world.cell_center(cell)
   if not failed.has(cell) and not world.fog.explored(unit.team, point) and (unit.air or not world.navigation.is_point_solid(cell)):
    candidates.append(point)
 candidates.sort_custom(func(a: Vector2, b: Vector2): return unit.position.distance_squared_to(a) < unit.position.distance_squared_to(b))
 for point in candidates:
  var path: Array = world.find_route(unit.position, point, unit.air)
  if path.is_empty():
   failed[world.world_cell(point)] = true
   continue
  unit.order_move(point)
  orders[unit].revision = unit.order_revision
  return
 orders.erase(unit) # Fully explored, or no remaining reachable scouting points.
