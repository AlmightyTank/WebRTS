extends Control
## Pure Vector2 icons for the production rack and tactical command console.
var icon_name := "power"
var tint := Color("#86ceee")

func configure(id: String) -> void:
 icon_name=id
 queue_redraw()

func _ready() -> void:
 mouse_filter=Control.MOUSE_FILTER_IGNORE
 queue_redraw()

func _draw() -> void:
 var factor=minf(size.x/72.0,size.y/52.0)
 draw_set_transform(size*0.5,0.0,Vector2.ONE*factor)
 var shadow=Color("#0b1117")
 var edge=Color("#92a0ad")
 var body=tint
 draw_ellipse_shadow(shadow)
 match icon_name:
  "EMBLEM":
   draw_colored_polygon(PackedVector2Array([Vector2(0,-26),Vector2(15,-6),Vector2(7,18),Vector2(0,28),Vector2(-7,18),Vector2(-15,-6)]),body)
   draw_line(Vector2(-30,8),Vector2(0,-5),edge,5)
   draw_line(Vector2(0,-5),Vector2(30,8),edge,5)
   draw_circle(Vector2(0,-3),5,Color("#101720"))
  "power":
   for i in range(3):
    draw_rect(Rect2(-25+i*18,-17,12,30),Color("#64798d"))
    draw_circle(Vector2(-19+i*18,-17),6,edge)
   draw_rect(Rect2(-30,10,61,8),body)
  "refinery":
   draw_rect(Rect2(-31,-5,60,23),Color("#778c9d"))
   for i in range(3):
    draw_circle(Vector2(-22+i*22,-10),10,body)
    draw_arc(Vector2(-22+i*22,-10),10,0.0,TAU,14,edge,2.0)
  "barracks":
   draw_colored_polygon(PackedVector2Array([Vector2(-30,0),Vector2(0,-24),Vector2(30,0)]),body)
   draw_rect(Rect2(-29,0,58,19),Color("#61758a"))
   draw_rect(Rect2(-8,5,16,14),shadow)
  "factory","depot":
   draw_rect(Rect2(-33,-14,65,33),body)
   draw_rect(Rect2(-26,-4,50,23),shadow)
   draw_rect(Rect2(-21,2,40,4),edge)
   draw_rect(Rect2(-21,12,40,3),edge)
   draw_rect(Rect2(-32,-20,38,7),edge)
  "turret","a_sentinel_aa":
   draw_circle(Vector2(0,5),21,body)
   draw_rect(Rect2(-5,-23,10,25),edge)
   draw_rect(Rect2(-19,4,38,13),Color("#3b5064"))
   if icon_name=="a_sentinel_aa":
    draw_rect(Rect2(-17,-19,8,24),edge)
    draw_rect(Rect2(9,-19,8,24),edge)
  "a_ranger","a_javelin","a_engineer":
   draw_circle(Vector2(0,-16),9,edge)
   draw_rect(Rect2(-10,-6,20,26),body)
   draw_line(Vector2(-9,1),Vector2(-25,19),edge,4)
   draw_line(Vector2(10,1),Vector2(24,18),edge,4)
   if icon_name=="a_javelin":
    draw_line(Vector2(-19,-8),Vector2(27,-18),Color("#e0ba61"),6)
   elif icon_name=="a_engineer":
    draw_line(Vector2(16,-8),Vector2(25,-27),Color("#e0ba61"),4)
    draw_circle(Vector2(25,-27),5,Color("#e0ba61"))
   else:
    draw_line(Vector2(-15,5),Vector2(26,-5),shadow,5)
  "a_sentinel","a_harvester","a_mcv":
   draw_rect(Rect2(-32,-7,64,25),body)
   draw_rect(Rect2(-24,-17,47,20),Color("#8195a7"))
   draw_rect(Rect2(-32,16,64,5),shadow)
   if icon_name=="a_sentinel":
    draw_circle(Vector2(0,-10),10,Color("#a5b9ca"))
    draw_line(Vector2(0,-12),Vector2(34,-29),edge,7)
   elif icon_name=="a_harvester":
    draw_rect(Rect2(11,-24,22,19),Color("#e0b05d"))
   else:
    draw_line(Vector2(-16,-19),Vector2(4,-34),edge,3)
    draw_circle(Vector2(4,-34),5,edge)
  "MOVE":
   draw_line(Vector2(-27,13),Vector2(12,-13),body,5)
   draw_colored_polygon(PackedVector2Array([Vector2(12,-24),Vector2(32,-13),Vector2(12,-2)]),body)
  "ATTACK_MOVE":
   draw_arc(Vector2.ZERO,22,0.0,TAU,24,Color("#e8b65d"),3)
   draw_line(Vector2(-32,0),Vector2(32,0),Color("#e8b65d"),3)
   draw_line(Vector2(0,-30),Vector2(0,30),Color("#e8b65d"),3)
  "STOP":
   draw_colored_polygon(PackedVector2Array([Vector2(-18,-23),Vector2(18,-23),Vector2(27,-14),Vector2(27,14),Vector2(18,23),Vector2(-18,23),Vector2(-27,14),Vector2(-27,-14)]),Color("#c76f65"))
   draw_rect(Rect2(-11,-11,22,22),shadow)
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
   draw_line(Vector2(-10,0),Vector2(10,0),shadow,3)

func draw_ellipse_shadow(shadow: Color) -> void:
  draw_custom_ellipse(Vector2(0,23),Vector2(32,5),shadow)

func draw_custom_ellipse(center: Vector2,radii: Vector2,color: Color) -> void:
 var pts=PackedVector2Array()
 for i in range(24):
  var a=TAU*float(i)/24.0
  pts.append(center+Vector2(cos(a)*radii.x,sin(a)*radii.y))
 draw_colored_polygon(pts,color)
