extends SceneTree

const Arena=preload("res://scripts/economy/skirmish_arena.gd")
const Kits=preload("res://scripts/economy/commander_system.gd")
const Art=preload("res://scripts/ui/industrial_art.gd")
var failed:=0
class InfrastructureGallery extends Node2D:
 func _draw() -> void:
  var ids: Array=["beam_bastion","missile_nest","foundry","vanguard_foundry","silo"]
  for i in range(ids.size()):
   draw_set_transform(Vector2(130+i*240,240))
   Art.draw_asset(self,ids[i],0,0,.3)
   draw_string(ThemeDB.fallback_font,Vector2(-70,90),ids[i],HORIZONTAL_ALIGNMENT_LEFT,-1,14)
  draw_set_transform(Vector2.ZERO)

func expect(ok: bool, label: String) -> void:
 if not ok:
  failed+=1
  push_error("FAIL: "+label)
 else: print("PASS: "+label)

func _initialize() -> void:
 call_deferred("run")

func run() -> void:
 for choice in ["alliance_energy","republic_armor","gia_missile"]:
  var w=Arena.new()
  w.army_choices=[choice,choice]
  w.fog_enabled=false
  root.add_child(w)
  w.set_physics_process(false)
  w.actors.process_mode=Node.PROCESS_MODE_DISABLED
  w.obstacles.clear()
  w._rebuild_navigation()
  var c=w.commander
  for side in range(2):
   w.states[side].credits=100000.0
   for id in ["yard","power","power","power","power","refinery","barracks","factory","depot"]:
    w._place_structure(id,side,Vector2(150+side*1200,150))
   if choice=="republic_armor": w._place_structure("vanguard_foundry",side,Vector2(300+side*1200,150))
   if choice=="gia_missile": w._place_structure("silo",side,Vector2(300+side*1200,150))
   w._calculate_power(side)
  expect(c.rank(0)==1 and c.teams[0].points==1,choice+": independent initial rank and GP")
  for id in w.ArmyRules.structure_ids(choice):
   expect(w.queue_production(0,w._lane_for(id),id),"Resolved infrastructure can queue: "+id)
   w.cancel_production(0,w._lane_for(id))
  var powers: Array=c.power_ids(0)
  w._apply_hud_layout(Vector2(1280,720))
  expect(w.hud_powers.visible,choice+": powers stay on the battlefield")
  expect(w.hud_powers.position.x+w.hud_powers.size.x<w.hud_dock.position.x,choice+": power column is left of the sidebar")
  expect(w.hud_powers.position.x+1.0<w.hud_top_panel.position.x,choice+": status bar starts to the right of the powers")
  expect(absf(w.hud_powers.position.y-w.hud_top_panel.position.y)<2.0,choice+": power column aligns with the top of the battlefield")
  var ancestor: Node=c.power_buttons[powers[0]].use
  var in_upgrades:=false
  while ancestor!=null:
   if ancestor==w.upgrades_panel: in_upgrades=true
   ancestor=ancestor.get_parent()
  expect(not in_upgrades,choice+": power cameos left the upgrades tab")
  expect(c.countdown_labels[powers[2]].text.begins_with("R"),choice+": a locked power shows its rank on the cameo")
  c.award_xp(1,3500.0)
  c.ai_tick()
  expect(not c.teams[1].powers.is_empty() and not c.teams[1].job.is_empty(),"AI purchases its own powers and starts legal research")
  c.cancel_research(1)
  expect(not c.buy_power(0,powers[2]),"Rank-five power locked")
  expect(not c.start_research(0,"autoloaders" if choice!="republic_armor" else "beam_capacitors"),"Foreign research rejected")
  for id in c.research_ids(0):
   var before: float=w.states[0].credits
   expect(c.start_research(0,id),"Start "+id)
   c.tick(1.0)
   expect(w.states[0].credits<before and not c.has_research(0,id),"Research pays over time")
   var paid: float=c.teams[0].job.paid
   var sites: Array=[]
   for structure in w.structures:
    if structure.team==0 and structure.kind==Kits.RESEARCH[id].site:
     sites.append(structure)
     structure.team=1
   c.tick(1.0)
   expect(c.teams[0].job.paid==paid,"Research pauses after losing its facility")
   for structure in sites: structure.team=0
   expect(c.cancel_research(0) and is_equal_approx(w.states[0].credits,before),"Cancel refunds actual investment")
   c.start_research(0,id)
   c.tick(200.0)
   expect(c.has_research(0,id) and is_equal_approx(before-w.states[0].credits,Kits.RESEARCH[id].cost),"Complete once at exact price: "+id)
   expect(not c.start_research(0,id),"No repeat research")
  expect(c.rank(0)==1 and c.teams[0].points==1,"Research does not grant command XP")
  c.award_xp(0,3500.0)
  expect(c.rank(0)==5 and c.teams[0].points==7,"Five ranks grant exactly seven spendable GP")
  c.power_buttons[powers[0]].buy.pressed.emit()
  expect(c.teams[0].powers.get(powers[0],0)==1,"HUD GP purchase reaches commander authority")
  c.teams[0].points+=1
  c.teams[0].powers.clear()
  for id in powers:
   expect(c.buy_power(0,id),"Buy "+id)
   var point:=Vector2(700,400)
   if id=="armor_reserve": point=Vector2(700,800)
   var ally=w._spawn("a_lance" if choice=="alliance_energy" else ("r_jugger" if choice=="republic_armor" else "g_volley"),0,point)
   ally.hp=ally.max_hp*.5
   var victim=w._spawn("r_imperator",1,point+Vector2(50,0))
   var hp: float=victim.hp
   var count: int=w.units.size()
   var target_point: Vector2=point+Vector2(0,80) if id=="armor_reserve" else point
   expect(c.cast(0,id,target_point),"Cast "+id)
   expect(c.countdown_labels[id].text==str(ceili(float(c.teams[0].cooldowns[id]))),choice+": cameo countdown matches "+id)
   expect(c.cameos[id].fraction>0.95,choice+": clock covers "+id+" after it fires")
   expect(not c.cast(0,id,point),"Cooldown prevents spam")
   if Kits.POWERS[id].delay>0:
    expect(not c.events.is_empty() and victim.hp==hp,"Warning precedes damage/delivery")
    c.tick(float(Kits.POWERS[id].delay)+.01)
   if id in ["orbital_pulse","harassing_salvo","saturation_strike"]: expect(victim.hp<hp,"Strike damages enemies")
   if id=="field_repairs": expect(ally.hp>ally.max_hp*.5,"Field repairs heal owned armor")
   if id=="armor_reserve": expect(w.units.size()>count,"Reserve delivers armor to clear nearby sites")
   if id in ["target_lattice","rocket_recon"]: expect(not c.reveals.is_empty(),"Recon creates temporary team sight")
   if id in ["grid_surge","breakthrough_order"]: expect(c.buff_at(0,id,point),"Temporary support area active")
   ally.position=Vector2(100,100)
   victim.position=Vector2(1700,100)
  var source=w._spawn("a_lattice" if choice=="alliance_energy" else ("r_jugger" if choice=="republic_armor" else "g_volley"),0,Vector2(650,650))
  var enemy=w._spawn("r_line",1,Vector2(750,650))
  var shot: Dictionary=source.weapon.duplicate(true)
  var base: float=shot.interval
  var interval: float=c.modify_shot(source,enemy,shot,base)
  if choice=="republic_armor":
   expect(source.unit_xp==100 and is_equal_approx(interval,base*.85),"Veteran crews and autoloaders apply independently")
  if choice=="gia_missile":
   expect(is_equal_approx(interval,base*.75/.9),"Reload stacking capped at 75 percent of original interval")
   expect(is_equal_approx(c.weapon_range(source,enemy),source.weapon.range+30),"Guidance improves signature missile range")
   c.teams[0].silo=0.0
   expect(c.launch_silo(0,enemy.position) and c.events.back().radius==230.0,"Payload changes the existing silo, not another superweapon")
  if choice=="alliance_energy":
   expect(is_equal_approx(shot.damage,source.weapon.damage*1.15),"Capacitors improve energy damage")
   enemy.air=true
   shot=source.weapon.duplicate(true)
   c.modify_shot(source,enemy,shot,base)
   expect(is_equal_approx(shot.damage,source.weapon.air_damage*1.1*1.15),"AA damage retains capacitor modifier")
   w.states[0].power=0.0
   interval=c.modify_shot(source,enemy,source.weapon.duplicate(true),base*2)
   expect(is_equal_approx(interval,base*1.5) and not c.interception_ready(source),"Stabilizers retain shortage penalty; interception loses power")
   w._calculate_power(0)
   w.spawn_projectile(enemy,source,{"type":"ROCKET","damage":10.0,"speed":100.0,"range":500.0})
   var p=w.projectiles.back()
   p.position=source.position+Vector2(30,0)
   c.tick(.01)
   expect(p.is_queued_for_deletion() and not c.interception_ready(source),"Lattice intercepts one missile, then recharges")
  var remaining: float=c.teams[0].cooldowns[powers.back()]
  w.paused=true
  c.tick(1.0)
  expect(c.teams[0].cooldowns[powers.back()]==remaining,"Pause freezes support timers")
  w.paused=false
  w.fog_enabled=true
  w._refresh_fog()
  c.teams[0].cooldowns[powers.back()]=0.0
  expect(not c.cast(0,powers.back(),Vector2(1900,1100)),"Offensive/support targeting rejects unseen terrain")
  expect(not c.cast(0,powers[0],Vector2(-10,-10)),"Out-of-board targets rejected")
  c.power_buttons[powers[0]].use.pressed.emit()
  expect(c.pending_power==powers[0],"HUD power button enters targeting mode")
  var cancel_event:=InputEventKey.new()
  cancel_event.pressed=true
  cancel_event.keycode=KEY_ESCAPE
  w._unhandled_input(cancel_event)
  expect(c.pending_power=="","Escape cancels targeting without spending cooldown")
  if choice=="gia_missile":
   c.teams[0].cooldowns.rocket_recon=0.0
   c.pending_power="rocket_recon"
   var click:=InputEventMouseButton.new()
   click.pressed=true
   click.button_index=MOUSE_BUTTON_LEFT
   click.position=Vector2(500,350)
   w._unhandled_input(click)
   expect(c.pending_power=="" and c.teams[0].cooldowns.rocket_recon>0,"World click confirms pending recon")
   c.tick(1.6)
   expect(w.fog.sees(0,w._screen_to_world(click.position)),"Recon reveals the targeted shroud")
   c.tick(30.0)
   w._refresh_fog()
   expect(c.reveals.is_empty(),"Recon sight expires independently of permanent exploration")
  if DisplayServer.get_name()!="headless":
   c.events.append({"id":"visual_warning","side":1,"point":Vector2(700,550),"radius":120.0,"remaining":3.0,"level":1})
   c.queue_redraw()
   w._update_hud()
   c.rank_label.get_parent().show()
   await process_frame
   await process_frame
   root.get_texture().get_image().save_png("user://commander_"+choice+".png")
  var fallen=w._spawn("r_line",1,Vector2(900,900))
  fallen.hp=0.0
  var xp_before: float=c.teams[0].xp
  var crew_before: float=source.unit_xp
  w.register_hit(source,fallen,10.0)
  expect(c.teams[0].xp>xp_before and source.unit_xp==crew_before+50.0,"Enemy kill grants separate command and crew XP")
  var awarded: float=c.teams[0].xp
  w.register_hit(source,fallen,10.0)
  expect(c.teams[0].xp==awarded,"Duplicate hit notification cannot grant duplicate kill XP")
  w.reset_battle()
  expect(c.teams[0].research.is_empty() and c.teams[0].powers.is_empty() and c.events.is_empty() and c.rank(0)==1,"Restart clears all match-local progression")
  w.free()
 Art._building_mesh_cache.clear()
 var gallery:=InfrastructureGallery.new()
 root.add_child(gallery)
 await process_frame
 await process_frame
 expect(Art._building_mesh_cache.size()==5,"All commander infrastructure has cached artwork")
 var meshes: Array=Art._building_mesh_cache.values().duplicate()
 gallery.queue_redraw()
 await process_frame
 await process_frame
 expect(Art._building_mesh_cache.values()==meshes,"Infrastructure redraw reuses the original mesh")
 if DisplayServer.get_name()!="headless": root.get_texture().get_image().save_png("user://commander_infrastructure.png")
 gallery.free()
 print("COMMANDER_KITS_SMOKE: %d failures" % failed)
 quit(1 if failed else 0)
