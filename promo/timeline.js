// Shared timeline for the Paw Paw App Store preview.
// Both the visuals (promo.js) and the soundtrack (audio.mjs) read from here,
// so sound effects always land on the same frame as the animation.

export const FPS = 30;
export const DURATION = 28; // App Store previews must be 15–30 s.

// App Store Connect app preview resolutions (portrait). `scale` maps
// design points to pixels, like @2x on a device.
export const SIZES = {
  iphone: { width: 886, height: 1920, scale: 2 },
  ipad: { width: 1200, height: 1600, scale: 2 },
};

export const SCENES = [
  { id: 'intro', start: 0, end: 3.4, theme: 'wood' },
  { id: 'tap', start: 3.4, end: 9.4, theme: 'wood' },
  { id: 'prey', start: 9.4, end: 14.2, theme: 'wood' },
  { id: 'grass', start: 14.2, end: 16.4, theme: 'grass' },
  { id: 'pond', start: 16.4, end: 18.6, theme: 'pond' },
  { id: 'snow', start: 18.6, end: 20.8, theme: 'snow' },
  { id: 'profiles', start: 20.8, end: 24.6, theme: 'wood' },
  { id: 'outro', start: 24.6, end: DURATION, theme: 'wood' },
];

// Every catch: when the paw lands, how many points, and where
// (x, y as fractions of the screen). Points match TargetKind.points.
export const CATCHES = [
  { id: 'mouse', t: 6.0, points: 10, x: 0.56, y: 0.37 },
  { id: 'bug', t: 8.3, points: 5, x: 0.36, y: 0.56 },
  { id: 'butterfly', t: 11.3, points: 20, x: 0.52, y: 0.3 },
  { id: 'laser', t: 13.4, points: 25, x: 0.32, y: 0.44 },
  { id: 'lizard', t: 15.8, points: 15, x: 0.6, y: 0.52 },
  { id: 'fish', t: 18.0, points: 15, x: 0.58, y: 0.42 },
  { id: 'bird', t: 20.2, points: 20, x: 0.48, y: 0.45 },
];

// Paw taps that miss (the laser dot zips away just in time).
export const MISSES = [{ t: 12.55, x: 0.74, y: 0.53 }];

// Off-screen rustles and squeaks before a critter runs in.
export const CUES = [
  { t: 3.55, sound: 'squeak', x: 0 },
  { t: 3.85, sound: 'rustle', x: 1 },
  { t: 9.5, sound: 'flutter', x: 1 },
  { t: 14.25, sound: 'skitter', x: 0 },
  { t: 16.5, sound: 'swish', x: 0.4 },
  { t: 18.65, sound: 'flutter', x: 1 },
  { t: 19.15, sound: 'tweet', x: 0.6 },
];

export const sceneAt = (t) => SCENES.find((s) => t >= s.start && t < s.end) ?? SCENES[SCENES.length - 1];
