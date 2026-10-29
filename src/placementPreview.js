import { BUILDING_TYPES } from './simulation/content.js';
import { buildCommand } from './simulation/commands.js';

export const PLACEMENT_COLORS = Object.freeze({
  valid: 0x66d69a,
  invalid: 0xe05e68
});

const REASONS = Object.freeze({
  no_command_core: 'COMMAND CORE REQUIRED',
  insufficient_resources: 'INSUFFICIENT METAL',
  invalid_placement: 'LOCATION BLOCKED',
  unknown_building: 'UNKNOWN BUILDING'
});

// Always use the simulation's authoritative command validation: it includes
// pending spending, occupied space, map boundaries and Command Core rules.
export function describePlacement(simulation, type, position, playerId = 0) {
  const definition = BUILDING_TYPES[type];
  if (!definition || !position || !Number.isFinite(position.x) || !Number.isFinite(position.y)) return null;
  const result = simulation.validateCommand(buildCommand(playerId, type, position));
  const valid = result.ok === true;
  return {
    type, x: position.x, y: position.y,
    width: definition.width, height: definition.height,
    cost: definition.cost,
    valid, reason: result.ok ? null : result.reason,
    color: valid ? PLACEMENT_COLORS.valid : PLACEMENT_COLORS.invalid,
    message: valid ? 'READY TO BUILD' : (REASONS[result.reason] ?? 'CANNOT BUILD HERE')
  };
}

// Preview is anchored in the unobstructed battlefield, not the HUD. Its world
// location is recalculated from screen coordinates after every camera movement.
export function defaultPreviewAnchor(width, height, mobile, sidebarLeft = width) {
  const left = 8;
  const right = mobile ? width - 8 : Math.min(sidebarLeft - 8, width - 8);
  const top = mobile ? 54 : 8;
  const bottom = mobile ? height - 100 : height - 165;
  return {
    x: Math.round((left + Math.max(left + 1, right)) / 2),
    y: Math.round((top + Math.max(top + 1, bottom)) / 2)
  };
}
