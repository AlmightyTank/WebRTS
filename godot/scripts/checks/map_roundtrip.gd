extends SceneTree
## Headless contract check for map serialization, loading, and editor commands.

const MAP_DOCUMENT := preload("res://scripts/map_document.gd")
const MAP_GENERATOR := preload("res://scripts/map_generator.gd")
const MAP_SHOWCASE := preload("res://scripts/map_showcase.gd")
const BASELINE := "res://maps/procedural-skirmish.map.json"
const SAMPLE := "res://maps/editor-sample.map.json"

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var started := Time.get_ticks_msec()
	_check_contract()
	_check_rejections()
	_check_procedural_baseline()
	_check_sample_battlefield()
	_check_elevation()
	_check_editor()
	var elapsed := Time.get_ticks_msec() - started
	if failures.is_empty():
		print("map roundtrip: ok (%d ms)" % elapsed)
		quit(0)
	else:
		for failure in failures:
			print("FAIL: %s" % failure)
		print("map roundtrip: %d failure(s)" % failures.size())
		quit(1)


func expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func expect_error(text: String, fragment: String) -> void:
	var parsed: Dictionary = MAP_DOCUMENT.from_json(text)
	expect(not bool(parsed.ok) and str(parsed.error).contains(fragment), "expected '%s' but got '%s'" % [fragment, parsed.error])


func _check_contract() -> void:
	expect(MAP_DOCUMENT.TILE_W == 128 and MAP_DOCUMENT.TILE_H == 64, "tile contract changed")
	expect(MAP_DOCUMENT.VERSION == 1, "map version changed")
	var generated = MAP_GENERATOR.procedural_skirmish()
	expect(generated.width == 64 and generated.height == 64, "procedural map size drifted")
	expect(generated.headquarters == Vector2i(32, 32), "procedural headquarters drifted")
	expect(generated.terrain_at(Vector2i(0, 0)) == 0, "origin terrain drifted")
	expect(generated.terrain_at(Vector2i(10, 1)) == 4, "road stripe drifted")
	var historical_obstacles := 0
	for y in range(64):
		for x in range(64):
			expect(generated.terrain_at(Vector2i(x, y)) == _historical_kind(x, y), "terrain %d,%d drifted" % [x, y])
			var expected_obstacle := _historical_obstacle(x, y)
			expect(generated.obstacle_at(Vector2i(x, y)) == expected_obstacle, "obstacle %d,%d drifted" % [x, y])
			if expected_obstacle >= 0:
				historical_obstacles += 1
	expect(historical_obstacles > 0, "procedural map lost its decorations")
	var roundtrip: Dictionary = MAP_DOCUMENT.from_json(JSON.stringify(generated.to_dictionary()))
	expect(bool(roundtrip.ok) and generated.matches(roundtrip.document), "in-memory JSON round trip changed the map")


func _check_rejections() -> void:
	expect_error('{"format":"nope"}', "missing")
	expect_error(_sample_json().replace('"version": 1', '"version": 2'), "version")
	expect_error(_sample_json().replace('"meridian-warfront-map"', '"other-map"'), "format")
	expect_error(_sample_json().replace('"editor-sample"', '""'), "name")
	expect_error(_sample_json().replace("[128, 64]", "[64, 32]"), "Tile size")
	expect_error(_sample_json().replace('"00000005"', '"0000000x"'), "digit")
	expect_error(_sample_json().replace('"00000005"', '"0000000"'), "8-character")
	expect_error(_sample_json().replace('"x": 4, "y": 4', '"x": 0, "y": 0'), "footprint")
	expect_error(_sample_json().replace('"kind": "tree"', '"kind": "bush"'), "tree, rock, debris, or derrick")
	expect_error(_sample_json().replace('{"kind": "rock", "x": 6, "y": 1},', '{"kind": "rock", "x": 1, "y": 1},'), "duplicates")
	expect_error(_sample_json().replace('"x": 1, "y": 1', '"x": 4, "y": 4'), "headquarters")
	expect_error(_sample_json().replace("\n}", ',\n\t"seed": 1\n}'), "Unknown map field")
	var missing: Dictionary = MAP_DOCUMENT.load_from_file("res://maps/does-not-exist.map.json")
	expect(not bool(missing.ok), "missing file was accepted")


func _check_procedural_baseline() -> void:
	var generated = MAP_GENERATOR.procedural_skirmish()
	var loaded: Dictionary = MAP_DOCUMENT.load_from_file(BASELINE)
	expect(bool(loaded.ok), "baseline failed to load: %s" % loaded.error)
	if bool(loaded.ok):
		expect(generated.matches(loaded.document), "committed baseline does not match the procedural generator")
	var started := Time.get_ticks_msec()
	var battlefield = _spawn_battlefield(BASELINE)
	expect(Time.get_ticks_msec() - started < 10000, "baseline battlefield load regressed past 10s")
	expect(battlefield.map_data.matches(generated), "runtime battlefield did not keep the baseline")
	expect(battlefield.terrain.get_cell_atlas_coords(Vector2i(10, 1)).y == 0, "road base tile no longer sits on grass")
	expect(battlefield.transitions.get_cell_source_id(Vector2i(10, 1)) == 0, "road overlay missing")
	expect(battlefield.transitions.get_cell_source_id(Vector2i(0, 0)) == -1, "plain grass gained an overlay")
	expect(battlefield.is_cell_blocked(Vector2i(32, 32)), "headquarters cell is not blocked")
	expect(battlefield.is_cell_blocked(Vector2i(-1, 0)), "outside cells must be blocked")
	expect(battlefield.get_node("WorldActors").y_sort_enabled, "actor layer lost Y sorting")
	expect(battlefield.get_node("RTSCamera") != null, "camera was not created")
	expect(battlefield.headquarters.center_cell == Vector2i(32, 32), "headquarters left the map center")


func _check_sample_battlefield() -> void:
	var battlefield = _spawn_battlefield(SAMPLE)
	expect(battlefield.map_data.map_name == "editor-sample", "sample name was not applied")
	expect(battlefield.map_data.terrain_at(Vector2i(0, 2)) == 4, "sample road missing")
	expect(battlefield.map_data.obstacle_at(Vector2i(1, 1)) == 0, "sample tree missing")
	expect(battlefield.map_data.obstacle_at(Vector2i(6, 1)) == 1, "sample rock missing")
	expect(battlefield.map_data.obstacle_at(Vector2i(1, 6)) == 2, "sample debris missing")
	expect(battlefield.is_cell_blocked(Vector2i(1, 1)), "tree cell is not blocked")
	expect(battlefield.is_cell_blocked(Vector2i(4, 4)), "sample headquarters is not blocked")
	expect(not battlefield.is_cell_blocked(Vector2i(0, 2)), "road cell was blocked")
	expect(battlefield.transitions.get_cell_atlas_coords(Vector2i(0, 2)) == Vector2i(4, 1), "road transition mask drifted")
	expect(battlefield.transitions.get_cell_atlas_coords(Vector2i(6, 6)) == Vector2i(8, 0), "dirt transition mask drifted")
	expect(battlefield.transitions.get_cell_atlas_coords(Vector2i(7, 7)) == Vector2i(1, 0), "corner dirt mask drifted")
	expect(battlefield.terrain.get_cell_atlas_coords(Vector2i(7, 0)) == Vector2i(2, 1), "grass C atlas drifted")
	expect(battlefield.headquarters.position == battlefield.tile_to_world(Vector2i(4, 4)), "headquarters anchor drifted")
	expect(battlefield.get_node("WorldActors/Obstacle_1_1") != null, "obstacle node was not spawned")
	expect(not battlefield.paint_terrain(Vector2i(-1, 0), 3), "out-of-bounds paint succeeded")
	expect(not battlefield.paint_obstacle(Vector2i(4, 4), 0), "obstacle replaced the headquarters")
	expect(not battlefield.place_headquarters(Vector2i(0, 0)), "headquarters moved off the map")
	expect(battlefield.paint_obstacle(Vector2i(0, 2), 1), "obstacle paint on a road was rejected")
	expect(battlefield.obstacle_nodes[Vector2i(0, 2)].kind == 1, "painted obstacle kind was not applied")
	expect(battlefield.paint_terrain(Vector2i(0, 0), 3), "terrain paint failed")
	expect(battlefield.transitions.get_cell_source_id(Vector2i(0, 0)) == 0, "painted dirt did not refresh the overlay")
	var saved := "user://maps/sample-roundtrip.map.json"
	expect(battlefield.map_data.save_to_file(saved) == OK, "sample save failed: %s" % battlefield.map_data.last_error)
	var reloaded = _spawn_battlefield(saved)
	for y in range(8):
		for x in range(8):
			var cell := Vector2i(x, y)
			expect(_signature(battlefield, cell) == _signature(reloaded, cell), "reload drifted at %d,%d" % [x, y])


func _check_elevation() -> void:
	var generated = MAP_GENERATOR.procedural_skirmish()
	var without_heights: Dictionary = generated.to_dictionary()
	without_heights.erase("elevation")
	var flattened: Dictionary = MAP_DOCUMENT.from_dictionary(without_heights)
	expect(bool(flattened.ok) and flattened.document.elevation_at(Vector2i(0, 0)) == 0, "maps without elevation should stay flat")
	var corrupt: Dictionary = MAP_SHOWCASE.hill().to_dictionary()
	corrupt.elevation[0] = "4" + "0".repeat(23)
	var rejected: Dictionary = MAP_DOCUMENT.from_dictionary(corrupt)
	expect(not bool(rejected.ok) and str(rejected.error).contains("0-3"), "bad elevation digit was accepted: %s" % rejected.error)
	for pair in [["res://maps/elevation-escarpment.map.json", MAP_SHOWCASE.escarpment()], ["res://maps/elevation-basin.map.json", MAP_SHOWCASE.basin()], ["res://maps/elevation-hill.map.json", MAP_SHOWCASE.hill()]]:
		var loaded: Dictionary = MAP_DOCUMENT.load_from_file(pair[0])
		expect(bool(loaded.ok) and pair[1].matches(loaded.document), "showcase drifted: %s" % pair[0])
	var hill = _spawn_battlefield("res://maps/elevation-hill.map.json")
	var peak := Vector2i(12, 12)
	expect(hill.map_data.elevation_at(peak) == 3, "hill peak is not elevation 3")
	expect(hill.map_data.elevation_at(Vector2i(0, 0)) == 0, "hill corner should be flat")
	var flat_center: Vector2 = hill.terrain.map_to_local(peak)
	expect(is_equal_approx(hill.tile_to_world(peak).y, flat_center.y - 3 * MAP_DOCUMENT.ELEVATION_RISE), "peak tile was not lifted")
	expect(hill.world_to_tile(hill.tile_to_world(peak)) == peak, "picking missed the raised peak")
	expect(hill.world_to_tile(hill.tile_to_world(Vector2i(0, 0))) == Vector2i(0, 0), "picking missed a flat corner")
	expect(hill.level_terrain[3].get_cell_source_id(peak) == 0, "peak was not drawn on the top layer")
	expect(hill.level_terrain[0].get_cell_source_id(peak) == -1, "peak was also drawn on the ground layer")
	expect(hill.headquarters.position == hill.tile_to_world(hill.map_data.headquarters), "headquarters did not follow elevation")
	expect(hill.paint_elevation(Vector2i(1, 1), 2), "elevation paint failed")
	expect(hill.map_data.elevation_at(Vector2i(1, 1)) == 2, "elevation paint did not stick")
	expect(hill.level_terrain[2].get_cell_source_id(Vector2i(1, 1)) == 0, "painted height used the wrong layer")
	var escarpment = _spawn_battlefield("res://maps/elevation-escarpment.map.json")
	expect(escarpment.map_data.elevation_at(Vector2i(12, 4)) == 2, "escarpment plateau is flat")
	expect(escarpment.map_data.elevation_at(Vector2i(12, 18)) == 0, "escarpment foreground is raised")
	expect(escarpment._cliff_drop(Vector2i(12, 7), Vector2i(0, 1)) == 1, "escarpment cliff does not face the camera")
	var cycle := _key(KEY_BRACKETRIGHT)
	escarpment._unhandled_input(cycle)
	expect(escarpment.map_data.map_name == "elevation-basin", "bracket did not cycle to the basin")
	var editor = load("res://scenes/map_editor.tscn").instantiate()
	root.add_child(editor)
	editor.load_from("res://maps/elevation-hill.map.json")
	var high := _key(KEY_R)
	editor._unhandled_input(high)
	expect(editor.brush_mode == "elevation" and editor.brush_kind == 2, "elevation shortcut failed")
	expect(editor.apply_brush_at(Vector2i(1, 20)), "editor elevation brush failed")
	expect(editor.battlefield.map_data.elevation_at(Vector2i(1, 20)) == 2, "editor elevation paint missed")
	var bay = MAP_SHOWCASE.mercy_bay()
	var loaded_bay: Dictionary = MAP_DOCUMENT.load_from_file("res://maps/mercy-bay.map.json")
	expect(bool(loaded_bay.ok) and bay.matches(loaded_bay.document), "Mercy Bay file drifted: %s" % loaded_bay.error)
	expect(bay.all_spawns().size() == 6, "Mercy Bay should have six landing pads")
	expect(bay.terrain_at(Vector2i(0, 0)) == MAP_DOCUMENT.TERRAIN_WATER, "Mercy Bay corner should be water")
	expect(bay.terrain_at(Vector2i(32, 24)) == MAP_DOCUMENT.TERRAIN_GEM or bay.elevation_at(Vector2i(32, 24)) == 2, "Mercy Bay highland missing")
	var island = _spawn_battlefield("res://maps/mercy-bay.map.json")
	expect(island.is_cell_blocked(Vector2i(0, 0)), "water should block movement")
	expect(island.extra_spawns.size() == 5, "extra landing bases were not spawned")
	expect(island.camera.position.distance_to(island.tile_to_world(bay.focus_cell())) < 2.0, "camera did not frame the island")


func _check_editor() -> void:
	var editor = load("res://scenes/map_editor.tscn").instantiate()
	root.add_child(editor)
	expect(editor.load_from(SAMPLE), "editor could not load the sample")
	expect(editor.battlefield.map_data.width == 8, "editor stayed on the previous map size")
	var dirt := _key(KEY_4)
	editor._unhandled_input(dirt)
	expect(editor.brush_mode == "terrain" and editor.brush_kind == 3, "dirt shortcut failed")
	expect(editor.apply_brush_at(Vector2i(2, 2)), "editor brush did not paint")
	expect(editor.battlefield.map_data.terrain_at(Vector2i(2, 2)) == 3, "editor paint missed the cell")
	var headquarters := _key(KEY_H)
	editor._unhandled_input(headquarters)
	expect(editor.brush_mode == "headquarters", "headquarters shortcut failed")
	expect(not editor.apply_brush_at(Vector2i(0, 0)), "editor moved headquarters out of bounds")
	expect(editor.battlefield.map_data.headquarters == Vector2i(4, 4), "failed headquarters move changed the cell")
	editor.path_edit.grab_focus()
	var blocked := _key(KEY_5)
	editor._unhandled_input(blocked)
	expect(editor.brush_mode == "headquarters", "line edit focus should keep number keys from changing tools")
	editor.path_edit.release_focus()
	var sketch := "user://maps/editor-sketch.map.json"
	editor.path_edit.text = sketch
	var save := _key(KEY_S)
	save.ctrl_pressed = true
	editor._unhandled_input(save)
	expect(FileAccess.file_exists(sketch), "Ctrl+S did not write the map")
	var fresh = _spawn_battlefield(sketch)
	expect(fresh.map_data.terrain_at(Vector2i(2, 2)) == 3, "saved editor paint did not load")
	editor.new_procedural()
	expect(editor.battlefield.map_data.width == 64, "new procedural map was not 64 tiles")
	expect(editor.battlefield.map_data.matches(MAP_GENERATOR.procedural_skirmish()), "new procedural map drifted")


func _spawn_battlefield(path: String):
	var battlefield = load("res://scenes/battlefield.tscn").instantiate()
	battlefield.map_path = path
	root.add_child(battlefield)
	return battlefield


func _signature(battlefield, cell: Vector2i) -> Array:
	return [
		battlefield.map_data.terrain_at(cell),
		battlefield.map_data.elevation_at(cell),
		battlefield.map_data.obstacle_at(cell),
		battlefield.is_cell_blocked(cell),
		battlefield.terrain.get_cell_atlas_coords(cell),
		battlefield.terrain.get_cell_source_id(cell),
		battlefield.transitions.get_cell_atlas_coords(cell),
		battlefield.transitions.get_cell_source_id(cell),
	]


func _key(keycode: Key) -> InputEventKey:
	var event := InputEventKey.new()
	event.pressed = true
	event.keycode = keycode
	event.echo = false
	return event


func _historical_kind(x: int, y: int) -> int:
	if abs(x - y - 9) <= 1:
		return 4
	if x > 17 and x < 35 and y > 19 and y < 33:
		return 3 if (x + y) % 7 == 0 else 2
	return posmod(x * 13 + y * 7 + x * y, 4) if (x + y) % 11 == 0 else posmod(x * 3 + y * 5, 3)


func _historical_obstacle(x: int, y: int) -> int:
	if x < 2 or y < 2 or x >= 62 or y >= 62:
		return -1
	if abs(x - 32) <= 3 and abs(y - 32) <= 3:
		return -1
	if _historical_kind(x, y) == 4:
		return -1
	var hash_value: int = posmod(x * 73856093 ^ y * 19349663, 997)
	if hash_value >= 22:
		return -1
	return hash_value % 3


func _sample_json() -> String:
	return FileAccess.get_file_as_string(SAMPLE)
