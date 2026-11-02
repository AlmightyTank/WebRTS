extends RefCounted
## Skirmish map list. Meridian Basin is the live board: the same cliffs, iron, relay and deployments the match already uses.
const MAPS := {
 "meridian_basin": {
  "name": "Meridian Basin",
  "summary": "West and east deployments. Iron on both flanks. A neutral relay holds the north.",
  "board": Rect2(0, 0, 1920, 1200),
  "spawns": {"west": Vector2(310, 620), "east": Vector2(1600, 610)},
  "ore": [
   {"position": Vector2(630, 330), "amount": 7200.0},
   {"position": Vector2(580, 930), "amount": 6000.0},
   {"position": Vector2(1320, 820), "amount": 7200.0},
   {"position": Vector2(1370, 150), "amount": 6000.0},
   {"position": Vector2(1080, 1010), "amount": 5500.0}
  ],
  # Same rectangles as the battlefield's fixed outcrops.
  "cliffs": [
   Rect2(840, 120, 92, 285),
   Rect2(840, 565, 92, 270),
   Rect2(1050, 430, 150, 100),
   Rect2(375, 825, 155, 95),
   Rect2(1430, 220, 105, 95)
  ],
  "relay": Vector2(1080, 225)
 }
}
const STARTS := ["west", "east", "random"]

static func ids() -> PackedStringArray:
 var result := PackedStringArray()
 for id in MAPS.keys():
  result.append(str(id))
 return result

static func get_map(id: String) -> Dictionary:
 return MAPS[id] if MAPS.has(id) else MAPS["meridian_basin"]

static func spawn_label(slot: String) -> String:
 match slot:
  "west": return "1  West"
  "east": return "2  East"
  _: return "Random"

static func point(map_id: String, slot: String) -> Vector2:
 var spawns: Dictionary = get_map(map_id)["spawns"]
 return spawns[slot] if spawns.has(slot) else spawns["west"]

static func display_slots(slots: Array) -> Array:
 var first := str(slots[0]) if slots.size() > 0 else "random"
 var second := str(slots[1]) if slots.size() > 1 else "random"
 if not _explicit(first) and not _explicit(second):
  return ["random", "random"]
 var rng := RandomNumberGenerator.new()
 rng.seed = 1
 return resolve_slots(slots, rng)

static func resolve_slots(slots: Array, rng: RandomNumberGenerator = null) -> Array:
 var roll := rng
 if roll == null:
  roll = RandomNumberGenerator.new()
  roll.randomize()
 var pool: Array[String] = ["west", "east"]
 var result: Array[String] = ["", ""]
 for side in range(mini(2, slots.size())):
  var pick := str(slots[side])
  if pick in pool:
   result[side] = pick
   pool.erase(pick)
 for side in range(2):
  if result[side] != "":
   continue
  if pool.is_empty():
   result[side] = "west" if side == 0 else "east"
  else:
   var index := 0 if pool.size() == 1 else roll.randi_range(0, pool.size() - 1)
   result[side] = pool[index]
   pool.remove_at(index)
 return result

static func _explicit(slot: String) -> bool:
 return slot == "west" or slot == "east"
