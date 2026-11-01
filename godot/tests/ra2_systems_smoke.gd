extends SceneTree
## End-to-end headless tests for refunds, repair, sell, factory speed, MCV and engineer capture.
var failures: Array[String] = []
var world

func _initialize() -> void:
 call_deferred("run_checks")

func expect(condition: bool, label: String) -> void:
 if condition: print("PASS: "+label)
 else:
  failures.append(label)
  push_error("FAIL: "+label)

func build(id: String, point: Vector2) -> void:
 expect(world.queue_production(0,"build",id),"Queue "+id)
 world._tick_production(0,80.0)
 expect(bool(world.states[0]["lanes"]["build"].get("ready",false)),id+" paid and READY")
 world.placement_lane="build"
 expect(world._place_player_ready(point),"Place "+id)

func run_checks() -> void:
 world=load("res://scenes/skirmish.tscn").instantiate()
 root.add_child(world)
 await process_frame
 expect(world._deploy_mcv(0),"Player can deploy starting MCV")
 expect(world._building_count(0,"yard")==1,"One construction authority after deployment")
 var initial=float(world.states[0]["credits"])
 expect(world.queue_production(0,"build","power"),"Start construction")
 world._tick_production(0,2.0)
 var partial=float(world.states[0]["lanes"]["build"]["paid"])
 expect(partial>0 and partial<800,"Gradual payment is partial")
 expect(world.cancel_production(0,"build"),"Cancel partially built power plant")
 expect(is_equal_approx(float(world.states[0]["credits"]),initial),"Refund precisely equals invested amount")
 expect(not world.cancel_production(0,"build"),"Cannot refund same job twice")
 expect(world.queue_production(0,"build","power"),"Requeue power")
 world._tick_production(0,20.0)
 expect(bool(world.states[0]["lanes"]["build"].get("ready",false)),"Power plant reaches READY")
 expect(world.cancel_production(0,"build"),"Cancel READY unplaced building")
 expect(is_equal_approx(float(world.states[0]["credits"]),initial),"Full paid READY construction refunded")
 expect(world.placement_lane=="","Cancel clears placement preview")
 build("power",Vector2(310,420))
 build("refinery",Vector2(480,420))
 build("barracks",Vector2(570,630))
 expect(world.queue_production(0,"infantry","a_engineer"),"Engineers unlock at Barracks")
 expect(world.queue_production(0,"infantry","a_ranger"),"Second infantry enters waiting queue")
 expect(world.cancel_production(0,"infantry",0),"Queued unit can be removed before paying")
 expect(world.states[0]["queued"]["infantry"].is_empty(),"Canceled queue item removed")
 expect(world.cancel_production(0,"infantry"),"Active infantry job can be canceled")
 expect(not world.queue_production(0,"vehicle","a_mcv"),"Replacement MCV locked before War Factory and Depot")
 build("factory",Vector2(740,750))
 expect(not world.queue_production(0,"vehicle","a_mcv"),"MCV still locked before Service Depot")
 build("depot",Vector2(935,750))
 expect(world.queue_production(0,"vehicle","a_mcv"),"Service Depot + War Factory unlock new MCV")
 world.deliver_ore(0,4500.0)
 world._tick_production(0,70.0)
 var mcvs=world.units.filter(func(u): return is_instance_valid(u) and u.team==0 and u.unit_id=="a_mcv")
 expect(mcvs.size()==1,"New MCV physically exits factory")
 if not mcvs.is_empty():
  var mcv=mcvs[0]
  mcv.position=Vector2(260,1040)
  mcv.moving=false
  world._set_selected([mcv])
  expect(world._deploy_mcv(0),"Replacement MCV deploys at remote open ground")
  expect(world._building_count(0,"yard")==2,"Two yards create separate expansion anchors")
  expect(world._production_time_multiplier(0,"build")<1.0,"Second Yard accelerates shared build lane")
 expect(world._production_time_multiplier(0,"vehicle")==1.0,"Single factory has baseline build time")
 build("factory",Vector2(945,930))
 expect(world._production_time_multiplier(0,"vehicle")<1.0,"Second factory accelerates shared vehicle lane")
 expect(world.states[0]["lanes"]["vehicle"].is_empty(),"Extra factory does not create an independent queue")
 var power = null
 for b in world.structures:
  if is_instance_valid(b) and b.team==0 and b.kind=="power": power=b
 expect(power!=null,"Power building exists to repair and sell")
 if power!=null:
  power.receive_damage(200.0,null)
  var before_hp=float(power.hp)
  var before_credits=float(world.states[0]["credits"])
  power.repairing=true
  world._advance_repairs(1.0)
  expect(power.hp>before_hp and power.hp<=power.max_hp,"Paid repair increases only missing HP")
  expect(float(world.states[0]["credits"])<before_credits,"Repair spends credits")
  power.repairing=false
  var sell_credit=float(world.states[0]["credits"])
  expect(not world.sell_structure(1,power),"Enemy cannot sell another player's building")
  expect(world.sell_structure(0,power),"Owner can sell building")
  expect(is_equal_approx(float(world.states[0]["credits"]),sell_credit+400.0),"Building sale returns 50% of paid cost")
  expect(not world.sell_structure(0,power),"Cannot sell same building twice")
 var enemy_refinery=world._place_structure("refinery",1,Vector2(1620,420))
 expect(enemy_refinery,"Enemy refinery fixture can be placed")
 var target=world._hit_building(Vector2(1620,420),1)
 var enemies_before=world.units.filter(func(u): return is_instance_valid(u) and u.team==1 and u.unit_id=="r_hauler").size()
 world._spawn_engineer("a_engineer",0,Vector2(1370,450))
 # _spawn_engineer returns void by design; look up the spawned actor instead.
 var engineers=world.units.filter(func(u): return is_instance_valid(u) and u.unit_id=="a_engineer")
 expect(engineers.size()>0,"Engineer instantiates with existing movement framework")
 if engineers.size()>0 and target!=null:
  var operative=engineers[0]
  operative.order_capture(target)
  operative.position=operative.capture_approach_point
  operative.moving=false
  operative._tick_capture(3.2)
  expect(target.team==0,"Engineer captures enemy structure")
  expect(world.units.find(operative)==-1,"Engineer consumed after successful capture")
  var enemies_after=world.units.filter(func(u): return is_instance_valid(u) and u.team==1 and u.unit_id=="r_hauler").size()
  expect(enemies_after==enemies_before,"Captured refinery does not duplicate free harvester")
 var neutral=world._hit_building(Vector2(1080,225),-1)
 expect(neutral!=null,"Neutral relay exists as a capture objective")
 world._spawn_engineer("a_engineer",0,Vector2(860,260))
 var free_engineers=world.units.filter(func(u): return is_instance_valid(u) and u.unit_id=="a_engineer")
 if free_engineers.size()>0 and neutral!=null:
  var scout=free_engineers[0]
  scout.order_capture(neutral)
  scout.position=scout.capture_approach_point
  scout.moving=false
  scout._tick_capture(0.8)
  expect(neutral.team==0,"Neutral relay captures faster than hostile buildings")
  expect(is_zero_approx(neutral.paid_value),"Neutral relay cannot be sold for free starting credits")
 expect(float(world.states[0]["credits"])>=0.0,"Balance never becomes negative")
 world.queue_free()
 if failures.is_empty():
  print("RA2_SYSTEMS_SMOKE_PASS")
  quit(0)
 else:
  print("RA2_SYSTEMS_SMOKE_FAIL "+str(failures.size()))
  quit(1)
