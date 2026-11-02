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

- Control groups: Ctrl+0–9 assigns the current selection; Alt+0–9 recalls it. Plain 1–4 still switch production tabs. Groups are cleared on restart.
- In skirmish setup, enable **AI vs AI** to watch both armies use the existing scripted AI. The view uses the western army's fog of war; this is a debugging mode, not an omniscient replay or a fully locked spectator interface.

- Left click: select one unit; drag: select several; Shift-click: toggle a unit; double-click: select on-screen units of the same type. Shift-click empty ground preserves selection.
- Right click: move, target, or attack; Shift-right-click queues movement. Right-click cancels an armed Move/Attack-Move command without issuing an order.
- Arrow keys / Q,W,D: camera movement; middle drag and mouse wheel: pan / zoom. Touch pan and pinch are supported through the existing camera input.
- H: deploy an idle MCV. 1–4: Buildings, Defense, Infantry, Vehicles tabs. G: place selected producer rally/staging area. T: toggle selected producer's Move/Attack-Move rally mode.
- A then click: attack move; M then click: move; S: stop; J: hold position (fire without chasing or retreating); F: cycle group, line, and wedge. A group order packs units into free cells around the click and follows one corridor around walls.
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

## Production sidebar and touch-first staging controls (v0.8.4)

- **Producer cards:** the production drawer starts with one readable card for every owned Barracks and War Factory. The active factory in each shared Infantry/Vehicle lane is visibly marked **ACTIVE** and shows its position, staging destination and movement mode. Tap/click any card to select it and change where the next completed unit spawns.
- **Always-visible summary:** the drawer header summarizes active Infantry and Vehicle factory numbers plus their assigned destination (Personal, Alpha, Bravo or Charlie), including **ATK** when attack-move rally is enabled. The active production building is also outlined with an **ACTIVE SPAWN** marker in the world.
- **Direct staging choices:** touch-sized Personal/Alpha/Bravo/Charlie buttons show the current selection. **SET DESTINATION (G)** positions the selected producer's personal rally or its shared staging area; **MOVE / ATTACK (T)** chooses the production rally behavior. The full dropdown remains available on desktop.
- **Responsive layouts:** a normal right sidebar on desktop becomes a bottom **collapsible production sheet** on narrow or short screens (including mobile portrait/landscape). Tapping its header opens/collapses the controls. The command toolbar supports horizontal touch scrolling. Primary controls use at least 44–48 logical pixel targets.
- **Scope:** this is a UI/interaction update. Shared production queues, factory acceleration, per-building rally assignments and unit combat behavior stay unchanged. The old and new factory mechanics are regression-tested.
- **Automated tests:** `godot --headless --path godot --script res://tests/production_hud_smoke.gd
godot --headless --path godot --script res://tests/retro_command_hud_smoke.gd` verifies desktop/phone layout bounds, drawer states, touch targets, active cards, staging choices, movement toggles, and deletion/reset cleanup.

## Retro command sidebar & command strip (v0.9)

The Godot GUI now uses an **original code-drawn industrial RTS aesthetic** inspired by early C&C interfaces. All chrome framing, insignia and production icons are new Godot primitives; no external RA2 artwork or proprietary sidebar assets are included.

- **Right sidebar:** original Alliance command crest, interactive real-time minimap, credits/power readout, power capacity meter and two-column production tile rack with building/unit silhouettes. The four classic Build/Defense/Infantry/Vehicles tabs stay wired to the existing shared queues; tile captions show credits, readiness and active payment percent.
- **Queue display:** four readout slots show the current production progress and up to three waiting unit jobs.
- **Factory staging:** the existing active Barracks/War Factory cards and Personal/Alpha/Bravo/Charlie selection remain accessible below the production rack with their rally/attack-move controls.
- **Bottom tactical bar:** original steel-framed icon buttons for Select All, Move, Attack-Move, Stop, Formation, Deploy, Rally, Staging, Pause and Restart. Rally and Staging work with the same producer UI and command logic as before.
- **Radar:** renders terrain obstacles, ore fields, structures, units and the camera viewing rectangle. Click/tap to reposition the camera. The radar is a functional Control, not a static texture.
- **Mobile:** the same responsive collapsible bottom production drawer and horizontally scrollable command bar are preserved. The radar is reduced in height for compact layouts; production tile buttons are large enough for touch.
- **Verification:** `godot --headless --path godot --script res://tests/retro_command_hud_smoke.gd` checks component creation, queue display, production tabs, minimap projection and phone/desktop layout geometry. Visual QA on an actual Android phone is still recommended.

## Current limits / intentionally not implemented

### Fog of war

Skirmishes start with unexplored black shroud. Living units reveal a 336-pixel
radius and owned structures reveal 360 pixels, shared by their team. Explored
terrain remains dimly visible when sight is lost; enemy units and structures do
not. The minimap follows the same visibility rules. Hidden enemies cannot be
clicked, captured by a new order, or acquired as combat targets. Both teams obey
sight; AI units can scout toward the opposing deployment area without querying
hidden targets. Combat labs remain fully visible.

Sight refreshes every 0.15 seconds and currently uses radial grid-based vision,
not terrain-occluded line of sight or remembered enemy-building silhouettes.
Restart clears exploration. Test with `res://tests/fog_of_war_smoke.gd`.

- This is an end-to-end **economy/combat vertical slice**, not the full RA2/ZH game. Vale, Voss, Korda, Orlov, Sayegh and Varek have research and commander trees. The match plays original cues for construction, a finished unit, low power, base under attack, an incoming superweapon, and one acknowledgement motif per faction. Music, spoken unit voices, naval, aircraft factories, saving and networking remain future work.
- Building production time/health and some structure silhouettes are provisional. Full battle balancing requires interactive device testing. The core v0.4 combat stats remain loaded from `res://data/unit_balance_v0.4.json`.
- AI is a budget-constrained scripted opponent, not a full tactical strategic planner; its building sites are selected from predefined viable locations.
- RTS mobile layout needs additional touch QA for differing aspect ratios and scaling.

## Automated checks

Army-command changes, AI benchmark methodology, measured results and remaining limits: [validation report](../docs/ARMY-COMMAND-VALIDATION.md). Run `res://tests/tactical_input_smoke.gd` without `--headless` for graphical input coverage and `res://tests/ai_match_benchmark.gd` for accelerated AI-vs-AI simulation.

```sh
python3 godot/tests/data_contract.py
godot --headless --editor --path godot --import --quit
godot --headless --path godot --script res://tests/combat_smoke.gd
godot --headless --path godot --script res://tests/skirmish_smoke.gd
godot --headless --path godot --script res://tests/ra2_systems_smoke.gd
godot --headless --path godot --script res://tests/rally_staging_smoke.gd
godot --headless --path godot --script res://tests/production_hud_smoke.gd
godot --headless --path godot --script res://tests/match_audio_smoke.gd
godot --headless --path godot --quit-after 180
```

The Combat Lab smoke assertions remain active; the new Skirmish smoke checks MCV deployment, production lanes, finite ore delivery, construction, power, factory unit creation and blocking.
# Scouting

Select combat units and press **G** or **Scout (G)** to explore reachable unknown
terrain automatically. Move, attack, capture and Stop replace scouting. Harvesters
and MCVs retain their economy roles. Exploration stops when no reachable unknown
cells remain. Idle AI combat units use the same team-specific exploration rules;
hidden enemy positions are not scouting inputs.

## Combat feedback

Weapons now have brief muzzle flashes and visual recoil, with distinct light/heavy
projectile trails, hit pulses, impact sparks and larger lethal-hit bursts. These
effects do not move collision bodies or pause combat. Feedback respects current
player sight and is capped at 96 simultaneous effects; restart clears it.
# Playable army slice

Skirmish setup is a lobby. It shows the Meridian Basin preview, your army and the computer's army, west or east deployment (or Random), starting credits (5,000 / 10,000 / 20,000), and fog. Two rows cannot take the same numbered start; Random fills the spot that is still open, and both Random are assigned when the match starts. On a narrow window the map stacks above the player rows. Player ownership remains blue/red; faction building geometry is independent of ownership and is retained when a building is captured. Both armies still use the shared power, ore, construction, capture and production systems.

Supported choices (initial tuning, not balance-certified):

| Army | Implemented differences |
| --- | --- |
| Alliance | Ranger, Javelin, Engineer, Sentinel, mobile AA, Striker; flexible combined arms |
| Vale / Lattice | Arc Lance, Lattice Interceptor, Beam Bastion replace Sentinel, mobile AA, Sentry Turret. Powered energy damage +10%; shortage doubles firing interval |
| Voss / Sky Command | Tempest replaces the Striker. Sentinel is unavailable. Aircraft cost +10% |
| Republic | Line Infantry, Tank Hunter, Engineer, Bastion, Flak, Mammoth, Siege Helicopter; heavier, slower armor |
| Korda / Steel Vanguard | Juggernaut, Imperator, Armored Scout Carrier, Vanguard Foundry replace Bastion, Mammoth, Recon APC, Heavy Foundry. Signature tanks +10% HP; aircraft +20% price |
| Orlov / Longbow | Stormrail replaces the Mammoth; Escort tank replaces the Bastion. Stormrail range +15%, two-second setup, minimum range |
| GIA | Militia, Rocket Cell, Technician, Scavenger, AA Truck, Rocket Buggy, improvised helicopter; cheaper, mobile, fragile forces |
| Sayegh / Saturation | Siege Rocket Squad, Volley, Missile Defense Nest replace Rocket Cell, Buggy, Salvaged AA. Signature missiles reload/move ×0.9; Nest is AA-only |
| Varek / Wreckrunner | Junker replaces the Scavenger and starts at 90% hull health. Rocket Truck, Rocket Buggy and the improvised helicopter move +10%. Kills add up to two salvage tiers |

Each army has its own MCV and collector. Aircraft temporarily use the vehicle queue and require a factory and power plant; there is no airfield/rearm simulation yet. New weapon translations are explicit provisional profiles in `scripts/economy/army_rules.gd`, not automatic parsing of proposal text. GIA standard units reuse existing art; replacement units and infrastructure have cached original silhouettes.

The supported roster resolves before displaying production tiles. Removed and foreign units/structures are rejected by queue and completion APIs; the AI uses the same rules and prices. Vale has no Precision Howitzer, Voss no Sentinel, Korda no Thunderbolt, Sayegh no Shadow Operative/camouflage research. Match choices are fixed until returning to setup. This is **nine choices**, not completion of the 12-army proposal: Rook, Volkov and Nadir, plus stealth, tunnels and the full wreck-yard system, remain unimplemented.

## Commander kits

Open the **UPG** tab beside the build tabs. Research pays gradually from credits, pauses if its site is lost, and can be canceled for an actual-investment refund. Completed research is permanent for the match; power-dependent benefits still require power. The AI uses these same systems.

| General | Research | Rank 1 / 3 / 5 support |
| --- | --- | --- |
| Vale | Depot: Beam Capacitors ($1400, +15% energy damage, +25 power demand); Grid Stabilizers ($1200, shortage interval 2× → 1.5×, +15 demand) | Grid Surge / Target Lattice / Orbital Pulse |
| Voss | Factory: Reinforced Hangars ($1300, new Tempests +15% hull, +20 demand); Advanced Countermeasures ($1100, Tempests take 15% less damage from AA, +10 demand) | Recon Overflight / Interdiction Flight / Sky Supremacy |
| Korda | Vanguard Foundry: Autoloaders ($1600, signature tank interval ×0.85); Veteran Crews ($1200, new signature tanks start with 100 unit XP) | Field Repairs / Armor Reserve / Breakthrough Order |
| Orlov | Factory: Forward Observers ($1200, Stormrail range +40, +10 demand); Rapid Fire Mission ($1500, Stormrail interval ×0.85, +15 demand) | Spotter Recon / Rolling Barrage / Fire Mission Omega |
| Sayegh | Depot: Guidance Van targeting ($1100, signature missile range +30); Rapid Reload ($1500, total interval floor 0.75× original). Silo: Saturation Payload ($2000) trades 900 focused damage/radius 100 for 380 damage/radius 230 | Rocket Recon Beacon / Harassing Salvo / Saturation Strike |
| Varek | Depot: Recovery Crews ($850, a Junker kill pays up to $200 or 15% of the victim's price); Field Improvisation ($1000, salvage tiers grant 12% instead of 10%) | Rapid Salvage / Roadside Reinforcements / Scavenger Convoy |

Command XP comes from enemy kills, not research. Five ranks at 0/400/1000/2000/3500 XP grant seven GP total. Each power level costs one GP, up to three levels; buy only after its rank gate. GP purchases never unlock replacement production. Unit XP is separate: kills grant 50; 100 XP grants +10% shot damage. Research and all progression reset on restart. Voss cooldowns are 80/110/150s; Orlov 80/120/150s; Varek 90/140/150s. Recon Overflight and Spotter Recon can scout shroud. Interdiction Flight and Sky Supremacy are rocket strikes a Lattice can intercept; Rolling Barrage (three AP blasts) and Fire Mission Omega are shells. Rapid Salvage heals owned ground vehicles and can raise a Junker's salvage tier. Roadside Reinforcements delivers one Junker per power level to a visible clear site. Scavenger Convoy gives light vehicles +10% speed in its area. A Junker kill raises one salvage tier, up to two: the first adds hull health, the second adds cannon damage. Tier meshes are `g_junker_salvage_1` and `g_junker_salvage_2`. There is no mobile salvage yard in this batch.

Choose a power then click/tap the world; Esc/right-click cancels. Damage powers require shared current sight. Target Lattice and Rocket Recon can scout shroud for 18 seconds (longer at higher levels); Lattice marks for +10% damage. Cooldowns: Vale 75/100/150s; Korda 90/150/150s; Sayegh 70/100/150s. Orbital Pulse warns for 3s; recon beacon 1.5s; Harassing Salvo 3s; Saturation Strike 5s. Warnings are public through shroud, with countdowns. Delayed strikes hit their fixed location, not a tracked target. They spare friendly/neutral entities and aircraft.

Grid Surge temporarily reduces powered energy intervals by 25%. Field Repairs heals owned ground vehicles by 25% max HP. Armor Reserve warns 3s, then delivers three Juggernauts at level 1 to a visible clear zone, rechecking arrival legality and the 80-unit cap. Breakthrough Order grants heavy armor +20% movement and 20% damage resistance in its temporary area. Higher levels extend support/recon duration or increase healing/strike strength and reserve count. Silo is a constructed, powered $5000 strategic weapon with its own 240s charge and 7s warning, not a GP power; payload research never grants a second silo weapon.

Counterplay: Lattice interception needs power, reaches 160px and stops **one** rocket/missile per 3.5s (one local support blast can instead consume that defense for 35% reduction). It does not block shells/energy or make an army invulnerable. Juggernauts reduce frontal damage by 20% but can be flanked. Siege Rocket Squads must stay still 1.2s before firing; Volley keeps its minimum range. Scatter or leave marked strike areas; pressure power, research sites and slow missile forces. SAM fallback and missile infantry remain available to Vale.

These are playable named kits, not balance certification. Values not specified by the design are provisional. Shared transport loading, stealth/detection and a suppression model are not yet implemented: the armored scout currently provides armored reconnaissance (420px sight), and Breakthrough uses the movement/resistance effect above rather than suppression immunity. The standard faction rosters are still a subset of the full design.

Regression: `godot --headless --path godot --script res://tests/commander_kits_smoke.gd` covers research payment/refunds/facility loss, GP/rank separation, all nine powers, cooldowns/delays/target legality, limited interception, reload caps, veteran crews, silo payload, pause/reset and HUD targeting. Run without `--headless` for `user://commander_*.png` captures.

Regression: `godot --headless --path godot --script res://tests/army_rules_smoke.gd` covers all nine choices on both ownership sides, mirror-match deployment, collector grants, queue/spawn legality, signature stats, power penalties and setup transfer. Running without `--headless` also saves `user://army_selection.png` and `user://army_battlefield.png` for visual review. Human counterplay/balance testing remains necessary.
