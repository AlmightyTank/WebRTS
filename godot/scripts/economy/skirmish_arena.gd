extends "res://scripts/combat/combat_arena.gd"
## Economic vertical slice: shared C&C-style production lanes over the existing combat renderer.
const StructureScript = preload("res://scripts/economy/structure.gd")
const EconomyVehicleScript = preload("res://scripts/economy/economy_vehicle.gd")
const RetroSkin = preload("res://scripts/ui/retro_skin.gd")
const RetroIcon = preload("res://scripts/ui/retro_icon.gd")
const RetroRadar = preload("res://scripts/ui/retro_radar.gd")
const STRUCTURE_DATA := {
 "power":{"name":"Power Plant","cost":800.0,"time":10.0,"power":150,"demand":0,"size":Vector2(104,94),"hp":1350},
 "refinery":{"name":"Ore Refinery (+ Harvester)","cost":2000.0,"time":24.0,"power":0,"demand":50,"size":Vector2(142,116),"hp":1350},
 "barracks":{"name":"Barracks","cost":500.0,"time":10.0,"power":0,"demand":10,"size":Vector2(102,96),"hp":1350},
 "factory":{"name":"War Factory","cost":2000.0,"time":26.0,"power":0,"demand":30,"size":Vector2(146,118),"hp":1700},
 "depot":{"name":"Service Depot","cost":850.0,"time":14.0,"power":0,"demand":25,"size":Vector2(118,100),"hp":1350},
 "relay":{"name":"Neutral Relay Outpost","cost":0.0,"time":0.0,"power":0,"demand":0,"size":Vector2(90,80),"hp":1200},
 "turret":{"name":"Sentry Turret","cost":550.0,"time":9.0,"power":0,"demand":10,"size":Vector2(66,66),"hp":1350},
 "beam_bastion":{"name":"Beam Bastion","cost":850.0,"time":14.0,"power":0,"demand":35,"size":Vector2(66,66),"hp":1350},
 "sam":{"name":"SAM Defense","cost":750.0,"time":12.0,"power":0,"demand":20,"size":Vector2(66,66),"hp":1100},
 "salvaged_aa":{"name":"Salvaged AA Platform","cost":650.0,"time":12.0,"power":0,"demand":15,"size":Vector2(66,66),"hp":1000},
 "missile_nest":{"name":"Missile Defense Nest","cost":800.0,"time":14.0,"power":0,"demand":20,"size":Vector2(66,66),"hp":1100},
 "foundry":{"name":"Heavy Foundry","cost":1600.0,"time":30.0,"power":0,"demand":35,"size":Vector2(130,110),"hp":1600},
 "vanguard_foundry":{"name":"Vanguard Foundry","cost":1600.0,"time":30.0,"power":0,"demand":35,"size":Vector2(130,110),"hp":1600},
 "silo":{"name":"Ballistic Missile Silo","cost":5000.0,"time":90.0,"power":0,"demand":100,"size":Vector2(110,100),"hp":1800}
}
const TABS := ["BUILDINGS","DEFENSE","INFANTRY","VEHICLES"]
const STAGING_IDS := ["ALPHA","BRAVO","CHARLIE"]
var structures: Array = []
var ore_fields: Array = []
var static_obstacles: Array[Rect2] = []
var states: Array = []
var current_tab := 0
var placement_lane := ""
var preview_pos := Vector2.ZERO
var action_buttons: Dictionary = {}
var build_container: GridContainer
var tab_buttons: Array = []
var title_text: Label
var details_text: Label
var hud_status := "Deploy your MCV (H), then build a Power Plant."
var economy_ai_timer := 0.0
var skirmish_time := 0.0
var ai_build_tick := 0
var cheat_test := false
var ai_vs_ai := false
var selected_building = null
var pending_sale = null
var repair_button: Button
var sell_button: Button
var refund_button: Button
var cancel_queue_button: Button
var sale_confirm_deadline := 0.0
var active_producers: Array = []
var rally_placing := false
var rally_source = null
var activate_producer_button: Button
var rally_button: Button
var rally_stage_selector: OptionButton
var rally_mode_button: Button
var staging_areas: Array = []
# UI references only; rally and production authority remain in the simulation.
var hud_top_panel: PanelContainer
var hud_dock: PanelContainer
var hud_toolbar: PanelContainer
var hud_scroll: ScrollContainer
var hud_build_column: VBoxContainer
var hud_toolbar_scroll: ScrollContainer
var sidebar_toggle: Button
var producer_summary: Label
var producer_list: VBoxContainer
var producer_buttons: Dictionary = {}
var producer_list_signature := ""
var stage_chips: Array = []
var stage_detail: Label
var compact_hud := false
var sidebar_open := true
var hud_layout_revision := 0
var radar_view: Control
var retro_economy_label: Label
var retro_powerbar: ProgressBar
var queue_preview_labels: Array = []
var queue_preview_caption: Label
var production_tile_icons: Dictionary = {}
var action_palette_buttons: Array = []

var fog_enabled := true
var fog
const ArmyRules = preload("res://scripts/economy/army_rules.gd")
var army_choices: Array = ["alliance", "republic"]
var commander = preload("res://scripts/economy/commander_system.gd").new()
var fog_timer := 0.0

func faction_style(side: int) -> int:
 if side < 0: return 2
 return {"alliance":0,"republic":1,"gia":2}[ArmyRules.faction(army_choices[side])]

func _load_balance() -> void:
 super._load_balance()
 for data in registry.get("specialist_units", []):
  if data.id in ["a_lance","a_lattice","r_jugger","r_imperator","r_armored_scout","g_siege_rocket","g_volley"]: roster[data.id] = data

func _spawn(id: String, side: int, point: Vector2):
 var unit
 if ArmyRules.PROFILES.has(id):
  unit = Node2D.new()
  unit.set_script(UnitScript)
  actors.add_child(unit)
  unit.configure(self, roster[id], side, point, ArmyRules.PROFILES[id], roster[id].armor == "AIR")
  unit.destroyed.connect(_on_destroyed)
  units.append(unit)
  invalidate_occupancy()
  unit.visible = entity_visible_to(0, unit)
 else:
  unit = super._spawn(id, side, point)
 if unit != null:
  ArmyRules.apply_unit(army_choices[side], unit)
  commander.prepare_unit(unit)
 return unit
var scouting = preload("res://scripts/combat/scouting.gd").new()

func entity_visible_to(side: int, entity) -> bool:
 if not is_instance_valid(entity): return false
 return not fog_enabled or fog == null or entity.team == side or fog.sees(side, entity.position)

func feedback_visible(point: Vector2) -> bool:
 return not fog_enabled or fog == null or fog.sees(0, point)

func _refresh_fog() -> void:
 if not fog_enabled: return
 if fog == null:
  fog = load("res://scripts/combat/fog_of_war.gd").new()
  add_child(fog)
  fog.reset(self)
 else:
  fog.refresh()

func _ai_decide() -> void:
 super._ai_decide()
 if ai_vs_ai: _ai_decide_side(0)
 if not fog_enabled or battle_over: return
 # Idle combat units explore using their team's knowledge, not enemy coordinates.
 for unit in units:
  if is_instance_valid(unit) and (unit.team == 1 or (ai_vs_ai and unit.team == 0)) and unit.hp > 0 and not unit.weapon.is_empty() and not unit.moving and unit.target == null:
   if not scouting.orders.has(unit): scouting.start(self, unit)

func _ready() -> void:
 army_choices = [ArmyRules.valid_choice(str(army_choices[0])), ArmyRules.valid_choice(str(army_choices[1]))]
 add_child(commander)
 commander.reset(self)
 super._ready()
 # reset_battle() captures immutable scenery on the first run.
 _rebuild_navigation()
 get_viewport().size_changed.connect(_on_hud_viewport_resized)
 _on_hud_viewport_resized()

func _new_state() -> Dictionary:
 return {"credits":10000.0,"total_mined":0.0,"total_spent":0.0,"total_refunded":0.0,"total_sales":0.0,"total_repairs":0.0,"power":0,"demand":0,"lanes":{"build":{},"defense":{},"infantry":{},"vehicle":{}},"queued":{"infantry":[],"vehicle":[]},"harvesters":0}

func reset_battle() -> void:
 commander.reset(self)
 if is_instance_valid(combat_feedback):
  combat_feedback.effects.clear()
  combat_feedback.queue_redraw()
 scouting.orders.clear()
 # Override the Combat Lab's scenario starting point; its four benchmark
 # scenes remain available as res://scenes/combat_lab.tscn.
 for u in units:
  if is_instance_valid(u): u.queue_free()
 for p in projectiles:
  if is_instance_valid(p): p.queue_free()
 for b in structures:
  if is_instance_valid(b): b.queue_free()
 units.clear()
 invalidate_occupancy()
 projectiles.clear()
 structures.clear()
 selected.clear()
 control_groups.clear()
 selected_building=null
 pending_sale=null
 sale_confirm_deadline=0.0
 rally_placing=false
 rally_source=null
 active_producers=[{"infantry":null,"vehicle":null},{"infantry":null,"vehicle":null}]
 staging_areas=[_new_staging_areas(),_new_staging_areas()]
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
 var ally=_spawn_economy(ArmyRules.economic_id(army_choices[0]),0,Vector2(310,620),false)
 _spawn_economy(ArmyRules.economic_id(army_choices[1]),1,Vector2(1600,610),false)
 # An AI follows the same construction/credit rules, but deploys its MCV immediately.
 _deploy_mcv(1)
 if ai_vs_ai: _deploy_mcv(0)
 # A capturable neutral structure provides a tactical expansion objective.
 _place_structure("relay",-1,Vector2(1080,225),0.0)
 if ally!=null and not ai_vs_ai:
  ally.selected=true
  selected=[ally]
 if is_instance_valid(result_text): result_text.text=""
 if fog_enabled:
  if fog != null: fog.reset(self)
  else: _refresh_fog()
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
 actor.visible=entity_visible_to(0,actor)
 actor.destroyed.connect(_on_destroyed)
 units.append(actor)
 invalidate_occupancy()
 return actor

func _deploy_mcv(side: int) -> bool:
 var mcv = null
 var expected_id=ArmyRules.economic_id(army_choices[side])
 # Deploy the currently selected MCV rather than an unrelated idle vehicle.
 if side==0:
  for unit in selected:
   if is_instance_valid(unit) and unit.team==side and unit.unit_id==expected_id and not unit.moving:
    mcv=unit
    break
 if mcv==null:
  for unit in units:
   if is_instance_valid(unit) and unit.team==side and unit.unit_id==expected_id and not unit.moving:
    mcv=unit
    break
 if mcv==null: return false
 if not can_place(mcv.position,"yard",side): return false
 var where: Vector2=mcv.position
 var paid_for_mcv: float=mcv.purchase_cost
 units.erase(mcv)
 invalidate_occupancy()
 selected.erase(mcv)
 mcv.queue_free()
 _place_structure("yard",side,where,paid_for_mcv)
 hud_status="Construction Yard deployed. Build power to begin." if side==0 else hud_status
 return true

func _place_structure(id: String, side: int, point: Vector2, paid_value: float=-1.0) -> bool:
 if side>=0 and id not in ["yard","relay"] and not id in ArmyRules.structure_ids(army_choices[side]): return false
 var size: Vector2=Vector2(155,135) if id=="yard" else STRUCTURE_DATA[id]["size"]
 var b=Node2D.new()
 b.set_script(StructureScript)
 actors.add_child(b)
 b.configure(self,id,side,point,size)
 if id!="yard":
  b.max_hp=float(STRUCTURE_DATA[id].hp)
  b.hp=b.max_hp
 b.visible=entity_visible_to(0,b)
 # An MCV-derived yard and map-authored neutral outpost never generate sell money.
 b.paid_value=0.0 if id=="relay" or (id=="yard" and paid_value<0.0) else (float(STRUCTURE_DATA[id]["cost"]) if paid_value<0.0 else paid_value)
 b.destroyed.connect(_building_destroyed)
 structures.append(b)
 if side>=0 and id in ["barracks","factory"]:
  b.rally_point=clamp_point(point+Vector2(0,240 if side==0 else -240))
  _set_active_producer(side,"infantry" if id=="barracks" else "vehicle",b)
 _rebuild_navigation()
 if side>=0: _calculate_power(side)
 if id=="refinery":
  var nearest=point+Vector2(0,135 if side==0 else -135)
  var spawn_site=_find_open_position(nearest,22.0)
  if spawn_site!=Vector2.ZERO:
   _spawn_economy(ArmyRules.economic_id(army_choices[side],true),side,spawn_site,true)
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
 if selected_building==building: selected_building=null
 if rally_source==building:
  rally_source=null
  rally_placing=false
 for side in range(active_producers.size()):
  for lane in ["infantry","vehicle"]:
   if active_producers[side][lane]==building: active_producers[side][lane]=null
 if pending_sale==building: pending_sale=null
 structures.erase(building)
 _rebuild_navigation()
 if building.team>=0: _calculate_power(building.team)
 _check_victory()

func _on_destroyed(unit) -> void:
 kills[1-unit.team]+=1
 selected.erase(unit)
 units.erase(unit)
 invalidate_occupancy()
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
   if is_instance_valid(actor) and actor.team==side and actor.unit_id in ["a_mcv","r_mcv","g_mcv"]: deployed_or_mobile=true
  if significant==0 and not deployed_or_mobile:
   battle_over=true
   if is_instance_valid(result_text): result_text.text="VICTORY — REPUBLIC DEFEATED" if side==1 else "DEFEAT — ALLIANCE LOST"
   return

func projectile_targets() -> Array:
 var targets=units.duplicate()
 targets.append_array(structures)
 return targets

func register_hit(source, victim, amount: float) -> void:
 super.register_hit(source,victim,amount)
 if victim.hp>0 or victim.has_meta("command_xp_awarded") or not is_instance_valid(source) or source.team<0 or source.team==victim.team or victim.team<0: return
 victim.set_meta("command_xp_awarded",true)
 var value:=100.0
 if victim.get("unit_id")!=null: value=maxf(40.0,float(roster.get(victim.unit_id,{}).get("credits",200.0))*0.25)
 commander.award_xp(source.team,value)
 if source.get("unit_xp")!=null: source.unit_xp+=50.0

func find_target(seeker, search_radius: float):
 var winner
 var best=INF
 for entity in projectile_targets():
  if not is_instance_valid(entity) or entity.hp<=0 or entity.team==seeker.team: continue
  if seeker.position.distance_squared_to(entity.position)>search_radius*search_radius: continue
  if not entity_visible_to(seeker.team,entity) or not seeker.can_hit(entity): continue
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
 states[side]["demand"]=demand+commander.extra_demand(side)

func has_structure(side: int, id: String) -> bool:
 for b in structures:
  if is_instance_valid(b) and b.hp>0 and b.team==side and b.kind==id: return true
 return false

# The active producer chooses the physical exit; all factories still boost one shared lane.
func _set_active_producer(side: int, lane: String, b) -> bool:
 if side<0 or side>=active_producers.size() or lane not in ["infantry","vehicle"]: return false
 var kind="barracks" if lane=="infantry" else "factory"
 if b==null or not is_instance_valid(b) or not structures.has(b) or b.hp<=0.0 or b.team!=side or b.kind!=kind: return false
 var old=active_producers[side][lane]
 active_producers[side][lane]=b
 if old!=null and is_instance_valid(old): old.queue_redraw()
 b.queue_redraw()
 queue_redraw()
 return true

func _active_producer(side: int, lane: String):
 if side<0 or side>=active_producers.size() or lane not in ["infantry","vehicle"]: return null
 var kind="barracks" if lane=="infantry" else "factory"
 var b=active_producers[side][lane]
 if b!=null and is_instance_valid(b) and structures.has(b) and b.hp>0.0 and b.team==side and b.kind==kind: return b
 active_producers[side][lane]=null
 for i in range(structures.size()-1,-1,-1):
  b=structures[i]
  if is_instance_valid(b) and b.hp>0.0 and b.team==side and b.kind==kind:
   active_producers[side][lane]=b
   return b
 return null

func set_producer_rally(side: int, lane: String, target: Vector2) -> bool:
 var b=_active_producer(side,lane)
 if b==null: return false
 var point=clamp_point(target)
 var cell=world_cell(point)
 if navigation.is_point_solid(cell):
  cell=_nearby_open_cell(cell)
  if navigation.is_point_solid(cell): return false
  point=cell_center(cell)
 b.rally_point=point
 b.rally_custom=true
 b.rally_stage_id=""
 b.rally_spawn_index=0
 queue_redraw()
 return true


# Player-owned staging areas are independent of the active production exit.
# Several barracks and factories may share a single area, but each producer
# retains its own move/attack-move behavior.
func _new_staging_areas() -> Dictionary:
 return {
  "ALPHA":{"position":Vector2.ZERO,"enabled":false,"next_slot":0},
  "BRAVO":{"position":Vector2.ZERO,"enabled":false,"next_slot":0},
  "CHARLIE":{"position":Vector2.ZERO,"enabled":false,"next_slot":0}
 }

func _valid_stage_point(target: Vector2) -> Vector2:
 var point=clamp_point(target)
 var cell=world_cell(point)
 if navigation.is_point_solid(cell):
  cell=_nearby_open_cell(cell)
  if navigation.is_point_solid(cell): return Vector2.ZERO
  point=cell_center(cell)
 return point

func set_staging_area(side: int, stage_id: String, target: Vector2) -> bool:
 if side<0 or side>=staging_areas.size() or stage_id not in STAGING_IDS: return false
 var point=_valid_stage_point(target)
 if point==Vector2.ZERO: return false
 var area: Dictionary=staging_areas[side][stage_id]
 area["position"]=point
 area["enabled"]=true
 area["next_slot"]=0
 queue_redraw()
 return true

func assign_producer_stage(side: int, b, stage_id: String) -> bool:
 if side<0 or side>=staging_areas.size(): return false
 if stage_id!="" and stage_id not in STAGING_IDS: return false
 var lane="infantry" if is_instance_valid(b) and b.kind=="barracks" else "vehicle"
 if not _set_active_producer(side,lane,b): return false
 if stage_id!="" and not bool(staging_areas[side][stage_id]["enabled"]):
  # First assignment starts at the producer's existing personal rally.
  if not set_staging_area(side,stage_id,b.rally_point): return false
 b.rally_stage_id=stage_id
 b.rally_spawn_index=0
 b.queue_redraw()
 queue_redraw()
 return true

func set_producer_attack_move(side: int, b, enabled: bool) -> bool:
 if b==null or not is_instance_valid(b) or b.team!=side or not structures.has(b) or b.kind not in ["barracks","factory"]: return false
 b.rally_attack_move=enabled
 queue_redraw()
 return true

func _producer_rally_point(side: int, b) -> Vector2:
 if b==null or not is_instance_valid(b): return Vector2.ZERO
 var stage_id: String=b.rally_stage_id
 if stage_id!="" and side>=0 and side<staging_areas.size() and stage_id in STAGING_IDS:
  var area: Dictionary=staging_areas[side][stage_id]
  if bool(area["enabled"]): return area["position"]
 return b.rally_point

func _set_producer_destination(side: int, b, target: Vector2) -> bool:
 if b==null or not is_instance_valid(b) or b.team!=side or b.kind not in ["barracks","factory"]: return false
 var lane="infantry" if b.kind=="barracks" else "vehicle"
 if not _set_active_producer(side,lane,b): return false
 if b.rally_stage_id!="": return set_staging_area(side,b.rally_stage_id,target)
 return set_producer_rally(side,lane,target)

func _rally_destination(side: int, b) -> Vector2:
 var center=_producer_rally_point(side,b)
 if center==Vector2.ZERO: return center
 # Personal rallies remain precise like Red Alert 2; only shared stage areas
 # distribute arriving units into multiple distinct tactical slots.
 if b.rally_stage_id=="": return center
 var area: Dictionary=staging_areas[side][b.rally_stage_id]
 if not bool(area["enabled"]): return center
 var index=int(area["next_slot"])
 area["next_slot"]=index+1
 # First unit uses exact rally; later arrivals spread into tactical staging slots.
 if index==0: return center
 var slot=(index-1)%35
 var row=slot/7
 var column=slot%7
 var spread=Vector2((float(column)-3.0)*34.0,(float(row)-2.0)*35.0)
 var result=_valid_stage_point(center+spread)
 return center if result==Vector2.ZERO else result

func _on_stage_selected(index: int) -> void:
 var b=_rally_candidate()
 if b==null: return
 var stage_id="" if index==0 else STAGING_IDS[index-1]
 if assign_producer_stage(0,b,stage_id):
  hud_status="Rally destination: "+("PERSONAL" if stage_id=="" else stage_id)+". Use G to reposition."
 else:
  hud_status="Cannot assign staging area."
 _update_hud()

func _toggle_rally_attack_move() -> void:
 var b=_rally_candidate()
 if b==null:
  hud_status="Select a Barracks or War Factory first."
 elif set_producer_attack_move(0,b,not b.rally_attack_move):
  hud_status="New combat units will "+("ATTACK-MOVE" if b.rally_attack_move else "MOVE")+" to their rally area."
 _update_hud()

func _rally_candidate():
 if selected_building!=null and is_instance_valid(selected_building) and selected_building.team==0 and selected_building.kind in ["barracks","factory"]:
  return selected_building
 if current_tab==2: return _active_producer(0,"infantry")
 if current_tab==3: return _active_producer(0,"vehicle")
 return null

func _begin_rally() -> void:
 var b=_rally_candidate()
 if b==null:
  hud_status="Select Barracks or War Factory to set rally."
 else:
  _set_active_producer(0,"infantry" if b.kind=="barracks" else "vehicle",b)
  rally_source=b
  rally_placing=true
  placement_lane=""
  hud_status="Click/tap a destination for this producer. Esc/right-click cancels."
 _update_hud()

func _set_rally_at(point: Vector2) -> bool:
 if not rally_placing or rally_source==null or not is_instance_valid(rally_source): return false
 var b=rally_source
 var lane="infantry" if b.kind=="barracks" else "vehicle"
 if not _set_active_producer(0,lane,b): return false
 if not _set_producer_destination(0,b,point): return false
 rally_placing=false
 rally_source=null
 hud_status="Rally point updated; new units will automatically move there."
 _update_hud()
 return true

func _activate_selected_producer() -> void:
 var b=selected_building
 if b!=null and is_instance_valid(b) and b.kind in ["barracks","factory"] and _set_active_producer(0,"infantry" if b.kind=="barracks" else "vehicle",b):
  hud_status="Active producer changed; existing rally point retained."
 else:
  hud_status="Select a friendly Barracks or War Factory first."
 _update_hud()

func _has_producer(side: int, lane: String) -> bool:
 if lane in ["build","defense"]: return has_structure(side,"yard")
 if lane=="infantry": return has_structure(side,"barracks")
 if lane=="vehicle": return has_structure(side,"factory")
 return false

func _tech_ready(side: int, id: String) -> bool:
 if STRUCTURE_DATA.has(id) and not id in ArmyRules.structure_ids(army_choices[side]): return false
 if roster.has(id):
  if not id in ArmyRules.roster_ids(army_choices[side]): return false
  var base=ArmyRules.base_id(id)
  if _lane_for(id)=="infantry":
   return has_structure(side,"barracks") and (has_structure(side,"refinery") if base in ["a_javelin","r_hunter","g_rocket_cell"] else true)
  if not has_structure(side,"factory"): return false
  if base in ["a_mcv","r_mcv","g_mcv","r_mammoth"]: return has_structure(side,"depot")
  if roster[id].armor=="AIR" or base in ["a_sentinel_aa","r_flak","g_rocket_truck"]: return has_structure(side,"power")
  return true
 match id:
  "power": return has_structure(side,"yard")
  "refinery","barracks": return has_structure(side,"power")
  "factory": return has_structure(side,"refinery") and has_structure(side,"barracks")
  "depot": return has_structure(side,"factory")
  "turret","beam_bastion","sam","salvaged_aa","missile_nest": return has_structure(side,"barracks")
  "foundry","vanguard_foundry": return has_structure(side,"factory") and has_structure(side,"depot")
  "silo": return has_structure(side,"factory") and has_structure(side,"depot")
  "a_ranger","r_line","a_engineer","r_engineer": return has_structure(side,"barracks")
  "a_javelin","r_hunter": return has_structure(side,"barracks") and has_structure(side,"refinery")
  "a_sentinel","r_bastion","a_harvester","r_hauler": return has_structure(side,"factory")
  "a_mcv","r_mcv": return has_structure(side,"factory") and has_structure(side,"depot")
  "a_sentinel_aa","r_flak": return has_structure(side,"factory") and has_structure(side,"power")
 return false

func _recipe(id: String, side: int = 0) -> Dictionary:
 if STRUCTURE_DATA.has(id): return STRUCTURE_DATA[id]
 if roster.has(id):
  return {"name":roster[id]["name"],"cost":float(roster[id]["credits"])*ArmyRules.cost_factor(army_choices[side],roster[id]),"time":float(roster[id]["build_seconds"])}
 return {}

func queue_production(side: int, lane: String, id: String) -> bool:
 if side<0 or side>=states.size() or not lane in ["build","defense","infantry","vehicle"]: return false
 if id=="relay" or _lane_for(id)!=lane or _recipe(id).is_empty(): return false
 if roster.has(id) and not id in ArmyRules.roster_ids(army_choices[side]): return false
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

func cancel_production(side: int, lane: String, queued_index: int=-1) -> bool:
 if side<0 or side>=states.size() or not lane in ["build","defense","infantry","vehicle"]: return false
 var state: Dictionary=states[side]
 if queued_index>=0:
  if lane not in ["infantry","vehicle"]: return false
  var queue: Array=state["queued"][lane]
  if queued_index>=queue.size(): return false
  queue.remove_at(queued_index) # Queued items have not been charged yet.
  return true
 var job: Dictionary=state["lanes"][lane]
 if job.is_empty(): return false
 var paid=maxf(0.0,float(job.get("paid",0.0)))
 state["credits"]=float(state["credits"])+paid
 state["total_refunded"]=float(state["total_refunded"])+paid
 state["total_spent"]=maxf(0.0,float(state["total_spent"])-paid)
 state["lanes"][lane]={}
 if side==0 and placement_lane==lane: placement_lane=""
 return true

func _production_time_multiplier(side: int, lane: String) -> float:
 # Each extra operational producer reduces time for this one SHARED lane.
 # Four or more producers cannot push completion below 55% of base time.
 var producer="yard" if lane in ["build","defense"] else ("barracks" if lane=="infantry" else "factory")
 var count=_building_count(side,producer)
 return maxf(0.55,pow(0.82,maxi(0,count-1)))

func _advance_repairs(delta: float) -> void:
 for b in structures:
  if not is_instance_valid(b) or b.hp<=0.0 or not b.repairing or b.hp>=b.max_hp: continue
  if b.team<0 or b.team>=states.size(): continue
  var state: Dictionary=states[b.team]
  var desired=minf(b.max_hp-b.hp,55.0*delta)
  var affordable=minf(desired,float(state["credits"])/0.45)
  if affordable<=0.0: continue
  var expense=affordable*0.45
  state["credits"]=float(state["credits"])-expense
  state["total_spent"]=float(state["total_spent"])+expense
  state["total_repairs"]=float(state["total_repairs"])+expense
  b.hp=minf(b.max_hp,b.hp+affordable)
  if b.hp>=b.max_hp: b.repairing=false
  b.queue_redraw()

func sell_structure(side: int, b) -> bool:
 if b==null or not is_instance_valid(b) or b.team!=side or b.hp<=0.0 or not structures.has(b): return false
 var payout=floorf(maxf(0.0,b.paid_value)*0.5)
 var state: Dictionary=states[side]
 state["credits"]=float(state["credits"])+payout
 state["total_sales"]=float(state["total_sales"])+payout
 b.repairing=false
 _building_destroyed(b)
 b.queue_free()
 # Refinery sales retain their *existing* harvester; they never spawn another.
 return true

func capture_structure(engineer, b) -> bool:
 if engineer==null or b==null or not is_instance_valid(engineer) or not is_instance_valid(b): return false
 if not units.has(engineer) or not structures.has(b) or b.hp<=0.0: return false
 if not ArmyRules.engineer(engineer.unit_id) or engineer.team==b.team: return false
 var old_owner: int=b.team
 b.team=engineer.team
 if b.kind in ["barracks","factory"]:
  # Captured producers become independent of the previous owner's staging areas.
  b.rally_point=clamp_point(b.position+Vector2(0,240 if b.team==0 else -240))
  b.rally_stage_id=""
  b.rally_attack_move=false
  b.rally_spawn_index=0
  _set_active_producer(b.team,"infantry" if b.kind=="barracks" else "vehicle",b)
 b.name=("Alliance" if b.team==0 else "Republic")+"_"+b.kind
 b.repairing=false
 b.selected=false
 b.queue_redraw()
 _calculate_power(engineer.team)
 if old_owner>=0: _calculate_power(old_owner)
 # No free harvester on capture; the bundled harvester is granted only on fresh construction.
 selected.erase(engineer)
 units.erase(engineer)
 invalidate_occupancy()
 engineer.queue_free()
 hud_status="Captured "+str(STRUCTURE_DATA[b.kind]["name"]) if b.team==0 else hud_status
 _check_victory()
 return true

func capture_approach(b, from: Vector2) -> Vector2:
 var bounds: Rect2=b.ground_bounds()
 var candidates: Array[Vector2]=[]
 var midpoint=b.position
 for offset in [Vector2(-1,0),Vector2(1,0),Vector2(0,-1),Vector2(0,1)]:
  var dist=(bounds.size.x if absf(offset.x)>0 else bounds.size.y)*0.5+35.0
  var point=midpoint+offset*dist
  if can_occupy(point,9.0,false): candidates.append(point)
 if candidates.is_empty(): return from
 candidates.sort_custom(func(a,bp): return from.distance_squared_to(a)<from.distance_squared_to(bp))
 return candidates[0]

func _tick_production(side: int, delta: float) -> void:
 var lanes: Dictionary=states[side]["lanes"]
 for lane in ["build","defense","infantry","vehicle"]:
  var job: Dictionary=lanes[lane]
  if not job.is_empty() and str(job.id) not in ArmyRules.roster_ids(army_choices[side]) and str(job.id) not in ArmyRules.structure_ids(army_choices[side]):
   states[side].credits+=float(job.get("paid",0.0))
   states[side].total_spent-=float(job.get("paid",0.0))
   lanes[lane]={}
   continue
  if job.is_empty():
   var waiting: Array=states[side]["queued"].get(lane,[])
   if not waiting.is_empty() and _has_producer(side,lane):
    lanes[lane]={"id":waiting.pop_front(),"paid":0.0,"ready":false}
   continue
  if bool(job.get("ready",false)):
   if lane in ["infantry","vehicle"]:
    if _has_producer(side,lane) and _produce_unit(side,str(job["id"])): lanes[lane]={}
   elif side==1 or ai_vs_ai: _ai_place_ready(lane,str(job["id"]),side)
   continue
  if not _has_producer(side,lane): continue
  var recipe=_recipe(str(job["id"]),side)
  if recipe.is_empty(): continue
  var cost=float(recipe["cost"])
  var duration=maxf(0.25,float(recipe["time"]))
  var speed=_power_speed(side,lane)
  var speed_multiplier=speed/_production_time_multiplier(side,lane)
  var target_spend=cost/duration*delta*speed_multiplier if cost>0.0 else 0.0
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
 if not id in ArmyRules.roster_ids(army_choices[side]): return false
 var lane=_lane_for(id)
 var producer=_active_producer(side,lane)
 if producer==null: return false
 # A blocked active exit stalls READY production, never secretly uses another factory.
 var offset=Vector2(0,125) if side==0 else Vector2(0,-125)
 if lane=="infantry":
  offset=_infantry_exit_offset(side,producer)
 var where=_find_open_position(producer.position+offset,20.0)
 if where==Vector2.ZERO: return false
 var unit=null
 if ArmyRules.economic(id):
  unit=_spawn_economy(id,side,where,id in ["a_harvester","r_hauler","g_collector"])
  if unit!=null and id in ["a_mcv","r_mcv","g_mcv"]: unit.purchase_cost=float(_recipe(id,side)["cost"])
 elif ArmyRules.engineer(id):
  unit=_spawn_engineer(id,side,where)
 else:
  unit=_spawn(id,side,where)
 if unit==null: return false
 producer.notify_unit_exit()
 var waypoint=_rally_destination(side,producer)
 if waypoint!=Vector2.ZERO:
  if unit.has_method("order_rally"): unit.order_rally(waypoint)
  elif unit.has_method("order_move"):
   var military=not ArmyRules.engineer(id)
   unit.order_move(waypoint,producer.rally_attack_move and military)
 return true

func _infantry_exit_offset(side: int, producer) -> Vector2:
 var art = preload("res://scripts/ui/industrial_art.gd")
 var exit: Vector2 = art.building_exit(producer.art_style)
 # Clear the footprint before spawning; retain the door's horizontal alignment.
 return Vector2(exit.x,maxf(exit.y,producer.footprint.y*0.5+30.0))

func _spawn_engineer(id: String, side: int, where: Vector2):
 # The engineer uses the same combat-unit steering/selection, but cannot attack.
 var data: Dictionary=roster[id]
 var u=Node2D.new()
 u.set_script(UnitScript)
 actors.add_child(u)
 u.configure(self,data,side,where,{"type":"UNARMED","damage":0.0,"interval":1.0,"range":0.0,"anti_ground":false})
 u.destroyed.connect(_on_destroyed)
 units.append(u)
 invalidate_occupancy()
 return u

func _ai_place_ready(lane: String, id: String, side: int = 1) -> void:
 var sites=[Vector2(-235,-205),Vector2(-225,-10),Vector2(-225,190),Vector2(80,-225),Vector2(200,15),Vector2(170,195),Vector2(-400,110),Vector2(40,360),Vector2(-400,-230),Vector2(340,-250)]
 for offset in sites:
  var place=(Vector2(1600,610)+offset) if side==1 else (Vector2(310,620)+Vector2(-offset.x,offset.y))
  place=Vector2(roundf(place.x/24.0)*24.0,roundf(place.y/24.0)*24.0)
  if can_place(place,id,side):
   _place_structure(id,side,place)
   states[side]["lanes"][lane]={}
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
   if not (id=="yard" and u.unit_id in ["a_mcv","r_mcv","g_mcv"] and u.team==side and u.position.distance_to(point)<3.0): return false
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

func _ai_economy(side: int = 1) -> void:
 commander.ai_tick(side)
 # The opponent pays actual costs, obeys prerequisites, and receives ore only
 # when its harvester physically unloads; no hidden AI resource grants.
 var state: Dictionary=states[side]
 if not has_structure(side,"yard"): _deploy_mcv(side)
 if state.lanes.build.is_empty() and not power_ok(side):
  queue_production(side,"build","power")
 # Replace lost collectors before buying another combat vehicle. Avoid filling
 # the paid FIFO with speculative orders that compete with economic recovery.
 var collector_id: String = ArmyRules.economic_id(army_choices[side],true)
 var has_collector: bool = units.any(func(u): return is_instance_valid(u) and u.hp>0 and u.team==side and u.unit_id==collector_id)
 if not has_collector and has_structure(side,"refinery") and has_structure(side,"factory"):
  if state.lanes.vehicle.is_empty(): queue_production(side,"vehicle",collector_id)
  return
 if state["lanes"]["build"].is_empty():
  for id in ["power","refinery","barracks","factory"]:
   if not has_structure(side,id) and _tech_ready(side,id):
    queue_production(side,"build",id)
    break
  if has_structure(side,"factory") and not has_structure(side,"depot") and float(state["credits"])>1700.0:
   queue_production(side,"build","depot")
  elif has_structure(side,"factory") and float(state["credits"])>4000.0 and ai_build_tick%6==0:
   queue_production(side,"build","factory" if _building_count(side,"factory")<2 else "power")
 if state["lanes"]["defense"].is_empty() and has_structure(side,"barracks") and ai_build_tick%5==0:
  var defense_id: String=ArmyRules.REPLACEMENTS.get(army_choices[side],{}).get("turret","turret")
  if _building_count(side,defense_id)<2: queue_production(side,"defense",defense_id)
 if has_structure(side,"barracks") and state.lanes.infantry.is_empty() and float(state["credits"])>800.0 and ai_build_tick%2==0:
   var ids=ArmyRules.roster_ids(army_choices[side])
   queue_production(side,"infantry",ids[1] if has_structure(side,"refinery") and ai_build_tick%4==0 else ids[0])
 if has_structure(side,"factory") and state.lanes.vehicle.is_empty() and float(state["credits"])>1700.0:
  if not has_structure(side,"yard") and has_structure(side,"depot"):
   queue_production(side,"vehicle",ArmyRules.economic_id(army_choices[side]))
  else:
   var options=ArmyRules.roster_ids(army_choices[side]).filter(func(id): return _lane_for(id)=="vehicle" and not ArmyRules.economic(id) and _tech_ready(side,id))
   if not options.is_empty(): queue_production(side,"vehicle",options[ai_build_tick%options.size()])
 if state.lanes.build.is_empty() and float(state.credits)>2500:
  for id in ArmyRules.structure_ids(army_choices[side]):
   if id in ["vanguard_foundry","silo"] and not has_structure(side,id) and _tech_ready(side,id):
    queue_production(side,"build",id)
    break

func _building_count(side: int, id: String) -> int:
 var count=0
 for b in structures:
  if is_instance_valid(b) and b.team==side and b.kind==id and b.hp>0: count+=1
 return count

func _physics_process(delta: float) -> void:
 fog_timer -= delta
 if fog_timer <= 0.0:
  fog_timer = 0.15
  _refresh_fog()
  if not paused and not battle_over: scouting.tick(self)
 super._physics_process(delta)
 if paused or battle_over: return
 skirmish_time+=delta
 commander.tick(delta)
 _tick_production(0,delta)
 _tick_production(1,delta)
 _advance_repairs(delta)
 economy_ai_timer-=delta
 if economy_ai_timer<=0:
  economy_ai_timer=2.1
  _ai_economy()
  if ai_vs_ai: _ai_economy(0)
  ai_build_tick+=1

func _unhandled_input(event: InputEvent) -> void:
 if commander.pending_power!="":
  if (event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE) or (event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_RIGHT):
   commander.pending_power=""
   get_viewport().set_input_as_handled()
   return
  var picked:=false
  var point:=Vector2.ZERO
  if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:
   point=_screen_to_world(event.position)
   picked=true
  elif event is InputEventScreenTouch and event.pressed and event.index==0:
   point=_screen_to_world(event.position)
   picked=true
  if picked:
   var ok: bool=commander.launch_silo(0,point) if commander.pending_power=="silo" else commander.cast(0,commander.pending_power,point)
   if ok: commander.pending_power=""
   hud_status="Support ordered." if ok else "Invalid target, locked power or cooldown. Choose another location."
   get_viewport().set_input_as_handled()
   return
  return
 if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_G and not rally_placing and selected.any(func(unit): return is_instance_valid(unit) and unit.get("order_revision") != null):
  _on_toolbar("SCOUT")
  get_viewport().set_input_as_handled()
  return
 if rally_placing:
  if event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE:
   rally_placing=false
   rally_source=null
   hud_status="Rally placement canceled."
   _update_hud()
   get_viewport().set_input_as_handled()
   return
  if event is InputEventMouseButton and event.pressed:
   if event.button_index==MOUSE_BUTTON_RIGHT:
    rally_placing=false
    rally_source=null
    hud_status="Rally placement canceled."
   elif event.button_index==MOUSE_BUTTON_LEFT:
    _set_rally_at(_screen_to_world(event.position))
   else: return
   _update_hud()
   get_viewport().set_input_as_handled()
   return
  if event is InputEventScreenTouch and event.index==0 and not event.pressed and not touch_dragged:
   _set_rally_at(_screen_to_world(event.position))
   get_viewport().set_input_as_handled()
   return
 if placement_lane=="" and event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_RIGHT and event.pressed:
  if selected.is_empty() and selected_building!=null and is_instance_valid(selected_building) and selected_building.kind in ["barracks","factory"]:
   var b=selected_building
   var lane="infantry" if b.kind=="barracks" else "vehicle"
   if _set_producer_destination(0,b,_screen_to_world(event.position)):
    hud_status="Updated the selected producer rally."
    _update_hud()
    get_viewport().set_input_as_handled()
    return
 if placement_lane=="" and mode=="MOVE" and event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.pressed:
  var picked=_hit_building(_screen_to_world(event.position),0)
  _select_building(picked)
  if picked!=null:
   get_viewport().set_input_as_handled()
   return
 if placement_lane=="" and event is InputEventScreenTouch and not event.pressed and event.index==0 and not touch_dragged:
  var picked=_hit_building(_screen_to_world(event.position),0)
  if picked!=null:
   _select_building(picked)
   get_viewport().set_input_as_handled()
   return
 if event is InputEventKey and event.pressed and not event.echo:
  if _control_group_key(event):
   get_viewport().set_input_as_handled()
   return
  if event.keycode==KEY_T:
   _toggle_rally_attack_move()
   get_viewport().set_input_as_handled()
   return
  if event.keycode==KEY_G:
   _begin_rally()
   get_viewport().set_input_as_handled()
   return
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
  _place_player_ready(_screen_to_world(event.position))
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

func _hit_building(point: Vector2, side: int=-2):
 for b in structures:
  if is_instance_valid(b) and b.hp>0 and entity_visible_to(0, b) and (side==-2 or b.team==side) and b.ground_bounds().grow(8).has_point(point): return b
 return null

func _select_building(b) -> void:
 if selected_building!=null and is_instance_valid(selected_building):
  selected_building.selected=false
  selected_building.queue_redraw()
 selected_building=b
 pending_sale=null
 if b!=null and is_instance_valid(b) and b.team==0 and b.kind in ["barracks","factory"]:
  _set_active_producer(0,"infantry" if b.kind=="barracks" else "vehicle",b)
  _set_selected([])
 if b!=null and is_instance_valid(b):
  b.selected=true
  b.queue_redraw()
 _update_hud()

func issue_order(point: Vector2, attack_move: bool=false, queued: bool=false) -> void:
 var capture_target=_hit_building(point,-2)
 if capture_target!=null and capture_target.team!=0:
  var assigned=false
  for u in selected:
   if is_instance_valid(u) and ArmyRules.engineer(u.unit_id):
    u.order_capture(capture_target)
    assigned=true
  if assigned: return
 var enemy_building
 for b in structures:
  if is_instance_valid(b) and b.team==1 and entity_visible_to(0, b) and b.ground_bounds().grow(8).has_point(point): enemy_building=b; break
 if enemy_building!=null:
  for u in selected:
   if is_instance_valid(u) and u.can_hit(enemy_building): u.order_attack(enemy_building)
  return
 super.issue_order(point,attack_move,queued)

# Godot 4 canvas-items stretch uses visible viewport coordinates on desktop
# and Android. Keep a single geometry contract for landscape and portrait.
func _hud_layout_for_size(view_size: Vector2, expanded: bool=true) -> Dictionary:
 var w=maxf(320.0,view_size.x)
 var h=maxf(280.0,view_size.y)
 var compact=w<980.0 or h<590.0
 var edge=clampf(minf(w,h)*0.025,6.0,12.0)
 var top_height=clampf(h*0.11,34.0,64.0)
 var toolbar_height=clampf(h*0.16,48.0,80.0)
 if compact:
  var expanded_height=minf(320.0,maxf(144.0,h*0.46))
  var drawer_height=expanded_height if expanded else 48.0
  return {
   "compact":true,
   "top":Rect2(edge,edge,w-edge*2.0,top_height),
   "toolbar":Rect2(edge,h-toolbar_height-edge,w-edge*2.0,toolbar_height),
   "dock":Rect2(edge,h-toolbar_height-drawer_height-edge*2.0,w-edge*2.0,drawer_height)
  }
 var dock_width=clampf(w*0.20,220.0,300.0)
 var play_width=w-dock_width-edge*3.0
 return {
  "compact":false,
  "top":Rect2(edge,edge,play_width,top_height),
  "toolbar":Rect2(edge,h-toolbar_height-edge,play_width,toolbar_height),
  "dock":Rect2(w-dock_width-edge,edge,dock_width,h-edge*2.0)
 }

func _set_control_rect(node: Control, bounds: Rect2) -> void:
 node.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
 node.position=bounds.position
 node.size=bounds.size

func _apply_hud_layout(view_size: Vector2) -> void:
 if not is_instance_valid(hud_dock): return
 var layout=_hud_layout_for_size(view_size,sidebar_open)
 compact_hud=bool(layout["compact"])
 if not compact_hud: sidebar_open=true
 layout=_hud_layout_for_size(view_size,sidebar_open)
 _set_control_rect(hud_top_panel,layout["top"])
 _set_control_rect(hud_toolbar,layout["toolbar"])
 _set_control_rect(hud_dock,layout["dock"])
 if is_instance_valid(sidebar_toggle):
  sidebar_toggle.text=("PRODUCTION  ▲  COLLAPSE" if sidebar_open else "PRODUCTION  ▼  OPEN") if compact_hud else "PRODUCTION / ACTIVE FACTORIES"
  sidebar_toggle.disabled=not compact_hud
 if is_instance_valid(producer_summary):
  producer_summary.visible=sidebar_open
 if is_instance_valid(hud_scroll):
  hud_scroll.visible=sidebar_open
  hud_scroll.custom_minimum_size=Vector2.ZERO
  if is_instance_valid(hud_build_column):
   hud_build_column.custom_minimum_size=Vector2.ZERO
 if is_instance_valid(radar_view):
  radar_view.custom_minimum_size=Vector2(0,82 if compact_hud else 108)
 for chip in stage_chips:
  chip.custom_minimum_size.y=44.0 if compact_hud else 27.0
 for tab in tab_buttons:
  tab.custom_minimum_size.y=44.0 if compact_hud else 27.0
 if is_instance_valid(rally_stage_selector):
  rally_stage_selector.visible=not compact_hud
 if is_instance_valid(activate_producer_button):
  activate_producer_button.visible=not compact_hud
 if is_instance_valid(hud_text): hud_text.clip_text=true
 if is_instance_valid(info_text): info_text.clip_text=true
 hud_layout_revision+=1

func _on_hud_viewport_resized() -> void:
 var is_compact=_hud_layout_for_size(get_viewport_rect().size,true)["compact"]
 if is_compact and not compact_hud: sidebar_open=false
 _apply_hud_layout(get_viewport_rect().size)

func _toggle_sidebar() -> void:
 if not compact_hud: return
 sidebar_open=not sidebar_open
 _apply_hud_layout(get_viewport_rect().size)
 _update_hud()

func _producer_snapshot(side: int) -> Array:
 var result: Array=[]
 for lane in ["infantry","vehicle"]:
  var label="BARRACKS" if lane=="infantry" else "WAR FACTORY"
  var ordinal=0
  for b in structures:
   if not is_instance_valid(b) or b.hp<=0.0 or b.team!=side or b.kind!=("barracks" if lane=="infantry" else "factory"): continue
   ordinal+=1
   var active=b==_active_producer(side,lane)
   result.append({
    "building":b,"lane":lane,"ordinal":ordinal,"type":label,
    "active":active,"stage":"PERSONAL" if b.rally_stage_id=="" else b.rally_stage_id,
    "mode":"ATTACK-MOVE" if b.rally_attack_move else "MOVE",
    "point":_producer_rally_point(side,b)
   })
 return result

func _on_producer_card_pressed(b) -> void:
 if b==null or not is_instance_valid(b) or not structures.has(b) or b.team!=0: return
 _select_building(b)
 hud_status="ACTIVE: "+("Barracks" if b.kind=="barracks" else "War Factory")+". Change stage or rally mode below."
 _update_hud()

func _refresh_producer_cards() -> void:
 if not is_instance_valid(producer_list): return
 var snapshot=_producer_snapshot(0)
 var signature=""
 for item in snapshot: signature+=str(item["building"].get_instance_id())+";"
 if signature!=producer_list_signature:
  producer_list_signature=signature
  for child in producer_list.get_children():
   producer_list.remove_child(child)
   child.queue_free()
  producer_buttons.clear()
  if snapshot.is_empty():
   var empty=Label.new()
   empty.text="Build a Barracks or War Factory to select its production exit."
   empty.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
   producer_list.add_child(empty)
  for item in snapshot:
   var b=item["building"]
   var button=Button.new()
   button.name="Producer_"+str(b.get_instance_id())
   button.toggle_mode=true
   button.custom_minimum_size=Vector2(240,52)
   button.pressed.connect(_on_producer_card_pressed.bind(b))
   RetroSkin.button(button)
   producer_list.add_child(button)
   producer_buttons[b.get_instance_id()]=button
 for item in snapshot:
  var b=item["building"]
  var card: Button=producer_buttons.get(b.get_instance_id())
  if card==null: continue
  var point: Vector2=item["point"]
  card.text=("%s %s #%d  ·  %s\n%s  •  %d, %d" % [
   "● ACTIVE" if item["active"] else "○ SELECT",
   item["type"],item["ordinal"],item["mode"],item["stage"],int(point.x),int(point.y)
  ])
  card.button_pressed=bool(item["active"])
  card.tooltip_text="Tap to use this building as the "+str(item["lane"])+" spawn exit. Stage and rally settings belong to this building."
  card.add_theme_color_override("font_color",Color("#c8f5dd") if item["active"] else Color("#ced5df"))
  card.add_theme_stylebox_override("normal",RetroSkin.tile("active" if item["active"] else "normal"))
 if is_instance_valid(producer_summary):
  var infantry_summary="INF —"
  var vehicle_summary="VEH —"
  for item in snapshot:
   if not item["active"]: continue
   var short_stage="PERS" if item["stage"]=="PERSONAL" else item["stage"]
   var summary=("#%d %s%s" % [int(item["ordinal"]),short_stage," ATK" if item["mode"]=="ATTACK-MOVE" else ""])
   if item["lane"]=="infantry": infantry_summary="INF "+summary
   else: vehicle_summary="VEH "+summary
  producer_summary.text=infantry_summary+"  |  "+vehicle_summary
  producer_summary.clip_text=true
  producer_summary.tooltip_text="Active production destinations. Tap producer cards to switch the spawn exit."

func _refresh_staging_chips(source) -> void:
 for i in range(stage_chips.size()):
  var chip: Button=stage_chips[i]
  chip.disabled=source==null
  chip.button_pressed=source!=null and (source.rally_stage_id==("" if i==0 else STAGING_IDS[i-1]))
 if not is_instance_valid(stage_detail): return
 if source==null:
  stage_detail.text="Select a producer to choose Personal / Alpha / Bravo / Charlie."
  return
 var label="PERSONAL" if source.rally_stage_id=="" else source.rally_stage_id
 var pt=_producer_rally_point(0,source)
 stage_detail.text="%s  ·  %s  ·  (%d, %d)" % [label,"ATTACK-MOVE" if source.rally_attack_move else "MOVE",int(pt.x),int(pt.y)]

func _create_hud() -> void:
 hud=CanvasLayer.new()
 add_child(hud)
 var root=Control.new()
 root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 root.mouse_filter=Control.MOUSE_FILTER_IGNORE
 hud.add_child(root)
 var top=PanelContainer.new()
 top.mouse_filter=Control.MOUSE_FILTER_STOP
 root.add_child(top)
 hud_top_panel=top
 var stats=VBoxContainer.new()
 stats.add_theme_constant_override("separation",1)
 top.add_child(stats)
 title_text=Label.new()
 title_text.text="MERIDIAN WARFRONT"
 title_text.add_theme_font_size_override("font_size",11)
 title_text.clip_text=true
 stats.add_child(title_text)
 hud_text=Label.new()
 hud_text.clip_text=true
 stats.add_child(hud_text)
 info_text=Label.new()
 info_text.clip_text=true
 stats.add_child(info_text)

 var dock=PanelContainer.new()
 dock.mouse_filter=Control.MOUSE_FILTER_STOP
 root.add_child(dock)
 hud_dock=dock
 var dock_stack=VBoxContainer.new()
 dock.add_child(dock_stack)
 sidebar_toggle=Button.new()
 sidebar_toggle.text="PRODUCTION / ACTIVE FACTORIES"
 sidebar_toggle.custom_minimum_size=Vector2(0,28)
 sidebar_toggle.pressed.connect(_toggle_sidebar)
 dock_stack.add_child(sidebar_toggle)
 producer_summary=Label.new()
 producer_summary.text="INF —  |  VEH —"
 producer_summary.add_theme_font_size_override("font_size",8)
 producer_summary.clip_text=true
 dock_stack.add_child(producer_summary)
 var scroll=ScrollContainer.new()
 scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
 scroll.vertical_scroll_mode=ScrollContainer.SCROLL_MODE_AUTO
 scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
 scroll.follow_focus=true
 dock_stack.add_child(scroll)
 hud_scroll=scroll
 var column=VBoxContainer.new()
 column.custom_minimum_size=Vector2(0,0)
 scroll.add_child(column)
 hud_build_column=column
 var badge=HBoxContainer.new()
 column.add_child(badge)
 var crest=Control.new()
 crest.set_script(RetroIcon)
 crest.custom_minimum_size=Vector2(28,28)
 badge.add_child(crest)
 crest.configure("EMBLEM")
 var faction=Label.new()
 faction.text=str(ArmyRules.CHOICES[army_choices[0]].name).to_upper()
 badge.add_child(faction)
 RetroSkin.label(faction,false,true)
 radar_view=Control.new()
 radar_view.set_script(RetroRadar)
 radar_view.custom_minimum_size=Vector2(0,108)
 column.add_child(radar_view)
 radar_view.configure(self)
 retro_economy_label=Label.new()
 retro_economy_label.text="CREDITS 010000  ·  POWER 0 / 0"
 column.add_child(retro_economy_label)
 RetroSkin.label(retro_economy_label,false,true)
 retro_powerbar=ProgressBar.new()
 retro_powerbar.custom_minimum_size=Vector2(0,7)
 retro_powerbar.show_percentage=false
 retro_powerbar.max_value=100.0
 retro_powerbar.value=100.0
 retro_powerbar.add_theme_stylebox_override("background",RetroSkin.tile("disabled"))
 retro_powerbar.add_theme_stylebox_override("fill",RetroSkin.tile("active"))
 column.add_child(retro_powerbar)
 var section=HSeparator.new()
 column.add_child(section)
 var command_toggle=Button.new()
 command_toggle.text="COMMAND / RESEARCH"
 command_toggle.toggle_mode=true
 command_toggle.custom_minimum_size.y=34
 RetroSkin.button(command_toggle)
 column.add_child(command_toggle)
 var command_panel=VBoxContainer.new()
 column.add_child(command_panel)
 commander.build_ui(command_panel)
 command_panel.visible=false
 command_toggle.toggled.connect(func(open: bool): command_panel.visible=open)
 command_toggle.visible=not commander.power_ids(0).is_empty() or ArmyRules.faction(army_choices[0])=="gia"
 var tab_header=Label.new()
 tab_header.text="PRODUCTION QUEUES"
 column.add_child(tab_header)
 var tabs=HBoxContainer.new()
 column.add_child(tabs)
 for i in range(4):
  var tab=Button.new()
  tab.text=["BUILD","DEF","INF","VEH"][i]
  tab.toggle_mode=true
  tab.custom_minimum_size=Vector2(0,27)
  tab.size_flags_horizontal=Control.SIZE_EXPAND_FILL
  tab.pressed.connect(_set_tab.bind(i))
  RetroSkin.button(tab,i==0,true)
  tabs.add_child(tab)
  tab_buttons.append(tab)
 build_container=GridContainer.new()
 build_container.columns=2
 build_container.add_theme_constant_override("h_separation",6)
 build_container.add_theme_constant_override("v_separation",6)
 column.add_child(build_container)
 for id in ArmyRules.structure_ids(army_choices[0]) + ArmyRules.roster_ids(army_choices[0]):
  var button=Button.new()
  button.text=id
  button.custom_minimum_size=Vector2(0,76)
  button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
  button.pressed.connect(_on_build_button.bind(id))
  RetroSkin.button(button)
  build_container.add_child(button)
  var icon=Control.new()
  icon.set_script(RetroIcon)
  icon.anchor_left=0.5
  icon.anchor_right=0.5
  icon.position=Vector2(-24,2)
  icon.size=Vector2(48,35)
  button.add_child(icon)
  icon.configure(id,0,faction_style(0))
  production_tile_icons[id]=icon
  action_buttons[id]=button
 var header=Label.new()
 header.text="SPAWN EXIT  ·  TAP TO ACTIVATE"
 header.add_theme_font_size_override("font_size",9)
 column.add_child(header)
 producer_list=VBoxContainer.new()
 column.add_child(producer_list)
 var stage_header=Label.new()
 stage_header.text="SEND NEW UNITS TO"
 stage_header.add_theme_font_size_override("font_size",13)
 column.add_child(stage_header)
 var stage_row=HBoxContainer.new()
 column.add_child(stage_row)
 for i in range(4):
  var chip=Button.new()
  chip.text=["SELF","ALPHA","BRAVO","CHARLIE"][i]
  chip.toggle_mode=true
  chip.custom_minimum_size=Vector2(0,27)
  chip.size_flags_horizontal=Control.SIZE_EXPAND_FILL
  chip.pressed.connect(_on_stage_selected.bind(i))
  RetroSkin.button(chip,false,true)
  stage_row.add_child(chip)
  stage_chips.append(chip)
 stage_detail=Label.new()
 stage_detail.text="Select a producer to assign a destination."
 stage_detail.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 column.add_child(stage_detail)

 var rally_row=HBoxContainer.new()
 column.add_child(rally_row)
 var rally=Button.new()
 rally.text="SET DESTINATION (G)"
 rally.custom_minimum_size=Vector2(0,28)
 rally.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 rally.pressed.connect(_begin_rally)
 rally_row.add_child(rally)
 rally_button=rally
 var mode_button=Button.new()
 mode_button.text="MOVE / ATTACK (T)"
 mode_button.custom_minimum_size=Vector2(0,28)
 mode_button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 mode_button.pressed.connect(_toggle_rally_attack_move)
 rally_row.add_child(mode_button)
 rally_mode_button=mode_button

 var stage=OptionButton.new()
 stage.name="RallyDestinationSelector"
 stage.custom_minimum_size=Vector2(0,27)
 stage.add_item("Personal rally",0)
 for i in range(STAGING_IDS.size()):
  stage.add_item("Stage "+STAGING_IDS[i],i+1)
 stage.item_selected.connect(_on_stage_selected)
 # Keep the desktop dropdown as an accessible alternative to the quick chips.
 column.add_child(stage)
 rally_stage_selector=stage
 var activate=Button.new()
 activate.text="ACTIVATE SELECTED PRODUCTION BUILDING"
 activate.custom_minimum_size=Vector2(0,28)
 activate.pressed.connect(_activate_selected_producer)
 column.add_child(activate)
 activate_producer_button=activate

 var queue_header=Label.new()
 queue_header.text="QUEUE / PRODUCTION STATUS"
 RetroSkin.label(queue_header,true,true)
 column.add_child(queue_header)
 queue_preview_caption=Label.new()
 queue_preview_caption.text="Select a production tab"
 RetroSkin.label(queue_preview_caption,true)
 column.add_child(queue_preview_caption)
 var queue_row=HBoxContainer.new()
 column.add_child(queue_row)
 for q in range(4):
  var slot=Label.new()
  slot.custom_minimum_size=Vector2(0,26)
  slot.size_flags_horizontal=Control.SIZE_EXPAND_FILL
  slot.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
  slot.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
  slot.add_theme_stylebox_override("normal",RetroSkin.tile("disabled"))
  RetroSkin.label(slot,true)
  queue_row.add_child(slot)
  queue_preview_labels.append(slot)
 var divider=HSeparator.new()
 column.add_child(divider)
 var operations=Label.new()
 operations.text="BASE & PRODUCTION ACTIONS"
 column.add_child(operations)
 var deploy=Button.new()
 deploy.text="DEPLOY SELECTED MCV (H)"
 deploy.custom_minimum_size=Vector2(0,28)
 deploy.pressed.connect(_on_deploy)
 column.add_child(deploy)
 var harvest=Button.new()
 harvest.text="AUTO-HARVEST SELECTED"
 harvest.custom_minimum_size=Vector2(0,28)
 harvest.pressed.connect(_on_harvest)
 column.add_child(harvest)
 var cancel=Button.new()
 cancel.text="CANCEL CURRENT / REFUND"
 cancel.custom_minimum_size=Vector2(0,28)
 cancel.pressed.connect(_cancel_current_tab)
 column.add_child(cancel)
 refund_button=cancel
 var cancel_queued=Button.new()
 cancel_queued.text="REMOVE LAST QUEUED UNIT"
 cancel_queued.custom_minimum_size=Vector2(0,28)
 cancel_queued.pressed.connect(_cancel_last_queued)
 column.add_child(cancel_queued)
 cancel_queue_button=cancel_queued
 var repair=Button.new()
 repair.text="REPAIR SELECTED BUILDING"
 repair.custom_minimum_size=Vector2(0,28)
 repair.pressed.connect(_toggle_repair_selected)
 column.add_child(repair)
 repair_button=repair
 var sell=Button.new()
 sell.text="SELL SELECTED (CONFIRM)"
 sell.custom_minimum_size=Vector2(0,28)
 sell.pressed.connect(_on_sell_selected)
 column.add_child(sell)
 sell_button=sell

 var bottom=PanelContainer.new()
 bottom.mouse_filter=Control.MOUSE_FILTER_STOP
 root.add_child(bottom)
 hud_toolbar=bottom
 var toolbar_scroll=ScrollContainer.new()
 toolbar_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_AUTO
 toolbar_scroll.vertical_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
 toolbar_scroll.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 bottom.add_child(toolbar_scroll)
 hud_toolbar_scroll=toolbar_scroll
 var row=HBoxContainer.new()
 toolbar_scroll.add_child(row)
 for pair in [["SELECT_ALL","Select All"],["MOVE","Move"],["ATTACK_MOVE","Attack-Move"],["STOP","Stop"],["SCOUT","Scout (G)"],["FORMATION","Formation"],["DEPLOY","Deploy"],["RALLY","Rally"],["STAGING","Staging"],["PAUSE","Pause"],["RESET","Restart"]]:
  var button=Button.new()
  button.text=pair[1]
  button.custom_minimum_size=Vector2(82,34)
  button.text="       "+pair[1]
  button.alignment=HORIZONTAL_ALIGNMENT_CENTER
  button.pressed.connect(_on_toolbar.bind(pair[0]))
  RetroSkin.button(button,pair[0]=="ATTACK_MOVE",true)
  row.add_child(button)
  var tool_icon=Control.new()
  tool_icon.set_script(RetroIcon)
  tool_icon.size=Vector2(26,26)
  tool_icon.position=Vector2(3,4)
  button.add_child(tool_icon)
  tool_icon.configure(pair[0])
  action_palette_buttons.append(button)
 result_text=Label.new()
 result_text.anchor_left=0.5
 result_text.anchor_right=0.5
 result_text.offset_left=-180
 result_text.offset_top=86
 result_text.add_theme_font_size_override("font_size",14)
 result_text.mouse_filter=Control.MOUSE_FILTER_IGNORE
 root.add_child(result_text)
 _skin_hud()
 _on_hud_viewport_resized()

func _skin_hud() -> void:
 for p in [hud_top_panel,hud_dock,hud_toolbar]:
  RetroSkin.panel(p)
 for control in [sidebar_toggle,activate_producer_button,rally_button,rally_mode_button,refund_button,cancel_queue_button,repair_button,sell_button]:
  if control!=null: RetroSkin.button(control)
 RetroSkin.button(sidebar_toggle,true)
 for l in [title_text,hud_text,info_text,producer_summary,stage_detail]:
  RetroSkin.label(l,l==stage_detail or l==producer_summary,l==title_text)
 for tab in tab_buttons: RetroSkin.button(tab)
 for chip in stage_chips: RetroSkin.button(chip,false,true)

func _on_toolbar(action: String) -> void:
 match action:
  "SCOUT":
   if paused or battle_over: return
   for unit in selected:
    if is_instance_valid(unit) and unit.team == 0: scouting.start(self, unit)
   hud_status="Scouting unexplored terrain. Move, attack or stop cancels."
  "DEPLOY": _on_deploy()
  "RALLY": _begin_rally()
  "STAGING":
   sidebar_open=true
   _apply_hud_layout(get_viewport_rect().size)
   if current_tab not in [2,3]: current_tab=2
   _update_hud()
  _: super._on_toolbar(action)

func _on_deploy() -> void:
 if _deploy_mcv(0): _update_hud()

func _cancel_current_tab() -> void:
 var lane=["build","defense","infantry","vehicle"][current_tab]
 if cancel_production(0,lane):
  hud_status="Canceled production; invested credits refunded."
 else:
  hud_status="Nothing currently building in this category."
 _update_hud()

func _cancel_last_queued() -> void:
 var lane=["build","defense","infantry","vehicle"][current_tab]
 var waiting: Array=states[0]["queued"].get(lane,[])
 if not waiting.is_empty() and cancel_production(0,lane,waiting.size()-1):
  hud_status="Removed uncharged queued unit."
 else: hud_status="No queued units in this tab."
 _update_hud()

func _toggle_repair_selected() -> void:
 if selected_building==null or not is_instance_valid(selected_building) or selected_building.team!=0:
  hud_status="Select one of your buildings first."
 else:
  selected_building.repairing=not selected_building.repairing
  hud_status="Repair active: credits deducted per HP." if selected_building.repairing else "Repair stopped."
 _update_hud()

func _on_sell_selected() -> void:
 if selected_building==null or not is_instance_valid(selected_building) or selected_building.team!=0:
  hud_status="Select one of your buildings first."
 elif pending_sale==selected_building and skirmish_time<=sale_confirm_deadline:
  var label=str(STRUCTURE_DATA.get(selected_building.kind,{}).get("name","building"))
  if sell_structure(0,selected_building):
   hud_status="Sold "+label+" for 50% of paid construction value."
   selected_building=null
  pending_sale=null
 else:
  pending_sale=selected_building
  sale_confirm_deadline=skirmish_time+5.0
  hud_status="CONFIRM SALE: tap SELL again within 5 seconds."
 _update_hud()

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
 if id in ["turret","beam_bastion","sam","salvaged_aa","missile_nest"]: return "defense"
 if STRUCTURE_DATA.has(id): return "build"
 if roster.has(id): return ArmyRules.lane(id,roster[id])
 return "vehicle"

func _update_hud() -> void:
 if not is_instance_valid(hud_text) or states.size()<2: return
 var state: Dictionary=states[0]
 if is_instance_valid(title_text):
  title_text.text="IRON %d" % int(state["credits"])
 hud_text.text="POWER %+d     COMMAND RANK %d     ORE %d" % [int(state["power"])-int(state["demand"]),commander.rank(0),int(state["total_mined"])]
 var details: Array[String]=[]
 for lane in ["build","defense","infantry","vehicle"]:
  var job: Dictionary=state["lanes"][lane]
  if not job.is_empty():
   var recipe=_recipe(str(job["id"]))
   var percentage=int(100.0*float(job["paid"])/maxf(1.0,float(recipe.get("cost",1.0))))
   details.append("%s %s %d%%" % [lane.to_upper(),str(recipe.get("name",job["id"])),percentage])
 if selected_building!=null and is_instance_valid(selected_building):
  details.append("SELECTED %s HP %d/%d %s" % [selected_building.kind,int(selected_building.hp),int(selected_building.max_hp),"REPAIRING" if selected_building.repairing else ""])
 for lane in ["infantry","vehicle"]:
  var b=_active_producer(0,lane)
  if b!=null:
   var endpoint=_producer_rally_point(0,b)
   var label="PERSONAL" if b.rally_stage_id=="" else b.rally_stage_id
   details.append("%s EXIT (%d,%d) %s (%d,%d) %s" % [lane.to_upper(),int(b.position.x),int(b.position.y),label,int(endpoint.x),int(endpoint.y),"ATTACK-MOVE" if b.rally_attack_move else "MOVE"])
 # Keep immediate guidance readable instead of overflowing the viewport.
 info_text.text=hud_status if compact_hud else (" | ".join(details)+" | "+hud_status if not details.is_empty() else hud_status)
 for i in range(tab_buttons.size()):
  tab_buttons[i].button_pressed=(i==current_tab)
 if is_instance_valid(retro_economy_label):
  retro_economy_label.text="IRON  %06d   POWER %+d" % [int(state["credits"]),int(state["power"])-int(state["demand"])]
 if is_instance_valid(retro_powerbar):
  retro_powerbar.value=100.0 if int(state["demand"])<=0 else clampf(100.0*float(state["power"])/float(state["demand"]),0.0,100.0)
 if is_instance_valid(queue_preview_caption):
  var queue_lane=["build","defense","infantry","vehicle"][current_tab]
  var current_job: Dictionary=state["lanes"][queue_lane]
  var in_line: Array=state["queued"].get(queue_lane,[])
  queue_preview_caption.text=queue_lane.to_upper()+"  •  "+str(in_line.size())+" waiting"
  for slot_i in range(queue_preview_labels.size()):
   var slot: Label=queue_preview_labels[slot_i]
   slot.text="—"
   if slot_i==0 and not current_job.is_empty():
    slot.text="READY" if bool(current_job.get("ready",false)) else ("%d%%" % int(100.0*float(current_job.get("paid",0.0))/maxf(1.0,float(_recipe(str(current_job["id"])).get("cost",1.0)))))
   elif slot_i>0 and slot_i-1<in_line.size():
    slot.text=str(in_line[slot_i-1]).trim_prefix("a_").to_upper().substr(0,7)
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
  var short_label={
   "refinery":"ORE REFINERY","factory":"WAR FACTORY","depot":"SERVICE DEPOT",
   "a_ranger":"RANGER","a_javelin":"JAVELIN","a_engineer":"ENGINEER",
   "a_sentinel":"SENTINEL","a_sentinel_aa":"MOBILE AA",
   "a_harvester":"HARVESTER","a_mcv":"MCV",
   "a_lance":"ARC LANCE","a_striker":"STRIKER",
   "r_imperator":"IMPERATOR","r_mammoth":"MAMMOTH","r_siege_heli":"SIEGE HELI",
   "g_rocket_truck":"MOBILE AA","g_volley":"VOLLEY","g_heli":"HELICOPTER","g_collector":"COLLECTOR"
  }.get(id,label.to_upper())
  var label_tail="$%d" % cost
  if ready: label_tail="READY"
  elif not job.is_empty() and str(job["id"])==id:
   label_tail="%d%%" % int(100.0*float(job["paid"])/maxf(1.0,float(recipe.get("cost",1))))
  button.text="\n\n\n"+str(short_label)+"\n"+label_tail
  button.tooltip_text="%s | %d credits | %d seconds" % [label,cost,int(recipe.get("time",0))]
  button.disabled=not ready and (not _tech_ready(0,id) or not _has_producer(0,lane) or (not job.is_empty() and lane in ["build","defense"]))
 if is_instance_valid(refund_button): refund_button.disabled=state["lanes"][["build","defense","infantry","vehicle"][current_tab]].is_empty()
 if is_instance_valid(cancel_queue_button): cancel_queue_button.disabled=current_tab not in [2,3] or state["queued"][["infantry","vehicle"][maxi(0,current_tab-2)]].is_empty()
 if is_instance_valid(repair_button): repair_button.disabled=selected_building==null or not is_instance_valid(selected_building) or selected_building.team!=0
 if is_instance_valid(sell_button): sell_button.disabled=selected_building==null or not is_instance_valid(selected_building) or selected_building.team!=0
 if is_instance_valid(activate_producer_button): activate_producer_button.disabled=selected_building==null or not is_instance_valid(selected_building) or selected_building.team!=0 or selected_building.kind not in ["barracks","factory"]
 if is_instance_valid(rally_button):
  rally_button.disabled=_rally_candidate()==null
  rally_button.text="PICK RALLY ON MAP (Esc cancels)" if rally_placing else "SET RALLY POINT (G)"
 var source=_rally_candidate()
 if is_instance_valid(rally_stage_selector):
  rally_stage_selector.disabled=source==null
  if source!=null:
   var idx=0 if source.rally_stage_id=="" else STAGING_IDS.find(source.rally_stage_id)+1
   rally_stage_selector.select(maxi(0,idx))
 if is_instance_valid(rally_mode_button):
  rally_mode_button.disabled=source==null
  rally_mode_button.text=("ATTACK-MOVE (T)" if source!=null and source.rally_attack_move else "MOVE (T)")
 _refresh_producer_cards()
 _refresh_staging_chips(source)
 if is_instance_valid(sidebar_toggle) and compact_hud and not sidebar_open:
  sidebar_toggle.text="PRODUCTION ▼   "+producer_summary.text
 queue_redraw()

func _scenery_obstacles() -> Array[Rect2]:
 # Navigation also contains building footprints; those are not scenery artwork.
 return static_obstacles.filter(func(bounds): return not tree_footprints.has(bounds))

func _draw() -> void:
 super._draw()
 for b in structures:
  if not is_instance_valid(b) or b.team!=0 or b.hp<=0.0 or b.kind not in ["barracks","factory"]: continue
  var endpoint=_producer_rally_point(0,b)
  if endpoint==Vector2.ZERO: continue
  var is_active=b==_active_producer(0,"infantry" if b.kind=="barracks" else "vehicle")
  var line_color=Color("#75d9ff") if b.kind=="barracks" else Color("#f9c474")
  draw_line(b.position,endpoint,Color(line_color,0.38 if is_active else 0.12),2.5 if is_active else 1.0)
  if b.rally_stage_id=="":
   draw_arc(endpoint,10.0,0.0,TAU,18,line_color,2.0 if is_active else 1.0)
 for i in range(STAGING_IDS.size()):
  var id=STAGING_IDS[i]
  var stage: Dictionary=staging_areas[0][id]
  if not bool(stage["enabled"]): continue
  var point: Vector2=stage["position"]
  var stage_color=[Color("#9becff"),Color("#f4d582"),Color("#dcadfa")][i]
  draw_arc(point,21.0,0.0,TAU,30,stage_color,3.0)
  draw_circle(point,5.0,stage_color)
  draw_string(ThemeDB.fallback_font,point+Vector2(24,-10),id,HORIZONTAL_ALIGNMENT_LEFT,-1,16,stage_color)
 for field in ore_fields:
  var amount=float(field["remaining"])/maxf(1.0,float(field["initial"]))
  var pos: Vector2=field["position"]
  SceneryArt.ore(self,pos,amount)
 if placement_lane!="" and states.size()>0:
  var job: Dictionary=states[0]["lanes"][placement_lane]
  if not job.is_empty():
   var pos=Vector2(roundf(get_global_mouse_position().x/24.0)*24.0,roundf(get_global_mouse_position().y/24.0)*24.0)
   var size: Vector2=STRUCTURE_DATA[str(job["id"])]["size"]
   draw_rect(Rect2(pos-size/2.0,size),Color(0.3,0.95,0.45,0.28) if can_place(pos,str(job["id"]),0) else Color(0.98,0.2,0.25,0.3))
