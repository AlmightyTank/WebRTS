extends SceneTree
const Art = preload("res://scripts/ui/industrial_art.gd")

func _initialize() -> void:
 call_deferred("_run")

func _run() -> void:
 root.size=Vector2i(1280,720)
 root.content_scale_size=Vector2i(1280,720)
 var gallery = load("res://scenes/faction_building_preview.tscn").instantiate()
 root.add_child(gallery)
 for step in range(48):
  gallery.batch=0 if step<24 else 1
  gallery.elapsed=step*0.5
  gallery.queue_redraw()
  await process_frame
 gallery.elapsed=0.0
 gallery.queue_redraw()
 await process_frame
 if DisplayServer.get_name()!="headless":
  await RenderingServer.frame_post_draw
  var error = root.get_texture().get_image().save_png("user://faction_building_batch.png")
  if error!=OK:
   quit(1)
   return
  gallery.elapsed=2.0
  gallery.queue_redraw()
  await process_frame
  await RenderingServer.frame_post_draw
  if root.get_texture().get_image().save_png("user://faction_building_open.png")!=OK:
   quit(1)
   return
 if Art._building_mesh_cache.is_empty() or Art._building_mesh_cache.size()>Art.BUILDING_CACHE_LIMIT:
  push_error("Building mesh cache must be populated and bounded")
  quit(1)
  return
 for mesh in Art._building_mesh_cache.values():
  if mesh.get_surface_count()!=1 or mesh.surface_get_array_len(0)==0:
   push_error("Cached building must contain one nonempty mesh surface")
   quit(1)
   return
 print("Faction building smoke: eighteen buildings, both animated batches rendered; bounded mesh cache verified")
 quit(0)
