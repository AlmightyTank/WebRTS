import test from 'node:test';
import assert from 'node:assert/strict';
import { RuntimeErrorLog } from './errorLog.js';

test('runtime errors are bounded and safely formatted', () => {
  const log = new RuntimeErrorLog(2);
  log.record(new Error('problem\nwith\tinput'), 'input');
  log.record('unhandled promise rejection', 'promise');
  log.record('a'.repeat(999), 'render');
  assert.equal(log.items.length, 2);
  assert.equal(log.items[0].category, 'promise');
  assert.equal(log.items[1].message.length, 180);
  assert.equal(log.record(new Error('unit error')).message, 'unit error');
});
