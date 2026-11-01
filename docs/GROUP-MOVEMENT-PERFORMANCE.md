# Group movement optimization

Ground collision and separation queries use local 48-pixel occupancy buckets
instead of scanning the whole army for every attempted step. The index rebuilds
once per physics tick; combat and economy movers update their membership
immediately so later movers see their new positions. Spawn/removal paths
invalidate it. Code that teleports units must call `update_unit_occupancy(unit)`;
synthetic test ticks must call `invalidate_occupancy()`.

Blocked combat units stagger path retries and retain their route briefly when
nearby traffic is moving. Waiting is bounded to avoid indefinitely suppressing
rerouting. Normal successful motion resets blockage timers. Ordinary move orders
can finish within six pixels if their final step is blocked; capture and combat
approaches retain precise arrival behavior. Existing formation spacing, swept
collision checks, and the Godot pathfinder remain in place.

Independently implemented after studying occupancy and retry concepts in EA's
released Red Alert source; no source code copied. Dynamic obstacle-aware route
searches still scan all units, but run only on delayed retries.

## Headless debug measurements

Godot 4.7.2, same machine, 180 movement ticks per scenario; no rendering or AI.
Numbers are movement tick time, not whole-game frame time or release results.

| Units | Scenario | Before mean / p95 ms | After mean / p95 ms |
|---|---|---|---|
| 32 | Parallel destinations | 2.97 / 7.40 | 1.87 / 5.48 |
| 32 | Converging destinations | 2.71 / 3.94 | 1.97 / 6.39 |
| 96 | Parallel destinations | 27.63 / 41.71 | 7.97 / 12.96 |
| 96 | Converging destinations | 26.70 / 36.87 | 7.54 / 12.10 |
| 192 | Parallel destinations | 108.31 / 134.24 | 14.51 / 19.83 |
| 192 | Converging destinations | 106.79 / 130.00 | 13.84 / 16.11 |

The 32-unit converging p95 regressed in this run; timings are noisy and motion
trajectories differ under the new retry rules. Large-group average movement cost
fell roughly 7.5 times at 192 units. This is not a guarantee of overall game FPS.

Tests: `group_movement_load.gd`, `movement_occupancy_smoke.gd`, and
`skirmish_smoke.gd` in `godot/tests`.
