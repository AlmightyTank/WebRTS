extends SceneTree
## godot --headless --path godot --script res://tests/command_screen_smoke.gd
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("run_checks")

func expect(value: bool, message: String) -> void:
	print(("PASS: " if value else "FAIL: ") + message)
	if not value:
		failures.append(message)

func run_checks() -> void:
	var menu = load("res://scenes/main_menu.tscn").instantiate()
	root.add_child(menu)
	await process_frame
	var battle = menu.showcase
	expect(battle != null and battle.showcase and not battle.hud.visible, "The main menu plays a battle with its command screen hidden")
	expect(battle.units.size() >= 8, "The menu battle is already fighting")
	expect(battle.retro_powerbar.fill_mode == ProgressBar.FILL_BOTTOM_TO_TOP, "The power bar fills from the bottom")
	expect(menu.menu_panel.offset_right < 500.0, "Home leaves the battle visible beside the buttons")
	menu._show_page("skirmish")
	expect(menu.menu_panel.offset_right > 800.0, "The skirmish form widens without covering the whole screen")
	menu._start_game()
	await process_frame
	expect(not is_instance_valid(menu.showcase) and is_instance_valid(menu.game), "Starting a match replaces the menu battle")
	var world = menu.game
	world.play_cue("low_power")
	expect(world.alert_banner.visible and world.alert_banner.text == "LOW POWER", "Low power posts a banner")
	world.states[0].queued.infantry = ["a_ranger", "a_ranger"]
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_RIGHT
	click.pressed = true
	world._on_cameo_pointer(click, "a_ranger")
	expect(world.states[0].queued.infantry.size() == 1, "Right click on a cameo removes one queued unit")
	world.states[0].queued.infantry = []
	world.states[0].lanes.infantry = {"id": "a_ranger", "paid": 40.0, "ready": false}
	world._on_cameo_pointer(click, "a_ranger")
	expect(world.states[0].lanes.infantry.is_empty(), "Right click cancels the cameo that is building")
	expect(is_instance_valid(world.command_cameo), "The command strip has a selected-unit cameo")
	world._spawn("a_ranger", 0, Vector2(400, 600))
	world._set_selected([world.units[world.units.size() - 1]])
	world._update_hud()
	expect(str(world.command_cameo.icon_name) == "a_ranger", "The command cameo follows the selection")
	menu._leave_game()
	await process_frame
	expect(menu.page == "home" and is_instance_valid(menu.showcase) and menu.showcase.showcase, "Returning to the menu starts another battle")
	menu.queue_free()
	await process_frame
	print("COMMAND_SCREEN_SMOKE: %d failures" % failures.size())
	quit(0 if failures.is_empty() else 1)
