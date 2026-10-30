# WebRTS — Roadmap to 1.0

> **Status (October 29, 2026):** v0.2 **COMPLETE** (Slices A–H merged to `main`; unit/build and Chromium desktop/mobile/tablet CI passed). **Up next: v0.3 Slice A — shared RTS player commands.** Future versions below are planned, not completed.
>
> **Detailed implementation plan:** [Desktop & Mobile 1.0 Master Roadmap](docs/ROADMAP-1.0-DESKTOP-MOBILE.md) · [v0.2 Foundation Release](docs/V0.2-ENGINE-FOUNDATION-RELEASE.md) · [High-DPI Rendering](docs/HIDPI-RENDERING.md) · [Changelog](CHANGELOG.md)

WebRTS is an original, browser-based real-time strategy game built for **desktop and mobile as equal platforms**. The design target is the immediacy, base-building depth, large-scale battles and two-sided storytelling of classic *Red Alert 2*, while using **original** factions, fiction, art, music, units, maps and code. The current prototype is built with Phaser 4, Vite and a fixed-step JavaScript simulation.

## What shipping 1.0 means

Players can start from the main menu and complete a full match or campaign on a desktop or phone without developer assistance:

- **Two distinct factions:** Iron Collective (heavier, durable army and fortifications) and Vanguard League (fast, precise units, scouting and technology).
- **Two story campaigns:** 10 authored missions per faction (20 total), with briefings, objectives, scripted events, checkpoints and endings.
- **Skirmish:** 12 polished maps, three AI difficulty levels, configurable teams and victory rules, and offline single-player.
- **Core RTS:** deployable HQ, ore harvesting and refineries, credits, power, production queues, tech trees, infantry, armor, air, navy, engineers, garrisons, veterancy, stealth and superweapons.
- **Online:** server-authoritative casual 1v1 and 2v2 with mixed desktop/mobile players, reconnection and replays.
- **Presentation and access:** original artwork, readable effects, audio, robust save/load, performance presets and accessibility settings.
- **Content budget:** approximately 50–70 distinct units, structures and specialist entities, finalized only after balance and asset testing.

Mobile uses touch-oriented input and compact HUDs, **not** easier economy, different damage values or reduced units/technology. Do not reuse copyrighted Red Alert code, maps, art, dialogue, music or characters.

## Milestone tracker (18 versions, 147 development slices)

Completion means a version's **all** slices, acceptance scenario and CI gate have passed on `main`, not simply that an initial prototype exists.

| Version | Slices | Deliverable / definition of done | Status |
| --- | ---: | --- | --- |
| **0.2** Engine foundation | A–H (8) | Modular simulation, validated data, deterministic saves, diagnostics, desktop/mobile/tablet CI | **Complete** |
| **0.3** RTS input and HUD | A–H (8) | Accurate selection, orders, touch gestures, camera and usable UI on all screens | **Next** |
| **0.4** Terrain and fog | A–H (8) | Map terrain, robust group pathfinding, vision and fog-of-war | Planned |
| **0.5** Base and economy | A–H (8) | Deploy HQ, harvest ore, build a base, manage power/tech and train units | Planned |
| **0.6** Ground combat | A–H (8) | Infantry, vehicles, weapon/armor counters, garrisons, capture and veterancy | Planned |
| **0.7** Factions | A–H (8) | Iron Collective and Vanguard League have distinct, viable rosters and tech | Planned |
| **0.8** Air and naval | A–H (8) | Aircraft, ships, submarines, amphibious transfers and counters | Planned |
| **0.9** Advanced warfare | A–H (8) | Stealth, infiltration, abilities, siege modes and original superweapons | Planned |
| **0.10** Offline skirmish | A–H (8) | Setup, smarter AI, 3 difficulties, win/lose states and match results | Planned |
| **0.11** Art and sound | A–H (8) | Original final assets, FX, soundtrack, unit voices and coherent UI | Planned |
| **0.12** Mission framework | A–H (8) | Objectives, trigger scripting, editor, progress, checkpoints and test missions | Planned |
| **0.13** Iron campaign | A–J (10) | Ten finished Iron Collective missions and ending | Planned |
| **0.14** Vanguard campaign | A–J (10) | Ten finished Vanguard League missions and ending | Planned |
| **0.15** Online core | A–H (8) | Authoritative headless server, lobby, sync, fair 1v1 and reconnect | Planned |
| **0.16** Crossplay and replay | A–H (8) | Casual 2v2, room flow, team controls, observer and replays | Planned |
| **0.17** Platform polish | A–H (8) | Mobile/desktop optimization, accessibility, persistence and PWA | Planned |
| **0.18** Release candidate | A–H (8) | 12 polished maps, tutorial, balance, full QA and release freeze | Planned |
| **1.0** Public release | A–G (7) | VPS deploy, verified full playthroughs, rollback, monitoring and support | Planned |

**Completion:** 8 / 147 slices implemented in v0.2; the remaining **139 slices** are tracked by the master specification. The count describes deliverable slices, not comparable estimates of effort.

## Execution sequence and playable checkpoints

| Stage | Versions | Playable milestone |
| --- | --- | --- |
| Foundation and controls | 0.2–0.4 | Reliable desktop/touch battlefield, navigation, terrain and fog |
| Complete basic RTS | 0.5–0.7 | Harvest, build, produce, attack and win as either faction |
| Complete warfare and skirmish | 0.8–0.10 | Combined ground/air/sea battles against configurable AI |
| Identity and authoring | 0.11–0.12 | Production-quality audiovisual direction and scripted test missions |
| Story completion | 0.13–0.14 | Two distinct, finishable 10-mission campaigns |
| Connected play | 0.15–0.16 | Reliable cross-platform 1v1/2v2 and match replays |
| Ship | 0.17–1.0 | Optimized, tested, deployed and supported 1.0 |

**Dependencies:** Input and deterministic simulation underpin pathfinding; pathfinding and combat underpin factions and AI; stable mechanics underpin campaign missions; authoritative server and reproducible commands underpin online play. Build reusable systems first and avoid one-off code for individual missions.

## Current sprint — v0.3: desktop and mobile RTS controls

No v0.3 slice is marked complete yet. Implement in sequence and update this section only after merge and verification.

- [ ] **A — Shared player intents.** Centralize select, move, attack, attack-move, defend, patrol, stop, command queue, build and ability orders behind platform-neutral inputs. Preserve existing construction and save contracts.
- [ ] **B — Desktop controls.** Click/box/shift selection, double-click same-type selection, right-click contextual orders, control groups 0–9, hotkeys and edge scrolling.
- [ ] **C — Mobile selection.** Tap, multi-select/lasso, double-tap similar units, large command targets, long-press inspection and non-conflicting gesture behavior.
- [ ] **D — Advanced unit orders.** Attack-move, force-fire, patrol, guard, stance, rally points, chained waypoints and visible queued-order feedback.
- [ ] **E — Camera and minimap.** One-finger drag pan, two-finger pinch, desktop camera controls, minimap jumps/orders and safe placement near HUD overlays.
- [ ] **F — Adaptive HUD.** Distinct desktop, tablet and phone compositions; landscape-first phone layout with functional portrait fallback.
- [ ] **G — Production and selection UI.** Context cards, unit groups, production queues, tooltips and information that remains accessible without obscuring the battlefield.
- [ ] **H — Acceptance and regression.** Automated mouse/keyboard/touch tests; desktop, phone portrait/landscape and tablet screenshots; wrong-target and overlay tap checks.

**v0.3 acceptance scenario:** A fresh player on a desktop and on a phone can select a mixed army, move and attack, use queued orders, pan and zoom, inspect the minimap, place a new building with a valid preview, and produce units. No accidental duplicate orders, unwanted camera jumps or blocked touch targets.

**Regression priorities:** Keep the Building Placement 2.0 preview (a completed building is not freely draggable), the high-DPI pointer mapping, one-finger map panning, two-finger zoom, correct purchase/refund handling, and v0.2 save/load functioning throughout the controls rewrite.

## End-to-end slice delivery contract

Every slice should be reviewable and playable, not just code-complete.

1. **Implement on a focused branch.** Reference the target version and letter: `feature/v0.3-slice-a-commands`, etc. Keep unrelated features out.
2. **Prove behavior.** Add/extend simulation tests and browser acceptance for any changed player input or UI. Include save compatibility checks when commands/state change.
3. **Use one ruleset.** Desktop and mobile send equivalent game commands. UI adaptations must not silently change combat, economy or fog rules.
4. **Pass CI.** Run `npm ci`, `npm test`, `npm run build` and `node --test tests/browser-placement.mjs`. Both `test-and-build` and `browser-playtest` must pass before merging.
5. **Test real devices.** Chromium touch emulation is a regression tool, not proof of actual Android/iOS smoothness, thermal behavior or visual sharpness.
6. **Document the result.** Update this tracker, the appropriate detailed milestone notes and `CHANGELOG.md` (when cutting a release), including screenshots and a manual playtest scenario.
7. **Deploy separately.** A green GitHub build does not mean the VPS-hosted game updated. Verify Nginx assets, server health where applicable, backup and rollback after deployment.

### Release gates

A milestone can be checked off only if its slices are merged to `main`, tests and production build pass, required device/playtest flows succeed, and there is no known blocker for the milestone's stated exit criteria. Maintain backward compatibility of local saves and future multiplayer protocols through explicit migrations.

**1.0 is blocked until:** both 10-mission campaigns are completable; all 12 skirmish maps are shippable; both factions are balanced; online 1v1/2v2 and reconnect work on desktop/mobile; fog-of-war information cannot leak from the server; every purchase is charged once with correct refunds; accessibility/performance targets and asset-license audit pass; VPS rollback, persistence, monitoring and backups are verified.

## Post-1.0 candidates — not launch blockers

A third faction and expansion campaign, ranked ladder, mods/map sharing, cooperative missions, tournaments, optional native desktop distribution and additional languages are **future projects**, not part of 1.0.

---

**Start here:** [v0.3 Slice A in the master roadmap](docs/ROADMAP-1.0-DESKTOP-MOBILE.md#v03--classic-rts-orders-and-desktopmobile-interaction). The complete A–H/A–J slice specifications, exit gates and 20 campaign mission outlines live in that document; this root file is the living status board.
