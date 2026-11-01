extends Node2D
## F6 to inspect the active playable roster; Tab switches buildings and units.
const Art = preload("res://scripts/ui/industrial_art.gd")
const Icon = preload("res://scripts/ui/retro_icon.gd")
const Terrain = preload("res://scripts/ui/battlefield_terrain.gd")
const BUILDINGS = ["yard","power","refinery","barracks","factory","depot","relay","turret"]
const UNITS = ["a_mcv","a_harvester","a_sentinel","r_bastion","a_sentinel_aa","r_flak","a_ranger","a_javelin","a_engineer","a_striker","r_siege_heli"]
var show_units = false

func _ready() -> void:
 refresh()

func _unhandled_key_input(event: InputEvent) -> void:
 if event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_TAB:
  show_units=not show_units
  refresh()

func refresh() -> void:
 for child in get_children():
  remove_child(child)
  child.queue_free()
 var ids = UNITS if show_units else BUILDINGS
 var columns = 4 if show_units else 3
 var width = 1224.0/columns
 for i in range(ids.size()):
  var icon=Control.new()
  icon.set_script(Icon)
  icon.position=Vector2(28+(i%columns)*width+width-65,89+floori(float(i)/columns)*196+121)
  icon.size=Vector2(48,48)
  add_child(icon)
  icon.configure(ids[i])
 queue_redraw()

func _draw() -> void:
 draw_rect(Rect2(0,0,1280,720),Color("#202d30"))
 draw_string(ThemeDB.fallback_font,Vector2(28,36),"MERIDIAN / "+("MOBILE UNITS" if show_units else "BASE STRUCTURES"),HORIZONTAL_ALIGNMENT_LEFT,-1,24,Color("#dbe9e5"))
 draw_string(ThemeDB.fallback_font,Vector2(28,64),"TAB: switch gallery  /  code-drawn polygons  /  matching production icons  /  no cast shadows",HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("#99b7b0"))
 var ids = UNITS if show_units else BUILDINGS
 var columns = 4 if show_units else 3
 var width = 1224.0/columns
 for i in range(ids.size()):
  var origin=Vector2(28+(i%columns)*width,89+floori(float(i)/columns)*196)
  Terrain.paint(self,Rect2(origin,Vector2(width-12,184)),false)
  var bounds=Art.asset_bounds(ids[i])
  var scale_factor=minf((width-80)/bounds.size.x,123/bounds.size.y)
  var center=origin+Vector2((width-12)*0.5,67)
  draw_set_transform(center-bounds.get_center()*scale_factor,0,Vector2.ONE*scale_factor)
  Art.draw_asset(self,ids[i],1 if ids[i].begins_with("r_") else 0,0.0,-0.35,0.65)
  draw_set_transform(Vector2.ZERO)
  draw_string(ThemeDB.fallback_font,origin+Vector2(12,157),ids[i].trim_prefix("a_").trim_prefix("r_").replace("_"," ").to_upper(),HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("#dfebdc"))
 draw_string(ThemeDB.fallback_font,Vector2(28,706),"Artwork only: unit statistics, construction costs, weapons and movement rules are unchanged.",HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("#b8cdc5"))
