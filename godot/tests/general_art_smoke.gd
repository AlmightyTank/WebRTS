extends SceneTree
## Run without --headless to also save a gallery capture in user://.
const Gallery = preload("res://scenes/general_art_preview.tscn")

func _initialize() -> void:
 call_deferred("_run")

func _run() -> void:
 var gallery = Gallery.instantiate()
 root.add_child(gallery)
 for batch in range(3):
  gallery.batch=batch
  for tier in range(3):
   gallery.salvage_tier=tier
   gallery._refresh()
   for step in range(16):
    gallery.heading=step*TAU/16.0
    gallery.aim=-step*TAU/16.0
    gallery.queue_redraw()
    await process_frame
 gallery.heading=0.0
 gallery.aim=-0.35
 gallery._refresh()
 await process_frame
 if DisplayServer.get_name()!="headless":
  await RenderingServer.frame_post_draw
  var error = root.get_texture().get_image().save_png("user://general_art_batch.png")
  if error!=OK:
   push_error("Could not save gallery capture")
   quit(1)
   return
 print("General art smoke: three batches, three salvage tiers, 16 independent hull/turret headings each")
 quit(0)
