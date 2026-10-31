# Meridian Warfront — Godot 4 Isometric Prototype

## Run
1. Install Godot 4.x.
2. Import `godot/project.godot` in Godot Project Manager.
3. Press F5.

## Slice B
- Uses Godot 4 `TileMapLayer` and an isometric `TileSet` with 128×64 tile cells.
- Builds a six-tile transparent RGBA atlas in memory at startup (grass variants, dirt, concrete/road).
- Terrain uses a 64×64 tile map with deterministic variation.
- Atlas can be exported as PNG or replaced with artist-authored PNG in a later art pass; no binary PNG file is committed yet.
- Camera: WASD/arrows to pan, right/middle drag to pan, wheel to zoom.
- The battlefield has not yet been verified in a Godot runtime or CI. Terrain transitions, actor Y-sorting and mobile touch input remain future slices.
