# MERIDIAN WARFRONT
## Master Game Design Document — v0.1 (Design Baseline)

**Date:** 2026-10-31  
**Status:** Working master design; approved foundations, proposed detailed rules; not yet implementation authorization  
**Project:** [AlmightyTank/WebRTS](https://github.com/AlmightyTank/WebRTS) — active Godot implementation in `godot/` on `main`  
**Engine:** Godot 4.x / GDScript; validate exact project version before dependency or engine updates  
**Primary release:** Native Windows; Android controls and performance engineered from the outset  
**Working title:** Meridian Warfront  
**Primary influences:** *Command & Conquer: Red Alert 2* (base-building flow and readable arcade warfare) and *Command & Conquer: Generals — Zero Hour* (three asymmetric armies, promotions, upgrades, command powers). Create original code, visual designs, naming, writing and audio, not derivative assets.

> **Authority labels:** **LOCKED** = five choices explicitly approved in conversation or previously established faction identity; **PROPOSED** = recommended game rule for approval and testing; **TUNING** = provisional benchmark/number; **DEFERRED** = not required to prove the first skirmish. Do not interpret a detailed proposal as approved final balance.

---

## 0. Executive design contract

### 0.1 Five approved decisions — LOCKED

1. **Camera:** fixed top-down battlefield, with subtle 2.5D depth in structures. No rotating 3D camera and no isometric diamond presentation.
2. **Construction:** Red Alert 2-style Construction Yard/sidebar queue, with engineers as a supplementary mechanic rather than mandatory build workers.
3. **Economy:** finite iron ore harvested and converted to credits; introduce renewable or controllable late-game income so the match cannot permanently deadlock.
4. **Combat:** rapid, readable, arcade-style combined-arms RTS, with modern military flavor. Tactical depth arises from counters, positions and abilities, not realistic micromanaged logistics.
5. **First milestone:** one end-to-end, enjoyable **small playable skirmish**, including opponents, the economic loop and an actual win/loss state. Rendering demos and isolated mechanics do not count.

### 0.2 Existing project facts and integration

- `AlmightyTank/WebRTS` is the active *Meridian Warfront* Godot project: `godot/project.godot`, `godot/scripts/battlefield.gd`, `godot/scripts/rts_camera.gd`, `godot/scripts/terrain_obstacle.gd`, and a static Command Center scene exist as prototype source. The root README specifies Godot 4.4.1; **verify runtime/tooling version before edits**. Its current main scene is a procedural isometric battlefield, not a complete RTS.
- `docs/IDEAS.md` preserves selected ideas from the **old rendering/production roadmap**; its 128×64 diamond tiles, fixed isometric sprites, directional sprite sheets and two-faction milestone are explicitly superseded by this design direction.
- `docs/FACTION-BUILDING-ROSTER-1.0.md` defines **Alliance, Republic and Global Insurgency Alliance (GIA)** and 19 strategic building roles. Preserve its gameplay intent, faction identities and names; rewrite the sprite/image contracts as procedural geometry contracts.
- The separate `AlmightyTank/WebRTS-Native` repo contains an older *Poly Warfront* low-poly 3D Godot project. **This document does not authorize merging, deleting or editing that repository.** Keep its history distinct.
- Do not destroy the current working isometric implementation to start this design. When implementation is authorized, preserve a branch/tag, profile code reuse, build the new renderer behind a switch/scene, and replace the active entry point only after tests and hands-on validation pass.

### 0.3 Non-negotiable game pillars

| Pillar | Player promise | Failure to avoid |
|---|---|---|
| Command an army | Large battles respond to clear orders | Single-unit micromanagement required to function |
| Build a military base | Production and expansion feel immediately rewarding | Construction is slow or involves tedious worker pathing |
| Fight for territory | Ore fields, routes and facilities provoke conflict | Safe turtling with no meaningful map decisions |
| Three distinct armies | Alliance, Republic and GIA play differently | Recolored copies or one faction with all strengths |
| Readable procedural visuals | Tanks look like tanks even at game zoom | Tiny indistinct shapes with effects hiding combat |
| Skirmish-first completion | Start, fight and finish a match | Prototype with no enemy AI, economy or victory condition |
| Native + portable UX | Desktop controls feel like RTS; touch has intentional design | Desktop UI shrunk onto a phone |

### 0.4 Product scope and release boundaries — PROPOSED

**Vertical slice:** single offline 1v1 skirmish against AI on one balanced land map, using a minimal faction roster. **1.0 target:** three factions; all essential land and air systems; varied skirmish maps; a complete authored campaign; general specialties and powers; high-quality native menus, saves, audio and accessibility. Water/naval maps and all nine general specializations are a **target with a separate schedule gate**; do not allow them to delay core skirmish quality indefinitely. Online multiplayer must be architecturally considered but is **not promised for the first vertical slice**; decide 1.0 versus post-1.0 before the release roadmap is final.

---

## 1. High-level game experience

### 1.1 Genre, setting and fantasy

A real-time strategy game in an alternate modern world circa 2025–2030. A fragile international order is challenged by a powerful expansionist state and by decentralized insurgent networks. The player commands one of three fictional powers, constructing bases, harvesting iron, scouting, fielding combined-arms armies and winning with a mix of economy, positioning and technology. The tone is grounded military fiction with distinctive, entertaining superweapons rather than a realistic military simulation.

### 1.2 The standard match

- **Opening (target 0–3 minutes):** HQ operational, build power and refinery, establish ore deliveries, scout and begin infantry production.
- **Expansion (target 3–7 minutes):** establish armor production, contest a second ore field, raid harvesters, defend supply lines and fight over neutral structures.
- **Escalation (target 7–13 minutes):** unlock radar/tech, mix tank/anti-tank/AA forces, earn general points and research specialized upgrades.
- **Endgame (13+ minutes):** large army engagements, superweapon threats, scarce ore and late-game income decisions; finish by overwhelming critical infrastructure.
- **Pacing:** 15–25 minutes for an average balanced 1v1 is a **TUNING target**, not a minimum match length. Well-executed rushes can end games early; stalemates should have counterplay.

### 1.3 Game modes

| Mode | Proposed rules | Phase |
|---|---|---|
| **Skirmish** | 1v1 vs AI first; later 2–4 or more slots, teams, faction/general selection, map setup and modifiers | Mandatory first |
| **Campaign** | Authored scenario objectives, briefings, persistent *story progression* but no permanent competitive army advantage | After skirmish foundation |
| **Tutorial/training** | Controls, resource loop, construction, combat, counters, powers | Before full release |
| **Challenge/survival** | Optional scripted conditions and waves, built from campaign scenario system | DEFERRED |
| **PvP** | Separate technical milestone with synchronization, reconnect and desync checks | Schedule decision pending |

### 1.4 Standard skirmish victory/defeat — PROPOSED

**Normal victory:** eliminate the opponent's **command capability**: every operational Construction Yard and deployable Mobile Command Vehicle (MCV), with no queued deployment already in progress. Display an impending defeat warning when the last command capability is destroyed; allow a short grace period **only if** an MCV deployment is genuinely in flight. No hidden units or decorative buildings should prolong a decided match. A custom **Full Annihilation** rule can require destroying all production/armed structures later.

**Vertical slice simplification:** destroy the enemy's sole HQ. Implement the general command-capability rule before multiple yards/MCVs are introduced. A player can always surrender; pause/restart work in offline mode. Teams win when all opponents meet their chosen defeat condition.

---

## 2. Battlefield and procedural appearance

### 2.1 Camera and projection — LOCKED

- Orthographic **top-down** XY playfield, camera pans and zooms without rotating. Units are evaluated against ground-plane position, not their apparent rooftop offset.
- Structures show **2.5D depth** using offset roof polygons, visible side faces, contact shadows, parapets, doors and roof apparatus. Their clickable/occupied footprint remains on the ground plane.
- Vehicles show top-down silhouettes with exposed tracks, hull, rotating turret and barrel. Infantry are recognizable small top-down soldiers, not generic dots. Aircraft may project moving ground shadows.
- No 3D meshes, rigged character animations, imported sprite sheets or hand-authored directional frames required. Transforming procedural shapes, moving projectiles, animated shader values and runtime particle-like geometry are allowed.
- Allow optional purely aesthetic sound and small UI icons later; a code-drawn art direction does **not** mean audio must be procedural.

### 2.2 Procedural rendering contract — PROPOSED

Each entity uses data-backed **shape layers** in a local coordinate system: shadow, foundation/tracks, chassis, attachments, faction insignia, damage overlay, and selected/targeted indicators. A `VisualDefinition` can specify polygon points, colors, offsets, material tags and hardpoints; the shared renderer draws it with `_draw()`/CanvasItem or another profiled Godot 2D pathway. Turrets rotate as independent child visuals. Building construction progress and damage stages change visible geometry; no sprite variations needed.

**Quality priorities:** silhouette first; team identification second; heading and weapon direction third; readable health/selection fourth; decorative detail last. At far zoom, simplify fine details and strengthen silhouettes/team markings; at close zoom, draw structural accents. Do not rely solely on hue for ownership.

**Proposed faction visual grammar:**

| Faction | Silhouette and materials | Accent | Legibility rule |
|---|---|---|---|
| Alliance | chamfered modular forms, smooth panels, high-tech sensor dishes | blue/cyan/charcoal | narrow, clean profiles and light-emitting hardpoints |
| Republic | low broad armored masses, thick turrets, concrete and steel | olive, dark iron, restrained crimson | wide tracks, heavy plates, squared fortifications |
| GIA | asymmetrical improvised armor, containers, tarp silhouettes, exposed frames | tan/green/rusted steel | uneven outlines, scavenged components, lighter vehicles |

Keep **team color** and **faction material** separate so Alliance and Republic can fight as different team colors in mirror matches.

### 2.3 Terrain and map rules

- The terrain appears organic at gameplay zoom: grass, dirt, rock, concrete, road, coast and shallow/deep water variants. Generated patches, edge blending, noise, trails, decals and shadows are preferred over thousands of individually updated nodes.
- Maps are **authored strategic layouts** with procedural dressing: resource balance, fair spawn locations and defendable geometry are controlled, not left to random noise.
- Terrain uses a **logical square navigation/placement grid** independent of graphical detail. Exact cell-to-world scale is **TUNING**; start with 32 world units/cell if it eases implementation. The old 128×64 isometric tile contract is not carried forward.
- Obstacles have explicit footprints and flags: `blocks_ground`, `blocks_projectiles`, `blocks_sight`, `destructible`, `harvestable` (if applicable), `capturable`, `navigable_water`.
- Road movement: **PROPOSED** modest speed benefit for wheeled vehicles, never so strong that roads become mandatory. Forests impede heavy armor or sight; cliffs and deep water restrict ground movement.
- Rivers and bridges create chokepoints; avoid single tile-width bridges that generate permanent group deadlocks. Destructible bridges only after path replanning works reliably.
- View terrain remembers revealed areas in fog, but enemies outside current sight disappear unless a valid detector/radar contact exists.

### 2.4 Map content and readability

Resource deposits, capturable neutral facilities, bridges, defensible high ground (if used), destructible cover, decorative structures, ambient traffic/objects only if budget allows. UI must distinguish actionable neutral structures from decorations. The minimap displays team positions, discovered ore, alerts, camera rectangle and active commands. Large effects must never hide the only indicator of which side is winning.

---

## 3. Economy, power and late-game survival

### 3.1 Primary economic loop — LOCKED

**Ore deposit -> harvester collects iron -> refinery unloads cargo -> credits -> construction/production/upgrades.** Iron exists in finite fields by default. A harvester autonomously repeats its route until ordered otherwise, depleted or threatened. The player can assign a different field and refinery explicitly; automatic selection avoids congestion and long dangerous routes when possible.

**Proposed transaction rules:** harvesters store ore cargo; credits are granted on delivery, not on mining. Lost harvesters also lose carried cargo. A refinery serves multiple harvesters; additional refineries reduce congestion. Deposit amount never becomes negative. Players receive notifications for exhausted fields, idle harvesters, refinery blockage and economic threats.

**TUNING example, not final prices:** start with 3,500 credits, 1 HQ and 1 scout; one deposit holds ~12,000 ore units; harvester cargo ~300 units and converts at 1 credit/unit; collecting a full cargo takes ~12 seconds before path/unload time. Prove these numbers create meaningful decisions in timed playtests before locking them.

### 3.2 Power

Each player has a shared power-generation and consumption ledger, not a mined power item. Output from generators vs draw from operational structures determines available capacity. **PROPOSED:** underpowered bases retain core life and command input, but radar switches off, base defenses operate slowly and new construction/production progress is reduced. Supply negative values must be visible; a fresh generator immediately helps. Power outages must never trap a player in an unrecoverable state where a generator cannot be constructed.

### 3.3 Late-game income — LOCKED principle, PROPOSED implementation

Finite ore must generate strategic urgency, but **the game must not become unwinnable when fields run dry**. Three complementary systems:

1. **Capturable neutral trade/industrial depots:** grant modest periodic credits only while controlled; create conflict over the map. Vulnerable to raids and recapture.
2. **Reclamation upgrade on the Supply Depot/Stockpile role:** costly tier-2 upgrade enables a capped trickle of credits through recovery contracts. This reuses the existing 19-role building roster rather than adding another art-dependent structure.
3. **Battlefield salvage:** a limited percentage of destroyed vehicle value can leave short-lived scrap/recoverable wrecks. Engineers or specialized GIA scavengers recover it, creating risk/reward; never a self-funding infinite loop.

**TUNING reference:** a maximum of two passive reclamation upgrades at about 4 credits/second each; compare against a functioning early harvester economy before approval. Neutral depots should make active map control more profitable than camping behind walls. Infinite-resources skirmish option remains available, clearly marked as a modified rule set.

### 3.4 Supply/logistics system — DESIGN HOLD

The existing three-faction building roster includes a Supply Depot/Quartermaster Depot/Hidden Stockpile. There is not yet an approved hard population cap. **For the first skirmish, do not impose a unit population cap.** Instead, depots can support replenishment, emergency repairs and later reclamation. A supply cap or upkeep mechanic is a **design experiment**, not a core requirement; evaluate only after large-army pacing tests. This protects the Red Alert-style large-army feeling.

### 3.5 Economic exploit prevention

- No refunds exceeding actual credit spend; no profitable build-cancel loops.
- Salvaging allied/self-destroyed units yields no net gain; cap/minimize friendly scrap.
- Neutral income stops when facility is neutralized and changes hands according to capture resolution.
- Keep resources and queue costs authoritative in simulation, not UI; validate spending immediately at command receipt.
- Ore fields and refinery delivery must be save/load safe and free of double-pay on reload.

---

## 4. Base building and engineering

### 4.1 Construction Yard model — LOCKED

Construction Yard is faction-specific (Alliance Command Center, Republic High Command Citadel, GIA Resistance Headquarters) and controls structure construction in a visible sidebar. The player selects a building, pays credits and starts construction. When ready, a translucent footprint follows the pointer/touch and the player places it within a valid owned build radius. The structure materializes through procedural staged geometry. **No construction worker is required to place ordinary structures.**

**PROPOSED queue rule:** each operational Yard supplies one structure-construction slot. Yards can queue one active structure at a time, with a ready-to-place structure holding its slot until placed or canceled; multiple yards can operate independently. Production facilities have their own unit queues. The player can place multiple copies of ordinary buildings unless restricted by explicit rules. One active **superweapon structure per player** by default. An additional Yard also creates a new local expansion anchor.

**Placement validity:** within controlled construction radius; terrain buildable; footprint clear of unmovable units/obstacles/other buildings; valid bridge/slope rules; no forbidden map zone; available tech/credits. A temporary friendly mobile unit blocking a site produces a clear 'units obstructing' warning rather than allowing overlap. Placement preview indicates costs, footprint, facing/door, adjacency and safe/unsafe locations. Cancel before placement returns **100%** of queued building cost; after construction begins on map, salvage/refund behavior remains **TUNING** (propose 50% of base cost, never exceed original spend).

**Build order dependency:** HQ -> power/refinery/barracks -> War Factory -> radar/repair/AA/outpost -> Tech Center -> airfield/advanced support -> superweapon. Satisfying tech prerequisites is checked at enqueue and at production completion where appropriate. Destroying prerequisite buildings prevents *new* advanced queue entries but does not delete owned units/upgrades.

### 4.2 Engineers — optional utility, not build workers

Engineers repair damaged structures, can capture eligible **neutral** infrastructure, and may capture specified **enemy** buildings under clear limitations. Capture requires entering the target, exposes the engineer to attack and uses a short interruptible channel. Captures should not be instantaneous and invisible in close matches. Protect capture from repeated exploit attempts with cooldown/occupancy rules. Engineers cannot auto-spawn a base at any point on the map.

**Captured enemy HQ rule (DEFERRED):** may eventually permit a partial foreign tech branch via research/prerequisites, but cannot immediately unlock every enemy unit/superweapon. Exclude enemy-HQ tech theft from the initial skirmish.

### 4.3 Building states and destruction

Blueprint/queued -> ready to place -> foundation -> constructing -> operational -> damaged -> destroyed rubble -> cleared. HP and damage stage must be visually distinguishable without per-frame sprite art. Destroyed structures release their footprint only after rubble-clear logic; keep rubble short-lived or clearable to avoid blocking rebuilding indefinitely. Units inside a destroyed production building are lost or refunded according to a consistent, testable production rule. Production pauses safely during brownouts; power failure should not corrupt queues.

---

## 5. Tech trees, production and upgrades

### 5.1 Tech tiers — PROPOSED

- **T0 (base economy):** HQ, power, ore refinery, depot, barracks, basic infantry/defense.
- **T1 (field warfare):** War Factory, AA, radar/intel, forward outposts, engineers, basic armor, repair.
- **T2 (advanced combat):** Tech Center, airfield, advanced heavy armor/aircraft, faction utility and anti-armor defenses; reclamation income.
- **T3 (strategic weapons):** faction superweapon, elite upgrades and high-tier general abilities.

Each unit, structure and upgrade has stable ID, owner faction, required structures/upgrades, credit cost, build time, power dependency, production domain and category. UI should explain missing requirements in plain language and show the build path rather than a dead/hidden button.

### 5.2 Production

Barracks produces infantry; War Factory produces ground vehicles; Airfield handles aircraft; Naval Yard serves naval maps. Each producer has an independent queue, rally point, cancel action and optional repeat toggle. **PROPOSED:** queue costs are paid when the item begins, with pending queued entries reserved/paid consistently; first implementation can restrict each factory to a single active item with a short list of queued orders. A destroyed factory cancels its orders and refunds according to one clear policy; production must never create units for free on load or during brownout.

### 5.3 Upgrade domains

**Economy:** harvester capacity/efficiency, refinery unloading. **Armor:** durable plating and situational active protection. **Firepower:** weapons with visible counterplay, never universal damage boosts only. **Mobility:** modest vehicle acceleration and vision. **Infrastructure:** power efficiency, sensor range, repair throughput. **General-specific:** units and doctrine modifiers unique to chosen commander.

Upgrades are permanent within the current match, unless mission modifiers say otherwise. They should alter what players build and how units perform, not require constant reactivation.

---

## 6. Combat, movement and unit command

### 6.1 Combat contract — LOCKED style, PROPOSED rules

Target the exciting combined-arms flow of C&C: readable weapon arcs, quick responses, vulnerable harvesters and important positional decisions. The game is **not** a simulation of real ammunition inventory, fuel decay or vehicle crew management. Individual projectiles, weapon cooldowns and unit hitpoints remain real gameplay systems. Armor/weapon types and clear weaknesses force mixed armies.

### 6.2 Armor and weapon interaction — INITIAL DESIGN MATRIX

**Illustrative multipliers (TUNING).** Rows are attack types; columns are defender armor types. Modify with playtesting and weapon-specific exceptions.

| Attack type | Infantry | Light vehicle | Heavy armor | Aircraft | Structure |
|---|---:|---:|---:|---:|---:|
| Small arms | 1.00 | 0.30 | 0.10 | 0.10 | 0.15 |
| Autocannon | 1.10 | 1.00 | 0.45 | 0.60 | 0.50 |
| Anti-armor cannon | 0.45 | 1.25 | 1.20 | 0.05 | 0.95 |
| Guided missile | 0.55 | 1.00 | 1.10 | 1.20* | 0.95 |
| High explosive | 1.35 | 0.85 | 0.55 | 0.10 | 1.20 |
| Energy beam | 0.65 | 1.00 | 1.15 | 0.35 | 1.15 |

`*` Air hit chance/capability is separately gated by weapon targeting tags; a surface-only missile cannot attack aircraft merely because its multiplier is nonzero. Range, line-of-sight, speed, projectile travel, cooldown, area radius, target tags and countermeasures remain separate parameters. Never let a general anti-armor tank also dominate infantry and aircraft without a large tradeoff.

**Damage formula (conceptual):** effective damage = base damage × weapon-versus-armor multiplier × temporary modifiers, with clamped nonnegative results. Armor penetration and area falloff can be introduced as explicit components. Avoid hidden random critical hits in baseline competitive rules. **Friendly fire:** OFF for ordinary direct and area attacks in the initial skirmish, revisitable as an optional realism modifier; friendly units still block movement.

### 6.3 Orders and selection

Must implement: select one, select box, shift-add, control groups, move, attack, attack-move, stop, hold-position, guard, patrol, rally, queue waypoints with modifier. Contextual right-click chooses attack/harvest/move/repair/capture based on owned units and clicked target. Group commands assign destinations without every unit selecting the exact same cell. Units turn/move smoothly and their turrets independently track targets; stationary tanks can rotate guns without rotating hulls.

### 6.4 Targeting/auto behavior

- Automatic target acquisition within vision/range and permitted behavior stance.
- Prioritize attackers/threats when responding to damage; respect hold-fire/hold-position where provided.
- `Attack-move` advances with opportunistic combat; `Move` prefers reaching destination and responds only under an explicit stance.
- Never attack objects behind fog without valid detection or deliberate ground-targeted blind fire.
- Units with no legal weapons for a target show a useful cursor/status, not silent failures.

### 6.5 Movement and pathfinding

Global pathfinding handles walkable terrain, bridge/road zones, water restrictions and static building footprints. Local avoidance handles moving units. Separate collision radii and navigation classes for infantry, tracked vehicles, wheeled vehicles and aircraft. Replan on blocked routes, with sensible retry limits and a visible 'cannot reach' feedback when appropriate. Groups can use formation offsets/loose cohesion; fast units should not endlessly orbit slower groups. Idle pathing must not consume excessive CPU.

**Quality gates:** squads cross a narrow bridge without permanent jams; harvesters don't deadlock at refinery unloading; attack-move doesn't chase across the map against player intent; retreat can escape a blocked scrum; camera zoom does not change actual targeting or movement. Automated path tests use seeded maps and stress thousands of commands, not just a successful single-unit movement.

### 6.6 Veterancy

Units accumulate XP for damage contribution and relevant support actions. Three visible ranks proposed (Experienced, Veteran, Elite), with small increases to survivability, handling or firepower. XP/upgrade stacking is capped. No immortal elite units, and player skill in positioning remains more important than a small numeric veterancy advantage.

### 6.7 Fog and intelligence

Each faction has per-player visible tiles/cells updated from units and structures, discovered-map memory, radar/minimap contact rules and dedicated stealth detection. Fog and shroud differ: shroud hides never-seen terrain; fog shows discovered terrain but hides enemy unit positions absent active vision. Radar outage reduces minimap contact/intel and advanced support targeting, not the player's sight from visible friendly units. Stealth units must have counters accessible before the stealth threat becomes unavoidable.

---

## 7. The three factions

### 7.1 Shared strategic foundation — LOCKED identities

**Alliance:** technological precision, superior sensors/air, expensive elite equipment and Particle Beam Array.  
**Republic:** resilient heavy armor, fortifications, conventional artillery and Ironstorm Artillery Array.  
**GIA (Global Insurgency Alliance):** inexpensive improvised units, mobility, concealment, salvage and Ballistic Missile Silo.

All factions share economic concepts and core commands but **not** the same unit geometry, tech routes or strategic strengths. Balance through different weaknesses, not identical DPS and cost.

### 7.2 Existing 19-role building roster — CARRIED FORWARD

Names preserve the existing draft wherever possible. **Tiers and detailed behavior remain proposed.** Naval row is conditional on water maps.

| Role | Alliance | Republic | GIA |
|---|---|---|---|
| 1. HQ / construction | Command Center | High Command Citadel | Resistance Headquarters |
| 2. Power | Fusion Plant | Thermal Power Station | Diesel Generator Yard |
| 3. Refinery | Ore Refinery | Industrial Ore Works | Scrapyard Refinery |
| 4. Depot / support | Supply Depot | Quartermaster Depot | Hidden Stockpile |
| 5. Infantry | Barracks | Garrison Barracks | Militia Camp |
| 6. Vehicle factory | War Factory | Armor Works | Salvage Garage |
| 7. Radar | Satellite Uplink | Command Radar | Signal Shack |
| 8. Expansion outpost | Forward Command Post | Fortified Outpost | Forward Hideout |
| 9. Anti-infantry defense | Sentry Turret | Machine-Gun Bunker | Gun Nest |
| 10. Anti-air defense | SAM Launcher | Flak Battery | Salvaged AA Platform |
| 11. Repair | Service Hangar | Vehicle Maintenance Depot | Field Workshop |
| 12. Advanced technology | Advanced Tech Center | Military Research Center | Black Market Laboratory |
| 13. Aircraft production | Airfield | Strike Airbase | Hidden Airstrip |
| 14. Heavy static defense | Gauss Turret | Heavy Anti-Tank Emplacement | Recoilless Cannon Nest |
| 15. Wall | Energy-Reinforced Barrier | Reinforced Concrete Wall | Scrap Barricade |
| 16. Gate | Security Gate | Fortress Gate | Checkpoint Gate |
| 17. Faction utility | Drone Control Node | Heavy Foundry | Tunnel Network |
| 18. Superweapon | Particle Beam Array | Ironstorm Artillery Array | Ballistic Missile Silo |
| 19. Naval production | Naval Dock | Armored Shipyard | Riverboat Yard |

**Mechanics distinctions:** Alliance drones support reconnaissance/target marking; Republic foundry supports heavy-armor production/upgrades; GIA tunnels connect built entrances for qualified infantry/light vehicles (no arbitrary teleports). Republic walls are unusually durable; GIA walls are economical and fragile; Alliance power/sensors are efficient but vulnerable to surgical strikes.

### 7.3 Proposed unit role roster — 1.0 target, names provisional

These are **unit archetypes and strategic jobs**, not promises that all are implemented in the first slice. Infantry and vehicles must be independently recognizable by code-drawn silhouettes.

| Role | Alliance | Republic | GIA | Combat job |
|---|---|---|---|---|
| Basic infantry | Ranger | Line Infantry | Militia Fighter | Cheap scouting/anti-infantry |
| Anti-armor infantry | Javelin Team | Tank Hunter | Rocket Cell | Ambush and armor counter |
| Engineer | Field Engineer | Combat Engineer | Salvage Technician | Repair/capture, special salvage |
| Recon unit | Specter Scout Drone | Recon APC | Raider Bike | Vision and harassment |
| Main battle vehicle | Sentinel Tank | Bastion Tank | Scavenger Tank | Baseline armored fighting |
| Light attack vehicle | Lynx IFV | Ironclad APC | Raider Technical | Mobility and infantry support |
| Anti-air mobile | Sentinel AA | Flak Carrier | Rocket Truck | Anti-air and protection |
| Artillery | Precision Howitzer | Thunderbolt Artillery | Rocket Buggy | Siege, fragile at close range |
| Advanced heavy unit | Arc Beam Tank | Mammoth Siege Tank | Reclaimed Assault Tank | Faction-defining late ground unit |
| Aircraft | Striker Gunship | Siege Helicopter | Improvised Attack Helicopter | Air support/raiding |
| High-tier aircraft | Specter Strike Craft | Heavy Bomber | Missile Drone Wing | Late-game specialist |
| Harvester | Ore Harvester | Industrial Hauler | Salvage Collector | Ore collection |

**Anti-sameness rule:** not every faction must have a one-to-one clone of every unit. The role rows indicate coverage, not identical chassis or identical costs. Each faction should have meaningful holes (Alliance less cheap mass armor; Republic less nimble stealth; GIA weaker head-on armor/air dominance). A general can replace a baseline unit, modify its production, or unlock one specialist.

### 7.4 Nine generals — proposed specializations

| Faction | General | Doctrine change | Intended weakness |
|---|---|---|---|
| Alliance | Air Superiority | Extra aircraft options, fast sortie recovery and air support | Expensive infrastructure, vulnerable AA matchups |
| Alliance | Directed Energy | Beam specialist units, power-efficient beam research | More reliance on power/tech |
| Alliance | Special Operations | Elite infantry, reconnaissance and strike targeting | Lower mass-armor efficiency |
| Republic | Heavy Armor | Better tank factories, tracked armor and veteran crews | Slow response, expensive mobility |
| Republic | Artillery Command | Strong siege coordination, spotting, area denial | Fragile close defense if unescorted |
| Republic | Fortress Defense | Stronger walls, bunker options and repair | Lower mobile offensive efficiency |
| GIA | Guerrilla Warfare | Disguise, ambush, infiltrators, quick relocation | Poor sustained frontal fights |
| GIA | Missile Warfare | Rocket vehicles, saturation and mobile SAM options | Vulnerable to fast assault and precision counters |
| GIA | Salvage & Mobility | Recover wrecks, faster technicals, resource adaptation | Lower peak late-game armor |

Each general should provide (1) a visible early benefit, (2) 1–2 signature units or replacements, (3) a branching upgrade and (4) unique command powers. No general should make an entire counter class inaccessible. Locked or exclusive units must be explained before a match starts.

### 7.5 General promotion and command powers

Players select a general before a skirmish. They gain **command experience during that match** by fighting, defending, capturing and destroying targets; no persistent competitive power carries across matches. **PROPOSED:** ranks 1, 3 and 5 unlock new choice tiers; each tier gives points to select limited powers rather than automatically granting every branch. Powers have telegraphs, cooldowns, tactical counters and UI explanations. Examples: recon flyover, emergency repair drop, artillery marking, smoke screen, decoy, suppression barrage, temporary mobile-resupply benefit. Keep command ability effects readable and avoid click-to-win damage with zero warning.

### 7.6 Superweapons and counterplay

- **Alliance Particle Beam Array:** steerable sustained blue-white beam; high precision, strong against packed or stationary targets; energy-dependent and highly telegraphed.
- **Republic Ironstorm Artillery Array:** several long-range salvos in a visible target zone; strong against fortifications and slow armor; fast units can evacuate between volleys.
- **GIA Ballistic Missile Silo:** marked impact area and delayed strike, strong area damage, temporary *fictional* hazard zone; scouting, dispersal and disrupting the silo are counters.

Every superweapon: one active structure per player by default, major tech/power requirement, very visible warning to all affected sides, significant reload, and a cancellation/destruction policy. Map-wide insta-kills without counterplay are out of scope. Exact damage/charge times are **TUNING**, not final.

---

## 8. AI and skirmish design

### 8.1 Opponent intelligence

The AI uses the **same game command contracts** as a human: queues, resource spending, sight restrictions, tech and movement. A separate strategic planner decides build order, economic expansion, defense, tech progression, army composition and timing attacks. A tactical controller handles squad assembly, scouting, attack routes, threat response and retreat. Individual unit automation remains the same under both human and AI ownership.

### 8.2 Difficulty

- **Recruit:** forgiving reaction time, smaller mixed armies, more mistakes; no need for hidden handicaps.
- **Regular:** balanced rules, varied builds, attacks on exposed economies, respects fog; baseline for quality.
- **Veteran:** better scouting, production uptime and counter decisions; any economic advantages must be explicit in settings.
- **Commander (later):** advanced coordination and map control, not omniscient cheating.

AI must not see undiscovered units or preemptively counter armies it has never scouted under normal rules. Include reproducible seeds and logging for AI decisions to debug passivity and impossible micro.

### 8.3 First 1v1 map — PROPOSED

Symmetrical strategic opportunities, visually distinct starting positions, at least two contested ore routes/fields, one defendable central passage, neutral depot or equivalent objective, enough alternate paths to prevent one turret wall from locking the entire map. Build locations should be easy to read from zoomed-out play. Start with **one land map** and mirror/fairness tests before generating dozens of variants.

### 8.4 Skirmish settings

Faction, general, AI difficulty, map, starting credits, game speed (limited options), fog on/off custom rule, unlimited ore custom rule, superweapons enabled/disabled, optional match time limit, victory rules, unit limit/performance profile once benchmarked. Presets must clearly distinguish standard balanced rules from custom games.

---

## 9. Controls, HUD and accessibility

### 9.1 Windows desktop

Left-click select, drag box selection, shift-add/toggle, right-click contextual orders, WASD/arrows or edge-pan camera, middle-drag pan, mouse-wheel cursor-centered zoom, number-key control groups, attack-move and stop hotkeys, queue orders with modifier, selected-unit command card, construction sidebar, factory queues, minimap jump/pings and event notifications. All controls remappable. Mouse pointer state must communicate normal move, attack, repair, capture, invalid placement and ready placement.

### 9.2 Android touch — purpose-built, not shrunk desktop

One-finger empty-ground drag pans camera; tap selects unit; tap selected unit twice/camera focus optional; tap destination issues context command when a unit/command mode is active, with explicit move/attack buttons where ambiguous. Two-finger pinch zooms; two-finger drag pans if camera focus would conflict. Long-press and drag activates group selection or a dedicated selection mode, not accidental movement. Production/sidebar becomes expandable panels; selected unit commands appear in a bottom action row sized for touch. Provide an **always-available cancel/back** action. Support safe areas, dynamic viewport scaling and accessibility text sizes. Test interactions on a physical Android device; an emulator is not enough.

### 9.3 HUD

Top bar: credits, iron harvester activity indicator, power balance, active general rank and warnings. Side build/production tabs: icons, costs, progress bars, prerequisites and a ready-to-place queue. Bottom/side context panel: selection count, unit health and veterancy, individual unit composition, command buttons, stance/rally, upgrades. Corner minimap: territory, visible units, alerts and camera. Notifications must be actionable and dismiss without covering combat. Distinguish gameplay-critical announcements from cosmetic effects.

### 9.4 Accessibility and comprehension

High-contrast team outlines, colorblind-safe silhouettes/markings, scalable UI, reduced effects/motion mode, subtitles for all voice cues, audio category controls, remappable keys, tooltips describing what counters what, optional extra command confirmation on touch, pause during offline campaign/skirmish, clear warnings before destructive actions. Text and tactical symbols must remain readable in low zoom and at phone resolutions.

---

## 10. Campaign and world — proposed creative framework

### 10.1 Fiction and stakes

Alternate 2027: a global mineral-trade crisis exposes fragile alliances and supply lines. The Alliance presents itself as a rules-based security coalition with superior technology but conflicting member interests. The Republic pursues order and strategic independence through military expansion, with a real civilian cost. The Global Insurgency Alliance unites decentralized opposition networks whose members disagree on liberation, security, profiteering and tactics. No faction should be written as uniformly virtuous or cartoonishly evil. Three intertwined campaigns reveal how the same events look from conflicting perspectives.

### 10.2 Twelve-mission foundation — PROPOSED, not scripted yet

| # | Perspective | Working mission title | Distinct gameplay lesson/goal |
|---:|---|---|---|
| 1 | Alliance | First Contact | Defend base, deploy infantry, scout |
| 2 | Republic | Steel Mandate | Expand refinery economy, advance armored column |
| 3 | GIA | Lines in the Sand | Ambush convoy and salvage while avoiding strongholds |
| 4 | Alliance | Quiet Radar | Capture intel station; prevent sensor blackout |
| 5 | Republic | Iron Crossing | Cross/hold bridge against tactical raids |
| 6 | GIA | Empty Convoys | Disrupt ore trade, defend mobile bases |
| 7 | Alliance | Broken Accord | Secure airfield and evacuate allied units |
| 8 | Republic | Siege Engines | Establish artillery line without losing logistics |
| 9 | GIA | Hidden Roads | Build tunnel pairs, seize neutral infrastructure |
| 10 | Alliance | The Narrow Window | Precision operation to disable strategic array |
| 11 | Republic | Last Directive | Combined-arms defense with difficult command choices |
| 12 | GIA | Fracture Point | Branching final assault and resolution of conflicting narratives |

The chronological sequence should be internally consistent and support mission variety: escort, hold, destroy, capture, rescue, build, defend and timed withdrawal. Campaign scenario scripts modify goals, starting units and resources but should **not** invent a separate combat engine. Story writing, named characters and final mission count need an independent narrative pass after the core skirmish proves fun.

---

## 11. Technology and data architecture

### 11.1 Principles

The simulation owns truth; presentation displays it; commands are validated by simulation. Do not tie unit HP, targeting or economy to a node's current visual geometry. Gameplay must be independently testable in headless Godot and ideally use the same command pathway for human, AI, campaign and future networking.

### 11.2 Proposed modules (conceptual, not mandated filenames)

| Domain | Responsibility |
|---|---|
| `GameRules` / `MatchState` | Match phases, teams, credits, victory, pause/save |
| `CommandBus` | Validated orders from player UI, AI and mission scripts |
| `WorldGrid` / `MapData` | Terrain, static occupancy, map facilities, seeds and resources |
| `NavigationService` | Global routes, local avoidance, multi-unit destinations |
| `EntityStore` | Stable IDs, ownership, transforms, status, HP, orders |
| `EconomySystem` | Harvesters, deposits, refineries, credits and incomes |
| `BuildSystem` | HQ construction queue, placement radius, footprints, refund rules |
| `ProductionSystem` | Factory queues, upgrade prereqs, rally points |
| `CombatSystem` | Visibility, acquisition, projectile simulation and damage |
| `VisionSystem` | Fog, shroud, radar, stealth detection |
| `AIStrategy` and `AITactics` | Resource planning, army composition, assaults and retreats |
| `ProceduralRenderers` | Terrain chunks, geometries, decals, effects and LOD |
| `UserInterface` / `InputAdapters` | Desktop/touch commands, HUD, menus, minimap |
| `MissionRuntime` | Briefings, objectives, triggers, cutscenes and victory overrides |
| `Serialization` | Versioned saves and authored map/scenario formats |

### 11.3 Entity/data definitions

Content should be **data-driven** with stable identifiers and immutable balance definitions. Example *illustrative* unit definition (not final serialization format):

```yaml
id: alliance_sentinel_tank
faction: alliance
kind: ground_vehicle
role: main_battle_tank
cost_credits: TBD
build_time_seconds: TBD
requires: [alliance_war_factory]
health: TBD
armor_class: heavy_armor
speed_cells_per_second: TBD
weapon_id: tank_cannon_90mm_fictional
vision_cells: TBD
visual_id: tank_alliance_sentinel_geometry
```

Avoid pinning gameplay definitions to brand-owned asset names, scene paths or text labels. Define separate tables for weapons, armor multipliers, ability rules, geometry definitions and tech prerequisites. Version data to keep saved games and balance changes traceable.

### 11.4 Simulation timing and multiplayer readiness

**PROPOSED starting point:** a fixed 20 simulation ticks/second for economy, movement, orders and cooldowns; rendering may run at 60 FPS with visual interpolation. Profile before finalizing tick rate. Commands carry match tick and unique actor/target IDs, never screen coordinates as authoritative game logic. Seed any random effects that influence simulation. Cross-platform deterministic lockstep is **not assumed**; test numeric stability and desync tolerance before committing to a network transport/authority model. A server-authoritative or lockstep model must be selected deliberately before PvP implementation.

### 11.5 Procedural renderer performance

Static terrain geometry caches in chunks; avoid creating one heavyweight object per grass blade. Building geometry redraws on state changes. Vehicle geometry uses reusable local shapes, with turrets and effects updated only as needed. Explosions, tracks, smoke and projectiles use pooling and on-screen LOD. Fog visibility updates should be amortized/partitioned. Measure draw calls, CPU tick time, input latency, pathfinding spikes and memory on both desktop and Android. 'Code drawn' is not automatically fast: poorly batched `draw_*` per entity can still be expensive.

### 11.6 Preserve/reuse plan for existing code

| Existing WebRTS item | Assessment before implementation |
|---|---|
| `godot/scripts/rts_camera.gd` | **Reuse/adapt** pan, zoom and touch infrastructure after removing assumptions about isometric bounds and fixing input conflicts with unit orders |
| `godot/scripts/battlefield.gd` | **Replace projection/terrain atlas**, preserve useful seeded map generation, occupancy concepts and scene plumbing |
| `godot/scripts/terrain_obstacle.gd` | **Refactor renderer**: procedural `_draw()` basis is useful; adapt footprints, shadow/palette and top-down shapes |
| `godot/scenes/buildings/command_center.tscn` | **Reuse entity concept**, replace asset-facing projection/geometry and formalize build state |
| Existing 19-building roster | **Preserve roles/identities**, replace isometric PNG contract |
| Existing 115-slice isometric roadmap | **Supersede through reviewed migration**, retain only compatible gameplay intent; don't check old workboxes as completion of new systems |

---

## 12. Milestones and vertical slice acceptance

### 12.1 Suggested project phases (not code tasks authorized yet)

| Phase | Goal | Exit gate |
|---|---|---|
| **Design sign-off** | Resolve P0 decisions and reconcile roadmap with this GDD | One approved rule set and revised release gates |
| **Foundation preservation** | Tag/branch existing Godot work; prove baseline runs; map replacement strategy | Existing build retained and no lost source |
| **Procedural visual proof** | Top-down terrain and recognizably distinct infantry/tank/HQ drawn at three zoom levels | Clear at mobile and desktop scales |
| **Movement/control proof** | Select, group, order, path and fire with dozens of units | No persistent jams; responsive controls |
| **Economy/base loop** | HQ construction, refinery, harvesters, credits, power, factories | Closed, testable resource-to-unit loop |
| **Complete skirmish vertical slice** | Two bases, AI, combat, victory, defeat, pause/restart, UI | End-to-end playtest passes, not just smoke test |
| **Faction differentiation** | Alliance/Republic/GIA, counter matrix, tech and upgrades | Distinct strategies with viable counters |
| **1.0 content gate** | AI polish, general powers, campaign, menus, audio, saves, accessibility, maps | Windows release candidate with metrics and playtesting |
| **Expansion gate** | Water/naval, 9-general completeness, Android shipping, multiplayer | Schedule/quality evaluated explicitly, not assumed |

### 12.2 Vertical slice minimum roster

One initially playable faction mirror-match is acceptable **only while building the foundation**; the **complete vertical slice** should expose at least two visibly distinct sides/factions to test ownership and counter readability. Minimal first pass uses:

- **Buildings:** HQ, power plant, ore refinery, barracks, War Factory, basic turret (6 types; separate factions' geometry can share behavior), with optional repair later.
- **Units:** harvester, rifle infantry, anti-armor infantry, engineer (if capture is in slice), scout/light vehicle and main battle tank (5–6 types).
- **Economy:** one finite ore field near each base, one contested field, and one late-game income mechanism activated in testing.
- **Orders:** select, group, move, attack, attack-move, stop, build, rally, harvest; save/load may follow after basic battle integrity is proven.
- **Opponent:** one AI that constructs, harvests, builds an army, attacks, defends exposed harvesters and can win/lose.
- **UI:** credits, power, production queues, build placement, selection, minimap, health, victory/defeat and pause/restart.
- **Map:** one balanced, authored land skirmish with fog and at least one approach/choke and alternative route.

**Acceptance:** a new user can start from a menu, gather resources, place buildings, build troops, give standard RTS orders, defeat or be defeated by an opponent, see a result and restart without dev console intervention or missing assets.

### 12.3 Specific acceptance tests

1. **Baseline boot:** start from project manager/headless import; no parse errors, missing dependencies or fatal errors.
2. **Economy test:** harvester loads, delivers exactly once, credit accounting matches cargo, finite deposit reaches zero, late-game income works after all ore is gone.
3. **Construction test:** valid and invalid placements, cancellation/refunds, two-yard queues and brownout behavior are consistent; no build overlaps.
4. **Combat test:** weapon counters work in simulation, independent tank turret targeting behaves correctly, attack-move and stance rules function, HP zero cleans up.
5. **AI test:** Regular AI uses only explored information, builds functional economy, attacks and finishes a match on at least three reproducible seeds.
6. **Movement test:** 20-unit group traverses a bridge, harvesters unload in congestion and stranded units do not continuously block the simulation.
7. **Control test:** desktop selection, groups, move/attack/build; touch select, camera pan, zoom, order and cancellation on device.
8. **Visual test:** QA at close, default and far zoom; players can identify faction, unit type and facing in representative combat density.
9. **Save/return test:** saved match resumes equivalent credits, queues, units, ore, fog and AI state once save/load is in slice.
10. **Performance test:** record median and 1% low frame rate plus simulation time. **Initial goals (TUNING):** 60 FPS desktop and 30 FPS on a chosen midrange Android device during a 100-unit stress scene; set measured hardware profiles before claiming targets met.
11. **Usability test:** complete 3 fresh-user matches; no basic progress blocker and key menus/orders understood without developer instructions.
12. **CI:** validation checks run on pull requests, but automated import/smoke is distinct from real gameplay and device acceptance.

### 12.4 Definition of Done for every future slice

Design rule referenced -> implementation integrated -> deterministic/unit test or reproducible scenario -> Godot build/start check -> desktop hands-on test -> mobile impact check -> performance/regression measurement -> documentation and screenshot/video evidence -> source commit/CI. An unchecked item remains incomplete even if a related placeholder looks good.

---

## 13. Balance process

- First balance **time-to-first-harvester delivery**, **time-to-first-tank**, **time-to-first-attack** and **average match duration**, not dozens of individual DPS values.
- Ensure every opening choice can be scouted and countered; a player who builds only tanks should lose to a competent anti-armor composition at an appropriate resource trade.
- Compare equivalent-resource armies, not equal unit counts. Map spawn advantage and defensive positions can outweigh small stat changes.
- Track credits floated, credit income/minute, harvester losses, building queue idle time, units lost by class, damage by attack type, general ability use, match length and win rate by side/general.
- For fairness, test faction matchups at equivalent skill and map starts. Avoid balancing only against an AI that follows one build order.
- Do not permanently lock numeric values in this GDD until the full skirmish loop exists; maintain separate versioned balance tables.

---

## 14. Out of scope / explicit non-goals

**Initial proof-of-concept non-goals:** all 57 unique building geometries, nine generals, naval simulation, fully authored campaign, online matchmaking, physics-based building destruction, realistic ammunition/fuel accounting, full 3D maps, character models, manually drawn animation sheets, giant procedural world editor, platform account integration.

**Game-wide non-goals:** exact recreation of copyrighted units/buildings/audio/UI from C&C; military simulation realism at the cost of accessibility; pay-to-win persistent upgrades; opaque AI wallhacks under normal difficulty; forcing online connectivity for offline play.

---

## 15. High-priority unresolved decisions

| ID | Priority | Question | Recommended provisional answer | Gate |
|---|---|---|---|---|
| D-01 | P0 | Which repository is source of truth? | `AlmightyTank/WebRTS` (`godot/`), not `WebRTS-Native` | Before migration |
| D-02 | P0 | Does 1.0 require online PvP? | Design for it, but keep 1.0 Windows offline-first unless network feasibility is proven | Before re-roadmap |
| D-03 | P0 | Does Army Supply Cap exist? | No hard cap for slice; test gameplay before enabling | Before unit scaling |
| D-04 | P0 | Exact command capability defeat rule? | Destroy all HQs/MCVs; HQ-only in first slice | Before skirmish |
| D-05 | P0 | What is late-game income? | Capturable depots + capped depot reclamation; test for turtling | Before full economy |
| D-06 | P0 | Which faction(s) are in first vertical slice? | One shared ruleset, at least two distinct appearances by acceptance | Before slice scope |
| D-07 | P1 | Can HQ/engineers unlock foreign tech? | Not in slice; partial research-gated system later | Before capture |
| D-08 | P1 | Are ships/naval mandatory at 1.0? | Conditional on stable water pathing/performance | Before content roadmap |
| D-09 | P1 | How many campaign missions? | Target 12 narrative missions, three perspectives, expand after story/playtest | Before campaign scripting |
| D-10 | P1 | What is base construction speed/cancel refund? | One active slot/HQ; 100% refund before placement; test during-build refunds | Before economy balance |
| D-11 | P1 | Is tactical high ground used? | Visual cover/chokes first; height-based combat modifiers later | Before map system |
| D-12 | P1 | Is friendly splash damage enabled? | Off for standard mode first | Before damage tuning |
| D-13 | P1 | Windows and Android release cadence? | Windows first; Android when touch/performance acceptance met | Before packaging |
| D-14 | P2 | Replay and spectator features? | Structure commands for replay; ship later | After slice |
| D-15 | P2 | Alternate match rules (infinite ore, annihilation)? | Custom skirmish options; standard balance unaffected | After basic skirmish |

### 15.1 Proposed next design documents

1. **Rules and Balance Specification:** exact costs, HP, ranges, power values, timing, armor tables and progression with test assertions.
2. **Entity/Tech Tree Catalog:** every faction unit/structure/upgrade and hard dependencies, plus superweapon and general powers.
3. **Procedural Visual Standard:** top-down geometry templates, color grammar, LOD, hardpoint and animation-by-transform rules, sample screenshots at three zooms.
4. **Input and UX Specification:** desktop/touch flow maps, context command priority and edge cases.
5. **Skirmish Vertical Slice Plan:** backlog ordered by dependency, acceptance tests and performance gates; supersede isometric roadmap without deleting history.
6. **Campaign Bible:** faction political dynamics, character arcs, chronological events and detailed twelve-mission scripts.

---

## 16. Design sign-off checklist

- [x] Top-down battlefield with subtle procedural building depth — user-approved.
- [x] RA2-style Construction Yard plus optional engineers — user-approved.
- [x] Finite iron ore and meaningful late-game income — user-approved.
- [x] Fast C&C-inspired arcade RTS combat — user-approved.
- [x] Complete small skirmish is the first major playable milestone — user-approved.
- [x] Alliance, Republic, GIA exist as established project factions; existing 19-role roster recovered from repository.
- [ ] Confirm details marked **P0** in section 15 before rewriting code/roadmap.
- [ ] Approve vertical-slice MVP roster and first-map shape.
- [ ] Record architecture migration and source control strategy.
- [ ] Reconcile current isometric roadmap, README and asset inventory after design approval.
- [ ] Translate accepted design into a complete dependency-ordered development roadmap with tests.

### Change history

| Version | Date | Notes |
|---|---|---|
| 0.1 | 2026-10-31 | First master GDD based on five approved decisions; references the active WebRTS Godot state and existing three-faction building roster; proposes rules for the economy, construction, combat, AI, UI, visuals, campaign and end-to-end skirmish. No game code or repository files changed. |

### Reference documents in existing repository

- [WebRTS README](https://github.com/AlmightyTank/WebRTS/blob/main/README.md)
- [Archived ideas from the former isometric roadmap](https://github.com/AlmightyTank/WebRTS/blob/main/docs/IDEAS.md)
- [Three-faction building roster](https://github.com/AlmightyTank/WebRTS/blob/main/docs/FACTION-BUILDING-ROSTER-1.0.md)
- [Sprite inventory (legacy art strategy)](https://github.com/AlmightyTank/WebRTS/blob/main/docs/SPRITE-ASSET-INVENTORY.md)

**Proposed eventual repository destination:** `docs/MERIDIAN-WARFRONT-MASTER-GDD.md` (not pushed in this drafting step).
