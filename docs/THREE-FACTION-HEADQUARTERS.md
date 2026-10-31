# Meridian Warfront — three headquarters sprite pack

This pack introduces distinct low-poly headquarters sprites in the same fixed 2:1 isometric camera view as the existing Godot terrain. This is an art/scene integration, not full construction gameplay.

| Faction | Building | PNG | Scene |
| --- | --- | --- | --- |
| Alliance | Command Center | `res://assets/buildings/headquarters/alliance_command_center.png` | `res://scenes/buildings/headquarters/alliance_command_center.tscn` |
| Republic | High Command Citadel | `res://assets/buildings/headquarters/republic_high_command_citadel.png` | `res://scenes/buildings/headquarters/republic_high_command_citadel.tscn` |
| GIA | Resistance Headquarters | `res://assets/buildings/headquarters/gia_resistance_headquarters.png` | `res://scenes/buildings/headquarters/gia_resistance_headquarters.tscn` |

All three sprites are 384×384 RGBA with transparent backgrounds and a shared (192, 284) sprite-pixel anchor; origin is a 3×3 footprint centered in the isometric TileMapLayer (terrain tile 128×64). Keep the separate original higher-resolution artwork in the downloadable art-production archive for future re-exporting.

Godot example:
```gdscript
const REPUBLIC_HQ = preload("res://scenes/buildings/headquarters/republic_high_command_citadel.tscn")
var hq = REPUBLIC_HQ.instantiate()
add_child(hq)
hq.place_on_tilemap(terrain, Vector2i(32, 32))
```

The legacy command center preview remains in the repo until it is deliberately replaced; do not enable both instances at the same position.

The graphics are isolated crops from a shared illustration; some glow/antenna halo pixels remain. Initial HP and faction ID fields are only metadata. Production, combat, occupancy conflict enforcement, art state transitions and gameplay balance remain scheduled work. Verify all sprites and depth in the actual Godot editor and game.
