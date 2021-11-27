import AppKit
import DMCWingWorks
import Foundation

/// Makes PNG images (movie frames) from world state
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
    let foil: AirFoil
    let foilForce: Vector
    let edgeForces: [Vector]
    let air: [ParticleGeom]

    public init(world: World, width: Int, height: Int, title: String) {
        // Expedient: assume the world has same aspect ratio as width/height
        imgWidth = Double(width)
        imgHeight = Double(height)
        self.title = title
        scale = imgWidth / world.worldWidth
        foil = world.airfoil
        foilForce = world.forceOnFoil()
        edgeForces = world.foilEdgeForces()
        air = world.air.map { (p) -> ParticleGeom in
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
        // Manually scale coords to avoid upscaling fuzziness/jaggies.

        let tracerColor = NSColor.init(
            calibratedRed: 1.0, green: 0.4, blue: 0.4, alpha: 1.0)
        let airColor = NSColor.init(
            calibratedRed: 0.0, green: 0.8, blue: 1.0, alpha: 0.3)

        airColor.setFill()
        airColor.set()

        for (i, particle) in air.enumerated() {
            let isTracer = (0 == i % 1000)

            let r = particle.radius * scale
            let d = 2 * r * (isTracer ? 3.0 : 1.0)
            let x = particle.x * scale - r
            let y = particle.y * scale - r
            let prect = NSRect(x: x, y: y, width: d, height: d)
            let p = NSBezierPath(ovalIn: prect)
            p.lineWidth = 0.1

            if isTracer {
                tracerColor.setFill()
                tracerColor.set()
            } else {
                airColor.setFill()
                airColor.set()
            }
            p.fill()
        }
    }

    private func drawFoil(_ rect: NSRect) {
        let path = NSBezierPath()
        let vertices = foil.shape.vertices
        let first = vertices[0]
        path.move(to: CGPoint(x: first.x * scale, y: first.y * scale))
        for vertex in vertices[1...] {
            let scaledVertex = CGPoint(x: vertex.x * scale, y: vertex.y * scale)
            path.line(to: scaledVertex)
        }
        path.close()

        let fillColor = NSColor.gray
        fillColor.setFill()
        path.fill()

        let strokeColor = NSColor.black
        strokeColor.set()
        path.lineWidth = 1.0
        path.stroke()
    }

    private func drawEdgeForces(_ rect: NSRect) {
        for i in 0..<foil.shape.edges.count {
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
        let magAlongNormal = edgeForce.dot(foil.shape.edgeNormals[i])
        let isInward = magAlongNormal < 0

        let color = isInward ? NSColor.red : NSColor.blue
        color.set()
        color.setFill()

        let arrow = arrowShape(length: mag * scale * forceScale, width: 3.0)

        // If the force is outward, offset the arrow so its tail will touch
        // the foil edge.
        let arrowLength = arrow.bounds.width
        let headXOffset = isInward ? 0.0 : arrowLength
        let headOffset = AffineTransform(
            translationByX: CGFloat(headXOffset), byY: 0.0)

        // Would that I understood quaternions...
        let angle = edgeForce.angle()
        let rot = AffineTransform(rotationByRadians: CGFloat(angle))

        // Anchor at the edge midpoint.
        let edge = foil.shape.edges[i]
        let xMid = scale * (edge.p0.x + edge.pf.x) / 2
        let yMid = scale * (edge.p0.y + edge.pf.y) / 2
        let anchorOffset = AffineTransform(
            translationByX: CGFloat(xMid), byY: CGFloat(yMid))

        var arrowHeadTransform = AffineTransform.identity
        arrowHeadTransform.append(headOffset)
        arrowHeadTransform.append(rot)
        arrowHeadTransform.append(anchorOffset)
        arrow.transform(using: arrowHeadTransform)

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

        let arrowWidth = scale * foil.shape.bbox.width / 50.0
        let arrow = arrowShape(
            length: foilForce.magnitude() * scale * forceScale,
            width: arrowWidth)

        // Offset the shape so its tail, rather than its head, will touch anchorOffset.
        let headOffset = AffineTransform(
            translationByX: arrow.bounds.width, byY: 0.0)
        let rot = AffineTransform(rotationByRadians: CGFloat(foilForce.angle()))
        // Anchor the force vector somewhere near the foil's center.
        let anchor = foil.shape.center
        let anchorOffset = AffineTransform(
            translationByX: anchor.x * scale, byY: anchor.y * scale)

        var transform = AffineTransform.identity
        transform.append(headOffset)
        transform.append(rot)
        transform.append(anchorOffset)
        arrow.transform(using: transform)

        NSColor.lightGray.set()
        NSColor.white.setFill()
        arrow.lineWidth = 0.4
        arrow.lineCapStyle = .round
        arrow.lineJoinStyle = .miter
        arrow.stroke()
        arrow.fill()
    }

    // Get a shape (a Bezier path) for an arrow with a given shaft length.
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
