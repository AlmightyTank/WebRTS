import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
const read = (path) => readFileSync(new URL('../' + path, import.meta.url));

test('three distinct Godot headquarters sprites are 384x384 transparent PNGs', () => {
  for (const type of ['alliance_command_center','republic_high_command_citadel','gia_resistance_headquarters']) {
    const raw = read('godot/assets/buildings/headquarters/' + type + '.png');
    assert.equal(raw.subarray(0,8).toString('hex'), '89504e470d0a1a0a');
    assert.equal(raw.readUInt32BE(16),384);
    assert.equal(raw.readUInt32BE(20),384);
    assert.ok([3,6].includes(raw.readUInt8(25)), 'indexed PNG or RGBA PNG with transparency');
    const scene = read('godot/scenes/buildings/headquarters/' + type + '.tscn').toString();
    assert.match(scene, new RegExp('assets/buildings/headquarters/' + type + '\\.png'));
    assert.match(scene, /Vector2\(-192, -284\)/);
  }
});
test('headquarters script and scenes agree on a 3x3 footprint', () => {
 const script=read('godot/scripts/buildings/headquarters/headquarters.gd').toString();
 assert.match(script,/footprint_tiles: Vector2i = Vector2i\(3, 3\)/);
 assert.match(script,/func occupied_cells\(/);
 for (const f of ['alliance_command_center','republic_high_command_citadel','gia_resistance_headquarters']) {
  const scene=read('godot/scenes/buildings/headquarters/'+f+'.tscn').toString();
  assert.match(scene,/footprint_tiles = Vector2i\(3, 3\)/);
 }
});
