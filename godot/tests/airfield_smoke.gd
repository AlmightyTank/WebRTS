extends SceneTree
## Aircraft build from an airfield, stop firing when dry, and rearm only on a powered pad.
const Arena = preload("res://scripts/economy/skirmish_arena.gd")
const Rules = preload("res://scripts/economy/army_rules.gd")
const Art = preload("res://scripts/ui/industrial_art.gd")
var failed := 0

class PadArt extends Node2D:
	func _draw() -> void:
		for style in range(3):
			draw_set_transform(Vector2(180.0 + style * 280.0, 160.0))
			Art.draw_asset(self, "airfield", style, 0.0, NAN, 0.0, {"time": 0.4, "door": 0.5, "working": style != 1, "faction_style": style})
			draw_set_transform(Vector2.ZERO)

func expect(ok: bool, label: String) -> void:
	if ok:
		print("PASS: " + label)
	else:
		failed += 1
		push_error("FAIL: " + label)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	expect(Rules.sortie_count("a_striker") == 4 and Rules.sortie_count("a_tempest") == 6 and Rules.sortie_count("r_siege_heli") == 6 and Rules.sortie_count("g_heli") == 4, "Sortie counts are 4, 6, 6 and 4")
	expect(is_equal_approx(Rules.rearm_seconds("alliance"), 8.0) and is_equal_approx(Rules.rearm_seconds("alliance_air"), 6.8), "Rearm is 8 seconds, and Voss finishes in 6.8")
	expect(Art.has_asset("airfield"), "The airfield has original art")
	var gallery = PadArt.new()
	root.add_child(gallery)
	gallery.queue_redraw()
	await process_frame
	_standard_loop()
	_voss_loop()
	gallery.queue_free()
	print("AIRFIELD_SMOKE: %d failures" % failed)
	quit(0 if failed == 0 else 1)

func _standard_loop() -> void:
	var world = _arena(["alliance", "republic"])
	expect(world.tab_buttons.size() == 5 and world.queue_preview_labels.size() == 4, "The sidebar stays at five tabs and four queue slots")
	world._place_structure("yard", 0, Vector2(360, 520))
	world._place_structure("power", 0, Vector2(360, 360))
	expect(not world.queue_production(0, "build", "airfield"), "An airfield still requires a war factory")
	expect(not world.queue_production(0, "air", "a_striker"), "A Striker cannot be queued without an airfield")
	world._place_structure("factory", 0, Vector2(360, 700))
	expect(world.queue_production(0, "build", "airfield"), "A factory lets the airfield into the build lane")
	world.cancel_production(0, "build")
	world._place_structure("airfield", 0, Vector2(720, 520))
	var pad = _building(world, "airfield", 0)
	var plant = _building(world, "power", 0)
	world.structures.erase(plant)
	expect(not world.queue_production(0, "air", "a_striker"), "Aircraft still require a power plant")
	world.structures.append(plant)
	world._calculate_power(0)
	expect(world.queue_production(0, "air", "a_striker"), "A powered airfield queues the Striker on the air lane")
	expect(world.queue_production(0, "vehicle", "a_sentinel"), "A tank still queues on the vehicle lane at the same time")
	expect(not world.states[0]["lanes"]["air"].is_empty() and not world.states[0]["lanes"]["vehicle"].is_empty(), "Air and vehicle construction run side by side")
	world.current_tab = 3
	world._update_hud()
	expect(world.info_text.text.contains("AIR"), "The air lane reports on the details line")
	expect(world.action_buttons["a_striker"].visible and not world.action_buttons["airfield"].visible, "Striker stays on the vehicles tab")
	world.current_tab = 0
	world._update_hud()
	expect(world.action_buttons["airfield"].visible and world.action_buttons["airfield"].text.contains("AIRFIELD"), "The airfield cameo reads AIRFIELD")
	world._tick_production(0, 1000.0)
	var striker = _unit(world, "a_striker")
	var tank = _unit(world, "a_sentinel")
	expect(striker != null and tank != null, "The airfield and the factory both finish a unit")
	expect(striker.position.distance_to(pad.position) < 40.0 and striker.position.distance_to(_building(world, "factory", 0).position) > 80.0, "The Striker launches at the airfield, not the factory")
	expect(striker.ammo == 4 and striker.ammo_max == 4, "A new Striker carries four salvos")
	var shots: int = world.projectiles.size()
	var dummy = world._spawn("r_line", 1, Vector2(900, 520))
	for _i in range(4):
		striker.fire(dummy)
	expect(striker.ammo == 0 and world.projectiles.size() == shots + 4, "Four salvos spend the Striker dry")
	striker.fire(dummy)
	expect(world.projectiles.size() == shots + 4, "A dry Striker does not fire")
	striker.position = pad.position + Vector2(360, 0)
	var away: float = striker.position.distance_to(pad.position)
	for _step in range(8):
		striker._physics_process(0.2)
	expect(striker.position.distance_to(pad.position) < away - 40.0 and striker.destination.distance_to(pad.position) <= 12.0, "A dry Striker flies itself back to the airfield")
	striker.position = pad.position
	world.states[0]["power"] = 0
	world.states[0]["demand"] = 80
	for _step in range(40):
		world.service_aircraft(striker, 0.05)
	expect(striker.ammo == 0 and is_zero_approx(striker.rearm_left), "A brownout holds rearm at zero")
	world._calculate_power(0)
	expect(world.power_ok(0), "Power returns")
	for _step in range(158):
		world.service_aircraft(striker, 0.05)
	expect(striker.ammo == 0 and striker.rearming and striker.rearm_left > 7.5 and striker.rearm_left < 8.0, "Rearm has run most of the 8 seconds without a shot")
	world.service_aircraft(striker, 0.5)
	expect(striker.ammo == 4 and not striker.rearming, "Eight seconds on a powered pad refills the Striker")
	world.selected = [striker]
	striker.ammo = 0
	striker.rearming = true
	world._update_hud()
	expect(world.info_text.text.contains("SALVOS 0/4") and world.info_text.text.contains("REARMING"), "The selected aircraft shows salvos and rearm")
	striker.rearm_left = 2.5
	expect(world.save_match("user://airfield_smoke.json"), "The dry aircraft is written into the snapshot")
	striker.ammo = 4
	expect(world.load_match("user://airfield_smoke.json"), "The snapshot loads")
	striker = _unit(world, "a_striker")
	expect(striker != null and striker.ammo == 0 and is_equal_approx(striker.rearm_left, 2.5), "A resumed Striker stays dry")
	world.states[0]["lanes"].erase("air")
	world.states[0]["queued"].erase("air")
	world._tick_production(0, 0.05)
	expect(world.states[0]["lanes"].has("air") and world.states[0]["queued"].has("air"), "An older save without an air lane still ticks")
	world.current_tab = 3
	expect(world.queue_production(0, "vehicle", "a_sentinel") and world.queue_production(0, "air", "a_striker"), "Tank and aircraft can be queued again after a resume")
	world._cancel_current_tab()
	expect(world.states[0]["lanes"]["vehicle"].is_empty() and not world.states[0]["lanes"]["air"].is_empty(), "Vehicles-tab cancel clears the tank first")
	world._cancel_current_tab()
	expect(world.states[0]["lanes"]["air"].is_empty(), "The same cancel reaches the aircraft when the tank lane is idle")
	pad = _building(world, "airfield", 0)
	striker.position = pad.position
	striker.ammo = 0
	striker.rearm_left = 3.0
	pad.receive_damage(100000.0, null)
	world.service_aircraft(striker, 1.0)
	expect(striker.ammo == 0 and not striker.rearming, "No living airfield means no rearm")
	_erase("user://airfield_smoke.json")
	world.queue_free()

func _voss_loop() -> void:
	var world = _arena(["alliance_air", "republic"])
	expect(is_equal_approx(float(world._recipe("a_tempest").cost), 1650.0 * 1.1), "Voss still pays 10% more for the Tempest")
	world._place_structure("yard", 0, Vector2(360, 520))
	world._place_structure("power", 0, Vector2(360, 360))
	world._place_structure("factory", 0, Vector2(360, 700))
	world._place_structure("airfield", 0, Vector2(720, 520))
	expect(world.queue_production(0, "air", "a_tempest"), "Tempest queues from the airfield")
	world.cancel_production(0, "air")
	world.commander.teams[0].research["reinforced_hangars"] = true
	var tempest = world._spawn("a_tempest", 0, Vector2(720, 520))
	expect(tempest.ammo == 6 and tempest.ammo_max == 6, "A Tempest carries six salvos")
	expect(is_equal_approx(tempest.max_hp, 460.0 * 1.15), "Reinforced Hangars still add 15% hull on a Tempest from the airfield")
	tempest.ammo = 0
	tempest.position = _building(world, "airfield", 0).position
	for _step in range(135):
		world.service_aircraft(tempest, 0.05)
	expect(tempest.ammo == 0 and tempest.rearm_left > 6.4 and tempest.rearm_left < 6.8, "Voss rearm is 15% faster and has not finished early")
	world.service_aircraft(tempest, 0.4)
	expect(tempest.ammo == 6, "Voss refills at 6.8 seconds")
	world.queue_free()

func _arena(choices: Array):
	var world = Arena.new()
	world.army_choices = choices
	world.fog_enabled = false
	world.set_physics_process(false)
	root.add_child(world)
	world.set_physics_process(false)
	return world

func _building(world, kind: String, side: int):
	for building in world.structures:
		if is_instance_valid(building) and building.kind == kind and building.team == side:
			return building
	return null

func _unit(world, id: String):
	for unit in world.units:
		if is_instance_valid(unit) and unit.unit_id == id and unit.team == 0:
			return unit
	return null

func _erase(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
