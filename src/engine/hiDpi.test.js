import test from 'node:test';
import assert from 'node:assert/strict';
import { renderDensity, gamePixels, logicalPointer, textFontSize, installHighDpiText } from './hiDpi.js';

test('native DPR is preserved on mobile instead of softened by fractional upscaling', () => {
  assert.equal(renderDensity(390, 844, 3), 3);
  assert.equal(renderDensity(390, 844, 3.5), 3.5);
  assert.equal(renderDensity(412, 915, 3.5), 3.5);
  assert.equal(renderDensity(390, 844, 2), 2);
  assert.equal(renderDensity(360, 640, 3), 3);
  assert.equal(renderDensity(390, 844, 1), 1);
  assert.equal(gamePixels(390, renderDensity(390, 844, 3)), 1170);
  assert.equal(gamePixels(844, renderDensity(390, 844, 3)), 2532);
});

test('pixel budget caps larger screens and balanced quality preserves a lower fill rate', () => {
  const density = renderDensity(1000, 1000, 3);
  assert.ok(1000 * 1000 * density ** 2 <= 5500000, 'density respects default GPU pixel cap');
  const balanced = renderDensity(390, 844, 3, 2600000);
  assert.ok(balanced < 3, 'balanced quality reduces density when needed');
  assert.ok(390 * 844 * balanced ** 2 <= 2600000, 'balanced quality respects budget');
  assert.ok(renderDensity(1920, 1080, 3, 3000000) < 1.3, 'desktop stays within lower budget');
  assert.equal(renderDensity(0, 844, 3), 1);
});
test('pointer coordinates normalize without changing touch identity', () => {
  const p = logicalPointer({ x: 230, y: 640, id: 4, isDown: true,
    pointerType: 'touch', wasTouch: true }, 2);
  assert.equal(p.x, 115); assert.equal(p.y, 320);
  assert.equal(p.id, 4); assert.equal(p.wasTouch, true);
});
test('text has a denser texture with its logical size preserved', () => {
  assert.equal(textFontSize('12px', 2), '24px');
  const mock = { add: { text(x, y, value, options) {
    return { options, setScale(n) { this.scale = n; return this; },
      setFontSize(n) { this.options.fontSize = n; return this; } };
  } } };
  installHighDpiText(mock, 2);
  const text = mock.add.text(0, 0, 'BUILD', { fontSize: '11px' });
  assert.equal(text.options.fontSize, '22px');
  assert.equal(text.scale, 0.5);
  text.setFontSize(13);
  assert.equal(text.options.fontSize, '26px');
});
