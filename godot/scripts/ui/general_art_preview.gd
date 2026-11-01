extends Node2D
## Art only: does not unlock units or implement salvage gameplay.
const Art = preload("res://scripts/ui/industrial_art.gd")
const Terrain = preload("res://scripts/ui/battlefield_terrain.gd")
const Icon = preload("res://scripts/ui/retro_icon.gd")
const IDS = ["a_arc_lance","r_imperator","g_junker"]
const NAMES = ["ARC LANCE / LATTICE COMMAND","IMPERATOR / STEEL VANGUARD","JUNKER / WRECKRUNNER COMMAND"]
const BATCH_TWO_IDS = ["a_tempest","r_stormrail","g_volley"]
const BATCH_TWO_NAMES = ["TEMPEST / SKY COMMAND","STORMRAIL / LONGBOW COMMAND","VOLLEY / SATURATION COMMAND"]
const BATCH_THREE_IDS = ["a_ghost_carrier","r_siege_carrier","g_ghost_technical"]
const BATCH_THREE_NAMES = ["GHOST CARRIER / GHOST COMMAND","SIEGE CARRIER / BASTION COMMAND","GHOST TECHNICAL / SHADOW FRONT"]
var batch: int = 0
var heading: float = 0.0
var aim: float = -0.35
var salvage_tier: int = 0
var rotating: bool = false
var icons: Array[Control] = []

func _ready() -> void:
 for i in range(3):
  var icon = Control.new()
  icon.set_script(Icon)
  icon.position = Vector2(335+i*408,535)
  icon.size = Vector2(64,64)
  add_child(icon)
  icons.append(icon)
 _refresh()

func _id(index: int) -> String:
 if batch==2: return BATCH_THREE_IDS[index]
 if batch==1: return BATCH_TWO_IDS[index]
 return "g_junker_salvage_%d" % salvage_tier if index==2 and salvage_tier>0 else IDS[index]

func _refresh() -> void:
 for i in range(3): icons[i].configure(_id(i))
 queue_redraw()

func _process(delta: float) -> void:
 if rotating:
  heading=wrapf(heading+delta*0.5,-PI,PI)
  queue_redraw()

func _unhandled_key_input(event: InputEvent) -> void:
 if not event is InputEventKey or not event.pressed or event.echo: return
 match event.keycode:
  KEY_SPACE: rotating=not rotating
  KEY_LEFT: heading-=PI/8.0
  KEY_RIGHT: heading+=PI/8.0
  KEY_UP: aim+=PI/8.0
  KEY_DOWN: aim-=PI/8.0
  KEY_TAB: salvage_tier=(salvage_tier+1)%3
  KEY_B: batch=(batch+1)%3
 _refresh()

func _draw() -> void:
 draw_rect(Rect2(0,0,1280,720),Color("#202d30"))
 draw_string(ThemeDB.fallback_font,Vector2(32,40),"MERIDIAN / GENERAL SIGNATURES — CODE ART",HORIZONTAL_ALIGNMENT_LEFT,-1,24,Color("#dbe9e5"))
 draw_string(ThemeDB.fallback_font,Vector2(32,72),"B: batch %d / 3   LEFT/RIGHT: hull   UP/DOWN: turret   SPACE: rotate   TAB: salvage tier" % (batch+1),HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("#99b7b0"))
 for i in range(3):
  var x: float = 32+i*408
  Terrain.paint(self,Rect2(x,96,392,554),false)
  draw_set_transform(Vector2(x+190,290),0,Vector2.ONE*2.2)
  Art.draw_asset(self,_id(i),i,heading,aim)
  draw_set_transform(Vector2.ZERO)
  draw_string(ThemeDB.fallback_font,Vector2(x+12,400),(BATCH_THREE_NAMES if batch==2 else (BATCH_TWO_NAMES if batch==1 else NAMES))[i],HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("#dfebdc"))
  var notes = ["Twin lift nacelles / missile pods","Long barrel / tracked carriage","Three axles / eight launch tubes"] if batch==1 else ["Split-prong emitter / capacitors","Four track pods / secondary turret","Salvage tier %d / 2" % salvage_tier]
  if batch==2: notes=["Low wedge / folded sensor mast","Layered armor / troop compartment","Canvas canopy / folded gun mount"]
  draw_string(ThemeDB.fallback_font,Vector2(x+12,428),notes[i],HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("#b8cdc5"))
  draw_set_transform(Vector2(x+72,568))
  Art.draw_asset(self,_id(i),i,heading,aim)
  draw_set_transform(Vector2(x+212,568))
  Art.draw_asset(self,"mcv",i)
  draw_set_transform(Vector2.ZERO)
  draw_string(ThemeDB.fallback_font,Vector2(x+12,627),"NATIVE SCALE       EXISTING MCV       ICON",HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("#b8cdc5"))
 draw_string(ThemeDB.fallback_font,Vector2(32,690),"Art only / shared renderer and icons / no textures, models or cast shadows",HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("#b8cdc5"))
