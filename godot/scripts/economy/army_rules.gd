extends RefCounted
## Resolved armies: replacements inherit ordinary production slots, never General Points.
const CHOICES := {
 "alliance": {"name":"Alliance — Standard", "faction":"alliance", "summary":"Flexible combined arms. Precise tanks, missile infantry and mobile AA."},
 "alliance_energy": {"name":"Vale — Lattice Command", "faction":"alliance", "summary":"Arc Lance, Lattice Interceptor and Beam Bastion. Powered energy +10%; shortage halves fire rate. Grid research and orbital support."},
 "republic": {"name":"Republic — Standard", "faction":"republic", "summary":"Durable, slower armor. Heavy tanks cost more and take longer to field."},
 "republic_armor": {"name":"Korda — Steel Vanguard", "faction":"republic", "summary":"Juggernaut, Imperator, Armored Scout and Vanguard Foundry. Tanks +10% HP; aircraft +20% cost. Veteran crews and armor support."},
 "gia": {"name":"GIA — Standard", "faction":"gia", "summary":"Cheap mobile pressure; fragile vehicles need flanks and missile support."},
 "gia_missile": {"name":"Sayegh — Saturation Command", "faction":"gia", "summary":"Siege Rocket Squad, Volley and AA-only Missile Nest. Signature missiles reload 10% faster, move 10% slower. Recon and warned saturation strikes."}
}
const ROSTERS := {
 "alliance":["a_ranger","a_javelin","a_engineer","a_sentinel","a_sentinel_aa","a_striker","a_harvester","a_mcv"],
  "republic":["r_line","r_hunter","r_engineer","r_bastion","r_flak","r_mammoth","r_siege_heli","r_hauler","r_mcv","r_recon"],
 "gia":["g_militia","g_rocket_cell","g_tech","g_scavenger","g_rocket_truck","g_rocket_buggy","g_heli","g_collector","g_mcv"]
}
const REPLACEMENTS := {"alliance_energy":{"a_sentinel":"a_lance","a_sentinel_aa":"a_lattice","turret":"beam_bastion"}, "republic_armor":{"r_bastion":"r_jugger","r_mammoth":"r_imperator","r_recon":"r_armored_scout","foundry":"vanguard_foundry"}, "gia_missile":{"g_rocket_cell":"g_siege_rocket","g_rocket_buggy":"g_volley","salvaged_aa":"missile_nest"}}
const DISABLED := {"alliance_energy":["a_howitzer"],"republic_armor":["r_thunder"],"gia_missile":["g_shadow","camo_netting"]}
const SIGNATURE_MISSILES := ["g_siege_rocket","g_volley"]
const STEEL_TANKS := ["r_jugger","r_imperator"]
static func structure_ids(choice: String) -> Array:
 var ids: Array = ["power","refinery","barracks","factory","depot","turret"]
 ids.append("salvaged_aa" if faction(choice)=="gia" else "sam")
 if faction(choice)=="republic": ids.append("foundry")
 if faction(choice)=="gia": ids.append("silo")
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
 "g_volley":{"type":"ROCKET","damage":125.0,"interval":3.2,"range":285.0,"min_range":80.0,"projectile_speed":320.0,"homing":true}
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
 if choice == "republic_armor" and unit.unit_id in STEEL_TANKS:
  unit.max_hp *= 1.1
  unit.hp = unit.max_hp
 if choice == "gia_missile" and unit.unit_id in SIGNATURE_MISSILES:
  unit.move_speed *= 0.9
  unit.weapon.interval *= 0.9
