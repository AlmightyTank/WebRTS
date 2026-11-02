extends Node2D
## Match-local authority for research, promotions, telegraphed support and interception.
const Rules = preload("res://scripts/economy/army_rules.gd")
const RetroSkin = preload("res://scripts/ui/retro_skin.gd")
const CameoScript = preload("res://scripts/ui/power_cameo.gd")
const RESEARCH := {
 "beam_capacitors":{"name":"Beam Capacitors","army":"alliance_energy","site":"depot","cost":1400.0,"time":35.0,"demand":25},
 "grid_stabilizers":{"name":"Grid Stabilizers","army":"alliance_energy","site":"depot","cost":1200.0,"time":30.0,"demand":15},
 "autoloaders":{"name":"Autoloaders","army":"republic_armor","site":"vanguard_foundry","cost":1600.0,"time":40.0,"demand":0},
 "veteran_crews":{"name":"Veteran Crews","army":"republic_armor","site":"vanguard_foundry","cost":1200.0,"time":30.0,"demand":0},
 "guidance_van":{"name":"Guidance Van Targeting","army":"gia_missile","site":"depot","cost":1100.0,"time":30.0,"demand":10},
 "rapid_reload":{"name":"Rapid Reload","army":"gia_missile","site":"depot","cost":1500.0,"time":40.0,"demand":10},
 "saturation_payload":{"name":"Silo Saturation Payload","army":"gia_missile","site":"silo","cost":2000.0,"time":50.0,"demand":10},
 "reinforced_hangars":{"name":"Reinforced Hangars","army":"alliance_air","site":"factory","cost":1300.0,"time":32.0,"demand":20},
 "countermeasures":{"name":"Advanced Countermeasures","army":"alliance_air","site":"factory","cost":1100.0,"time":28.0,"demand":10},
 "forward_observers":{"name":"Forward Observers","army":"republic_artillery","site":"factory","cost":1200.0,"time":30.0,"demand":10},
 "rapid_fire_mission":{"name":"Rapid Fire Mission","army":"republic_artillery","site":"factory","cost":1500.0,"time":36.0,"demand":15},
 "recovery_crews":{"name":"Recovery Crews","army":"gia_salvage","site":"depot","cost":850.0,"time":30.0,"demand":0},
 "field_improvisation":{"name":"Field Improvisation","army":"gia_salvage","site":"depot","cost":1000.0,"time":34.0,"demand":0}
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
 "saturation_strike":{"name":"Saturation Strike","army":"gia_missile","rank":5,"cooldown":150.0,"radius":210.0,"delay":5.0},
 "recon_overflight":{"name":"Recon Overflight","army":"alliance_air","rank":1,"cooldown":80.0,"radius":240.0,"delay":0.0},
 "interdiction_flight":{"name":"Interdiction Flight","army":"alliance_air","rank":3,"cooldown":110.0,"radius":120.0,"delay":3.0},
 "sky_supremacy":{"name":"Sky Supremacy","army":"alliance_air","rank":5,"cooldown":150.0,"radius":170.0,"delay":5.0},
 "spotter_recon":{"name":"Spotter Recon","army":"republic_artillery","rank":1,"cooldown":80.0,"radius":230.0,"delay":0.0},
 "rolling_barrage":{"name":"Rolling Barrage","army":"republic_artillery","rank":3,"cooldown":120.0,"radius":80.0,"delay":3.0},
 "fire_mission":{"name":"Fire Mission Omega","army":"republic_artillery","rank":5,"cooldown":150.0,"radius":160.0,"delay":4.0},
 "rapid_salvage":{"name":"Rapid Salvage","army":"gia_salvage","rank":1,"cooldown":90.0,"radius":180.0,"delay":0.0},
 "roadside_reinforcements":{"name":"Roadside Reinforcements","army":"gia_salvage","rank":3,"cooldown":140.0,"radius":110.0,"delay":3.0},
 "scavenger_convoy":{"name":"Scavenger Convoy","army":"gia_salvage","rank":5,"cooldown":150.0,"radius":200.0,"delay":0.0}
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
var power_column: VBoxContainer
var strip_label: Label
var countdown_labels: Dictionary = {}
var cameos: Dictionary = {}

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
 if is_instance_valid(rank_label): refresh_ui()
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
 if id not in ["rocket_recon","target_lattice","recon_overflight","spotter_recon"] and not sees(side,point): return false
 if id=="grid_surge" and not world.power_ok(side): return false
 if id=="armor_reserve" and (not legal_site(side,point) or living_count(side)+2+level>80): return false
 if id=="roadside_reinforcements" and (not legal_site(side,point) or living_count(side)+level>80): return false
 s.cooldowns[id]=float(POWERS[id].cooldown)
 var event={"id":id,"side":side,"point":point,"radius":float(POWERS[id].radius),"remaining":float(POWERS[id].delay),"level":level}
 if event.remaining>0.0: _queue_warning(event)
 else: resolve(event)
 pending_power=""
 queue_redraw()
 if is_instance_valid(rank_label): refresh_ui()
 return true

func _queue_warning(event: Dictionary) -> void:
 events.append(event)
 if float(event.get("remaining",0.0))>=0.5 and world!=null and world.has_method("play_cue"): world.play_cue("superweapon")

func living_count(side: int) -> int:
 var count:=0
 for unit in world.units:
  if is_instance_valid(unit) and unit.hp>0 and unit.team==side: count+=1
 return count

func launch_silo(side: int, point: Vector2) -> bool:
 if side<0 or side>1 or world.paused or world.battle_over or not world.BOARD.has_point(point): return false
 if not world.has_structure(side,"silo") or not world.power_ok(side) or teams[side].silo>0.0 or not sees(side,point): return false
 teams[side].silo=240.0
 _queue_warning({"id":"silo","side":side,"point":point,"radius":230.0 if has_research(side,"saturation_payload") else 100.0,"remaining":7.0,"level":1,"wide":has_research(side,"saturation_payload")})
 queue_redraw()
 if is_instance_valid(rank_label): refresh_ui()
 return true

func blast(event: Dictionary, point: Vector2, kind: String, damage: float, radius: float) -> void:
 var side: int=event.side
 if kind=="ROCKET" and intercept_area(side,point): damage*=0.65
 for victim in world.projectile_targets().duplicate():
  if not is_instance_valid(victim) or victim.team==side or victim.team<0 or victim.hp<=0 or victim.air or victim.position.distance_to(point)>radius: continue
  var amount: float=damage*world.armor_multiplier(kind,victim.armor)
  victim.receive_damage(amount,null)
  world.register_hit(null,victim,amount)
  if victim.hp<=0: award_xp(side,100.0)
 world.show_combat_feedback(point,"death",kind,radius*0.35)

func resolve(event: Dictionary) -> void:
 var id: String=event.id
 var side: int=event.side
 var point: Vector2=event.point
 var scale:=1.0+0.25*(int(event.level)-1)
 if id in ["target_lattice","rocket_recon","recon_overflight","spotter_recon"]:
  reveals.append({"side":side,"point":point,"radius":event.radius,"remaining":18.0*scale,"mark":id=="target_lattice"})
  world._refresh_fog()
 elif id in ["grid_surge","breakthrough_order","scavenger_convoy"]:
  buffs.append({"id":id,"side":side,"point":point,"radius":event.radius,"remaining":12.0*scale})
 elif id=="rapid_salvage":
  for unit in world.units:
   if is_instance_valid(unit) and unit.team==side and unit.hp>0 and not unit.air and unit.armor!="PERSONNEL" and unit.position.distance_to(point)<=event.radius:
    unit.hp=minf(unit.max_hp,unit.hp+unit.max_hp*0.12*scale)
    if unit.unit_id=="g_junker": grant_salvage_tier(unit)
    unit.queue_redraw()
 elif id=="field_repairs":
  for unit in world.units:
   if is_instance_valid(unit) and unit.team==side and unit.hp>0 and not unit.air and unit.armor!="PERSONNEL" and unit.position.distance_to(point)<=event.radius:
    unit.hp=minf(unit.max_hp,unit.hp+unit.max_hp*0.25*scale)
    unit.queue_redraw()
 elif id in ["armor_reserve","roadside_reinforcements"]:
  # Recheck occupancy and vision at arrival. A blocked/lost landing zone cancels delivery.
  if not legal_site(side,point): return
  var reserve_id: String="g_junker" if id=="roadside_reinforcements" else "r_jugger"
  var reserve_count: int=int(event.level) if id=="roadside_reinforcements" else 2+int(event.level)
  for i in range(reserve_count):
   if living_count(side)>=80: break
   var site: Vector2=world._find_open_position(point,18.0)
   if site!=Vector2.ZERO and site.distance_to(point)<=event.radius and sees(side,site):
    var unit=world._spawn(reserve_id,side,site)
    world.show_combat_feedback(site,"impact","AP",18.0)
    unit.order_move(site+Vector2(0,72 if side==0 else -72))
 elif id=="rolling_barrage":
  for step in range(3):
   blast(event, point+Vector2((step-1)*90.0,0.0), "AP", 120.0*scale, 70.0)
 else:
  var kind: String="ENERGY" if id=="orbital_pulse" else ("AP" if id=="fire_mission" else "ROCKET")
  var damage: float={"orbital_pulse":260.0,"harassing_salvo":100.0,"saturation_strike":190.0,"interdiction_flight":140.0,"sky_supremacy":210.0,"fire_mission":170.0,"silo":380.0 if bool(event.get("wide",false)) else 900.0}.get(id,0.0)*scale
  # Missile support is finite and interceptable. One ready lattice reduces one local blast.
  blast(event, point, kind, damage, event.radius)

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
 if source.get("unit_id")=="r_stormrail" and has_research(side,"rapid_fire_mission"): interval*=0.85
 if marked(enemy.team,enemy.position): shot.damage*=1.1
 if source.get("unit_xp")!=null and source.unit_xp>=100.0: shot.damage*=1.1
 return interval

func weapon_range(unit, enemy) -> float:
 var result:=float(unit.weapon.get("range",0.0))
 if not enemy.air: result=float(unit.weapon.get("ground_range",result))
 if unit.unit_id in Rules.SIGNATURE_MISSILES and has_research(unit.team,"guidance_van"): result+=30.0
 if unit.unit_id=="r_stormrail":
  result*=1.15
  if has_research(unit.team,"forward_observers"): result+=40.0
 return result

func prepare_unit(unit) -> void:
 if unit.unit_id in Rules.STEEL_TANKS and has_research(unit.team,"veteran_crews"): unit.unit_xp=100.0
 if unit.unit_id=="a_tempest" and has_research(unit.team,"reinforced_hangars"):
  unit.max_hp*=1.15
  unit.hp=unit.max_hp

func grant_salvage_tier(unit) -> void:
 if unit==null or not is_instance_valid(unit) or unit.unit_id!="g_junker": return
 var tier: int=int(unit.get("salvage_tier"))
 if tier>=2: return
 unit.salvage_tier=tier+1
 var bonus: float=0.12 if has_research(unit.team,"field_improvisation") else 0.10
 if unit.salvage_tier==1:
  unit.max_hp*=1.0+bonus
  unit.hp=minf(unit.max_hp,unit.hp+unit.max_hp*bonus)
 else:
  unit.weapon.damage*=1.0+bonus
 unit.queue_redraw()

func salvage_kill(unit, victim) -> void:
 grant_salvage_tier(unit)
 if not has_research(unit.team,"recovery_crews") or victim.get("unit_id")==null: return
 var payout: float=minf(200.0,float(world.roster.get(victim.unit_id,{}).get("credits",0.0))*0.15)
 world.states[unit.team].credits+=payout

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

func ai_tick(side: int = 1) -> void:
 for id in research_ids(side):
  if world.states[side].credits>2500 and start_research(side,id): break
 for id in power_ids(side):
  if not teams[side].powers.has(id): buy_power(side,id)
 if rank(side)==5:
  for id in power_ids(side):
   if int(teams[side].powers.get(id,0))<3: buy_power(side,id)
 for id in power_ids(side):
  var point:=Vector2(-1,-1)
  if id in ["target_lattice","rocket_recon","recon_overflight","spotter_recon"]:
   for unit in world.units:
    if is_instance_valid(unit) and unit.team==side and unit.moving: point=unit.destination; break
  elif id in ["grid_surge","field_repairs","armor_reserve","breakthrough_order","rapid_salvage","roadside_reinforcements","scavenger_convoy"]:
   for unit in world.units:
    if is_instance_valid(unit) and unit.team==side and not Rules.economic(unit.unit_id):
     point=world._find_open_position(unit.position+Vector2(0,80),20.0) if id in ["armor_reserve","roadside_reinforcements"] else unit.position
     break
  else:
   for enemy in world.projectile_targets():
    if is_instance_valid(enemy) and enemy.team==1-side and sees(side,enemy.position): point=enemy.position; break
  if point.x>=0: cast(side,id,point)
 if world.has_structure(side,"silo"):
  for enemy in world.projectile_targets():
   if is_instance_valid(enemy) and enemy.team==1-side and sees(side,enemy.position):
    launch_silo(side,enemy.position)
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
 if power_column==null: return
 strip_label=Label.new()
 strip_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 strip_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 RetroSkin.label(strip_label,true,true)
 power_column.add_child(strip_label)
 for id in power_ids(0):
  _add_cameo(id,true)
 if Rules.faction(world.army_choices[0])=="gia":
  _add_cameo("silo",false)
 _show_column()
 refresh_ui()

func _player_tint() -> Color:
 match Rules.faction(world.army_choices[0]):
  "republic": return Color("#d9896a")
  "gia": return Color("#c4b56a")
  _: return Color("#7ec8d4")

func _show_column() -> void:
 var show: bool=not power_ids(0).is_empty() or Rules.faction(world.army_choices[0])=="gia"
 if world.get("hud_powers")!=null and is_instance_valid(world.hud_powers):
  world.hud_powers.visible=show

func _add_cameo(id: String, purchasable: bool) -> void:
 var slot:=Control.new()
 slot.custom_minimum_size=Vector2(64,64)
 slot.mouse_filter=Control.MOUSE_FILTER_IGNORE
 power_column.add_child(slot)
 var use:=Button.new()
 use.flat=true
 use.focus_mode=Control.FOCUS_ALL
 use.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 use.pressed.connect(_arm_power.bind(id))
 RetroSkin.button(use,false,true)
 slot.add_child(use)
 var cameo:=Control.new()
 cameo.set_script(CameoScript)
 cameo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 cameo.configure(id,_player_tint())
 use.add_child(cameo)
 var count:=Label.new()
 count.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 count.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 count.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
 count.mouse_filter=Control.MOUSE_FILTER_IGNORE
 count.add_theme_font_size_override("font_size",16)
 count.add_theme_color_override("font_color",Color("#f6f3e8"))
 count.add_theme_color_override("font_outline_color",Color("#061014"))
 count.add_theme_constant_override("outline_size",6)
 use.add_child(count)
 if purchasable:
  var buy:=Button.new()
  buy.text="+"
  buy.focus_mode=Control.FOCUS_ALL
  buy.anchor_left=1.0
  buy.anchor_right=1.0
  buy.anchor_top=0.0
  buy.anchor_bottom=0.0
  buy.offset_left=-24.0
  buy.offset_right=-2.0
  buy.offset_top=2.0
  buy.offset_bottom=24.0
  buy.pressed.connect(func(): buy_power(0,id); refresh_ui())
  RetroSkin.button(buy,true,true)
  buy.add_theme_font_size_override("font_size",14)
  buy.tooltip_text="Spend 1 general point. Each power has three levels."
  slot.add_child(buy)
  power_buttons[id]={"buy":buy,"use":use}
 else:
  silo_button=use
 countdown_labels[id]=count
 cameos[id]=cameo

func _arm_power(id: String) -> void:
 pending_power=id
 world.placement_lane=""
 world.rally_placing=false
 if id=="silo":
  world.hud_status="Choose the silo impact. Right-click or Esc cancels."
 else:
  world.hud_status="Choose target for "+str(POWERS[id].name)+". Right-click or Esc cancels."
 refresh_ui()

func refresh_ui() -> void:
 if not is_instance_valid(rank_label) or teams.size()!=2: return
 var s: Dictionary=teams[0]
 rank_label.text="COMMAND RANK %d · XP %d · GP %d\nResearch" % [s.rank,int(s.xp),s.points]
 if is_instance_valid(strip_label):
  strip_label.text="RANK %d\nGP %d" % [s.rank,s.points]
 for id in research_buttons:
  var button: Button=research_buttons[id]
  button.text=str(RESEARCH[id].name)+(" DONE" if has_research(0,id) else " $%d" % int(RESEARCH[id].cost))
  if not s.job.is_empty() and s.job.id==id: button.text+=" %d%%" % int(100*s.job.paid/RESEARCH[id].cost)
  button.disabled=has_research(0,id) or not s.job.is_empty() or not world.has_structure(0,RESEARCH[id].site)
  button.tooltip_text="Requires "+str(RESEARCH[id].site)+"; %ds; permanent extra power demand %d." % [int(RESEARCH[id].time),RESEARCH[id].demand]
 for id in power_buttons:
  var level:=int(s.powers.get(id,0))
  var cooldown:=float(s.cooldowns.get(id,0.0))
  var data: Dictionary=POWERS[id]
  var ranked: bool=rank(0)>=int(data.rank)
  power_buttons[id].buy.disabled=s.points<1 or level>=3 or not ranked
  power_buttons[id].buy.visible=level<3 and ranked
  power_buttons[id].use.disabled=level==0 or cooldown>0.0
  power_buttons[id].use.tooltip_text="%s. Rank %d. 1 GP per level, up to 3. Radius %d. Cooldown %ds. Warning %.1fs. Offensive powers need shared sight. Recon can target shroud." % [data.name,data.rank,data.radius,data.cooldown,data.delay]
  _present_cameo(id,level,cooldown,float(data.cooldown),rank(0)<int(data.rank) and level==0,"R%d" % int(data.rank))
 if is_instance_valid(silo_button):
  var owns_silo: bool=world.has_structure(0,"silo")
  var charge: float=float(s.silo) if owns_silo else 0.0
  var silo_ready: bool=owns_silo and world.power_ok(0) and charge<=0.0
  silo_button.disabled=not silo_ready
  silo_button.tooltip_text="Ballistic missile. 240s charge. A powered silo is required."
  _present_cameo("silo",1 if owns_silo else 0,charge,240.0,not owns_silo or not world.power_ok(0),"")
 _show_column()

func _present_cameo(id: String, level: int, remaining: float, duration: float, locked: bool, locked_text: String) -> void:
 if not countdown_labels.has(id): return
 var count: Label=countdown_labels[id]
 if remaining>0.0:
  count.text=str(ceili(remaining))
  count.add_theme_font_size_override("font_size",16)
 elif locked and locked_text!="":
  count.text=locked_text
  count.add_theme_font_size_override("font_size",13)
 else:
  count.text=""
 cameos[id].present(level,remaining/maxf(duration,0.001),pending_power==id,locked)

func _draw() -> void:
 for event in events:
  var tint:=Color("#ffb460") if event.side==0 else Color("#ff6258")
  draw_arc(event.point,event.radius,0,TAU,48,tint,3.0)
  draw_line(event.point-Vector2(12,0),event.point+Vector2(12,0),tint,2)
  draw_line(event.point-Vector2(0,12),event.point+Vector2(0,12),tint,2)
  draw_string(ThemeDB.fallback_font,event.point+Vector2(12,-15),"%s %.1fs" % [event.id.to_upper(),event.remaining],HORIZONTAL_ALIGNMENT_LEFT,-1,14,tint)
 for effect in buffs:
  if effect.side==0 or world.feedback_visible(effect.point): draw_arc(effect.point,effect.radius,0,TAU,48,Color("#74d4d0"),1.5)
