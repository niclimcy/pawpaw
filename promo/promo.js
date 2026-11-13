// Paw Paw App Store preview, drawn frame by frame on a canvas.
// `renderFrame(t)` is pure: the same `t` always draws the same frame,
// so render.mjs can step through time at an exact frame rate.

import { FPS, DURATION, SIZES, SCENES, CATCHES, MISSES, sceneAt } from './timeline.js';

const params = new URLSearchParams(location.search);
const size = SIZES[params.get('size')] ?? SIZES.iphone;
const S = size.scale;
const W = size.width / S;
const H = size.height / S;

const canvas = document.getElementById('stage');
canvas.width = size.width;
canvas.height = size.height;
const ctx = canvas.getContext('2d');

// Theme.swift
const C = {
  background: '#291a0f',
  panel: '#452b1a',
  accent: '#ff9e33',
  gold: '#ffd64d',
  text: '#fff0cc',
};
const FONT = 'PawRounded, ui-rounded, system-ui, sans-serif';
const CRITTER_SIZE = 110;

// ---------------------------------------------------------------- helpers

const clamp = (v, a = 0, b = 1) => Math.min(b, Math.max(a, v));
const lerp = (a, b, u) => a + (b - a) * u;
const progress = (t, a, b) => clamp((t - a) / (b - a));
const smooth = (u) => u * u * (3 - 2 * u);
const easeOutCubic = (u) => 1 - (1 - u) ** 3;
const easeInCubic = (u) => u ** 3;
const easeOutBack = (u) => 1 + 2.4 * (u - 1) ** 3 + 1.4 * (u - 1) ** 2;
const lerpAngle = (a, b, u) => {
  let d = ((b - a + Math.PI) % (Math.PI * 2)) - Math.PI;
  if (d < -Math.PI) d += Math.PI * 2;
  return a + d * u;
};

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

function roundRect(c, x, y, w, h, r) {
  c.beginPath();
  c.roundRect(x, y, w, h, r);
}

// ---------------------------------------------------------------- assets

const IMAGE_NAMES = [
  'logo_paw',
  'critter_mouse', 'critter_bug', 'critter_butterfly', 'critter_cricket', 'critter_feather',
  'critter_laser', 'critter_fish', 'critter_bird', 'critter_lizard', 'critter_ribbon',
  'critter_mouse_move', 'critter_mouse_move2', 'critter_bug_move', 'critter_bug_move2',
  'critter_lizard_move', 'critter_lizard_move2', 'critter_fish_move', 'critter_fish_move2',
  'critter_bird_fly',
  'cat_orange', 'cat_black', 'cat_white', 'cat_gray', 'cat_calico', 'cat_siamese',
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

// ---------------------------------------------------------------- backgrounds
// Ports of WoodCrateBackgroundView and NatureBackgroundView, pre-rendered once.

function makeLayer(draw) {
  const layer = document.createElement('canvas');
  layer.width = size.width;
  layer.height = size.height;
  const c = layer.getContext('2d');
  c.scale(S, S);
  draw(c);
  return layer;
}

function drawVignette(c, darkness) {
  const g = c.createRadialGradient(W / 2, H / 2, Math.min(W, H) * 0.3, W / 2, H / 2, Math.hypot(W, H) / 2);
  g.addColorStop(0, 'rgba(0,0,0,0)');
  g.addColorStop(1, `rgba(0,0,0,${darkness})`);
  c.fillStyle = g;
  c.fillRect(0, 0, W, H);
}

function drawWood(c) {
  const rng = mulberry32(42);
  const plankHeight = 96;
  c.fillStyle = C.background;
  c.fillRect(0, 0, W, H);
  for (let y = 0; y < H; y += plankHeight) {
    const shade = rand(rng, -0.025, 0.035);
    const rgb = [0.2 + shade, 0.125 + shade * 0.7, 0.075 + shade * 0.4].map((v) => Math.round(v * 255));
    c.fillStyle = `rgb(${rgb})`;
    c.fillRect(0, y, W, plankHeight);
    for (let i = 0; i < 14; i++) {
      const gy = y + rand(rng, 4, plankHeight - 4);
      const amp = rand(rng, 1, 4);
      const x0 = rand(rng, -40, W * 0.4);
      const x1 = x0 + rand(rng, W * 0.3, W);
      c.beginPath();
      c.moveTo(x0, gy);
      c.bezierCurveTo(lerp(x0, x1, 0.3), gy - amp, lerp(x0, x1, 0.7), gy + amp, x1, gy + rand(rng, -3, 3));
      c.lineWidth = rand(rng, 0.6, 1.6);
      c.strokeStyle = `rgba(0,0,0,${rand(rng, 0.08, 0.22)})`;
      c.stroke();
    }
    if (rng() < 0.5) {
      const k = rand(rng, 14, 26);
      const kx = rand(rng, 40, W - 60);
      const ky = y + plankHeight / 2 + rand(rng, -10, 10);
      c.fillStyle = 'rgba(0,0,0,0.28)';
      c.beginPath();
      c.ellipse(kx + k * 0.8, ky, k * 0.8, k / 2, 0, 0, Math.PI * 2);
      c.fill();
      c.strokeStyle = 'rgba(0,0,0,0.18)';
      c.lineWidth = 1;
      c.beginPath();
      c.ellipse(kx + k * 0.8, ky, k * 0.8 + 4, k / 2 + 3, 0, 0, Math.PI * 2);
      c.stroke();
    }
    c.fillStyle = 'rgba(255,255,255,0.05)';
    c.fillRect(0, y, W, 2);
    c.fillStyle = 'rgba(0,0,0,0.65)';
    c.fillRect(0, y + plankHeight - 3, W, 3);
    for (const nx of [18, W - 18]) {
      const ny = y + plankHeight / 2;
      c.fillStyle = 'rgba(0,0,0,0.5)';
      c.beginPath(); c.arc(nx + 1, ny + 1.5, 5, 0, Math.PI * 2); c.fill();
      c.fillStyle = 'rgb(82,82,82)';
      c.beginPath(); c.arc(nx, ny, 5, 0, Math.PI * 2); c.fill();
      c.fillStyle = 'rgba(153,153,153,0.8)';
      c.beginPath(); c.arc(nx - 1.5, ny - 1.5, 1.5, 0, Math.PI * 2); c.fill();
    }
  }
  drawVignette(c, 0.55);
}

function drawGrass(c) {
  const rng = mulberry32(7);
  c.fillStyle = 'rgb(18,41,20)';
  c.fillRect(0, 0, W, H);
  const greens = ['rgb(31,71,31)', 'rgb(41,87,36)', 'rgb(23,56,26)'];
  c.lineCap = 'round';
  const count = Math.floor((W * H) / 260);
  for (let i = 0; i < count; i++) {
    const x = rand(rng, 0, W);
    const y = rand(rng, 0, H);
    const h = rand(rng, 10, 24);
    const lean = rand(rng, -6, 6);
    c.beginPath();
    c.moveTo(x, y);
    c.quadraticCurveTo(x + lean * 0.2, y - h * 0.6, x + lean, y - h);
    c.lineWidth = rand(rng, 1, 2.2);
    c.strokeStyle = greens[Math.floor(rng() * greens.length)];
    c.stroke();
  }
  drawVignette(c, 0.5);
}

function drawPond(c) {
  const rng = mulberry32(7);
  c.fillStyle = 'rgb(10,31,51)';
  c.fillRect(0, 0, W, H);
  for (let i = 0; i < 14; i++) {
    const x = rand(rng, 0, W);
    const y = rand(rng, 0, H);
    for (let ring = 1; ring <= 3; ring++) {
      const r = ring * rand(rng, 14, 24);
      c.beginPath();
      c.ellipse(x, y, r, r * 0.6, 0, 0, Math.PI * 2);
      c.lineWidth = 1.5;
      c.strokeStyle = `rgba(115,179,217,${0.16 / ring})`;
      c.stroke();
    }
  }
  for (let i = 0; i < 7; i++) {
    const s = rand(rng, 26, 44);
    const x = rand(rng, 0, W);
    const y = rand(rng, 0, H);
    c.fillStyle = 'rgba(31,87,56,0.9)';
    c.beginPath();
    c.ellipse(x + s / 2, y + s * 0.425, s / 2, s * 0.425, 0, 0, Math.PI * 2);
    c.fill();
    c.fillStyle = 'rgb(10,31,51)';
    c.fillRect(x + s / 2, y + s * 0.425 - 1.5, s / 2, 3);
  }
  drawVignette(c, 0.5);
}

function drawSnow(c) {
  const rng = mulberry32(7);
  c.fillStyle = 'rgb(36,46,66)';
  c.fillRect(0, 0, W, H);
  for (let i = 0; i < 9; i++) {
    const w = rand(rng, 90, 220);
    const x = rand(rng, -40, W);
    const y = rand(rng, 0, H);
    c.fillStyle = 'rgba(255,255,255,0.06)';
    c.beginPath();
    c.ellipse(x + w / 2, y + w * 0.175, w / 2, w * 0.175, 0, 0, Math.PI * 2);
    c.fill();
  }
  const flakes = Math.floor((W * H) / 3000);
  for (let i = 0; i < flakes; i++) {
    const s = rand(rng, 1.5, 4);
    c.fillStyle = `rgba(255,255,255,${rand(rng, 0.2, 0.6)})`;
    c.beginPath();
    c.arc(rand(rng, 0, W), rand(rng, 0, H), s / 2, 0, Math.PI * 2);
    c.fill();
  }
  drawVignette(c, 0.5);
}

let backgrounds;

function drawBackground(t) {
  const scene = sceneAt(t);
  const index = SCENES.indexOf(scene);
  const previous = SCENES[index - 1];
  ctx.drawImage(backgrounds[scene.theme], 0, 0, W, H);
  // A circular wipe from the centre whenever the playground changes.
  if (previous && previous.theme !== scene.theme) {
    const u = progress(t, scene.start, scene.start + 0.55);
    if (u < 1) {
      ctx.save();
      ctx.beginPath();
      ctx.rect(0, 0, W, H);
      ctx.arc(W / 2, H * 0.45, easeInCubic(u) * Math.hypot(W, H) * 0.6, 0, Math.PI * 2, true);
      ctx.clip('evenodd');
      ctx.drawImage(backgrounds[previous.theme], 0, 0, W, H);
      ctx.restore();
    }
  }
}

// ---------------------------------------------------------------- critters

const catchById = Object.fromEntries(CATCHES.map((c) => [c.id, c]));
const at = (id) => ({ t: catchById[id].t, x: catchById[id].x, y: catchById[id].y });

// Stride poses from CritterActions.poseCycle, stepped by distance so the feet
// keep pace with the ground. `length` is body lengths per full stride
// (strideSlowdown's gait), so one cycle of `frames` covers that distance.
const STRIDE = ['_move', '', '_move2', ''];
const GAITS = {
  mouse: { frames: STRIDE, length: 1.0 },
  lizard: { frames: STRIDE, length: 1.0 },
  // Six legs are never all at rest: half reach forward as the other half push back.
  bug: { frames: ['_move', '_move2'], length: 0.35 },
};
// CritterActions.swimFrames and swimSwayPeriod: each tail pose sits on a peak of the sway.
const SWIM_FRAMES = ['_move2', '', '_move', ''];
const SWIM_PERIOD = 0.7;

// Keyframes are { t, x, y } in screen fractions. Between keyframes the
// critter eases in and out, which reads as dart-and-freeze; `smooth: true`
// instead glides through them on a Catmull-Rom curve.
const CRITTERS = [
  {
    id: 'mouse', image: 'critter_mouse', size: 1, gait: GAITS.mouse,
    twitches: [4.75, 5.45],
    keys: [
      { t: 3.75, x: -0.2, y: 0.42 }, { t: 4.35, x: 0.34, y: 0.47 },
      { t: 4.95, x: 0.34, y: 0.47 }, { t: 5.3, x: 0.56, y: 0.37 }, at('mouse'),
    ],
  },
  {
    id: 'bug', image: 'critter_bug', size: 0.85, gait: GAITS.bug,
    twitches: [7.1, 7.9],
    keys: [
      { t: 4.0, x: 1.2, y: 0.62 }, { t: 5.6, x: 0.72, y: 0.6 },
      { t: 6.9, x: 0.5, y: 0.67 }, { t: 7.7, x: 0.36, y: 0.56 }, at('bug'),
    ],
  },
  {
    id: 'butterfly', image: 'critter_butterfly', size: 1, smooth: true, flap: true,
    keys: [
      { t: 9.5, x: 1.25, y: 0.22 }, { t: 10.1, x: 0.78, y: 0.36 }, { t: 10.6, x: 0.42, y: 0.24 },
      { t: 11.0, x: 0.56, y: 0.33 }, at('butterfly'),
    ],
  },
  {
    id: 'laser', image: 'critter_laser', size: 0.7, jitter: true, keepHeading: true,
    keys: [
      { t: 11.7, x: -0.15, y: 0.68 }, { t: 12.05, x: 0.74, y: 0.53 },
      { t: 12.48, x: 0.74, y: 0.53 }, { t: 12.68, x: 0.32, y: 0.44 }, at('laser'),
    ],
  },
  {
    id: 'lizard', image: 'critter_lizard', size: 1.05, gait: GAITS.lizard, pushups: [14.85, 15.5],
    keys: [
      { t: 14.4, x: -0.2, y: 0.42 }, { t: 14.75, x: 0.42, y: 0.4 },
      { t: 15.25, x: 0.42, y: 0.4 }, { t: 15.45, x: 0.6, y: 0.52 }, at('lizard'),
    ],
  },
  {
    id: 'fish', image: 'critter_fish', size: 1.15, smooth: true, swim: true, rise: 16.55,
    keys: [
      { t: 16.55, x: 0.3, y: 0.56 }, { t: 17.2, x: 0.4, y: 0.4 },
      { t: 17.7, x: 0.54, y: 0.38 }, at('fish'),
    ],
  },
  {
    id: 'bird', image: 'critter_bird', size: 1, pecks: [19.85], fliesUntil: 19.15,
    keys: [
      { t: 18.75, x: 1.25, y: 0.28 }, { t: 19.15, x: 0.62, y: 0.42 },
      { t: 19.4, x: 0.62, y: 0.42 }, { t: 19.52, x: 0.55, y: 0.44 },
      { t: 19.7, x: 0.55, y: 0.44 }, { t: 19.8, x: 0.48, y: 0.45 }, at('bird'),
    ],
  },
];

function catmull(p0, p1, p2, p3, u) {
  const u2 = u * u;
  const u3 = u2 * u;
  return 0.5 * (2 * p1 + (-p0 + p2) * u + (2 * p0 - 5 * p1 + 4 * p2 - p3) * u2 + (-p0 + 3 * p1 - 3 * p2 + p3) * u3);
}

function positionAt(critter, t) {
  const k = critter.keys;
  if (t <= k[0].t) return { x: k[0].x, y: k[0].y };
  for (let i = 0; i < k.length - 1; i++) {
    const a = k[i];
    const b = k[i + 1];
    if (t > b.t) continue;
    const u = (t - a.t) / (b.t - a.t);
    if (critter.smooth) {
      const p0 = k[Math.max(i - 1, 0)];
      const p3 = k[Math.min(i + 2, k.length - 1)];
      return { x: catmull(p0.x, a.x, b.x, p3.x, u), y: catmull(p0.y, a.y, b.y, p3.y, u) };
    }
    const e = critter.jitter ? easeOutCubic(u) : smooth(u);
    return { x: lerp(a.x, b.x, e), y: lerp(a.y, b.y, e) };
  }
  const last = k[k.length - 1];
  return { x: last.x, y: last.y };
}

// Faces the way it last moved, turning quickly rather than snapping.
function headingAt(critter, t) {
  const dt = 1 / 120;
  let back = t;
  let heading = null;
  for (let i = 0; i < 240 && heading === null; i++) {
    const a = positionAt(critter, back - dt);
    const b = positionAt(critter, back);
    const dx = (b.x - a.x) * W;
    const dy = (b.y - a.y) * H;
    if (Math.hypot(dx, dy) > 0.05) heading = Math.atan2(dy, dx);
    back -= dt;
  }
  if (heading === null) {
    const k = critter.keys;
    heading = Math.atan2((k[1].y - k[0].y) * H, (k[1].x - k[0].x) * W);
  }
  return heading;
}

function smoothedHeading(critter, t) {
  // Average a few samples so turns take ~0.12 s instead of one frame.
  let angle = headingAt(critter, t - 0.12);
  for (const lag of [0.08, 0.04, 0]) angle = lerpAngle(angle, headingAt(critter, t - lag), 0.6);
  return angle;
}

function pulse(t, times, length) {
  for (const p of times ?? []) {
    const u = (t - p) / length;
    if (u >= 0 && u <= 1) return Math.sin(u * Math.PI);
  }
  return 0;
}

// Points travelled since the critter's first keyframe, sampled so the
// result depends only on `t`.
function distanceAt(critter, t) {
  const dt = 1 / 120;
  let total = 0;
  let prev = positionAt(critter, critter.keys[0].t);
  for (let s = critter.keys[0].t + dt; s <= t; s += dt) {
    const p = positionAt(critter, s);
    total += Math.hypot((p.x - prev.x) * W, (p.y - prev.y) * H);
    prev = p;
  }
  return total;
}

function isMoving(critter, t) {
  const a = positionAt(critter, t - 1 / 60);
  const b = positionAt(critter, t);
  return Math.hypot((b.x - a.x) * W, (b.y - a.y) * H) > 0.4;
}

// The artwork for this moment: a stride pose while walking, the tail
// sweeping while swimming, wings spread while flying, otherwise at rest.
function poseImage(critter, t) {
  if (critter.fliesUntil !== undefined && t < critter.fliesUntil) return `${critter.image}_fly`;
  if (critter.swim) {
    const frameTime = SWIM_PERIOD / SWIM_FRAMES.length;
    const age = t - critter.rise - frameTime / 2;
    if (age < 0) return critter.image;
    return critter.image + SWIM_FRAMES[Math.floor(age / frameTime) % SWIM_FRAMES.length];
  }
  if (critter.gait && isMoving(critter, t)) {
    const { frames, length } = critter.gait;
    const stride = length * CRITTER_SIZE * critter.size;
    const phase = distanceAt(critter, t) / stride;
    return critter.image + frames[Math.floor(phase * frames.length) % frames.length];
  }
  return critter.image;
}

function drawCritter(critter, t) {
  const caught = catchById[critter.id];
  const first = critter.keys[0].t - 0.2;
  if (t < first || t > caught.t + 0.25) return;
  const p = positionAt(critter, t);
  const x = p.x * W;
  let y = p.y * H;
  let rotation = critter.keepHeading ? 0 : smoothedHeading(critter, t) + Math.PI / 2;
  let sx = 1;
  let sy = 1;
  let alpha = 1;

  rotation += pulse(t, critter.twitches, 0.16) * 0.35;
  const push = pulse(t, critter.pushups, 0.18) + pulse(t, critter.pushups?.map((v) => v + 0.22), 0.18);
  sx *= 1 + push * 0.08;
  sy *= 1 + push * 0.08;
  const peck = pulse(t, critter.pecks, 0.14) + pulse(t, critter.pecks?.map((v) => v + 0.2), 0.14);
  y -= peck * 6;
  if (critter.flap) sx *= 0.45 + 0.55 * Math.abs(Math.sin(t * 17));
  // Head swings left (anticlockwise) first, as CritterActions.sway does.
  if (critter.swim) rotation -= Math.sin((2 * Math.PI * (t - critter.rise)) / SWIM_PERIOD) * 0.14;
  // Wings opening and closing, as CritterActions.wingbeat does for the bird.
  if (critter.fliesUntil !== undefined && t < critter.fliesUntil) {
    sx *= 1 - 0.3 * smooth(Math.abs(Math.sin((Math.PI * t) / 0.18)));
  }
  if (critter.rise !== undefined) {
    alpha = smooth(progress(t, critter.rise, critter.rise + 0.6));
    drawRipples(x, y, t - critter.rise);
  }
  let jx = 0;
  let jy = 0;
  if (critter.jitter) {
    jx = Math.sin(t * 53) * 1.6 + Math.sin(t * 31) * 1.1;
    jy = Math.cos(t * 47) * 1.6 + Math.sin(t * 23) * 1.1;
  }

  // Pop out when caught.
  const u = progress(t, caught.t, caught.t + 0.22);
  const pop = u > 0 ? lerp(1.2, 0, easeInCubic(u)) * (u < 0.3 ? lerp(1 / 1.2, 1, u / 0.3) : 1) : 1;
  alpha *= u > 0 ? 1 - u : 1;

  const s = CRITTER_SIZE * critter.size;
  ctx.save();
  ctx.globalAlpha = alpha;
  ctx.translate(x + jx, y + jy);
  if (critter.jitter) {
    const glow = ctx.createRadialGradient(0, 0, 0, 0, 0, s * 0.7);
    glow.addColorStop(0, 'rgba(255,60,40,0.5)');
    glow.addColorStop(1, 'rgba(255,60,40,0)');
    ctx.fillStyle = glow;
    ctx.fillRect(-s, -s, s * 2, s * 2);
  } else {
    // Soft contact shadow, like the in-game drop shadow.
    ctx.save();
    ctx.rotate(rotation);
    ctx.scale(sx * pop, sy * pop);
    ctx.shadowColor = 'rgba(0,0,0,0.45)';
    ctx.shadowBlur = 10 * S;
    ctx.shadowOffsetY = 4 * S;
    ctx.drawImage(img[poseImage(critter, t)], -s / 2, -s / 2, s, s);
    ctx.restore();
    ctx.restore();
    return;
  }
  ctx.rotate(rotation);
  ctx.scale(sx * pop, sy * pop);
  ctx.drawImage(img[critter.image], -s / 2, -s / 2, s, s);
  ctx.restore();
}

function drawRipples(x, y, age) {
  for (let i = 0; i < 3; i++) {
    const u = (age - i * 0.25) / 1.2;
    if (u < 0 || u > 1) continue;
    ctx.beginPath();
    ctx.ellipse(x, y, 30 + u * 90, (30 + u * 90) * 0.6, 0, 0, Math.PI * 2);
    ctx.lineWidth = 2;
    ctx.strokeStyle = `rgba(160,210,240,${0.5 * (1 - u)})`;
    ctx.stroke();
  }
}

// ---------------------------------------------------------------- the cat's paw

// Fur, stripe and shading colours from the cat_* profile art.
const CAT_COATS = {
  orange: { fur: '#eaa35a', edge: '#b0622c', stripe: '#c9783a' },
  gray: { fur: '#9ea5b0', edge: '#535b70', stripe: '#737b8a' },
  white: { fur: '#fcf8ef', edge: '#b9a78c', stripe: null },
  siamese: { fur: '#f2e4ca', edge: '#86675a', stripe: null, toe: '#6f5345' },
};
const PAW_PADS = { fill: '#e98a84', edge: '#c9656b' };
const coatForScene = { tap: 'orange', prey: 'orange', grass: 'gray', pond: 'white', snow: 'siamese' };

const STRIKES = [
  ...CATCHES.map((c) => ({ ...c, hit: true })),
  ...MISSES.map((m) => ({ ...m, hit: false })),
];

function drawPaw(strike, t) {
  const reach = 0.3;
  const back = 0.38;
  if (t < strike.t - reach || t > strike.t + back) return;
  const coat = CAT_COATS[coatForScene[sceneAt(strike.t).id]];
  const extend = t <= strike.t
    ? easeOutCubic(progress(t, strike.t - reach, strike.t))
    : 1 - easeInCubic(progress(t, strike.t + 0.06, strike.t + back));
  const target = { x: strike.x * W, y: strike.y * H + 26 };
  const base = { x: target.x + (strike.x < 0.5 ? 60 : -60), y: H + 120 };
  const paw = { x: lerp(base.x, target.x, extend), y: lerp(base.y, target.y, extend) };
  const angle = Math.atan2(paw.y - base.y, paw.x - base.x);
  const squash = 1 + pulse(t, [strike.t - 0.02], 0.12) * 0.1;

  ctx.save();
  ctx.shadowColor = 'rgba(0,0,0,0.5)';
  ctx.shadowBlur = 18 * S;
  ctx.shadowOffsetY = 8 * S;
  // Foreleg.
  ctx.lineCap = 'round';
  ctx.strokeStyle = coat.edge;
  ctx.lineWidth = 78;
  ctx.beginPath(); ctx.moveTo(base.x, base.y + 200); ctx.lineTo(paw.x, paw.y); ctx.stroke();
  ctx.shadowColor = 'transparent';
  ctx.strokeStyle = coat.fur;
  ctx.lineWidth = 70;
  ctx.beginPath(); ctx.moveTo(base.x, base.y + 200); ctx.lineTo(paw.x, paw.y); ctx.stroke();
  ctx.restore();

  ctx.save();
  ctx.translate(paw.x, paw.y);
  ctx.rotate(angle + Math.PI / 2);
  if (coat.stripe) {
    ctx.strokeStyle = coat.stripe;
    ctx.lineWidth = 9;
    ctx.lineCap = 'round';
    for (let i = 0; i < 4; i++) {
      const sy = 70 + i * 48;
      ctx.beginPath(); ctx.moveTo(-26, sy + 8); ctx.quadraticCurveTo(0, sy - 6, 26, sy + 8); ctx.stroke();
    }
  }
  ctx.scale(squash, squash);
  // Paw pads face the glass, so the screen sees the toe beans.
  ctx.fillStyle = coat.toe ?? coat.fur;
  ctx.strokeStyle = coat.edge;
  ctx.lineWidth = 4;
  ctx.beginPath(); ctx.ellipse(0, 0, 46, 42, 0, 0, Math.PI * 2); ctx.fill(); ctx.stroke();
  ctx.fillStyle = PAW_PADS.fill;
  ctx.strokeStyle = PAW_PADS.edge;
  ctx.lineWidth = 2;
  ctx.beginPath(); ctx.ellipse(0, 10, 19, 15, 0, 0, Math.PI * 2); ctx.fill(); ctx.stroke();
  for (const [bx, by, r] of [[-27, -10, 8.5], [-11, -25, 9], [11, -25, 9], [27, -10, 8.5]]) {
    ctx.beginPath(); ctx.ellipse(bx, by, r, r * 1.15, 0, 0, Math.PI * 2); ctx.fill(); ctx.stroke();
  }
  ctx.restore();
}

// ---------------------------------------------------------------- catch effects
// Mirrors GameAreaView+Effects: sparkles, a gold and a white ring, a flash and "+points".

function star(c, r) {
  c.beginPath();
  for (let i = 0; i < 8; i++) {
    const radius = i % 2 === 0 ? r : r / 3;
    const a = (i * Math.PI) / 4 - Math.PI / 2;
    c.lineTo(Math.cos(a) * radius, Math.sin(a) * radius);
  }
  c.closePath();
}

const particles = CATCHES.map((c, index) => {
  const rng = mulberry32(100 + index);
  const big = c.points >= 20;
  const list = [];
  const add = (kind, color, count, fast) => {
    for (let i = 0; i < count * 2; i++) {
      const a = rng() * Math.PI * 2;
      const v = (fast ? 220 : 140) + rand(rng, -90, 90);
      list.push({
        kind, color,
        vx: Math.cos(a) * v, vy: Math.sin(a) * v,
        life: 1 + rand(rng, -0.4, 0.4),
        scale: (fast ? 0.9 : 0.7) + rand(rng, -0.4, 0.4),
        spin: 3 + rand(rng, -6, 6),
        delay: rng() * 0.08,
      });
    }
  };
  add('star', C.gold, big ? 4 : 2, true);
  add('star', '#ffffff', big ? 4 : 2, true);
  add('dot', C.gold, big ? 3 : 1, false);
  return list;
});

function drawRing(x, y, age, color, endRadius, width) {
  const u = age / 0.5;
  if (u < 0 || u > 1) return;
  ctx.beginPath();
  ctx.arc(x, y, Math.max(1, endRadius * easeOutCubic(u)), 0, Math.PI * 2);
  ctx.lineWidth = width;
  ctx.strokeStyle = color;
  ctx.globalAlpha = 1 - u;
  ctx.stroke();
  ctx.globalAlpha = 1;
}

function drawCatchEffects(t) {
  CATCHES.forEach((c, index) => {
    const age = t - c.t;
    if (age < 0 || age > 1.6) return;
    const x = c.x * W;
    const y = c.y * H;

    const flash = 1 - age / 0.25;
    if (flash > 0) {
      const g = ctx.createRadialGradient(x, y, 0, x, y, 70);
      g.addColorStop(0, `rgba(255,255,255,${0.7 * flash})`);
      g.addColorStop(1, 'rgba(255,255,255,0)');
      ctx.fillStyle = g;
      ctx.fillRect(x - 70, y - 70, 140, 140);
    }
    drawRing(x, y, age, C.gold, 110, 5);
    drawRing(x, y, age - 0.06, '#ffffff', 70, 3);

    ctx.save();
    ctx.globalCompositeOperation = 'lighter';
    for (const p of particles[index]) {
      const a = age - p.delay;
      if (a < 0 || a > p.life) continue;
      const alpha = clamp(1 - a * 1.1);
      const scale = Math.max(0, p.scale - 0.5 * a);
      ctx.save();
      ctx.translate(x + p.vx * a, y + p.vy * a + 130 * a * a);
      ctx.rotate(p.spin * a);
      ctx.globalAlpha = alpha;
      ctx.fillStyle = p.color;
      if (p.kind === 'star') {
        star(ctx, 12 * scale);
        ctx.fill();
      } else {
        ctx.beginPath(); ctx.arc(0, 0, 6 * scale, 0, Math.PI * 2); ctx.fill();
      }
      ctx.restore();
    }
    ctx.restore();

    const up = progress(age, 0, 0.9);
    if (up < 1) {
      const scale = age < 0.15 ? easeOutBack(age / 0.15) : 1;
      ctx.save();
      ctx.translate(x, y - 50 - easeOutCubic(up) * 60);
      ctx.scale(scale, scale);
      ctx.globalAlpha = 1 - progress(up, 0.65, 1);
      ctx.font = `900 40px ${FONT}`;
      ctx.textAlign = 'center';
      ctx.textBaseline = 'middle';
      ctx.lineWidth = 6;
      ctx.strokeStyle = 'rgba(60,30,10,0.85)';
      ctx.strokeText(`+${c.points}`, 0, 0);
      ctx.fillStyle = C.gold;
      ctx.fillText(`+${c.points}`, 0, 0);
      ctx.restore();
    }
  });

  for (const m of MISSES) {
    drawRing(m.x * W, m.y * H, t - m.t, 'rgba(255,240,204,0.6)', 28, 2);
  }
}

// ---------------------------------------------------------------- HUD and captions

const HUD_START = 3.5;
const HUD_END = SCENES.find((s) => s.id === 'profiles').start;

function drawHouse(x, y, s) {
  ctx.save();
  ctx.translate(x, y);
  ctx.fillStyle = C.text;
  ctx.beginPath();
  ctx.moveTo(0, -s * 0.55); ctx.lineTo(s * 0.6, 0); ctx.lineTo(s * 0.45, 0); ctx.lineTo(s * 0.45, s * 0.5);
  ctx.lineTo(s * 0.12, s * 0.5); ctx.lineTo(s * 0.12, s * 0.18); ctx.lineTo(-s * 0.12, s * 0.18);
  ctx.lineTo(-s * 0.12, s * 0.5); ctx.lineTo(-s * 0.45, s * 0.5); ctx.lineTo(-s * 0.45, 0); ctx.lineTo(-s * 0.6, 0);
  ctx.closePath();
  ctx.fill();
  ctx.restore();
}

function drawHUD(t) {
  const fadeIn = smooth(progress(t, HUD_START, HUD_START + 0.4));
  const fadeOut = 1 - smooth(progress(t, HUD_END - 0.3, HUD_END));
  const alpha = fadeIn * fadeOut;
  if (alpha <= 0) return;
  const score = CATCHES.filter((c) => c.t <= t).reduce((sum, c) => sum + c.points, 0);
  const lastCatch = [...CATCHES].reverse().find((c) => c.t <= t);
  const bump = lastCatch ? 1 + pulse(t, [lastCatch.t], 0.3) * 0.18 : 1;
  const seconds = Math.max(0, 60 - Math.floor(Math.max(0, t - HUD_START)));
  const y = 100;

  ctx.save();
  ctx.globalAlpha = alpha;
  ctx.shadowColor = 'rgba(0,0,0,0.5)';
  ctx.shadowBlur = 6 * S;
  drawHouse(44, y, 36);
  ctx.font = `800 30px ${FONT}`;
  ctx.textBaseline = 'middle';
  ctx.fillStyle = C.text;
  ctx.textAlign = 'left';
  ctx.save();
  ctx.translate(86, y);
  ctx.scale(bump, bump);
  ctx.fillText(`Score: ${score}`, 0, 0);
  ctx.restore();
  ctx.textAlign = 'right';
  ctx.fillText(`${seconds}`, W - 24, y);
  const numberWidth = ctx.measureText(`${seconds}`).width;
  ctx.font = `26px "Apple Color Emoji", ${FONT}`;
  ctx.fillText('⏱️', W - 34 - numberWidth, y);
  ctx.restore();
}

const PLAYGROUNDS = ['Crate', 'Grass', 'Pond', 'Snow'];
const CAPTIONS = [
  { start: 3.6, end: 9.25, title: 'Paws on the screen!', sub: 'Your cat taps critters to catch them' },
  { start: 9.55, end: 14.05, title: 'Moves like real prey', sub: 'Dart, freeze, twitch… pounce!' },
  { start: 14.35, end: 20.65, title: 'Four playgrounds', playgrounds: true },
];

function drawCaption(t) {
  const cap = CAPTIONS.find((c) => t >= c.start && t <= c.end);
  if (!cap) return;
  const enter = easeOutCubic(progress(t, cap.start, cap.start + 0.4));
  const leave = smooth(progress(t, cap.end - 0.3, cap.end));
  const alpha = enter * (1 - leave);
  const panelW = Math.min(W - 40, 520);
  const panelH = 124;
  const x = (W - panelW) / 2;
  const y = H - panelH - 64 + (1 - enter) * 40 + leave * 20;

  ctx.save();
  ctx.globalAlpha = alpha;
  ctx.shadowColor = 'rgba(0,0,0,0.5)';
  ctx.shadowBlur = 20 * S;
  ctx.shadowOffsetY = 6 * S;
  roundRect(ctx, x, y, panelW, panelH, 28);
  ctx.fillStyle = 'rgba(69,43,26,0.94)';
  ctx.fill();
  ctx.shadowColor = 'transparent';
  ctx.lineWidth = 3;
  ctx.strokeStyle = 'rgba(255,214,77,0.6)';
  ctx.stroke();

  ctx.textAlign = 'center';
  ctx.textBaseline = 'middle';
  ctx.fillStyle = C.text;
  ctx.font = `900 34px ${FONT}`;
  ctx.fillText(cap.title, W / 2, y + 44);

  if (cap.playgrounds) {
    const active = { grass: 1, pond: 2, snow: 3 }[sceneAt(t).id] ?? 1;
    ctx.font = `800 21px ${FONT}`;
    const gap = 16;
    const widths = PLAYGROUNDS.map((p) => ctx.measureText(p).width + 26);
    let px = W / 2 - (widths.reduce((a, b) => a + b, 0) + gap * 3) / 2;
    PLAYGROUNDS.forEach((name, i) => {
      const on = i === active;
      roundRect(ctx, px, y + 72, widths[i], 34, 17);
      ctx.fillStyle = on ? C.accent : 'rgba(41,26,15,0.9)';
      ctx.fill();
      ctx.fillStyle = on ? '#ffffff' : 'rgba(255,240,204,0.7)';
      ctx.fillText(name, px + widths[i] / 2, y + 90);
      px += widths[i] + gap;
    });
  } else {
    ctx.font = `600 21px ${FONT}`;
    ctx.fillStyle = 'rgba(255,240,204,0.8)';
    ctx.fillText(cap.sub, W / 2, y + 88);
  }
  ctx.restore();
}

// ---------------------------------------------------------------- title cards

function drawTitle(cx, cy, appear, t, tagline) {
  const logoIn = easeOutBack(progress(t, appear, appear + 0.5));
  const titleIn = easeOutBack(progress(t, appear + 0.35, appear + 0.85));
  const tagIn = smooth(progress(t, appear + 0.8, appear + 1.2));
  const bob = Math.sin((t - appear) * 2.4) * 4;

  ctx.save();
  ctx.translate(cx, cy - 110 + bob);
  ctx.scale(logoIn, logoIn);
  ctx.rotate((1 - logoIn) * -0.4);
  const lw = 150;
  const lh = (lw * 168) / 200;
  ctx.shadowColor = 'rgba(0,0,0,0.5)';
  ctx.shadowBlur = 16 * S;
  ctx.shadowOffsetY = 6 * S;
  ctx.drawImage(img.logo_paw, -lw / 2, -lh / 2, lw, lh);
  ctx.restore();

  ctx.save();
  ctx.translate(cx, cy + 30);
  ctx.scale(titleIn, titleIn);
  ctx.globalAlpha = clamp(titleIn);
  ctx.textAlign = 'center';
  ctx.textBaseline = 'middle';
  ctx.shadowColor = 'rgba(0,0,0,0.55)';
  ctx.shadowBlur = 14 * S;
  ctx.shadowOffsetY = 5 * S;
  ctx.font = `900 76px ${FONT}`;
  ctx.fillStyle = C.text;
  ctx.fillText('Paw Paw', 0, 0);
  ctx.restore();

  ctx.save();
  ctx.globalAlpha = tagIn;
  ctx.textAlign = 'center';
  ctx.textBaseline = 'middle';
  ctx.font = `800 27px ${FONT}`;
  ctx.fillStyle = C.accent;
  ctx.shadowColor = 'rgba(0,0,0,0.6)';
  ctx.shadowBlur = 8 * S;
  ctx.fillText(tagline, cx, cy + 102 + (1 - tagIn) * 14);
  ctx.restore();
}

// Paw prints padding across the crate before the logo lands.
function drawPawTrail(t) {
  for (let i = 0; i < 7; i++) {
    const appear = 0.05 + i * 0.1;
    const age = t - appear;
    if (age < 0) continue;
    const alpha = 0.35 * smooth(progress(age, 0, 0.12)) * (1 - smooth(progress(t, 2.0, 2.8)));
    if (alpha <= 0) continue;
    const u = i / 6;
    const x = lerp(W * 0.12, W * 0.5, u) + (i % 2 ? 26 : -26);
    const y = lerp(H * 0.92, H * 0.5, u);
    ctx.save();
    ctx.globalAlpha = alpha;
    ctx.translate(x, y);
    ctx.rotate(Math.atan2(-(H * 0.42), W * 0.38) + Math.PI / 2);
    ctx.drawImage(img.logo_paw, -26, -22, 52, 44);
    ctx.restore();
  }
}

function drawIntro(t) {
  drawPawTrail(t);
  const out = easeInCubic(progress(t, 2.95, 3.4));
  ctx.save();
  ctx.globalAlpha = 1 - out;
  ctx.translate(W / 2, H * 0.44);
  ctx.scale(1 + out * 0.25, 1 + out * 0.25);
  ctx.translate(-W / 2, -H * 0.44);
  drawTitle(W / 2, H * 0.44, 0.75, t, 'The game made for cats');
  ctx.restore();
}

const PROFILES = [
  { name: 'Mochi', cat: 'cat_orange', best: 110 },
  { name: 'Shadow', cat: 'cat_black', best: 85 },
  { name: 'Luna', cat: 'cat_white', best: 95 },
  { name: 'Pepper', cat: 'cat_gray', best: 70 },
  { name: 'Biscuit', cat: 'cat_calico', best: 120 },
  { name: 'Miso', cat: 'cat_siamese', best: 90 },
];

function drawProfiles(t) {
  const scene = SCENES.find((s) => s.id === 'profiles');
  if (t < scene.start || t >= scene.end) return;
  const local = t - scene.start;
  const leave = smooth(progress(t, scene.end - 0.35, scene.end));

  ctx.save();
  ctx.globalAlpha = 1 - leave;
  const headIn = easeOutCubic(progress(local, 0.2, 0.6));
  ctx.textAlign = 'center';
  ctx.textBaseline = 'middle';
  ctx.shadowColor = 'rgba(0,0,0,0.55)';
  ctx.shadowBlur = 10 * S;
  ctx.globalAlpha = (1 - leave) * headIn;
  ctx.font = `900 42px ${FONT}`;
  ctx.fillStyle = C.text;
  const headY = H * 0.17 + (1 - headIn) * 20;
  ctx.fillText('A profile for', W / 2, headY);
  ctx.fillText('every cat', W / 2, headY + 50);
  ctx.font = `700 22px ${FONT}`;
  ctx.fillStyle = C.accent;
  ctx.fillText('Best scores and stats for each one', W / 2, headY + 104);
  ctx.restore();

  const cols = 2;
  const gap = 18;
  const cardW = Math.min((W - 48 - gap) / cols, 230);
  const cardH = 196;
  const gridW = cardW * cols + gap;
  const top = H * 0.17 + 160;
  PROFILES.forEach((p, i) => {
    const appear = 0.45 + i * 0.12;
    const u = easeOutBack(progress(local, appear, appear + 0.45));
    if (u <= 0) return;
    const col = i % cols;
    const row = Math.floor(i / cols);
    const cx = (W - gridW) / 2 + col * (cardW + gap) + cardW / 2;
    const cy = top + row * (cardH + gap) + cardH / 2;
    const highlight = i === 0 ? 1 : 0;
    ctx.save();
    ctx.globalAlpha = clamp(u) * (1 - leave);
    ctx.translate(cx, cy);
    ctx.scale(u, u);
    ctx.shadowColor = 'rgba(0,0,0,0.45)';
    ctx.shadowBlur = 14 * S;
    ctx.shadowOffsetY = 5 * S;
    roundRect(ctx, -cardW / 2, -cardH / 2, cardW, cardH, 26);
    ctx.fillStyle = C.panel;
    ctx.fill();
    ctx.shadowColor = 'transparent';
    ctx.lineWidth = 3;
    ctx.strokeStyle = highlight ? C.accent : 'rgba(255,214,77,0.5)';
    ctx.stroke();
    const face = 96;
    const wiggle = Math.sin((local - appear) * 5) * 0.06 * (1 - progress(local, appear + 0.6, appear + 1.4));
    ctx.save();
    ctx.translate(0, -cardH / 2 + 18 + face / 2);
    ctx.rotate(wiggle);
    ctx.drawImage(img[p.cat], -face / 2, -face / 2, face, face);
    ctx.restore();
    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';
    ctx.font = `800 25px ${FONT}`;
    ctx.fillStyle = C.text;
    ctx.fillText(p.name, 0, cardH / 2 - 56);
    ctx.font = `800 19px ${FONT}`;
    ctx.fillStyle = C.gold;
    const counted = Math.round(p.best * easeOutCubic(progress(local, appear + 0.3, appear + 1.2)));
    ctx.fillText(`🏆 Best ${counted}`, 0, cardH / 2 - 26);
    ctx.restore();
  });
}

// A parade of every critter scurrying along under the end card.
const PARADE = ['critter_mouse', 'critter_bug', 'critter_butterfly', 'critter_cricket',
  'critter_feather', 'critter_bird', 'critter_lizard', 'critter_ribbon'];

function drawOutro(t) {
  const scene = SCENES.find((s) => s.id === 'outro');
  if (t < scene.start) return;
  const local = t - scene.start;
  drawTitle(W / 2, H * 0.38, scene.start + 0.1, t, 'The game made for cats');

  const sub = smooth(progress(local, 1.3, 1.7));
  ctx.save();
  ctx.globalAlpha = sub;
  ctx.textAlign = 'center';
  ctx.textBaseline = 'middle';
  ctx.font = `700 22px ${FONT}`;
  ctx.fillStyle = 'rgba(255,240,204,0.85)';
  ctx.fillText('Tap · Pounce · Purr', W / 2, H * 0.38 + 150);
  ctx.restore();

  const speed = 150;
  const spacing = 92;
  PARADE.forEach((name, i) => {
    const x = -60 + (local - 0.3) * speed - i * spacing + (W - 300) * 0.5;
    if (x < -70 || x > W + 70) return;
    const s = name === 'critter_butterfly' ? 72 : 64;
    const y = H * 0.8 + Math.sin(local * 9 + i) * (name === 'critter_butterfly' ? 10 : 2);
    ctx.save();
    ctx.translate(x, y);
    ctx.rotate(Math.PI / 2 + Math.sin(local * 14 + i * 2) * 0.06);
    if (name === 'critter_butterfly') ctx.scale(0.45 + 0.55 * Math.abs(Math.sin(local * 17)), 1);
    ctx.shadowColor = 'rgba(0,0,0,0.45)';
    ctx.shadowBlur = 8 * S;
    ctx.shadowOffsetY = 3 * S;
    const gait = GAITS[name.replace('critter_', '')];
    let pose = name;
    if (gait && local > 0.3) {
      const phase = ((local - 0.3) * speed) / (gait.length * s);
      pose += gait.frames[Math.floor(phase * gait.frames.length) % gait.frames.length];
    }
    ctx.drawImage(img[pose], -s / 2, -s / 2, s, s);
    ctx.restore();
  });
}

// ---------------------------------------------------------------- frame

function drawDim(t) {
  // Darken the crate behind the profile cards and end card so text pops.
  const profiles = SCENES.find((s) => s.id === 'profiles');
  const amount = 0.35 * smooth(progress(t, profiles.start, profiles.start + 0.5));
  if (amount <= 0) return;
  ctx.fillStyle = `rgba(20,12,6,${amount})`;
  ctx.fillRect(0, 0, W, H);
}

function renderFrame(t) {
  ctx.setTransform(S, 0, 0, S, 0, 0);
  ctx.clearRect(0, 0, W, H);
  drawBackground(t);
  drawDim(t);
  if (t < 3.4) drawIntro(t);
  for (const critter of CRITTERS) drawCritter(critter, t);
  drawCatchEffects(t);
  for (const strike of STRIKES) drawPaw(strike, t);
  drawHUD(t);
  drawCaption(t);
  drawProfiles(t);
  drawOutro(t);
  // Fade from and to black at the very ends.
  const fade = Math.max(1 - progress(t, 0, 0.35), progress(t, DURATION - 0.6, DURATION));
  if (fade > 0) {
    ctx.fillStyle = `rgba(0,0,0,${fade})`;
    ctx.fillRect(0, 0, W, H);
  }
}

// ---------------------------------------------------------------- boot

window.promo = {
  ready: (async () => {
    await loadAssets();
    backgrounds = {
      wood: makeLayer(drawWood),
      grass: makeLayer(drawGrass),
      pond: makeLayer(drawPond),
      snow: makeLayer(drawSnow),
    };
  })(),
  frame(t) {
    renderFrame(t);
    return canvas.toDataURL('image/png').split(',')[1];
  },
  still(t) {
    renderFrame(t);
  },
};

// Opened directly in a browser: play in real time on a loop (click to restart).
if (!params.has('render')) {
  window.promo.ready.then(() => {
    let start = performance.now() - Number(params.get('t') ?? 0) * 1000;
    canvas.addEventListener('click', () => { start = performance.now(); });
    const tick = (now) => {
      const t = ((now - start) / 1000) % DURATION;
      renderFrame(t);
      requestAnimationFrame(tick);
    };
    requestAnimationFrame(tick);
  });
}

export { FPS };
