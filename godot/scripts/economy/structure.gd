extends Node2D
## Static, procedural 2.5D structures; combat targets use the same damage contract as units.
const IndustrialArt = preload("res://scripts/ui/industrial_art.gd")
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

func _draw() -> void:
 var size := footprint
 IndustrialArt.draw_asset(self,kind,team)
 if repairing:
  draw_arc(Vector2.ZERO,radius+10.0,0,TAU,28,Color("#67e7bf"),2.5)
 if selected: draw_rect(Rect2(-size*0.5-Vector2(5,5),size+Vector2(10,10)),Color("#e5e8b8"),false,2.0)
 if team==0 and kind in ["barracks","factory"] and arena!=null and arena.has_method("_active_producer"):
  var lane="infantry" if kind=="barracks" else "vehicle"
  if arena._active_producer(team,lane)==self:
   var active_color=Color("#8fe9cb") if kind=="barracks" else Color("#ffd489")
   draw_rect(Rect2(-size*0.5-Vector2(9,9),size+Vector2(18,18)),active_color,false,3.0)
   draw_string(ThemeDB.fallback_font,Vector2(-size.x*0.5,-size.y*0.5-42),"ACTIVE SPAWN",HORIZONTAL_ALIGNMENT_LEFT,-1,15,active_color)
 var bar_y = IndustrialArt.asset_bounds(kind).position.y-8.0
 var ratio=hp/maxf(1.0,max_hp)
 draw_rect(Rect2(-size.x*0.5,bar_y,size.x,5),Color("#182a27"))
 draw_rect(Rect2(-size.x*0.5,bar_y,size.x*ratio,5),Color("#95df87") if ratio>0.4 else Color("#f2a56a"))
