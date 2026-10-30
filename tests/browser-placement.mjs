import test, { before, after } from 'node:test';
import assert from 'node:assert/strict';
import { spawn } from 'node:child_process';
import { mkdir } from 'node:fs/promises';
import { chromium } from 'playwright';

const URL = 'http://127.0.0.1:4173/';
let server, browser;

before(async () => {
  await mkdir('test-results', { recursive: true });
  server = spawn(process.execPath, [
    'node_modules/vite/bin/vite.js', '--host', '127.0.0.1',
    '--port', '4173', '--strictPort', '--mode', 'e2e'
  ], { stdio: 'inherit' });
  let started = false;
  for (let i = 0; i < 100; i++) {
    if (server.exitCode !== null) throw Error('Vite exited early');
    try {
      if ((await fetch(URL)).ok) { started = true; break; }
    } catch {}
    await new Promise(r => setTimeout(r, 180));
  }
  assert.equal(started, true, 'Vite server should start');
  browser = await chromium.launch({
    headless: true,
    args: ['--no-sandbox', '--use-gl=angle', '--use-angle=swiftshader']
  });
});

after(async () => {
  await browser?.close();
  if (server?.pid) server.kill('SIGTERM');
});

async function launch(options) {
  const context = await browser.newContext({
    viewport: { width: 390, height: 844 },
    deviceScaleFactor: 1,
    ...options
  });
  const page = await context.newPage();
  const errors = [];
  page.on('pageerror', error => errors.push(String(error)));
  await page.goto(URL, { waitUntil: 'domcontentloaded' });
  await page.waitForFunction(() => {
    try {
      const s = window.__WEBRTS_E2E__?.();
      return s?.simulation && s?.buildCards?.length && s?.cameras?.main;
    } catch { return false; }
  }, null, { timeout: 30000 });
  await page.waitForTimeout(350);
  return { page, context, errors };
}

async function state(page) {
  return page.evaluate(() => {
    const s = window.__WEBRTS_E2E__();
    const c = s.cameras.main;
    return {
      active: s.placement.active, type: s.placement.selected,
      drawer: s.mobilePanelOpen,
      preview: s.buildPreviewLabel.visible,
      cancel: s.mobileMenuText.text,
      status: s.mobilePlacementStatus.visible,
      actions: s.commandButtons.map(b => b.background.visible),
      buildings: s.simulation.buildings.filter(b => b.playerId === 0)
        .map(b => ({ id: b.id, type: b.type, complete: b.complete })),
      metal: s.simulation.resources[0],
      camera: { x: c.scrollX, y: c.scrollY, zoom: c.zoom },
      message: s.message
    };
  });
}

async function target(page, name) {
  const a = await page.evaluate(name => {
    const s = window.__WEBRTS_E2E__();
    const item = name === 'menu' ? s.mobileMenuButton
      : s.buildCards.find(c => c.type === name)?.background;
    return item && { x: item.x, y: item.y, visible: item.visible };
  }, name);
  assert.ok(a?.visible, name + ' must be visible');
  return a;
}

async function spot(page, valid, type = 'refinery') {
  return page.evaluate(({ valid, type }) => {
    const s = window.__WEBRTS_E2E__();
    const { width, height } = s.uiSize();
    const mobile = width < 700 || s.isTouchDevice();
    const right = mobile ? width - 28 : s.sidebarLayout().left - 28;
    const bottom = mobile ? height - 115 : height - 175;
    for (let y = 98; y < bottom; y += 24) {
      for (let x = 32; x < right; x += 24) {
        const position = s.cameras.main.getWorldPoint(x, y);
        if (Boolean(s.simulation.validateCommand({
          type: 'build', playerId: 0, buildingType: type, position
        }).ok) === valid) return { x, y };
      }
    }
    return null;
  }, { valid, type });
}

async function gesture(page, frames) {
  const client = await page.context().newCDPSession(page);
  const points = frame => frame.map((p, i) => ({
    x: p.x, y: p.y, id: i + 1, radiusX: 3, radiusY: 3, force: 1
  }));
  try {
    await client.send('Input.dispatchTouchEvent', { type: 'touchStart', touchPoints: points(frames[0]) });
    for (const frame of frames.slice(1)) {
      await client.send('Input.dispatchTouchEvent', { type: 'touchMove', touchPoints: points(frame) });
      await page.waitForTimeout(55);
    }
    await client.send('Input.dispatchTouchEvent', { type: 'touchEnd', touchPoints: [] });
    await page.waitForTimeout(160);
  } finally { await client.detach(); }
}

test('desktop: blocked placement, Escape cancel, successful single charge', async () => {
  const { page, context, errors } = await launch({ viewport: { width: 1280, height: 800 } });
  try {
    const before = await state(page);
    const refinery = await target(page, 'refinery');
    await page.mouse.click(refinery.x, refinery.y);
    const selected = await state(page);
    assert.equal(selected.active, true);
    assert.equal(selected.preview, true);
    assert.equal(selected.type, 'refinery');
    const blocked = await spot(page, false);
    assert.ok(blocked, 'blocked desktop position exists');
    await page.mouse.click(blocked.x, blocked.y);
    assert.equal((await state(page)).active, true);
    const restoreInfo = await page.evaluate(() => ({
      metal: window.__WEBRTS_E2E__().simulation.resources[0],
      message: window.__WEBRTS_E2E__().message
    }));
    assert.equal(restoreInfo.metal, before.metal, restoreInfo.message);
    await page.keyboard.press('Escape');
    assert.equal((await state(page)).active, false);
    await page.mouse.click(refinery.x, refinery.y);
    const valid = await spot(page, true);
    assert.ok(valid, 'valid desktop position exists');
    await page.mouse.click(valid.x, valid.y);
    await page.waitForTimeout(240);
    const built = await state(page);
    assert.equal(built.active, false);
    assert.equal(built.buildings.length, before.buildings.length + 1);
    assert.equal(built.metal, before.metal - 300);
    await page.screenshot({ path: 'test-results/desktop-placement.png' });
    assert.deepEqual(errors, []);
  } finally { await context.close(); }
});

test('mobile: open build, pan, pinch, invalid placement, cancel safely', async () => {
  const { page, context, errors } = await launch({
    viewport: { width: 390, height: 844 }, isMobile: true, hasTouch: true
  });
  try {
    const before = await state(page);
    const menu = await target(page, 'menu');
    await page.touchscreen.tap(menu.x, menu.y);
    assert.equal((await state(page)).drawer, true);
    const refinery = await target(page, 'refinery');
    await page.touchscreen.tap(refinery.x, refinery.y);
    const selection = await state(page);
    assert.equal(selection.active, true);
    assert.equal(selection.drawer, false);
    assert.equal(selection.cancel, 'CANCEL ×');
    assert.equal(selection.status, true);
    assert.ok(selection.actions.every(v => !v));
    await gesture(page, [
      [{ x: 195, y: 320 }],
      [{ x: 205, y: 335 }],
      [{ x: 235, y: 355 }],
      [{ x: 265, y: 375 }]
    ]);
    const moved = await state(page);
    assert.ok(Math.abs(moved.camera.x - selection.camera.x) > 5 ||
      Math.abs(moved.camera.y - selection.camera.y) > 5, 'one finger pans');
    assert.equal(moved.buildings.length, before.buildings.length);
    assert.equal(moved.active, true);
    await gesture(page, [
      [{x: 125, y: 300}, {x: 230, y: 300}],
      [{x: 100, y: 310}, {x: 255, y: 310}],
      [{x: 90, y: 325}, {x: 265, y: 325}]
    ]);
    const zoomed = await state(page);
    assert.ok(Math.abs(zoomed.camera.zoom - moved.camera.zoom) > 0.01, 'pinch zooms');
    assert.equal(zoomed.buildings.length, before.buildings.length);
    const blocked = await spot(page, false);
    assert.ok(blocked);
    await page.touchscreen.tap(blocked.x, blocked.y);
    assert.equal((await state(page)).active, true);
    await page.touchscreen.tap(menu.x, menu.y);
    const canceled = await state(page);
    assert.equal(canceled.active, false);
    assert.ok(canceled.actions.every(Boolean));
    assert.equal(canceled.metal, before.metal);
    await page.screenshot({ path: 'test-results/mobile-placement-cancel.png' });
    assert.deepEqual(errors, []);
  } finally { await context.close(); }
});

test('mobile: a deliberate tap constructs and charges exactly once', async () => {
  const { page, context, errors } = await launch({
    viewport: { width: 360, height: 640 }, isMobile: true, hasTouch: true
  });
  try {
    const before = await state(page);
    const menu = await target(page, 'menu');
    await page.touchscreen.tap(menu.x, menu.y);
    const barracks = await target(page, 'barracks');
    await page.touchscreen.tap(barracks.x, barracks.y);
    assert.equal((await state(page)).type, 'barracks');
    const valid = await spot(page, true, 'barracks');
    assert.ok(valid, 'valid mobile position exists');
    await page.touchscreen.tap(valid.x, valid.y);
    await page.waitForTimeout(240);
    const built = await state(page);
    assert.equal(built.active, false);
    assert.equal(built.buildings.length, before.buildings.length + 1);
    assert.equal(built.metal, before.metal - 250);
    assert.ok(built.actions.every(Boolean));
    await page.screenshot({ path: 'test-results/mobile-placement-built.png' });
    assert.deepEqual(errors, []);
  } finally { await context.close(); }
});

// v0.2 release device matrix: desktop input, portrait/landscape touch and tablet.
test('desktop: complete match save/load, deterministic hash and F3 diagnostics', async () => {
  const { page, context, errors } = await launch({ viewport: { width: 1280, height: 800 } });
  try {
    const before = await state(page);
    await page.keyboard.press('F6');
    const saved = await page.evaluate(() => window.localStorage.getItem('webrts.skirmish.v1'));
    assert.ok(saved?.includes('webrts-game'));
    await page.evaluate(() => { window.__WEBRTS_E2E__().simulation.resources[0] = 23; });
    await page.keyboard.press('F7');
    assert.equal((await state(page)).metal, before.metal);
    await page.keyboard.press('F3');
    await page.waitForTimeout(700);
    const overlay = await page.evaluate(() => {
      const s = window.__WEBRTS_E2E__();
      return { visible: s.debugText.visible, text: s.debugText.text, tick: s.simulation.tick };
    });
    assert.equal(overlay.visible, true);
    assert.match(overlay.text, /FPS/);
    assert.match(overlay.text, /HASH/);
    const count = (await state(page)).buildings.length;
    await page.keyboard.press('F4');
    const units = await page.evaluate(() => window.__WEBRTS_E2E__().units.length);
    assert.ok(units >= 60);
    assert.equal((await state(page)).buildings.length, count);
    await page.screenshot({ path: 'test-results/v02-desktop-diagnostics.png' });
    assert.deepEqual(errors, []);
  } finally { await context.close(); }
});

for (const [name, viewport] of [
  ['portrait-small', { width: 320, height: 568 }],
  ['landscape-phone', { width: 844, height: 390 }],
  ['tablet', { width: 820, height: 1180 }]
]) {
  test('v0.2 mobile ' + name + ': pause/save/load and responsive HUD', async () => {
    const { page, context, errors } = await launch({
      viewport, isMobile: true, hasTouch: true
    });
    try {
      const before = await state(page);
      const positions = await page.evaluate(() => {
        const s = window.__WEBRTS_E2E__();
        return {
          pause: { x: s.mobilePauseButton.x, y: s.mobilePauseButton.y, visible: s.mobilePauseButton.visible },
          menu: { x: s.mobileMenuButton.x, y: s.mobileMenuButton.y, visible: s.mobileMenuButton.visible }
        };
      });
      assert.equal(positions.pause.visible, true, 'Pause available on touch device');
      assert.ok(positions.pause.x > 0 && positions.pause.x < viewport.width);
      assert.ok(positions.menu.x > positions.pause.x);
      await page.touchscreen.tap(positions.pause.x, positions.pause.y);
      const paused = await page.evaluate(() => {
        const s = window.__WEBRTS_E2E__();
        return {
          paused: s.isPaused, save: { x: s.pauseSave.x, y: s.pauseSave.y, visible: s.pauseSave.visible },
          load: { x: s.pauseLoad.x, y: s.pauseLoad.y, visible: s.pauseLoad.visible }
        };
      });
      assert.equal(paused.paused, true);
      assert.equal(paused.save.visible, true);
      assert.equal(paused.load.visible, true);
      for (const p of [paused.save, paused.load]) {
        assert.ok(p.x > 0 && p.x < viewport.width && p.y > 0 && p.y < viewport.height,
          'pause actions stay within touch viewport');
      }
      await page.touchscreen.tap(paused.save.x, paused.save.y);
      const saved = await page.evaluate(() => window.localStorage.getItem('webrts.skirmish.v1'));
      assert.ok(saved && saved.includes('webrts-game'));
      await page.evaluate(() => { window.__WEBRTS_E2E__().simulation.resources[0] = 50; });
      await page.touchscreen.tap(paused.load.x, paused.load.y);
      const restored = await state(page);
      assert.equal(restored.metal, before.metal);
      assert.equal(restored.active, false);
      assert.ok(restored.actions.every(Boolean));
      await page.screenshot({ path: 'test-results/v02-' + name + '.png' });
      assert.deepEqual(errors, []);
    } finally { await context.close(); }
  });
}
