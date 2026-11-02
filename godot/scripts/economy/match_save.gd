extends RefCounted
## Versioned skirmish snapshot. Campaign checkpoints call the same write/read/apply API with their own path.
## In-flight shots are dropped. The AI has no separate plan: continuity is the economy, the buildings, and the build clock.
const VERSION := 1
const PATH := "user://match_save.json"
const ArmyRules = preload("res://scripts/economy/army_rules.gd")
const SkirmishMaps = preload("res://scripts/economy/skirmish_maps.gd")

static func read(path: String = PATH):
	if not FileAccess.file_exists(path):
		return null
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY or int(parsed.get("version", 0)) != VERSION:
		return null
	return parsed

static func write(arena, path: String = PATH) -> bool:
	var data := capture(arena)
	if data.is_empty():
		return false
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(data))
	return true

static func capture(arena) -> Dictionary:
	if arena == null or not is_instance_valid(arena) or arena.states.size() < 2:
		return {}
	var ore: Array = []
	for field in arena.ore_fields:
		ore.append(float(field["remaining"]))
	var structures: Array = []
	for building in arena.structures:
		if not is_instance_valid(building) or building.hp <= 0.0:
			continue
		var row := {
			"kind": building.kind,
			"team": building.team,
			"at": _pair(building.position),
			"hp": building.hp,
			"max_hp": building.max_hp,
			"repairing": building.repairing,
			"paid": building.paid_value,
			"rally": _pair(building.rally_point),
			"rally_custom": building.rally_custom,
			"rally_stage": building.rally_stage_id,
			"rally_attack": building.rally_attack_move,
			"rally_slot": building.rally_spawn_index,
			"timer": building.timer
		}
		if building.kind in ["wall", "gate"]:
			row["style"] = int(building.art_style)
		if building.get("life_left") != null and float(building.life_left) >= 0.0:
			row["life_left"] = float(building.life_left)
		structures.append(row)
	var units: Array = []
	for unit in arena.units:
		if not is_instance_valid(unit) or unit.hp <= 0.0:
			continue
		units.append(_capture_unit(arena, unit))
	var producers: Array = []
	for side in range(mini(2, arena.active_producers.size())):
		producers.append({
			"infantry": arena.structures.find(arena.active_producers[side].get("infantry")),
			"vehicle": arena.structures.find(arena.active_producers[side].get("vehicle")),
			"air": arena.structures.find(arena.active_producers[side].get("air"))
		})
	var staging: Array = []
	for side in range(mini(2, arena.staging_areas.size())):
		var areas := {}
		for id in arena.STAGING_IDS:
			var area: Dictionary = arena.staging_areas[side][id]
			areas[id] = {"at": _pair(area["position"]), "enabled": bool(area["enabled"]), "next_slot": int(area["next_slot"])}
		staging.append(areas)
	var selected: Array = []
	for unit in arena.selected:
		var index := int(arena.units.find(unit))
		if index >= 0:
			selected.append(index)
	var groups := {}
	for key in arena.control_groups.keys():
		var members: Array = []
		for unit in arena.control_groups[key]:
			var index := int(arena.units.find(unit))
			if index >= 0:
				members.append(index)
		groups[str(key)] = members
	var camera := {}
	if arena.get("camera") != null and is_instance_valid(arena.camera):
		camera = {"at": _pair(arena.camera.destination), "zoom": float(arena.camera.zoom_goal)}
	var explored: Array = [[], []]
	if arena.fog_enabled and arena.fog != null:
		for side in range(2):
			for cell in arena.fog.explored_cells[side].keys():
				explored[side].append([cell.x, cell.y])
	var states = _detach(arena.states)
	if typeof(states) != TYPE_ARRAY:
		return {}
	return {
		"version": VERSION,
		"army": [str(arena.army_choices[0]), str(arena.army_choices[1])],
		"ai_vs_ai": bool(arena.ai_vs_ai),
		"map": str(arena.map_id),
		"credits_start": int(arena.starting_credits),
		"fog": bool(arena.fog_enabled),
		"ai_difficulty": str(arena.ai_difficulty) if arena.get("ai_difficulty") != null else "regular",
		"ai_clock": _capture_clock(arena),
		"ai_pushed": [bool(arena.ai_pushed[0]), bool(arena.ai_pushed[1])] if arena.get("ai_pushed") != null else [false, false],
		"ai_next_build": [float(arena.ai_next_build[0]), float(arena.ai_next_build[1])] if arena.get("ai_next_build") != null else [0.0, 0.0],
		"starts": [str(arena.start_slots[0]), str(arena.start_slots[1])],
		"time": float(arena.skirmish_time),
		"ai_tick": int(arena.ai_build_tick),
		"ai_timer": float(arena.economy_ai_timer),
		"tab": int(arena.current_tab),
		"placement": str(arena.placement_lane),
		"status": str(arena.hud_status),
		"shots": int(arena.shots),
		"hits": int(arena.hits),
		"kills": [int(arena.kills[0]), int(arena.kills[1])],
		"battle_over": bool(arena.battle_over),
		"result": str(arena.result_text.text) if is_instance_valid(arena.result_text) else "",
		"states": states,
		"ore": ore,
		"structures": structures,
		"units": units,
		"producers": producers,
		"staging": staging,
		"selected": selected,
		"selected_building": arena.structures.find(arena.selected_building),
		"groups": groups,
		"camera": camera,
		"explored": explored,
		"commander": _capture_commander(arena.commander)
	}

static func _capture_clock(arena) -> Array:
	var clocks: Array = []
	if arena.get("ai_clock") == null:
		return clocks
	for side in range(mini(2, arena.ai_clock.size())):
		var row: Dictionary = arena.ai_clock[side]
		clocks.append({"ore": float(row.get("ore", -1.0)), "tank": float(row.get("tank", -1.0)), "attack": float(row.get("attack", -1.0))})
	return clocks

static func _restore_clock(arena, data: Dictionary) -> void:
	if arena.get("ai_clock") == null:
		return
	var clocks = data.get("ai_clock", [])
	if typeof(clocks) == TYPE_ARRAY:
		for side in range(mini(2, clocks.size())):
			var row = clocks[side]
			if typeof(row) != TYPE_DICTIONARY:
				continue
			for key in ["ore", "tank", "attack"]:
				arena.ai_clock[side][key] = float(row.get(key, -1.0))
	var pushed = data.get("ai_pushed", [])
	if arena.get("ai_pushed") != null and typeof(pushed) == TYPE_ARRAY:
		for side in range(mini(2, pushed.size())):
			arena.ai_pushed[side] = bool(pushed[side])
	var nxt = data.get("ai_next_build", [])
	if arena.get("ai_next_build") != null and typeof(nxt) == TYPE_ARRAY:
		for side in range(mini(2, nxt.size())):
			arena.ai_next_build[side] = float(nxt[side])

static func apply(arena, data: Dictionary) -> bool:
	if _problem(arena, data) != "":
		return false
	arena.restoring = true
	arena.army_choices = [str(data.army[0]), str(data.army[1])]
	arena.ai_vs_ai = bool(data.get("ai_vs_ai", false))
	arena.map_id = str(data.map)
	if arena.has_method("adopt_map"):
		arena.adopt_map()
	arena.starting_credits = int(data.get("credits_start", arena.starting_credits))
	arena.fog_enabled = bool(data.get("fog", true))
	if arena.has_method("_valid_difficulty"):
		arena.ai_difficulty = arena._valid_difficulty(str(data.get("ai_difficulty", "regular")))
	arena.start_slots = [str(data.starts[0]), str(data.starts[1])]
	arena.clear_for_restore()
	var battlefield: Dictionary = SkirmishMaps.MAPS[arena.map_id]
	for i in range(battlefield.ore.size()):
		var site: Dictionary = battlefield.ore[i]
		arena.ore_fields.append({"position": site["position"], "remaining": float(data.ore[i]), "initial": float(site["amount"])})
	arena.states = _copy_states(data.states)
	_restore_commander(arena.commander, data.commander)
	var structure_rows: Array = data.structures
	for row in structure_rows:
		var at := _vec(row.at)
		if not arena._place_structure(str(row.kind), int(row.team), at, float(row.get("paid", 0.0))):
			arena.restoring = false
			return false
		var building = arena.structures[arena.structures.size() - 1]
		building.hp = float(row.hp)
		building.max_hp = float(row.get("max_hp", building.max_hp))
		building.repairing = bool(row.get("repairing", false))
		building.paid_value = float(row.get("paid", building.paid_value))
		building.rally_point = _vec(row.get("rally", _pair(at)))
		building.rally_custom = bool(row.get("rally_custom", false))
		building.rally_stage_id = str(row.get("rally_stage", ""))
		building.rally_attack_move = bool(row.get("rally_attack", false))
		building.rally_spawn_index = int(row.get("rally_slot", 0))
		building.timer = float(row.get("timer", 0.0))
		if row.has("style"):
			building.art_style = int(row.style)
		if row.has("life_left") and building.get("life_left") != null:
			building.life_left = float(row.life_left)
		building.queue_redraw()
	var unit_rows: Array = data.units
	for row in unit_rows:
		if _spawn_saved_unit(arena, row) == null:
			arena.restoring = false
			return false
	_bind_targets(arena, unit_rows)
	var producer_rows: Array = data.get("producers", [])
	for side in range(mini(2, producer_rows.size())):
		for lane in ["infantry", "vehicle", "air"]:
			if not producer_rows[side].has(lane):
				continue
			var index := int(producer_rows[side].get(lane, -1))
			if index >= 0 and index < arena.structures.size():
				arena._set_active_producer(side, lane, arena.structures[index])
	var stage_rows: Array = data.get("staging", [])
	for side in range(mini(2, stage_rows.size())):
		for id in arena.STAGING_IDS:
			if not stage_rows[side].has(id):
				continue
			var area: Dictionary = stage_rows[side][id]
			var live: Dictionary = arena.staging_areas[side][id]
			live["position"] = _vec(area.get("at", [0, 0]))
			live["enabled"] = bool(area.get("enabled", false))
			live["next_slot"] = int(area.get("next_slot", 0))
	arena.selected.clear()
	for index in data.get("selected", []):
		var unit_index := int(index)
		if unit_index >= 0 and unit_index < arena.units.size():
			var unit = arena.units[unit_index]
			unit.selected = true
			arena.selected.append(unit)
	var building_index := int(data.get("selected_building", -1))
	arena.selected_building = arena.structures[building_index] if building_index >= 0 and building_index < arena.structures.size() else null
	if arena.selected_building != null:
		arena.selected_building.selected = true
	arena.control_groups.clear()
	var groups: Dictionary = data.get("groups", {})
	for key in groups.keys():
		var members: Array = []
		for index in groups[key]:
			var unit_index := int(index)
			if unit_index >= 0 and unit_index < arena.units.size():
				members.append(arena.units[unit_index])
		if not members.is_empty():
			arena.control_groups[int(key)] = members
	arena.skirmish_time = float(data.get("time", 0.0))
	_restore_clock(arena, data)
	arena.ai_build_tick = int(data.get("ai_tick", 0))
	arena.economy_ai_timer = float(data.get("ai_timer", 2.0))
	arena.current_tab = int(data.get("tab", 0))
	arena.placement_lane = str(data.get("placement", ""))
	arena.hud_status = str(data.get("status", arena.hud_status))
	arena.shots = int(data.get("shots", 0))
	arena.hits = int(data.get("hits", 0))
	var kills = data.get("kills", [0, 0])
	arena.kills = [int(kills[0]) if typeof(kills) == TYPE_ARRAY and kills.size() > 0 else 0, int(kills[1]) if typeof(kills) == TYPE_ARRAY and kills.size() > 1 else 0]
	arena.battle_over = bool(data.get("battle_over", false))
	arena.paused = false
	if is_instance_valid(arena.result_text):
		arena.result_text.text = str(data.get("result", ""))
	var camera: Dictionary = data.get("camera", {})
	if not camera.is_empty() and arena.get("camera") != null and is_instance_valid(arena.camera):
		var at := _vec(camera.get("at", [0, 0]))
		arena.camera.destination = at
		arena.camera.position = at
		arena.camera.zoom_goal = float(camera.get("zoom", arena.camera.zoom_goal))
		arena.camera.zoom = Vector2.ONE * arena.camera.zoom_goal
	for side in range(2):
		arena._calculate_power(side)
	arena._rebuild_navigation()
	arena.restore_explored(data.get("explored", [[], []]))
	if is_instance_valid(arena.commander.rank_label):
		arena.commander.refresh_ui()
	arena._update_hud()
	arena.queue_redraw()
	arena.restoring = false
	return true

static func _problem(arena, data: Dictionary) -> String:
	if arena == null or not is_instance_valid(arena) or not (arena.roster is Dictionary):
		return "arena"
	if int(data.get("version", 0)) != VERSION:
		return "version"
	var army = data.get("army", [])
	var starts = data.get("starts", [])
	if typeof(army) != TYPE_ARRAY or army.size() != 2 or typeof(starts) != TYPE_ARRAY or starts.size() != 2:
		return "setup"
	if not ArmyRules.CHOICES.has(str(army[0])) or not ArmyRules.CHOICES.has(str(army[1])):
		return "army"
	if not SkirmishMaps.MAPS.has(str(data.get("map", ""))):
		return "map"
	var battlefield: Dictionary = SkirmishMaps.MAPS[str(data.map)]
	if typeof(data.get("ore")) != TYPE_ARRAY or data.ore.size() != battlefield.ore.size():
		return "ore"
	if typeof(data.get("states")) != TYPE_ARRAY or data.states.size() < 2:
		return "states"
	if typeof(data.get("structures")) != TYPE_ARRAY or typeof(data.get("units")) != TYPE_ARRAY:
		return "actors"
	if typeof(data.get("commander")) != TYPE_DICTIONARY:
		return "commander"
	for row in data.structures:
		if typeof(row) != TYPE_DICTIONARY:
			return "structure"
		var kind := str(row.get("kind", ""))
		if kind != "yard" and not arena.STRUCTURE_DATA.has(kind):
			return "structure"
		var team := int(row.get("team", 99))
		if team < -1 or team > 1:
			return "structure"
	for row in data.units:
		if typeof(row) != TYPE_DICTIONARY or not arena.roster.has(str(row.get("id", ""))):
			return "unit"
		var team := int(row.get("team", 99))
		if team < 0 or team > 1:
			return "unit"
	return ""

static func _capture_unit(arena, unit) -> Dictionary:
	var id := str(unit.unit_id)
	var kind := "economy" if ArmyRules.economic(id) else ("engineer" if ArmyRules.engineer(id) else "combat")
	var target := -1
	var target_kind := ""
	var aimed = unit.get("target")
	if aimed != null and is_instance_valid(aimed):
		var unit_index := int(arena.units.find(aimed))
		if unit_index >= 0:
			target = unit_index
			target_kind = "unit"
		else:
			var building_index := int(arena.structures.find(aimed))
			if building_index >= 0:
				target = building_index
				target_kind = "structure"
	var capture := -1
	var captured = unit.get("capture_target")
	if captured != null and is_instance_valid(captured):
		capture = arena.structures.find(captured)
	var row := {
		"kind": kind,
		"id": id,
		"team": int(unit.team),
		"at": _pair(unit.position),
		"hp": float(unit.hp),
		"max_hp": float(unit.max_hp),
		"facing": _num(unit, "facing"),
		"moving": bool(unit.get("moving")),
		"destination": _pair(unit.destination) if unit.get("destination") != null else [0, 0],
		"route": _route(unit.route) if unit.get("route") != null else [],
		"route_index": int(unit.route_index) if unit.get("route_index") != null else 0,
		"pending": _orders(unit.pending_orders) if unit.get("pending_orders") != null else [],
		"target": target,
		"target_kind": target_kind,
		"capture": capture
	}
	if kind == "economy":
		row["cargo"] = float(unit.cargo)
		row["working"] = bool(unit.working)
		row["state"] = str(unit.state)
		row["mine_timer"] = float(unit.mine_timer)
		row["deposits"] = int(unit.deposits)
		row["purchase_cost"] = float(unit.purchase_cost)
		row["resume_harvest"] = bool(unit.resume_harvest_on_arrival)
	else:
		row["turret"] = _num(unit, "turret_angle")
		row["cooldown"] = _num(unit, "cooldown")
		row["aggressive"] = bool(unit.get("aggressive"))
		row["attack_goal"] = _pair(unit.attack_move_goal) if unit.get("attack_move_goal") != null else [0, 0]
		row["has_attack_goal"] = bool(unit.get("has_attack_move_goal"))
		row["hold"] = bool(unit.get("hold_position"))
		row["explicit_attack"] = bool(unit.get("explicit_attack"))
		row["unit_xp"] = _num(unit, "unit_xp")
		row["salvage_tier"] = int(unit.get("salvage_tier") if unit.get("salvage_tier") != null else 0)
		row["capture_progress"] = _num(unit, "capture_progress")
		row["capture_pause"] = _num(unit, "capture_pause")
		row["capture_at"] = _pair(unit.capture_approach_point) if unit.get("capture_approach_point") != null else [0, 0]
		if unit.get("life_left") != null and float(unit.life_left) >= 0.0:
			row["life_left"] = float(unit.life_left)
		if unit.get("deployed") == true or float(unit.get("deploy_left") if unit.get("deploy_left") != null else 0.0) > 0.0:
			row["deployed"] = bool(unit.deployed)
			row["packing"] = bool(unit.packing)
			row["deploy_left"] = float(unit.deploy_left)
		if unit.get("cloak_hold") != null and (bool(unit.cloaked) or float(unit.cloak_hold) > 0.0):
			row["cloaked"] = bool(unit.cloaked)
			row["cloak_hold"] = float(unit.cloak_hold)
		if unit.get("ammo") != null:
			row["ammo"] = int(unit.ammo)
			row["ammo_max"] = int(unit.ammo_max)
			row["rearming"] = bool(unit.rearming)
			row["rearm_left"] = float(unit.rearm_left)
	if bool(unit.get("column_move")):
		row["column"] = {
			"goal": _pair(unit.column_goal),
			"slot": _pair(unit.column_slot),
			"spine": _route(unit.column_spine)
		}
	return row

static func _spawn_saved_unit(arena, row: Dictionary):
	var id := str(row.id)
	var side := int(row.team)
	var at := _vec(row.at)
	var unit
	if str(row.get("kind", "")) == "economy" or ArmyRules.economic(id):
		unit = arena._spawn_economy(id, side, at, id in ["a_harvester", "r_hauler", "g_collector"])
	elif str(row.get("kind", "")) == "engineer" or ArmyRules.engineer(id):
		unit = arena._spawn_engineer(id, side, at)
	else:
		unit = arena._spawn(id, side, at)
	if unit == null:
		return null
	unit.position = at
	unit.hp = float(row.hp)
	unit.max_hp = float(row.get("max_hp", unit.max_hp))
	var tier := int(row.get("salvage_tier", 0))
	if id == "g_junker" and tier >= 2 and unit.get("weapon") is Dictionary:
		var bonus := 0.12 if arena.commander.has_research(side, "field_improvisation") else 0.10
		unit.weapon.damage = float(unit.weapon.get("damage", 0.0)) * (1.0 + bonus)
	if unit.get("salvage_tier") != null:
		unit.salvage_tier = tier
	if unit.get("facing") != null:
		unit.facing = float(row.get("facing", 0.0))
	if unit.get("turret_angle") != null:
		unit.turret_angle = float(row.get("turret", 0.0))
	if unit.get("cooldown") != null:
		unit.cooldown = float(row.get("cooldown", unit.cooldown))
	if unit.get("unit_xp") != null:
		unit.unit_xp = float(row.get("unit_xp", 0.0))
	if unit.get("hold_position") != null:
		unit.hold_position = bool(row.get("hold", false))
	if unit.get("aggressive") != null:
		unit.aggressive = bool(row.get("aggressive", false))
	if unit.get("explicit_attack") != null:
		unit.explicit_attack = bool(row.get("explicit_attack", false))
	if unit.get("has_attack_move_goal") != null:
		unit.has_attack_move_goal = bool(row.get("has_attack_goal", false))
		unit.attack_move_goal = _vec(row.get("attack_goal", [0, 0]))
	if row.has("life_left") and unit.get("life_left") != null:
		unit.life_left = float(row.life_left)
	if row.has("deployed") and unit.get("deployed") != null:
		unit.deployed = bool(row.deployed)
		unit.packing = bool(row.get("packing", false))
		unit.deploy_left = float(row.get("deploy_left", 0.0))
	if row.has("cloak_hold") and unit.get("cloak_hold") != null:
		unit.cloaked = bool(row.get("cloaked", false))
		unit.cloak_hold = float(row.cloak_hold)
	if row.has("ammo") and unit.get("ammo") != null:
		unit.ammo = int(row.ammo)
		unit.ammo_max = int(row.get("ammo_max", unit.ammo_max))
		unit.rearming = bool(row.get("rearming", false))
		unit.rearm_left = float(row.get("rearm_left", 0.0))
	if unit.get("cargo") != null:
		unit.cargo = float(row.get("cargo", 0.0))
		unit.working = bool(row.get("working", false))
		unit.state = str(row.get("state", "IDLE"))
		unit.mine_timer = float(row.get("mine_timer", 0.0))
		unit.deposits = int(row.get("deposits", 0))
		unit.purchase_cost = float(row.get("purchase_cost", 0.0))
		unit.resume_harvest_on_arrival = bool(row.get("resume_harvest", false))
	unit.destination = _vec(row.get("destination", [0, 0]))
	if unit.get("route") != null:
		unit.route = _packed(row.get("route", []))
		unit.route_index = int(row.get("route_index", 0))
	unit.moving = bool(row.get("moving", false)) and unit.get("route") != null and unit.route.size() > unit.route_index
	if unit.get("pending_orders") != null:
		unit.pending_orders = _restore_orders(row.get("pending", []))
	if row.has("column") and unit.get("column_move") != null:
		var column: Dictionary = row.column
		unit.column_move = true
		unit.column_goal = _vec(column.get("goal", [0, 0]))
		unit.column_slot = _vec(column.get("slot", [0, 0]))
		unit.column_spine = _packed(column.get("spine", []))
	unit.visible = arena.entity_visible_to(0, unit)
	unit.queue_redraw()
	return unit

static func _bind_targets(arena, rows: Array) -> void:
	for i in range(mini(rows.size(), arena.units.size())):
		var row: Dictionary = rows[i]
		var unit = arena.units[i]
		var target_index := int(row.get("target", -1))
		if unit.get("target") != null or (target_index >= 0 and str(row.get("target_kind", "")) != ""):
			var aimed = null
			if str(row.get("target_kind", "")) == "unit" and target_index >= 0 and target_index < arena.units.size():
				aimed = arena.units[target_index]
			elif str(row.get("target_kind", "")) == "structure" and target_index >= 0 and target_index < arena.structures.size():
				aimed = arena.structures[target_index]
			unit.target = aimed
		var capture_index := int(row.get("capture", -1))
		if unit.get("capture_target") != null or capture_index >= 0:
			unit.capture_target = arena.structures[capture_index] if capture_index >= 0 and capture_index < arena.structures.size() else null
			unit.capture_progress = float(row.get("capture_progress", 0.0))
			unit.capture_pause = float(row.get("capture_pause", 0.0))
			unit.capture_approach_point = _vec(row.get("capture_at", [0, 0]))

static func _capture_commander(commander) -> Dictionary:
	var teams: Array = []
	for state in commander.teams:
		var powers := {}
		for id in state.powers.keys():
			powers[str(id)] = int(state.powers[id])
		var research := {}
		for id in state.research.keys():
			research[str(id)] = true
		var cooldowns := {}
		for id in state.cooldowns.keys():
			cooldowns[str(id)] = float(state.cooldowns[id])
		var job: Dictionary = state.job
		teams.append({
			"xp": float(state.xp),
			"rank": int(state.rank),
			"points": int(state.points),
			"powers": powers,
			"research": research,
			"job": {"id": str(job.get("id", "")), "paid": float(job.get("paid", 0.0))} if not job.is_empty() else {},
			"cooldowns": cooldowns,
			"silo": float(state.silo)
		})
	return {
		"pending": str(commander.pending_power),
		"teams": teams,
		"events": _areas(commander.events, true),
		"reveals": _areas(commander.reveals, false),
		"buffs": _areas(commander.buffs, true)
	}

static func _restore_commander(commander, data: Dictionary) -> void:
	var rows: Array = data.get("teams", [])
	commander.teams.clear()
	for side in range(2):
		var row: Dictionary = rows[side] if side < rows.size() and typeof(rows[side]) == TYPE_DICTIONARY else {}
		var job: Dictionary = row.get("job", {})
		commander.teams.append({
			"xp": float(row.get("xp", 0.0)),
			"rank": int(row.get("rank", 1)),
			"points": int(row.get("points", 1)),
			"powers": _number_map(row.get("powers", {})),
			"research": _flag_map(row.get("research", {})),
			"job": {"id": str(job.get("id", "")), "paid": float(job.get("paid", 0.0))} if typeof(job) == TYPE_DICTIONARY and str(job.get("id", "")) != "" else {},
			"cooldowns": _number_map(row.get("cooldowns", {})),
			"silo": float(row.get("silo", 240.0))
		})
	commander.events = _restore_areas(data.get("events", []))
	commander.reveals = _restore_areas(data.get("reveals", []))
	commander.buffs = _restore_areas(data.get("buffs", []))
	commander.interception.clear()
	commander.pending_power = str(data.get("pending", ""))
	commander.queue_redraw()

static func _areas(list: Array, named: bool) -> Array:
	var out: Array = []
	for area in list:
		if typeof(area) != TYPE_DICTIONARY or area.get("point") == null:
			continue
		var row := {
			"side": int(area.get("side", 0)),
			"at": _pair(area.point),
			"radius": float(area.get("radius", 0.0)),
			"remaining": float(area.get("remaining", 0.0))
		}
		if named:
			row["id"] = str(area.get("id", ""))
		if area.has("level"):
			row["level"] = int(area.level)
		if area.has("mark"):
			row["mark"] = bool(area.mark)
		if area.has("wide"):
			row["wide"] = bool(area.wide)
		if area.has("pulse"):
			row["pulse"] = int(area.pulse)
		out.append(row)
	return out

static func _restore_areas(list) -> Array:
	var out: Array = []
	if typeof(list) != TYPE_ARRAY:
		return out
	for row in list:
		if typeof(row) != TYPE_DICTIONARY:
			continue
		var area := {
			"side": int(row.get("side", 0)),
			"point": _vec(row.get("at", [0, 0])),
			"radius": float(row.get("radius", 0.0)),
			"remaining": float(row.get("remaining", 0.0))
		}
		if row.has("id"):
			area["id"] = str(row.id)
		if row.has("level"):
			area["level"] = int(row.level)
		if row.has("mark"):
			area["mark"] = bool(row.mark)
		if row.has("wide"):
			area["wide"] = bool(row.wide)
		if row.has("pulse"):
			area["pulse"] = int(row.pulse)
		out.append(area)
	return out

static func _orders(list: Array) -> Array:
	var out: Array = []
	for order in list:
		if typeof(order) != TYPE_DICTIONARY or order.get("point") == null:
			continue
		var saved := {"point": _pair(order.point), "attack_move": bool(order.get("attack_move", false))}
		var spine = order.get("column_spine")
		if spine is PackedVector2Array and not spine.is_empty():
			saved["column_spine"] = _route(spine)
			saved["column_slot"] = _pair(order.get("column_slot", Vector2.ZERO))
		out.append(saved)
	return out

static func _restore_orders(list) -> Array:
	var out: Array = []
	if typeof(list) != TYPE_ARRAY:
		return out
	for order in list:
		if typeof(order) != TYPE_DICTIONARY:
			continue
		var restored := {"point": _vec(order.get("point", [0, 0])), "attack_move": bool(order.get("attack_move", false))}
		if order.has("column_spine"):
			restored["column_spine"] = _packed(order.column_spine)
			restored["column_slot"] = _vec(order.get("column_slot", [0, 0]))
		out.append(restored)
	return out

static func _copy_states(states: Array) -> Array:
	var copy = _detach(states)
	return copy if typeof(copy) == TYPE_ARRAY else [{}, {}]

static func _number_map(value) -> Dictionary:
	var out := {}
	if typeof(value) != TYPE_DICTIONARY:
		return out
	for key in value.keys():
		out[str(key)] = float(value[key])
	return out

static func _flag_map(value) -> Dictionary:
	var out := {}
	if typeof(value) != TYPE_DICTIONARY:
		return out
	for key in value.keys():
		out[str(key)] = true
	return out

static func _detach(value):
	var text := JSON.stringify(value)
	if text == "":
		return null
	return JSON.parse_string(text)

static func _pair(point: Vector2) -> Array:
	return [point.x, point.y]

static func _vec(value) -> Vector2:
	if value is Vector2:
		return value
	if typeof(value) != TYPE_ARRAY or value.size() < 2:
		return Vector2.ZERO
	return Vector2(float(value[0]), float(value[1]))

static func _route(points: PackedVector2Array) -> Array:
	var out: Array = []
	for point in points:
		out.append(_pair(point))
	return out

static func _packed(points) -> PackedVector2Array:
	var out := PackedVector2Array()
	if typeof(points) != TYPE_ARRAY:
		return out
	for point in points:
		out.append(_vec(point))
	return out

static func _num(node, property: String) -> float:
	var value = node.get(property)
	return float(value) if value != null else 0.0
