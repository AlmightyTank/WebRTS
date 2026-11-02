extends SceneTree
## Alliance beam and Republic ironstorm share the silo timer, and the strikes feel different.
const Arena = preload("res://scripts/economy/skirmish_arena.gd")
const Kits = preload("res://scripts/economy/commander_system.gd")
const Art = preload("res://scripts/ui/industrial_art.gd")
const SAVE_PATH := "user://superweapon_smoke.json"
var failed := 0

class WeaponArt extends Node2D:
	func _draw() -> void:
		var ids: Array = ["beam_array", "ironstorm"]
		for style in range(3):
			for i in range(ids.size()):
				draw_set_transform(Vector2(160.0 + style * 280.0, 140.0 + i * 220.0))
				Art.draw_asset(self, ids[i], style, 0.0, NAN, 0.0, {"time": 0.4, "faction_style": style})
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
	_constants()
	var gallery = WeaponArt.new()
	root.add_child(gallery)
	gallery.queue_redraw()
	await process_frame
	_alliance()
	_republic()
	_gia()
	gallery.queue_free()
	_erase(SAVE_PATH)
	print("SUPERWEAPON_SMOKE: %d failures" % failed)
	quit(0 if failed == 0 else 1)

func _constants() -> void:
	for id in ["silo", "beam_array", "ironstorm"]:
		var data: Dictionary = Arena.STRUCTURE_DATA[id]
		var spec: Dictionary = Kits.SUPERWEAPONS[id]
		expect(data.cost == 5000.0 and data.time == 90.0 and data.demand == 100 and data.hp == 1800, id + " costs 5000, builds in 90s, draws 100, and has 1800 health")
		expect(is_equal_approx(float(spec.charge), 240.0) and is_equal_approx(float(spec.warning), 7.0), id + " charges for 240s and warns for 7s")
	expect(is_equal_approx(float(Kits.SUPERWEAPONS.beam_array.radius), 70.0) and Kits.BEAM_PULSES == 4 and is_equal_approx(Kits.BEAM_GAP, 0.65) and is_equal_approx(Kits.BEAM_DAMAGE, 220.0), "The beam is four pulses of 220 inside a radius of 70, 0.65s apart")
	expect(is_equal_approx(float(Kits.SUPERWEAPONS.ironstorm.radius), 145.0) and Kits.IRON_VOLLEYS == 3 and is_equal_approx(Kits.IRON_GAP, 1.8) and is_equal_approx(Kits.IRON_DAMAGE, 180.0), "Ironstorm is three volleys of 180 inside a radius of 145, 1.8s apart")
	expect(Art.has_asset("beam_array") and Art.has_asset("ironstorm"), "Both weapons have original art")

func _alliance() -> void:
	var world = _arena(["alliance", "republic"])
	var commander = world.commander
	expect(world.tab_buttons.size() == 5, "The sidebar stays at five tabs")
	expect(is_instance_valid(world.hud_powers) and not world.hud_powers.visible, "A standard army hides the beam until the array exists")
	_base(world, 0, "beam_array")
	commander.refresh_ui()
	world._update_hud()
	expect(world.hud_powers.visible, "Owning the array opens the power column")
	expect(world.action_buttons["beam_array"].text.contains("BEAM ARRAY") and world.action_buttons["beam_array"].text.contains("$5000"), "The build cameo reads BEAM ARRAY")
	expect(not world.queue_production(0, "build", "silo") and not world.queue_production(0, "build", "ironstorm"), "Alliance cannot queue the silo or the ironstorm")
	expect(world.queue_production(0, "build", "beam_array"), "A second array can still be queued")
	world.cancel_production(0, "build")
	expect(commander.silo_button.disabled and commander.countdown_labels["beam_array"].text == "240", "The cameo counts down from 240 while the array is charging")
	expect(commander.silo_button.tooltip_text.contains("Particle Beam Array"), "The cameo names the particle beam")
	commander.tick(1.0)
	expect(is_equal_approx(float(commander.teams[0].silo), 239.0), "Charge falls only while the array is powered")
	world.states[0]["power"] = 0
	commander.tick(3.0)
	expect(is_equal_approx(float(commander.teams[0].silo), 239.0), "A brownout freezes the beam charge")
	world._calculate_power(0)
	var array = _building(world, "beam_array", 0)
	array.hp = 0.0
	commander.tick(0.1)
	expect(is_equal_approx(float(commander.teams[0].silo), 240.0) and not world.hud_powers.visible, "Losing the array resets the charge and hides the column")
	array.hp = array.max_hp
	commander.refresh_ui()
	expect(world.hud_powers.visible, "Rebuilding the array shows the column again")
	var aim := Vector2(960, 700)
	expect(not commander.launch_superweapon(0, aim), "A full charge cannot fire")
	commander.teams[0].silo = 0.0
	world.paused = true
	expect(not commander.launch_superweapon(0, aim), "Pause blocks the beam")
	world.paused = false
	expect(not commander.launch_superweapon(0, Vector2(-30, -30)), "The beam rejects a point off the board")
	world.states[0]["power"] = 0
	expect(not commander.launch_superweapon(0, aim), "A brownout blocks the beam")
	world._calculate_power(0)
	world.fog_enabled = true
	world._refresh_fog()
	expect(not commander.launch_superweapon(0, Vector2(1800, 1100)), "The beam rejects a point in shroud")
	world.fog_enabled = false
	expect(not commander.launch_silo(0, aim), "Alliance has no missile silo")
	expect(world._place_structure("turret", 1, aim) and world._place_structure("turret", 0, aim + Vector2(-60, 0)), "The strike area has an enemy turret and a friendly turret")
	var turret = _building(world, "turret", 1)
	var friendly = _building(world, "turret", 0)
	var runner = world._spawn("a_sentinel_aa", 1, aim + Vector2(56, 0))
	var aircraft = world._spawn("a_striker", 1, aim + Vector2(0, 50))
	var warnings: int = world.audio.history.count("superweapon")
	commander.teams[0].silo = 0.0
	expect(commander.launch_superweapon(0, aim), "A powered, charged array fires")
	expect(commander.events.size() == 1 and str(commander.events[0].id) == "beam_array" and int(commander.events[0].pulse) == 0 and is_equal_approx(float(commander.events[0].radius), 70.0) and is_equal_approx(float(commander.events[0].remaining), 7.0), "The beam warns for 7 seconds inside a radius of 70")
	expect(world.audio.history.count("superweapon") == warnings + 1, "The warning plays the superweapon cue once")
	expect(not commander.launch_superweapon(0, aim), "A second array does not grant a second shot")
	runner.order_move(aim + Vector2(900, 0), false)
	var beam_hit: float = 220.0 * world.armor_multiplier("ENERGY", "STRUCTURE")
	var turret_hp: float = turret.hp
	var steps: int = _until(world, [runner], func() -> bool: return turret.hp < turret_hp, 180)
	expect(steps > 100 and steps < 160 and is_equal_approx(turret_hp - turret.hp, beam_hit), "The first pulse waits out the warning")
	expect(runner.position.distance_to(aim) > 70.0 and is_equal_approx(runner.hp, runner.max_hp), "A unit that leaves during the warning takes nothing")
	expect(is_equal_approx(friendly.hp, friendly.max_hp) and is_equal_approx(aircraft.hp, aircraft.max_hp), "The beam spares friendlies and aircraft")
	expect(int(commander.events[0].pulse) == 1 and bool(commander.events[0].get("quiet", false)), "Later pulses stay quiet")
	expect(world.audio.history.count("superweapon") == warnings + 1, "Follow-up pulses do not repeat the warning")
	var saved_charge: float = float(commander.teams[0].silo)
	expect(world.save_match(SAVE_PATH), "A beam between pulses is written into the snapshot")
	commander.teams[0].silo = 1.0
	commander.events[0].pulse = 9
	expect(world.load_match(SAVE_PATH), "The beam snapshot loads")
	turret = _building(world, "turret", 1)
	expect(int(commander.events[0].pulse) == 1 and is_equal_approx(float(commander.teams[0].silo), saved_charge), "Resume keeps the pulse index and the remaining charge")
	var after_resume: float = turret.hp
	_until(world, [], func() -> bool: return commander.events.is_empty(), 80)
	expect(is_equal_approx(after_resume - turret.hp, beam_hit * 3.0), "The resumed beam finishes the three pulses it had left")
	expect(world.audio.history.count("superweapon") == warnings + 1, "The resumed beam does not play the warning again")
	commander.teams[0].silo = 0.0
	var before_cut: float = turret.hp
	expect(commander.launch_superweapon(0, aim), "The array can fire again once the charge is cleared")
	_until(world, [], func() -> bool: return turret.hp < before_cut, 180)
	expect(is_equal_approx(before_cut - turret.hp, beam_hit), "The second strike also opens with one pulse")
	world.states[0]["power"] = 0
	world.states[0]["demand"] = 500
	var frozen: float = turret.hp
	_until(world, [], func() -> bool: return commander.events.is_empty(), 40)
	expect(commander.events.is_empty() and is_equal_approx(turret.hp, frozen), "A brownout cuts the beam off before the next pulse")
	world.queue_free()

func _republic() -> void:
	var world = _arena(["republic", "alliance"])
	var commander = world.commander
	expect(not world.hud_powers.visible, "A standard republic hides the ironstorm until the array exists")
	_base(world, 0, "ironstorm")
	commander.refresh_ui()
	world._update_hud()
	expect(world.hud_powers.visible and commander.silo_button.tooltip_text.contains("Ironstorm Artillery Array"), "Owning the array names the ironstorm")
	expect(world.action_buttons["ironstorm"].text.contains("IRONSTORM"), "The build cameo reads IRONSTORM")
	expect(not world.queue_production(0, "build", "silo") and not world.queue_production(0, "build", "beam_array"), "Republic cannot queue the other weapons")
	expect(world.queue_production(0, "build", "ironstorm"), "A second ironstorm can still be queued")
	world.cancel_production(0, "build")
	var aim := Vector2(960, 700)
	var bastion = world._spawn("r_bastion", 1, aim)
	commander.teams[0].silo = 0.0
	var warnings: int = world.audio.history.count("superweapon")
	commander.ai_tick(0)
	expect(commander.events.size() == 1 and str(commander.events[0].id) == "ironstorm" and commander.events[0].point.distance_to(aim) < 8.0 and is_equal_approx(float(commander.events[0].radius), 145.0), "The AI fires the ironstorm at a visible enemy")
	var scout = world._spawn("a_sentinel_aa", 1, aim + Vector2(90, 0))
	var friendly = world._spawn("r_line", 0, aim + Vector2(0, 100))
	var aircraft = world._spawn("a_striker", 1, aim + Vector2(-90, 0))
	expect(world.audio.history.count("superweapon") == warnings + 1, "Ironstorm warns once")
	var light_hit: float = 180.0 * world.armor_multiplier("ARTILLERY", "LIGHT")
	var heavy_hit: float = 180.0 * world.armor_multiplier("ARTILLERY", "HEAVY")
	var bastion_hp: float = bastion.hp
	var scout_hp: float = scout.hp
	var friendly_hp: float = friendly.hp
	var aircraft_hp: float = aircraft.hp
	_until(world, [], func() -> bool: return bastion.hp < bastion_hp, 180)
	expect(is_equal_approx(bastion_hp - bastion.hp, heavy_hit) and is_equal_approx(scout_hp - scout.hp, light_hit), "The first volley hits the tank and the fast vehicle")
	expect(is_equal_approx(friendly.hp, friendly_hp) and is_equal_approx(aircraft.hp, aircraft_hp), "Ironstorm spares friendlies and aircraft")
	var array = _building(world, "ironstorm", 0)
	array.receive_damage(array.hp + 10.0, null)
	expect(not world.has_structure(0, "ironstorm"), "The array can be destroyed after the shells are fired")
	bastion.order_move(aim + Vector2(800, 0), false)
	scout.order_move(aim + Vector2(800, 0), false)
	bastion_hp = bastion.hp
	scout_hp = scout.hp
	var moved: int = _until(world, [bastion, scout], func() -> bool: return bastion.hp < bastion_hp, 50)
	expect(moved > 30 and moved < 45, "The second volley waits about 1.8 seconds")
	expect(scout.position.distance_to(aim) > 145.0 and is_equal_approx(scout.hp, scout_hp), "The fast vehicle is outside the circle and skips the next volley")
	expect(bastion.position.distance_to(aim) < 145.0 and is_equal_approx(bastion_hp - bastion.hp, heavy_hit), "The tank is still inside, and the lost array does not stop the shells")
	expect(world.audio.history.count("superweapon") == warnings + 1, "Later volleys stay quiet")
	world.queue_free()

func _gia() -> void:
	var world = _arena(["gia", "alliance"])
	var commander = world.commander
	_base(world, 0, "silo")
	commander.refresh_ui()
	world._update_hud()
	expect(world.hud_powers.visible and world.action_buttons["silo"].text.contains("MISSILE SILO"), "GIA keeps the missile silo on the power column")
	expect(not world.queue_production(0, "build", "beam_array") and not world.queue_production(0, "build", "ironstorm"), "GIA cannot queue the beam or the ironstorm")
	commander.teams[0].silo = 0.0
	var aim := Vector2(960, 700)
	expect(commander.launch_silo(0, aim) and is_equal_approx(float(commander.events.back().radius), 100.0), "The silo still warns at radius 100 without payload research")
	world.queue_free()

func _base(world, side: int, weapon_id: String) -> void:
	world._place_structure("yard", side, Vector2(180, 200))
	world._place_structure("power", side, Vector2(180, 340))
	world._place_structure("power", side, Vector2(320, 200))
	world._place_structure("factory", side, Vector2(180, 500))
	world._place_structure("depot", side, Vector2(340, 360))
	world._place_structure(weapon_id, side, Vector2(340, 520))
	world._calculate_power(side)

func _arena(choices: Array):
	var world = Arena.new()
	world.army_choices = choices
	world.fog_enabled = false
	root.add_child(world)
	world.set_physics_process(false)
	world.actors.process_mode = Node.PROCESS_MODE_DISABLED
	for unit in world.units:
		if is_instance_valid(unit):
			unit.queue_free()
	world.units.clear()
	world.invalidate_occupancy()
	world.selected.clear()
	for building in world.structures.duplicate():
		if is_instance_valid(building):
			building.queue_free()
			world.structures.erase(building)
	world.static_obstacles.clear()
	world.obstacles.clear()
	world._rebuild_navigation()
	return world

func _building(world, kind: String, side: int):
	for building in world.structures:
		if is_instance_valid(building) and building.kind == kind and building.team == side and building.hp > 0.0:
			return building
	return null

func _until(world, actors: Array, done: Callable, limit: int) -> int:
	var steps := 0
	while steps < limit and not bool(done.call()):
		for actor in actors:
			if is_instance_valid(actor) and actor.hp > 0.0:
				actor._physics_process(0.05)
		world.commander.tick(0.05)
		steps += 1
	return steps

func _erase(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
