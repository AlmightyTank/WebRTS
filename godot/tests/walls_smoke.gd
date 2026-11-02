extends SceneTree
## Walls seal a ground line. Gates open for their owner. Factions do not share health.
const Arena = preload("res://scripts/economy/skirmish_arena.gd")
const Rules = preload("res://scripts/economy/army_rules.gd")
const Art = preload("res://scripts/ui/industrial_art.gd")
const SAVE_PATH := "user://walls_smoke.json"
var failed := 0

class PerimeterArt extends Node2D:
	func _draw() -> void:
		for style in range(3):
			draw_set_transform(Vector2(160.0 + style * 220.0, 140.0))
			Art.draw_asset(self, "wall", style, 0.0, NAN, 0.0, {"faction_style": style})
			draw_set_transform(Vector2(160.0 + style * 220.0, 300.0))
			Art.draw_asset(self, "gate", style, 0.0, NAN, 0.0, {"faction_style": style, "door": 1.0})
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
	expect(Art.has_asset("wall") and Art.has_asset("gate"), "Walls and gates have original art")
	var gallery = PerimeterArt.new()
	root.add_child(gallery)
	gallery.queue_redraw()
	await process_frame
	_profiles()
	_line()
	gallery.queue_free()
	_erase(SAVE_PATH)
	print("WALLS_SMOKE: %d failures" % failed)
	quit(0 if failed == 0 else 1)

func _profiles() -> void:
	for row in [["alliance", 100.0, 6.0, 600.0, 180.0, 8.0, "Energy-Reinforced Barrier", "Security Gate"], ["republic", 150.0, 8.0, 1200.0, 250.0, 10.0, "Reinforced Concrete Wall", "Fortress Gate"], ["gia", 50.0, 4.0, 280.0, 90.0, 5.0, "Scrap Barricade", "Checkpoint Gate"]]:
		var choice: String = row[0]
		var world = _arena([choice, choice])
		var wall_spec: Dictionary = Rules.perimeter(choice, "wall")
		var gate_spec: Dictionary = Rules.perimeter(choice, "gate")
		expect(is_equal_approx(float(wall_spec.cost), float(row[1])) and is_equal_approx(float(wall_spec.time), float(row[2])) and is_equal_approx(float(wall_spec.hp), float(row[3])), choice + " wall price, time, and health")
		expect(is_equal_approx(float(gate_spec.cost), float(row[4])) and is_equal_approx(float(gate_spec.time), float(row[5])) and is_equal_approx(float(gate_spec.hp), float(row[3])), choice + " gate costs more and uses the wall's health")
		world._place_structure("wall", 0, Vector2(408, 408))
		world._place_structure("gate", 0, Vector2(408, 456))
		var wall = _building(world, "wall", 0)
		var gate = _building(world, "gate", 0)
		expect(wall != null and is_equal_approx(wall.max_hp, float(row[3])) and is_equal_approx(wall.paid_value, float(row[1])), choice + " places a wall at that health and refund base")
		expect(str(world._recipe("wall", 0).name) == str(row[6]) and str(world._recipe("gate", 0).name) == str(row[7]), choice + " cameo uses its own names")
		expect(gate != null and is_equal_approx(gate.max_hp, float(row[3])), choice + " gate health matches the wall")
		world.queue_free()

func _line() -> void:
	var world = _arena(["alliance", "republic"])
	world.static_obstacles.clear()
	world.tree_footprints.clear()
	world.obstacles.clear()
	world._rebuild_navigation()
	expect(world.tab_buttons.size() == 5, "The sidebar stays at five tabs")
	expect(not world.queue_production(0, "defense", "wall"), "A wall still needs a construction yard")
	world._place_structure("yard", 0, Vector2(216, 216))
	expect(not world.queue_production(0, "defense", "turret"), "A turret still waits for a barracks")
	expect(world.queue_production(0, "defense", "wall"), "The yard queues a wall on the defense lane")
	world.cancel_production(0, "defense")
	world._ai_economy(0)
	expect(world.states[0]["lanes"]["defense"].is_empty(), "The opening AI does not buy a wall")
	world.current_tab = 1
	world._update_hud()
	expect(world.action_buttons["wall"].visible and world.action_buttons["wall"].text.contains("WALL") and world.action_buttons["wall"].text.contains("$100"), "The defense tab reads WALL $100")
	expect(world.action_buttons["gate"].text.contains("GATE") and world.action_buttons["gate"].text.contains("$180"), "The defense tab reads GATE $180")
	expect(world.action_buttons["wall"].tooltip_text.contains("Energy-Reinforced Barrier"), "The tooltip names the Alliance barrier")
	var snapped: Vector2 = world._snap_build_point("wall", Vector2(1000, 610))
	expect(snapped.is_equal_approx(Vector2(984, 600)), "A wall snaps to the navigation cell")
	var column := 20
	var gate_row := 12
	for row in range(25):
		var at := Vector2((column + 0.5) * 48.0, (row + 0.5) * 48.0)
		world._place_structure("gate" if row == gate_row else "wall", 0, at)
	var gate = _building(world, "gate", 0)
	var sealed := true
	for row in range(25):
		if not world.navigation.is_point_solid(Vector2i(column, row)):
			sealed = false
	expect(sealed and gate != null, "The column seals every ground cell, including the gate")
	var west := Vector2(792, 600)
	var east := Vector2(1176, 600)
	var friendly = world._spawn("a_sentinel_aa", 0, west)
	var owned: PackedVector2Array = world.find_route(west, east, false, friendly)
	var through := false
	for point in owned:
		if point.distance_to(gate.position) < 8.0:
			through = true
	expect(not owned.is_empty() and through, "The owner's route walks the gate cell")
	friendly.position = gate.position
	gate._process(0.2)
	expect(gate.door_open > 0.2, "A nearby owner opens the gate")
	friendly.position = west
	gate._process(1.0)
	expect(is_zero_approx(gate.door_open), "The gate closes when the owner leaves")
	var stranger = world._spawn("r_bastion", 1, gate.position + Vector2(0, 80))
	gate._process(0.5)
	expect(is_zero_approx(gate.door_open), "An enemy does not open the gate")
	stranger.queue_free()
	world.units.erase(stranger)
	friendly.order_move(east, false)
	for _step in range(120):
		friendly._physics_process(0.05)
	expect(friendly.position.x > gate.position.x + 40.0, "The owner drives through the gate")
	var enemy = world._spawn("r_bastion", 1, west + Vector2(0, 48))
	var denied: PackedVector2Array = world.find_route(enemy.position, east, false, enemy)
	expect(denied.is_empty(), "An enemy has no ground route through the line")
	var held: float = enemy.position.x
	enemy.order_move(east, false)
	for _step in range(40):
		enemy._physics_process(0.05)
	expect(enemy.position.x <= held + 8.0, "The enemy does not walk through the wall")
	var aircraft = world._spawn("a_striker", 1, west)
	var flight: PackedVector2Array = world.find_route(west, east, true, aircraft)
	aircraft.order_move(east, false)
	for _step in range(40):
		aircraft._physics_process(0.05)
	expect(flight.size() == 1 and aircraft.position.x > gate.position.x + 40.0, "Aircraft fly over the line")
	expect(not world.clear_shot(west, east, false, false, null), "A ground shot stops on the line")
	expect(world.clear_shot(west, gate.position, false, false, gate), "The gate itself can be targeted")
	expect(world.clear_shot(west, east, true, false, null), "An aircraft shot crosses the line")
	var cracked = _building(world, "wall", 0)
	cracked.hp = 250.0
	expect(world.save_match(SAVE_PATH), "The line is written into the snapshot")
	expect(world.load_match(SAVE_PATH), "The line snapshot loads")
	var restored := false
	for building in world.structures:
		if is_instance_valid(building) and building.kind == "wall" and is_equal_approx(building.hp, 250.0):
			restored = true
	gate = _building(world, "gate", 0)
	expect(restored and gate != null, "A resumed wall keeps its damage and the gate")
	world.static_obstacles.clear()
	world._rebuild_navigation()
	var engineer = world._spawn_engineer("a_engineer", 1, gate.position + Vector2(-80, 0))
	expect(world.capture_structure(engineer, gate) and gate.team == 1, "Capturing the gate hands it to the engineer")
	var old_owner = world._spawn("a_sentinel_aa", 0, west)
	var new_owner = world._spawn("r_bastion", 1, west + Vector2(0, 64))
	expect(world.find_route(west, east, false, old_owner).is_empty(), "The old owner loses the passage")
	var handed: PackedVector2Array = world.find_route(new_owner.position, east, false, new_owner)
	expect(not handed.is_empty(), "The new owner receives the passage")
	var before: float = float(world.states[1]["credits"])
	var gate_cell: Vector2i = world.world_cell(gate.position)
	expect(world.sell_structure(1, gate), "The new owner can sell the gate")
	expect(is_equal_approx(float(world.states[1]["credits"]) - before, 90.0), "Selling the gate refunds half of 180")
	expect(not world.navigation.is_point_solid(gate_cell), "The sold gate opens that ground cell")
	var reopened: PackedVector2Array = world.find_route(west, east, false, old_owner)
	expect(not reopened.is_empty(), "Either side can cross once the gate is gone")
	world.queue_free()

func _arena(choices: Array):
	var world = Arena.new()
	world.army_choices = choices
	world.fog_enabled = false
	root.add_child(world)
	world.set_physics_process(false)
	world.actors.process_mode = Node.PROCESS_MODE_DISABLED
	return world

func _building(world, kind: String, side: int):
	for building in world.structures:
		if is_instance_valid(building) and building.kind == kind and building.team == side and building.hp > 0.0:
			return building
	return null

func _erase(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
