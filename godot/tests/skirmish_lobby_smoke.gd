extends SceneTree
const Maps = preload("res://scripts/economy/skirmish_maps.gd")
const Rules = preload("res://scripts/economy/army_rules.gd")
var failures: Array[String] = []

func expect(ok: bool, message: String) -> void:
 if ok:
  print("PASS: " + message)
 else:
  failures.append(message)
  push_error(message)

func _initialize() -> void:
 call_deferred("run_checks")

func run_checks() -> void:
 var rolled_rng := RandomNumberGenerator.new()
 rolled_rng.seed = 7
 var rolled: Array = Maps.resolve_slots(["random", "random"], rolled_rng)
 expect(rolled[0] != rolled[1] and str(rolled[0]) in ["west", "east"] and str(rolled[1]) in ["west", "east"], "Two random deployments take opposite starts")
 expect(Maps.resolve_slots(["west", "west"])[1] == "east", "A duplicated west start leaves east for the other side")
 expect(Maps.resolve_slots(["east", "random"])[0] == "east" and Maps.resolve_slots(["east", "random"])[1] == "west", "Random fills the deployment that is still open")
 expect(str(Maps.display_slots(["random", "random"])[0]) == "random", "Both random stays unmarked until the match starts")
 var menu = load("res://scenes/main_menu.tscn").instantiate()
 root.add_child(menu)
 menu.lobby_compact_override = 0
 menu._show_page("skirmish")
 await process_frame
 expect(menu.find_child("LobbyColumns", true, false) is HBoxContainer, "Wide lobby places the map beside the players")
 expect(menu.find_child("MapSelect", true, false) != null, "Map selector is on the setup screen")
 expect(menu.find_child("MapPreview", true, false) != null, "Map preview is on the setup screen")
 expect(menu.find_child("StartSkirmish", true, false) != null, "Start Game is on the setup screen")
 var fog: CheckButton = menu.find_child("FogToggle", true, false)
 expect(fog != null and fog.button_pressed, "Fog starts on")
 menu.set_start(0, "east")
 expect(menu.start_slots[0] == "east" and menu.start_slots[1] == "west", "Taking the east start moves the computer to the west")
 menu.set_start(1, "east")
 expect(menu.start_slots[0] == "west" and menu.start_slots[1] == "east", "The computer taking east moves you back to the west")
 menu.set_army(0, "alliance_air")
 expect(menu.army_choices[0] == "alliance_air" and menu.lobby_summary[0].text == Rules.CHOICES["alliance_air"].summary, "Your faction summary follows the selected army")
 menu.set_army(1, "no-such-army")
 expect(menu.army_choices[1] == "alliance", "An unknown army falls back to the standard Alliance")
 menu.set_credits(5000)
 menu.set_fog(false)
 menu.set_army(1, "republic_artillery")
 menu.set_start(0, "east")
 menu._start_game()
 await process_frame
 var world = menu.game
 expect(world.army_choices[0] == "alliance_air" and world.army_choices[1] == "republic_artillery", "Lobby armies reach the match")
 expect(is_equal_approx(float(world.states[0].credits), 5000.0) and is_equal_approx(float(world.states[1].credits), 5000.0), "Starting credits reach both sides")
 expect(world.fog_enabled == false, "Fog choice reaches the match")
 var player = _mcv(world, 0)
 var yard = _yard(world, 1)
 expect(player != null and player.position.distance_to(Vector2(1600, 610)) < 2.0, "You deploy on the east start")
 expect(yard != null and yard.position.distance_to(Vector2(310, 620)) < 2.0, "The computer deploys on the west start")
 world.queue_free()
 await process_frame
 menu.lobby_compact_override = 1
 menu._show_page("skirmish")
 await process_frame
 expect(menu.find_child("LobbyColumns", true, false) is VBoxContainer, "Narrow lobby stacks the map above the players")
 if DisplayServer.get_name() != "headless":
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("user://skirmish_lobby_narrow.png")
 menu.queue_free()
 print("SKIRMISH_LOBBY_SMOKE: %d failures" % failures.size())
 quit(0 if failures.is_empty() else 1)

func _mcv(world, team: int):
 for unit in world.units:
  if is_instance_valid(unit) and unit.team == team and str(unit.unit_id).ends_with("mcv"):
   return unit
 return null

func _yard(world, team: int):
 for building in world.structures:
  if is_instance_valid(building) and building.team == team and building.kind == "yard":
   return building
 return null
