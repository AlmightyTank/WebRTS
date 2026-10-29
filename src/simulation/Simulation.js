import { BUILDING_TYPES, MAPS, UNIT_TYPES } from './content.js';
import { COMMANDS } from './commands.js';

const FIXED_STEP = 1 / 30;

export class Simulation {
  constructor({ seed = MAPS.FIRST_CONTACT.seed, map = MAPS.FIRST_CONTACT } = {}) {
    this.seed = seed >>> 0;
    this.map = map;
    this.units = [];
    this.buildings = [];
    this.resources = { 0: 1250, 1: 1250 };
    this.resourceNodes = [{ id: 1, x: 820, y: 400, amount: 5000 }, { id: 2, x: 1580, y: 400, amount: 5000 }, { id: 3, x: 820, y: 1100, amount: 5000 }, { id: 4, x: 1580, y: 1100, amount: 5000 }];
    this.tick = 0;
    this.time = 0;
    this.accumulator = 0;
    this.nextUnitId = 1;
    this.nextBuildingId = 1;
    this.nextProjectileId = 1;
    this.projectiles = [];
    this.pathCellSize = 60;
    this.commandQueue = [];
    this.events = [];
    this.gameState = 'playing';
    this.gameOverReason = null;
    this.commandCoreStarted = { 0: false, 1: false };
    this.aiTimer = 0;
  }

  addUnit({ playerId = 0, team = playerId, type = 'rifle_squad', x = 0, y = 0 } = {}) {
    const definition = UNIT_TYPES[type];
    if (!definition) throw new Error(`Unknown unit type: ${type}`);
    const unit = {
      id: this.nextUnitId++, playerId, team, type, name: definition.name, x, y,
      hp: definition.maxHp, maxHp: definition.maxHp,
      target: null, cooldown: 0, facing: 0, stance: 'aggressive', guardPosition: null, guardRadius: 180
    };
    if (type === 'harvester') {
      unit.cargo = 0;
      unit.capacity = definition.capacity;
      unit.harvesterState = 'to_resource';
      const home = this.closestRefinery(x, y, playerId) ?? this.buildings.find((building) => building.playerId === playerId && building.type === 'command_core');
      unit.homeBuildingId = home?.id ?? null;
      unit.resourceNodeId = this.closestResourceNodeToHome(unit)?.id ?? null;
    }
    this.units.push(unit);
    return unit;
  }

  addBuilding({ playerId = 0, team = playerId, type = 'command_core', x = 0, y = 0, complete = true } = {}) {
    const definition = BUILDING_TYPES[type];
    if (!definition) throw new Error(`Unknown building type: ${type}`);
    const building = { id: this.nextBuildingId++, playerId, team, type, name: definition.name, x, y, hp: definition.maxHp, maxHp: definition.maxHp, queue: [], queuePaused: false, complete, repairing: false, constructionRemaining: complete ? 0 : definition.constructionTime };
    this.buildings.push(building);
    if (type === 'command_core') this.commandCoreStarted[playerId] = true;
    return building;
  }

  getPlayerState(playerId) {
    const ownedBuildings = this.buildings.filter((building) => building.playerId === playerId && building.complete);
    const generated = ownedBuildings.reduce((sum, building) => sum + Math.max(0, BUILDING_TYPES[building.type].power ?? 0), 0);
    const consumed = ownedBuildings.reduce((sum, building) => sum + Math.max(0, -(BUILDING_TYPES[building.type].power ?? 0)), 0);
    const units = this.units.filter((unit) => unit.playerId === playerId);
    const queued = ownedBuildings.reduce((sum, building) => sum + building.queue.reduce((total, item) => total + (UNIT_TYPES[item.type]?.supply ?? 0), 0), 0);
    const usedSupply = units.reduce((sum, unit) => sum + (UNIT_TYPES[unit.type].supply ?? 0), 0) + queued;
    const capacity = ownedBuildings.reduce((sum, building) => sum + (BUILDING_TYPES[building.type].supply ?? 0), 0);
    return { generated, consumed, power: consumed === 0 ? 100 : Math.min(100, Math.floor((generated / consumed) * 100)), usedSupply, capacity };
  }

  issue(command) {
    const valid = this.validateCommand(command);
    if (!valid.ok) return valid;
    this.commandQueue.push(command);
    return { ok: true };
  }

  controlProduction(playerId, buildingId, action) {
    const building = this.buildings.find((candidate) => candidate.id === buildingId && candidate.playerId === playerId && candidate.complete);
    if (!building) return { ok: false, reason: 'invalid_producer' };
    if (action === 'clear') {
      building.queue.length = 0;
      building.queuePaused = false;
    } else if (action === 'cancel') {
      building.queue.shift();
      building.queuePaused = false;
    } else if (action === 'pause') {
      building.queuePaused = !building.queuePaused;
    }
    return { ok: true, paused: building.queuePaused, queueLength: building.queue.length };
  }

  validateCommand(command) {
    if (!command || !Object.values(COMMANDS).includes(command.type)) return { ok: false, reason: 'unknown_command' };
    const unitCommands = [COMMANDS.MOVE, COMMANDS.ATTACK, COMMANDS.STOP, COMMANDS.DEFEND];
    if (unitCommands.includes(command.type)) {
      if (!Array.isArray(command.unitIds) || command.unitIds.length === 0) return { ok: false, reason: 'no_units' };
      const units = command.unitIds.map((id) => this.units.find((unit) => unit.id === id));
      if (units.some((unit) => !unit || unit.playerId !== command.playerId)) return { ok: false, reason: 'unauthorized_unit' };
    }
    if (command.type === COMMANDS.MOVE && (!command.destination || !Number.isFinite(command.destination.x) || !Number.isFinite(command.destination.y))) return { ok: false, reason: 'invalid_destination' };
    if (command.type === COMMANDS.DEFEND && (!command.position || !Number.isFinite(command.position.x) || !Number.isFinite(command.position.y))) return { ok: false, reason: 'invalid_destination' };
    if (command.type === COMMANDS.ATTACK) {
      const targetExists = command.targetType === 'building'
        ? this.buildings.some((building) => building.id === command.targetId && building.playerId !== command.playerId)
        : this.units.some((unit) => unit.id === command.targetId && unit.playerId !== command.playerId);
      if (!targetExists) return { ok: false, reason: 'invalid_target' };
    }
    if (command.type === COMMANDS.BUILD) {
      const definition = BUILDING_TYPES[command.buildingType];
      if (!definition) return { ok: false, reason: 'unknown_building' };
      if (!this.buildings.some((building) => building.playerId === command.playerId && building.type === 'command_core' && building.complete)) return { ok: false, reason: 'no_command_core' };
      if (!command.position || this.resources[command.playerId] < definition.cost) return { ok: false, reason: 'insufficient_resources' };
      if (!this.canPlace(command.buildingType, command.position)) return { ok: false, reason: 'invalid_placement' };
    }
    if (command.type === COMMANDS.PRODUCE) {
      const building = this.buildings.find((candidate) => candidate.id === command.buildingId);
      const definition = building && BUILDING_TYPES[building.type];
      if (!building || building.playerId !== command.playerId || !building.complete || !definition?.produces) return { ok: false, reason: 'invalid_producer' };
      const products = Array.isArray(definition.produces) ? definition.produces : [definition.produces];
      const productType = command.unitType ?? products[0];
      if (!products.includes(productType) || !UNIT_TYPES[productType]) return { ok: false, reason: 'invalid_product' };
      const unitDefinition = UNIT_TYPES[productType];
      const queuedCost = building.queue.reduce((total, item) => total + (UNIT_TYPES[item.type]?.cost ?? 0), 0);
      if (this.resources[command.playerId] < queuedCost + (unitDefinition.cost ?? 0)) return { ok: false, reason: 'insufficient_resources' };
      const state = this.getPlayerState(command.playerId);
      if (state.capacity > 0 && state.usedSupply + (unitDefinition.supply ?? 0) > state.capacity) return { ok: false, reason: 'supply_limit' };
      if (this.commandCoreStarted[command.playerId] && state.generated > 0 && state.power < 100) return { ok: false, reason: 'insufficient_power' };
    }
    if (command.type === COMMANDS.REPAIR || command.type === COMMANDS.SELL) {
      const targetId = command.targetId ?? command.buildingId;
      const targetType = command.targetType ?? 'building';
      const target = targetType === 'unit'
        ? this.units.find((candidate) => candidate.id === targetId)
        : this.buildings.find((candidate) => candidate.id === targetId);
      if (!target || target.playerId !== command.playerId || (targetType === 'building' && !target.complete)) return { ok: false, reason: 'invalid_target' };
      if (command.type === COMMANDS.SELL && targetType !== 'building') return { ok: false, reason: 'cannot_sell_unit' };
      if (command.type === COMMANDS.SELL && target.type === 'command_core') return { ok: false, reason: 'cannot_sell_command_core' };
      if (command.type === COMMANDS.REPAIR && target.hp >= target.maxHp) return { ok: false, reason: 'already_repaired' };
      if (command.type === COMMANDS.REPAIR && target.repairing) return { ok: false, reason: 'repair_in_progress' };
      if (command.type === COMMANDS.REPAIR && this.resources[command.playerId] < 100) return { ok: false, reason: 'insufficient_resources' };
    }
    return { ok: true };
  }

  canPlace(type, position) {
    const definition = BUILDING_TYPES[type];
    return position.x > definition.width / 2 && position.x < this.map.width - definition.width / 2
      && position.y > definition.height / 2 && position.y < this.map.height - definition.height / 2
      && !this.buildings.some((building) => {
        const other = BUILDING_TYPES[building.type];
        return Math.abs(building.x - position.x) < (other.width + definition.width) / 2
          && Math.abs(building.y - position.y) < (other.height + definition.height) / 2;
      })
      && !this.units.some((unit) => this.unitOverlapsBuilding(unit.x, unit.y, type, position.x, position.y))
      && !this.commandQueue.some((command) => command.type === COMMANDS.BUILD && Math.abs(command.position.x - position.x) < (BUILDING_TYPES[command.buildingType].width + definition.width) / 2 && Math.abs(command.position.y - position.y) < (BUILDING_TYPES[command.buildingType].height + definition.height) / 2);
  }

  unitOverlapsBuilding(x, y, buildingType, buildingX, buildingY) {
    const definition = BUILDING_TYPES[buildingType];
    const closestX = Math.max(buildingX - definition.width / 2, Math.min(x, buildingX + definition.width / 2));
    const closestY = Math.max(buildingY - definition.height / 2, Math.min(y, buildingY + definition.height / 2));
    return Math.hypot(x - closestX, y - closestY) < 25;
  }

  canUnitOccupy(unit, x, y) {
    return x >= 25 && x <= this.map.width - 25 && y >= 25 && y <= this.map.height - 25
      && !this.buildings.some((building) => this.unitOverlapsBuilding(x, y, building.type, building.x, building.y));
  }

  findPath(start, goal) {
    const size = this.pathCellSize;
    const columns = Math.ceil(this.map.width / size);
    const rows = Math.ceil(this.map.height / size);
    const toCell = (point) => ({ x: Math.max(0, Math.min(columns - 1, Math.floor(point.x / size))), y: Math.max(0, Math.min(rows - 1, Math.floor(point.y / size))) });
    const cellPoint = (cell) => ({ x: cell.x * size + size / 2, y: cell.y * size + size / 2 });
    const key = (cell) => `${cell.x},${cell.y}`;
    const walkable = (cell) => {
      if (cell.x < 0 || cell.x >= columns || cell.y < 0 || cell.y >= rows) return false;
      const point = cellPoint(cell);
      return this.canUnitOccupy({}, point.x, point.y);
    };
    const nearestWalkable = (cell) => {
      if (walkable(cell)) return cell;
      for (let radius = 1; radius < Math.max(columns, rows); radius += 1) {
        for (let y = cell.y - radius; y <= cell.y + radius; y += 1) {
          for (let x = cell.x - radius; x <= cell.x + radius; x += 1) {
            const candidate = { x, y };
            if (walkable(candidate)) return candidate;
          }
        }
      }
      return null;
    };
    const startCell = nearestWalkable(toCell(start));
    const goalCell = nearestWalkable(toCell(goal));
    if (!startCell || !goalCell) return [];
    const directions = [[1, 0, 1], [-1, 0, 1], [0, 1, 1], [0, -1, 1], [1, 1, Math.SQRT2], [-1, 1, Math.SQRT2], [1, -1, Math.SQRT2], [-1, -1, Math.SQRT2]];
    const heuristic = (a, b) => Math.hypot(a.x - b.x, a.y - b.y);
    const open = [{ cell: startCell, g: 0, f: heuristic(startCell, goalCell) }];
    const cameFrom = new Map();
    const cost = new Map([[key(startCell), 0]]);
    while (open.length) {
      open.sort((a, b) => a.f - b.f);
      const current = open.shift().cell;
      if (key(current) === key(goalCell)) {
        const path = [];
        let cursor = current;
        while (key(cursor) !== key(startCell)) {
          path.unshift(cellPoint(cursor));
          cursor = cameFrom.get(key(cursor));
        }
        return path;
      }
      for (const [dx, dy, stepCost] of directions) {
        const next = { x: current.x + dx, y: current.y + dy };
        if (!walkable(next)) continue;
        if (dx !== 0 && dy !== 0 && (!walkable({ x: current.x + dx, y: current.y }) || !walkable({ x: current.x, y: current.y + dy }))) continue;
        const nextKey = key(next);
        const nextCost = (cost.get(key(current)) ?? Infinity) + stepCost;
        if (nextCost < (cost.get(nextKey) ?? Infinity)) {
          cameFrom.set(nextKey, current);
          cost.set(nextKey, nextCost);
          open.push({ cell: next, g: nextCost, f: nextCost + heuristic(next, goalCell) });
        }
      }
    }
    return [];
  }

  findSpawnPosition(building) {
    const definition = BUILDING_TYPES[building.type];
    const distance = Math.max(definition.width, definition.height) / 2 + 35;
    const candidates = [
      { x: building.x + distance, y: building.y }, { x: building.x - distance, y: building.y },
      { x: building.x, y: building.y + distance }, { x: building.x, y: building.y - distance }
    ];
    return candidates.find(({ x, y }) => {
      const probe = { x, y };
      return this.canUnitOccupy(probe, x, y) && !this.units.some((unit) => Math.hypot(unit.x - x, unit.y - y) < 50);
    });
  }

  closestResourceNode(x, y) {
    const available = this.resourceNodes.filter((node) => node.amount > 0);
    return (available.length ? available : this.resourceNodes).reduce((closest, node) => {
      return Math.hypot(node.x - x, node.y - y) < Math.hypot(closest.x - x, closest.y - y) ? node : closest;
    });
  }

  closestResourceNodeToHome(unit) {
    const home = this.buildings.find((building) => building.id === unit.homeBuildingId)
      ?? this.closestRefinery(unit.x, unit.y, unit.playerId)
      ?? this.buildings.find((building) => building.playerId === unit.playerId && building.type === 'command_core');
    if (!home) return this.closestResourceNode(unit.x, unit.y);
    const available = this.resourceNodes.filter((node) => node.amount > 0);
    return available.sort((a, b) => Math.hypot(a.x - home.x, a.y - home.y) - Math.hypot(b.x - home.x, b.y - home.y))[0];
  }

  closestRefinery(x, y, playerId) {
    return this.buildings.filter((building) => building.playerId === playerId && building.type === 'refinery')
      .sort((a, b) => Math.hypot(a.x - x, a.y - y) - Math.hypot(b.x - x, b.y - y))[0];
  }

  moveUnitToward(unit, x, y, speed, dt) {
    const dx = x - unit.x;
    const dy = y - unit.y;
    const distance = Math.hypot(dx, dy);
    if (distance <= 1) return true;
    const step = Math.min(distance, speed * dt);
    const nextX = unit.x + (dx / distance) * step;
    const nextY = unit.y + (dy / distance) * step;
    this.tryMoveUnit(unit, nextX, nextY, dx, dy);
    return distance <= speed * dt + 1;
  }

  tryMoveUnit(unit, nextX, nextY, dx, dy) {
    if (this.canUnitOccupy(unit, nextX, nextY)) {
      unit.facing = Math.atan2(nextY - unit.y, nextX - unit.x);
      unit.x = nextX;
      unit.y = nextY;
      return true;
    }
    // Slide along the clear axis rather than cancelling the order at a corner.
    const xFirst = Math.abs(dx) >= Math.abs(dy);
    const candidates = xFirst
      ? [[nextX, unit.y], [unit.x, nextY]]
      : [[unit.x, nextY], [nextX, unit.y]];
    const clear = candidates.find(([x, y]) => this.canUnitOccupy(unit, x, y));
    if (!clear) {
      const detourDistance = 45;
      const detours = [
        [unit.x + detourDistance, unit.y], [unit.x - detourDistance, unit.y],
        [unit.x, unit.y + detourDistance], [unit.x, unit.y - detourDistance],
        [unit.x + detourDistance, unit.y + detourDistance], [unit.x - detourDistance, unit.y + detourDistance],
        [unit.x + detourDistance, unit.y - detourDistance], [unit.x - detourDistance, unit.y - detourDistance]
      ];
      const detour = detours.find(([x, y]) => this.canUnitOccupy(unit, x, y));
      if (!detour) return false;
      unit.facing = Math.atan2(detour[1] - unit.y, detour[0] - unit.x);
      [unit.x, unit.y] = detour;
      return true;
    }
    unit.facing = Math.atan2(clear[1] - unit.y, clear[0] - unit.x);
    [unit.x, unit.y] = clear;
    return true;
  }

  separateUnits() {
    const minimum = 38;
    for (let i = 0; i < this.units.length; i += 1) {
      for (let j = i + 1; j < this.units.length; j += 1) {
        const a = this.units[i];
        const b = this.units[j];
        let dx = b.x - a.x;
        let dy = b.y - a.y;
        let distance = Math.hypot(dx, dy);
        if (distance >= minimum) continue;
        if (distance < 0.001) {
          dx = ((a.id * 17 + b.id * 7) % 3) - 1;
          dy = ((a.id * 11 + b.id * 5) % 3) - 1;
          distance = Math.hypot(dx, dy) || 1;
        }
        const push = (minimum - distance) / 2;
        const nx = dx / distance;
        const ny = dy / distance;
        const aX = a.x - nx * push;
        const aY = a.y - ny * push;
        const bX = b.x + nx * push;
        const bY = b.y + ny * push;
        if (this.canUnitOccupy(a, aX, aY)) [a.x, a.y] = [aX, aY];
        if (this.canUnitOccupy(b, bX, bY)) [b.x, b.y] = [bX, bY];
      }
    }
  }

  updateProjectiles(dt) {
    const remaining = [];
    this.projectiles.forEach((projectile) => {
      const target = projectile.targetType === 'building'
        ? this.buildings.find((building) => building.id === projectile.targetId)
        : this.units.find((unit) => unit.id === projectile.targetId);
      if (!target || target.hp <= 0) return;
      const dx = target.x - projectile.x;
      const dy = target.y - projectile.y;
      const distance = Math.hypot(dx, dy);
      if (distance <= projectile.speed * dt + (projectile.targetType === 'building' ? 18 : 8)) {
        target.hp -= projectile.damage;
        this.events.push({ type: 'damage', sourceId: projectile.sourceId, targetId: projectile.targetId, amount: projectile.damage });
        return;
      }
      projectile.x += (dx / distance) * projectile.speed * dt;
      projectile.y += (dy / distance) * projectile.speed * dt;
      remaining.push(projectile);
    });
    this.projectiles = remaining;
  }

  updateHarvester(unit, dt) {
    const definition = UNIT_TYPES[unit.type];
    if (unit.harvesterState === 'to_resource' || unit.harvesterState === 'harvesting') {
      const node = this.resourceNodes.find((candidate) => candidate.id === unit.resourceNodeId) ?? this.closestResourceNode(unit.x, unit.y);
      if (!node || node.amount <= 0) {
        const nextNode = this.closestResourceNodeToHome(unit);
        if (!nextNode) {
          unit.harvesterState = 'idle';
          return;
        }
        unit.resourceNodeId = nextNode.id;
        unit.harvesterState = 'to_resource';
      }
      const activeNode = this.resourceNodes.find((candidate) => candidate.id === unit.resourceNodeId);
      if (this.moveUnitToward(unit, activeNode.x, activeNode.y, definition.speed, dt) && Math.hypot(unit.x - activeNode.x, unit.y - activeNode.y) <= definition.range) {
        unit.harvesterState = 'harvesting';
        const harvested = Math.min(unit.capacity - unit.cargo, definition.harvestRate * dt, activeNode.amount);
        unit.cargo += harvested;
        activeNode.amount -= harvested;
        if (unit.cargo >= unit.capacity || activeNode.amount <= 0) unit.harvesterState = 'to_refinery';
      }
      return;
    }

    const refinery = this.closestRefinery(unit.x, unit.y, unit.playerId);
    if (!refinery) return;
    const refineryType = BUILDING_TYPES[refinery.type];
    const dropX = refinery.x + refineryType.width / 2 + 30;
    if (this.moveUnitToward(unit, dropX, refinery.y, definition.speed, dt) && Math.abs(unit.x - dropX) <= 8 && Math.abs(unit.y - refinery.y) <= 8) {
      this.resources[unit.playerId] += unit.cargo;
      this.events.push({ type: 'harvester_deposit', unitId: unit.id, amount: unit.cargo });
      unit.cargo = 0;
      const nextNode = this.closestResourceNodeToHome(unit);
      unit.harvesterState = nextNode ? 'to_resource' : 'idle';
      if (nextNode) unit.resourceNodeId = nextNode.id;
    }
  }

  advance(realDelta) {
    this.accumulator = Math.min(this.accumulator + Math.max(0, realDelta), 0.25);
    while (this.accumulator >= FIXED_STEP) {
      this.step(FIXED_STEP);
      this.accumulator -= FIXED_STEP;
    }
  }

  step(dt) {
    this.tick += 1;
    this.time += dt;
    this.events.length = 0;
    if (this.gameState !== 'playing') return;
    while (this.commandQueue.length) this.apply(this.commandQueue.shift());
    this.aiTimer -= dt;
    if (this.aiTimer <= 0) {
      this.aiTimer = 1.5;
      this.updateEnemyAI();
    }

    // Defensive emplacements acquire the nearest enemy automatically.
    this.buildings.filter((building) => building.complete && BUILDING_TYPES[building.type].range).forEach((building) => {
      const definition = BUILDING_TYPES[building.type];
      const powerState = this.getPlayerState(building.playerId);
      if (powerState.generated > 0 && powerState.power < 100) return;
      building.cooldown = Math.max(0, (building.cooldown ?? 0) - dt);
      const target = this.units
        .filter((unit) => unit.team !== building.team && Math.hypot(unit.x - building.x, unit.y - building.y) <= definition.range)
        .sort((a, b) => Math.hypot(a.x - building.x, a.y - building.y) - Math.hypot(b.x - building.x, b.y - building.y))[0];
      if (target && building.cooldown === 0) {
        this.projectiles.push({ id: this.nextProjectileId++, sourceId: building.id, targetId: target.id, targetType: 'unit', x: building.x, y: building.y, speed: 500, damage: definition.damage, team: building.team });
        building.cooldown = definition.attackCooldown;
        this.events.push({ type: 'projectile_fired', sourceId: building.id, targetId: target.id });
      }
    });

    this.buildings.forEach((building) => {
      if (building.complete) return;
      building.constructionRemaining = Math.max(0, building.constructionRemaining - dt);
      if (building.constructionRemaining === 0) {
        building.complete = true;
        this.events.push({ type: 'building_completed', buildingId: building.id });
      }
    });

    // Service depots continuously restore nearby friendly vehicles.
    this.buildings.filter((building) => building.complete && BUILDING_TYPES[building.type].repairRadius).forEach((depot) => {
      const definition = BUILDING_TYPES[depot.type];
      this.units
        .filter((unit) => unit.playerId === depot.playerId && ['scout_bike', 'light_tank', 'siege_tank', 'harvester'].includes(unit.type))
        .filter((unit) => unit.hp < unit.maxHp && Math.hypot(unit.x - depot.x, unit.y - depot.y) <= definition.repairRadius)
        .forEach((unit) => {
          unit.hp = Math.min(unit.maxHp, unit.hp + definition.repairRate * dt);
          this.events.push({ type: 'unit_repaired', unitId: unit.id, buildingId: depot.id });
        });
    });

    this.buildings.filter((building) => building.complete && building.repairing).forEach((building) => {
      const repairRate = Math.max(18, building.maxHp * 0.12);
      building.hp = Math.min(building.maxHp, building.hp + repairRate * dt);
      this.events.push({ type: 'building_repaired', buildingId: building.id });
      if (building.hp >= building.maxHp) building.repairing = false;
    });
    this.units.filter((unit) => unit.repairing).forEach((unit) => {
      unit.hp = Math.min(unit.maxHp, unit.hp + Math.max(18, unit.maxHp * 0.12) * dt);
      if (unit.hp >= unit.maxHp) unit.repairing = false;
      this.events.push({ type: 'unit_repaired', unitId: unit.id });
    });

    for (const unit of this.units) {
      const definition = UNIT_TYPES[unit.type];
      unit.cooldown = Math.max(0, unit.cooldown - dt);
      if (unit.type === 'harvester') {
        this.updateHarvester(unit, dt);
        continue;
      }
      if (unit.stance === 'defend_area' && !unit.target) {
        const enemy = this.units
          .filter((candidate) => candidate.team !== unit.team && unit.guardPosition && Math.hypot(candidate.x - unit.guardPosition.x, candidate.y - unit.guardPosition.y) <= unit.guardRadius)
          .sort((a, b) => Math.hypot(a.x - unit.x, a.y - unit.y) - Math.hypot(b.x - unit.x, b.y - unit.y))[0];
        if (enemy) unit.target = enemy.id;
      }
      if (!unit.target) continue;
      const buildingTarget = unit.target.kind === 'building';
      const target = buildingTarget
        ? this.buildings.find((candidate) => candidate.id === unit.target.id)
        : typeof unit.target === 'number' ? this.units.find((candidate) => candidate.id === unit.target) : unit.target;
      if (!target || ((typeof unit.target === 'number' || buildingTarget) && target.hp <= 0)) {
        unit.target = null;
        continue;
      }
      const dx = target.x - unit.x;
      const dy = target.y - unit.y;
      const distance = Math.hypot(dx, dy);
      if (unit.stance === 'defend_area' && typeof unit.target !== 'number' && !buildingTarget && distance <= 8) {
        unit.target = null;
        continue;
      }
      const targetRadius = buildingTarget ? Math.max(BUILDING_TYPES[target.type].width, BUILDING_TYPES[target.type].height) / 2 : 0;
      if (distance - targetRadius > definition.range) {
        let destination = target;
        const path = unit.target.path;
        if (path?.length) {
          while (unit.target.waypointIndex < path.length - 1 && Math.hypot(unit.x - path[unit.target.waypointIndex].x, unit.y - path[unit.target.waypointIndex].y) < 12) unit.target.waypointIndex += 1;
          destination = path[unit.target.waypointIndex];
        }
        const pathDx = destination.x - unit.x;
        const pathDy = destination.y - unit.y;
        const pathDistance = Math.hypot(pathDx, pathDy) || 1;
        const nextX = unit.x + (pathDx / pathDistance) * definition.speed * dt;
        const nextY = unit.y + (pathDy / pathDistance) * definition.speed * dt;
        if (!this.tryMoveUnit(unit, nextX, nextY, pathDx, pathDy)) {
          unit.target = null;
        }
      } else if ((typeof unit.target === 'number' || buildingTarget) && unit.cooldown === 0) {
        this.projectiles.push({
          id: this.nextProjectileId++, sourceId: unit.id, targetId: buildingTarget ? unit.target.id : unit.target,
          targetType: buildingTarget ? 'building' : 'unit', x: unit.x, y: unit.y,
          speed: 460, damage: definition.damage, team: unit.team
        });
        unit.cooldown = definition.attackCooldown;
        this.events.push({ type: 'projectile_fired', sourceId: unit.id, targetId: target.id });
      }
      unit.x = Math.max(0, Math.min(this.map.width, unit.x));
      unit.y = Math.max(0, Math.min(this.map.height, unit.y));
    }

    this.separateUnits();
    this.updateProjectiles(dt);

    const destroyedBuildings = this.buildings.filter((building) => building.hp <= 0);
    destroyedBuildings.forEach((building) => {
      this.events.push({ type: 'building_destroyed', buildingId: building.id });
      this.units.forEach((unit) => {
        if (unit.homeBuildingId === building.id || unit.target?.kind === 'building' && unit.target.id === building.id) unit.target = null;
        if (unit.homeBuildingId === building.id) unit.homeBuildingId = null;
      });
    });
    if (destroyedBuildings.length) {
      const destroyedIds = new Set(destroyedBuildings.map((building) => building.id));
      this.buildings.splice(0, this.buildings.length, ...this.buildings.filter((building) => !destroyedIds.has(building.id)));
    }

    const dead = this.units.filter((unit) => unit.hp <= 0);
    dead.forEach((unit) => this.events.push({ type: 'unit_destroyed', unitId: unit.id }));
    if (dead.length) {
      const deadIds = new Set(dead.map((unit) => unit.id));
      this.units.splice(0, this.units.length, ...this.units.filter((unit) => !deadIds.has(unit.id)));
    }

    this.checkGameState();

    this.buildings.forEach((building) => {
      if (!building.queue.length) return;
      if (!building.complete || building.queuePaused) return;
      const item = building.queue[0];
      item.remaining -= dt;
      if (item.remaining <= 0) {
        const definition = BUILDING_TYPES[building.type];
        const spawn = this.findSpawnPosition(building);
        if (!spawn) return;
        this.addUnit({ playerId: building.playerId, team: building.team, type: item.type, x: spawn.x, y: spawn.y });
        building.queue.shift();
        this.events.push({ type: 'production_complete', buildingId: building.id });
      }
    });
  }

  updateEnemyAI() {
    const enemyUnits = this.units.filter((unit) => unit.playerId === 1 && unit.type !== 'harvester');
    const playerTargets = [...this.units.filter((unit) => unit.playerId === 0), ...this.buildings.filter((building) => building.playerId === 0)];
    const target = playerTargets.sort((a, b) => Math.hypot(a.x - 1900, a.y - 750) - Math.hypot(b.x - 1900, b.y - 750))[0];
    if (target) enemyUnits.filter((unit) => !unit.target).forEach((unit) => {
      this.issue({ type: COMMANDS.ATTACK, playerId: 1, unitIds: [unit.id], targetId: target.id, targetType: target.queue ? 'building' : 'unit' });
    });
    const barracks = this.buildings.find((building) => building.playerId === 1 && building.type === 'barracks' && building.complete && !building.queue.length);
    if (barracks && this.resources[1] >= (UNIT_TYPES.rifle_squad.cost ?? 0)) this.issue({ type: COMMANDS.PRODUCE, playerId: 1, buildingId: barracks.id });
  }

  checkGameState() {
    if (!this.commandCoreStarted[0] || !this.commandCoreStarted[1]) return;
    const playerAlive = this.buildings.some((building) => building.playerId === 0 && building.type === 'command_core');
    const enemyAlive = this.buildings.some((building) => building.playerId === 1 && building.type === 'command_core');
    if (!playerAlive) {
      this.gameState = 'defeat';
      this.gameOverReason = 'COMMAND CORE LOST';
    } else if (!enemyAlive) {
      this.gameState = 'victory';
      this.gameOverReason = 'ENEMY COMMAND CORE DESTROYED';
    }
    if (this.gameState !== 'playing') this.events.push({ type: 'game_over', result: this.gameState });
  }

  apply(command) {
    const selected = (command.unitIds ?? []).map((id) => this.units.find((unit) => unit.id === id)).filter(Boolean);
    if (command.type === COMMANDS.STOP) selected.forEach((unit) => { unit.target = null; unit.stance = 'aggressive'; unit.guardPosition = null; });
    if (command.type === COMMANDS.DEFEND) selected.forEach((unit) => {
      unit.stance = 'defend_area';
      unit.guardPosition = { ...command.position };
      unit.guardRadius = command.radius ?? 180;
      unit.target = { x: command.position.x, y: command.position.y, path: this.findPath(unit, command.position), waypointIndex: 0 };
    });
    if (command.type === COMMANDS.ATTACK) selected.forEach((unit) => {
      unit.stance = 'aggressive';
      unit.guardPosition = null;
      if (command.targetType === 'building') {
        const building = this.buildings.find((candidate) => candidate.id === command.targetId);
        unit.target = { kind: 'building', id: command.targetId, path: building ? this.findPath(unit, building) : [], waypointIndex: 0 };
      } else unit.target = command.targetId;
    });
    if (command.type === COMMANDS.MOVE) {
      selected.forEach((unit, index) => {
        unit.stance = 'aggressive';
        unit.guardPosition = null;
        const angle = (index / Math.max(1, selected.length)) * Math.PI * 2;
        const destination = { x: command.destination.x + Math.cos(angle) * 42, y: command.destination.y + Math.sin(angle) * 42 };
        unit.target = { ...destination, path: this.findPath(unit, destination), waypointIndex: 0 };
      });
    }
    if (command.type === COMMANDS.BUILD) {
      const definition = BUILDING_TYPES[command.buildingType];
      this.resources[command.playerId] -= definition.cost;
      this.addBuilding({ playerId: command.playerId, team: command.playerId, type: command.buildingType, x: command.position.x, y: command.position.y, complete: false });
      this.events.push({ type: 'building_created', buildingType: command.buildingType });
    }
    if (command.type === COMMANDS.PRODUCE) {
      const building = this.buildings.find((candidate) => candidate.id === command.buildingId);
      const definition = BUILDING_TYPES[building.type];
      const products = Array.isArray(definition.produces) ? definition.produces : [definition.produces];
      const productType = command.unitType ?? products[0];
      this.resources[command.playerId] -= (UNIT_TYPES[productType].cost ?? 0);
      building.queue.push({ type: productType, remaining: UNIT_TYPES[productType].productionTime ?? definition.productionTime });
    }
    if (command.type === COMMANDS.REPAIR) {
      const targetId = command.targetId ?? command.buildingId;
      const targetType = command.targetType ?? 'building';
      const target = targetType === 'unit' ? this.units.find((candidate) => candidate.id === targetId) : this.buildings.find((candidate) => candidate.id === targetId);
      this.resources[command.playerId] -= 100;
      target.repairing = true;
      this.events.push({ type: 'repair_started', targetId, targetType });
    }
    if (command.type === COMMANDS.SELL) {
      const index = this.buildings.findIndex((candidate) => candidate.id === command.buildingId);
      const building = this.buildings[index];
      this.resources[command.playerId] += Math.floor((BUILDING_TYPES[building.type].cost ?? 0) * 0.5);
      this.buildings.splice(index, 1);
      this.units.filter((unit) => unit.homeBuildingId === command.buildingId).forEach((unit) => { unit.homeBuildingId = null; });
      this.events.push({ type: 'building_sold', buildingId: command.buildingId });
    }
  }

  snapshot() {
    return JSON.parse(JSON.stringify({ seed: this.seed, tick: this.tick, time: this.time, resources: this.resources, resourceNodes: this.resourceNodes, buildings: this.buildings, units: this.units, projectiles: this.projectiles, gameState: this.gameState, gameOverReason: this.gameOverReason, playerState: { 0: this.getPlayerState(0), 1: this.getPlayerState(1) } }));
  }
}
