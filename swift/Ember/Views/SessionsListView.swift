import SwiftUI

struct SessionsListView: View {
    @EnvironmentObject var store: SessionStore
    @State private var selectedSessionID: UUID?
    @State private var memoirSession: Session?
    @State private var processingIDs: Set<UUID> = []
    @State private var errorMessage: String?
    @State private var showingError = false

    private var selectedSession: Session? {
        store.sessions.first { $0.id == selectedSessionID }
    }

    var body: some View {
        ZStack {
            EmberTheme.backgroundGradient.ignoresSafeArea()

            if store.sessions.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(store.sessions) { session in
                            SessionCard(
                                session: session,
                                isSelected: session.id == selectedSessionID,
                                isProcessing: processingIDs.contains(session.id),
                                onSelect: { selectedSessionID = session.id },
                                onTranscribe: { transcribe(session) },
                                onGenerateMemoir: { generateMemoir(for: session) },
                                onViewMemoir: {
                                    memoirSession = store.sessions.first { $0.id == session.id }
                                },
                                onDelete: { store.delete(session) }
                            )
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 24)
                }
            }
        }
        .sheet(item: $memoirSession) { session in
            MemoirView(session: session)
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
        .onReceive(NotificationCenter.default.publisher(for: .transcribeSelected)) { _ in
            if let s = selectedSession { transcribe(s) }
        }
        .onReceive(NotificationCenter.default.publisher(for: .generateMemoirSelected)) { _ in
            if let s = selectedSession { generateMemoir(for: s) }
        }
        .onReceive(NotificationCenter.default.publisher(for: .viewMemoirSelected)) { _ in
            if let s = selectedSession, s.memoir != nil {
                memoirSession = s
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "waveform")
                .font(.system(size: 48))
                .foregroundColor(EmberTheme.amber.opacity(0.6))
            Text("No stories yet")
                .font(.emberHeadline)
                .foregroundColor(EmberTheme.inkBrown)
            Text("Switch to Record to begin capturing\nyour first story.")
                .font(.emberBody)
                .foregroundColor(EmberTheme.warmGray)
                .multilineTextAlignment(.center)
                .italic()
        }
    }

    private func transcribe(_ session: Session) {
        processingIDs.insert(session.id)
        var updated = session
        updated.status = .transcribing
        store.update(updated)

        Task {
            defer { processingIDs.remove(session.id) }
            let audioURL = store.audioDirectory.appendingPathComponent(session.audioFilename)
            do {
                let transcript = try await TranscriptionService.transcribe(audioURL: audioURL)
                var s = session
                s.transcript = transcript
                s.status = .transcribed
                store.update(s)
            } catch {
                var s = session
                s.status = .failed
                s.errorMessage = error.localizedDescription
                store.update(s)
                errorMessage = error.localizedDescription
                showingError = true
            }
        }
    }

    private func generateMemoir(for session: Session) {
        guard let transcript = session.transcript, !transcript.isEmpty else { return }
        processingIDs.insert(session.id)
        var updated = session
        updated.status = .generatingMemoir
        store.update(updated)

        Task {
            defer { processingIDs.remove(session.id) }
            do {
                let memoir = try await MemoirService.generateMemoir(from: transcript, sessionTitle: session.title)
                var s = session
                s.memoir = memoir
                s.status = .memoirReady
                store.update(s)
            } catch {
                var s = session
                s.status = .transcribed // revert to transcribed so they can retry
                s.errorMessage = error.localizedDescription
                store.update(s)
                errorMessage = error.localizedDescription
                showingError = true
            }
        }
    }
}

struct SessionCard: View {
    let session: Session
    let isSelected: Bool
    let isProcessing: Bool
    let onSelect: () -> Void
    let onTranscribe: () -> Void
    let onGenerateMemoir: () -> Void
    let onViewMemoir: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(session.title)
                        .font(.emberHeadline)
                        .foregroundColor(EmberTheme.inkBrown)
                        .lineLimit(2)

                    Text(session.formattedDate)
                        .font(.emberCaption)
                        .foregroundColor(EmberTheme.warmGray)
                }

                Spacer()

                StatusBadge(status: session.status)
            }

            HStack(spacing: 16) {
                Label(session.formattedDuration, systemImage: "clock")
                    .font(.emberCaption)
                    .foregroundColor(EmberTheme.warmGray)

                if let error = session.errorMessage, session.status == .failed {
                    Label("Failed", systemImage: "exclamationmark.triangle")
                        .font(.emberCaption)
                        .foregroundColor(EmberTheme.recordRed)
                        .help(error)
                }
            }

            if isProcessing {
                HStack(spacing: 8) {
                    ProgressView()
                        .scaleEffect(0.7)
                        .tint(EmberTheme.amber)
                    Text(session.status.displayName)
                        .font(.emberCaption)
                        .foregroundColor(EmberTheme.amber)
                        .italic()
                }
            } else {
                actionButtons
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? EmberTheme.amberLight.opacity(0.9) : Color.white.opacity(0.7))
                .shadow(color: EmberTheme.sepia.opacity(isSelected ? 0.2 : 0.1), radius: isSelected ? 6 : 4, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? EmberTheme.amber.opacity(0.6) : EmberTheme.amber.opacity(0.2), lineWidth: isSelected ? 1.5 : 1)
        )
        .contentShape(Rectangle())
        .onTapGesture { onSelect() }
    }

    @ViewBuilder
    private var actionButtons: some View {
        HStack(spacing: 10) {
            switch session.status {
            case .recorded, .failed:
                EmberButton("Transcribe", icon: "text.bubble", style: .secondary, action: onTranscribe)
            case .transcribed:
                EmberButton("Write Memoir", icon: "book.closed", style: .primary, action: onGenerateMemoir)
                EmberButton("Transcribe Again", icon: "arrow.counterclockwise", style: .ghost, action: onTranscribe)
            case .memoirReady:
                EmberButton("Read Memoir", icon: "book.open", style: .primary, action: onViewMemoir)
                EmberButton("Regenerate", icon: "arrow.counterclockwise", style: .ghost, action: onGenerateMemoir)
            case .transcribing, .generatingMemoir:
                EmptyView()
            }

            Spacer()

            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.system(size: 14))
                    .foregroundColor(EmberTheme.warmGray.opacity(0.6))
            }
            .buttonStyle(.plain)
            .help("Delete session")
        }
    }
}

struct StatusBadge: View {
    let status: SessionStatus

    var body: some View {
        Text(status.displayName)
            .font(.system(size: 11, weight: .medium))
            .foregroundColor(EmberTheme.statusColor(status))
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(EmberTheme.statusColor(status).opacity(0.12))
            )
    }
}

enum EmberButtonStyle { case primary, secondary, ghost }

struct EmberButton: View {
    let title: String
    let icon: String
    let style: EmberButtonStyle
    let action: () -> Void

    init(_ title: String, icon: String, style: EmberButtonStyle = .secondary, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.style = style
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(labelColor)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(background)
        }
        .buttonStyle(.plain)
    }

    private var labelColor: Color {
        switch style {
        case .primary: return .white
        case .secondary: return EmberTheme.sepia
        case .ghost: return EmberTheme.warmGray
        }
    }

    @ViewBuilder
    private var background: some View {
        switch style {
        case .primary:
            RoundedRectangle(cornerRadius: 8)
                .fill(EmberTheme.amber)
        case .secondary:
            RoundedRectangle(cornerRadius: 8)
                .stroke(EmberTheme.amber.opacity(0.6), lineWidth: 1)
        case .ghost:
            Color.clear
        }
    }
}
