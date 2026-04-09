import Foundation
import AVFoundation
import Combine

@MainActor
class AudioRecorder: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var isPaused = false
    @Published var elapsedTime: TimeInterval = 0

    private var audioRecorder: AVAudioRecorder?
    private var timer: Timer?
    private var startDate: Date?
    private var accumulatedTime: TimeInterval = 0
    private(set) var currentFilename: String = ""

    func startRecording(to directory: URL) throws -> String {
        let filename = "\(UUID().uuidString).m4a"
        let url = directory.appendingPathComponent(filename)
        currentFilename = filename

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        audioRecorder = try AVAudioRecorder(url: url, settings: settings)
        audioRecorder?.delegate = self
        audioRecorder?.record()

        isRecording = true
        isPaused = false
        startDate = Date()
        accumulatedTime = 0
        startTimer()

        return filename
    }

    func pause() {
        guard isRecording, !isPaused else { return }
        audioRecorder?.pause()
        isPaused = true
        accumulatedTime = elapsedTime
        stopTimer()
    }

    func resume() {
        guard isRecording, isPaused else { return }
        audioRecorder?.record()
        isPaused = false
        startDate = Date()
        startTimer()
    }

    func stop() -> TimeInterval {
        audioRecorder?.stop()
        isRecording = false
        isPaused = false
        stopTimer()
        let total = elapsedTime
        elapsedTime = 0
        accumulatedTime = 0
        return total
    }

    private func startTimer() {
        startDate = Date()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self, let start = self.startDate else { return }
                self.elapsedTime = self.accumulatedTime + Date().timeIntervalSince(start)
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
        startDate = nil
    }
}

extension AudioRecorder: AVAudioRecorderDelegate {
    nonisolated func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {}
}
