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
 var main=Color("#6795aa") if team==0 else Color("#ab785e")
 var top=main.lightened(0.22)
 var edge=main.darkened(0.45)
 var size=footprint
 draw_rect(Rect2(-size*0.5+Vector2(7,9),size),Color(0.05,0.08,0.07,0.28))
 draw_rect(Rect2(-size*0.5,size),edge)
 draw_rect(Rect2(-size*0.5+Vector2(4,4),size-Vector2(8,8)),main)
 draw_colored_polygon(PackedVector2Array([Vector2(-size.x/2,-size.y/2),Vector2(-size.x/2+9,-size.y/2-18),Vector2(size.x/2+9,-size.y/2-18),Vector2(size.x/2,-size.y/2)]),top)
 draw_colored_polygon(PackedVector2Array([Vector2(size.x/2,-size.y/2),Vector2(size.x/2+9,-size.y/2-18),Vector2(size.x/2+9,size.y/2-18),Vector2(size.x/2,size.y/2)]),edge)
 match kind:
  "yard":
   draw_rect(Rect2(-27,-26,54,43),edge)
   draw_rect(Rect2(-18,-34,36,26),top)
   draw_line(Vector2(15,-30),Vector2(43,-55),Color("#dee6ce"),4)
   draw_arc(Vector2(44,-56),15,0,TAU,20,Color("#dfe8e0"),3)
  "power":
   for i in range(3):
    draw_rect(Rect2(-37+i*27,-28,18,56),edge)
    draw_circle(Vector2(-28+i*27,-28),9,top)
  "refinery":
   draw_rect(Rect2(-38,-25,38,40),edge)
   draw_rect(Rect2(6,-24,37,42),top)
   draw_circle(Vector2(15,0),13,edge)
  "barracks":
   draw_rect(Rect2(-32,-18,64,36),edge)
   draw_rect(Rect2(-10,3,20,16),top)
  "factory":
   draw_rect(Rect2(-44,-22,88,44),edge)
   draw_rect(Rect2(-28,-16,57,28),Color("#1d343b"))
   for i in range(3): draw_line(Vector2(-37+i*25,-21),Vector2(-37+i*25,19),top,2)
  "turret":
   draw_circle(Vector2.ZERO,21,edge)
   draw_circle(Vector2.ZERO,14,main)
   draw_line(Vector2.ZERO,Vector2(32,-4),top,7)
 if selected: draw_rect(Rect2(-size*0.5-Vector2(5,5),size+Vector2(10,10)),Color("#e5e8b8"),false,2.0)
 var ratio=hp/maxf(1.0,max_hp)
 draw_rect(Rect2(-size.x*0.5,-size.y*0.5-32,size.x,5),Color("#182a27"))
 draw_rect(Rect2(-size.x*0.5,-size.y*0.5-32,size.x*ratio,5),Color("#95df87") if ratio>0.4 else Color("#f2a56a"))
