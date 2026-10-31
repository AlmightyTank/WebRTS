# Meridian Warfront — Three-Faction Building Roster (1.0 Design Draft)

**Branch:** `2d-isometric`  
**Status:** Design proposal (not an implementation or completed roadmap slice)  
**Scope:** Alliance, Republic, and Global Insurgency Alliance (GIA). This three-faction decision supersedes the roadmap's older two-faction assumption, which still needs an explicit scheduling update.

## Design pillars

- **Alliance:** clean modular blue-gray architecture, advanced electronics, mobile precision and air superiority. Signature superweapon: **Particle Beam Array**, a steerable blue-white energy beam.
- **Republic:** imposing, militaristic fortified construction, armor plating, heavy industry and superior tanks/artillery. Signature superweapon: **Ironstorm Artillery Array**, long-range conventional area bombardment. Do not make its buildings Alliance shapes painted red.
- **GIA (Global Insurgency Alliance):** improvised modular bases, scavenged metal, green/tan canvas and rusty machinery; guerrilla mobility and inexpensive units. Signature superweapon: **Ballistic Missile Silo**, a high-impact long-range strike with a fictional temporary hazardous zone.

**Economy:** all factions harvest finite iron ore and require power and logistics/supply. Their refineries, factories and generators work differently in balance, but use shared fundamental rules for multiplayer clarity. Supply capacity and power are existing prototype concepts; economy numbers are not locked.

## Full planned building roster

Each faction receives the same **19 strategic roles**, but with different visual models and selected mechanical variations. Tiers are proposed unlock progression: **T0** starting infrastructure, **T1** early combat/expansion, **T2** advanced infrastructure, **T3** late-game superweapon. Naval structures exist only on water maps and do not block ordinary land skirmishes.

| # | Function | Tier | Alliance | Republic | GIA |
|---|---|---|---|---|---|
| 01 | Starting HQ / build authority | T0 | Command Center | High Command Citadel | Resistance Headquarters |
| 02 | Produce power | T0 | Fusion Plant | Thermal Power Station | Diesel Generator Yard |
| 03 | Receive iron ore from harvesters | T0 | Ore Refinery | Industrial Ore Works | Scrapyard Refinery |
| 04 | Increase logistics/supply capacity | T0 | Supply Depot | Quartermaster Depot | Hidden Stockpile |
| 05 | Train infantry | T0 | Barracks | Garrison Barracks | Militia Camp |
| 06 | Produce ground vehicles | T1 | War Factory | Armor Works | Salvage Garage |
| 07 | Radar and intel/advanced unlocks | T1 | Satellite Uplink | Command Radar | Signal Shack |
| 08 | Expand build radius | T1 | Forward Command Post | Fortified Outpost | Forward Hideout |
| 09 | Basic anti-infantry defense | T0 | Sentry Turret | Machine-Gun Bunker | Gun Nest |
| 10 | Anti-air defense | T1 | SAM Launcher | Flak Battery | Salvaged AA Platform |
| 11 | Repair damaged units | T1 | Service Hangar | Vehicle Maintenance Depot | Field Workshop |
| 12 | Unlock advanced technology | T2 | Advanced Tech Center | Military Research Center | Black Market Laboratory |
| 13 | Produce aircraft | T2 | Airfield | Strike Airbase | Hidden Airstrip |
| 14 | Anti-armor/static heavy defense | T2 | Gauss Turret | Heavy Anti-Tank Emplacement | Recoilless Cannon Nest |
| 15 | Perimeter barrier | T1 | Energy-Reinforced Barrier | Reinforced Concrete Wall | Scrap Barricade |
| 16 | Perimeter vehicle passage | T1 | Security Gate | Fortress Gate | Checkpoint Gate |
| 17 | Faction-specific utility | T2 | Drone Control Node | Heavy Foundry | Tunnel Network |
| 18 | Faction superweapon | T3 | Particle Beam Array | Ironstorm Artillery Array | Ballistic Missile Silo |
| 19 | Naval production on water maps | T2 | Naval Dock | Armored Shipyard | Riverboat Yard |

**Count:** 18 main roles plus 1 conditional naval role = **19 roles × 3 factions = 57 faction building designs**, before modular wall/gate variants, damage states and construction phases.

## What each branch unlocks

### Core opening (T0)
HQ allows standard construction; Fusion Plant/Thermal Station/Diesel Yard generate power; ore refinery receives harvesters; depot expands logistics; barracks trains soldiers; basic turret defends against early raids. Initial placement is restricted by build radius from HQ and outposts. Starting HQ may be spawned rather than purchased depending on the scenario.

### Expansion and field warfare (T1)
War Factory/Armor Works/Salvage Garage produce vehicles; radar provides battlefield sensors and tech prerequisites; outpost extends build radius; anti-air and repairs provide survivability; walls and gates support defensive layouts. **Republic walls and gates are substantially tougher**. **GIA walls are cheaper/faster but more fragile**.

### Advanced warfare (T2)
Tech Center gates upgraded hardware, elite units and advanced defenses. Airfields create aircraft, heavy defenses counter armor, and unique support shifts battlefield play:
- **Alliance Drone Control Node:** scouting drones, surveillance support and precision target marking.
- **Republic Heavy Foundry:** heavy tank production upgrades, armor and conventional firepower bonuses. Keeps advanced tank production tied to the Armor Works rather than requiring a second production queue.
- **GIA Tunnel Network:** paired tunnel entrances for moving eligible ground infantry and light vehicles across connected safe routes. Entrance is destructible; no free teleportation anywhere.

### Superweapons (T3)
- **Alliance Particle Beam Array:** single player-directed sustained beam, excellent precise/line damage, requires substantial power and exposes its aim; it cuts out if the power grid fails.
- **Republic Ironstorm Artillery Array:** multiple long-range high-explosive artillery volleys in a marked area, strong against fortified positions, telegraphed so moving units can escape.
- **GIA Ballistic Missile Silo:** one spectacular ballistic strike with area impact and temporary fictional contamination hazard. Long charge and visible launch warning; no real-world weapon technical detail.

**Common balance constraints:** tech prerequisite, one active superweapon structure per player by default, announced target warning, visible cooldown, and counterplay through scouting, power disruption or destroying the installation. No final damage/cooldown numbers until playtesting.

## Faction visual references

| Faction | Color/material | Structure silhouette | Construction personality |
|---|---|---|---|
| Alliance | Blue, charcoal, gray, cyan light | Neat modular chamfered volumes, glass and dish antennas | Clean prefabricated sections |
| Republic | Crimson insignia, dark iron, olive drab, concrete | Wide low bunkers, reinforced blast doors, gun towers, squared-off armor | Heavy cranes, girders and thick foundations |
| GIA | Green/tan, weathered steel, orange hazard lighting | Asymmetric tents, shipping containers, scrap towers and disguised entrances | Improvised scaffolding and modular scrap |

**Non-negotiable:** Republic and GIA buildings must have different geometry and silhouettes from the Alliance, not recolors.

## Initial production order (avoid requiring all 57 before gameplay)

**Wave A — playable base economy (7 roles per faction; 21 designs):** HQ, power, ore refinery, logistics depot, barracks, vehicle factory and basic turret. Existing legacy Phaser building definitions can inspire role behavior but are **not** Godot implementations.

**Wave B — RTS combined arms (6 additional roles per faction; 18 designs):** radar, outpost, AA defense, repair, tech center and airfield.

**Wave C — faction identity and late-game (5 additional roles per faction; 15 designs):** anti-armor defense, walls, gates, faction utility and superweapon.

**Wave D — water maps (1 additional role per faction; 3 designs):** naval facilities, only when navigable water and naval unit systems are working.

## Godot 2D sprite contract

- Grid: **128×64 2:1 diamond** terrain tiles; these are tile dimensions, **not building sprite dimensions**.
- Buildings: fixed isometric perspective, transparent PNG in a consistent atlas/source pipeline, with a **centered ground footprint anchor** and Y-sort based on the south/base point. Never bake an entire grass square into a building sprite.
- Footprints (initial art budget): basic defenses/walls 1×1; power, barracks, depots and repair 2×2; HQ, refinery, factory, tech and advanced support 3×3; superweapons 4×4; airfield/naval vary by map and may span 4×4 or more. Final footprint validation happens in v0.3.
- Each finalized building needs: intact sprite, damaged sprite, destroyed/rubble sprite, construction stage, build-menu icon, minimap icon and selection footprint. Modular walls need corner, straight, T-junction, intersection, gate/endpoint variants.
- A completed atlas reference sheet is **not** the same as separate import-ready images. Maintain individual PNGs and per-building metadata. Avoid deriving sprites by cropping text-labeled concept art.

## Gameplay and roadmap integration

- The `2d-isometric` roadmap currently states two factions in its vision and v0.6 exit condition. Change to **three factions** when re-scoping that milestone; this document records their planned structures, not actual implementation.
- Keep current v0.3 building construction foundation generic: faction ID, structure type, placement cells, sprite, owner, health, production and prerequisites.
- Capturing an enemy HQ may unlock its faction tech tree after explicit engineering/research requirements; balance must prevent instant access to every enemy superweapon.
- No final prices, health, construction duration, power output or superweapon damage are approved yet; establish numerical balance in v0.4–0.6 testing.
