import AppKit
import CoreGraphics

// App icon: charcoal background + an orange radial-gradient sphere (orb).
// Trademark-safe — evokes Blender's orange-on-dark feel without reproducing the logo.
// Usage: swift make_icon.swift /path/to/out_1024.png

let size = 1024
guard let rep = NSBitmapImageRep(bitmapDataPlanes: nil,
                                 pixelsWide: size, pixelsHigh: size,
                                 bitsPerSample: 8, samplesPerPixel: 4,
                                 hasAlpha: true, isPlanar: false,
                                 colorSpaceName: .deviceRGB,
                                 bytesPerRow: 0, bitsPerPixel: 0) else { fatalError("rep") }
guard let ctx = NSGraphicsContext(bitmapImageRep: rep) else { fatalError("ctx") }
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = ctx
let cg = ctx.cgContext
let W = CGFloat(size), H = CGFloat(size)
let space = CGColorSpaceCreateDeviceRGB()

// Work in screen-like (y-down) coordinates.
cg.translateBy(x: 0, y: H)
cg.scaleBy(x: 1, y: -1)

// Background: charcoal gradient.
let bgColors = [CGColor(srgbRed: 0.23, green: 0.24, blue: 0.26, alpha: 1.0),
                CGColor(srgbRed: 0.10, green: 0.11, blue: 0.12, alpha: 1.0)] as CFArray
let bg = CGGradient(colorsSpace: space, colors: bgColors, locations: [0.0, 1.0])!
cg.drawLinearGradient(bg, start: CGPoint(x: 0, y: 0), end: CGPoint(x: W, y: H), options: [])

// Orange sphere with a radial gradient (highlight toward upper-left for volume).
let cxx = W / 2, cyy = H / 2
let r: CGFloat = 330
cg.saveGState()
cg.beginPath()
cg.addEllipse(in: CGRect(x: cxx - r, y: cyy - r, width: 2 * r, height: 2 * r))
cg.clip()
let orange = [CGColor(srgbRed: 1.00, green: 0.82, blue: 0.45, alpha: 1.0),
              CGColor(srgbRed: 0.96, green: 0.49, blue: 0.16, alpha: 1.0),
              CGColor(srgbRed: 0.71, green: 0.27, blue: 0.04, alpha: 1.0)] as CFArray
let og = CGGradient(colorsSpace: space, colors: orange, locations: [0.0, 0.55, 1.0])!
let highlight = CGPoint(x: cxx - 110, y: cyy - 130)
cg.drawRadialGradient(og,
                      startCenter: highlight, startRadius: 20,
                      endCenter: CGPoint(x: cxx, y: cyy), endRadius: r,
                      options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
cg.restoreGState()

NSGraphicsContext.restoreGraphicsState()
guard let data = rep.representation(using: .png, properties: [:]) else { fatalError("png") }
let outPath = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "/tmp/icon_1024.png"
try! data.write(to: URL(fileURLWithPath: outPath))
print("wrote \(outPath)")
