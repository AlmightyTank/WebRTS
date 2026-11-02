extends Control
## Original support-power cameo. A clock covers the icon until the cooldown ends.
var power_id := ""
var fraction := 0.0
var armed := false
var locked := false
var level := 0
var accent := Color("#7ec8d4")

func configure(id: String, tint: Color) -> void:
	power_id = id
	accent = tint
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()

func present(next_level: int, next_fraction: float, is_armed: bool, is_locked: bool) -> void:
	level = next_level
	fraction = clampf(next_fraction, 0.0, 1.0)
	armed = is_armed
	locked = is_locked
	queue_redraw()

func _draw() -> void:
	var box := Rect2(Vector2.ZERO, size)
	draw_rect(box, Color("#121a1f"))
	var scale_factor := minf(size.x, size.y) / 64.0
	draw_set_transform(size * 0.5, 0.0, Vector2.ONE * scale_factor)
	_icon(accent.darkened(0.45) if level == 0 else accent)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if fraction > 0.001:
		_clock(fraction)
	elif locked:
		draw_rect(box, Color(0, 0, 0, 0.42))
	for pip in range(mini(level, 3)):
		draw_rect(Rect2(5.0 + pip * 9.0, size.y - 7.0, 6.0, 3.0), accent)
	draw_rect(box, Color("#efc56a") if armed else Color("#84969d"), false, 2.0)

func _clock(amount: float) -> void:
	var center := size * 0.5
	var radius := maxf(size.x, size.y)
	var steps := maxi(8, int(round(28.0 * amount)))
	var pts := PackedVector2Array()
	pts.append(center)
	var sweep := TAU * amount
	for i in range(steps + 1):
		var angle := -PI * 0.5 + sweep * float(i) / float(steps)
		pts.append(center + Vector2(cos(angle), sin(angle)) * radius)
	draw_colored_polygon(pts, Color(0, 0, 0, 0.78))

func _icon(body: Color) -> void:
	var ink := Color("#0c1418")
	match power_id:
		"grid_surge", "breakthrough_order", "scavenger_convoy":
			draw_colored_polygon(PackedVector2Array([Vector2(-4, -26), Vector2(10, -6), Vector2(1, -6), Vector2(8, 26), Vector2(-10, 4), Vector2(-1, 4)]), body)
		"target_lattice", "rocket_recon", "spotter_recon", "recon_overflight":
			draw_arc(Vector2.ZERO, 16, 0, TAU, 24, body, 3.0)
			draw_line(Vector2(-22, 0), Vector2(22, 0), body, 2.0)
			draw_line(Vector2(0, -22), Vector2(0, 22), body, 2.0)
			draw_circle(Vector2.ZERO, 4, body)
		"orbital_pulse", "sky_supremacy", "fire_mission", "saturation_strike":
			draw_colored_polygon(PackedVector2Array([Vector2(0, -24), Vector2(16, 8), Vector2(5, 8), Vector2(8, 24), Vector2(-8, 24), Vector2(-5, 8), Vector2(-16, 8)]), body)
		"field_repairs", "rapid_salvage":
			draw_rect(Rect2(-5, -18, 10, 36), body)
			draw_rect(Rect2(-18, -5, 36, 10), body)
		"armor_reserve", "roadside_reinforcements":
			draw_colored_polygon(PackedVector2Array([Vector2(-16, -18), Vector2(16, -18), Vector2(16, 6), Vector2(0, 22), Vector2(-16, 6)]), body)
			draw_rect(Rect2(-8, -10, 16, 8), ink)
		"rolling_barrage", "harassing_salvo", "interdiction_flight":
			for i in range(3):
				var origin := Vector2(-16 + i * 14, 8)
				draw_colored_polygon(PackedVector2Array([origin + Vector2(0, -28), origin + Vector2(6, -8), origin + Vector2(-6, -8)]), body)
				draw_rect(Rect2(origin.x - 3, origin.y - 8, 6, 16), body)
		"silo":
			draw_colored_polygon(PackedVector2Array([Vector2(0, -26), Vector2(8, -8), Vector2(5, -8), Vector2(5, 16), Vector2(-5, 16), Vector2(-5, -8), Vector2(-8, -8)]), body)
			draw_rect(Rect2(-14, 16, 28, 5), body)
		"beam_array":
			draw_line(Vector2(-16, 10), Vector2(-16, -14), body, 4)
			draw_line(Vector2(16, 10), Vector2(16, -14), body, 4)
			draw_line(Vector2(-16, -6), Vector2(16, -6), Color("#d7fbff"), 3)
			draw_circle(Vector2(0, -6), 5, Color("#d7fbff"))
		"ironstorm":
			for i in range(3):
				var origin := Vector2(-18 + i * 14, 6)
				draw_rect(Rect2(origin.x, origin.y - 16, 8, 22), body)
				draw_line(origin + Vector2(4, -16), origin + Vector2(4, -28), body, 3)
		_:
			draw_circle(Vector2.ZERO, 14, body)
