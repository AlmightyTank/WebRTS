# Changelog

## 0.2.0 — Engine Foundation (desktop and mobile)

### Added
- Modular Phaser bootstrap, game scene, terrain renderer, camera and input adapters, and UI geometry
- Versioned command/event contracts and content data validation
- Deterministic seeded random stream, command journal, state hashes and save/load validation
- Full skirmish save/load and autosaves; touch Pause with Save/Load, desktop Shift+S/Shift+O (F6/F7 optional)
- Data registries for maps, factions, units, buildings, weapons, armor and abilities
- Optional performance/FPS debugging overlay (H) and dev-only stress scenarios (J)
- Chromium regression matrix for desktop, phone portrait/landscape, and tablet

### Compatibility and deployment
- Existing RTS combat and build commands remain compatible.
- Saves are versioned local-browser data; there is no account/cloud sync yet.
- Migrate old v0 internal snapshots when valid; reject unsupported save versions.
- Update local installs with `npm ci`, test, build and deploy static assets to the verified Nginx root.
- No VPS deployment is implied by merging this code.

### Known scope limits
This milestone is engine infrastructure for the larger Red Alert-style roadmap, not
the completed campaigns, online multiplayer, air/naval game or final artwork.
