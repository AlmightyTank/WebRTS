// Pure screen-space geometry used by the mobile Phaser HUD.
export function getMobileHudLayout(width, height) {
  const topBarHeight = 54;
  const bottomBarHeight = 100;
  const bottomTop = height - bottomBarHeight;
  const drawerWidth = Math.min(390, Math.max(220, width - 16));
  const drawerLeft = (width - drawerWidth) / 2;
  const drawerTop = topBarHeight + 4;
  const drawerBottom = bottomTop - 4;
  const compact = height < 540;
  const mapX = drawerLeft + 12;
  const mapY = drawerTop + 12;
  const mapWidth = Math.min(168, Math.floor(drawerWidth * 0.48));
  const mapHeight = compact ? 43 : 68;
  const utilityY = mapY + mapHeight / 2;
  const tabsY = mapY + mapHeight + 20;
  const titleY = tabsY + 30;
  const cardsTop = titleY + (compact ? 30 : 38);
  const cardWidth = Math.floor((drawerWidth - 34) / 2);
  const cardHeight = compact ? 46 : 54;
  const cardRowHeight = cardHeight + 8;
  const rowsPerPage = Math.max(1, Math.floor((drawerBottom - cardsTop - 40) / cardRowHeight));
  return { width, height, topBarHeight, bottomBarHeight, bottomTop,
    drawerLeft, drawerTop, drawerWidth, drawerBottom, mapX, mapY, mapWidth,
    mapHeight, utilityY, tabsY, titleY, cardsTop, cardWidth, cardHeight,
    cardRowHeight, rowsPerPage };
}
