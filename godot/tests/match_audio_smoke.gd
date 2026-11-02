extends SceneTree
## Original match cues: construction, unit ready, low power, base under attack, superweapon, faction ack.
const Arena = preload("res://scripts/economy/skirmish_arena.gd")
const Audio = preload("res://scripts/audio/match_audio.gd")
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
	var alliance := Audio.stream_for("ack_alliance").data
	var republic := Audio.stream_for("ack_republic").data
	var gia := Audio.stream_for("ack_gia").data
	expect(alliance.size() > 200 and alliance != republic and republic != gia and gia != alliance, "Each faction acknowledgement is its own sound")
	var loud := false
	for i in range(0, alliance.size(), 2):
		var sample := int(alliance[i]) | (int(alliance[i + 1]) << 8)
		if sample > 32767:
			sample -= 65536
		if absi(sample) > 1000:
			loud = true
			break
	expect(loud, "Acknowledgement waveform is not silence")
	var world = Arena.new()
	world.army_choices = ["alliance_energy", "republic"]
	world.fog_enabled = false
	root.add_child(world)
	world.set_physics_process(false)
	var audio = world.audio
	expect(audio.history.is_empty(), "Match start does not play a cue")
	var marker: int = audio.history.size()
	world._place_structure("power", 1, Vector2(1500, 400))
	expect(audio.history.size() == marker, "Enemy construction stays silent")
	world._place_structure("barracks", 0, Vector2(420, 520))
	expect(audio.history[0] == "low_power" and audio.history[1] == "construction", "First unpowered building warns, then confirms construction")
	world._place_structure("power", 0, Vector2(560, 520))
	expect(audio.history[audio.history.size() - 1] == "construction" and audio.history.count("low_power") == 1, "Restoring power does not repeat the low-power cue")
	var plant = null
	for building in world.structures:
		if building.team == 0 and building.kind == "power":
			plant = building
	plant.hp = 1.0
	plant.receive_damage(10.0, null)
	expect(audio.history[audio.history.size() - 1] == "low_power", "Losing the plant warns again")
	expect(audio.history.count("under_attack") == 1, "Base under attack plays once for that hit")
	var barracks = null
	for building in world.structures:
		if building.team == 0 and building.kind == "barracks":
			barracks = building
	barracks.receive_damage(20.0, null)
	expect(audio.history.count("under_attack") == 1, "A second hit inside the alarm window stays quiet")
	audio._left["under_attack"] = 0.0
	barracks.receive_damage(20.0, null)
	expect(audio.history.count("under_attack") == 2, "The alarm can sound again after its cooldown")
	world._place_structure("factory", 0, Vector2(700, 700))
	var before_units: int = audio.history.count("unit_ready")
	expect(world._produce_unit(0, "a_ranger"), "Ranger leaves the barracks")
	expect(audio.history.count("unit_ready") == before_units + 1, "A finished unit plays the ready cue")
	var ranger = world.units[world.units.size() - 1]
	world.selected = [ranger]
	world.issue_order(Vector2(900, 760))
	expect(audio.history[audio.history.size() - 1] == "ack_alliance", "Alliance orders use the Alliance acknowledgement")
	world._place_structure("power", 0, Vector2(860, 520))
	var commander = world.commander
	commander.award_xp(0, 3500.0)
	expect(commander.buy_power(0, "grid_surge"), "Grid Surge can be purchased")
	var warnings: int = audio.history.count("superweapon")
	expect(commander.cast(0, "grid_surge", Vector2(640, 640)), "Instant support resolves")
	expect(audio.history.count("superweapon") == warnings, "An instant power does not play the warning")
	expect(commander.buy_power(0, "orbital_pulse"), "Orbital Pulse can be purchased")
	expect(commander.cast(0, "orbital_pulse", Vector2(900, 500)), "Warned strike is ordered")
	expect(audio.history.count("superweapon") == warnings + 1, "A delayed strike plays the superweapon warning")
	print("MATCH_AUDIO_SMOKE: %d failures" % failed)
	quit(1 if failed else 0)
