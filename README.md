# Meridian Warfront

A native **Godot 4**, 2D isometric real-time strategy game, inspired by classic Command & Conquer base-building and modern military warfare.

## Run the game

1. Install **Godot 4.4.1**.
2. Open Godot Project Manager and import `godot/project.godot`.
3. Run the project with **F5**.

The Godot project is the primary implementation. Source code and artwork live in [`godot/`](godot/). The complete development plan is in [`docs/ROADMAP-GODOT-ISOMETRIC-1.0.md`](docs/ROADMAP-GODOT-ISOMETRIC-1.0.md).

## Status

F5 opens Mercy Bay, an original six-start island with a southern bay, beaches, cliffs, ore, gems, and derricks. It follows the shape of a Red Alert 2 skirmish island and does not reproduce a commercial map. `[` and `]` cycle the other showcase maps. Details are in [`docs/MAP-FORMAT.md`](docs/MAP-FORMAT.md). GitHub Actions imports the project, runs the map round-trip check, and launches a headless smoke test.

## Previous WebRTS prototype

The previous Phaser/browser prototype is preserved on the **`legacy-web-phaser`** branch. It is not the active game and its Node/npm build steps do not apply to this Godot project.

## Controls

- WASD / arrow keys: pan camera.
- Right or middle mouse drag: pan.
- Mouse wheel: zoom.
- Touch: drag or pinch to navigate (pending device validation).
- `[` / `]`: cycle the flat skirmish, escarpment, basin, and hill maps.
