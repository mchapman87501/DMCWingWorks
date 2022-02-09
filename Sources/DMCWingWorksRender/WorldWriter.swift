import AppKit
import DMCMovieWriter
import DMCWingWorks
import Foundation

/// Create a movie showing the evolving state of a `World` particle simulation.
public struct WorldWriter {
    let world: World
    let width: Int
    let height: Int
    let title: String
    let movieWriter: DMCMovieWriter

    public init(
        world: World, writingTo: URL, width: Int, height: Int,
        title: String = ""
    ) throws {
        self.world = world
        self.width = width
        self.height = height
        self.title = title
        movieWriter = try DMCMovieWriter(
            outpath: writingTo, width: width, height: height)
    }

    public func finish() throws {
        try movieWriter.finish()
    }

    /// Add a title frame.
    /// - Parameters:
    ///   - title: Text to show in the title frame.  Multiline text *should* be supported, but I can't guarantee that it will be.
    ///   - duration: How long to display the title frame, excluding any fade-in/out time.
    public func showTitle(_ title: String, duration seconds: Int = 3) throws {
        let size = NSSize(width: width, height: height)

        let numRampFrames = 30
        let rampFrameDuration = 1.0 / 30.0

        var alpha = 0.0
        let dAlpha = 1.0 / Double(numRampFrames)
        for _ in 0..<numRampFrames {
            try addTitleFrame(
                title: title, size: size, alpha: alpha,
                duration: rampFrameDuration)
            alpha += dAlpha
        }

        try addTitleFrame(
            title: title, size: size, alpha: 1.0, duration: Double(seconds))

        for _ in 0..<numRampFrames {
            try addTitleFrame(
                title: title, size: size, alpha: alpha,
                duration: rampFrameDuration)
            alpha -= dAlpha
        }
        try movieWriter.drain()
    }

    private func addTitleFrame(
        title: String, size: NSSize, alpha: Double, duration: Double
    ) throws {
        try autoreleasepool {
            try movieWriter.addFrame(
                titleFrameImage(title: title, size: size, alpha: alpha),
                duration: duration)
        }
    }

    private func titleFrameImage(title: String, size: NSSize, alpha: Double)
        -> NSImage
    {
        return NSImage(size: size, flipped: false) { rect in
            NSColor.black.setFill()
            NSBezierPath.fill(rect)

            // Solution from https://izziswift.com/how-to-use-nsstring-drawinrect-to-center-text/ inter alia
            let numLines = title.components(separatedBy: "\n").count

            // Try to use, e.g.,  1/3 of the height.
            let fontSize = (rect.height / 3.0) / Double(numLines)
            // https://stackoverflow.com/a/21940339/2826337
            let font = NSFont.systemFont(ofSize: fontSize)
            let attrs = [
                NSAttributedString.Key.font: font,
                NSAttributedString.Key.foregroundColor: NSColor.white
                    .withAlphaComponent(alpha),
            ]
            let size = (title as NSString).size(withAttributes: attrs)
            let xPos = max(0.0, (rect.size.width - size.width) / 2.0)
            let yPos = max(0.0, (rect.size.height - size.height) / 2.0)

            (title as NSString).draw(
                at: NSPoint(x: rect.origin.x + xPos, y: rect.origin.y + yPos),
                withAttributes: attrs)
            return true
        }
    }

    public func writeNextFrame(alpha: Double = 1.0) throws {
        try autoreleasepool {
            let frame = MovieFrame(
                world: world, width: width, height: height, title: title)
            try movieWriter.addFrame(frame.createFrame(alpha: alpha))
        }
    }

    public func getNextFrame(width desiredWidth: Double) -> NSImage {
        autoreleasepool {
            let scaleFactor = desiredWidth / Double(width)
            let desiredHeight = Double(height) * scaleFactor
            let w = Int(desiredWidth)
            let h = Int(desiredHeight)
            let frame = MovieFrame(
                world: world, width: w, height: h, title: title)
            let result = frame.createFrame()
            return result
        }
    }
}
