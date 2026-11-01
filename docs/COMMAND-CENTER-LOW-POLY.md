# Command Center — low-poly 2D-isometric asset contract

This prototype commits a **fixed-camera, pre-rendered low-poly** headquarters rather than introducing 3D buildings. The composition uses flat facets, armored concrete, blue team accents, a proper outward-facing dish, a lit garage entrance, roof vents and a transparent background. There is no ground/grass rectangle baked into the sprite.

## Import and anchor
- Artwork: `godot/assets/buildings/command_center.svg` (620×510 source canvas), imported by Godot as a 2D texture.
- Reusable scene: `godot/scenes/buildings/command_center.tscn`.
- Scale: 0.825; sprite uncentered, local offset (-310, -330), so the **foundation center** lies at the parent building origin.
- Occupied map space: **3×3 isometric cells** at 128×64 base tile size; centered on `center_cell` in the TileMapLayer.
- The building image stays fixed as the camera pans and zooms. Rotating the camera is not in scope. Future buildings should use a matching anchor and footprint metadata.

## Exporting PNG artwork
For the art pipeline, export the SVG to a transparent **620×510 RGBA PNG** (or 2× for HiDPI). Keep all exterior pixels transparent. Do not crop to the visual bounds or the scene's anchor changes. Godot can consume SVG source directly and converts it into a texture at import, while a finalized PNG can replace the source later with the same dimensions and offset.

## Prototype limits / follow-ups
- This preview only spawns the Command Center once at battlefield center (not an actual building queue).
- v0.3 C–J will introduce ownership, health UI, translucent preview, collision/footprint validation, construction, production, destruction, and proper lifecycle.
- v0.1 E adds generic Y-sorting for overlapping actors, terrain and buildings.
- The Godot executable has not been run in this environment: scene load and visual sizing still need a Godot 4 headless and in-editor check.
