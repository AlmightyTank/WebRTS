// Data-only unit definitions; no Phaser dependencies.
export const UNIT_TYPES = Object.freeze({
  rifle_squad: Object.freeze({ id: 'rifle_squad', name: 'Rifle Squad', maxHp: 100, speed: 130, range: 105, damage: 13, attackCooldown: 0.65, cost: 100, supply: 1 }),
  rocket_team: Object.freeze({ id: 'rocket_team', name: 'Rocket Team', maxHp: 90, speed: 112, range: 155, damage: 25, attackCooldown: 1.1, cost: 175, supply: 1 }),
  assault_trooper: Object.freeze({ id: 'assault_trooper', name: 'Assault Trooper', maxHp: 125, speed: 145, range: 85, damage: 18, attackCooldown: 0.55, cost: 140, supply: 1 }),
  scout_bike: Object.freeze({ id: 'scout_bike', name: 'Scout Bike', maxHp: 75, speed: 210, range: 90, damage: 8, attackCooldown: 0.45, cost: 150, supply: 1 }),
  light_tank: Object.freeze({ id: 'light_tank', name: 'Light Tank', maxHp: 260, speed: 82, range: 170, damage: 32, attackCooldown: 1.25, cost: 350, supply: 3 }),
  siege_tank: Object.freeze({ id: 'siege_tank', name: 'Siege Tank', maxHp: 420, speed: 50, range: 220, damage: 58, attackCooldown: 2, cost: 550, supply: 4 }),
  harvester: Object.freeze({ id: 'harvester', name: 'Harvester', maxHp: 180, speed: 90, range: 45, damage: 0, attackCooldown: 0, capacity: 100, harvestRate: 50, supply: 2 })
});
