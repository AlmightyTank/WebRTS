// Screen-space layout and gesture decisions for mobile construction.
// Kept independent of Phaser so tap/pan/pinch regressions are testable.
export function getPlacementHudGeometry(width, height) {
  const bottomTop = height - 100;
  return {
    cancel: { x: width - 60, y: 27, width: 100, height: 40 },
    title: { x: 12, y: bottomTop + 9 },
    status: { x: 12, y: bottomTop + 34 },
    hint: { x: width / 2, y: bottomTop + 72 },
    bottomTop
  };
}

export function isPlacementTap(start, end, { panned = false, pinched = false, threshold = 8 } = {}) {
  if (!start || !end || panned || pinched) return false;
  return Math.hypot(end.x - start.x, end.y - start.y) <= threshold;
}

// Pan by midpoint translation and zoom around that same midpoint, allowing
// two-finger drag and pinch concurrently without launching build orders.
export function getPinchUpdate(previous, first, second, zoom, minZoom, maxZoom = 1.5) {
  const center = { x: (first.x + second.x) / 2, y: (first.y + second.y) / 2 };
  const distance = Math.hypot(first.x - second.x, first.y - second.y);
  const ratio = previous?.distance > 0 ? distance / previous.distance : 1;
  return {
    center,
    distance,
    panX: previous ? center.x - previous.center.x : 0,
    panY: previous ? center.y - previous.center.y : 0,
    zoom: Math.max(minZoom, Math.min(maxZoom, zoom * ratio))
  };
}
