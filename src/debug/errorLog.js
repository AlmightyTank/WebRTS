export class RuntimeErrorLog {
  constructor(limit = 12) {
    this.limit = limit;
    this.items = [];
  }
  record(error, category = 'runtime') {
    const message = String(error?.message ?? error ?? 'Unknown error')
      .replace(/[\r\n\t]+/g, ' ').slice(0, 180);
    const entry = { category: String(category).slice(0, 20), message };
    this.items.push(entry);
    if (this.items.length > this.limit) this.items.shift();
    return entry;
  }
}
