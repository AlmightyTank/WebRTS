extends Node2D
## Low-poly Command Center sprite anchor and occupied tile metadata.
## Construction, ownership and combat systems will follow in v0.3.
const FOOTPRINT := Vector2i(3, 3)
@export var center_cell := Vector2i(32, 32)
@export var team_id: int = 0
@export var max_health: int = 3000
var health: int = 3000

func _ready() -> void:
	health = max_health

func place_on_grid(tile_map: TileMapLayer, cell: Vector2i) -> void:
	center_cell = cell
	position = tile_map.map_to_local(cell)

func occupied_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for y in range(-1, 2):
		for x in range(-1, 2):
			cells.append(center_cell + Vector2i(x, y))
	return cells
