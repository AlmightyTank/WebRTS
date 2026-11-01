# Meridian Warfront — Procedural Top-Down Combat Lab

**This is the primary Godot implementation**. The previous isometric PNG/SVG scene and asset pipeline were removed from `main` in the transition to v0.6; prior history remains available through Git. The primary goal is playable Red Alert 2-paced movement, unit combat and Zero Hour-style differentiated armies without hand-built models or frame animations.

## Run

1. Install **Godot 4.4.1** (standard build).
2. Import `godot/project.godot` and press **F5**.
3. The opening scene is `res://scenes/combat_lab.tscn`, a complete **combat sandbox**, *not* a finished economy/base-building skirmish.

## Controls

| Action | Control |
| --- | --- |
| Select one | Left-click blue unit |
| Select several | Drag left-button selection rectangle |
| Add to selection | Shift + left-click / drag |
| Move / focus fire | Right-click ground / enemy |
| Attack-move | A then left-click destination, or use toolbar |
| Line / wedge | F or toolbar |
| Stop | S or toolbar |
| Camera | Arrow keys or W/D/Q, middle-drag, mouse wheel zoom |
| Pause / restart | Space / R |
| Switch scenarios | Keys 1–4 or scenario sidebar |
| Touch | Tap blue unit, tap destination; toolbar for attack-move, stop, select-all and reset; single-finger pan and two-finger pinch are experimental |

## Scenarios

1. **Combined Arms:** infantry, missile infantry, MBTs, AA vehicles and helicopters on both sides.
2. **Infantry vs Tanks:** rifles/rocket infantry against armored vehicles.
3. **Air Interception:** AA vehicles and rockets against approaching helicopters.
4. **Formation Drill:** line and wedge formation movement under fire.

All terrain, unit shapes, health bars, projectiles, impact tracers and buildings/obstacles are drawn in code. GDScript uses exact v0.4 HP, movement speed and armor multipliers from `res://data/unit_balance_v0.4.json`; firing profiles are **explicit provisional mappings** because the registry describes weapons in prose rather than structured machine data. Initial target priorities are simplified AI tactics. The combat sandbox is not a real-time multiplayer or full skirmish implementation.

## Automated checks

```sh
godot --headless --editor --path godot --import --quit
godot --headless --path godot --script res://tests/combat_smoke.gd
godot --headless --path godot --quit-after 10
```

CI must pass Godot import, headless smoke assertions and scene launch. Playtesting on Windows and Android devices remains required; CI checks cannot verify responsiveness or game feel.

## Source of truth

- `godot/scripts/combat/combat_arena.gd`: battlefield, A* routing, orders, HUD and AI
- `godot/scripts/combat/combat_unit.gd`: movement, collision, target engagement and code-drawn units
- `godot/scripts/combat/combat_projectile.gd`: moving projectiles with swept collision
- `godot/scripts/combat/combat_camera.gd`: top-down camera
- `godot/data/unit_balance_v0.4.json`: versioned immutable copy of the committed v0.4 design registry
- `docs/data/MERIDIAN-WARFRONT-UNIT-BALANCE-v0.4.json`: canonical design registry

Known next steps: improved stuck-unit recovery and path replanning, target lead/accuracy, true aircraft flight patterns and rearming, LOS/occlusion by elevation, formation persistence, cross-team difficulty tuning, audio, mobile ergonomics and full economy/construction gameplay.
