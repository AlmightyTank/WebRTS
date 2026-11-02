extends SceneTree
## A captured relay pays one capped trickle, and a working harvester still earns more.
const Arena = preload("res://scripts/economy/skirmish_arena.gd")
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
	var world = _arena()
	var rate := float(world.RELAY_CREDITS_PER_SECOND)
	expect(is_equal_approx(world.ORE_BITE, 18.0) and is_equal_approx(world.ORE_BITE_SECONDS, 0.15) and is_equal_approx(rate, 6.0), "Ore bite and relay rate stay the documented pair")
	var relay = _relay(world)
	expect(relay != null and relay.team < 0, "The north relay starts neutral")
	var credits := float(world.states[0]["credits"])
	world._tick_relay_income(10.0)
	expect(is_equal_approx(float(world.states[0]["credits"]), credits), "A neutral relay pays nothing")
	_capture(world, "a_engineer", 0, relay)
	expect(relay.team == 0, "The player captures the relay")
	world._place_structure("barracks", 0, Vector2(420, 520))
	expect(not world.power_ok(0), "The base is in a brownout")
	world._tick_relay_income(10.0)
	expect(is_equal_approx(float(world.states[0]["credits"]), credits + rate * 10.0), "The captured relay pays 6 credits per second during a brownout")
	expect(is_zero_approx(float(world.states[0]["total_mined"])), "Relay income is not counted as mined ore")
	expect(is_equal_approx(float(world.states[0]["total_relay"]), rate * 10.0), "Relay income is tracked on its own")
	world.selected_building = relay
	world._update_hud()
	var shown := "RELAY +%d/s" % int(rate)
	expect(world.retro_economy_label.text.contains(shown) and world.hud_text.text.contains(shown) and world.info_text.text.contains(shown), "The command bar shows the relay rate beside the ore line")
	world.ai_timer = 100.0
	world.economy_ai_timer = 100.0
	var paced := float(world.states[0]["credits"])
	world._physics_process(1.0)
	expect(is_equal_approx(float(world.states[0]["credits"]), paced + rate), "The match clock pays the relay")
	world.paused = true
	var held := float(world.states[0]["credits"])
	world._physics_process(4.0)
	expect(is_equal_approx(float(world.states[0]["credits"]), held), "A paused match does not pay the relay")
	world.paused = false
	world.battle_over = true
	world._physics_process(4.0)
	expect(is_equal_approx(float(world.states[0]["credits"]), held), "A finished match does not pay the relay")
	world.battle_over = false
	world._place_structure("relay", 0, Vector2(220, 220), 0.0)
	var extra = world.structures[world.structures.size() - 1]
	var before_cap := float(world.states[0]["credits"])
	world._tick_relay_income(10.0)
	expect(is_equal_approx(float(world.states[0]["credits"]), before_cap + rate * 10.0), "A second relay does not raise the trickle")
	extra.receive_damage(100000.0, null)
	expect(world._owns_living_relay(0), "The original relay still belongs to the player")
	_capture(world, "r_engineer", 1, relay)
	expect(relay.team == 1, "The opponent takes the relay")
	var player_credits := float(world.states[0]["credits"])
	var enemy_credits := float(world.states[1]["credits"])
	world._tick_relay_income(10.0)
	expect(is_equal_approx(float(world.states[0]["credits"]), player_credits), "Losing the relay stops the player's trickle")
	expect(is_equal_approx(float(world.states[1]["credits"]), enemy_credits + rate * 10.0), "The new owner receives the same trickle")
	relay.receive_damage(100000.0, null)
	var silent_player := float(world.states[0]["credits"])
	var silent_enemy := float(world.states[1]["credits"])
	world._tick_relay_income(10.0)
	expect(is_equal_approx(float(world.states[0]["credits"]), silent_player) and is_equal_approx(float(world.states[1]["credits"]), silent_enemy), "A destroyed relay pays nobody")
	world._update_hud()
	expect(not world.retro_economy_label.text.contains(shown), "The rate leaves the command bar with the relay")
	_compare_with_harvester()
	print("RELAY_INCOME_SMOKE: %d failures" % failed)
	quit(0 if failed == 0 else 1)

func _compare_with_harvester() -> void:
	var world = _arena()
	var field: Dictionary = world.ore_fields[0]
	for i in range(1, world.ore_fields.size()):
		world.ore_fields[i]["remaining"] = 0.0
	var ore: Vector2 = field["position"]
	# The refinery stands beside the field, so this is the short haul. A longer route earns less, and the relay still has to lose to this one.
	expect(world._place_structure("refinery", 0, ore + Vector2(90, 0)), "A refinery sits beside the one living field")
	var harvester = _unit(world, "a_harvester")
	var relay = _relay(world)
	expect(harvester != null and relay != null, "The harvester and the relay are both on the field")
	if harvester == null or relay == null:
		return
	harvester.position = ore
	harvester.state = "SEEK"
	harvester.working = true
	harvester.moving = false
	_capture(world, "a_engineer", 0, relay)
	world.states[0]["credits"] = 0.0
	world.states[0]["total_mined"] = 0.0
	world.states[0]["total_relay"] = 0.0
	world.ai_timer = 10000.0
	world.economy_ai_timer = 10000.0
	world.set_physics_process(false)
	var duration := 30.0
	var dt := 0.05
	var steps := int(duration / dt)
	for _i in steps:
		world._physics_process(dt)
		for unit in world.units.duplicate():
			if is_instance_valid(unit):
				unit._physics_process(dt)
	var mined := float(world.states[0]["total_mined"])
	var trickle := float(world.states[0]["total_relay"])
	expect(mined > 0.0, "The harvester delivers iron from the living field")
	expect(absf(trickle - world.RELAY_CREDITS_PER_SECOND * duration) < 0.05, "The relay trickle over the same window is 6 credits per second")
	expect(mined > trickle, "One harvester on a living field outruns the relay")

func _arena():
	var world = Arena.new()
	world.fog_enabled = false
	world.set_physics_process(false)
	root.add_child(world)
	return world

func _capture(world, id: String, side: int, building) -> void:
	var engineer = world._spawn_engineer(id, side, building.position + Vector2(70, 0))
	world.capture_structure(engineer, building)

func _relay(world):
	for building in world.structures:
		if is_instance_valid(building) and building.kind == "relay":
			return building
	return null

func _unit(world, id: String):
	for unit in world.units:
		if is_instance_valid(unit) and unit.unit_id == id:
			return unit
	return null
