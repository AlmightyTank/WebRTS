# Movement and order playtest

Launch the repeatable 25-tank chokepoint lab:

```sh
godot --path godot res://scenes/congestion_lab.tscn
```

All tanks start selected. Right-click beyond the wall opening to move the army;
Shift-right-click additional destinations to append waypoints. The selected units
show gold destination markers and connecting order lines (not the obstacle detour).
Use **A**, then Shift-left-click for a queued attack-move leg. **S** cancels both
the active order and its queue; an ordinary movement command replaces the queue.
**R** resets the army. Drag-select a smaller group to try opposing traffic.

Queueing applies to movement and attack-move, including MCVs and harvesters.
Contextual attack/capture/harvest orders remain immediate, not queued actions.
Enemy AI is disabled in this lab; normal skirmish AI is unchanged.

## Regression checks

```sh
godot --headless --path godot --script res://tests/movement_orders_smoke.gd
godot --path godot --script res://tests/movement_input_smoke.gd
```

The deterministic test covers swept collision, unreachable goals, explicit attack
locks, FIFO execution/cancellation, economy vehicles, and all 25 tanks reaching
distinct non-overlapping slots after a chokepoint. Traffic replans temporarily
consider nearby units, without permanently modifying the navigation grid.

The second test dispatches viewport mouse/keyboard events into a running scene,
checks movement, Shift-queue and Stop, and exits automatically. Without
`--headless`, it also saves `user://movement_lab.png` from the live renderer.
Both tests run headlessly in CI. This improves congestion but does not guarantee
deadlock-free movement for arbitrary opposing crowds or fully blocked passages.

## Rendering performance

All mobile unit artwork uses shared colored meshes instead of
submitting each procedural plate and line separately. The vehicle cache is bounded
to 512 meshes. Hull/turret artwork uses 64 angular steps; gameplay angles remain
continuous. Harvesters retain separate cargo geometry in 16 fill steps; assets
without independent turrets do not duplicate meshes for unused aim angles.
Building artwork keeps its separate existing cache. Run
`godot --path godot --script res://tests/unit_mesh_cache_smoke.gd` to check every
unit's mesh reuse and capture `user://unit_mesh_gallery.png`.

Local rendered debug measurements (Godot 4.7.2, RX 5500 XT, 1280×720, three-second
samples of the moving 25-tank lab): median frame time fell from **204 ms** to
**16.6 ms**, and average draw calls from about **2,017** to **420**. Hiding the
tanks before the fix gave a 16.8 ms median, identifying artwork submission as the
primary bottleneck. These are local observations, not a cross-hardware FPS
guarantee or a release-build benchmark.
