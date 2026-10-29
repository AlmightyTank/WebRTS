// Pure mobile HUD geometry. Phaser uses center coordinates for card placement.
// Fit the drawer to its displayed content so it doesn't hide the whole battlefield.
export function getMobileHudLayout(width, height, itemCount = 5) {
  const compact = height < 540;
  const topBarHeight = 54;
  const bottomBarHeight = 100;
  const bottomTop = height - bottomBarHeight;
  const drawerWidth = Math.min(390, Math.max(220, width - 16));
  const drawerLeft = (width - drawerWidth) / 2;
  const drawerTop = topBarHeight + 4;
  const maxDrawerBottom = bottomTop - 6;
  const mapX = drawerLeft + 12;
  const mapY = drawerTop + 12;
  const mapWidth = Math.min(168, Math.floor(drawerWidth * 0.46));
  const mapHeight = compact ? 42 : 66;
  const utilityButtonHeight = compact ? 19 : 30;
  const utilityY = mapY + mapHeight / 2;
  const tabsY = mapY + mapHeight + (compact ? 18 : 22);
  const tabHeight = compact ? 28 : 34;
  const titleY = tabsY + (compact ? 29 : 33);
  const cardHeight = compact ? 44 : 54;
  const cardWidth = Math.floor((drawerWidth - 34) / 2);
  const cardRowHeight = cardHeight + (compact ? 8 : 10);
  // Heading is top-aligned while cards are center-aligned.
  const cardsTop = titleY + (compact ? 55 : 53);
  const edgePadding = 16;
  const pagerHeight = compact ? 30 : 34;
  const neededRows = Math.ceil(Math.max(0, itemCount) / 2);
  const capacityWithoutPager = Math.max(1,
    Math.floor((maxDrawerBottom - cardsTop - cardHeight / 2 - edgePadding) / cardRowHeight) + 1);
  const paged = neededRows > capacityWithoutPager;
  const rowsPerPage = paged
    ? Math.max(1, Math.floor((maxDrawerBottom - cardsTop - cardHeight / 2 - edgePadding - pagerHeight) / cardRowHeight) + 1)
    : capacityWithoutPager;
  const visibleRows = Math.max(1, Math.min(neededRows, rowsPerPage));
  const drawerBottom = Math.min(maxDrawerBottom, Math.max(drawerTop + 170,
    cardsTop + (visibleRows - 1) * cardRowHeight + cardHeight / 2 + edgePadding + (paged ? pagerHeight : 0)));
  return {
    width, height, topBarHeight, bottomBarHeight, bottomTop,
    drawerLeft, drawerTop, drawerWidth, drawerBottom, mapX, mapY, mapWidth,
    mapHeight, utilityY, utilityButtonHeight, tabsY, tabHeight, titleY,
    cardsTop, cardWidth, cardHeight, cardRowHeight, rowsPerPage,
    pagerHeight, paged, visibleRows
  };
}
