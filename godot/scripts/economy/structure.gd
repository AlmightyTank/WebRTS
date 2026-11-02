extends Node2D
## Static, procedural 2.5D structures; combat targets use the same damage contract as units.
const IndustrialArt = preload("res://scripts/ui/industrial_art.gd")
signal destroyed(entity: Node2D)
var arena
var kind := ""
var team := 0
var art_style := 0
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
var art_time: float = 0.0
var door_open: float = 0.0
var exit_activity: float = 0.0
var art_working: bool = false
var _drawn_art_frame := -999
var _drawn_door_frame := -999
var _drawn_working := false
var weapon := {"type":"SMALL_ARMS", "damage":16.0, "interval":0.7, "range":165.0, "projectile_speed":620.0}

func configure(world, building_kind: String, side: int, pos: Vector2, size: Vector2) -> void:
 arena=world
 kind=building_kind
 team=side
 art_style=arena.faction_style(team) if arena.has_method("faction_style") else team
 position=pos
 footprint=size
 radius=maxf(26.0, minf(size.x,size.y)*0.43)
 max_hp=2600.0 if kind=="yard" else (1700.0 if kind=="factory" else 1350.0)
 hp=max_hp
 name=("Alliance" if team==0 else "Republic")+"_"+kind
 if kind=="beam_bastion": weapon={"type":"ENERGY","damage":75.0,"interval":1.5,"range":225.0,"projectile_speed":850.0,"grid_energy":true}
 if kind in ["sam","salvaged_aa","missile_nest"]: weapon={"type":"ROCKET","damage":90.0 if kind=="missile_nest" else 70.0,"interval":2.4,"range":300.0,"projectile_speed":400.0,"homing":true,"anti_air":true,"anti_ground":false}
 queue_redraw()

func ground_bounds() -> Rect2:
 return Rect2(position-footprint*0.5, footprint)

func notify_unit_exit() -> void:
 exit_activity=2.0

func _process(delta: float) -> void:
 if kind not in ["yard","power","barracks","refinery","factory","depot","relay","vanguard_foundry"] or arena==null: return
 if kind=="relay" and team<0: return
 if arena.paused or arena.battle_over: return
 var powered: bool = arena.power_ok(team)
 art_working=false
 if kind=="yard":
  var lanes: Dictionary = arena.states[team]["lanes"]
  for lane in ["build","defense"]:
   if not lanes[lane].is_empty() and not bool(lanes[lane].get("ready",false)): art_working=true
 if powered: art_time+=delta
 exit_activity=maxf(0.0,exit_activity-delta)
 var target := 0.0
 if kind in ["barracks","factory"]:
  target=1.0 if exit_activity>0.0 else 0.0
 elif kind=="yard" and powered:
  # Service-only ambient cycle. Never produces or spawns a unit.
  target=0.7 if fmod(art_time,18.0)>13.0 else 0.0
 door_open=move_toward(door_open,target,delta*2.5)
 # Building meshes are cached per 20 Hz frame and 16 door steps. Health, selection
 # and repair call queue_redraw themselves when those overlays change.
 var frame := int(art_time*20.0)
 var door_frame := int(round(door_open*16.0))
 if frame==_drawn_art_frame and door_frame==_drawn_door_frame and art_working==_drawn_working:
  return
 _drawn_art_frame=frame
 _drawn_door_frame=door_frame
 _drawn_working=art_working
 queue_redraw()

func _physics_process(delta: float) -> void:
 if arena.paused or arena.battle_over or hp<=0 or kind not in ["turret","beam_bastion","sam","salvaged_aa","missile_nest"]: return
 if not arena.power_ok(team) and kind!="beam_bastion": return
 timer-=delta
 if timer>0.0: return
 var victim=arena.find_target(self,float(weapon["range"]))
 if victim!=null and arena.clear_shot(position,victim.position,false,victim.air):
  var shot:=weapon.duplicate(true)
  timer=float(weapon.interval)
  if kind=="beam_bastion":
   if arena.power_ok(team): shot.damage*=1.1
   else: timer*=2.0
  if arena.get("commander")!=null: timer=arena.commander.modify_shot(self,victim,shot,timer)
  arena.spawn_projectile(self,victim,shot)

func can_hit(other) -> bool:
 return other!=null and is_instance_valid(other) and other.team!=team and other.hp>0.0 and (bool(weapon.get("anti_air",false)) if other.air else bool(weapon.get("anti_ground",true)))

func receive_damage(amount: float, _attacker) -> void:
 if hp<=0.0: return
 hp=maxf(0.0,hp-amount)
 if team==0 and amount>0.0 and arena!=null and arena.has_method("play_cue"): arena.play_cue("under_attack")
 queue_redraw()
 if hp<=0.0:
  destroyed.emit(self)
  queue_free()

func _draw() -> void:
 var size := footprint
 IndustrialArt.draw_asset(self,kind,team,0.0,NAN,0.0,{"time":art_time,"door":door_open,"working":art_working,"faction_style":art_style})
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
