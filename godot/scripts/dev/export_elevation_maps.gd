extends SceneTree
## Writes the elevation showcase maps from map_showcase.gd.
const MAP_SHOWCASE := preload("res://scripts/map_showcase.gd")


func _init() -> void:
	var maps := [
		["res://maps/elevation-escarpment.map.json", MAP_SHOWCASE.escarpment()],
		["res://maps/elevation-basin.map.json", MAP_SHOWCASE.basin()],
		["res://maps/elevation-hill.map.json", MAP_SHOWCASE.hill()],
		["res://maps/mercy-bay.map.json", MAP_SHOWCASE.mercy_bay()],
	]
	for entry in maps:
		var error: Error = entry[1].save_to_file(entry[0])
		if error != OK:
			push_error(entry[1].last_error)
			quit(1)
			return
		print("Exported %s" % entry[0])
	quit(0)
