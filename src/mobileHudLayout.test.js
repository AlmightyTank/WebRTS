import test from 'node:test';
import assert from 'node:assert/strict';
import { getMobileHudLayout } from './mobileHudLayout.js';

for (const [width, height] of [[360, 640], [320, 568], [390, 844], [414, 760], [700, 393], [320, 480]]) {
  for (const itemCount of [0, 1, 3, 5, 12]) {
    test(`mobile HUD fits ${width}x${height} with ${itemCount} cards`, () => {
      const hud = getMobileHudLayout(width, height, itemCount);
      assert.ok(hud.drawerLeft >= 0);
      assert.ok(hud.drawerLeft + hud.drawerWidth <= width);
      assert.ok(hud.drawerTop >= hud.topBarHeight);
      assert.ok(hud.drawerBottom <= hud.bottomTop);
      assert.ok(hud.mapX + hud.mapWidth < hud.drawerLeft + hud.drawerWidth);
      assert.ok(hud.cardWidth * 2 + 34 <= hud.drawerWidth);
      assert.ok(hud.rowsPerPage >= 1);
      assert.ok(hud.tabsY - hud.tabHeight / 2 > hud.mapY + hud.mapHeight, 'tabs must clear minimap');
      assert.ok(hud.titleY > hud.tabsY + hud.tabHeight / 2, 'heading must clear tabs');
      assert.ok(hud.titleY + 26 <= hud.cardsTop - hud.cardHeight / 2, 'heading must clear first card');
      const lastCardBottom = hud.cardsTop + (hud.visibleRows - 1) * hud.cardRowHeight + hud.cardHeight / 2;
      assert.ok(lastCardBottom <= hud.drawerBottom - 10, 'final card must fit drawer');
      if (hud.paged) assert.ok(lastCardBottom < hud.drawerBottom - hud.pagerHeight, 'pager must clear cards');
      const commandWidth = Math.floor((width - 20 - 4 * 5) / 5);
      assert.ok(commandWidth >= 45);
      assert.ok(10 + 5 * commandWidth + 4 * 5 <= width);
    });
  }
}

test('mobile drawer fits build cards without covering the rest of the map', () => {
  const hud = getMobileHudLayout(360, 640, 5);
  const finalCardBottom = hud.cardsTop + 2 * hud.cardRowHeight + hud.cardHeight / 2;
  assert.ok(hud.drawerBottom - finalCardBottom <= 24);
  assert.ok(hud.bottomTop - hud.drawerBottom >= 80);
});

test('shorter category lists produce shorter drawers', () => {
  assert.ok(getMobileHudLayout(390, 844, 1).drawerBottom < getMobileHudLayout(390, 844, 5).drawerBottom);
});
