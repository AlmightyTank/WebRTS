# Battlefield map format

Version 1 maps are UTF-8 JSON files. The battlefield loads `res://maps/procedural-skirmish.map.json`. Authored maps use the same contract, including the small `res://maps/editor-sample.map.json`.

## Document

The terrain array below is abbreviated. The full sample is `godot/maps/editor-sample.map.json`.

```json
{
  "format": "meridian-warfront-map",
  "version": 1,
  "name": "editor-sample",
  "width": 8,
  "height": 8,
  "tile_size": [128, 64],
  "terrain": ["00000005", "...one 8-digit string per row..."],
  "obstacles": [{"x": 1, "y": 1, "kind": "tree"}],
  "headquarters": {"x": 4, "y": 4}
}
```

`width` and `height` are 3–256. `tile_size` stays `[128, 64]`. `terrain` has one string per row, and each character is a digit `0`–`5`. Unknown fields, duplicate obstacles, and a headquarters footprint that leaves the map are rejected.

| Digit | Editor tool | Rendering |
| --- | --- | --- |
| 0 | Grass | Grass A, no overlay |
| 1 | Grass B | Grass B, no overlay |
| 2 | Blend | Grass base with a feathered third-grass edge |
| 3 | Dirt | Grass base with a feathered dirt edge |
| 4 | Road | Grass base with a feathered concrete edge |
| 5 | Grass C | Grass C, no overlay |

Obstacle `kind` is `tree`, `rock`, or `debris`. Only one obstacle occupies a cell. The headquarters cell owns a 3×3 footprint, the same footprint as `CommandCenter.FOOTPRINT`, and that footprint cannot contain obstacles.

If the configured file is missing or invalid, the battlefield logs a warning and builds the procedural layout instead of starting empty.

## Editor workflow

1. Import the Godot project.
2. Open `res://scenes/map_editor.tscn`, or choose **Project → Tools → Open Map Editor**.
3. Run the current scene. F5 remains the battlefield without the editor panel.
4. Pick a tool and left-click or drag across tiles. Right or middle drag still pans, and the wheel still zooms.
5. Save writes the path in the text field. The default is `res://maps/sketch.map.json`, so saving does not replace the shipped baseline. `res://` is writable from the Godot editor; exported games should use `user://`.

| Input | Action |
| --- | --- |
| 1–6 | Grass, Grass B, Blend, Dirt, Road, Grass C |
| 7, 8, 9, 0 | Tree, rock, debris, erase obstacle |
| H | Move headquarters |
| Ctrl+S / Ctrl+L | Save or load the path field |
| Ctrl+N | New procedural 64×64 map |
| Ctrl+B | Reload the shipped baseline |

Number keys are ignored while the path field is focused.

The map editor is a desktop authoring tool. A paint gesture is not bound to touch, because one-finger painting would fight camera pan. Phones and tablets load the same JSON, and the existing drag and pinch camera behavior is unchanged.

Regenerate the shipped baseline with:

```bash
godot --headless --path godot --script res://scripts/dev/export_procedural_map.gd
```

The headless check expects that file to match the generator. Save custom maps under a new filename.

```bash
godot --headless --path godot --script res://scripts/checks/map_roundtrip.gd
```
