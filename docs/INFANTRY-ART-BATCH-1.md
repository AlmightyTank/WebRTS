# Infantry artwork — first batch

Nine code-only designs covering existing rifle, rocket, and engineer roles:

| Faction | Rifle | Rocket | Engineer |
|---|---|---|---|
| Alliance | Ranger | Javelin | Engineer |
| Republic | Line Infantry | Hunter | Engineer |
| GIA | Militia | Rocket Cell | Technician |

Alliance uses fitted armor, compact packs, and visored helmets. Republic uses
broader armor, steel helmets, and heavier equipment. GIA uses light webbing,
wrapped head coverings, earth-tone cloth, and improvised field cases. Engineers
carry a tablet and handled toolkit; rocket troops carry shoulder-mounted tubes.

Faction architecture follows the source unit ID, independently of player/team
color. The bounded single-surface unit mesh cache includes infantry style.
Legs follow body heading; torso, arms, head, and equipment share the aim pivot.
This batch adds no walk cycle, firing animation, balance, or collision changes.

Preview: `godot/scenes/infantry_art_preview.tscn`. Left/Right changes body heading,
Up/Down changes aim, and Space toggles rotation. Each panel includes an enlarged
figure and a native-scale figure.

`godot/tests/infantry_art_smoke.gd` renders nine designs at 32 opposing body/aim
angles, checks bounded single-surface meshes, and saves a rendered screenshot.
