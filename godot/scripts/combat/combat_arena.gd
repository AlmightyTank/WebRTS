extends Node2D
## Combat Lab: standalone code-drawn top-down RTS test battlefield.
## Combat uses the committed v0.4 armor/HP/speed data. Fire profiles are explicit
## provisional v0.5 translations of the readable weapon descriptions.
const UnitScript = preload("res://scripts/combat/combat_unit.gd")
const ProjectileScript = preload("res://scripts/combat/combat_projectile.gd")
const CameraScript = preload("res://scripts/combat/combat_camera.gd")
const BALANCE = "res://data/unit_balance_v0.4.json"
const CELL := 48
const COLS := 40
const ROWS := 25
const BOARD := Rect2(0, 0, COLS * CELL, ROWS * CELL)
const ALLY := Color("#73b9e3")
const ENEMY := Color("#dc907a")
const WEAPONS := {
 "a_ranger": {"type":"SMALL_ARMS","damage":11.0,"interval":0.65,"range":145.0,"projectile_speed":660.0},
 "a_javelin": {"type":"ROCKET","damage":75.0,"interval":3.2,"range":220.0,"projectile_speed":285.0,"homing":true,"anti_air":true},
 "a_sentinel": {"type":"AP","damage":115.0,"interval":2.4,"range":205.0,"projectile_speed":450.0},
 "a_sentinel_aa": {"type":"AA","damage":80.0,"interval":2.2,"range":320.0,"projectile_speed":400.0,"homing":true,"anti_ground":false,"anti_air":true},
 "a_striker": {"type":"ROCKET","damage":70.0,"interval":1.4,"range":210.0,"projectile_speed":350.0,"homing":true,"anti_air":false},
 "r_line": {"type":"SMALL_ARMS","damage":11.0,"interval":0.65,"range":140.0,"projectile_speed":660.0},
 "r_hunter": {"type":"ROCKET","damage":80.0,"interval":3.3,"range":210.0,"projectile_speed":285.0,"homing":true,"anti_air":true},
 "r_bastion": {"type":"AP","damage":130.0,"interval":2.6,"range":200.0,"projectile_speed":450.0},
 "r_flak": {"type":"AA","damage":55.0,"interval":0.85,"range":270.0,"projectile_speed":430.0,"anti_air":true,"anti_ground":false},
 "r_siege_heli": {"type":"ROCKET","damage":92.0,"interval":1.65,"range":215.0,"projectile_speed":350.0,"homing":true},
}
const SCENARIOS := ["Combined Arms", "Infantry vs Tanks", "Air Interception", "Formation Drill"]
var registry: Dictionary = {}
var roster: Dictionary = {}
var units: Array = []
var projectiles: Array = []
var obstacles: Array[Rect2] = []
var navigation: AStarGrid2D
var camera: Camera2D
var actors: Node2D
var hud: CanvasLayer
var hud_text: Label
var info_text: Label
var result_text: Label
var selected: Array = []
var paused := false
var scenario_index := 0
var mode := "MOVE"
var formation := "LINE"
var drag_start := Vector2.ZERO
var drag_end := Vector2.ZERO
var dragging_selection := false
var touch_start := Vector2.ZERO
var touch_start_world := Vector2.ZERO
var touch_dragged := false
var ai_timer := 0.0
var hud_timer := 0.0
var battle_over := false
var shots := 0
var hits := 0
var kills := [0, 0]

func _ready() -> void:
 _load_balance()
 _make_obstacles()
 _create_navigation()
 actors = Node2D.new()
 actors.name = "UnitsAndProjectiles"
 add_child(actors)
 camera = Camera2D.new()
 camera.name = "CombatCamera"
 camera.set_script(CameraScript)
 add_child(camera)
 camera.enabled = true
 camera.call("configure", BOARD, BOARD.get_center())
 _create_hud()
 reset_battle()
 queue_redraw()

func _load_balance() -> void:
 var file := FileAccess.open(BALANCE, FileAccess.READ)
 if file == null:
  push_error("Missing unit registry: " + BALANCE)
  return
 var parsed: Variant = JSON.parse_string(file.get_as_text())
 if not (parsed is Dictionary):
  push_error("Invalid balance JSON")
  return
 registry = parsed
 for u in registry.get("standard_units", []):
  roster[str(u.get("id", ""))] = u

func _make_obstacles() -> void:
 # Rectangle obstacles deliberately create chokepoints for navigation tests.
 obstacles = [Rect2(840, 120, 92, 285), Rect2(840, 565, 92, 270), Rect2(1050, 430, 150, 100), Rect2(375, 825, 155, 95), Rect2(1430, 220, 105, 95)]

func _create_navigation() -> void:
 navigation = AStarGrid2D.new()
 navigation.region = Rect2i(0, 0, COLS, ROWS)
 navigation.cell_size = Vector2(CELL, CELL)
 navigation.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
 navigation.update()
 for y in range(ROWS):
  for x in range(COLS):
   var cell := Vector2i(x, y)
   for obstacle in obstacles:
    if obstacle.grow(17.0).has_point(cell_center(cell)):
     navigation.set_point_solid(cell)
     break

func cell_center(cell: Vector2i) -> Vector2:
 return Vector2((float(cell.x) + 0.5) * CELL, (float(cell.y) + 0.5) * CELL)

func world_cell(point: Vector2) -> Vector2i:
 return Vector2i(clampi(floori(point.x / CELL), 0, COLS - 1), clampi(floori(point.y / CELL), 0, ROWS - 1))

func clamp_point(point: Vector2) -> Vector2:
 return Vector2(clampf(point.x, 24, BOARD.size.x - 24), clampf(point.y, 24, BOARD.size.y - 24))

func can_occupy(point: Vector2, radius: float, is_air: bool, actor = null) -> bool:
 if not BOARD.grow(-radius).has_point(point):
  return false
 if is_air:
  return true
 for box in obstacles:
  if box.grow(radius).has_point(point):
   return false
 for unit in units:
  if not is_instance_valid(unit) or unit == actor or unit.hp <= 0.0 or unit.air:
   continue
  if point.distance_squared_to(unit.position) < pow(radius + unit.radius + 1.0, 2.0):
   return false
 return true

func find_route(origin: Vector2, destination: Vector2, is_air: bool) -> PackedVector2Array:
 var end := clamp_point(destination)
 if is_air:
  return PackedVector2Array([end])
 var start_cell := world_cell(origin)
 var goal_cell := world_cell(end)
 if navigation.is_point_solid(goal_cell):
  goal_cell = _nearby_open_cell(goal_cell)
 if navigation.is_point_solid(start_cell):
  start_cell = _nearby_open_cell(start_cell)
 var ids: Array[Vector2i] = navigation.get_id_path(start_cell, goal_cell)
 var result := PackedVector2Array()
 for cell in ids:
  result.append(cell_center(cell))
 if not navigation.is_point_solid(world_cell(end)) and end.distance_to(cell_center(goal_cell)) < 32.0:
  result.append(end)
 return result

func _nearby_open_cell(point: Vector2i) -> Vector2i:
 for radius in range(1, 8):
  for y in range(-radius, radius + 1):
   for x in range(-radius, radius + 1):
    var cell := point + Vector2i(x, y)
    if navigation.is_in_boundsv(cell) and not navigation.is_point_solid(cell):
     return cell
 return point

func clear_shot(from: Vector2, to: Vector2, from_air: bool, to_air: bool, hit_target = null) -> bool:
 if from_air or to_air:
  return true
 for box in obstacles:
  if hit_target != null and is_instance_valid(hit_target) and hit_target.has_method("ground_bounds") and hit_target.ground_bounds() == box:
   continue
  if _segment_hits_rect(from, to, box):
   return false
 return true

func _segment_hits_rect(start: Vector2, finish: Vector2, box: Rect2) -> bool:
 if box.has_point(start) or box.has_point(finish):
  return true
 var top_left := box.position
 var bottom_right := box.end
 var top_right := Vector2(bottom_right.x, top_left.y)
 var bottom_left := Vector2(top_left.x, bottom_right.y)
 return Geometry2D.segment_intersects_segment(start, finish, top_left, top_right) != null or Geometry2D.segment_intersects_segment(start, finish, top_right, bottom_right) != null or Geometry2D.segment_intersects_segment(start, finish, bottom_right, bottom_left) != null or Geometry2D.segment_intersects_segment(start, finish, bottom_left, top_left) != null

func armor_multiplier(kind: String, armor: String) -> float:
 return float(registry.get("weapon_armor_multipliers", {}).get(kind.to_upper(), {}).get(armor, 0.0))

func _spawn(unit_id: String, side: int, pos: Vector2):
 if not roster.has(unit_id) or not WEAPONS.has(unit_id):
  push_error("Unknown Combat Lab unit: " + unit_id)
  return null
 var data: Dictionary = roster[unit_id]
 var u: Variant = Node2D.new()
 u.set_script(UnitScript)
 actors.add_child(u)
 u.configure(self, data, side, pos, WEAPONS[unit_id], str(data.get("armor", "")) == "AIR")
 u.connect("destroyed", Callable(self, "_on_destroyed"))
 units.append(u)
 return u

func reset_battle() -> void:
 for u in units:
  if is_instance_valid(u):
   u.queue_free()
 for p in projectiles:
  if is_instance_valid(p):
   p.queue_free()
 units.clear()
 projectiles.clear()
 selected.clear()
 shots = 0
 hits = 0
 kills = [0, 0]
 battle_over = false
 paused = false
 mode = "MOVE"
 var allies: Array = []
 var enemies: Array = []
 match scenario_index:
  1:
   allies = [["a_ranger",Vector2(450,360)],["a_ranger",Vector2(490,400)],["a_javelin",Vector2(410,470)],["a_javelin",Vector2(480,500)],["a_javelin",Vector2(530,550)]]
   enemies = [["r_bastion",Vector2(1510,360)],["r_bastion",Vector2(1570,465)]]
  2:
   allies = [["a_sentinel_aa",Vector2(470,310)],["a_sentinel_aa",Vector2(480,435)],["a_javelin",Vector2(420,550)],["a_sentinel",Vector2(550,650)]]
   enemies = [["r_siege_heli",Vector2(1425,290)],["r_siege_heli",Vector2(1490,410)],["r_bastion",Vector2(1510,660)]]
  3:
   allies = [["a_ranger",Vector2(370,320)],["a_ranger",Vector2(405,385)],["a_javelin",Vector2(420,450)],["a_sentinel",Vector2(450,555)],["a_sentinel",Vector2(515,630)],["a_sentinel_aa",Vector2(380,720)]]
   enemies = [["r_line",Vector2(1620,340)],["r_hunter",Vector2(1600,500)],["r_bastion",Vector2(1620,630)]]
  _:
   allies = [["a_ranger",Vector2(375,300)],["a_ranger",Vector2(410,345)],["a_javelin",Vector2(355,410)],["a_sentinel",Vector2(395,535)],["a_sentinel",Vector2(480,590)],["a_sentinel_aa",Vector2(460,705)],["a_striker",Vector2(340,790)]]
   enemies = [["r_line",Vector2(1630,310)],["r_line",Vector2(1600,390)],["r_hunter",Vector2(1660,465)],["r_bastion",Vector2(1590,555)],["r_bastion",Vector2(1690,640)],["r_flak",Vector2(1590,720)],["r_siege_heli",Vector2(1680,815)]]
 for item in allies:
  _spawn(item[0], 0, item[1])
 for item in enemies:
  _spawn(item[0], 1, item[1])
 ai_timer = 0.8
 hud_timer = 0.0
 if is_instance_valid(result_text):
  result_text.text = ""
 _update_hud()
 queue_redraw()

func spawn_projectile(source, target, weapon: Dictionary) -> void:
 if not is_instance_valid(target):
  return
 var p: Variant = Node2D.new()
 p.set_script(ProjectileScript)
 actors.add_child(p)
 p.configure(self, source.position, source, target, weapon)
 projectiles.append(p)
 shots += 1

func register_hit(_source, _victim, _damage: float) -> void:
 hits += 1

func _on_destroyed(unit) -> void:
 kills[1 - unit.team] += 1
 selected.erase(unit)
 # Keep deleted nodes out of future targeting/collision decisions.
 units.erase(unit)
 if not battle_over:
  var ally_count := 0
  var enemy_count := 0
  for u in units:
   if not is_instance_valid(u) or u.hp <= 0.0:
    continue
   if u.team == 0: ally_count += 1
   else: enemy_count += 1
  if ally_count == 0 or enemy_count == 0:
   battle_over = true
   if is_instance_valid(result_text):
    result_text.text = "ALLIANCE VICTORY" if enemy_count == 0 else "REPUBLIC VICTORY"

func find_target(seeker, search_radius: float):
 var best
 var best_score := INF
 for u in units:
  if not is_instance_valid(u) or u.hp <= 0.0 or not seeker.can_hit(u):
   continue
  var distance: float = seeker.position.distance_to(u.position)
  if distance > search_radius:
   continue
  var score := distance
  # Anti-air intercepts aircraft first; rockets respond to armor first.
  if seeker.weapon.get("type", "") == "AA" and u.air:
   score *= 0.5
  elif seeker.weapon.get("type", "") == "ROCKET" and u.armor == "HEAVY":
   score *= 0.7
  elif seeker.weapon.get("type", "") == "SMALL_ARMS" and u.armor == "PERSONNEL":
   score *= 0.75
  if score < best_score:
   best_score = score
   best = u
 return best

func _ai_decide() -> void:
 if battle_over:
  return
 for unit in units:
  if not is_instance_valid(unit) or unit.hp <= 0.0 or unit.team != 1:
   continue
  var enemy = find_target(unit, 1400.0)
  if enemy == null:
   continue
  if unit.target == null or not is_instance_valid(unit.target) or (unit.position.distance_to(enemy.position) + 100.0 < unit.position.distance_to(unit.target.position)):
   unit.order_attack(enemy)

func formation_targets(origin: Vector2, count: int, toward: Vector2, shape: String) -> Array[Vector2]:
 var result: Array[Vector2] = []
 var forward := (toward-origin).normalized()
 if forward == Vector2.ZERO:
  forward = Vector2.RIGHT
 var right := Vector2(-forward.y,forward.x)
 for i in range(count):
  var point: Vector2
  if shape == "WEDGE":
   var rank := (i+1)/2
   var wing := -1.0 if i % 2 == 0 else 1.0
   point = toward - forward * 35.0 * rank + right * 43.0 * rank * wing
  else:
   var column := i % 5
   var row := i / 5
   point = toward + right * (float(column) - float(mini(count,5)-1)*0.5)*43.0 - forward * float(row)*48.0
  var cell := world_cell(clamp_point(point))
  if navigation.is_point_solid(cell):
   cell = _nearby_open_cell(cell)
  result.append(cell_center(cell))
 return result

func issue_order(point: Vector2, attack_move: bool = false) -> void:
 var clicked = _hit_unit(point, -1)
 if clicked != null and clicked.team == 1:
  for u in selected:
   if is_instance_valid(u) and u.can_hit(clicked):
    u.order_attack(clicked)
  return
 if selected.is_empty():
  return
 var targets := formation_targets(_selection_midpoint(), selected.size(), point, formation)
 for i in range(selected.size()):
  var u = selected[i]
  if is_instance_valid(u):
   u.order_move(targets[i], attack_move)

func _screen_to_world(screen_point: Vector2) -> Vector2:
 # InputEventScreenTouch coordinates are in viewport space, unlike mouse-world.
 return camera.get_canvas_transform().affine_inverse() * screen_point

func _selection_midpoint() -> Vector2:
 var sum := Vector2.ZERO
 for u in selected: sum += u.position
 return sum / float(maxi(1, selected.size()))

func _hit_unit(point: Vector2, side: int = -1):
 var best
 var best_d := INF
 for u in units:
  if not is_instance_valid(u) or u.hp <= 0.0 or (side != -1 and u.team != side):
   continue
  var d := point.distance_to(u.position)
  if d < u.radius + 10.0 and d < best_d:
   best_d = d
   best = u
 return best

func _set_selected(items: Array, additive: bool = false) -> void:
 if not additive:
  for u in selected:
   if is_instance_valid(u): u.selected = false
  selected.clear()
 for u in items:
  if is_instance_valid(u) and u.team == 0 and not selected.has(u):
   selected.append(u)
   u.selected = true
   u.queue_redraw()
 _update_hud()

func _unhandled_input(event: InputEvent) -> void:
 if event is InputEventMouseButton:
  if event.button_index == MOUSE_BUTTON_LEFT:
   if event.pressed:
    drag_start = get_global_mouse_position()
    drag_end = drag_start
    dragging_selection = true
   elif dragging_selection:
    dragging_selection = false
    var point: Vector2 = get_global_mouse_position()
    if mode == "ATTACK_MOVE" or mode == "COMMAND":
     issue_order(point, mode == "ATTACK_MOVE")
     mode = "MOVE"
    elif drag_start.distance_to(point) > 15.0:
     var selection := Rect2(drag_start,point-drag_start).abs()
     var picked: Array = []
     for u in units:
      if is_instance_valid(u) and u.team == 0 and selection.has_point(u.position): picked.append(u)
     _set_selected(picked, Input.is_key_pressed(KEY_SHIFT))
    else:
     var picked = _hit_unit(point,0)
     if picked != null:
      _set_selected([picked],Input.is_key_pressed(KEY_SHIFT))
     else:
      _set_selected([])
    queue_redraw()
  elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
   issue_order(get_global_mouse_position(),Input.is_key_pressed(KEY_A))
 elif event is InputEventMouseMotion and dragging_selection:
  drag_end = get_global_mouse_position()
  queue_redraw()
 elif event is InputEventScreenTouch:
  if event.pressed and event.index == 0:
   touch_start = event.position
   touch_start_world = _screen_to_world(event.position)
   touch_dragged = false
  elif not event.pressed and event.index == 0 and not touch_dragged:
   var point := _screen_to_world(event.position)
   if mode == "ATTACK_MOVE" or mode == "COMMAND":
    issue_order(point, mode == "ATTACK_MOVE")
    mode = "MOVE"
   else:
    var unit = _hit_unit(point, 0)
    if unit != null: _set_selected([unit])
    elif not selected.is_empty(): issue_order(point)
 elif event is InputEventScreenDrag:
  if event.index == 0 and event.position.distance_to(touch_start) > 14.0:
   touch_dragged = true
 elif event is InputEventKey and event.pressed and not event.echo:
  match event.keycode:
   KEY_A: mode = "ATTACK_MOVE"
   KEY_M: mode = "COMMAND"
   KEY_S:
    for u in selected:
     if is_instance_valid(u): u.order_stop()
   KEY_F: formation = "WEDGE" if formation == "LINE" else "LINE"
   KEY_R: reset_battle()
   KEY_SPACE: paused = not paused
   KEY_ESCAPE: mode = "MOVE"
   KEY_1, KEY_2, KEY_3, KEY_4:
    scenario_index = event.keycode - KEY_1
    reset_battle()
  _update_hud()

func _physics_process(delta: float) -> void:
 if paused or battle_over:
  return
 ai_timer -= delta
 if ai_timer <= 0.0:
  ai_timer = 1.1
  _ai_decide()
 hud_timer -= delta
 if hud_timer <= 0.0:
  hud_timer = 0.2
  _update_hud()
 # Drop freed projectile references periodically.
 if projectiles.size() > 40:
  projectiles = projectiles.filter(func(p): return is_instance_valid(p))

func _create_hud() -> void:
 hud = CanvasLayer.new()
 add_child(hud)
 var root := Control.new()
 root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 root.mouse_filter = Control.MOUSE_FILTER_IGNORE
 hud.add_child(root)
 var top := PanelContainer.new()
 top.position = Vector2(12,12)
 top.custom_minimum_size = Vector2(690,82)
 root.add_child(top)
 var v := VBoxContainer.new()
 top.add_child(v)
 var title := Label.new()
 title.text = "MERIDIAN WARFRONT   /   COMBAT LAB v0.6"
 title.add_theme_font_size_override("font_size",17)
 v.add_child(title)
 hud_text = Label.new()
 v.add_child(hud_text)
 info_text = Label.new()
 v.add_child(info_text)
 var bottom := PanelContainer.new()
 bottom.anchor_top = 1.0
 bottom.anchor_bottom = 1.0
 bottom.offset_left = 12.0
 bottom.offset_top = -74.0
 bottom.offset_bottom = -12.0
 root.add_child(bottom)
 var buttons := HBoxContainer.new()
 bottom.add_child(buttons)
 for entry in [["SELECT_ALL","Select All"],["MOVE","Move"],["ATTACK_MOVE","Attack-Move"],["STOP","Stop"],["FORMATION","Line / Wedge"],["PAUSE","Pause"],["RESET","Reset"]]:
  var button := Button.new()
  button.text = entry[1]
  button.custom_minimum_size = Vector2(92,43)
  button.pressed.connect(_on_toolbar.bind(entry[0]))
  buttons.add_child(button)
 var side := PanelContainer.new()
 side.anchor_left = 1.0
 side.anchor_right = 1.0
 side.offset_left = -235.0
 side.offset_right = -12.0
 side.offset_top = 12.0
 root.add_child(side)
 var scenarios := VBoxContainer.new()
 side.add_child(scenarios)
 var header := Label.new()
 header.text = "TEST SCENARIOS"
 scenarios.add_child(header)
 for i in range(SCENARIOS.size()):
  var button := Button.new()
  button.text = "%d  %s" % [i+1, SCENARIOS[i]]
  button.pressed.connect(_choose_scenario.bind(i))
  scenarios.add_child(button)
 result_text = Label.new()
 result_text.anchor_left = 0.5
 result_text.anchor_right = 0.5
 result_text.offset_left = -110.0
 result_text.offset_top = 105.0
 result_text.add_theme_font_size_override("font_size",22)
 root.add_child(result_text)

func _choose_scenario(index: int) -> void:
 scenario_index = index
 reset_battle()

func _on_toolbar(action: String) -> void:
 match action:
  "SELECT_ALL":
   var army: Array = []
   for u in units:
    if is_instance_valid(u) and u.team == 0: army.append(u)
   _set_selected(army)
  "MOVE": mode = "COMMAND"
  "ATTACK_MOVE": mode = "ATTACK_MOVE"
  "STOP":
   for u in selected:
    if is_instance_valid(u): u.order_stop()
  "FORMATION": formation = "WEDGE" if formation == "LINE" else "LINE"
  "PAUSE": paused = not paused
  "RESET": reset_battle()
 _update_hud()

func _update_hud() -> void:
 if not is_instance_valid(hud_text): return
 var blue := 0
 var red := 0
 for u in units:
  if not is_instance_valid(u) or u.hp <= 0.0: continue
  if u.team == 0: blue += 1
  else: red += 1
 hud_text.text = "ALLIANCE %d   |   REPUBLIC %d   |   HITS %d/%d   |   KILLS %d:%d" % [blue,red,hits,shots,kills[0],kills[1]]
 info_text.text = "%s | Selected %d | %s | %s" % [SCENARIOS[scenario_index],selected.size(),formation,"PAUSED" if paused else "Mode: " + mode]

func _draw() -> void:
 draw_rect(BOARD,Color("#344d3b"))
 for x in range(COLS + 1):
  draw_line(Vector2(x*CELL,0),Vector2(x*CELL,BOARD.size.y),Color(0.65,0.75,0.57,0.10),1.0)
 for y in range(ROWS + 1):
  draw_line(Vector2(0,y*CELL),Vector2(BOARD.size.x,y*CELL),Color(0.65,0.75,0.57,0.10),1.0)
 draw_rect(Rect2(210,110,150,120),Color("#4a6048"))
 draw_rect(Rect2(1510,940,170,120),Color("#485c43"))
 draw_line(Vector2(80,960),Vector2(1700,225),Color("#a29977"),21.0)
 draw_line(Vector2(80,960),Vector2(1700,225),Color("#c8b795"),1.5)
 for box in obstacles:
  draw_rect(box.grow(5),Color(0,0,0,0.18))
  draw_rect(box,Color("#6b716b"))
  draw_rect(Rect2(box.position+Vector2(8,8),box.size-Vector2(16,16)),Color("#818880"))
  draw_line(box.position+Vector2(5,5),box.position+Vector2(box.size.x-5,5),Color("#b0b7a6"),3)
 if dragging_selection:
  var area := Rect2(drag_start,drag_end-drag_start).abs()
  draw_rect(area,Color(0.45,0.83,1,0.12),true)
  draw_rect(area,Color("#8fdaf7"),false,2.0)
