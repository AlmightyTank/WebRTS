# Specialist building artwork — batch four

Five existing structure IDs now have more developed procedural artwork:

- `foundry`: Republic rolling hall, twin rear furnace stacks, roof louvers,
  sliding service shutter, and external ingot pallets.
- `vanguard_foundry`: Korda's foundry adds a foreground portal crane with
  moving trolley, attached cable, and hoist. Powered gameplay animation is enabled.
- `silo`: GIA reinforced sealed hatch with guide rails, locking ribs, control
  cabinet, antenna, and hazard markings. The hatch does not open or launch anything.
- `beam_bastion`: Vale's split-rail emitter on a capacitor-lined fortified base.
- `missile_nest`: Sayegh's expanded eight-tube rack, sandbag perimeter, and fixed
  radar mast independent of weapon rotation.

No balance, targeting, production, collision, or launch behavior changed. Foundry
doors cycle only in the gallery; they do not introduce a new production exit.
All artwork uses the existing bounded one-surface building mesh cache. Foundry
animation time/door frames remain in cache keys; defense keys include aim.

Open `godot/scenes/faction_building_preview.tscn` and press **B three times**.
Blank cells intentionally indicate no additional specialist design for that
faction in this batch; these buildings are not shared faction-wide equivalents.

The rendered `faction_building_smoke.gd` test now covers 32 designs in four batches.
