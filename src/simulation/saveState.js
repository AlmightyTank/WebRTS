import { BUILDING_TYPES, MAPS, UNIT_TYPES, CONTENT_VERSION } from './content.js';
import { validateEntity, validateCommandShape } from './contracts.js';

export const SAVE_VERSION = 1;
const jsonCopy = value => JSON.parse(JSON.stringify(value));

const finite = x => typeof x === 'number' && Number.isFinite(x);
const safeId = x => Number.isSafeInteger(x) && x > 0;
const validObject = x => x && typeof x === 'object' && !Array.isArray(x);

// Canonical JSON for deterministic state hashes; object key order must not
// affect the result, and all supported values must be JSON serializable.
export function stableStringify(value) {
  if (value === null || typeof value !== 'object') return JSON.stringify(value);
  if (Array.isArray(value)) return '[' + value.map(stableStringify).join(',') + ']';
  return '{' + Object.keys(value).sort().filter(k => value[k] !== undefined)
    .map(k => JSON.stringify(k) + ':' + stableStringify(value[k])).join(',') + '}';
}

export function stateHash(value) {
  const text = stableStringify(value);
  let hash = 2166136261;
  for (let i = 0; i < text.length; i++) {
    hash ^= text.charCodeAt(i);
    hash = Math.imul(hash, 16777619);
  }
  return (hash >>> 0).toString(16).padStart(8, '0');
}

export function nextSeededRandom(state) {
  // xorshift32 with a deterministic nonzero seed for the zero-seed case.
  let x = (state >>> 0) || 0x6d2b79f5;
  x ^= x << 13;
  x ^= x >>> 17;
  x ^= x << 5;
  return { state: x >>> 0, value: (x >>> 0) / 4294967296 };
}

export function migrateSaveState(raw) {
  if (!validObject(raw)) throw new TypeError('Invalid skirmish save');
  if (raw.version === SAVE_VERSION) return raw;
  if (raw.version === 0) {
    // Early internal snapshots predated a save format and command journaling.
    return {
      ...raw, version: SAVE_VERSION, contentVersion: raw.contentVersion ?? CONTENT_VERSION,
      mapId: raw.mapId ?? 'first_contact', randomState: raw.randomState ?? raw.seed,
      commandJournal: raw.commandJournal ?? [], events: raw.events ?? [],
      commandQueue: raw.commandQueue ?? [], aiTimer: raw.aiTimer ?? 0,
      accumulator: raw.accumulator ?? 0, pathCellSize: raw.pathCellSize ?? 60,
      nextUnitId: raw.nextUnitId ?? 1 + Math.max(0, ...(raw.units ?? []).map(x => x.id)),
      nextBuildingId: raw.nextBuildingId ?? 1 + Math.max(0, ...(raw.buildings ?? []).map(x => x.id)),
      nextProjectileId: raw.nextProjectileId ?? 1 + Math.max(0, ...(raw.projectiles ?? []).map(x => x.id)),
      commandCoreStarted: raw.commandCoreStarted ?? { 0: true, 1: true }
    };
  }
  throw new TypeError('Unsupported skirmish save version');
}

export function validateSaveState(raw) {
  const state = migrateSaveState(raw);
  if (state.contentVersion !== CONTENT_VERSION) throw new TypeError('Incompatible content version');
  if (!Object.values(MAPS).some(m => m.id === state.mapId)) throw new TypeError('Unknown save map');
  if (!Number.isSafeInteger(state.seed) || state.seed < 0 ||
    !Number.isSafeInteger(state.randomState) || state.randomState < 0 ||
    !Number.isSafeInteger(state.tick) || state.tick < 0 ||
    !finite(state.time) || state.time < 0 || !finite(state.accumulator) || state.accumulator < 0 ||
    !finite(state.aiTimer) || !finite(state.pathCellSize) || state.pathCellSize <= 0) throw new TypeError('Invalid save timing');
  for (const key of ['units','buildings','projectiles','resourceNodes','commandQueue','commandJournal','events']) {
    if (!Array.isArray(state[key])) throw new TypeError('Invalid save collection: ' + key);
  }
  if (!validObject(state.resources) || !validObject(state.commandCoreStarted)) throw new TypeError('Invalid save resources');
  if (!['playing','victory','defeat'].includes(state.gameState)) throw new TypeError('Invalid match state');
  for (const value of Object.values(state.resources)) if (!finite(value) || value < 0) throw new TypeError('Invalid resource amount');
  for (const unit of state.units) {
    if (!UNIT_TYPES[unit.type] || !validateEntity(unit).ok) throw new TypeError('Invalid saved unit');
  }
  for (const building of state.buildings) {
    if (!BUILDING_TYPES[building.type] || !validateEntity(building).ok ||
      !Array.isArray(building.queue) || !finite(building.constructionRemaining)) throw new TypeError('Invalid saved building');
  }
  for (const key of ['nextUnitId','nextBuildingId','nextProjectileId']) {
    if (!safeId(state[key])) throw new TypeError('Invalid next entity id');
  }
  for (const node of state.resourceNodes) {
    if (!safeId(node.id) || !finite(node.x) || !finite(node.y) || !finite(node.amount) || node.amount < 0) {
      throw new TypeError('Invalid saved resource node');
    }
  }
  for (const command of state.commandQueue) {
    if (!validateCommandShape(command).ok) throw new TypeError('Invalid saved command');
  }
  for (const record of state.commandJournal) {
    if (!Number.isSafeInteger(record.tick) || record.tick < 0 || !validateCommandShape(record.command).ok) {
      throw new TypeError('Invalid saved command journal');
    }
  }
  return jsonCopy(state);
}
