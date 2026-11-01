extends SceneTree
var failures := 0

func expect(value: bool, label: String) -> void:
 if value: print("PASS: " + label)
 else:
  failures += 1
  push_error(label)

func _initialize() -> void:
 call_deferred("_run")

func _run() -> void:
 var world = load("res://scenes/skirmish.tscn").instantiate()
 root.add_child(world)
 world.set_physics_process(false)
 world.paused = true
 var scout = world.units[0]
 var enemy = world.structures[0]
 world._refresh_fog()
 expect(world.fog.sees(0, scout.position), "Starting MCV reveals friendly territory")
 expect(not world.entity_visible_to(0, enemy) and not enemy.visible, "Enemy base starts hidden")
 expect(world._hit_building(enemy.position) == null, "Hidden buildings cannot be clicked")
 var old_position: Vector2 = scout.position
 scout.position = enemy.position + Vector2(-120, 0)
 world._refresh_fog()
 expect(world.entity_visible_to(0, enemy) and enemy.visible, "Scouting reveals the enemy base")
 expect(world.fog.explored(0, enemy.position), "Scouting records exploration")
 expect(world.fog.sees(1, enemy.position), "Enemy has independent friendly sight")
 scout.position = old_position
 world._refresh_fog()
 expect(not enemy.visible and not world.entity_visible_to(0, enemy), "Enemy disappears when sight is lost")
 expect(world.fog.explored(0, enemy.position), "Explored terrain persists after scout leaves")
 var cell := Vector2i(enemy.position / 48.0)
 expect(absf(world.fog.shroud_image.get_pixelv(cell).a - 0.72) < 0.01, "Explored shroud uses translucent darkness")
 var soldier = world._spawn("a_sentinel", 0, old_position)
 soldier.order_attack(enemy)
 expect(soldier.target == null, "Direct attack cannot lock unseen enemies")
 soldier.position = enemy.position + Vector2(-140, 0)
 world._refresh_fog()
 soldier.order_attack(enemy)
 expect(soldier.target == enemy, "Revealed enemy accepts an attack lock")
 soldier.position = old_position
 world._refresh_fog()
 world.paused = false
 soldier._physics_process(0.01)
 world.paused = true
 expect(soldier.target == null, "Losing shared sight drops the attack lock")
 if DisplayServer.get_name() != "headless":
  await process_frame
  await RenderingServer.frame_post_draw
  expect(root.get_texture().get_image().save_png("user://fog_of_war.png") == OK, "Rendered fog screenshot saved")
 world.reset_battle()
 expect(not world.fog.explored(0, enemy.position), "Restart clears exploration")
 world.queue_free()
 await process_frame
 print("FOG_OF_WAR_SMOKE: %d failures" % failures)
 quit(1 if failures else 0)
