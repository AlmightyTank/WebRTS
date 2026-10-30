// Data-only base construction definitions.
export const BUILDING_TYPES = Object.freeze({
  command_core: Object.freeze({ id: 'command_core', name: 'Command Core', maxHp: 1200, cost: 0, width: 180, height: 180, constructionTime: 0, power: 40, supply: 8 }),
  refinery: Object.freeze({ id: 'refinery', name: 'Refinery', maxHp: 500, cost: 300, width: 120, height: 100, constructionTime: 8, power: -5 }),
  barracks: Object.freeze({ id: 'barracks', name: 'Barracks', maxHp: 450, cost: 250, width: 120, height: 100, constructionTime: 6, power: -5, supply: 5, produces: ['rifle_squad', 'rocket_team', 'assault_trooper'], productionTime: 3 }),
  machine_shop: Object.freeze({ id: 'machine_shop', name: 'War Factory', maxHp: 700, cost: 800, width: 160, height: 120, constructionTime: 10, power: -25, supply: 8, produces: ['scout_bike', 'light_tank', 'siege_tank'], productionTime: 4 }),
  defense_grid: Object.freeze({ id: 'defense_grid', name: 'Sentry Turret', maxHp: 520, cost: 450, width: 86, height: 86, constructionTime: 7, power: -10, range: 230, damage: 22, attackCooldown: 1.2 }),
  service_depot: Object.freeze({ id: 'service_depot', name: 'Service Depot', maxHp: 460, cost: 500, width: 120, height: 95, constructionTime: 8, power: -10, repairRadius: 150, repairRate: 18 }),
  power_plant: Object.freeze({ id: 'power_plant', name: 'Power Plant', maxHp: 400, cost: 400, width: 120, height: 100, constructionTime: 8, power: 35 })
});
