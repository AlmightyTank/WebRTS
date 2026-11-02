extends SceneTree
const Art = preload("res://scripts/ui/industrial_art.gd")
var failures := 0

class Drawing:
 extends Node2D
 var churn := false
 var generation := 0
 func _draw() -> void:
  if not churn:
   Art.draw_asset(self,"tank",0)
   Art.draw_asset(self,"power",0)
  else:
   for index in range(64):
    var frame := generation*64+index+1
    draw_set_transform(Vector2(index%16,index/16)*Vector2(50,80),0,Vector2.ONE*0.3)
    Art.draw_asset(self,"tank",0,(frame%64)*TAU/64.0,(frame/64)*TAU/64.0)
    Art.draw_asset(self,"power",1,0,NAN,0,{"time":frame/20.0})

func expect(ok: bool, label: String) -> void:
 print(("PASS: " if ok else "FAIL: ")+label)
 if not ok: failures+=1

func _initialize() -> void:
 call_deferred("run_checks")

func run_checks() -> void:
 if DisplayServer.get_name()=="headless":
  push_error("This regression requires a real renderer; omit --headless")
  quit(1)
  return
 Art._vehicle_mesh_cache.clear()
 Art._building_mesh_cache.clear()
 var still := Drawing.new()
 still.position=Vector2(150,150)
 root.add_child(still)
 await process_frame
 await RenderingServer.frame_post_draw
 var vehicle_ref: WeakRef = weakref(Art._vehicle_mesh_cache.values()[0])
 var building_ref: WeakRef = weakref(Art._building_mesh_cache.values()[0])
 var churn := Drawing.new()
 churn.churn=true
 root.add_child(churn)
 for generation in range(10):
  churn.generation=generation
  churn.queue_redraw()
  await process_frame
  await RenderingServer.frame_post_draw
 expect(vehicle_ref.get_ref()!=null,"Unchanged canvas retains its evicted vehicle mesh")
 expect(building_ref.get_ref()!=null,"Unchanged canvas retains its evicted building mesh")
 expect(Art._vehicle_mesh_cache.size()<=Art.VEHICLE_CACHE_LIMIT and Art._building_mesh_cache.size()<=Art.BUILDING_CACHE_LIMIT,"Shared caches remain bounded")
 # A new drawing replaces the old command list and should release old resources.
 still.queue_redraw()
 await process_frame
 await RenderingServer.frame_post_draw
 expect(vehicle_ref.get_ref()==null and building_ref.get_ref()==null,"Redraw releases obsolete retained meshes")
 still.queue_free()
 churn.queue_free()
 await process_frame
 print("MESH_CACHE_LIFETIME_SMOKE_", "PASS" if failures==0 else "FAIL")
 quit(0 if failures==0 else 1)
