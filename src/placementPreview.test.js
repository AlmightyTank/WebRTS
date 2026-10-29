import test from 'node:test';
import assert from 'node:assert/strict';
import { Simulation } from './simulation/Simulation.js';
import { buildCommand } from './simulation/commands.js';
import { describePlacement, defaultPreviewAnchor, PLACEMENT_COLORS } from './placementPreview.js';

function withCore() {
  const simulation = new Simulation();
  simulation.addBuilding({ playerId: 0, type: 'command_core', x: 300, y: 300 });
  return simulation;
}

test('preview uses the real building footprint and can place when valid', () => {
  const sim = withCore();
  const placement = describePlacement(sim, 'refinery', { x: 1100, y: 1050 });
  assert.equal(placement.width, 120);
  assert.equal(placement.height, 100);
  assert.equal(placement.cost, 300);
  assert.equal(placement.valid, true);
  assert.equal(placement.color, PLACEMENT_COLORS.valid);
  assert.equal(placement.message, 'READY TO BUILD');
  assert.deepEqual(sim.issue(buildCommand(0, 'refinery', { x: 1100, y: 1050 })), { ok: true });
});

test('preview is invalid when blocked by an existing structure', () => {
  const sim = withCore();
  const placement = describePlacement(sim, 'refinery', { x: 300, y: 300 });
  assert.equal(placement.valid, false);
  assert.equal(placement.reason, 'invalid_placement');
  assert.equal(placement.color, PLACEMENT_COLORS.invalid);
});

test('preview handles off-map placement and overlapping units', () => {
  const sim = withCore();
  assert.equal(describePlacement(sim, 'refinery', { x: 15, y: 20 }).valid, false);
  sim.addUnit({ playerId: 0, type: 'rifle_squad', x: 1100, y: 1050 });
  assert.equal(describePlacement(sim, 'refinery', { x: 1100, y: 1050 }).valid, false);
});

test('preview includes affordability and pending construction costs', () => {
  const sim = withCore();
  sim.resources[0] = 350;
  const first = { x: 950, y: 1050 };
  const second = { x: 1300, y: 1050 };
  assert.equal(describePlacement(sim, 'refinery', first).valid, true);
  assert.deepEqual(sim.issue(buildCommand(0, 'refinery', first)), { ok: true });
  const preview = describePlacement(sim, 'refinery', second);
  assert.equal(preview.valid, false);
  assert.equal(preview.reason, 'insufficient_resources');
  assert.equal(preview.message, 'INSUFFICIENT METAL');
});

test('preview warns if no completed Command Core is present', () => {
  const sim = new Simulation();
  const preview = describePlacement(sim, 'refinery', { x: 1100, y: 1050 });
  assert.equal(preview.valid, false);
  assert.equal(preview.reason, 'no_command_core');
});

test('invalid coordinates or unknown types never generate a preview', () => {
  const sim = withCore();
  assert.equal(describePlacement(sim, 'not_a_building', { x: 1200, y: 1200 }), null);
  assert.equal(describePlacement(sim, 'refinery', { x: NaN, y: 500 }), null);
  assert.equal(describePlacement(sim, 'refinery', null), null);
});

test('mobile default preview starts within the playable area, not the HUD', () => {
  const p = defaultPreviewAnchor(360, 640, true);
  assert.deepEqual(p, { x: 180, y: 297 });
  assert.ok(p.y > 54 && p.y < 540);
  assert.deepEqual(defaultPreviewAnchor(1200, 800, false, 992), { x: 496, y: 322 });
});

test('camera movement changes preview world position while preserving screen anchor', () => {
  const anchor = defaultPreviewAnchor(360, 640, true);
  const camera = { scrollX: 0, scrollY: 100, zoom: 1,
    getWorldPoint(x, y) { return { x: this.scrollX + x / this.zoom, y: this.scrollY + y / this.zoom }; }
  };
  const before = camera.getWorldPoint(anchor.x, anchor.y);
  camera.scrollX = 200;
  camera.zoom = 1.25;
  const after = camera.getWorldPoint(anchor.x, anchor.y);
  assert.notDeepEqual(before, after);
  assert.equal(after.x, 344);
  assert.equal(after.y, 337.6);
});
