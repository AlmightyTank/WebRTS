extends Node2D
const Art = preload("res://scripts/ui/industrial_art.gd")
const Terrain = preload("res://scripts/ui/battlefield_terrain.gd")
const IDS = [["a_ranger","a_javelin","a_engineer"],["r_line","r_hunter","r_engineer"],["g_militia","g_rocket_cell","g_tech"]]
const NAMES = [["RANGER","JAVELIN","ENGINEER"],["LINE INFANTRY","HUNTER","ENGINEER"],["MILITIA","ROCKET CELL","TECHNICIAN"]]
var heading: float = 0.0
var aim: float = -0.35
var rotating: bool = false

func _process(delta: float) -> void:
 if rotating:
  heading+=delta*0.5
  aim+=delta*0.7
  queue_redraw()

func _unhandled_key_input(event: InputEvent) -> void:
 if not event is InputEventKey or not event.pressed or event.echo: return
 match event.keycode:
  KEY_LEFT: heading-=PI/8.0
  KEY_RIGHT: heading+=PI/8.0
  KEY_UP: aim+=PI/8.0
  KEY_DOWN: aim-=PI/8.0
  KEY_SPACE: rotating=not rotating
 queue_redraw()

func _draw() -> void:
 draw_rect(Rect2(0,0,1280,720),Color("#202d30"))
 for faction in range(3):
  var x := 26.0+faction*416.0
  draw_string(ThemeDB.fallback_font,Vector2(x+12,32),["ALLIANCE","REPUBLIC","GIA"][faction],HORIZONTAL_ALIGNMENT_LEFT,-1,22,Color("#dbe9e5"))
  for role in range(3):
   var y := 48.0+role*218.0
   Terrain.paint(self,Rect2(x,y,400,204),false)
   draw_set_transform(Vector2(x+181,y+151),0,Vector2.ONE*3.4)
   Art.draw_asset(self,IDS[faction][role],faction,heading,aim)
   draw_set_transform(Vector2(x+340,y+151))
   Art.draw_asset(self,IDS[faction][role],faction,heading,aim)
   draw_set_transform(Vector2.ZERO)
   draw_string(ThemeDB.fallback_font,Vector2(x+12,y+190),NAMES[faction][role],HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("#dfebdc"))
 draw_string(ThemeDB.fallback_font,Vector2(30,718),"Left/Right: body  |  Up/Down: aim  |  Space: rotate  |  Right figure: native scale",HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("#b8cdc5"))
