# WebRTS Roadmap

WebRTS is a browser RTS for PC and mobile, inspired by the readability and tactical clarity of classic RTS games. It will use original factions, fiction, art, maps, and missions.

## Product goals

- Playable in a modern desktop or mobile browser.
- Mouse/keyboard and touch controls share the same gameplay commands.
- Short skirmishes: roughly 8–15 minutes.
- Multiple single-player campaigns built from reusable mission systems.
- Multiplayer added after the core simulation is stable and testable.
- Data-driven units, buildings, factions, maps, objectives, dialogue, and missions.

## Guiding rules

1. Build the simulation before producing large amounts of content.
2. Prove the game on mobile as well as PC at every major milestone.
3. Every campaign mission must use the same reusable objective and scripting systems.
4. Keep the first version deliberately small: two factions, one resource, a limited unit roster.
5. Do not create campaign content that depends on unfinished engine features.

## Roadmap overview

| Phase | Outcome | Main risk answered |
| --- | --- | --- |
| 0. Foundation | Stable project and simulation contracts | Can the codebase evolve safely? |
| 1. Toy battlefield | Units select, move, and fight | Is the core interaction fun? |
| 2. RTS economy | Harvest, build, produce, win | Does the RTS loop work? |
| 3. Vertical slice | One polished campaign mission | Can we deliver a complete experience? |
| 4. Campaign framework | Branches, objectives, dialogue, saves | Can missions be authored efficiently? |
| 5. Campaign One | A complete first story campaign | Can the content pipeline scale? |
| 6. Multiplayer beta | Server-authoritative skirmishes | Does networking remain fair and reliable? |
| 7. Campaigns Two+ | Additional factions and stories | Can the game support long-term content? |
| 8. Release hardening | Performance, accessibility, deployment | Is it ready for public players? |

---

## Phase 0 — Foundation

### Work

- Establish TypeScript code organization.
- Separate simulation, rendering, input, UI, and content data.
- Define stable command types:
  - select
  - move
  - attack
  - build
  - produce
  - harvest
  - use ability
- Add a fixed simulation tick independent from rendering.
- Add deterministic seeded matches.
- Add basic error reporting and debug overlays.
- Define content schemas for units, buildings, factions, maps, missions, and objectives.

### Done when

- The simulation can run without Phaser rendering.
- A test can issue commands and inspect the resulting state.
- A match can be reset from a seed.
- PC and touch input both emit the same command objects.

## Phase 1 — Toy battlefield

This is the current slice and should be kept as a deliberately small prototype.

### Work

- One map.
- Blue and red test armies.
- Unit selection and drag selection.
- Touch selection, pan, and pinch zoom.
- Mouse movement and attack commands.
- Basic health, range, damage, and death.
- Camera bounds and responsive HUD.

### Done when

- A player can select, move, attack, and defeat the opposing army on PC and mobile.
- The game remains usable at phone, tablet, and desktop resolutions.
- No feature in this phase requires campaign-specific code.

## Phase 2 — RTS economy and base loop

### Work

- Command Core / headquarters.
- Resource fields and harvesters.
- Refineries and income flow.
- Building placement with valid/invalid previews.
- Barracks and vehicle factory.
- Production queues.
- Population or supply limit.
- Power or technology gating, only if needed by playtests.
- Victory, defeat, surrender, and restart states.
- Basic computer opponent.

### Initial roster

- Rifle Squad
- Scout Bike
- Assault Vehicle
- Siege Tank
- Harvester
- Command Core
- Refinery
- Barracks
- Factory
- Turret

### Done when

- A complete local skirmish can be won by destroying the enemy core or achieving the map objective.
- A new unit or building can be added through data rather than copied gameplay code.
- The AI can gather, produce, attack, and react at a basic level.

## Phase 3 — First polished vertical slice

Build one complete mission before building a full campaign.

### Mission: “The First Landing”

- One playable faction.
- One authored map.
- A short briefing.
- A clear objective: establish a base and destroy an enemy outpost.
- Two or three scripted events.
- Enemy reinforcements.
- Mission success and failure screens.
- Mobile and PC playtest pass.
- Temporary but cohesive art and audio direction.

### Done when

- A new player understands the objective without developer instructions.
- The mission takes 10–20 minutes.
- Restarting the mission is reliable.
- The mission can be authored from data plus a small number of script hooks.

## Phase 4 — Campaign framework

Campaigns must be content assembled from shared systems, not custom scenes.

### Campaign structure

```text
Campaign
  chapters
    missions
      briefing
      map
      starting state
      objectives
      triggers
      rewards
      dialogue
      unlocks
```

### Work

- Campaign and mission selection screens.
- Mission unlock progression.
- Persistent campaign state.
- Save slots and autosave.
- Mission objectives:
  - destroy
  - survive
  - escort
  - capture
  - gather
  - build
  - reach location
  - protect target
- Objective dependencies and optional objectives.
- Trigger system:
  - elapsed time
  - unit destroyed
  - location entered
  - building created
  - resource threshold
  - objective completed
- Dialogue and briefing panels.
- Mission-specific reinforcements and scripted behaviors.
- Difficulty settings.
- Localization-ready text data.

### Done when

- A designer can create a basic mission without modifying the renderer.
- At least three missions use the same objective and trigger framework.
- Campaign progress survives reloads.
- A failed mission can be restarted without corrupting campaign state.

## Phase 5 — Campaign One

Campaign One should be small but complete: approximately **6–8 missions**.

### Suggested arc

1. **First Landing** — tutorial and base establishment.
2. **Broken Relay** — scout and repair a communications site.
3. **The Crossing** — escort engineers through contested territory.
4. **Pressure Point** — defend a base against timed attacks.
5. **No Safe Route** — capture or destroy an enemy resource network.
6. **Counteroffensive** — use a forward base to break a defensive line.
7. **The Core** — assault a major enemy installation.
8. **Aftermath** — campaign conclusion and unlocks.

### Content budget

- One primary playable faction.
- One recurring enemy faction.
- One or two faction-specific units introduced late in the campaign.
- 3–4 environment themes at most.
- Reuse systems and art wherever it improves consistency.

### Done when

- Every mission has a clear purpose and distinct tactical emphasis.
- The campaign can be completed from a clean save.
- Difficulty has been tested on touch and mouse controls.
- Mission pacing does not depend on developer knowledge.

## Phase 6 — Multiplayer beta

Multiplayer should share the same simulation and content definitions as skirmish mode.

### Work

- Authoritative server simulation.
- WebSocket connection and lobby flow.
- Command validation.
- Tick or snapshot synchronization.
- Reconnect handling.
- Match result reporting.
- Player-ready and surrender flow.
- Basic anti-cheat protections.
- Mobile/PC latency and performance testing.

### Multiplayer scope

Start with:

- 1v1 skirmish.
- One competitive map.
- Two balanced factions.
- No ranked ladder initially.

Do not add co-op campaign until the server model and save/progression rules are proven.

## Phase 7 — Campaigns Two and Three

Only begin additional campaigns after Campaign One proves the content pipeline.

### Campaign Two

- A second playable faction.
- Different economy or combat identity.
- 6–8 missions from the opposing perspective.
- Reuse shared mission systems, but add faction-specific objectives where useful.

### Campaign Three

- A third faction or an independent force.
- A different map/environment identity.
- More complex mission combinations.
- Optional branching outcomes if the framework can support them cleanly.

### Campaign rule

New campaigns should add new strategic situations, not just more maps with the same objectives.

## Phase 8 — Release hardening

### Work

- Mobile performance profiling.
- Low-end device fallback settings.
- Asset compression and loading screens.
- Offline-friendly single-player boot path.
- Accessibility options:
  - UI scale
  - text size
  - colorblind-safe team colors
  - remappable controls
  - reduced motion
  - hold/toggle preferences
- Localization pass.
- Analytics that do not collect unnecessary personal data.
- Crash and connection diagnostics.
- Browser compatibility testing.
- Production hosting, HTTPS, and deployment automation.

## Work slicing rules

Each task should fit into one of these slices:

### Engineering slice

One reusable system with a test or debug scenario.

Example: “Add a production queue that accepts unit definitions and emits completion events.”

### Content slice

One playable mission, unit, building, or map using existing systems.

Example: “Create a defense mission using timer triggers and wave reinforcements.”

### UX slice

One player-facing interaction verified on PC and mobile.

Example: “Implement touch building placement with a large confirmation button and invalid-placement feedback.”

### Verification slice

One cross-device or multiplayer behavior tested and documented.

Example: “Verify reconnecting after a 10-second mobile network interruption.”

## Immediate next slices

1. Move the current prototype simulation into a standalone `simulation` module.
2. Add a fixed simulation tick and command objects.
3. Add command core, resource fields, harvesters, and resource income.
4. Add building placement and a production queue.
5. Add a basic AI opponent.
6. Turn the current battlefield into the first complete skirmish.
7. Prototype the first authored campaign mission.
8. Use that mission to identify missing campaign framework features.

## Explicitly deferred

- Ranked matchmaking.
- Large team battles.
- Co-op campaign.
- Procedural campaign generation.
- More than three factions.
- Extensive cosmetic progression.
- Full replay and observer tools.
- Voice chat.

These features may be valuable later, but they should not delay proving the core RTS and campaign pipeline.
