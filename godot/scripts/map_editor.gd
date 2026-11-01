extends Node
## Desktop authoring tool for terrain, decorations, and the headquarters cell.
const MAP_DOCUMENT := preload("res://scripts/map_document.gd")
const MAP_GENERATOR := preload("res://scripts/map_generator.gd")
const BASELINE_PATH := "res://maps/procedural-skirmish.map.json"
const DEFAULT_SAVE_PATH := "res://maps/sketch.map.json"

@onready var battlefield = $Battlefield
var path_edit: LineEdit
var status: Label
var hud_root: Control
var preview: Node2D
var brush_mode := "terrain"
var brush_kind := 0
var painting := false
var tool_buttons: Dictionary = {}


func _ready() -> void:
	_build_hud()
	preview = Node2D.new()
	preview.name = "BrushPreview"
	preview.z_index = 20
	preview.z_as_relative = false
	preview.draw.connect(_draw_preview)
	add_child(preview)
	_set_status("Tool: Grass. Click a tile to paint. Save writes the path below.")


func apply_brush_at(cell: Vector2i) -> bool:
	var painted := false
	if brush_mode == "terrain":
		painted = battlefield.paint_terrain(cell, brush_kind)
	elif brush_mode == "obstacle":
		painted = battlefield.paint_obstacle(cell, brush_kind)
	elif brush_mode == "headquarters":
		painted = battlefield.place_headquarters(cell)
	elif brush_mode == "elevation":
		painted = battlefield.paint_elevation(cell, brush_kind)
	if painted:
		_set_status("Updated %s at %d, %d." % [brush_mode, cell.x, cell.y])
	else:
		_set_status(str(battlefield.map_data.last_error))
	return painted


func save_to(path: String) -> bool:
	var trimmed := path.strip_edges()
	if trimmed.is_empty():
		_set_status("Enter a map path.")
		return false
	var error: Error = battlefield.map_data.save_to_file(trimmed)
	if error != OK:
		_set_status(str(battlefield.map_data.last_error))
		return false
	_set_status("Saved %s." % trimmed)
	return true


func load_from(path: String) -> bool:
	var trimmed := path.strip_edges()
	if trimmed.is_empty():
		_set_status("Enter a map path.")
		return false
	var loaded: Dictionary = MAP_DOCUMENT.load_from_file(trimmed)
	if not bool(loaded.ok):
		_set_status(str(loaded.error))
		return false
	battlefield.apply_map(loaded.document)
	_set_status("Loaded %s (%d×%d)." % [loaded.document.map_name, loaded.document.width, loaded.document.height])
	return true


func new_procedural() -> void:
	battlefield.apply_map(MAP_GENERATOR.procedural_skirmish())
	_set_status("Generated a new procedural skirmish map.")


func load_baseline() -> bool:
	return load_from(BASELINE_PATH)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if _shortcut_blocked():
			return
		if _handle_shortcut(event):
			get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if _pointer_over_hud():
			return
		painting = event.pressed
		if event.pressed:
			apply_brush_at(_cell_under_mouse())
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and painting:
		if _pointer_over_hud():
			return
		apply_brush_at(_cell_under_mouse())
		get_viewport().set_input_as_handled()


func _process(_delta: float) -> void:
	if preview == null or battlefield == null or battlefield.terrain == null:
		return
	if _pointer_over_hud():
		preview.visible = false
		return
	var cell := _cell_under_mouse()
	if not battlefield.map_data.in_bounds(cell):
		preview.visible = false
		return
	preview.visible = true
	preview.position = battlefield.tile_to_world(cell)
	preview.queue_redraw()


func _draw_preview() -> void:
	var points := PackedVector2Array([
		Vector2(0, -32), Vector2(64, 0), Vector2(0, 32), Vector2(-64, 0), Vector2(0, -32)
	])
	preview.draw_polyline(points, Color(1, 1, 1, 0.9), 2.0, true)


func _handle_shortcut(event: InputEventKey) -> bool:
	if event.ctrl_pressed and event.keycode == KEY_S:
		save_to(path_edit.text)
		return true
	if event.ctrl_pressed and event.keycode == KEY_L:
		load_from(path_edit.text)
		return true
	if event.ctrl_pressed and event.keycode == KEY_N:
		new_procedural()
		return true
	if event.ctrl_pressed and event.keycode == KEY_B:
		load_baseline()
		return true
	if event.ctrl_pressed or event.alt_pressed or event.meta_pressed:
		return false
	match event.keycode:
		KEY_1:
			_select_terrain(0)
		KEY_2:
			_select_terrain(1)
		KEY_3:
			_select_terrain(2)
		KEY_4:
			_select_terrain(3)
		KEY_5:
			_select_terrain(4)
		KEY_6:
			_select_terrain(5)
		KEY_7:
			_select_obstacle(0)
		KEY_8:
			_select_obstacle(1)
		KEY_9:
			_select_obstacle(2)
		KEY_0:
			_select_obstacle(-1)
		KEY_H:
			_select_headquarters()
		KEY_Q:
			_select_elevation(0)
		KEY_E:
			_select_elevation(1)
		KEY_R:
			_select_elevation(2)
		KEY_T:
			_select_elevation(3)
		KEY_Y:
			_select_terrain(MAP_DOCUMENT.TERRAIN_WATER)
		KEY_U:
			_select_terrain(MAP_DOCUMENT.TERRAIN_SAND)
		KEY_I:
			_select_terrain(MAP_DOCUMENT.TERRAIN_ORE)
		KEY_O:
			_select_terrain(MAP_DOCUMENT.TERRAIN_GEM)
		KEY_P:
			_select_obstacle(3)
		KEY_BRACKETRIGHT:
			cycle_showcase(1)
		KEY_BRACKETLEFT:
			cycle_showcase(-1)
		_:
			return false
	return true


func _cell_under_mouse() -> Vector2i:
	return battlefield.world_to_tile(battlefield.get_global_mouse_position())


func _pointer_over_hud() -> bool:
	var hovered := get_viewport().gui_get_hovered_control()
	return hovered != null and hovered != hud_root


func _shortcut_blocked() -> bool:
	return get_viewport().gui_get_focus_owner() is LineEdit


func _select_terrain(kind: int) -> void:
	brush_mode = "terrain"
	brush_kind = kind
	_refresh_tool_buttons()
	_set_status("Tool: %s." % ["Grass", "Grass B", "Blend", "Dirt", "Road", "Grass C", "Water", "Sand", "Ore", "Gem"][kind])


func _select_obstacle(kind: int) -> void:
	brush_mode = "obstacle"
	brush_kind = kind
	_refresh_tool_buttons()
	_set_status("Tool: %s." % ("Erase obstacle" if kind < 0 else ["Tree", "Rock", "Debris", "Derrick"][kind]))


func _select_headquarters() -> void:
	brush_mode = "headquarters"
	brush_kind = 0
	_refresh_tool_buttons()
	_set_status("Tool: Headquarters. Click the new center cell.")


func _select_elevation(level: int) -> void:
	brush_mode = "elevation"
	brush_kind = level
	_refresh_tool_buttons()
	_set_status("Tool: elevation %d. Click a tile to raise or lower it." % level)


func cycle_showcase(step: int) -> void:
	battlefield._cycle_showcase(step)
	_set_status("Loaded %s (%d×%d)." % [battlefield.map_data.map_name, battlefield.map_data.width, battlefield.map_data.height])


func _refresh_tool_buttons() -> void:
	for key in tool_buttons.keys():
		var button: Button = tool_buttons[key]
		var active := false
		if brush_mode == "terrain" and key == "terrain-%d" % brush_kind:
			active = true
		elif brush_mode == "obstacle" and key == "obstacle-%d" % brush_kind:
			active = true
		elif brush_mode == "headquarters" and key == "headquarters":
			active = true
		elif brush_mode == "elevation" and key == "elevation-%d" % brush_kind:
			active = true
		button.modulate = Color(0.75, 0.95, 0.75) if active else Color.WHITE


func _build_hud() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	hud_root = Control.new()
	hud_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	hud_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(hud_root)
	var panel := PanelContainer.new()
	panel.position = Vector2(12, 12)
	panel.custom_minimum_size = Vector2(560, 0)
	hud_root.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	panel.add_child(box)
	var title := Label.new()
	title.text = "Map editor"
	box.add_child(title)
	box.add_child(_tool_row([
		["Grass", "terrain-0", _select_terrain.bind(0)],
		["Grass B", "terrain-1", _select_terrain.bind(1)],
		["Blend", "terrain-2", _select_terrain.bind(2)],
		["Dirt", "terrain-3", _select_terrain.bind(3)],
		["Road", "terrain-4", _select_terrain.bind(4)],
		["Grass C", "terrain-5", _select_terrain.bind(5)],
	]))
	box.add_child(_tool_row([
		["Water", "terrain-6", _select_terrain.bind(MAP_DOCUMENT.TERRAIN_WATER)],
		["Sand", "terrain-7", _select_terrain.bind(MAP_DOCUMENT.TERRAIN_SAND)],
		["Ore", "terrain-8", _select_terrain.bind(MAP_DOCUMENT.TERRAIN_ORE)],
		["Gem", "terrain-9", _select_terrain.bind(MAP_DOCUMENT.TERRAIN_GEM)],
	]))
	box.add_child(_tool_row([
		["Tree", "obstacle-0", _select_obstacle.bind(0)],
		["Rock", "obstacle-1", _select_obstacle.bind(1)],
		["Debris", "obstacle-2", _select_obstacle.bind(2)],
		["Derrick", "obstacle-3", _select_obstacle.bind(3)],
		["Erase", "obstacle--1", _select_obstacle.bind(-1)],
		["HQ", "headquarters", _select_headquarters],
	]))
	box.add_child(_tool_row([
		["Flat", "elevation-0", _select_elevation.bind(0)],
		["Low", "elevation-1", _select_elevation.bind(1)],
		["High", "elevation-2", _select_elevation.bind(2)],
		["Peak", "elevation-3", _select_elevation.bind(3)],
	]))
	box.add_child(_tool_row([
		["Escarpment", "show-escarpment", func() -> void: load_from("res://maps/elevation-escarpment.map.json")],
		["Basin", "show-basin", func() -> void: load_from("res://maps/elevation-basin.map.json")],
		["Hill", "show-hill", func() -> void: load_from("res://maps/elevation-hill.map.json")],
		["Mercy Bay", "show-mercy", func() -> void: load_from("res://maps/mercy-bay.map.json")],
	]))
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 6)
	box.add_child(actions)
	actions.add_child(_action_button("Save", func() -> void: save_to(path_edit.text)))
	actions.add_child(_action_button("Load", func() -> void: load_from(path_edit.text)))
	actions.add_child(_action_button("New procedural", new_procedural))
	actions.add_child(_action_button("Load baseline", load_baseline))
	path_edit = LineEdit.new()
	path_edit.text = DEFAULT_SAVE_PATH
	path_edit.placeholder_text = "res://maps/name.map.json or user://maps/name.map.json"
	path_edit.custom_minimum_size = Vector2(520, 0)
	box.add_child(path_edit)
	status = Label.new()
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.custom_minimum_size = Vector2(520, 48)
	box.add_child(status)
	_refresh_tool_buttons()


func _tool_row(entries: Array) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	for entry in entries:
		var button := Button.new()
		button.text = entry[0]
		button.pressed.connect(entry[2])
		row.add_child(button)
		tool_buttons[entry[1]] = button
	return row


func _action_button(text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.pressed.connect(callback)
	return button


func _set_status(message: String) -> void:
	if status != null:
		status.text = message
