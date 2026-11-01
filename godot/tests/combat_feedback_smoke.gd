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
 var tank = world._spawn("a_sentinel", 0, Vector2(350, 600))
 var enemy = world._spawn("a_sentinel", 1, Vector2(490, 600))
 world._refresh_fog()
 var origin: Vector2 = tank.position
 tank.fire(enemy)
 var fx = world.combat_feedback
 expect(fx != null and fx.effects.size() == 1 and fx.effects[0].kind == "muzzle", "Weapon fire emits a short muzzle flash")
 expect(tank.position == origin and tank.fire_feedback > 0, "Recoil leaves simulation position unchanged")
 world.paused = false
 world.projectiles.back()._physics_process(0.5)
 world.paused = true
 expect(enemy.hit_feedback > 0 and fx.effects.back().kind == "impact", "Damage provides a hit pulse and impact sparks")
 enemy.hp = 1
 tank.fire(enemy)
 world.paused = false
 world.projectiles.back()._physics_process(0.5)
 world.paused = true
 expect(fx.effects.back().kind == "death", "Lethal impacts produce a larger destruction effect")
 var count: int = fx.effects.size()
 world.show_combat_feedback(Vector2(1800, 100), "death", "CANNON")
 expect(fx.effects.size() == count, "Hidden battles do not create visible feedback")
 for i in range(150): world.show_combat_feedback(origin, "impact", "CANNON")
 expect(fx.effects.size() == fx.MAX_EFFECTS, "Feedback remains bounded under dense combat")
 fx._process(0.02)
 expect(fx.effects[0].age == 0.0, "Pause freezes feedback consistently with combat")
 world.paused = false
 tank._physics_process(0.2)
 fx._process(1.0)
 expect(fx.effects.is_empty() and tank.fire_feedback == 0.0, "Transient effects and recoil return to rest")
 world.paused = true
 world.show_combat_feedback(origin, "death", "CANNON", 25)
 fx.effects[0].age = 0.15
 fx.queue_redraw()
 if DisplayServer.get_name() != "headless":
  await process_frame
  await process_frame
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("user://combat_feedback.png")
 world.reset_battle()
 expect(fx.effects.is_empty(), "Restart removes previous battle effects")
 world.queue_free()
 await process_frame
 print("COMBAT_FEEDBACK_SMOKE: %d failures" % failures)
 quit(1 if failures else 0)
