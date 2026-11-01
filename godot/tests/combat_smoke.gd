extends SceneTree
## Run: godot --headless --path godot --script res://tests/combat_smoke.gd
var failures: Array[String] = []
var world

func _initialize() -> void:
 call_deferred("run_checks")

func expect(value: bool, reason: String) -> void:
 if not value:
  failures.append(reason)
  push_error("FAIL: " + reason)
 else:
  print("PASS: " + reason)

func run_checks() -> void:
 world = load("res://scenes/combat_lab.tscn").instantiate()
 root.add_child(world)
 await process_frame
 expect(world.registry.has("standard_units"), "Real v0.4 roster parsed")
 expect(world.units.size() >= 10, "Both teams spawn visible infantry, vehicles and aircraft")
 var blue := 0
 var red := 0
 for u in world.units:
  if u.team == 0: blue += 1
  else: red += 1
 expect(blue >= 5 and red >= 5, "Both teams receive units")
 expect(is_equal_approx(world.armor_multiplier("SMALL_ARMS","HEAVY"),0.08), "Weapon armor multipliers use balance registry")
 expect(not world.can_occupy(Vector2(875,270),10,false), "Static collision blocks movement")
 expect(world.can_occupy(Vector2(800,900),5,false), "Free terrain is navigable")
 var route: PackedVector2Array = world.find_route(Vector2(780,240),Vector2(1020,240),false)
 expect(route.size()>2, "Ground units path around obstacle")
 var airroute: PackedVector2Array = world.find_route(Vector2(780,240),Vector2(1020,240),true)
 expect(airroute.size()==1, "Aircraft ignore ground obstruction")
 var infantry
 var tank
 var aa
 var hostile_air
 for u in world.units:
  if u.unit_id == "a_ranger": infantry = u
  if u.unit_id == "a_sentinel": tank = u
  if u.unit_id == "a_sentinel_aa": aa = u
  if u.unit_id == "r_siege_heli": hostile_air = u
 expect(infantry != null and tank != null and aa != null and hostile_air != null,"Infantry, tank, anti-air and helicopter all instanced")
 expect(not infantry.can_hit(hostile_air),"Rifleman cannot target aircraft")
 expect(aa.can_hit(hostile_air),"AA vehicle can lock onto aircraft")
 var slots: Array[Vector2] = world.formation_targets(Vector2(300,400),5,Vector2(600,400),"LINE")
 expect(slots.size()==5 and slots[0]!=slots[1] and slots[2]!=slots[3],"Group formation assigns distinct slots")
 tank.order_move(Vector2(1100,900))
 expect(tank.moving and tank.route.size()>0,"Actual unit receives move orders")
 tank.order_stop()
 expect(not tank.moving,"Stop cancels movement")
 world.scenario_index = 2
 world.reset_battle()
 var air_count := 0
 for u in world.units:
  if u.air: air_count+=1
 expect(air_count>=2,"Air interception scenario includes aircraft")
 world.paused = true
 expect(world.paused,"Combat simulation can be paused")
 world.queue_free()
 if failures.is_empty():
  print("COMBAT_SMOKE_PASS")
  quit(0)
 else:
  print("COMBAT_SMOKE_FAIL %d" % failures.size())
  quit(1)
