extends RefCounted
## Shared FIFO for combat actors, harvesters and MCVs.
static func enqueue(actor, point: Vector2, attack_move: bool) -> void:
 actor.pending_orders.append({"point": point, "attack_move": attack_move})
 if not actor.moving and actor.target == null:
  advance(actor)

static func advance(actor) -> void:
 if actor.pending_orders.is_empty():
  return
 var next: Dictionary = actor.pending_orders.pop_front()
 var remaining: Array = actor.pending_orders.duplicate()
 actor.order_move(next["point"], next["attack_move"])
 actor.pending_orders = remaining

static func draw_route(actor) -> void:
 if not actor.selected:
  return
 var previous: Vector2 = actor.position
 if actor.moving:
  actor.draw_line(Vector2.ZERO, actor.destination - actor.position, Color("#e8cd78"), 1.0)
  actor.draw_circle(actor.destination - actor.position, 5.0, Color("#e8cd78"), false, 1.5)
  previous = actor.destination
 for order in actor.pending_orders:
  var point: Vector2 = order["point"]
  actor.draw_line(previous - actor.position, point - actor.position, Color("#e8cd78"), 1.5)
  actor.draw_circle(point - actor.position, 5.0, Color("#e8cd78"), false, 1.5)
  previous = point
