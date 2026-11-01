extends Node2D
## A three-stage 2D activity sequence for Batch 2 economy and production buildings.
## Not a continuous hand-animated clip. Unit exits shown in the artwork are visual only.
@export_enum("alliance", "republic", "gia") var faction: String = "alliance"
@export var building_id: String = "ore_refinery"
@export var footprint_tiles: Vector2i = Vector2i(3, 3)
@export var center_cell: Vector2i = Vector2i.ZERO
@export_enum("idle", "working", "peak") var initial_state: String = "idle"
const FRAME_WIDTH := 384
@onready var visual: AnimatedSprite2D = $Visual

func _ready() -> void:
    var texture: Texture2D = load("res://assets/buildings/core/%s/%s_states.png" % [faction, building_id])
    if texture == null:
        push_error("Missing building art: %s/%s" % [faction, building_id])
        return
    var frames := SpriteFrames.new()
    if frames.has_animation("default"):
        frames.remove_animation("default")
    for state in ["idle", "working", "peak"]:
        frames.add_animation(state)
        frames.set_animation_speed(state, 2.0)
        frames.set_animation_loop(state, state == "working")
    for index in range(3):
        var atlas := AtlasTexture.new()
        atlas.atlas = texture
        atlas.region = Rect2(index * FRAME_WIDTH, 0, FRAME_WIDTH, FRAME_WIDTH)
        frames.add_frame(["idle", "working", "peak"][index], atlas)
    # A working animation flips between active and peak. Idle is a single static frame.
    var peak_atlas := AtlasTexture.new()
    peak_atlas.atlas = texture
    peak_atlas.region = Rect2(FRAME_WIDTH * 2, 0, FRAME_WIDTH, FRAME_WIDTH)
    frames.add_frame("working", peak_atlas)
    visual.sprite_frames = frames
    visual.centered = false
    visual.position = Vector2(-192, -364)
    set_visual_state(initial_state)

func set_visual_state(value: String) -> void:
    if is_instance_valid(visual) and visual.sprite_frames != null and visual.sprite_frames.has_animation(value):
        visual.play(value)

func place_on_grid(tile_map: TileMapLayer, cell: Vector2i) -> void:
    center_cell = cell
    position = tile_map.map_to_local(cell)

func occupied_cells() -> Array[Vector2i]:
    var cells: Array[Vector2i] = []
    for y in range(-1, 2):
        for x in range(-1, 2):
            cells.append(center_cell + Vector2i(x, y))
    return cells
