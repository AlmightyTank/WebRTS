export function worldPoint(camera, pointer) {
  return camera.getWorldPoint(pointer.x, pointer.y);
}

export function zoomAtPoint(camera, screenX, screenY, zoom) {
  const before = camera.getWorldPoint(screenX, screenY);
  camera.setZoom(zoom);
  const after = camera.getWorldPoint(screenX, screenY);
  camera.scrollX += before.x - after.x;
  camera.scrollY += before.y - after.y;
}

export function getTouchPointers(input, isTouch) {
  return (input.manager?.pointers ?? [input.pointer1, input.pointer2])
    .filter(pointer => pointer?.isDown && isTouch(pointer));
}
