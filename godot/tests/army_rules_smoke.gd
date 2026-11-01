extends SceneTree
const Rules = preload("res://scripts/economy/army_rules.gd")
var failures := 0

func expect(value: bool, label: String) -> void:
 if value: print("PASS: " + label)
 else:
  failures += 1
  push_error(label)

func _initialize() -> void:
 call_deferred("_run")

func _run() -> void:
 for choice in Rules.CHOICES:
  var world = load("res://scenes/skirmish.tscn").instantiate()
  world.army_choices = [choice, choice]
  root.add_child(world)
  world.set_physics_process(false)
  world.paused = true
  expect(world.units[0].unit_id == Rules.economic_id(choice), choice + ": correct starting MCV")
  expect(world._deploy_mcv(0), choice + ": MCV deploys in a mirror match")
  for side in range(2):
   var x := 450.0 if side == 0 else 1400.0
   world._place_structure("power",side,Vector2(x,300))
   world._place_structure("refinery",side,Vector2(x,900))
   world._place_structure("barracks",side,Vector2(x,460))
   world._place_structure("factory",side,Vector2(x,700))
   world._place_structure("depot",side,Vector2(x+180,300))
   var collector := false
   for u in world.units:
    if u.team==side and u.unit_id==Rules.economic_id(choice,true): collector=true
   expect(collector, choice + ": faction collector on team %d" % side)
   for id in Rules.roster_ids(choice):
    var lane: String = world._lane_for(id)
    expect(world.queue_production(side,lane,id), choice + ": team %d can queue " % side + id)
    world.cancel_production(side,lane)
    expect(world._produce_unit(side,id), choice + ": team %d can spawn " % side + id)
   for mapping in Rules.REPLACEMENTS.values():
    for original in mapping:
     if not original in Rules.roster_ids(choice):
      expect(not world.queue_production(side,world._lane_for(original),original), "Removed/cross-faction slot rejected: " + original)
   var foreign := "r_line" if Rules.faction(choice)!="republic" else "a_ranger"
   expect(not world.queue_production(side,"infantry",foreign), "Cross-faction infantry rejected")
  if choice=="alliance_energy":
   var unit = world._spawn("a_lance",0,Vector2(700,600))
   var enemy = world._spawn("r_line",1,Vector2(780,600))
   unit.fire(enemy)
   expect(is_equal_approx(world.projectiles.back().damage,110.0), "Powered Arc Lance gets exactly +10% damage")
   world.states[0].power=0
   world.states[0].demand=100
   unit.fire(enemy)
   expect(is_equal_approx(world.projectiles.back().damage,100.0) and is_equal_approx(unit.cooldown,3.8), "Low power halves energy fire rate without damage bonus")
  if choice=="republic_armor":
   var tank = world._spawn("r_imperator",0,Vector2(700,600))
   expect(is_equal_approx(tank.max_hp,float(world.roster.r_imperator.hp)*1.1), "Steel Vanguard tank health applies exactly once")
   expect(is_equal_approx(float(world._recipe("r_siege_heli",1).cost),float(world.roster.r_siege_heli.credits)*1.2), "Aircraft price tradeoff applies to either team")
   for side in range(2):
    var paid_before: float = world.states[side].total_spent
    world.queue_production(side,"vehicle","r_siege_heli")
    world._tick_production(side,1000.0)
    expect(is_equal_approx(float(world.states[side].total_spent)-paid_before,float(world.roster.r_siege_heli.credits)*1.2), "Production actually charges the aircraft premium")
  if choice=="gia_missile":
   var volley = world._spawn("g_volley",0,Vector2(700,600))
   expect(is_equal_approx(volley.move_speed,float(world.roster.g_volley.speed)*0.9), "Volley speed tradeoff")
   expect(is_equal_approx(float(volley.weapon.interval),3.2*0.9), "Volley reload bonus")
  for id in Rules.roster_ids(choice): expect(world.action_buttons.has(id), "Production tile matches resolved roster: " + id)
  var ai_used_signature := not Rules.REPLACEMENTS.has(choice)
  for tick in range(12):
   world._ai_economy()
   var job: Dictionary = world.states[1].lanes.vehicle
   if not job.is_empty():
    expect(str(job.id) in Rules.roster_ids(choice), "AI chooses legal faction units")
    if str(job.id) in Rules.REPLACEMENTS.get(choice,{}).values(): ai_used_signature=true
   world.cancel_production(1,"vehicle")
   world.cancel_production(1,"infantry")
  expect(ai_used_signature, "AI can field the selected general's signature")
  expect(world.faction_style(0)==world.faction_style(1), "Mirror match shares faction geometry, not owner color")
  if choice=="gia_missile" and DisplayServer.get_name()!="headless":
   world.current_tab=3
   world._update_hud()
   await process_frame
   await process_frame
   root.get_texture().get_image().save_png("user://army_battlefield.png")
  world.queue_free()
  await process_frame
 var menu = load("res://scenes/main_menu.tscn").instantiate()
 root.add_child(menu)
 menu.army_choices = ["gia_missile","republic_armor"]
 menu._show_page("skirmish")
 await process_frame
 await process_frame
 if DisplayServer.get_name()!="headless": root.get_texture().get_image().save_png("user://army_selection.png")
 menu._start_game()
 expect(menu.game.army_choices==menu.army_choices, "Menu transfers both army choices before battlefield setup")
 menu._leave_game()
 menu.queue_free()
 await process_frame
 print("ARMY_RULES_SMOKE: %d failures" % failures)
 quit(1 if failures else 0)
