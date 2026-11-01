extends "res://scripts/combat/combat_arena.gd"
## Repeatable live-input playground, without enemy AI interrupting movement tests.
func _make_obstacles() -> void:
 obstacles.assign([Rect2(900, 0, 96, 432), Rect2(900, 720, 96, 480)])
 scenery.clear()
 tree_footprints.clear()

func reset_battle() -> void:
 for unit in units:
  if is_instance_valid(unit):
   unit.queue_free()
 units.clear()
 selected.clear()
 paused = false
 battle_over = false
 for i in range(25):
  _spawn("a_sentinel", 0, Vector2(288 + (i % 5) * 60, 432 + (i / 5) * 60))
 _set_selected(units.duplicate(), false)
 result_text.anchor_left = 0.0
 result_text.anchor_right = 0.0
 result_text.offset_left = 12.0
 result_text.add_theme_font_size_override("font_size", 16)
 result_text.text = "MOVEMENT LAB — 25 tanks\nRight-click: move | Shift: queue | S: stop | R: reset"
 _update_hud()
 queue_redraw()

func _ai_decide() -> void:
 pass
