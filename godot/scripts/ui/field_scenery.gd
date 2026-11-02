extends RefCounted
## Seeded code-only scenery. Trees have explicit ground collision footprints;
## low shrubs and pebbles are passable decoration. Ore remains harvestable.
const ORE_SITES = [Vector2(630,330),Vector2(580,930),Vector2(1320,820),Vector2(1370,150),Vector2(1080,1010)]

static func road_distance(point: Vector2) -> float:
 return point.distance_to(Geometry2D.get_closest_point_to_segment(point,Vector2(80,960),Vector2(1700,225)))

static func generate(bounds: Rect2, blocked: Array[Rect2]) -> Array[Dictionary]:
 var rng = RandomNumberGenerator.new()
 rng.seed = 77341
 var result: Array[Dictionary] = []
 for attempt in range(260):
  if result.size() >= 42: break
  var p = Vector2(rng.randf_range(65,bounds.size.x-65),rng.randf_range(75,bounds.size.y-65))+bounds.position
  # Keep scenery at the outskirts, leaving both base development areas clear.
  if p.x>250 and p.x<bounds.end.x-250 and p.y>190 and p.y<bounds.end.y-190: continue
  if road_distance(p)<110: continue
  if p.distance_to(Vector2(310,620))<330 or p.distance_to(Vector2(1600,610))<330: continue
  if p.distance_to(Vector2(1080,225))<160: continue
  var clear = true
  for site in ORE_SITES:
   if p.distance_to(site)<135: clear=false
  for obstacle in blocked:
   if obstacle.grow(70).has_point(p): clear=false
  for item in result:
   if p.distance_to(item["position"])<78: clear=false
  if not clear: continue
  var kind = "tree" if result.size()%4==0 else ("shrub" if result.size()%3==0 else "stones")
  result.append({"position":p,"kind":kind,"variant":rng.randi_range(0,4),"bounds":Rect2(p-Vector2(12,12),Vector2(24,24))})
 result.sort_custom(func(a,b): return a["position"].y<b["position"].y)
 return result

static func rock(c: CanvasItem, p: Vector2, size: Vector2, color: Color, height: float) -> void:
 # Faceted boulder with a lit ridge and darker right-hand face.
 var a = p+Vector2(-size.x*0.55,0)
 var b = p+Vector2(-size.x*0.33,-size.y*0.55-height*0.45)
 var d = p+Vector2(size.x*0.23,-size.y*0.62-height)
 var e = p+Vector2(size.x*0.57,-size.y*0.1)
 var f = p+Vector2(size.x*0.35,size.y*0.38)
 var g = p+Vector2(-size.x*0.3,size.y*0.4)
 var ridge = p+Vector2(-size.x*0.02,-size.y*0.18-height*0.35)
 c.draw_colored_polygon(PackedVector2Array([a,b,d,ridge]),color.lightened(0.22))
 c.draw_colored_polygon(PackedVector2Array([a,ridge,f,g]),color)
 c.draw_colored_polygon(PackedVector2Array([ridge,d,e,f]),color.darkened(0.3))

static func ore(c: CanvasItem, p: Vector2, amount: float) -> void:
 # Iron-stained earth stays after the vein is mined. Hematite and magnetite boulders shrink away with the remaining ore.
 var earth = PackedVector2Array()
 for i in range(11):
  var angle = TAU*float(i)/11.0
  var radius = 40.0+float(i%3)*4.0
  earth.append(p+Vector2(cos(angle)*radius,sin(angle)*radius*0.67))
 c.draw_colored_polygon(earth,Color("#6d5344"))
 var offsets = [Vector2(-27,-8),Vector2(-5,-13),Vector2(21,-11),Vector2(-19,8),Vector2(9,6),Vector2(30,10),Vector2(-8,21)]
 var count = ceili(clampf(amount,0,1)*offsets.size())
 var iron = [Color("#8a4636"),Color("#4e565f"),Color("#3e454d")]
 for i in range(count):
  var size = Vector2(16+float(i%3)*3,14+float(i%2)*4)
  rock(c,p+offsets[i],size,iron[i%iron.size()],7+float(i%3)*2)
 if count==0:
  for offset in [Vector2(-12,3),Vector2(18,-8)]:
   rock(c,p+offset,Vector2(7,5),Color("#8b795a"),1)

static func obstacle(c: CanvasItem, bounds: Rect2, index: int) -> void:
 if index%3==1:
  _ruin(c,bounds)
  return
 # Raised rocky outcrop fills the old collision silhouette, rather than
 # leaving large apparently walkable gaps inside a blocked rectangle.
 var p = bounds.position
 var s = bounds.size
 c.draw_colored_polygon(PackedVector2Array([p+Vector2(0,s.y*0.15),p+Vector2(s.x*0.12,0),p+Vector2(s.x*0.9,0),p+Vector2(s.x,s.y*0.13),p+s,p+Vector2(0,s.y)]),Color("#66694f"))
 var rows = maxi(2,ceili(s.y/47.0))
 var rng = RandomNumberGenerator.new()
 rng.seed = int(p.x*13+p.y)
 for row in range(rows):
  var y = p.y+(float(row)+0.6)*s.y/rows
  rock(c,Vector2(p.x+s.x*rng.randf_range(0.29,0.35),y),Vector2(s.x*rng.randf_range(0.59,0.7),s.y/rows*rng.randf_range(0.7,0.94)),Color("#818574").darkened(rng.randf_range(0,0.12)),rng.randf_range(11,27))
  rock(c,Vector2(p.x+s.x*0.73,y+rng.randf_range(1,13)),Vector2(s.x*rng.randf_range(0.48,0.57),s.y/rows*rng.randf_range(0.65,0.87)),Color("#717a69"),rng.randf_range(8,19))

static func _ruin(c: CanvasItem, bounds: Rect2) -> void:
 var p = bounds.position
 var s = bounds.size
 # Rubble-covered industrial foundation, broken walls and rusty beams.
 c.draw_rect(bounds,Color("#696b5c"))
 c.draw_rect(bounds.grow(-5),Color("#858673"))
 for y in range(0,int(s.y),31):
  var top = p+Vector2(0,y)
  c.draw_colored_polygon(PackedVector2Array([top,top+Vector2(8,-10),top+Vector2(16,8),top+Vector2(16,28),top+Vector2(0,28)]),Color("#9c9e8a"))
  c.draw_line(top+Vector2(s.x-7,0),top+Vector2(s.x-7,24),Color("#505f5c"),9)
 var rng = RandomNumberGenerator.new()
 rng.seed = int(p.x*31+p.y)
 for i in range(maxi(8,int(bounds.get_area()/1700))):
  var at = p+Vector2(rng.randf_range(18,s.x-18),rng.randf_range(15,s.y-10))
  rock(c,at,Vector2(rng.randf_range(10,21),12),Color("#8c8e7b"),5)
 c.draw_line(p+Vector2(s.x*0.25,s.y*0.23),p+Vector2(s.x*0.7,s.y*0.73),Color("#6e4e3a"),6)
 c.draw_line(p+Vector2(s.x*0.25,s.y*0.23-2),p+Vector2(s.x*0.7,s.y*0.73-2),Color("#a07951"),2)

static func decoration(c: CanvasItem, item: Dictionary) -> void:
 var p: Vector2 = item["position"]
 var variant: int = item["variant"]
 match item["kind"]:
  "tree":
   c.draw_line(p+Vector2(0,3),p+Vector2(0,-24),Color("#65513a"),5)
   for level in range(3):
    var center = p+Vector2(0,-16-level*12)
    var width = 24.0-level*5+variant
    var tip = center+Vector2(-3,-25)
    c.draw_colored_polygon(PackedVector2Array([center+Vector2(-width,5),tip,center+Vector2(1,10)]),Color("#536e43"))
    c.draw_colored_polygon(PackedVector2Array([tip,center+Vector2(width,3),center+Vector2(1,10)]),Color("#354f37"))
  "shrub":
   for offset in [Vector2(-9,2),Vector2(8,4),Vector2(0,-3)]:
    rock(c,p+offset,Vector2(16,11),Color("#61764a"),5)
  "stones":
   rock(c,p,Vector2(15+variant,11),Color("#8b8d78"),4)
   rock(c,p+Vector2(13,6),Vector2(8,6),Color("#747d68"),2)
