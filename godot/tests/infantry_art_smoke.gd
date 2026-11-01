extends SceneTree
const Art = preload("res://scripts/ui/industrial_art.gd")

func _initialize() -> void:
 call_deferred("_run")

func _run() -> void:
 root.size=Vector2i(1280,720)
 root.content_scale_size=Vector2i(1280,720)
 var gallery = load("res://scenes/infantry_art_preview.tscn").instantiate()
 root.add_child(gallery)
 for step in range(32):
  gallery.heading=step*TAU/32.0
  gallery.aim=-step*TAU/32.0
  gallery.queue_redraw()
  await process_frame
 gallery.heading=0.0
 gallery.aim=-0.35
 gallery.queue_redraw()
 await process_frame
 if DisplayServer.get_name()!="headless":
  await RenderingServer.frame_post_draw
  if root.get_texture().get_image().save_png("user://infantry_art_batch.png")!=OK:
   quit(1)
   return
 if Art._vehicle_mesh_cache.is_empty() or Art._vehicle_mesh_cache.size()>Art.VEHICLE_CACHE_LIMIT:
  push_error("Infantry mesh cache must be populated and bounded")
  quit(1)
  return
 for mesh in Art._vehicle_mesh_cache.values():
  if mesh.get_surface_count()!=1 or mesh.surface_get_array_len(0)==0:
   push_error("Infantry requires one nonempty mesh surface")
   quit(1)
   return
 print("Infantry art smoke: nine designs, 32 opposing body/aim angles, bounded single-surface meshes")
 quit(0)
