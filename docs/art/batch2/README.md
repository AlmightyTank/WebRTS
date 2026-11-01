# Meridian Warfront — Batch 2 art pack (Godot)

Contains **three missing headquarters PNGs** for existing committed scenes plus **all 12 Batch 2 building artworks** across Alliance/Republic/GIA.

- Three power buildings have separate idle/working/damaged **eight-frame looping** 3072×384 RGBA PNG sprite sheets and single-frame offline art, with a shared AnimatedSprite2D scene script.
- Each of the nine other buildings has a **three-frame 1152×384 PNG** (idle, working, peak). These are *3 stage illustrations*, not a smooth continuous animation, with a simple 2 FPS working/peak loop.
- All sprites use a fixed isometric viewpoint on transparent 384×384 frame canvases; building frames are **not** the 128×64 terrain tile size.
- HQ PNGs restore the currently missing texture resources for the three faction headquarters scenes already in GitHub.
- Right-facing exits/intakes reflect latest source artwork where available; the visual aircraft/infantry/vehicles depicted are baked into those frames and do not create playable units.
- Art is isolated from generated reference illustrations. Some generated halo/color artifacts may remain; manual review in Godot is needed before calling the sprite pack final.
- **No gameplay integration yet:** placing, spawning, harvesting and power calculation are separate v0.3/v0.4 work; do not mark those slices complete based on this art commit.

Copy `godot/` into the existing Godot root. Run the Godot import and headless smoke tests. In the editor, instantiate e.g. `res://scenes/buildings/core/alliance_ore_refinery.tscn` or `res://scenes/buildings/power/gia_diesel_generator_yard.tscn` in the Y-sorted world layer.

Note: the HQ scenes already committed use a slightly different visual anchor; visually compare foot centers in-engine before finalizing footprint sizes.
