extends Node2D
## MCV and finite-ore harvester. All payments are credited by the arena on physical delivery.
signal destroyed(entity: Node2D)
var arena
var unit_id := ""
var team := 0
var hp := 850.0
var max_hp := 850.0
var armor := "HEAVY"
var air := false
var radius := 20.0
var selected := false
var move_speed := 66.0
var moving := false
var route := PackedVector2Array()
var route_index := 0
var destination := Vector2.ZERO
var facing := 0.0
var target = null
var weapon := {"type":"UNARMED", "range":0.0}
var cargo := 0.0
var capacity := 800.0
var working := false
var state := "IDLE"
var mine_timer := 0.0
var deposits := 0
var purchase_cost := 0.0
var resume_harvest_on_arrival := false

func configure(world, data: Dictionary, side: int, pos: Vector2, harvester: bool) -> void:
 arena=world
 unit_id=str(data.get("id",""))
 team=side
 position=pos
 hp=float(data.get("hp",850.0))
 max_hp=hp
 move_speed=float(data.get("speed",66.0))
 working=harvester
 state="SEEK" if working else "IDLE"
 name=("Ally_" if side==0 else "Enemy_")+unit_id
 queue_redraw()

func can_hit(_other) -> bool:
 return false

func order_attack(_enemy) -> void:
 pass

func order_stop() -> void:
 working=false
 state="IDLE"
 moving=false
 route.clear()

func order_move(point: Vector2, _attack_move: bool=false) -> void:
 resume_harvest_on_arrival=false
 working=false
 state="MOVE"
 _route_to(point)

func order_rally(point: Vector2) -> void:
 var automatic=unit_id in ["a_harvester","r_hauler"]
 order_move(point)
 resume_harvest_on_arrival=automatic

func set_harvest() -> void:
 resume_harvest_on_arrival=false
 working=true
 state="SEEK"
 moving=false
 route.clear()

func _route_to(point: Vector2) -> void:
 destination=arena.clamp_point(point)
 route=arena.find_route(position,destination,false)
 route_index=0
 moving=route.size()>0

func _physics_process(delta: float) -> void:
 if hp<=0.0 or arena.paused or arena.battle_over: return
 if working:
  if state=="SEEK":
   var ore=arena.find_ore(position,team)
   if ore<0:
    state="RETURN" if cargo>0.0 else "IDLE"
    moving=false
   else:
    var point: Vector2=arena.ore_fields[ore]["position"]
    if position.distance_to(point)<38.0:
     state="MINING"
     moving=false
    elif not moving or destination.distance_to(point)>35.0:
     _route_to(point)
  elif state=="MINING":
   mine_timer-=delta
   if mine_timer<=0.0:
    mine_timer=0.15
    cargo+=arena.mine_near(position,60.0,team)
    if cargo>=capacity or arena.find_ore(position,team)<0:
     state="RETURN"
     moving=false
  elif state=="RETURN":
   var refinery=arena.find_refinery(position,team)
   if refinery==null:
    state="IDLE"
    moving=false
   elif position.distance_to(refinery.position)<105.0:
    arena.deliver_ore(team,cargo)
    deposits+=1
    cargo=0.0
    state="SEEK"
    moving=false
   elif not moving or destination.distance_to(refinery.position)>15.0:
    _route_to(refinery.position)
 if moving: _step(delta)
 queue_redraw()

func _step(delta: float) -> void:
 if route_index>=route.size():
  moving=false
  if state=="MOVE":
   if resume_harvest_on_arrival: set_harvest()
   else: state="IDLE"
  return
 var waypoint: Vector2=route[route_index]
 if position.distance_to(waypoint)<12.0:
  route_index+=1
  if route_index>=route.size():
   moving=false
   if state=="MOVE":
    if resume_harvest_on_arrival: set_harvest()
    else: state="IDLE"
   return
  waypoint=route[route_index]
 var direction=(waypoint-position).normalized()
 var proposed=position+direction*minf(move_speed*delta,position.distance_to(waypoint))
 if arena.can_occupy(proposed,radius,false,self):
  position=proposed
  facing=lerp_angle(facing,direction.angle(),minf(1.0,delta*3.5))

func receive_damage(value: float, _attacker) -> void:
 if hp<=0.0: return
 hp=maxf(0.0,hp-value)
 if hp<=0.0:
  destroyed.emit(self)
  queue_free()
 queue_redraw()

func _draw() -> void:
 var base=Color("#6e9bb4") if team==0 else Color("#b08962")
 var edge=base.darkened(0.5)
 if selected: draw_arc(Vector2.ZERO,29,0,TAU,36,Color("#eef3b1"),2.2)
 draw_set_transform(Vector2.ZERO,facing)
 draw_rect(Rect2(-24,-18,48,36),edge)
 draw_rect(Rect2(-18,-20,36,40),base)
 draw_rect(Rect2(-12,-11,24,18),edge)
 if working:
  draw_rect(Rect2(-12,11,24,9),Color("#b5a27a"))
  draw_circle(Vector2(-13,-5),5,Color("#c7d2b8"))
 else:
  draw_rect(Rect2(-17,-13,34,12),Color("#d6d6c4"))
  draw_line(Vector2(-18,18),Vector2(18,18),Color("#d6d6c4"),4)
 draw_set_transform(Vector2.ZERO,0.0)
 if working and cargo>0.0:
  draw_rect(Rect2(-23,-33,46,4),Color("#1b2927"))
  draw_rect(Rect2(-23,-33,46*cargo/capacity,4),Color("#f3c276"))
 draw_rect(Rect2(-23,-41,46,4),Color("#20302f"))
 draw_rect(Rect2(-23,-41,46*hp/maxf(1.0,max_hp),4),Color("#8fe18a"))
