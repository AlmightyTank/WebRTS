extends Node2D
## Godot 4 — load fixed, transparent 384×384 PNG sprite-sheet frames for power plants.
## An AnimatedSprite2D only updates the visual; power logic is handled by a separate economy system.

@export_enum("alliance", "republic", "gia") var faction: String = "alliance"
@export var center_cell: Vector2i = Vector2i.ZERO
@export var footprint_tiles: Vector2i = Vector2i(3, 3)
@export_enum("idle", "working", "damaged", "offline") var initial_state: String = "idle"

const FRAME_SIZE := Vector2i(384, 384)
const FRAME_COUNT := 8
const FPS := 8.0

@onready var visual: AnimatedSprite2D = $Visual

func _ready() -> void:
    visual.sprite_frames = _make_sprite_frames()
    visual.centered = false
    # Artwork's ground center at (192, 365) within each frame: place this pixel at parent origin.
    visual.position = Vector2(-192, -365)
    visual.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
    set_visual_state(initial_state)

func _make_sprite_frames() -> SpriteFrames:
    var frames := SpriteFrames.new()
    if frames.has_animation("default"):
        frames.remove_animation("default")
    for state in ["idle", "working", "damaged", "offline"]:
        var atlas: Texture2D = load("res://assets/buildings/power/%s/%s.png" % [faction, state])
        if atlas == null:
            push_error("Power sprite sheet missing: %s / %s" % [faction, state])
            continue
        frames.add_animation(state)
        frames.set_animation_speed(state, FPS)
        frames.set_animation_loop(state, state != "offline")
        var n: int = FRAME_COUNT if state != "offline" else 1
        for index in range(n):
            var region := AtlasTexture.new()
            region.atlas = atlas
            region.region = Rect2(index * FRAME_SIZE.x, 0, FRAME_SIZE.x, FRAME_SIZE.y)
            frames.add_frame(state, region)
    return frames

func set_visual_state(state: String) -> void:
    if visual == null or visual.sprite_frames == null:
        return
    if not visual.sprite_frames.has_animation(state):
        push_warning("Unknown power plant sprite animation: %s" % state)
        return
    if visual.animation != state or not visual.is_playing():
        visual.play(state)

func place_on_grid(terrain: TileMapLayer, cell: Vector2i) -> void:
    center_cell = cell
    position = terrain.map_to_local(cell)

func occupied_cells() -> Array[Vector2i]:
    var result: Array[Vector2i] = []
    for y in range(-1, 2):
        for x in range(-1, 2):
            result.append(center_cell + Vector2i(x, y))
    return result
