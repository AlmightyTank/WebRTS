# Building Placement 2.0 — Slice E: Playtest and Release

## Automated release gates

1. `npm ci && npm test && npm run build` — simulation, state, preview, and gesture regression tests plus production bundle.
2. Chromium playtests using real browser input (not mocked pointer events):
   - Desktop 1280×800: select a building, see preview, reject invalid placement, cancel with Escape, then build with one charge.
   - Mobile 390×844: open build drawer, select a structure, check Cancel/status, pan with one finger, pinch with two, reject invalid placement, cancel, restore controls.
   - Mobile 360×640: select Barracks and construct with a deliberate tap.
3. Browser screenshots are uploaded as the GitHub Actions artifact `placement-browser-screenshots`.
4. Merge to `main` only once BOTH jobs pass.

## Physical-device acceptance

- [ ] Android Chrome: no pan or pinch gesture causes construction.
- [ ] Tap valid ground to place; tap blocked ground remains in build mode.
- [ ] Cancel button restores the standard command dock.
- [ ] Rotate device; ghost and HUD remain visible and usable.
- [ ] Desktop: left-click, Escape, and right-click interactions work.
- [ ] VPS: refreshed HTML loads the newly built assets; verify an actual device.

GitHub passing is not equivalent to testing the real VPS deployment or all hardware.
