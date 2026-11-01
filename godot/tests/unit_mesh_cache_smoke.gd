extends SceneTree
const Art = preload("res://scripts/ui/industrial_art.gd")
var failures: Array[String] = []

class Gallery extends Node2D:
 var cargo := 0.0
 func _draw() -> void:
  for i in range(Art.UNIT_MESH_KINDS.size()):
   for team in range(2):
    draw_set_transform(Vector2(70 + (i % 11) * 110, 110 + (i / 11) * 230 + team * 105))
    Art.draw_asset(self, Art.UNIT_MESH_KINDS[i], team, 0.3, -0.6, cargo)
  draw_set_transform(Vector2.ZERO)

func expect(value: bool, label: String) -> void:
 print(("PASS: " if value else "FAIL: ") + label)
 if not value: failures.append(label)

func _initialize() -> void:
 await process_frame
 Art._vehicle_mesh_cache.clear()
 var gallery := Gallery.new()
 root.add_child(gallery)
 await process_frame
 await process_frame
 var count := Art._vehicle_mesh_cache.size()
 expect(count == Art.UNIT_MESH_KINDS.size() * 2, "Every mobile artwork creates a mesh for each faction")
 var first_meshes: Array = Art._vehicle_mesh_cache.values().duplicate()
 gallery.queue_redraw()
 await process_frame
 await process_frame
 expect(Art._vehicle_mesh_cache.values() == first_meshes, "Repeated poses reuse the same mesh resources")
 gallery.cargo = 0.5
 gallery.queue_redraw()
 await process_frame
 await process_frame
 expect(Art._vehicle_mesh_cache.size() == count + 2, "Loaded harvesters have separate geometry; other units ignore cargo")
 if DisplayServer.get_name() != "headless":
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("user://unit_mesh_gallery.png")
 gallery.queue_free()
 await process_frame
 print("UNIT_MESH_CACHE_SMOKE_", "PASS" if failures.is_empty() else "FAIL")
 quit(0 if failures.is_empty() else 1)
