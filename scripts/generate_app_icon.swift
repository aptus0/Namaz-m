import AppKit
import Foundation

let outputDirectoryPath: String
if CommandLine.arguments.count > 1 {
    outputDirectoryPath = CommandLine.arguments[1]
} else {
    outputDirectoryPath = "Namazım/Assets.xcassets/AppIcon.appiconset"
}

let outputDirectory = URL(fileURLWithPath: outputDirectoryPath, isDirectory: true)
let size = CGSize(width: 1024, height: 1024)

func drawSharedMark(
    on rect: CGRect,
    mainColor: NSColor,
    cutoutColor: NSColor,
    minaretColor: NSColor,
    starColor: NSColor,
    withGlow: Bool
) {
    if withGlow {
        let glowRect = CGRect(x: rect.midX - 340, y: rect.midY - 340, width: 680, height: 680)
        let gradient = NSGradient(colors: [mainColor.withAlphaComponent(0.20), .clear])
        gradient?.draw(in: NSBezierPath(ovalIn: glowRect), relativeCenterPosition: .zero)
    }

    let outerMoon = NSBezierPath(ovalIn: CGRect(x: 210, y: 190, width: 600, height: 600))
    let innerCut = NSBezierPath(ovalIn: CGRect(x: 360, y: 235, width: 500, height: 500))
    outerMoon.append(innerCut)
    outerMoon.windingRule = .evenOdd
    mainColor.setFill()
    outerMoon.fill()

    let minaretBody = NSBezierPath(roundedRect: CGRect(x: 520, y: 300, width: 82, height: 360), xRadius: 36, yRadius: 36)
    minaretColor.setFill()
    minaretBody.fill()

    let minaretTop = NSBezierPath()
    minaretTop.move(to: CGPoint(x: 500, y: 660))
    minaretTop.line(to: CGPoint(x: 561, y: 752))
    minaretTop.line(to: CGPoint(x: 622, y: 660))
    minaretTop.close()
    minaretColor.setFill()
    minaretTop.fill()

    let minaretSpire = NSBezierPath(roundedRect: CGRect(x: 550, y: 742, width: 22, height: 86), xRadius: 10, yRadius: 10)
    minaretSpire.fill()

    let starPath = NSBezierPath()
    let center = CGPoint(x: 385, y: 735)
    let points = 5
    let outerRadius: CGFloat = 35
    let innerRadius: CGFloat = 15
    var angle = -CGFloat.pi / 2
    let step = CGFloat.pi / CGFloat(points)

    for index in 0..<(points * 2) {
        let radius = index.isMultiple(of: 2) ? outerRadius : innerRadius
        let point = CGPoint(x: center.x + cos(angle) * radius, y: center.y + sin(angle) * radius)
        if index == 0 {
            starPath.move(to: point)
        } else {
            starPath.line(to: point)
        }
        angle += step
    }

    starPath.close()
    starColor.setFill()
    starPath.fill()

    // Tiny cutout to keep the crescent edge crisp.
    let cutout = NSBezierPath(ovalIn: CGRect(x: 350, y: 275, width: 500, height: 500))
    cutoutColor.setFill()
    cutout.fill()
}

func renderIcon(
    fileName: String,
    backgroundColor: NSColor,
    mainColor: NSColor,
    minaretColor: NSColor,
    starColor: NSColor,
    cutoutColor: NSColor,
    withGlow: Bool,
    transparentBackground: Bool
) throws {
    let rect = CGRect(origin: .zero, size: size)
    guard let cgContext = CGContext(
        data: nil,
        width: Int(size.width),
        height: Int(size.height),
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else {
        throw NSError(
            domain: "icon",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: "Failed to allocate CoreGraphics context"]
        )
    }

    cgContext.interpolationQuality = .high

    let context = NSGraphicsContext(cgContext: cgContext, flipped: false)

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = context

    if !transparentBackground {
        backgroundColor.setFill()
        rect.fill()
    }

    drawSharedMark(
        on: rect,
        mainColor: mainColor,
        cutoutColor: cutoutColor,
        minaretColor: minaretColor,
        starColor: starColor,
        withGlow: withGlow
    )

    context.flushGraphics()
    NSGraphicsContext.restoreGraphicsState()

    guard let cgImage = cgContext.makeImage() else {
        throw NSError(
            domain: "icon",
            code: 3,
            userInfo: [NSLocalizedDescriptionKey: "Failed to create image from context"]
        )
    }

    let rep = NSBitmapImageRep(cgImage: cgImage)
    rep.size = size

    guard let pngData = rep.representation(using: .png, properties: [:]) else {
        throw NSError(
            domain: "icon",
            code: 4,
            userInfo: [NSLocalizedDescriptionKey: "Failed to export image"]
        )
    }

    try pngData.write(to: outputDirectory.appendingPathComponent(fileName), options: .atomic)
}

try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)

try renderIcon(
    fileName: "icon-main.png",
    backgroundColor: NSColor(calibratedRed: 0.055, green: 0.086, blue: 0.149, alpha: 1),
    mainColor: NSColor(calibratedRed: 0.831, green: 0.686, blue: 0.247, alpha: 1),
    minaretColor: NSColor(calibratedRed: 0.831, green: 0.686, blue: 0.247, alpha: 1),
    starColor: NSColor(calibratedRed: 0.95, green: 0.82, blue: 0.48, alpha: 1),
    cutoutColor: NSColor(calibratedRed: 0.055, green: 0.086, blue: 0.149, alpha: 1),
    withGlow: true,
    transparentBackground: false
)

try renderIcon(
    fileName: "icon-dark.png",
    backgroundColor: NSColor(calibratedRed: 0.035, green: 0.050, blue: 0.090, alpha: 1),
    mainColor: NSColor(calibratedRed: 0.854, green: 0.725, blue: 0.360, alpha: 1),
    minaretColor: NSColor(calibratedRed: 0.854, green: 0.725, blue: 0.360, alpha: 1),
    starColor: NSColor(calibratedRed: 0.97, green: 0.86, blue: 0.58, alpha: 1),
    cutoutColor: NSColor(calibratedRed: 0.035, green: 0.050, blue: 0.090, alpha: 1),
    withGlow: true,
    transparentBackground: false
)

try renderIcon(
    fileName: "icon-tinted.png",
    backgroundColor: .clear,
    mainColor: NSColor(calibratedWhite: 0.05, alpha: 1),
    minaretColor: NSColor(calibratedWhite: 0.05, alpha: 1),
    starColor: NSColor(calibratedWhite: 0.05, alpha: 1),
    cutoutColor: .clear,
    withGlow: false,
    transparentBackground: true
)

print("Generated icons in \(outputDirectory.path)")
