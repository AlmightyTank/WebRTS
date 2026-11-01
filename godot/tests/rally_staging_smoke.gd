extends SceneTree
## Headless integration checks for shared staging destinations and attack-move rally.
var failures: Array[String] = []
var world

func expect(ok: bool, label: String) -> void:
 if ok:
  print("PASS: "+label)
 else:
  failures.append(label)
  push_error("FAIL: "+label)

func find_unit(id: String, index: int=0):
 var found=[]
 for u in world.units:
  if is_instance_valid(u) and u.team==0 and u.unit_id==id: found.append(u)
 return found[index] if index<found.size() else null

func _initialize() -> void:
 call_deferred("run_checks")

func run_checks() -> void:
 world=load("res://scenes/skirmish.tscn").instantiate()
 root.add_child(world)
 await process_frame
 world.paused=true
 expect(world._deploy_mcv(0),"MCV deploys for staging test")
 expect(world._place_structure("barracks",0,Vector2(450,430)),"First Barracks placed")
 var west_barracks=world._active_producer(0,"infantry")
 expect(world._place_structure("factory",0,Vector2(600,700)),"First War Factory placed")
 var war_factory=world._active_producer(0,"vehicle")
 expect(world._place_structure("barracks",0,Vector2(780,640)),"Second Barracks placed")
 var east_barracks=world._active_producer(0,"infantry")
 expect(west_barracks!=east_barracks,"Newest Barracks becomes infantry production exit")
 expect(world._production_time_multiplier(0,"infantry")<1.0,"Second Barracks still accelerates shared infantry lane")
 expect(not world.set_staging_area(0,"INVALID",Vector2(700,900)),"Reject unknown staging area")
 expect(not world.set_staging_area(4,"ALPHA",Vector2(700,900)),"Reject invalid owner")
 expect(world.set_staging_area(0,"ALPHA",Vector2(780,970)),"Set Alpha staging position")
 expect(world.set_staging_area(0,"BRAVO",Vector2(720,160)),"Set Bravo staging position")
 expect(world.set_staging_area(0,"CHARLIE",Vector2(690,1120)),"Set Charlie staging position")
 var alpha=world.staging_areas[0]["ALPHA"]["position"]
 var bravo=world.staging_areas[0]["BRAVO"]["position"]
 expect(alpha!=bravo,"Different staging areas have different destinations")
 expect(world.assign_producer_stage(0,west_barracks,"ALPHA"),"First Barracks assigned Alpha")
 expect(world.assign_producer_stage(0,war_factory,"ALPHA"),"Factory assigned same Alpha")
 expect(world.assign_producer_stage(0,east_barracks,"BRAVO"),"Second Barracks assigned Bravo")
 expect(west_barracks.rally_stage_id=="ALPHA" and war_factory.rally_stage_id=="ALPHA","Two distinct producers share Alpha")
 expect(east_barracks.rally_stage_id=="BRAVO","Third producer retains independent Bravo")
 expect(not world.assign_producer_stage(1,west_barracks,"ALPHA"),"Cannot reassign opponent producer")
 expect(world._active_producer(0,"infantry")==east_barracks,"Most recently selected Barracks controls shared infantry queue")
 expect(world._produce_unit(0,"a_ranger"),"Spawn infantry from Bravo Barracks")
 var bravo_ranger=find_unit("a_ranger")
 if bravo_ranger!=null:
  expect(bravo_ranger.destination.distance_to(bravo)<2.0,"First Bravo infantry targets exact staging center")
  expect(not bravo_ranger.aggressive,"Default rally uses move rather than attack-move")
 expect(world._set_active_producer(0,"infantry",west_barracks),"Manually choose Alpha Barracks")
 expect(world.set_producer_attack_move(0,west_barracks,true),"Enable attack-move for selected Barracks")
 expect(not world.set_producer_attack_move(1,west_barracks,true),"Cannot change enemy's rally mode")
 expect(world._produce_unit(0,"a_javelin"),"Spawn attack-move rocket team")
 var alpha_rocket=find_unit("a_javelin")
 if alpha_rocket!=null:
  expect(alpha_rocket.destination.distance_to(alpha)<2.0,"First Alpha arrival targets center")
  expect(alpha_rocket.aggressive and alpha_rocket.has_attack_move_goal,"Rocket team receives persistent attack-move goal")
 expect(world._produce_unit(0,"a_sentinel"),"Spawn vehicle into shared Alpha stage")
 var alpha_tank=find_unit("a_sentinel")
 if alpha_tank!=null:
  expect(alpha_tank.destination.distance_to(alpha)<155.0,"Tank converges on shared Alpha stage")
  expect(not alpha_tank.aggressive,"Factory mode remains MOVE independently of Barracks")
  if alpha_rocket!=null:
   expect(alpha_tank.destination.distance_to(alpha_rocket.destination)>8.0,"Staging slots separate infantry and vehicle arrivals")
 expect(world._produce_unit(0,"a_engineer"),"Spawn engineer under attack-move Barracks")
 var engineer=find_unit("a_engineer")
 if engineer!=null:
  expect(not engineer.aggressive,"Unarmed engineer does not receive attack-move")
 expect(world._produce_unit(0,"a_harvester"),"Spawn purchased harvester with staged rally")
 var harvester=find_unit("a_harvester")
 if harvester!=null:
  expect(harvester.resume_harvest_on_arrival,"Harvester resumes mining after traveling to stage")
 expect(world.set_staging_area(0,"ALPHA",Vector2(760,1020)),"Reposition shared Alpha stage")
 var moved=world.staging_areas[0]["ALPHA"]["position"]
 expect(world._producer_rally_point(0,war_factory)==moved and world._producer_rally_point(0,west_barracks)==moved,"Moving stage updates all linked producers")
 expect(world._producer_rally_point(0,east_barracks)==bravo,"Unrelated Bravo stage is unchanged")
 expect(world._produce_unit(0,"a_sentinel"),"Spawn another tank after moving shared stage")
 var second_tank=find_unit("a_sentinel",1)
 if second_tank!=null:
  expect(second_tank.destination.distance_to(moved)<155.0,"Later tank uses new shared Alpha destination")
 expect(world.assign_producer_stage(0,war_factory,""),"Factory may return to personal rally")
 expect(war_factory.rally_stage_id=="","Returning to personal does not delete Alpha")
 expect(world.set_producer_rally(0,"vehicle",Vector2(1020,900)),"Personal rally still supports direct placement")
 expect(war_factory.rally_point.distance_to(Vector2(1020,900))<2.0,"Personal rally remains independent")
 expect(world.assign_producer_stage(0,war_factory,"CHARLIE"),"Factory can select Charlie")
 expect(world._producer_rally_point(0,war_factory)==world.staging_areas[0]["CHARLIE"]["position"],"Factory targets third stage")
 if alpha_rocket!=null:
  # Simulate the end of a hostile engagement. Original attack-move goal must persist.
  alpha_rocket.target=null
  alpha_rocket.moving=false
  alpha_rocket.destination=Vector2(400,400)
  world.paused=false
  alpha_rocket._physics_process(0.05)
  expect(alpha_rocket.destination.distance_to(alpha)<2.0,"Attack-move resumes its original goal after combat")
  world.paused=true
 world.reset_battle()
 expect(not bool(world.staging_areas[0]["ALPHA"]["enabled"]),"Restart clears staging locations")
 expect(world._active_producer(0,"infantry")==null,"Restart clears old producer references")
 world.queue_free()
 if failures.is_empty():
  print("RALLY_STAGING_SMOKE_PASS")
  quit(0)
 else:
  print("RALLY_STAGING_SMOKE_FAIL "+str(failures.size()))
  quit(1)
