# Meridian Warfront — Godot 4 Isometric Prototype

## Run
1. Install Godot 4.x.
2. Import `godot/project.godot` in Godot Project Manager.
3. Press F5.

## Slice B
- Uses Godot 4 `TileMapLayer` and an isometric `TileSet` with 128×64 tile cells.
- Builds a six-tile transparent RGBA atlas in memory at startup (grass variants, dirt, concrete/road).
- The shipped battlefield is `res://maps/procedural-skirmish.map.json`, a serialization of the original 64×64 procedural layout.
- Atlas can be exported as PNG or replaced with artist-authored PNG in a later art pass; no binary terrain PNG is committed yet.
- Camera: WASD/arrows to pan, right/middle drag to pan, wheel to zoom. Touch drag and pinch still move the camera.

## Map editor
- Open `res://scenes/map_editor.tscn` and run the current scene, or use **Project → Tools → Open Map Editor**.
- F5 still runs the battlefield without the editor panel.
- Paint terrain, trees, rocks, debris, and the headquarters cell, then save a `.map.json` file.
- The format, shortcuts, and mobile limits are documented in `docs/MAP-FORMAT.md`.

## Command Center early building prototype

- The battlefield now instantiates one fixed **low-poly Command Center** at its center tile.
- Sprite source: `res://assets/buildings/command_center.svg`, a **transparent vector original** which Godot 4 imports into a texture at edit time (no 3D model at runtime). A PNG can be exported from this source as a replacement sprite.
- Reusable scene: `res://scenes/buildings/command_center.tscn`, with placement anchor, three-by-three occupancy metadata and initial HP/team fields.
- Current behavior is a **visual prototype only**: not yet selectable, buildable, damageable, or validated in a running Godot executable. Work remains in v0.3 C–J, and v0.1 runtime validation is still outstanding.
- See `docs/COMMAND-CENTER-LOW-POLY.md` for the asset contract.
