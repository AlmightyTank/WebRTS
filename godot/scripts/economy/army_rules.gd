extends RefCounted
## Resolved armies: replacements inherit ordinary production slots, never General Points.
const CHOICES := {
 "alliance": {"name":"Alliance — Standard", "faction":"alliance", "summary":"Flexible combined arms. Precise tanks, missile infantry and mobile AA."},
 "alliance_energy": {"name":"Vale — Lattice Command", "faction":"alliance", "summary":"Arc Lance, Lattice Interceptor and Beam Bastion. Powered energy +10%; shortage halves fire rate. Grid research and orbital support."},
 "alliance_air": {"name":"Voss — Sky Command", "faction":"alliance", "summary":"Tempest replaces the Striker. No Sentinel tank. Aircraft cost +10%. Hangar research and warned air strikes."},
 "alliance_ghost": {"name":"Rook — Ghost Command", "faction":"alliance", "summary":"Pathfinders replace Rangers. A Ghost Carrier and the Ghost Operations Node detect hidden units. Stealth breaks on fire, damage, and detectors."},
 "republic": {"name":"Republic — Standard", "faction":"republic", "summary":"Durable, slower armor. Heavy tanks cost more and take longer to field."},
 "republic_armor": {"name":"Korda — Steel Vanguard", "faction":"republic", "summary":"Juggernaut, Imperator, Armored Scout and Vanguard Foundry. Tanks +10% HP; aircraft +20% cost. Veteran crews and armor support."},
 "republic_artillery": {"name":"Orlov — Longbow Command", "faction":"republic", "summary":"Stormrail replaces the Mammoth. Escort tank replaces the Bastion. Longer range, two-second setup, and warned barrages."},
 "republic_fortress": {"name":"Volkov — Bastion Command", "faction":"republic", "summary":"Garrison Guards, a Siege Carrier that deploys, and a Steel Pillbox. Defenses have more health and take longer to build."},
 "gia": {"name":"GIA — Standard", "faction":"gia", "summary":"Cheap mobile pressure; fragile vehicles need flanks and missile support."},
 "gia_guerrilla": {"name":"Nadir — Shadow Front", "faction":"gia", "summary":"Shade Cells and a Ghost Technical. No Scavenger tank. The Concealed Gun Nest stays hidden until it fires."},
 "gia_missile": {"name":"Sayegh — Saturation Command", "faction":"gia", "summary":"Siege Rocket Squad, Volley and AA-only Missile Nest. Signature missiles reload 10% faster, move 10% slower. Recon and warned saturation strikes."},
 "gia_salvage": {"name":"Varek — Wreckrunner Command", "faction":"gia", "summary":"Junker replaces the Scavenger and starts weaker. Light raiders are faster. Kills add up to two salvage tiers."}
}
const ROSTERS := {
 "alliance":["a_ranger","a_javelin","a_engineer","a_sentinel","a_sentinel_aa","a_striker","a_harvester","a_mcv"],
  "republic":["r_line","r_hunter","r_engineer","r_bastion","r_flak","r_mammoth","r_siege_heli","r_hauler","r_mcv","r_recon"],
 "gia":["g_militia","g_rocket_cell","g_tech","g_scavenger","g_rocket_truck","g_rocket_buggy","g_heli","g_collector","g_mcv"]
}
const REPLACEMENTS := {
 "alliance_energy":{"a_sentinel":"a_lance","a_sentinel_aa":"a_lattice","turret":"beam_bastion"},
 "alliance_air":{"a_striker":"a_tempest"},
 "republic_armor":{"r_bastion":"r_jugger","r_mammoth":"r_imperator","r_recon":"r_armored_scout","foundry":"vanguard_foundry"},
 "republic_artillery":{"r_bastion":"r_escort","r_mammoth":"r_stormrail"},
 "gia_missile":{"g_rocket_cell":"g_siege_rocket","g_rocket_buggy":"g_volley","salvaged_aa":"missile_nest"},
 "gia_salvage":{"g_scavenger":"g_junker"},
 "alliance_ghost":{"a_ranger":"a_pathfinder","depot":"ghost_node"},
 "republic_fortress":{"r_line":"r_garrison","r_recon":"r_siege_carrier","turret":"pillbox"},
 "gia_guerrilla":{"g_militia":"g_shade","g_scavenger":"g_ghost_technical","turret":"concealed_nest"}
}
const EXTRAS := {"alliance_ghost":["a_ghost_carrier"]}
const DISABLED := {"alliance_energy":["a_howitzer"],"alliance_air":["a_sentinel"],"republic_armor":["r_thunder"],"gia_missile":["g_shadow","camo_netting"],"alliance_ghost":["a_howitzer"]}
# Stationary cloak delay in seconds. Firing, damage, and a detector break it.
const CLOAK := {
 "a_pathfinder":{"delay":3.0,"detect":200.0},
 "a_ghost_carrier":{"delay":3.0,"detect":0.0},
 "g_shade":{"delay":3.0,"detect":0.0},
 "g_ghost_technical":{"delay":3.0,"detect":0.0}
}
const GHOST_NODE_DETECT := 240.0
const FORTRESS_DEFENSES := ["pillbox","wall","gate","sam","turret"]
const FORTRESS_BONUS := 1.15
const SIGNATURE_MISSILES := ["g_siege_rocket","g_volley"]
const STEEL_TANKS := ["r_jugger","r_imperator"]
const LIGHT_RAIDERS := ["g_rocket_truck","g_rocket_buggy","g_heli"]
# Salvos per sortie. A dry aircraft cannot fire until a powered airfield rearms it.
const SORTIES := {"a_striker":4,"a_tempest":6,"r_siege_heli":6,"g_heli":4}
const REARM_SECONDS := 8.0
# Perimeter segments. Republic is the tough line. GIA is cheap and fragile. Gates share that health.
const PERIMETER := {
 "alliance": {
  "wall": {"name":"Energy-Reinforced Barrier","cost":100.0,"time":6.0,"hp":600.0},
  "gate": {"name":"Security Gate","cost":180.0,"time":8.0,"hp":600.0}
 },
 "republic": {
  "wall": {"name":"Reinforced Concrete Wall","cost":150.0,"time":8.0,"hp":1200.0},
  "gate": {"name":"Fortress Gate","cost":250.0,"time":10.0,"hp":1200.0}
 },
 "gia": {
  "wall": {"name":"Scrap Barricade","cost":50.0,"time":4.0,"hp":280.0},
  "gate": {"name":"Checkpoint Gate","cost":90.0,"time":5.0,"hp":280.0}
 }
}
static func structure_ids(choice: String) -> Array:
 var ids: Array = ["power","refinery","barracks","factory","airfield","depot","turret","wall","gate"]
 ids.append("salvaged_aa" if faction(choice)=="gia" else "sam")
 if faction(choice)=="republic": ids.append("foundry")
 if faction(choice)=="gia": ids.append("silo")
 elif faction(choice)=="alliance": ids.append("beam_array")
 elif faction(choice)=="republic": ids.append("ironstorm")
 var mapping: Dictionary = REPLACEMENTS.get(choice,{})
 return ids.map(func(id): return mapping.get(id,id)).filter(func(id): return id not in DISABLED.get(choice,[]))
const PROFILES := {
 "g_militia":{"type":"SMALL_ARMS","damage":9.0,"interval":0.6,"range":135.0,"projectile_speed":660.0},
 "g_rocket_cell":{"type":"ROCKET","damage":68.0,"interval":3.0,"range":215.0,"projectile_speed":285.0,"homing":true,"anti_air":true},
 "g_scavenger":{"type":"AP","damage":90.0,"interval":2.5,"range":190.0,"projectile_speed":450.0},
 "g_rocket_truck":{"type":"AA","damage":65.0,"interval":1.8,"range":280.0,"projectile_speed":360.0,"homing":true,"anti_air":true,"anti_ground":false},
 "g_rocket_buggy":{"type":"ROCKET","damage":80.0,"interval":2.8,"range":260.0,"min_range":65.0,"projectile_speed":330.0,"homing":true},
 "g_heli":{"type":"ROCKET","damage":55.0,"interval":1.6,"range":200.0,"projectile_speed":350.0,"homing":true},
 "a_lance":{"type":"ENERGY","damage":100.0,"interval":1.9,"range":220.0,"projectile_speed":850.0,"grid_energy":true},
 "a_lattice":{"type":"ENERGY","damage":24.0,"air_damage":45.0,"interval":0.6,"range":260.0,"ground_range":140.0,"projectile_speed":850.0,"anti_air":true,"grid_energy":true},
 "r_jugger":{"type":"AP","damage":165.0,"interval":2.7,"range":205.0,"projectile_speed":460.0},
 "r_recon":{"type":"SMALL_ARMS","damage":15.0,"interval":0.5,"range":140.0,"projectile_speed":620.0},
 "r_armored_scout":{"type":"SMALL_ARMS","damage":18.0,"interval":0.5,"range":140.0,"projectile_speed":620.0},
 "g_siege_rocket":{"type":"ROCKET","damage":110.0,"interval":3.8,"range":235.0,"projectile_speed":285.0,"homing":true,"anti_air":true,"brace":1.2},
 "r_mammoth":{"type":"AP","damage":210.0,"interval":3.5,"range":220.0,"projectile_speed":430.0},
 "r_imperator":{"type":"AP","damage":245.0,"interval":3.7,"range":225.0,"projectile_speed":430.0},
 "g_volley":{"type":"ROCKET","damage":125.0,"interval":3.2,"range":285.0,"min_range":80.0,"projectile_speed":320.0,"homing":true},
 "a_tempest":{"type":"ROCKET","damage":110.0,"interval":1.65,"range":230.0,"projectile_speed":350.0,"homing":true},
 "r_escort":{"type":"AP","damage":95.0,"interval":2.1,"range":190.0,"projectile_speed":460.0},
 "r_stormrail":{"type":"AP","damage":160.0,"interval":6.0,"range":400.0,"min_range":140.0,"projectile_speed":280.0,"brace":2.0},
 "g_junker":{"type":"AP","damage":92.0,"interval":2.65,"range":185.0,"projectile_speed":420.0},
 "a_pathfinder":{"type":"SMALL_ARMS","damage":35.0,"interval":1.7,"range":205.0,"projectile_speed":700.0},
 "a_ghost_carrier":{"type":"SMALL_ARMS","damage":14.0,"interval":0.6,"range":150.0,"projectile_speed":660.0},
 "r_garrison":{"type":"SMALL_ARMS","damage":14.0,"interval":0.55,"range":145.0,"projectile_speed":660.0},
 "r_siege_carrier":{"type":"SMALL_ARMS","damage":27.0,"interval":0.55,"range":190.0,"projectile_speed":660.0},
 "g_shade":{"type":"SMALL_ARMS","damage":13.0,"interval":0.75,"range":135.0,"projectile_speed":660.0},
 "g_ghost_technical":{"type":"SMALL_ARMS","damage":14.0,"interval":0.5,"range":140.0,"projectile_speed":660.0}
}
const EXTRA_UNITS := {
 "a_pathfinder":{"id":"a_pathfinder","name":"Pathfinder Team","armor":"PERSONNEL","hp":90.0,"credits":260.0,"build_seconds":8.0,"speed":83.0},
 "a_ghost_carrier":{"id":"a_ghost_carrier","name":"Ghost Recon Carrier","armor":"LIGHT","hp":295.0,"credits":950.0,"build_seconds":18.0,"speed":130.0},
 "r_garrison":{"id":"r_garrison","name":"Garrison Guard","armor":"PERSONNEL","hp":140.0,"credits":200.0,"build_seconds":6.0,"speed":66.0},
 "r_siege_carrier":{"id":"r_siege_carrier","name":"Siege Carrier","armor":"HEAVY","hp":780.0,"credits":1300.0,"build_seconds":25.0,"speed":77.0},
 "g_shade":{"id":"g_shade","name":"Shade Cell","armor":"PERSONNEL","hp":80.0,"credits":175.0,"build_seconds":6.0,"speed":95.0},
 "g_ghost_technical":{"id":"g_ghost_technical","name":"Ghost Technical","armor":"LIGHT","hp":260.0,"credits":700.0,"build_seconds":14.0,"speed":155.0}
}

static func valid_choice(id: String) -> String:
 return id if CHOICES.has(id) else "alliance"

static func faction(choice: String) -> String:
 return CHOICES[valid_choice(choice)].faction

static func roster_ids(choice: String) -> Array:
 var result: Array = []
 var replacements: Dictionary = REPLACEMENTS.get(choice, {})
 for id in ROSTERS[faction(choice)]:
  var resolved: String=replacements.get(id,id)
  if resolved not in DISABLED.get(choice,[]): result.append(resolved)
 for id in EXTRAS.get(choice, []):
  if id not in result and id not in DISABLED.get(choice, []): result.append(id)
 return result

static func base_id(id: String) -> String:
 for mapping in REPLACEMENTS.values():
  for original in mapping:
   if mapping[original] == id: return original
 return id

static func economic_id(choice: String, harvester: bool = false) -> String:
 var prefix: String = {"alliance":"a", "republic":"r", "gia":"g"}[faction(choice)]
 return {"a":"a_harvester","r":"r_hauler","g":"g_collector"}[prefix] if harvester else prefix + "_mcv"

static func engineer(id: String) -> bool:
 return id in ["a_engineer","r_engineer","g_tech"]

static func economic(id: String) -> bool:
 return id in ["a_mcv","r_mcv","g_mcv","a_harvester","r_hauler","g_collector"]

static func lane(id: String, data: Dictionary) -> String:
 if data.get("armor", "") == "AIR": return "air"
 return "infantry" if data.get("armor", "") == "PERSONNEL" else "vehicle"

static func sortie_count(id: String) -> int:
 return int(SORTIES.get(id, 0))

static func rearm_seconds(choice: String) -> float:
 return REARM_SECONDS * (0.85 if choice == "alliance_air" else 1.0)

static func perimeter(choice: String, id: String) -> Dictionary:
 return PERIMETER[faction(choice)][id]

static func fortress_defense(choice: String, id: String) -> bool:
 return choice=="republic_fortress" and id in FORTRESS_DEFENSES

static func cost_factor(choice: String, data: Dictionary) -> float:
 if choice == "republic_armor" and data.get("armor", "") == "AIR": return 1.2
 if choice == "alliance_air" and data.get("armor", "") == "AIR": return 1.1
 if choice == "alliance_ghost" and str(data.get("id",""))=="a_pathfinder": return 1.15
 return 1.0

static func apply_unit(choice: String, unit) -> void:
 if choice == "republic_armor" and unit.unit_id in STEEL_TANKS:
  unit.max_hp *= 1.1
  unit.hp = unit.max_hp
 if choice == "gia_missile" and unit.unit_id in SIGNATURE_MISSILES:
  unit.move_speed *= 0.9
  unit.weapon.interval *= 0.9
 if choice == "gia_salvage" and unit.unit_id == "g_junker":
  unit.max_hp *= 0.9
  unit.hp = unit.max_hp
 if choice == "gia_salvage" and unit.unit_id in LIGHT_RAIDERS:
  unit.move_speed *= 1.1
 if choice == "gia_guerrilla" and unit.unit_id == "g_ghost_technical":
  unit.max_hp *= 0.9
  unit.hp = unit.max_hp
