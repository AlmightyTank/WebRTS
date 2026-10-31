# Meridian Warfront — Godot Isometric RTS Roadmap to 1.0

**Status:** Active development plan  
**Engine:** Godot 4, pure 2D isometric  
**Branch:** `2d-isometric` (merge into `main` after validation)  
**Product:** This **replaces the current native implementation**; it is not a second game. Preserve legacy native history in a `legacy-native` branch before replacing its files.

## Vision and constraints
- Fixed Red Alert 2-inspired isometric battlefield; camera pans and zooms but does not rotate.
- 128×64 diamond terrain tiles; transparent PNG sprites and sprite sheets for actors/buildings.
- Buildings use one fixed isometric view; infantry begin with four facings and advance to eight; vehicles use eight facings where useful.
- Windows-first native release with Android compatibility considered throughout development.
- Two asymmetric modern military factions, base building, economy, combat, AI skirmish, story campaign, and multiplayer.
- Maintain a playable vertical slice at every milestone. Placeholder art is acceptable until asset production.
- Build multiplayer-compatible simulation rules early; do not promise determinism without tests.

## v0.1 — Isometric Engine Foundation (8 slices)
- [x] **A:** Godot project and initial procedural isometric battlefield foundation (committed; runtime verification outstanding).
- [x] **B:** Procedurally generated PNG-compatible terrain atlas and TileMapLayer (committed; runtime validation and artist-authored PNG import pending).
- [x] **C:** Terrain blending and transitions (procedural feathered overlay committed; Godot runtime verification pending).
- [x] **D:** Smooth camera pan, cursor zoom, map bounds, edge scrolling, desktop drag and mobile pan/pinch (implemented; Godot runtime verification pending).
- [x] **E:** Shared Y-sorted world actor layer and foot-anchor depth rules (implemented; Godot runtime verification pending).
- [ ] **F:** Terrain decorations and collision obstacles.
- [ ] **G:** Map serialization, loading and editor workflow.
- [ ] **H:** Performance profiling, automated checks and Godot runtime validation.

**Exit:** Smooth, correct, editable isometric battlefield with verified Godot runtime.

## v0.2 — Units and RTS Controls (10 slices)
- [ ] **A:** Infantry sprite/animation architecture.
- [ ] **B:** Four-direction movement sprites.
- [ ] **C:** Eight-direction animation compatibility.
- [ ] **D:** Single and box selection.
- [ ] **E:** Right-click movement orders.
- [ ] **F:** Navigation and obstacle avoidance.
- [ ] **G:** Group movement and formations.
- [ ] **H:** Control groups and hotkeys.
- [ ] **I:** Mobile selection and touch orders.
- [ ] **J:** Movement polish and regression tests.

**Exit:** Select and command groups of infantry reliably.

## v0.3 — Buildings and Construction (10 slices)
- [ ] **A:** Building PNG rendering and anchoring.
- [ ] **B:** Command Center scene.
- [ ] **C:** Selection, health and ownership.
- [ ] **D:** Translucent placement preview.
- [ ] **E:** Footprint occupancy and placement validation.
- [ ] **F:** Construction visuals.
- [ ] **G:** Building production queues.
- [ ] **H:** Damage, destruction and rubble.
- [ ] **I:** Base expansion and construction radius.
- [ ] **J:** Construction tests and polish.

**Exit:** Place, build, select and operate a base.

## v0.4 — Resources and Economy (10 slices)
- [ ] **A:** Resource fields and deposits.
- [ ] **B:** Harvester units.
- [ ] **C:** Collection, carrying and delivery.
- [ ] **D:** Refineries.
- [ ] **E:** Power plants.
- [ ] **F:** Power draw, outages and recovery.
- [ ] **G:** Unit/building prices and spending.
- [ ] **H:** Resource tuning and regeneration policy.
- [ ] **I:** Economy HUD and feedback.
- [ ] **J:** Economy tests.

**Exit:** Resource-to-production gameplay loop.

## v0.5 — Combat and Warfare (12 slices)
- [ ] **A:** Target acquisition.
- [ ] **B:** Infantry weapons.
- [ ] **C:** Projectiles and hit registration.
- [ ] **D:** Damage and armor rules.
- [ ] **E:** Infantry deaths.
- [ ] **F:** Vehicle weapons.
- [ ] **G:** Turrets and static defenses.
- [ ] **H:** Explosions, smoke and destruction effects.
- [ ] **I:** Veterancy.
- [ ] **J:** Attack-move and guard orders.
- [ ] **K:** Combat balance.
- [ ] **L:** Combat tests.

**Exit:** Full opposing-army battles.

## v0.6 — Factions and Military Production (12 slices)
- [ ] **A:** Data-driven faction definitions.
- [ ] **B:** Faction One structures.
- [ ] **C:** Faction One infantry.
- [ ] **D:** Faction One vehicles.
- [ ] **E:** Faction Two structures.
- [ ] **F:** Faction Two infantry.
- [ ] **G:** Faction Two vehicles.
- [ ] **H:** Unique faction technologies.
- [ ] **I:** Upgrades.
- [ ] **J:** Asymmetric balance.
- [ ] **K:** Tech trees and production gating.
- [ ] **L:** Faction tests.

**Exit:** Two distinct playable factions.

## v0.7 — AI and Skirmish (12 slices)
- [ ] **A:** AI resource planning.
- [ ] **B:** AI construction.
- [ ] **C:** AI production.
- [ ] **D:** AI scouting.
- [ ] **E:** Attack planning.
- [ ] **F:** Defense and repairs.
- [ ] **G:** Difficulty levels.
- [ ] **H:** Skirmish setup.
- [ ] **I:** Win/loss rules.
- [ ] **J:** Multiple opponents.
- [ ] **K:** AI profiling and balancing.
- [ ] **L:** AI tests.

**Exit:** Complete solo skirmish.

## v0.8 — Multiplayer (12 slices)
- [ ] **A:** Network architecture and authority model.
- [ ] **B:** Deterministic simulation rules and checks.
- [ ] **C:** Command synchronization.
- [ ] **D:** Match lobbies.
- [ ] **E:** Joining and ready checks.
- [ ] **F:** Two-player matches.
- [ ] **G:** Four-player matches.
- [ ] **H:** Teams.
- [ ] **I:** Latency handling.
- [ ] **J:** Disconnect/rejoin behavior.
- [ ] **K:** Desync and network tests.
- [ ] **L:** Multiplayer balance.

**Exit:** Stable online matches.

## v0.9 — Campaign, Interface and Polish (15 slices)
- [ ] **A:** Menus/settings.
- [ ] **B:** RTS command sidebar.
- [ ] **C:** Minimap.
- [ ] **D:** Fog of war and shroud.
- [ ] **E:** Campaign mission framework.
- [ ] **F:** Objective triggers.
- [ ] **G:** Briefings.
- [ ] **H:** Story missions.
- [ ] **I:** Voice lines and sound.
- [ ] **J:** Music/ambience.
- [ ] **K:** Save/load.
- [ ] **L:** Graphics/performance options.
- [ ] **M:** Accessibility.
- [ ] **N:** Tutorial.
- [ ] **O:** UI polish and bug fixing.

**Exit:** Feature-complete playable RTS.

## v1.0 — Full Release (14 slices)
- [ ] **A:** Final balance.
- [ ] **B:** Complete campaign.
- [ ] **C:** Multiplayer stability.
- [ ] **D:** Performance optimization.
- [ ] **E:** Sprite resolution/art consistency review.
- [ ] **F:** Audio/animation polish.
- [ ] **G:** Steam integration.
- [ ] **H:** Achievements.
- [ ] **I:** Save compatibility.
- [ ] **J:** Controls/accessibility review.
- [ ] **K:** Release-candidate testing.
- [ ] **L:** Windows packaging.
- [ ] **M:** Steam store/release preparation.
- [ ] **N:** 1.0 release.

**Exit:** Stable Windows RTS release; Android release separately gated on mobile performance, UI and QA.

## Milestone accounting
| Version | Slices |
| --- | ---: |
| 0.1 | 8 |
| 0.2 | 10 |
| 0.3 | 10 |
| 0.4 | 10 |
| 0.5 | 12 |
| 0.6 | 12 |
| 0.7 | 12 |
| 0.8 | 12 |
| 0.9 | 15 |
| 1.0 | 14 |
| **Total** | **115** |

## Definition of done for each slice
1. Feature implementation with reusable scenes/scripts and documented asset contracts.
2. Relevant automated checks plus in-editor/runtime Godot verification where applicable.
3. Desktop input tested; mobile implications documented or tested.
4. Performance and rendering checked for regressions.
5. Changes committed to `2d-isometric`, CI checked, and PR reviewed before merging to `main`.
6. Update checkboxes only after verifying the slice; no unchecked claims of completion.

## Migration policy
- The existing native implementation is replaced by the Godot isometric version, not shipped as a parallel game.
- Preserve previous native source in a dedicated legacy branch before removal.
- Retain gameplay concepts and reusable design/data where practical; do not assume engine-specific code can be copied directly.
- Keep current WebRTS history intact and avoid deleting existing code before the new Godot foundation is verified.
