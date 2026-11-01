extends Node2D

func _process(delta: float) -> void:
 for building in get_children():
  building.art_time+=delta
  building.queue_redraw()
