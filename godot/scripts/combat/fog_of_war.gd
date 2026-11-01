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
 visible_cells = [{}, {}]
 var sources: Array = world.units.duplicate()
 sources.append_array(world.structures)
 for source in sources:
  if not is_instance_valid(source) or source.hp <= 0 or source.team < 0 or source.team > 1:
   continue
  var sight := 360.0 if source in world.structures else 336.0
  var center := Vector2i(floori(source.position.x / CELL), floori(source.position.y / CELL))
  var reach := ceili(sight / CELL)
  for y in range(maxi(0, center.y - reach), mini(world.ROWS, center.y + reach + 1)):
   for x in range(maxi(0, center.x - reach), mini(world.COLS, center.x + reach + 1)):
    var cell := Vector2i(x, y)
    if (Vector2(cell) * CELL + Vector2.ONE * CELL * 0.5).distance_to(source.position) <= sight:
     visible_cells[source.team][cell] = true
     explored_cells[source.team][cell] = true
 var image := Image.create(world.COLS, world.ROWS, false, Image.FORMAT_RGBA8)
 for y in range(world.ROWS):
  for x in range(world.COLS):
   var cell := Vector2i(x, y)
   image.set_pixel(x, y, Color(0, 0, 0, 0.0 if visible_cells[0].has(cell) else (0.72 if explored_cells[0].has(cell) else 1.0)))
 shroud_image = image
 if texture == null:
  texture = ImageTexture.create_from_image(image)
 else:
  texture.update(image)
 for entity in sources:
  if is_instance_valid(entity):
   entity.visible = entity.team == 0 or sees(0, entity.position)
 for projectile in world.projectiles:
  if is_instance_valid(projectile):
   projectile.visible = sees(0, projectile.position)
 queue_redraw()

func _draw() -> void:
 if texture != null:
  draw_texture_rect(texture, world.BOARD, false)
