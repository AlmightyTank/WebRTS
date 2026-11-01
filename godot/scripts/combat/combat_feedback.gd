extends Node2D
## Bounded, cosmetic-only combat feedback. Sight is checked again every draw.
const MAX_EFFECTS := 96
var arena
var effects: Array = []

func emit_effect(point: Vector2, kind: String, weapon: String, size: float = 18.0) -> void:
 if not arena.feedback_visible(point): return
 if effects.size() >= MAX_EFFECTS: effects.pop_front()
 effects.append({"point": point, "kind": kind, "weapon": weapon, "size": size,
  "age": 0.0, "life": 0.1 if kind == "muzzle" else (0.65 if kind == "death" else 0.28)})
 queue_redraw()

func _process(delta: float) -> void:
 if arena.paused: return
 for index in range(effects.size() - 1, -1, -1):
  effects[index].age += delta
  if effects[index].age >= effects[index].life: effects.remove_at(index)
 queue_redraw()

func _draw() -> void:
 for effect in effects:
  var point: Vector2 = effect.point
  if not arena.feedback_visible(point): continue
  var t: float = effect.age / effect.life
  var fade := 1.0 - t
  var heavy: bool = effect.weapon not in ["SMALL_ARMS", "SNIPER"]
  var color := Color("#ffbb61") if heavy else Color("#ffe7ab")
  color.a = fade
  var size: float = effect.size
  if effect.kind == "muzzle":
   draw_circle(point, (7.0 if heavy else 4.0) * fade, color)
   draw_circle(point, 2.0 * fade, Color(1, 1, 0.9, fade))
  else:
   var death: bool = effect.kind == "death"
   var reach := size * (1.8 if death else (0.8 if heavy else 0.4))
   if death:
    for puff in range(3):
     var drift := Vector2(puff - 1, -1.0) * size * t
     draw_circle(point + drift, size * (0.3 + 0.5 * t), Color(0.19, 0.21, 0.2, fade * 0.5))
   draw_arc(point, reach * sqrt(t), 0, TAU, 20, color, 2.0)
   draw_circle(point, size * (0.6 if death else 0.22) * fade, color)
   for spoke in range(8 if death else 4):
    var direction := Vector2.from_angle(spoke * TAU / (8 if death else 4) + 0.35)
    draw_line(point + direction * reach * t, point + direction * (reach * t + 5.0 * fade), color, 1.5)
