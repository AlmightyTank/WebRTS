import Phaser from 'phaser';
import './style.css';
import { Battlefield } from './scenes/Battlefield.js';
import { renderDensity, gamePixels } from './engine/hiDpi.js';

const container = document.getElementById('game-container');
const viewWidth = Math.max(1, container.clientWidth);
const viewHeight = Math.max(1, container.clientHeight);
// Favor true device pixels for crisp mobile text and vectors. Large desktop
// windows keep a smaller fill-rate budget, and ?quality=balanced is available
// as a mobile fallback if a device struggles with native-density rendering.
const isSmallScreen = Math.min(viewWidth, viewHeight) < 700;
const graphicsQuality = new URLSearchParams(window.location.search).get('quality');
const pixelBudget = graphicsQuality === 'balanced' ? 2600000 : isSmallScreen ? 5500000 : 3000000;
const density = renderDensity(viewWidth, viewHeight, window.devicePixelRatio || 1, pixelBudget);

// Use a physical-size backing canvas and inverse CSS zoom. The scene's
// cameras maintain original logical coordinates for UI and world entities.
const game = new Phaser.Game({
  type: Phaser.AUTO,
  parent: 'game-container',
  backgroundColor: '#101a2a',
  scale: {
    mode: Phaser.Scale.NONE,
    width: gamePixels(viewWidth, density),
    height: gamePixels(viewHeight, density),
    zoom: 1 / density
  },
  render: { antialias: true, roundPixels: true },
  scene: [Battlefield]
});

const observer = new ResizeObserver(() => {
  const width = gamePixels(Math.max(1, container.clientWidth), density);
  const height = gamePixels(Math.max(1, container.clientHeight), density);
  if (game.scale.width !== width || game.scale.height !== height) {
    game.scale.resize(width, height);
  }
});
observer.observe(container);

// Browser acceptance tests can inspect the real scene without altering the
// production game. Vite compiles this branch out unless mode=e2e.
if (import.meta.env.MODE === 'e2e') {
  window.__WEBRTS_E2E__ = () => game.scene.getScene('battlefield');
}
