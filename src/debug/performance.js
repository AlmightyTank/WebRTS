export class PerformanceMonitor {
  constructor(windowSize = 120) {
    this.windowSize = windowSize;
    this.samples = [];
    this.slowFrames = 0;
    this.maxFrameMs = 0;
  }
  record(deltaMs) {
    if (!Number.isFinite(deltaMs) || deltaMs < 0) return;
    this.samples.push(deltaMs);
    if (this.samples.length > this.windowSize) this.samples.shift();
    this.maxFrameMs = Math.max(this.maxFrameMs, deltaMs);
    if (deltaMs > 50) this.slowFrames++;
  }
  summary(simulation) {
    const mean = this.samples.length ? this.samples.reduce((a, b) => a + b, 0) / this.samples.length : 0;
    return {
      fps: mean ? Math.round(1000 / mean) : 0,
      avgFrameMs: Math.round(mean * 10) / 10,
      maxFrameMs: Math.round(this.maxFrameMs * 10) / 10,
      slowFrames: this.slowFrames, units: simulation.units.length,
      buildings: simulation.buildings.length,
      projectiles: simulation.projectiles.length,
      commands: simulation.commandQueue.length, tick: simulation.tick,
      hash: simulation.getStateHash()
    };
  }
}

export function debugScenario(name) {
  if (name === 'unit_stress') return { units: 60, spacing: 36, columns: 10 };
  if (name === 'pathing') return { units: 25, spacing: 54, columns: 5 };
  if (name === 'baseline') return { units: 0, spacing: 40, columns: 10 };
  throw new TypeError('Unknown debug scenario');
}
