extends SceneTree
## Rook, Volkov, and Nadir: stealth, one structure or stance, research, and three powers.
const Arena = preload("res://scripts/economy/skirmish_arena.gd")
const Art = preload("res://scripts/ui/industrial_art.gd")
var failures := 0

class Gallery extends Node2D:
	func _draw() -> void:
		var ids := ["a_pathfinder", "r_garrison", "g_shade", "ghost_node", "pillbox", "concealed_nest", "sandbag", "passage"]
		for i in ids.size():
			draw_set_transform(Vector2(90 + i * 150, 180))
			Art.draw_asset(self, ids[i], 0, 0.2, 0.4)
		draw_set_transform(Vector2.ZERO)

func expect(ok: bool, label: String) -> void:
	if ok:
		print("PASS: " + label)
	else:
		failures += 1
		push_error(label)

func _initialize() -> void:
	call_deferred("run")

func prepare(choice: String):
	var world = Arena.new()
	world.army_choices = [choice, choice]
	world.fog_enabled = false
	root.add_child(world)
	world.set_physics_process(false)
	world.paused = false
	world.obstacles.clear()
	world.static_obstacles.clear()
	world._rebuild_navigation()
	for side in range(2):
		world.states[side].credits = 100000.0
	world._place_structure("yard", 0, Vector2(420, 520))
	world._place_structure("power", 0, Vector2(280, 320))
	world._place_structure("power", 0, Vector2(280, 460))
	world._place_structure("barracks", 0, Vector2(420, 760))
	world._place_structure("factory", 0, Vector2(700, 520))
	var service := "ghost_node" if choice == "alliance_ghost" else "depot"
	world._place_structure(service, 0, Vector2(700, 300))
	world._calculate_power(0)
	return world

func pad(world, kind: String) -> Vector2:
	for radius in [110.0, 170.0, 230.0, 300.0]:
		for i in 12:
			var point: Vector2 = Vector2(420, 520) + Vector2.RIGHT.rotated(TAU * float(i) / 12.0) * radius
			if world.can_place(point, kind, 0):
				return point
	return Vector2.ZERO

func run() -> void:
	for id in ["a_pathfinder", "a_ghost_carrier", "r_garrison", "r_siege_carrier", "g_shade", "g_ghost_technical", "ghost_node", "pillbox", "concealed_nest", "sandbag", "passage"]:
		expect(Art.has_asset(id), id + " has original art")
	_rook()
	_volkov()
	_nadir()
	Art._building_mesh_cache.clear()
	var gallery := Gallery.new()
	root.add_child(gallery)
	await process_frame
	await process_frame
	expect(Art._building_mesh_cache.size() >= 5, "Doctrine structures cache a mesh")
	gallery.queue_free()
	print("GENERALS_SMOKE: %d failures" % failures)
	quit(1 if failures else 0)

func _rook() -> void:
	var world = prepare("alliance_ghost")
	var commander = world.commander
	expect(world.tab_buttons.size() == 5, "Ghost Command keeps the five sidebar tabs")
	expect(world.hud_powers.visible, "Ghost Command shows its power column")
	expect(world.queue_production(0, "infantry", "a_pathfinder"), "Pathfinders queue from the barracks")
	world.cancel_production(0, "infantry")
	expect(world.queue_production(0, "build", "ghost_node"), "The operations node queues like a depot")
	world.cancel_production(0, "build")
	expect(not world.queue_production(0, "build", "depot"), "Rook cannot build a normal depot")
	expect(commander.start_research(0, "silent_running"), "Silent Running starts at the operations node")
	commander.tick(40.0)
	expect(commander.has_research(0, "silent_running"), "Silent Running completes")
	var shade_standin = world._spawn("a_pathfinder", 1, Vector2(1100, 700))
	shade_standin.stationary_time = 3.0
	shade_standin._tick_cloak()
	expect(shade_standin.cloaked and not world.entity_visible_to(0, shade_standin), "A settled pathfinder is hidden with fog off")
	expect(world.entity_visible_to(1, shade_standin), "The owner still sees a cloaked pathfinder")
	var watcher = world._spawn("a_pathfinder", 0, shade_standin.position + Vector2(80, 0))
	expect(world.detected_by(0, shade_standin) and world.entity_visible_to(0, shade_standin), "A pathfinder detects hidden enemies")
	watcher.position = Vector2(80, 80)
	var node = world._place_structure("ghost_node", 0, shade_standin.position + Vector2(100, 0))
	expect(node and world.entity_visible_to(0, shade_standin), "The operations node detects hidden enemies")
	for building in world.structures:
		if building.kind == "ghost_node" and building.position.distance_to(shade_standin.position) < 200.0:
			building.position = Vector2(80, 200)
	shade_standin.fire(watcher)
	expect(not shade_standin.cloaked and shade_standin.cloak_hold > 0.0 and world.entity_visible_to(0, shade_standin), "Firing reveals a cloaked unit")
	var mover = world._spawn("a_pathfinder", 1, Vector2(1200, 800))
	mover.moving = true
	mover.cloak_hold = 0.0
	mover.stationary_time = 0.0
	mover._tick_cloak()
	expect(not mover.cloaked, "Pathfinders do not cloak while moving")
	commander.teams[1].research["silent_running"] = true
	mover._tick_cloak()
	expect(mover.cloaked, "Silent Running lets pathfinders cloak on the move")
	commander.teams[0].research["coordinated_designation"] = true
	var shooter = world._spawn("a_sentinel", 0, Vector2(900, 700))
	var marked = world._spawn("r_line", 1, watcher.position)
	watcher.position = marked.position + Vector2(40, 0)
	var shot: Dictionary = shooter.weapon.duplicate(true)
	commander.modify_shot(shooter, marked, shot, 1.0)
	expect(is_equal_approx(shot.damage, shooter.weapon.damage * 1.08), "Coordinated Designation adds 8 percent once")
	commander.reveals.append({"side": 0, "point": marked.position, "radius": 80.0, "remaining": 5.0, "mark": true})
	shot = shooter.weapon.duplicate(true)
	commander.modify_shot(shooter, marked, shot, 1.0)
	expect(is_equal_approx(shot.damage, shooter.weapon.damage * 1.1), "A mark replaces designation instead of stacking")
	commander.award_xp(0, 3500.0)
	for id in commander.power_ids(0):
		expect(commander.buy_power(0, id), "Buy " + id)
	world.fog_enabled = true
	world._refresh_fog()
	expect(commander.cast(0, "signal_sweep", Vector2(1800, 200)) and not commander.reveals.is_empty(), "Signal Sweep scouts shroud")
	expect(not commander.cast(0, "electronic_blackout", Vector2(1800, 1100)), "Electronic Blackout needs shared sight")
	world.fog_enabled = false
	commander.teams[0].cooldowns["signal_sweep"] = 0.0
	var foe = world._spawn("r_line", 1, Vector2(1280, 520))
	var friend = world._spawn("a_ranger", 0, Vector2(1160, 520))
	expect(foe.can_hit(friend), "A line infantry can target before the blackout")
	var powered: bool = world.power_ok(0)
	expect(commander.cast(0, "electronic_blackout", foe.position), "Electronic Blackout arms")
	expect(world.power_ok(0) == powered, "Electronic Blackout does not shut down power")
	commander.tick(2.05)
	expect(not foe.can_hit(friend), "Electronic Blackout stops targeting")
	var before: int = world.units.size()
	var landing: Vector2 = world._find_open_position(Vector2(980, 860), 18.0)
	expect(commander.cast(0, "covert_insertion", landing), "Covert Insertion arms")
	commander.tick(3.05)
	var inserted := 0
	for unit in world.units:
		if is_instance_valid(unit) and unit.unit_id == "a_pathfinder" and unit.life_left > 0.0:
			inserted += 1
	expect(world.units.size() > before and inserted == 3, "Covert Insertion delivers three temporary pathfinders")
	world.free()

func _volkov() -> void:
	var world = prepare("republic_fortress")
	var commander = world.commander
	var box: Vector2 = pad(world, "pillbox")
	expect(box != Vector2.ZERO and world._place_structure("pillbox", 0, box), "Steel Pillbox places from the defense tab rules")
	var pillbox = world.structures[world.structures.size() - 1]
	expect(is_equal_approx(pillbox.max_hp, 1600.0 * 1.15), "Pillbox health includes the defense bonus once")
	var segment: Vector2 = pad(world, "wall")
	world._place_structure("wall", 0, segment)
	var wall = world.structures[world.structures.size() - 1]
	var wall_hp: float = wall.hp
	wall.receive_damage(100.0, null)
	expect(is_equal_approx(wall_hp - wall.hp, 100.0), "Walls take full damage before the fortification research")
	commander.teams[0].research["reinforced_fortifications"] = true
	wall_hp = wall.hp
	wall.receive_damage(100.0, null)
	expect(is_equal_approx(wall_hp - wall.hp, 90.0), "Reinforced Fortifications reduces defense damage by 10 percent")
	var carrier = world._spawn("r_siege_carrier", 0, Vector2(980, 760))
	carrier.order_deploy()
	expect(is_equal_approx(carrier.deploy_left, 3.0), "Siege Carrier takes three seconds to deploy")
	carrier._physics_process(3.05)
	expect(carrier.deployed and not carrier.moving, "A deployed Siege Carrier holds still")
	var away: Vector2 = carrier.position + Vector2(0, 200)
	carrier.order_move(away)
	expect(not carrier.deployed and carrier.packing and carrier.deploy_left > 0.0, "Leaving the stance packs the carrier before it moves")
	commander.teams[0].research["mobile_field_works"] = true
	var faster = world._spawn("r_siege_carrier", 0, Vector2(1100, 760))
	faster.order_deploy()
	expect(is_equal_approx(faster.deploy_left, 2.0), "Mobile Field Works shortens deployment to two seconds")
	commander.award_xp(0, 3500.0)
	for id in commander.power_ids(0):
		expect(commander.buy_power(0, id), "Buy " + id)
	var rally: Vector2 = world._find_open_position(Vector2(500, 900), 18.0)
	var guards_before := 0
	for unit in world.units:
		if unit.unit_id == "r_garrison":
			guards_before += 1
	expect(commander.cast(0, "reserve_garrison", rally), "Reserve Garrison arms beside the barracks")
	commander.tick(3.05)
	var guards := 0
	for unit in world.units:
		if is_instance_valid(unit) and unit.unit_id == "r_garrison" and unit.life_left < 0.0:
			guards += 1
	expect(guards >= guards_before + 5, "Reserve Garrison delivers five guards")
	var yard = null
	for building in world.structures:
		if building.kind == "yard" and building.team == 0:
			yard = building
	expect(yard != null and commander.cast(0, "hold_the_line", yard.position), "Hold the Line arms on an owned structure")
	var guard = world._spawn("r_garrison", 0, yard.position)
	var health: float = guard.hp
	guard.receive_damage(100.0, null)
	expect(is_equal_approx(health - guard.hp, 85.0), "Hold the Line reduces damage by 15 percent")
	yard.hp = yard.max_hp - 30.0
	var credits: float = world.states[0].credits
	commander.tick(1.0)
	expect(yard.hp > yard.max_hp - 30.0 and world.states[0].credits < credits, "Hold the Line repairs for credits")
	expect(not commander.cast(0, "emergency_fortification", Vector2(1700, 200)), "Emergency Fortification cannot extend the build radius")
	expect(float(commander.teams[0].cooldowns.get("emergency_fortification", 0.0)) == 0.0, "A rejected fortification does not start the cooldown")
	var bags: Vector2 = pad(world, "sandbag")
	expect(commander.cast(0, "emergency_fortification", bags), "Emergency Fortification arms inside the base")
	var sandbags := 0
	for building in world.structures:
		if building.kind == "sandbag" and building.hp > 0.0:
			sandbags += 1
			expect(is_equal_approx(building.max_hp, 450.0) and building.life_left > 0.0, "Sandbags are temporary and limited")
	expect(sandbags >= 1, "Emergency Fortification places sandbags")
	for building in world.structures:
		if building.kind != "sandbag":
			building.team = 1
	for unit in world.units:
		if str(unit.unit_id) in ["a_mcv", "r_mcv", "g_mcv"]:
			unit.hp = 0.0
	expect(not world._side_alive(0), "Sandbags do not keep a defeated base alive")
	world.free()

func _nadir() -> void:
	var world = prepare("gia_guerrilla")
	var commander = world.commander
	expect(not world.queue_production(0, "vehicle", "g_scavenger"), "Shadow Front cannot build a Scavenger")
	expect(world.queue_production(0, "vehicle", "g_rocket_buggy"), "Rocket Buggies stay available")
	world.cancel_production(0, "vehicle")
	var nest_at: Vector2 = pad(world, "concealed_nest")
	expect(world._place_structure("concealed_nest", 0, nest_at), "Concealed Gun Nest places")
	var nest = world.structures[world.structures.size() - 1]
	expect(nest.cloaked and not world.entity_visible_to(1, nest), "The nest starts hidden from the enemy")
	expect(world.entity_visible_to(0, nest), "The owner can see the concealed nest")
	var victim = world._spawn("r_line", 1, nest.position + Vector2(90, 0))
	nest.timer = 0.0
	nest._physics_process(0.05)
	expect(not nest.cloaked and nest.reveal_left > 0.0 and world.projectiles.size() > 0, "The nest reveals itself when it fires")
	var shade = world._spawn("g_shade", 1, Vector2(1280, 860))
	shade.stationary_time = 3.0
	shade.moving = false
	shade._tick_cloak()
	expect(shade.cloaked and not world.entity_visible_to(0, shade), "Shade infantry cloak after three seconds with fog off")
	var quarry = world._spawn("a_ranger", 0, shade.position + Vector2(40, 0))
	shade.fire(quarry)
	expect(not shade.cloaked and world.entity_visible_to(0, shade), "Firing breaks Shade concealment")
	expect(is_equal_approx(world.projectiles[world.projectiles.size() - 1].damage, 19.5), "The opening shot from cloak hits harder")
	shade.cloaked = true
	shade.cloak_hold = 0.0
	commander.teams[1].research["safe_passage"] = true
	var before: float = shade.hp
	shade.receive_damage(40.0, victim)
	expect(is_equal_approx(before - shade.hp, 34.0), "Safe Passage reduces damage while concealed")
	expect(shade.cloak_hold > 0.0, "Damage reveals a concealed Shade")
	commander.teams[0].research["camo_netting"] = true
	var faster = world._spawn("g_shade", 0, Vector2(860, 900))
	expect(is_equal_approx(faster._cloak_delay(), 2.2), "Camo Netting shortens concealment by 0.8 seconds")
	commander.award_xp(0, 3500.0)
	for id in commander.power_ids(0):
		expect(commander.buy_power(0, id), "Buy " + id)
	expect(commander.cast(0, "false_signals", Vector2(1000, 400)) and commander.decoys.size() == 2, "False Signals plants two radar contacts")
	var ambush: Vector2 = world._find_open_position(Vector2(1040, 900), 18.0)
	expect(commander.cast(0, "ambush_cell", ambush), "Ambush Cell arms")
	commander.tick(3.05)
	var cells := 0
	for unit in world.units:
		if is_instance_valid(unit) and unit.unit_id == "g_shade" and unit.life_left > 40.0:
			cells += 1
	expect(cells == 4, "Ambush Cell delivers four temporary Shade Cells")
	var gate_at: Vector2 = world._find_open_position(Vector2(1180, 640), 18.0)
	expect(commander.cast(0, "hidden_passage", gate_at), "Hidden Passage arms on revealed ground")
	commander.tick(2.05)
	var passage = null
	for building in world.structures:
		if building.kind == "passage" and building.hp > 0.0:
			passage = building
	expect(passage != null and passage.life_left > 0.0, "Hidden Passage places a temporary checkpoint")
	var owner = world._spawn("g_militia", 0, passage.position + Vector2(0, 40))
	var intruder = world._spawn("r_line", 1, passage.position + Vector2(0, 80))
	expect(world.passage_open(owner, passage.ground_bounds()) and not world.passage_open(intruder, passage.ground_bounds()), "The checkpoint opens for its owner")
	for building in world.structures:
		if building.kind != "passage":
			building.team = 1
	for unit in world.units:
		if str(unit.unit_id) in ["a_mcv", "r_mcv", "g_mcv"]:
			unit.hp = 0.0
	expect(not world._side_alive(0), "A hidden passage does not keep a defeated base alive")
	world.free()
