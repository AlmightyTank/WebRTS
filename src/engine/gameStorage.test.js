import test from 'node:test';
import assert from 'node:assert/strict';
import { saveGameToStorage, readGameFromStorage, SKIRMISH_SAVE_KEY } from './gameStorage.js';
import { Simulation } from '../simulation/Simulation.js';

function storage() {
  const contents = new Map();
  return {
    setItem(key, value) { contents.set(key, value); },
    getItem(key) { return contents.get(key) ?? null; }
  };
}

test('browser save stores the complete simulation and camera view', () => {
  const sim = new Simulation();
  sim.addBuilding({ playerId: 0, x: 400, y: 500 });
  const camera = { scrollX: 220, scrollY: 180, zoom: 1.2 };
  const store = storage();
  assert.deepEqual(saveGameToStorage({ simulation: sim, cameras: { main: camera } }, store), { ok: true });
  const loaded = readGameFromStorage(store);
  assert.equal(loaded.ok, true);
  assert.deepEqual(loaded.data.camera, camera);
  assert.deepEqual(Simulation.fromSaveState(loaded.data.simulation).snapshot(), sim.snapshot());
  assert.ok(store.getItem(SKIRMISH_SAVE_KEY));
});

test('storage failure and corrupt save return a failure instead of crashing', () => {
  const store = storage();
  assert.equal(readGameFromStorage(store).reason, 'no_save');
  store.setItem(SKIRMISH_SAVE_KEY, '{bad json');
  assert.equal(readGameFromStorage(store).ok, false);
  const failed = saveGameToStorage({ simulation: new Simulation(),
    cameras: { main: { scrollX: 0, scrollY: 0, zoom: 1 } } },
    { setItem() { throw Error('quota exceeded'); } });
  assert.equal(failed.ok, false);
  assert.match(failed.reason, /quota exceeded/);
});
