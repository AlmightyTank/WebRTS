import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { execFileSync } from 'node:child_process';

const pkg = JSON.parse(readFileSync(new URL('../package.json', import.meta.url), 'utf8'));
const lock = JSON.parse(readFileSync(new URL('../package-lock.json', import.meta.url), 'utf8'));
const ignore = readFileSync(new URL('../.gitignore', import.meta.url), 'utf8');

test('locked direct dependencies match the manifest exactly', () => {
  assert.equal(lock.lockfileVersion, 3);
  assert.deepEqual(lock.packages[''].dependencies, pkg.dependencies);
  assert.deepEqual(lock.packages[''].devDependencies, pkg.devDependencies);
  assert.deepEqual(lock.packages[''].engines, pkg.engines);
  for (const [name, version] of Object.entries({ ...pkg.dependencies, ...pkg.devDependencies })) {
    assert.match(version, /^\\d+\\.\\d+\\.\\d+$/, name + ' should have an exact version');
    assert.equal(lock.packages['node_modules/' + name]?.version, version);
  }
});

test('local dependencies, build outputs and environment files are ignored', () => {
  for (const file of [
    'node_modules/.cache/example.js', 'dist/assets/game.js', 'build/index.html',
    'coverage/report.html', 'test-results/screenshot.png', '.env.local'
  ]) {
    const output = execFileSync('git', ['check-ignore', '--no-index', file], { encoding: 'utf8' }).trim();
    assert.equal(output, file, file + ' must be ignored');
  }
  assert.match(ignore, /^!\\.env\\.example$/m);
});

test('tracked repository content excludes generated directories and secrets', () => {
  const tracked = execFileSync('git', ['ls-files', '-z'], { encoding: 'utf8' })
    .split('\\0').filter(Boolean);
  assert.ok(tracked.includes('package-lock.json'), 'committed lockfile required');
  assert.ok(tracked.includes('.gitignore'), 'committed ignore rules required');
  const unwanted = tracked.filter(path =>
    /^(?:node_modules|dist|build|coverage|test-results|playwright-report)\\//.test(path)
    || /^(?:\\.env|npm-debug\\.log)/.test(path));
  assert.deepEqual(unwanted, [], 'generated files must not be committed');
});
