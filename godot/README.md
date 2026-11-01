# Meridian Warfront — Procedural RTS RA2 Economy, Engineers & Expansion

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
- H: deploy an idle MCV. 1–4: Buildings, Defense, Infantry, Vehicles tabs. G: place selected producer rally/staging area. T: toggle selected producer's Move/Attack-Move rally mode.
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

## New RA2-style commands (v0.8)

- **CANCEL CURRENT / REFUND:** cancels the currently building structure, defense or unit, returning exactly the credits paid so far; a completed but unplaced READY structure is refundable. This is separate from right-click/Esc, which only exits placement mode without canceling the READY job.
- **REMOVE LAST QUEUED UNIT:** removes the most recently queued (unstarted, uncharged) troop or vehicle order in the active tab.
- **REPAIR SELECTED BUILDING:** click/tap one of your buildings, then toggle repairs. Repairs restore 55 HP per second while affordable and charge 0.45 credits per HP. Repairs stop at full health, when canceled or when resources run out.
- **SELL SELECTED (CONFIRM):** click a friendly building and press SELL twice within five seconds. Returns 50% of the construction or MCV purchase value. Original starter MCV/Yard and neutral relay cannot generate free credits; selling a refinery never creates a new harvester.
- **Factory scaling:** additional operational barracks, War Factories or Construction Yards speed up their respective shared queues (up to a 0.55× time floor). The existing Buildings/Defense lanes stay independent; extra factories do not create unlimited lanes. Low power still slows all eligible production.
- **Active factory/barracks:** the newest completed War Factory or Barracks automatically becomes the physical production exit for its shared unit queue. Click an older owned producer to make it active, or use **USE SELECTED PRODUCTION BUILDING**. This does not change the multiple-factory speed bonus. If it is sold, captured, or destroyed, production switches to the newest surviving eligible factory.
- **Independent rally points:** with the factory or Barracks selected, right-click ground to set its rally destination, or click **SET RALLY POINT (G)** and select a destination with mouse/touch. Each producer retains its own point when another is selected. The active point is drawn as a world marker; units automatically walk or drive there on completion. Purchased harvesters resume automatic harvesting after arriving. Esc/right-click cancels armed rally mode.
- **Expansion MCV:** after building a **Service Depot**, purchase an MCV in the VEHICLES tab. Select it, move it to clear ground and press H to deploy an additional Yard and base-building anchor.
- **Engineer capture:** train a **Field Engineer** at the Barracks, select it and right-click an enemy structure or the neutral relay in the north-center of the map. Neutral capture takes 0.7s; enemy takeover requires 3 uninterrupted seconds near the target. Engineers are consumed after success; damage interrupts capture progress. No refinery harvesting vehicle is spawned by capture.

## Shared staging areas and attack-move rally (v0.8.3)

- Each Barracks and War Factory can choose **Personal**, **Alpha**, **Bravo**, or **Charlie** from the new staging selector. A producer's selected staging area is independent of which physical factory is active for the shared unit-production queue.
- Set a shared area's location by selecting a producer assigned to it, pressing **G / SET RALLY POINT**, and clicking or tapping the battlefield. Changing that location changes the destination of **every producer linked to the same stage**, but only for subsequently produced units. Alpha, Bravo, and Charlie appear as labeled map markers.
- Different producers may use the same named stage (for example, Barracks and War Factory converging on Alpha), or independent stages to organize separate fronts. Incoming units receive deterministic staging slots to reduce pile-ups.
- **RALLY MODE: MOVE / ATTACK-MOVE (T)** toggles for the selected producer. New combat units set to ATTACK-MOVE engage threats along the route and resume toward their assigned rally destination after an engagement. A Barracks and War Factory sharing Alpha can still have different modes.
- Engineers never attack-move (unarmed). Purchased harvesters move to their staging area and then resume automatic ore collection. MCVs move there normally.
- Existing **right-click rally placement**, manual active factory selection, multiple-factory speed bonuses, and direct personal rally points still work. The panel scrolls so the new controls remain accessible on smaller screens.
- Cancelling rally placement with **Esc / right-click** keeps the previous destination. A fresh skirmish resets the stage locations and producer assignments.

## Current limits / intentionally not implemented

- This is an end-to-end **economy/combat vertical slice**, not the full RA2/ZH game. No upgrades, general-specific trees, naval, aircraft factories, saving, networking, or refined audio yet.
- Building production time/health and some structure silhouettes are provisional. Full battle balancing requires interactive device testing. The core v0.4 combat stats remain loaded from `res://data/unit_balance_v0.4.json`.
- AI is a budget-constrained scripted opponent, not a full tactical strategic planner; its building sites are selected from predefined viable locations.
- RTS mobile layout needs additional touch QA for differing aspect ratios and scaling.

## Automated checks

```sh
python3 godot/tests/data_contract.py
godot --headless --editor --path godot --import --quit
godot --headless --path godot --script res://tests/combat_smoke.gd
godot --headless --path godot --script res://tests/skirmish_smoke.gd
godot --headless --path godot --script res://tests/ra2_systems_smoke.gd
godot --headless --path godot --script res://tests/rally_staging_smoke.gd
godot --headless --path godot --quit-after 180
```

The Combat Lab smoke assertions remain active; the new Skirmish smoke checks MCV deployment, production lanes, finite ore delivery, construction, power, factory unit creation and blocking.
