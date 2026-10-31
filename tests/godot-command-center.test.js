import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';

const read = (p) => readFileSync(new URL(p, import.meta.url), 'utf8');

test('Godot Command Center is a reusable transparent imported sprite', () => {
  const sprite = read('../godot/assets/buildings/command_center.svg');
  const scene = read('../godot/scenes/buildings/command_center.tscn');
  const script = read('../godot/scripts/buildings/command_center.gd');
  assert.match(sprite, /<svg[^>]+width="620"[^>]+height="510"/);
  assert.doesNotMatch(sprite, /<rect[^>]+(?:fill="#[a-f\d]{6}"|fill="white")/i);
  assert.match(scene, /command_center\.svg/);
  assert.match(scene, /offset = Vector2\(-310, -330\)/);
  assert.match(scene, /scale = Vector2\(0\.825, 0\.825\)/);
  assert.match(script, /FOOTPRINT := Vector2i\(3, 3\)/);
  assert.match(script, /tile_map\.map_to_local\(cell\)/);
  assert.match(script, /range\(-1, 2\)/);
});
test('Godot battlefield spawns centered headquarters without affecting camera controls', () => {
  const battlefield = read('../godot/scripts/battlefield.gd');
  assert.match(battlefield, /COMMAND_CENTER_SCENE\.instantiate\(\)/);
  assert.match(battlefield, /headquarters\.place_on_grid\(terrain, Vector2i\(WIDTH \/ 2, HEIGHT \/ 2\)\)/);
  assert.match(battlefield, /func set_zoom\(/);
  assert.match(battlefield, /func clamp_camera\(/);
});
