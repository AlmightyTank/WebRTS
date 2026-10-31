extends Node2D
## Deterministic decorative obstacles; collision footprint is tracked on the map.
const TREE := 0
const ROCK := 1
const DEBRIS := 2
var kind: int = TREE
var cell := Vector2i.ZERO

func configure(tile_kind: int, grid_cell: Vector2i, world_position: Vector2) -> void:
	kind = tile_kind
	cell = grid_cell
	position = world_position
	queue_redraw()

func _draw() -> void:
	match kind:
		TREE:
			draw_rect(Rect2(-5, -28, 10, 28), Color("#5c4937"))
			draw_colored_polygon(PackedVector2Array([Vector2(-27, -20), Vector2(0, -78), Vector2(27, -20)]), Color("#315a38"))
			draw_colored_polygon(PackedVector2Array([Vector2(-23, -37), Vector2(0, -92), Vector2(23, -37)]), Color("#427344"))
		ROCK:
			draw_colored_polygon(PackedVector2Array([Vector2(-23, -3), Vector2(-19, -22), Vector2(-4, -34), Vector2(21, -22), Vector2(26, -4)]), Color("#747b7b"))
			draw_colored_polygon(PackedVector2Array([Vector2(-19, -22), Vector2(-4, -34), Vector2(21, -22), Vector2(6, -17)]), Color("#9ca4a2"))
		DEBRIS:
			draw_rect(Rect2(-22, -13, 27, 12), Color("#705d4c"))
			draw_rect(Rect2(2, -19, 20, 14), Color("#8b8377"))
			draw_line(Vector2(-26, -5), Vector2(24, -22), Color("#4a4945"), 3.0)
