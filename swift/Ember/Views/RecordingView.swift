import SwiftUI
import AVFoundation

struct RecordingView: View {
    @EnvironmentObject var store: SessionStore
    @StateObject private var recorder = AudioRecorder()
    @State private var sessionTitle = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var recordingFilename = ""

    var body: some View {
        ZStack {
            EmberTheme.backgroundGradient.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                VStack(spacing: 8) {
                    Text("Ember")
                        .font(.emberTitle)
                        .foregroundColor(EmberTheme.inkBrown)
                    Text("Preserve the stories that matter")
                        .font(.emberCaption)
                        .foregroundColor(EmberTheme.warmGray)
                        .italic()
                }
                .padding(.top, 40)
                .padding(.bottom, 32)

                // Title field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Story Title")
                        .font(.emberCaption)
                        .foregroundColor(EmberTheme.warmGray)
                        .textCase(.uppercase)
                        .tracking(1.5)

                    TextField("e.g. Growing up on the farm", text: $sessionTitle)
                        .font(.emberBody)
                        .foregroundColor(EmberTheme.inkBrown)
                        .textFieldStyle(.plain)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.white.opacity(0.6))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(EmberTheme.amber.opacity(0.4), lineWidth: 1)
                                )
                        )
                        .disabled(recorder.isRecording)
                }
                .padding(.horizontal, 48)
                .padding(.bottom, 48)

                // Timer
                Text(formatTime(recorder.elapsedTime))
                    .font(.system(size: 56, weight: .light, design: .serif))
                    .foregroundColor(recorder.isRecording ? EmberTheme.inkBrown : EmberTheme.warmGray.opacity(0.5))
                    .monospacedDigit()
                    .padding(.bottom, 8)

                if recorder.isPaused {
                    Text("Paused")
                        .font(.emberCaption)
                        .foregroundColor(EmberTheme.amber)
                        .italic()
                        .padding(.bottom, 32)
                } else if recorder.isRecording {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(EmberTheme.recordRed)
                            .frame(width: 8, height: 8)
                        Text("Recording")
                            .font(.emberCaption)
                            .foregroundColor(EmberTheme.warmGray)
                    }
                    .padding(.bottom, 32)
                } else {
                    Text("Ready to record")
                        .font(.emberCaption)
                        .foregroundColor(EmberTheme.warmGray.opacity(0.6))
                        .italic()
                        .padding(.bottom, 32)
                }

                // Record button
                Button(action: handleRecordTap) {
                    ZStack {
                        Circle()
                            .fill(
                                recorder.isRecording && !recorder.isPaused
                                    ? EmberTheme.recordRed
                                    : EmberTheme.amber
                            )
                            .frame(width: 96, height: 96)
                            .shadow(color: (recorder.isRecording ? EmberTheme.recordRed : EmberTheme.amber).opacity(0.4), radius: 16, x: 0, y: 6)

                        if recorder.isRecording && !recorder.isPaused {
                            // Pause icon
                            HStack(spacing: 8) {
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(Color.white)
                                    .frame(width: 10, height: 30)
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(Color.white)
                                    .frame(width: 10, height: 30)
                            }
                        } else if recorder.isPaused {
                            // Resume icon
                            Image(systemName: "play.fill")
                                .font(.system(size: 30))
                                .foregroundColor(.white)
                                .offset(x: 3)
                        } else {
                            // Microphone icon
                            Image(systemName: "mic.fill")
                                .font(.system(size: 36))
                                .foregroundColor(.white)
                        }
                    }
                }
                .buttonStyle(.plain)
                .padding(.bottom, 24)

                Text(recorder.isRecording ? (recorder.isPaused ? "Tap to resume" : "Tap to pause") : "Tap to begin recording")
                    .font(.emberCaption)
                    .foregroundColor(EmberTheme.warmGray)

                // Stop button
                if recorder.isRecording {
                    Button(action: stopRecording) {
                        HStack(spacing: 8) {
                            Image(systemName: "stop.fill")
                                .font(.system(size: 14))
                            Text("Finish Recording")
                                .font(.emberBody)
                        }
                        .foregroundColor(EmberTheme.sepia)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(EmberTheme.sepia.opacity(0.5), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 24)
                }

                Spacer()

                // Footer quote
                Text("\"Stories are the threads that weave families together.\"")
                    .font(.emberCaption)
                    .foregroundColor(EmberTheme.warmGray.opacity(0.6))
                    .italic()
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 48)
                    .padding(.bottom, 32)
            }
        }
        .alert("Error", isPresented: $showingAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
        .onReceive(NotificationCenter.default.publisher(for: .toggleRecording)) { _ in
            handleRecordTap()
        }
        .onReceive(NotificationCenter.default.publisher(for: .stopRecording)) { _ in
            if recorder.isRecording { stopRecording() }
        }
    }

    private func handleRecordTap() {
        if !recorder.isRecording {
            startRecording()
        } else if recorder.isPaused {
            recorder.resume()
        } else {
            recorder.pause()
        }
    }

    private func startRecording() {
        let title = sessionTitle.trimmingCharacters(in: .whitespaces)
        if title.isEmpty {
            sessionTitle = "Story \(formattedNow())"
        }
        do {
            recordingFilename = try recorder.startRecording(to: store.audioDirectory)
        } catch {
            alertMessage = error.localizedDescription
            showingAlert = true
        }
    }

    private func stopRecording() {
        let duration = recorder.stop()
        let title = sessionTitle.trimmingCharacters(in: .whitespaces).isEmpty
            ? "Story \(formattedNow())"
            : sessionTitle

        let session = Session(title: title, duration: duration, audioFilename: recordingFilename)
        store.add(session)
        sessionTitle = ""
    }

    private func formatTime(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private func formattedNow() -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM d, yyyy"
        return fmt.string(from: Date())
    }
}
