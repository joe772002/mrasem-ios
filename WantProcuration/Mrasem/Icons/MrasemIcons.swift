//
//  MrasemIcons.swift
//  Mrasem
//
//  Mirrors Android: app/src/main/java/com/informatique/tawsekmisr/ui/icons/MrasemIcons.kt
//  Line icons (24×24, stroke 1.8) — copied from the original SVG paths.
//  The color is chosen at usage time via `foregroundStyle`.
//

import SwiftUI

/// شكل الأيقونة: مسارات SVG بالنقطة المرجعية 24×24.
struct MrasemIconShape: Shape {
    let paths: [Path]

    func path(in rect: CGRect) -> Path {
        let scale = rect.width / 24
        var result = Path()
        for path in paths {
            result.addPath(path, transform: CGAffineTransform(scaleX: scale, y: scale))
        }
        return result
    }
}

/// أيقونة مراسم.
struct MrasemIcon: View {
    let paths: [Path]
    var size: CGFloat = 24
    var lineWidth: CGFloat = 1.8

    init(_ paths: [Path], size: CGFloat = 24, lineWidth: CGFloat = 1.8) {
        self.paths = paths
        self.size = size
        self.lineWidth = lineWidth
    }

    var body: some View {
        MrasemIconShape(paths: paths)
            .stroke(
                style: StrokeStyle(lineWidth: lineWidth, lineCap: .butt, lineJoin: .miter)
            )
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}

enum MrasemIcons {
    // MARK: - Paths

    private static func rect(_ x: Double, _ y: Double, _ w: Double, _ h: Double, _ r: Double) -> String {
        "M\(x + r) \(y)H\(x + w - r)A\(r) \(r) 0 0 1 \(x + w) \(y + r)V\(y + h - r)" +
            "A\(r) \(r) 0 0 1 \(x + w - r) \(y + h)H\(x + r)A\(r) \(r) 0 0 1 \(x) \(y + h - r)V\(y + r)" +
            "A\(r) \(r) 0 0 1 \(x + r) \(y)Z"
    }

    private static func circle(_ cx: Double, _ cy: Double, _ r: Double) -> String {
        "M\(cx - r) \(cy)a\(r) \(r) 0 1 0 \(2 * r) 0a\(r) \(r) 0 1 0 \(-2 * r) 0Z"
    }

    private static func icon(_ paths: [String]) -> [Path] {
        paths.map { SVGPath.parse($0) }
    }

    // MARK: - Icons

    static let mission = MrasemIcon(
        icon([
            rect(3, 5, 18, 15, 3),
            "M8 5V3h8v2M3 11h18",
        ])
    )

    static let plan = MrasemIcon(
        icon([
            rect(3, 4, 18, 17, 3),
            "M3 9h18M8 2v4M16 2v4M7 13h4M7 17h7",
        ])
    )

    static let services = MrasemIcon(
        icon([
            "M5 17h14l-1.5-6.5A2 2 0 0 0 15.6 9H8.4a2 2 0 0 0-1.9 1.5Z",
            circle(8, 18, 1.8),
            circle(16, 18, 1.8),
        ])
    )

    static let explore = MrasemIcon(
        icon([
            "M12 21s-7-6.2-7-11.5A7 7 0 0 1 19 9.5C19 14.8 12 21 12 21Z",
            circle(12, 9.5, 2.5),
        ])
    )

    /// `protocol` كلمة محجوزة في Swift — بنستخدم backticks عشان نطابق اسم Android.
    static let `protocol` = MrasemIcon(
        icon([
            "M12 3 4 6v6c0 4.5 3.4 8 8 9 4.6-1 8-4.5 8-9V6Z",
            "m9 12 2 2 4-4",
        ])
    )

    static let assistant = MrasemIcon(
        icon([
            "M4 5h16v11H9l-5 4Z",
            "M8 10h8M8 13h5",
        ])
    )

    static let dash = MrasemIcon(
        icon([
            rect(3, 3, 8, 8, 2),
            rect(13, 3, 8, 5, 2),
            rect(13, 10, 8, 11, 2),
            rect(3, 13, 8, 8, 2),
        ])
    )

    static let edit = MrasemIcon(icon(["M4 20h4L19 9l-4-4L4 16Z"]))

    static let inbox = MrasemIcon(icon(["M3 13h5l1.5 3h5L16 13h5M5 5h14l2 8v6H3v-6Z"]))

    static let settings = MrasemIcon(
        icon([
            circle(12, 12, 3.2),
            "M12 3v3M12 18v3M3 12h3M18 12h3M5.6 5.6l2.1 2.1M16.3 16.3l2.1 2.1M18.4 5.6l-2.1 2.1M7.7 16.3l-2.1 2.1",
        ])
    )
}
