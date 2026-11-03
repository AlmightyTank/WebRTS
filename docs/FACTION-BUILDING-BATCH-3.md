# Faction buildings: defense and communications

Code-only artwork; no balance, weapon, or production changes.

| Role | Alliance | Republic | GIA |
|---|---|---|---|
| Ground defense | Compact single-gun turret and clean armored plinth | Heavy twin-gun turret and concrete buttresses | Open twin-gun mount with scrap shield and sandbags |
| Anti-air | Compact paired missile pods | Heavy six-tube missile battery | Four exposed launch tubes on a patched emplacement |
| Relay outpost | Flat-roof communications station and rooftop cooling | Reinforced bunker and braced radar mast | Corrugated workshop and improvised antenna mast |

All three relay arrays rotate in the preview. Captured outposts animate while
powered; neutral outposts retain their existing neutral artwork. Ground and AA
mounts support independent aim in the renderer; simulation targeting is unchanged.

Open `godot/scenes/faction_building_preview.tscn` and press **B twice** for batch
three. Each design is shown enlarged and at small battlefield scale. The shared
bounded building mesh cache includes faction style and quantized aiming angle.

Validation: `godot/tests/faction_building_smoke.gd` renders all 27 designs across
three batches and verifies cached meshes contain one nonempty surface.
