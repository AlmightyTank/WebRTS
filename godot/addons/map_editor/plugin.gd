@tool
extends EditorPlugin
## Project menu entry for the desktop map editor scene.

const MAP_EDITOR_SCENE := "res://scenes/map_editor.tscn"


func _enter_tree() -> void:
	add_tool_menu_item("Open Map Editor", _open_map_editor)


func _exit_tree() -> void:
	remove_tool_menu_item("Open Map Editor")


func _open_map_editor() -> void:
	EditorInterface.open_scene_from_path(MAP_EDITOR_SCENE)
	EditorInterface.set_main_screen_editor("2D")
