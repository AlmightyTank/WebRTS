extends SceneTree
## godot --headless --path godot --script res://tests/army_command_ai_smoke.gd
var failures: Array[String] = []

func _initialize() -> void:
 call_deferred("run_checks")

func expect(value: bool, message: String) -> void:
 print(("PASS: " if value else "FAIL: ") + message)
 if not value: failures.append(message)

func key(code: Key, control: bool = false, alt: bool = false) -> InputEventKey:
 var event := InputEventKey.new()
 event.keycode = code
 event.pressed = true
 event.ctrl_pressed = control
 event.alt_pressed = alt
 return event

func run_checks() -> void:
 var world = load("res://scenes/skirmish.tscn").instantiate()
 root.add_child(world)
 await process_frame
 var unit = world.selected[0]
 expect(world._control_group_key(key(KEY_1, true)), "Ctrl+1 assigns a control group")
 world._set_selected([])
 expect(world._control_group_key(key(KEY_1, false, true)) and world.selected.has(unit), "Alt+1 recalls the group")
 expect(not world._control_group_key(key(KEY_1)), "Plain number remains available for production tabs")
 world.reset_battle()
 expect(world.control_groups.is_empty(), "Restart clears control groups")
 world.queue_free()
 await process_frame

 var match_world = load("res://scenes/skirmish.tscn").instantiate()
 match_world.ai_vs_ai = true
 root.add_child(match_world)
 await process_frame
 expect(match_world.has_structure(0, "yard") and match_world.has_structure(1, "yard"), "Both AIs deploy their own MCV")
 match_world._ai_economy(0)
 match_world._ai_economy(1)
 expect(not match_world.states[0].lanes.build.is_empty() and not match_world.states[1].lanes.build.is_empty(), "Both AIs start paid construction")
 match_world._tick_production(0, 20.0)
 match_world._tick_production(1, 20.0)
 match_world._tick_production(0, 0.1)
 match_world._tick_production(1, 0.1)
 expect(match_world.has_structure(0, "power") and match_world.has_structure(1, "power"), "Both AIs place their completed power plants")
 expect(match_world.states[0].credits < 10000 and match_world.states[1].credits < 10000, "Both AIs pay for construction")
 for side in [0,1]:
  var anchor := Vector2(310,620) if side==0 else Vector2(1600,610)
  match_world._place_structure("refinery",side,anchor+Vector2(0,220))
  match_world._place_structure("factory",side,anchor+Vector2(0,-220))
  var collector_id: String = match_world.ArmyRules.economic_id(match_world.army_choices[side],true)
  for actor in match_world.units:
   if is_instance_valid(actor) and actor.team==side and actor.unit_id==collector_id: actor.hp=0
  match_world._ai_economy(side)
  expect(match_world.states[side].lanes.vehicle.get("id","")==collector_id,"AI %d replaces a lost harvester before combat vehicles" % side)
  match_world._ai_economy(side)
  expect(match_world.states[side].queued.vehicle.is_empty(),"AI %d does not duplicate its pending harvester" % side)
  match_world.states[side].lanes.build={}
  match_world.states[side].demand=999
  match_world._ai_economy(side)
  expect(match_world.states[side].lanes.build.get("id","")=="power","AI %d prioritizes power shortage" % side)
 match_world.queue_free()
 await process_frame
 print("ARMY_COMMAND_AI_SMOKE_", "PASS" if failures.is_empty() else "FAIL")
 quit(0 if failures.is_empty() else 1)
