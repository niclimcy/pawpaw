// Synthesizes the soundtrack for the preview: a gentle pentatonic
// music box plus the game's prey sounds and catch chimes, all timed
// from timeline.js. Writes a 16-bit stereo WAV.

import { writeFileSync } from 'node:fs';
import { DURATION, CATCHES, MISSES, CUES } from './timeline.js';

const RATE = 44100;
const total = Math.floor(DURATION * RATE);
const left = new Float32Array(total);
const right = new Float32Array(total);

let seed = 1234;
const noise = () => {
  seed = (Math.imul(seed, 1664525) + 1013904223) | 0;
  return (seed >>> 0) / 2147483648 - 1;
};

// Adds a mono sample generator f(age) to the mix, panned 0 (left) … 1 (right).
function add(start, length, pan, gain, f) {
  const l = Math.cos(pan * Math.PI / 2) * gain;
  const r = Math.sin(pan * Math.PI / 2) * gain;
  const from = Math.floor(start * RATE);
  const count = Math.floor(length * RATE);
  for (let i = 0; i < count; i++) {
    const idx = from + i;
    if (idx < 0 || idx >= total) continue;
    const v = f(i / RATE);
    left[idx] += v * l;
    right[idx] += v * r;
  }
}

const midi = (n) => 440 * 2 ** ((n - 69) / 12);
const env = (age, attack, decay) => Math.min(1, age / attack) * Math.exp(-age / decay);

function pluck(start, note, gain = 0.14, pan = 0.5, decay = 0.45) {
  const f = midi(note);
  add(start, decay * 6, pan, gain, (a) =>
    env(a, 0.004, decay) * (Math.sin(2 * Math.PI * f * a) + 0.35 * Math.sin(2 * Math.PI * f * 2 * a) * Math.exp(-a * 8)
      + 0.12 * Math.sin(2 * Math.PI * f * 3.01 * a) * Math.exp(-a * 14)));
}

// ---- music bed: C major pentatonic arpeggios over a slow bass, 100 BPM.
const beat = 60 / 100;
const chords = [[48, 55, 64], [45, 52, 60], [41, 48, 57], [43, 50, 59]];
const melody = [72, 76, 79, 76, 74, 79, 81, 79, 72, 76, 79, 84, 83, 79, 76, 74];
for (let bar = 0; bar * 4 * beat < DURATION; bar++) {
  const chord = chords[bar % chords.length];
  const t0 = bar * 4 * beat;
  const intro = Math.min(1, t0 / 3);
  for (let i = 0; i < 8; i++) {
    const note = chord[i % 3] + (i >= 3 && i < 6 ? 12 : 0);
    pluck(t0 + i * beat / 2, note + 12, 0.05 * intro, 0.35 + 0.3 * ((i % 4) / 3), 0.4);
  }
  pluck(t0, chord[0] - 12, 0.12 * intro, 0.5, 1.1);
  pluck(t0 + 2 * beat, chord[1] - 12, 0.08 * intro, 0.5, 0.9);
  for (let i = 0; i < 4; i++) {
    const m = melody[(bar * 4 + i) % melody.length];
    if (t0 > 2.4) pluck(t0 + i * beat, m, 0.075, 0.6, 0.6);
  }
}

// ---- prey sounds, same families as SoundPlayer.
const bandNoise = (center, a, decay) => {
  let lp = 0;
  let hp = 0;
  const k = Math.min(0.95, (2 * Math.PI * center) / RATE);
  return (age) => {
    const n = noise();
    lp += k * (n - lp);
    hp += 0.05 * (lp - hp);
    return (lp - hp) * 6 * env(age, a, decay);
  };
}

// Prey sounds sit under the music rather than on top of it.
const PREY_GAIN = 0.35;
const prey = (t, length, pan, gain, f) => add(t, length, pan, gain * PREY_GAIN, f);

const SOUNDS = {
  squeak: (t, pan) => prey(t, 0.3, pan, 0.2, (a) => Math.sin(2 * Math.PI * (1800 + 1400 * a / 0.12) * a) * env(a, 0.005, 0.08)),
  rustle: (t, pan) => prey(t, 0.5, pan, 0.28, bandNoise(5000, 0.02, 0.15)),
  flutter: (t, pan) => prey(t, 0.5, pan, 0.3, (() => {
    const base = bandNoise(7500, 0.01, 0.2);
    return (a) => base(a) * (0.6 + 0.4 * Math.sin(2 * Math.PI * 26 * a));
  })()),
  skitter: (t, pan) => { for (let i = 0; i < 5; i++) prey(t + i * 0.05, 0.1, pan, 0.2, bandNoise(6500, 0.002, 0.02)); },
  swish: (t, pan) => prey(t, 0.7, pan, 0.28, (() => {
    const base = bandNoise(3000, 0.12, 0.25);
    return (a) => base(a);
  })()),
  tweet: (t, pan) => {
    for (let i = 0; i < 3; i++) {
      prey(t + i * 0.13, 0.14, pan, 0.14, (a) =>
        Math.sin(2 * Math.PI * (3600 + 900 * i + 1200 * a / 0.1) * a) * env(a, 0.006, 0.05));
    }
  },
};

for (const cue of CUES) SOUNDS[cue.sound](cue.t, cue.x);

// ---- paw taps and catch chimes.
for (const catchEvent of CATCHES) {
  const pan = catchEvent.x;
  add(catchEvent.t, 0.2, pan, 0.45, (a) =>
    Math.sin(2 * Math.PI * (130 - 60 * a / 0.1) * a) * env(a, 0.002, 0.05));
  const big = catchEvent.points >= 20;
  const notes = big ? [79, 83, 86, 91] : [79, 83, 86];
  notes.forEach((n, i) => pluck(catchEvent.t + 0.02 + i * 0.07, n, 0.13, pan, 0.5));
}
for (const miss of MISSES) {
  add(miss.t, 0.15, miss.x, 0.3, (a) => Math.sin(2 * Math.PI * 110 * a) * env(a, 0.002, 0.04));
}

// ---- end card sting, then fade the whole mix out.
const outro = DURATION - 3.4;
[72, 76, 79, 84].forEach((n, i) => pluck(outro + 0.1 + i * 0.09, n, 0.12, 0.5, 1.2));
pluck(outro + 0.1, 48, 0.14, 0.5, 2);

let peak = 0;
for (let i = 0; i < total; i++) {
  const t = i / RATE;
  const gain = Math.min(1, t / 0.4) * Math.min(1, (DURATION - t) / 0.8);
  left[i] *= gain;
  right[i] *= gain;
  peak = Math.max(peak, Math.abs(left[i]), Math.abs(right[i]));
}
const norm = peak > 0 ? 0.85 / peak : 1;

const data = Buffer.alloc(total * 4);
for (let i = 0; i < total; i++) {
  data.writeInt16LE(Math.round(Math.max(-1, Math.min(1, left[i] * norm)) * 32767), i * 4);
  data.writeInt16LE(Math.round(Math.max(-1, Math.min(1, right[i] * norm)) * 32767), i * 4 + 2);
}
const header = Buffer.alloc(44);
header.write('RIFF', 0);
header.writeUInt32LE(36 + data.length, 4);
header.write('WAVEfmt ', 8);
header.writeUInt32LE(16, 16);
header.writeUInt16LE(1, 20);
header.writeUInt16LE(2, 22);
header.writeUInt32LE(RATE, 24);
header.writeUInt32LE(RATE * 4, 28);
header.writeUInt16LE(4, 32);
header.writeUInt16LE(16, 34);
header.write('data', 36);
header.writeUInt32LE(data.length, 40);

const out = process.argv[2] ?? 'out/soundtrack.wav';
writeFileSync(out, Buffer.concat([header, data]));
console.log(`Wrote ${out}`);
