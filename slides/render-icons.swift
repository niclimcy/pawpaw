// Inlines the deck's icons into slides/index.html as an SVG sprite, so the
// deck stays one self-contained file.
// SF Symbols have no public vector export (AppKit rasterizes them even into a
// PDF), so this reads the outline from the symbol's private CoreUI glyph.
// Fine for a one-off build script; it may break on a future macOS.
// Run from the repo root: swift slides/render-icons.swift

import AppKit

let symbols = [
    "person.fill",
    "pawprint.fill",
    "hand.tap.fill",
    "timer",
    "house.fill",
    "cat.fill",
    "pause.fill",
    "figure.walk.motion",
    "point.topleft.down.to.point.bottomright.curvepath.fill",
    "waveform.path",
    "shippingbox.fill",
    "speaker.wave.3.fill",
    "iphone",
    "rectangle.split.2x1",
    "ipad.landscape",
    "accessibility",
    "textformat.size",
]
/// Artwork with an optional tighter viewBox, so small icons aren't mostly padding.
let artwork: [(name: String, viewBox: String?)] = [
    ("logo_paw", nil),
    ("critter_mouse", "45 0 110 200"),
]
let deck = URL(fileURLWithPath: "slides/index.html")
let startMarker = "<!-- icons:start -->"
let endMarker = "<!-- icons:end -->"

func fmt(_ v: CGFloat) -> String {
    let r = (v * 100).rounded() / 100
    if r == r.rounded() { return String(Int(r)) }
    return String(format: "%.2f", r).replacingOccurrences(
        of: "0+$", with: "", options: .regularExpression)
}

func glyphPath(_ name: String) -> CGPath? {
    guard
        let image = NSImage(systemSymbolName: name, accessibilityDescription: nil)?
            .withSymbolConfiguration(.init(pointSize: 64, weight: .semibold)),
        let rep = image.representations.first as NSObject?,
        rep.responds(to: NSSelectorFromString("vectorGlyph")),
        let glyph = rep.value(forKey: "vectorGlyph") as? NSObject,
        glyph.responds(to: NSSelectorFromString("CGPath")),
        let result = glyph.perform(NSSelectorFromString("CGPath"))
    else { return nil }
    let path = result.takeUnretainedValue() as! CGPath
    return path.isEmpty ? nil : path
}

func symbolSVG(_ name: String) -> String? {
    guard let path = glyphPath(name) else { return nil }
    var d = ""
    path.applyWithBlock { element in
        let e = element.pointee
        let p = { (i: Int) in "\(fmt(e.points[i].x)) \(fmt(e.points[i].y))" }
        switch e.type {
        case .moveToPoint: d += "M\(p(0))"
        case .addLineToPoint: d += "L\(p(0))"
        case .addQuadCurveToPoint: d += "Q\(p(0)) \(p(1))"
        case .addCurveToPoint: d += "C\(p(0)) \(p(1)) \(p(2))"
        case .closeSubpath: d += "Z"
        @unknown default: break
        }
    }
    let box = path.boundingBoxOfPath
    let viewBox = [box.minX, box.minY, box.width, box.height].map(fmt).joined(separator: " ")
    return "<symbol id=\"sf-\(name)\" viewBox=\"\(viewBox)\"><path d=\"\(d)\"/></symbol>"
}

func artworkSVG(_ name: String, viewBox override: String?) throws -> String {
    let svg = try String(contentsOfFile: "site/assets/art/\(name).svg", encoding: .utf8)
    let viewBox = override ?? String(svg.firstMatch(of: #/viewBox="([^"]+)"/#)!.1)
    let body =
        svg
        .replacing(#/<svg[^>]*>/#, with: "")
        .replacing("</svg>", with: "")
        .replacing(#/<!--[\s\S]*?-->/#, with: "")
        .replacing(#/\s*\n\s*/#, with: "")
    return "<symbol id=\"art-\(name)\" viewBox=\"\(viewBox)\">\(body)</symbol>"
}

var parts: [String] = []
var missing: [String] = []
for name in symbols {
    if let svg = symbolSVG(name) { parts.append(svg) } else { missing.append(name) }
}
guard missing.isEmpty else {
    print("Missing symbols: \(missing.joined(separator: ", "))")
    exit(1)
}
for art in artwork { parts.append(try artworkSVG(art.name, viewBox: art.viewBox)) }

let sprite =
    "<svg xmlns=\"http://www.w3.org/2000/svg\" style=\"display: none\">\n"
    + parts.joined(separator: "\n") + "\n</svg>"
var html = try String(contentsOf: deck, encoding: .utf8)
guard let start = html.range(of: startMarker), let end = html.range(of: endMarker) else {
    print("Markers not found in \(deck.path)")
    exit(1)
}
html.replaceSubrange(start.upperBound..<end.lowerBound, with: "\n\(sprite)\n")
try html.write(to: deck, atomically: true, encoding: .utf8)
print(
    "Inlined \(symbols.count) symbols and \(artwork.count) artworks (\(sprite.utf8.count / 1024) KB)"
)
