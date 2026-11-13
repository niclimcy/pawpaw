// Renders the Paw Paw App Store featuring artwork (Header and Search Results).
//   node render-artwork.mjs
// Each asset is rendered at every supported size, with and without the title
// text (App Store editorial often sets its own text over the artwork), then
// flattened to an opaque sRGB PNG with ImageMagick.

import { execFileSync } from 'node:child_process';
import { createServer } from 'node:http';
import { cpSync, existsSync, mkdirSync, readFileSync, readdirSync, writeFileSync } from 'node:fs';
import { homedir } from 'node:os';
import { dirname, extname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { chromium } from 'playwright-core';

const root = dirname(fileURLToPath(import.meta.url));
const assetCatalog = resolve(root, '../pawpaw/Assets.xcassets');

// Bump whenever the artwork changes, so uploads don't clash with older files.
export const VERSION = 2;

export const ARTWORK = {
  header: [[5244, 2950], [3840, 1646]],
  search: [[5244, 2950], [3840, 2560], [1920, 1280]],
  // Link preview for the marketing site: site/assets/og-image.jpg.
  og: [[1200, 630]],
};

// Same artwork and font as render.mjs.
mkdirSync(join(root, 'assets'), { recursive: true });
mkdirSync(join(root, 'font'), { recursive: true });
for (const entry of readdirSync(assetCatalog)) {
  if (!entry.endsWith('.imageset')) continue;
  const name = entry.replace('.imageset', '');
  const svg = join(assetCatalog, entry, `${name}.svg`);
  if (existsSync(svg)) cpSync(svg, join(root, 'assets', `${name}.svg`));
}
cpSync('/System/Library/Fonts/SFNSRounded.ttf', join(root, 'font/rounded.ttf'));
const outDir = join(root, 'out/artwork');
mkdirSync(outDir, { recursive: true });

const types = { '.html': 'text/html', '.js': 'text/javascript', '.mjs': 'text/javascript', '.svg': 'image/svg+xml', '.ttf': 'font/ttf' };
const server = createServer((req, res) => {
  const path = join(root, decodeURIComponent(new URL(req.url, 'http://x').pathname));
  if (!path.startsWith(root) || !existsSync(path)) { res.writeHead(404).end(); return; }
  res.writeHead(200, { 'content-type': types[extname(path)] ?? 'application/octet-stream' }).end(readFileSync(path));
});
await new Promise((ok) => server.listen(0, '127.0.0.1', ok));
const base = `http://127.0.0.1:${server.address().port}/artwork.html`;

const chromePath = readdirSync(join(homedir(), 'Library/Caches/ms-playwright'))
  .filter((d) => d.startsWith('chromium_headless_shell'))
  .map((d) => join(homedir(), 'Library/Caches/ms-playwright', d, 'chrome-headless-shell-mac-arm64/chrome-headless-shell'))
  .find(existsSync);
const browser = await chromium.launch({ executablePath: chromePath });
const page = await browser.newPage({ viewport: { width: 800, height: 600 } });
page.on('console', (m) => console.log(`[page] ${m.text()}`));
page.on('pageerror', (e) => console.error(`[page error] ${e.message}`));

for (const [kind, sizes] of Object.entries(ARTWORK)) {
  for (const [w, h] of sizes) {
    for (const text of [true, false]) {
      await page.goto(`${base}?kind=${kind}&w=${w}&h=${h}&text=${text ? 1 : 0}`);
      await page.evaluate(() => window.artwork.ready);
      const b64 = await page.evaluate(() => window.artwork.png());
      const file = join(outDir, `pawpaw-${kind}-${w}x${h}${text ? '' : '-notext'}-v${VERSION}.png`);
      writeFileSync(file, Buffer.from(b64, 'base64'));
      // App Store artwork must be opaque RGB.
      execFileSync('magick', [file, '-background', '#291a0f', '-alpha', 'remove', '-alpha', 'off', '-colorspace', 'sRGB', '-strip', `PNG24:${file}`]);
      console.log(file);
    }
  }
}

await browser.close();
server.close();
