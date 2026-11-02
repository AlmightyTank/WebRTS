extends "res://scripts/combat/combat_arena.gd"
## Inclusive timings: callers include time spent in their measured children.
var timings: Dictionary = {}
var calls: Dictionary = {}

func record(label: String, start: int) -> void:
 timings[label] = timings.get(label,0) + Time.get_ticks_usec()-start
 calls[label] = calls.get(label,0)+1

func can_traverse(origin: Vector2, finish: Vector2, radius: float, is_air: bool, actor = null, neighbors = null) -> bool:
 var start := Time.get_ticks_usec()
 var result := super.can_traverse(origin,finish,radius,is_air,actor,neighbors)
 record("traverse",start)
 return result

func can_occupy(point: Vector2, radius: float, is_air: bool, actor = null, neighbors = null) -> bool:
 var start := Time.get_ticks_usec()
 var result := super.can_occupy(point,radius,is_air,actor,neighbors)
 record("occupy",start)
 return result

func nearby_units(origin: Vector2, finish: Vector2, margin: float) -> Array:
 var start := Time.get_ticks_usec()
 var result := super.nearby_units(origin,finish,margin)
 record("nearby",start)
 return result

func find_route(origin: Vector2, destination: Vector2, is_air: bool, actor = null, avoid_units: bool = true) -> PackedVector2Array:
 var start := Time.get_ticks_usec()
 var result := super.find_route(origin,destination,is_air,actor,avoid_units)
 record("route",start)
 return result
