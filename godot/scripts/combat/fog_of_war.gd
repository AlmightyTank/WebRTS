extends Node2D
## Shared radial sight, persistent exploration, and one textured shroud draw.
const CELL := 48
var world
var visible_cells: Array = [{}, {}]
var explored_cells: Array = [{}, {}]
var texture: ImageTexture
var shroud_image: Image

func reset(arena) -> void:
 world = arena
 visible_cells = [{}, {}]
 explored_cells = [{}, {}]
 z_index = 90
 texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
 refresh()

func sees(side: int, point: Vector2) -> bool:
 return side >= 0 and side < 2 and visible_cells[side].has(Vector2i(floori(point.x / CELL), floori(point.y / CELL)))

func explored(side: int, point: Vector2) -> bool:
 return side >= 0 and side < 2 and explored_cells[side].has(Vector2i(floori(point.x / CELL), floori(point.y / CELL)))

func refresh() -> void:
 if visible_cells.size() != 2:
  visible_cells = [{}, {}]
 else:
  visible_cells[0].clear()
  visible_cells[1].clear()
 var structure_lookup := {}
 for building in world.structures:
  structure_lookup[building] = true
 for source in world.units:
  _reveal_source(source, structure_lookup)
 for source in world.structures:
  _reveal_source(source, structure_lookup)
 if world.get("commander") != null:
  for area in world.commander.reveals:
   _reveal_area(int(area.side), area.point, float(area.radius))
 _paint_shroud()
 for entity in world.units:
  if is_instance_valid(entity):
   entity.visible = world.entity_visible_to(0, entity)
 for entity in world.structures:
  if is_instance_valid(entity):
   entity.visible = world.entity_visible_to(0, entity)
 for projectile in world.projectiles:
  if is_instance_valid(projectile):
   projectile.visible = sees(0, projectile.position)
 queue_redraw()

func _reveal_source(source, structure_lookup: Dictionary) -> void:
 if not is_instance_valid(source) or source.hp <= 0 or source.team < 0 or source.team > 1:
  return
 var sight := 360.0 if structure_lookup.has(source) else 336.0
 if source.get("unit_id") in ["r_recon", "r_armored_scout"]:
  sight = 420.0
 elif source.get("unit_id") in ["a_pathfinder", "a_ghost_carrier"]:
  sight = 403.0
 elif str(source.get("kind")) == "ghost_node":
  sight = 432.0
 _stamp_sight(source.team, source.position, sight, ceili(sight / CELL))

func _reveal_area(side: int, point: Vector2, radius: float) -> void:
 if side < 0 or side > 1:
  return
 # Powers previously scanned the whole map. One extra ring cannot miss an in-range cell.
 _stamp_sight(side, point, radius, ceili(radius / CELL) + 1)

func _stamp_sight(side: int, point: Vector2, radius: float, reach: int) -> void:
 var center := Vector2i(floori(point.x / CELL), floori(point.y / CELL))
 for y in range(maxi(0, center.y - reach), mini(world.ROWS, center.y + reach + 1)):
  for x in range(maxi(0, center.x - reach), mini(world.COLS, center.x + reach + 1)):
   var cell := Vector2i(x, y)
   # Keep the original cell test. A hand-rolled sqrt disagrees on the radius edge
   # and sends scouts toward a different frontier.
   if (Vector2(cell) * CELL + Vector2.ONE * CELL * 0.5).distance_to(point) <= radius:
    visible_cells[side][cell] = true
    explored_cells[side][cell] = true

func _paint_shroud() -> void:
 if shroud_image == null or shroud_image.get_width() != world.COLS or shroud_image.get_height() != world.ROWS:
  shroud_image = Image.create(world.COLS, world.ROWS, false, Image.FORMAT_RGBA8)
 shroud_image.fill(Color(0, 0, 0, 1))
 var dim := Color(0, 0, 0, 0.72)
 var clear := Color(0, 0, 0, 0)
 for cell in explored_cells[0]:
  shroud_image.set_pixelv(cell, dim)
 for cell in visible_cells[0]:
  shroud_image.set_pixelv(cell, clear)
 if texture == null:
  texture = ImageTexture.create_from_image(shroud_image)
 else:
  texture.update(shroud_image)

func _draw() -> void:
 if texture != null:
  draw_texture_rect(texture, world.BOARD, false)
