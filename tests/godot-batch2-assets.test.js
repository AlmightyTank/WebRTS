import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync, existsSync } from 'node:fs';
const root = new URL('../godot/', import.meta.url);
function path(s) { return new URL(s, root); }
function checkPng(rel,w,h) {
  const a=readFileSync(path(rel));
  assert.equal(a.subarray(0,8).toString('hex'),'89504e470d0a1a0a');
  assert.equal(a.readUInt32BE(16),w);
  assert.equal(a.readUInt32BE(20),h);
  assert.equal(a.readUInt8(25),6, 'PNG must be RGBA');
}
test('three HQ resources referenced by committed scenes are present',()=>{
 for(const n of ['alliance_command_center','republic_high_command_citadel','gia_resistance_headquarters'])
  checkPng('assets/buildings/headquarters/'+n+'.png',384,384);
});
test('every faction imports three power sprite animations and nine production/economy strips',()=>{
 const factions=['alliance','republic','gia'];
 const blds={alliance:['ore_refinery','barracks','war_factory'],republic:['industrial_ore_works','garrison_barracks','armor_works'],gia:['scrapyard_refinery','militia_training_camp','salvage_garage']};
 for(const faction of factions){
  for(const state of ['idle','working','damaged'])checkPng('assets/buildings/power/'+faction+'/'+state+'.png',3072,384);
  checkPng('assets/buildings/power/'+faction+'/offline.png',384,384);
  for(const b of blds[faction]){
    checkPng('assets/buildings/core/'+faction+'/'+b+'_states.png',1152,384);
    assert.ok(existsSync(path('scenes/buildings/core/'+faction+'_'+b+'.tscn')));
  }
 }
});
