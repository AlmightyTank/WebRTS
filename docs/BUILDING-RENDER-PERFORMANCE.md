# Building rendering

The six faction building roles batch their ordered polygons, line quads, and smoke
puffs into one colored `ArrayMesh` surface per artwork frame. Buildings share a
bounded, 128-entry FIFO mesh cache keyed by role, team, animation tick, door state,
and working state. Animation is sampled at 20 Hz; doors use 16 opening intervals.
Selection, repair indicators, and health bars remain independent live overlays.
Units and other artwork retain their existing rendering path. Mesh lines are
solid quads and smoke uses 12-sided puffs rather than immediate-mode circles.

## Debug benchmark

Godot 4.7.2, Compatibility renderer, Radeon RX 5500 XT; vsync disabled.
Run `godot --path godot --script res://tests/building_load_test.gd`.
Same 54-building workload, 120 measured frames after warmup:

| Workload | Before mean / p95 ms | After mean / p95 ms | Draw calls before / after |
| --- | --- | --- | --- |
| Frozen buildings | 14.88 / 20.22 | 1.96 / 5.24 | 3531 / 108 |
| Animated buildings | 14.37 / 18.98 | 1.90 / 4.40 | 3531 / 108 |
| Initial battle | 6.06 / 10.87 | 3.58 / 8.78 | 1143 / 785 |

These are individual debug-build runs, not release or full late-game combat
measurements. Frame timing varies; draw counts include overlays and scene content.
The building gallery smoke test checks cache bounds and nonempty single-surface
meshes, and saves closed/open gallery captures for visual inspection.
