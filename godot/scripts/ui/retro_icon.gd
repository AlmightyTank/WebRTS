extends Control
## Pure Vector2 icons for the production rack and tactical command console.
const IndustrialArt = preload("res://scripts/ui/industrial_art.gd")
var icon_name := "power"
var tint := Color("#86ceee")

func _icon_body() -> Color:
 if icon_name.begins_with("r_"):
  return Color("#c87559")
 if icon_name.begins_with("a_"):
  return Color("#62b6d7")
 return tint

func configure(id: String) -> void:
 icon_name=id
 queue_redraw()

func _ready() -> void:
 mouse_filter=Control.MOUSE_FILTER_IGNORE
 queue_redraw()

func _draw() -> void:
 if IndustrialArt.has_asset(icon_name):
  var bounds = IndustrialArt.asset_bounds(icon_name)
  var scale_factor = minf(size.x/bounds.size.x,size.y/bounds.size.y)
  draw_set_transform(size*0.5-bounds.get_center()*scale_factor,0,Vector2.ONE*scale_factor)
  IndustrialArt.draw_asset(self,icon_name,1 if icon_name.begins_with("r_") else 0)
  draw_set_transform(Vector2.ZERO)
  return
 var factor=minf(size.x/72.0,size.y/52.0)
 draw_set_transform(size*0.5,0.0,Vector2.ONE*factor)
 var ink=Color("#0b1117")
 var edge=Color("#92a0ad")
 var body=_icon_body()
 match icon_name:
  "EMBLEM":
   draw_colored_polygon(PackedVector2Array([Vector2(0,-26),Vector2(15,-6),Vector2(7,18),Vector2(0,28),Vector2(-7,18),Vector2(-15,-6)]),body)
   draw_line(Vector2(-30,8),Vector2(0,-5),edge,5)
   draw_line(Vector2(0,-5),Vector2(30,8),edge,5)
   draw_circle(Vector2(0,-3),5,Color("#101720"))
  "MOVE":
   draw_line(Vector2(-27,13),Vector2(12,-13),body,5)
   draw_colored_polygon(PackedVector2Array([Vector2(12,-24),Vector2(32,-13),Vector2(12,-2)]),body)
  "ATTACK_MOVE":
   draw_arc(Vector2.ZERO,22,0.0,TAU,24,Color("#e8b65d"),3)
   draw_line(Vector2(-32,0),Vector2(32,0),Color("#e8b65d"),3)
   draw_line(Vector2(0,-30),Vector2(0,30),Color("#e8b65d"),3)
  "STOP":
   draw_colored_polygon(PackedVector2Array([Vector2(-18,-23),Vector2(18,-23),Vector2(27,-14),Vector2(27,14),Vector2(18,23),Vector2(-18,23),Vector2(-27,14),Vector2(-27,-14)]),Color("#c76f65"))
   draw_rect(Rect2(-11,-11,22,22),ink)
  "FORMATION":
   for i in range(3):
    for j in range(3):
     draw_circle(Vector2(-22+i*22,-19+j*19),5,body)
  "PAUSE":
   draw_rect(Rect2(-18,-20,12,40),body)
   draw_rect(Rect2(6,-20,12,40),body)
  "RESET":
   draw_arc(Vector2.ZERO,21,-PI*0.2,PI*1.6,24,body,4)
   draw_colored_polygon(PackedVector2Array([Vector2(16,-25),Vector2(34,-23),Vector2(25,-7)]),body)
  "DEPLOY":
   draw_line(Vector2(0,-23),Vector2(0,12),body,5)
   draw_colored_polygon(PackedVector2Array([Vector2(-15,0),Vector2(15,0),Vector2(0,18)]),body)
   draw_rect(Rect2(-25,19,50,5),edge)
  "RALLY":
   draw_line(Vector2(-16,22),Vector2(-16,-27),edge,4)
   draw_colored_polygon(PackedVector2Array([Vector2(-14,-25),Vector2(25,-15),Vector2(-14,-3)]),body)
  "STAGING":
   for i in range(3):
    draw_line(Vector2(-28,-16+i*15),Vector2(27,-16+i*15),body,5)
  "SELECT_ALL":
   draw_rect(Rect2(-27,-21,54,42),body,false,3.0)
   for i in range(3): draw_circle(Vector2(-15+i*14,0),5,body)
  "HARVEST":
   draw_rect(Rect2(-30,-5,60,25),body)
   draw_line(Vector2(-20,-15),Vector2(10,-27),edge,5)
  _:
   draw_circle(Vector2.ZERO,19,body)
   draw_line(Vector2(-10,0),Vector2(10,0),ink,3)
