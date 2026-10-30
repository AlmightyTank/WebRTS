// Desktop sidebar geometry is independent of the scene.
export function sidebarLayout(width, height, mobile = false) {
    const sidebarWidth = mobile ? 142 : 208;
    const top = 0;
    const mapWidth = sidebarWidth - 24;
    const mapHeight = mobile ? 54 : 88;
    const mapX = width - sidebarWidth + 12;
    const creditY = top + 11;
    const mapY = top + 28;
    const utilityTop = mapY + mapHeight + 20;
    const categoryTabsTop = utilityTop + 36;
    const buildingsY = categoryTabsTop + 52;
    const tabsY = buildingsY;
    const cardsTop = buildingsY + 48;
    const cardHeight = mobile ? 38 : 48;
    const sectionsStart = cardsTop + 3 * (cardHeight + 5) + 10;
    const powerY = height - (mobile ? 34 : 40);
    const sectionNames = ['defensive', 'infantry', 'vehicles', 'aircraft', 'navy'];
    const step = Math.max(27, Math.floor((powerY - 18 - sectionsStart) / sectionNames.length));
    const sections = Object.fromEntries(sectionNames.map((name, index) => [name, sectionsStart + index * step]));
    return { left: width - sidebarWidth, top, width: sidebarWidth, height: Math.max(150, height - top), mapX, mapY, mapWidth, mapHeight, creditY, tabsY, utilityTop, categoryTabsTop, buildingsY, cardsTop, cardHeight, sections, unitCardsTop: buildingsY + 50, vehicleCardsTop: buildingsY + 50, unitCardHeight: mobile ? 36 : 42, powerY, tabHeight: 22 };
}
