extends SceneTree
var failures: Array[String] = []

func _initialize() -> void:
 call_deferred("run_checks")

func expect(ok: bool, message: String) -> void:
 if not ok:
  failures.append(message)
  push_error(message)

func run_checks() -> void:
 var menu = load("res://scenes/main_menu.tscn").instantiate()
 root.add_child(menu)
 await process_frame
 expect(menu.page == "home" and menu.overlay.visible, "Starts at main menu")
 for page in ["skirmish", "settings", "controls", "credits", "quit"]:
  menu._show_page(page)
  await process_frame
  expect(menu.content.get_child_count() > 3, "Populates " + page)
 menu._start_game()
 await process_frame
 expect(is_instance_valid(menu.game) and not menu.overlay.visible, "Launches battlefield")
 expect(menu.game.process_mode == Node.PROCESS_MODE_PAUSABLE, "Battlefield pauses")
 var event := InputEventKey.new()
 event.keycode = KEY_F10
 event.pressed = true
 menu._input(event)
 expect(paused and menu.page == "pause", "F10 pauses match")
 menu._show_page("controls")
 expect(paused, "Subpages keep simulation paused")
 menu._resume()
 expect(not paused and not menu.overlay.visible, "Resumes match")
 menu._leave_game()
 await process_frame
 expect(menu.game == null and menu.page == "home", "Return clears match")
 menu.queue_free()
 await process_frame
 if failures.is_empty(): print("MAIN_MENU_SMOKE_PASS")
 quit(0 if failures.is_empty() else 1)
