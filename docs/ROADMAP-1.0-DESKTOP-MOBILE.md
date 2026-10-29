# WebRTS — Desktop & Mobile RTS 1.0 Master Roadmap

**Status:** planned after building-placement 2.0 slices A–E; baseline commit `6fdeec67830bae136b64c02e9130fdeac4980afe`.
**Reference feel:** the strategic depth and immediacy of classic Red Alert 2, rebuilt as an original intellectual property with original names, graphics, voices, maps, music, technology and story.
**Release platforms:** modern desktop browsers, Android/iOS mobile browsers and tablets; installable PWA is planned.

## Definition of the 1.0 product

- Two genuinely different factions: **Iron Collective** and **Vanguard League**.
- 10 authored story missions per faction (20 total), narrative briefings/debriefings and persistent progress.
- 12 polished skirmish maps, three AI difficulties, solo skirmish, casual online 1v1 and 2v2 crossplay.
- Ground/air/naval combat; harvesting, deployable HQ, radar, power, tech trees, walls, garrisons, engineers, veterancy, infiltration, bridges and faction-specific superweapons.
- A content target of roughly 50–70 **distinct** units, buildings and specialist entities across shared and faction-specific rosters; adjust after balance/asset testing.
- Classic mouse/keyboard controls on desktop and thoughtfully adapted touch gestures and command HUDs on phones and tablets, with gameplay parity.
- Saves/checkpoints for solo play, spectator/replay for multiplayer, meaningful accessibility and device performance settings.
- Fully original fiction, media and visual design; **do not reuse Red Alert 2 code, art, names, soundtrack, cinematics or maps**.

## What exists already

Phaser 4 + Vite frontend; JavaScript fixed-step simulation; seeded map; initial 7 unit classes, 7 building classes, 2 starter faction records; commands for move/attack/defend/build/produce/repair/sell; resource harvesting, queues, power/supply, baseline enemy AI, building-placement 2.0 and cross-device Chromium acceptance tests. These are prototypes, not completed production-quality systems. No dedicated online server, mission framework or complete air/naval game exists yet.

**Immediate technical finding:** the Git tree includes tracked `node_modules` paths. Clean tracked dependencies as the first slice before a major refactor.

## Desktop/mobile design contract

| Area | Desktop browser | Phone/tablet browser |
| --- | --- | --- |
| Selection | Click, box drag, shift click, double click, 0–9 groups | Tap, dedicated multiselect/lasso, double tap same type, quick groups |
| Orders | Right-click context, hotkeys, queued waypoints | Context order dock, explicit attack/move mode, large target affordances |
| Camera | Mouse wheel, keyboard, edge scroll, minimap | Finger pan, two-finger pinch/pan, minimap jump |
| Base building | Sidebar click → live green/red ghost → place | Drawer selection → closes → ghost preview → tap to place or Cancel |
| Production | Persistent sidebar with detailed queues | Drawer with production badges/queue and compact status |
| Alerts | Onscreen feed, voice, minimap ping | Brief toast, edge alert, minimap jump, optional vibration |
| Performance | 60 FPS aim with scaling for large armies | 30 FPS floor on supported midrange devices, 60 FPS target where possible |
| Multiplayer | Mouse/keyboard without exclusive mechanics | Same simulation and orders with adapted touch affordances |

Target performance numbers are **acceptance goals**, not measured claims. Establish measured device classes during profiling.

## Execution rules for every slice

1. Implement on a focused feature branch and make a single reviewable engine/content/UX change.
2. Extend unit, simulation and browser acceptance tests as applicable; test desktop and mobile controls.
3. Keep gameplay rules platform-neutral. A mobile UI may simplify input but not give different combat or economy rules.
4. CI must pass tests, production build and browser playtests. Merge to `main` only after green.
5. Save and multiplayer protocol changes require compatibility notes; avoid losing player campaign progress.
6. Each milestone ends with a playable acceptance scenario and a short testing document.
7. Deploy the hosted site/server separately from GitHub merges, and verify actual device behavior before release.

## Complete version-by-version slices

### v0.2 — Engine, data and repository foundation

- **Slice A:** Repository hygiene: remove tracked node_modules/build outputs, add .gitignore, lock dependency versions and document boot/deploy.
- **Slice B:** Separate app shell, scene renderer, camera/input adapter, HUD, simulation and content registries without changing behavior.
- **Slice C:** Define versioned commands/events and entity schemas; reject malformed commands at boundaries.
- **Slice D:** Determinism: seeded simulation, stable entity IDs, tick-indexed commands, snapshot tests and cross-run state hashes.
- **Slice E:** Save/load full in-progress skirmish state with schema migration and restart tests.
- **Slice F:** Introduce data-driven units/buildings/weapon/armor/ability/faction definitions and validation tooling.
- **Slice G:** Performance diagnostics, slow-frame tracing, error panel and reproducible debug scenarios.
- **Slice H:** Regression suite including browser smoke tests in desktop, portrait/landscape phone and tablet layouts.

**Exit gate:** Simulation and assets are modular; a match can be serialized and replayed deterministically; CI stays green.

### v0.3 — Classic RTS orders and desktop/mobile interaction

- **Slice A:** Centralize player intents (select, move, attack, attack-move, defend, patrol, stop, queue, build, ability); both input schemes dispatch identical commands.
- **Slice B:** Desktop: box/shift selection, control groups 0–9, double-click same-type selection, right-click context orders, hotkeys and edge scroll.
- **Slice C:** Mobile: tap select, multiselect/lasso mode, double-tap similar units, large order targets, optional long-press inspect and haptic feedback.
- **Slice D:** Orders: attack-move, force-fire, guard, patrol, stance, rally points, waypoint chaining and command queue indicators.
- **Slice E:** Camera/minimap: finger pan, pinch zoom, mouse wheel/drag, quick jump to alerts, pinch-safe building placement and minimap orders.
- **Slice F:** Separate HUD compositions for desktop sidebar, tablet and phone; landscape-first phone layout with fully usable portrait fallback.
- **Slice G:** Production sidebar, context cards, selection detail, grouped unit commands and tooltips without blocking the battlefield.
- **Slice H:** Browser gesture tests and UX passes for touch, mouse, keyboard and mixed input including incorrect taps under overlays.

**Exit gate:** A player can command dozens of units, control groups and build a base without fighting the UI on any supported screen.

### v0.4 — Maps, terrain, navigation, line-of-sight and fog

- **Slice A:** Create map schema, terrain tiles, obstacles, spawn zones, neutral structures, ore fields and height/land-water metadata.
- **Slice B:** Build recognizable 2.5D RTS/isometric-style terrain and map renderer with original visual assets.
- **Slice C:** Add land classes, water/shoreline transitions, cliffs, walls and destructible environmental objects.
- **Slice D:** Improve pathfinding with dynamic blockers, unit radii, path replanning and stuck-unit recovery.
- **Slice E:** Squad formations, group steering, traffic priority and sensible arrival around occupied targets.
- **Slice F:** Per-player shroud/fog-of-war, vision, detection and minimap visibility without leaking hidden enemy positions.
- **Slice G:** Destructible/repairable bridges and crossable chokepoints with path updates.
- **Slice H:** Pathfinding stress scenarios, fog correctness tests and performance checks on midrange Android and desktop.

**Exit gate:** Multi-terrain maps have reliable unit traffic, shroud, vision and passable land/water transitions.

### v0.5 — Economy, base construction and production depth

- **Slice A:** Deployable headquarters/MCV mechanic; base placement radius, undeploy rules and expansion sites.
- **Slice B:** Ore fields: finite resources, variable richness, visual depletion and map-authored replenishment rules.
- **Slice C:** Harvesters: reliable collection, refinery docking, refineries spawning harvesters and harassment/escort behaviors.
- **Slice D:** Credits, construction queues, production speeds, shared resource reservations and repeat-order safeguards.
- **Slice E:** Power generation/consumption, brownout effects, radar access and visible power meters.
- **Slice F:** Tech prerequisites and unlock overlays for factories, defenses and advanced laboratories.
- **Slice G:** Repair/sell, walls/gates, buildings under construction, damage states and construction footprints.
- **Slice H:** Factory queues, multiple producers, rally points, pause/cancel/reorder/refunds and save/load integration.

**Exit gate:** Players can start with a deployable headquarters, develop income and tech, and complete a full base-building loop.

### v0.6 — Ground combat and veteran unit systems

- **Slice A:** Damage model: armor tags, weapon types, rate of fire, accuracy, range and damage falloff.
- **Slice B:** Infantry roles: rifle, anti-armor, anti-air, engineer, scout, specialist and anti-structure units.
- **Slice C:** Vehicles: recon, APC, main battle tank, heavy armor, artillery, mobile support and dedicated anti-air.
- **Slice D:** Projectile and impact effects: hitscan, shells, missiles, splash, friendly-fire rules and destructible target damage.
- **Slice E:** Garrisonable neutral buildings, infantry cover, ungarrison commands and urban map interactions.
- **Slice F:** Engineer capture/repair, neutral-tech takeover and anti-capture defenses.
- **Slice G:** Veterancy, elite modifiers, combat experience, regeneration/service repair and visible rank badges.
- **Slice H:** Combat AI orders, target priorities, force fire, attack-move and regression tests for pathing/combat/survival.

**Exit gate:** Infantry and armored engagements are tactical, readable, and reliable in high-unit-count fights.

### v0.7 — Two truly asymmetric factions and tech trees

- **Slice A:** Define original fictional history, design rules and tactical identities for Iron Collective and Vanguard League.
- **Slice B:** Iron Collective: heavy armor, battlefield fortification, rugged economy and faction-specific roster.
- **Slice C:** Vanguard League: speed, precision, reconnaissance and high-technology roster.
- **Slice D:** Faction-specific building visuals, names, production audio, voices and silhouette readability.
- **Slice E:** Tech trees, prerequisites, research-like unlocks and special faction structures.
- **Slice F:** Hero/specialist units and limited faction-specific tactical powers.
- **Slice G:** Neutral capturable technologies, optional country/subfaction doctrines and skirmish configuration.
- **Slice H:** Mirror and cross-faction balance suites, AI checks and equal mobile/desktop command access.

**Exit gate:** Iron Collective and Vanguard League play differently but are both viable on every standard skirmish map.

### v0.8 — Air, sea and mixed-terrain warfare

- **Slice A:** Flying/ground/naval movement classes, altitude and shoreline path restrictions.
- **Slice B:** Airfields and aircraft production with fuel/ammo, landing, reload and returning home.
- **Slice C:** Air targets: fighters, bombers, transports and air-defense systems.
- **Slice D:** Naval yards with water-only placement, ship lanes, collision and dock repair.
- **Slice E:** Surface ships, submarines/stealth ships, detection sonar and anti-sub counters.
- **Slice F:** Amphibious transports, shore landings and cross-domain group orders.
- **Slice G:** Anti-air/anti-naval counters, mixed-domain targeting and cinematic combat feedback.
- **Slice H:** Coastal maps, balance tests and performance tests with simultaneous air, sea and ground battles.

**Exit gate:** The same match can support infantry, armor, aircraft, warships and amphibious movement.

### v0.9 — Advanced tactics and superweapons

- **Slice A:** Stealth, disguise/infiltration, detection and temporary intel disruption with counters.
- **Slice B:** Deployable units, mobile artillery transformation and siege/defense modes.
- **Slice C:** Special combat abilities with cooldowns, energy/cost gating and clear cast previews.
- **Slice D:** Superweapon buildings, charge timers, warning indicators and target confirmation.
- **Slice E:** Two original faction superweapon systems with unique impact, visuals and counterplay.
- **Slice F:** Civilian/neutral capture objectives, map-control powers and tactical denial mechanics.
- **Slice G:** Balance caps and match rules for superweapon enable/disable and cooldown configuration.
- **Slice H:** Network-ready command serialization, replayable effects and mobile target UI tests.

**Exit gate:** Late-game technology creates impactful strategic choices with visible warnings and counterplay.

### v0.10 — Complete offline skirmish and intelligent AI

- **Slice A:** Skirmish setup: map, faction, spawn, team, AI slot, resources, tech level and victory rule.
- **Slice B:** AI build orders, construction priorities and resource recovery.
- **Slice C:** AI scouting, map memory and fog-respecting decision-making.
- **Slice D:** AI unit compositions, raids, retreats, base defense and adaptive threat evaluation.
- **Slice E:** Difficulty settings with defined behavior changes rather than relying solely on resource cheating.
- **Slice F:** Alliances, teams, starting locations, cease-fire and surrender rules.
- **Slice G:** Win/lose states, pause/save/restart, post-match breakdown and rematch.
- **Slice H:** Skirmish soak tests, map-specific AI validation and 1v1/2v2 offline scenarios.

**Exit gate:** A fresh player can configure and finish fair, enjoyable skirmishes on phone or desktop.

### v0.11 — Complete original art, effects, sound and UI identity

- **Slice A:** Art bible: original factions, silhouettes, color language, terrain palettes and production constraints.
- **Slice B:** Building sprites/models and construction/damage/destruction animation states.
- **Slice C:** Infantry, ground vehicle, aircraft and ship animations, selection rings and shadows.
- **Slice D:** Map terrain, ore, roads, trees, bridges, water, city props and destructible scenery.
- **Slice E:** Projectile, impact, explosion, smoke, fire and superweapon VFX with reduced-motion option.
- **Slice F:** Original soundtrack, ambience, unit acknowledgements, alerts and mixing/audio preferences.
- **Slice G:** HUD skin, icons, radar, loading states, briefing visuals and accessibility contrast.
- **Slice H:** Asset atlas budgets, compressed audio, low-spec render mode, visual regression screenshots and art QA.

**Exit gate:** A full match looks and sounds like a coherent finished game rather than a debug prototype.

### v0.12 — Mission scripting, campaign progression and authoring tools

- **Slice A:** Versioned campaign/mission schemas, authored map references, spawn loadouts and briefing data.
- **Slice B:** Objective graph: destroy, defend, capture, escort, survive, rescue, build and gather.
- **Slice C:** Event triggers: timer, region entered, unit killed, structure lost, objective completed and reinforcement spawn.
- **Slice D:** Scripted camera moments, dialogue, portrait messages, briefings/debriefings and cutscene sequencing.
- **Slice E:** Mission and map editor tools: draw terrain, place entities, define AI scripts and validate win/loss.
- **Slice F:** Save slots, checkpoints, autosave, mission retry and campaign progress/unlocks.
- **Slice G:** Difficulty, optional objectives, cinematics-skip/rewatch and mission telemetry for tuning.
- **Slice H:** Author 3 test missions and verify portrait/landscape/desktop experience and save compatibility.

**Exit gate:** A content author can create a complete mission with objectives and story without modifying the engine.

### v0.13 — Iron Collective campaign — 10 missions

- **Slice A:** M01: Into the Ash — establish a command base and secure an ore route.
- **Slice B:** M02: Broken Line — defend mining convoys and rebuild a ruined bridge.
- **Slice C:** M03: Iron Harvest — raid an enemy supply network using armored escorts.
- **Slice D:** M04: Hostile City — garrison streets and capture key neutral structures.
- **Slice E:** M05: The Crossing — execute a combined naval and ground landing.
- **Slice F:** M06: Black Sky — survive raids and disable an enemy airfield.
- **Slice G:** M07: Silent Wire — infiltrate a radar facility and steal battlefield intelligence.
- **Slice H:** M08: The Foundry — establish forward production under siege.
- **Slice I:** M09: Countdown — assault a superweapon before its timer expires.
- **Slice J:** M10: The Last Directive — multi-stage endgame mission, cinematic ending and progression check.

**Exit gate:** Iron campaign is beatable from a clean save, with a complete coherent arc, briefings and ending.

### v0.14 — Vanguard League campaign — 10 missions

- **Slice A:** M01: Signal Lost — reconnaissance, extraction and first contact.
- **Slice B:** M02: Lightning Run — disrupt a supply convoy with fast mobile units.
- **Slice C:** M03: Hold the Grid — protect vulnerable power and radar networks.
- **Slice D:** M04: City of Glass — combine infantry cover and engineering objectives.
- **Slice E:** M05: Blue Water — naval interception and a coastal rescue.
- **Slice F:** M06: Air Superiority — secure airfields and counter heavy defenses.
- **Slice G:** M07: Ghost Protocol — infiltrate a fortress without alerting the entire base.
- **Slice H:** M08: The Fault Line — demolish chokepoints and outmaneuver armored columns.
- **Slice I:** M09: False Sunrise — detect decoys and interrupt a late-game superweapon.
- **Slice J:** M10: Dawn Protocol — full-spectrum final assault, ending and campaign completion checks.

**Exit gate:** Vanguard campaign is a distinct playable story, not a mirrored set of Iron missions.

### v0.15 — Authoritative online multiplayer core

- **Slice A:** Extract simulation into a headless Node server runtime without Phaser dependency.
- **Slice B:** Define match protocol: room IDs, player commands, ticks, hashes, snapshots and version compatibility.
- **Slice C:** Server command authorization, rate limiting, anti-spam and hidden-information filtering.
- **Slice D:** Private room creation, invite codes, ready states, faction/map choices and game countdown.
- **Slice E:** Transport and synchronization: WebSocket delivery, server tick, client interpolation and correction.
- **Slice F:** Reconnect after mobile backgrounding/network loss, grace time, catch-up and forfeit rules.
- **Slice G:** 1v1 match lifecycle, disconnect handling, surrender, results and durable result reporting.
- **Slice H:** Latency, packet-loss, state-drift, cheating and mixed desktop/mobile browser stress testing.

**Exit gate:** Two players can finish a fair 1v1 in an authoritative server match, with reconnection and verified results.

### v0.16 — Multiplayer modes, replays and crossplay

- **Slice A:** 2v2 teams, alliances, shared team vision rules and synchronized victory conditions.
- **Slice B:** Casual public lobby, invites, friends/room codes and server discovery.
- **Slice C:** Optional guest and account identity, display names, consent and safe data retention.
- **Slice D:** Team and opponent communication: pings, limited preset messages, report/mute safeguards.
- **Slice E:** Replay file format, command stream playback, observer camera and match timeline.
- **Slice F:** Fair-input controls: smart touch selection without hidden extra commands; optional platform-inclusive queues.
- **Slice G:** Desktop/mobile matchmaking test matrix across Wi-Fi/cellular and reconnect/replay corruption cases.
- **Slice H:** Dedicated server deploy, monitoring, backups, health checks and operational runbooks.

**Exit gate:** Casual 1v1 and 2v2 work between desktop and mobile and can be observed or replayed.

### v0.17 — Mobile/desktop performance, accessibility and saves

- **Slice A:** Phone: 320–430 CSS px, portrait and landscape HUD, safe areas, large tap targets and gesture blocking.
- **Slice B:** Tablet: flexible command sidebar, tactical minimap, pen/mouse and keyboard coexistence.
- **Slice C:** Desktop: 720p–4K, ultrawide UI scaling, customizable keyboard shortcuts and precise pointer control.
- **Slice D:** Rendering budget: unit culling, batching, animation LOD, dynamic effects settings and adaptive quality.
- **Slice E:** Simulation pathfinding costs, input response budgets, battery/thermal tuning and mobile low-memory handling.
- **Slice F:** Accessibility: scalable text, colorblind-friendly factions, high contrast, reduced motion and subtitles.
- **Slice G:** Single-player local autosave, optional cross-device cloud-save design and PWA install/offline boot.
- **Slice H:** Browser matrix, orientation changes, interruptions, lifecycle tests, security headers and privacy checks.

**Exit gate:** Both platforms hit documented performance targets; saves, settings and input preferences persist reliably.

### v0.18 — Final balance, content QA and release candidate

- **Slice A:** Build 12 polished skirmish maps spanning urban, industrial, forest, desert, coastal and river terrain.
- **Slice B:** Complete tutorial, first-session guidance, help index and contextual command teaching on both platforms.
- **Slice C:** Balance both factions and all tiers, economy openings, air/naval access and superweapon counterplay.
- **Slice D:** Campaign start-to-end regression, checkpoint migrations and difficulty consistency.
- **Slice E:** Cross-platform multiplayer load/soak, replay verification, reconnect tests and anti-cheat review.
- **Slice F:** Compatibility sweep across desktop Chrome/Firefox/Edge/Safari and mobile Chrome/Safari where supported.
- **Slice G:** Release packaging, versioned save/protocol compatibility, accessibility review and third-party asset/license audit.
- **Slice H:** Release-candidate freeze, crash triage, performance profiles and beta feedback closure.

**Exit gate:** All campaigns/skirmish/multiplayer/controls meet acceptance criteria without critical known issues.

### v1.0 — Launch and maintain the complete game

- **Slice A:** Finalize original naming/branding, EULA/privacy, website, onboarding and help documentation.
- **Slice B:** Production deploy of frontend, game server and persistence with HTTPS, domain routing and rollback.
- **Slice C:** Data backup/restore verification, match recovery, user report/abuse workflow and server alerts.
- **Slice D:** Public full-playthrough acceptance: two 10-mission campaigns, offline skirmish, casual 1v1/2v2.
- **Slice E:** Release validation on real Android/iPhone/tablet and desktop hardware; graphics presets and input check.
- **Slice F:** Publish 1.0 changelog and marketing assets; monitor crashes and performance, use hotfix-only release policy.
- **Slice G:** Establish post-launch support, issue triage and balance patch cadence; preserve backwards-compatible saves.

**Exit gate:** The same production build is live, monitored, documented and fully playable on desktop and mobile.

## Launch quality gates

A: Every campaign mission is completable, restartable and save-compatible on desktop and mobile. B: The 12 skirmish maps support all tech/terrain families. C: Both factions have clear, balanced counters. D: Desktop and mobile can complete crossplay 1v1 and 2v2 with disconnect/reconnect handling. E: Multiplayer server commands are authoritative and never disclose fogged enemy data. F: Every construction/production purchase is charged once, with correct refunds. G: Accessibility/performance/device matrix and original media license audit pass. H: VPS production deploy, rollback, backups and alerting verified.

## Beyond 1.0 (explicitly not launch blockers)

- Third playable faction with its own 8–10 mission campaign, reminiscent of an expansion rather than a reskin.
- Public map sharing, curated community mods, co-op campaigns, ranked ladder, tournaments and richer observer tools.
- Further languages, optional desktop distribution, advanced touch command automation within fair-play limits.

## First next action

**Start with v0.2 Slice A:** remove tracked dependencies, normalize `.gitignore`, and confirm clean `npm ci`, unit tests, production build and Chromium tests. This comes before large game expansions.
