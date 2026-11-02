extends SceneTree
var failures := 0

func expect(ok: bool, label: String) -> void:
 print(("PASS: " if ok else "FAIL: ") + label)
 if not ok: failures += 1

func click(world, point: Vector2, shift := false, double := false, right := false) -> void:
 var event := InputEventMouseButton.new()
 event.position = world.get_global_transform_with_canvas() * point
 event.button_index = MOUSE_BUTTON_RIGHT if right else MOUSE_BUTTON_LEFT
 event.shift_pressed = shift
 event.double_click = double
 event.pressed = true
 root.push_input(event, true)
 event = event.duplicate()
 event.pressed = false
 event.double_click = false
 root.push_input(event, true)

func _initialize() -> void:
 call_deferred("run_checks")

func run_checks() -> void:
 root.size = Vector2i(1280,720)
 var world = load("res://scenes/combat_lab.tscn").instantiate()
 root.add_child(world)
 await process_frame
 world.paused = true
 world.camera.set_process(false)
 world.camera.set_physics_process(false)
 world.camera.force_update_scroll()
 var actor = world.units[0]
 click(world, actor.position)
 expect(world.selected == [actor], "Click selects one actor")
 click(world, actor.position, true)
 expect(world.selected.is_empty() and not actor.selected, "Shift-click removes selected actor")
 click(world, actor.position)
 click(world, Vector2(700,700), true)
 expect(world.selected == [actor], "Shift-empty-click preserves selection")
 click(world, actor.position, false, true)
 expect(world.selected.size()==2, "Double-click selects on-screen actors of the same type")
 world.mode = "ATTACK_MOVE"
 var revision: int = actor.order_revision
 click(world, Vector2(650,600), false, false, true)
 expect(world.mode=="MOVE" and actor.order_revision==revision, "Right-click cancels armed command without issuing movement")
 world._set_selected([actor])
 var key := InputEventKey.new()
 key.keycode = KEY_J
 key.pressed = true
 root.push_input(key,true)
 expect(actor.hold_position and not actor.moving, "J holds position")
 world.paused = false
 actor.cooldown = 100.0
 var enemy = world.units[7]
 enemy.position = actor.position + Vector2(200,0)
 actor.target = enemy
 var original: Vector2 = actor.position
 actor._physics_process(0.1)
 expect(actor.position==original and not actor.moving, "Holding actor does not chase a target outside weapon range")
 actor.order_move(Vector2(650,600))
 expect(not actor.hold_position and actor.moving, "Move replaces hold position")
 world.queue_free()
 await process_frame
 print("TACTICAL_INPUT_SMOKE_", "PASS" if failures==0 else "FAIL")
 quit(0 if failures==0 else 1)
