import test from 'node:test';
import assert from 'node:assert/strict';
import { getMobileHudLayout } from './mobileHudLayout.js';

for (const [width, height] of [[360, 640], [320, 568], [390, 844], [414, 760], [700, 393]]) {
  test(`mobile HUD fits viewport ${width}x${height}`, () => {
    const hud = getMobileHudLayout(width, height);
    assert.ok(hud.drawerLeft >= 0);
    assert.ok(hud.drawerLeft + hud.drawerWidth <= width);
    assert.ok(hud.drawerTop >= hud.topBarHeight);
    assert.ok(hud.drawerBottom <= hud.bottomTop);
    assert.ok(hud.mapX + hud.mapWidth < hud.drawerLeft + hud.drawerWidth);
    assert.ok(hud.cardWidth * 2 + 34 <= hud.drawerWidth);
    assert.ok(hud.rowsPerPage >= 1);
    const lastCardY = hud.cardsTop + (hud.rowsPerPage - 1) * hud.cardRowHeight + hud.cardHeight / 2;
    assert.ok(lastCardY <= hud.drawerBottom - 25, `card overlaps pager: ${lastCardY} > ${hud.drawerBottom - 25}`);
    const commandWidth = Math.floor((width - 20 - 4 * 5) / 5);
    assert.ok(commandWidth >= 45);
    assert.ok(10 + 5 * commandWidth + 4 * 5 <= width);
  });
}
