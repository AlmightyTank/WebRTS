import test from 'node:test';
import assert from 'node:assert/strict';
import { validateCommandShape, validateCommandEnvelope, commandEnvelope, simulationEvent, validateEntity } from './contracts.js';
import { Simulation } from './Simulation.js';
import { buildCommand, moveCommand } from './commands.js';
import { GAME_CONTENT, validateContentRegistry } from './content.js';

test('all built-in content and cross references are valid', () => {
  assert.deepEqual(validateContentRegistry(), []);
  assert.equal(GAME_CONTENT.units.rifle_squad.id, 'rifle_squad');
  assert.equal(GAME_CONTENT.buildings.refinery.produces, undefined);
  assert.equal(GAME_CONTENT.equipment.siege_tank.weapon, 'siege');
});

test('invalid content references are rejected during validation', () => {
  const broken = { ...GAME_CONTENT,
    buildings: { bogus: { id: 'bogus', maxHp: 1, width: 2, height: 3, cost: 0, produces: ['unknown'] } }
  };
  assert.ok(validateContentRegistry(broken).some(e => e.includes('unknown unit')));
});

test('command protocol round trips with a tick and isolated payload', () => {
  const source = buildCommand(0, 'refinery', { x: 850, y: 750 });
  const envelope = commandEnvelope(source, 7);
  assert.deepEqual(validateCommandEnvelope(envelope), { ok: true });
  source.position.x = NaN;
  assert.equal(envelope.command.position.x, 850);
  assert.equal(validateCommandEnvelope({ ...envelope, version: 4 }).ok, false);
  assert.equal(validateCommandEnvelope({ ...envelope, tick: -1 }).ok, false);
});

test('invalid player, malformed points, unknown versions and unsafe IDs are rejected', () => {
  assert.equal(validateCommandShape({ ...buildCommand(0, 'barracks', { x: 800, y: 500 }), playerId: -1 }).reason, 'invalid_player');
  assert.equal(validateCommandShape(buildCommand(0, 'barracks', { x: NaN, y: 500 })).reason, 'invalid_placement');
  assert.equal(validateCommandShape({ ...moveCommand(0, [1], { x: 200, y: 200 }), unitIds: [Infinity] }).reason, 'no_units');
  assert.equal(validateCommandShape({ ...buildCommand(0, 'barracks', { x: 800, y: 500 }), version: 999 }).reason, 'unsupported_protocol');
  const simulation = new Simulation();
  assert.equal(simulation.issue({ type: 'produce', playerId: 0, buildingId: -4 }).reason, 'invalid_producer');
});

test('events and entity envelopes are versioned and validated', () => {
  assert.deepEqual(simulationEvent('building_created', 42, { buildingId: 12 }),
    { version: 1, tick: 42, type: 'building_created', buildingId: 12 });
  assert.equal(validateEntity({ id: 1, type: 'test', playerId: 0, x: 2, y: 3, hp: 6, maxHp: 10 }).ok, true);
  assert.equal(validateEntity({ id: 1, playerId: 0, x: 2, y: 3, hp: Infinity, maxHp: 10 }).ok, false);
});
