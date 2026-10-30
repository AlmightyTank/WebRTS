// Phaser-agnostic draw calls: the Battlefield owns its graphics objects.
export function drawTerrain(layer, world, team) {
  layer.clear();
  layer.fillStyle(0x17263a, 1).fillRect(0, 0, world.width, world.height);
  layer.lineStyle(1, 0x28425d, 0.65);
  for (let x = 0; x <= world.width; x += 80) layer.lineBetween(x, 0, x, world.height);
  for (let y = 0; y <= world.height; y += 80) layer.lineBetween(0, y, world.width, y);
  layer.fillStyle(0x20384a, 1).fillCircle(1200, 750, 190);
  layer.lineStyle(3, 0x46718a, 0.7).strokeCircle(1200, 750, 190);
  layer.fillStyle(team.PLAYER, 0.16).fillRect(240, 440, 430, 620);
  layer.fillStyle(team.ENEMY, 0.16).fillRect(1730, 440, 430, 620);
}

export function drawResources(layer, nodes) {
  layer.clear();
  for (const node of nodes) {
    const fullness = Math.max(0, Math.min(1, node.amount / 5000));
    const radius = 16 + fullness * 29;
    layer.fillStyle(0x74d7bd, 0.18 + fullness * 0.22).fillCircle(node.x, node.y, radius + 10);
    layer.fillStyle(node.amount > 0 ? 0x2e9b91 : 0x29403f, 1).fillCircle(node.x, node.y, radius);
    if (node.amount > 0) layer.lineStyle(2, 0x8ce6cc, 0.8).strokeCircle(node.x, node.y, radius);
  }
}
