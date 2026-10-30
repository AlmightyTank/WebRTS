// v1 transport contracts; the existing command builders remain lightweight
// objects so old saves and AI routines can continue to issue commands.
export const PROTOCOL_VERSION = 1;
export const ENTITY_VERSION = 1;
const COMMAND_TYPES = new Set(['move', 'attack', 'stop', 'defend', 'build', 'produce', 'repair', 'sell']);

const index = value => Number.isSafeInteger(value) && value >= 0;
const id = value => Number.isSafeInteger(value) && value > 0;
const point = p => !!p && Number.isFinite(p.x) && Number.isFinite(p.y);
const ids = list => Array.isArray(list) && list.length > 0 && list.every(id);

export function validateCommandShape(command) {
  if (!command || typeof command !== 'object' || !COMMAND_TYPES.has(command.type)) {
    return { ok: false, reason: 'unknown_command' };
  }
  if (command.version !== undefined && command.version !== PROTOCOL_VERSION) {
    return { ok: false, reason: 'unsupported_protocol' };
  }
  if (!index(command.playerId)) return { ok: false, reason: 'invalid_player' };
  if (['move', 'attack', 'stop', 'defend'].includes(command.type) && !ids(command.unitIds)) {
    return { ok: false, reason: 'no_units' };
  }
  if (command.type === 'move' && !point(command.destination)) return { ok: false, reason: 'invalid_destination' };
  if (command.type === 'defend' && !point(command.position)) return { ok: false, reason: 'invalid_destination' };
  if (command.type === 'build' && (!point(command.position))) return { ok: false, reason: 'invalid_placement' };
  if (command.type === 'build' && typeof command.buildingType !== 'string') return { ok: false, reason: 'unknown_building' };
  if (command.type === 'produce' && !id(command.buildingId)) return { ok: false, reason: 'invalid_producer' };
  if (command.type === 'attack' && !id(command.targetId)) return { ok: false, reason: 'invalid_target' };
  if (command.type === 'repair' || command.type === 'sell') {
    if (!id(command.targetId ?? command.buildingId)) return { ok: false, reason: 'invalid_target' };
  }
  return { ok: true };
}

export function commandEnvelope(command, tick) {
  if (!Number.isSafeInteger(tick) || tick < 0) throw new TypeError('Invalid command tick');
  const result = validateCommandShape(command);
  if (!result.ok) throw new TypeError(result.reason);
  return { version: PROTOCOL_VERSION, tick, command: structuredClone(command) };
}

export function validateCommandEnvelope(envelope) {
  if (envelope?.version !== PROTOCOL_VERSION || !Number.isSafeInteger(envelope.tick) || envelope.tick < 0) {
    return { ok: false, reason: 'unsupported_protocol' };
  }
  return validateCommandShape(envelope.command);
}

export function simulationEvent(type, tick, payload = {}) {
  if (!Number.isSafeInteger(tick) || tick < 0 || typeof type !== 'string' || !type) {
    throw new TypeError('Invalid event');
  }
  return { version: PROTOCOL_VERSION, tick, type, ...structuredClone(payload) };
}

export function validateEntity(entity, type) {
  if (!entity || !id(entity.id) || !index(entity.playerId) || !point(entity) ||
    !Number.isFinite(entity.hp) || !Number.isFinite(entity.maxHp) ||
    !(entity.maxHp > 0) || entity.hp < 0 || entity.hp > entity.maxHp) {
    return { ok: false, reason: 'invalid_entity' };
  }
  if (type && entity.type !== type) return { ok: false, reason: 'invalid_entity_type' };
  return { ok: true };
}
