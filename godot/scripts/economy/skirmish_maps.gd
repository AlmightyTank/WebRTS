extends RefCounted
## Skirmish map list. Every board uses the same schema: two starts, iron, cliffs, one relay.
## Sizes are multiples of the 48px navigation cell. Meridian Basin stays the original layout.
const MAPS := {
 "meridian_basin": {
  "name": "Meridian Basin",
  "summary": "West and east deployments. Iron on both flanks. A neutral relay holds the north.",
  "board": Rect2(0, 0, 1920, 1200),
  "seed": 77341,
  "spawns": {"west": Vector2(310, 620), "east": Vector2(1600, 610)},
  "ore": [
   {"position": Vector2(630, 330), "amount": 7200.0},
   {"position": Vector2(580, 930), "amount": 6000.0},
   {"position": Vector2(1320, 820), "amount": 7200.0},
   {"position": Vector2(1370, 150), "amount": 6000.0},
   {"position": Vector2(1080, 1010), "amount": 5500.0}
  ],
  "cliffs": [
   Rect2(840, 120, 92, 285),
   Rect2(840, 565, 92, 270),
   Rect2(1050, 430, 150, 100),
   Rect2(375, 825, 155, 95),
   Rect2(1430, 220, 105, 95)
  ],
  "relay": Vector2(1080, 225)
 },
 "cutter_gap": {
  "name": "Cutter Gap",
  "summary": "A broken ridge leaves one crossing. The relay sits on the west side of that gap.",
  "board": Rect2(0, 0, 1920, 1200),
  "seed": 12011,
  "spawns": {"west": Vector2(300, 640), "east": Vector2(1620, 640)},
  "ore": [
   {"position": Vector2(420, 260), "amount": 6800.0},
   {"position": Vector2(400, 1020), "amount": 6800.0},
   {"position": Vector2(1500, 280), "amount": 6800.0},
   {"position": Vector2(1520, 1000), "amount": 6800.0},
   {"position": Vector2(1200, 180), "amount": 7600.0}
  ],
  "cliffs": [
   Rect2(900, 0, 130, 400),
   Rect2(900, 800, 130, 400)
  ],
  "relay": Vector2(740, 640)
 },
 "salt_flats": {
  "name": "Salt Flats",
  "summary": "Open ground. Iron sits in a ring, and the relay is the north prize.",
  "board": Rect2(0, 0, 1920, 1200),
  "seed": 12017,
  "spawns": {"west": Vector2(340, 600), "east": Vector2(1580, 600)},
  "ore": [
   {"position": Vector2(560, 240), "amount": 7000.0},
   {"position": Vector2(560, 1000), "amount": 7000.0},
   {"position": Vector2(1360, 240), "amount": 7000.0},
   {"position": Vector2(1360, 1000), "amount": 7000.0},
   {"position": Vector2(960, 1040), "amount": 5600.0}
  ],
  "cliffs": [
   Rect2(760, 430, 70, 60),
   Rect2(1080, 760, 80, 70),
   Rect2(470, 780, 60, 50)
  ],
  "relay": Vector2(960, 180)
 },
 "shelf_road": {
  "name": "Shelf Road",
  "summary": "A wider field. The north shelf holds the relay, with one ramp through the lip.",
  "board": Rect2(0, 0, 2880, 1680),
  "seed": 12023,
  "spawns": {"west": Vector2(420, 1100), "east": Vector2(2460, 1100)},
  "ore": [
   {"position": Vector2(500, 1420), "amount": 8000.0},
   {"position": Vector2(620, 860), "amount": 6200.0},
   {"position": Vector2(2300, 1420), "amount": 8000.0},
   {"position": Vector2(2200, 860), "amount": 6200.0},
   {"position": Vector2(1440, 420), "amount": 9000.0},
   {"position": Vector2(1440, 980), "amount": 7000.0}
  ],
  "cliffs": [
   Rect2(160, 620, 980, 90),
   Rect2(1560, 620, 1160, 90)
  ],
  "relay": Vector2(1440, 260)
 },
 "twin_fords": {
  "name": "Twin Fords",
  "summary": "A wider field split by a broken ridge. Two fords. The relay watches the north one.",
  "board": Rect2(0, 0, 2880, 1680),
  "seed": 12029,
  "spawns": {"west": Vector2(420, 840), "east": Vector2(2460, 840)},
  "ore": [
   {"position": Vector2(560, 280), "amount": 7500.0},
   {"position": Vector2(560, 1460), "amount": 7500.0},
   {"position": Vector2(2320, 280), "amount": 7500.0},
   {"position": Vector2(2320, 1460), "amount": 7500.0},
   {"position": Vector2(1680, 1220), "amount": 8800.0}
  ],
  "cliffs": [
   Rect2(1320, 40, 140, 520),
   Rect2(1320, 860, 140, 240),
   Rect2(1320, 1360, 140, 280)
  ],
  "relay": Vector2(1100, 700)
 },
 "scrap_mile": {
  "name": "Scrap Mile",
  "summary": "A wider field. Staggered ruins make the drive weave. The relay is north of the mile.",
  "board": Rect2(0, 0, 2880, 1680),
  "seed": 12037,
  "spawns": {"west": Vector2(380, 840), "east": Vector2(2500, 840)},
  "ore": [
   {"position": Vector2(460, 1320), "amount": 7200.0},
   {"position": Vector2(860, 360), "amount": 6400.0},
   {"position": Vector2(1440, 1320), "amount": 8200.0},
   {"position": Vector2(1760, 400), "amount": 6400.0},
   {"position": Vector2(2360, 1320), "amount": 7200.0},
   {"position": Vector2(1180, 520), "amount": 6000.0}
  ],
  "cliffs": [
   Rect2(640, 180, 150, 360),
   Rect2(680, 1080, 150, 420),
   Rect2(1500, 160, 160, 280),
   Rect2(1240, 1100, 180, 400),
   Rect2(1900, 240, 160, 340),
   Rect2(1860, 1180, 170, 360)
  ],
  "relay": Vector2(1180, 320)
 },
 "amber_reach": {
  "name": "Amber Reach",
  "summary": "A large field. Starts sit in opposite corners, with two fords toward a center relay.",
  "board": Rect2(0, 0, 3840, 2160),
  "seed": 12041,
  "spawns": {"west": Vector2(560, 1720), "east": Vector2(3280, 440)},
  "ore": [
   {"position": Vector2(700, 1960), "amount": 9000.0},
   {"position": Vector2(1100, 1480), "amount": 7000.0},
   {"position": Vector2(1920, 820), "amount": 8000.0},
   {"position": Vector2(3000, 680), "amount": 7000.0},
   {"position": Vector2(3180, 240), "amount": 9000.0},
   {"position": Vector2(2500, 1760), "amount": 8000.0},
   {"position": Vector2(1600, 360), "amount": 6000.0}
  ],
  "cliffs": [
   Rect2(980, 280, 180, 420),
   Rect2(1500, 860, 200, 360),
   Rect2(2100, 1280, 200, 380),
   Rect2(2680, 1560, 180, 360),
   Rect2(700, 900, 120, 100),
   Rect2(3000, 1100, 140, 120)
  ],
  "relay": Vector2(1920, 1080)
 },
 "glass_canyon": {
  "name": "Glass Canyon",
  "summary": "A large field. North and south lanes run past a broken center wall. The relay is in the north lane.",
  "board": Rect2(0, 0, 3840, 2160),
  "seed": 12043,
  "spawns": {"west": Vector2(520, 1080), "east": Vector2(3320, 1080)},
  "ore": [
   {"position": Vector2(560, 1680), "amount": 8000.0},
   {"position": Vector2(560, 420), "amount": 8000.0},
   {"position": Vector2(3280, 1680), "amount": 8000.0},
   {"position": Vector2(3280, 420), "amount": 8000.0},
   {"position": Vector2(1920, 520), "amount": 7000.0},
   {"position": Vector2(1920, 1560), "amount": 9000.0}
  ],
  "cliffs": [
   Rect2(700, 760, 1000, 140),
   Rect2(2100, 760, 1100, 140)
  ],
  "relay": Vector2(1920, 340)
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
