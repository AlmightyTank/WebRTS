extends RefCounted
## Shared code-only low-poly art. Coordinates are ground X/Y plus height Z.
## The projection affects drawing only; navigation and hitboxes remain in 2D.
const STEEL = Color("#687b83")
const CONCRETE = Color("#a7ad9b")
const YELLOW = Color("#efbc45")
const INK = Color("#202e35")

static var _batch_units: bool = false
static var _mesh_vertices := PackedVector2Array()
static var _mesh_colors := PackedColorArray()
static var _mesh_indices := PackedInt32Array()
static var _vehicle_mesh_cache: Dictionary = {}
const VEHICLE_CACHE_LIMIT = 512
const VEHICLE_ANGLE_STEPS = 64
const UNIT_MESH_KINDS = [
 "mcv","harvester","rifleman","missile_team","engineer",
 "tank","heavy_tank","aa","flak","gunship","helicopter"
]

static func _polygon(c: CanvasItem, points: PackedVector2Array, color: Color) -> void:
 if not _batch_units:
  c.draw_colored_polygon(points,color)
  return
 var triangles = Geometry2D.triangulate_polygon(points)
 var base = _mesh_vertices.size()
 _mesh_vertices.append_array(points)
 for point in points: _mesh_colors.append(color)
 for index in triangles: _mesh_indices.append(base+index)

static func _line(c: CanvasItem, a: Vector2, b: Vector2, color: Color, width: float) -> void:
 if not _batch_units:
  c.draw_line(a,b,color,width,true)
  return
 var normal = (b-a).orthogonal().normalized()*width*0.5
 _polygon(c,PackedVector2Array([a-normal,b-normal,b+normal,a+normal]),color)

static func _finish_unit_batch(c: CanvasItem, key: String) -> void:
 var arrays: Array = []
 arrays.resize(Mesh.ARRAY_MAX)
 arrays[Mesh.ARRAY_VERTEX]=_mesh_vertices
 arrays[Mesh.ARRAY_COLOR]=_mesh_colors
 arrays[Mesh.ARRAY_INDEX]=_mesh_indices
 var mesh = ArrayMesh.new()
 mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
 var cache: Dictionary = _vehicle_mesh_cache
 var limit: int = VEHICLE_CACHE_LIMIT
 if cache.size()>=limit:
  cache.erase(cache.keys()[0])
 cache[key]=mesh
 c.draw_mesh(mesh,null)
 _batch_units=false
 _mesh_vertices=PackedVector2Array()
 _mesh_colors=PackedColorArray()
 _mesh_indices=PackedInt32Array()

static func project(p: Vector3, heading: float = 0.0) -> Vector2:
 var ground = Vector2(p.x, p.y).rotated(heading)
 return Vector2(ground.x + ground.y * 0.35, ground.y * 0.72 - p.z)

static func face(c: CanvasItem, points: Array, color: Color, heading: float = 0.0) -> void:
 var polygon = PackedVector2Array()
 for p in points: polygon.append(project(p, heading))
 var area = 0.0
 for i in range(polygon.size()): area+=polygon[i].cross(polygon[(i+1)%polygon.size()])
 if absf(area)<0.001: return # Edge-on faces have no visible area.
 _polygon(c,polygon,color)

static func beam(c: CanvasItem, a: Vector3, b: Vector3, color: Color, width: float, heading: float = 0.0) -> void:
 _line(c,project(a,heading),project(b,heading),color,width)

static func box(c: CanvasItem, origin: Vector3, extent: Vector3, color: Color, heading: float = 0.0) -> void:
 var a = origin
 var b = origin + Vector3(extent.x, 0, 0)
 var d = origin + Vector3(0, extent.y, 0)
 var e = origin + Vector3(extent.x, extent.y, 0)
 var up = Vector3(0, 0, extent.z)
 # Draw only camera-facing walls, then the lit roof. This also handles MCV rotation.
 var corners = [a, b, e, d]
 var normals = [Vector2(0,-1), Vector2(1,0), Vector2(0,1), Vector2(-1,0)]
 for i in range(4):
  var normal: Vector2 = normals[i].rotated(heading)
  if normal.dot(Vector2(-0.35,1)) <= 0: continue
  var shade = 0.20 if normal.x < 0 else 0.38
  face(c,[corners[i],corners[(i+1)%4],corners[(i+1)%4]+up,corners[i]+up],color.darkened(shade),heading)
 face(c,[a+up,b+up,e+up,d+up],color.lightened(0.14),heading)

static func asset_kind(id: String) -> String:
 return {"a_mcv":"mcv","r_mcv":"mcv","a_harvester":"harvester","r_hauler":"harvester","a_ranger":"rifleman","r_line":"rifleman","a_javelin":"missile_team","r_hunter":"missile_team","a_engineer":"engineer","r_engineer":"engineer","a_sentinel":"tank","r_bastion":"heavy_tank","a_sentinel_aa":"aa","r_flak":"flak","a_striker":"gunship","r_siege_heli":"helicopter"}.get(id,id)

static func has_asset(id: String) -> bool:
 return asset_kind(id) in ["mcv","yard","power","refinery","barracks","factory","depot","relay","turret","harvester","rifleman","missile_team","engineer","tank","heavy_tank","aa","flak","gunship","helicopter"]

static func asset_bounds(id: String) -> Rect2:
 var kind = asset_kind(id)
 if kind in ["rifleman","missile_team","engineer"]: return Rect2(-23,-43,54,57)
 if kind in ["mcv","harvester","tank","heavy_tank","aa","flak"]: return Rect2(-53,-61,106,98)
 if kind in ["gunship","helicopter"]: return Rect2(-63,-66,126,110)
 if kind=="relay": return Rect2(-65,-128,130,173)
 return Rect2(-104,-115,208,180)

static func draw_asset(c: CanvasItem, kind: String, team: int = 0, heading: float = 0.0, aim: float = NAN, cargo: float = 0.0) -> void:
 kind = asset_kind(kind)
 var faction = Color("#389fda") if team == 0 else (Color("#d95c45") if team==1 else Color("#919b81"))
 if is_nan(aim): aim=heading
 var vehicle_key := ""
 if kind in UNIT_MESH_KINDS:
  # Reuse one colored mesh rather than submitting every armor plate separately.
  # Quantization only affects artwork; simulation facing/aim remain continuous.
  var hull_frame := posmod(int(round(heading / TAU * VEHICLE_ANGLE_STEPS)), VEHICLE_ANGLE_STEPS)
  var aim_frame := posmod(int(round(aim / TAU * VEHICLE_ANGLE_STEPS)), VEHICLE_ANGLE_STEPS)
  if kind in ["mcv","harvester","gunship","helicopter","a_tempest"]:
   aim_frame = hull_frame # These assets have no independent aiming geometry.
  var cargo_frame := int(ceil(clampf(cargo, 0.0, 1.0) * 16.0)) if kind == "harvester" else 0
  vehicle_key = "%s:%d:%d:%d:%d" % [kind, team, hull_frame, aim_frame, cargo_frame]
  if _vehicle_mesh_cache.has(vehicle_key):
   c.draw_mesh(_vehicle_mesh_cache[vehicle_key], null)
   return
  heading = hull_frame * TAU / VEHICLE_ANGLE_STEPS
  aim = aim_frame * TAU / VEHICLE_ANGLE_STEPS
  if kind == "harvester": cargo = cargo_frame / 16.0
  _batch_units = true
 match kind:
  "mcv": _mcv(c,faction,heading)
  "yard": _yard(c,faction)
  "power": _power(c,faction)
  "refinery": _refinery(c,faction)
  "barracks": _barracks(c,faction)
  "factory": _factory(c,faction)
  "depot": _depot(c,faction)
  "relay": _relay(c,faction)
  "turret":
   _slab(c,Vector2(27,25))
   box(c,Vector3(-16,-14,5),Vector3(32,28,14),STEEL)
   _turret(c,faction,aim,"tank",19)
  "harvester": _harvester(c,faction,heading,cargo)
  "rifleman","missile_team","engineer": _infantry(c,faction,heading,aim,kind)
  "tank","heavy_tank","aa","flak": _tank(c,faction,heading,aim,kind)
  "gunship","helicopter": _aircraft(c,faction,heading,kind)
 if not vehicle_key.is_empty(): _finish_unit_batch(c,vehicle_key)

static func _mcv(c: CanvasItem, color: Color, heading: float) -> void:
 # Six chunky tires, armored chassis, forward cab and folded yellow crane.
 for x in [-20.0,-2.0,19.0]:
  for y in [-19.0,12.0]:
   box(c,Vector3(x-5,y,0),Vector3(10,7,10),INK,heading)
   box(c,Vector3(x-3,y-0.2,3),Vector3(6,7.4,4),STEEL,heading)
 box(c,Vector3(-29,-14,7),Vector3(58,28,8),STEEL,heading)
 box(c,Vector3(-27,-13,15),Vector3(33,26,7),color.darkened(0.18),heading)
 box(c,Vector3(10,-13,15),Vector3(18,26,14),color,heading)
 box(c,Vector3(25,-10,23),Vector3(3,20,4),Color("#143d53"),heading)
 box(c,Vector3(12,-10,29),Vector3(12,20,1),color.lightened(0.25),heading)
 box(c,Vector3(-23,-10,22),Vector3(18,20,5),STEEL,heading)
 for x in [-21.0,-16.0,-11.0]:
  beam(c,Vector3(x,-8,28),Vector3(x,8,28),INK,1.5,heading)
 box(c,Vector3(-6,-5,22),Vector3(10,10,9),YELLOW,heading)
 beam(c,Vector3(-1,0,32),Vector3(-21,0,39),YELLOW.darkened(0.3),7,heading)
 beam(c,Vector3(-21,0,39),Vector3(12,0,39),YELLOW,5,heading)
 beam(c,Vector3(12,0,39),Vector3(12,0,33),INK,1.5,heading)
 beam(c,Vector3(12,0,33),Vector3(16,0,33),YELLOW,2,heading)
 for y in [-10.0,8.0]:
  box(c,Vector3(28,y,17),Vector3(2,3,3),Color("#fff0a5"),heading)
 beam(c,Vector3(31,-13,12),Vector3(31,13,12),INK,3,heading)

static func _foundation(c: CanvasItem, outline: Array) -> void:
 # A thin exposed slab edge, with irregular earth and gravel at ground level.
 var top = []
 var earth = []
 for p in outline:
  top.append(Vector3(p.x,p.y,5))
  earth.append(Vector3(p.x*1.07,p.y*1.08,0))
 face(c,earth,Color("#756d52"))
 for i in range(outline.size()):
  var a: Vector2 = outline[i]
  var b: Vector2 = outline[(i+1)%outline.size()]
  face(c,[Vector3(a.x,a.y,3),Vector3(b.x,b.y,3),Vector3(b.x,b.y,5),Vector3(a.x,a.y,5)],CONCRETE.darkened(0.36))
 face(c,top,CONCRETE.darkened(0.07))
 # Small deterministic chips; no random changes when the object redraws.
 for i in range(outline.size()):
  var a: Vector2 = outline[i]
  var b: Vector2 = outline[(i+1)%outline.size()]
  for t in [0.23,0.69]:
   var p = a.lerp(b,t)*1.04
   face(c,[Vector3(p.x-2,p.y,0),Vector3(p.x+1,p.y-2,0),Vector3(p.x+3,p.y+1,0),Vector3(p.x,p.y+2,0)],Color("#92917b"))

static func _yard(c: CanvasItem, color: Color) -> void:
 # Workshop foundation with a garage apron and a separate crane footing.
 _foundation(c,[Vector2(-64,-49),Vector2(23,-49),Vector2(23,25),Vector2(7,25),Vector2(7,53),Vector2(-57,53),Vector2(-57,25),Vector2(-64,25)])
 _foundation(c,[Vector2(29,-36),Vector2(64,-36),Vector2(64,3),Vector2(29,3)])
 _foundation(c,[Vector2(29,21),Vector2(60,21),Vector2(60,49),Vector2(29,49)])
 beam(c,Vector3(-57,26,5.1),Vector3(7,26,5.1),Color("#767e70"),0.8)
 beam(c,Vector3(-57,40,5.1),Vector3(7,40,5.1),Color("#767e70"),0.8)
 beam(c,Vector3(-25,26,5.1),Vector3(-25,53,5.1),Color("#767e70"),0.8)
 # Workshop with raised roof ribs, roller door and unloading apron.
 box(c,Vector3(-57,-43,5),Vector3(73,62,32),STEEL)
 box(c,Vector3(-60,-46,37),Vector3(79,68,5),color)
 for x in [-49.0,-32.0,-15.0,2.0]:
  beam(c,Vector3(x,-42,43),Vector3(x,17,43),color.lightened(0.35),2)
 box(c,Vector3(-42,19,5),Vector3(41,2,26),INK)
 for z in [10.0,16.0,22.0,28.0]:
  beam(c,Vector3(-39,22,z),Vector3(-4,22,z),STEEL,2)
 face(c,[Vector3(-49,27,5.2),Vector3(0,27,5.2),Vector3(0,35,5.2),Vector3(-49,35,5.2)],INK)
 for x in [-45.0,-33.0,-21.0,-9.0]:
  face(c,[Vector3(x,27,5.3),Vector3(x+6,27,5.3),Vector3(x+1,35,5.3),Vector3(x-5,35,5.3)],YELLOW)
 box(c,Vector3(-56,-38,42),Vector3(20,18,8),STEEL)
 for x in [-53.0,-47.0,-41.0]:
  beam(c,Vector3(x,-36,51),Vector3(x,-23,51),INK,2)
 # Lattice crane with counterweight, suspended hook and large yellow boom.
 box(c,Vector3(35,-31,5),Vector3(24,29,9),STEEL)
 for x in [39.0,53.0]:
  beam(c,Vector3(x,-19,14),Vector3(x,-19,75),YELLOW,4)
 for z in [16.0,31.0,46.0,61.0]:
  beam(c,Vector3(39,-19,z),Vector3(53,-19,z+14),YELLOW.darkened(0.15),2)
  beam(c,Vector3(53,-19,z),Vector3(39,-19,z+14),YELLOW.darkened(0.15),2)
 box(c,Vector3(34,-29,68),Vector3(26,22,10),color)
 beam(c,Vector3(15,-19,80),Vector3(70,-19,80),YELLOW,7)
 beam(c,Vector3(42,-19,94),Vector3(15,-19,80),STEEL,1.5)
 beam(c,Vector3(42,-19,94),Vector3(70,-19,80),STEEL,1.5)
 beam(c,Vector3(66,-19,79),Vector3(66,-19,38),INK,1.5)
 beam(c,Vector3(66,-19,38),Vector3(62,-19,34),YELLOW,3)
 beam(c,Vector3(62,-19,34),Vector3(58,-19,38),YELLOW,3)
 box(c,Vector3(34,25,5),Vector3(22,20,16),YELLOW.darkened(0.12))
 beam(c,Vector3(37,46,10),Vector3(51,46,10),INK,3)

static func _tower(c: CanvasItem, center: Vector2) -> void:
 # Octagonal tapered cooling tower; each face has a deliberately flat shade.
 var base = []
 var waist = []
 var rim = []
 for i in range(8):
  var a = TAU*float(i)/8.0
  base.append(Vector3(center.x+cos(a)*18,center.y+sin(a)*18,7))
  waist.append(Vector3(center.x+cos(a)*11,center.y+sin(a)*11,37))
  rim.append(Vector3(center.x+cos(a)*15,center.y+sin(a)*15,66))
 for i in [4,5,6,7,0,1,2,3]:
  var j = (i+1)%8
  var shade = [0.12,0.23,0.32,0.28,0.14,0.02,0.0,0.04][i]
  face(c,[base[i],base[j],waist[j],waist[i]],CONCRETE.darkened(shade))
  face(c,[waist[i],waist[j],rim[j],rim[i]],CONCRETE.darkened(shade))
 face(c,rim,Color("#cbd0bd"))
 var opening = []
 for i in range(8):
  var a = TAU*float(i)/8.0
  opening.append(Vector3(center.x+cos(a)*10,center.y+sin(a)*10,66.2))
 face(c,opening,INK)

static func _power(c: CanvasItem, color: Color) -> void:
 _foundation(c,[Vector2(-45,-41),Vector2(41,-41),Vector2(41,8),Vector2(44,8),Vector2(44,40),Vector2(17,40),Vector2(17,45),Vector2(-19,45),Vector2(-19,40),Vector2(-44,40),Vector2(-44,8),Vector2(-45,8)])
 beam(c,Vector3(-44,3,5.1),Vector3(41,3,5.1),Color("#767e70"),0.8)
 beam(c,Vector3(-2,-41,5.1),Vector3(-2,8,5.1),Color("#767e70"),0.8)
 _tower(c,Vector2(-24,-19))
 _tower(c,Vector2(20,-19))
 # Turbine hall, exposed supply pipes and front-facing switch cabinet.
 box(c,Vector3(-36,9,5),Vector3(73,27,22),STEEL)
 box(c,Vector3(-39,7,27),Vector3(79,31,5),color)
 for x in [-28.0,-15.0,-2.0,11.0,24.0]:
  beam(c,Vector3(x,11,33),Vector3(x,33,33),color.darkened(0.3),3)
 for x in [-24.0,20.0]:
  beam(c,Vector3(x,-3,16),Vector3(x,4,16),YELLOW,5)
  beam(c,Vector3(x,4,16),Vector3(x+8,4,16),YELLOW,5)
 box(c,Vector3(-14,36,5),Vector3(25,5,17),INK)
 for x in [-9.0,-1.0,7.0]:
  beam(c,Vector3(x,42,13),Vector3(x,42,19),Color("#9aebbf"),2)

static func _slab(c: CanvasItem, half: Vector2) -> void:
 _foundation(c,[Vector2(-half.x,-half.y),Vector2(half.x,-half.y),half,Vector2(-half.x,half.y)])
 beam(c,Vector3(0,-half.y,5.1),Vector3(0,half.y,5.1),Color("#777e70"),0.8)

static func _hazards(c: CanvasItem, x: float, y: float, width: float) -> void:
 face(c,[Vector3(x,y,5.2),Vector3(x+width,y,5.2),Vector3(x+width,y+8,5.2),Vector3(x,y+8,5.2)],INK)
 for i in range(int(width/12)):
  var at=x+4+i*12
  face(c,[Vector3(at,y,5.3),Vector3(at+6,y,5.3),Vector3(at+2,y+8,5.3),Vector3(at-4,y+8,5.3)],YELLOW)

static func _cylinder(c: CanvasItem, center: Vector3, radius: float, height: float, color: Color) -> void:
 var roof=[]
 for i in range(8):
  var a=TAU*float(i)/8.0
  var b=TAU*float(i+1)/8.0
  var p=center+Vector3(cos(a)*radius,sin(a)*radius,0)
  var q=center+Vector3(cos(b)*radius,sin(b)*radius,0)
  var normal=Vector2(cos((a+b)*0.5),sin((a+b)*0.5))
  if normal.dot(Vector2(-0.35,1))>0:
   var shade=0.12+0.3*(1.0-normal.dot(Vector2(-0.8,-0.6)))*0.5
   face(c,[p,q,q+Vector3(0,0,height),p+Vector3(0,0,height)],color.darkened(shade))
  roof.append(p+Vector3(0,0,height))
 face(c,roof,color.lightened(0.18))

static func _refinery(c: CanvasItem, color: Color) -> void:
 _slab(c,Vector2(63,50))
 box(c,Vector3(-56,-36,5),Vector3(45,59,35),STEEL)
 box(c,Vector3(-59,-39,40),Vector3(51,65,5),color)
 box(c,Vector3(-48,-26,45),Vector3(13,14,26),STEEL)
 box(c,Vector3(-50,-28,71),Vector3(17,18,3),INK)
 # Rear tanks first, then the front tank. Leave actual ground clearance
 # between the octagonal rims instead of intersecting their silhouettes.
 for at in [Vector2(24,-27),Vector2(49,-27),Vector2(37,14)]:
  # Keep the complete projected tank silhouette clear of the workshop wall.
  # A narrow base ring makes contact with the slab visible at game scale.
  _cylinder(c,Vector3(at.x,at.y,5),12,2,STEEL)
  _cylinder(c,Vector3(at.x,at.y,7),11,28,CONCRETE)
  _cylinder(c,Vector3(at.x,at.y,35),11.5,3,color)
  box(c,Vector3(at.x-2,at.y-2,38),Vector3(4,4,3),STEEL)
 beam(c,Vector3(-10,17,16),Vector3(30,17,16),YELLOW,5)
 box(c,Vector3(-43,25,5),Vector3(43,3,20),INK)
 _hazards(c,-50,33,54)
 beam(c,Vector3(-45,48,5.1),Vector3(-45,41,5.1),YELLOW,2)
 beam(c,Vector3(0,48,5.1),Vector3(0,41,5.1),YELLOW,2)

static func _barracks(c: CanvasItem, color: Color) -> void:
 _slab(c,Vector2(45,40))
 box(c,Vector3(-35,-29,5),Vector3(65,58,27),CONCRETE)
 # Gabled faction roof, distinct from the industrial flat roofs.
 face(c,[Vector3(-39,-33,32),Vector3(-39,33,32),Vector3(-5,33,49),Vector3(-5,-33,49)],color.lightened(0.18))
 face(c,[Vector3(-5,-33,49),Vector3(-5,33,49),Vector3(34,33,32),Vector3(34,-33,32)],color.darkened(0.15))
 face(c,[Vector3(-35,29,32),Vector3(-5,29,48),Vector3(30,29,32)],STEEL)
 box(c,Vector3(-12,29,5),Vector3(19,2,22),INK)
 box(c,Vector3(-16,28,27),Vector3(28,8,3),color)
 for x in [-29.0,16.0]:
  box(c,Vector3(x,29,17),Vector3(9,1,8),Color("#344f58"))
 beam(c,Vector3(39,-22,5),Vector3(39,-22,61),STEEL,2)
 face(c,[Vector3(39,-22,59),Vector3(59,-22,56),Vector3(54,-22,44),Vector3(39,-22,46)],color)
 beam(c,Vector3(-11,40,5),Vector3(8,40,5),CONCRETE.lightened(0.2),3)

static func _factory(c: CanvasItem, color: Color) -> void:
 _slab(c,Vector2(65,51))
 box(c,Vector3(-54,-41,5),Vector3(108,69,35),STEEL)
 box(c,Vector3(-57,-44,40),Vector3(114,75,6),color)
 for x in [-43.0,-20.0,3.0,26.0,49.0]:
  beam(c,Vector3(x,-39,47),Vector3(x,26,47),color.lightened(0.32),2)
 box(c,Vector3(-35,28,5),Vector3(69,2,28),INK)
 for z in [11.0,18.0,25.0]:
  beam(c,Vector3(-31,31,z),Vector3(30,31,z),STEEL,2)
 for x in [-39.0,37.0]:
  box(c,Vector3(x,29,11),Vector3(4,3,18),YELLOW)
 for x in [-40.0,16.0]:
  box(c,Vector3(x,-29,46),Vector3(22,25,7),STEEL)
  for offset in [4.0,10.0,16.0]:
   beam(c,Vector3(x+offset,-26,54),Vector3(x+offset,-7,54),INK,2)
 _hazards(c,-43,35,84)
 beam(c,Vector3(-28,48,5.1),Vector3(27,48,5.1),Color("#777e70"),1)

static func _depot(c: CanvasItem, color: Color) -> void:
 _slab(c,Vector2(52,44))
 # Open repair bay with two ramps, lift arms and an overhead gantry.
 for x in [-25.0,15.0]:
  box(c,Vector3(x,-28,5),Vector3(10,57,4),STEEL)
  beam(c,Vector3(x+5,-24,10),Vector3(x+5,25,10),YELLOW,2)
 for x in [-45.0,37.0]:
  box(c,Vector3(x,-24,5),Vector3(8,14,48),color)
 beam(c,Vector3(-41,-17,54),Vector3(41,-17,54),YELLOW,7)
 beam(c,Vector3(0,-17,54),Vector3(0,-17,23),INK,1.5)
 beam(c,Vector3(0,-17,23),Vector3(5,-17,20),YELLOW,3)
 box(c,Vector3(31,14,5),Vector3(15,18,16),color)
 for z in [10.0,15.0]:
  beam(c,Vector3(33,33,z),Vector3(43,33,z),STEEL,1)
 _hazards(c,-36,34,72)

static func _relay(c: CanvasItem, color: Color) -> void:
 _slab(c,Vector2(36,32))
 box(c,Vector3(-27,-21,5),Vector3(54,42,24),STEEL)
 box(c,Vector3(-30,-24,29),Vector3(60,48,4),color)
 box(c,Vector3(-15,21,5),Vector3(14,2,20),INK)
 box(c,Vector3(8,22,16),Vector3(12,1,8),Color("#9aebbf"))
 for x in [-12.0,12.0]:
  beam(c,Vector3(x,-4,33),Vector3(0,-4,93),STEEL,3)
 for z in [40.0,53.0,66.0]:
  beam(c,Vector3(-9,-4,z),Vector3(8,-4,z+12),YELLOW,1.5)
 face(c,[Vector3(-18,-5,91),Vector3(1,-13,105),Vector3(23,-5,93),Vector3(1,3,82)],CONCRETE)
 face(c,[Vector3(-18,-5,91),Vector3(1,3,82),Vector3(23,-5,93),Vector3(1,-5,89)],STEEL)
 beam(c,Vector3(1,-5,89),Vector3(1,-5,103),YELLOW,2)

static func _tracks(c: CanvasItem, heading: float, heavy: bool) -> void:
 var length = 54.0 if heavy else 46.0
 for y in [-20.0,12.0]:
  box(c,Vector3(-length*0.5,y,0),Vector3(length,8,10),INK,heading)
  for x in range(-int(length*0.5)+3,int(length*0.5)-1,8):
   box(c,Vector3(x,y+0.5,8),Vector3(4,7,2),STEEL,heading)

static func _turret(c: CanvasItem, color: Color, aim: float, kind: String, z: float) -> void:
 box(c,Vector3(-10,-10,z),Vector3(21,20,8),color,aim)
 if kind in ["aa","flak"]:
  for y in [-7.0,5.0]:
   box(c,Vector3(-8,y,z+8),Vector3(26,5,6),STEEL,aim)
   beam(c,Vector3(17,y+2,z+11),Vector3(31,y+2,z+15),INK,3,aim)
  beam(c,Vector3(-7,0,z+8),Vector3(-7,0,z+22),STEEL,1.5,aim)
  face(c,[Vector3(-15,0,z+21),Vector3(-7,-3,z+25),Vector3(1,0,z+21)],color.lightened(0.15),aim)
  face(c,[Vector3(-15,0,z+21),Vector3(1,0,z+21),Vector3(-7,3,z+18)],color,aim)
 else:
  for y in ([-5.0,5.0] if kind=="heavy_tank" else [0.0]):
   beam(c,Vector3(7,y,z+5),Vector3(34,y,z+5),STEEL,4,aim)
   box(c,Vector3(30,y-2.5,z+2.5),Vector3(7,5,5),INK,aim)
  box(c,Vector3(-6,-5,z+8),Vector3(9,10,2),STEEL,aim)

static func _tank(c: CanvasItem, color: Color, heading: float, aim: float, kind: String) -> void:
 var heavy = kind=="heavy_tank"
 _tracks(c,heading,heavy)
 box(c,Vector3(-24 if heavy else -20,-13,7),Vector3(48 if heavy else 40,26,9),color.darkened(0.1),heading)
 box(c,Vector3(-17,-11,16),Vector3(32,22,3),color,heading)
 for x in [-16.0,-11.0,-6.0]:
  beam(c,Vector3(x,-7,20),Vector3(x,7,20),INK,1.5,heading)
 for y in [-11.0,9.0]:
  box(c,Vector3(18,y,13),Vector3(3,3,2),Color("#ffe3a2"),heading)
 _turret(c,color,aim,kind,19)

static func _harvester(c: CanvasItem, color: Color, heading: float, cargo: float) -> void:
 for x in [-22.0,0.0,22.0]:
  for y in [-20.0,13.0]:
   box(c,Vector3(x-5,y,0),Vector3(10,7,11),INK,heading)
 box(c,Vector3(-30,-15,8),Vector3(60,30,8),STEEL,heading)
 box(c,Vector3(13,-13,16),Vector3(17,26,13),color,heading)
 box(c,Vector3(28,-10,22),Vector3(3,20,5),Color("#244b60"),heading)
 box(c,Vector3(-28,-14,16),Vector3(36,28,2),INK,heading)
 if cargo>0:
  for x in [-20.0,-7.0]:
   box(c,Vector3(x,-8,18),Vector3(9,16,clampf(cargo,0,1)*9),YELLOW.darkened(0.2),heading)
 for y in [-15.0,12.0]:
  box(c,Vector3(-29,y,16),Vector3(38,3,10),YELLOW,heading)
 box(c,Vector3(-30,-12,16),Vector3(3,24,10),YELLOW,heading)
 beam(c,Vector3(30,-11,10),Vector3(38,-11,4),STEEL,3,heading)
 beam(c,Vector3(30,11,10),Vector3(38,11,4),STEEL,3,heading)
 box(c,Vector3(35,-17,2),Vector3(7,34,5),YELLOW,heading)

static func _infantry(c: CanvasItem, color: Color, heading: float, aim: float, kind: String) -> void:
 for y in [-5.0,2.0]:
  box(c,Vector3(-4,y,0),Vector3(10,4,4),INK,heading)
  box(c,Vector3(-3,y,4),Vector3(5,4,8),STEEL,heading)
 box(c,Vector3(-6,-6,12),Vector3(12,12,11),color,heading)
 box(c,Vector3(-4,-4,23),Vector3(8,8,6),Color("#c5ab7f"),heading)
 box(c,Vector3(-6,-6,28),Vector3(12,12,3),color,heading)
 box(c,Vector3(4,-4,25),Vector3(1,8,3),INK,heading)
 box(c,Vector3(-9,-5,13),Vector3(3,10,9),STEEL,heading)
 if kind=="missile_team":
  beam(c,Vector3(-9,-6,23),Vector3(20,-6,23),STEEL,5,aim)
  box(c,Vector3(17,-9,20),Vector3(6,6,6),YELLOW,aim)
 elif kind=="engineer":
  box(c,Vector3(-6,-6,28),Vector3(12,12,4),YELLOW,heading)
  box(c,Vector3(0,8,5),Vector3(10,6,7),YELLOW,heading)
  beam(c,Vector3(5,-8,15),Vector3(15,-8,17),STEEL,2,aim)
 else:
  beam(c,Vector3(3,-7,17),Vector3(19,-7,17),INK,3,aim)
  box(c,Vector3(1,-8,15),Vector3(6,3,5),STEEL,aim)

static func _aircraft(c: CanvasItem, color: Color, heading: float, kind: String) -> void:
 # Tilted faceted fuselage, cockpit, stub wings and separate weapon pods.
 var z=16.0
 face(c,[Vector3(-33,0,z),Vector3(-15,-9,z),Vector3(18,-8,z),Vector3(32,0,z),Vector3(18,9,z),Vector3(-15,9,z)],color.darkened(0.18),heading)
 var hull = [Vector3(-33,0,z),Vector3(-15,-9,z),Vector3(18,-8,z),Vector3(32,0,z),Vector3(18,9,z),Vector3(-15,9,z)]
 for i in range(hull.size()):
  face(c,[hull[i],hull[(i+1)%hull.size()],Vector3(0,0,z+11)],color.lightened(0.18) if i<3 else color,heading)
 face(c,[Vector3(15,0,z+12),Vector3(29,0,z+3),Vector3(18,8,z+1)],Color("#244859"),heading)
 face(c,[Vector3(15,0,z+12),Vector3(18,8,z+1),Vector3(10,7,z+7)],Color("#315d6d"),heading)
 for side in [-1.0,1.0]:
  face(c,[Vector3(-8,side*6,z+3),Vector3(-16,side*27,z),Vector3(5,side*25,z),Vector3(12,side*7,z+3)],color,heading)
  box(c,Vector3(-10,side*23-3,z-4),Vector3(23,6,6),STEEL,heading)
  for x in [-5.0,3.0]:
   beam(c,Vector3(x,side*23,z-3),Vector3(x+13,side*23,z-3),YELLOW,2,heading)
 if kind=="helicopter":
  beam(c,Vector3(-14,0,z),Vector3(-49,0,z+2),STEEL,4,heading)
  beam(c,Vector3(-49,-9,z+2),Vector3(-49,9,z+2),INK,2,heading)
  beam(c,Vector3(0,0,z+10),Vector3(0,0,z+19),STEEL,2,heading)
  beam(c,Vector3(-38,0,z+19),Vector3(38,0,z+19),INK,3,heading)
  beam(c,Vector3(0,-38,z+19),Vector3(0,38,z+19),STEEL,2,heading)
 else:
  for y in [-17.0,17.0]:
   box(c,Vector3(-17,y-5,z+3),Vector3(19,10,7),STEEL,heading)
   beam(c,Vector3(-15,y,z+11),Vector3(-1,y,z+11),INK,2,heading)
