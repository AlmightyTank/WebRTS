extends SceneTree
## Tests actual instantiated buildings, production, ore payout and power behavior.
## godot --headless --path godot --script res://tests/skirmish_smoke.gd
var failures: Array[String]=[]
var world
func _initialize() -> void:
 call_deferred("run_checks")
func expect(value: bool, message: String) -> void:
 if value: print("PASS: "+message)
 else:
  failures.append(message)
  push_error("FAIL: "+message)
func build(id: String, point: Vector2) -> void:
 expect(world.queue_production(0,"build",id),"Queue "+id)
 world._tick_production(0,31.0)
 var job: Dictionary=world.states[0]["lanes"]["build"]
 expect(bool(job.get("ready",false)),id+" completed and paid")
 world.placement_lane="build"
 expect(world._place_player_ready(point),"Place "+id+" with terrain+adjacency rules")
func run_checks() -> void:
 world=load("res://scenes/skirmish.tscn").instantiate()
 root.add_child(world)
 await process_frame
 expect(world.registry.has("standard_units"),"Shared v0.4 balance registry loads")
 expect(world.units.size()==1,"Initial Alliance starts with one MCV; AI MCV deployed")
 expect(world.structures.size()==1 and world.has_structure(1,"yard"),"AI starts with a deployed command yard")
 expect(world.selected.size()==1,"Player MCV selected by default")
 expect(world._deploy_mcv(0),"Deploy MCV to Construction Yard")
 expect(world.has_structure(0,"yard"),"Deployed Yard grants base build authority")
 expect(not world.queue_production(0,"build","refinery"),"Tech gating prevents refinery before power")
 build("power",Vector2(310,420))
 expect(int(world.states[0]["power"])==150,"Power plant contributes 150 generation")
 build("refinery",Vector2(480,420))
 expect(int(world.states[0]["demand"])==50,"Refinery consumes 50 power")
 var harvesters: Array=world.units.filter(func(u): return is_instance_valid(u) and u.team==0 and u.unit_id=="a_harvester")
 expect(harvesters.size()==1,"First refinery grants exactly one free harvester")
 var harvester=harvesters[0]
 var remaining=float(world.ore_fields[0]["remaining"])
 harvester.position=world.ore_fields[0]["position"]
 harvester.state="MINING"
 harvester.mine_timer=0.0
 harvester._physics_process(0.2)
 expect(harvester.cargo>0 and float(world.ore_fields[0]["remaining"])<remaining,"Finite ore is consumed by harvester")
 var earned=harvester.cargo
 harvester.state="RETURN"
 harvester.moving=false
 var refinery=world.find_refinery(harvester.position,0)
 harvester.position=refinery.position+Vector2(0,89)
 var old_credits=float(world.states[0]["credits"])
 harvester._physics_process(0.15)
 expect(is_equal_approx(float(world.states[0]["credits"]),old_credits+earned),"Unloading pays exactly once")
 expect(is_zero_approx(harvester.cargo),"Unloading clears cargo")
 build("barracks",Vector2(570,630))
 expect(world.queue_production(0,"infantry","a_ranger"),"Barracks can train an infantry unit")
 expect(world.queue_production(0,"build","factory"),"Factory construction starts independently of infantry")
 expect(world.queue_production(0,"defense","turret"),"Defense builds concurrently with normal structures")
 world._tick_production(0,4.0)
 expect(float(world.states[0]["lanes"]["build"]["paid"])>0,"Factory production spends credits gradually")
 expect(float(world.states[0]["lanes"]["defense"]["paid"])>0,"Separate defense lane progresses in parallel")
 world._tick_production(0,30.0)
 expect(world.units.any(func(u): return is_instance_valid(u) and u.unit_id=="a_ranger"),"Trained infantry exits barracks into battlefield")
 world.placement_lane="build"
 expect(world._place_player_ready(Vector2(740,750)),"War Factory is placed without intersecting buildings")
 world.placement_lane="defense"
 expect(world._place_player_ready(Vector2(710,525)),"Completed turret can be placed independently")
 expect(world.queue_production(0,"vehicle","a_sentinel"),"Factory can queue a Sentinel tank")
 world._tick_production(0,24.0)
 expect(world.units.any(func(u): return is_instance_valid(u) and u.unit_id=="a_sentinel"),"New tank exits War Factory")
 expect(not world.can_place(Vector2(875,270),"barracks",0),"Static obstacle stops building placement")
 expect(not world.can_place(Vector2(1670,250),"power",0),"Enemy territory is outside build radius")
 var generator
 for b in world.structures:
  if b.team==0 and b.kind=="power": generator=b
 expect(generator!=null,"Generator remains targetable and destructible")
 generator.receive_damage(99999.0,null)
 expect(not world.power_ok(0),"Losing power disables power-dependent systems")
 expect(world.states[0]["credits"]>=0.0,"Credits cannot become negative")
 world.queue_free()
 if failures.is_empty():
  print("SKIRMISH_SMOKE_PASS")
  quit(0)
 else:
  print("SKIRMISH_SMOKE_FAIL "+str(failures.size()))
  quit(1)

