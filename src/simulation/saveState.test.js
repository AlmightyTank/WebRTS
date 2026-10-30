import test from 'node:test';
import assert from 'node:assert/strict';
import { Simulation } from './Simulation.js';
import { buildCommand, moveCommand, produceCommand } from './commands.js';
import { stateHash, stableStringify, nextSeededRandom, validateSaveState } from './saveState.js';

function mission(seed = 1337) {
  const sim = new Simulation({ seed });
  sim.addBuilding({ playerId: 0, type: 'command_core', x: 300, y: 300 });
  sim.addBuilding({ playerId: 0, type: 'barracks', x: 550, y: 300 });
  sim.addBuilding({ playerId: 1, type: 'command_core', x: 2100, y: 750 });
  sim.addUnit({ playerId: 0, x: 650, y: 650 });
  sim.addUnit({ playerId: 1, x: 1750, y: 650 });
  return sim;
}

test('seeded PRNG produces the same deterministic stream', () => {
  const a = mission(1234), b = mission(1234), c = mission(5678);
  const numbers = Array.from({ length: 10 }, () => a.random());
  assert.deepEqual(numbers, Array.from({ length: 10 }, () => b.random()));
  assert.notDeepEqual(numbers, Array.from({ length: 10 }, () => c.random()));
  assert.ok(numbers.every(n => n >= 0 && n < 1));
  assert.deepEqual(nextSeededRandom(0), nextSeededRandom(0));
});

test('stable hash ignores JSON key insertion order but detects changes', () => {
  assert.equal(stableStringify({ b: 2, a: 1 }), stableStringify({ a: 1, b: 2 }));
  assert.equal(stateHash({ b: 2, a: [4, 5] }), stateHash({ a: [4, 5], b: 2 }));
  assert.notEqual(stateHash({ n: 1 }), stateHash({ n: 2 }));
});

test('same seed and identical commands produce matching tick state hashes', () => {
  const a = mission(), b = mission();
  for (let i = 0; i < 105; i++) {
    for (const sim of [a, b]) {
      if (i === 0) sim.issue(moveCommand(0, [1], { x: 900, y: 650 }));
      if (i === 12) sim.issue(buildCommand(0, 'refinery', { x: 1120, y: 800 }));
      if (i === 15) sim.issue(produceCommand(0, 2, 'rifle_squad'));
      sim.step(1 / 30);
    }
    assert.equal(a.getStateHash(), b.getStateHash(), 'tick ' + i);
  }
  assert.equal(a.commandJournal[0].tick, 1);
  assert.equal(a.commandJournal.find(entry =>
    entry.command.type === 'build' && entry.command.playerId === 0).tick, 13);
});

test('accepted commands are immutable snapshots in queue and journal', () => {
  const sim = mission();
  const command = moveCommand(0, [1], { x: 950, y: 650 });
  assert.deepEqual(sim.issue(command), { ok: true });
  command.unitIds[0] = 999;
  command.destination.x = NaN;
  assert.deepEqual(sim.commandQueue[0].unitIds, [1]);
  assert.equal(sim.commandJournal[0].command.destination.x, 950);
  assert.equal(sim.commandJournal[0].tick, 1);
});

test('save and restore preserves all in-flight state and continues deterministically', () => {
  const a = mission();
  a.issue(buildCommand(0, 'refinery', { x: 1100, y: 880 }));
  a.issue(produceCommand(0, 2, 'rifle_squad'));
  a.advance(0.042);
  a.random();
  a.issue(moveCommand(0, [1], { x: 1200, y: 880 }));
  const input = JSON.parse(JSON.stringify(a.exportSaveState()));
  const b = Simulation.fromSaveState(input);
  assert.deepEqual(b.exportSaveState(), input);
  assert.equal(b.getStateHash(), a.getStateHash());
  assert.deepEqual(b.snapshot(), a.snapshot());
  input.units[0].hp = 0;
  assert.notEqual(input.units[0].hp, b.units[0].hp);
  for (let t = 0; t < 90; t++) {
    a.advance(1 / 30);
    b.advance(1 / 30);
    assert.equal(a.getStateHash(), b.getStateHash(), 'after load tick ' + t);
  }
  const next = b.addUnit({ playerId: 0, x: 1000, y: 700 });
  assert.ok(next.id >= 3);
});

test('legacy v0 save migrates and rejects incompatible or corrupt saves', () => {
  const sim = mission();
  const save = sim.exportSaveState();
  const legacy = { ...save, version: 0 };
  delete legacy.commandJournal; delete legacy.randomState;
  const migrated = validateSaveState(legacy);
  assert.equal(migrated.version, 1);
  assert.deepEqual(migrated.commandJournal, []);
  assert.equal(Simulation.fromSaveState(legacy).tick, sim.tick);
  assert.throws(() => Simulation.fromSaveState({ ...save, version: 999 }), /Unsupported/);
  assert.throws(() => Simulation.fromSaveState({ ...save, contentVersion: 99 }), /content version/);
  assert.throws(() => Simulation.fromSaveState({ ...save, units: [{ type: 'rifle_squad' }] }), /Invalid saved unit/);
  assert.throws(() => Simulation.fromSaveState({ ...save, resources: { 0: -1, 1: 30 } }), /resource amount/);
  assert.throws(() => Simulation.fromSaveState({ ...save, mapId: 'other' }), /Unknown save map/);
});
