import test from 'node:test';
import assert from 'node:assert/strict';
import { getPlacementHudGeometry, isPlacementTap, getPinchUpdate } from './mobilePlacement.js';
import { getDragPanDelta } from './mobileGestures.js';

for (const [width, height] of [[320, 568], [360, 640], [390, 844], [414, 760], [700, 393]]) {
  test(`placement HUD remains inside ${width}x${height} viewport`, () => {
    const hud = getPlacementHudGeometry(width, height);
    assert.ok(hud.cancel.x - hud.cancel.width / 2 >= 0);
    assert.ok(hud.cancel.x + hud.cancel.width / 2 <= width);
    assert.ok(hud.cancel.y - hud.cancel.height / 2 >= 0);
    assert.ok(hud.title.y < hud.status.y && hud.status.y < hud.hint.y);
    assert.ok(hud.title.y >= hud.bottomTop);
    assert.ok(hud.hint.y < height - 5);
  });
}

test('small single-finger placement tap can confirm', () => {
  assert.equal(isPlacementTap({ x: 100, y: 200 }, { x: 106, y: 204 }), true);
  assert.equal(isPlacementTap({ x: 100, y: 200 }, { x: 108, y: 200 }), true);
});

test('one-finger camera pan never becomes placement', () => {
  const start = { x: 120, y: 250 };
  const end = { x: 165, y: 300 };
  assert.deepEqual(getDragPanDelta(start, start, end), { x: 45, y: 50 });
  assert.equal(isPlacementTap(start, end), false);
  assert.equal(isPlacementTap(start, { x: 121, y: 251 }, { panned: true }), false);
});

test('pinch gesture cannot become placement even if the last finger barely moves', () => {
  assert.equal(isPlacementTap({ x: 200, y: 300 }, { x: 201, y: 301 }, { pinched: true }), false);
  assert.equal(isPlacementTap({ x: 200, y: 300 }, { x: 200, y: 300 }, { pinched: true }), false);
  assert.equal(isPlacementTap(null, { x: 200, y: 300 }), false);
});

test('two-finger pinch zooms and pans using the midpoint', () => {
  const a = getPinchUpdate(null, { x: 100, y: 100 }, { x: 200, y: 100 }, 1, 0.55);
  assert.deepEqual(a.center, { x: 150, y: 100 });
  assert.equal(a.distance, 100);
  assert.equal(a.panX, 0);
  const b = getPinchUpdate(a, { x: 110, y: 120 }, { x: 230, y: 120 }, 1, 0.55);
  assert.deepEqual(b.center, { x: 170, y: 120 });
  assert.equal(b.panX, 20);
  assert.equal(b.panY, 20);
  assert.equal(b.zoom, 1.2);
});

test('pinch zoom stays within camera limits', () => {
  const a = getPinchUpdate(null, { x: 0, y: 0 }, { x: 100, y: 0 }, 1, 0.55);
  assert.equal(getPinchUpdate(a, { x: 0, y: 0 }, { x: 300, y: 0 }, 1, 0.55).zoom, 1.5);
  assert.equal(getPinchUpdate(a, { x: 0, y: 0 }, { x: 10, y: 0 }, 1, 0.55).zoom, 0.55);
});
