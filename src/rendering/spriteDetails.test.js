import test from 'node:test';
import assert from 'node:assert/strict';
import { drawBuildingDetails, drawUnitDetails } from './spriteDetails.js';

function mockGraphics() {
  const calls = [];
  const graphics = {
    fillStyle(...args) { calls.push(['fillStyle', ...args]); return graphics; },
    fillRect(...args) { calls.push(['fillRect', ...args]); return graphics; },
    lineStyle(...args) { calls.push(['lineStyle', ...args]); return graphics; },
    lineBetween(...args) { calls.push(['lineBetween', ...args]); return graphics; }
  };
  return { graphics, calls };
}

test('every built structure has original, fully finite crisp detail rectangles', () => {
  for (const type of [
    'command_core', 'refinery', 'power_plant', 'machine_shop',
    'defense_grid', 'service_depot', 'barracks', 'future_building'
  ]) {
    const { graphics, calls } = mockGraphics();
    drawBuildingDetails(graphics, { type, x: 100.25, y: 150.75 }, 0x54b7ff, 0.42);
    const rects = calls.filter(([name]) => name === 'fillRect');
    assert.ok(rects.length >= 3, type + ' has readable details');
    for (const [, x, y, w, h] of rects) {
      assert.ok([x, y, w, h].every(Number.isInteger), type + ' uses whole-pixel geometry');
      assert.ok(w > 0 && h > 0, type + ' has positive detail size');
    }
    assert.ok(calls.some(call => call[0] === 'fillStyle' && call[2] === 0.42),
      'construction translucency preserved');
  }
});

test('all unit classes get crisp painted details without modifying gameplay units', () => {
  for (const type of [
    'harvester', 'scout_bike', 'light_tank', 'siege_tank',
    'rocket_team', 'assault_trooper', 'rifle_squad'
  ]) {
    const unit = { type, x: 40.4, y: 25.7, hp: 60 };
    const original = { ...unit };
    const { graphics, calls } = mockGraphics();
    drawUnitDetails(graphics, unit, 0xff6575);
    assert.deepEqual(unit, original);
    const rects = calls.filter(([name]) => name === 'fillRect');
    assert.ok(rects.length >= 3, type + ' has visible overlays');
    for (const [, x, y, w, h] of rects) {
      assert.ok([x, y, w, h].every(Number.isInteger), type + ' has pixel-aligned details');
    }
  }
});
