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
   _text("OFFLINE SKIRMISH", true)
   _text("One battlefield • You vs AI • Standard starting credits: 10,000\nDeploy your MCV, build a power plant and refinery, then produce an army. Eliminate the opposing base to win.\nMap, faction and difficulty selection are not yet implemented.")
   first = _button("DEPLOY TO BATTLEFIELD", _start_game)
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
   volume.grab_focus.call_deferred()
  "controls":
   _text("FIELD MANUAL", true)
   _text("Select: left click / drag selection box\nOrders: right click\nCamera: WASD / arrows; right or middle drag\nZoom: mouse wheel\nDeploy selected MCV: H\nTactical pause: Space\nOpen / close pause menu: F10\nCancel current command: Escape\nTouch camera: drag / pinch (device validation pending)")
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
 if first != null: first.grab_focus.call_deferred()

func _start_game() -> void:
 var scene := load("res://scenes/skirmish.tscn") as PackedScene
 if scene == null:
  _text("Unable to load the battlefield.")
  return
 game = scene.instantiate()
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
