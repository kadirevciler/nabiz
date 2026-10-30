import AppKit

// Basit gradyanlı uygulama simgesi üretir: make_icon.swift <çıktı.iconset>
let out = URL(fileURLWithPath: CommandLine.arguments[1])
try? FileManager.default.createDirectory(at: out, withIntermediateDirectories: true)

func render(_ px: Int) -> Data {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: px, pixelsHigh: px, bitsPerSample: 8, samplesPerPixel: 4,
                               hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    let s = CGFloat(px), inset = s * 0.1
    let rect = NSRect(x: inset, y: inset, width: s - inset * 2, height: s - inset * 2)
    let path = NSBezierPath(roundedRect: rect, xRadius: rect.width * 0.225, yRadius: rect.width * 0.225)
    NSGradient(colors: [NSColor(red: 0.10, green: 0.08, blue: 0.22, alpha: 1), NSColor(red: 0.03, green: 0.04, blue: 0.09, alpha: 1)])!
        .draw(in: path, angle: -90)
    NSGradient(colors: [NSColor(red: 0.58, green: 0.45, blue: 1, alpha: 0.55), .clear])!
        .draw(in: path, relativeCenterPosition: NSPoint(x: -0.4, y: 0.5))
    let cfg = NSImage.SymbolConfiguration(pointSize: s * 0.42, weight: .bold)
    if let sym = NSImage(systemSymbolName: "waveform.path.ecg", accessibilityDescription: nil)?.withSymbolConfiguration(cfg) {
        let tinted = NSImage(size: sym.size, flipped: false) { r in
            sym.draw(in: r)
            NSGradient(colors: [NSColor(red: 0.58, green: 0.45, blue: 1, alpha: 1), NSColor(red: 0.25, green: 0.85, blue: 0.97, alpha: 1)])!
                .draw(in: r, angle: 0)
            return true
        }
        // gradyanı sembol şekline maskele
        let masked = NSImage(size: sym.size, flipped: false) { r in
            tinted.draw(in: r)
            sym.draw(in: r, from: .zero, operation: .destinationIn, fraction: 1)
            return true
        }
        let w = sym.size.width, h = sym.size.height
        masked.draw(in: NSRect(x: (s - w) / 2, y: (s - h) / 2, width: w, height: h))
    }
    NSGraphicsContext.restoreGraphicsState()
    return rep.representation(using: .png, properties: [:])!
}

for (name, px) in [("16x16", 16), ("16x16@2x", 32), ("32x32", 32), ("32x32@2x", 64), ("128x128", 128),
                   ("128x128@2x", 256), ("256x256", 256), ("256x256@2x", 512), ("512x512", 512), ("512x512@2x", 1024)] {
    try! render(px).write(to: out.appending(path: "icon_\(name).png"))
}
