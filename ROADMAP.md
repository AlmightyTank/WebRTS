# Meridian Warfront — Roadmap to 1.0

> **Status (November 1, 2026):** The playable game is the Godot skirmish in `godot/`. A match already has a construction yard, iron ore, power, three factions, six generals, fog, and a win/loss state. **1.0 is the offline Windows game that feels like Red Alert 2’s base-building and Zero Hour’s generals had a child.** The old browser plan in [docs/ROADMAP-1.0-DESKTOP-MOBILE.md](docs/ROADMAP-1.0-DESKTOP-MOBILE.md) is archived.

Design authority: [Master GDD](docs/MERIDIAN-WARFRONT-MASTER-GDD-v0.1.md) · [Factions and generals](docs/FACTIONS-AND-GENERALS-DESIGN-v0.5.md) · [Building roles](docs/FACTION-BUILDING-ROSTER-1.0.md)

## The feel test

Every slice is done when a player can feel it in a match, with original names, art, audio, and fiction.

**From Red Alert 2:** deploy an MCV, build from the sidebar, run harvesters, care about power, capture and sell, queue production, rally an army, and fight a readable combined-arms battle. Late game has a warned superweapon. Skirmish means several maps. A campaign teaches one idea per mission.

**From Zero Hour:** three armies that are different games. You pick a general and the roster, building, and powers change before the match starts. Fighting earns rank and points. Powers are buttons on the battlefield, aimed with a click, and telegraphed. Each faction has a hole: expensive precision, slow armor, or fragile raids.

**Working 1.0 decisions** (the GDD left these open; this board closes them so work can proceed):

- 1.0 ships on Windows, offline. Skirmish and a 12-mission campaign, four missions from each faction’s point of view.
- The captured neutral relay pays a small capped credit trickle. That is the late-game income so a match can continue after the ore is gone.
- There is no army supply cap. The existing unit limit stays a performance guard.
- All nine generals are in 1.0. Rook, Volkov, and Nadir are the missing doctrines (ghost, fortress, guerrilla), so the general select screen is the Zero Hour half of the game.
- Navy, online play, Android store release, replays, and the full 57-building art set wait until after 1.0. Touch layout stays in the project so it does not have to be invented later.

## Where the skirmish is

| Fantasy | In a match today | Still missing for the feel |
| --- | --- | --- |
| Construction yard | Deploy, sidebar tabs, queues, refund, repair, sell, rally, staging, multiple factories, walls and gates | Radar building |
| Ore and power | Finite iron, delivery once, brownout slows production, turrets go dark, low-power cue. Captured relay pays 6/s, once per side | — |
| Orders | Select, groups, attack-move, hold, formations, scout, fog | Fog is a radius, not terrain line of sight |
| Three armies | Alliance, Republic, GIA, with different rosters and some structures | Shared build rules; many designed units stay in the balance file |
| Generals | Vale, Voss, Korda, Orlov, Sayegh, Varek: replacements, research, rank, aimed powers on the left | Rook, Volkov, and Nadir are unbuilt |
| Superweapons | Silo, particle beam, and ironstorm. Each warns for 7s, then strikes. One 240s charge per player | — |
| Air | Tempest, Striker, helicopters build at an airfield. 4 or 6 salvos, then an 8 second rearm (Voss 6.8s) | — |
| Skirmish | Lobby: army, start, credits, fog, AI vs AI. Eight land maps, from Meridian Basin up to the large Amber Reach and Glass Canyon. Save and resume | Difficulty that changes behavior |
| Product | Main menu, pause, settings file, match cues, save and resume | Campaign and multiplayer buttons are disabled |

About 38 unit ids and 16 structure ids can appear in a match. The balance file holds a larger proposed roster. Godot smoke tests cover combat, economy, fog, armies, and commander kits. CI installs Godot 4.4.1; `project.godot` declares a 4.7 feature tag, which should be reconciled before a release export.

## Path

Work in this order. A later row can start only when the rows above it are playable.

1. **Command bar.** Show rank, points, and the three powers on the battlefield. Click to arm, click the map to cast, keep the warnings that already exist. The Upgrades tab keeps research. Done.
2. **Match sounds.** Original cues for construction complete, unit ready, low power, base under attack, and incoming superweapon. One acknowledgement style per faction is enough here. Done.
3. **Save and resume.** A versioned skirmish snapshot: credits, ore, queues, units, structures, fog, commander rank, research, and AI plans. Leaving the match can offer save. Campaign checkpoints reuse this. Done.
4. **Relay income.** Capturing the north relay starts a capped credit trickle. Document the rate next to the ore numbers and test that it cannot outrun a living economy. Done. The rate is 6 credits per second, once per side. A harvester biting 18 iron every 0.15 seconds still earns more while a field has iron.
5. **Airfield.** Aircraft build from an airfield, return to rearm, and stop firing when they are dry. Voss’s bonuses apply to that loop. Done. A Striker and the GIA helicopter carry 4 salvos; a Tempest and the Siege Helicopter carry 6. Rearm takes 8 seconds on a powered pad, 6.8 seconds for Voss. A brownout or a wrecked pad does not reload them. They use their own production lane, and the aircraft cameos stay on the vehicles tab.
6. **The other two superweapons.** Alliance particle beam and Republic ironstorm, with the same warning, power, and one-charge rules as the silo. Done. All three cost 5000, take 90 seconds, draw 100 power, and recharge for 240 seconds. The warning is 7 seconds. The beam holds a radius of 70 and fires four energy pulses of 220, 0.65 seconds apart; a brownout or a wrecked array cuts it off. Ironstorm walks a radius of 145 with three artillery volleys of 180, 1.8 seconds apart, and shells already fired still land. A second building does not grant a second shot. Payload research still only widens the existing silo.
7. **Walls and gates.** They block ground paths, have faction health differences, and open for friendlies. This is also Volkov’s foundation. Done. A segment snaps to the navigation cell and draws no power. Alliance barrier: 100 credits, 6 seconds, 600 health. Republic concrete wall: 150 credits, 8 seconds, 1200 health. GIA scrap barricade: 50 credits, 4 seconds, 280 health. Gates cost more and take longer, and they use the same health as that faction’s wall. They block ground movement and ground shots. Aircraft fly and shoot over them. A gate opens only for the faction that built it. Engineers cannot capture a wall or a gate, and the silhouette stays with that faction. Selling or destroying the segment opens the cell. If that faction is wiped and another side still has a base, its walls and gates go neutral and fire on everyone still on the field: 18 damage, every 0.9 seconds, out to 150. The match ends once that abandoned line is gone, or immediately when the wiped side built none. The AI does not buy walls during its opening.
8. **Maps.** Add land maps on the Meridian Basin schema (spawns, ore, cliffs, one capturable). Done. Eight land maps. Meridian Basin, Cutter Gap, and Salt Flats stay on the original 1920×1200 board. Shelf Road, Twin Fords, and Scrap Mile are 2880×1680. Amber Reach and Glass Canyon are 3840×2160, and the camera opens on your start so the extra ground is somewhere you have to drive. Every map has two starts, at least five iron fields, cliffs, one neutral relay, and a ground route between the starts. A saved match resumes on the board it was played on.
9. **Rook, Volkov, Nadir.** Ghost, fortress, and guerrilla: replacement units, one special structure or stance, research, and three powers each. Stealth reveals on fire and to detectors.
10. **AI and the opening clock.** Recruit, Regular, and Veteran change scouting, build choice, and attack timing. Measure time to first ore delivery, first tank, and first attack. Regular uses no hidden resources.
11. **Missions.** A data-driven objective and trigger layer, briefings, and 12 missions. The first Alliance mission is the tutorial.
12. **Ship.** Remappable keys, colorblind team marks, reduced motion, subtitles for the cues in row 2, a Windows export, and three fresh-player skirmishes plus one campaign path played without a developer in the room.

## Done when

A new player can pick any of the nine generals, build a base, hear the match, fight an AI on more than one map, fire a faction superweapon they were warned about, save, and finish a mission from each faction. The same build runs from the Godot project and from the Windows export.

## After 1.0

Naval maps and docks. Online matches, once commands are already the same ones the AI and the campaign send. An Android release after a real device pass. Replays. The remaining building-role art (radar as a deeper intel structure, tunnels, drones) wherever a general or mission still needs it.
