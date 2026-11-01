# Meridian Warfront — Procedural RTS Economy & Combat Vertical Slice

**Godot 4.4.1, pure code-drawn top-down battlefield.** `res://scenes/skirmish.tscn` is the primary entry point. The previous combat-only scenarios remain in `res://scenes/combat_lab.tscn` for regression tests. The old isometric renderer is NOT part of this project.

## Run

1. Open `godot/project.godot` in Godot 4.4.1.
2. Press F5 to launch the main skirmish.
3. Your selected Alliance MCV appears near the west edge. Press **H** or **DEPLOY SELECTED MCV**.
4. Open **BUILD** and queue a **Power Plant**. Credits are deducted gradually. When the build button changes to **READY: PLACE**, click it and place the transparent preview near your base.
5. Queue an **Ore Refinery** and place it near your Command Yard. It automatically spawns one free harvester; ore only becomes credits after physical refinery delivery.
6. Build **Barracks**, then **War Factory**, while using the separate **DEF** tab for a sentry turret.
7. Select combat units, right-click to move or attack, press **A** and click to attack-move. Fight the enemy Republic's AI army and destroy its significant structures.

## Controls

- Left click: select one unit; drag: select several; right click: move, target, or attack.
- Arrow keys / Q,W,D: camera movement; middle drag and mouse wheel: pan / zoom. Touch pan and pinch are supported through the existing camera input.
- H: deploy an idle MCV. 1–4: Buildings, Defense, Infantry, Vehicles tabs.
- A then click: attack move; M then click: move; S: stop; F: line/wedge formation.
- Space: pause; R: restart skirmish; Esc or right click while placing: exit placement mode.
- Bottom toolbar provides corresponding actions for touch. **AUTO-HARVEST SELECTED** reactivates a harvester after a manual move.

## Systems currently in the playable slice

- Starting MCV deploys into a procedural 2.5D Construction Yard. Structures are attackable and block pathfinding; destroying them removes the obstruction.
- Buildings and defenses have separate shared READY-to-place queues. Barracks and War Factory run concurrent unit-production queues, with incremental credit payments and pause-on-insufficient-funds.
- Construction placement validates map bounds, blockers, units, ore patches, and proximity to connected friendly buildings; structures cannot overlap.
- Power plants produce 150 power; refinery, barracks, factory, and turret consume power. A deficit slows production to 50%, and unpowered defense turrets stop firing. Power production remains possible during brownouts.
- Finite iron patches are mined in value units, carried by armored harvesters, and delivered to refineries exactly once. The initial harvester with a refinery is free, while additional harvesters are produced at factories.
- Selectable infantry, rockets, tanks, AA vehicles, auto-harvesters and MCVs share the existing collision, A* ground navigation, damage, projectile and AI combat systems.
- Republic AI deploys its Yard and follows its own paid building, defense and troop production. Both sides obey credit and prerequisite rules, not hidden grants.
- Victory/defeat when one side loses all significant placed structures and all surviving MCVs. Combat Lab scenario keys are not active in the main skirmish.

## Current limits / intentionally not implemented

- This is an end-to-end **economy/combat vertical slice**, not the full RA2/ZH game. No upgrades, general-specific trees, naval, aircraft factories, engineers/capture, saving, networking, or refined audio yet.
- Building production time/health and some structure silhouettes are provisional. Full battle balancing requires interactive device testing. The core v0.4 combat stats remain loaded from `res://data/unit_balance_v0.4.json`.
- AI is a budget-constrained scripted opponent, not a full tactical strategic planner; its building sites are selected from predefined viable locations.
- RTS mobile layout needs additional touch QA for differing aspect ratios and scaling.

## Automated checks

```sh
python3 godot/tests/data_contract.py
godot --headless --editor --path godot --import --quit
godot --headless --path godot --script res://tests/combat_smoke.gd
godot --headless --path godot --script res://tests/skirmish_smoke.gd
godot --headless --path godot --quit-after 180
```

The Combat Lab smoke assertions remain active; the new Skirmish smoke checks MCV deployment, production lanes, finite ore delivery, construction, power, factory unit creation and blocking.
