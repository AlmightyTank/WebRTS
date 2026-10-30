import Phaser from 'phaser';
import { getDragPanDelta } from '../mobileGestures.js';
import { getPinchUpdate, isPlacementTap } from '../mobilePlacement.js';

export function installBattlefieldInput(scene) {
    scene.game.canvas.addEventListener('contextmenu', (event) => event.preventDefault());
    scene.input.addPointer(1);
    scene.pinchDistance = null;
    scene.pinchCenter = null;
    scene.touchGestureOccurred = false;
    scene.input.keyboard?.addCapture([
    Phaser.Input.Keyboard.KeyCodes.F3,
    Phaser.Input.Keyboard.KeyCodes.F4,
    Phaser.Input.Keyboard.KeyCodes.F6,
    Phaser.Input.Keyboard.KeyCodes.F7
  ]);
  scene.cameraKeys = scene.input.keyboard?.createCursorKeys();
    scene.cameraKeys.w = scene.input.keyboard?.addKey(Phaser.Input.Keyboard.KeyCodes.W);
    scene.cameraKeys.a = scene.input.keyboard?.addKey(Phaser.Input.Keyboard.KeyCodes.A);
    scene.cameraKeys.s = scene.input.keyboard?.addKey(Phaser.Input.Keyboard.KeyCodes.S);
    scene.cameraKeys.d = scene.input.keyboard?.addKey(Phaser.Input.Keyboard.KeyCodes.D);
    scene.input.on('pointerdown', (pointer) => {
      if (scene.uiPointerGate.active) {
        scene.dragStart = null;
        scene.pointerMode = 'ui';
        return;
      }
      if (pointer.button === 2 && scene.placement.active) {
        scene.cancelPlacement();
        scene.uiPointerGate.block();
        scene.message = 'Building placement cancelled.';
        scene.pointerMode = 'ui';
        scene.dragStart = null;
        return;
      }
      const touches = scene.getTouchPointers();
      if (scene.isTouchPointer(pointer) && touches.length >= 2) {
        scene.pointerMode = 'touch';
        scene.touchGestureOccurred = true;
        scene.dragStart = null;
        const gesture = getPinchUpdate(null, touches[0], touches[1], scene.cameras.main.zoom, scene.minZoom);
        scene.pinchDistance = gesture.distance;
        scene.pinchCenter = gesture.center;
        return;
      }
      if (scene.isUiPointer(pointer)) {
        scene.dragStart = null;
        scene.pointerMode = 'ui';
        return;
      }
      const world = scene.toWorld(pointer);
      // Touch pan keeps the ghost at its screen anchor; only a deliberate tap
      // relocates it. Desktop mouse placement still follows the cursor.
      if (scene.placement.active && !scene.isTouchPointer(pointer)) {
        scene.previewScreenAnchor = { x: pointer.x, y: pointer.y };
      }
      scene.dragStart = { screenX: pointer.x, screenY: pointer.y, lastX: pointer.x, lastY: pointer.y,
      pointerId: pointer.id, panStarted: false, worldX: world.x, worldY: world.y };
      if (pointer.button === 1) {
        scene.pointerMode = 'pan';
        return;
      }
      scene.pointerMode = scene.isTouchPointer(pointer) ? 'touch' : 'mouse';
      scene.touchGestureOccurred = false;
    });

    scene.input.on('pointermove', (pointer) => {
      if (scene.pointerMode === 'ui' || scene.uiPointerGate.active) return;
      if (scene.placement.active && !scene.isUiPointer(pointer) && !scene.isTouchPointer(pointer)) {
        scene.previewScreenAnchor = { x: pointer.x, y: pointer.y };
      }
      const touches = scene.getTouchPointers();
      if (scene.pointerMode === 'touch' && touches.length >= 2) {
        const previous = scene.pinchCenter ? { center: scene.pinchCenter, distance: scene.pinchDistance } : null;
        const gesture = getPinchUpdate(previous, touches[0], touches[1],
          scene.cameras.main.zoom, scene.minZoom);
        // Both fingers moving together pans; their separation controls zoom.
        scene.cameras.main.scrollX -= gesture.panX / scene.cameras.main.zoom;
        scene.cameras.main.scrollY -= gesture.panY / scene.cameras.main.zoom;
        scene.zoomAt(gesture.center.x, gesture.center.y, gesture.zoom);
        scene.pinchDistance = gesture.distance;
        scene.pinchCenter = gesture.center;
        scene.touchGestureOccurred = true;
        return;
      }
      if (!pointer.isDown || !scene.dragStart || pointer.id !== scene.dragStart.pointerId) return;
      const point = { x: pointer.x, y: pointer.y };
      const start = { x: scene.dragStart.screenX, y: scene.dragStart.screenY };
      if (scene.pointerMode === 'pan' || scene.pointerMode === 'touch') {
        // Phaser may update prevPosition before scene callbacks on mobile.
        // Keep our own last position and retain the full initial drag delta.
        const delta = getDragPanDelta(start,
          { x: scene.dragStart.lastX, y: scene.dragStart.lastY },
          point, scene.dragStart.panStarted || scene.pointerMode === 'pan');
        if (delta) {
          scene.cameras.main.scrollX -= delta.x / scene.cameras.main.zoom;
          scene.cameras.main.scrollY -= delta.y / scene.cameras.main.zoom;
          scene.dragStart.panStarted = true;
          scene.dragStart.lastX = point.x;
          scene.dragStart.lastY = point.y;
          if (scene.pointerMode === 'touch') scene.touchGestureOccurred = true;
        }
        return;
      }
      if (scene.pointerMode === 'mouse' && Phaser.Math.Distance.Between(start.x, start.y, point.x, point.y) > 8) scene.drawSelectionBox(pointer);
    });

    scene.input.on('pointerup', (pointer) => {
      if (scene.uiPointerGate.release()) {
        scene.dragStart = null;
        scene.pointerMode = null;
        scene.selectionLayer.clear();
        return;
      }
      if (scene.isTouchPointer(pointer) && scene.touchGestureOccurred) {
        // Never convert a pan or a two-finger pinch into an accidental move/order.
        scene.dragStart = null;
        scene.selectionLayer.clear();
        // Keep pinch suppression until the last finger has lifted.
        scene.pinchDistance = null;
        scene.pinchCenter = null;
        if (scene.getTouchPointers().filter((active) => active.id !== pointer.id).length === 0) {
          scene.pointerMode = null;
          scene.touchGestureOccurred = false;
        }
        return;
      }
      if (scene.pointerMode === 'ui' || scene.isUiPointer(pointer)) {
        scene.dragStart = null;
        scene.pointerMode = null;
        scene.pinchDistance = null;
        scene.pinchCenter = null;
        scene.selectionLayer.clear();
        return;
      }
      if (!scene.dragStart) return;
      const start = scene.dragStart;
      const world = scene.toWorld(pointer);
      const distance = Phaser.Math.Distance.Between(start.screenX, start.screenY, pointer.x, pointer.y);
      scene.dragStart = null;
      scene.pinchDistance = null;
      scene.pinchCenter = null;
      scene.selectionLayer.clear();
      if (scene.pointerMode === 'pan') return;
      if (scene.placement.active && scene.isTouchPointer(pointer)) {
        if (isPlacementTap(
          { x: start.screenX, y: start.screenY },
          { x: pointer.x, y: pointer.y },
          { panned: start.panStarted, pinched: scene.touchGestureOccurred }
        )) scene.handleTap(world, pointer);
        return;
      }
      if (distance > 8 && scene.pointerMode === 'mouse') scene.selectBox(start.worldX, start.worldY, world.x, world.y);
      else if (distance <= 8) scene.handleTap(world, pointer);
    });

    scene.input.on('wheel', (_pointer, _over, _dx, dy) => {
      const pointer = scene.input.activePointer;
      const next = Phaser.Math.Clamp(scene.cameras.main.zoom - dy * 0.001, scene.minZoom, 1.5);
      scene.zoomAt(pointer.x, pointer.y, next);
    });

    scene.input.keyboard?.on('keydown-ESC', () => {
      if (scene.cancelPlacement()) scene.message = 'Building placement cancelled.';
      else scene.togglePause();
    });
    scene.input.keyboard?.on('keydown-SPACE', () => scene.centerOnSelection());
    scene.input.keyboard?.on('keydown-F6', (event) => { event?.preventDefault?.(); scene.saveSkirmish(); });
    scene.input.keyboard?.on('keydown-F7', (event) => { event?.preventDefault?.(); scene.loadSkirmish(); });
    scene.input.keyboard?.on('keydown-F3', (event) => {
      event?.preventDefault?.();
      scene.debugVisible = !scene.debugVisible;
      scene.debugText.setVisible(scene.debugVisible);
    });
    scene.input.keyboard?.on('keydown-F4', (event) => { event?.preventDefault?.(); scene.runDebugScenario(); });
    // F3 may be intercepted by the browser's Find Next; H/J are reliable
    // alternatives for gameplay diagnostics and dev stress scenarios.
    scene.input.keyboard?.on('keydown-H', () => {
      scene.debugVisible = !scene.debugVisible;
      scene.debugText.setVisible(scene.debugVisible);
    });
    scene.input.keyboard?.on('keydown-J', () => scene.runDebugScenario());
    // Browser-safe desktop save/open shortcuts; F6/F7 can be reserved by the
    // address bar or caret-navigation settings on some browsers.
    scene.input.keyboard?.on('keydown-S', event => {
      if (event.shiftKey) scene.saveSkirmish();
    });
    scene.input.keyboard?.on('keydown-O', event => {
      if (event.shiftKey) scene.loadSkirmish();
    });
    scene.input.keyboard?.on('keydown-B', () => scene.useCommandButton('build'));
    scene.input.keyboard?.on('keydown-P', () => scene.produceSelected());
    scene.input.keyboard?.on('keydown-Q', () => scene.setCategory('buildings'));
    scene.input.keyboard?.on('keydown-T', () => scene.setCategory('defensive'));
    scene.input.keyboard?.on('keydown-E', () => scene.setCategory('infantry'));
    scene.input.keyboard?.on('keydown-R', () => scene.setCategory('vehicles'));
    scene.input.keyboard?.on('keydown-Y', () => scene.setCategory('aircraft'));
    scene.input.keyboard?.on('keydown-U', () => scene.setCategory('navy'));
    scene.input.keyboard?.on('keydown-K', () => scene.useBuildingAction('repair'));
    scene.input.keyboard?.on('keydown-L', () => scene.useBuildingAction('sell'));
    scene.input.keyboard?.on('keydown-ONE', () => scene.choosePreferredBuilding('refinery'));
    scene.input.keyboard?.on('keydown-TWO', () => scene.choosePreferredBuilding('barracks'));
}
