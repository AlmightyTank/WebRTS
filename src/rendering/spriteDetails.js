// Readable, original vector trim drawn over the basic unit/building silhouettes.
// Use whole-world-pixel coordinates; camera scale and the high-DPI canvas do the
// final rasterization. This layer is visual only and never alters hitboxes.
const DARK = 0x07111a;
const LIGHT = 0xe1f6ff;
const METAL = 0x7899ac;

function bar(graphics, x, y, width, height, color, opacity) {
  graphics.fillStyle(color, opacity).fillRect(x, y, width, height);
}

export function drawBuildingDetails(graphics, building, teamColor, opacity = 1) {
  const x = Math.round(building.x);
  const y = Math.round(building.y);
  // Consistent bevels and bright highlights make each structure readable
  // without needing images that turn soft when camera zoom changes.
  if (building.type === 'command_core') {
    bar(graphics, x - 56, y - 48, 112, 4, LIGHT, opacity);
    bar(graphics, x - 51, y + 32, 102, 5, DARK, opacity);
    bar(graphics, x - 13, y - 15, 26, 26, DARK, opacity);
    bar(graphics, x - 8, y - 11, 16, 16, LIGHT, opacity);
    for (const dx of [-47, 38]) {
      bar(graphics, x + dx, y - 25, 9, 18, DARK, opacity);
      bar(graphics, x + dx + 2, y - 23, 5, 7, teamColor, opacity);
    }
  } else if (building.type === 'refinery') {
    bar(graphics, x - 42, y - 30, 6, 40, LIGHT, opacity);
    bar(graphics, x - 12, y - 34, 7, 40, DARK, opacity);
    bar(graphics, x + 23, y - 17, 15, 16, DARK, opacity);
    bar(graphics, x + 26, y - 14, 9, 10, METAL, opacity);
    bar(graphics, x - 38, y + 17, 76, 4, DARK, opacity);
  } else if (building.type === 'power_plant') {
    bar(graphics, x - 39, y - 28, 78, 4, LIGHT, opacity);
    bar(graphics, x - 35, y + 18, 70, 4, DARK, opacity);
    bar(graphics, x - 3, y - 17, 6, 23, 0xffdc77, opacity);
    bar(graphics, x - 27, y - 12, 9, 19, DARK, opacity);
    bar(graphics, x + 18, y - 12, 9, 19, DARK, opacity);
  } else if (building.type === 'machine_shop') {
    bar(graphics, x - 57, y - 39, 114, 4, LIGHT, opacity);
    bar(graphics, x - 38, y - 27, 76, 6, METAL, opacity);
    bar(graphics, x - 38, y - 15, 76, 4, DARK, opacity);
    bar(graphics, x - 38, y - 4, 76, 4, DARK, opacity);
    bar(graphics, x - 52, y + 24, 104, 4, DARK, opacity);
  } else if (building.type === 'defense_grid') {
    bar(graphics, x - 29, y - 29, 58, 4, LIGHT, opacity);
    bar(graphics, x - 6, y - 10, 12, 12, DARK, opacity);
    bar(graphics, x - 3, y - 7, 6, 6, LIGHT, opacity);
    bar(graphics, x - 26, y + 14, 52, 4, DARK, opacity);
  } else if (building.type === 'service_depot') {
    bar(graphics, x - 40, y - 29, 80, 4, LIGHT, opacity);
    bar(graphics, x - 23, y - 15, 46, 4, METAL, opacity);
    bar(graphics, x - 23, y + 2, 46, 4, METAL, opacity);
    bar(graphics, x - 4, y - 16, 8, 19, LIGHT, opacity);
    bar(graphics, x - 34, y + 18, 68, 4, DARK, opacity);
  } else {
    // Barracks and future generic buildings.
    bar(graphics, x - 40, y - 28, 80, 4, LIGHT, opacity);
    for (const dx of [-30, -8, 14]) {
      bar(graphics, x + dx, y - 13, 14, 19, DARK, opacity);
      bar(graphics, x + dx + 3, y - 10, 8, 10, METAL, opacity);
    }
    bar(graphics, x - 38, y + 17, 76, 4, DARK, opacity);
  }
}

export function drawUnitDetails(graphics, unit, teamColor) {
  const x = Math.round(unit.x);
  const y = Math.round(unit.y);
  if (unit.type === 'harvester') {
    bar(graphics, x - 19, y - 8, 20, 3, LIGHT, 1);
    bar(graphics, x - 19, y + 5, 20, 3, DARK, 1);
    bar(graphics, x + 11, y - 9, 7, 7, LIGHT, 1);
    bar(graphics, x + 12, y + 4, 6, 3, DARK, 1);
  } else if (unit.type === 'scout_bike') {
    graphics.lineStyle(2, LIGHT, 1).lineBetween(x - 14, y + 8, x + 14, y + 8);
    bar(graphics, x - 3, y - 8, 6, 9, DARK, 1);
    bar(graphics, x - 2, y - 5, 4, 4, LIGHT, 1);
  } else if (unit.type === 'light_tank' || unit.type === 'siege_tank') {
    const heavy = unit.type === 'siege_tank';
    const width = heavy ? 54 : 46;
    bar(graphics, x - width / 2, y + 9, width, 4, DARK, 1);
    for (const dx of [-17, -6, 6, 17]) bar(graphics, x + dx - 2, y + 13, 4, 3, METAL, 1);
    bar(graphics, x - 7, y - 16, 12, 3, LIGHT, 1);
    bar(graphics, x + 13, y - 8, heavy ? 17 : 13, 2, LIGHT, 1);
  } else if (unit.type === 'rocket_team') {
    bar(graphics, x - 12, y - 12, 24, 3, LIGHT, 1);
    bar(graphics, x - 11, y + 9, 22, 3, DARK, 1);
    bar(graphics, x + 10, y - 13, 3, 18, 0xffdc77, 1);
  } else if (unit.type === 'assault_trooper') {
    bar(graphics, x - 11, y - 11, 22, 3, LIGHT, 1);
    bar(graphics, x - 11, y + 7, 22, 3, DARK, 1);
    bar(graphics, x + 13, y - 9, 9, 2, LIGHT, 1);
  } else {
    // Three individual helmet highlights help rifle squads read as units,
    // rather than miniature rectangular buildings.
    for (const dx of [-10, 0, 10]) {
      bar(graphics, x + dx - 3, y - 8, 7, 3, DARK, 1);
      bar(graphics, x + dx - 2, y - 6, 5, 3, LIGHT, 1);
    }
    bar(graphics, x - 17, y + 8, 34, 2, DARK, 1);
  }
  // Common high-contrast identification stripe, not a second hitbox.
  bar(graphics, x - 8, y + 13, 16, 2, teamColor, 1);
}
