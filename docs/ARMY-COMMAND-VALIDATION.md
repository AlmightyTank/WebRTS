# Army command and AI validation — 2026-11-01

Tested with official portable Godot 4.4.1 on Windows, including the OpenGL Compatibility renderer (Radeon RX 5500 XT). Existing faction-building work was left intact.

## Changes

- Shift-click toggles individual selection; Shift-click empty ground keeps it. Double-click selects living, on-screen units of the same type.
- Ctrl+0–9 assigns control groups; Alt+0–9 recalls surviving members. Plain 1–4 retain production tabs. Restart clears groups.
- Right-click cancels an armed Move/Attack-Move command without issuing another order. Existing Shift-queued movement remains supported.
- J holds combat units in place while allowing fire; movement, attack, capture and Stop replace hold. Economy vehicles are unaffected.
- Mouse rally/building input uses event coordinates transformed through the camera. Shared-column routes fall back to an individual path if their join or destination branch is disconnected.
- AI-vs-AI setup gives both teams the paid construction, commander and scouting loops. Building placement mirrors across the map. This is not a locked spectator mode and uses western fog.
- AI prioritizes brownout recovery, replaces lost collectors, deploys replacement MCVs, and avoids stacking speculative unit queues. Target acquisition rejects distant/friendly candidates before expensive eligibility checks.

## Verification

Passing: `army_command_ai_smoke`, `tactical_input_smoke`, `movement_orders_smoke`, `movement_occupancy_smoke`, `movement_input_smoke`, `combat_reliability_smoke`, `skirmish_smoke`, `ra2_systems_smoke`, `scouting_smoke`, `fog_of_war_smoke`, `commander_kits_smoke`, `army_rules_smoke`, `main_menu_smoke`.

Graphical viewport input tests passed for queued movement, selection toggles, double-click, command cancellation, and hold. The movement test captured `user://movement_lab.png`; the graphical AI benchmark captured `user://ai_match.png` and reached an Alliance defeat at 303.7 simulated seconds (2,086 shots, peak 26 units). Two GLES null-mesh warnings occurred in that graphical run; it completed, but renderer QA remains open.

### AI simulation samples

Four accelerated 180-second runs, seed 42, fixed 30 Hz simulation:

| West / East | Peak units | Shots | Mean tick ms | p95 tick ms |
| --- | ---: | ---: | ---: | ---: |
| Alliance / Republic | 27 | 765 | 2.08 | 7.56 |
| Republic / Alliance | 27 | 1,207 | 2.15 | 7.75 |
| Vale / Korda | 14 | 764 | 1.72 | 6.15 |
| Sayegh / Alliance | 16 | 554 | 1.79 | 6.42 |

Both sides mined and spent resources in all samples. These are simulation-only timings, **not rendered FPS**, and not a balance study. Samples were taken alongside regression tests, so comparisons are approximate. Re-rendering can change outcomes; seed alone is not a deterministic replay guarantee.

Movement-only baseline for 192 actors was roughly 18–20 ms mean tick, with 23–28 ms p95. Larger armies still need profiling and optimization; no 60 FPS claim is made.

## Reproduce

```sh
godot --headless --path godot --import
godot --headless --path godot --script res://tests/army_command_ai_smoke.gd
godot --path godot --script res://tests/tactical_input_smoke.gd
godot --path godot --script res://tests/movement_input_smoke.gd
godot --headless --path godot --script res://tests/ai_match_benchmark.gd -- alliance republic 180
```

Benchmark arguments are west army ID, east army ID, and maximum simulated seconds (defaults: Alliance/Republic, 180). Omit `--headless` for a final-frame screenshot. The benchmark manually steps economy, combat, structures, projectiles and fog; it stops early on victory. It excludes rendering cost, ordinary frame pacing and UI process work. Touch-device validation, patrol/force-fire, deeper strategic AI and large-army optimization remain outside this pass.
