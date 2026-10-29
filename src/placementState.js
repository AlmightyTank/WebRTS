// The active building is either a single type or null.
export class PlacementState {
  constructor(buildings, preferred = 'refinery') {
    this.buildings = buildings;
    if (!Object.hasOwn(buildings, preferred)) throw new Error('Unknown default building');
    this.preferred = preferred;
    this.selected = null;
  }
  get active() { return this.selected !== null; }
  get type() { return this.selected ?? this.preferred; }
  prefer(type) {
    if (!Object.hasOwn(this.buildings, type)) return false;
    this.preferred = type;
    if (this.active) this.selected = type;
    return true;
  }
  begin(type = this.preferred) {
    if (!this.prefer(type)) return false;
    this.selected = type;
    return true;
  }
  cancel() {
    if (!this.active) return false;
    this.selected = null;
    return true;
  }
  finish() { return this.cancel(); }
}

// Prevents a UI pointer gesture from triggering a world action as the UI closes.
export class UiPointerGate {
  constructor() { this.blocked = false; }
  get active() { return this.blocked; }
  block() { this.blocked = true; }
  release() {
    if (!this.blocked) return false;
    this.blocked = false;
    return true;
  }
}
