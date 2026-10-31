extends Node2D
## Reusable faction headquarters visual with tile occupancy metadata.
## Art-only scene: building interactions, economy and combat are implemented separately.
@export var faction_id: String = "alliance"
@export var team_id: int = 0
@export var max_health: int = 3000
@export var footprint_tiles: Vector2i = Vector2i(3, 3)
@export var center_cell: Vector2i = Vector2i.ZERO
var health: int = 3000

func _ready() -> void:
    health = max_health

func place_on_tilemap(tilemap: TileMapLayer, cell: Vector2i) -> void:
    center_cell = cell
    position = tilemap.map_to_local(cell)

func occupied_cells() -> Array[Vector2i]:
    var cells: Array[Vector2i] = []
    var start := center_cell - Vector2i(floori(footprint_tiles.x / 2.0), floori(footprint_tiles.y / 2.0))
    for y in range(footprint_tiles.y):
        for x in range(footprint_tiles.x):
            cells.append(start + Vector2i(x, y))
    return cells
