// Phaser 4 requires a denser backing canvas, an inverse CSS zoom,
// and coordinated camera / pointer transforms (scale.resolution is ignored).
export function renderDensity(width, height, devicePixelRatio = 1, maxPixels = 2600000) {
  if (!(width > 0) || !(height > 0)) return 1;
  // More than 2x noticeably helps small HUD glyphs and thin vector edges.
  // Bound fill-rate on large displays and stay strictly inside the pixel budget.
  const ratio = Number.isFinite(devicePixelRatio) ? Math.max(1, Math.min(2.5, devicePixelRatio)) : 1;
  return Math.max(1, Math.floor(Math.min(ratio, Math.sqrt(maxPixels / (width * height))) * 100) / 100);
}

export function gamePixels(value, ratio) { return Math.round(value * ratio); }

export function logicalPointer(pointer, ratio = 1) {
  return {
    x: pointer.x / ratio, y: pointer.y / ratio,
    id: pointer.id, isDown: pointer.isDown, button: pointer.button,
    pointerType: pointer.pointerType, event: pointer.event,
    wasTouch: pointer.wasTouch
  };
}

export function textFontSize(size, ratio) {
  const n = Number.parseFloat(String(size));
  return Number.isFinite(n) ? Number((n * ratio).toFixed(2)) + 'px' : size;
}

// Create high-resolution Text textures, then preserve the same logical size.
// Camera zoom supplies the physical pixel scaling for the entire HUD.
export function installHighDpiText(scene, ratio) {
  if (ratio <= 1) return;
  const create = scene.add.text.bind(scene.add);
  scene.add.text = (x, y, value, style = {}) => {
    const options = { ...style };
    if (options.fontSize !== undefined) options.fontSize = textFontSize(options.fontSize, ratio);
    if (options.padding && typeof options.padding === 'object') {
      options.padding = Object.fromEntries(Object.entries(options.padding).map(([key, n]) =>
        [key, typeof n === 'number' ? n * ratio : n]));
    }
    const text = create(x, y, value, options);
    text.setScale(1 / ratio);
    const setFontSize = text.setFontSize.bind(text);
    text.setFontSize = size => setFontSize(textFontSize(size, ratio));
    return text;
  };
}
