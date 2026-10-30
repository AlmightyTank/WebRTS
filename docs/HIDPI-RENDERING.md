# Sharp High-DPI Rendering — Desktop and Mobile

WebRTS uses Phaser 4.2.1. `RESIZE` alone rasterizes into CSS-size canvas pixels,
which the browser enlarges on high-density phones. Phaser 4 does not implement
the old `scale.resolution` fix.

## Implementation

- Start with `Phaser.Scale.NONE` and a backing canvas of logical size × chosen density.
- Use `scale.zoom = 1/density` to keep the visible canvas at logical CSS size.
- Scale world and UI cameras by the same density. The UI camera uses
  `setOrigin(0, 0)` so its rendering and hit tests stay aligned at the top-left.
- Rasterize Phaser text at higher resolution and inversely scale the Text objects.
  `setFontSize()` still accepts logical CSS-size values.
- Translate Phaser's physical pointer positions back to logical positions for
  mobile HUD, canvas touch, pan and pinch. World conversions multiply by density.
- Use the camera's actual physical zoom for camera boundaries and saves.

## Performance budget

The default density is the smaller of the device's pixel ratio and 2×, further
restricted to approximately 2.6 million backing pixels. A typical 390×844 CSS
phone with DPR 3 uses a 780×1688 canvas (2×); 3× would require more than twice
as many pixels again. Large desktop screens may use a smaller density to avoid
GPU fill-rate spikes.

The density is chosen at startup; phone orientation changes are handled by a
ResizeObserver and Phaser ScaleManager, without changing the scale mid-session.

## Validation

`npm test` covers density choice, pointer conversion and text scaling.
CI Chromium playtests use real touch gestures for an emulated DPR-3 Android phone
in addition to existing desktop/mobile/tablet scenarios, checking:
- Backing pixel dimensions versus CSS canvas bounds
- Build-menu touch hit testing at scaled density
- One-finger camera panning and two-finger pinch zoom
- Construction validity and exactly-once resource deductions

Physical-phone verification is still necessary to measure FPS/temperature and
inspect text clarity in actual Chrome/Safari. If frame rate is too low, reduce
the density cap in `src/engine/hiDpi.js`; do not resize the canvas backing
without also updating Phaser cameras and pointer transforms.
