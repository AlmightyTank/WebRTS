// Normalize Phaser's native, wrapped and synthesized touch inputs.
export function isTouchGesturePointer(pointer, coarsePointer = false) {
  if (!pointer) return false;
  const event = pointer.event;
  if (event?.pointerType === 'touch' || pointer.pointerType === 'touch' || pointer.wasTouch) return true;
  if (event?.touches || event?.changedTouches || event?.type?.startsWith('touch')) return true;
  return Boolean(coarsePointer);
}

// The first pan move includes the threshold distance; later moves use our
// stored screen sample instead of the engine's prevPosition.
export function getDragPanDelta(start, last, current, alreadyPanning = false, threshold = 8) {
  if (!alreadyPanning && Math.hypot(current.x - start.x, current.y - start.y) <= threshold) return null;
  const origin = alreadyPanning ? last : start;
  return { x: current.x - origin.x, y: current.y - origin.y };
}
