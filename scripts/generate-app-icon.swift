import AppKit
import Foundation

// Native vector drawing, rendered at every required macOS app-icon resolution.
let directory = URL(fileURLWithPath: CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "CalendarX/Assets.xcassets/AppIcon.appiconset")
for size in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        let pixels = size * scale
        guard let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: pixels * 4, bitsPerPixel: 32) else { fatalError("Cannot create bitmap") }
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
        let transform = NSAffineTransform()
        transform.scale(by: CGFloat(pixels) / 1024)
        transform.concat()
        NSColor(calibratedRed: 0.985, green: 0.968, blue: 0.933, alpha: 1).setFill()
        NSBezierPath(roundedRect: NSRect(x: 72, y: 72, width: 880, height: 880), xRadius: 198, yRadius: 198).fill()
        let ink = NSColor(calibratedRed: 0.70, green: 0.23, blue: 0.20, alpha: 1)
        ink.setFill()
        NSBezierPath(roundedRect: NSRect(x: 240, y: 230, width: 544, height: 594), xRadius: 94, yRadius: 94).fill()
        NSColor(calibratedRed: 0.985, green: 0.968, blue: 0.933, alpha: 1).setFill()
        NSBezierPath(roundedRect: NSRect(x: 269, y: 259, width: 486, height: 410), xRadius: 66, yRadius: 66).fill()
        let ring = NSBezierPath()
        ring.lineWidth = 36
        ring.lineCapStyle = .round
        ring.move(to: NSPoint(x: 374, y: 778)); ring.line(to: NSPoint(x: 374, y: 864))
        ring.move(to: NSPoint(x: 650, y: 778)); ring.line(to: NSPoint(x: 650, y: 864))
        ink.setStroke(); ring.stroke()
        ink.setFill()
        NSBezierPath(ovalIn: NSRect(x: 398, y: 349, width: 238, height: 238)).fill()
        NSColor(calibratedRed: 0.985, green: 0.968, blue: 0.933, alpha: 1).setFill()
        NSBezierPath(ovalIn: NSRect(x: 470, y: 405, width: 205, height: 205)).fill()
        ink.setFill()
        let star = NSBezierPath()
        star.move(to: NSPoint(x: 651, y: 606)); star.line(to: NSPoint(x: 662, y: 577))
        star.line(to: NSPoint(x: 691, y: 566)); star.line(to: NSPoint(x: 662, y: 555))
        star.line(to: NSPoint(x: 651, y: 526)); star.line(to: NSPoint(x: 640, y: 555))
        star.line(to: NSPoint(x: 611, y: 566)); star.line(to: NSPoint(x: 640, y: 577)); star.close(); star.fill()
        NSGraphicsContext.restoreGraphicsState()
        guard let png = bitmap.representation(using: .png, properties: [:]) else { fatalError("Cannot render app icon") }
        let name = "icon_\(size)x\(size)" + (scale == 2 ? "@2x" : "") + ".png"
        try png.write(to: directory.appendingPathComponent(name))
    }
}
