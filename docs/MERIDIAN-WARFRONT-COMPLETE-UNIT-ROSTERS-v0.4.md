# Meridian Warfront — Complete Unit Roster, Balance Sheet & General Differences
**Version 0.4 — Design proposal (2026-10-31)** · **Status: pre-playtest; numeric values are untested targets.**
**Companions:** Master GDD v0.1; RA2 Construction & Tech Trees v0.2; Zero Hour Generals System v0.3.
**Implementation status:** This is design work, not implemented game content; no GitHub push has occurred. Files are generated from one validated registry and include JSON plus CSV export.

## 1. Governing decisions
Red Alert 2 remains the model for Construction Yard, four-tab sidebar, shared Buildings and Defense lanes, gradual-cost production, finite ore economy, free first harvester, base crawling and fast skirmishes. Zero Hour remains the model for standard faction + three General armies, roster swaps, unavailable units, exclusive technologies, and General Points.
Every general is an **effective roster computed from a base faction**, never a copy with arbitrary UI differences. A swap removes the original production icon, inserts its named replacement in exactly the same slot, and inherits its original production prerequisites unless a specific change is listed. An exclusive unit creates one extra icon in the listed producer. A removed unit cannot be built by human, AI, captures or save/load.

### Battlefield / stat vocabulary
- **Credits / time:** price and seconds at standard speed (one producer, full power, adequate income). Credits drain while produced, not all at click-time. First refinery grants exactly one harvester for no extra charge; replacements cost their listed price.
- **HP / armor / speed:** baseline health points, armor type, and movement units/second. Building armor is STRUCTURE. All aircraft use AIR, naval ships NAVAL. HP and damage upgrades affect only their documented tagged units.
- **Weapon notation:** `damage/interval s`, `R` effective weapon range in world units, `×N` projectiles per salvo. Splash areas state their radius. Actual damage = base × weapon-versus-armor multiplier × applicable upgrades × veterancy; shields, cover and defense reductions apply afterward. Listed reloads are proposals, not tested.
- **Counterplay:** unit weapons that specify `ground` cannot hit aircraft; AA weapons require valid aerial targets. Rockets that specify `ground/air` may shoot both. Air weapons require rearming; ground artillery has setup times and minimum ranges where noted.
- **Roles and tech:** T0 basic, T1 War Factory/Radar era, T2 air/advanced tech, NAVAL conditional. Production sources are faction-specific names, while prerequisites reference shared *roles* (`War Factory`, `Radar`, etc.).
- **Army veterancy:** Rookie 1.0; Veteran +8% HP and +8% damage; Elite +15% HP and +15% damage (relative to rookie, not cumulative). General XP remains a separate five-rank, seven-point progression.

### Damage-versus-armor tuning matrix (design target)
| Weapon class | Personnel | Light | Medium | Heavy | Air | Naval | Structure |
| --- | --- | --- | --- | --- | --- | --- | --- |
| SMALL_ARMS | 1.00× | 0.55× | 0.16× | 0.08× | 0.00× | 0.10× | 0.22× |
| AP | 0.40× | 1.05× | 1.20× | 1.20× | 0.00× | 0.80× | 0.75× |
| EXPLOSIVE | 1.10× | 1.05× | 0.70× | 0.48× | 0.00× | 0.75× | 1.10× |
| ROCKET | 0.65× | 1.05× | 1.10× | 1.15× | 1.00× | 1.00× | 0.95× |
| AA | 0.20× | 0.45× | 0.25× | 0.12× | 1.40× | 0.30× | 0.30× |
| ENERGY | 0.75× | 1.05× | 1.10× | 1.05× | 0.70× | 0.60× | 0.90× |
| ARTILLERY | 1.00× | 1.00× | 1.05× | 0.78× | 0.00× | 0.90× | 1.40× |
All weapons must explicitly map to one of these classes; the table is a first-pass test harness, not an assertion of exact RA2/Zero Hour damage rules. Aircraft can only be attacked by weapons that explicitly list air capability.

## 2. All standard army units — full baseline catalog
### Alliance — flexible precision and air (15 units)
The following are the *standard faction* values. Each General inherits these unless a change is spelled out in section 4.
| Unit (ID) | Tier | HP / armor | Credits / time | Weapon | Active ability / behavior | Available upgrades |
| --- | --- | --- | --- | --- | --- | --- |
| **Ranger** (`a_ranger`) | T0 | 105 / PERSONNEL · Spd 85 | 150 / 5s | Assault rifle · small arms 11/0.65s R145 ground | Garrison; take cover; suppress light infantry | `INF_ARMOR`, `INF_OPTICS`, `A_DATALINK` |
| **Javelin Missile Team** (`a_javelin`) | T0 | 90 / PERSONNEL · Spd 68 | 320 / 9s | Guided rocket · rocket 75/3.2s R220 ground/air | Deploy 0.8s; targets tanks and helicopters | `INF_ARMOR`, `INF_OPTICS`, `A_DATALINK` |
| **Field Engineer** (`a_engineer`) | T0 | 85 / PERSONNEL · Spd 78 | 450 / 10s | Unarmed | Capture neutral/enemy structure; repair one allied structure; consumed on capture | `INF_ARMOR` |
| **Lynx IFV** (`a_lynx`) | T1 | 360 / LIGHT · Spd 120 | 750 / 14s | Autocannon · kinetic 24/0.5s R185 ground | Transport 3 infantry; fire infantry support ports; no firing when evacuating | `TRACK_DRIVE`, `TARGETING`, `A_DATALINK` |
| **Sentinel MBT** (`a_sentinel`) | T1 | 740 / HEAVY · Spd 80 | 1,200 / 22s | 120mm cannon · armor-piercing 115/2.4s R205 ground | Independent turret; attack-move; crush light cover (not infantry) | `ARMOR_PLATING`, `TARGETING`, `TRACK_DRIVE` |
| **Specter Scout Drone** (`a_specter`) | T1 | 180 / LIGHT · Spd 145 | 480 / 10s | Light pulse gun · small arms 9/0.5s R130 ground | Extended vision; detects concealed targets R180; fragile | `AA_TRACKING`, `A_SENSOR_NET` |
| **Sentinel AA Vehicle** (`a_sentinel_aa`) | T1 | 380 / LIGHT · Spd 115 | 900 / 17s | Twin SAM · AA rocket 80/2.2s R320 air; light cannon 10/0.5s R120 ground | Tracks aircraft while moving | `AA_TRACKING`, `TRACK_DRIVE`, `A_DATALINK` |
| **Precision Howitzer** (`a_howitzer`) | T1 | 420 / MEDIUM · Spd 67 | 1,400 / 25s | 155mm shell · artillery 190/5s R400 ground; min R85 | Brace 2.2s before fire; splash R55; reveal firing position | `ARTY_COMPUTER`, `TARGETING` |
| **Arc Beam Tank** (`a_arc_beam`) | T2 | 590 / HEAVY · Spd 77 | 1,900 / 31s | Focused beam · energy 60/0.9s R255 ground | Spool 1.5s; full damage after continuous fire; poor vs swarms | `ARMOR_PLATING`, `TARGETING`, `A_DATALINK` |
| **Striker Gunship** (`a_striker`) | T2 | 400 / AIR · Spd 175 | 1,250 / 23s | Rockets · guided 70/1.4s R210 ground | 4 strike salvos; automatic rearm at airfield; hover vulnerable to AA | `AIRFRAMES`, `ECM_PODS`, `A_DATALINK` |
| **Vortex Fighter** (`a_vortex`) | T2 | 330 / AIR · Spd 250 | 1,450 / 29s | Air missiles · AA 125/1.8s R260 air; light ground missiles 90/2.4s R230 ground | 4 missiles per sortie; return to reload; boost dash | `AIRFRAMES`, `ECM_PODS`, `A_DATALINK` |
| **Ore Harvester** (`a_harvester`) | T0 | 850 / HEAVY · Spd 66 | 1,200 / 25s | Unarmed | Cargo 800 ore-value units; auto mine-return-unload; issued free once per refinery placement | `HARVEST_EFF`, `ARMOR_PLATING` |
| **Alliance MCV** (`a_mcv`) | T2 | 1150 / HEAVY · Spd 60 | 3,000 / 45s | Unarmed | Deploy/pack Construction Yard; no moving while transforming | `ARMOR_PLATING`, `MCV_DEPLOY` |
| **Patrol Corvette** (`a_patrol`) | NAVAL | 600 / NAVAL · Spd 85 | 1,100 / 25s | Deck cannon · HE 90/1.8s R260 ground/sea; AA gun 16/0.3s R200 air | Coastal reconnaissance; escorts harvest routes near water | `NAVAL_FIRE`, `AA_TRACKING` |
| **Dart Missile Frigate** (`a_dart`) | NAVAL | 950 / NAVAL · Spd 85 | 2,400 / 45s | Cruise missiles · guided 230/5.5s R460 land/sea; AA 70/2.2s R270 air | Long-range bombardment; minimum R120 | `NAVAL_FIRE`, `A_DATALINK` |

### Republic — durable armor and artillery (15 units)
The following are the *standard faction* values. Each General inherits these unless a change is spelled out in section 4.
| Unit (ID) | Tier | HP / armor | Credits / time | Weapon | Active ability / behavior | Available upgrades |
| --- | --- | --- | --- | --- | --- | --- |
| **Line Infantry** (`r_line`) | T0 | 120 / PERSONNEL · Spd 78 | 140 / 5s | Service rifle · small arms 11/0.65s R140 ground | Garrison; fortified crouch improves cover | `INF_ARMOR`, `INF_OPTICS`, `R_DISCIPLINE` |
| **Tank Hunter** (`r_hunter`) | T0 | 110 / PERSONNEL · Spd 65 | 290 / 9s | Shoulder rocket · rocket 80/3.3s R210 ground/air | Entrench for +15% rocket range, cannot move while braced | `INF_ARMOR`, `INF_OPTICS`, `R_DISCIPLINE` |
| **Combat Engineer** (`r_engineer`) | T0 | 105 / PERSONNEL · Spd 77 | 450 / 10s | Unarmed | Capture; repairs structures; consumed on capture | `INF_ARMOR` |
| **Ironclad APC** (`r_ironclad`) | T1 | 540 / MEDIUM · Spd 97 | 850 / 17s | Heavy MG · small arms 19/0.45s R175 ground | Transport 5 infantry; can unload behind cover | `ARMOR_PLATING`, `TRACK_DRIVE`, `R_REACTIVE` |
| **Bastion MBT** (`r_bastion`) | T1 | 900 / HEAVY · Spd 70 | 1,350 / 25s | Heavy smoothbore · AP 130/2.6s R200 ground | Hull armor +15% frontal protection while facing target | `ARMOR_PLATING`, `TARGETING`, `R_REACTIVE` |
| **Recon APC** (`r_recon`) | T1 | 340 / LIGHT · Spd 140 | 600 / 12s | Coaxial MG · small arms 12/0.45s R135 ground | Detection radius 180; speed burst 4s with 16s cooldown | `TRACK_DRIVE`, `AA_TRACKING` |
| **Flak Carrier** (`r_flak`) | T1 | 500 / MEDIUM · Spd 95 | 850 / 18s | Flak shells · AA 55/0.85s R270 air; 20/0.85s ground | Area flak against clustered light air targets | `AA_TRACKING`, `ARMOR_PLATING` |
| **Thunderbolt Artillery** (`r_thunder`) | T1 | 475 / MEDIUM · Spd 60 | 1,450 / 27s | Heavy howitzer · artillery 220/5.3s R370 ground, min R90 | Deploy 2.5s; splash R65; cannot shoot while moving | `ARTY_COMPUTER`, `R_SHELLS` |
| **Mammoth Siege Tank** (`r_mammoth`) | T2 | 1700 / HEAVY · Spd 47 | 2,450 / 43s | Twin cannons · AP 130×2/3.5s R215 ground; AA rocket 55/3s R200 air | Very slow; crush light obstacles; vulnerable to surrounding | `ARMOR_PLATING`, `TARGETING`, `R_REACTIVE` |
| **Siege Helicopter** (`r_siege_heli`) | T2 | 470 / AIR · Spd 165 | 1,550 / 26s | Heavy rockets · guided 92/1.65s R215 ground | 6 salvos; returns to reload; slow hover | `AIRFRAMES`, `ECM_PODS` |
| **Heavy Bomber** (`r_bomber`) | T2 | 580 / AIR · Spd 205 | 2,300 / 43s | Bomb load · explosive 400/strike R95 splash ground | 2 payloads per sortie; long rearm; AA vulnerable | `AIRFRAMES`, `ECM_PODS` |
| **Industrial Hauler** (`r_hauler`) | T0 | 1000 / HEAVY · Spd 59 | 1,250 / 27s | Unarmed | Cargo 900; slower than Alliance harvester; first one bundled | `HARVEST_EFF`, `ARMOR_PLATING` |
| **Republic MCV** (`r_mcv`) | T2 | 1300 / HEAVY · Spd 52 | 3,100 / 48s | Unarmed | Deploy/pack Construction Yard; heavy hull | `ARMOR_PLATING`, `MCV_DEPLOY` |
| **Armored River Monitor** (`r_patrol`) | NAVAL | 850 / NAVAL · Spd 85 | 1,300 / 29s | Dual deck guns · HE 115/2s R265 ground/sea; flak 40/1s R175 air | High durability for shallow water | `NAVAL_FIRE`, `R_SHELLS` |
| **Bastion Missile Cruiser** (`r_dread`) | NAVAL | 1450 / NAVAL · Spd 85 | 2,750 / 50s | Missile barrage · guided 180×2/6s R440 land/sea; flak 75/2.2s R240 air | Slow; shore siege requires scout vision | `NAVAL_FIRE`, `AA_TRACKING` |

### GIA — mobile, inexpensive improvisation (16 units)
The following are the *standard faction* values. Each General inherits these unless a change is spelled out in section 4.
| Unit (ID) | Tier | HP / armor | Credits / time | Weapon | Active ability / behavior | Available upgrades |
| --- | --- | --- | --- | --- | --- | --- |
| **Militia Fighter** (`g_militia`) | T0 | 90 / PERSONNEL · Spd 92 | 100 / 4s | Scrap rifle · small arms 10/0.7s R130 ground | Garrison; cheaper squads; scavenges spare rounds for no economic profit | `INF_ARMOR`, `INF_OPTICS`, `G_CAMO` |
| **Rocket Cell** (`g_rocket_cell`) | T0 | 85 / PERSONNEL · Spd 72 | 260 / 8s | Scrap rocket · rocket 75/3.2s R205 ground/air | Ambush first shot +15% damage from cover | `INF_ARMOR`, `INF_OPTICS`, `G_CAMO` |
| **Salvage Technician** (`g_tech`) | T0 | 80 / PERSONNEL · Spd 90 | 400 / 9s | Unarmed | Capture structures; repair GIA vehicles at reduced rate | `INF_ARMOR` |
| **Raider Technical** (`g_technical`) | T1 | 290 / LIGHT · Spd 145 | 550 / 12s | Mounted MG · small arms 18/0.45s R155 ground | Transport 2 infantry; fast flank; not a tank | `TRACK_DRIVE`, `G_SCAVENGE` |
| **Scavenger Tank** (`g_scavenger`) | T1 | 630 / MEDIUM · Spd 87 | 950 / 19s | Salvaged cannon · AP 105/2.7s R190 ground | Can collect one wreck upgrade: +10% damage OR +10% max HP | `ARMOR_PLATING`, `TARGETING`, `G_SCAVENGE` |
| **Raider Bike** (`g_bike`) | T1 | 165 / LIGHT · Spd 165 | 320 / 7s | Light MG · small arms 9/0.4s R115 ground | Detection R135; fastest ground spotter | `TRACK_DRIVE`, `G_CAMO` |
| **Rocket Truck** (`g_rocket_truck`) | T1 | 330 / LIGHT · Spd 130 | 730 / 15s | Twin rockets · AA 95/2.3s R290 air; 45/2.3s R160 ground | Brief setup to fire; low armor | `AA_TRACKING`, `TRACK_DRIVE` |
| **Rocket Buggy** (`g_rocket_buggy`) | T1 | 250 / LIGHT · Spd 144 | 800 / 17s | Multi-rocket · explosive 50×3/4s R325 ground | Kite attack; max turn speed; small splash | `ARTY_COMPUTER`, `TRACK_DRIVE`, `G_SCAVENGE` |
| **Reclaimed Assault Tank** (`g_reclaimed`) | T2 | 980 / HEAVY · Spd 72 | 1,650 / 31s | Heavy salvaged cannon · AP 130/3s R205 ground | One permanent wreck mod per life; can choose weapon or armor | `ARMOR_PLATING`, `TARGETING`, `G_SCAVENGE` |
| **Improvised Attack Helicopter** (`g_heli`) | T2 | 330 / AIR · Spd 178 | 1,050 / 20s | Unguided rockets · explosive 58×2/1.8s R180 ground | 4 attack runs; return to rearm; very AA vulnerable | `AIRFRAMES`, `G_CAMO` |
| **Missile Drone Wing** (`g_drone_wing`) | T2 | 240 / AIR · Spd 218 | 1,550 / 29s | Attack drone missiles · guided 80×2/2.2s R200 ground/air | 6 missiles; wing counts as one selectable unit; fragile | `AIRFRAMES`, `ECM_PODS` |
| **Salvage Collector** (`g_collector`) | T0 | 650 / HEAVY · Spd 82 | 1,000 / 22s | Unarmed | Cargo 650; fast turnaround; first one bundled | `HARVEST_EFF` |
| **GIA MCV** (`g_mcv`) | T2 | 850 / HEAVY · Spd 68 | 2,600 / 42s | Unarmed | Deploy/pack Resistance Headquarters; relatively fast | `MCV_DEPLOY`, `ARMOR_PLATING` |
| **Shadow Operative** (`g_shadow`) | T2 | 105 / PERSONNEL · Spd 97 | 850 / 18s | Suppressed carbine · small arms 20/0.85s R155 ground | Stealth while still; saboteur charge vs unguarded structure, 30s cooldown | `INF_ARMOR`, `G_CAMO` |
| **Raider Riverboat** (`g_river`) | NAVAL | 510 / NAVAL · Spd 85 | 850 / 21s | Deck MG · small arms 20/0.3s R210 ground/sea; AA 10/0.3s R145 air | Shallow water raiding; can transport 3 infantry | `NAVAL_FIRE`, `G_SCAVENGE` |
| **Improvised Missile Barge** (`g_missile_boat`) | NAVAL | 850 / NAVAL · Spd 85 | 1,900 / 36s | Rocket salvos · guided 105×2/5.2s R390 land/sea | Deploy 2.5s to fire; vulnerable in transit | `NAVAL_FIRE`, `ARTY_COMPUTER` |

## 3. Exact shared and faction research options
All upgrades below are purchased once per player, progress in the Building research UI, and apply to the named unit tags. Upgrades are not themselves separate units or hidden extra build lanes. Prohibited upgrades are removed for the specified general.
### Shared infantry/vehicle/air/economy research
| Upgrade ID | Price / research time | Research location | Exact effect |
| --- | --- | --- | --- |
| `INF_ARMOR` — Infantry Ballistic Vests | 450 / 25s | Barracks | Infantry +15% max HP; no effect on vehicles |
| `INF_OPTICS` — Optical Sights | 550 / 30s | Barracks+Radar | Line, scout and specialist infantry +10% weapon range; not guided rockets |
| `ARMOR_PLATING` — Composite Armor | 900 / 42s | War Factory+Tech Center | Vehicles with this tag +15% max HP |
| `TARGETING` — Targeting Computer | 800 / 35s | War Factory+Radar | Tagged cannon/energy vehicles +10% damage to MEDIUM/HEAVY armor |
| `TRACK_DRIVE` — Improved Drive Trains | 600 / 32s | War Factory | Tagged light and medium vehicles +10% move speed |
| `AA_TRACKING` — Tracking Array | 650 / 32s | Radar | Tagged AA units/detectors +12% AA range; detector +10% detection range |
| `ARTY_COMPUTER` — Ballistic Fire Control | 800 / 40s | Radar | Mobile artillery −12% shell scatter; no damage boost |
| `AIRFRAMES` — Reinforced Airframes | 950 / 48s | Airfield+Tech Center | Aircraft +15% max HP |
| `ECM_PODS` — Electronic Countermeasures | 950 / 42s | Airfield+Radar | Incoming guided missiles have −15% hit probability; cannot stack with similar effect |
| `HARVEST_EFF` — Fast Unloading | 650 / 28s | Refinery+War Factory | Harvester unloading time −20%; no cargo creation |
| `MCV_DEPLOY` — Hydraulic Deploy | 550 / 28s | Service Depot | MCV deploy/pack time −20% |
| `NAVAL_FIRE` — Naval Gunnery Systems | 850 / 38s | Naval Dock+Radar | Ship direct-fire range +8%; does not affect superweapons |

### Faction baseline research
| Upgrade ID | Price / research time | Research location | Exact effect |
| --- | --- | --- | --- |
| `A_DATALINK` — Alliance Precision Datalink | 850 / 38s | Satellite Uplink | Tagged Alliance units +8% accuracy on moving targets |
| `A_SENSOR_NET` — Advanced Sensor Mesh | 650 / 30s | Satellite Uplink | Tagged reconnaissance units gain +40 vision/detection range |
| `R_DISCIPLINE` — Republic Fire Discipline | 550 / 30s | Garrison Barracks+Radar | Tagged infantry +10% accuracy while stationary |
| `R_REACTIVE` — Reactive Armor | 1,050 / 48s | Military Research Center | Tagged Republican armored vehicles −12% incoming AP/rocket damage |
| `R_SHELLS` — Improved Heavy Shells | 850 / 42s | Command Radar | Tagged Republic artillery/ships +8% anti-structure damage |
| `G_CAMO` — Improvised Camouflage | 650 / 32s | Signal Shack | Tagged GIA infantry/aircraft hide at rest 3s; firing breaks stealth |
| `G_SCAVENGE` — Wreck Recovery Protocol | 550 / 30s | Field Workshop | Tagged GIA units may extract one capped combat-only wreck bonus |
| `G_HEAVY_DEF` — Heavy Static Fortification | 850 / 40s | Black Market Laboratory | GIA heavy emplacement +15% maximum HP, not a unit buff |

### General-specific research
| Upgrade ID | Price / research time | Research location | Exact effect |
| --- | --- | --- | --- |
| `AS_HANGARS` — Reinforced Hangars | 1,050 / 45s | Airfield | Airfield pad capacity 2→3; Air Superiority gunships rearm 12% faster |
| `AS_COUNTERMEASURES` — Advanced Countermeasures | 1,200 / 50s | Airfield+Radar | Ace aircraft and Skywatch chance of guided missile hit −18%, nonstacking with ECM; takes better value |
| `DE_CAPACITORS` — Beam Capacitors | 1,100 / 45s | Advanced Tech Center | Arc Lance/Arc Sapper +12% beam damage; Beam Bastion +12% damage |
| `DE_GRID` — Grid Stabilizers | 950 / 40s | Advanced Tech Center | Lance and Lattice low-power firing penalty 2.0×→1.35×; Beam Bastion stays offline at brownout |
| `SO_SILENT` — Silent Running | 850 / 36s | Satellite Uplink | Ghost Carrier and Ghost Sniper recloak after 2s instead of 3s |
| `SO_DESIGNATION` — Coordinated Designation | 950 / 42s | Satellite Uplink+Tech Center | Pathfinder/Phantom marks target 8s: allied guided weapons +10% damage to marked target |
| `HA_AUTOLOAD` — Heavy Autoloaders | 1,250 / 48s | Military Research Center | Juggernaut/Imperator weapon reload interval −12% |
| `HA_VETERANS` — Veteran Crews | 1,500 / 60s | Heavy Foundry+Tech Center | New Juggernaut, Imperator tanks spawn at 1st veterancy; not retroactive |
| `AR_OBSERVERS` — Forward Observers | 950 / 40s | Command Radar | Stormrail near line-of-sight spotter −18% scatter; Survey Drone detect +20 |
| `AR_RAPID` — Rapid Fire Mission | 1,200 / 50s | Military Research Center | Stormrail deployment 3.5→2.5s and reload −10% |
| `FD_FORTS` — Reinforced Fortifications | 1,000 / 45s | Military Research Center | Steel Pillbox and Forward Bastion +20% max HP; Garrison Guard +10% while garrisoned |
| `FD_FIELDWORKS` — Mobile Field Works | 750 / 34s | Fortified Outpost | Siege Carrier deploy 3→2s; Fortification Engineer barriers 60→85s |
| `GW_CAMO` — Camo Netting | 850 / 35s | Signal Shack | Shade/Ghost Technical/Saboteur recloak 0.8s sooner; valid GIA structures gain concealed silhouette |
| `GW_PASSAGE` — Safe Passage | 800 / 38s | Tunnel Network | Ghost Technical and Saboteur tunnel exit protection +30% damage reduction for 3s |
| `MW_GUIDANCE` — Guidance Van Network | 1,050 / 44s | Signal Shack | Siege Rocket/Volley/Guidance Van missile scatter −15%; no flat extra damage |
| `MW_RELOAD` — Rapid Reload | 1,250 / 52s | Black Market Laboratory | Siege Rocket Squad/Volley Launcher firing intervals −12% |
| `SM_RECOVERY` — Recovery Crews | 850 / 38s | Field Workshop or Mobile Salvage Yard | Ripper/Junker/Scrap Runner recover wrecks 25% faster; no same-wreck repeat |
| `SM_IMPROV` — Field Improvisation | 1,000 / 44s | Black Market Laboratory | Junker wreck tiers max +12% each instead of +10%; Recovery Truck heals 24 HP/s at same credit cost |

## 4. Each general: exact changes to the standard faction
**IMPORTANT:** the tables below are the complete *difference list*. All units not named as replaced/removed remain available at their baseline statistics, except where a modifier explicitly states otherwise. All general-only unit entries have full weapon, HP, armor, cost, time, ability and upgrade columns.
### Alliance generals
#### Air Superiority (`alliance_air`)
**Tradeoff:** No mainline ground MBT; vulnerable to AA and airfield raids.
| Change | Standard slot | This general | Meaning |
| --- | --- | --- | --- |
| REPLACE | Vortex Fighter (`a_vortex`) | Vortex Ace Interceptor (`a_ace`) | 1,450 / 29s → 1,800 / 34s; original unavailable |
| REPLACE | Striker Gunship (`a_striker`) | Tempest Assault VTOL (`a_tempest`) | 1,250 / 23s → 1,650 / 29s; original unavailable |
| REPLACE | Lynx IFV (`a_lynx`) | Lynx Missile Escort (`a_missile_escort`) | 750 / 14s → 850 / 16s; original unavailable |
| REMOVE | Sentinel MBT (`a_sentinel`) | — | Entire unit slot disappears |
| REMOVE | Arc Beam Tank (`a_arc_beam`) | — | Entire unit slot disappears |
| ADD | — | Skywatch Recon Craft (`a_skywatch`) | Airfield; 900 / 20s |
**Complete statistics for newly accessible units:**
| Unit (ID) | Tier | HP / armor | Credits / time | Weapon | Active ability / behavior | Available upgrades |
| --- | --- | --- | --- | --- | --- | --- |
| **Vortex Ace Interceptor** (`a_ace`) | T2 | 430 / AIR · Spd 270 | 1,800 / 34s | Guided AA missiles · AA 160/1.7s R290 air; strike missiles 105/2.4s R230 ground | 6 missiles per sortie; intercepts one incoming AA missile each 18s | `AIRFRAMES`, `ECM_PODS`, `AS_COUNTERMEASURES` |
| **Tempest Assault VTOL** (`a_tempest`) | T2 | 460 / AIR · Spd 177 | 1,650 / 29s | Piercing rockets · guided 110/1.65s R230 ground | 6 salvos; 2s firing hover exposes aircraft to AA | `AIRFRAMES`, `ECM_PODS`, `AS_HANGARS` |
| **Lynx Missile Escort** (`a_missile_escort`) | T1 | 350 / LIGHT · Spd 125 | 850 / 16s | Dual missiles · rocket 80/2.5s R220 ground; 70/2.5s R260 air | Transport 2 infantry; low sustained anti-infantry power | `TRACK_DRIVE`, `AA_TRACKING` |
| **Skywatch Recon Craft** (`a_skywatch`) | T2 | 280 / AIR · Spd 220 | 900 / 20s | Unarmed | Large 300 vision, detector R220; 25s endurance per sortie; airfield reload 12s | `AIRFRAMES`, `AS_COUNTERMEASURES` |
**Exclusive upgrades:** `AS_HANGARS`, `AS_COUNTERMEASURES`. **Prohibited upgrades:** none.
**Numeric and mechanical overrides:** 1) Airfield capacity 3 aircraft rather than 2 with Reinforced Hangars. 2) Striker/Vortex standard slots unavailable; no standard or advanced tanks.
**General Powers (rank / cooldown):**
| Unlock rank | Ability | Cooldown | Effect |
| --- | --- | --- | --- |
| Rank 1 | Recon Overflight | 100s | Reveal 350-wide path for 18s |
| Rank 3 | Interdiction Flight | 210s | Two interceptable strike passes against marked ground area |
| Rank 5 | Sky Supremacy | 360s | Four warning-marked aircraft attack waves; no persistent units |
**Resolved playable army:** Patrol Corvette, Dart Missile Frigate, Ranger, Javelin Missile Team, Field Engineer, Ore Harvester, Specter Scout Drone, Lynx Missile Escort, Sentinel AA Vehicle, Precision Howitzer, Skywatch Recon Craft, Tempest Assault VTOL, Vortex Ace Interceptor, Alliance MCV.

#### Directed Energy (`alliance_energy`)
**Tradeoff:** High power dependence; weak long-range conventional artillery.
| Change | Standard slot | This general | Meaning |
| --- | --- | --- | --- |
| REPLACE | Sentinel MBT (`a_sentinel`) | Arc Lance Tank (`a_lance`) | 1,200 / 22s → 1,450 / 26s; original unavailable |
| REPLACE | Sentinel AA Vehicle (`a_sentinel_aa`) | Lattice Interceptor (`a_lattice`) | 900 / 17s → 1,150 / 22s; original unavailable |
| REMOVE | Precision Howitzer (`a_howitzer`) | — | Entire unit slot disappears |
| ADD | — | Arc Sapper (`a_arc_sapper`) | Barracks; 450 / 11s |
| BUILDING REPLACE | Sentry Turret | Beam Bastion | Same strategic building role and prerequisites, changed attributes described below |
**Complete statistics for newly accessible units:**
| Unit (ID) | Tier | HP / armor | Credits / time | Weapon | Active ability / behavior | Available upgrades |
| --- | --- | --- | --- | --- | --- | --- |
| **Arc Lance Tank** (`a_lance`) | T1 | 670 / HEAVY · Spd 76 | 1,450 / 26s | Pulse lance · energy 92/1.65s R215 ground | Accurate first shot; at low power weapon fire interval doubles; conventional missiles unaffected | `ARMOR_PLATING`, `DE_CAPACITORS`, `DE_GRID` |
| **Lattice Interceptor** (`a_lattice`) | T1 | 370 / LIGHT · Spd 118 | 1,150 / 22s | Pulse array · energy 45/0.6s R260 air, 24/0.6s R140 ground | Intercept one hostile rocket every 3.5s; low power disables interceptions | `AA_TRACKING`, `DE_GRID` |
| **Arc Sapper** (`a_arc_sapper`) | T1 | 95 / PERSONNEL · Spd 80 | 450 / 11s | Arc carbine · energy 20/0.8s R145 ground | EMP burst: 3s disable on vehicle/defense; 26s cooldown, range 110; not an instant kill | `INF_ARMOR`, `DE_CAPACITORS` |
**Exclusive upgrades:** `DE_CAPACITORS`, `DE_GRID`. **Prohibited upgrades:** `ARTY_COMPUTER`.
**Numeric and mechanical overrides:** 1) Beam Bastion 800 credits/14s/−45 power, replaces Sentry Turret 550/9s/−10. 2) Arc Lance and Lattice lose effectiveness during base-wide brownout.
**General Powers (rank / cooldown):**
| Unlock rank | Ability | Cooldown | Effect |
| --- | --- | --- | --- |
| Rank 1 | Grid Surge | 120s | Allied energy weapons in 190 radius +20% rate for 12s; +20% power draw |
| Rank 3 | Target Lattice | 185s | Reveal and mark 160 radius for 14s; accuracy +12% |
| Rank 5 | Orbital Pulse | 370s | Warned 120 radius pulse; lower building damage than Particle Beam |
**Resolved playable army:** Patrol Corvette, Dart Missile Frigate, Ranger, Javelin Missile Team, Field Engineer, Ore Harvester, Arc Sapper, Specter Scout Drone, Lynx IFV, Lattice Interceptor, Arc Lance Tank, Striker Gunship, Vortex Fighter, Arc Beam Tank, Alliance MCV.

#### Special Operations (`alliance_ops`)
**Tradeoff:** Expensive elite infantry and lighter anti-armor ceiling.
| Change | Standard slot | This general | Meaning |
| --- | --- | --- | --- |
| REPLACE | Ranger (`a_ranger`) | Pathfinder Team (`a_pathfinder`) | 150 / 5s → 260 / 8s; original unavailable |
| REPLACE | Lynx IFV (`a_lynx`) | Ghost Recon Carrier (`a_ghost_carrier`) | 750 / 14s → 950 / 18s; original unavailable |
| REPLACE | Specter Scout Drone (`a_specter`) | Phantom Sensor Drone (`a_phantom_drone`) | 480 / 10s → 650 / 13s; original unavailable |
| REMOVE | Arc Beam Tank (`a_arc_beam`) | — | Entire unit slot disappears |
| ADD | — | Ghost Sniper (`a_ghost_sniper`) | Barracks; 650 / 16s |
**Complete statistics for newly accessible units:**
| Unit (ID) | Tier | HP / armor | Credits / time | Weapon | Active ability / behavior | Available upgrades |
| --- | --- | --- | --- | --- | --- | --- |
| **Pathfinder Team** (`a_pathfinder`) | T0 | 90 / PERSONNEL · Spd 83 | 260 / 8s | Marksman rifle · small arms 35/1.7s R205 ground | Detection R200; hides after 3s stationary; no effective anti-armor | `INF_OPTICS`, `SO_DESIGNATION` |
| **Ghost Recon Carrier** (`a_ghost_carrier`) | T1 | 295 / LIGHT · Spd 130 | 950 / 18s | Silenced MG · small arms 14/0.6s R150 ground | Transports 4; stealth after 3s idle, revealed by firing/detectors | `TRACK_DRIVE`, `SO_SILENT` |
| **Phantom Sensor Drone** (`a_phantom_drone`) | T1 | 155 / LIGHT · Spd 150 | 650 / 13s | Unarmed | Vision 280, detection R250; drone cloaks while stationary, speed reduced | `A_SENSOR_NET`, `SO_DESIGNATION` |
| **Ghost Sniper** (`a_ghost_sniper`) | T2 | 95 / PERSONNEL · Spd 76 | 650 / 16s | Precision rifle · small arms 95/3s R260 ground | Prioritizes exposed personnel; stealth at rest; 18s relocation stealth cooldown | `INF_OPTICS`, `SO_SILENT`, `SO_DESIGNATION` |
**Exclusive upgrades:** `SO_SILENT`, `SO_DESIGNATION`. **Prohibited upgrades:** `ARTY_COMPUTER`.
**Numeric and mechanical overrides:** 1) Lose the heaviest artillery computer optimization on Precision Howitzer. 2) Stealth ends on firing, taking damage or being detected; +3s recloak.
**General Powers (rank / cooldown):**
| Unlock rank | Ability | Cooldown | Effect |
| --- | --- | --- | --- |
| Rank 1 | Signal Sweep | 105s | Reveal detectors and enemy radar emitters R300 for 12s |
| Rank 3 | Covert Insertion | 225s | Deploy 3 limited-lifetime Pathfinder squads at revealed legal site |
| Rank 5 | Electronic Blackout | 390s | Disable radar/targeting in target R170 for 12s; no total power shutdown |
**Resolved playable army:** Patrol Corvette, Dart Missile Frigate, Pathfinder Team, Javelin Missile Team, Field Engineer, Ore Harvester, Phantom Sensor Drone, Sentinel AA Vehicle, Ghost Recon Carrier, Sentinel MBT, Precision Howitzer, Striker Gunship, Vortex Fighter, Ghost Sniper, Alliance MCV.

### Republic generals
#### Heavy Armor (`republic_armor`)
**Tradeoff:** Slow expensive ground push, no mobile artillery.
| Change | Standard slot | This general | Meaning |
| --- | --- | --- | --- |
| REPLACE | Bastion MBT (`r_bastion`) | Juggernaut Battle Tank (`r_jugger`) | 1,350 / 25s → 1,700 / 30s; original unavailable |
| REPLACE | Mammoth Siege Tank (`r_mammoth`) | Imperator Heavy Tank (`r_imperator`) | 2,450 / 43s → 3,050 / 52s; original unavailable |
| REPLACE | Recon APC (`r_recon`) | Armored Scout Carrier (`r_armored_scout`) | 600 / 12s → 850 / 18s; original unavailable |
| REMOVE | Thunderbolt Artillery (`r_thunder`) | — | Entire unit slot disappears |
| ADD | — | Assault Breacher (`r_breacher`) | Garrison Barracks; 400 / 11s |
**Complete statistics for newly accessible units:**
| Unit (ID) | Tier | HP / armor | Credits / time | Weapon | Active ability / behavior | Available upgrades |
| --- | --- | --- | --- | --- | --- | --- |
| **Juggernaut Battle Tank** (`r_jugger`) | T1 | 1100 / HEAVY · Spd 57 | 1,700 / 30s | High-velocity cannon · AP 165/2.7s R205 ground | Front +20% damage reduction; speed -18% vs Bastion | `ARMOR_PLATING`, `HA_AUTOLOAD`, `HA_VETERANS` |
| **Imperator Heavy Tank** (`r_imperator`) | T2 | 2150 / HEAVY · Spd 43 | 3,050 / 52s | Twin siege cannons · AP 170×2/3.8s R220 ground; AA 65/3s R195 air | Very slow; cannot reverse quickly; high recovery penalty if lost | `ARMOR_PLATING`, `HA_AUTOLOAD`, `HA_VETERANS` |
| **Armored Scout Carrier** (`r_armored_scout`) | T1 | 550 / MEDIUM · Spd 105 | 850 / 18s | Heavy MG · small arms 18/0.5s R140 ground | Detect R160; slower than Recon APC; transports 2 | `TRACK_DRIVE`, `R_REACTIVE` |
| **Assault Breacher** (`r_breacher`) | T1 | 170 / PERSONNEL · Spd 74 | 400 / 11s | Close assault shotgun · HE 32/0.9s R90 ground | Clear garrison: suppress occupied building for 4s; 28s cooldown | `INF_ARMOR`, `R_DISCIPLINE` |
**Exclusive upgrades:** `HA_AUTOLOAD`, `HA_VETERANS`. **Prohibited upgrades:** `ARTY_COMPUTER`, `R_SHELLS`.
**Numeric and mechanical overrides:** 1) Siege Helicopter cost 1550→1800; Heavy Bomber cost 2300→2650. 2) Only tanks from this general gain Veteran Crews initial veterancy.
**Exact extra unit-price overrides:** `r_siege_heli` 1,550 → 1,800 credits, `r_bomber` 2,300 → 2,650 credits.
**General Powers (rank / cooldown):**
| Unlock rank | Ability | Cooldown | Effect |
| --- | --- | --- | --- |
| Rank 1 | Field Repairs | 125s | Restore 15% HP over 12s to up to 6 friendly vehicles in area |
| Rank 3 | Armor Reserve | 240s | Call in 2 temporary escorted Juggernauts via map edge |
| Rank 5 | Breakthrough Order | 375s | Nearby tanks +15% move and suppression resistance for 18s |
**Resolved playable army:** Armored River Monitor, Bastion Missile Cruiser, Industrial Hauler, Line Infantry, Tank Hunter, Combat Engineer, Ironclad APC, Flak Carrier, Armored Scout Carrier, Juggernaut Battle Tank, Assault Breacher, Imperator Heavy Tank, Republic MCV, Siege Helicopter, Heavy Bomber.

#### Artillery Command (`republic_artillery`)
**Tradeoff:** Fragile at close range; requires scouting and time to deploy.
| Change | Standard slot | This general | Meaning |
| --- | --- | --- | --- |
| REPLACE | Thunderbolt Artillery (`r_thunder`) | Stormrail Howitzer (`r_stormrail`) | 1,450 / 27s → 1,850 / 33s; original unavailable |
| REPLACE | Bastion MBT (`r_bastion`) | Escort Battle Tank (`r_escort`) | 1,350 / 25s → 1,050 / 20s; original unavailable |
| REMOVE | Mammoth Siege Tank (`r_mammoth`) | — | Entire unit slot disappears |
| ADD | — | Survey Spotter Drone (`r_survey`) | Armor Works; 520 / 12s |
| BUILDING REPLACE | Heavy Anti-Tank Emplacement | Counterbattery Station | Same strategic building role and prerequisites, changed attributes described below |
**Complete statistics for newly accessible units:**
| Unit (ID) | Tier | HP / armor | Credits / time | Weapon | Active ability / behavior | Available upgrades |
| --- | --- | --- | --- | --- | --- | --- |
| **Stormrail Howitzer** (`r_stormrail`) | T1 | 440 / MEDIUM · Spd 54 | 1,850 / 33s | Precision shell · artillery 265/6s R470 ground; min R140 | Deploy 3.5s; accuracy relies on sight; weak within min range | `ARTY_COMPUTER`, `AR_OBSERVERS`, `AR_RAPID` |
| **Escort Battle Tank** (`r_escort`) | T1 | 680 / MEDIUM · Spd 100 | 1,050 / 20s | Compact cannon · AP 95/2.1s R190 ground | +18% move speed vs Bastion; quick pivot | `ARMOR_PLATING`, `TRACK_DRIVE` |
| **Survey Spotter Drone** (`r_survey`) | T1 | 165 / LIGHT · Spd 141 | 520 / 12s | Unarmed | Detect R180; reveals last known position 4s; artillery mark radius 140, 25s cooldown | `AR_OBSERVERS`, `AA_TRACKING` |
**Exclusive upgrades:** `AR_OBSERVERS`, `AR_RAPID`. **Prohibited upgrades:** `R_REACTIVE`.
**Numeric and mechanical overrides:** 1) Counterbattery Station 2000 credits/24s/−105 power, minimum range 160. 2) Escort Tank is faster and less armored; cannot research Reactive Armor.
**General Powers (rank / cooldown):**
| Unlock rank | Ability | Cooldown | Effect |
| --- | --- | --- | --- |
| Rank 1 | Spotter Recon | 110s | Reveal R230 for 14s; detected target marks remain 4s |
| Rank 3 | Rolling Barrage | 240s | 3 telegraphed artillery salvos across 260 length |
| Rank 5 | Fire Mission Omega | 395s | 5 delayed artillery salvos over R190; unit warning 4s |
**Resolved playable army:** Armored River Monitor, Bastion Missile Cruiser, Industrial Hauler, Line Infantry, Tank Hunter, Combat Engineer, Survey Spotter Drone, Recon APC, Ironclad APC, Flak Carrier, Escort Battle Tank, Stormrail Howitzer, Republic MCV, Siege Helicopter, Heavy Bomber.

#### Fortress Defense (`republic_fortress`)
**Tradeoff:** Slow map control; vulnerable to coordinated artillery and harvester raids.
| Change | Standard slot | This general | Meaning |
| --- | --- | --- | --- |
| REPLACE | Line Infantry (`r_line`) | Garrison Guard (`r_garrison`) | 140 / 5s → 200 / 6s; original unavailable |
| REPLACE | Ironclad APC (`r_ironclad`) | Siege Carrier (`r_siege_carrier`) | 850 / 17s → 1,300 / 25s; original unavailable |
| REMOVE | Recon APC (`r_recon`) | — | Entire unit slot disappears |
| REMOVE | Heavy Bomber (`r_bomber`) | — | Entire unit slot disappears |
| ADD | — | Fortification Engineer (`r_field_engineer`) | Garrison Barracks; 480 / 12s |
| BUILDING REPLACE | Machine-Gun Bunker | Steel Pillbox | Same strategic building role and prerequisites, changed attributes described below |
| BUILDING REPLACE | Fortified Outpost | Forward Bastion | Same strategic building role and prerequisites, changed attributes described below |
**Complete statistics for newly accessible units:**
| Unit (ID) | Tier | HP / armor | Credits / time | Weapon | Active ability / behavior | Available upgrades |
| --- | --- | --- | --- | --- | --- | --- |
| **Garrison Guard** (`r_garrison`) | T0 | 140 / PERSONNEL · Spd 66 | 200 / 6s | Defensive LMG · small arms 14/0.55s R145 ground | In cover +30% damage reduction, +20% range; slower movement | `INF_ARMOR`, `FD_FORTS`, `R_DISCIPLINE` |
| **Siege Carrier** (`r_siege_carrier`) | T1 | 780 / HEAVY · Spd 77 | 1,300 / 25s | Heavy MG · small arms 27/0.55s R190 ground | Carries 5; deploy as immobile protected strongpoint in 3s | `ARMOR_PLATING`, `FD_FIELDWORKS`, `R_REACTIVE` |
| **Fortification Engineer** (`r_field_engineer`) | T1 | 110 / PERSONNEL · Spd 79 | 480 / 12s | Unarmed | Places one temporary 400 HP sandbag barrier for 60s; 35s cooldown; cannot extend build radius | `INF_ARMOR`, `FD_FIELDWORKS` |
**Exclusive upgrades:** `FD_FORTS`, `FD_FIELDWORKS`. **Prohibited upgrades:** none.
**Numeric and mechanical overrides:** 1) Steel Pillbox 800 credits/15s/−5 power; Forward Bastion 1600/25s/−35. 2) Land vehicle move speed −8% except siege carriers; no Heavy Bomber or Recon APC.
**General Powers (rank / cooldown):**
| Unlock rank | Ability | Cooldown | Effect |
| --- | --- | --- | --- |
| Rank 1 | Emergency Fortification | 130s | Place temporary 450 HP sandbags in friendly build area for 45s |
| Rank 3 | Reserve Garrison | 240s | Spawn 5 line-equivalent defenders at owned Barracks/Outpost |
| Rank 5 | Hold the Line | 420s | Area R210 around owned structure: fortification +15% reduction and +6 HP/s repair for 16s; repair costs credits |
**Resolved playable army:** Armored River Monitor, Bastion Missile Cruiser, Industrial Hauler, Garrison Guard, Tank Hunter, Combat Engineer, Flak Carrier, Siege Carrier, Bastion MBT, Thunderbolt Artillery, Fortification Engineer, Mammoth Siege Tank, Republic MCV, Siege Helicopter.

### GIA generals
#### Guerrilla Warfare (`gia_guerrilla`)
**Tradeoff:** No main battle tanks; must defeat armor via rockets and ambush.
| Change | Standard slot | This general | Meaning |
| --- | --- | --- | --- |
| REPLACE | Militia Fighter (`g_militia`) | Shade Cell (`g_shade`) | 100 / 4s → 175 / 6s; original unavailable |
| REPLACE | Raider Technical (`g_technical`) | Ghost Technical (`g_ghost_technical`) | 550 / 12s → 700 / 14s; original unavailable |
| REMOVE | Scavenger Tank (`g_scavenger`) | — | Entire unit slot disappears |
| REMOVE | Reclaimed Assault Tank (`g_reclaimed`) | — | Entire unit slot disappears |
| ADD | — | Hideout Saboteur (`g_saboteur`) | Militia Camp; 700 / 16s |
| BUILDING REPLACE | Gun Nest | Concealed Gun Nest | Same strategic building role and prerequisites, changed attributes described below |
**Complete statistics for newly accessible units:**
| Unit (ID) | Tier | HP / armor | Credits / time | Weapon | Active ability / behavior | Available upgrades |
| --- | --- | --- | --- | --- | --- | --- |
| **Shade Cell** (`g_shade`) | T0 | 80 / PERSONNEL · Spd 95 | 175 / 6s | Silenced rifle · small arms 13/0.75s R135 ground | Cloak after 2s idle/in cover; bonus first shot vs infantry; no tank penetration | `INF_OPTICS`, `GW_CAMO` |
| **Ghost Technical** (`g_ghost_technical`) | T1 | 260 / LIGHT · Spd 155 | 700 / 14s | Concealed MG · small arms 14/0.5s R140 ground | Carries 3; camouflaged at rest; decloaks while firing | `TRACK_DRIVE`, `GW_CAMO`, `GW_PASSAGE` |
| **Hideout Saboteur** (`g_saboteur`) | T2 | 95 / PERSONNEL · Spd 105 | 700 / 16s | Suppressed SMG · small arms 12/0.45s R110 ground | Disable enemy building for 9s on infiltration; 45s cooldown; target alerts opponent | `INF_ARMOR`, `GW_CAMO`, `GW_PASSAGE` |
**Exclusive upgrades:** `GW_CAMO`, `GW_PASSAGE`. **Prohibited upgrades:** none.
**Numeric and mechanical overrides:** 1) Concealed Gun Nest 650 credits/11s/−5 power; lower sustained DPS than standard Gun Nest. 2) Stealth cannot persist through attack, detection or sustained fast movement.
**General Powers (rank / cooldown):**
| Unlock rank | Ability | Cooldown | Effect |
| --- | --- | --- | --- |
| Rank 1 | False Signals | 95s | Creates 2 detectable false radar contacts for 20s |
| Rank 3 | Ambush Cell | 220s | Deploy 4 Shade Cell units in revealed legal brush; 45s duration |
| Rank 5 | Hidden Passage | 400s | Temporary tunnel entrance in legal revealed terrain for 60s; warning on placement |
**Resolved playable army:** Raider Riverboat, Improvised Missile Barge, Shade Cell, Rocket Cell, Salvage Technician, Salvage Collector, Raider Bike, Ghost Technical, Rocket Truck, Rocket Buggy, Improvised Attack Helicopter, Missile Drone Wing, Hideout Saboteur, Shadow Operative, GIA MCV.

#### Missile Warfare (`gia_missile`)
**Tradeoff:** Slow setup and long reloads; no stealth or Shadow Operative.
| Change | Standard slot | This general | Meaning |
| --- | --- | --- | --- |
| REPLACE | Rocket Cell (`g_rocket_cell`) | Siege Rocket Squad (`g_siege_rocket`) | 260 / 8s → 360 / 11s; original unavailable |
| REPLACE | Rocket Buggy (`g_rocket_buggy`) | Volley Launcher (`g_volley`) | 800 / 17s → 1,150 / 24s; original unavailable |
| REMOVE | Shadow Operative (`g_shadow`) | — | Entire unit slot disappears |
| ADD | — | Missile Guidance Van (`g_spotter`) | Salvage Garage; 700 / 16s |
| BUILDING REPLACE | Salvaged AA Platform | Missile Defense Nest | Same strategic building role and prerequisites, changed attributes described below |
**Complete statistics for newly accessible units:**
| Unit (ID) | Tier | HP / armor | Credits / time | Weapon | Active ability / behavior | Available upgrades |
| --- | --- | --- | --- | --- | --- | --- |
| **Siege Rocket Squad** (`g_siege_rocket`) | T0 | 90 / PERSONNEL · Spd 65 | 360 / 11s | Siege rocket · rocket 110/3.8s R235 ground/air | Brace 1.2s to fire; weak while moving; no stealth | `INF_ARMOR`, `MW_GUIDANCE`, `MW_RELOAD` |
| **Volley Launcher** (`g_volley`) | T1 | 300 / LIGHT · Spd 95 | 1,150 / 24s | Volley pod · rocket 62×4/5.5s R350 ground | Stationary 2s setup, long reload, high burst; min R70 | `ARTY_COMPUTER`, `MW_GUIDANCE`, `MW_RELOAD` |
| **Missile Guidance Van** (`g_spotter`) | T1 | 270 / LIGHT · Spd 122 | 700 / 16s | Light MG · small arms 10/0.6s R120 ground | Designate target area R240; allied missiles gain +15% accuracy for 12s; 25s cooldown | `TRACK_DRIVE`, `MW_GUIDANCE` |
**Exclusive upgrades:** `MW_GUIDANCE`, `MW_RELOAD`. **Prohibited upgrades:** `G_CAMO`.
**Numeric and mechanical overrides:** 1) Missile Defense Nest 1100 credits/16s/−55 power; improved AA but limited ground fire. 2) Ballistic Missile Silo can buy 1100-credit Warhead Saturation package to widen AoE but reduce center damage 25%.
**General Powers (rank / cooldown):**
| Unlock rank | Ability | Cooldown | Effect |
| --- | --- | --- | --- |
| Rank 1 | Rocket Recon Beacon | 110s | Marks revealed R160 zone; missile scatter −12% for 14s |
| Rank 3 | Harassing Salvo | 225s | 3 light delayed rocket salvos over R125 |
| Rank 5 | Saturation Strike | 390s | Broad warned guided rocket barrage over R205; weaker center damage than strategic silo |
**Resolved playable army:** Raider Riverboat, Improvised Missile Barge, Militia Fighter, Siege Rocket Squad, Salvage Technician, Salvage Collector, Raider Bike, Raider Technical, Missile Guidance Van, Rocket Truck, Scavenger Tank, Volley Launcher, Improvised Attack Helicopter, Missile Drone Wing, Reclaimed Assault Tank, GIA MCV.

#### Salvage & Mobility (`gia_salvage`)
**Tradeoff:** Weak starting armor, requires contested enemy wrecks for scaling.
| Change | Standard slot | This general | Meaning |
| --- | --- | --- | --- |
| REPLACE | Raider Technical (`g_technical`) | Ripper Technical (`g_ripper`) | 550 / 12s → 625 / 12s; original unavailable |
| REPLACE | Scavenger Tank (`g_scavenger`) | Junker Assault Tank (`g_junker`) | 950 / 19s → 1,000 / 20s; original unavailable |
| REPLACE | Raider Bike (`g_bike`) | Scrap Runner (`g_scraprunner`) | 320 / 7s → 350 / 8s; original unavailable |
| REMOVE | Missile Drone Wing (`g_drone_wing`) | — | Entire unit slot disappears |
| ADD | — | Wreck Recovery Truck (`g_recovery`) | Salvage Garage; 850 / 17s |
| BUILDING REPLACE | Field Workshop | Mobile Salvage Yard | Same strategic building role and prerequisites, changed attributes described below |
**Complete statistics for newly accessible units:**
| Unit (ID) | Tier | HP / armor | Credits / time | Weapon | Active ability / behavior | Available upgrades |
| --- | --- | --- | --- | --- | --- | --- |
| **Ripper Technical** (`g_ripper`) | T1 | 230 / LIGHT · Spd 177 | 625 / 12s | Mounted MG · small arms 16/0.42s R145 ground | +22% speed vs Technical; salvages one nearby enemy wreck; fragile | `TRACK_DRIVE`, `SM_RECOVERY`, `SM_IMPROV` |
| **Junker Assault Tank** (`g_junker`) | T1 | 560 / MEDIUM · Spd 95 | 1,000 / 20s | Scrap cannon · AP 92/2.65s R185 ground | Up to 2 enemy-wreck upgrades; each gives +10% damage OR +10% HP, capped | `ARMOR_PLATING`, `SM_RECOVERY`, `SM_IMPROV` |
| **Scrap Runner** (`g_scraprunner`) | T1 | 145 / LIGHT · Spd 185 | 350 / 8s | Weak carbine · small arms 8/0.42s R105 ground | Rapid wreck pickup; reveal R160; outpaced by dedicated combat scouts | `TRACK_DRIVE`, `SM_RECOVERY` |
| **Wreck Recovery Truck** (`g_recovery`) | T1 | 320 / LIGHT · Spd 115 | 850 / 17s | Unarmed | Repairs nearby friendly vehicles at 20 HP/s while stationary, charges 2 credits/HP; cannot self-repair | `SM_RECOVERY`, `SM_IMPROV` |
**Exclusive upgrades:** `SM_RECOVERY`, `SM_IMPROV`. **Prohibited upgrades:** `G_HEAVY_DEF`.
**Numeric and mechanical overrides:** 1) Mobile Salvage Yard 1050 credits/18s/−30 power; replaces Field Workshop 850/14s/−25. 2) Cannot research Heavy Static Fortification upgrade; retains baseline anti-armor defense.
**General Powers (rank / cooldown):**
| Unlock rank | Ability | Cooldown | Effect |
| --- | --- | --- | --- |
| Rank 1 | Rapid Salvage | 120s | Wreck recovery rate +40% for 18s in R180; value caps remain |
| Rank 3 | Roadside Reinforcements | 250s | 2 Raider-class vehicles enter from viable friendly road/outpost |
| Rank 5 | Scavenger Convoy | 405s | 4 temporary light scavenger vehicles enter at map edge; no free permanent credits |
**Resolved playable army:** Raider Riverboat, Improvised Missile Barge, Militia Fighter, Rocket Cell, Salvage Technician, Salvage Collector, Scrap Runner, Ripper Technical, Rocket Truck, Rocket Buggy, Wreck Recovery Truck, Junker Assault Tank, Improvised Attack Helicopter, Shadow Operative, Reclaimed Assault Tank, GIA MCV.

## 5. Exact variant structure substitutions
Baseline structure costs/times/power from the RA2 Construction & Tech Trees v0.2. This table adds first-pass structural HP and weapon parameters. These replacements inherit the baseline tech prerequisite and construction slot.
| General | Normal structure / stats | Replacement / stats | Weapon, utility, disadvantage |
| --- | --- | --- | --- |
| Alliance Directed Energy | Sentry Turret — 550 / 9s / −10 P / 550 HP | Beam Bastion — 800 / 14s / −45 P / 740 HP | Energy turret: 58/1.1s R230 ground; power shortage: offline |
| Republic Artillery Command | Heavy Anti-Tank Emplacement — 1650 / 19s / −90 P / 1200 HP | Counterbattery Station — 2000 / 24s / −105 P / 960 HP | Artillery: 250/5.6s R480 ground; min R160; needs radar vision |
| Republic Fortress Defense | Machine-Gun Bunker — 550 / 9s / −10 P / 740 HP | Steel Pillbox — 800 / 15s / −5 P / 1120 HP | Heavy MG: 28/0.5s R195 ground; 4 infantry garrison slots |
| Republic Fortress Defense | Fortified Outpost — 1200 / 19s / −25 P / 1350 HP | Forward Bastion — 1600 / 25s / −35 P / 1700 HP | Light autocannon: 24/0.6s R185 ground; adds build-area anchor |
| GIA Guerrilla Warfare | Gun Nest — 550 / 9s / −10 P / 470 HP | Concealed Gun Nest — 650 / 11s / −5 P / 440 HP | MG: 17/0.45s R170 ground; cloaks 4s after firing stops |
| GIA Missile Warfare | Salvaged AA Platform — 950 / 12s / −45 P / 650 HP | Missile Defense Nest — 1100 / 16s / −55 P / 620 HP | AA rocket: 115/2.5s R330 air; ground 35/2.5s R140 |
| GIA Salvage & Mobility | Field Workshop — 850 / 14s / −25 P / 730 HP | Mobile Salvage Yard — 1050 / 18s / −30 P / 650 HP | Repair station: 25 HP/s on one grounded vehicle, charges 2 credits/HP; wreck processing capped |
For unmodified base defenses, the working examples are: Alliance Sentry Turret 20/0.35s R175 anti-personnel; Republic Machine-Gun Bunker 20/0.5s R170; GIA Gun Nest 22/0.55s R165. All use ground-only small arms. Other standard defensive stats still require their separate full building-balance specification.

## 6. How specialist changes interact with build menus, tech and AI
1. Select Standard or one of 3 generals before match. Resolve all patches against the relevant standard roster. Apply general-only changes to combat and upgrades; never mutate the shared catalog.
2. Every replacement inherits the original slot and prerequisite exactly unless an explicit row overrides it. The displayed standard icon is removed, not silently duplicated. Disabled units and upgrades are unbuildable to humans, AI, scripts and resumed saved matches.
3. General-exclusive units have their explicit producer and prerequisite. Army-selection screen must summarize `REPLACES`, `REMOVES`, `ADDS`, and unique research before a player commits.
4. A destroyed prerequisite structure locks **new** orders for dependent units but does not delete existing units. On rebuilding, normal availability returns. Radar loss cannot delete a unit and airfield loss forces aircraft to find another friendly rearm pad or remain unable to reload.
5. Producer limit remains one shared queue per domain, with extra factories accelerating it (as in RA2-first spec). A specialist cannot sidestep these constraints by constructing a second version of a replaced unit.
6. Every faction and general must have basic anti-infantry, anti-vehicle and anti-air; several can replace MBTs with missiles/gunships instead. AI must understand a general’s nonstandard counters and not spam nonexistent units.
7. Aircraft sortie capacity: 2 ready pads/standard Airfield, 3 with Air Superiority Reinforced Hangars; each aircraft has limited ammunition stated in ability and returns to reload. Airfield capacity must not be interpreted as total hard aircraft population cap.
8. Wreck bonus rule: one unique wreck GUID can grant a combat modifier once to a receiving GIA unit. Friendly self-destruction and sell/destroy cycles yield no salvage benefit. This is a combat bonus, not free credits.

## 7. Targeting, costs and combat mathematics — integration detail
**Production:** spend credits proportionally as construction advances. A 1,200-credit 24s tank consumes ~50 credits per second at full speed if income allows. If credits run out, pause; multi-factory construction speed modifies *rate*, not total price. Repair costs come from credits too.
**Damage:** `actual_damage = base_hit × armor_multiplier × weapon_upgrades × veterancy × positional_modifiers × cover_modifiers`. Never multiply continuous weapon entries by fire rate twice; the `/interval` string already states delay between attacks. For splash or multiple projectiles, apply damage per hit and use caps/accuracy appropriately.
**Direct counters:** soft targets require infantry/fire/splash; heavy tanks resist small arms; artillery can bombard defensive lines but has minimum range and deployment cost; rocket infantry pressure armor but must be screened from riflemen; air power has limited munitions, pad dependence and visible AA counters.
**Target acquisition:** respect sight range, sensor visibility, fog, target type (air/land/sea), firing cone and min/max range. Superweapon powers remain separate from weapon firing and must be counterable before impact.
**Map scale:** weapon ranges are in Godot world units, where one logical construction tile = 32 world units. A 205-range tank cannon therefore shoots about 6.4 cells. Tune range alongside pathfinding and camera zoom for readability.
**Speed:** units/second in the table, not animation frame rate. A lightweight scout should arrive before a heavy siege tank across identical paths; vehicles have turning and collision penalties not yet specified.

## 8. Skirmish balance gates before any of this is treated as final
- First 60–90s: deploy MCV, build power, place refinery and observe one automatic harvester exactly once. A viable infantry anti-rush option must exist.
- First 3–4 minutes: both sides can field at least one combat vehicle. No general should depend solely on unavailable late-tech units to stop a T1 attack.
- By 7 minutes: AA is accessible before enemy aircraft can dominate; early interception and missile counter behavior are observable.
- Standard 1v1: 15–25 minutes is a *target median*, not a hard scripted limit. Early all-in rush and late turtle games remain possible.
- Every general passes 1v1 versus its faction standard and faction rivals, economy parity, tank/rocket/AA composition, infantry rushes, raid/defense and power-loss tests.
- Mobile/low-end Android: draw at 60 FPS target with 50v50 initial and scaled 100v100 profiling; no performance guarantee without real-device tests.
- Check 3×3 faction matchups and all **12×11 / 2 = 66 unique unordered army pairings** for counters, not necessarily full AI match simulation on each commit. Include mirror match stress tests separately.
- Validate every unit ID, price, time, armor enum, upgrade reference, producer, general patch target, exact effective roster and serialization. JSON/CSV generated here support the automated checks.

## 9. Earlier design conflicts resolved by this version
This version formalizes **46 baseline unit definitions** (including original naval units and the previously referenced GIA Shadow Operative), **31 specialist-only definitions** (22 replacement units + 9 exclusive additions), **nine general patch sets**, **38 research upgrades** and all named general powers. Previous docs intentionally left unit statistics unresolved; these are initial numbers for simulation and review, **not approved balance**. Construction stays Red Alert 2-first; army differentiation stays Zero Hour-first. If earlier documents mention a unit unavailable here, keep that name only as an unapproved idea until explicitly added to the registry.

## 10. Design / IP note and background
References for rules, not asset copying: [RA2 manual](https://www.manualshelf.com/manual/games-pc/command-conquer-red-alert-2/user-guide-english.html); [Zero Hour USA General faction comparison](https://www.cnclabs.com/generals/zerohour/factions/usa/generals.aspx); [Zero Hour GLA General comparisons](https://www.cnclabs.com/generals/zerohour/factions/gla/generals.aspx); [existing WebRTS faction buildings](https://github.com/AlmightyTank/WebRTS/blob/main/docs/FACTION-BUILDING-ROSTER-1.0.md). We are making original factions, original technology, original geometry and original unit names. Balance values here are not copied from these games.
