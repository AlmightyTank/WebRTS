extends SceneTree
const Arena = preload("res://scripts/combat/combat_arena.gd")
const Unit = preload("res://scripts/combat/combat_unit.gd")
var failures: int = 0

func check(value: bool, message: String) -> void:
 if not value:
  failures += 1
  push_error(message)

func _initialize() -> void:
 call_deferred("_run")

func _run() -> void:
 var arena = Arena.new()
 arena._create_navigation()
 arena.obstacles.clear()
 for index in range(120):
  var actor = Unit.new()
  actor.configure(arena,{"id":"a_ranger","armor":"PERSONNEL","speed":90},0,Vector2(80+(index%15)*90,80+(index/15)*90),{})
  arena.units.append(actor)
 # Compare indexed collision decisions against the original exhaustive check.
 for index in range(400):
  var point := Vector2(30+(index*71)%1800,30+(index*137)%1100)
  var expected := true
  for actor in arena.units:
   if point.distance_squared_to(actor.position) < pow(9.0+actor.radius+1.0,2.0):
    expected = false
  check(arena.can_occupy(point,9,false)==expected,"Indexed occupancy differs from exhaustive scan")
 var first = arena.units[0]
 first.position = Vector2(1700,1000)
 arena.update_unit_occupancy(first)
 check(not arena.can_occupy(first.position,9,false),"Same-tick movement missing from index")
 check(arena.can_occupy(Vector2(80,80),9,false),"Old cell still blocks movement")
 check(not arena.can_traverse(Vector2(1650,1000),Vector2(1750,1000),9,false),"Swept collision missed a unit")
 first.hp = 0
 check(arena.can_occupy(first.position,9,false),"Dead unit still blocks movement")
 check(not arena.can_occupy(Vector2(1,1),9,false),"Board bounds ignored")
 var spawned = Unit.new()
 spawned.configure(arena,{"id":"a_ranger","armor":"PERSONNEL","speed":90},0,Vector2(1750,1000),{})
 arena.units.append(spawned)
 check(not arena.can_occupy(spawned.position,9,false),"Same-tick spawn missing from index")
 arena.units.erase(spawned)
 arena.invalidate_occupancy()
 check(arena.can_occupy(spawned.position,9,false),"Removed unit still blocks movement")
 spawned.free()
 for actor in arena.units:
  actor.free()
 arena.free()
 print("Movement occupancy regression failures: %d" % failures)
 quit(1 if failures else 0)
