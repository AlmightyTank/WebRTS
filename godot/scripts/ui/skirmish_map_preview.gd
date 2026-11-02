extends Control
## Thumbnail of a skirmish map. Start dots follow the lobby assignment.
const Maps = preload("res://scripts/economy/skirmish_maps.gd")
const Terrain = preload("res://scripts/ui/battlefield_terrain.gd")
const Scenery = preload("res://scripts/ui/field_scenery.gd")
const PLAYER := [Color("#73b9e3"), Color("#dc907a")]
var map_id := "meridian_basin"
var slots: Array = ["west", "east"]

func _ready() -> void:
 mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
 if size.x < 8.0 or size.y < 8.0:
  return
 var map: Dictionary = Maps.get_map(map_id)
 var board: Rect2 = map["board"]
 var fit := minf((size.x - 8.0) / board.size.x, (size.y - 8.0) / board.size.y)
 var origin := (size - board.size * fit) * 0.5
 draw_rect(Rect2(Vector2.ZERO, size), Color("#101e24"))
 draw_set_transform(origin, 0.0, Vector2(fit, fit))
 Terrain.paint(self, board)
 var cliffs: Array = map["cliffs"]
 for i in range(cliffs.size()):
  Scenery.obstacle(self, cliffs[i], i)
 for site in map["ore"]:
  Scenery.ore(self, site["position"], 1.0)
 var relay: Vector2 = map["relay"]
 draw_rect(Rect2(relay - Vector2(28, 24), Vector2(56, 48)), Color("#9aebbf"))
 draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
 draw_rect(Rect2(origin, board.size * fit), Color("#84969d"), false, 2.0)
 var shown: Array = Maps.display_slots(slots)
 var spawns: Dictionary = map["spawns"]
 for key in ["west", "east"]:
  var at: Vector2 = origin + spawns[key] * fit
  var owner := -1
  for side in range(mini(2, shown.size())):
   if str(shown[side]) == key:
    owner = side
  var fill := Color("#dce9e9")
  if owner >= 0:
   fill = Color(PLAYER[owner])
  draw_circle(at, 11.0, fill)
  draw_arc(at, 14.0, 0.0, TAU, 20, Color("#101e24"), 2.0)
  var numeral := "1" if key == "west" else "2"
  if owner >= 0 and str(slots[owner]) == "random":
   numeral += "?"
  elif owner < 0:
   numeral = "?"
  draw_string(ThemeDB.fallback_font, at + Vector2(-10, 22), numeral, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#f4f7f2"))
