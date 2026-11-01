"""Static registry contract checks (run independently of Godot)."""
import json
from pathlib import Path

base = Path(__file__).resolve().parents[1]
data = json.loads((base / 'data/unit_balance_v0.4.json').read_text())
assert len(data['standard_units']) == 46
assert len(data['specialist_units']) == 31
assert len(data['generals']) == 9
units = {u['id']: u for u in data['standard_units']}
for name in ['a_ranger', 'a_javelin', 'a_sentinel', 'a_sentinel_aa', 'a_striker', 'r_line', 'r_hunter', 'r_bastion', 'r_flak', 'r_siege_heli']:
    assert name in units, name
    assert units[name]['hp'] > 0 and units[name]['speed'] > 0
assert data['weapon_armor_multipliers']['SMALL_ARMS']['HEAVY'] == 0.08
assert data['weapon_armor_multipliers']['AA']['AIR'] == 1.4
print('DATA_CONTRACT_PASS 46 standard, 31 specialist, 9 generals, 10 combat profiles')
