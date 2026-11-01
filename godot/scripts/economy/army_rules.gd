extends RefCounted
## Supported vertical slice; advanced doctrines are deliberately not selectable.
const CHOICES := {
 "alliance": {"name":"Alliance — Standard", "faction":"alliance", "summary":"Flexible combined arms. Precise tanks, missile infantry and mobile AA."},
 "alliance_energy": {"name":"Vale — Lattice Command", "faction":"alliance", "summary":"Arc Lance replaces Sentinel. Energy damage +10% with adequate power; half fire rate during shortage."},
 "republic": {"name":"Republic — Standard", "faction":"republic", "summary":"Durable, slower armor. Heavy tanks cost more and take longer to field."},
 "republic_armor": {"name":"Korda — Steel Vanguard", "faction":"republic", "summary":"Imperator replaces Mammoth. Mainline/heavy tanks +10% HP; aircraft cost +20%."},
 "gia": {"name":"GIA — Standard", "faction":"gia", "summary":"Cheap mobile pressure; fragile vehicles need flanks and missile support."},
 "gia_missile": {"name":"Sayegh — Saturation Command", "faction":"gia", "summary":"Volley replaces Rocket Buggy. Volley reloads 10% faster but moves 10% slower."}
}
const ROSTERS := {
 "alliance":["a_ranger","a_javelin","a_engineer","a_sentinel","a_sentinel_aa","a_striker","a_harvester","a_mcv"],
 "republic":["r_line","r_hunter","r_engineer","r_bastion","r_flak","r_mammoth","r_siege_heli","r_hauler","r_mcv"],
 "gia":["g_militia","g_rocket_cell","g_tech","g_scavenger","g_rocket_truck","g_rocket_buggy","g_heli","g_collector","g_mcv"]
}
const REPLACEMENTS := {"alliance_energy":{"a_sentinel":"a_lance"}, "republic_armor":{"r_mammoth":"r_imperator"}, "gia_missile":{"g_rocket_buggy":"g_volley"}}
const PROFILES := {
 "g_militia":{"type":"SMALL_ARMS","damage":9.0,"interval":0.6,"range":135.0,"projectile_speed":660.0},
 "g_rocket_cell":{"type":"ROCKET","damage":68.0,"interval":3.0,"range":215.0,"projectile_speed":285.0,"homing":true,"anti_air":true},
 "g_scavenger":{"type":"AP","damage":90.0,"interval":2.5,"range":190.0,"projectile_speed":450.0},
 "g_rocket_truck":{"type":"AA","damage":65.0,"interval":1.8,"range":280.0,"projectile_speed":360.0,"homing":true,"anti_air":true,"anti_ground":false},
 "g_rocket_buggy":{"type":"ROCKET","damage":80.0,"interval":2.8,"range":260.0,"min_range":65.0,"projectile_speed":330.0,"homing":true},
 "g_heli":{"type":"ROCKET","damage":55.0,"interval":1.6,"range":200.0,"projectile_speed":350.0,"homing":true},
 "a_lance":{"type":"ENERGY","damage":100.0,"interval":1.9,"range":220.0,"projectile_speed":850.0,"grid_energy":true},
 "r_mammoth":{"type":"AP","damage":210.0,"interval":3.5,"range":220.0,"projectile_speed":430.0},
 "r_imperator":{"type":"AP","damage":245.0,"interval":3.7,"range":225.0,"projectile_speed":430.0},
 "g_volley":{"type":"ROCKET","damage":125.0,"interval":3.2,"range":285.0,"min_range":80.0,"projectile_speed":320.0,"homing":true}
}

static func valid_choice(id: String) -> String:
 return id if CHOICES.has(id) else "alliance"

static func faction(choice: String) -> String:
 return CHOICES[valid_choice(choice)].faction

static func roster_ids(choice: String) -> Array:
 var result: Array = []
 var replacements: Dictionary = REPLACEMENTS.get(choice, {})
 for id in ROSTERS[faction(choice)]: result.append(replacements.get(id, id))
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
 return "infantry" if data.get("armor", "") == "PERSONNEL" else "vehicle"

static func cost_factor(choice: String, data: Dictionary) -> float:
 return 1.2 if choice == "republic_armor" and data.get("armor", "") == "AIR" else 1.0

static func apply_unit(choice: String, unit) -> void:
 if choice == "republic_armor" and unit.unit_id in ["r_bastion","r_imperator"]:
  unit.max_hp *= 1.1
  unit.hp = unit.max_hp
 if choice == "gia_missile" and unit.unit_id == "g_volley":
  unit.move_speed *= 0.9
  unit.weapon.interval *= 0.9
