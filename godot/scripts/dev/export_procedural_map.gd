extends SceneTree
## Writes the procedural baseline consumed by the battlefield and the round-trip check.
const MAP_GENERATOR := preload("res://scripts/map_generator.gd")
const OUTPUT := "res://maps/procedural-skirmish.map.json"


func _init() -> void:
	var document = MAP_GENERATOR.procedural_skirmish()
	var error: Error = document.save_to_file(OUTPUT)
	if error != OK:
		push_error(document.last_error)
		quit(1)
		return
	print("Exported %s" % OUTPUT)
	quit(0)
