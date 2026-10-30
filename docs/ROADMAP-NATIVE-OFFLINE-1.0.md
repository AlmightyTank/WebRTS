# WebRTS Native — Complete Offline Game 1.0 Master Roadmap

**Status:** Planning only — **0 / 132 native slices accepted**. The separate browser/Phaser track has completed v0.2 A–H, but those slices are NOT native-game completion.
**Authority:** This document describes the native game and does not replace the browser roadmap at `docs/ROADMAP-1.0-DESKTOP-MOBILE.md`.
**Working title:** WebRTS Native (final marketable title unconfirmed).
**Product:** Standalone, fully offline single-player real-time strategy game for Windows and Android; original 3D low-poly visuals under an angled classic-RTS camera; integrated native game menus and HUD; no browser, website, VPS or internet connection required for normal play.
**Engine:** Godot 4 stable, GDScript, reusable scene/data architecture; pin specific stable engine/export-template version in Slice v0.1-A before first verified build. Separate `native/` project; preserve existing Phaser prototype and tests untouched.

## Full 1.0 scope
- Two distinctly playable original factions: **Iron Collective** (durability/armor/fortification) and **Vanguard League** (speed/precision/recon).
- **20 authored story missions**, 10 per faction with briefings, scripted objectives, progress and endings.
- **12 polished skirmish maps**, configurable AI, three difficulties, teams, victory conditions and post-match results.
- Core RTS includes bases, deployable HQ, ore/refinery economy, construction/production queues, power and tech trees; infantry, ground vehicles, aircraft, naval, stealth, garrisons, capture, veterancy and original superweapons.
- Integrated gameplay UI: native main/pause/settings menus, construction sidebar, radar/minimap, selection and orders, notifications, save/loading screens. Distinct desktop and touch layouts with **the same game rules**.
- Versioned offline saves, checkpoints, autosaves, accessibility and scalable graphics quality.
- Art/music/campaign content must be original; emulate the *feel*, never copy protected Command & Conquer/Red Alert assets, narrative, names, music, maps or code.
- Multiplayer, accounts, dedicated servers, cross-platform matchmaking, Steam cloud and storefront integrations are **post-1.0 optional**, not dependencies for offline launch. Optional storefront delivery must not create an in-game network requirement.

## Technical choices and nonnegotiable constraints
1. **Preserve the web prototype:** don't remove `src/`, `tests/`, existing npm scripts, browser CI or the existing browser roadmap. New native work lives in `native/`, with its own CI job and docs.
2. **Port behavior, not blindly code:** inventory existing fixed-step JS gameplay, seeded RNG, command contracts and saves; use these as reference/specs/tests. New GDScript cannot directly import Phaser scene code. Choose a stable simulation tick and isolate simulation logic from 3D graphics/camera and UI.
3. **Offline-by-design:** simulation, AI, menus, mission scripts and persistence run on-device. No external login, telemetry service, CDN, VPS or web request needed to launch or finish a match.
4. **Windows/Android first-class:** mouse/keyboard and mobile touch dispatch common commands. A completed building remains fixed; placement uses preview and validation, never dragging existing construction.
5. **Native save policy:** store player data in Godot's user data directory (`user://`), version every save/schema, use atomic or backed-up save writes and migrate deliberately. Existing browser saves are *not* promised compatible without a tested converter.
6. **Performance goals, not promises:** define hardware test tiers; aim 60 FPS desktop and usable 30 FPS midrange Android; measure large-army simulation and rendering separately.
7. **Pin and validate engine version:** use stable Godot 4 and matched export templates. Decide renderer/asset budgets in early Android tests and keep high-end features optional.
8. **Content before polish:** get a complete playable offline skirmish first (v0.6), then deepen factions/warfare, build story tools, write campaigns and ship.
9. **No unverified completion:** a slice is done only if code/assets land, tests and native CI pass, a playable acceptance test succeeds, documentation is updated and the review is merged.

## Milestone tracker

| Version | Milestone | Slices | Status |
| --- | --- | ---: | --- |
| v0.1 | Native foundation and runnable application | 8 | Planned |
| v0.2 | RTS battlefield camera and controls | 8 | Planned |
| v0.3 | Maps, navigation and fog of war | 8 | Planned |
| v0.4 | Base building and economy | 8 | Planned |
| v0.5 | Ground armies and tactical combat | 8 | Planned |
| v0.6 | Offline skirmish and enemy AI | 8 | Planned |
| v0.7 | Two asymmetric factions | 8 | Planned |
| v0.8 | Air, navy and amphibious warfare | 8 | Planned |
| v0.9 | Advanced warfare and superweapons | 8 | Planned |
| v0.10 | Production UI, original art and sound | 8 | Planned |
| v0.11 | Campaign engine and mission tools | 8 | Planned |
| v0.12 | Iron Collective story campaign | 10 | Planned |
| v0.13 | Vanguard League story campaign | 10 | Planned |
| v0.14 | Maps, tutorial, balance and player experience | 8 | Planned |
| v0.15 | Windows/Android optimization and distribution readiness | 8 | Planned |
| v1.0 | Offline PC and Android launch | 8 | Planned |

**Total: 16 milestones, 132 native slices.** Slices vary in size; number of slices is not an effort or calendar estimate.

## Execution discipline for every slice
- Work on a focused branch such as `feature/native-v0.1-a-bootstrap`. Avoid merging into `main` without build/CI verification.
- Each slice must deliver tangible working behavior, its own automated tests where feasible, an acceptance scenario and a short compatibility note.
- Preserve clean offline execution on both platforms. Run editor/headless import, GDScript checks, scene/test runner and native build checks; add device acceptance early rather than waiting for launch.
- Record completion only after merge, green native CI and relevant hardware checks. Engine/UI-only checks are not equivalent to an end-to-end playtest.
- Use playable gates after v0.1 (native menus), v0.2 (RTS controls), v0.4 (economy), v0.6 (complete offline skirmish), v0.11 (campaign framework), v0.13 (both campaigns), and v1.0 (ship).

## Detailed slices and exit gates

### v0.1 — Native foundation and runnable application

- [ ] **A — Native project bootstrap:** Add isolated `native/` Godot project (main scene, bootstrap, original placeholder theme), without changing the working web build; run a headless import smoke test.
- [ ] **B — Scene architecture:** Establish game-state service, navigation stack, event bus, asset folders and scene conventions; test navigation lifecycle.
- [ ] **C — Main menu:** Play, Campaign, Skirmish, Load, Options, Credits, Quit; disable unfinished destinations explicitly; prove keyboard, mouse and touch navigation.
- [ ] **D — Settings persistence:** Resolution/windowed/fullscreen, UI scaling, sound groups and quality presets saved locally with schema-safe defaults.
- [ ] **E — Platform-neutral command contract:** Native intent/event types mirror the web prototype concepts without embedding browser/Phaser dependencies; unit tests for invalid commands.
- [ ] **F — Godot CI:** Add headless import, script parsing, tests, Windows build checks, asset validation and artifact retention on a dedicated workflow.
- [ ] **G — Windows export:** Versioned portable desktop build, icons, startup/shutdown checks, and tested offline launch without a local server.
- [ ] **H — Android baseline:** Export preset, orientation/safe-area rules, touch smoke scene, debug APK workflow and physical-device checklist; native offline boot required.

**Exit gate:** A fresh checkout opens in Godot, boots into the main menu, persists settings, and can be built as a Windows application; Android debug-export pipeline is documented and smoke-tested.

### v0.2 — RTS battlefield camera and controls

- [ ] **A — Battlefield scene:** Fixed-angle low-poly 3D camera and test terrain with deterministic screen-to-ground picking.
- [ ] **B — Desktop camera:** Pan via keyboard/middle-drag/edge scroll, mouse-wheel zoom, bounds and reset-to-base.
- [ ] **C — Android camera:** One-finger pan, pinch zoom and safe gesture handling with HUD overlays.
- [ ] **D — Selection:** Click/tap unit select, drag-box desktop and multiselect/lasso touch mode.
- [ ] **E — Command input:** Right-click contextual move/attack and touch order bar invoke the same game intents.
- [ ] **F — Control groups:** Desktop groups and mobile quick groups, unit-type multi-select and selection filtering.
- [ ] **G — Selection feedback:** Unit highlights, health indicators, order markers and readable event pings.
- [ ] **H — Integration acceptance:** Automated input mapping tests plus PC and real Android camera/selection playtest.

**Exit gate:** From the native menu, players can explore a 3D map and select/control sample units with desktop and touch controls.

### v0.3 — Maps, navigation and fog of war

- [ ] **A — Map format:** Versioned maps with terrain height, walkability, water, obstacles, resources, spawns and validation.
- [ ] **B — Low-poly terrain:** Terrain meshes, props, cliffs, shorelines and strategic readable silhouettes.
- [ ] **C — Pathfinding:** Grid/navmesh strategy, path cost, terrain classes, and unreachable-destination response.
- [ ] **D — Dynamic blockers:** New structures, destroyed bridges, collisions and path replanning.
- [ ] **E — Group movement:** Formations, avoidance, destination spread and anti-stuck recovery.
- [ ] **F — Fog of war:** Shroud, explored cells, per-team sight, detectors and LOS rules.
- [ ] **G — Minimap:** Terrain/map icons, revealed information, camera rectangle and click/touch camera jumps.
- [ ] **H — Stress regression:** Dense unit pathing and fog tests on PC/Android with performance instrumentation.

**Exit gate:** Units navigate around terrain, dynamic obstacles and each other; hidden enemy information never leaks to the player.

### v0.4 — Base building and economy

- [ ] **A — Starting construction unit:** Deployable mobile HQ, footprint, base radius and undeploy policy.
- [ ] **B — Placement:** Valid/invalid ghost preview with terrain, overlap and tech checks; completed buildings cannot be dragged.
- [ ] **C — Ore economy:** Resource deposits, harvester routes, refinery unload, depletion and visible credit income.
- [ ] **D — Power:** Generators, usage, brownouts, radar penalties and actionable power UI.
- [ ] **E — Construction queues:** Build/produce/cancel/rally/repeat, reservation and refund rules, duplicate-command protection.
- [ ] **F — Tech tree:** Data-driven prerequisites and locked/unlocked building and unit cards.
- [ ] **G — Repair/sell:** Damage, repair cost/time, demolition/refund and construction state visuals.
- [ ] **H — Save/restore economy:** Restore construction queues, resources and power with equivalence tests.

**Exit gate:** A player can deploy a base, gather resources, power buildings, construct, produce and sell without developer controls.

### v0.5 — Ground armies and tactical combat

- [ ] **A — Unit data registry:** Weapons, armor, costs, movement, roles, ownership, abilities and content validation.
- [ ] **B — Infantry:** Rifle, engineer, scout, anti-armor and specialist behaviors.
- [ ] **C — Vehicles:** Recon, transport, tank, artillery and anti-air roles.
- [ ] **D — Combat resolution:** Range, armor modifiers, accuracy, projectiles, splash and destruction; deterministic tests.
- [ ] **E — Orders:** Attack-move, defend, patrol, hold, stop, queued waypoints and stances.
- [ ] **F — Garrison/capture:** Neutral buildings, engineers, capture restrictions and repair interactions.
- [ ] **G — Veterancy:** Experience, rank indicators, bounded upgrades and service repair.
- [ ] **H — Battle acceptance:** Mixed-unit combat scenarios, counters and PC/Android readability test.

**Exit gate:** Infantry and vehicles can maneuver, fight, retreat, capture and earn veterancy in complete test battles.

### v0.6 — Offline skirmish and enemy AI

- [ ] **A — Skirmish lobby:** Select map, faction, teams, AI count/difficulty, spawn and victory conditions.
- [ ] **B — Match lifecycle:** Pause, resume, victory/defeat, surrender, restart, result screen and rematch.
- [ ] **C — AI economy:** Base building, harvest, production queues, power and recovery from losses.
- [ ] **D — AI tactical behavior:** Scouting, attack waves, defense, target priorities and retreat.
- [ ] **E — AI difficulties:** Three tuned behaviors; limited and clearly specified bonuses, no omniscient map knowledge.
- [ ] **F — Save/load:** Slot-based versioned native saves, autosave, validation, migration and crash-safe writes.
- [ ] **G — Match records:** Local victory statistics, faction preferences and optional offline skirmish history.
- [ ] **H — Soak tests:** Multiple full AI games, early rush, late-game stalemate and Android resume testing.

**Exit gate:** A player can start, finish and rematch a complete offline skirmish against AI, with local save/load.

### v0.7 — Two asymmetric factions

- [ ] **A — Lore bible:** Original geopolitical fiction, visual rules, naming and art restrictions.
- [ ] **B — Iron Collective roster:** Armor, defenses, economy and unique structures/units.
- [ ] **C — Vanguard League roster:** Recon, mobility, precision and unique structures/units.
- [ ] **D — Distinct tech trees:** Build prerequisites, progression, production roles and strategic tradeoffs.
- [ ] **E — Hero/specialist roles:** Limited abilities and clear counterplay without unavoidable snowball.
- [ ] **F — Faction readability:** Silhouettes, team colors, icons, audio cues and unit selection responses.
- [ ] **G — Neutral tech/doctrines:** Capturable objectives, optional country doctrines and fair start options.
- [ ] **H — Faction testing:** Mirror and cross-faction AI matches, counters, timing and mobile input parity.

**Exit gate:** Iron Collective and Vanguard League each have complete, distinctive and balanced enough early-game-to-late-game strategies.

### v0.8 — Air, navy and amphibious warfare

- [ ] **A — Movement layers:** Land, air, surface and submerged movement with layer-aware orders.
- [ ] **B — Aircraft systems:** Airbase, launch/land, reload/refuel and return-to-base behaviors.
- [ ] **C — Air combat:** Fighters, bombers, transports, air-to-air and air-defense counters.
- [ ] **D — Naval yards:** Shore placement, naval production and ship navigation/docking.
- [ ] **E — Sea combat:** Surface ships, submarines, sonar and anti-sub counters.
- [ ] **F — Amphibious transport:** Loading/unloading, valid beachheads and combined movement.
- [ ] **G — Mixed-force orders:** Multi-domain selection, valid targets, formations and radar visibility.
- [ ] **H — Coastal acceptance:** Balanced air/ground/sea map tests and mobile/desktop performance checks.

**Exit gate:** Land, air and sea forces interact correctly in coastal skirmishes with effective counters and route planning.

### v0.9 — Advanced warfare and superweapons

- [ ] **A — Stealth:** Cloaking, sensors, radar concealment and visibility tests.
- [ ] **B — Infiltration:** Spies/disguise, protected facilities and counter-intelligence rules.
- [ ] **C — Deploy modes:** Stationary artillery, fortification and mode-switch transitions.
- [ ] **D — Tactical abilities:** Context targeting, resource cost, cooldowns and cancel/confirm.
- [ ] **E — Iron superweapon:** Original mechanic with charge, intel, warnings, counters and optional disabling.
- [ ] **F — Vanguard superweapon:** Distinct original mechanic with equivalent risk/reward.
- [ ] **G — Match rules:** Superweapon limits, custom skirmish rules and fairness presets.
- [ ] **H — Stress and save tests:** Heavy FX/abilities, command replay equivalence, interrupted charge persistence.

**Exit gate:** Late-game mechanics support strong strategic choices with warnings, cooldowns and reliable counters.

### v0.10 — Production UI, original art and sound

- [ ] **A — Art direction:** Original low-poly asset bible, factions, terrain palette, scale and silhouette requirements.
- [ ] **B — Final HUD:** Responsive in-game RTS sidebar, queue, command palette, selection info and minimap.
- [ ] **C — Main menus and usability:** Animated menu backgrounds, pause, settings, loading, tooltips and gamepad fallback where relevant.
- [ ] **D — Environment assets:** Buildings, ore fields, roads, water, trees, bridges, props and terrain variants.
- [ ] **E — Unit assets:** Animated infantry, vehicles, aircraft, navy, construction and destruction states.
- [ ] **F — VFX:** Projectiles, impacts, smoke, fire, death feedback and reduced-effects mode.
- [ ] **G — Audio:** Original soundtrack, unit acknowledgements, warnings, ambience and mixer controls.
- [ ] **H — Art performance:** Low/medium/high presets, LOD/occlusion testing, asset budgets and visual regression checks.

**Exit gate:** The game has a cohesive, integrated PC/mobile UI and recognizable original art/audio rather than debug placeholders.

### v0.11 — Campaign engine and mission tools

- [ ] **A — Mission schema:** Versioned mission configuration, map, player setup, available tech and validator.
- [ ] **B — Objective graph:** Destroy, defend, capture, escort, survive, build, extract and optional goals.
- [ ] **C — Triggers:** Time, region, sight, event, death, arrival, objective dependency and reinforcement waves.
- [ ] **D — Narrative:** Briefings, portraits, subtitles, mission dialogue, cutscenes and skip/rewatch.
- [ ] **E — AI mission scripts:** Reinforcement triggers, scripted enemy plans and adaptive challenge behavior.
- [ ] **F — Persistence:** Campaign slots, chapter unlocks, checkpoints, retries and failure states.
- [ ] **G — Authoring tools:** Map editor, mission data inspectors, event debug overlays and validation reports.
- [ ] **H — Vertical slice:** Three internally complete demonstration missions from menu through ending.

**Exit gate:** Mission authors can ship an entire voiced/text-based scripted mission without modifying combat or scene core.

### v0.12 — Iron Collective story campaign

- [ ] **A — M01 Into the Ash:** Deployment, first base, protect first supply line.
- [ ] **B — M02 Broken Line:** Defend convoys and restore a strategic crossing.
- [ ] **C — M03 Iron Harvest:** Raid refinery network, escort stolen resources.
- [ ] **D — M04 Hostile City:** Garrison buildings and secure urban districts.
- [ ] **E — M05 The Crossing:** Launch a coordinated coastal landing.
- [ ] **F — M06 Black Sky:** Survive air raids and disable enemy airfields.
- [ ] **G — M07 Silent Wire:** Infiltrate signals complex and recover intelligence.
- [ ] **H — M08 The Foundry:** Maintain forward factories under a siege.
- [ ] **I — M09 Countdown:** Intercept a superweapon activation sequence.
- [ ] **J — M10 The Last Directive:** Multi-stage finale, cinematic outcome and clean-save campaign run.

**Exit gate:** Ten connected, beatable Iron Collective missions with original briefings, branching side-objectives and a complete ending.

### v0.13 — Vanguard League story campaign

- [ ] **A — M01 Signal Lost:** Investigate a missing recon team and extract.
- [ ] **B — M02 Lightning Run:** Mobile attack on enemy logistics.
- [ ] **C — M03 Hold the Grid:** Defend a failing power and radar network.
- [ ] **D — M04 City of Glass:** Urban engineer and intelligence operation.
- [ ] **E — M05 Blue Water:** Naval interception and coastal rescue.
- [ ] **F — M06 Air Superiority:** Counter armored defenses through air control.
- [ ] **G — M07 Ghost Protocol:** Covert base infiltration and extraction.
- [ ] **H — M08 The Fault Line:** Exploit terrain and demolish chokepoints.
- [ ] **I — M09 False Sunrise:** Detect decoys and stop a major strike.
- [ ] **J — M10 Dawn Protocol:** Combined-arms ending and fully verified progression.

**Exit gate:** Ten distinct Vanguard League missions, complete arc and ending, verified from a fresh profile.

### v0.14 — Maps, tutorial, balance and player experience

- [ ] **A — Map set:** Twelve distinct balanced skirmish maps with size/team/victory metadata.
- [ ] **B — Tutorial:** Real guided mission for selection, movement, resources, construction, fighting and saving.
- [ ] **C — Difficulty:** Campaign and skirmish difficulty tuning, optional assistance and challenge modes.
- [ ] **D — Balance:** Economy timing, counters, faction win-rate testing and anti-stalemate fixes.
- [ ] **E — Accessibility:** Text scale, key rebinding, colorblind-friendly team indicators, subtitles, reduced motion.
- [ ] **F — User experience:** Tooltip consistency, quick-start, error messaging and player-facing help/codex.
- [ ] **G — Content completion:** Final unique asset/tech/unit coverage target set from real playtests.
- [ ] **H — End-to-end QA:** Clean install to both campaign endings, diverse 12-map AI match sweeps.

**Exit gate:** A first-time player can learn the game and complete campaigns and skirmishes across 12 polished maps.

### v0.15 — Windows/Android optimization and distribution readiness

- [ ] **A — Windows performance:** GPU/CPU profiling, graphics presets, window handling and 60 FPS target on defined hardware.
- [ ] **B — Android performance:** Batching, LOD, thermal/memory budgets and 30 FPS floor target on defined devices.
- [ ] **C — Android controls:** Landscape HUD, orientation transitions, safe areas, back navigation and resume.
- [ ] **D — Native save robustness:** Disk-full, power loss, version upgrades, backups and migration verification.
- [ ] **E — Input coverage:** Mouse, keyboard, touch, tablet pointer and high-DPI/ultrawide testing.
- [ ] **F — Package compliance:** Icons, metadata, offline permissions, installer/APK packaging and signing preparation.
- [ ] **G — Crash observability:** Optional privacy-respecting diagnostics, user-accessible logs and reproducible bug reports.
- [ ] **H — Release candidate:** Closed beta builds, compatibility matrix and release-blocker triage.

**Exit gate:** Real PCs and Android phones can run and save full matches with tested settings, recoverable errors and stable input.

### v1.0 — Offline PC and Android launch

- [ ] **A — Content freeze:** Lock missions, units, maps, balance rules and safe data migrations.
- [ ] **B — Windows release:** Final portable installer/build, versioned binaries and smoke install.
- [ ] **C — Android release:** Signed release APK/AAB, offline install, touch and Android store checks where applicable.
- [ ] **D — Release QA:** Complete both ten-mission campaigns and skirmish on defined desktop/Android devices.
- [ ] **E — Regression gate:** Automated gameplay, asset, save/load, performance and build pipelines all green.
- [ ] **F — Player documentation:** Controls, requirements, troubleshooting, accessibility and known limitations.
- [ ] **G — Publication:** Versioned GitHub release/installer, optional storefront publication and release notes.
- [ ] **H — Postrelease support:** Crash/bug intake, reproduction templates, hotfix branch rules and verified rollback.

**Exit gate:** Signed/packaged 1.0 builds are published with all release gates, two campaigns, offline skirmish and local saves working.

## Immediate next work: v0.1 Slice A
1. Create `native/project.godot`, minimal native launch/bootstrap scene and native-only `.gitignore` patterns.
2. Show a functioning game window with project title and a visible UI root (not a web wrapper).
3. Add small headless import and scene smoke-test steps; pin the Godot engine/export-template version.
4. Keep Phaser main builds and browser CI passing.
5. PR with evidence; **do not mark Slice A complete until verified**.

## De-risking / future decisions
- The native 3D fixed-angle camera and GDScript stack are current **working assumptions** from planning, subject to an explicit engine/design change if needed.
- Choose a title, art pipeline and target minimum Android hardware before significant asset spending.
- Post-1.0 candidate: optional multiplayer (LAN first, then online 1v1/2v2), replay viewer, more campaigns/maps, Steam/Google Play features; none belong to offline 1.0's critical path.
- The existing browser roadmap remains usable if a web edition is revisited.
