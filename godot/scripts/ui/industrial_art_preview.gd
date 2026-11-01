extends Node2D
## Run scenes/art_preview.tscn with F6 to inspect the procedural art direction.
const Terrain = preload("res://scripts/ui/battlefield_terrain.gd")
const Art = preload("res://scripts/ui/industrial_art.gd")
const Icon = preload("res://scripts/ui/retro_icon.gd")

func _ready() -> void:
 for i in range(3):
  var icon = Control.new()
  icon.set_script(Icon)
  icon.position = Vector2(220+i*400,545)
  icon.size = Vector2(96,76)
  add_child(icon)
  icon.configure(["a_mcv","yard","power"][i])
 queue_redraw()

func _draw() -> void:
 draw_rect(Rect2(0,0,1280,720),Color("#202d30"))
 draw_string(ThemeDB.fallback_font,Vector2(36,49),"MERIDIAN / PROCEDURAL INDUSTRIAL ART",HORIZONTAL_ALIGNMENT_LEFT,-1,24,Color("#dbe9e5"))
 draw_string(ThemeDB.fallback_font,Vector2(36,78),"2D polygons  /  flat-shaded faces  /  shared battlefield and production artwork",HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("#99b7b0"))
 var names = ["MCV / SIX-WHEEL CONSTRUCTION VEHICLE","CONSTRUCTION YARD / CRANE & WORKSHOP","POWER PLANT / TWIN COOLING TOWERS"]
 for i in range(3):
  var x = 32.0+i*408
  Terrain.paint(self,Rect2(x,106,392,530),false)
  draw_set_transform(Vector2(x+195,326),0,Vector2.ONE*(3.0 if i==0 else 1.8))
  Art.draw_asset(self,["mcv","yard","power"][i])
  draw_set_transform(Vector2.ZERO)
  draw_string(ThemeDB.fallback_font,Vector2(x+12,466),names[i],HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("#dfebdc"))
  draw_set_transform(Vector2(x+86,540),0,Vector2.ONE*(1.0 if i==0 else 0.68))
  Art.draw_asset(self,["mcv","yard","power"][i],1,PI*0.65 if i==0 else 0.0)
  draw_set_transform(Vector2.ZERO)
  draw_rect(Rect2(x+188,539,104,88),Color("#26363e"))
  draw_string(ThemeDB.fallback_font,Vector2(x+12,615),"RED FACTION",HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color("#b7c9c4"))
  draw_string(ThemeDB.fallback_font,Vector2(x+302,588),"ICON",HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color("#b7c9c4"))
 draw_string(ThemeDB.fallback_font,Vector2(36,677),"All artwork is drawn in code. No sprites, textures, imported models or image assets.",HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("#b8cdc5"))
