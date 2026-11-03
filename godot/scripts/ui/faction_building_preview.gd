extends Node2D
## First faction building batch: shared roles, distinct procedural architecture.
const Art = preload("res://scripts/ui/industrial_art.gd")
const Terrain = preload("res://scripts/ui/battlefield_terrain.gd")
const ROLES = ["yard","power","barracks"]
const LABELS = ["CONSTRUCTION YARD","POWER PLANT","BARRACKS"]
const INDUSTRY_ROLES = ["refinery","factory","depot"]
const INDUSTRY_LABELS = ["REFINERY","WAR FACTORY","REPAIR DEPOT"]
const DEFENSE_ROLES = ["turret","sam","relay"]
const DEFENSE_LABELS = ["GROUND DEFENSE","ANTI-AIR EMPLACEMENT","RELAY OUTPOST"]
const SPECIALIST_ROLES = [["beam_bastion","",""],["foundry","vanguard_foundry",""],["silo","missile_nest",""]]
const SPECIALIST_LABELS = [["VALE: BEAM BASTION","",""],["FOUNDRY","KORDA: VANGUARD FOUNDRY",""],["SILO","SAYEGH: MISSILE NEST",""]]
var batch: int = 0
var elapsed: float = 0.0

func _process(delta: float) -> void:
 elapsed+=delta
 queue_redraw()

func _unhandled_key_input(event: InputEvent) -> void:
 if event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_B:
  batch=(batch+1)%4
  queue_redraw()

func _draw() -> void:
 draw_rect(Rect2(0,0,1280,720),Color("#202d30"))
 for team in range(3):
  var x = 26.0+team*416.0
  draw_string(ThemeDB.fallback_font,Vector2(x+12,32),["ALLIANCE","REPUBLIC","GIA"][team],HORIZONTAL_ALIGNMENT_LEFT,-1,22,Color("#dbe9e5"))
  for row in range(3):
   var y = 48.0+row*218.0
   Terrain.paint(self,Rect2(x,y,400,204),false)
   var role: String = SPECIALIST_ROLES[team][row] if batch==3 else [ROLES,INDUSTRY_ROLES,DEFENSE_ROLES][batch][row]
   if role.is_empty(): continue
   draw_set_transform(Vector2(x+197,y+(143 if role=="relay" else 122)),0,Vector2.ONE*(1.0 if role=="relay" else 1.2))
   var animation = {"time":elapsed,"door":clampf((sin(elapsed*0.8)-0.2)*2.0,0.0,1.0) if role!="power" else 0.0,"working":true}
   Art.draw_asset(self,role,team,0.0,elapsed*0.25 if batch>=2 else NAN,0.0,animation)
   draw_set_transform(Vector2(x+355,y+170),0,Vector2.ONE*0.32)
   Art.draw_asset(self,role,team,0.0,elapsed*0.25 if batch>=2 else NAN,0.0,animation)
   draw_set_transform(Vector2.ZERO)
   var label: String = SPECIALIST_LABELS[team][row] if batch==3 else [LABELS,INDUSTRY_LABELS,DEFENSE_LABELS][batch][row]
   draw_string(ThemeDB.fallback_font,Vector2(x+12,y+190),label,HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("#dfebdc"))
 draw_string(ThemeDB.fallback_font,Vector2(30,718),"B: building batch %d / 4" % (batch+1),HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("#b8cdc5"))
