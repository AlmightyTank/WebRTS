import test from 'node:test';
import assert from 'node:assert/strict';
import { Simulation } from './Simulation.js';
import { attackCommand, buildCommand, defendCommand, moveCommand, produceCommand, repairCommand, sellCommand } from './commands.js';

test('simulation advances movement on a fixed tick', () => {
  const simulation = new Simulation();
  const unit = simulation.addUnit({ playerId: 0, x: 100, y: 100 });
  assert.deepEqual(simulation.issue(moveCommand(0, [unit.id], { x: 300, y: 100 })), { ok: true });
  simulation.advance(1 / 30);
  assert.ok(unit.x > 100);
  assert.equal(simulation.tick, 1);
});

test('defend area stance guards a position and engages nearby enemies', () => {
  const simulation = new Simulation();
  const defender = simulation.addUnit({ playerId: 0, team: 0, x: 300, y: 300 });
  const enemy = simulation.addUnit({ playerId: 1, team: 1, x: 390, y: 300 });
  assert.deepEqual(simulation.issue(defendCommand(0, [defender.id], { x: 300, y: 300 })), { ok: true });
  for (let i = 0; i < 60; i += 1) simulation.advance(1 / 30);
  assert.equal(defender.stance, 'defend_area');
  assert.ok(enemy.hp < enemy.maxHp);
});

test('invalid commands cannot control another player unit', () => {
  const simulation = new Simulation();
  const unit = simulation.addUnit({ playerId: 1 });
  const result = simulation.issue(moveCommand(0, [unit.id], { x: 300, y: 100 }));
  assert.equal(result.ok, false);
  assert.equal(result.reason, 'unauthorized_unit');
});

test('same seed and commands produce the same snapshot', () => {
  const make = () => {
    const simulation = new Simulation({ seed: 42 });
    const a = simulation.addUnit({ playerId: 0, x: 100, y: 100 });
    const b = simulation.addUnit({ playerId: 1, team: 1, x: 300, y: 100 });
    simulation.issue(attackCommand(0, [a.id], b.id));
    simulation.advance(2);
    return simulation.snapshot();
  };
  assert.deepEqual(make(), make());
});

test('units can attack and damage enemy buildings', () => {
  const simulation = new Simulation();
  const attacker = simulation.addUnit({ playerId: 0, team: 0, x: 100, y: 300 });
  const enemyBuilding = simulation.addBuilding({ playerId: 1, team: 1, type: 'barracks', x: 260, y: 300 });
  assert.deepEqual(simulation.issue(attackCommand(0, [attacker.id], enemyBuilding.id, 'building')), { ok: true });
  for (let i = 0; i < 60; i += 1) simulation.advance(1 / 30);
  assert.ok(enemyBuilding.hp < enemyBuilding.maxHp);
});

test('building placement spends resources and harvester deposits cargo', () => {
  const simulation = new Simulation();
  simulation.addBuilding({ playerId: 0, type: 'command_core', x: 300, y: 550 });
  const refinery = simulation.addBuilding({ playerId: 0, type: 'refinery', x: 300, y: 300 });
  const harvester = simulation.addUnit({ playerId: 0, type: 'harvester', x: 400, y: 300 });
  simulation.resourceNodes[0].x = 500;
  simulation.resourceNodes[0].y = 300;
  harvester.resourceNodeId = simulation.resourceNodes[0].id;
  assert.deepEqual(simulation.issue(buildCommand(0, 'refinery', { x: 820, y: 400 })), { ok: true });
  simulation.advance(1 / 30);
  assert.equal(simulation.resources[0], 950);
  for (let i = 0; i < 240; i += 1) simulation.advance(1 / 30);
  assert.ok(simulation.resources[0] > 950);
  assert.equal(simulation.buildings.includes(refinery), true);
});

test('barracks production spawns a unit after its queue completes', () => {
  const simulation = new Simulation();
  const barracks = simulation.addBuilding({ playerId: 0, type: 'barracks', x: 300, y: 300 });
  assert.deepEqual(simulation.issue(produceCommand(0, barracks.id)), { ok: true });
  for (let i = 0; i < 100; i += 1) simulation.advance(1 / 30);
  assert.equal(simulation.units.length, 1);
  assert.equal(simulation.units[0].type, 'rifle_squad');
});

test('machine shop produces scout bikes', () => {
  const simulation = new Simulation();
  simulation.addBuilding({ playerId: 0, type: 'command_core', x: 300, y: 300 });
  const machineShop = simulation.addBuilding({ playerId: 0, type: 'machine_shop', x: 600, y: 300 });
  assert.deepEqual(simulation.issue(produceCommand(0, machineShop.id)), { ok: true });
  for (let i = 0; i < 130; i += 1) simulation.advance(1 / 30);
  assert.ok(simulation.units.some((unit) => unit.type === 'scout_bike'));
});

test('production buildings can queue their alternate roster units', () => {
  const simulation = new Simulation();
  const core = simulation.addBuilding({ playerId: 0, type: 'command_core', x: 300, y: 300 });
  const barracks = simulation.addBuilding({ playerId: 0, type: 'barracks', x: 600, y: 300 });
  const factory = simulation.addBuilding({ playerId: 0, type: 'machine_shop', x: 900, y: 300 });
  assert.deepEqual(simulation.issue(produceCommand(0, barracks.id, 'rocket_team')), { ok: true });
  assert.deepEqual(simulation.issue(produceCommand(0, factory.id, 'light_tank')), { ok: true });
  for (let i = 0; i < 140; i += 1) simulation.advance(1 / 30);
  assert.ok(simulation.units.some((unit) => unit.type === 'rocket_team'));
  assert.ok(simulation.units.some((unit) => unit.type === 'light_tank'));
  assert.equal(core.complete, true);
});

test('defense grid automatically fires on an enemy unit', () => {
  const simulation = new Simulation();
  simulation.addBuilding({ playerId: 0, type: 'command_core', x: 300, y: 300 });
  const defense = simulation.addBuilding({ playerId: 0, type: 'defense_grid', x: 600, y: 300 });
  const enemy = simulation.addUnit({ playerId: 1, team: 1, x: 720, y: 300 });
  for (let i = 0; i < 45; i += 1) simulation.advance(1 / 30);
  assert.ok(enemy.hp < enemy.maxHp);
  assert.ok(simulation.events.some((event) => event.type === 'damage') || enemy.hp < enemy.maxHp);
  assert.equal(defense.complete, true);
});

test('service depot repairs nearby friendly vehicles over time', () => {
  const simulation = new Simulation();
  simulation.addBuilding({ playerId: 0, type: 'command_core', x: 300, y: 300 });
  simulation.addBuilding({ playerId: 0, type: 'service_depot', x: 600, y: 300 });
  const tank = simulation.addUnit({ playerId: 0, type: 'light_tank', x: 650, y: 300 });
  tank.hp = 100;
  for (let i = 0; i < 120; i += 1) simulation.advance(1 / 30);
  assert.ok(tank.hp > 100);
  assert.ok(tank.hp <= tank.maxHp);
});

test('new buildings construct over time before they become operational', () => {
  const simulation = new Simulation({ seed: 9 });
  const core = simulation.addBuilding({ playerId: 0, team: 0, type: 'command_core', x: 300, y: 300 });
  const result = simulation.issue(buildCommand(0, 'barracks', { x: 600, y: 300 }));
  assert.equal(result.ok, true);
  simulation.advance(1 / 30);
  const barracks = simulation.buildings.find((building) => building.type === 'barracks');
  assert.equal(barracks.complete, false);
  assert.equal(simulation.issue(produceCommand(0, barracks.id)).reason, 'invalid_producer');
  for (let elapsed = 0; elapsed < 6.1; elapsed += 0.2) simulation.advance(0.2);
  assert.equal(barracks.complete, true);
  assert.equal(barracks.constructionRemaining, 0);
  assert.equal(core.complete, true);
});

test('repair restores building health over time for metal and sell refunds part of the cost', () => {
  const simulation = new Simulation();
  simulation.addBuilding({ playerId: 0, type: 'command_core', x: 300, y: 300 });
  const barracks = simulation.addBuilding({ playerId: 0, type: 'barracks', x: 600, y: 300 });
  barracks.hp = 100;
  const beforeRepair = simulation.resources[0];
  assert.deepEqual(simulation.issue(repairCommand(0, barracks.id)), { ok: true });
  simulation.advance(1 / 30);
  assert.ok(barracks.hp > 100);
  assert.ok(barracks.hp < barracks.maxHp);
  assert.equal(simulation.resources[0], beforeRepair - 100);
  for (let i = 0; i < 240; i += 1) simulation.advance(1 / 30);
  assert.equal(barracks.hp, barracks.maxHp);
  assert.equal(barracks.repairing, false);
  assert.deepEqual(simulation.issue(sellCommand(0, barracks.id)), { ok: true });
  simulation.advance(1 / 30);
  assert.equal(simulation.buildings.includes(barracks), false);
  assert.equal(simulation.resources[0], beforeRepair - 100 + 125);
});

test('units cannot enter buildings and occupied locations cannot be built on', () => {
  const simulation = new Simulation();
  const building = simulation.addBuilding({ playerId: 0, type: 'command_core', x: 300, y: 300 });
  const unit = simulation.addUnit({ playerId: 0, x: 300, y: 500 });
  assert.equal(simulation.canPlace('refinery', { x: 300, y: 300 }), false);
  simulation.issue(moveCommand(0, [unit.id], { x: 300, y: 300 }));
  for (let i = 0; i < 60; i += 1) simulation.advance(1 / 30);
  assert.ok(Math.hypot(unit.x - building.x, unit.y - building.y) > 110);
});

test('starting unit positions can be placed outside building footprints', () => {
  const simulation = new Simulation();
  simulation.addBuilding({ playerId: 0, type: 'command_core', x: 300, y: 750 });
  simulation.addBuilding({ playerId: 0, type: 'barracks', x: 560, y: 500 });
  simulation.addBuilding({ playerId: 0, type: 'refinery', x: 620, y: 750 });
  const positions = [[420, 620], [500, 700], [420, 780], [560, 610], [480, 850]];
  positions.forEach(([x, y]) => {
    assert.equal(simulation.canUnitOccupy({}, x, y), true);
    simulation.addUnit({ playerId: 0, x, y });
  });
});

test('resource fields deplete and stop producing metal', () => {
  const simulation = new Simulation();
  simulation.addBuilding({ playerId: 0, type: 'refinery', x: 300, y: 300 });
  const harvester = simulation.addUnit({ playerId: 0, type: 'harvester', x: 400, y: 300 });
  simulation.resourceNodes.forEach((node) => { node.amount = 0; });
  simulation.resourceNodes[0].x = 500;
  simulation.resourceNodes[0].y = 300;
  simulation.resourceNodes[0].amount = 40;
  harvester.resourceNodeId = simulation.resourceNodes[0].id;
  for (let i = 0; i < 240; i += 1) simulation.advance(1 / 30);
  assert.equal(simulation.resourceNodes[0].amount, 0);
  assert.equal(simulation.resources[0], 1290);
  assert.equal(harvester.harvesterState, 'idle');
});

test('harvester chooses fields by distance from its home refinery', () => {
  const simulation = new Simulation();
  const refinery = simulation.addBuilding({ playerId: 0, type: 'refinery', x: 300, y: 300 });
  const harvester = simulation.addUnit({ playerId: 0, type: 'harvester', x: 900, y: 300 });
  simulation.resourceNodes[0].x = 350;
  simulation.resourceNodes[0].y = 300;
  simulation.resourceNodes[1].x = 900;
  simulation.resourceNodes[1].y = 300;
  assert.equal(harvester.homeBuildingId, refinery.id);
  assert.equal(harvester.resourceNodeId, simulation.resourceNodes[0].id);
});

test('harvester navigates around its home refinery', () => {
  const simulation = new Simulation();
  simulation.addBuilding({ playerId: 0, type: 'refinery', x: 620, y: 750 });
  const harvester = simulation.addUnit({ playerId: 0, type: 'harvester', x: 500, y: 900 });
  for (let i = 0; i < 2400; i += 1) simulation.advance(1 / 30);
  assert.ok(simulation.resourceNodes.some((node) => node.amount < 5000));
  assert.notEqual(harvester.harvesterState, 'idle');
});

test('power and supply gate production', () => {
  const simulation = new Simulation();
  simulation.addBuilding({ playerId: 0, type: 'command_core', x: 300, y: 300 });
  const barracks = simulation.addBuilding({ playerId: 0, type: 'barracks', x: 600, y: 300 });
  for (let i = 0; i < 10; i += 1) simulation.addBuilding({ playerId: 0, type: 'refinery', x: 900 + i * 140, y: 300 });
  assert.equal(simulation.issue(produceCommand(0, barracks.id)).reason, 'insufficient_power');
});

test('power plants increase the base power budget', () => {
  const simulation = new Simulation();
  simulation.addBuilding({ playerId: 0, type: 'command_core', x: 300, y: 300 });
  simulation.addBuilding({ playerId: 0, type: 'barracks', x: 600, y: 300 });
  const before = simulation.getPlayerState(0);
  simulation.addBuilding({ playerId: 0, type: 'power_plant', x: 900, y: 300 });
  const after = simulation.getPlayerState(0);
  assert.equal(before.generated, 40);
  assert.equal(after.generated, 75);
  assert.equal(after.lowPower, false);
  assert.ok(after.powerRatio > before.powerRatio);
});

test('destroying the enemy command core ends the match', () => {
  const simulation = new Simulation();
  simulation.addBuilding({ playerId: 0, type: 'command_core', x: 300, y: 300 });
  const enemyCore = simulation.addBuilding({ playerId: 1, type: 'command_core', x: 900, y: 300 });
  enemyCore.hp = 0;
  simulation.advance(1 / 30);
  assert.equal(simulation.gameState, 'victory');
  assert.equal(simulation.gameOverReason, 'ENEMY COMMAND CORE DESTROYED');
});


test('pending production and construction reserve metal before the next tick', () => {
  const simulation = new Simulation();
  simulation.resources[0] = 350;
  simulation.addBuilding({ playerId: 0, type: 'command_core', x: 300, y: 300 });
  const barracks = simulation.addBuilding({ playerId: 0, type: 'barracks', x: 600, y: 300 });
  assert.deepEqual(simulation.issue(buildCommand(0, 'refinery', { x: 950, y: 500 })), { ok: true });
  assert.equal(simulation.issue(produceCommand(0, barracks.id)).reason, 'insufficient_resources');
  simulation.advance(1 / 30);
  assert.equal(simulation.resources[0], 50);
});

test('queued units are paid once and rapid purchase clicks cannot overspend', () => {
  const simulation = new Simulation();
  simulation.resources[0] = 250;
  const barracks = simulation.addBuilding({ playerId: 0, type: 'barracks', x: 300, y: 300 });
  assert.deepEqual(simulation.issue(produceCommand(0, barracks.id)), { ok: true });
  assert.deepEqual(simulation.issue(produceCommand(0, barracks.id)), { ok: true });
  assert.equal(simulation.issue(produceCommand(0, barracks.id)).reason, 'insufficient_resources');
  simulation.advance(1 / 30);
  assert.equal(simulation.resources[0], 50);
  simulation.resources[0] = 110;
  assert.deepEqual(simulation.issue(produceCommand(0, barracks.id)), { ok: true });
  simulation.advance(1 / 30);
  assert.equal(simulation.resources[0], 10);
});

test('pending production counts toward supply limits', () => {
  const simulation = new Simulation();
  simulation.resources[0] = 1000;
  const barracks = simulation.addBuilding({ playerId: 0, type: 'barracks', x: 300, y: 300 });
  for (let i = 0; i < 4; i += 1) simulation.addUnit({ playerId: 0, x: 600 + i * 50, y: 500 });
  assert.deepEqual(simulation.issue(produceCommand(0, barracks.id)), { ok: true });
  assert.equal(simulation.issue(produceCommand(0, barracks.id)).reason, 'supply_limit');
  simulation.advance(1 / 30);
  assert.equal(simulation.getPlayerState(0).usedSupply, 5);
});

test('cancel and clear refund queued production and discard pending orders', () => {
  const simulation = new Simulation();
  simulation.resources[0] = 500;
  const barracks = simulation.addBuilding({ playerId: 0, type: 'barracks', x: 300, y: 300 });
  simulation.issue(produceCommand(0, barracks.id, 'rocket_team'));
  assert.equal(simulation.controlProduction(0, barracks.id, 'cancel').canceledPending, 1);
  simulation.advance(1 / 30);
  assert.equal(simulation.resources[0], 500);
  simulation.issue(produceCommand(0, barracks.id, 'rocket_team'));
  simulation.issue(produceCommand(0, barracks.id, 'rifle_squad'));
  simulation.advance(1 / 30);
  assert.equal(simulation.resources[0], 225);
  assert.equal(simulation.controlProduction(0, barracks.id, 'cancel').refunded, 175);
  assert.equal(simulation.resources[0], 400);
  assert.equal(simulation.controlProduction(0, barracks.id, 'clear').refunded, 100);
  assert.equal(simulation.resources[0], 500);
  assert.equal(barracks.queue.length, 0);
});

test('selling a building refunds its outstanding production queue', () => {
  const simulation = new Simulation();
  simulation.resources[0] = 500;
  const barracks = simulation.addBuilding({ playerId: 0, type: 'barracks', x: 300, y: 300 });
  simulation.issue(produceCommand(0, barracks.id));
  simulation.advance(1 / 30);
  assert.equal(simulation.resources[0], 400);
  assert.deepEqual(simulation.issue(sellCommand(0, barracks.id)), { ok: true });
  simulation.advance(1 / 30);
  assert.equal(simulation.resources[0], 625);
});

test('harvesters wait for a completed refinery and retain existing cargo', () => {
  const simulation = new Simulation();
  const refinery = simulation.addBuilding({ playerId: 0, type: 'refinery', x: 300, y: 300 });
  const harvester = simulation.addUnit({ playerId: 0, type: 'harvester', x: 500, y: 300 });
  harvester.cargo = 80;
  harvester.harvesterState = 'to_refinery';
  refinery.hp = 0;
  simulation.advance(1 / 30);
  assert.equal(harvester.harvesterState, 'awaiting_refinery');
  assert.equal(harvester.cargo, 80);
  const replacement = simulation.addBuilding({ playerId: 0, type: 'refinery', x: 650, y: 500, complete: false });
  for (let i = 0; i < 30; i += 1) simulation.advance(1 / 30);
  assert.equal(harvester.harvesterState, 'awaiting_refinery');
  replacement.complete = true;
  for (let i = 0; i < 250; i += 1) simulation.advance(1 / 30);
  assert.equal(harvester.homeBuildingId, replacement.id);
  assert.ok(simulation.resources[0] >= 1330, 'saved cargo should reach the new refinery');
  assert.ok(harvester.cargo >= 0 && harvester.cargo <= harvester.capacity);
});
