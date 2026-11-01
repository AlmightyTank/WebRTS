extends RefCounted
## Shared code-only low-poly art. Coordinates are ground X/Y plus height Z.
## The projection affects drawing only; navigation and hitboxes remain in 2D.
const STEEL = Color("#687b83")
const CONCRETE = Color("#a7ad9b")
const YELLOW = Color("#efbc45")
const INK = Color("#202e35")
static var _depth_faces: Array[Dictionary] = []
static var _collect_depth: bool = false
static var _building_doors: Array[Array] = []
static var _batch_building: bool = false
static var _mesh_vertices := PackedVector2Array()
static var _mesh_colors := PackedColorArray()
static var _mesh_indices := PackedInt32Array()
static var _building_mesh_cache: Dictionary = {}
static var _vehicle_mesh_cache: Dictionary = {}
const BUILDING_CACHE_LIMIT = 128
const VEHICLE_CACHE_LIMIT = 512
const VEHICLE_ANGLE_STEPS = 64
const UNIT_MESH_KINDS = [
 "mcv","harvester","rifleman","missile_team","engineer",
 "tank","heavy_tank","aa","flak","gunship","helicopter",
 "a_arc_lance","a_tempest","r_stormrail","g_volley",
 "a_ghost_carrier","r_siege_carrier","g_ghost_technical",
 "r_imperator","g_junker","g_junker_salvage_1","g_junker_salvage_2"
]

static func _polygon(c: CanvasItem, points: PackedVector2Array, color: Color) -> void:
 if not _batch_building:
  c.draw_colored_polygon(points,color)
  return
 var triangles = Geometry2D.triangulate_polygon(points)
 var base = _mesh_vertices.size()
 _mesh_vertices.append_array(points)
 for point in points: _mesh_colors.append(color)
 for index in triangles: _mesh_indices.append(base+index)

static func _line(c: CanvasItem, a: Vector2, b: Vector2, color: Color, width: float) -> void:
 if not _batch_building:
  c.draw_line(a,b,color,width,true)
  return
 var normal = (b-a).orthogonal().normalized()*width*0.5
 _polygon(c,PackedVector2Array([a-normal,b-normal,b+normal,a+normal]),color)

static func _finish_building_batch(c: CanvasItem, key: String, vehicle: bool = false) -> void:
 var arrays: Array = []
 arrays.resize(Mesh.ARRAY_MAX)
 arrays[Mesh.ARRAY_VERTEX]=_mesh_vertices
 arrays[Mesh.ARRAY_COLOR]=_mesh_colors
 arrays[Mesh.ARRAY_INDEX]=_mesh_indices
 var mesh = ArrayMesh.new()
 mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
 var cache: Dictionary = _vehicle_mesh_cache if vehicle else _building_mesh_cache
 var limit: int = VEHICLE_CACHE_LIMIT if vehicle else BUILDING_CACHE_LIMIT
 if cache.size()>=limit:
  cache.erase(cache.keys()[0])
 cache[key]=mesh
 c.draw_mesh(mesh,null)
 _batch_building=false
 _mesh_vertices=PackedVector2Array()
 _mesh_colors=PackedColorArray()
 _mesh_indices=PackedInt32Array()

static func _depth(points: Array, heading: float) -> float:
 var center = Vector3.ZERO
 for p in points:
  var ground = Vector2(p.x,p.y).rotated(heading)
  center += Vector3(ground.x,ground.y,p.z)
 center /= float(points.size())
 # Camera direction is the null axis of project(): (-0.35, 1, 0.72).
 return center.dot(Vector3(-0.35,1.0,0.72))

static func _flush_depth(c: CanvasItem) -> void:
 _depth_faces.sort_custom(func(a: Dictionary,b: Dictionary) -> bool: return a.depth<b.depth)
 for item in _depth_faces:
  if item.has("width"):
   _line(c,item.points[0],item.points[1],item.color,item.width)
  else:
   _polygon(c,item.points,item.color)
 _depth_faces.clear()
 _collect_depth=false

static func project(p: Vector3, heading: float = 0.0) -> Vector2:
 var ground = Vector2(p.x, p.y).rotated(heading)
 return Vector2(ground.x + ground.y * 0.35, ground.y * 0.72 - p.z)

static func face(c: CanvasItem, points: Array, color: Color, heading: float = 0.0) -> void:
 var polygon = PackedVector2Array()
 for p in points: polygon.append(project(p, heading))
 var area = 0.0
 for i in range(polygon.size()): area+=polygon[i].cross(polygon[(i+1)%polygon.size()])
 if absf(area)<0.001: return # Edge-on faces have no visible area.
 if _collect_depth:
  _depth_faces.append({"points":polygon,"color":color,"depth":_depth(points,heading)})
 else:
  _polygon(c,polygon,color)

static func beam(c: CanvasItem, a: Vector3, b: Vector3, color: Color, width: float, heading: float = 0.0) -> void:
 if _collect_depth:
  _depth_faces.append({"points":PackedVector2Array([project(a,heading),project(b,heading)]),"color":color,"width":width,"depth":_depth([a,b],heading)+0.01})
 else:
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
 if id in ["a_ghost_carrier","r_siege_carrier","g_ghost_technical"]: return true
 if id in ["a_tempest","r_stormrail","g_volley"]: return true
 if id in ["a_arc_lance","r_imperator","g_junker","g_junker_salvage_1","g_junker_salvage_2"]: return true
 return asset_kind(id) in ["mcv","yard","power","refinery","barracks","factory","depot","relay","turret","harvester","rifleman","missile_team","engineer","tank","heavy_tank","aa","flak","gunship","helicopter"]

static func asset_bounds(id: String) -> Rect2:
 if id in ["a_ghost_carrier","r_siege_carrier","g_ghost_technical"]: return Rect2(-82,-100,164,170)
 if id in ["a_tempest","r_stormrail","g_volley"]: return Rect2(-90,-110,180,180)
 if id in ["a_arc_lance","r_imperator","g_junker","g_junker_salvage_1","g_junker_salvage_2"]: return Rect2(-82,-100,164,170)
 var kind = asset_kind(id)
 if kind in ["rifleman","missile_team","engineer"]: return Rect2(-23,-43,54,57)
 if kind in ["mcv","harvester","tank","heavy_tank","aa","flak"]: return Rect2(-53,-61,106,98)
 if kind in ["gunship","helicopter"]: return Rect2(-63,-66,126,110)
 if kind=="relay": return Rect2(-65,-128,130,173)
 return Rect2(-104,-115,208,180)

static func draw_asset(c: CanvasItem, kind: String, team: int = 0, heading: float = 0.0, aim: float = NAN, cargo: float = 0.0, animation: Dictionary = {}) -> void:
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
  _batch_building = true
 var building_key := ""
 if kind in ["yard","power","barracks","refinery","factory","depot"]:
  # Share identical animation frames across instances; bound retained GPU memory.
  var frame = int(float(animation.get("time",0.0))*20.0)
  var door_frame = int(round(float(animation.get("door",0.0))*16.0))
  building_key="%s:%d:%d:%d:%s" % [kind,team,frame,door_frame,animation.get("working",false)]
  if _building_mesh_cache.has(building_key):
   c.draw_mesh(_building_mesh_cache[building_key],null)
   return
  animation=animation.duplicate()
  animation["time"]=frame/20.0
  animation["door"]=door_frame/16.0
  _batch_building=true
 var depth_sorted = kind in ["a_arc_lance","r_imperator","g_junker","g_junker_salvage_1","g_junker_salvage_2"]
 if depth_sorted:
  _depth_faces.clear()
  _collect_depth=false
 match kind:
  "mcv": _mcv(c,faction,heading)
  "a_arc_lance": _arc_lance(c,faction,heading,aim)
  "a_tempest": _tempest(c,faction,heading)
  "r_stormrail": _stormrail(c,faction,heading,aim)
  "g_volley": _volley(c,faction,heading,aim)
  "a_ghost_carrier": _ghost_carrier(c,faction,heading,aim)
  "r_siege_carrier": _siege_carrier(c,faction,heading,aim)
  "g_ghost_technical": _ghost_technical(c,faction,heading,aim)
  "r_imperator": _imperator(c,faction,heading,aim)
  "g_junker","g_junker_salvage_1","g_junker_salvage_2":
   _junker(c,faction,heading,aim,2 if kind.ends_with("_2") else (1 if kind.ends_with("_1") else 0))
  "yard": _faction_building(c,"yard",team,faction,animation)
  "power": _faction_building(c,"power",team,faction,animation)
  "refinery": _faction_industry(c,"refinery",team,faction,animation)
  "barracks": _faction_building(c,"barracks",team,faction,animation)
  "factory": _faction_industry(c,"factory",team,faction,animation)
  "depot": _faction_industry(c,"depot",team,faction,animation)
  "relay": _relay(c,faction)
  "turret":
   _slab(c,Vector2(27,25))
   box(c,Vector3(-16,-14,5),Vector3(32,28,14),STEEL)
   _turret(c,faction,aim,"tank",19)
  "harvester": _harvester(c,faction,heading,cargo)
  "rifleman","missile_team","engineer": _infantry(c,faction,heading,aim,kind)
  "tank","heavy_tank","aa","flak": _tank(c,faction,heading,aim,kind)
  "gunship","helicopter": _aircraft(c,faction,heading,kind)
 if depth_sorted: _flush_depth(c)
 if not vehicle_key.is_empty(): _finish_building_batch(c,vehicle_key,true)
 if not building_key.is_empty(): _finish_building_batch(c,building_key)

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

static func building_exit(team: int) -> Vector2:
 # Ground-space centers of the front personnel doors, projected to the map.
 return project(Vector3(37,15,0)) if team==0 else (project(Vector3(2,30,0)) if team==1 else project(Vector3(-29,27,0)))

static func _building_door(c: CanvasItem, origin: Vector3, width: float, height: float, opening: float, color: Color, style: int) -> void:
 if _collect_depth:
  _building_doors.append([origin,width,height,opening,color,style])
  return
 box(c,origin,Vector3(width,0.6,height),INK)
 var amount = clampf(opening,0.0,1.0)
 if style==0: # Sectional service shutter lifts vertically.
  box(c,origin+Vector3(0,0.8,height*amount),Vector3(width,1.2,height*(1.0-amount)+0.1),color)
  for i in range(1,5):
   var z = height*amount+height*(1.0-amount)*i/5.0
   beam(c,origin+Vector3(0,2.1,z),origin+Vector3(width,2.1,z),STEEL.darkened(0.3),0.7)
 else: # Independent sliding leaves (armored panels or light canvas).
  # Panels retract into wall pockets, rather than passing through buttresses
  # or floating beyond the building when fully open.
  var remaining = width*0.5*(1.0-amount)
  for side in [-1.0,1.0]:
   if remaining<0.05: continue
   var x = width-remaining if side>0 else 0.0
   box(c,origin+Vector3(x,0.8,0),Vector3(remaining,1.2,height),color)
 box(c,origin+Vector3(-2,0,0),Vector3(2,3,height+2),STEEL)
 box(c,origin+Vector3(width,0,0),Vector3(2,3,height+2),STEEL)
 box(c,origin+Vector3(-2,0,height),Vector3(width+4,3,2),STEEL)

static func _roof_fan(c: CanvasItem, center: Vector3, phase: float, size: float) -> void:
 box(c,center-Vector3(size,size,2),Vector3(size*2,size*2,2),INK)
 for blade in range(4):
  var angle = phase+blade*PI*0.5
  var along = Vector3(cos(angle),sin(angle),0)
  var across = Vector3(-sin(angle),cos(angle),0)
  face(c,[center+along*2-across,center+along*size-across*2,center+along*size+across*2,center+along*2+across],STEEL)

static func _faction_building(c: CanvasItem, role: String, team: int, color: Color, animation: Dictionary = {}) -> void:
 # Role footprints remain shared; geometry communicates faction construction culture.
 _building_doors.clear()
 _foundation(c,[Vector2(-62,-43),Vector2(60,-43),Vector2(60,45),Vector2(-62,45)])
 _collect_depth=true
 var phase: float = animation.get("time",0.0)
 var door: float = animation.get("door",0.0)
 var working: bool = animation.get("working",false)
 if team==0:
  if role=="yard":
   box(c,Vector3(-51,-33,5),Vector3(65,55,28),STEEL)
   box(c,Vector3(-54,-35,33),Vector3(71,59,4),color)
   _building_door(c,Vector3(-43,22.1,5),45,23,door,color.darkened(0.35),0)
   for x in [25.0,49.0]:
    box(c,Vector3(x,-27,5),Vector3(5,54,49),STEEL)
   box(c,Vector3(23,-29,54),Vector3(33,58,5),color)
   var trolley = sin(phase*(1.2 if working else 0.35))*17.0
   var hook_z = 24.0+sin(phase*0.7)*6.0
   box(c,Vector3(34,trolley-5,51),Vector3(10,10,4),STEEL)
   beam(c,Vector3(39,trolley,51),Vector3(39,trolley,hook_z),YELLOW,2)
   box(c,Vector3(34,trolley-5,hook_z-3),Vector3(10,10,3),YELLOW)
  elif role=="power":
   box(c,Vector3(-29,-24,5),Vector3(58,48,17),STEEL)
   box(c,Vector3(-21,-17,22),Vector3(42,34,32),color)
   box(c,Vector3(-15,-11,54),Vector3(30,22,5),STEEL)
   for x in [-46.0,34.0]:
    box(c,Vector3(x,-24,5),Vector3(12,48,26),color)
    for y in [-17.0,-5.0,7.0]:
     box(c,Vector3(x+2,y,31),Vector3(8,7,2),Color("#8adce5"))
  else:
   box(c,Vector3(-50,-27,5),Vector3(76,54,22),STEEL)
   box(c,Vector3(-53,-30,27),Vector3(82,60,4),color)
   box(c,Vector3(25,-14,5),Vector3(24,28,32),color)
   _building_door(c,Vector3(30,14.1,5),14,23,door,STEEL,1)
   for x in [-39.0,-19.0,1.0]:
    box(c,Vector3(x,27,16),Vector3(12,1,5),Color("#244b60"))
 elif team==1:
  if role=="yard":
   box(c,Vector3(-53,-34,5),Vector3(76,65,36),CONCRETE)
   box(c,Vector3(-55,-36,41),Vector3(80,69,7),color)
   _building_door(c,Vector3(-37,31.1,5),42,28,door,STEEL,1)
   for x in [-51.0,11.0]:
    box(c,Vector3(x,25,5),Vector3(10,17,38),STEEL)
   box(c,Vector3(34,-30,5),Vector3(15,15,65),STEEL)
   # Quarter-turn about the mast: boom now reaches toward the foreground.
   box(c,Vector3(35.5,-35,65),Vector3(12,51,7),YELLOW)
   var hoist_z = 49.0+sin(phase*(1.2 if working else 0.3))*8.0
   beam(c,Vector3(41.5,11,65),Vector3(41.5,11,hoist_z),INK,2)
   box(c,Vector3(38.5,8,hoist_z-3),Vector3(6,6,3),YELLOW)
  elif role=="power":
   box(c,Vector3(-51,-30,5),Vector3(72,60,27),CONCRETE)
   box(c,Vector3(-54,-33,32),Vector3(78,66,6),color)
   for x in [-39.0,-12.0]:
    box(c,Vector3(x,-19,38),Vector3(17,22,36),STEEL)
    box(c,Vector3(x-2,-21,74),Vector3(21,26,4),color)
    box(c,Vector3(x+2,-17,78),Vector3(13,18,1),INK)
   box(c,Vector3(31,-20,5),Vector3(21,43,19),STEEL)
  else:
   box(c,Vector3(-49,-29,5),Vector3(98,58,27),CONCRETE)
   box(c,Vector3(-52,-32,32),Vector3(104,64,8),color)
   for x in [-48.0,-20.0,18.0,39.0]:
    box(c,Vector3(x,25,5),Vector3(9,14,29),STEEL)
   _building_door(c,Vector3(-8,29.1,5),20,23,door,STEEL,1)
   for x in [-35.0,24.0]:
    box(c,Vector3(x,29,23),Vector3(13,1,3),INK)
 else:
  var rust = Color("#86634c")
  var canvas = Color("#b1a17b")
  if role=="yard":
   box(c,Vector3(-51,-30,5),Vector3(52,55,25),rust)
   box(c,Vector3(-55,-34,30),Vector3(61,63,3),color)
   _building_door(c,Vector3(-39,25.1,5),30,21,door,rust,1)
   for x in [16.0,48.0]:
    box(c,Vector3(x,-26,5),Vector3(3,51,27),STEEL)
   box(c,Vector3(11,-30,32),Vector3(46,60,3),canvas)
   box(c,Vector3(23,-15,5),Vector3(18,18,11),STEEL)
   box(c,Vector3(30,9,5),Vector3(22,12,8),rust)
   var hoist_z = 18.0+sin(phase*(1.5 if working else 0.4))*5.0
   beam(c,Vector3(36,2,32),Vector3(36,2,hoist_z),INK,1.5)
   box(c,Vector3(34,0,hoist_z-2),Vector3(4,4,2),YELLOW)
  elif role=="power":
   for y in [-23.0,7.0]:
    box(c,Vector3(-37,y,5),Vector3(55,22,19),STEEL)
    box(c,Vector3(-32,y+3,24),Vector3(45,16,4),color)
    for x in [-24.0,-12.0,0.0]:
     box(c,Vector3(x,y+4,28),Vector3(5,14,2),INK)
   box(c,Vector3(31,-22,5),Vector3(14,43,21),rust)
   box(c,Vector3(34,-18,26),Vector3(5,6,26),STEEL)
   beam(c,Vector3(18,-12,15),Vector3(31,-12,15),YELLOW,3)
  else:
   box(c,Vector3(-48,-28,5),Vector3(39,54,22),rust)
   box(c,Vector3(-51,-31,27),Vector3(45,60,3),color)
   _building_door(c,Vector3(-39,26.1,5),20,18,door,rust,1)
   face(c,[Vector3(0,-27,7),Vector3(23,-27,30),Vector3(49,-27,7)],canvas.darkened(0.2))
   face(c,[Vector3(0,-27,7),Vector3(23,-27,30),Vector3(23,29,30),Vector3(0,29,7)],canvas)
   face(c,[Vector3(23,-27,30),Vector3(49,-27,7),Vector3(49,29,7),Vector3(23,29,30)],canvas.darkened(0.12))
   face(c,[Vector3(0,29,7),Vector3(23,29,30),Vector3(49,29,7)],canvas.darkened(0.25))
   _building_door(c,Vector3(17,29.1,5),12,18,door,canvas,1)
 if role=="power":
  var fan_center = Vector3(-3,0,60) if team==0 else (Vector3(39,0,25) if team==1 else Vector3(-9,-12,29))
  _roof_fan(c,fan_center,phase*4.0,7.0)
  var service = Vector3(-12,24.1,5) if team==0 else (Vector3(-29,30.1,5) if team==1 else Vector3(-32,29.1,5))
  _building_door(c,service,12,15,0.0,STEEL,1)
 elif role=="barracks":
  _roof_fan(c,Vector3(-27,0,32 if team==0 else (41 if team==1 else 31)),phase*2.0,6.0)
 _flush_depth(c)
 # Front-wall insets are decals: draw after their coplanar wall, not by centroid.
 for door_part in _building_doors:
  _building_door(c,door_part[0],door_part[1],door_part[2],door_part[3],door_part[4],door_part[5])
 _building_doors.clear()

 if role=="power":
  # Lightweight code-only plumes. Fade out aloft; no textures or random flicker.
  var vents: Array[Vector3] = [Vector3(-3,0,61)]
  if team==1: vents=[Vector3(-30,-8,79),Vector3(-3,-8,79)]
  elif team!=0: vents=[Vector3(36,-15,53)]
  for index in range(vents.size()):
   for puff in range(7):
    var age = fposmod(phase*0.38+float(puff)/7.0+index*0.31,1.0)
    var drift = Vector3(age*12.0+sin(age*5.0+index)*age*3.0,age*4.0,age*34.0)
    var tint = Color("#d6e8e5") if team==0 else (Color("#797d78") if team==1 else Color("#8e897a"))
    tint.a=sin(age*PI)*(0.14 if team==0 else 0.27)
    var radius = (2.0+age*7.0)*(0.75 if team==2 else 1.0)
    var puff_points := PackedVector2Array()
    var center = project(vents[index]+drift)
    for segment in range(12):
     puff_points.append(center+Vector2.from_angle(segment*TAU/12.0)*radius)
    _polygon(c,puff_points,tint)

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

static func _faction_industry(c: CanvasItem, role: String, team: int, color: Color, animation: Dictionary = {}) -> void:
 _foundation(c,[Vector2(-64,-46),Vector2(64,-46),Vector2(64,50),Vector2(-64,50)])
 _building_doors.clear()
 # Fixed-camera architecture uses explicit back-to-front component ordering.
 # Centroid sorting large roofs against tiny roof fixtures causes clipping.
 _collect_depth=false
 var phase: float = animation.get("time",0.0)
 var door: float = animation.get("door",0.0)
 var shell = STEEL if team==0 else (CONCRETE if team==1 else Color("#86634c"))
 if role=="refinery":
  # Separate processing block, storage vessels and a visible unloading apron.
  box(c,Vector3(-54,-34,5),Vector3(49,58,30),shell)
  box(c,Vector3(-57,-37,35),Vector3(55,64,5),color)
  _building_door(c,Vector3(-46,24.1,5),32,22,door,STEEL,0 if team==0 else 1)
  if team==0:
   for y in [-23.0,13.0]:
    box(c,Vector3(15,y-12,5),Vector3(32,24,29),STEEL)
    box(c,Vector3(18,y-9,34),Vector3(26,18,4),color)
    box(c,Vector3(23,y-5,38),Vector3(16,10,3),Color("#8adce5"))
  elif team==1:
   for x in [13.0,43.0]:
    _cylinder(c,Vector3(x,-12,5),12,42,CONCRETE)
    _cylinder(c,Vector3(x,-12,47),13,4,color)
   box(c,Vector3(-43,-22,40),Vector3(12,15,29),STEEL)
  else:
   for at in [Vector2(14,-23),Vector2(44,-18),Vector2(30,17)]:
    _cylinder(c,Vector3(at.x,at.y,5),10,22,shell)
    _cylinder(c,Vector3(at.x,at.y,27),11,3,color)
   box(c,Vector3(-49,-26,40),Vector3(39,45,3),Color("#b1a17b"))
  beam(c,Vector3(-4,16,17),Vector3(19,16,17),YELLOW,4)
  _roof_fan(c,Vector3(-29,-7,41 if team!=2 else 44),phase*3.0,7)
  _hazards(c,-49,34,43)
 elif role=="factory":
  # Wide front vehicle door; the roof profile differs by construction culture.
  box(c,Vector3(-54,-35,5),Vector3(108,62,32),shell)
  if team==0:
   box(c,Vector3(-57,-38,37),Vector3(114,68,5),color)
   box(c,Vector3(-48,-28,42),Vector3(25,46,8),STEEL)
   box(c,Vector3(24,-28,42),Vector3(25,46,8),STEEL)
   for x in [-43.0,29.0]:
    _roof_fan(c,Vector3(x+7,-5,51),phase*3.0,6)
  elif team==1:
   # Three sawtooth roof segments, with heavy external buttresses.
   for x in [-54.0,-18.0,18.0]:
    face(c,[Vector3(x,-35,37),Vector3(x+30,-35,53),Vector3(x+30,27,53),Vector3(x,27,37)],color)
    face(c,[Vector3(x+30,-35,53),Vector3(x+36,-35,37),Vector3(x+36,27,37),Vector3(x+30,27,53)],STEEL)
    face(c,[Vector3(x,27,37),Vector3(x+36,27,37),Vector3(x+30,27,53)],color.darkened(0.2))
   for x in [-56.0,46.0]:
    box(c,Vector3(x,20,5),Vector3(10,18,35),STEEL)
   box(c,Vector3(37,-30,46),Vector3(10,12,25),STEEL)
  else:
   box(c,Vector3(-58,-39,37),Vector3(65,71,3),color)
   box(c,Vector3(7,-39,39),Vector3(52,71,3),Color("#b1a17b"))
   for x in [-44.0,-22.0,0.0,22.0,44.0]:
    box(c,Vector3(x,-36,42),Vector3(3,65,2),STEEL)
    box(c,Vector3(-47,-24,40),Vector3(13,17,12),shell)
  _building_door(c,Vector3(-34,27.1,5),68,28,door,color.darkened(0.35),0 if team==0 else 1)
  _hazards(c,-42,39,84)
 else:
  # Open service bay: preserve a clear drive-through lane under the gantry.
  for x in [-27.0,17.0]:
   box(c,Vector3(x,-27,5),Vector3(10,61,4),STEEL)
   beam(c,Vector3(x+5,-22,10),Vector3(x+5,30,10),YELLOW,2)
  if team==0:
   for x in [-48.0,39.0]:
    box(c,Vector3(x,-29,5),Vector3(9,20,41),color)
   box(c,Vector3(-48,-29,46),Vector3(96,20,5),STEEL)
  elif team==1:
   for x in [-52.0,37.0]:
    box(c,Vector3(x,-32,5),Vector3(15,26,48),CONCRETE)
   box(c,Vector3(-54,-34,53),Vector3(108,30,7),color)
   box(c,Vector3(37,9,5),Vector3(18,25,21),shell)
  else:
   for x in [-46.0,43.0]:
    box(c,Vector3(x,-28,5),Vector3(4,19,36),STEEL)
   box(c,Vector3(-48,-29,41),Vector3(98,8,5),Color("#86634c"))
   box(c,Vector3(-56,-23,5),Vector3(17,48,18),shell)
   box(c,Vector3(36,10,5),Vector3(20,25,17),color)
  var top = 53.0 if team==1 else (46.0 if team==0 else 41.0)
  var trolley = sin(phase*0.5)*24.0
  var hook = 23.0+sin(phase)*6.0
  box(c,Vector3(trolley-5,-23,top-3),Vector3(10,9,3),YELLOW)
  beam(c,Vector3(trolley,-19,top-3),Vector3(trolley,-19,hook),INK,1.5)
  box(c,Vector3(trolley-3,-22,hook-3),Vector3(6,6,3),YELLOW)
  _hazards(c,-35,39,70)
 _flush_depth(c)
 for part in _building_doors:
  _building_door(c,part[0],part[1],part[2],part[3],part[4],part[5])
 _building_doors.clear()

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

static func _tempest(c: CanvasItem, color: Color, heading: float) -> void:
 # Twin lift nacelles, narrow faceted fuselage and underslung missile pods.
 _collect_depth=true
 for side in [-1.0,1.0]:
  box(c,Vector3(-12,side*29-3,25),Vector3(26,6,4),STEEL,heading)
  box(c,Vector3(-5,side*36-6,18),Vector3(22,12,9),STEEL.darkened(0.15),heading)
  for x in [2.0,10.0]:
   box(c,Vector3(x,side*36-4,27),Vector3(3,8,1),YELLOW,heading)
  box(c,Vector3(-22,side*28-8,33),Vector3(36,16,9),color,heading)
  box(c,Vector3(-18,side*28-5,42),Vector3(26,10,2),INK,heading)
  for x in [-14.0,-6.0,2.0]:
   box(c,Vector3(x,side*28-4,44),Vector3(4,8,1),STEEL,heading)
 face(c,[Vector3(-35,0,28),Vector3(-19,-9,28),Vector3(22,-7,28),Vector3(36,0,28),Vector3(22,7,28),Vector3(-19,9,28)],STEEL,heading)
 for side in [-1.0,1.0]:
  var rim = [Vector3(-35,0,28),Vector3(-19,side*9,28),Vector3(22,side*7,28),Vector3(36,0,28)]
  for edge in range(3):
   face(c,[rim[edge],rim[edge+1],Vector3(7,0,43)],color if side>0 else color.darkened(0.15),heading)
 face(c,[Vector3(7,0,43),Vector3(21,-5,34),Vector3(32,0,30),Vector3(21,5,34)],Color("#244b60"),heading)
 box(c,Vector3(-29,-16,30),Vector3(10,32,3),color,heading)
 _flush_depth(c)

static func _stormrail(c: CanvasItem, color: Color, heading: float, aim: float) -> void:
 # Clean tracked carriage, open rear deck and long conventional artillery tube.
 _tracks(c,heading,true)
 box(c,Vector3(-28,-14,10),Vector3(53,28,8),STEEL,heading)
 box(c,Vector3(-28,-14,18),Vector3(17,28,6),color,heading)
 _collect_depth=true
 for side in [-1.0,1.0]:
  box(c,Vector3(6,side*15-2,19),Vector3(14,4,12),color,aim)
 box(c,Vector3(-7,-10,19),Vector3(24,20,12),color,aim)
 box(c,Vector3(-16,-7,25),Vector3(12,14,7),STEEL,aim)
 _gun_barrel(c,Vector3(14,0,27),49,4,aim)
 box(c,Vector3(-12,9,23),Vector3(8,7,10),INK,aim)
 _flush_depth(c)

static func _volley(c: CanvasItem, color: Color, heading: float, aim: float) -> void:
 # Three axles and an exposed cab distinguish this from a tracked tank.
 for x in [-23.0,0.0,23.0]:
  for y in [-18.0,12.0]:
   box(c,Vector3(x-5,y,0),Vector3(10,6,10),INK,heading)
   box(c,Vector3(x-2,y-0.2,3),Vector3(4,6.4,4),STEEL,heading)
 box(c,Vector3(-30,-12,8),Vector3(60,24,6),STEEL,heading)
 # Cab and launcher share one depth pass so the near cab occludes the rack.
 _collect_depth=true
 box(c,Vector3(14,-12,14),Vector3(16,24,14),color,heading)
 box(c,Vector3(29,-9,21),Vector3(1,18,5),Color("#244b60"),heading)
 box(c,Vector3(16,-13,28),Vector3(12,26,2),Color("#ac9c72"),heading)
 # Pedestal belongs to the chassis. Translate the rotating rack so its
 # center stays over that rear pedestal for every independent aim angle.
 box(c,Vector3(-18,-8,14),Vector3(18,16,10),STEEL,heading)
 var pivot = Vector2(-9,0).rotated(heading-aim)
 var offset = Vector3(pivot.x+9,pivot.y,0)
 _collect_depth=true
 box(c,Vector3(-26,-16,24)+offset,Vector3(34,32,12),color,aim)
 # Individual launch tubes with recessed mouths instead of a solid rack face.
 for y in [-12.0,-4.0,4.0,12.0]:
  for z in [27.0,33.0]:
   box(c,Vector3(-24,y-2.5,z-2)+offset,Vector3(35,5,4),STEEL,aim)
   face(c,[Vector3(11.1,y-1.7,z-1.3)+offset,Vector3(11.1,y+1.7,z-1.3)+offset,Vector3(11.1,y+1.7,z+1.3)+offset,Vector3(11.1,y-1.7,z+1.3)+offset],INK,aim)
 _flush_depth(c)

static func _gun_barrel(c: CanvasItem, start: Vector3, length: float, width: float, aim: float) -> void:
 # Real projected volume: line strokes have constant screen width and cannot
 # meet a rotated muzzle or mantlet consistently.
 box(c,start+Vector3(-2,-width*0.75,-width*0.75),Vector3(7,width*1.5,width*1.5),STEEL.darkened(0.12),aim)
 box(c,start+Vector3(3,-width*0.5,-width*0.5),Vector3(length-3,width,width),STEEL,aim)
 box(c,start+Vector3(length-4,-width*0.6,-width*0.6),Vector3(5,width*1.2,width*1.2),STEEL.darkened(0.2),aim)
 # Recessed bore on the forward end rather than a solid black cube.
 var end = start.x+length+1.01
 if Vector2.RIGHT.rotated(aim).dot(Vector2(-0.35,1))>0:
  face(c,[Vector3(end,start.y-width*0.32,start.z-width*0.32),Vector3(end,start.y+width*0.32,start.z-width*0.32),Vector3(end,start.y+width*0.32,start.z+width*0.32),Vector3(end,start.y-width*0.32,start.z+width*0.32)],INK,aim)

static func _ghost_carrier(c: CanvasItem, color: Color, heading: float, aim: float) -> void:
 # Low reconnaissance wedge with a folded, asymmetric sensor mast.
 _tracks(c,heading,false)
 _collect_depth=true
 box(c,Vector3(-27,-14,9),Vector3(51,28,9),STEEL,heading)
 face(c,[Vector3(-26,-14,18),Vector3(9,-14,25),Vector3(29,-10,14),Vector3(29,10,14),Vector3(9,14,25),Vector3(-26,14,18)],color,heading)
 box(c,Vector3(-21,-11,19),Vector3(13,22,3),color.darkened(0.25),heading)
 box(c,Vector3(9,-8,23),Vector3(8,16,2),Color("#244b60"),heading)
 box(c,Vector3(-10,-3,24),Vector3(6,6,11),STEEL,aim)
 box(c,Vector3(-18,-2,34),Vector3(25,4,4),color,aim)
 box(c,Vector3(4,-3,34),Vector3(3,6,5),Color("#8adce5"),aim)
 _flush_depth(c)

static func _siege_carrier(c: CanvasItem, color: Color, heading: float, aim: float) -> void:
 # Armored troop carrier; layered side panels suggest its future bunker stance.
 _tracks(c,heading,true)
 _collect_depth=true
 box(c,Vector3(-29,-15,10),Vector3(58,30,15),STEEL,heading)
 box(c,Vector3(-23,-13,25),Vector3(40,26,6),color,heading)
 for side in [-1.0,1.0]:
  for x in [-26.0,-9.0,8.0]:
   box(c,Vector3(x,side*18-2,12),Vector3(15,4,17),color,heading)
   box(c,Vector3(x+5,side*18-2.2,23),Vector3(4,4.4,3),STEEL,heading)
 box(c,Vector3(20,-10,23),Vector3(7,20,3),INK,heading)
 box(c,Vector3(-8,-7,31),Vector3(15,14,5),STEEL,aim)
 _gun_barrel(c,Vector3(5,0,35),16,2,aim)
 _flush_depth(c)

static func _ghost_technical(c: CanvasItem, color: Color, heading: float, aim: float) -> void:
 # Light pickup with low canvas canopy and a compact folded weapon mount.
 for x in [-21.0,20.0]:
  for y in [-16.0,10.0]:
   box(c,Vector3(x-5,y,0),Vector3(10,6,10),INK,heading)
 _collect_depth=true
 box(c,Vector3(-29,-11,8),Vector3(58,22,6),STEEL,heading)
 box(c,Vector3(8,-11,14),Vector3(14,22,12),color,heading)
 box(c,Vector3(22,-10,14),Vector3(9,20,6),color.darkened(0.12),heading)
 box(c,Vector3(21.1,-8,21),Vector3(1,16,4),Color("#244b60"),heading)
 box(c,Vector3(-27,-12,14),Vector3(31,24,4),color,heading)
 for y in [-11.0,10.0]:
  box(c,Vector3(-25,y,18),Vector3(2,2,9),STEEL,heading)
 box(c,Vector3(-28,-13,26),Vector3(33,26,3),Color("#a99b76"),heading)
 box(c,Vector3(-4,-3,29),Vector3(8,6,3),STEEL,aim)
 _gun_barrel(c,Vector3(2,0,31),13,1.8,aim)
 _flush_depth(c)

static func _arc_lance(c: CanvasItem, color: Color, heading: float, aim: float) -> void:
 _tracks(c,heading,false)
 box(c,Vector3(-23,-13,8),Vector3(43,26,9),STEEL,heading)
 face(c,[Vector3(-18,-13,17),Vector3(15,-13,17),Vector3(25,0,11),Vector3(15,13,17),Vector3(-18,13,17)],color,heading)
 for y in [-14.0,8.0]:
  box(c,Vector3(-19,y,17),Vector3(20,6,6),color.darkened(0.15),heading)
  for x in [-15.0,-10.0,-5.0]:
   beam(c,Vector3(x,y+1,24),Vector3(x,y+5,24),INK,1.2,heading)
 _collect_depth=true
 box(c,Vector3(-10,-9,20),Vector3(23,18,8),STEEL,aim)
 face(c,[Vector3(-12,-10,28),Vector3(6,-10,32),Vector3(16,0,29),Vector3(6,10,32),Vector3(-12,10,28)],color,aim)
 for y in [-8.0,5.0]:
  box(c,Vector3(8,y-1,24),Vector3(8,5,7),STEEL.darkened(0.12),aim)
  box(c,Vector3(14,y,25),Vector3(23,3,5),STEEL,aim)
  box(c,Vector3(30,y,30),Vector3(7,3,1),Color("#8adce5"),aim)
 box(c,Vector3(8,-3,26),Vector3(10,6,5),INK,aim)
 box(c,Vector3(17,-2,27),Vector3(2,4,3),Color("#a5f2ee"),aim)

static func _imperator(c: CanvasItem, color: Color, heading: float, aim: float) -> void:
 var pods: Array[Vector2] = []
 for y in [-29.0,18.0]:
  for x in [-35.0,3.0]:
   pods.append(Vector2(x,y))
 pods.sort_custom(func(a: Vector2,b: Vector2) -> bool:
  return a.rotated(heading).dot(Vector2(-0.35,1))<b.rotated(heading).dot(Vector2(-0.35,1)))
 for pod in pods:
  # Track tops meet the hull underside at z=10 instead of cutting through
  # its side walls (the previous caps extended all the way up to z=18).
  box(c,Vector3(pod.x,pod.y,0),Vector3(32,11,8),INK,heading)
  box(c,Vector3(pod.x-1,pod.y,8),Vector3(34,11,2),STEEL,heading)
  for rib in [4.0,12.0,20.0,28.0]:
   beam(c,Vector3(pod.x+rib,pod.y+1,10.1),Vector3(pod.x+rib,pod.y+10,10.1),color,2,heading)
 box(c,Vector3(-31,-20,10),Vector3(62,40,12),color.darkened(0.18),heading)
 box(c,Vector3(-26,-17,22),Vector3(51,34,5),STEEL,heading)
 for x in [-22.0,-16.0,-10.0]:
  beam(c,Vector3(x,-11,27.2),Vector3(x,11,27.2),INK,2,heading)
 _collect_depth=true
 box(c,Vector3(-15,-16,27),Vector3(34,32,12),color,aim)
 box(c,Vector3(-11,-12,39),Vector3(24,24,4),STEEL,aim)
 for y in [-8.0,8.0]:
  _gun_barrel(c,Vector3(16,y,34),34,4.5,aim)
 box(c,Vector3(-10,5,43),Vector3(13,12,6),color,aim)
 _gun_barrel(c,Vector3(1,11,46),17,2,aim)
 box(c,Vector3(-10,-10,43),Vector3(9,8,3),color,aim)

static func _junker(c: CanvasItem, color: Color, heading: float, aim: float, tier: int) -> void:
 var rust = Color("#966548")
 _tracks(c,heading,false)
 box(c,Vector3(-23,-12,8),Vector3(43,25,9),STEEL.darkened(0.12),heading)
 box(c,Vector3(-22,-12,17),Vector3(16,25,5),rust,heading)
 box(c,Vector3(-3,-12,17),Vector3(21,25,4),color,heading)
 box(c,Vector3(-25,-17,11),Vector3(7,5,16),INK,heading)
 box(c,Vector3(-17,7,22),Vector3(12,9,7),Color("#ac9c72"),heading)
 # Side skirts belong to the chassis, not the rotating turret depth group.
 if tier>=1:
  for y in [-23.0,17.0]:
   box(c,Vector3(-19,y,10),Vector3(37,5,12),rust,heading)
   box(c,Vector3(-12,y,22),Vector3(13,5,2),color,heading)
 _collect_depth=true
 box(c,Vector3(-4,-9,22),Vector3(21,18,8),color,aim)
 box(c,Vector3(-6,-11,30),Vector3(25,22,3),rust,aim)
 _gun_barrel(c,Vector3(14,-2,27),22,3.2,aim)
 beam(c,Vector3(-3,6,34),Vector3(-3,6,46),INK,1.5,aim)
 if tier>=2:
  box(c,Vector3(-8,-20,31),Vector3(22,8,8),STEEL,aim)
  for x in [-3.0,6.0]:
   box(c,Vector3(x,-20,39),Vector3(4,8,2),YELLOW,aim)
  _gun_barrel(c,Vector3(12,-16,35),14,2,aim)

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
