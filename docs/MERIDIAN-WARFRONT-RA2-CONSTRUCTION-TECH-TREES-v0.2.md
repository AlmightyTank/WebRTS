# Meridian Warfront — Red Alert 2-First Construction & Technology Specification

**Revision:** 0.2 — design proposal, 2026-10-31  
**Parent document:** `MERIDIAN-WARFRONT-MASTER-GDD-v0.1.md`  
**Intended repository:** `AlmightyTank/WebRTS`, proposed `docs/MERIDIAN-WARFRONT-RA2-CONSTRUCTION-TECH-TREES.md`  
**Status:** Detailed proposal for collaborative review. No game code or GitHub files changed.

> **Design instruction:** Prefer the *rhythm, clarity and interaction model* of Command & Conquer: Red Alert 2 over more elaborate mechanics from Generals: Zero Hour. Preserve original Meridian Warfront factions, artwork, names, fiction, and source code. This addendum **supersedes conflicting proposals** in the parent GDD concerning construction queues, extra Construction Yards, victory conditions and production queues; other parent sections remain proposals unless separately approved.

## 1. Player promise and fidelity targets

The player should be able to: deploy an MCV; click a power plant on a four-tab right sidebar; watch a circular build timer; place the completed building beside the base; set up an ore refinery and free first harvester; grow the army from barracks and war factories; speed up training by adding more factories; build perimeter defenses independently of the main building queue; rush, expand, turtle, capture, sell and repair; eventually use battle labs and superweapons.

This is a **top-down procedural 2D game**, not an isometric sprite clone. Game rules and presentation rhythm emulate RA2; artwork does not.

### Closest-to-RA2 rules (strong proposals)

1. **MCV → Construction Yard:** Default skirmish begins with one mobile command vehicle (MCV) and credits. Deploy it on clear buildable land to unlock the sidebar. An MCV can pack and move again after a brief, vulnerable pack/unpack sequence. Alternative campaign missions may start with a deployed Yard.
2. **Four persistent sidebar tabs:** `BUILDINGS`, `DEFENSE`, `INFANTRY`, `VEHICLES`; vehicle tab also has aircraft/naval filters when applicable. Keep the power meter, credits, minimap/radar, repair/sell modes and production timers visible.
3. **Two construction lanes:** Exactly one shared `BUILDINGS` lane and one shared `DEFENSE` lane per player, available while an operational owned Construction Yard exists. They can run **at the same time**. They are not one lane per yard.
4. **One queue per production domain:** Infantry, ground vehicles, aircraft and naval vessels operate concurrently through their respective production domains. Factories of the same domain **accelerate that domain**, not create unrestricted independent queues; domains can build in parallel.
5. **READY-to-place:** Completed buildings are stored as a deployable placement preview. The relevant construction lane remains blocked until the completed structure is placed or canceled; vehicles/infantry can still train.
6. **RA2-style adjacency:** Place new buildings near existing eligible allied structures. The main Yard is the original anchor; most ordinary owned buildings expand valid adjacency. Walls and turrets do not generally extend the build boundary. A forward outpost can deliberately expand it.
7. **Harvester rhythm:** First refinery comes with one harvester; harvester automatically gathers from assigned/nearest viable ore patch, returns to nearest usable refinery, unloads once, and resumes.
8. **Credits drip during building:** Deduct credit cost gradually as construction proceeds. When credits reach zero, production pauses and resumes automatically on new income. Do not charge full price upfront by default.
9. **Repair and sell modes:** Building repair drains credits while restoring HP. Selling an ordinary structure removes it and returns a clearly communicated fraction of its value, without a profitable sell/build loop.
10. **No hard unit cap in normal skirmish:** Production throughput, economy, space and performance create practical army limits. Do not introduce a Generals-style supply-cap mechanic as a fourth strategic resource.

### RA2-specific findings that guide this design

- The original Red Alert 2 manual describes four production tabs, construction-and-placement once `READY`, credit deductions over time, halted production on insufficient funds, free refinery mining vehicles, rally points, repair/sell modes, and reduced functionality under low power.
- Its *Short Game* skirmish option focuses defeat on loss of significant buildings rather than hunting every unit.
- Modding analysis documents the production-time benefit from multiple identical factories/Construction Yards. **Do not** import the later Generals mechanic of completely independent factory queues when aiming at RA2 pacing.

## 2. Construction command contract

### 2.1 Player interactions

`select icon → progress timer (credits drained) → READY → green/red ground preview → left-click/tap to place → structure becomes operational`

- Click on an available building/defense icon: start its category's construction if idle; otherwise the UI explains that category is busy.
- A **left-click** on an existing production icon can resume a paused entry. The UI must make pause, cancel and READY actions unambiguous; for touch, use dedicated buttons rather than a right-click-only workflow.
- While READY, the preview follows pointer/touch, snaps to grid, shows the ground footprint, doors/exits, viable green cells, blocked red cells and placement reason tooltip.
- Buildings take effect **immediately upon placement**, with a 0.4–1.0 second purely cosmetic assembly effect. Do not impose a second Generals-like worker-based on-map construction timer.
- Normal buildings cannot rotate, initially; standardize exits and clickable ground footprints. A later optional orientation feature may be added without altering placement validity.
- Multiple items cannot be prebuilt in the same building or defense category. Producing a building and defense in parallel **is allowed**.
- If the last Yard is packed or destroyed, building/defense production halts. Other existing unit factories continue producing while powered; an undeployed MCV can restore the Yard.
- The active category and progress survive switching sidebar tabs or selecting units.
- On cost withdrawal, use one authoritative simulation account. `payment = min(remaining_cost, available_credits, target_spend_this_tick)`; progress advances proportionally to paid construction cost. Unspent credits never become negative.
- Pausing stops both cost withdrawal and progress. Cancel returns **exactly the credits invested in that item**, not a free full-cost refund if only partly built.
- A completed READY structure has 100% paid cost; canceling it returns 100% while unplaced. After placement, demolition/sell rules apply.
- Power shortages: production slows to a clear fraction, and power-dependent defenses shut off; constructing another power plant remains possible without power.

### 2.2 Queue and multiple-factory rules

| Domain | Earliest producer | Concurrent with | Effect of adding another producer |
|---|---|---|---|
| Buildings | Construction Yard | Defense, Infantry, Vehicles, Aircraft, Naval | Faster **shared** building lane |
| Defense | Construction Yard | Buildings and units | Faster **shared** defense lane |
| Infantry | Barracks | All other domains | Faster **shared** infantry lane |
| Ground vehicles | War Factory | All other domains | Faster **shared** ground vehicle lane |
| Aircraft | Airfield | All other domains | Faster aircraft lane; pads add capacity |
| Naval | Naval Dock / Shipyard | All other domains | Faster naval lane; water-map only |

**Illustrative speed factor, not approved balance:** category completion time = `base_time × 0.82 ^ min(additional_operational_factories, 3)` with a **0.55 × base-time floor**. Multiple factories speed up queues but there is still only one active unit being assembled per domain; arrival locations choose the active producer and can be switched. Construction Yards accelerate both building and defense lanes.

- Infantry and ground vehicles each permit a visible queued list (proposed maximum 20 entries) and `+1 / +5` quick order controls.
- A single producer must exist for the domain. If the last producer disappears, unfinished orders **pause** while producer capacity is absent; let the player cancel/refund or rebuild a producer. Finished-but-blocked units stay pending at a physical exit.
- Producers may not exploit free spawn space: if every appropriate factory exit is blocked, build completion waits, clearly marked `EXIT BLOCKED`, without creating overlapping units.
- Refund pending unstarted orders in full, and active orders by their actual invested credits. There is no invisible bank/debt.
- Additional factory effects use diminishing benefits and cost more power/credits, so two factories are useful but twenty are not mandatory.

### 2.3 Grid adjacency and placement

**Proposed initial constants** (tunable after first playable match):

| Parameter | Initial proposal |
|---|---|
| Logical grid | 32 × 32 world-unit square ground cells, with top-down 2.5D rooftops projected visually upward |
| Most core economic/production buildings | 3×3 or 4×3 cells, authored per role |
| Basic defense | 1×1 or 2×2 cells |
| Standard maximum gap from an eligible friendly building | 2 grid cells, measured shortest edge-to-edge gap |
| Yard placement nucleus | Occupies 4×4 cells, allows normal connected expansion |
| Outpost expansion | New eligible placement anchor after the forward outpost is operational |
| Walls | May be placed in short continuous lines from connected base; do **not** create expansion anchors |
| Neutral capture | Ownership alone does not instantly make every neutral tech building an unlimited build-radius anchor |
| Placement blocks | Terrain, water (except naval), cliffs, buildings, unmovable obstacles, living units in footprint, enemy-only zones |
| Moving allied unit blocks | Show `UNITS BLOCKING SITE`; do not silently place over or crush it |
| Fog | No blind building into unexplored terrain; require explored and currently valid footprint |

This deliberately allows **base crawling** through ordinary structures, an RA2 strategy worth preserving, while walls and cheap turrets do not provide free infinite extension. A discrete expansion anchor may provide a more expensive alternate route.

### 2.4 Selling, repairs and MCV recovery

- **Sell:** default return = 50% of adjusted building price, capped by actual prior payment; fully sellable only if placed and operational. A refinery sale must account for whether its included harvester is retained to avoid money exploits. Sell confirmation is optional desktop, required for touch on unique HQ/superweapon.
- **Repair:** toggle via wrench mode and pay as HP is restored; paused if credits run out; automatic restore resumes when funded. Repair is cheaper than reconstructing, but under attack cannot out-heal overwhelming damage.
- **MCV:** standard constructible mobile command vehicle unlocked by War Factory + Service Depot. Deploying occupies a large clear footprint and changes command authority; packing leaves no magical ghost anchor. If it is the last command source, building/defense queues pause.
- **Capturing:** engineers are trained at barracks. Neutral tech buildings are captured on entry; enemy capture has a short interruptible take-over to remain readable. Engineer is consumed on successful capture. Full enemy tech theft requires separate research/tech restrictions later.
- **Destroyed Yard:** existing units and structures remain; active Building and Defense lanes freeze. A surviving MCV can deploy, or a player may capture another eligible Yard. Do not instantly force defeat solely for losing the Yard when substantial other structures remain.

## 3. Economy, radar, and power (RA2-like behavior)

### Ore
- Finite normal ore plus rare high-value deposits (higher credits per cargo, still finite).
- Every refinery **spawns one free harvester** on completed placement. Extra harvesters are bought at the War Factory.
- Harvester behavior: seek patch → gather up to capacity → reserve/route to friendly refinery → unload **exactly once** → return to available ore. Repairable and vulnerable to harassment.
- Refinery throughput, ore position and harvester traffic should matter more than an abstract income-per-second bar.
- Ore is the primary mined resource; there is no additional worker supply economy.

### Late-game income without breaking RA2 feeling
- Prefer **capturable neutral industrial depots / oil-equivalent derricks** as the main renewable income: fixed small periodic credit payments while held. This preserves familiar map-control gameplay.
- At T2, an existing Supply Depot/Stockpile may buy a costly **Reclamation Contract** upgrade for a *small, capped* backup trickle, so finite ore cannot permanently stalemate a match.
- Avoid mass passive-income structures that make harvesters irrelevant. Salvage is a GIA/faction specialist bonus, not the universal primary income.
- Infinite ore is a skirmish rule modifier, not default balance.

### Power
- A single player-wide power ledger. Generators provide power, facilities consume it; construction has no separate worker or fuel requirement.
- At low power, map radar shuts down, some defenses disable, and build/unit progress slows by a clear factor (proposed 50%).
- Power plants and MCVs must remain repairable/buildable during an outage to prevent unwinnable lockout.
- Radar/minimap terrain memory remains explored even when signal is lost; live sensor updates cease until power returns. This feels closer to RA2 than an always-perfect minimap.

## 4. Three-faction shared technology skeleton

**Shared progression, different capability and identity.** Terms use existing WebRTS three-faction building roster, not RA2 copyrighted faction names.

```text
MCV
 └─ DEPLOY → CONSTRUCTION YARD (HQ)
     ├─ POWER PLANT
     │   ├─ ORE REFINERY → free HARVESTER
     │   │   ├─ SUPPLY DEPOT → Reclamation Contract (advanced)
     │   │   ├─ RADAR / INTEL → minimap + new options
     │   │   │   ├─ FORWARD OUTPOST
     │   │   │   └─ AIRFIELD (plus War Factory)
     │   │   └─ WAR FACTORY (also requires Barracks)
     │   │        ├─ SERVICE DEPOT → MCV
     │   │        └─ ADVANCED TECH CENTER (also requires Radar)
     │   │             ├─ elite units and advanced upgrades
     │   │             ├─ faction utility structure
     │   │             ├─ heavy defensive weapon
     │   │             └─ SUPERWEAPON
     │   └─ BARRACKS
     │       ├─ infantry / engineers
     │       ├─ basic gun emplacement
     │       ├─ walls / gate
     │       └─ AA defense (also requires Radar)
     └─ NAVAL YARD (also requires Power + Refinery; water maps)
```

A **tech dependency** is not a cost tier: if a prerequisite building is destroyed, **new** production requiring it is locked until rebuilt; units already manufactured are not deleted and already completed upgrades remain. A special tech building that was legitimately captured may grant a specific capability, never an unexplained full tree.

### Full common building-role catalog — proposed first tuning values

These are **Meridian proposals**, not purported RA2 figures. Costs are in credits, times in game seconds, `+P` generates power and `−P` consumes power. Building identities differ per faction (next section). Health, armor and precise placement footprints remain separate data fields to balance.

| # | Role | Tab | Requirement | Cost | Time | Power | Primary purpose |
|---|---|---|---|---:|---:|---:|---|
| 01 | Construction Yard / HQ | MCV deploy | Deployed MCV | MCV cost | 4 | 0 | Base authority and adjacency |
| 02 | Power plant | Buildings | HQ | 800 | 10 | +150 | Power generation |
| 03 | Ore refinery | Buildings | Power | 2,000 | 24 | −50 | Ore → credits; free harvester |
| 04 | Supply depot | Buildings | Refinery | 900 | 14 | −10 | Base utility; late backup income upgrade |
| 05 | Barracks | Buildings | Power | 500 | 10 | −10 | Infantry and engineers |
| 06 | War Factory | Buildings | Barracks + Refinery | 2,000 | 26 | −30 | Vehicles and additional harvesters |
| 07 | Radar / intel | Buildings | Refinery | 1,000 | 16 | −50 | Live minimap, tech and sensor unlock |
| 08 | Forward outpost | Buildings | Radar | 1,200 | 19 | −25 | Remote base anchor |
| 09 | Basic gun defense | Defense | Barracks | 550 | 9 | −10 | Counter infantry/raids |
| 10 | Anti-air defense | Defense | Barracks + Radar | 950 | 12 | −45 | Stop aircraft attacks |
| 11 | Service depot | Buildings | War Factory | 850 | 14 | −25 | Repair vehicles; unlock replacement MCV |
| 12 | Advanced Tech Center | Buildings | War Factory + Radar | 2,000 | 28 | −100 | Advanced units and structures |
| 13 | Airfield | Buildings | War Factory + Radar | 1,450 | 22 | −50 | Aircraft and pad/rearm capacity |
| 14 | Heavy static defense | Defense | Tech Center | 1,650 | 19 | −90 | Break armor/sieges |
| 15 | Walls | Defense | Barracks | 90/segment | 2/segment | 0 | Delay and funnel attackers |
| 16 | Security gate | Defense | Barracks | 320 | 5 | 0 | Friendly unit passage through walls |
| 17 | Faction utility | Buildings | Tech Center | 1,850 | 23 | −75 | Distinct faction ability |
| 18 | Superweapon | Defense | Tech Center + Radar | 4,500 | 38 | −200 | Telegraphed strategic weapon |
| 19 | Naval production | Buildings | Power + Refinery + suitable shoreline | 1,300 | 21 | −25 | Build and service ships |

**Economy note:** the starter Supply Depot remains optional and does **not** impose a unit cap. It should never become a mandatory tech choke immediately after refinery. **Naval:** no requirement to build naval structures on land-only skirmish maps. **Advanced units:** distinct unit-level prerequisites are listed below.

## 5. Exact faction structure mapping (19 roles each)

| Role | Alliance | Republic | GIA |
|---|---|---|---|
| HQ | Command Center | High Command Citadel | Resistance Headquarters |
| Power | Fusion Plant | Thermal Power Station | Diesel Generator Yard |
| Ore processing | Ore Refinery | Industrial Ore Works | Scrapyard Refinery |
| Supply | Supply Depot | Quartermaster Depot | Hidden Stockpile |
| Infantry | Barracks | Garrison Barracks | Militia Camp |
| Vehicles | War Factory | Armor Works | Salvage Garage |
| Radar | Satellite Uplink | Command Radar | Signal Shack |
| Outpost | Forward Command Post | Fortified Outpost | Forward Hideout |
| Gun defense | Sentry Turret | Machine-Gun Bunker | Gun Nest |
| Anti-air | SAM Launcher | Flak Battery | Salvaged AA Platform |
| Repair | Service Hangar | Vehicle Maintenance Depot | Field Workshop |
| Advanced tech | Advanced Tech Center | Military Research Center | Black Market Laboratory |
| Air | Airfield | Strike Airbase | Hidden Airstrip |
| Heavy defense | Gauss Turret | Heavy Anti-Tank Emplacement | Recoilless Cannon Nest |
| Wall | Energy-Reinforced Barrier | Reinforced Concrete Wall | Scrap Barricade |
| Gate | Security Gate | Fortress Gate | Checkpoint Gate |
| Utility | Drone Control Node | Heavy Foundry | Tunnel Network |
| Superweapon | Particle Beam Array | Ironstorm Artillery Array | Ballistic Missile Silo |
| Naval | Naval Dock | Armored Shipyard | Riverboat Yard |

### Differentiation without abandoning RA2 rhythm

**Alliance:** power-efficient high-tech base, excellent sensing and precision air/beam weapons, expensive elite units, lighter conventional armor; vulnerable to power disruption. Utility unlocks recon drones/target designation. Superweapon is a guided particle beam.

**Republic:** tougher structures/walls, slower hard-hitting ground forces, superior artillery, heavy-factory throughput, more costly mobility. Utility upgrades armored vehicle production and durability. Superweapon is a multi-salvo strategic artillery strike.

**GIA:** cheaper basic infantry and vehicles, weaker armored structures, more mobile light forces, concealment, outpost/tunnel options and salvage bonuses. Utility is a network of linked tunnel entrances. Superweapon is a ballistic missile strike with an avoidable warning zone.

**Preserve fairness:** each faction always has an anti-infantry, anti-armor, anti-air and base-breaching pathway. Distinctiveness comes from costs, silhouettes, unit abilities, and tactics, **not** removing basic counters from a faction.

## 6. Which units become available at each tech step?

The following is a **role contract** for the original Meridian unit names; further statistics and exact purchase prices belong in the balance matrix.

| Progression | Alliance | Republic | GIA | Main requirement |
|---|---|---|---|---|
| Basic rifle infantry | Ranger | Line Infantry | Militia Fighter | Barracks |
| Anti-armor infantry | Javelin Team | Tank Hunter | Rocket Cell | Barracks + Refinery |
| Engineer | Field Engineer | Combat Engineer | Salvage Technician | Barracks |
| Harvester | Ore Harvester | Industrial Hauler | Salvage Collector | Free with Refinery, more via War Factory |
| Light raider | Lynx IFV | Ironclad APC | Raider Technical | War Factory |
| Main battle tank | Sentinel Tank | Bastion Tank | Scavenger Tank | War Factory |
| Scout specialist | Specter Scout Drone | Recon APC | Raider Bike | War Factory / faction-specific early alternative |
| Mobile AA | Sentinel AA | Flak Carrier | Rocket Truck | War Factory + Radar |
| Artillery | Precision Howitzer | Thunderbolt Artillery | Rocket Buggy | War Factory + Radar |
| Heavy/elite armor | Arc Beam Tank | Mammoth Siege Tank | Reclaimed Assault Tank | War Factory + Tech Center |
| Aircraft | Striker Gunship | Siege Helicopter | Improvised Attack Helicopter | Airfield |
| Advanced aircraft | Specter Strike Craft | Heavy Bomber | Missile Drone Wing | Airfield + Tech Center |
| Replacement MCV | Alliance MCV | Republic MCV | GIA MCV | War Factory + Service Depot |

**Strategic rule:** make tanks available *before* the Tech Center, so early/midgame is already an RTS. The Tech Center unlocks specialized solutions, not the basic ability to fight.

### Phase gates

- **T0 / opening:** MCV/Yard, power, refinery + harvester, barracks, infantry, engineers, simple defenses.
- **T1 / armored warfare:** War Factory, cheap vehicles, tanks, second harvester, radar, AA, outpost and repairs.
- **T2 / advanced warfare:** Tech Center, aircraft/elite armor, advanced defenses, specialty upgrades and faction utility.
- **T3 / strategic endgame:** superweapon, advanced powers and selected elite upgrades. T3 uses new prerequisites/credit costs but no fourth generic "super-tech research meter."

## 7. Upgrades, generals and command powers

**RA2-first constraint:** Keep technology principally *building-gated*. Do not turn the base into dozens of research menus before the core construction loop is fun.

- **Basic upgrades** (small scope): at War Factory or Tech Center, one armor package and one targeting package; at refinery, unloading efficiency; at support depot, reclamation. Selecting the building opens a compact upgrades pane, not a new compulsory production tab.
- **Generals** (Zero Hour layer): choose one of nine specializations before skirmish. Each changes 1–2 units and/or unlocks one specialist building/ability plus a small doctrine bonus; keep the common tree recognizable.
- **Promotions:** earn command experience during a match and spend rank points on special abilities, with visible cooldowns and counterplay. All power is reset each new competitive match.
- **Radar is meaningful:** ordinary minimap requires radar + sufficient power. Fog-shroud still works independently.
- **Superweapon toggle:** skirmish setup supports ON/OFF, like RA2. Each faction has one signature strategic weapon; activation warns opponents and provides counterplay.

## 8. Victory and skirmish option correction

**Closer-to-RA2 proposal:** Default `SHORT GAME` victory when an opponent has **no significant owned buildings and no surviving MCV**. Exclude insignificant walls, decorative wreckage and passive neutral objects from keeping a player alive. Keep `ANNIHILATION` as a toggle that also requires remaining enemy military units to be destroyed.

This replaces the earlier parent GDD's `destroy every Construction Yard/MCV to win` rule. Destroying an HQ should be a devastating *strategic disadvantage*, but not necessarily an instant loss while a player's other important base structures and army survive. The first skirmish can simplify by explicitly stating its victory objective, but must not silently teach the wrong full-game rule.

Additional options: starting credits, starting unit count, game speed, random faction/position, short game, superweapons, infinite ore and build near ally (where ally teams are available).

## 9. First complete skirmish (build what proves the RA2 fantasy)

**First deliverable:** One balanced **1v1 land map** against a real AI, using identical generic strategic rules beneath two visually distinct sides (Alliance and Republic proposed). GIA's complete roster follows after core mechanics are tested.

**Minimum buildings:** Yard, Power, Refinery, Barracks, War Factory, Gun Defense. **Radar and Service Depot are the next extensions**; the DEFENSE lane must already be distinct in MVP even if it offers only one turret.

**Minimum units:** MCV (initially can be predeployed if necessary for the first automation test), Harvester, Rifle Infantry, Rocket Infantry, Engineer (can be omitted until capture mechanics are tested), Light Vehicle, Main Battle Tank.

**Representative opening build order** (validity target, not optimal mandatory play):

1. Deploy MCV → build Power (10s baseline).
2. Build Refinery (24s baseline), receive one Harvester, start ore loop.
3. Build Barracks (10s), train rifle soldiers, scout and defend ore line.
4. Build War Factory (26s), queue tanks, optionally buy second Harvester.
5. Independently produce a Gun Defense while a building is in progress.
6. Expand to contested ore; protect harvesters; attack opponent's infrastructure.
7. Destroy opponent's significant structures or lose your own; result screen and restart.

**Early balance targets for playtesting:** first harvester working within 60–90 seconds; first combat vehicle fielded within 3–4 minutes; first meaningful raid before 5 minutes; default match length 15–25 minutes if both armies are similarly skilled. These benchmarks are not implementation claims.

### QA cases that must be automated or manually reproduced

1. Buildings and Defenses advance in parallel; extra Yards speed both **without** granting unbounded lanes.
2. One War Factory produces one tank at a time; two factories reduce build time but do not generate two identical tanks simultaneously.
3. Ore unloading pays exactly once and the free first Harvester is never duplicated by save/load, placement cancel or building sell.
4. Construction pauses at zero credits and resumes on ore delivery; cancellation refunds actual invested credits.
5. Placement is green near eligible base structure and red when blocked/outside adjacency; wall/turret chaining alone cannot extend the base.
6. Radar disappears or is disrupted on brownout without resetting explored fog.
7. Packed MCV pauses base construction; deploying it restores queues and offers a fresh placement anchor.
8. Unit queues survive changing tabs, factory destruction (paused or refunded according to policy) and pause/restart.
9. Engineers capture eligible neutral sites; enemy building capture obeys interruption and tech restrictions.
10. Standard short-game defeat and optional annihilation mode resolve cleanly without chasing hidden decorations.
11. AI obeys the same credit, tech and production constraints as humans.
12. Unit selection, build placement and command issuing remain comfortable by mouse/keyboard and touch.

## 10. Revision ledger: parent GDD proposals changed

| Parent GDD v0.1 | This RA2-first proposal |
|---|---|
| One building slot **per Construction Yard** | **One shared Buildings lane + one shared Defense lane**, extra Yards grant category speed bonus |
| Each barracks/war factory has an independent queue | **One shared queue per unit production domain** and multiple-factory speed bonus |
| HQ or all MCVs destroyed = standard defeat | **RA2-style Short Game:** all significant buildings and MCVs lost |
| Buildings conceptually "constructing" after placement | **Prebuilt in sidebar**, become operational upon placement; visual assembly only |
| Costs may be spent upfront/reserved for queues | **Gradual withdrawal as progress occurs**, pause if broke |
| Placement around a Yard radius alone | **Build adjacency via eligible buildings**, with outposts as optional explicit anchors |
| First refinery harvester not specified | **First harvester bundled** with refinery placement |
| Hard supply-cap undecided | **Explicit default: no hard population cap** |
| Infinite late-game funds risk from passive structures | **Capturable neutral income is primary**; slow capped reclamation is safety net |

## 11. Decisions to review before implementation

The five previously agreed foundations stay fixed. The following are **strong recommendations rather than newly user-approved final rules**:

- Whether to use exact RA2-like **four-tab sidebar** and **dual Buildings/Defense lanes** (recommended YES).
- Whether construction and troop costs **drain during production** rather than on order (recommended YES).
- Whether extra factories **speed up one shared queue** rather than provide independent queues (recommended YES).
- Whether default victory is **Short Game** rather than HQ destruction (recommended YES).
- Whether starting skirmish begins with a **mobile MCV** or a predeployed HQ (recommended MCV for normal skirmish; predeployed optional in campaigns).
- Whether late-game income is mostly capturable map facilities instead of passive base income (recommended YES).
- Keep **top-down + 2.5D** view, despite RA2's original isometric view; matching mechanics takes priority over exact projection (previously approved).

## Reference links

- [Red Alert 2 original manual transcription — production, economy, power, repairing and unit behavior](https://manualzz.com/doc/24314810/westwood-studios-red-alert-2-user-manual)
- [Red Alert 2 manual — skirmish setup and Short Game toggle](https://www.manualshelf.com/manual/games-pc/command-conquer-red-alert-2/user-guide-english/page-17.html)
- [Red Alert 2 original manual — production tabs](https://www.manualshelf.com/manual/games-pc/command-conquer-red-alert-2/user-guide-english/page-22.html)
- [Red Alert 2 multi-factory production behavior, ModEnc](https://modenc.renegadeprojects.com/MultipleFactory)
- [Red Alert 2 Short Game, ModEnc](https://modenc.renegadeprojects.com/ShortGame)
- [WebRTS three-faction building catalog](https://github.com/AlmightyTank/WebRTS/blob/main/docs/FACTION-BUILDING-ROSTER-1.0.md)
- [Current WebRTS isometric roadmap (to be superseded after sign-off)](https://github.com/AlmightyTank/WebRTS/blob/main/docs/ROADMAP-GODOT-ISOMETRIC-1.0.md)
