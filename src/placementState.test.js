import test from 'node:test';
import assert from 'node:assert/strict';
import { PlacementState, UiPointerGate } from './placementState.js';

const buildings = Object.freeze({ refinery: {cost:300}, barracks:{cost:250}, power_plant:{cost:400} });

test('only one building is selected; switching replaces the active type', () => {
  const state = new PlacementState(buildings);
  assert.equal(state.active, false);
  assert.equal(state.type, 'refinery');
  assert.equal(state.begin('refinery'), true);
  assert.equal(state.begin('barracks'), true);
  assert.equal(state.selected, 'barracks');
  assert.equal(state.type, 'barracks');
});

test('invalid building choices do not modify selection', () => {
  const state = new PlacementState(buildings);
  state.begin('refinery');
  assert.equal(state.begin('invalid'), false);
  assert.equal(state.prefer('__proto__'), false);
  assert.equal(state.selected, 'refinery');
});

test('cancel clears construction but keeps the preferred type', () => {
  const state = new PlacementState(buildings);
  state.begin('barracks');
  assert.equal(state.cancel(), true);
  assert.equal(state.active, false);
  assert.equal(state.cancel(), false);
  assert.equal(state.type, 'barracks');
  assert.equal(state.begin(), true);
  assert.equal(state.selected, 'barracks');
});

test('success exits placement without stale selection', () => {
  const state = new PlacementState(buildings);
  state.begin('refinery');
  assert.equal(state.finish(), true);
  assert.equal(state.finish(), false);
  assert.equal(state.selected, null);
});

test('keyboard preference does not inadvertently activate construction', () => {
  const state = new PlacementState(buildings);
  state.prefer('power_plant');
  assert.equal(state.active, false);
  assert.equal(state.type, 'power_plant');
  state.begin();
  state.prefer('barracks');
  assert.equal(state.selected, 'barracks');
});

test('UI gesture blocks its world release even after panel closes', () => {
  const gate = new UiPointerGate();
  assert.equal(gate.active, false);
  gate.block();
  gate.block();
  assert.equal(gate.active, true);
  assert.equal(gate.release(), true);
  assert.equal(gate.active, false);
  assert.equal(gate.release(), false);
});
