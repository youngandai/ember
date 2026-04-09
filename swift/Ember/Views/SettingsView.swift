import SwiftUI

struct SettingsView: View {
    var body: some View {
        TabView {
            APIKeysSettingsView()
                .tabItem { Label("API Keys", systemImage: "key.fill") }

            KeyboardShortcutsSettingsView()
                .tabItem { Label("Shortcuts", systemImage: "keyboard") }
        }
        .frame(width: 520, height: 360)
    }
}

// MARK: - API Keys Tab

struct APIKeysSettingsView: View {
    @AppStorage("apiKey_openAI")    private var openAIKey    = ""
    @AppStorage("apiKey_anthropic") private var anthropicKey = ""

    @State private var showOpenAI    = false
    @State private var showAnthropic = false
    @State private var saved         = false

    var body: some View {
        Form {
            Section {
                Text("Keys are stored in local preferences on this Mac. Environment variables (OPENAI_API_KEY, ANTHROPIC_API_KEY) always take priority if set.")
                    .foregroundStyle(.secondary)
                    .font(.callout)
            }

            Section("OpenAI (Whisper — transcription)") {
                HStack {
                    if showOpenAI {
                        TextField("sk-...", text: $openAIKey)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(.body, design: .monospaced))
                    } else {
                        SecureField("sk-...", text: $openAIKey)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(.body, design: .monospaced))
                    }
                    Button {
                        showOpenAI.toggle()
                    } label: {
                        Image(systemName: showOpenAI ? "eye.slash" : "eye")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help(showOpenAI ? "Hide key" : "Show key")
                }

                if let env = ProcessInfo.processInfo.environment["OPENAI_API_KEY"], !env.isEmpty {
                    Label("Overridden by OPENAI_API_KEY environment variable", systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Anthropic (Claude — memoir generation)") {
                HStack {
                    if showAnthropic {
                        TextField("sk-ant-...", text: $anthropicKey)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(.body, design: .monospaced))
                    } else {
                        SecureField("sk-ant-...", text: $anthropicKey)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(.body, design: .monospaced))
                    }
                    Button {
                        showAnthropic.toggle()
                    } label: {
                        Image(systemName: showAnthropic ? "eye.slash" : "eye")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help(showAnthropic ? "Hide key" : "Show key")
                }

                if let env = ProcessInfo.processInfo.environment["ANTHROPIC_API_KEY"], !env.isEmpty {
                    Label("Overridden by ANTHROPIC_API_KEY environment variable", systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                HStack {
                    Spacer()
                    if saved {
                        Label("Saved", systemImage: "checkmark")
                            .foregroundStyle(.green)
                            .transition(.opacity)
                    }
                    Button("Save Keys") {
                        // @AppStorage saves automatically; just give feedback
                        withAnimation { saved = true }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation { saved = false }
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color(red: 0.831, green: 0.561, blue: 0.298))
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

// MARK: - Shortcuts Tab

struct KeyboardShortcutsSettingsView: View {
    private let shortcuts: [(String, String)] = [
        ("⌘ ,",        "Open Settings"),
        ("⌘ 1",        "Switch to Record"),
        ("⌘ 2",        "Switch to Stories"),
        ("⌘ R",        "Start / Pause recording"),
        ("⌘ .",        "Stop recording"),
        ("⌘ T",        "Transcribe selected session"),
        ("⌘ M",        "Generate memoir for selected session"),
        ("⌘ ⏎",       "View memoir for selected session"),
        ("⌫",          "Delete selected session (Stories list)"),
        ("Esc",         "Close modal / sheet"),
    ]

    var body: some View {
        Form {
            ForEach(shortcuts, id: \.0) { shortcut in
                HStack(spacing: 16) {
                    Text(shortcut.0)
                        .font(.system(.body, design: .monospaced))
                        .frame(width: 80, alignment: .leading)
                        .foregroundStyle(.primary)
                    Text(shortcut.1)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}
