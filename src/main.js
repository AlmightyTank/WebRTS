import Phaser from 'phaser';
import './style.css';
import { Battlefield } from './scenes/Battlefield.js';

const game = new Phaser.Game({
  type: Phaser.AUTO,
  parent: 'game-container',
  backgroundColor: '#101a2a',
  scale: { mode: Phaser.Scale.RESIZE, width: '100%', height: '100%' },
  render: { antialias: true, roundPixels: true },
  scene: [Battlefield]
});

// Browser acceptance tests can inspect the real scene without altering the
// production game. Vite compiles this branch out unless mode=e2e.
if (import.meta.env.MODE === 'e2e') {
  window.__WEBRTS_E2E__ = () => game.scene.getScene('battlefield');
}
