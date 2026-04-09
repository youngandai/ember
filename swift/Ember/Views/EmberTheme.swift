import SwiftUI

enum EmberTheme {
    // Warm amber/sepia palette
    static let amber = Color(red: 0.831, green: 0.561, blue: 0.298)
    static let amberDark = Color(red: 0.600, green: 0.380, blue: 0.150)
    static let amberLight = Color(red: 0.980, green: 0.910, blue: 0.820)
    static let sepia = Color(red: 0.420, green: 0.310, blue: 0.200)
    static let parchment = Color(red: 0.972, green: 0.952, blue: 0.910)
    static let inkBrown = Color(red: 0.200, green: 0.140, blue: 0.080)
    static let warmGray = Color(red: 0.550, green: 0.500, blue: 0.450)
    static let recordRed = Color(red: 0.780, green: 0.220, blue: 0.150)

    static let backgroundGradient = LinearGradient(
        colors: [parchment, Color(red: 0.960, green: 0.935, blue: 0.885)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static func statusColor(_ status: SessionStatus) -> Color {
        switch status {
        case .recorded: return warmGray
        case .transcribing, .generatingMemoir: return amber
        case .transcribed: return Color(red: 0.400, green: 0.650, blue: 0.400)
        case .memoirReady: return amberDark
        case .failed: return recordRed
        }
    }
}

extension Font {
    static var emberTitle: Font { .custom("Georgia", size: 28).weight(.semibold) }
    static var emberHeadline: Font { .custom("Georgia", size: 18).weight(.semibold) }
    static var emberBody: Font { .custom("Georgia", size: 16) }
    static var emberCaption: Font { .custom("Georgia", size: 13) }
    static var emberTimer: Font { .custom("Georgia-Bold", size: 48).weight(.bold) }
}
