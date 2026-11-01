# Meridian Warfront

A native **Godot 4**, top-down 2D real-time strategy game, inspired by classic Command & Conquer base-building and modern military warfare.

## Run the game

1. Install **Godot 4.4.1**.
2. Open Godot Project Manager and import `godot/project.godot`.
3. Run the project with **F5**.

The Godot project is the primary implementation. Source code and artwork live in [`godot/`](godot/). The active status board is [`ROADMAP.md`](ROADMAP.md); retained ideas from the former isometric plan are in [`docs/IDEAS.md`](docs/IDEAS.md).

The proposed [three-faction, nine-general content design](docs/FACTIONS-AND-GENERALS-DESIGN-v0.5.md) defines named commanders, signature replacements, bonuses, weaknesses and an art direction matching the current procedural renderer. It is a design specification, not completed gameplay content.

## Status

The default scene is the playable skirmish: a green grid battlefield, steel status panel, bottom tactical command bar, and right production sidebar with a live minimap. The desktop window opens at 1280 × 720 to match the visual reference. Smaller screens use a collapsible production drawer. Units and structures use procedural placeholder artwork. The GitHub Actions Godot smoke tests validate gameplay, HUD behavior, import and startup; they are not a substitute for an interactive playtest.

## Main menu

F5 opens the main menu: offline skirmish, saved volume/fullscreen settings, controls, credits and quit. Campaign and multiplayer are explicitly unavailable. During a match, **F10** opens the pause menu; returning to the main menu asks before discarding the match. Escape retains its battlefield command-cancel behavior.

Menu regression: `godot --headless --path godot --script res://tests/main_menu_smoke.gd`.

## Procedural art preview

Open `godot/scenes/art_preview.tscn` and press **F6** to inspect the low-poly-style MCV, construction yard and power plant, including faction variants and production icons. The shared renderer in `godot/scripts/ui/industrial_art.gd` draws shaded polygon faces directly on the 2D canvas; it requires no image assets or 3D models. These designs also appear in the playable skirmish.

Open `godot/scenes/roster_art_preview.tscn` with **F6** for the full active roster. Press **Tab** to switch between eight structures and the mobile-unit designs, including infantry, harvesters, tanks, anti-air vehicles and aircraft. Production icons use the same procedural renderer. Face shading provides depth without cast shadows.

Open `godot/scenes/general_art_preview.tscn` with **F6** for the first code-only general art batch: Arc Lance, Imperator and Junker, including two visible salvage tiers. Arrow keys rotate hull/turret independently, Space toggles hull rotation, and Tab cycles salvage art. Includes native-scale MCV comparisons and shared production icons. Gameplay rosters and statistics are unchanged.

The same gallery's **B** key switches to batch two: Tempest Assault VTOL, Stormrail Howitzer and Volley Launcher. These are also code-only artwork and shared icons, not new playable roster entries.

## Previous WebRTS prototype

The previous Phaser/browser prototype is preserved on the **`legacy-web-phaser`** branch. It is not the active game and its Node/npm build steps do not apply to this Godot project.

## Controls

- WASD / arrow keys: pan camera.
- Right or middle mouse drag: pan.
- Mouse wheel: zoom.
- Touch: drag or pinch to navigate (pending device validation).
