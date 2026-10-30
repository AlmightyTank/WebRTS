# Repository setup, reproducible builds, and VPS deployment

WebRTS v0.2 Slice A removes generated files from Git. Dependency installation
uses the committed `package-lock.json`; `dist/` and `node_modules/` are
generated locally and must **not** be committed.

## Prerequisites

- Git
- Node.js 22.12 or newer (Node.js 22 LTS recommended; CI uses Node 22)
- npm bundled with Node
- For browser playtests in CI: Chromium installed by Playwright
- No database or game server is currently needed to run the local prototype;
  multiplayer server setup will be added in later roadmap versions.

## Start the game locally (desktop or mobile)

```bash
git clone https://github.com/AlmightyTank/WebRTS.git
cd WebRTS
npm ci
npm run dev
```

Open the URL printed by Vite in a desktop browser. For a phone on the **same
trusted Wi-Fi network**, run `npm run dev -- --host 0.0.0.0` and use the
computer's LAN IP and the printed Vite port. Do not expose a development
server directly to the public internet.

## Validate changes before merging

```bash
npm ci
npm test
npm run build
```

- `npm ci` installs exactly from the lockfile and replaces existing
  `node_modules` rather than modifying the dependency graph.
- `npm test` covers simulation, building placement, input geometry, and
  repository hygiene (including checks that generated artifacts are untracked).
- `npm run build` produces a fresh `dist/` directory.
- GitHub Actions also runs separate Chromium desktop and touchscreen
  placement playtests. Its screenshot artifact is named
  `placement-browser-screenshots`.

If dependencies intentionally change, update **both** `package.json` and
`package-lock.json` with npm, review the lockfile diff, then rerun CI.
Do not commit `node_modules/`, `dist/`, `.env`, logs or test output.

## Deploy the static site on the VPS

The repository is known as `AlmightyTank/WebRTS`. Earlier deployment
examples used `~/apps/WebRTS` for checkout and `/var/www/webrts/` as the
web root; those exact paths have **not** been verified on the live VPS.
Confirm the actual paths before copying anything.

```bash
# First inspect the Nginx server block and its effective document root.
sudo nginx -T 2>/dev/null | grep -n -A 30 -B 5 'server_name ts.streetsempire.dev'

# Use the existing verified local checkout path:
cd ~/apps/WebRTS
git fetch origin
git switch main
git pull --ff-only origin main
npm ci
npm test
npm run build

# Replace /VERIFIED/NGINX/WEB/ROOT with the real static site root.
sudo cp -a dist/. /VERIFIED/NGINX/WEB/ROOT/
sudo nginx -t
```

Nginx can serve the new static assets without a game-process restart when
its document root already points to the copied files. Check
`https://ts.streetsempire.dev/` and perform a hard refresh to bypass an
old cached asset version. If an asset or route remains stale, inspect
caching and the site's Nginx configuration before changing server settings.

## Troubleshooting

| Problem | Check |
| --- | --- |
| `npm ci` fails with lock mismatch | Regenerate and commit a reviewed lockfile together with package.json |
| `npm run build` reports EACCES | Check ownership of checkout/`dist`; build as deploy user, not via sudo |
| Site still shows old game | Confirm Nginx `root`, copied `dist/index.html`, CDN/browser cache and build hash |
| Touch controls work in CI, not phone | Compare device/browser version and report screenshot plus touch/rotation steps |
| Browser test CI fails | Open `browser-playtest` job logs and screenshot artifacts |
