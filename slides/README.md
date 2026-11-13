# Slides

A short talk on Paw Paw for the iOS class: the design thinking behind it, a live demo, and why the playfield uses SpriteKit instead of only UIKit.

- `index.html`: the deck. One HTML file, no build step.
- `render-icons.swift`: puts the icons into `index.html`.
- `pawpaw-slides.pdf`: a PDF copy of the deck.

## Present

Open `index.html` in Safari or Chrome.

| Key | Action |
|---|---|
| → / Space / click | Next slide |
| ← / click the left third | Previous slide |
| N | Show or hide speaker notes |
| F | Fullscreen |

Add the slide number to the URL to jump to it, e.g. `index.html#7`.

The screenshots and the backup demo video load from `../previews/`, so open the deck from inside the repo. Play the video once before presenting to make sure it loads.

## Icons

The icons are SF Symbols plus the app's own art (`logo_paw`, `critter_mouse` from `site/assets/art/`). They sit in `index.html` as an SVG sprite between the `icons:start` and `icons:end` comments, and slides use them with `<use href="#sf-…">` or `<use href="#art-…">`.

To add one, put its name in the `symbols` or `artwork` list in `render-icons.swift`, then run from the repo root:

```sh
swift slides/render-icons.swift
```

The script replaces the sprite. It reads each symbol's outline through an undocumented macOS interface, so it needs a Mac and may stop working after a macOS update.

## PDF

Each slide prints as one 16:9 page; notes and controls are hidden. To export from the repo root:

```sh
"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" --headless=new \
  --no-pdf-header-footer --virtual-time-budget=5000 \
  --print-to-pdf=slides/pawpaw-slides.pdf "file://$PWD/slides/index.html"
```

Or open the deck in Chrome, press ⌘P, and turn on **Background graphics**. In the PDF, the demo slide shows a still image in place of the video.
