// Renders the Paw Paw App Store preview.
//   node render.mjs [iphone|ipad] [--still=<seconds>]
// Steps through the animation one frame at a time in headless Chromium,
// pipes the frames to ffmpeg, and muxes in the synthesized soundtrack.

import { spawn, execFileSync } from 'node:child_process';
import { createServer } from 'node:http';
import { cpSync, existsSync, mkdirSync, readFileSync, readdirSync, writeFileSync } from 'node:fs';
import { homedir } from 'node:os';
import { dirname, extname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { chromium } from 'playwright-core';
import { FPS, DURATION } from './timeline.js';

const root = dirname(fileURLToPath(import.meta.url));
const assetCatalog = resolve(root, '../pawpaw/Assets.xcassets');
const size = process.argv.find((a) => a === 'iphone' || a === 'ipad') ?? 'iphone';
const stillArg = process.argv.find((a) => a.startsWith('--still='));

// Use the game's own artwork and its rounded system font. Neither is
// committed here; they are copied next to the page on every render.
mkdirSync(join(root, 'assets'), { recursive: true });
mkdirSync(join(root, 'font'), { recursive: true });
for (const entry of readdirSync(assetCatalog)) {
  if (!entry.endsWith('.imageset')) continue;
  const name = entry.replace('.imageset', '');
  const svg = join(assetCatalog, entry, `${name}.svg`);
  if (existsSync(svg)) cpSync(svg, join(root, 'assets', `${name}.svg`));
}
cpSync('/System/Library/Fonts/SFNSRounded.ttf', join(root, 'font/rounded.ttf'));
mkdirSync(join(root, 'out'), { recursive: true });

const types = { '.html': 'text/html', '.js': 'text/javascript', '.mjs': 'text/javascript', '.svg': 'image/svg+xml', '.ttf': 'font/ttf' };
const server = createServer((req, res) => {
  const path = join(root, decodeURIComponent(new URL(req.url, 'http://x').pathname));
  if (!path.startsWith(root) || !existsSync(path)) { res.writeHead(404).end(); return; }
  res.writeHead(200, { 'content-type': types[extname(path)] ?? 'application/octet-stream' }).end(readFileSync(path));
});
await new Promise((ok) => server.listen(0, '127.0.0.1', ok));
const url = `http://127.0.0.1:${server.address().port}/index.html?render=1&size=${size}`;

const chromePath = readdirSync(join(homedir(), 'Library/Caches/ms-playwright'))
  .filter((d) => d.startsWith('chromium_headless_shell'))
  .map((d) => join(homedir(), 'Library/Caches/ms-playwright', d, 'chrome-headless-shell-mac-arm64/chrome-headless-shell'))
  .find(existsSync);
const browser = await chromium.launch({ executablePath: chromePath });
const page = await browser.newPage({ viewport: { width: 600, height: 900 } });
page.on('console', (m) => console.log(`[page] ${m.text()}`));
page.on('pageerror', (e) => console.error(`[page error] ${e.message}`));
await page.goto(url);
await page.evaluate(() => window.promo.ready);

if (stillArg) {
  const t = Number(stillArg.split('=')[1]);
  const b64 = await page.evaluate((time) => window.promo.frame(time), t);
  const file = join(root, 'out', `still-${size}-${t}.png`);
  writeFileSync(file, Buffer.from(b64, 'base64'));
  console.log(file);
} else {
  const wav = join(root, 'out/soundtrack.wav');
  execFileSync('node', [join(root, 'audio.mjs'), wav], { stdio: 'inherit' });

  const outFile = join(root, 'out', `pawpaw-preview-${size}.mp4`);
  const ffmpeg = spawn('ffmpeg', [
    '-y', '-loglevel', 'error',
    '-f', 'image2pipe', '-framerate', String(FPS), '-c:v', 'png', '-i', '-',
    '-i', wav,
    '-c:v', 'libx264', '-profile:v', 'high', '-pix_fmt', 'yuv420p', '-crf', '14', '-preset', 'slow',
    '-r', String(FPS), '-c:a', 'aac', '-b:a', '256k', '-ar', '44100', '-shortest',
    '-movflags', '+faststart', outFile,
  ], { stdio: ['pipe', 'inherit', 'inherit'] });
  const done = new Promise((ok, fail) => ffmpeg.on('close', (code) => (code === 0 ? ok() : fail(new Error(`ffmpeg exited ${code}`)))));

  const frames = Math.round(DURATION * FPS);
  for (let i = 0; i < frames; i++) {
    const b64 = await page.evaluate((time) => window.promo.frame(time), i / FPS);
    if (!ffmpeg.stdin.write(Buffer.from(b64, 'base64'))) await new Promise((ok) => ffmpeg.stdin.once('drain', ok));
    if (i % 60 === 0) console.log(`frame ${i}/${frames}`);
  }
  ffmpeg.stdin.end();
  await done;
  console.log(outFile);
}
await browser.close();
server.close();
