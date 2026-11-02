extends Control
## Live procedural minimap, bound to the current economy/combat world.
var world
var update_elapsed := 0.0
var enabled := true
const BACK=Color("#07150f")
const ALLIED=Color("#6fd4ff")
const FOE=Color("#f68171")
const ORE=Color("#c5ccd4")

func configure(arena) -> void:
 world=arena
 mouse_filter=Control.MOUSE_FILTER_STOP
 queue_redraw()

func _process(delta: float) -> void:
 update_elapsed+=delta
 if update_elapsed>0.25:
  update_elapsed=0.0
  queue_redraw()

func map_point(point: Vector2) -> Vector2:
 if world==null: return Vector2.ZERO
 return Vector2(clampf(point.x/world.BOARD.size.x,0.0,1.0)*size.x,clampf(point.y/world.BOARD.size.y,0.0,1.0)*size.y)

func _gui_input(event: InputEvent) -> void:
 if world==null or not is_instance_valid(world.camera): return
 if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.pressed:
  world.camera.position=Vector2(event.position.x/maxf(1.0,size.x)*world.BOARD.size.x,event.position.y/maxf(1.0,size.y)*world.BOARD.size.y)
  accept_event()
 if event is InputEventScreenTouch and event.pressed:
  world.camera.position=Vector2(event.position.x/maxf(1.0,size.x)*world.BOARD.size.x,event.position.y/maxf(1.0,size.y)*world.BOARD.size.y)
  accept_event()

func _draw() -> void:
 draw_rect(Rect2(Vector2.ZERO,size),BACK)
 if world==null: return
 for i in range(0,9):
  var x=float(i)/8.0*size.x
  draw_line(Vector2(x,0),Vector2(x,size.y),Color("#1b332a"),1)
 for i in range(0,7):
  var y=float(i)/6.0*size.y
  draw_line(Vector2(0,y),Vector2(size.x,y),Color("#1b332a"),1)
 for o in world.static_obstacles:
  var p=map_point(o.position)
  var q=map_point(o.end)
  draw_rect(Rect2(p,q-p),Color("#435449"))
 for f in world.ore_fields:
  if float(f.get("remaining",0.0))>0 and (not world.fog_enabled or world.fog == null or world.fog.explored(0, f["position"])):
   draw_circle(map_point(f["position"]),3.2,ORE)
 for b in world.structures:
  if is_instance_valid(b) and b.hp>0.0 and world.entity_visible_to(0, b):
   draw_rect(Rect2(map_point(b.position)-Vector2.ONE*4.0,Vector2.ONE*8.0),ALLIED if b.team==0 else (FOE if b.team==1 else Color("#a2b3a9")))
 for u in world.units:
  if is_instance_valid(u) and u.hp>0.0 and world.entity_visible_to(0, u):
   draw_circle(map_point(u.position),2.0,ALLIED if u.team==0 else FOE)
 if world.fog_enabled and world.fog != null and world.fog.texture != null:
  draw_texture_rect(world.fog.texture, Rect2(Vector2.ZERO, size), false)
 if is_instance_valid(world.camera):
  var visible=get_viewport_rect().size/maxf(0.25,world.camera.zoom.x)
  var top=world.camera.position-visible*0.5
  var bottom=world.camera.position+visible*0.5
  draw_rect(Rect2(map_point(top),map_point(bottom)-map_point(top)),Color("#d7e6d8"),false,1.5)
 draw_rect(Rect2(Vector2.ZERO,size),Color("#7a98a7"),false,2)
