export const COMMANDS = Object.freeze({
  MOVE: 'move',
  ATTACK: 'attack',
  STOP: 'stop',
  DEFEND: 'defend',
  BUILD: 'build',
  PRODUCE: 'produce',
  REPAIR: 'repair',
  SELL: 'sell'
});

export function moveCommand(playerId, unitIds, destination) {
  return { type: COMMANDS.MOVE, playerId, unitIds: [...unitIds], destination: { x: destination.x, y: destination.y } };
}

export function attackCommand(playerId, unitIds, targetId, targetType = 'unit') {
  return { type: COMMANDS.ATTACK, playerId, unitIds: [...unitIds], targetId, targetType };
}

export function stopCommand(playerId, unitIds) {
  return { type: COMMANDS.STOP, playerId, unitIds: [...unitIds] };
}

export function defendCommand(playerId, unitIds, position, radius = 180) {
  return { type: COMMANDS.DEFEND, playerId, unitIds: [...unitIds], position: { x: position.x, y: position.y }, radius };
}

export function buildCommand(playerId, buildingType, position) {
  return { type: COMMANDS.BUILD, playerId, buildingType, position: { x: position.x, y: position.y } };
}

export function produceCommand(playerId, buildingId, unitType = null) {
  return { type: COMMANDS.PRODUCE, playerId, buildingId, unitType };
}

export function repairCommand(playerId, targetId, targetType = 'building') {
  return { type: COMMANDS.REPAIR, playerId, targetId, targetType, buildingId: targetType === 'building' ? targetId : undefined };
}

export function sellCommand(playerId, buildingId) {
  return { type: COMMANDS.SELL, playerId, buildingId };
}
