export const SKIRMISH_SAVE_KEY = 'webrts.skirmish.v1';
export const AUTOSAVE_KEY = 'webrts.autosave.v1';

export function serializeGameScene(scene) {
  const c = scene.cameras.main;
  return {
    format: 'webrts-game', version: 1,
    simulation: scene.simulation.exportSaveState(),
    camera: { scrollX: c.scrollX, scrollY: c.scrollY, zoom: c.zoom }
  };
}

export function saveGameToStorage(scene, storage, key = SKIRMISH_SAVE_KEY) {
  try {
    storage.setItem(key, JSON.stringify(serializeGameScene(scene)));
    return { ok: true };
  } catch (error) {
    return { ok: false, reason: String(error?.message ?? error) };
  }
}

export function readGameFromStorage(storage, key = SKIRMISH_SAVE_KEY) {
  try {
    const content = storage.getItem(key);
    if (!content) return { ok: false, reason: 'no_save' };
    const data = JSON.parse(content);
    if (data?.format !== 'webrts-game' || data.version !== 1 || !data.simulation) {
      return { ok: false, reason: 'incompatible_save' };
    }
    const c = data.camera;
    if (!c || ![c.scrollX, c.scrollY, c.zoom].every(Number.isFinite) || c.zoom <= 0) {
      return { ok: false, reason: 'invalid_camera' };
    }
    return { ok: true, data };
  } catch (error) {
    return { ok: false, reason: String(error?.message ?? error) };
  }
}
