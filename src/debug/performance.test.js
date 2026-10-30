import test from 'node:test';
import assert from 'node:assert/strict';
import { PerformanceMonitor, debugScenario } from './performance.js';
import { Simulation } from '../simulation/Simulation.js';

test('rolling monitor tracks frame time, slow frames, and simulation pressure', () => {
  const p = new PerformanceMonitor(3);
  p.record(16); p.record(20); p.record(60); p.record(14);
  const info = p.summary(new Simulation());
  assert.equal(info.slowFrames, 1);
  assert.equal(info.maxFrameMs, 60);
  assert.equal(info.avgFrameMs, 31.3);
  assert.equal(info.tick, 0);
  assert.equal(info.units, 0);
  assert.equal(info.hash.length, 8);
});

test('reproducible stress scenarios have bounded size and reject unknown names', () => {
  assert.equal(debugScenario('baseline').units, 0);
  assert.deepEqual(debugScenario('unit_stress'), { units: 60, spacing: 36, columns: 10 });
  assert.throws(() => debugScenario('unknown'), /Unknown/);
});
