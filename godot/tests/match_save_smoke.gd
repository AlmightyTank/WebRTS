extends SceneTree
## A skirmish snapshot restores the battlefield, and leaving can save it for the main menu.
const Arena = preload("res://scripts/economy/skirmish_arena.gd")
const MatchSave = preload("res://scripts/economy/match_save.gd")
var failed := 0

func expect(ok: bool, label: String) -> void:
	if ok:
		print("PASS: " + label)
	else:
		failed += 1
		push_error("FAIL: " + label)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	_erase(MatchSave.PATH)
	var intact = Arena.new()
	intact.fog_enabled = false
	intact.set_physics_process(false)
	root.add_child(intact)
	var opening := int(intact.units.size())
	var bad := MatchSave.capture(intact)
	bad["ore"] = []
	expect(not MatchSave.apply(intact, bad), "A snapshot that does not match the map is refused")
	expect(intact.units.size() == opening, "A refused snapshot leaves the match in place")
	_write_raw("user://match_save_bad.json", "{\"version\":2}")
	expect(intact.load_match("user://match_save_bad.json") == false, "A newer snapshot is not loaded")
	expect(intact.units.size() == opening, "An unreadable snapshot leaves the match in place")
	var world = Arena.new()
	world.army_choices = ["alliance_energy", "republic"]
	world.fog_enabled = true
	world.starting_credits = 10000
	world.set_physics_process(false)
	root.add_child(world)
	world._place_structure("power", 0, Vector2(560, 520))
	world._place_structure("barracks", 0, Vector2(420, 520))
	world._place_structure("refinery", 0, Vector2(240, 900))
	var barracks = null
	var harvester = null
	for building in world.structures:
		if building.team == 0 and building.kind == "barracks":
			barracks = building
	for unit in world.units:
		if unit.unit_id == "a_harvester":
			harvester = unit
	expect(barracks != null and harvester != null, "Setup builds a barracks and its refinery harvester")
	barracks.hp = 640.0
	barracks.repairing = true
	barracks.paid_value = 320.0
	barracks.rally_point = Vector2(450, 800)
	barracks.rally_custom = true
	barracks.timer = 1.25
	harvester.cargo = 320.0
	harvester.state = "RETURN"
	harvester.working = true
	harvester.deposits = 2
	expect(world._produce_unit(0, "a_ranger"), "Ranger is produced before the save")
	var ranger = world.units[world.units.size() - 1]
	ranger.hp = 41.0
	ranger.order_move(Vector2(520, 760))
	ranger.queue_move(Vector2(600, 800))
	world.selected = [ranger]
	ranger.selected = true
	world.control_groups[2] = [ranger]
	world.states[0]["credits"] = 4321.0
	world.states[0]["total_mined"] = 640.0
	world.states[0]["lanes"]["build"] = {"id": "turret", "paid": 125.0, "ready": false}
	world.states[0]["queued"]["infantry"] = ["a_javelin"]
	world.states[1]["credits"] = 7777.0
	world.ore_fields[0]["remaining"] = 2222.0
	world.staging_areas[0]["BRAVO"]["position"] = Vector2(640, 880)
	world.staging_areas[0]["BRAVO"]["enabled"] = true
	world.staging_areas[0]["BRAVO"]["next_slot"] = 2
	world.skirmish_time = 48.5
	world.ai_build_tick = 11
	world.economy_ai_timer = 0.37
	world.current_tab = 1
	world.placement_lane = "build"
	world.hud_status = "Hold the relay."
	world.shots = 4
	world.hits = 2
	world.kills = [1, 3]
	world.camera.destination = Vector2(480, 360)
	world.camera.position = Vector2(480, 360)
	world.camera.zoom_goal = 1.05
	var commander = world.commander
	commander.award_xp(0, 3500.0)
	expect(commander.buy_power(0, "grid_surge"), "Grid Surge is purchased before the save")
	commander.teams[0].cooldowns["grid_surge"] = 22.0
	commander.pending_power = "grid_surge"
	commander.teams[0].job = {"id": "grid_stabilizers", "paid": 80.0}
	commander.events.append({"id": "orbital_pulse", "side": 0, "point": Vector2(900, 400), "radius": 100.0, "remaining": 3.2, "level": 1})
	var far := Vector2(36 * 48 + 24, 3 * 48 + 24)
	world.fog.explored_cells[0][Vector2i(36, 3)] = true
	world.fog.explored_cells[1][Vector2i(36, 3)] = true
	var explored_before: int = world.fog.explored_cells[0].size()
	var cues_before: int = world.audio.history.size()
	var units_before: int = world.units.size()
	var buildings_before: int = world.structures.size()
	var harvesters_before := _count_units(world, "a_harvester")
	expect(harvesters_before == 1, "The refinery brought one harvester")
	expect(world.save_match("user://match_save_smoke.json"), "The match writes a snapshot")
	expect(world.save_match(), "The match writes the resume file")
	world.states[0]["credits"] = 1.0
	commander.teams[0].rank = 1
	world.ore_fields[0]["remaining"] = 5.0
	expect(world.load_match("user://match_save_smoke.json"), "The same battlefield reloads the snapshot")
	_assert_world(world, barracks.position, explored_before)
	expect(world.audio.history.size() == cues_before, "Reloading does not replay construction or ready cues")
	expect(_count_units(world, "a_harvester") == 1, "Reloading does not grant a second refinery harvester")
	expect(world.units.size() == units_before and world.structures.size() == buildings_before, "Reload keeps the same actors")
	var resumed = Arena.new()
	resumed.fog_enabled = false
	resumed.set_physics_process(false)
	root.add_child(resumed)
	var fresh_cues: int = resumed.audio.history.size()
	expect(resumed.load_match("user://match_save_smoke.json"), "A new battlefield resumes the snapshot")
	_assert_world(resumed, barracks.position, explored_before)
	expect(resumed.audio.history.size() == fresh_cues, "Resume does not play the construction cues again")
	expect(_count_units(resumed, "a_mcv") == 1 and _count_units(resumed, "r_mcv") == 0 and _count_structures(resumed, "yard") == 1, "Resume keeps the player's MCV and the deployed enemy yard")
	expect(resumed.units.size() == units_before, "Resume does not spawn a second opening force")
	expect(_count_structures(resumed, "relay") == 1, "Resume keeps the single relay")
	world.paused = true
	resumed.paused = true
	intact.paused = true
	var menu = load("res://scenes/main_menu.tscn").instantiate()
	root.add_child(menu)
	expect(menu.page == "home" and _button(menu, "RESUME MATCH") != null, "Main menu offers resume when a snapshot exists")
	menu._resume_saved_match()
	expect(is_instance_valid(menu.game) and is_equal_approx(float(menu.game.states[0]["credits"]), 4321.0), "Resume match restores the saved credits")
	menu.game.paused = true
	menu.game.set_physics_process(false)
	menu._show_page("pause")
	expect(_button(menu, "SAVE MATCH") != null, "Pause can save the match")
	menu._save_from_pause()
	expect(menu.save_notice.begins_with("Match saved"), "Saving from pause confirms the snapshot")
	menu._show_page("leave")
	expect(_button(menu, "KEEP PLAYING") != null and _button(menu, "SAVE AND LEAVE") != null and _button(menu, "END MATCH") != null, "Leaving offers save and still ends the match")
	_button(menu, "END MATCH").pressed.emit()
	expect(menu.game == null and menu.page == "home" and _button(menu, "RESUME MATCH") != null, "Ending the match keeps the snapshot")
	_erase(MatchSave.PATH)
	menu._show_page("home")
	expect(_button(menu, "RESUME MATCH") == null and _button(menu, "SKIRMISH") != null, "Home returns to skirmish when nothing is saved")
	_erase("user://match_save_smoke.json")
	_erase("user://match_save_bad.json")
	print("MATCH_SAVE_SMOKE: %d failures" % failed)
	quit(0 if failed == 0 else 1)

func _assert_world(world, barracks_at: Vector2, explored_before: int) -> void:
	expect(is_equal_approx(float(world.states[0]["credits"]), 4321.0), "Credits resume at the saved balance")
	expect(is_equal_approx(float(world.states[1]["credits"]), 7777.0), "The opponent's credits resume too")
	expect(is_equal_approx(float(world.states[0]["total_mined"]), 640.0), "Mined ore total resumes")
	expect(str(world.states[0]["lanes"]["build"]["id"]) == "turret" and is_equal_approx(float(world.states[0]["lanes"]["build"]["paid"]), 125.0), "A half-paid building stays in the queue")
	expect(world.states[0]["queued"]["infantry"].size() == 1 and str(world.states[0]["queued"]["infantry"][0]) == "a_javelin", "The infantry queue resumes")
	expect(is_equal_approx(float(world.ore_fields[0]["remaining"]), 2222.0), "Remaining ore resumes")
	var barracks = _structure(world, 0, "barracks")
	expect(barracks != null and barracks.position.distance_to(barracks_at) < 1.0 and is_equal_approx(barracks.hp, 640.0), "The damaged barracks returns")
	expect(barracks != null and barracks.repairing and barracks.rally_custom and barracks.rally_point.distance_to(Vector2(450, 800)) < 1.0, "Repair and the rally point resume")
	expect(barracks != null and is_equal_approx(float(barracks.paid_value), 320.0), "The barracks keeps its paid value")
	var producer = world._active_producer(0, "infantry")
	expect(producer != null and producer.position.distance_to(barracks_at) < 1.0, "The active barracks resumes")
	var harvester = _unit(world, "a_harvester")
	expect(harvester != null and is_equal_approx(harvester.cargo, 320.0) and str(harvester.state) == "RETURN" and harvester.deposits == 2, "The harvester resumes its haul")
	var ranger = _unit(world, "a_ranger")
	expect(ranger != null and is_equal_approx(ranger.hp, 41.0), "The ranger resumes its health")
	expect(ranger != null and ranger.pending_orders.size() == 1 and ranger.pending_orders[0]["point"].distance_to(Vector2(600, 800)) < 1.0, "The ranger's queued order resumes")
	expect(world.selected.size() == 1 and world.selected[0] == ranger, "The selection resumes")
	expect(world.control_groups.has(2) and world.control_groups[2][0] == ranger, "Control group 2 resumes")
	expect(world.staging_areas[0]["BRAVO"]["enabled"] and world.staging_areas[0]["BRAVO"]["position"].distance_to(Vector2(640, 880)) < 1.0 and int(world.staging_areas[0]["BRAVO"]["next_slot"]) == 2, "Staging area Bravo resumes")
	expect(is_equal_approx(world.skirmish_time, 48.5) and world.ai_build_tick == 11 and is_equal_approx(world.economy_ai_timer, 0.37), "The match clock and AI build clock resume")
	expect(world.current_tab == 1 and world.placement_lane == "build" and world.hud_status == "Hold the relay.", "The command view resumes")
	expect(world.shots == 4 and world.hits == 2 and int(world.kills[0]) == 1 and int(world.kills[1]) == 3, "The battle tally resumes")
	expect(world.camera.destination.distance_to(Vector2(480, 360)) < 1.0 and is_equal_approx(world.camera.zoom_goal, 1.05), "The camera resumes")
	var team: Dictionary = world.commander.teams[0]
	expect(int(team.rank) == 5 and int(team.points) == 6 and int(team.powers.get("grid_surge", 0)) == 1, "Commander rank and Grid Surge resume")
	expect(is_equal_approx(float(team.cooldowns.get("grid_surge", 0.0)), 22.0) and world.commander.pending_power == "grid_surge", "The armed power and its cooldown resume")
	expect(str(team.job.get("id", "")) == "grid_stabilizers" and is_equal_approx(float(team.job.get("paid", 0.0)), 80.0), "Research in progress resumes without charging twice")
	expect(world.commander.events.size() == 1 and is_equal_approx(float(world.commander.events[0].remaining), 3.2) and world.commander.events[0].point.distance_to(Vector2(900, 400)) < 1.0, "A warned strike still on the clock resumes")
	var far := Vector2(36 * 48 + 24, 3 * 48 + 24)
	expect(world.fog.explored(0, far) and world.fog.explored(1, far) and world.fog.explored_cells[0].size() >= explored_before, "Explored fog resumes, including ground nobody can see")

func _structure(world, side: int, kind: String):
	for building in world.structures:
		if is_instance_valid(building) and building.team == side and building.kind == kind:
			return building
	return null

func _unit(world, id: String):
	for unit in world.units:
		if is_instance_valid(unit) and unit.unit_id == id:
			return unit
	return null

func _count_units(world, id: String) -> int:
	var count := 0
	for unit in world.units:
		if is_instance_valid(unit) and unit.unit_id == id:
			count += 1
	return count

func _count_structures(world, kind: String) -> int:
	var count := 0
	for building in world.structures:
		if is_instance_valid(building) and building.kind == kind:
			count += 1
	return count

func _button(menu, title: String) -> Button:
	for child in menu.content.get_children():
		if child is Button and child.text == title:
			return child
	return null

func _write_raw(path: String, text: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file != null:
		file.store_string(text)

func _erase(path: String) -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
