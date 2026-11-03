extends SceneTree
## godot --headless --path godot --script res://tests/ai_opening_smoke.gd
const MatchSave = preload("res://scripts/economy/match_save.gd")
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("run_checks")

func expect(value: bool, message: String) -> void:
	print(("PASS: " if value else "FAIL: ") + message)
	if not value:
		failures.append(message)

func run_checks() -> void:
	var world = load("res://scenes/skirmish.tscn").instantiate()
	root.add_child(world)
	await process_frame
	world.set_physics_process(false)
	world.paused = false
	expect(world.ai_difficulty == "regular", "A match starts on Regular")
	expect(str(world._ai_profile().label) == "REGULAR", "Regular is the published build")
	var credits_before := float(world.states[1].credits)
	var mined_before := float(world.states[1].total_mined)
	for _i in range(8):
		world._ai_economy(1)
	expect(is_equal_approx(float(world.states[1].credits), credits_before) and is_equal_approx(float(world.states[1].total_mined), mined_before), "Regular gains nothing from an economy tick")
	world.skirmish_time = 17.0
	world.deliver_ore(1, 40.0)
	world.skirmish_time = 30.0
	world.deliver_ore(1, 15.0)
	expect(is_equal_approx(float(world.ai_clock[1].ore), 17.0), "The first ore delivery keeps its clock")
	expect(is_equal_approx(float(world.states[1].credits), credits_before + 55.0), "Delivered ore is the credit increase")

	_build_choice(world)
	_scout_and_attack(world)
	_save_clock(world)
	var measured := {}
	for id in ["veteran", "regular", "recruit"]:
		measured[id] = _measure(world, id)
	_compare_clocks(measured)
	world.queue_free()
	await process_frame

	var menu = load("res://scenes/main_menu.tscn").instantiate()
	root.add_child(menu)
	menu.lobby_compact_override = 0
	menu._show_page("skirmish")
	await process_frame
	var picker: OptionButton = menu.find_child("DifficultySelect", true, false)
	expect(picker != null and picker.item_count == 3, "The lobby lists Recruit, Regular, and Veteran")
	menu.set_difficulty("veteran")
	expect(menu.lobby_difficulty_note.text.contains("early"), "The Veteran note describes the early scout")
	menu.set_difficulty("nope")
	expect(menu.ai_difficulty == "regular", "An unknown difficulty falls back to Regular")
	menu.set_difficulty("recruit")
	menu._start_game()
	await process_frame
	expect(menu.game.ai_difficulty == "recruit", "The lobby difficulty reaches the match")
	menu.game._update_hud()
	expect(str(menu.game.retro_ai_label.text).contains("RECRUIT") and str(menu.game.hud_text.text).contains("RECRUIT"), "The battlefield names the computer difficulty")
	menu.queue_free()
	await process_frame
	print("AI_OPENING_SMOKE: %d failures" % failures.size())
	quit(0 if failures.is_empty() else 1)

func _build_choice(world) -> void:
	world.ai_difficulty = "recruit"
	world.reset_battle()
	world.set_physics_process(false)
	var anchor := _yard(world, 1)
	world._place_structure("power", 1, anchor + Vector2(-220, -180))
	world._place_structure("refinery", 1, anchor + Vector2(-220, 180))
	world._place_structure("barracks", 1, anchor + Vector2(180, -180))
	world.states[1].lanes.build = {}
	world.states[1].credits = 8000.0
	world.skirmish_time = 20.0
	world.ai_next_build[1] = 0.0
	world._ai_economy(1)
	expect(str(world.states[1].lanes.build.get("id", "")) != "factory", "Recruit does not start a factory during the opening")
	world.states[1].lanes.build = {}
	world.skirmish_time = 120.0
	world.ai_next_build[1] = 0.0
	world._ai_economy(1)
	expect(str(world.states[1].lanes.build.get("id", "")) == "factory", "Recruit starts the factory once the opening wait is over")
	world._place_structure("factory", 1, anchor + Vector2(180, 160))
	world._place_structure("depot", 1, anchor + Vector2(40, 40))
	world.states[1].lanes.build = {}
	world.states[1].credits = 8000.0
	world.ai_build_tick = 0
	world._ai_economy(1)
	expect(str(world.states[1].lanes.build.get("id", "")) != "airfield" and str(world.states[1].lanes.build.get("id", "")) not in ["silo", "beam_array", "ironstorm"], "Recruit skips the airfield and the superweapon")

	world.ai_difficulty = "regular"
	world.states[1].lanes.build = {}
	world.states[1].credits = 2300.0
	world.ai_build_tick = 0
	world.ai_next_build[1] = 0.0
	world._ai_economy(1)
	expect(str(world.states[1].lanes.build.get("id", "")) != "airfield", "Regular waits for 3500 credits before an airfield")
	world.states[1].lanes.build = {}
	world.states[1].credits = 3600.0
	world.ai_build_tick = 0
	world._ai_economy(1)
	expect(str(world.states[1].lanes.build.get("id", "")) == "airfield", "Regular queues the airfield at 3500 credits")

	world.ai_difficulty = "veteran"
	world.states[1].lanes.build = {}
	world.states[1].lanes.vehicle = {}
	world.states[1].credits = 2300.0
	world.ai_build_tick = 0
	world.ai_next_build[1] = 0.0
	world._ai_economy(1)
	expect(str(world.states[1].lanes.vehicle.get("id", "")) == "r_hauler", "Veteran trains a second harvester")
	expect(str(world.states[1].lanes.build.get("id", "")) == "airfield", "Veteran queues the airfield at 2200 credits")

func _scout_and_attack(world) -> void:
	world.fog_enabled = true
	world.ai_difficulty = "veteran"
	world.reset_battle()
	world.set_physics_process(false)
	if world.fog == null:
		world._refresh_fog()
	var anchor := _yard(world, 1)
	var veteran_unit = world._spawn("r_line", 1, anchor + Vector2(30, 40))
	world.skirmish_time = 5.0
	world._ai_decide()
	var west: Vector2 = world.SkirmishMaps.point(world.map_id, "west")
	expect(veteran_unit.moving and veteran_unit.destination.distance_to(west) + 40.0 < veteran_unit.position.distance_to(west), "Veteran sends the first soldier toward the enemy start")
	expect(float(world.ai_clock[1].attack) < 0.0, "One soldier is not yet an attack")

	world.ai_difficulty = "recruit"
	world.reset_battle()
	world.set_physics_process(false)
	if world.fog == null:
		world._refresh_fog()
	anchor = _yard(world, 1)
	var first = world._spawn("r_line", 1, anchor + Vector2(30, 40))
	var second = world._spawn("r_line", 1, anchor + Vector2(-30, 40))
	world.skirmish_time = 10.0
	world._ai_decide()
	expect(not world.scouting.orders.has(first) and not world.scouting.orders.has(second), "Recruit holds both soldiers early")
	world.skirmish_time = 80.0
	world._ai_decide()
	var recruit_scouts := 0
	if world.scouting.orders.has(first):
		recruit_scouts += 1
	if world.scouting.orders.has(second):
		recruit_scouts += 1
	expect(recruit_scouts == 1, "Recruit sends one scout after 75 seconds")

	world.ai_difficulty = "regular"
	world.reset_battle()
	world.set_physics_process(false)
	if world.fog == null:
		world._refresh_fog()
	anchor = _yard(world, 1)
	var regulars: Array = []
	for i in range(4):
		regulars.append(world._spawn("r_line", 1, anchor + Vector2(-40.0 + float(i) * 28.0, 50.0)))
	world.skirmish_time = 20.0
	world._ai_decide()
	expect(not bool(world.ai_pushed[1]), "Regular holds the attack before 90 seconds")
	var scouted := 0
	for unit in regulars:
		if world.scouting.orders.has(unit):
			scouted += 1
	expect(scouted == 4, "Regular sends idle combat units to explore")
	world.skirmish_time = 90.0
	world._ai_decide()
	expect(bool(world.ai_pushed[1]) and is_equal_approx(float(world.ai_clock[1].attack), 90.0), "Regular attacks at 90 seconds with four soldiers")
	expect(bool(regulars[0].has_attack_move_goal), "The opening attack is an attack-move")

	world.ai_difficulty = "recruit"
	world.ai_pushed[1] = false
	world.ai_clock[1].attack = -1.0
	world.skirmish_time = 200.0
	world._ai_decide()
	expect(not bool(world.ai_pushed[1]), "Recruit with four soldiers does not attack yet")
	world._spawn("r_line", 1, anchor + Vector2(70, 50))
	world._spawn("r_line", 1, anchor + Vector2(98, 50))
	world.skirmish_time = 160.0
	world._ai_decide()
	expect(bool(world.ai_pushed[1]) and is_equal_approx(float(world.ai_clock[1].attack), 160.0), "Recruit attacks at 160 seconds with six soldiers")

	world.ai_difficulty = "veteran"
	world.reset_battle()
	world.set_physics_process(false)
	anchor = _yard(world, 1)
	world._spawn("r_line", 1, anchor + Vector2(-20, 36))
	world._spawn("r_line", 1, anchor + Vector2(20, 36))
	world.skirmish_time = 30.0
	world._ai_decide()
	expect(not bool(world.ai_pushed[1]), "Veteran waits until 36 seconds")
	world.skirmish_time = 36.0
	world._ai_decide()
	expect(bool(world.ai_pushed[1]) and is_equal_approx(float(world.ai_clock[1].attack), 36.0), "Veteran attacks at 36 seconds with two soldiers")

func _save_clock(world) -> void:
	world.ai_difficulty = "veteran"
	world.skirmish_time = 12.5
	world.ai_clock = [{"ore": -1.0, "tank": -1.0, "attack": -1.0}, {"ore": -1.0, "tank": -1.0, "attack": -1.0}]
	world.deliver_ore(1, 20.0)
	world.ai_pushed[1] = true
	world.ai_next_build[1] = 44.0
	var path := "user://ai_opening_smoke.json"
	expect(MatchSave.write(world, path), "The opening clock can be saved")
	world.ai_difficulty = "recruit"
	world.ai_pushed[1] = false
	var data = MatchSave.read(path)
	expect(data != null and MatchSave.apply(world, data), "The saved opening clock loads")
	expect(world.ai_difficulty == "veteran" and bool(world.ai_pushed[1]) and is_equal_approx(float(world.ai_clock[1].ore), 12.5) and is_equal_approx(float(world.ai_next_build[1]), 44.0), "Resume keeps the difficulty, the ore clock, and the attack")

func _measure(world, id: String) -> Dictionary:
	world.ai_difficulty = id
	world.fog_enabled = true
	world.reset_battle()
	world.set_physics_process(false)
	world.paused = false
	var decide := 0.0
	var guard := 0
	while not _clocks_ready(world) and world.skirmish_time < 280.0 and guard < 5000:
		guard += 1
		var dt := 0.25
		world.skirmish_time += dt
		world._tick_production(1, dt)
		for unit in world.units:
			if not is_instance_valid(unit) or unit.team != 1:
				continue
			if unit.get("working") == true:
				unit._physics_process(dt)
			elif unit.get("moving") == true and unit.has_method("_step_movement"):
				unit._step_movement(dt)
		world.economy_ai_timer -= dt
		if world.economy_ai_timer <= 0.0:
			world.economy_ai_timer = float(world._ai_profile().period)
			world._ai_economy(1)
			world.ai_build_tick += 1
		decide -= dt
		if decide <= 0.0:
			decide = 1.1
			world._ai_decide()
	var clock: Dictionary = world.ai_clock[1]
	print("OPENING %s ore=%.1f tank=%.1f attack=%.1f" % [id, float(clock.ore), float(clock.tank), float(clock.attack)])
	expect(float(clock.ore) >= 0.0 and float(clock.tank) >= 0.0 and float(clock.attack) >= 0.0, id.capitalize() + " records ore, tank, and attack")
	expect(float(clock.attack) + 0.01 >= float(world.AI_PROFILES[id].attack_after), id.capitalize() + " attacks on its clock")
	expect(float(clock.tank) > float(clock.ore), id.capitalize() + " fields a tank after the first ore delivery")
	return {"ore": float(clock.ore), "tank": float(clock.tank), "attack": float(clock.attack)}

func _clocks_ready(world) -> bool:
	var clock: Dictionary = world.ai_clock[1]
	return float(clock.ore) >= 0.0 and float(clock.tank) >= 0.0 and float(clock.attack) >= 0.0

func _compare_clocks(measured: Dictionary) -> void:
	expect(float(measured.veteran.attack) < float(measured.regular.attack) and float(measured.regular.attack) < float(measured.recruit.attack), "The attack leaves earlier as the difficulty rises")
	expect(float(measured.recruit.ore) > float(measured.regular.ore) + 4.0, "Recruit's first delivery is later than Regular's")
	expect(float(measured.veteran.ore) < float(measured.regular.ore), "Veteran's first delivery is earlier than Regular's")
	expect(float(measured.recruit.tank) > float(measured.regular.tank) + 15.0, "Recruit's first tank waits on the factory")

func _yard(world, team: int) -> Vector2:
	for building in world.structures:
		if is_instance_valid(building) and building.team == team and building.kind == "yard":
			return building.position
	return Vector2.ZERO
