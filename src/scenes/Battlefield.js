import Phaser from 'phaser';
import { drawTerrain, drawResources } from '../rendering/terrain.js';
import { worldPoint, zoomAtPoint, getTouchPointers as activeTouchPointers } from '../engine/cameraInput.js';
import { installHighDpiText, logicalPointer } from '../engine/hiDpi.js';
import { sidebarLayout } from '../ui/sidebarLayout.js';
import { installBattlefieldInput } from '../input/battlefieldInput.js';
import { PerformanceMonitor, debugScenario } from '../debug/performance.js';
import { RuntimeErrorLog } from '../debug/errorLog.js';
import { AUTOSAVE_KEY, SKIRMISH_SAVE_KEY, saveGameToStorage, readGameFromStorage } from '../engine/gameStorage.js';
import { Simulation } from '../simulation/Simulation.js';
import { attackCommand, buildCommand, defendCommand, moveCommand, produceCommand, repairCommand, sellCommand, stopCommand } from '../simulation/commands.js';
import { BUILDING_TYPES } from '../simulation/content.js';
import { getMobileHudLayout } from '../mobileHudLayout.js';
import { PlacementState, UiPointerGate } from '../placementState.js';
import { describePlacement, defaultPreviewAnchor } from '../placementPreview.js';
import { getPlacementHudGeometry } from '../mobilePlacement.js';
import { isTouchGesturePointer } from '../mobileGestures.js';

const WORLD = { width: 2400, height: 1500 };
const TEAM = { PLAYER: 0x54b7ff, ENEMY: 0xff6575 };

export class Battlefield extends Phaser.Scene {
  constructor() {
    super('battlefield');
  }

  get buildType() { return this.placement.type; }

  init() {
    this.simulation = new Simulation({ seed: 1337 });
    this.units = this.simulation.units;
    this.performanceMonitor = new PerformanceMonitor();
    this.runtimeErrors = new RuntimeErrorLog();
    this.debugVisible = false;
    this.debugRefreshMs = 0;
    this.nextAutosaveTime = 60;
    this.selected = new Set();
    this.selectedBuildings = new Set();
    this.dragStart = null;
    this.pointerMode = null;
    this.cameraKeys = null;
    this.nextUnitId = 1;
    this.message = 'Select a unit, then tap or right-click to move.';
    this.commandMode = null;
    this.utilityMode = null;
    this.isPaused = false;
    this.placement = new PlacementState(BUILDING_TYPES);
    this.buildPreviewPosition = null;
    this.previewScreenAnchor = null;
    this.mobilePanelOpen = false;
    this.mobileCardPage = 0;
    this.uiPointerGate = new UiPointerGate();
    this.pinchCenter = null;
  }

  create() {
    this.renderDensity = this.game.scale.zoom ? 1 / this.game.scale.zoom : 1;
    installHighDpiText(this, this.renderDensity);
    this.cameras.main.setBounds(0, 0, WORLD.width, WORLD.height);
    this.updateZoomLimits();
    this.cameras.main.setZoom(Math.max((this.isTouchDevice() ? 0.8 : 1) * this.renderDensity, this.minZoom));

    this.worldLayer = this.add.graphics();
    this.resourceLayer = this.add.graphics();
    // Selection is world geometry, so it must use the same camera transform as units.
    this.selectionLayer = this.add.graphics();
    this.unitLayer = this.add.graphics();
    this.projectileLayer = this.add.graphics();
    this.buildPreview = this.add.graphics().setDepth(9);
    this.buildPreviewLabel = this.add.text(0, 0, '', {
      fontFamily: 'monospace', fontSize: '12px', fontStyle: 'bold',
      color: '#a7f5c7', backgroundColor: '#07101ade',
      padding: { x: 7, y: 4 }
    }).setOrigin(0.5, 1).setDepth(10).setVisible(false);
    this.ui = this.add.graphics().setScrollFactor(0);
    this.helpText = this.add.text(18, 16, '', {
      color: '#e8f2ff', fontFamily: 'system-ui, sans-serif', fontSize: '15px',
      backgroundColor: '#101a2bcc', padding: { x: 12, y: 9 }
    }).setScrollFactor(0).setDepth(10);
    this.statusText = this.add.text(18, 70, '', {
      color: '#c8d6e5', fontFamily: 'system-ui, sans-serif', fontSize: '14px',
      backgroundColor: '#101a2bcc', padding: { x: 12, y: 8 }
    }).setScrollFactor(0).setDepth(10);

    this.createHud();
    this.setupUiCamera();

    this.createUnits();
    if (this.uiSize().width < 700 || this.isTouchDevice()) {
      // Begin on the player's base, not the empty corner of the map.
      this.cameras.main.centerOn(520, 720);
    }
    this.drawWorld();
    this.installInput();
    this.installErrorDiagnostics();
    this.scale.on('resize', () => {
      this.updateZoomLimits();
      const { width, height } = this.uiSize();
      this.uiCamera?.setViewport(0, 0, width * this.renderDensity, height * this.renderDensity)
        .setSize(width * this.renderDensity, height * this.renderDensity);
      if (this.placement.active) this.previewScreenAnchor = this.defaultPlacementScreenAnchor();
      this.layoutUi();
    });
    this.layoutUi();
  }

  createHud() {
    this.hud = this.add.graphics().setScrollFactor(0).setDepth(20);
    this.buildPanel = this.add.graphics().setScrollFactor(0).setDepth(20);
    this.hudText = {
      title: this.add.text(0, 0, 'FRONTIER COMMAND', { fontFamily: 'monospace', fontSize: '17px', fontStyle: 'bold', color: '#f2d27b' }).setScrollFactor(0).setDepth(21),
      resources: this.add.text(0, 0, '', { fontFamily: 'monospace', fontSize: '16px', color: '#e9f0dd' }).setScrollFactor(0).setDepth(21),
      intel: this.add.text(0, 0, 'TACTICAL LINK // ONLINE', { fontFamily: 'monospace', fontSize: '12px', color: '#8ca58b' }).setScrollFactor(0).setDepth(21),
      selection: this.add.text(0, 0, '', { fontFamily: 'monospace', fontSize: '15px', color: '#f2d27b' }).setScrollFactor(0).setDepth(21),
      hint: this.add.text(0, 0, '', { fontFamily: 'system-ui, sans-serif', fontSize: '12px', color: '#9da9b0' }).setScrollFactor(0).setDepth(21),
      sidebarCredit: this.add.text(0, 0, '', { fontFamily: 'monospace', fontSize: '12px', fontStyle: 'bold', color: '#f2d27b' }).setScrollFactor(0).setDepth(22),
      sidebarPower: this.add.text(0, 0, 'POWER  100%', { fontFamily: 'monospace', fontSize: '10px', color: '#d9e0c4' }).setScrollFactor(0).setDepth(22)
    };
    this.mobileMenuButton = this.add.rectangle(0, 0, 100, 38, 0x354744, 1)
      .setStrokeStyle(2, 0xf2d27b).setScrollFactor(0).setDepth(23)
      .setInteractive({ useHandCursor: true }).setVisible(false);
    this.mobileMenuText = this.add.text(0, 0, 'BUILD', { fontFamily: 'monospace', fontSize: '12px', fontStyle: 'bold', color: '#f2d27b' })
      .setOrigin(0.5).setScrollFactor(0).setDepth(24).setVisible(false);
    this.mobileMenuButton.on('pointerdown', () => this.toggleMobilePanel());
    this.mobilePlacementStatus = this.add.text(0, 0, '', {
      fontFamily: 'monospace', fontSize: '11px', fontStyle: 'bold', color: '#a7f5c7'
    }).setScrollFactor(0).setDepth(23).setVisible(false);
    this.mobilePlacementHint = this.add.text(0, 0, 'TAP TO PLACE  •  DRAG TO PAN  •  PINCH TO ZOOM', {
      fontFamily: 'monospace', fontSize: '10px', color: '#d9e0c4'
    }).setOrigin(0.5).setScrollFactor(0).setDepth(23).setVisible(false);
    this.mobilePagerButtons = ['prev', 'next'].map((action) => {
      const background = this.add.rectangle(0, 0, 72, 32, 0x26343b, 1).setStrokeStyle(1, 0x8ca58b)
        .setScrollFactor(0).setDepth(23).setInteractive({ useHandCursor: true }).setVisible(false);
      const text = this.add.text(0, 0, action === 'prev' ? 'PREV' : 'NEXT', { fontFamily: 'monospace', fontSize: '11px', color: '#e9f0dd' })
        .setOrigin(0.5).setScrollFactor(0).setDepth(24).setVisible(false);
      background.on('pointerdown', () => this.changeMobilePage(action === 'prev' ? -1 : 1));
      return { background, text, action };
    });
    this.mobilePageText = this.add.text(0, 0, '', { fontFamily: 'monospace', fontSize: '11px', color: '#f2d27b' })
      .setOrigin(0.5).setScrollFactor(0).setDepth(24).setVisible(false);
    this.buildTitle = this.add.text(0, 0, '▣ BUILDINGS', { fontFamily: 'monospace', fontSize: '13px', fontStyle: 'bold', color: '#f2d27b' }).setScrollFactor(0).setDepth(22);
    this.sidebarSections = {};
    this.categoryTabs = [];
    this.activeCategory = 'buildings';
    [['buildings', '▣', 'BUILDINGS'], ['defensive', '⌂', 'DEFENSIVE'], ['infantry', '✚', 'INFANTRY'], ['vehicles', '▰', 'VEHICLES'], ['aircraft', '▲', 'AIRCRAFT'], ['navy', '≋', 'NAVY']].forEach(([key, symbol, title]) => {
      const background = this.add.rectangle(0, 0, 40, 23, 0x26343b, 1).setStrokeStyle(1, 0x71806d).setScrollFactor(0).setDepth(21).setInteractive({ useHandCursor: true });
      const text = this.add.text(0, 0, symbol, { fontFamily: 'monospace', fontSize: '12px', fontStyle: 'bold', color: '#d9e0c4' }).setOrigin(0.5).setScrollFactor(0).setDepth(22);
      background.on('pointerdown', () => { this.uiPointerGate.block(); this.setCategory(key); });
      this.categoryTabs.push({ background, text, key, title });
    });
    [['defensive', '⌂ DEFENSIVE', 'NO STRUCTURES'], ['infantry', '✚ INFANTRY', 'RIFLE SQUAD'], ['vehicles', '▰ VEHICLES', 'NO VEHICLES'], ['aircraft', '▲ AIRCRAFT', 'NO AIRCRAFT'], ['navy', '≋ NAVY', 'NO NAVAL UNITS']].forEach(([key, title, row]) => {
      this.sidebarSections[key] = {
        title: this.add.text(0, 0, title, { fontFamily: 'monospace', fontSize: '9px', fontStyle: 'bold', color: '#8ca58b' }).setScrollFactor(0).setDepth(22),
        row: this.add.text(0, 0, row, { fontFamily: 'monospace', fontSize: '9px', color: '#c6d2c0' }).setScrollFactor(0).setDepth(22)
      };
    });
    this.unitEntries = ['rifle_squad', 'scout_bike', 'harvester'].map((type) => this.add.text(0, 0, '', {
      fontFamily: 'monospace', fontSize: '9px', color: '#c6d2c0'
    }).setScrollFactor(0).setDepth(22));
    this.activeBuildTab = 'main';
    this.buildTabs = [];
    [['MAIN BUILDINGS', 'main'], ['SUPPORT BUILDINGS', 'support']].forEach(([label, tab]) => {
      const background = this.add.rectangle(0, 0, 90, 25, 0x26343b, 1).setStrokeStyle(1, 0x71806d).setScrollFactor(0).setDepth(21).setInteractive({ useHandCursor: true });
      const text = this.add.text(0, 0, label, { fontFamily: 'monospace', fontSize: '8px', fontStyle: 'bold', color: '#d9e0c4' }).setOrigin(0.5).setScrollFactor(0).setDepth(22);
      background.on('pointerdown', () => { this.uiPointerGate.block(); this.setBuildTab(tab); });
      this.buildTabs.push({ background, text, tab });
    });
    this.supportNotice = this.add.text(0, 0, 'SUPPORT SYSTEMS\nNO STRUCTURES\nAVAILABLE', { fontFamily: 'monospace', fontSize: '10px', align: 'center', color: '#8ca58b' }).setOrigin(0.5).setScrollFactor(0).setDepth(22);
    this.commandButtons = [];
    [
       ['MOVE', 'move'], ['ATTACK', 'attack'], ['STOP', 'stop'], ['DEFEND AREA', 'defend'], ['SELECT ALL', 'select_all']
    ].forEach(([label, action]) => {
      const background = this.add.rectangle(0, 0, 112, 42, 0x26343b, 1).setStrokeStyle(1, 0x71806d).setScrollFactor(0).setDepth(21).setInteractive({ useHandCursor: true });
      const text = this.add.text(0, 0, label, { fontFamily: 'monospace', fontSize: '12px', fontStyle: 'bold', color: '#d9e0c4' }).setOrigin(0.5).setScrollFactor(0).setDepth(22);
      background.on('pointerover', () => background.setFillStyle(0x3e5748));
      background.on('pointerout', () => background.setFillStyle(0x26343b));
      background.on('pointerdown', () => { this.uiPointerGate.block(); this.useCommandButton(action); });
      this.commandButtons.push({ background, text, action });
    });
    this.buildCards = [];
    [['REFINERY', 'refinery', 300, 'buildings'], ['BARRACKS', 'barracks', 250, 'buildings'], ['WAR FACTORY', 'machine_shop', 800, 'buildings'], ['SERVICE DEPOT', 'service_depot', 500, 'buildings'], ['SENTRY TURRET', 'defense_grid', 450, 'defensive'], ['POWER PLANT', 'power_plant', 400, 'buildings']].forEach(([label, type, cost, category]) => {
      const background = this.add.rectangle(0, 0, 178, 62, 0x26343b, 1).setStrokeStyle(1, 0x71806d).setScrollFactor(0).setDepth(21).setInteractive({ useHandCursor: true });
      const text = this.add.text(0, 0, label, { fontFamily: 'monospace', fontSize: '12px', fontStyle: 'bold', color: '#d9e0c4' }).setOrigin(0, 0.5).setScrollFactor(0).setDepth(22);
       const powerLabel = type === 'power_plant' ? '  +35 PWR' : '';
       const costText = this.add.text(0, 0, `METAL ${cost}${powerLabel}`, { fontFamily: 'monospace', fontSize: '10px', color: '#aebc9a' }).setOrigin(0, 0.5).setScrollFactor(0).setDepth(22);
      background.on('pointerover', () => background.setFillStyle(0x3e5748));
      background.on('pointerout', () => background.setFillStyle(0x26343b));
      background.on('pointerdown', () => { this.uiPointerGate.block(); this.selectBuildType(type); });
      this.buildCards.push({ background, text, costText, type, category });
    });
    this.unitCards = [];
    [['RIFLE SQUAD', 'rifle_squad', 100, 1, true], ['ROCKET TEAM', 'rocket_team', 175, 1, true], ['ASSAULT TROOPER', 'assault_trooper', 140, 1, true], ['SCOUT BIKE', 'scout_bike', 150, 1, true], ['LIGHT TANK', 'light_tank', 350, 3, true], ['SIEGE TANK', 'siege_tank', 550, 4, true], ['HARVESTER', 'harvester', 0, 2, false]].forEach(([label, type, cost, supply, available]) => {
      const background = this.add.rectangle(0, 0, 178, 44, available ? 0x26343b : 0x182126, 1).setStrokeStyle(1, available ? 0x71806d : 0x35433f).setScrollFactor(0).setDepth(21).setInteractive({ useHandCursor: available });
      const text = this.add.text(0, 0, label, { fontFamily: 'monospace', fontSize: '10px', fontStyle: 'bold', color: available ? '#d9e0c4' : '#66736d' }).setOrigin(0, 0.5).setScrollFactor(0).setDepth(22);
      const costText = this.add.text(0, 0, available ? `METAL ${cost}  SUP ${supply}` : 'NOT AVAILABLE', { fontFamily: 'monospace', fontSize: '9px', color: available ? '#aebc9a' : '#66736d' }).setOrigin(0, 0.5).setScrollFactor(0).setDepth(22);
      if (available) {
        background.on('pointerover', () => background.setFillStyle(0x3e5748));
        background.on('pointerout', () => background.setFillStyle(0x26343b));
         background.on('pointerdown', (pointer) => this.handleProductionCard(type, pointer));
         background.on('pointerdown', (pointer) => pointer.event?.preventDefault?.());
      }
      this.unitCards.push({ background, text, costText, type, available });
    });
    this.utilityButtons = [];
    [['REPAIR', 'repair'], ['SELL', 'sell']].forEach(([label, action]) => {
      const background = this.add.rectangle(0, 0, 84, 34, 0x26343b, 1).setStrokeStyle(1, 0x71806d).setScrollFactor(0).setDepth(21).setInteractive({ useHandCursor: true });
      const text = this.add.text(0, 0, label, { fontFamily: 'monospace', fontSize: '10px', fontStyle: 'bold', color: '#d9e0c4' }).setOrigin(0.5).setScrollFactor(0).setDepth(22);
      background.on('pointerover', () => background.setFillStyle(0x3e5748));
      background.on('pointerout', () => background.setFillStyle(0x26343b));
       background.on('pointerdown', () => { this.uiPointerGate.block(); this.useBuildingAction(action); });
      this.utilityButtons.push({ background, text, action });
    });
    this.gameOverPanel = this.add.graphics().setScrollFactor(0).setDepth(30).setVisible(false);
    this.gameOverTitle = this.add.text(0, 0, '', { fontFamily: 'monospace', fontSize: '28px', fontStyle: 'bold', color: '#f2d27b' }).setOrigin(0.5).setScrollFactor(0).setDepth(31).setVisible(false);
    this.gameOverDetail = this.add.text(0, 0, '', { fontFamily: 'monospace', fontSize: '13px', color: '#d9e0c4' }).setOrigin(0.5).setScrollFactor(0).setDepth(31).setVisible(false);
    this.restartButton = this.add.rectangle(0, 0, 190, 44, 0x26343b, 1).setStrokeStyle(2, 0xf2d27b).setScrollFactor(0).setDepth(31).setInteractive({ useHandCursor: true }).setVisible(false);
    this.restartButtonText = this.add.text(0, 0, 'RESTART MISSION', { fontFamily: 'monospace', fontSize: '12px', fontStyle: 'bold', color: '#f2d27b' }).setOrigin(0.5).setScrollFactor(0).setDepth(32).setVisible(false);
    this.restartButton.on('pointerdown', () => this.scene.restart());
    this.pausePanel = this.add.graphics().setScrollFactor(0).setDepth(28).setVisible(false);
    this.pauseTitle = this.add.text(0, 0, 'GAME PAUSED', { fontFamily: 'monospace', fontSize: '28px', fontStyle: 'bold', color: '#f2d27b' }).setOrigin(0.5).setScrollFactor(0).setDepth(29).setVisible(false);
    this.pauseDetail = this.add.text(0, 0, 'SIMULATION HOLD // ESC TO RESUME', { fontFamily: 'monospace', fontSize: '12px', color: '#d9e0c4' }).setOrigin(0.5).setScrollFactor(0).setDepth(29).setVisible(false);
    this.pauseResume = this.add.rectangle(0, 0, 190, 44, 0x26343b, 1).setStrokeStyle(2, 0xf2d27b).setScrollFactor(0).setDepth(29).setInteractive({ useHandCursor: true }).setVisible(false);
    this.pauseResumeText = this.add.text(0, 0, 'RESUME', { fontFamily: 'monospace', fontSize: '12px', fontStyle: 'bold', color: '#f2d27b' }).setOrigin(0.5).setScrollFactor(0).setDepth(30).setVisible(false);
    this.pauseRestart = this.add.rectangle(0, 0, 190, 44, 0x26343b, 1).setStrokeStyle(1, 0x71806d).setScrollFactor(0).setDepth(29).setInteractive({ useHandCursor: true }).setVisible(false);
    this.pauseRestartText = this.add.text(0, 0, 'RESTART MISSION', { fontFamily: 'monospace', fontSize: '12px', fontStyle: 'bold', color: '#d9e0c4' }).setOrigin(0.5).setScrollFactor(0).setDepth(30).setVisible(false);
    this.pauseSave = this.add.rectangle(0, 0, 116, 38, 0x26343b, 1).setStrokeStyle(1, 0xf2d27b)
      .setScrollFactor(0).setDepth(29).setInteractive({ useHandCursor: true }).setVisible(false);
    this.pauseSaveText = this.add.text(0, 0, 'SAVE', {
      fontFamily: 'monospace', fontSize: '12px', color: '#e9f0dd'
    }).setOrigin(0.5).setScrollFactor(0).setDepth(30).setVisible(false);
    this.pauseLoad = this.add.rectangle(0, 0, 116, 38, 0x26343b, 1).setStrokeStyle(1, 0xf2d27b)
      .setScrollFactor(0).setDepth(29).setInteractive({ useHandCursor: true }).setVisible(false);
    this.pauseLoadText = this.add.text(0, 0, 'LOAD', {
      fontFamily: 'monospace', fontSize: '12px', color: '#e9f0dd'
    }).setOrigin(0.5).setScrollFactor(0).setDepth(30).setVisible(false);
    this.pauseSave.on('pointerdown', () => { this.uiPointerGate.block(); this.saveSkirmish(); });
    this.pauseLoad.on('pointerdown', () => { this.uiPointerGate.block(); this.loadSkirmish(); });
    this.mobilePauseButton = this.add.rectangle(0, 0, 74, 36, 0x263f3b, 1)
      .setStrokeStyle(1, 0x8ca58b).setScrollFactor(0).setDepth(23)
      .setInteractive({ useHandCursor: true }).setVisible(false);
    this.mobilePauseText = this.add.text(0, 0, 'PAUSE', {
      fontFamily: 'monospace', fontSize: '11px', color: '#e9f0dd'
    }).setOrigin(0.5).setScrollFactor(0).setDepth(24).setVisible(false);
    this.mobilePauseButton.on('pointerdown', () => {
      this.uiPointerGate.block();
      this.cancelPlacement();
      this.togglePause();
    });
    this.debugText = this.add.text(8, 58, '', {
      fontFamily: 'monospace', fontSize: '11px', color: '#b7e7cb',
      backgroundColor: '#06131bef', padding: { x: 8, y: 7 }
    }).setScrollFactor(0).setDepth(33).setVisible(false);
    this.errorText = this.add.text(12, 80, '', {
      fontFamily: 'monospace', fontSize: '11px', color: '#ffc0c5',
      backgroundColor: '#381821f2', padding: { x: 9, y: 7 },
      wordWrap: { width: 350 }
    }).setScrollFactor(0).setDepth(35).setVisible(false);
    this.pauseResume.on('pointerdown', () => { this.uiPointerGate.block(); this.togglePause(false); });
    this.pauseRestart.on('pointerdown', () => this.scene.restart());
    this.setBuildTab('main');
    this.setCategory('buildings');
  }

  setupUiCamera() {
    const { width, height } = this.uiSize();
    this.uiCamera = this.cameras.add(0, 0, width * this.renderDensity, height * this.renderDensity);
    this.uiCamera.setScroll(0, 0).setZoom(this.renderDensity);
    const hudObjects = [
      this.hud,
      ...Object.values(this.hudText),
      this.buildTitle,
      this.mobileMenuButton, this.mobileMenuText, this.mobilePageText,
      this.mobilePlacementStatus, this.mobilePlacementHint,
      this.mobilePauseButton, this.mobilePauseText, this.debugText, this.errorText,
      ...this.mobilePagerButtons.flatMap((button) => [button.background, button.text]),
      ...this.categoryTabs.flatMap((tab) => [tab.background, tab.text]),
      ...Object.values(this.sidebarSections).flatMap((section) => [section.title, section.row]),
      ...this.unitEntries,
      ...this.buildTabs.flatMap((tab) => [tab.background, tab.text]),
      this.supportNotice,
      this.gameOverPanel, this.gameOverTitle, this.gameOverDetail, this.restartButton, this.restartButtonText,
      this.pausePanel, this.pauseTitle, this.pauseDetail, this.pauseResume, this.pauseResumeText, this.pauseRestart, this.pauseRestartText,
      this.pauseSave, this.pauseSaveText, this.pauseLoad, this.pauseLoadText,
      ...this.commandButtons.flatMap((button) => [button.background, button.text]),
      this.buildPanel,
      ...this.buildCards.flatMap((card) => [card.background, card.text, card.costText]),
      ...this.unitCards.flatMap((card) => [card.background, card.text, card.costText]),
      ...this.utilityButtons.flatMap((button) => [button.background, button.text]),
      this.helpText,
      this.statusText
    ];
    this.cameras.main.ignore(hudObjects);
    this.uiCamera.ignore([this.worldLayer, this.resourceLayer, this.selectionLayer, this.unitLayer, this.projectileLayer, this.buildPreview, this.buildPreviewLabel, this.ui]);
  }

  uiSize() {
    return {
      width: (this.scale.gameSize?.width ?? this.scale.width) / this.renderDensity,
      height: (this.scale.gameSize?.height ?? this.scale.height) / this.renderDensity
    };
  }

  toggleMobilePanel() {
    this.uiPointerGate.block();
    if (!this.mobilePanelOpen && this.cancelPlacement()) {
      this.message = 'Building placement cancelled.';
      return;
    }
    this.mobilePanelOpen = !this.mobilePanelOpen;
    this.mobileCardPage = 0;
    this.uiPointerGate.block();
    this.layoutUi();
  }

  changeMobilePage(delta) {
    this.uiPointerGate.block();
    this.mobileCardPage = Math.max(0, this.mobileCardPage + delta);
    this.uiPointerGate.block();
    this.layoutUi();
  }

  closeMobilePanelForTargeting() {
    if (this.mobilePanelOpen && (this.uiSize().width < 700 || this.isTouchDevice())) {
      this.mobilePanelOpen = false;
      this.uiPointerGate.block();
      this.layoutUi();
    }
  }

  beginPlacement(type = this.buildType) {
    if (!this.placement.begin(type)) return false;
    this.commandMode = 'build';
    this.utilityMode = null;
    this.buildPreviewPosition = null;
    this.buildPreview?.clear();
    this.buildPreviewLabel?.setVisible(false);
    this.closeMobilePanelForTargeting();
    this.previewScreenAnchor = this.defaultPlacementScreenAnchor();
    this.message = `Placing ${BUILDING_TYPES[type].name}. Tap a valid location to construct.`;
    this.refreshPlacementPreview();
    if (this.uiCamera) this.layoutUi();
    return true;
  }

  cancelPlacement() {
    if (!this.placement.cancel()) return false;
    if (this.commandMode === 'build') this.commandMode = null;
    this.buildPreviewPosition = null;
    this.previewScreenAnchor = null;
    this.buildPreview?.clear();
    this.buildPreviewLabel?.setVisible(false);
    if (this.uiCamera) this.layoutUi();
    return true;
  }

  finishPlacement() {
    if (!this.placement.finish()) return false;
    if (this.commandMode === 'build') this.commandMode = null;
    this.buildPreviewPosition = null;
    this.previewScreenAnchor = null;
    this.buildPreview?.clear();
    this.buildPreviewLabel?.setVisible(false);
    if (this.uiCamera) this.layoutUi();
    return true;
  }

  choosePreferredBuilding(type) {
    if (!this.placement.prefer(type)) return false;
    this.buildPreviewPosition = null;
    this.buildPreview?.clear();
    this.message = `${BUILDING_TYPES[type].name} selected.`;
    if (this.placement.active) {
      this.previewScreenAnchor = this.previewScreenAnchor ?? this.defaultPlacementScreenAnchor();
      this.refreshPlacementPreview();
    }
    return true;
  }

  useCommandButton(action) {
    if (action === 'build') {
      if (this.cancelPlacement()) {
        this.message = 'Building placement cancelled.';
        return;
      }
      const core = this.simulation.buildings.find((building) =>
        this.selectedBuildings.has(building.id) && building.type === 'command_core' && building.complete);
      if (!core) {
        this.message = 'Select a completed Command Core to open construction.';
        return;
      }
      this.beginPlacement();
      return;
    }
    this.cancelPlacement();
    this.utilityMode = null;
    if (action === 'select_all') {
      this.selected.clear();
      this.selectedBuildings.clear();
      this.units.filter((unit) => unit.team === 0).forEach((unit) => this.selected.add(unit.id));
      this.message = `${this.selected.size} units selected.`;
    } else if (action === 'stop') {
      if (this.selected.size) this.simulation.issue(stopCommand(0, [...this.selected]));
      this.commandMode = null;
      this.message = 'Stop order issued.';
    } else if (action === 'defend') {
      this.commandMode = 'defend';
      this.message = 'DEFEND AREA: choose a guard position.';
    } else {
      this.commandMode = action;
      this.message = `${action.toUpperCase()} mode: choose a target.`;
    }
  }

  selectBuildType(type) { return this.beginPlacement(type); }

  setBuildTab(tab) {
    this.activeBuildTab = tab;
    // The sidebar uses fixed C&C-style category sections rather than Main/Support tabs.
    this.buildTabs.forEach((categoryTab) => {
      categoryTab.background.setVisible(false);
      categoryTab.text.setVisible(false);
    });
    this.buildCards.forEach((card) => {
       const visible = this.activeCategory === card.category;
      card.background.setVisible(visible);
      card.text.setVisible(visible);
      card.costText.setVisible(visible);
    });
    this.unitCards.forEach((card) => {
       const visible = (this.activeCategory === 'infantry' && ['rifle_squad', 'rocket_team', 'assault_trooper'].includes(card.type))
         || (this.activeCategory === 'vehicles' && ['scout_bike', 'light_tank', 'siege_tank', 'harvester'].includes(card.type));
      card.background.setVisible(visible);
      card.text.setVisible(visible);
      card.costText.setVisible(visible);
    });
    this.supportNotice.setVisible(false);
  }

  setCategory(category) {
    if (this.activeCategory !== category) this.mobileCardPage = 0;
    this.activeCategory = category;
    const tab = this.categoryTabs.find((candidate) => candidate.key === category);
    this.buildTitle.setText(`${tab?.text.text ?? '▣'} ${tab?.title ?? 'BUILDINGS'}`);
    this.buildCards.forEach((card) => {
       const visible = category === card.category;
      card.background.setVisible(visible);
      card.text.setVisible(visible);
      card.costText.setVisible(visible);
    });
    this.unitCards.forEach((card) => {
       const visible = (category === 'infantry' && ['rifle_squad', 'rocket_team', 'assault_trooper'].includes(card.type))
         || (category === 'vehicles' && ['scout_bike', 'light_tank', 'siege_tank', 'harvester'].includes(card.type));
      card.background.setVisible(visible);
      card.text.setVisible(visible);
      card.costText.setVisible(visible);
    });
    Object.entries(this.sidebarSections).forEach(([key, section]) => {
      const visible = key === category;
       const hasCards = key === 'defensive' || key === 'infantry' || key === 'vehicles';
       section.title.setVisible(visible && !hasCards);
       section.row.setVisible(visible && !hasCards);
    });
    // Unit cards are the roster now; keep the older text entries hidden to avoid
    // duplicating and overlapping the card contents.
    this.unitEntries.forEach((entry) => entry.setVisible(false));
    this.categoryTabs.forEach((categoryTab) => categoryTab.background.setStrokeStyle(2, categoryTab.key === category ? 0xf2d27b : 0x71806d));
    // Reflow cards immediately when switching tabs; otherwise cards keep the
    // positions calculated for the previously selected category.
    if (this.uiCamera) this.layoutUi();
  }

  installErrorDiagnostics() {
    const runtimeError = event => this.reportRuntimeError(event.message || 'Unknown runtime error', 'ERROR');
    const rejection = event => this.reportRuntimeError(event.reason, 'PROMISE');
    window.addEventListener('error', runtimeError);
    window.addEventListener('unhandledrejection', rejection);
    this.events.once(Phaser.Scenes.Events.SHUTDOWN, () => {
      window.removeEventListener('error', runtimeError);
      window.removeEventListener('unhandledrejection', rejection);
    });
  }

  reportRuntimeError(error, kind = 'ERROR') {
    const entry = this.runtimeErrors.record(error, kind);
    this.errorText.setText(`${entry.category}: ${entry.message}`)
      .setWordWrapWidth(Math.max(160, this.uiSize().width - 42))
      .setVisible(true);
  }

  saveSkirmish(automatic = false) {
    const result = saveGameToStorage(this, window.localStorage, automatic ? AUTOSAVE_KEY : SKIRMISH_SAVE_KEY);
    if (!automatic) {
      this.message = result.ok ? 'Skirmish saved to this browser.' : `Save failed: ${result.reason}.`;
      this.pauseDetail.setText(this.message);
    }
    return result;
  }

  loadSkirmish() {
    let loaded = readGameFromStorage(window.localStorage);
    if (!loaded.ok && loaded.reason === 'no_save') loaded = readGameFromStorage(window.localStorage, AUTOSAVE_KEY);
    if (!loaded.ok) {
      this.message = `Load failed: ${loaded.reason}.`;
      this.pauseDetail.setText(this.message);
      return loaded;
    }
    try {
      const restored = Simulation.fromSaveState(loaded.data.simulation);
      this.simulation = restored;
      this.units = restored.units;
      this.selected.clear();
      this.selectedBuildings.clear();
      this.commandMode = null;
      this.utilityMode = null;
      this.cancelPlacement();
      this.mobilePanelOpen = false;
      this.isPaused = false;
      this.cameras.main.setZoom(Math.max(this.minZoom, Math.min(1.5 * this.renderDensity, loaded.data.camera.zoom)));
      this.cameras.main.setScroll(loaded.data.camera.scrollX, loaded.data.camera.scrollY);
      this.nextAutosaveTime = restored.time + 60;
      this.message = 'Skirmish loaded.';
      this.layoutUi();
      return { ok: true };
    } catch (error) {
      this.message = `Load failed: ${error?.message ?? error}.`;
      this.pauseDetail.setText(this.message);
      return { ok: false, reason: this.message };
    }
  }

  runDebugScenario(name = 'unit_stress') {
    if (!import.meta.env.DEV && import.meta.env.MODE !== 'e2e') return false;
    const scenario = debugScenario(name);
    for (let i = 0; i < scenario.units; i++) {
      const col = i % scenario.columns, row = Math.floor(i / scenario.columns);
      this.simulation.addUnit({ playerId: i % 2, team: i % 2, type: 'rifle_squad',
        x: 900 + col * scenario.spacing, y: 250 + row * scenario.spacing });
    }
    this.message = `DEBUG ${name}: ${scenario.units} units spawned.`;
    return true;
  }

  togglePause(force) {
    if (this.simulation.gameState !== 'playing') return;
    this.isPaused = force ?? !this.isPaused;
    this.message = this.isPaused ? 'Game paused.' : 'Game resumed.';
    this.updateUi();
  }

  useBuildingAction(action) {
    this.cancelPlacement();
    this.utilityMode = action;
    this.commandMode = null;
    this.closeMobilePanelForTargeting();
    this.message = `${action.toUpperCase()} MODE: click a friendly ${action === 'sell' ? 'structure' : 'structure or vehicle'}.`;
  }

  handleProductionCard(type, pointer) {
    this.uiPointerGate.block();
    this.cancelPlacement();
    const canProduce = (building) => {
      const products = BUILDING_TYPES[building.type]?.produces;
      return building.playerId === 0 && building.complete && (Array.isArray(products) ? products.includes(type) : products === type);
    };
    const producer = this.simulation.buildings.find((building) => this.selectedBuildings.has(building.id) && canProduce(building))
      ?? this.simulation.buildings.find(canProduce);
    if (!producer) { this.message = 'Select a completed producer or choose a compatible card.'; return; }
    this.selected.clear();
    this.selectedBuildings.clear();
    this.selectedBuildings.add(producer.id);
    const rightClick = pointer.button === 2;
    const shift = pointer.event?.shiftKey ?? false;
    if (rightClick) {
      const action = shift ? 'clear' : producer.queuePaused ? 'cancel' : 'pause';
      const result = this.simulation.controlProduction(0, producer.id, action);
      this.message = result.ok
        ? `${producer.name} queue ${action === 'clear' ? 'cleared' : action === 'cancel' ? 'item cancelled' : result.paused ? 'paused' : 'resumed'}.${result.refunded ? ` ${result.refunded} metal refunded.` : ''}`
        : `QUEUE rejected: ${result.reason}.`;
      return;
    }
    const count = shift ? 5 : 1;
    let queued = 0;
    for (let index = 0; index < count; index += 1) {
      const result = this.simulation.issue(produceCommand(0, producer.id, type));
      if (!result.ok) break;
      queued += 1;
    }
    this.message = queued ? `${type.replaceAll('_', ' ').toUpperCase()} queued ×${queued}.` : 'Production rejected.';
  }

  isTouchDevice() {
    return window.matchMedia?.('(pointer: coarse)').matches ?? false;
  }

  mobileAvailableCards() {
    if (this.activeCategory === 'buildings' || this.activeCategory === 'defensive') {
      return this.buildCards.filter((card) => card.category === this.activeCategory);
    }
    if (this.activeCategory === 'infantry') {
      return this.unitCards.filter((card) => ['rifle_squad', 'rocket_team', 'assault_trooper'].includes(card.type));
    }
    if (this.activeCategory === 'vehicles') {
      return this.unitCards.filter((card) => ['scout_bike', 'light_tank', 'siege_tank', 'harvester'].includes(card.type));
    }
    return [];
  }

  mobileHudLayout() {
    const { width, height } = this.uiSize();
    return getMobileHudLayout(width, height, this.mobileAvailableCards().length);
  }

  isUiPointer(pointer) {
    const { width, height } = this.uiSize();
    if (width < 700 || this.isTouchDevice()) {
      const layout = this.mobileHudLayout();
      const inPanel = this.mobilePanelOpen
        && pointer.x >= layout.drawerLeft && pointer.x <= layout.drawerLeft + layout.drawerWidth
        && pointer.y >= layout.drawerTop && pointer.y <= layout.drawerBottom;
      return this.isPaused || pointer.y <= layout.topBarHeight || pointer.y >= layout.bottomTop || inPanel;
    }
    return this.isPaused || pointer.x >= this.sidebarLayout().left || pointer.y >= height - 165;
  }

  updateZoomLimits() {
    // Keep the viewport no larger than the world, otherwise camera bounds
    // force the view to the exact middle when zooming out.
    this.minZoom = Math.max(0.55 * this.renderDensity, this.scale.width / WORLD.width,
      this.scale.height / WORLD.height);
  }

  createUnits() {
    const add = (team, x, y) => this.simulation.addUnit({ playerId: team, team, type: 'rifle_squad', x, y });
    [[420, 620], [500, 700], [420, 780], [560, 610], [480, 850]].forEach(([x, y]) => add(0, x, y));
    [[1980, 620], [1900, 700], [1980, 780], [1840, 610], [1920, 850]].forEach(([x, y]) => add(1, x, y));
    this.simulation.addBuilding({ playerId: 0, team: 0, type: 'command_core', x: 300, y: 750 });
    this.simulation.addBuilding({ playerId: 0, team: 0, type: 'barracks', x: 560, y: 500 });
    this.simulation.addBuilding({ playerId: 0, team: 0, type: 'refinery', x: 620, y: 750 });
    this.simulation.addBuilding({ playerId: 0, team: 0, type: 'power_plant', x: 700, y: 500 });
    this.simulation.addBuilding({ playerId: 1, team: 1, type: 'command_core', x: 2100, y: 750 });
    this.simulation.addBuilding({ playerId: 1, team: 1, type: 'barracks', x: 1840, y: 500 });
    this.simulation.addBuilding({ playerId: 1, team: 1, type: 'refinery', x: 1780, y: 750 });
    this.simulation.addBuilding({ playerId: 1, team: 1, type: 'power_plant', x: 1700, y: 500 });
    this.simulation.addUnit({ playerId: 0, team: 0, type: 'harvester', x: 500, y: 900 });
    this.simulation.addUnit({ playerId: 1, team: 1, type: 'harvester', x: 1900, y: 900 });
  }

  drawWorld() {
    drawTerrain(this.worldLayer, WORLD, TEAM);
    this.drawResourceNodes();
  }

  drawResourceNodes() {
    drawResources(this.resourceLayer, this.simulation.resourceNodes);
  }

  installInput() { installBattlefieldInput(this); }

  handleTap(world, pointer) {
    const building = this.hitBuilding(world);
    const unit = this.hitUnit(world);
    if (this.utilityMode) {
      const target = building?.team === 0 ? building : unit?.team === 0 ? unit : null;
      const targetType = target === building ? 'building' : 'unit';
      if (!target || (this.utilityMode === 'sell' && targetType !== 'building')) {
        this.message = `${this.utilityMode.toUpperCase()} rejected: choose a valid friendly target.`;
      } else {
        const command = this.utilityMode === 'repair'
          ? repairCommand(0, target.id, targetType)
          : sellCommand(0, target.id);
        const result = this.simulation.issue(command);
        this.message = result.ok ? `${target.name ?? target.type} ${this.utilityMode === 'repair' ? 'repair ordered.' : 'sold.'}` : `${this.utilityMode.toUpperCase()} rejected: ${result.reason}.`;
        if (result.ok) this.utilityMode = null;
      }
      return;
    }
    if (this.placement.active) {
      const type = this.placement.selected;
      this.previewScreenAnchor = { x: pointer.x, y: pointer.y };
      this.updateBuildPreview(world);
      const result = this.simulation.issue(buildCommand(0, type, world));
      this.message = result.ok ? `${BUILDING_TYPES[type].name} construction queued.` : `Build rejected: ${result.reason}.`;
      if (result.ok) this.finishPlacement();
      return;
    }
    if (this.commandMode === 'attack' && this.selected.size > 0 && building?.team === 1) {
      const result = this.simulation.issue(attackCommand(0, [...this.selected], building.id, 'building'));
      this.message = result.ok ? 'Attack order issued against building.' : `Command rejected: ${result.reason}.`;
      if (result.ok) this.commandMode = null;
      return;
    }
    if (building && building.team === 0) {
      this.selected.clear();
      this.selectedBuildings.clear();
      this.selectedBuildings.add(building.id);
       this.message = building.type === 'barracks'
         ? `${building.name} selected. Press P to queue rifle squads.`
         : building.type === 'command_core'
           ? `${building.name} selected. Press BUILD or B to construct.`
           : `${building.name} selected. Harvesters deliver metal here.`;
      return;
    }
    if (this.commandMode && this.selected.size > 0 && ['move', 'attack', 'defend'].includes(this.commandMode)) {
      if (this.commandMode === 'defend') {
        const result = this.simulation.issue(defendCommand(0, [...this.selected], world));
        this.message = result.ok ? 'Defend area stance assigned.' : `Command rejected: ${result.reason}.`;
        if (result.ok) this.commandMode = null;
        return;
      }
      if (this.commandMode === 'attack' && unit?.team === 1) {
        this.simulation.issue(attackCommand(0, [...this.selected], unit.id));
        this.message = 'Attack order issued.';
        this.commandMode = null;
        return;
      }
      if (this.commandMode === 'move' && !unit) {
        this.simulation.issue(moveCommand(0, [...this.selected], world));
        this.message = 'Move order issued.';
        this.commandMode = null;
        return;
      }
    }
    if (unit?.team === 0) {
      this.selectedBuildings.clear();
      if (!pointer.event?.shiftKey) this.selected.clear();
      this.selected.add(unit.id);
      this.message = `${this.selected.size} unit${this.selected.size === 1 ? '' : 's'} selected.`;
      return;
    }
    if (this.selected.size === 0) return;
    if (unit?.team === 1) {
      const result = this.simulation.issue(attackCommand(0, [...this.selected], unit.id));
      this.message = result.ok ? 'Attack order issued.' : `Command rejected: ${result.reason}.`;
    } else if (building?.team === 1) {
      const result = this.simulation.issue(attackCommand(0, [...this.selected], building.id, 'building'));
      this.message = result.ok ? 'Attack order issued against building.' : `Command rejected: ${result.reason}.`;
    } else {
      const selected = [...this.selected].map((id) => this.getUnit(id)).filter(Boolean);
      const result = this.simulation.issue(moveCommand(0, selected.map((own) => own.id), world));
      this.message = result.ok ? 'Move order issued.' : `Command rejected: ${result.reason}.`;
    }
  }

  drawSelectionBox(pointer) {
    const start = this.dragStart;
    const world = this.toWorld(pointer);
    this.selectionLayer.clear().lineStyle(2, TEAM.PLAYER, 0.9).fillStyle(TEAM.PLAYER, 0.12);
    this.selectionLayer.fillRect(start.worldX, start.worldY, world.x - start.worldX, world.y - start.worldY);
    this.selectionLayer.strokeRect(start.worldX, start.worldY, world.x - start.worldX, world.y - start.worldY);
  }

  selectBox(x1, y1, x2, y2) {
    const left = Math.min(x1, x2), right = Math.max(x1, x2), top = Math.min(y1, y2), bottom = Math.max(y1, y2);
    this.selected.clear();
    this.units.filter((u) => u.team === 0 && u.x >= left && u.x <= right && u.y >= top && u.y <= bottom)
      .forEach((u) => this.selected.add(u.id));
    this.message = `${this.selected.size} unit${this.selected.size === 1 ? '' : 's'} selected.`;
  }

  hitUnit(world) {
    return this.units.slice().reverse().find((unit) => Phaser.Math.Distance.Between(world.x, world.y, unit.x, unit.y) < 30);
  }
  hitBuilding(world) {
    return this.simulation.buildings.slice().reverse().find((building) => {
      const definition = BUILDING_TYPES[building.type];
      return definition && Math.abs(world.x - building.x) <= definition.width / 2 && Math.abs(world.y - building.y) <= definition.height / 2;
    });
  }

  defaultPlacementScreenAnchor() {
    const { width, height } = this.uiSize();
    const mobile = width < 700 || this.isTouchDevice();
    return defaultPreviewAnchor(width, height, mobile, mobile ? width : this.sidebarLayout().left);
  }

  refreshPlacementPreview() {
    if (!this.placement.active || this.isPaused || this.simulation.gameState !== 'playing') {
      this.buildPreview.clear();
      this.buildPreviewLabel.setVisible(false);
      return;
    }
    const anchor = this.previewScreenAnchor ?? this.defaultPlacementScreenAnchor();
    this.updateBuildPreview(this.cameras.main.getWorldPoint(anchor.x * this.renderDensity, anchor.y * this.renderDensity));
  }

  updateBuildPreview(world) {
    this.buildPreviewPosition = world;
    const preview = describePlacement(this.simulation, this.placement.selected, world);
    this.buildPreview.clear();
    if (!preview) {
      this.buildPreviewLabel.setVisible(false);
      return;
    }
    const { x, y, width, height, color, valid } = preview;
    const graphics = this.buildPreview;
    // The same footprint and silhouette as the finished building.
    graphics.fillStyle(0x07101a, 0.35)
      .fillRect(x - width / 2, y - height / 2, width, height);
    graphics.fillStyle(color, 0.26)
      .fillRect(x - width / 2 + 5, y - height / 2 + 5, width - 10, height - 10);
    this.drawBuildingSymbol({ type: preview.type, x, y }, color, 0.52, graphics);
    graphics.fillStyle(color, 0.12).fillRect(x - width / 2, y - height / 2, width, height);
    graphics.lineStyle(3, color, 0.98)
      .strokeRect(x - width / 2, y - height / 2, width, height);
    const corner = 12;
    graphics.lineStyle(2, color, 1);
    for (const dx of [-1, 1]) for (const dy of [-1, 1]) {
      const px = x + dx * width / 2;
      const py = y + dy * height / 2;
      graphics.lineBetween(px, py, px - dx * corner, py);
      graphics.lineBetween(px, py, px, py - dy * corner);
    }
    this.buildPreviewLabel.setText(`${preview.type.replaceAll('_', ' ').toUpperCase()} // ${preview.message}`)
      .setColor(valid ? '#a7f5c7' : '#ffc0c5')
      .setPosition(x, y - height / 2 - 13)
      .setVisible(true);
  }
  produceSelected(type = 'rifle_squad') {
    const selectedProducer = this.simulation.buildings.find((candidate) => {
      const definition = BUILDING_TYPES[candidate.type];
       return this.selectedBuildings.has(candidate.id) && candidate.playerId === 0 && candidate.complete
         && (Array.isArray(definition?.produces) ? definition.produces.includes(type) : definition?.produces === type);
    });
    const building = selectedProducer ?? this.simulation.buildings.find((candidate) => {
      const definition = BUILDING_TYPES[candidate.type];
       return candidate.playerId === 0 && candidate.complete
         && (Array.isArray(definition?.produces) ? definition.produces.includes(type) : definition?.produces === type);
    });
    if (!building) { this.message = `No completed producer for ${type.replace('_', ' ')}.`; return; }
    this.selected.clear();
    this.selectedBuildings.clear();
    this.selectedBuildings.add(building.id);
    const result = this.simulation.issue(produceCommand(0, building.id, type));
    const name = type.replace('_', ' ').replace(/\b\w/g, (letter) => letter.toUpperCase());
    this.message = result.ok ? `${name} queued.` : `Production rejected: ${result.reason}.`;
  }

  produceUnitType(type) {
    if (!['rifle_squad', 'rocket_team', 'assault_trooper', 'scout_bike', 'light_tank', 'siege_tank'].includes(type)) {
      this.message = `${type.replace('_', ' ').toUpperCase()} production is not available.`;
      return;
    }
    this.produceSelected(type);
  }

  toWorld(pointer) { return worldPoint(this.cameras.main, pointer, this.renderDensity); }
  isTouchPointer(pointer) {
    return isTouchGesturePointer(pointer, this.isTouchDevice());
  }
  getTouchPointers() {
    return activeTouchPointers(this.input, (pointer) => this.isTouchPointer(pointer))
      .map(pointer => logicalPointer(pointer, this.renderDensity));
  }
  zoomAt(screenX, screenY, zoom) {
    zoomAtPoint(this.cameras.main, screenX * this.renderDensity, screenY * this.renderDensity, zoom);
  }
  getUnit(id) { return this.units.find((unit) => unit.id === id); }

  centerOnSelection() {
    const chosen = [...this.selected].map((id) => this.getUnit(id)).filter(Boolean);
    if (chosen.length) this.cameras.main.centerOn(chosen[0].x, chosen[0].y);
  }

  update(_time, delta) {
    this.performanceMonitor.record(delta);
    this.debugRefreshMs += delta;
    if (this.debugVisible && this.debugRefreshMs >= 500) {
      this.debugRefreshMs = 0;
      const p = this.performanceMonitor.summary(this.simulation);
      this.debugText.setText(`FPS ${p.fps} | AVG ${p.avgFrameMs}ms | MAX ${p.maxFrameMs}ms\n` +
        `SLOW ${p.slowFrames} | UNITS ${p.units} | BUILD ${p.buildings}\n` +
        `CMD ${p.commands} | TICK ${p.tick} | HASH ${p.hash}`);
    }
    const dt = Math.min(delta / 1000, 0.05);
    if (!this.isPaused) {
      this.updateKeyboardPan(dt);
      this.simulation.advance(dt);
      if (this.simulation.time >= this.nextAutosaveTime) {
        this.nextAutosaveTime = this.simulation.time + 60;
        this.saveSkirmish(true);
      }
      const constructionEvent = this.simulation.events.find((event) =>
        event.type === 'building_rejected' || event.type === 'building_created');
      if (constructionEvent) {
        const name = BUILDING_TYPES[constructionEvent.buildingType]?.name ?? 'Building';
        this.message = constructionEvent.type === 'building_created'
          ? `${name} construction started.`
          : `${name} construction cancelled: ${constructionEvent.reason}.`;
      }
    }
    this.selected.forEach((id) => { if (!this.getUnit(id)) this.selected.delete(id); });
    this.drawUnits();
    this.drawProjectiles();
    this.refreshPlacementPreview();
    this.drawResourceNodes();
    this.updateUi();
  }

  updateKeyboardPan(dt) {
    if (!this.cameraKeys) return;
    const horizontal = Number(this.cameraKeys.right.isDown || this.cameraKeys.d.isDown) - Number(this.cameraKeys.left.isDown || this.cameraKeys.a.isDown);
    const vertical = Number(this.cameraKeys.down.isDown || this.cameraKeys.s.isDown) - Number(this.cameraKeys.up.isDown || this.cameraKeys.w.isDown);
    if (horizontal === 0 && vertical === 0) return;
    const speed = 720 * dt * this.renderDensity / this.cameras.main.zoom;
    this.cameras.main.scrollX += horizontal * speed;
    this.cameras.main.scrollY += vertical * speed;
  }

  drawUnits() {
    this.unitLayer.clear();
    this.simulation.buildings.forEach((building) => {
      const definition = BUILDING_TYPES[building.type];
      const sizes = [definition.width, definition.height];
      const color = building.team === 0 ? TEAM.PLAYER : TEAM.ENEMY;
      const [width, height] = sizes;
      const opacity = building.complete ? 1 : 0.42;
      this.unitLayer.fillStyle(0x0a1218, opacity).fillRect(building.x - width / 2, building.y - height / 2, width, height);
      this.unitLayer.fillStyle(color, building.complete ? 0.78 : 0.3).fillRect(building.x - width / 2 + 5, building.y - height / 2 + 5, width - 10, height - 10);
      this.unitLayer.fillStyle(0x07101a, opacity).fillRect(building.x - width / 2, building.y + height / 2 - 12, width, 12);
      this.unitLayer.fillStyle(color, building.complete ? 1 : 0.35).fillRect(building.x - width / 2, building.y - height / 2, 7, height - 12);
      this.drawBuildingSymbol(building, color, opacity);
      this.unitLayer.lineStyle(this.selectedBuildings.has(building.id) ? 4 : 2, this.selectedBuildings.has(building.id) ? 0xffe66d : color, 1).strokeRect(building.x - width / 2, building.y - height / 2, width, height);
      const healthRatio = Math.max(0, Math.min(1, building.hp / building.maxHp));
      if (this.selectedBuildings.has(building.id) || healthRatio < 1) {
        const barWidth = Math.max(54, width - 12);
        const barX = building.x - barWidth / 2;
        const barY = building.y - height / 2 - 12;
        const barColor = healthRatio > 0.6 ? 0x65e39b : healthRatio > 0.3 ? 0xf2c75c : 0xff6575;
        this.unitLayer.fillStyle(0x07101a, 1).fillRect(barX, barY, barWidth, 6);
        this.unitLayer.fillStyle(barColor, 1).fillRect(barX, barY, barWidth * healthRatio, 6);
      }
       if (!building.complete) {
        const progress = 1 - building.constructionRemaining / definition.constructionTime;
        this.unitLayer.fillStyle(0xffe66d, 1).fillRect(building.x - width / 2, building.y + height / 2 + 10, width * progress, 6);
       } else if (building.queue.length) this.unitLayer.fillStyle(0xffe66d, 1).fillRect(building.x - 30, building.y + height / 2 + 10, 60 * (1 - building.queue[0].remaining / definition.productionTime), 5);
     });
    const shownPerimeters = new Set();
    this.units.filter((unit) => this.selected.has(unit.id) && unit.stance === 'defend_area' && unit.guardPosition).forEach((unit) => {
      const key = `${Math.round(unit.guardPosition.x)}:${Math.round(unit.guardPosition.y)}:${unit.guardRadius}`;
      if (shownPerimeters.has(key)) return;
      shownPerimeters.add(key);
      this.unitLayer.fillStyle(0x66d69a, 0.08).fillCircle(unit.guardPosition.x, unit.guardPosition.y, unit.guardRadius);
      this.unitLayer.lineStyle(2, 0x66d69a, 0.75).strokeCircle(unit.guardPosition.x, unit.guardPosition.y, unit.guardRadius);
      this.unitLayer.lineStyle(1, 0xa7f5c7, 0.45).strokeCircle(unit.guardPosition.x, unit.guardPosition.y, 6);
    });
    this.units.forEach((unit) => {
      const color = unit.team === 0 ? TEAM.PLAYER : TEAM.ENEMY;
      const isSelected = this.selected.has(unit.id);
      if (isSelected) this.unitLayer.lineStyle(3, 0xffe66d, 1).strokeCircle(unit.x, unit.y, 30);
      this.drawUnitSilhouette(unit, color);
      this.unitLayer.fillStyle(0x07101a, 1).fillRect(unit.x - 22, unit.y - 34, 44, 5);
      this.unitLayer.fillStyle(0x65e39b, 1).fillRect(unit.x - 22, unit.y - 34, 44 * (unit.hp / unit.maxHp), 5);
    });
  }

  drawProjectiles() {
    this.projectileLayer.clear();
    this.simulation.projectiles.forEach((projectile) => {
      const color = projectile.team === 0 ? TEAM.PLAYER : TEAM.ENEMY;
      this.projectileLayer.fillStyle(color, 0.35).fillCircle(projectile.x, projectile.y, 7);
      this.projectileLayer.fillStyle(0xfff1a6, 1).fillCircle(projectile.x, projectile.y, 3);
    });
  }

  drawBuildingSymbol(building, teamColor, opacity, graphics = this.unitLayer) {
    const x = building.x;
    const y = building.y;
    const shadow = 0x07101a;
    const detail = 0xd7e4e8;
    if (building.type === 'command_core') {
      // Same language as the rifle squad: dark silhouette, team-color armor, light markers.
      graphics.fillStyle(shadow, opacity).fillRect(x - 67, y - 57, 134, 110);
      graphics.fillStyle(teamColor, opacity).fillRect(x - 58, y - 50, 116, 91);
      graphics.fillStyle(shadow, opacity).fillRect(x - 30, y - 32, 60, 58);
      graphics.fillStyle(teamColor, opacity).fillRect(x - 21, y - 23, 42, 40);
      graphics.fillStyle(detail, opacity).fillRect(x - 7, y - 15, 14, 23);
      graphics.fillStyle(detail, opacity).fillRect(x - 42, y - 38, 24, 5).fillRect(x + 18, y - 38, 24, 5);
      graphics.fillStyle(detail, opacity).fillRect(x - 28, y + 31, 56, 5);
      return;
    }
    if (building.type === 'refinery') {
      graphics.fillStyle(shadow, opacity).fillRect(x - 53, y - 39, 106, 70);
      graphics.fillStyle(teamColor, opacity).fillRect(x - 45, y - 32, 90, 55);
      graphics.fillStyle(shadow, opacity).fillRect(x - 34, y - 24, 20, 39).fillRect(x - 7, y - 31, 22, 46);
      graphics.fillStyle(teamColor, opacity).fillCircle(x - 24, y - 24, 10).fillCircle(x + 4, y - 31, 11);
      graphics.fillStyle(detail, opacity).fillRect(x - 39, y + 12, 78, 5);
      graphics.fillStyle(detail, opacity).fillRect(x + 24, y - 32, 5, 21);
      return;
    }
    if (building.type === 'power_plant') {
      graphics.fillStyle(shadow, opacity).fillRect(x - 53, y - 39, 106, 70);
      graphics.fillStyle(teamColor, opacity).fillRect(x - 45, y - 32, 90, 55);
      graphics.fillStyle(shadow, opacity).fillTriangle(x - 18, y + 16, x, y - 24, x + 18, y + 16);
      graphics.fillStyle(detail, opacity).fillRect(x - 4, y - 14, 8, 25);
      graphics.fillStyle(detail, opacity).fillRect(x - 29, y + 12, 58, 5);
      return;
    }
      if (building.type === 'machine_shop') {
        graphics.fillStyle(shadow, opacity).fillRect(x - 70, y - 51, 140, 90);
        graphics.fillStyle(teamColor, opacity).fillRect(x - 61, y - 43, 122, 73);
        graphics.fillStyle(shadow, opacity).fillRect(x - 42, y - 32, 84, 48);
        graphics.fillStyle(detail, opacity).fillRect(x - 31, y - 22, 62, 5);
        graphics.fillStyle(detail, opacity).fillRect(x - 31, y - 10, 62, 5);
        graphics.fillStyle(teamColor, opacity).fillRect(x - 48, y + 18, 96, 6);
        graphics.fillStyle(detail, opacity).fillRect(x + 48, y - 35, 7, 48);
        return;
      }
      if (building.type === 'defense_grid') {
        graphics.fillStyle(shadow, opacity).fillRect(x - 38, y - 38, 76, 68);
        graphics.fillStyle(teamColor, opacity).fillRect(x - 32, y - 32, 64, 54);
        graphics.fillStyle(shadow, opacity).fillCircle(x, y - 5, 20);
        graphics.fillStyle(detail, opacity).fillCircle(x, y - 5, 10);
        graphics.fillStyle(teamColor, opacity).fillCircle(x, y - 5, 5);
        graphics.fillStyle(detail, opacity).fillRect(x - 3, y - 31, 6, 14);
        graphics.fillStyle(detail, opacity).fillRect(x - 25, y + 13, 50, 4);
        return;
      }
      if (building.type === 'service_depot') {
        graphics.fillStyle(shadow, opacity).fillRect(x - 53, y - 40, 106, 74);
        graphics.fillStyle(teamColor, opacity).fillRect(x - 45, y - 32, 90, 58);
        graphics.fillStyle(shadow, opacity).fillRect(x - 30, y - 22, 60, 38);
        graphics.fillStyle(detail, opacity).fillRect(x - 22, y - 13, 44, 6);
        graphics.fillStyle(detail, opacity).fillRect(x - 5, y - 25, 10, 30);
        graphics.fillStyle(teamColor, opacity).fillRect(x - 38, y + 14, 76, 5);
        return;
      }
    graphics.fillStyle(shadow, opacity).fillRect(x - 53, y - 39, 106, 70);
    graphics.fillStyle(teamColor, opacity).fillRect(x - 45, y - 32, 90, 55);
    graphics.fillStyle(shadow, opacity).fillRect(x - 18, y - 24, 36, 47);
    graphics.fillStyle(detail, opacity).fillRect(x - 11, y - 17, 22, 27);
    graphics.fillStyle(detail, opacity).fillRect(x - 35, y - 25, 16, 5).fillRect(x + 19, y - 25, 16, 5);
    graphics.fillStyle(teamColor, opacity).fillRect(x - 38, y + 12, 76, 5);
  }

  drawUnitSilhouette(unit, teamColor) {
    const graphics = this.unitLayer;
    const shadow = 0x09111c;
    if (unit.type === 'harvester') {
      const direction = Math.cos(unit.facing ?? 0) < 0 ? -1 : 1;
      const rect = (x, y, width, height, color) => {
        const left = direction === 1 ? unit.x + x : unit.x - x - width;
        graphics.fillStyle(color, 1).fillRect(left, unit.y + y, width, height);
      };
      graphics.fillStyle(shadow, 1).fillRect(unit.x - 27, unit.y - 16, 54, 32);
      rect(-22, -11, 29, 22, 0xf2c75c);
      rect(7, -13, 15, 26, 0xd29c3c);
      rect(10, -9, 9, 8, teamColor);
      graphics.fillStyle(shadow, 1).fillCircle(unit.x - 16, unit.y + 16, 7).fillCircle(unit.x + 16, unit.y + 16, 7);
      graphics.lineStyle(2, teamColor, 1).lineBetween(unit.x + direction * 7, unit.y - 12, unit.x + direction * 7, unit.y + 12);
      return;
    }
     if (unit.type === 'scout_bike') {
      graphics.fillStyle(shadow, 1).fillCircle(unit.x - 14, unit.y + 9, 9).fillCircle(unit.x + 14, unit.y + 9, 9);
      graphics.fillStyle(teamColor, 1).fillTriangle(unit.x - 22, unit.y + 7, unit.x, unit.y - 13, unit.x + 22, unit.y + 7);
      graphics.fillStyle(0xd7e4e8, 1).fillRect(unit.x - 3, unit.y - 12, 6, 12);
      graphics.lineStyle(2, teamColor, 1).lineBetween(unit.x - 18, unit.y + 7, unit.x + 18, unit.y + 7);
       return;
     }
     if (unit.type === 'light_tank') {
       graphics.fillStyle(shadow, 1).fillRect(unit.x - 27, unit.y - 18, 54, 36);
       graphics.fillStyle(teamColor, 1).fillRect(unit.x - 22, unit.y - 13, 44, 25);
       graphics.fillStyle(shadow, 1).fillRect(unit.x - 12, unit.y - 19, 24, 22);
       graphics.fillStyle(teamColor, 1).fillCircle(unit.x, unit.y - 8, 10);
       graphics.fillStyle(0xd7e4e8, 1).fillRect(unit.x + 8, unit.y - 10, 22, 5);
       graphics.fillStyle(shadow, 1).fillCircle(unit.x - 19, unit.y + 17, 6).fillCircle(unit.x + 19, unit.y + 17, 6);
       return;
     }
      if (unit.type === 'rocket_team') {
       graphics.fillStyle(shadow, 1).fillRect(unit.x - 20, unit.y - 16, 40, 31);
       graphics.fillStyle(teamColor, 1).fillRect(unit.x - 15, unit.y - 11, 30, 21);
       graphics.fillStyle(0xd7e4e8, 1).fillCircle(unit.x - 8, unit.y - 5, 4).fillCircle(unit.x + 3, unit.y - 5, 4);
       graphics.fillStyle(0xf2c75c, 1).fillRect(unit.x + 9, unit.y - 15, 5, 25);
        return;
      }
      if (unit.type === 'siege_tank') {
        graphics.fillStyle(shadow, 1).fillRect(unit.x - 30, unit.y - 20, 60, 40);
        graphics.fillStyle(teamColor, 1).fillRect(unit.x - 24, unit.y - 14, 48, 27);
        graphics.fillStyle(shadow, 1).fillCircle(unit.x - 2, unit.y - 7, 13);
        graphics.fillStyle(teamColor, 1).fillCircle(unit.x - 2, unit.y - 7, 8);
        graphics.fillStyle(0xd7e4e8, 1).fillRect(unit.x + 5, unit.y - 10, 28, 6);
        graphics.fillStyle(shadow, 1).fillCircle(unit.x - 21, unit.y + 19, 6).fillCircle(unit.x + 21, unit.y + 19, 6);
        return;
      }
      if (unit.type === 'assault_trooper') {
        graphics.fillStyle(shadow, 1).fillRect(unit.x - 19, unit.y - 17, 38, 34);
        graphics.fillStyle(teamColor, 1).fillRect(unit.x - 14, unit.y - 12, 28, 24);
        graphics.fillStyle(0xd7e4e8, 1).fillCircle(unit.x - 7, unit.y - 6, 4).fillCircle(unit.x + 5, unit.y - 6, 4);
        graphics.fillStyle(0xf2c75c, 1).fillRect(unit.x + 11, unit.y - 11, 13, 4);
        return;
      }
    // Rifle squad: a compact armored formation with three soldier markers.
    graphics.fillStyle(shadow, 1).fillRect(unit.x - 23, unit.y - 16, 46, 32);
    graphics.fillStyle(teamColor, 1).fillRect(unit.x - 18, unit.y - 11, 36, 22);
    graphics.fillStyle(0xd7e4e8, 1).fillRect(unit.x - 12, unit.y - 6, 5, 12).fillRect(unit.x - 2, unit.y - 6, 5, 12).fillRect(unit.x + 8, unit.y - 6, 5, 12);
    graphics.lineStyle(2, 0x07101a, 1).strokeRect(unit.x - 18, unit.y - 11, 36, 22);
  }

  updateUi() {
     const alivePlayer = this.units.filter((u) => u.team === 0).length;
    const aliveEnemy = this.units.filter((u) => u.team === 1).length;
    this.helpText.setText(this.isTouchDevice()
      ? 'Tap to select • tap ground to move • tap enemy to attack • drag empty space to pan • pinch to zoom'
      : 'Drag to select • right-click to move/attack • B build refinery • P produce • WASD/arrows to pan • wheel to zoom');
    this.statusText.setText(`${this.message}   |   Blue: ${alivePlayer}   Red: ${aliveEnemy}`);
    const selectedUnits = [...this.selected].map((id) => this.getUnit(id)).filter(Boolean);
    const { width } = this.uiSize();
     const metal = Math.floor(this.simulation.resources[0]);
     const playerState = this.simulation.getPlayerState(0);
     this.hudText.sidebarCredit.setText(`${metal.toLocaleString()} CREDITS`);
      const powerStatus = playerState.lowPower ? 'LOW' : 'ONLINE';
      this.hudText.sidebarPower.setText(`POWER ${playerState.generated}/${playerState.consumed}  ${powerStatus}`);
     this.hudText.resources.setText('');
      this.sidebarSections.infantry.row.setText(`RIFLE SQUAD // ${this.units.filter((unit) => unit.team === 0 && unit.type === 'rifle_squad').length}`);
      const unitLabels = { rifle_squad: 'RIFLE SQUAD', scout_bike: 'SCOUT BIKE', harvester: 'HARVESTER' };
      this.unitEntries.forEach((entry, index) => {
       const type = ['rifle_squad', 'scout_bike', 'harvester'][index];
       const count = this.units.filter((unit) => unit.team === 0 && unit.type === type).length;
       entry.setText(`${unitLabels[type].padEnd(13, ' ')} ${count}   SUP ${type === 'harvester' ? 2 : 1}`);
       const card = this.unitCards.find((candidate) => candidate.type === type);
       if (card) card.text.setText(`${unitLabels[type]}  [${count}]`);
      });
     const selectedBuilding = this.simulation.buildings.find((building) => this.selectedBuildings.has(building.id));
     this.hudText.selection.setText(selectedBuilding ? `${selectedBuilding.name.toUpperCase()}   HP ${Math.round(selectedBuilding.hp / selectedBuilding.maxHp * 100)}%   QUEUE ${selectedBuilding.queue.length}` : selectedUnits.length ? `${selectedUnits.length} × ${selectedUnits[0].name ?? 'RIFLE SQUAD'}   HP ${Math.round(selectedUnits.reduce((sum, unit) => sum + unit.hp, 0) / selectedUnits.length)}%` : 'NO UNIT SELECTED');
     if (this.placement.active && (width < 700 || this.isTouchDevice())) {
       const type = this.placement.selected;
       this.hudText.selection.setText(`PLACE ${BUILDING_TYPES[type].name.toUpperCase()}   •   ${BUILDING_TYPES[type].cost} METAL`);
       const location = describePlacement(this.simulation, type, this.buildPreviewPosition);
       this.mobilePlacementStatus.setText(location?.message ?? 'TAP A LOCATION TO BUILD')
         .setColor(location && !location.valid ? '#ffc0c5' : '#a7f5c7');
     }
     this.hudText.hint.setText(this.placement.active ? `CONSTRUCTION: ${this.buildType.toUpperCase()} // 1 REFINERY  2 BARRACKS` : this.commandMode ? `${this.commandMode.toUpperCase()} MODE ACTIVE` : this.message);
     const ended = this.simulation.gameState !== 'playing';
     this.gameOverPanel.setVisible(ended);
     this.gameOverTitle.setVisible(ended).setText(this.simulation.gameState === 'victory' ? 'MISSION COMPLETE' : 'MISSION FAILED');
      this.gameOverDetail.setVisible(ended).setText(this.simulation.gameOverReason ?? 'TACTICAL LINK LOST');
      this.restartButton.setVisible(ended);
      this.restartButtonText.setVisible(ended);
      const paused = this.isPaused && !ended;
      this.pausePanel.setVisible(paused);
      this.pauseTitle.setVisible(paused);
      this.pauseDetail.setVisible(paused);
      this.pauseResume.setVisible(paused);
      this.pauseResumeText.setVisible(paused);
      this.pauseRestart.setVisible(paused);
      this.pauseRestartText.setVisible(paused);
      this.pauseSave.setVisible(paused);
      this.pauseSaveText.setVisible(paused);
      this.pauseLoad.setVisible(paused);
      this.pauseLoadText.setVisible(paused);
      this.drawHud();
  }

  layoutUi() {
    const { width, height } = this.uiSize();
    const mobile = width < 700 || this.isTouchDevice();
    if (mobile) {
      this.layoutMobileUi();
      return;
    }
    this.mobileMenuButton.setVisible(false);
    this.mobileMenuText.setVisible(false);
    this.mobilePauseButton.setVisible(false);
    this.mobilePauseText.setVisible(false);
    this.mobilePlacementStatus.setVisible(false);
    this.mobilePlacementHint.setVisible(false);
    this.mobilePageText.setVisible(false);
    this.mobilePagerButtons.forEach((button) => {
      button.background.setVisible(false);
      button.text.setVisible(false);
    });
    this.commandButtons.forEach((button) => {
      button.background.setVisible(true);
      button.text.setVisible(true).setText(
        button.action === 'defend' ? 'DEFEND AREA' : button.action === 'select_all' ? 'SELECT ALL' : button.action.toUpperCase()
      );
    });
    const bottomHeight = mobile ? 145 : 165;
    const bottomTop = height - bottomHeight;
    const sidebar = this.sidebarLayout();
    const playWidth = sidebar.left;
    this.helpText.setX(Math.max(12, (width - this.helpText.width) / 2));
    this.statusText.setX(18);
    this.hudText.title.setVisible(false);
    this.hudText.resources.setVisible(false);
    this.hudText.intel.setVisible(false);
    this.hudText.selection.setPosition(16, bottomTop + 14).setFontSize(mobile ? 12 : 15);
    this.hudText.hint.setPosition(16, bottomTop + bottomHeight - 26).setFontSize(12).setVisible(!mobile);
    this.hudText.sidebarCredit.setPosition(sidebar.left + 12, sidebar.creditY).setFontSize(mobile ? 10 : 12);
    this.hudText.sidebarPower.setPosition(sidebar.left + 12, sidebar.powerY).setFontSize(mobile ? 8 : 10);
    this.gameOverPanel.clear().fillStyle(0x07101a, 0.88).fillRect(0, 0, width, height);
    this.gameOverTitle.setPosition(width / 2, height / 2 - 48).setFontSize(mobile ? 20 : 28);
    this.gameOverDetail.setPosition(width / 2, height / 2 - 12).setFontSize(mobile ? 10 : 13);
    this.restartButton.setPosition(width / 2, height / 2 + 38);
    this.restartButtonText.setPosition(width / 2, height / 2 + 38);
    this.pausePanel.clear().fillStyle(0x07101a, 0.9).fillRect(0, 0, width, height);
    this.pauseTitle.setPosition(width / 2, height / 2 - 72).setFontSize(mobile ? 20 : 28);
    this.pauseDetail.setPosition(width / 2, height / 2 - 35).setFontSize(mobile ? 9 : 12);
    this.pauseResume.setPosition(width / 2, height / 2 + 8);
    this.pauseResumeText.setPosition(width / 2, height / 2 + 8);
    this.pauseRestart.setPosition(width / 2, height / 2 + 62);
    this.pauseRestartText.setPosition(width / 2, height / 2 + 62);
    this.pauseSave.setPosition(width / 2 - 66, height / 2 + 116);
    this.pauseSaveText.setPosition(width / 2 - 66, height / 2 + 116);
    this.pauseLoad.setPosition(width / 2 + 66, height / 2 + 116);
    this.pauseLoadText.setPosition(width / 2 + 66, height / 2 + 116);
     const buttonWidth = mobile ? Math.max(42, Math.floor((playWidth - 24) / this.commandButtons.length)) : 112;
    const gap = mobile ? 5 : 8;
    const buttonAreaWidth = buttonWidth * this.commandButtons.length + gap * (this.commandButtons.length - 1);
    const startX = mobile ? 12 : Math.max(24, playWidth - buttonAreaWidth - 24);
    this.commandButtons.forEach((button, index) => {
      const x = startX + index * (buttonWidth + gap) + buttonWidth / 2;
      const buttonY = bottomTop + (mobile ? 112 : 67);
      button.background.setSize(buttonWidth, 40).setPosition(x, buttonY);
      if (button.background.input?.hitArea?.setSize) button.background.input.hitArea.setSize(buttonWidth, 40);
      button.text.setPosition(x, buttonY).setFontSize(mobile ? 9 : 12);
    });
     this.buildCards.forEach((card) => {
       const cardIndex = this.buildCards.filter((candidate) => candidate.category === this.activeCategory).indexOf(card);
       const y = sidebar.cardsTop + Math.max(0, cardIndex) * (sidebar.cardHeight + 5);
      card.background.setSize(sidebar.width - 24, sidebar.cardHeight).setPosition(sidebar.left + sidebar.width / 2, y);
      if (card.background.input?.hitArea?.setSize) card.background.input.hitArea.setSize(sidebar.width - 24, sidebar.cardHeight);
      card.text.setPosition(sidebar.left + 30, y - 7).setFontSize(mobile ? 8 : 11);
      card.costText.setPosition(sidebar.left + 30, y + 9).setFontSize(mobile ? 8 : 10);
       const visible = this.activeCategory === card.category;
      card.background.setVisible(visible);
      card.text.setVisible(visible);
      card.costText.setVisible(visible);
    });
    this.unitCards.forEach((card, index) => {
      const cardTop = this.activeCategory === 'vehicles' ? sidebar.vehicleCardsTop : sidebar.unitCardsTop;
       const visibleTypes = this.activeCategory === 'infantry' ? ['rifle_squad', 'rocket_team', 'assault_trooper']
         : this.activeCategory === 'vehicles' ? ['scout_bike', 'light_tank', 'siege_tank', 'harvester'] : ['rifle_squad'];
      const cardIndex = visibleTypes.indexOf(card.type);
      const y = cardTop + Math.max(0, cardIndex) * (sidebar.unitCardHeight + 5);
      card.background.setSize(sidebar.width - 24, sidebar.unitCardHeight).setPosition(sidebar.left + sidebar.width / 2, y);
      if (card.background.input?.hitArea?.setSize) card.background.input.hitArea.setSize(sidebar.width - 24, sidebar.unitCardHeight);
      card.text.setPosition(sidebar.left + 30, y - 6).setFontSize(mobile ? 8 : 10);
      card.costText.setPosition(sidebar.left + 30, y + 9).setFontSize(mobile ? 8 : 9);
        const visible = (this.activeCategory === 'infantry' && ['rifle_squad', 'rocket_team', 'assault_trooper'].includes(card.type))
          || (this.activeCategory === 'vehicles' && ['scout_bike', 'light_tank', 'siege_tank', 'harvester'].includes(card.type));
      card.background.setVisible(visible);
      card.text.setVisible(visible);
      card.costText.setVisible(visible);
    });
    this.buildTitle.setPosition(sidebar.left + 12, sidebar.buildingsY).setFontSize(mobile ? 9 : 13);
    this.buildTabs.forEach((tab, index) => {
      const tabWidth = (sidebar.width - 24) / 2;
      const x = sidebar.left + 12 + tabWidth * index + tabWidth / 2;
      tab.background.setSize(tabWidth, sidebar.tabHeight).setPosition(x, sidebar.tabsY).setVisible(false);
      if (tab.background.input?.hitArea?.setSize) tab.background.input.hitArea.setSize(tabWidth, sidebar.tabHeight);
      tab.text.setPosition(x, sidebar.tabsY).setFontSize(mobile ? 7 : 8).setVisible(false);
      tab.background.setStrokeStyle(2, tab.tab === this.activeBuildTab ? 0xf2d27b : 0x71806d);
    });
    const tabWidth = (sidebar.width - 24) / 4;
    this.categoryTabs.forEach((tab, index) => {
      const row = Math.floor(index / 4);
      const column = index % 4;
      const x = sidebar.left + 12 + tabWidth * column + tabWidth / 2;
      const y = sidebar.categoryTabsTop + row * 25;
      tab.background.setSize(tabWidth - 2, 22).setPosition(x, y);
      if (tab.background.input?.hitArea?.setSize) tab.background.input.hitArea.setSize(tabWidth - 2, 22);
      tab.text.setPosition(x, y).setFontSize(mobile ? 10 : 12);
    });
    this.supportNotice.setPosition(sidebar.left + sidebar.width / 2, sidebar.cardsTop + sidebar.cardHeight).setVisible(false);
    this.utilityButtons.forEach((button, index) => {
      const x = sidebar.left + 12 + (sidebar.width - 24) * (index + 0.5) / this.utilityButtons.length;
      const y = sidebar.utilityTop;
      button.background.setPosition(x, y).setSize((sidebar.width - 30) / 2, 34);
      if (button.background.input?.hitArea?.setSize) button.background.input.hitArea.setSize((sidebar.width - 30) / 2, 34);
      button.text.setPosition(x, y);
    });
    Object.entries(this.sidebarSections).forEach(([key, section]) => {
      const y = sidebar.sections[key];
      section.title.setPosition(sidebar.left + 12, y).setFontSize(mobile ? 8 : 9);
      section.row.setPosition(sidebar.left + 12, y + 13).setFontSize(mobile ? 8 : 9);
    });
    this.unitEntries.forEach((entry, index) => {
      entry.setPosition(sidebar.left + 12, sidebar.sections.units + 30 + index * 18).setFontSize(mobile ? 8 : 9);
    });
    this.helpText.setVisible(false);
    this.statusText.setVisible(false);
    this.drawHud();
  }

  layoutMobileUi() {
    const { width, height } = this.uiSize();
    const layout = this.mobileHudLayout();
    const opened = this.mobilePanelOpen;
    const { drawerLeft, drawerWidth, drawerTop, drawerBottom, bottomTop,
      mapX, mapY, mapWidth, mapHeight, utilityY, utilityButtonHeight, 
      tabsY, tabHeight, titleY, cardsTop,
      cardWidth, cardHeight, cardRowHeight, rowsPerPage } = layout;

    this.hudText.title.setVisible(false);
    this.hudText.resources.setVisible(false);
    this.hudText.intel.setVisible(false);
    this.hudText.hint.setVisible(false);
    this.helpText.setVisible(false);
    this.statusText.setVisible(false);

    this.hudText.sidebarCredit.setPosition(12, 8).setFontSize(13).setVisible(true);
    this.hudText.sidebarPower.setPosition(12, 31).setFontSize(9).setVisible(true);
    this.hudText.selection.setPosition(12, bottomTop + 9).setFontSize(11)
      .setWordWrapWidth(width - 24).setVisible(true);

    const placing = this.placement.active;
    const placementHud = getPlacementHudGeometry(width, height);
    const cancel = placementHud.cancel;
    this.mobileMenuButton.setVisible(true).setPosition(cancel.x, cancel.y).setSize(cancel.width, cancel.height)
      .setFillStyle(placing ? 0x67363a : opened ? 0x5b4435 : 0x263f3b);
    if (this.mobileMenuButton.input?.hitArea?.setSize) {
      this.mobileMenuButton.input.hitArea.setSize(cancel.width, cancel.height);
    }
    this.mobileMenuText.setVisible(true).setPosition(cancel.x, cancel.y)
      .setText(placing ? 'CANCEL ×' : opened ? 'CLOSE ×' : 'BUILD ▣');
    this.mobilePauseButton.setPosition(width / 2, 27).setVisible(!this.isPaused);
    this.mobilePauseText.setPosition(width / 2, 27).setVisible(!this.isPaused);
    this.mobilePlacementStatus.setPosition(placementHud.status.x, placementHud.status.y)
      .setFontSize(width < 355 ? 10 : 11).setVisible(placing);
    this.mobilePlacementHint.setPosition(placementHud.hint.x, placementHud.hint.y)
      .setFontSize(width < 355 ? 9 : 10).setVisible(placing);

    const gap = 5;
    const buttonWidth = Math.floor((width - 20 - 4 * gap) / 5);
    this.commandButtons.forEach((button, index) => {
      const labels = { move: 'MOVE', attack: 'ATTACK', stop: 'STOP', defend: 'GUARD', select_all: 'ALL' };
      const x = 10 + buttonWidth * (index + 0.5) + index * gap;
      const y = bottomTop + 66;
      button.text.setText(labels[button.action]).setPosition(x, y).setFontSize(width < 340 ? 9 : 10);
      button.background.setSize(buttonWidth, 44).setPosition(x, y).setVisible(!placing);
      if (button.background.input?.hitArea?.setSize) button.background.input.hitArea.setSize(buttonWidth, 44);
      button.text.setVisible(!placing);
    });

    this.gameOverPanel.clear().fillStyle(0x07101a, 0.9).fillRect(0, 0, width, height);
    this.gameOverTitle.setPosition(width / 2, height / 2 - 52).setFontSize(21);
    this.gameOverDetail.setPosition(width / 2, height / 2 - 14).setFontSize(10);
    this.restartButton.setPosition(width / 2, height / 2 + 38);
    this.restartButtonText.setPosition(width / 2, height / 2 + 38);
    this.pausePanel.clear().fillStyle(0x07101a, 0.9).fillRect(0, 0, width, height);
    this.pauseTitle.setPosition(width / 2, height / 2 - 72).setFontSize(21);
    this.pauseDetail.setPosition(width / 2, height / 2 - 35).setFontSize(10);
    this.pauseResume.setPosition(width / 2, height / 2 + 8);
    this.pauseResumeText.setPosition(width / 2, height / 2 + 8);
    this.pauseRestart.setPosition(width / 2, height / 2 + 62);
    this.pauseRestartText.setPosition(width / 2, height / 2 + 62);
    this.pauseSave.setPosition(width / 2 - 66, height / 2 + 116);
    this.pauseSaveText.setPosition(width / 2 - 66, height / 2 + 116);
    this.pauseLoad.setPosition(width / 2 + 66, height / 2 + 116);
    this.pauseLoadText.setPosition(width / 2 + 66, height / 2 + 116);

    this.buildTabs.forEach((tab) => {
      tab.background.setVisible(false);
      tab.text.setVisible(false);
    });
    this.supportNotice.setVisible(false);
    this.unitEntries.forEach((entry) => entry.setVisible(false));
    Object.values(this.sidebarSections).forEach((section) => {
      section.title.setVisible(false);
      section.row.setVisible(false);
    });
    this.buildTitle.setVisible(opened).setPosition(drawerLeft + 12, titleY).setFontSize(14);
    this.categoryTabs.forEach((tab, index) => {
      const slotWidth = (drawerWidth - 24) / 6;
      const x = drawerLeft + 12 + slotWidth * (index + 0.5);
      tab.background.setSize(slotWidth - 5, tabHeight).setPosition(x, tabsY).setVisible(opened);
      if (tab.background.input?.hitArea?.setSize) tab.background.input.hitArea.setSize(slotWidth - 5, tabHeight);
      tab.text.setPosition(x, tabsY).setFontSize(15).setVisible(opened);
      tab.background.setStrokeStyle(2, tab.key === this.activeCategory ? 0xf2d27b : 0x71806d);
    });
    this.utilityButtons.forEach((button, index) => {
      const availableWidth = drawerWidth - (mapX - drawerLeft) - mapWidth - 24;
      const x = mapX + mapWidth + 12 + availableWidth / 2;
      const y = utilityY + (index === 0 ? -(utilityButtonHeight + 4) / 2 : (utilityButtonHeight + 4) / 2);
      button.background.setSize(availableWidth, utilityButtonHeight).setPosition(x, y).setVisible(opened);
      if (button.background.input?.hitArea?.setSize) button.background.input.hitArea.setSize(availableWidth, utilityButtonHeight);
      button.text.setPosition(x, y).setFontSize(mapHeight < 50 ? 10 : 12).setVisible(opened);
    });

    const allVisible = this.mobileAvailableCards();
    const pageSize = rowsPerPage * 2;
    const pages = Math.max(1, Math.ceil(allVisible.length / pageSize));
    this.mobileCardPage = Math.min(this.mobileCardPage, pages - 1);
    const current = allVisible.slice(this.mobileCardPage * pageSize, (this.mobileCardPage + 1) * pageSize);
    const positionCard = (card, list) => {
      const index = list.indexOf(card);
      const visible = opened && index >= 0;
      const x = drawerLeft + 12 + (index % 2) * (cardWidth + 10) + cardWidth / 2;
      const y = cardsTop + Math.floor(index / 2) * cardRowHeight;
      card.background.setVisible(visible);
      card.text.setVisible(visible);
      card.costText.setVisible(visible);
      if (!visible) return;
      card.background.setSize(cardWidth, cardHeight).setPosition(x, y);
      if (card.background.input?.hitArea?.setSize) card.background.input.hitArea.setSize(cardWidth, cardHeight);
      card.text.setPosition(x - cardWidth / 2 + 9, y - 9).setFontSize(width < 340 ? 9 : 10);
      card.costText.setPosition(x - cardWidth / 2 + 9, y + 10).setFontSize(9);
    };
    this.buildCards.forEach((card) => positionCard(card, current));
    this.unitCards.forEach((card) => positionCard(card, current));
    const showPager = opened && pages > 1;
    this.mobilePagerButtons.forEach((button, index) => {
      const x = width / 2 + (index === 0 ? -95 : 95);
      const y = drawerBottom - (layout.pagerHeight / 2) - 5;
      button.background.setPosition(x, y).setVisible(showPager).setAlpha(
        index === 0 ? (this.mobileCardPage === 0 ? 0.45 : 1) : (this.mobileCardPage === pages - 1 ? 0.45 : 1));
      button.text.setPosition(x, y).setVisible(showPager);
    });
    this.mobilePageText.setPosition(width / 2, drawerBottom - (layout.pagerHeight / 2) - 5)
      .setText(`${this.mobileCardPage + 1} / ${pages}`).setVisible(showPager);
    this.drawHud();
  }

  drawHud() {
    if (!this.hud) return;
    const { width, height } = this.uiSize();
    const mobile = width < 700 || this.isTouchDevice();
    if (mobile) {
      this.drawMobileHud();
      return;
    }
    const bottomHeight = 165;
    const bottomTop = height - bottomHeight;
    const sidebar = this.sidebarLayout();
    this.hud.clear();
    this.hud.fillStyle(0x11191b, 0.98).fillRect(0, bottomTop, sidebar.left, bottomHeight);
    this.hud.lineStyle(2, 0x6f7b5d, 1).lineBetween(0, bottomTop, sidebar.left, bottomTop);
    this.buildPanel.clear();
    this.buildPanel.fillStyle(0x11191b, 0.98).fillRect(sidebar.left, sidebar.top, sidebar.width, sidebar.height);
    this.buildPanel.lineStyle(2, 0x6f7b5d, 1).strokeRect(sidebar.left, sidebar.top, sidebar.width, sidebar.height);
    this.buildPanel.lineStyle(1, 0x3d5148, 1).lineBetween(sidebar.left + 12, sidebar.top + 30, sidebar.left + sidebar.width - 12, sidebar.top + 30);
    this.buildPanel.fillStyle(0x1e3030, 1).fillRect(sidebar.mapX, sidebar.mapY, sidebar.mapWidth, sidebar.mapHeight);
    this.buildPanel.lineStyle(2, 0xa89a58, 1).strokeRect(sidebar.mapX, sidebar.mapY, sidebar.mapWidth, sidebar.mapHeight);
    this.units.forEach((unit) => {
      const color = unit.team === 0 ? TEAM.PLAYER : TEAM.ENEMY;
      const dot = unit.type === 'harvester' ? 5 : 4;
      this.buildPanel.fillStyle(unit.type === 'harvester' ? 0xf2c75c : color, 1).fillRect(sidebar.mapX + (unit.x / 2400) * sidebar.mapWidth - dot / 2, sidebar.mapY + (unit.y / 1500) * sidebar.mapHeight - dot / 2, dot, dot);
    });
    this.simulation.buildings.forEach((building) => {
      const color = building.team === 0 ? TEAM.PLAYER : TEAM.ENEMY;
      this.buildPanel.fillStyle(color, 1).fillRect(sidebar.mapX + (building.x / 2400) * sidebar.mapWidth - 3, sidebar.mapY + (building.y / 1500) * sidebar.mapHeight - 3, 6, 6);
    });
    this.buildPanel.lineStyle(1, 0x3d5148, 1).lineBetween(sidebar.left + 12, sidebar.powerY - 8, sidebar.left + sidebar.width - 12, sidebar.powerY - 8);
     const playerState = this.simulation.getPlayerState(0);
     const powerRatio = Phaser.Math.Clamp(playerState.powerRatio, 0, 1);
     this.buildPanel.fillStyle(0x26343b, 1).fillRect(sidebar.left + 12, sidebar.powerY + 14, sidebar.width - 24, 7);
     this.buildPanel.fillStyle(playerState.lowPower ? 0xff6575 : powerRatio < 1 ? 0xf2c75c : 0x54b7ff, 1).fillRect(sidebar.left + 12, sidebar.powerY + 14, (sidebar.width - 24) * powerRatio, 7);
    this.buildCards.forEach((card) => card.background.setStrokeStyle(2, card.type === this.buildType ? 0xf2d27b : 0x71806d));
    this.buildTabs.forEach((tab) => tab.background.setStrokeStyle(2, tab.tab === this.activeBuildTab ? 0xf2d27b : 0x71806d));
  }

  drawMobileHud() {
    const { width, height } = this.uiSize();
    const layout = this.mobileHudLayout();
    this.hud.clear();
    this.hud.fillStyle(0x11191b, 0.97).fillRect(0, 0, width, layout.topBarHeight);
    this.hud.lineStyle(2, 0x6f7b5d, 1).lineBetween(0, layout.topBarHeight, width, layout.topBarHeight);
    this.hud.fillStyle(0x11191b, 0.97).fillRect(0, layout.bottomTop, width, height - layout.bottomTop);
    this.hud.lineStyle(2, 0x6f7b5d, 1).lineBetween(0, layout.bottomTop, width, layout.bottomTop);
    this.buildPanel.clear();
    if (this.mobilePanelOpen) {
      this.buildPanel.fillStyle(0x11191b, 0.99).fillRect(layout.drawerLeft, layout.drawerTop, layout.drawerWidth, layout.drawerBottom - layout.drawerTop);
      this.buildPanel.lineStyle(2, 0x8a8559, 1).strokeRect(layout.drawerLeft, layout.drawerTop, layout.drawerWidth, layout.drawerBottom - layout.drawerTop);
      this.buildPanel.fillStyle(0x1e3030, 1).fillRect(layout.mapX, layout.mapY, layout.mapWidth, layout.mapHeight);
      this.buildPanel.lineStyle(2, 0xa89a58, 1).strokeRect(layout.mapX, layout.mapY, layout.mapWidth, layout.mapHeight);
      this.units.forEach((unit) => {
        const dot = unit.type === 'harvester' ? 5 : 4;
        this.buildPanel.fillStyle(unit.type === 'harvester' ? 0xf2c75c : unit.team === 0 ? TEAM.PLAYER : TEAM.ENEMY, 1)
          .fillRect(layout.mapX + unit.x / WORLD.width * layout.mapWidth - dot / 2,
            layout.mapY + unit.y / WORLD.height * layout.mapHeight - dot / 2, dot, dot);
      });
      this.simulation.buildings.forEach((building) => {
        this.buildPanel.fillStyle(building.team === 0 ? TEAM.PLAYER : TEAM.ENEMY, 1)
          .fillRect(layout.mapX + building.x / WORLD.width * layout.mapWidth - 3,
            layout.mapY + building.y / WORLD.height * layout.mapHeight - 3, 6, 6);
      });
      this.buildCards.forEach((card) => card.background.setStrokeStyle(2, card.type === this.buildType ? 0xf2d27b : 0x71806d));
    }
  }

  sidebarLayout() {
    const { width, height } = this.uiSize();
    return sidebarLayout(width, height, width < 700 || this.isTouchDevice());
  }}

