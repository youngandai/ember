import Foundation
import Combine

@MainActor
class SessionStore: ObservableObject {
    @Published var sessions: [Session] = []

    private let storageURL: URL = {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("Ember", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("sessions.json")
    }()

    var audioDirectory: URL = {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("Ember/Audio", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()

    init() {
        load()
    }

    func add(_ session: Session) {
        sessions.insert(session, at: 0)
        save()
    }

    func update(_ session: Session) {
        if let index = sessions.firstIndex(where: { $0.id == session.id }) {
            sessions[index] = session
            save()
        }
    }

    func delete(_ session: Session) {
        // Remove audio file
        let audioURL = audioDirectory.appendingPathComponent(session.audioFilename)
        try? FileManager.default.removeItem(at: audioURL)
        sessions.removeAll { $0.id == session.id }
        save()
    }

    private func save() {
        do {
            let data = try JSONEncoder().encode(sessions)
            try data.write(to: storageURL)
        } catch {
            print("Failed to save sessions: \(error)")
        }
    }

    private func load() {
        guard FileManager.default.fileExists(atPath: storageURL.path) else { return }
        do {
            let data = try Data(contentsOf: storageURL)
            sessions = try JSONDecoder().decode([Session].self, from: data)
        } catch {
            print("Failed to load sessions: \(error)")
        }
    }
}
