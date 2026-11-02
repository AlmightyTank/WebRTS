extends SceneTree
## Accelerated fixed-step match; timings exclude rendering and frame pacing.
var failures := 0

func _initialize() -> void:
 call_deferred("run_match")

func run_match() -> void:
 seed(42)
 var world = load("res://scripts/economy/skirmish_arena.gd").new()
 var args := OS.get_cmdline_user_args()
 if args.size()>=2: world.army_choices = [args[0],args[1]]
 var duration := 180.0 if args.size()<3 else maxf(1.0,float(args[2]))
 world.ai_vs_ai = true
 root.add_child(world)
 world.process_mode = Node.PROCESS_MODE_DISABLED
 var samples: Array[float] = []
 var peak_units := 0
 var peak_shots := 0
 for step in range(int(duration*30.0)):
  var start := Time.get_ticks_usec()
  world.invalidate_occupancy()
  world._physics_process(1.0 / 30.0)
  for actor in world.units.duplicate():
   if is_instance_valid(actor) and not actor.is_queued_for_deletion(): actor._physics_process(1.0 / 30.0)
  for building in world.structures.duplicate():
   if is_instance_valid(building) and not building.is_queued_for_deletion(): building._physics_process(1.0 / 30.0)
  for shot in world.projectiles.duplicate():
   if is_instance_valid(shot) and not shot.is_queued_for_deletion(): shot._physics_process(1.0 / 30.0)
  samples.append((Time.get_ticks_usec() - start) / 1000.0)
  peak_units = maxi(peak_units, world.units.size())
  peak_shots = maxi(peak_shots, world.shots)
  # Flush deferred destruction without allowing automatic double simulation.
  if step % 30 == 0: await process_frame
  if world.battle_over: break
 var total := 0.0
 for sample in samples: total += sample
 samples.sort()
 print("AI_MATCH armies=%s seconds=%.1f peak_units=%d shots=%d kills=%s tick_mean_ms=%.2f tick_p95_ms=%.2f" % [world.army_choices,world.skirmish_time,peak_units,peak_shots,world.kills,total/samples.size(),samples[int(samples.size()*0.95)]])
 for side in [0,1]:
  print("AI_SIDE side=%d mined=%.0f spent=%.0f credits=%.0f buildings=%d" % [side,world.states[side].total_mined,world.states[side].total_spent,world.states[side].credits,world.structures.filter(func(b): return is_instance_valid(b) and b.team==side).size()])
  if world.states[side].total_spent <= 0 or world.states[side].total_mined <= 0: failures += 1
 if peak_shots == 0: failures += 1
 if DisplayServer.get_name()!="headless":
  await process_frame
  await process_frame
  root.get_texture().get_image().save_png("user://ai_match.png")
 world.queue_free()
 await process_frame
 print("AI_MATCH_BENCHMARK_", "PASS" if failures==0 else "FAIL")
 quit(0 if failures==0 else 1)
