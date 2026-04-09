import Foundation

enum SessionStatus: String, Codable {
    case recorded
    case transcribing
    case transcribed
    case generatingMemoir
    case memoirReady
    case failed

    var displayName: String {
        switch self {
        case .recorded: return "Recorded"
        case .transcribing: return "Transcribing..."
        case .transcribed: return "Transcribed"
        case .generatingMemoir: return "Writing memoir..."
        case .memoirReady: return "Memoir Ready"
        case .failed: return "Failed"
        }
    }
}

struct Session: Identifiable, Codable {
    var id: UUID
    var title: String
    var date: Date
    var duration: TimeInterval
    var audioFilename: String
    var transcript: String?
    var memoir: String?
    var status: SessionStatus
    var errorMessage: String?

    init(id: UUID = UUID(), title: String, date: Date = Date(), duration: TimeInterval = 0, audioFilename: String) {
        self.id = id
        self.title = title
        self.date = date
        self.duration = duration
        self.audioFilename = audioFilename
        self.status = .recorded
    }

    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
