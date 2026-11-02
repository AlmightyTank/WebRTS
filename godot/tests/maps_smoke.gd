extends SceneTree
## Eight skirmish maps. Larger boards scroll, and every map still has a ground route, iron, and one relay.
const Arena = preload("res://scripts/economy/skirmish_arena.gd")
const Maps = preload("res://scripts/economy/skirmish_maps.gd")
const Preview = preload("res://scripts/ui/skirmish_map_preview.gd")
const SAVE_PATH := "user://maps_smoke.json"
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
	var names: Array = []
	var ids: PackedStringArray = Maps.ids()
	expect(ids.size() == 8 and str(ids[0]) == "meridian_basin", "Eight maps, with Meridian Basin first")
	for id in ids:
		var map: Dictionary = Maps.get_map(id)
		names.append(str(map["name"]))
		_check_schema(id, map)
	expect(names.size() == 8, "Each map has its own name")
	var seen := {}
	var unique := true
	for map_name in names:
		if seen.has(map_name):
			unique = false
		seen[map_name] = true
	expect(unique, "Map names do not repeat")
	var preview = Preview.new()
	root.add_child(preview)
	preview.size = Vector2(420, 250)
	for id in ids:
		preview.map_id = str(id)
		preview._draw()
	preview.queue_free()
	var menu = load("res://scenes/main_menu.tscn").instantiate()
	root.add_child(menu)
	menu._show_page("skirmish")
	var picker: OptionButton = menu.find_child("MapSelect", true, false)
	var listed := true
	if picker == null or picker.item_count != ids.size():
		listed = false
	else:
		for index in picker.item_count:
			if str(picker.get_item_metadata(index)) != str(ids[index]):
				listed = false
	expect(listed, "The lobby lists every map in order, starting with Meridian Basin")
	menu.queue_free()
	for id in ids:
		_play(str(id))
	_resume_large()
	_erase(SAVE_PATH)
	print("MAPS_SMOKE: %d failures" % failed)
	quit(0 if failed == 0 else 1)

func _check_schema(id: String, map: Dictionary) -> void:
	var board: Rect2 = map["board"]
	var wide: bool = is_equal_approx(fmod(board.size.x, 48.0), 0.0) and is_equal_approx(fmod(board.size.y, 48.0), 0.0)
	var west: Vector2 = map["spawns"]["west"]
	var east: Vector2 = map["spawns"]["east"]
	var relay: Vector2 = map["relay"]
	var ore: Array = map["ore"]
	var inside: bool = board.has_point(west) and board.has_point(east) and board.has_point(relay)
	expect(wide and board.size.x >= 1920.0 and board.size.y >= 1200.0 and inside, id + " uses the cell grid and keeps its starts on the board")
	expect(west.distance_to(east) > 900.0 and ore.size() >= 5, id + " separates the starts and offers at least five iron fields")
	for site in ore:
		var at: Vector2 = site["position"]
		if not board.grow(-80.0).has_point(at) or west.distance_to(at) < 180.0 or east.distance_to(at) < 180.0:
			inside = false
	expect(inside, id + " keeps iron on the board and away from the starts")

func _play(id: String) -> void:
	var map: Dictionary = Maps.get_map(id)
	var world = _open(id)
	var board: Rect2 = map["board"]
	expect(is_equal_approx(world.BOARD.size.x, board.size.x) and is_equal_approx(world.BOARD.size.y, board.size.y), id + " builds that board")
	var west: Vector2 = map["spawns"]["west"]
	var east: Vector2 = map["spawns"]["east"]
	var player = _mcv(world, 0)
	var yard = _building(world, "yard", 1)
	var relay = _building(world, "relay", -1)
	expect(player != null and player.position.distance_to(west) < 2.0, id + " deploys the player on the west start")
	expect(yard != null and yard.position.distance_to(east) < 2.0, id + " deploys the computer on the east start")
	expect(player != null and world.can_place(player.position, "yard", 0), id + " can deploy a yard on its start")
	expect(relay != null and relay.position.distance_to(map["relay"]) < 2.0, id + " places the one relay")
	var route: PackedVector2Array = world.find_route(west, east, false, player)
	expect(not route.is_empty(), id + " has a ground route between the starts")
	var open_ore := true
	for field in world.ore_fields:
		if not world.can_occupy(field["position"], 20.0, false):
			open_ore = false
	expect(open_ore and world.ore_fields.size() == map["ore"].size(), id + " leaves every iron field open")
	var trees := false
	for item in world.scenery:
		if str(item["kind"]) == "tree":
			trees = true
	expect(trees, id + " still has trees")
	if id == "meridian_basin":
		expect(world.camera.destination.distance_to(board.get_center()) < 30.0, "Meridian Basin still opens on the middle of the field")
	elif board.size.x > 1920.0:
		var at: Vector2 = world.camera.destination
		var half: Vector2 = world.get_viewport_rect().size * 0.5 / world.camera.zoom_goal
		var view := Rect2(at - half, half * 2.0)
		expect(view.has_point(west) and at.distance_squared_to(west) < at.distance_squared_to(board.get_center()), id + " opens toward the player's start")
	world.queue_free()

func _resume_large() -> void:
	var world = _open("amber_reach")
	expect(world.save_match(SAVE_PATH), "Amber Reach can be saved")
	world.queue_free()
	var resumed = _open("meridian_basin")
	expect(resumed.load_match(SAVE_PATH), "A saved large map resumes")
	expect(resumed.map_id == "amber_reach" and is_equal_approx(resumed.BOARD.size.x, 3840.0) and resumed.ore_fields.size() == 7, "Resume rebuilds the Amber Reach board and its iron")
	var player = _mcv(resumed, 0)
	expect(player != null and player.position.distance_to(Vector2(560, 1720)) < 2.0, "The resumed player is still on the Amber Reach start")
	resumed.queue_free()

func _open(id: String):
	var world = Arena.new()
	world.map_id = id
	world.fog_enabled = false
	world.army_choices = ["alliance", "republic"]
	world.start_slots = ["west", "east"]
	root.add_child(world)
	world.set_physics_process(false)
	return world

func _mcv(world, team: int):
	for unit in world.units:
		if is_instance_valid(unit) and unit.team == team and str(unit.unit_id).ends_with("mcv"):
			return unit
	return null

func _building(world, kind: String, team: int):
	for building in world.structures:
		if is_instance_valid(building) and building.kind == kind and building.team == team and building.hp > 0.0:
			return building
	return null

func _erase(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
