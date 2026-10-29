import test from 'node:test';
import assert from 'node:assert/strict';
import { isTouchGesturePointer, getDragPanDelta } from './mobileGestures.js';

test('recognizes native and synthetic touch input', () => {
  assert.equal(isTouchGesturePointer({ event: { pointerType: 'touch' } }), true);
  assert.equal(isTouchGesturePointer({ event: { type: 'touchmove' } }), true);
  assert.equal(isTouchGesturePointer({ event: { pointerType: 'mouse' } }, true), true);
  assert.equal(isTouchGesturePointer({ event: { pointerType: 'mouse' } }, false), false);
});
test('short motions remain taps', () => {
  const p = { x: 100, y: 100 };
  assert.equal(getDragPanDelta(p, p, { x: 108, y: 100 }), null);
});
test('the first touch pan includes all movement and subsequent moves are incremental', () => {
  const p = { x: 100, y: 100 };
  assert.deepEqual(getDragPanDelta(p, p, { x: 125, y: 90 }), { x: 25, y: -10 });
  assert.deepEqual(getDragPanDelta(p, { x: 125, y: 90 }, { x: 130, y: 87 }, true), { x: 5, y: -3 });
});
