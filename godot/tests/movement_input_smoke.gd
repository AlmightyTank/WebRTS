extends SceneTree
## Run without --headless to exercise viewport input and capture the live renderer.
var failures: Array[String] = []

func expect(value: bool, label: String) -> void:
 print(("PASS: " if value else "FAIL: ") + label)
 if not value:
  failures.append(label)

func click_world(arena, point: Vector2, queued: bool, button_index: int = MOUSE_BUTTON_RIGHT) -> void:
 var screen: Vector2 = arena.get_global_transform_with_canvas() * point
 var motion := InputEventMouseMotion.new()
 motion.position = screen
 root.push_input(motion, true)
 var button := InputEventMouseButton.new()
 button.position = screen
 button.button_index = button_index
 button.pressed = true
 button.shift_pressed = queued
 root.push_input(button, true)
 button = button.duplicate()
 button.pressed = false
 root.push_input(button, true)

func _initialize() -> void:
 await process_frame
 var arena = load("res://scenes/congestion_lab.tscn").instantiate()
 root.add_child(arena)
 await process_frame
 arena.camera.set_process(false)
 arena.camera.set_physics_process(false)
 click_world(arena, Vector2(1200, 540), false)
 await process_frame
 expect(arena.units[0].moving, "Viewport right-click orders selected army")
 var original: Vector2 = arena.units[0].destination
 expect(original.distance_to(Vector2(1200, 540)) < 400, "Mouse order uses event world coordinates")
 click_world(arena, Vector2(1440, 840), true)
 await process_frame
 expect(arena.units[0].pending_orders.size() == 1 and arena.units[0].destination == original, "Viewport Shift-right-click appends instead of replacing")
 var start: Vector2 = arena.units[0].position
 await create_timer(1.0).timeout
 expect(arena.units[0].position.distance_to(start) > 5, "Live physics advances army")
 if DisplayServer.get_name() != "headless":
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("user://movement_lab.png")
  print("Screenshot: ", ProjectSettings.globalize_path("user://movement_lab.png"))
 var stop := InputEventKey.new()
 stop.keycode = KEY_S
 stop.pressed = true
 root.push_input(stop, true)
 await process_frame
 expect(not arena.units[0].moving and arena.units[0].pending_orders.is_empty(), "Viewport S cancels active and queued orders")
 click_world(arena, arena.units[0].position, false, MOUSE_BUTTON_LEFT)
 await process_frame
 expect(arena.selected.size() == 1 and arena.selected[0] == arena.units[0], "Viewport left-click selects one tank")
 arena.queue_free()
 await process_frame
 print("MOVEMENT_INPUT_SMOKE_", "PASS" if failures.is_empty() else "FAIL")
 quit(0 if failures.is_empty() else 1)
