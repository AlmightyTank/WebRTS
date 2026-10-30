import { UNIT_TYPES } from './units.js';
import { BUILDING_TYPES } from './buildings.js';
import { FACTIONS } from './factions.js';
import { MAPS } from './maps.js';
import { WEAPON_TYPES, ARMOR_TYPES, ABILITY_TYPES, UNIT_EQUIPMENT } from './weapons.js';

export const CONTENT_VERSION = 1;

export function validateContentRegistry(data = {
  units: UNIT_TYPES, buildings: BUILDING_TYPES, factions: FACTIONS, maps: MAPS,
  weapons: WEAPON_TYPES, armor: ARMOR_TYPES, abilities: ABILITY_TYPES, equipment: UNIT_EQUIPMENT
}) {
  const errors = [];
  for (const [category, entries] of Object.entries(data)) {
    if (!entries || typeof entries !== 'object' || Array.isArray(entries)) {
      errors.push(`${category} must be an object registry`);
      continue;
    }
    for (const [id, entry] of Object.entries(entries)) {
      if (!entry || typeof entry !== 'object') { errors.push(`${category}.${id} must be an object`); continue; }
      // Factions/maps intentionally use a display key distinct from their ID.
      if (category !== 'equipment' && category !== 'factions' && category !== 'maps' && entry.id !== id) {
        errors.push(`${category}.${id} must have id '${id}'`);
      }
    }
  }
  const { units = {}, buildings = {}, factions = {}, maps = {}, weapons = {}, armor = {}, equipment = {} } = data;
  for (const [id, unit] of Object.entries(units)) {
    if (!(unit.maxHp > 0) || !(unit.speed >= 0) || !(unit.range >= 0)) errors.push(`Invalid unit stats for ${id}`);
  }
  for (const [id, building] of Object.entries(buildings)) {
    if (!(building.maxHp > 0) || !(building.width > 0) || !(building.height > 0) || !(building.cost >= 0)) {
      errors.push(`Invalid building stats for ${id}`);
    }
    for (const produced of [building.produces].flat().filter(Boolean)) {
      if (!units[produced]) errors.push(`${id} produces an unknown unit ${produced}`);
    }
  }
  for (const [id, loadout] of Object.entries(equipment)) {
    if (!units[id]) errors.push(`Unknown equipped unit ${id}`);
    if (!armor[loadout.armor]) errors.push(`Unknown armor ${loadout.armor} for ${id}`);
    if (loadout.weapon && !weapons[loadout.weapon]) errors.push(`Unknown weapon ${loadout.weapon} for ${id}`);
  }
  for (const faction of Object.values(factions)) {
    for (const id of faction.startingUnits || []) if (!units[id]) errors.push(`Unknown starting unit ${id}`);
  }
  for (const map of Object.values(maps)) {
    if (!(map.width > 0 && map.height > 0) || !Number.isInteger(map.seed)) errors.push(`Invalid map ${map.id}`);
  }
  return errors;
}

export const GAME_CONTENT = Object.freeze({
  version: CONTENT_VERSION, units: UNIT_TYPES, buildings: BUILDING_TYPES,
  factions: FACTIONS, maps: MAPS, weapons: WEAPON_TYPES,
  armor: ARMOR_TYPES, abilities: ABILITY_TYPES, equipment: UNIT_EQUIPMENT
});
