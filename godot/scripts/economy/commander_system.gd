extends Node2D
## Match-local authority for research, promotions, telegraphed support and interception.
const Rules = preload("res://scripts/economy/army_rules.gd")
const RetroSkin = preload("res://scripts/ui/retro_skin.gd")
const RESEARCH := {
 "beam_capacitors":{"name":"Beam Capacitors","army":"alliance_energy","site":"depot","cost":1400.0,"time":35.0,"demand":25},
 "grid_stabilizers":{"name":"Grid Stabilizers","army":"alliance_energy","site":"depot","cost":1200.0,"time":30.0,"demand":15},
 "autoloaders":{"name":"Autoloaders","army":"republic_armor","site":"vanguard_foundry","cost":1600.0,"time":40.0,"demand":0},
 "veteran_crews":{"name":"Veteran Crews","army":"republic_armor","site":"vanguard_foundry","cost":1200.0,"time":30.0,"demand":0},
 "guidance_van":{"name":"Guidance Van Targeting","army":"gia_missile","site":"depot","cost":1100.0,"time":30.0,"demand":10},
 "rapid_reload":{"name":"Rapid Reload","army":"gia_missile","site":"depot","cost":1500.0,"time":40.0,"demand":10},
 "saturation_payload":{"name":"Silo Saturation Payload","army":"gia_missile","site":"silo","cost":2000.0,"time":50.0,"demand":10}
}
const POWERS := {
 "grid_surge":{"name":"Grid Surge","army":"alliance_energy","rank":1,"cooldown":75.0,"radius":200.0,"delay":0.0},
 "target_lattice":{"name":"Target Lattice","army":"alliance_energy","rank":3,"cooldown":100.0,"radius":220.0,"delay":0.0},
 "orbital_pulse":{"name":"Orbital Pulse","army":"alliance_energy","rank":5,"cooldown":150.0,"radius":100.0,"delay":3.0},
 "field_repairs":{"name":"Field Repairs","army":"republic_armor","rank":1,"cooldown":90.0,"radius":180.0,"delay":0.0},
 "armor_reserve":{"name":"Armor Reserve","army":"republic_armor","rank":3,"cooldown":150.0,"radius":110.0,"delay":3.0},
 "breakthrough_order":{"name":"Breakthrough Order","army":"republic_armor","rank":5,"cooldown":150.0,"radius":200.0,"delay":0.0},
 "rocket_recon":{"name":"Rocket Recon Beacon","army":"gia_missile","rank":1,"cooldown":70.0,"radius":200.0,"delay":1.5},
 "harassing_salvo":{"name":"Harassing Salvo","army":"gia_missile","rank":3,"cooldown":100.0,"radius":125.0,"delay":3.0},
 "saturation_strike":{"name":"Saturation Strike","army":"gia_missile","rank":5,"cooldown":150.0,"radius":210.0,"delay":5.0}
}
const THRESHOLDS := [0.0,400.0,1000.0,2000.0,3500.0]
var world
var teams: Array = []
var events: Array = []
var reveals: Array = []
var buffs: Array = []
var interception: Dictionary = {}
var pending_power := ""
var research_buttons: Dictionary = {}
var power_buttons: Dictionary = {}
var rank_label: Label
var silo_button: Button

func reset(arena) -> void:
 world=arena
 teams=[]
 for side in range(2): teams.append({"xp":0.0,"rank":1,"points":1,"powers":{},"research":{},"job":{},"cooldowns":{},"silo":240.0})
 events.clear()
 reveals.clear()
 buffs.clear()
 interception.clear()
 pending_power=""
 z_index=95 # Warning circles are visible to both teams, even through shroud.
 queue_redraw()

func rank(side: int) -> int:
 return int(teams[side].rank)

func award_xp(side: int, amount: float) -> void:
 if side<0 or side>1 or amount<=0: return
 var state: Dictionary=teams[side]
 state.xp+=amount
 while state.rank<5 and state.xp>=THRESHOLDS[state.rank]:
  state.rank+=1
  state.points+=3 if state.rank==5 else 1

func has_research(side: int, id: String) -> bool:
 return teams.size()==2 and teams[side].research.has(id)

func research_ids(side: int) -> Array:
 return RESEARCH.keys().filter(func(id): return RESEARCH[id].army==world.army_choices[side])

func power_ids(side: int) -> Array:
 return POWERS.keys().filter(func(id): return POWERS[id].army==world.army_choices[side])

func start_research(side: int, id: String) -> bool:
 if side<0 or side>1 or world.paused or world.battle_over or not id in research_ids(side): return false
 if has_research(side,id) or not teams[side].job.is_empty() or not world.has_structure(side,RESEARCH[id].site): return false
 teams[side].job={"id":id,"paid":0.0}
 return true

func cancel_research(side: int) -> bool:
 var job: Dictionary=teams[side].job
 if job.is_empty(): return false
 world.states[side].credits+=job.paid
 world.states[side].total_spent-=job.paid
 world.states[side].total_refunded+=job.paid
 teams[side].job={}
 return true

func extra_demand(side: int) -> int:
 var result:=0
 if teams.size()!=2: return result
 for id in teams[side].research: result+=int(RESEARCH[id].demand)
 return result

func buy_power(side: int, id: String) -> bool:
 if side<0 or side>1 or world.paused or world.battle_over or not id in power_ids(side): return false
 var s: Dictionary=teams[side]
 var level:=int(s.powers.get(id,0))
 if rank(side)<int(POWERS[id].rank) or s.points<1 or level>=3: return false
 s.points-=1
 s.powers[id]=level+1
 return true

func sees(side: int, point: Vector2) -> bool:
 return not world.fog_enabled or world.fog==null or world.fog.sees(side,point)

func legal_site(side: int, point: Vector2) -> bool:
 return world.BOARD.grow(-24.0).has_point(point) and sees(side,point) and world.can_occupy(point,20.0,false)

func cast(side: int, id: String, point: Vector2) -> bool:
 if side<0 or side>1 or world.paused or world.battle_over or not POWERS.has(id) or not id in power_ids(side): return false
 var s: Dictionary=teams[side]
 var level:=int(s.powers.get(id,0))
 if level==0 or float(s.cooldowns.get(id,0.0))>0.0 or not world.BOARD.has_point(point): return false
 # Recon can scout unknown terrain; damaging/support powers require shared sight.
 if id not in ["rocket_recon","target_lattice"] and not sees(side,point): return false
 if id=="grid_surge" and not world.power_ok(side): return false
 if id=="armor_reserve" and (not legal_site(side,point) or living_count(side)+2+level>80): return false
 s.cooldowns[id]=float(POWERS[id].cooldown)
 var event={"id":id,"side":side,"point":point,"radius":float(POWERS[id].radius),"remaining":float(POWERS[id].delay),"level":level}
 if event.remaining>0.0: events.append(event)
 else: resolve(event)
 pending_power=""
 queue_redraw()
 return true

func living_count(side: int) -> int:
 var count:=0
 for unit in world.units:
  if is_instance_valid(unit) and unit.hp>0 and unit.team==side: count+=1
 return count

func launch_silo(side: int, point: Vector2) -> bool:
 if side<0 or side>1 or world.paused or world.battle_over or not world.BOARD.has_point(point): return false
 if not world.has_structure(side,"silo") or not world.power_ok(side) or teams[side].silo>0.0 or not sees(side,point): return false
 teams[side].silo=240.0
 events.append({"id":"silo","side":side,"point":point,"radius":230.0 if has_research(side,"saturation_payload") else 100.0,"remaining":7.0,"level":1,"wide":has_research(side,"saturation_payload")})
 queue_redraw()
 return true

func resolve(event: Dictionary) -> void:
 var id: String=event.id
 var side: int=event.side
 var point: Vector2=event.point
 var scale:=1.0+0.25*(int(event.level)-1)
 if id in ["target_lattice","rocket_recon"]:
  reveals.append({"side":side,"point":point,"radius":event.radius,"remaining":18.0*scale,"mark":id=="target_lattice"})
  world._refresh_fog()
 elif id in ["grid_surge","breakthrough_order"]:
  buffs.append({"id":id,"side":side,"point":point,"radius":event.radius,"remaining":12.0*scale})
 elif id=="field_repairs":
  for unit in world.units:
   if is_instance_valid(unit) and unit.team==side and unit.hp>0 and not unit.air and unit.armor!="PERSONNEL" and unit.position.distance_to(point)<=event.radius:
    unit.hp=minf(unit.max_hp,unit.hp+unit.max_hp*0.25*scale)
    unit.queue_redraw()
 elif id=="armor_reserve":
  # Recheck occupancy and vision at arrival. A blocked/lost landing zone cancels delivery.
  if not legal_site(side,point): return
  for i in range(2+int(event.level)):
   if living_count(side)>=80: break
   var site: Vector2=world._find_open_position(point,18.0)
   if site!=Vector2.ZERO and site.distance_to(point)<=event.radius and sees(side,site):
    var unit=world._spawn("r_jugger",side,site)
    world.show_combat_feedback(site,"impact","AP",18.0)
    unit.order_move(site+Vector2(0,72 if side==0 else -72))
 else:
  var kind: String="ENERGY" if id=="orbital_pulse" else "ROCKET"
  var damage: float={"orbital_pulse":260.0,"harassing_salvo":100.0,"saturation_strike":190.0,"silo":380.0 if bool(event.get("wide",false)) else 900.0}.get(id,0.0)*scale
  # Missile support is finite and interceptable. One ready lattice reduces one local blast.
  if kind=="ROCKET" and intercept_area(side,point): damage*=0.65
  for victim in world.projectile_targets().duplicate():
   if not is_instance_valid(victim) or victim.team==side or victim.team<0 or victim.hp<=0 or victim.air or victim.position.distance_to(point)>event.radius: continue
   var amount: float=damage*world.armor_multiplier(kind,victim.armor)
   victim.receive_damage(amount,null)
   world.register_hit(null,victim,amount)
   if victim.hp<=0: award_xp(side,100.0)
  world.show_combat_feedback(point,"death",kind,event.radius*0.35)

func buff_at(side: int, id: String, point: Vector2) -> bool:
 for effect in buffs:
  if effect.side==side and effect.id==id and point.distance_to(effect.point)<=effect.radius: return true
 return false

func marked(enemy_side: int, point: Vector2) -> bool:
 for area in reveals:
  if area.side!=enemy_side and area.mark and point.distance_to(area.point)<=area.radius: return true
 return false

func modify_shot(source, enemy, shot: Dictionary, interval: float) -> float:
 var side: int=source.team
 if enemy.air and shot.has("air_damage"): shot.damage=shot.air_damage*(1.1 if world.power_ok(side) else 1.0)
 if bool(shot.get("grid_energy",false)):
  if has_research(side,"beam_capacitors"): shot.damage*=1.15
  if not world.power_ok(side) and has_research(side,"grid_stabilizers"): interval*=0.75 # 2x becomes 1.5x; still power-dependent.
  if world.power_ok(side) and buff_at(side,"grid_surge",source.position): interval*=0.75
 if source.get("unit_id") in Rules.STEEL_TANKS and has_research(side,"autoloaders"): interval*=0.85
 if source.get("unit_id") in Rules.SIGNATURE_MISSILES:
  # Starting .9 bonus and researched reload are clamped to .75 of base.
  if has_research(side,"rapid_reload"): interval*=0.75/0.9
 if marked(enemy.team,enemy.position): shot.damage*=1.1
 if source.get("unit_xp")!=null and source.unit_xp>=100.0: shot.damage*=1.1
 return interval

func weapon_range(unit, enemy) -> float:
 var result:=float(unit.weapon.get("range",0.0))
 if not enemy.air: result=float(unit.weapon.get("ground_range",result))
 if unit.unit_id in Rules.SIGNATURE_MISSILES and has_research(unit.team,"guidance_van"): result+=30.0
 return result

func prepare_unit(unit) -> void:
 if unit.unit_id in Rules.STEEL_TANKS and has_research(unit.team,"veteran_crews"): unit.unit_xp=100.0

func interception_ready(unit) -> bool:
 return unit.unit_id=="a_lattice" and world.power_ok(unit.team) and float(interception.get(unit.get_instance_id(),0.0))<=0.0

func intercept_area(side: int, point: Vector2) -> bool:
 for unit in world.units:
  if is_instance_valid(unit) and unit.hp>0 and unit.team!=side and unit.team>=0 and interception_ready(unit) and unit.position.distance_to(point)<=160.0:
   interception[unit.get_instance_id()]=3.5
   world.show_combat_feedback(unit.position,"impact","ENERGY",12.0)
   return true
 return false

func tick(delta: float) -> void:
 if world.paused or world.battle_over: return
 for key in interception.keys():
  interception[key]-=delta
  if interception[key]<=0: interception.erase(key)
 for unit in world.units:
  if not is_instance_valid(unit) or unit.hp<=0 or not interception_ready(unit): continue
  for projectile in world.projectiles:
   if not is_instance_valid(projectile) or projectile.is_queued_for_deletion() or projectile.owner_team==unit.team or projectile.weapon_kind not in ["ROCKET","MISSILE"] or unit.position.distance_to(projectile.position)>160: continue
   interception[unit.get_instance_id()]=3.5
   world.show_combat_feedback(projectile.position,"impact","ENERGY",12.0)
   projectile.queue_free()
   break
 for side in range(2):
  var state: Dictionary=teams[side]
  for id in state.cooldowns: state.cooldowns[id]=maxf(0.0,state.cooldowns[id]-delta)
  # Strategic charge exists only while a powered, living silo exists.
  if world.has_structure(side,"silo") and world.power_ok(side): state.silo=maxf(0.0,state.silo-delta)
  elif not world.has_structure(side,"silo"): state.silo=240.0
  var job: Dictionary=state.job
  if not job.is_empty():
   var data: Dictionary=RESEARCH[job.id]
   if world.has_structure(side,data.site):
    var payment:=minf(float(world.states[side].credits),minf(data.cost-job.paid,data.cost/data.time*delta*(1.0 if world.power_ok(side) else 0.5)))
    payment=maxf(0.0,payment)
    world.states[side].credits-=payment
    world.states[side].total_spent+=payment
    job.paid+=payment
    if job.paid>=data.cost-0.001:
     state.research[job.id]=true
     state.job={}
     world._calculate_power(side)
 for list in [reveals,buffs]:
  for i in range(list.size()-1,-1,-1):
   list[i].remaining-=delta
   if list[i].remaining<=0: list.remove_at(i)
 for i in range(events.size()-1,-1,-1):
  events[i].remaining-=delta
  if events[i].remaining<=0:
   var event: Dictionary=events[i]
   events.remove_at(i)
   resolve(event)
 refresh_ui()
 queue_redraw()

func ai_tick() -> void:
 for id in research_ids(1):
  if world.states[1].credits>2500 and start_research(1,id): break
 for id in power_ids(1):
  if not teams[1].powers.has(id): buy_power(1,id)
 if rank(1)==5:
  for id in power_ids(1):
   if int(teams[1].powers.get(id,0))<3: buy_power(1,id)
 for id in power_ids(1):
  var point:=Vector2(-1,-1)
  if id in ["target_lattice","rocket_recon"]:
   for unit in world.units:
    if is_instance_valid(unit) and unit.team==1 and unit.moving: point=unit.destination; break
  elif id in ["grid_surge","field_repairs","armor_reserve","breakthrough_order"]:
   for unit in world.units:
    if is_instance_valid(unit) and unit.team==1 and not Rules.economic(unit.unit_id):
     point=world._find_open_position(unit.position+Vector2(0,80),20.0) if id=="armor_reserve" else unit.position
     break
  else:
   for enemy in world.projectile_targets():
    if is_instance_valid(enemy) and enemy.team==0 and sees(1,enemy.position): point=enemy.position; break
  if point.x>=0: cast(1,id,point)
 if world.has_structure(1,"silo"):
  for enemy in world.projectile_targets():
   if is_instance_valid(enemy) and enemy.team==0 and sees(1,enemy.position):
    launch_silo(1,enemy.position)
    break

func build_ui(column: VBoxContainer) -> void:
 rank_label=Label.new()
 column.add_child(rank_label)
 rank_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 for id in research_ids(0):
  var button:=Button.new()
  button.custom_minimum_size.y=44
  button.pressed.connect(func(): start_research(0,id); refresh_ui())
  column.add_child(button)
  RetroSkin.button(button,false,true)
  research_buttons[id]=button
 var cancel:=Button.new()
 cancel.text="CANCEL RESEARCH / REFUND"
 RetroSkin.button(cancel,false,true)
 cancel.pressed.connect(func(): cancel_research(0); refresh_ui())
 column.add_child(cancel)
 for id in power_ids(0):
  var row:=HBoxContainer.new()
  column.add_child(row)
  var buy:=Button.new()
  buy.text="+ GP"
  buy.custom_minimum_size=Vector2(50,44)
  buy.pressed.connect(func(): buy_power(0,id); refresh_ui())
  row.add_child(buy)
  RetroSkin.button(buy,false,true)
  var use:=Button.new()
  use.custom_minimum_size.y=44
  use.size_flags_horizontal=Control.SIZE_EXPAND_FILL
  use.pressed.connect(func(): pending_power=id; world.placement_lane=""; world.rally_placing=false; world.hud_status="Choose target for "+str(POWERS[id].name)+"; right-click/Esc cancels.")
  row.add_child(use)
  RetroSkin.button(use,false,true)
  use.tooltip_text="Rank %d; 1 GP per level, up to 3 levels. Radius %d; cooldown %ds; warning %.1fs. Offensive powers need shared sight; recon can target shroud." % [POWERS[id].rank,POWERS[id].radius,POWERS[id].cooldown,POWERS[id].delay]
  power_buttons[id]={"buy":buy,"use":use}
 if Rules.faction(world.army_choices[0])=="gia":
  var use:=Button.new()
  use.text="FIRE SILO (240s charge)"
  use.custom_minimum_size.y=44
  use.pressed.connect(func(): pending_power="silo"; world.placement_lane=""; world.rally_placing=false)
  silo_button=use
  RetroSkin.button(use,false,true)
  column.add_child(use)

func refresh_ui() -> void:
 if not is_instance_valid(rank_label) or teams.size()!=2: return
 var s: Dictionary=teams[0]
 rank_label.text="COMMAND RANK %d · XP %d · GP %d\nResearch & commander powers" % [s.rank,int(s.xp),s.points]
 for id in research_buttons:
  var button: Button=research_buttons[id]
  button.text=str(RESEARCH[id].name)+(" DONE" if has_research(0,id) else " $%d" % int(RESEARCH[id].cost))
  if not s.job.is_empty() and s.job.id==id: button.text+=" %d%%" % int(100*s.job.paid/RESEARCH[id].cost)
  button.disabled=has_research(0,id) or not s.job.is_empty() or not world.has_structure(0,RESEARCH[id].site)
  button.tooltip_text="Requires "+str(RESEARCH[id].site)+"; %ds; permanent extra power demand %d." % [int(RESEARCH[id].time),RESEARCH[id].demand]
 for id in power_buttons:
  var level:=int(s.powers.get(id,0))
  var cooldown:=float(s.cooldowns.get(id,0.0))
  power_buttons[id].buy.disabled=s.points<1 or level>=3 or rank(0)<POWERS[id].rank
  power_buttons[id].use.disabled=level==0 or cooldown>0.0
  power_buttons[id].use.text="%s L%d · %s" % [POWERS[id].name,level,"R%d" % POWERS[id].rank if level==0 else ("%ds" % ceili(cooldown) if cooldown>0 else "READY")]
 if is_instance_valid(silo_button):
  silo_button.text="SILO · "+("%ds" % ceili(s.silo) if s.silo>0 else "READY")
  silo_button.disabled=not world.has_structure(0,"silo") or not world.power_ok(0) or s.silo>0

func _draw() -> void:
 for event in events:
  var tint:=Color("#ffb460") if event.side==0 else Color("#ff6258")
  draw_arc(event.point,event.radius,0,TAU,48,tint,3.0)
  draw_line(event.point-Vector2(12,0),event.point+Vector2(12,0),tint,2)
  draw_line(event.point-Vector2(0,12),event.point+Vector2(0,12),tint,2)
  draw_string(ThemeDB.fallback_font,event.point+Vector2(12,-15),"%s %.1fs" % [event.id.to_upper(),event.remaining],HORIZONTAL_ALIGNMENT_LEFT,-1,14,tint)
 for effect in buffs:
  if effect.side==0 or world.feedback_visible(effect.point): draw_arc(effect.point,effect.radius,0,TAU,48,Color("#74d4d0"),1.5)
