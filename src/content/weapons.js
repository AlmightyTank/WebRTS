// Stable IDs for future damage/armor simulation; existing unit combat stats remain authoritative.
export const WEAPON_TYPES = Object.freeze({
  rifle: Object.freeze({ id: 'rifle', damageType: 'bullet', targetDomains: ['ground'] }),
  rocket: Object.freeze({ id: 'rocket', damageType: 'explosive', targetDomains: ['ground', 'air'] }),
  cannon: Object.freeze({ id: 'cannon', damageType: 'shell', targetDomains: ['ground'] }),
  siege: Object.freeze({ id: 'siege', damageType: 'artillery', targetDomains: ['ground'] }),
  turret: Object.freeze({ id: 'turret', damageType: 'shell', targetDomains: ['ground'] })
});
export const ARMOR_TYPES = Object.freeze({
  infantry: Object.freeze({ id: 'infantry', category: 'light' }),
  light_vehicle: Object.freeze({ id: 'light_vehicle', category: 'light' }),
  heavy_vehicle: Object.freeze({ id: 'heavy_vehicle', category: 'heavy' }),
  structure: Object.freeze({ id: 'structure', category: 'fortified' })
});
export const UNIT_EQUIPMENT = Object.freeze({
  rifle_squad: Object.freeze({ weapon: 'rifle', armor: 'infantry' }),
  rocket_team: Object.freeze({ weapon: 'rocket', armor: 'infantry' }),
  assault_trooper: Object.freeze({ weapon: 'rifle', armor: 'infantry' }),
  scout_bike: Object.freeze({ weapon: 'rifle', armor: 'light_vehicle' }),
  light_tank: Object.freeze({ weapon: 'cannon', armor: 'heavy_vehicle' }),
  siege_tank: Object.freeze({ weapon: 'siege', armor: 'heavy_vehicle' }),
  harvester: Object.freeze({ weapon: null, armor: 'heavy_vehicle' })
});
export const ABILITY_TYPES = Object.freeze({
  guard: Object.freeze({ id: 'guard', domain: 'combat', cooldown: 0 }),
  repair: Object.freeze({ id: 'repair', domain: 'economy', cooldown: 0 }),
  deploy: Object.freeze({ id: 'deploy', domain: 'construction', cooldown: 0 })
});
