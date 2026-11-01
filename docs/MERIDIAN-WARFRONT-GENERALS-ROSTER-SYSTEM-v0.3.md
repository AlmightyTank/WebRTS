# Meridian Warfront — Zero Hour-Style Generals and Army Variants

**Design revision:** v0.3 · **Status:** Proposal for review · **Date:** 2026-10-31  
**Companion designs:** `MERIDIAN-WARFRONT-MASTER-GDD-v0.1.md` and `MERIDIAN-WARFRONT-RA2-CONSTRUCTION-TECH-TREES-v0.2.md`  
**Proposed repository file:** `docs/MERIDIAN-WARFRONT-GENERALS-ROSTER-SYSTEM.md`  
**Reference:** Command & Conquer: Generals – Zero Hour, especially its faction-specific army variants and five-rank General Powers system.

> **Design intent:** Keep Red Alert 2 as the blueprint for construction, sidebar controls, MCV deployment, ore economy, and fast match pacing. **Use Zero Hour as the blueprint for selectable generals, exclusive replacement units and structures, restricted units, unique upgrades, altered starting veterancy, and in-match General Powers.** Keep the names, setting, geometry, balance, and fiction original to Meridian Warfront. This document does not mean any functionality is already implemented.

## 1. The rule: a general changes the actual army

Each of three factions has a **standard army** and **three specialized general variants**. The standard faction provides a flexible, balanced roster, while a general produces a more distinctive army with genuine strengths and significant tradeoffs. This creates **12 selectable army configurations** built from **three common economic and construction foundations**, not twelve entirely separate implementations.

General changes can include:

1. **Replace:** one available unit/building is swapped for a different, exclusive unit/building in the *same production slot*. The original is not buildable by that general.
2. **Disable:** remove a unit, research item or command power completely. Its production icon is absent or explicitly locked with a reason; it must not remain misleadingly buildable.
3. **Add:** add an exclusive specialist unit, defense, upgrade, or ability in an appropriate production category.
4. **Modify:** change specific prices, training experience, movement profiles, power draw, sensors or abilities, showing the change in the UI. Numerical changes must support identity, not replace it.
5. **Prerequisite override:** some unique units unlock earlier/later, or replace an ordinary requirement. No faction loses access to essential economy, engineering, basic anti-infantry, anti-armor and anti-air responses.
6. **Promotions:** gain General Points as combat experience increases and buy unique tactical powers. This is separate from general choice: replacements exist from match start and become trainable when their building prerequisites are met.

**Explicit example:** A Directed Energy player opens their War Factory. The normal `Sentinel MBT` slot reads `Arc Lance Tank`. The normal Sentinel is absent; the player cannot order both. The alternative tank has a beam weapon and needs a working base power network to fire at full effectiveness, while standard Javelin missile infantry remain available as a non-energy fallback. That is a mechanical replacement, not a paint job.

### Scope of the variants

Every specialist should have **1–3 meaningful unit replacements**, **0–2 changed structures/defenses**, **1–3 unavailable units or upgrades**, **1–3 distinct research choices**, **2–4 notable command powers**, and a clearly explained shortcoming. Some generals may rely more heavily on prohibited units rather than additional units; these numbers are design targets, not quotas. Do not create redundant models/artwork: procedural 2D unit geometry can compose reusable tracks, turrets, guns, antennas, and decals into distinct silhouettes.

## 2. Standard faction rosters — baseline for comparisons

These are *working names*, not approved final unit statistics. All three retain the shared 19-building-role foundation, including HQ, power, refinery, barracks, ground factory, radar, service, air, advanced tech, defenses, specialty utility, superweapon, and conditional naval role. No standard faction should need to research its own common basic rifleman or mainline tank via a General Point.

**Standard Alliance:** Ranger, Javelin Missile Team, Field Engineer, Lynx IFV, Sentinel MBT, Specter Scout Drone, Sentinel AA Vehicle, Precision Howitzer, Arc Beam Tank (T2), Striker Gunship, Vortex Fighter (T2), Ore Harvester, MCV; Sentry Turret, SAM Launcher, Gauss Turret; Particle Beam Array. Flexible precision and air capability, relatively expensive equipment.

**Standard Republic:** Line Infantry, Tank Hunter, Combat Engineer, Ironclad APC, Bastion MBT, Recon APC, Flak Carrier, Thunderbolt Artillery, Mammoth Siege Tank (T2), Siege Helicopter, Heavy Bomber (T2), Industrial Hauler, MCV; Machine-Gun Bunker, Flak Battery, Heavy Anti-Tank Emplacement; Ironstorm Artillery Array. Strong conventional defenses and armor, slower response.

**Standard GIA:** Militia Fighter, Rocket Cell, Salvage Technician, Raider Technical, Scavenger Tank, Raider Bike, Rocket Truck, Rocket Buggy, Reclaimed Assault Tank (T2), Improvised Attack Helicopter, Missile Drone Wing (T2), Salvage Collector, MCV; Gun Nest, Salvaged AA Platform, Recoilless Cannon Nest; Ballistic Missile Silo. Economical mobility, tunnels and scavenging, weaker direct durability.

The base rosters are balance starting points. A general's replaced unit is removed **only for that general**, not from the standard faction.

## 3. Alliance — advanced technology, precision, air control

### A1. Air Superiority General — *Sky Command*
**Fantasy:** The battlefield belongs to aircraft. Defend airfields, scout quickly, win through strike timing and surgical raids; ground forces support aircraft rather than replace them.

- **Unit swap 1:** `Vortex Fighter` → `Vortex Ace Interceptor`. More robust against missile interception and aircraft; more expensive to lose. Occupies the same fighter production slot.
- **Unit swap 2:** `Striker Gunship` → `Tempest Assault VTOL`. A specialized gunship with stronger anti-vehicle strikes but vulnerable during rearm/cooldowns.
- **Unit swap 3:** `Lynx IFV` → `Lynx Missile Escort`. Ground-based anti-armor/anti-air escort, deliberately weaker against sustained tank duels.
- **Unavailable:** `Sentinel MBT` and `Arc Beam Tank`. This is a significant permanent concession, comparable to Zero Hour's Air Force General losing mainline tanks.
- **Structure/upgrade changes:** Airfield receives a `Reinforced Hangars` upgrade; `Advanced Countermeasures` researched at Radar/Airfield. Airfields remain vulnerable to base rushes and power disruption.
- **Command powers:** Rank 1 `Recon Overflight` (reveals a path); Rank 3 `Interdiction Flight` (targeted aircraft strike); Rank 5 `Sky Supremacy` (large but telegraphed aircraft formation strike). Multiple ranks improve scale or reliability.
- **Counterplay:** Invest in AA and attack exposed airfields/rearm sites. Cheaper rocket infantry and ground AA prevent an unwinnable tankless opening.
- **Power balance:** Standard Particle Beam Array remains available at ordinary faction costs; this general is not also the best superweapon player.

### A2. Directed Energy General — *Lattice Command*
**Fantasy:** Precise beam weapons and elite electronic defenses, at the price of power dependence and some lost conventional artillery.

- **Unit swap 1:** `Sentinel MBT` → `Arc Lance Tank`. Beam tank with excellent accurate damage but weak against dispersed missile infantry and expensive power demands.
- **Unit swap 2:** `Sentinel AA Vehicle` → `Lattice Interceptor`. Strong electronic point defense against projectiles; less conventional anti-air burst damage.
- **Building swap:** `Sentry Turret` → `Beam Bastion`, power-hungry precision defense instead of cheap ballistic turret.
- **Unavailable:** `Precision Howitzer` and the ordinary ballistic `Sentinel MBT`. The T2 `Arc Beam Tank` remains as an advanced specialist but is not simply an unconditional stronger copy of Arc Lance.
- **Upgrades:** `Beam Capacitors` (better sustained damage), `Grid Stabilizers` (reduced low-power penalty); both have significant cost/power tradeoffs.
- **Command powers:** Rank 1 `Grid Surge` (temporary friendly energy fire-rate boost with visible heat); Rank 3 `Target Lattice` (reveals/marks a single area); Rank 5 `Orbital Pulse` (short, signaled precision energy strike). The permanent Particle Beam superweapon remains a separately constructed building.
- **Counterplay:** Raid power facilities, pressure with numerous cheap units, use smoke/disruption and long-range ordnance. At low power the energy weapons slow or cease firing, but the army still moves and retains ordinary infantry alternatives.

### A3. Special Operations General — *Ghost Command*
**Fantasy:** Reconnaissance, elite infantry, intelligence denial and fast precision attacks instead of superior armored formations.

- **Unit swap 1:** `Ranger` → `Pathfinder Team`. Better reconnaissance/camouflage and precision engagements, weaker against armored pushes.
- **Unit swap 2:** `Lynx IFV` → `Ghost Recon Carrier`. Concealed when stationary and not firing, carries infantry; weaker direct DPS.
- **Unit swap 3:** `Specter Scout Drone` → `Phantom Sensor Drone`. Longer-duration spotting with weaker survivability.
- **Unavailable:** `Arc Beam Tank` and the strongest conventional heavy artillery upgrade. `Sentinel MBT` remains for basic armored counterplay.
- **Upgrade changes:** `Silent Running` for eligible vehicles and `Coordinated Designation` for infantry/drone synergy; stealth always breaks under clear detection/certain actions.
- **Command powers:** Rank 1 `Signal Sweep`; Rank 3 `Covert Insertion` of a modest elite infantry team at a legal revealed location; Rank 5 `Electronic Blackout` temporarily disrupts a marked enemy radar/defense area (not a total map-wide power shutdown).
- **Counterplay:** Radar, scouting, detector escorts and area suppression. Elite infantry is expensive and vulnerable when revealed.

## 4. Republic — conventional power, heavy armor, fortifications

### R1. Heavy Armor General — *Steel Vanguard*
**Fantasy:** Tank-led breakthrough armies that sacrifice artillery variety and aircraft efficiency for armored dominance.

- **Unit swap 1:** `Bastion MBT` → `Juggernaut Battle Tank`. More armor and anti-vehicle output, lower speed and higher cost.
- **Unit swap 2:** `Mammoth Siege Tank` → `Imperator Heavy Tank`. A major T2 superheavy with a distinctive multi-gun geometry and costly upkeep/recovery. Takes the Mammoth production slot.
- **Unit swap 3:** `Recon APC` → `Armored Scout Carrier`. Better durability, worse concealment/speed.
- **Unavailable:** `Thunderbolt Artillery` and its specialized artillery upgrades. Aircraft are more expensive; the army must cross the map instead of relying on easy ranged bombardment.
- **Upgrades:** `Autoloaders` for mainline tanks; `Veteran Crews` gives produced armor initial experience rather than making every tank overpowered at base price.
- **Command powers:** Rank 1 `Field Repairs`; Rank 3 `Armor Reserve` (small timed reinforcements); Rank 5 `Breakthrough Order` (temporary, localized armored momentum and suppression resistance).
- **Counterplay:** Rocket infantry, terrain chokepoints, aircraft and flanking attacks; expensive tanks create risk from lost harvesters.

### R2. Artillery Command General — *Longbow Command*
**Fantasy:** Recon-driven long-range fire and fortified gunlines that struggle in close brawls.

- **Unit swap 1:** `Thunderbolt Artillery` → `Stormrail Howitzer`. Longer range and deploy/bracing delay; vulnerable to mobile attacks and detection denial.
- **Unit swap 2:** `Bastion MBT` → `Escort Battle Tank`. Cheaper and faster, weaker in a direct heavy-tank clash.
- **Building swap:** `Heavy Anti-Tank Emplacement` → `Counterbattery Station`, a long-range static defense with minimum effective range.
- **Unavailable:** `Mammoth Siege Tank` and the strongest close-range tank armor package.
- **Upgrades:** `Forward Observers` link spotters to artillery accuracy; `Rapid Fire Mission` shortens salvo preparation at a credit cost.
- **Command powers:** Rank 1 `Spotter Recon`; Rank 3 `Rolling Barrage` (warning marker); Rank 5 `Fire Mission Omega` (larger area denial, destructible spotter assistance).
- **Counterplay:** Close-range rushes, attack observers and exploit long reloads. Outranging a base should require risk, visibility and setup time.
- **Superweapon:** Ironstorm remains the faction strategic superweapon, not a free rank ability; this general may eventually research reduced dispersion instead of raw damage.

### R3. Fortress Defense General — *Bastion Command*
**Fantasy:** A slowly advancing military fortress. Better bunkers, defensive infantry and armored transports, but weak map-wide response.

- **Unit swap 1:** `Line Infantry` → `Garrison Guard`. Particularly effective while in cover or a friendly bunker, less mobile when attacking.
- **Unit swap 2:** `Ironclad APC` → `Siege Carrier`. Heavier armored personnel transport that can deploy as a temporary bunker, cannot move while deployed.
- **Building swap 1:** `Machine-Gun Bunker` → `Steel Pillbox`; stronger protection, slower construction.
- **Building swap 2:** `Fortified Outpost` → `Forward Bastion`; provides expansion and a defensible staging location at greater cost.
- **Unavailable:** `Recon APC` high-speed scouting variant and `Heavy Bomber`. Other aircraft remain but are not the central strength.
- **Upgrades:** `Reinforced Fortifications`, `Mobile Field Works` for temporary forward defenses.
- **Command powers:** Rank 1 `Emergency Fortification`; Rank 3 `Reserve Garrison` (defensive troop arrival at owned building); Rank 5 `Hold the Line` (temporary area-wide fortification/repair effect centered on a friendly structure).
- **Counterplay:** Artillery, multiple fronts, harvester raids and denying forward expansion. Cannot generate unstoppable income merely by turtling.
- **Offensive route:** Sieged carriers and forward bastions allow deliberate **advancing** front lines; it must not be a general that can only wait for attacks.

## 5. GIA — mobile improvised warfare, ambush and salvage

### G1. Guerrilla Warfare General — *Shadow Front*
**Fantasy:** Ambush and deception; sacrifice tanks for stealth, raid timing and map intelligence.

- **Unit swap 1:** `Militia Fighter` → `Shade Cell`. Concealed when stationary/in cover; lower durability than conventional infantry.
- **Unit swap 2:** `Raider Technical` → `Ghost Technical`. Recon/ambush transport with reduced direct firepower.
- **Building swap:** `Gun Nest` → `Concealed Gun Nest`, weaker sustained defense but hidden until detected/firing.
- **Unavailable:** `Scavenger Tank` and `Reclaimed Assault Tank`. Mobile rocket infantry and rocket buggies remain to counter armor; a vehicle-heavy enemy is a serious problem.
- **Upgrades:** `Camo Netting` on eligible facilities, `Safe Passage` for tunnel-network units; active shooting, close detection and sustained movement can expose units.
- **Command powers:** Rank 1 `False Signals`; Rank 3 `Ambush Cell` (limited temporary infiltration); Rank 5 `Hidden Passage` (telegraphed temporary tunnel entrance on revealed legal terrain).
- **Counterplay:** Radar detectors, recon infantry, area weapons and controlling exposed tunnel exits.

### G2. Missile Warfare General — *Saturation Command*
**Fantasy:** Mobile rocket salvos, ranged pressure and high-risk strike batteries rather than covert hit-and-run play.

- **Unit swap 1:** `Rocket Cell` → `Siege Rocket Squad`. Slower redeploy, more potent against emplacements and heavy vehicles.
- **Unit swap 2:** `Rocket Buggy` → `Volley Launcher`. Fires clustered short salvos; vulnerable between volleys and to fast attack vehicles.
- **Building swap:** `Salvaged AA Platform` → `Missile Defense Nest`, better missile coverage but worse against light infantry.
- **Unavailable:** `Shadow Operative` and stealth/camouflage research line; vehicles cannot rely on undetectable ambush tactics.
- **Upgrades:** `Guidance Van` targeting upgrade, `Rapid Reload` for specialized missile units, at meaningful credit cost.
- **Command powers:** Rank 1 `Rocket Recon Beacon`; Rank 3 `Harassing Salvo`; Rank 5 `Saturation Strike` (obvious warning zone and delayed rockets).
- **Superweapon interaction:** Existing `Ballistic Missile Silo` keeps the same strategic role; exclusive upgrade converts its payload into a wider, lower-single-target-damage saturation pattern. This is a **variant**, not a second free superweapon.
- **Counterplay:** Fast ground troops, point-defense technology, dispersed formations and attacks during reload cycles.

### G3. Salvage & Mobility General — *Wreckrunner Command*
**Fantasy:** Cheap, fast improvised vehicles evolve by scavenging the battlefield. Risk-reward raiding and wreck control instead of static firepower.

- **Unit swap 1:** `Raider Technical` → `Ripper Technical`. Faster light raider with greater salvage capacity and reduced armor.
- **Unit swap 2:** `Scavenger Tank` → `Junker Assault Tank`. Starts weaker than the standard tank but has two visually clear wreck-derived weapon/armor modification tiers, limited and capped.
- **Unit swap 3:** `Raider Bike` → `Scrap Runner`. Fast battlefield collection/recon vehicle with weak armament.
- **Building swap:** `Field Workshop` → `Mobile Salvage Yard`, capable of repairs and limited wreck conversion but more vulnerable to assault.
- **Unavailable:** `Missile Drone Wing` and the strongest static heavy-defense upgrade. The general must win by maneuver, not total map denial.
- **Upgrades:** `Recovery Crews`, `Field Improvisation`. Salvaging **never** mints more credits than the value of a destroyed target or repeatedly farms the same wreck; friendly self-destruction provides no gain.
- **Command powers:** Rank 1 `Rapid Salvage`; Rank 3 `Roadside Reinforcements` (small mobile unit delivery near valid friendly road/outpost); Rank 5 `Scavenger Convoy` (temporary group of light vehicles with a visible entry point).
- **Counterplay:** Deny wreck access, employ anti-light armor, defend ore routes, and force costly head-on battles.

## 6. Generals Points: Zero Hour-style five-rank progression

### Permanent decision versus in-match progression

- **Before the match:** choose `Standard` or one named general under the faction. This resolves the entire valid roster, starting traits, tech substitutions and available promotion tree. Selection is locked once a standard skirmish starts.
- **During the match:** combat earns **command XP** separately from each individual unit's veterancy. Destroying enemies, capturing objectives and fulfilling mission targets can grant XP; avoid idle-farming exploits.
- **Five ranks:** begin at Rank 1 with 1 General Point; ascending to Ranks 2, 3 and 4 grants 1 each; reaching Rank 5 grants 3. **Seven total points** available per match (Zero Hour-style benchmark; exact XP thresholds to tune).
- **Rank gates:** early scouting/training unlocks at Rank 1; stronger support powers generally at Rank 3; most decisive area support at Rank 5. Some powers can be upgraded across up to three levels, consuming points each time.
- **Choices matter:** a player cannot purchase every available power in one match; rank is not a universal unlock-all button. Some powers unlock optional elite unit slots; **the general's signature replacement units remain available through their ordinary factory/tech prerequisites**, not locked away solely behind General Points.
- **Retain RA2 superweapon distinction:** The faction's strategic superweapon is a constructed, expensive building with its own cooldown and warnings. A Rank 5 support strike must not be equally destructive or eliminate the need to build that structure.
- **No persistent combat grind:** rank, General Points, powers and unit veterancy reset in standard competitive/skirmish matches. Campaign missions can supply scripted starting ranks.

### Example of player-facing power purchase

A Rank 3 Air Superiority player might have to choose between upgrading `Recon Overflight` for greater vision, purchasing `Interdiction Flight` for a limited strike, or improving `Emergency Repair` for better ground escorts. The chosen nodes appear as callable abilities in a separate command power tray, not among ordinary unit construction icons.

### General versus unit veterancy

- **General Rank:** player-wide XP/points; unlocks support actions and selected doctrine-level perks.
- **Unit Veterancy:** individual squad/vehicle combat experience; improves that unit. Some generals can grant *their own class* of new units starting veteran, as in Zero Hour, but this must be a visible, balanced property.
- Never confuse a "Rank 3 General" with a "Veteran Tank": the systems must have separate UIs, data and test coverage.

## 7. Economy and construction stays RA2-first

All 12 configurations share the same fundamental **MCV → Construction Yard**, **four construction tabs** (Buildings, Defense, Infantry, Vehicles), **two shared structural lanes**, gradual credit spending, **first harvester bundled with a refinery**, finite iron ore, low-power consequences, placement and adjacency, sell/repair, and Short Game/Annihilation setting.

A general may change a *particular* factory's prices, speed, or what it produces; generals may not silently replace the core RA2 building mechanism with Generals-style independent bulldozer building. Optional engineers remain scouts/repair/capture units without becoming mandatory construction workers.

Research and prerequisite contracts are **inherited by replacement unit slots** unless the general explicitly overrides them. Example: `Arc Lance Tank` inherits `Sentinel MBT`'s War Factory prerequisite; `Imperator Heavy Tank` inherits `Mammoth Siege Tank`'s T2 requirement. Replacing a unit must not accidentally bypass the intended tech tier.

## 8. Production sidebar & player readability

**Pre-match general selection** displays faction icon, doctrine, two signature swaps with before/after silhouettes, unavailable units, special structures, exclusive upgrades and a one-sentence weakness. Include `Compare with Standard Faction`.

**During match:** The production sidebar shows only available replacements; standard units removed by the variant do not appear as duplicates. Hover/long-press an exclusive item to view `REPLACES: Sentinel MBT` and `UNAVAILABLE TO: Standard Alliance`. Removed tech can appear in a faction dossier but not as a tappable unbuildable choice.

**Enemy readability:** Recognizable silhouettes and faction badges make the general identifiable without requiring the opponent to read a player name. Fog of war still hides unscouted units. On encounter, a short tooltip can say `Air Superiority: heavy MBTs unavailable; stronger aircraft`.

**No sprite burden:** Procedural shapes share components; new silhouette templates (fighter wings, gun barrels, tracks, roof armor, radar dishes, chassis geometry) can encode variation. A unique general should affect weapon and physical role, not only paint a unit a different color.

## 9. Data contract for implementations (not executable code)

```yaml
faction: alliance
general_id: directed_energy
inherits: alliance_standard
replacements:
  sentinel_mbt: arc_lance_tank
  sentinel_aa_vehicle: lattice_interceptor
  sentry_turret: beam_bastion
disabled:
  - precision_howitzer
added_upgrades:
  - beam_capacitors
  - grid_stabilizers
modifiers:
  energy_weapons_require_power: true
  energy_power_shortage_behavior: reduced_fire_or_shutdown
powers:
  rank_1: [grid_surge, early_radar_sweep]
  rank_3: [target_lattice, emergency_repair]
  rank_5: [orbital_pulse]
```

**Resolve once:** `effective_roster = base faction roster - replaced base entries - disabled entries + replacement targets + added entries`. Apply explicit numerical modifiers on top; do not mutate the base catalog when loading one variant. The effective production menu, tech graph, AI, campaign loadout, UI icons, save/load, and balance tests must all consume that same resolved data.

**Validation at load time:** Confirm every replaced source belongs to the base roster, every replacement target exists exactly once, no unit is both disabled and reintroduced, no recursive substitutions, prerequisites are satisfiable, early infantry/armor/AA counters remain possible, and the first-minute economy is playable. Log violations and fail tests rather than silently falling back to standard units.

## 10. Balance design rules

1. A specialist must feel **better at its specialty and meaningfully worse somewhere else**. Visible, permanent weaknesses beat unexplained penalties.
2. Everyone must have basic anti-infantry, anti-vehicle and anti-air counters available by the time the corresponding threats arrive.
3. Each general should have an early-game identity by the first Barracks or War Factory, a distinctive T2 response, and at least one late-game payoff.
4. If one army loses a mainline tank, it needs adequate *alternative* tank counters — not a disguised better main battle tank.
5. Stealth requires detection counters; artillery needs scouting and minimum-range exposure; air power needs rearm/AA vulnerabilities; heavy armor needs speed and economy costs; salvage must not be credit-infinite; directed energy must be power-disruptible.
6. Keep the faction's signature constructed superweapon recognizable across all its generals; allow targeted changes to cost/payload/upgrades as exceptions.
7. Avoid twelve independent unit-balance silos: reuse base unit classes and test specialized matchups against the standard faction first, then among all nine variants.
8. Do not hide unavailable units behind obscure tech paths. General selection must honestly reveal restrictions before the match.
9. Every variant's doctrine must be observable in AI behavior, not solely in player-controlled matches.
10. Do not copy copyrighted character names, dialogue, silhouettes, 3D models, art, or assets from Zero Hour. These are original factions and mechanics.

## 11. Development order and acceptance tests

**A. Framework:** resolve base faction + general substitution/disabled/added definitions to one canonical unit, building and upgrade catalog. Validate all data. Add the pre-match army comparison screen.

**B. First full variant proof:** build **Standard Alliance** and **Alliance Directed Energy** in the same small skirmish. Verify `Sentinel MBT → Arc Lance Tank`, `Sentry Turret → Beam Bastion`, no Precision Howitzer, grid-power failure, functional conventional counters, production queue UI and AI use. This proves the architecture without creating nine separate rosters before one works.

**C. Complete faction foundations:** standard Alliance, Republic and GIA with a winning/losing AI skirmish. Preserve RA2 economics and construction tests throughout.

**D. Nine variant passes:** for each general, implement minimum one concrete unit replacement, one weakness, one unique upgrade and one callable General Power. Build out remaining swaps/powers in subsequent balance slices.

**E. Five-rank command tree:** confirm 1/3/5-star gates, seven total points, multiple upgrade ranks, cooldown saves, power UI, mission starting ranks and non-exploitable XP.

**F. Balance:** standard vs specialist, specialists within faction, specialists cross-faction, and strategic counters. Measure opening production, harassment, anti-air availability, heavy armor cost and 15–25-minute standard skirmish target.

### Test matrix

- [ ] Each of 9 generals replaces at least one appropriate **slot**, and the removed original is absent from the production UI and underlying build permission.
- [ ] Disabled units cannot be built by script, AI, enemy capture abuse or saved production queues.
- [ ] Shared costs, build lanes, refinery harvester and construction anchors behave identically unless a documented general override explicitly says otherwise.
- [ ] A replaced unit inherits the correct tech and production domain, unless an explicit variant override changes them.
- [ ] A general with no conventional MBT can still defeat enemy light armor without needing a general point or unbuildable structure.
- [ ] Power failure impacts energy-specialist weapons clearly; other factions and ordinary missiles are not unintentionally disabled.
- [ ] Rank choices, prerequisites, upgrade ranks, cooldowns, save/load and pause states remain valid across selection, defeat and replay.
- [ ] AI obeys every restriction and responds to the chosen general's doctrine; it never cheats by spawning disabled units.
- [ ] Mobile long-press, comparison, unit swap labels and power selection are readable and operable.
- [ ] Variant silhouettes remain recognizable at low zoom and on Android.

## 12. Design issues to settle after this proposal

- Whether the **standard** army is selectable in skirmish (strong recommendation: yes, matching Zero Hour; 12 configurations total).
- Naming/identities of the nine individual commanders (role names are placeholders; we should write distinct personalities and dialogue only after army mechanics are sound).
- Whether a specialist may replace one faction's already-unusual superweapon payload, and how strongly that should vary across generals (recommend small targeted differences rather than nine unrelated superweapons).
- Unit prices, health, build durations, power draw, General XP thresholds, ability cooldowns and exact hero-unit roles remain unapproved numerical balance tasks.
- Which generals are available in the **first skirmish milestone**: recommend only Standard Alliance and one Directed Energy variant for architecture validation, then the standard Republic opponent, before the nine-general content expansion.

## Reference material

- [C&C Labs — Zero Hour USA generals](https://www.cnclabs.com/generals/zerohour/factions/usa/generals.aspx)
- [C&C Labs — Zero Hour China generals](https://www.cnclabs.com/generals/zerohour/factions/china/generals.aspx)
- [C&C Labs — Zero Hour GLA generals](https://www.cnclabs.com/generals/zerohour/factions/gla/generals.aspx)
- [StrategyWiki — Zero Hour Laser General](https://strategywiki.org/wiki/Command_%26_Conquer:_Generals_-_Zero_Hour/Laser)
- [StrategyWiki — Zero Hour Tank General](https://strategywiki.org/wiki/Command_%26_Conquer:_Generals_-_Zero_Hour/Tank)
- [StrategyWiki — Zero Hour Stealth General](https://strategywiki.org/wiki/Command_%26_Conquer:_Generals_-_Zero_Hour/Stealth)
