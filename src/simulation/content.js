export const CONTENT_VERSION = 1;

export const UNIT_TYPES = Object.freeze({
  rifle_squad: Object.freeze({ id: 'rifle_squad', name: 'Rifle Squad', maxHp: 100, speed: 130, range: 105, damage: 13, attackCooldown: 0.65, cost: 100, supply: 1 }),
  rocket_team: Object.freeze({ id: 'rocket_team', name: 'Rocket Team', maxHp: 90, speed: 112, range: 155, damage: 25, attackCooldown: 1.1, cost: 175, supply: 1 }),
  assault_trooper: Object.freeze({ id: 'assault_trooper', name: 'Assault Trooper', maxHp: 125, speed: 145, range: 85, damage: 18, attackCooldown: 0.55, cost: 140, supply: 1 }),
  scout_bike: Object.freeze({ id: 'scout_bike', name: 'Scout Bike', maxHp: 75, speed: 210, range: 90, damage: 8, attackCooldown: 0.45, cost: 150, supply: 1 }),
  light_tank: Object.freeze({ id: 'light_tank', name: 'Light Tank', maxHp: 260, speed: 82, range: 170, damage: 32, attackCooldown: 1.25, cost: 350, supply: 3 }),
  siege_tank: Object.freeze({ id: 'siege_tank', name: 'Siege Tank', maxHp: 420, speed: 50, range: 220, damage: 58, attackCooldown: 2, cost: 550, supply: 4 }),
  harvester: Object.freeze({ id: 'harvester', name: 'Harvester', maxHp: 180, speed: 90, range: 45, damage: 0, attackCooldown: 0, capacity: 100, harvestRate: 50, supply: 2 })
});

export const BUILDING_TYPES = Object.freeze({
  command_core: Object.freeze({ id: 'command_core', name: 'Command Core', maxHp: 1200, cost: 0, width: 180, height: 180, constructionTime: 0, power: 40, supply: 8 }),
  refinery: Object.freeze({ id: 'refinery', name: 'Refinery', maxHp: 500, cost: 300, width: 120, height: 100, constructionTime: 8, power: -5 }),
  barracks: Object.freeze({ id: 'barracks', name: 'Barracks', maxHp: 450, cost: 250, width: 120, height: 100, constructionTime: 6, power: -5, supply: 5, produces: ['rifle_squad', 'rocket_team', 'assault_trooper'], productionTime: 3 }),
  machine_shop: Object.freeze({ id: 'machine_shop', name: 'War Factory', maxHp: 700, cost: 800, width: 160, height: 120, constructionTime: 10, power: -25, supply: 8, produces: ['scout_bike', 'light_tank', 'siege_tank'], productionTime: 4 }),
  defense_grid: Object.freeze({ id: 'defense_grid', name: 'Sentry Turret', maxHp: 520, cost: 450, width: 86, height: 86, constructionTime: 7, power: -10, range: 230, damage: 22, attackCooldown: 1.2 }),
  service_depot: Object.freeze({ id: 'service_depot', name: 'Service Depot', maxHp: 460, cost: 500, width: 120, height: 95, constructionTime: 8, power: -10, repairRadius: 150, repairRate: 18 }),
  power_plant: Object.freeze({ id: 'power_plant', name: 'Power Plant', maxHp: 400, cost: 400, width: 120, height: 100, constructionTime: 8, power: 35 })
});

export const FACTIONS = Object.freeze({
  IRON_COLLECTIVE: Object.freeze({ id: 'iron_collective', name: 'Iron Collective', startingUnits: ['rifle_squad'] }),
  VANGUARD_LEAGUE: Object.freeze({ id: 'vanguard_league', name: 'Vanguard League', startingUnits: ['rifle_squad'] })
});

export const MAPS = Object.freeze({
  FIRST_CONTACT: Object.freeze({ id: 'first_contact', name: 'First Contact', width: 2400, height: 1500, seed: 1337 })
});
