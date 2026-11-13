// Paw Paw App Store featuring artwork (Header and Search Results), drawn on a canvas.
// Everything is laid out in design units where the canvas is 1000 units tall,
// so one composition renders crisply at every requested pixel size.
//   artwork.html?kind=header|search&w=5244&h=2950&text=1|0

const params = new URLSearchParams(location.search);
const PX_W = Number(params.get('w') ?? 5244);
const PX_H = Number(params.get('h') ?? 2950);
const KIND = params.get('kind') ?? 'header';
const WITH_TEXT = params.get('text') !== '0';

const U = PX_H / 1000; // pixels per design unit
const H = 1000;
const W = PX_W / U;

const canvas = document.getElementById('stage');
canvas.width = PX_W;
canvas.height = PX_H;
const ctx = canvas.getContext('2d');

// Theme.swift
const C = {
  background: '#291a0f',
  accent: '#ff9e33',
  gold: '#ffd64d',
  text: '#fff0cc',
};
const FONT = 'PawRounded, ui-rounded, system-ui, sans-serif';

// ---------------------------------------------------------------- helpers

const lerp = (a, b, u) => a + (b - a) * u;

function mulberry32(seed) {
  return () => {
    seed |= 0;
    seed = (seed + 0x6d2b79f5) | 0;
    let r = Math.imul(seed ^ (seed >>> 15), 1 | seed);
    r = (r + Math.imul(r ^ (r >>> 7), 61 | r)) ^ r;
    return ((r ^ (r >>> 14)) >>> 0) / 4294967296;
  };
}
const rand = (rng, a, b) => a + (b - a) * rng();

// Canvas shadows are in device pixels and ignore the transform, so scale them.
function shadow(blur, offsetY, color = 'rgba(0,0,0,0.5)') {
  ctx.shadowColor = color;
  ctx.shadowBlur = blur * U;
  ctx.shadowOffsetX = 0;
  ctx.shadowOffsetY = offsetY * U;
}

// ---------------------------------------------------------------- assets

const IMAGE_NAMES = [
  'logo_paw', 'cat_orange',
  'critter_mouse_move', 'critter_bug', 'critter_butterfly', 'critter_cricket',
  'critter_feather', 'critter_laser', 'critter_ribbon',
];
const img = {};

async function loadAssets() {
  await Promise.all(IMAGE_NAMES.map((name) => new Promise((resolve, reject) => {
    const image = new Image();
    image.onload = () => { img[name] = image; resolve(); };
    image.onerror = () => reject(new Error(`Could not load ${name}`));
    image.src = `assets/${name}.svg`;
  })));
  const font = new FontFace('PawRounded', 'url(font/rounded.ttf)', { weight: '100 1000' });
  try {
    document.fonts.add(await font.load());
  } catch {
    console.warn('SF Rounded not available; using a fallback font');
  }
}

// ---------------------------------------------------------------- background
// The crate from WoodCrateBackgroundView, as in promo.js, at artwork scale.

function drawWood() {
  const rng = mulberry32(42);
  const plankHeight = 125;
  ctx.fillStyle = C.background;
  ctx.fillRect(0, 0, W, H);
  for (let y = 0; y < H; y += plankHeight) {
    const shade = rand(rng, -0.025, 0.035);
    const rgb = [0.2 + shade, 0.125 + shade * 0.7, 0.075 + shade * 0.4].map((v) => Math.round(v * 255));
    ctx.fillStyle = `rgb(${rgb})`;
    ctx.fillRect(0, y, W, plankHeight);
    for (let i = 0; i < 18; i++) {
      const gy = y + rand(rng, 5, plankHeight - 5);
      const amp = rand(rng, 1, 5);
      const x0 = rand(rng, -60, W * 0.5);
      const x1 = x0 + rand(rng, W * 0.25, W * 0.8);
      ctx.beginPath();
      ctx.moveTo(x0, gy);
      ctx.bezierCurveTo(lerp(x0, x1, 0.3), gy - amp, lerp(x0, x1, 0.7), gy + amp, x1, gy + rand(rng, -4, 4));
      ctx.lineWidth = rand(rng, 0.6, 1.6);
      ctx.strokeStyle = `rgba(0,0,0,${rand(rng, 0.08, 0.22)})`;
      ctx.stroke();
    }
    if (rng() < 0.5) {
      const k = rand(rng, 18, 32);
      const kx = rand(rng, 60, W - 100);
      const ky = y + plankHeight / 2 + rand(rng, -12, 12);
      ctx.fillStyle = 'rgba(0,0,0,0.28)';
      ctx.beginPath();
      ctx.ellipse(kx + k * 0.8, ky, k * 0.8, k / 2, 0, 0, Math.PI * 2);
      ctx.fill();
      ctx.strokeStyle = 'rgba(0,0,0,0.18)';
      ctx.lineWidth = 1.2;
      ctx.beginPath();
      ctx.ellipse(kx + k * 0.8, ky, k * 0.8 + 5, k / 2 + 4, 0, 0, Math.PI * 2);
      ctx.stroke();
    }
    ctx.fillStyle = 'rgba(255,255,255,0.05)';
    ctx.fillRect(0, y, W, 2.5);
    ctx.fillStyle = 'rgba(0,0,0,0.65)';
    ctx.fillRect(0, y + plankHeight - 4, W, 4);
    for (const nx of [24, W - 24]) {
      const ny = y + plankHeight / 2;
      ctx.fillStyle = 'rgba(0,0,0,0.5)';
      ctx.beginPath(); ctx.arc(nx + 1.5, ny + 2, 7, 0, Math.PI * 2); ctx.fill();
      ctx.fillStyle = 'rgb(82,82,82)';
      ctx.beginPath(); ctx.arc(nx, ny, 7, 0, Math.PI * 2); ctx.fill();
      ctx.fillStyle = 'rgba(153,153,153,0.8)';
      ctx.beginPath(); ctx.arc(nx - 2, ny - 2, 2, 0, Math.PI * 2); ctx.fill();
    }
  }
  // Warm pool of light behind the logo, then a vignette towards the edges.
  const glow = ctx.createRadialGradient(W / 2, H * 0.45, 0, W / 2, H * 0.45, H * 0.62);
  glow.addColorStop(0, 'rgba(255,158,51,0.20)');
  glow.addColorStop(1, 'rgba(255,158,51,0)');
  ctx.fillStyle = glow;
  ctx.fillRect(0, 0, W, H);
  const v = ctx.createRadialGradient(W / 2, H / 2, H * 0.35, W / 2, H / 2, Math.hypot(W, H) / 2);
  v.addColorStop(0, 'rgba(0,0,0,0)');
  v.addColorStop(1, 'rgba(0,0,0,0.6)');
  ctx.fillStyle = v;
  ctx.fillRect(0, 0, W, H);
}

// ---------------------------------------------------------------- critters
// `dx` is an offset from the centre as a fraction of half the width, so the
// critters fan out to the edges on every aspect ratio while the middle stays
// clear for the logo. `y` is a fraction of the height.

const CRITTERS = [
  { image: 'critter_feather', dx: -0.8, y: 0.22, size: 170, rotation: 0.7 },
  { image: 'critter_ribbon', dx: -0.46, y: 0.13, size: 140, rotation: 1.9 },
  { image: 'critter_mouse_move', dx: -0.54, y: 0.42, size: 185, rotation: 0.75, motion: true },
  { image: 'critter_butterfly', dx: 0.6, y: 0.2, size: 195, rotation: 0.45 },
  { image: 'critter_cricket', dx: 0.88, y: 0.45, size: 125, rotation: -0.35 },
  { image: 'critter_bug', dx: 0.56, y: 0.47, size: 140, rotation: -2.3 },
  { image: 'critter_laser', offset: 270, y: 0.9, size: 90, rotation: 0, laser: true },
];

const at = (dx, y) => ({ x: W / 2 + dx * (W / 2), y: y * H });

// The App Store crops wide artwork towards the centre, so the cats sit a fixed
// distance from it (in design units) instead of fanning out with the width.
const CAT_OFFSET = 520;
const nearCentre = (side, y) => ({ x: W / 2 + side * Math.min(CAT_OFFSET, W * 0.4), y: y * H });

function drawMotionLines(x, y, rotation, size) {
  // Short speed streaks trailing behind the critter (it faces up in its art).
  ctx.save();
  ctx.translate(x, y);
  ctx.rotate(rotation);
  ctx.strokeStyle = 'rgba(255,240,204,0.35)';
  ctx.lineCap = 'round';
  ctx.lineWidth = 6;
  for (const [ox, len] of [[-28, 46], [0, 64], [28, 46]]) {
    ctx.beginPath();
    ctx.moveTo(ox, size * 0.62);
    ctx.lineTo(ox, size * 0.62 + len);
    ctx.stroke();
  }
  ctx.restore();
}

function drawCritter(c) {
  const p = c.offset === undefined ? at(c.dx, c.y) : { x: W / 2 + c.offset, y: c.y * H };
  if (c.laser) {
    const glow = ctx.createRadialGradient(p.x, p.y, 0, p.x, p.y, c.size * 1.1);
    glow.addColorStop(0, 'rgba(255,60,40,0.55)');
    glow.addColorStop(1, 'rgba(255,60,40,0)');
    ctx.fillStyle = glow;
    ctx.fillRect(p.x - c.size * 1.2, p.y - c.size * 1.2, c.size * 2.4, c.size * 2.4);
  }
  if (c.motion) drawMotionLines(p.x, p.y, c.rotation, c.size);
  ctx.save();
  ctx.translate(p.x, p.y);
  ctx.rotate(c.rotation);
  if (!c.laser) shadow(16, 7);
  ctx.drawImage(img[c.image], -c.size / 2, -c.size / 2, c.size, c.size);
  ctx.restore();
}

// ---------------------------------------------------------------- the cats

// A gray tabby paw pouncing up from the bottom edge, like drawPaw in promo.js.
function drawPaw() {
  const coat = { fur: '#9ea5b0', edge: '#535b70' };
  const tip = nearCentre(-1, 0.8);
  const base = { x: tip.x - 70, y: H + 260 };
  const angle = Math.atan2(tip.y - base.y, tip.x - base.x);
  const k = 2.1; // promo.js draws this paw at 1/2.1 of this size

  ctx.save();
  shadow(26, 12);
  ctx.lineCap = 'round';
  ctx.strokeStyle = coat.edge;
  ctx.lineWidth = 78 * k;
  ctx.beginPath(); ctx.moveTo(base.x, base.y); ctx.lineTo(tip.x, tip.y); ctx.stroke();
  ctx.shadowColor = 'transparent';
  ctx.strokeStyle = coat.fur;
  ctx.lineWidth = 70 * k;
  ctx.beginPath(); ctx.moveTo(base.x, base.y); ctx.lineTo(tip.x, tip.y); ctx.stroke();
  ctx.restore();

  ctx.save();
  ctx.translate(tip.x, tip.y);
  ctx.rotate(angle + Math.PI / 2);
  ctx.scale(k, k);
  // Paw pads face the glass, so the screen sees the toe beans.
  ctx.fillStyle = coat.fur;
  ctx.strokeStyle = coat.edge;
  ctx.lineWidth = 4;
  ctx.beginPath(); ctx.ellipse(0, 0, 46, 42, 0, 0, Math.PI * 2); ctx.fill(); ctx.stroke();
  ctx.fillStyle = '#e98a84';
  ctx.strokeStyle = '#c9656b';
  ctx.lineWidth = 2;
  ctx.beginPath(); ctx.ellipse(0, 10, 19, 15, 0, 0, Math.PI * 2); ctx.fill(); ctx.stroke();
  for (const [bx, by, r] of [[-27, -10, 8.5], [-11, -25, 9], [11, -25, 9], [27, -10, 8.5]]) {
    ctx.beginPath(); ctx.ellipse(bx, by, r, r * 1.15, 0, 0, Math.PI * 2); ctx.fill(); ctx.stroke();
  }
  ctx.restore();
}

// Mochi, the orange tabby, peeking up over the bottom edge.
function drawPeekingCat() {
  const s = 330;
  const p = nearCentre(1, 1);
  ctx.save();
  ctx.translate(p.x, p.y - s * 0.78);
  ctx.rotate(-0.12);
  shadow(24, 10);
  ctx.drawImage(img.cat_orange, -s / 2, 0, s, s);
  ctx.restore();
}

// ---------------------------------------------------------------- hero

function star(cx, cy, r, color) {
  ctx.save();
  ctx.translate(cx, cy);
  ctx.beginPath();
  for (let i = 0; i < 8; i++) {
    const radius = i % 2 === 0 ? r : r / 3;
    const a = (i * Math.PI) / 4 - Math.PI / 2;
    ctx.lineTo(Math.cos(a) * radius, Math.sin(a) * radius);
  }
  ctx.closePath();
  ctx.fillStyle = color;
  ctx.fill();
  ctx.restore();
}

function drawLogo(cx, cy, width) {
  const h = (width * 168) / 200;
  ctx.save();
  shadow(30, 12, 'rgba(0,0,0,0.55)');
  ctx.drawImage(img.logo_paw, cx - width / 2, cy - h / 2, width, h);
  ctx.restore();
  // Catch sparkles, as in GameAreaView+Effects.
  const r = width / 2;
  star(cx - r * 1.12, cy - h * 0.42, 26, C.gold);
  star(cx + r * 1.16, cy - h * 0.5, 34, C.gold);
  star(cx + r * 1.02, cy + h * 0.12, 18, '#ffffff');
  star(cx - r * 1.0, cy + h * 0.2, 16, '#ffffff');
}

function drawHero() {
  if (!WITH_TEXT) {
    drawLogo(W / 2, H * 0.47, 470);
    return;
  }
  drawLogo(W / 2, H * 0.31, 330);
  ctx.save();
  ctx.textAlign = 'center';
  ctx.textBaseline = 'middle';
  shadow(22, 8, 'rgba(0,0,0,0.6)');
  ctx.font = `900 172px ${FONT}`;
  ctx.fillStyle = C.text;
  ctx.fillText('Paw Paw', W / 2, H * 0.6);
  shadow(14, 4, 'rgba(0,0,0,0.65)');
  ctx.font = `800 58px ${FONT}`;
  ctx.fillStyle = C.accent;
  ctx.fillText('The game made for cats', W / 2, H * 0.745);
  ctx.restore();
}

// ---------------------------------------------------------------- frame

function render() {
  ctx.setTransform(U, 0, 0, U, 0, 0);
  ctx.clearRect(0, 0, W, H);
  drawWood();
  for (const c of CRITTERS) drawCritter(c);
  drawPeekingCat();
  drawPaw();
  drawHero();
}

window.artwork = {
  kind: KIND,
  ready: loadAssets().then(render),
  png() {
    return canvas.toDataURL('image/png').split(',')[1];
  },
};
