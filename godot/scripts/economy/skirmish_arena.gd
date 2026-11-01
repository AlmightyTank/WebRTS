extends "res://scripts/combat/combat_arena.gd"
## Economic vertical slice: shared C&C-style production lanes over the existing combat renderer.
const StructureScript = preload("res://scripts/economy/structure.gd")
const EconomyVehicleScript = preload("res://scripts/economy/economy_vehicle.gd")
const STRUCTURE_DATA := {
 "power":{"name":"Power Plant","cost":800.0,"time":10.0,"power":150,"demand":0,"size":Vector2(104,94),"hp":1350},
 "refinery":{"name":"Ore Refinery (+ Harvester)","cost":2000.0,"time":24.0,"power":0,"demand":50,"size":Vector2(142,116),"hp":1350},
 "barracks":{"name":"Barracks","cost":500.0,"time":10.0,"power":0,"demand":10,"size":Vector2(102,96),"hp":1350},
 "factory":{"name":"War Factory","cost":2000.0,"time":26.0,"power":0,"demand":30,"size":Vector2(146,118),"hp":1700},
 "turret":{"name":"Sentry Turret","cost":550.0,"time":9.0,"power":0,"demand":10,"size":Vector2(66,66),"hp":1350}
}
const TABS := ["BUILDINGS","DEFENSE","INFANTRY","VEHICLES"]
var structures: Array = []
var ore_fields: Array = []
var static_obstacles: Array[Rect2] = []
var states: Array = []
var current_tab := 0
var placement_lane := ""
var preview_pos := Vector2.ZERO
var action_buttons: Dictionary = {}
var build_container: VBoxContainer
var tab_buttons: Array = []
var title_text: Label
var details_text: Label
var hud_status := "Deploy your MCV (H), then build a Power Plant."
var economy_ai_timer := 0.0
var skirmish_time := 0.0
var ai_build_tick := 0
var cheat_test := false

func _ready() -> void:
 super._ready()
 # reset_battle() captures immutable scenery on the first run.
 _rebuild_navigation()

func _new_state() -> Dictionary:
 return {"credits":10000.0,"total_mined":0.0,"total_spent":0.0,"power":0,"demand":0,"lanes":{"build":{},"defense":{},"infantry":{},"vehicle":{}},"queued":{"infantry":[],"vehicle":[]},"harvesters":0}

func reset_battle() -> void:
 # Override the Combat Lab's scenario starting point; its four benchmark
 # scenes remain available as res://scenes/combat_lab.tscn.
 for u in units:
  if is_instance_valid(u): u.queue_free()
 for p in projectiles:
  if is_instance_valid(p): p.queue_free()
 for b in structures:
  if is_instance_valid(b): b.queue_free()
 units.clear()
 projectiles.clear()
 structures.clear()
 selected.clear()
 states=[_new_state(),_new_state()]
 ore_fields=[
  {"position":Vector2(630,330),"remaining":7200.0,"initial":7200.0},
  {"position":Vector2(580,930),"remaining":6000.0,"initial":6000.0},
  {"position":Vector2(1320,820),"remaining":7200.0,"initial":7200.0},
  {"position":Vector2(1370,150),"remaining":6000.0,"initial":6000.0},
  {"position":Vector2(1080,1010),"remaining":5500.0,"initial":5500.0}
 ]
 skirmish_time=0.0
 economy_ai_timer=2.0
 ai_build_tick=0
 battle_over=false
 paused=false
 shots=0
 hits=0
 kills=[0,0]
 placement_lane=""
 current_tab=0
 hud_status="Select the MCV, press H or tap DEPLOY, and build POWER."
 if static_obstacles.is_empty(): static_obstacles=obstacles.duplicate()
 _rebuild_navigation()
 var ally=_spawn_economy("a_mcv",0,Vector2(310,620),false)
 _spawn_economy("r_mcv",1,Vector2(1600,610),false)
 # An AI follows the same construction/credit rules, but deploys its MCV immediately.
 _deploy_mcv(1)
 if ally!=null:
  ally.selected=true
  selected=[ally]
 if is_instance_valid(result_text): result_text.text=""
 _update_hud()
 queue_redraw()

func _rebuild_navigation() -> void:
 obstacles=static_obstacles.duplicate()
 for building in structures:
  if is_instance_valid(building) and building.hp>0.0: obstacles.append(building.ground_bounds())
 _create_navigation()

func _spawn_economy(id: String, side: int, where: Vector2, harvester: bool):
 if not roster.has(id):
  push_error("Missing economic unit in balance registry: "+id)
  return null
 var actor=Node2D.new()
 actor.set_script(EconomyVehicleScript)
 actors.add_child(actor)
 actor.configure(self,roster[id],side,where,harvester)
 actor.destroyed.connect(_on_destroyed)
 units.append(actor)
 return actor

func _deploy_mcv(side: int) -> bool:
 var mcv
 for unit in units:
  if is_instance_valid(unit) and unit.team==side and unit.unit_id in ["a_mcv","r_mcv"] and not unit.moving:
   mcv=unit
   break
 if mcv==null: return false
 if not can_place(mcv.position,"yard",side): return false
 var where: Vector2=mcv.position
 units.erase(mcv)
 selected.erase(mcv)
 mcv.queue_free()
 _place_structure("yard",side,where)
 hud_status="Construction Yard deployed. Build power to begin." if side==0 else hud_status
 return true

func _place_structure(id: String, side: int, point: Vector2) -> bool:
 var size: Vector2=Vector2(155,135) if id=="yard" else STRUCTURE_DATA[id]["size"]
 var b=Node2D.new()
 b.set_script(StructureScript)
 actors.add_child(b)
 b.configure(self,id,side,point,size)
 b.destroyed.connect(_building_destroyed)
 structures.append(b)
 _rebuild_navigation()
 _calculate_power(side)
 if id=="refinery":
  var nearest=point+Vector2(0,135 if side==0 else -135)
  var spawn_site=_find_open_position(nearest,22.0)
  if spawn_site!=Vector2.ZERO:
   _spawn_economy("a_harvester" if side==0 else "r_hauler",side,spawn_site,true)
   states[side]["harvesters"]=int(states[side]["harvesters"])+1
  else:
   push_warning("Refinery deployed but initial harvester spawn is obstructed")
 queue_redraw()
 return true

func _find_open_position(point: Vector2, radius: float) -> Vector2:
 for r in [0.0,54.0,105.0,156.0,210.0]:
  for i in range(12):
   var angle=TAU*float(i)/12.0
   var pos=clamp_point(point+Vector2.RIGHT.rotated(angle)*r)
   if can_occupy(pos,radius,false): return pos
 return Vector2.ZERO

func _building_destroyed(building) -> void:
 structures.erase(building)
 _rebuild_navigation()
 _calculate_power(building.team)
 _check_victory()

func _on_destroyed(unit) -> void:
 kills[1-unit.team]+=1
 selected.erase(unit)
 units.erase(unit)
 _check_victory()

func _check_victory() -> void:
 if battle_over: return
 if skirmish_time<3.0: return
 for side in range(2):
  var significant=0
  var deployed_or_mobile=false
  for building in structures:
   if is_instance_valid(building) and building.team==side and building.hp>0:
    if building.kind!="turret": significant+=1
    if building.kind=="yard": deployed_or_mobile=true
  for actor in units:
   if is_instance_valid(actor) and actor.team==side and actor.unit_id in ["a_mcv","r_mcv"]: deployed_or_mobile=true
  if significant==0 and not deployed_or_mobile:
   battle_over=true
   if is_instance_valid(result_text): result_text.text="VICTORY — REPUBLIC DEFEATED" if side==1 else "DEFEAT — ALLIANCE LOST"
   return

func projectile_targets() -> Array:
 var targets=units.duplicate()
 targets.append_array(structures)
 return targets

func find_target(seeker, search_radius: float):
 var winner
 var best=INF
 for entity in projectile_targets():
  if not is_instance_valid(entity) or entity.hp<=0 or not seeker.can_hit(entity): continue
  var distance=seeker.position.distance_to(entity.position)
  if distance>search_radius: continue
  var score=distance
  if entity is Node2D and entity in structures: score*=1.25
  if seeker.weapon.get("type","")=="AA" and entity.air: score*=0.5
  if seeker.weapon.get("type","")=="ROCKET" and entity.armor=="HEAVY": score*=0.7
  if score<best:
   best=score
   winner=entity
 return winner

func power_ok(side: int) -> bool:
 return int(states[side]["power"])>=int(states[side]["demand"])

func _power_speed(side: int, category: String) -> float:
 if category=="build" and str(states[side]["lanes"][category].get("id",""))=="power": return 1.0
 return 1.0 if power_ok(side) else 0.5

func _calculate_power(side: int) -> void:
 var capacity=0
 var demand=0
 for b in structures:
  if not is_instance_valid(b) or b.hp<=0 or b.team!=side or b.kind=="yard": continue
  capacity+=int(STRUCTURE_DATA[b.kind]["power"])
  demand+=int(STRUCTURE_DATA[b.kind]["demand"])
 states[side]["power"]=capacity
 states[side]["demand"]=demand

func has_structure(side: int, id: String) -> bool:
 for b in structures:
  if is_instance_valid(b) and b.hp>0 and b.team==side and b.kind==id: return true
 return false

func _has_producer(side: int, lane: String) -> bool:
 if lane in ["build","defense"]: return has_structure(side,"yard")
 if lane=="infantry": return has_structure(side,"barracks")
 if lane=="vehicle": return has_structure(side,"factory")
 return false

func _tech_ready(side: int, id: String) -> bool:
 match id:
  "power": return has_structure(side,"yard")
  "refinery","barracks": return has_structure(side,"power")
  "factory": return has_structure(side,"refinery") and has_structure(side,"barracks")
  "turret": return has_structure(side,"barracks")
  "a_ranger","r_line": return has_structure(side,"barracks")
  "a_javelin","r_hunter": return has_structure(side,"barracks") and has_structure(side,"refinery")
  "a_sentinel","r_bastion","a_harvester","r_hauler": return has_structure(side,"factory")
  "a_sentinel_aa","r_flak": return has_structure(side,"factory") and has_structure(side,"power")
 return false

func _recipe(id: String) -> Dictionary:
 if STRUCTURE_DATA.has(id): return STRUCTURE_DATA[id]
 if roster.has(id):
  return {"name":roster[id]["name"],"cost":float(roster[id]["credits"]),"time":float(roster[id]["build_seconds"])}
 return {}

func queue_production(side: int, lane: String, id: String) -> bool:
 if not _has_producer(side,lane) or not _tech_ready(side,id): return false
 var lanes: Dictionary=states[side]["lanes"]
 if lane in ["build","defense"]:
  if not lanes[lane].is_empty(): return false
 else:
  var scheduled: Array=states[side]["queued"][lane]
  if scheduled.size()>=20: return false
  if not lanes[lane].is_empty():
   scheduled.append(id)
   return true
 lanes[lane]={"id":id,"paid":0.0,"ready":false}
 return true

func _tick_production(side: int, delta: float) -> void:
 var lanes: Dictionary=states[side]["lanes"]
 for lane in ["build","defense","infantry","vehicle"]:
  var job: Dictionary=lanes[lane]
  if job.is_empty():
   var waiting: Array=states[side]["queued"].get(lane,[])
   if not waiting.is_empty() and _has_producer(side,lane):
    lanes[lane]={"id":waiting.pop_front(),"paid":0.0,"ready":false}
   continue
  if bool(job.get("ready",false)):
   if side==1: _ai_place_ready(lane,str(job["id"]))
   continue
  if not _has_producer(side,lane): continue
  var recipe=_recipe(str(job["id"]))
  if recipe.is_empty(): continue
  var cost=float(recipe["cost"])
  var duration=maxf(0.25,float(recipe["time"]))
  var speed=_power_speed(side,lane)
  # Multiple same-domain producers accelerate one shared lane (RA2-style).
  var producers=0
  var producer_name="yard" if lane in ["build","defense"] else ("barracks" if lane=="infantry" else "factory")
  for building in structures:
   if is_instance_valid(building) and building.team==side and building.kind==producer_name: producers+=1
  speed*=maxf(0.55,pow(0.82,maxi(0,producers-1)))
  # Speed factor above represents seconds-per-item; inverse for actual progress.
  var target_spend=cost/duration*delta/maxf(0.55,speed) if cost>0.0 else 0.0
  var payment=minf(maxf(0.0,float(states[side]["credits"])),minf(cost-float(job["paid"]),target_spend))
  states[side]["credits"]=float(states[side]["credits"])-payment
  states[side]["total_spent"]=float(states[side]["total_spent"])+payment
  job["paid"]=minf(cost,float(job["paid"])+payment)
  if float(job["paid"])>=cost-0.001:
   job["paid"]=cost
   job["ready"]=true
   if lane in ["infantry","vehicle"]:
    if _produce_unit(side,str(job["id"])): lanes[lane]={}

func _produce_unit(side: int, id: String) -> bool:
 var producer="barracks" if id in ["a_ranger","a_javelin","r_line","r_hunter"] else "factory"
 for b in structures:
  if is_instance_valid(b) and b.team==side and b.kind==producer:
   var offset=Vector2(0,125) if side==0 else Vector2(0,-125)
   var where=_find_open_position(b.position+offset,20.0)
   if where==Vector2.ZERO: return false
   if id in ["a_harvester","r_hauler"]:
    _spawn_economy(id,side,where,true)
   else:
    _spawn(id,side,where)
   return true
 return false

func _ai_place_ready(lane: String, id: String) -> void:
 var sites=[Vector2(-235,-205),Vector2(-225,-10),Vector2(-225,190),Vector2(80,-225),Vector2(200,15),Vector2(170,195),Vector2(-400,110),Vector2(40,360),Vector2(-400,-230),Vector2(340,-250)]
 for offset in sites:
  var place=Vector2(1600,610)+offset
  place=Vector2(roundf(place.x/24.0)*24.0,roundf(place.y/24.0)*24.0)
  if can_place(place,id,1):
   _place_structure(id,1,place)
   states[1]["lanes"][lane]={}
   return

func can_place(point: Vector2, id: String, side: int) -> bool:
 var size=Vector2(155,135) if id=="yard" else STRUCTURE_DATA[id]["size"]
 var rect=Rect2(point-size/2.0,size)
 if not BOARD.grow(-16).encloses(rect): return false
 for obstacle in obstacles:
  if obstacle.grow(12.0).intersects(rect): return false
 for field in ore_fields:
  if float(field["remaining"])>0 and point.distance_to(field["position"])<105.0: return false
 for u in units:
  if is_instance_valid(u) and u.hp>0 and rect.grow(u.radius+3).has_point(u.position):
   # Allow MCV to deploy on its own exact position.
   if not (id=="yard" and u.unit_id in ["a_mcv","r_mcv"] and u.team==side and u.position.distance_to(point)<3.0): return false
 if id=="yard": return true
 if not has_structure(side,"yard"): return false
 for b in structures:
  if is_instance_valid(b) and b.team==side and b.hp>0 and b.position.distance_to(point)<330.0:
   return true
 return false

func _place_player_ready(point: Vector2) -> bool:
 if placement_lane=="": return false
 var lane=placement_lane
 var job: Dictionary=states[0]["lanes"][lane]
 if job.is_empty() or not bool(job.get("ready",false)): return false
 var id=str(job["id"])
 var snapped=Vector2(roundf(point.x/24.0)*24.0,roundf(point.y/24.0)*24.0)
 if not can_place(snapped,id,0):
  hud_status="Placement blocked: stay near your base on clear ground."
  return false
 _place_structure(id,0,snapped)
 states[0]["lanes"][lane]={}
 placement_lane=""
 hud_status="Built "+str(STRUCTURE_DATA[id]["name"])
 return true

func find_ore(point: Vector2, _side: int) -> int:
 var best=-1
 var d=INF
 for i in range(ore_fields.size()):
  if float(ore_fields[i]["remaining"])<1.0: continue
  var dist=point.distance_squared_to(ore_fields[i]["position"])
  if dist<d:
   d=dist
   best=i
 return best

func mine_near(point: Vector2, radius: float, _side: int) -> float:
 for field in ore_fields:
  if point.distance_to(field["position"])<radius and float(field["remaining"])>0.0:
   var amount=minf(18.0,float(field["remaining"]))
   field["remaining"]=float(field["remaining"])-amount
   return amount
 return 0.0

func deliver_ore(side: int, amount: float) -> void:
 if amount<=0.0: return
 states[side]["credits"]=float(states[side]["credits"])+amount
 states[side]["total_mined"]=float(states[side]["total_mined"])+amount

func find_refinery(point: Vector2, side: int):
 var refinery
 var best=INF
 for b in structures:
  if is_instance_valid(b) and b.team==side and b.kind=="refinery" and b.hp>0:
   var d=point.distance_squared_to(b.position)
   if d<best: best=d; refinery=b
 return refinery

func _ai_economy() -> void:
 # The opponent pays actual costs, obeys prerequisites, and receives ore only
 # when its harvester physically unloads; no hidden AI resource grants.
 var state: Dictionary=states[1]
 if state["lanes"]["build"].is_empty():
  for id in ["power","refinery","barracks","factory"]:
   if not has_structure(1,id) and _tech_ready(1,id):
    queue_production(1,"build",id)
    break
  if has_structure(1,"factory") and float(state["credits"])>2500.0 and ai_build_tick%6==0:
   queue_production(1,"build","power")
 if state["lanes"]["defense"].is_empty() and has_structure(1,"barracks") and ai_build_tick%5==0:
  if _building_count(1,"turret")<2: queue_production(1,"defense","turret")
 if has_structure(1,"barracks") and float(state["credits"])>800.0 and ai_build_tick%2==0:
  queue_production(1,"infantry","r_hunter" if has_structure(1,"refinery") and ai_build_tick%4==0 else "r_line")
 if has_structure(1,"factory") and float(state["credits"])>1700.0:
  queue_production(1,"vehicle","r_bastion" if ai_build_tick%3!=0 else "r_flak")
 ai_build_tick+=1

func _building_count(side: int, id: String) -> int:
 var count=0
 for b in structures:
  if is_instance_valid(b) and b.team==side and b.kind==id and b.hp>0: count+=1
 return count

func _physics_process(delta: float) -> void:
 super._physics_process(delta)
 if paused or battle_over: return
 skirmish_time+=delta
 _tick_production(0,delta)
 _tick_production(1,delta)
 economy_ai_timer-=delta
 if economy_ai_timer<=0:
  economy_ai_timer=2.1
  _ai_economy()

func _unhandled_input(event: InputEvent) -> void:
 if event is InputEventKey and event.pressed and not event.echo:
  if event.keycode==KEY_H:
   if _deploy_mcv(0): _update_hud()
   get_viewport().set_input_as_handled()
   return
  if event.keycode in [KEY_1,KEY_2,KEY_3,KEY_4]:
   current_tab=event.keycode-KEY_1
   _update_hud()
   get_viewport().set_input_as_handled()
   return
 if placement_lane!="" and event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.pressed:
  _place_player_ready(get_global_mouse_position())
  _update_hud()
  get_viewport().set_input_as_handled()
  return
 if placement_lane!="" and event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_RIGHT and event.pressed:
  placement_lane=""
  queue_redraw()
  get_viewport().set_input_as_handled()
  return
 if placement_lane!="" and event is InputEventScreenTouch and event.pressed and event.index==0:
  _place_player_ready(_screen_to_world(event.position))
  _update_hud()
  get_viewport().set_input_as_handled()
  return
 super._unhandled_input(event)

func issue_order(point: Vector2, attack_move: bool=false) -> void:
 var enemy_building
 for b in structures:
  if is_instance_valid(b) and b.team==1 and b.ground_bounds().grow(8).has_point(point): enemy_building=b; break
 if enemy_building!=null:
  for u in selected:
   if is_instance_valid(u) and u.can_hit(enemy_building): u.order_attack(enemy_building)
  return
 super.issue_order(point,attack_move)

func _create_hud() -> void:
 hud=CanvasLayer.new()
 add_child(hud)
 var root=Control.new()
 root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 root.mouse_filter=Control.MOUSE_FILTER_IGNORE
 hud.add_child(root)
 var top=PanelContainer.new()
 top.position=Vector2(12,12)
 top.custom_minimum_size=Vector2(775,83)
 root.add_child(top)
 var stats=VBoxContainer.new()
 top.add_child(stats)
 title_text=Label.new()
 title_text.text="MERIDIAN WARFRONT  /  CONSTRUCTION + COMBAT  v0.7"
 title_text.add_theme_font_size_override("font_size",18)
 stats.add_child(title_text)
 hud_text=Label.new()
 stats.add_child(hud_text)
 info_text=Label.new()
 stats.add_child(info_text)
 var dock=PanelContainer.new()
 dock.anchor_left=1.0
 dock.anchor_right=1.0
 dock.offset_left=-294.0
 dock.offset_right=-10.0
 dock.offset_top=12.0
 dock.offset_bottom=620.0
 root.add_child(dock)
 var column=VBoxContainer.new()
 dock.add_child(column)
 var header=Label.new()
 header.text="CONSTRUCTION SIDEBAR"
 column.add_child(header)
 var tabs=HBoxContainer.new()
 column.add_child(tabs)
 for i in range(4):
  var tab=Button.new()
  tab.text=["BUILD","DEF","INF","VEH"][i]
  tab.custom_minimum_size=Vector2(64,37)
  tab.pressed.connect(_set_tab.bind(i))
  tabs.add_child(tab)
  tab_buttons.append(tab)
 build_container=VBoxContainer.new()
 column.add_child(build_container)
 for id in ["power","refinery","barracks","factory","turret","a_ranger","a_javelin","a_sentinel","a_sentinel_aa","a_harvester"]:
  var button=Button.new()
  button.text=id
  button.custom_minimum_size=Vector2(256,48)
  button.pressed.connect(_on_build_button.bind(id))
  build_container.add_child(button)
  action_buttons[id]=button
 var separator=HSeparator.new()
 column.add_child(separator)
 var deploy=Button.new()
 deploy.text="DEPLOY SELECTED MCV (H)"
 deploy.custom_minimum_size=Vector2(240,46)
 deploy.pressed.connect(_on_deploy)
 column.add_child(deploy)
 var harvest=Button.new()
 harvest.text="AUTO-HARVEST SELECTED"
 harvest.custom_minimum_size=Vector2(240,40)
 harvest.pressed.connect(_on_harvest)
 column.add_child(harvest)
 var bottom=PanelContainer.new()
 bottom.anchor_top=1.0
 bottom.anchor_bottom=1.0
 bottom.offset_top=-89.0
 bottom.offset_bottom=-12.0
 bottom.offset_left=12.0
 root.add_child(bottom)
 var row=HBoxContainer.new()
 bottom.add_child(row)
 for pair in [["SELECT_ALL","Select All"],["MOVE","Move"],["ATTACK_MOVE","Attack-Move"],["STOP","Stop"],["FORMATION","Formation"],["PAUSE","Pause"],["RESET","Restart"]]:
  var button=Button.new()
  button.text=pair[1]
  button.custom_minimum_size=Vector2(92,45)
  button.pressed.connect(_on_toolbar.bind(pair[0]))
  row.add_child(button)
 result_text=Label.new()
 result_text.anchor_left=0.5
 result_text.anchor_right=0.5
 result_text.offset_left=-180
 result_text.offset_top=108
 result_text.add_theme_font_size_override("font_size",24)
 root.add_child(result_text)

func _on_deploy() -> void:
 if _deploy_mcv(0): _update_hud()

func _on_harvest() -> void:
 for actor in selected:
  if is_instance_valid(actor) and actor.unit_id=="a_harvester": actor.set_harvest()

func _set_tab(value: int) -> void:
 current_tab=value
 _update_hud()

func _on_build_button(id: String) -> void:
 var lane=_lane_for(id)
 var job: Dictionary=states[0]["lanes"][lane]
 if not job.is_empty() and str(job["id"])==id and bool(job["ready"]) and lane in ["build","defense"]:
  placement_lane=lane
  hud_status="Place "+str(STRUCTURE_DATA[id]["name"])+" near friendly buildings (right-click to cancel)."
 elif queue_production(0,lane,id):
  hud_status="Queued "+str(_recipe(id)["name"])
 else:
  hud_status="Unavailable: check tech prerequisites, producer, or busy construction lane."
 _update_hud()
 queue_redraw()

func _lane_for(id: String) -> String:
 if id=="turret": return "defense"
 if id in ["power","refinery","barracks","factory"]: return "build"
 if id in ["a_ranger","a_javelin","r_line","r_hunter"]: return "infantry"
 return "vehicle"

func _update_hud() -> void:
 if not is_instance_valid(hud_text) or states.size()<2: return
 var state: Dictionary=states[0]
 var power_mark="LOW POWER" if not power_ok(0) else "POWER OK"
 hud_text.text="CREDITS %d     POWER %d / %d (%s)     ORE BANKED %d" % [int(state["credits"]),int(state["power"]),int(state["demand"]),power_mark,int(state["total_mined"])]
 var details: Array[String]=[]
 for lane in ["build","defense","infantry","vehicle"]:
  var job: Dictionary=state["lanes"][lane]
  if not job.is_empty():
   var recipe=_recipe(str(job["id"]))
   var percentage=int(100.0*float(job["paid"])/maxf(1.0,float(recipe.get("cost",1.0))))
   details.append("%s %s %d%%" % [lane.to_upper(),str(recipe.get("name",job["id"])),percentage])
 info_text.text=" | ".join(details) if not details.is_empty() else hud_status
 for i in range(tab_buttons.size()):
  tab_buttons[i].button_pressed=(i==current_tab)
 for id in action_buttons.keys():
  var button: Button=action_buttons[id]
  var lane=_lane_for(id)
  var tab_index=0 if lane=="build" else (1 if lane=="defense" else (2 if lane=="infantry" else 3))
  button.visible=(current_tab==tab_index)
  var job: Dictionary=state["lanes"][lane]
  var recipe=_recipe(id)
  var label=str(recipe.get("name",id))
  var cost=int(recipe.get("cost",0))
  var ready=not job.is_empty() and str(job["id"])==id and bool(job["ready"])
  button.text="READY: PLACE "+label if ready else ("%s    $%d  %ds" % [label,cost,int(recipe.get("time",0))])
  button.disabled=not ready and (not _tech_ready(0,id) or not _has_producer(0,lane) or (not job.is_empty() and lane in ["build","defense"]))
 queue_redraw()

func _draw() -> void:
 super._draw()
 for field in ore_fields:
  if float(field["remaining"])<=0: continue
  var amount=float(field["remaining"])/maxf(1.0,float(field["initial"]))
  var pos: Vector2=field["position"]
  draw_circle(pos,30.0,Color("#65593d"))
  for i in range(9):
   var angle=float(i)*2.399
   var dist=6.0+float(i%3)*9.0
   draw_colored_polygon(PackedVector2Array([pos+Vector2.RIGHT.rotated(angle)*dist+Vector2(-9,7),pos+Vector2.RIGHT.rotated(angle)*dist+Vector2(0,-10),pos+Vector2.RIGHT.rotated(angle)*dist+Vector2(11,7)]),Color("#c9ae72").darkened(0.4*(1.0-amount)))
 if placement_lane!="" and states.size()>0:
  var job: Dictionary=states[0]["lanes"][placement_lane]
  if not job.is_empty():
   var pos=Vector2(roundf(get_global_mouse_position().x/24.0)*24.0,roundf(get_global_mouse_position().y/24.0)*24.0)
   var size: Vector2=STRUCTURE_DATA[str(job["id"])]["size"]
   draw_rect(Rect2(pos-size/2.0,size),Color(0.3,0.95,0.45,0.28) if can_place(pos,str(job["id"]),0) else Color(0.98,0.2,0.25,0.3))

