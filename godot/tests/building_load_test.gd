extends SceneTree
## Rendered diagnostic, not a release-build performance guarantee.
const Structure = preload("res://scripts/economy/structure.gd")
var samples: Array[float] = []

func _initialize() -> void:
 call_deferred("_run")

func _measure(label: String) -> void:
 for i in range(20): await process_frame
 samples.clear()
 var previous = Time.get_ticks_usec()
 for i in range(120):
  await process_frame
  var now = Time.get_ticks_usec()
  samples.append((now-previous)/1000.0)
  previous=now
 samples.sort()
 var total := 0.0
 for value in samples: total+=value
 print("LOAD ",label," mean_ms=",snappedf(total/samples.size(),0.01)," p95_ms=",snappedf(samples[int(samples.size()*0.95)],0.01)," process_ms=",snappedf(Performance.get_monitor(Performance.TIME_PROCESS)*1000.0,0.01)," draw_calls=",Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))

func _run() -> void:
 DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
 Engine.max_fps=0
 var world = load("res://scenes/skirmish.tscn").instantiate()
 root.add_child(world)
 await process_frame
 await _measure("initial battle")
 world.queue_free()
 await process_frame
 # Isolate the new building art from AI, pathfinding and combat.
 var gallery = Node2D.new()
 root.add_child(gallery)
 var buildings: Array[Node2D] = []
 var roles = ["yard","power","barracks","refinery","factory","depot"]
 for i in range(54):
  var building = Node2D.new()
  building.set_script(Structure)
  building.kind=roles[i%6]
  building.team=(i/6)%3
  building.position=Vector2(75+(i%9)*140,95+(i/9)*110)
  building.scale=Vector2.ONE*0.65
  gallery.add_child(building)
  building.set_process(false)
  building.set_physics_process(false)
  buildings.append(building)
 await _measure("54 buildings frozen")
 for frame in range(140):
  for building in buildings:
   building.art_time=frame/60.0
   building.queue_redraw()
  await process_frame
 # _measure needs the redraw driver to continue during its sampling window.
 gallery.set_script(load("res://tests/building_load_driver.gd"))
 await _measure("54 buildings redraw each frame")
 quit(0)
