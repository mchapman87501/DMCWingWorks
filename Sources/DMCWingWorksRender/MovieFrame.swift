import AppKit
import DMC2D
import DMCWingWorks
import Foundation

typealias Polygon = DMC2D.Polygon

/// Makes PNG images (movie frames) from world state.
public struct MovieFrame {
    struct ParticleGeom {
        let x: Double
        let y: Double
        let radius: Double
    }

    let imgWidth: Double
    let imgHeight: Double
    let title: String
    let scale: Double
    let forceScale = 1.0
    let foilShape: Polygon
    let foilForce: Vector
    let edgeForces: [Vector]
    let air: [ParticleGeom]

    public init(world: World, width: Int, height: Int, title: String) {
        // Expedient: assume the world has same aspect ratio as width/height
        imgWidth = Double(width)
        imgHeight = Double(height)
        self.title = title
        scale = imgWidth / world.worldWidth
        foilShape = world.airfoil.shape
        foilForce = world.forceOnFoil()
        edgeForces = world.foilEdgeForces()
        air = world.air.map { p -> ParticleGeom in
            let pos = p.pos()
            return ParticleGeom(x: pos.x, y: pos.y, radius: p.radius)
        }
    }

    public func createFrame(alpha: Double = 1.0) -> NSImage {
        let size = NSSize(width: imgWidth, height: imgHeight)

        return NSImage(size: size, flipped: false) { rect in
            drawBackground(rect)
            drawAir(rect)
            drawEdgeForces(rect)
            drawFoil(rect)
            drawNetForceOnFoil(rect)
            drawLegend(rect)
            overlayAlpha(rect, alpha: alpha)
            return true
        }
    }

    private func drawBackground(_ rect: NSRect) {
        NSColor.white.setFill()
        NSBezierPath.fill(rect)
    }

    private func overlayAlpha(_ rect: NSRect, alpha: Double) {
        NSColor.black.withAlphaComponent(1.0 - alpha).setFill()
        NSBezierPath.fill(rect)
    }

    private func drawAir(_ rect: NSRect) {
        let tracerColor = NSColor(
            calibratedRed: 1.0, green: 0.4, blue: 0.4, alpha: 1.0)
        let airColor = NSColor(
            calibratedRed: 0.0, green: 0.8, blue: 1.0, alpha: 0.3)

        for (i, particle) in air.enumerated() {
            let isTracer = (0 == i % 1000)

            let r = particle.radius * scale * (isTracer ? 3.0 : 1.0)
            let d = 2 * r
            let x = particle.x * scale - r
            let y = particle.y * scale - r
            let prect = NSRect(x: x, y: y, width: d, height: d)
            let p = NSBezierPath(ovalIn: prect)
            if isTracer {
                tracerColor.setFill()
            } else {
                airColor.setFill()
            }
            p.fill()
        }
    }

    private func drawFoil(_ rect: NSRect) {
        let path = NSBezierPath()
        let vertices = foilShape.vertices
        let first = vertices[0]
        path.move(to: CGPoint(x: first.x * scale, y: first.y * scale))
        for vertex in vertices[1...] {
            path.line(to: CGPoint(x: vertex.x * scale, y: vertex.y * scale))
        }
        path.close()

        let fillColor = NSColor.gray
        fillColor.setFill()
        path.fill()

        let strokeColor = NSColor.black
        strokeColor.set()
        path.stroke()
    }

    private func drawEdgeForces(_ rect: NSRect) {
        for i in 0..<foilShape.edges.count {
            drawEdgeForce(rect, index: i)
        }
    }

    private func drawEdgeForce(_ rect: NSRect, index i: Int) {
        let edgeForce = edgeForces[i]
        let mag = edgeForce.magnitude()
        // Too small?  Don't show it.
        guard mag > 0.1 else { return }

        // If the force is inward, it will have a negative extent along
        // the edge normal.
        let magAlongNormal = edgeForce.dot(foilShape.edgeNormals[i])
        let isInward = magAlongNormal < 0

        let color = isInward ? NSColor.red : NSColor.blue
        color.set()
        color.setFill()

        // Anchor at the edge midpoint.
        let edge = foilShape.edges[i]
        let xMid = scale * (edge.p0.x + edge.pf.x) / 2
        let yMid = scale * (edge.p0.y + edge.pf.y) / 2
        let tipAnchor = Vector(x: xMid, y: yMid)
        let arrow = ArrowShapeMaker().getArrowShape(
            vector: edgeForce * scale, tipAnchor: tipAnchor, width: 3.0)

        arrow.lineWidth = 0.2
        arrow.lineCapStyle = .round
        arrow.lineJoinStyle = .miter
        arrow.stroke()
        arrow.fill()
    }

    private func drawNetForceOnFoil(_ rect: NSRect) {
        if foilForce.magSqr() <= 0.0 {
            return
        }

        let tailAnchor = Vector(foilShape.center) * scale
        let arrowWidth = scale * foilShape.bbox.width / 50.0
        let arrow = ArrowShapeMaker().getArrowShape(
            vector: foilForce * scale, tailAnchor: tailAnchor,
            width: arrowWidth)

        NSColor.lightGray.set()
        NSColor.white.setFill()
        arrow.lineWidth = 0.4
        arrow.lineCapStyle = .round
        arrow.lineJoinStyle = .miter
        arrow.stroke()
        arrow.fill()
    }

    // Get a a Bezier path for an arrow with a given shaft length.
    // The arrowhead size is fixed.
    // The arrow points in the positive x direction.
    private func arrowShape(length shaftLength: Double, width: Double)
        -> NSBezierPath
    {
        let arrow = NSBezierPath()

        let arrSz = 5.0 * width / 2.0
        let yLineOffset = width / 2.0
        // Let positive X direction be zero rotation.

        // This is the arrowhead.
        let first = NSPoint(x: -1.5 * arrSz, y: yLineOffset)
        arrow.move(to: first)
        arrow.line(to: NSPoint(x: -2.0 * arrSz, y: arrSz))
        arrow.line(to: NSPoint(x: 0.0, y: 0.0))
        arrow.line(to: NSPoint(x: -2.0 * arrSz, y: -arrSz))
        arrow.line(to: NSPoint(x: -1.5 * arrSz, y: -yLineOffset))

        // This is the shaft.
        let xShaftEnd = -1.5 * arrSz - shaftLength
        let shaftEnd1 = NSPoint(x: xShaftEnd, y: -yLineOffset)
        let shaftEnd2 = NSPoint(x: xShaftEnd, y: yLineOffset)
        let arcCenter = NSPoint(x: xShaftEnd - width, y: 0.0)

        // Add a half-circle from shaftEnd1 to the implied shaftEnd2.
        arrow.line(to: shaftEnd1)
        arrow.appendArc(from: arcCenter, to: shaftEnd2, radius: width / 2.0)
        // Connect back to the arrowhead.
        arrow.close()

        return arrow
    }

    private func drawLegend(_ fullRect: NSRect) {
        if title.isEmpty {
            return
        }
        let width = fullRect.width / 4
        let height = fullRect.height / 4

        let mfSize = 10.0
        let measureFont = NSFont.systemFont(ofSize: mfSize)
        let measureAttrs = [
            NSAttributedString.Key.font: measureFont
        ]
        let refTitleSize = (title as NSString).size(
            withAttributes: measureAttrs)

        let scale = min(
            width / refTitleSize.width, height / refTitleSize.height)
        let fontSize = scale * mfSize
        let font = NSFont.systemFont(ofSize: fontSize)
        let attrs = [
            NSAttributedString.Key.font: font,
            NSAttributedString.Key.foregroundColor: NSColor.black,
        ]
        let titleSize = (title as String).size(withAttributes: attrs)

        // Create a background rect that fits the text plus some margin.
        let marginFract = 0.05  // Margin within the background rect
        let bgWidth = titleSize.width * (1.0 + 2.0 * marginFract)
        let bgHeight = titleSize.height * (1.0 + 2.0 * marginFract)

        let bgOffset = 10.0
        let bgOrigin = CGPoint(
            x: fullRect.origin.x + bgOffset,
            y: fullRect.height - bgHeight - bgOffset)
        let bgSize = NSSize(width: bgWidth, height: bgHeight)
        let backgroundRect = NSRect(origin: bgOrigin, size: bgSize)

        NSColor(calibratedWhite: 1.0, alpha: 0.3).setFill()
        NSBezierPath.fill(backgroundRect)

        let xPos = bgOrigin.x + (bgWidth - titleSize.width) / 2.0
        let yPos = bgOrigin.y + (bgHeight - titleSize.height) / 2.0

        (title as NSString).draw(
            at: NSPoint(x: xPos, y: yPos),
            withAttributes: attrs)

        NSColor.black.setStroke()
        NSBezierPath.stroke(backgroundRect)
    }
}
