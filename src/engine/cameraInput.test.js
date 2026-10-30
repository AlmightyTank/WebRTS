import test from 'node:test';
import assert from 'node:assert/strict';
import { worldPoint, zoomAtPoint, getTouchPointers } from './cameraInput.js';

test('zoom keeps the world location under cursor stable', () => {
  const camera = {
    scrollX: 125, scrollY: 200, zoom: 1,
    getWorldPoint(x, y) { return { x: this.scrollX + x / this.zoom, y: this.scrollY + y / this.zoom }; },
    setZoom(value) { this.zoom = value; }
  };
  const before = worldPoint(camera, { x: 100, y: 120 });
  zoomAtPoint(camera, 100, 120, 1.25);
  assert.deepEqual(worldPoint(camera, { x: 100, y: 120 }), before);
});

test('touch pointer collection is read from manager and ignores inactive mouse', () => {
  const touch = { id: 3, isDown: true, pointerType: 'touch' };
  const mouse = { id: 1, isDown: true, pointerType: 'mouse' };
  assert.deepEqual(getTouchPointers({ manager: { pointers: [mouse, touch] } },
    pointer => pointer.pointerType === 'touch'), [touch]);
});
