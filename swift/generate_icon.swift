#!/usr/bin/env swift

import Cocoa

func generateIcon(size: Int) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()

    let s = CGFloat(size)
    let rect = NSRect(x: 0, y: 0, width: s, height: s)

    // ── Background: warm amber-to-deep-sienna gradient ──────────────────────
    let cornerRadius = s * 0.22
    let bgPath = NSBezierPath(roundedRect: rect, xRadius: cornerRadius, yRadius: cornerRadius)
    let gradient = NSGradient(colors: [
        NSColor(red: 0.93, green: 0.62, blue: 0.28, alpha: 1.0),   // warm amber top
        NSColor(red: 0.58, green: 0.26, blue: 0.08, alpha: 1.0),   // deep sienna bottom
    ])!
    gradient.draw(in: bgPath, angle: -60)

    // ── Inner glow (soft warm center) ───────────────────────────────────────
    let glowGradient = NSGradient(colors: [
        NSColor(red: 1.0, green: 0.85, blue: 0.55, alpha: 0.30),
        NSColor(red: 1.0, green: 0.65, blue: 0.20, alpha: 0.00),
    ])!
    let glowCenter = NSPoint(x: s * 0.50, y: s * 0.38)
    glowGradient.draw(fromCenter: glowCenter, radius: 0, toCenter: glowCenter, radius: s * 0.48, options: [])

    // ── Flame shape ─────────────────────────────────────────────────────────
    // Built from bezier curves — a classic upright flame
    let cx = s * 0.50           // horizontal center
    let base = s * 0.18         // flame base y
    let tip  = s * 0.88         // flame tip y
    let fw   = s * 0.28         // half-width at widest

    let flame = NSBezierPath()
    // Start at bottom-left of flame base
    flame.move(to: NSPoint(x: cx - fw * 0.6, y: base))

    // Left side: curve up to the tip
    flame.curve(
        to: NSPoint(x: cx, y: tip),
        controlPoint1: NSPoint(x: cx - fw * 1.1, y: base + s * 0.25),
        controlPoint2: NSPoint(x: cx - fw * 0.5, y: tip - s * 0.10)
    )

    // Right side: curve back down to base
    flame.curve(
        to: NSPoint(x: cx + fw * 0.6, y: base),
        controlPoint1: NSPoint(x: cx + fw * 0.5, y: tip - s * 0.10),
        controlPoint2: NSPoint(x: cx + fw * 1.1, y: base + s * 0.25)
    )

    // Bottom arc to close
    flame.curve(
        to: NSPoint(x: cx - fw * 0.6, y: base),
        controlPoint1: NSPoint(x: cx + fw * 0.3, y: base - s * 0.02),
        controlPoint2: NSPoint(x: cx - fw * 0.3, y: base - s * 0.02)
    )
    flame.close()

    // Fill flame with white-to-cream gradient (simulates inner light)
    NSGraphicsContext.saveGraphicsState()
    flame.setClip()
    let flameGrad = NSGradient(colors: [
        NSColor(white: 1.0, alpha: 0.95),
        NSColor(red: 1.0, green: 0.88, blue: 0.60, alpha: 0.75),
    ])!
    flameGrad.draw(in: flame.bounds, angle: 90)
    NSGraphicsContext.restoreGraphicsState()

    // ── Inner flame (warm core) ──────────────────────────────────────────────
    let innerFlame = NSBezierPath()
    let ifw = fw * 0.50
    let ibase = base + s * 0.06
    let itip  = tip  - s * 0.18

    innerFlame.move(to: NSPoint(x: cx - ifw * 0.5, y: ibase))
    innerFlame.curve(
        to: NSPoint(x: cx, y: itip),
        controlPoint1: NSPoint(x: cx - ifw * 1.0, y: ibase + s * 0.16),
        controlPoint2: NSPoint(x: cx - ifw * 0.4, y: itip - s * 0.08)
    )
    innerFlame.curve(
        to: NSPoint(x: cx + ifw * 0.5, y: ibase),
        controlPoint1: NSPoint(x: cx + ifw * 0.4, y: itip - s * 0.08),
        controlPoint2: NSPoint(x: cx + ifw * 1.0, y: ibase + s * 0.16)
    )
    innerFlame.curve(
        to: NSPoint(x: cx - ifw * 0.5, y: ibase),
        controlPoint1: NSPoint(x: cx + ifw * 0.25, y: ibase),
        controlPoint2: NSPoint(x: cx - ifw * 0.25, y: ibase)
    )
    innerFlame.close()

    NSGraphicsContext.saveGraphicsState()
    innerFlame.setClip()
    let innerGrad = NSGradient(colors: [
        NSColor(red: 1.00, green: 0.75, blue: 0.30, alpha: 0.90),
        NSColor(red: 0.95, green: 0.45, blue: 0.10, alpha: 0.60),
    ])!
    innerGrad.draw(in: innerFlame.bounds, angle: 90)
    NSGraphicsContext.restoreGraphicsState()

    // ── Subtle drop shadow on flame ──────────────────────────────────────────
    // (drawn by adding a slightly larger semi-transparent path behind)
    // We drew it above; the shadow effect comes from the background gradient

    // ── App name "ember" in small elegant serif at bottom ───────────────────
    let fontSize = s * 0.115
    let font = NSFont(name: "Georgia", size: fontSize) ?? NSFont.systemFont(ofSize: fontSize)
    let attrs: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: NSColor(white: 1.0, alpha: 0.75),
        .kern: s * 0.015,
    ]
    let label = NSAttributedString(string: "ember", attributes: attrs)
    let labelSize = label.size()
    label.draw(at: NSPoint(x: (s - labelSize.width) / 2, y: s * 0.06))

    image.unlockFocus()
    return image
}

func savePNG(_ image: NSImage, to path: String, size: Int) {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: size,
        pixelsHigh: size,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    )!

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    image.draw(in: NSRect(x: 0, y: 0, width: size, height: size))
    NSGraphicsContext.restoreGraphicsState()

    let data = rep.representation(using: .png, properties: [:])!
    try! data.write(to: URL(fileURLWithPath: path))
    print("  Written: \(path)")
}

let sizes: [(points: Int, scale: Int)] = [
    (16, 1), (16, 2),
    (32, 1), (32, 2),
    (128, 1), (128, 2),
    (256, 1), (256, 2),
    (512, 1), (512, 2),
]

let iconDir = "Ember/Assets.xcassets/AppIcon.appiconset"
try? FileManager.default.createDirectory(atPath: iconDir, withIntermediateDirectories: true)

print("Generating Ember icons...")
for entry in sizes {
    let pixels = entry.points * entry.scale
    let image = generateIcon(size: pixels)
    let suffix = entry.scale > 1 ? "@\(entry.scale)x" : ""
    let filename = "icon_\(entry.points)x\(entry.points)\(suffix).png"
    savePNG(image, to: "\(iconDir)/\(filename)", size: pixels)
}
print("Done!")
