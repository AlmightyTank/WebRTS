# Meridian Warfront — Godot 2D isometric prototype

Slice A is a standalone Godot 4 project in this folder. It does not replace the existing Phaser/WebRTS game.

## Run
1. Install Godot 4.x.
2. Import this folder by selecting `godot/project.godot` in the Project Manager.
3. Press F6 in the battlefield scene or F5 to run the project.

## Controls
- WASD / arrow keys: pan
- Right- or middle-mouse drag: pan
- Mouse wheel: zoom

## Implementation
- 64×64 diamond grid with 128×64 logical tile dimensions.
- Procedurally colored terrain is intentionally placeholder artwork; future slices replace it with transparent PNG atlas tiles and a TileMapLayer.
- Deterministic dirt, grass, road, and concrete patches.
- Isometric tile/world coordinate helpers.
- Camera clamping and zoom.
- Buildings, Y-sort actors, touch input, and construction belong to subsequent slices.

## Caveat
Godot runtime validation has not yet been performed in CI.
