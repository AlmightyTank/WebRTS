# Meridian Warfront — Archived Ideas

This document collects reusable ideas from the former Godot isometric roadmap.
It is a design backlog, not an implementation schedule or a statement that any
feature is complete. The active execution plan is the root [`ROADMAP.md`](../ROADMAP.md)
(Red Alert 2 base-building plus Zero Hour generals, offline Windows 1.0).
The current design authority is the reviewed master GDD.

## Ideas retained from the old roadmap

### Presentation and platform

- A readable Red Alert-style battlefield with smooth camera pan and zoom.
- Desktop-first controls with mobile touch navigation and command input considered
  from the start.
- Placeholder art is acceptable while gameplay and asset contracts are validated.
- Keep a playable vertical slice at every meaningful milestone.
- Use data-driven entities, reusable scenes/scripts, and explicit asset contracts.

### World and map foundation

- Seeded map generation with terrain, decorations, obstacles and occupancy queries.
- Map serialization, loading and an editor workflow.
- Y-sorted or otherwise depth-correct actor presentation where it improves readability.
- Performance profiling and automated runtime checks as first-class work, not release cleanup.

### RTS command layer

- Single selection, box selection, control groups and keyboard shortcuts.
- Right-click movement, attack-move, guard, rally and formation orders.
- Navigation, obstacle avoidance, group movement and formation spacing.
- Touch-friendly selection and order confirmation.

### Base building and production

- Command Center / Construction Yard as the anchor for base expansion.
- Placement previews, footprint validation and construction-radius rules.
- Ownership, selection, health, damage, destruction and rubble states.
- Production queues, production gating and multiple production lanes.
- Construction visuals that communicate progress without making worker pathing mandatory.

### Economy

- Finite resource fields and a visible gather-deliver-spend loop.
- Harvesters, refineries, carrying capacity and delivery feedback.
- Power generation, power demand, outages and recovery.
- Data-driven prices, build times and economy tuning.
- An economy HUD that makes shortages, income and spending legible.

### Combat

- Automatic target acquisition constrained by range, vision and stance.
- Infantry and vehicle weapons, projectiles, hit registration, damage and armor rules.
- Static defenses, turrets, explosions, smoke, destruction feedback and veterancy.
- Readable counterplay through attack-move, guard and defensive orders.
- Automated combat tests and repeatable balance scenarios.

### Factions and technology

- Data-driven faction definitions with distinct structures, infantry and vehicles.
- Faction technologies, upgrades, production prerequisites and tech trees.
- Asymmetric strengths and weaknesses rather than identical rosters with different names.
- Balance and regression tests for faction matchups.

### AI and skirmish

- AI resource planning, construction, production and scouting.
- Attack planning, defense, repairs and difficulty profiles.
- Skirmish setup, multiple opponents, victory/loss rules and short-game options.
- AI profiling, repeatable scenarios and tests that use the same simulation commands as players.

### Multiplayer considerations

- Server-authoritative or otherwise explicit authority boundaries.
- Command synchronization, lobby/ready flow, teams and reconnect behavior.
- Determinism checks, desync diagnostics and latency-aware command handling.
- Multiplayer-compatible simulation rules without promising determinism before it is tested.

### Campaign, interface and polish

- Menus, settings, command sidebar, minimap, fog of war and shroud.
- Mission framework, objective triggers, briefings, tutorials and authored story missions.
- Save/load with compatibility planning and migration paths.
- Voice, music, ambience, animation and destruction feedback.
- Graphics, performance and accessibility options, followed by focused usability testing.

### Release readiness

- Final balance and regression pass across campaign, skirmish and multiplayer.
- Save compatibility checks and release-candidate testing.
- Windows packaging, storefront preparation, achievements and post-release support planning.

## Ideas deliberately superseded

The old roadmap also contained assumptions that are no longer active design
direction and must not be copied into new implementation work:

- Fixed 128×64 diamond tiles and a no-rotation isometric presentation.
- A two-faction milestone; the current direction is Alliance, Republic and GIA.
- Replacing the active implementation wholesale through a dedicated `2d-isometric`
  branch. New work must preserve the working project and migrate through validated slices.
- The old 115-slice version accounting and its completion checkboxes.

These entries remain here only to explain the provenance of the backlog and to
prevent old assumptions from being mistaken for current requirements.

## Quality and migration principles worth keeping

1. Verify each feature in Godot and with automated checks where practical.
2. Test desktop input and document or test mobile implications.
3. Check performance and rendering regressions as features land.
4. Preserve reusable gameplay/data concepts, but do not assume engine-specific code can be copied unchanged.
5. Do not delete or replace working implementation code until the successor path is tested and playable.
