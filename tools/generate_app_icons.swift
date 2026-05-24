import AppKit
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

struct IconSlot {
    let filename: String
    let pixels: Int
}

let outputDirectory = URL(fileURLWithPath: "Assets.xcassets/AppIcon.appiconset", isDirectory: true)
let slots = [
    IconSlot(filename: "AppIcon-20x20@1x.png", pixels: 20),
    IconSlot(filename: "AppIcon-20x20@2x.png", pixels: 40),
    IconSlot(filename: "AppIcon-20x20@3x.png", pixels: 60),
    IconSlot(filename: "AppIcon-29x29@1x.png", pixels: 29),
    IconSlot(filename: "AppIcon-29x29@2x.png", pixels: 58),
    IconSlot(filename: "AppIcon-29x29@3x.png", pixels: 87),
    IconSlot(filename: "AppIcon-40x40@1x.png", pixels: 40),
    IconSlot(filename: "AppIcon-40x40@2x.png", pixels: 80),
    IconSlot(filename: "AppIcon-40x40@3x.png", pixels: 120),
    IconSlot(filename: "AppIcon-60x60@2x.png", pixels: 120),
    IconSlot(filename: "AppIcon-60x60@3x.png", pixels: 180),
    IconSlot(filename: "AppIcon-76x76@2x.png", pixels: 152),
    IconSlot(filename: "AppIcon-83.5x83.5@2x.png", pixels: 167),
    IconSlot(filename: "AppIcon-1024x1024@1x.png", pixels: 1024)
]

func color(_ hex: UInt32) -> CGColor {
    let r = CGFloat((hex >> 16) & 0xff) / 255.0
    let g = CGFloat((hex >> 8) & 0xff) / 255.0
    let b = CGFloat(hex & 0xff) / 255.0
    return CGColor(red: r, green: g, blue: b, alpha: 1)
}

func drawIcon(size: Int) -> CGImage {
    let scale = CGFloat(size)
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let context = CGContext(
        data: nil,
        width: size,
        height: size,
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    )!

    context.setAllowsAntialiasing(true)
    context.setShouldAntialias(true)

    let background = CGGradient(
        colorsSpace: colorSpace,
        colors: [color(0x08131F), color(0x10263A), color(0x0F4F58)] as CFArray,
        locations: [0.0, 0.58, 1.0]
    )!
    context.drawLinearGradient(
        background,
        start: CGPoint(x: scale * 0.12, y: scale * 0.08),
        end: CGPoint(x: scale * 0.9, y: scale * 0.96),
        options: []
    )

    let glow = CGGradient(
        colorsSpace: colorSpace,
        colors: [
            CGColor(red: 0.0, green: 0.88, blue: 0.78, alpha: 0.42),
            CGColor(red: 0.0, green: 0.88, blue: 0.78, alpha: 0.0)
        ] as CFArray,
        locations: [0.0, 1.0]
    )!
    context.drawRadialGradient(
        glow,
        startCenter: CGPoint(x: scale * 0.72, y: scale * 0.28),
        startRadius: scale * 0.02,
        endCenter: CGPoint(x: scale * 0.72, y: scale * 0.28),
        endRadius: scale * 0.62,
        options: []
    )

    let panelRect = CGRect(x: scale * 0.17, y: scale * 0.18, width: scale * 0.66, height: scale * 0.64)
    let panelPath = CGPath(
        roundedRect: panelRect,
        cornerWidth: scale * 0.12,
        cornerHeight: scale * 0.12,
        transform: nil
    )
    context.addPath(panelPath)
    context.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.10))
    context.fillPath()

    context.saveGState()
    context.addPath(panelPath)
    context.clip()
    let panelGradient = CGGradient(
        colorsSpace: colorSpace,
        colors: [
            CGColor(red: 1, green: 1, blue: 1, alpha: 0.24),
            CGColor(red: 1, green: 1, blue: 1, alpha: 0.04)
        ] as CFArray,
        locations: [0.0, 1.0]
    )!
    context.drawLinearGradient(
        panelGradient,
        start: CGPoint(x: panelRect.minX, y: panelRect.minY),
        end: CGPoint(x: panelRect.maxX, y: panelRect.maxY),
        options: []
    )
    context.restoreGState()

    let axisWidth = max(1.6, scale * 0.018)
    context.setLineCap(.round)
    context.setLineJoin(.round)
    context.setStrokeColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.24))
    context.setLineWidth(axisWidth)
    for index in 0..<3 {
        let y = scale * (0.34 + CGFloat(index) * 0.12)
        context.move(to: CGPoint(x: scale * 0.26, y: y))
        context.addLine(to: CGPoint(x: scale * 0.74, y: y))
        context.strokePath()
    }

    let chartPath = CGMutablePath()
    chartPath.move(to: CGPoint(x: scale * 0.27, y: scale * 0.63))
    chartPath.addCurve(
        to: CGPoint(x: scale * 0.46, y: scale * 0.52),
        control1: CGPoint(x: scale * 0.33, y: scale * 0.61),
        control2: CGPoint(x: scale * 0.38, y: scale * 0.55)
    )
    chartPath.addCurve(
        to: CGPoint(x: scale * 0.59, y: scale * 0.42),
        control1: CGPoint(x: scale * 0.51, y: scale * 0.50),
        control2: CGPoint(x: scale * 0.53, y: scale * 0.43)
    )
    chartPath.addCurve(
        to: CGPoint(x: scale * 0.74, y: scale * 0.30),
        control1: CGPoint(x: scale * 0.64, y: scale * 0.41),
        control2: CGPoint(x: scale * 0.68, y: scale * 0.34)
    )

    context.addPath(chartPath)
    context.setStrokeColor(color(0x25E0C3))
    context.setLineWidth(max(3.0, scale * 0.052))
    context.strokePath()

    context.addPath(chartPath)
    context.setStrokeColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.72))
    context.setLineWidth(max(1.4, scale * 0.018))
    context.strokePath()

    let barY = scale * 0.69
    let barHeight = max(3.0, scale * 0.068)
    let barPath = CGPath(
        roundedRect: CGRect(x: scale * 0.28, y: barY, width: scale * 0.44, height: barHeight),
        cornerWidth: barHeight / 2,
        cornerHeight: barHeight / 2,
        transform: nil
    )
    context.addPath(barPath)
    context.setFillColor(color(0xF5A524))
    context.fillPath()

    let plateWidth = scale * 0.055
    let plateHeight = scale * 0.17
    for x in [scale * 0.22, scale * 0.72] {
        let plate = CGRect(x: x, y: barY - scale * 0.05, width: plateWidth, height: plateHeight)
        context.addPath(CGPath(
            roundedRect: plate,
            cornerWidth: plateWidth * 0.35,
            cornerHeight: plateWidth * 0.35,
            transform: nil
        ))
        context.setFillColor(color(0xF5A524))
        context.fillPath()
    }

    let badgeRect = CGRect(x: scale * 0.56, y: scale * 0.52, width: scale * 0.19, height: scale * 0.19)
    context.addEllipse(in: badgeRect)
    context.setFillColor(color(0xFF5E57))
    context.fillPath()
    context.addEllipse(in: badgeRect.insetBy(dx: scale * 0.045, dy: scale * 0.045))
    context.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.84))
    context.fillPath()

    return context.makeImage()!
}

func writePNG(_ image: CGImage, to url: URL) {
    let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(destination, image, nil)
    guard CGImageDestinationFinalize(destination) else {
        fatalError("Failed to write \(url.path)")
    }
}

for slot in slots {
    writePNG(drawIcon(size: slot.pixels), to: outputDirectory.appendingPathComponent(slot.filename))
}
