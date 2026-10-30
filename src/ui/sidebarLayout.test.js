import test from 'node:test';
import assert from 'node:assert/strict';
import { sidebarLayout } from './sidebarLayout.js';

for (const [width, height, touch] of [
  [1280, 800, false], [1920, 1080, false], [820, 1180, true],
  [390, 844, true], [844, 390, true]
]) {
  test('sidebar geometry for ' + width + 'x' + height + ' touch=' + touch, () => {
    const layout = sidebarLayout(width, height, touch);
    assert.equal(layout.left + layout.width, width);
    assert.ok(layout.width >= 140 && layout.width <= 208);
    assert.ok(layout.mapX >= layout.left && layout.mapX + layout.mapWidth <= width);
    assert.ok(layout.cardsTop > layout.buildingsY);
    assert.ok(layout.sections.infantry !== undefined);
  });
}
