# Meridian Warfront — Three Factions, Nine Generals

**Status:** Proposed content lock for review; not implemented or balance-tested.  
**Scope:** Three standard armies, each with three selectable generals (12 army choices).  
**Relationship:** Develops the doctrine roster in `MERIDIAN-WARFRONT-GENERALS-ROSTER-SYSTEM-v0.3.md`; keeps its replacement, tech inheritance, rank and counterplay rules. Names and numbers below are new proposals. This document supersedes older isometric art instructions for this content, not existing gameplay code.

## Shared art direction

Match `godot/scripts/ui/industrial_art.gd` and the current MCV, construction yard and power plant: chunky low-poly industrial forms, flat shaded polygon faces, bright roofs, darker visible walls, sparse panel seams, dark windows, mechanical joints and restrained hazard yellow. Keep the existing ground-plus-height projection and top-down 2D gameplay. No cast shadows, photoreal textures, baked terrain squares or new isometric camera.

- Reuse wheels, tracks, cabs, cranes, barrels and structural slabs; vary the overall geometry, not just paint.
- Alliance: chamfered modules, narrow turrets, paired electronics and precise cyan emitters; blue trim `#389fda`.
- Republic: broad tracks, thick concrete, squared turrets, exposed bracing and recessed blast doors; red trim `#d95c45`.
- GIA: asymmetric cabs, uneven armor plates, canvas roofs, containers and exposed machinery; olive trim `#919b81`, tan canvas and small rusty accents.
- Preserve shared steel `#687b83`, concrete `#a7ad9b`, hazard yellow `#efbc45` and dark mechanical recesses `#202e35`. Player ownership color is separate from faction geometry; an Alliance mirror match must remain readable.
- General signatures need a silhouette cue at normal gameplay zoom. Effects and color alone do not qualify. Use the same geometry for production icons and world art.
- Generals are commanders, not mandatory battlefield hero units. Portraits, if added later, use angular illustrated busts with the same restrained palette, not photographic faces.

## Faction foundations

| Faction | Battlefield identity | Signature infrastructure | Strategic weapon | Built-in weakness |
|---|---|---|---|---|
| Alliance | Precision, reconnaissance, flexible air/ground coordination | Drone Control Node: scouting and target designation | Particle Beam Array: sustained, telegraphed precision beam | Expensive losses; power infrastructure is a priority target |
| Republic | Durable armor, conventional artillery, deliberate territorial advance | Heavy Foundry: armor research, not a duplicate vehicle queue | Ironstorm Artillery Array: warned conventional bombardment | Slow rotation between fronts; vulnerable supply routes |
| Global Insurgency Alliance (GIA) | Cheap mobile pressure, ambush, salvage and route control | Tunnel Network: paired, destructible entrances for eligible units | Ballistic Missile Silo: warned impact and temporary fictional hazard | Fragile direct-combat formations; vulnerable tunnel exits |

All retain MCV deployment, finite ore, refinery/harvester economy, power, engineers, basic anti-infantry/armor/air coverage and the shared construction system. Faction identity does not mean free global buffs. The existing 19-role building proposal remains the long-term structure list; naval content is conditional on water-map systems.

## Alliance generals

### A1 — General Mara Voss · Sky Command

**Playstyle:** Aircraft-led precision raids supported by missile escorts.

- **Exclusive replacements:** Vortex Fighter → **Vortex Ace Interceptor**; Striker Gunship → **Tempest Assault VTOL**; Lynx IFV → **Lynx Missile Escort**.
- **Building:** Airfield → **Skybridge Airfield**, with split hangars and two raised service gantries; inherits airfield prerequisites and footprint constraints.
- **Starting doctrine bonus:** Aircraft rearm time −15%; aircraft purchase prices +10%. Rearm benefit requires a functioning airfield, not merely owning its wreck.
- **Research:** Reinforced Hangars; Advanced Countermeasures.
- **Unavailable:** Sentinel MBT and Arc Beam Tank. Retains missile infantry and ground AA.
- **Rank 1 / 3 / 5 powers:** Recon Overflight / Interdiction Flight / Sky Supremacy.
- **Art signatures:** Ace has swept forked wings; Tempest has twin lift nacelles and a narrow central body; escort has raised paired missile rails rather than the standard IFV turret.
- **Counterplay:** Layer AA, raid hangars and exploit rearm windows. Aircraft losses are expensive.

### A2 — General Imani Vale · Lattice Command

**Playstyle:** Accurate energy fire and projectile interception tied to a vulnerable power grid.

- **Exclusive replacements:** Sentinel MBT → **Arc Lance Tank**; Sentinel AA Vehicle → **Lattice Interceptor**; Sentry Turret → **Beam Bastion**.
- **Building identity:** Beam Bastion uses two capacitor shoulders around an open emitter cradle; recognizable even without its beam effect.
- **Starting doctrine bonus:** Signature energy weapons gain +10% sustained damage at adequate power; fire at 50% normal rate during shortage. All other low-power penalties still apply. Interceptor is a limited projectile-defense specialist, not universal immunity; ordinary missile infantry and SAM defense remain the reliable AA fallback.
- **Research:** Beam Capacitors; Grid Stabilizers. Neither removes power dependence completely.
- **Unavailable:** Precision Howitzer and the replaced ballistic tank/AA/turret slots.
- **Rank 1 / 3 / 5 powers:** Grid Surge / Target Lattice / Orbital Pulse.
- **Art signatures:** Arc Lance has a split-prong emitter instead of a barrel; interceptor has a four-panel sensor crown. Small cyan sockets convey energy hardware without flooding the silhouette with glow.
- **Counterplay:** Destroy generators, disperse infantry and use long-range conventional weapons.

### A3 — General Elias Rook · Ghost Command

**Playstyle:** Elite scouting, infantry insertion and coordinated precision attacks.

- **Exclusive replacements:** Ranger → **Pathfinder Team**; Lynx IFV → **Ghost Recon Carrier**; Specter Scout Drone → **Phantom Sensor Drone**.
- **Special building:** Drone Control Node → **Ghost Operations Node**, a low command block with folded antenna wings. Adds detection intelligence, not invisible map-wide vision.
- **Starting doctrine bonus:** Recon units gain +20% sight radius; elite replacement infantry cost +15%. Sight still obeys terrain and fog rules.
- **Research:** Silent Running; Coordinated Designation.
- **Unavailable:** Arc Beam Tank and the top conventional artillery upgrade. Keeps Sentinel MBT.
- **Rank 1 / 3 / 5 powers:** Signal Sweep / Covert Insertion / Electronic Blackout.
- **Art signatures:** Pathfinder has a compact angular cloak and long sensor rifle; carrier has a low wedge roof and folding mast; drone uses a thin diamond frame. Stealth is a state, not permanent transparency.
- **Counterplay:** Detector escorts, area suppression and pressure on expensive infantry.

## Republic generals

### R1 — Marshal Viktor Korda · Steel Vanguard

**Playstyle:** Costly armored breakthrough formations with limited ranged alternatives.

- **Exclusive replacements:** Bastion MBT → **Juggernaut Battle Tank**; Mammoth Siege Tank → **Imperator Heavy Tank**; Recon APC → **Armored Scout Carrier**.
- **Building:** Heavy Foundry → **Vanguard Foundry**, with broad crane arms and exposed track assembly racks; upgrades still apply to Armor Works production.
- **Starting doctrine bonus:** Mainline/superheavy tanks gain +10% hull health; aircraft cost +20%. Slower signature chassis remain slow.
- **Research:** Autoloaders; Veteran Crews (visible initial unit XP, independent of commander rank).
- **Unavailable:** Thunderbolt Artillery and its dedicated upgrades.
- **Rank 1 / 3 / 5 powers:** Field Repairs / Armor Reserve / Breakthrough Order.
- **Art signatures:** Juggernaut has deep side skirts and a broad squared turret; Imperator has separated double tracks and offset secondary guns, not merely a scaled-up MBT.
- **Counterplay:** Rocket infantry, flanking, aircraft and economy raids; tanks must physically reach targets.

### R2 — General Nadia Orlov · Longbow Command

**Playstyle:** Spotter-led artillery batteries with a vulnerable close-range screen.

- **Exclusive replacements:** Thunderbolt Artillery → **Stormrail Howitzer**; Bastion MBT → **Escort Battle Tank**; Heavy Anti-Tank Emplacement → **Counterbattery Station**.
- **Building identity:** Counterbattery Station has a rear-mounted gun, broad outriggers and a separate spotting dish; minimum range creates a visible defensive gap.
- **Starting doctrine bonus:** Braced artillery gains +15% range; signature artillery requires a two-second setup before firing after movement. No firing into unexplored terrain without the normal targeting rules.
- **Research:** Forward Observers; Rapid Fire Mission.
- **Unavailable:** Mammoth Siege Tank and the top close-range tank armor package.
- **Rank 1 / 3 / 5 powers:** Spotter Recon / Rolling Barrage / Fire Mission Omega.
- **Art signatures:** Stormrail uses one long conventional barrel, an open rear carriage and deployable feet—despite its name, it is not an energy railgun. Escort tank has a visibly smaller turret and lighter skirts.
- **Counterplay:** Kill spotters, rush minimum range and attack during setup or reload.

### R3 — General Petra Volkov · Bastion Command

**Playstyle:** Advancing fortified positions and protected infantry, not passive infinite-income turtling.

- **Exclusive replacements:** Line Infantry → **Garrison Guard**; Ironclad APC → **Siege Carrier**; Machine-Gun Bunker → **Steel Pillbox**; Fortified Outpost → **Forward Bastion**.
- **Starting doctrine bonus:** Defensive structures gain +15% hull health and take +15% construction time. No free build-radius expansion or instant frontline placement.
- **Research:** Reinforced Fortifications; Mobile Field Works.
- **Unavailable:** Recon APC and Heavy Bomber.
- **Rank 1 / 3 / 5 powers:** Emergency Fortification / Reserve Garrison / Hold the Line.
- **Art signatures:** Guard has a broad armored vest; carrier folds side plates into a stationary bunker stance; pillbox has a layered roof and recessed slit; Forward Bastion has four corner buttresses. Carrier cannot move while deployed.
- **Counterplay:** Artillery, simultaneous fronts, blocked expansions and harvester raids.

## GIA generals

### G1 — Commander Samira Nadir · Shadow Front

**Playstyle:** Concealed infantry and light-vehicle ambushes without a tank safety net.

- **Exclusive replacements:** Militia Fighter → **Shade Cell**; Raider Technical → **Ghost Technical**; Gun Nest → **Concealed Gun Nest**.
- **Starting doctrine bonus:** Eligible infantry conceal after three seconds stationary and not firing; signature light vehicles have −10% hull health. Detection and firing reveal concealed units; concealment never removes collision or targeting rules after reveal.
- **Research:** Camo Netting; Safe Passage.
- **Unavailable:** Scavenger Tank and Reclaimed Assault Tank. Keeps Rocket Cells and Rocket Buggies.
- **Rank 1 / 3 / 5 powers:** False Signals / Ambush Cell / Hidden Passage.
- **Art signatures:** Shade infantry have angular tan wraps; Ghost Technical has a low canvas canopy and folded weapon mount; nest has an uneven scrap roof with a narrow firing opening. Friendly concealed assets retain a readable outline.
- **Counterplay:** Detectors, area fire and controlling destructible tunnel exits.

### G2 — Commander Tariq Sayegh · Saturation Command

**Playstyle:** Mobile missile salvos and warned area pressure with vulnerable reload windows.

- **Exclusive replacements:** Rocket Cell → **Siege Rocket Squad**; Rocket Buggy → **Volley Launcher**; Salvaged AA Platform → **Missile Defense Nest**.
- **Starting doctrine bonus:** Signature missile units reload 10% faster; their movement speed is 10% lower. Nest remains an AA defense, not an all-purpose anti-everything turret.
- **Research:** Guidance Van targeting package; Rapid Reload (tuned with the starting bonus, not multiplied without a cap).
- **Unavailable:** Shadow Operative and camouflage research.
- **Rank 1 / 3 / 5 powers:** Rocket Recon Beacon / Harassing Salvo / Saturation Strike.
- **Art signatures:** Squad carries a broad launcher frame; Volley Launcher has a raised rectangular rack on a narrow wheeled bed; nest uses mismatched paired launch boxes and a small radar dish.
- **Superweapon option:** Silo payload research trades concentrated damage for a wider saturation pattern; never grants a second superweapon.
- **Counterplay:** Fast raiders, dispersed formations, point defense and attacks between salvos.

### G3 — Commander Juno Varek · Wreckrunner Command

**Playstyle:** Fast scavenging raids that earn bounded improvements through contested wreck control.

- **Exclusive replacements:** Raider Technical → **Ripper Technical**; Scavenger Tank → **Junker Assault Tank**; Raider Bike → **Scrap Runner**; Field Workshop → **Mobile Salvage Yard**.
- **Starting doctrine bonus:** Light raiders gain +10% movement speed; Junker starts with 10% less hull health than the standard tank. Two capped salvage tiers can add armor and weapon modules; no endlessly growing stats.
- **Building identity:** Mobile Salvage Yard is a deployed service rig with a side crane and scrap bins. Packing disables repair/conversion; redeployment obeys legal placement and cannot move build authority or refund/recreate wrecks.
- **Research:** Recovery Crews; Field Improvisation.
- **Unavailable:** Missile Drone Wing and the top static heavy-defense upgrade.
- **Rank 1 / 3 / 5 powers:** Rapid Salvage / Roadside Reinforcements / Scavenger Convoy.
- **Art signatures:** Ripper has an exposed roll cage and offset gun; Junker's two upgrades visibly add a side plate then a weapon module; Scrap Runner has a sidecar scrap basket. Upgrades must remain legible without changing hitboxes unexpectedly.
- **Counterplay:** Deny wreck access, protect ore routes and force head-on battles. Each enemy wreck pays once; friendly self-destruction grants nothing; recovery value is capped below the destroyed unit's purchase value.

## Production and implementation contract

1. Keep faction, general and player/team identity separate. The current renderer's team-based tint is not a full faction system.
2. Resolve standard roster → replacements → disables → modifiers before rendering production choices. Removed units must not remain purchasable through hotkeys, AI, saved queues or alternate factories.
3. Replacements inherit the original production slot and tech tier unless explicitly overridden. Never gate signature units solely behind General Points.
4. Define modifier targets explicitly (aircraft, signature missile units, defensive structures, etc.). Do not apply bonuses to every entity sharing a convenient renderer template. All values above are initial tuning hypotheses; avoid stacking equivalent upgrades without limits.
5. Commander rank, General Points, unit veterancy and researched upgrades remain independent. Use the v0.3 five-rank/seven-point proposal; powers need their own targeting, legality, warnings and cooldown definitions before implementation.
6. Every general keeps a viable early answer to infantry, armor and air. Reinforcement powers require legal revealed arrival sites, unit caps and visible entry; no spawning inside enemy structures or bypassing terrain.
7. Stage delivery: standard three-faction economy/combined-arms coverage → one signature unit per general → replacement/disable/bonus resolver → special structures and research → powers and advanced stealth/tunnel/salvage systems. Do not expose unimplemented powers as functioning buttons.

## Art manifest and review gates

For each named replacement above, track: stable content ID, faction/general, replaced ID, renderer family, unique silhouette components, world bounds/pivot, production icon, intact/damaged/destroyed/construction or deployment states as applicable, source/provenance and review status. This is the required manifest schema, not a claim that the assets already exist. Source is original procedural geometry; no paid generation is required by this plan.

First visual batch: **Arc Lance Tank, Imperator Heavy Tank and Junker Assault Tank**, together on the current battlefield and beside the existing MCV/power plant. These test clean high-tech, heavy industrial and improvised silhouettes before committing the whole roster. Then review all nine generals' signature units as a contact sheet and in-game at 1280×720, native zoom and production-icon scale.

Acceptance requires distinct silhouettes in grayscale, clear ownership in mirror matches, stable selection bounds, no clipping at all headings, readable damage/deployment/salvage states, and icons that match world geometry. General selection must display replacements, disabled units, bonus and weakness. Gameplay completion additionally requires roster-resolution tests for all 12 choices and interactive counterplay/balance testing; documentation or an art preview alone does not satisfy that gate.
