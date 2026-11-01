extends Node2D
## Static, procedural 2.5D structures; combat targets use the same damage contract as units.
signal destroyed(entity: Node2D)
var arena
var kind := ""
var team := 0
var hp := 1600.0
var max_hp := 1600.0
var armor := "STRUCTURE"
var air := false
var radius := 56.0
var footprint := Vector2(126, 106)
var selected := false
var repairing := false
var paid_value := 0.0
var rally_point := Vector2.ZERO
var rally_custom := false
var rally_stage_id := ""
var rally_attack_move := false
var rally_spawn_index := 0
var timer := 0.0
var weapon := {"type":"SMALL_ARMS", "damage":16.0, "interval":0.7, "range":165.0, "projectile_speed":620.0}

func configure(world, building_kind: String, side: int, pos: Vector2, size: Vector2) -> void:
 arena=world
 kind=building_kind
 team=side
 position=pos
 footprint=size
 radius=maxf(26.0, minf(size.x,size.y)*0.43)
 max_hp=2600.0 if kind=="yard" else (1700.0 if kind=="factory" else 1350.0)
 hp=max_hp
 name=("Alliance" if team==0 else "Republic")+"_"+kind
 queue_redraw()

func ground_bounds() -> Rect2:
 return Rect2(position-footprint*0.5, footprint)

func _physics_process(delta: float) -> void:
 if arena.paused or arena.battle_over or hp<=0 or kind!="turret" or not arena.power_ok(team): return
 timer-=delta
 if timer>0.0: return
 var victim=arena.find_target(self,float(weapon["range"]))
 if victim!=null and arena.clear_shot(position,victim.position,false,victim.air):
  arena.spawn_projectile(self,victim,weapon)
  timer=float(weapon["interval"])

func can_hit(other) -> bool:
 return other!=null and is_instance_valid(other) and other.team!=team and other.hp>0.0 and not other.air

func receive_damage(amount: float, _attacker) -> void:
 if hp<=0.0: return
 hp=maxf(0.0,hp-amount)
 queue_redraw()
 if hp<=0.0:
  destroyed.emit(self)
  queue_free()

func _faction_colors() -> Dictionary:
 if team == 0:
  return {"main": Color("#4b9fc2"), "dark": Color("#173d52"), "accent": Color("#bfe8e7"), "signal": Color("#75e0c0")}
 if team == 1:
  return {"main": Color("#b9654d"), "dark": Color("#4d2929"), "accent": Color("#f1c28f"), "signal": Color("#f09b68")}
 return {"main": Color("#8d9188"), "dark": Color("#343b3a"), "accent": Color("#d3d8c6"), "signal": Color("#e2d276")}

func _draw_flat_shell(size: Vector2, colors: Dictionary) -> void:
 var frame := Rect2(-size * 0.5, size)
 draw_rect(Rect2(frame.position + Vector2(6, 8), frame.size), Color(0.03, 0.06, 0.07, 0.32))
 draw_rect(frame, colors["dark"])
 draw_rect(frame.grow(-5.0), colors["main"])
 draw_line(Vector2(-size.x * 0.5 + 8.0, -size.y * 0.5 + 8.0), Vector2(size.x * 0.5 - 8.0, -size.y * 0.5 + 8.0), colors["accent"], 3.0)

func _draw() -> void:
 var colors := _faction_colors()
 var main: Color = colors["main"]
 var dark: Color = colors["dark"]
 var accent: Color = colors["accent"]
 var signal_color: Color = colors["signal"]
 var size := footprint
 _draw_flat_shell(size, colors)
 match kind:
  "yard":
   draw_colored_polygon(PackedVector2Array([Vector2(-34, 13), Vector2(-22, -22), Vector2(0, -36), Vector2(22, -22), Vector2(34, 13), Vector2(0, 28)]), dark)
   draw_colored_polygon(PackedVector2Array([Vector2(-22, 10), Vector2(-13, -16), Vector2(0, -26), Vector2(13, -16), Vector2(22, 10), Vector2(0, 20)]), main)
   draw_line(Vector2(0, -25), Vector2(0, 18), accent, 3.0)
   draw_line(Vector2(-17, -3), Vector2(17, -3), accent, 3.0)
   draw_arc(Vector2(43, -48), 13, 0.0, TAU, 20, signal_color, 3.0)
   draw_line(Vector2(15, -25), Vector2(42, -47), accent, 3.0)
  "power":
   for i in range(3):
    var x := -36.0 + i * 27.0
    draw_rect(Rect2(x, -28, 18, 55), dark)
    draw_rect(Rect2(x + 4, -23, 10, 45), main)
    draw_circle(Vector2(x + 9, -28), 7.0, accent)
    draw_line(Vector2(x + 3, 27), Vector2(x + 15, 27), signal_color, 2.0)
  "refinery":
   draw_rect(Rect2(-40, -24, 34, 42), dark)
   draw_rect(Rect2(-34, -19, 22, 32), main)
   for x in [-2.0, 18.0, 34.0]:
    draw_circle(Vector2(x, -9), 11.0, dark)
    draw_circle(Vector2(x, -9), 7.0, accent)
   draw_line(Vector2(-36, 20), Vector2(40, 20), signal_color, 3.0)
  "barracks":
   draw_colored_polygon(PackedVector2Array([Vector2(-34, -3), Vector2(0, -29), Vector2(34, -3), Vector2(34, 19), Vector2(-34, 19)]), dark)
   draw_colored_polygon(PackedVector2Array([Vector2(-25, -4), Vector2(0, -22), Vector2(25, -4)]), main)
   draw_rect(Rect2(-10, 4, 20, 15), accent)
   draw_rect(Rect2(-6, 8, 12, 11), dark)
   draw_line(Vector2(-28, 0), Vector2(28, 0), signal_color, 2.0)
  "factory":
   draw_rect(Rect2(-46, -22, 92, 43), dark)
   draw_rect(Rect2(-38, -14, 76, 27), main)
   draw_rect(Rect2(-24, -8, 48, 21), Color("#162b36"))
   for x in [-35.0, -12.0, 12.0, 35.0]:
    draw_line(Vector2(x, -20), Vector2(x, 20), accent, 2.0)
   draw_line(Vector2(-32, 16), Vector2(32, 16), signal_color, 3.0)
  "depot":
   draw_colored_polygon(PackedVector2Array([Vector2(-35, -20), Vector2(26, -20), Vector2(38, -8), Vector2(30, 19), Vector2(-31, 19), Vector2(-40, 7)]), dark)
   draw_rect(Rect2(-28, -14, 57, 28), main)
   for x in [-20.0, 0.0, 20.0]:
    draw_line(Vector2(x - 8, -12), Vector2(x + 8, 12), accent, 3.0)
  "relay":
   draw_rect(Rect2(-28, -25, 56, 43), dark)
   draw_rect(Rect2(-20, -18, 40, 31), main)
   draw_line(Vector2(0, -22), Vector2(0, -69), accent, 4.0)
   draw_arc(Vector2(0, -69), 16.0, 0.0, TAU, 24, signal_color, 3.0)
   draw_circle(Vector2(0, -69), 4.0, signal_color)
  "turret":
   draw_circle(Vector2.ZERO, 25.0, dark)
   draw_circle(Vector2.ZERO, 18.0, main)
   draw_circle(Vector2.ZERO, 8.0, accent)
   draw_line(Vector2(0, 0), Vector2(36, -5), accent, 7.0)
   draw_line(Vector2(27, -5), Vector2(39, -5), signal_color, 3.0)
 if repairing:
  draw_arc(Vector2.ZERO,radius+10.0,0,TAU,28,Color("#67e7bf"),2.5)
 if selected: draw_rect(Rect2(-size*0.5-Vector2(5,5),size+Vector2(10,10)),Color("#e5e8b8"),false,2.0)
 if team==0 and kind in ["barracks","factory"] and arena!=null and arena.has_method("_active_producer"):
  var lane="infantry" if kind=="barracks" else "vehicle"
  if arena._active_producer(team,lane)==self:
   var active_color=Color("#8fe9cb") if kind=="barracks" else Color("#ffd489")
   draw_rect(Rect2(-size*0.5-Vector2(9,9),size+Vector2(18,18)),active_color,false,3.0)
   draw_string(ThemeDB.fallback_font,Vector2(-size.x*0.5,-size.y*0.5-42),"ACTIVE SPAWN",HORIZONTAL_ALIGNMENT_LEFT,-1,15,active_color)
 var ratio=hp/maxf(1.0,max_hp)
 draw_rect(Rect2(-size.x*0.5,-size.y*0.5-32,size.x,5),Color("#182a27"))
 draw_rect(Rect2(-size.x*0.5,-size.y*0.5-32,size.x*ratio,5),Color("#95df87") if ratio>0.4 else Color("#f2a56a"))
