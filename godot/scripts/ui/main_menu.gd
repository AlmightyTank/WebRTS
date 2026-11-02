extends Node
## Front-end shell: gameplay stays in its own unchanged scene.
const RetroSkin = preload("res://scripts/ui/retro_skin.gd")
const SETTINGS_PATH := "user://settings.cfg"
var config := ConfigFile.new()
var game: Node
var overlay: Control
var content: VBoxContainer
var page := "home"
var status: Label
const ArmyRules = preload("res://scripts/economy/army_rules.gd")
const SkirmishMaps = preload("res://scripts/economy/skirmish_maps.gd")
const MapPreview = preload("res://scripts/ui/skirmish_map_preview.gd")
const PLAYER_COLOR := [Color("#73b9e3"), Color("#dc907a")]
const CREDIT_AMOUNTS := [5000, 10000, 20000]
var army_choices: Array = ["alliance", "republic"]
var ai_vs_ai := false
var map_id := "meridian_basin"
var starting_credits := 10000
var fog_enabled := true
var start_slots: Array = ["west", "east"]
var lobby_compact_override := -1
var lobby_lock := false
var lobby_preview: Control
var lobby_summary: Array = []
var lobby_faction: Array = []
var lobby_start: Array = []
var lobby_credits: OptionButton
var lobby_fog: CheckButton
var lobby_watch: CheckButton
var lobby_map_summary: Label
var _lobby_compact_applied := false
var _lobby_compact_known := false

func _ready() -> void:
 process_mode = Node.PROCESS_MODE_ALWAYS
 config.load(SETTINGS_PATH)
 _apply_settings()
 var layer := CanvasLayer.new()
 layer.layer = 100
 add_child(layer)
 overlay = Control.new()
 overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 layer.add_child(overlay)
 var background := ColorRect.new()
 background.color = Color("#101e24")
 background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 overlay.add_child(background)
 var margin := MarginContainer.new()
 margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 for edge in ["left", "right", "top", "bottom"]:
  margin.add_theme_constant_override("margin_" + edge, 24)
 overlay.add_child(margin)
 var scroll := ScrollContainer.new()
 margin.add_child(scroll)
 content = VBoxContainer.new()
 content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 content.add_theme_constant_override("separation", 12)
 scroll.add_child(content)
 var theme := Theme.new()
 theme.default_font_size = 18
 theme.set_color("font_color", "Label", RetroSkin.TEXT)
 overlay.theme = theme
 _show_page("home")
 get_viewport().size_changed.connect(_on_menu_resized)

func _input(event: InputEvent) -> void:
 if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F10:
  if is_instance_valid(game):
   if overlay.visible and page == "pause":
    _resume()
   else:
    get_tree().paused = true
    overlay.show()
    _show_page("pause")
   get_viewport().set_input_as_handled()
 if event.is_action_pressed("ui_cancel") and overlay.visible:
  if page == "pause":
   _resume()
  elif page != "home":
   _show_page("pause" if is_instance_valid(game) else "home")
  get_viewport().set_input_as_handled()

func _text(value: String, large: bool = false) -> Label:
 var label := Label.new()
 label.text = value
 label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 label.add_theme_font_size_override("font_size", 32 if large else 18)
 content.add_child(label)
 return label

func _button(title: String, action: Callable, enabled: bool = true) -> Button:
 var button := Button.new()
 button.text = title
 button.custom_minimum_size.y = 44
 button.disabled = not enabled
 RetroSkin.button(button)
 button.add_theme_font_size_override("font_size", 18)
 content.add_child(button)
 button.pressed.connect(action)
 return button

func _focus_if_active(control: Control) -> void:
 if is_instance_valid(control) and control.is_inside_tree() and control.is_visible_in_tree(): control.grab_focus()

func _show_page(next_page: String) -> void:
 page = next_page
 for child in content.get_children():
  content.remove_child(child)
  child.queue_free()
 _text("MERIDIAN WARFRONT", true)
 _text("TACTICAL COMMAND  /  " + page.to_upper())
 var first: Button
 match page:
  "home":
   _text("Establish your base. Secure the ore fields. Control the front.")
   first = _button("SKIRMISH", _show_page.bind("skirmish"))
   _button("CAMPAIGN — coming later", func(): pass, false)
   _button("MULTIPLAYER — coming later", func(): pass, false)
   _button("SETTINGS", _show_page.bind("settings"))
   _button("CONTROLS", _show_page.bind("controls"))
   _button("CREDITS", _show_page.bind("credits"))
   _button("QUIT", _show_page.bind("quit"))
  "skirmish":
   first = _add_skirmish_lobby()
  "pause":
   _text("OPERATIONS PAUSED", true)
   first = _button("RESUME", _resume)
   _button("SETTINGS", _show_page.bind("settings"))
   _button("CONTROLS", _show_page.bind("controls"))
   _button("RETURN TO MAIN MENU", _show_page.bind("leave"))
  "settings":
   _text("SETTINGS", true)
   var volume := HSlider.new()
   volume.min_value = 0
   volume.max_value = 100
   volume.step = 1
   volume.value = float(config.get_value("audio", "volume", 80))
   volume.custom_minimum_size.y = 44
   _text("Master volume (applies when audio is available)")
   content.add_child(volume)
   volume.value_changed.connect(_set_volume)
   var fullscreen := CheckButton.new()
   fullscreen.text = "Fullscreen"
   fullscreen.custom_minimum_size.y = 44
   fullscreen.button_pressed = bool(config.get_value("display", "fullscreen", false))
   content.add_child(fullscreen)
   fullscreen.toggled.connect(_set_fullscreen)
   status = _text("Settings are saved automatically.")
   _focus_if_active.call_deferred(volume)
  "controls":
   _text("FIELD MANUAL", true)
   _text("Select: click / drag; Shift-click toggles; double-click same type\nOrders: right click; Shift queues movement; J holds position\nControl groups: Ctrl+0–9 assign, Alt+0–9 recall\nProduction tabs: 1–4\nCamera: WASD / arrows; right or middle drag\nZoom: mouse wheel\nDeploy selected MCV: H\nTactical pause: Space\nOpen / close pause menu: F10\nCancel current command: Escape or right click\nTouch camera: drag / pinch (device validation pending)")
  "credits":
   _text("Meridian Warfront\nAn original real-time strategy project.\nBuilt with Godot Engine — godotengine.org (MIT license).\nUnits, structures and command UI use the project's procedural artwork.\nDevelopment build: gameplay, artwork and content are still evolving.")
  "leave":
   _text("Return to main menu? The current match will be lost.", true)
   first = _button("KEEP PLAYING", _resume)
   _button("END MATCH", _leave_game)
  "quit":
   _text("Exit Meridian Warfront?", true)
   first = _button("CANCEL", _show_page.bind("home"))
   _button("EXIT GAME", get_tree().quit)
 if page not in ["home", "pause", "leave", "quit"]:
  var back := _button("BACK", _show_page.bind("pause" if is_instance_valid(game) else "home"))
  if first == null and page != "settings": first = back
 if first != null: _focus_if_active.call_deferred(first)

func _lobby_is_compact() -> bool:
 if lobby_compact_override == 0: return false
 if lobby_compact_override == 1: return true
 return get_viewport().get_visible_rect().size.x < 980.0

func _on_menu_resized() -> void:
 if page != "skirmish" or lobby_compact_override != -1: return
 var compact := _lobby_is_compact()
 if _lobby_compact_known and compact == _lobby_compact_applied: return
 _show_page("skirmish")

func _add_skirmish_lobby() -> Button:
 var compact := _lobby_is_compact()
 _lobby_compact_applied = compact
 _lobby_compact_known = true
 lobby_summary.clear()
 lobby_faction.clear()
 lobby_start.clear()
 var columns: Container = VBoxContainer.new() if compact else HBoxContainer.new()
 columns.name = "LobbyColumns"
 columns.add_theme_constant_override("separation", 18)
 columns.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 content.add_child(columns)
 var map_col := _lobby_column(columns)
 _lobby_heading(map_col, "MAP")
 var preview: Control = MapPreview.new()
 preview.name = "MapPreview"
 preview.map_id = map_id
 preview.slots = start_slots
 preview.custom_minimum_size = Vector2(300, 180) if compact else Vector2(420, 250)
 preview.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 map_col.add_child(preview)
 lobby_preview = preview
 var map_picker := OptionButton.new()
 map_picker.name = "MapSelect"
 for id in SkirmishMaps.ids():
  map_picker.add_item(str(SkirmishMaps.get_map(id)["name"]))
  map_picker.set_item_metadata(map_picker.item_count - 1, id)
 _lobby_option(map_col, "Map", map_picker)
 map_picker.item_selected.connect(func(index): _on_map_picked(map_picker, index))
 lobby_map_summary = _lobby_note(map_col, str(SkirmishMaps.get_map(map_id)["summary"]))
 var credits := OptionButton.new()
 credits.name = "CreditsSelect"
 for amount in CREDIT_AMOUNTS:
  credits.add_item(_credit_label(amount))
  credits.set_item_metadata(credits.item_count - 1, amount)
 _lobby_option(map_col, "Credits", credits)
 credits.item_selected.connect(func(index): _on_credits_picked(credits, index))
 lobby_credits = credits
 lobby_fog = _lobby_check(map_col, "Fog of war", fog_enabled)
 lobby_fog.name = "FogToggle"
 lobby_fog.toggled.connect(func(enabled):
  if not lobby_lock: set_fog(enabled))
 lobby_watch = _lobby_check(map_col, "Watch only (both sides are AI)", ai_vs_ai)
 lobby_watch.toggled.connect(func(enabled):
  if not lobby_lock: ai_vs_ai = enabled)
 var players := _lobby_column(columns)
 for side in range(2):
  _add_player_card(players, side)
 var start := Button.new()
 start.name = "StartSkirmish"
 start.text = "START GAME"
 start.custom_minimum_size.y = 48
 RetroSkin.button(start, true)
 start.add_theme_font_size_override("font_size", 18)
 players.add_child(start)
 start.pressed.connect(_start_game)
 _sync_lobby()
 return start

func _lobby_column(parent: Container) -> VBoxContainer:
 var column := VBoxContainer.new()
 column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 column.add_theme_constant_override("separation", 8)
 parent.add_child(column)
 return column

func _lobby_heading(parent: Control, title: String) -> void:
 var label := Label.new()
 label.text = title
 label.add_theme_font_size_override("font_size", 13)
 label.add_theme_color_override("font_color", RetroSkin.MUTED)
 parent.add_child(label)

func _lobby_note(parent: Control, value: String) -> Label:
 var label := Label.new()
 label.text = value
 label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 parent.add_child(label)
 return label

func _lobby_option(parent: Control, caption: String, picker: OptionButton) -> void:
 var row := HBoxContainer.new()
 row.add_theme_constant_override("separation", 8)
 parent.add_child(row)
 var label := Label.new()
 label.text = caption
 label.custom_minimum_size = Vector2(84, 40)
 label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
 row.add_child(label)
 picker.custom_minimum_size.y = 40
 picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 row.add_child(picker)

func _lobby_check(parent: Control, caption: String, pressed: bool) -> CheckButton:
 var check := CheckButton.new()
 check.text = caption
 check.button_pressed = pressed
 check.custom_minimum_size.y = 36
 parent.add_child(check)
 return check

func _add_player_card(parent: Control, side: int) -> void:
 var card := PanelContainer.new()
 RetroSkin.panel(card, "screen")
 parent.add_child(card)
 var box := VBoxContainer.new()
 box.add_theme_constant_override("separation", 6)
 card.add_child(box)
 var title := HBoxContainer.new()
 title.add_theme_constant_override("separation", 8)
 box.add_child(title)
 var swatch := ColorRect.new()
 swatch.custom_minimum_size = Vector2(22, 22)
 swatch.size_flags_vertical = Control.SIZE_SHRINK_CENTER
 swatch.color = PLAYER_COLOR[side]
 title.add_child(swatch)
 var who := Label.new()
 who.text = "YOU" if side == 0 else "COMPUTER"
 who.add_theme_font_size_override("font_size", 20)
 title.add_child(who)
 var faction := OptionButton.new()
 faction.name = "Faction%d" % side
 var ids: Array = ArmyRules.CHOICES.keys()
 for id in ids:
  faction.add_item(ArmyRules.CHOICES[id].name)
  faction.set_item_metadata(faction.item_count - 1, id)
 _lobby_option(box, "Faction", faction)
 faction.item_selected.connect(func(index): _on_faction_picked(side, faction, index))
 lobby_faction.append(faction)
 var start := OptionButton.new()
 start.name = "Start%d" % side
 for slot in SkirmishMaps.STARTS:
  start.add_item(SkirmishMaps.spawn_label(slot))
  start.set_item_metadata(start.item_count - 1, slot)
 _lobby_option(box, "Start", start)
 start.item_selected.connect(func(index): _on_start_picked(side, start, index))
 lobby_start.append(start)
 var summary := _lobby_note(box, "")
 lobby_summary.append(summary)

func _on_map_picked(picker: OptionButton, index: int) -> void:
 if lobby_lock: return
 map_id = str(picker.get_item_metadata(index))
 _sync_lobby()

func _on_credits_picked(picker: OptionButton, index: int) -> void:
 if lobby_lock: return
 set_credits(int(picker.get_item_metadata(index)))

func _on_faction_picked(side: int, picker: OptionButton, index: int) -> void:
 if lobby_lock: return
 set_army(side, str(picker.get_item_metadata(index)))

func _on_start_picked(side: int, picker: OptionButton, index: int) -> void:
 if lobby_lock: return
 set_start(side, str(picker.get_item_metadata(index)))

func set_army(side: int, id: String) -> void:
 army_choices[side] = ArmyRules.valid_choice(id)
 _sync_lobby()

func set_start(side: int, slot: String) -> void:
 if slot not in SkirmishMaps.STARTS: slot = "random"
 start_slots[side] = slot
 var other: int = 1 - side
 if slot != "random" and str(start_slots[other]) == slot:
  start_slots[other] = "east" if slot == "west" else "west"
 _sync_lobby()

func _credit_label(amount: int) -> String:
 var text := str(amount)
 if text.length() <= 3: return text
 return text.substr(0, text.length() - 3) + "," + text.substr(text.length() - 3)

func set_credits(amount: int) -> void:
 starting_credits = amount if amount in CREDIT_AMOUNTS else 10000
 _sync_lobby()

func set_fog(enabled: bool) -> void:
 fog_enabled = enabled
 _sync_lobby()

func _sync_lobby() -> void:
 if lobby_lock or not is_instance_valid(lobby_preview): return
 lobby_lock = true
 lobby_preview.map_id = map_id
 lobby_preview.slots = start_slots
 lobby_preview.queue_redraw()
 if is_instance_valid(lobby_map_summary):
  lobby_map_summary.text = str(SkirmishMaps.get_map(map_id)["summary"])
 var ids: Array = ArmyRules.CHOICES.keys()
 for side in range(mini(2, lobby_faction.size())):
  var faction: OptionButton = lobby_faction[side]
  var faction_index := ids.find(army_choices[side])
  faction.select(faction_index if faction_index >= 0 else 0)
  lobby_summary[side].text = ArmyRules.CHOICES[ArmyRules.valid_choice(str(army_choices[side]))].summary
  var start: OptionButton = lobby_start[side]
  var start_index := SkirmishMaps.STARTS.find(str(start_slots[side]))
  start.select(start_index if start_index >= 0 else 2)
 if is_instance_valid(lobby_credits):
  var credit_index := CREDIT_AMOUNTS.find(starting_credits)
  lobby_credits.select(credit_index if credit_index >= 0 else 1)
 if is_instance_valid(lobby_fog): lobby_fog.button_pressed = fog_enabled
 if is_instance_valid(lobby_watch): lobby_watch.button_pressed = ai_vs_ai
 lobby_lock = false

func _start_game() -> void:
 var scene := load("res://scenes/skirmish.tscn") as PackedScene
 if scene == null:
  _text("Unable to load the battlefield.")
  return
 game = scene.instantiate()
 game.army_choices = army_choices.duplicate()
 game.ai_vs_ai = ai_vs_ai
 game.map_id = map_id
 game.starting_credits = starting_credits
 game.fog_enabled = fog_enabled
 game.start_slots = start_slots.duplicate()
 # The front-end runs while paused; the battlefield must not inherit that mode.
 game.process_mode = Node.PROCESS_MODE_PAUSABLE
 add_child(game)
 overlay.hide()
 get_tree().paused = false

func _resume() -> void:
 overlay.hide()
 get_tree().paused = false

func _leave_game() -> void:
 get_tree().paused = false
 if is_instance_valid(game):
  remove_child(game)
  game.queue_free()
 game = null
 _show_page("home")

func _set_volume(value: float) -> void:
 config.set_value("audio", "volume", value)
 _apply_settings()
 _save_settings()

func _set_fullscreen(value: bool) -> void:
 config.set_value("display", "fullscreen", value)
 _apply_settings()
 _save_settings()

func _save_settings() -> void:
 if config.save(SETTINGS_PATH) != OK:
  status.text = "Could not save settings; changes apply for this session only."

func _apply_settings() -> void:
 var volume := clampf(float(config.get_value("audio", "volume", 80)), 0, 100)
 AudioServer.set_bus_volume_db(0, linear_to_db(maxf(volume / 100.0, 0.0001)))
 AudioServer.set_bus_mute(0, volume == 0)
 if DisplayServer.get_name() != "headless":
  DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if bool(config.get_value("display", "fullscreen", false)) else DisplayServer.WINDOW_MODE_WINDOWED)
