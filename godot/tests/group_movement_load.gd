extends SceneTree
const Arena = preload("res://scripts/combat/combat_arena.gd")
const Unit = preload("res://scripts/combat/combat_unit.gd")

func _initialize() -> void:
 call_deferred("_run")

func _run() -> void:
 # Isolate real movement/collision code from rendering, AI, and building updates.
 for count in [32,96,192]:
  for crowded in [false,true]:
   var arena = Arena.new()
   arena._create_navigation()
   for index in range(count):
    var actor = Unit.new()
    var start = Vector2(160+(index%12)*22,160+(index/12)*22)
    actor.configure(arena,{"id":"a_ranger","armor":"PERSONNEL","speed":90},0,start,{})
    arena.units.append(actor)
   var start_us = Time.get_ticks_usec()
   for actor in arena.units:
    var goal = actor.position+Vector2(700,0)
    if crowded: goal=Vector2(1000,330)+(actor.position-Vector2(280,280))*0.4
    actor.order_move(goal)
   var order_ms = (Time.get_ticks_usec()-start_us)/1000.0
   var samples: Array[float] = []
   for step in range(180):
    start_us=Time.get_ticks_usec()
    arena.invalidate_occupancy()
    for actor in arena.units:
     if actor.moving: actor._step_movement(1.0/60.0)
    samples.append((Time.get_ticks_usec()-start_us)/1000.0)
   var total := 0.0
   for sample in samples: total+=sample
   samples.sort()
   print("MOVE count=%d crowded=%s order_ms=%.2f tick_mean_ms=%.2f tick_p95_ms=%.2f" % [count,crowded,order_ms,total/samples.size(),samples[int(samples.size()*0.95)]])
   for actor in arena.units: actor.free()
   arena.free()
 quit(0)
