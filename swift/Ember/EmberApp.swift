import SwiftUI

@main
struct EmberApp: App {
    @StateObject private var store = SessionStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(replacing: .newItem) {}

            CommandMenu("Record") {
                Button("Start / Pause Recording") {
                    NotificationCenter.default.post(name: .toggleRecording, object: nil)
                }
                .keyboardShortcut("r", modifiers: .command)

                Button("Stop Recording") {
                    NotificationCenter.default.post(name: .stopRecording, object: nil)
                }
                .keyboardShortcut(".", modifiers: .command)
            }

            CommandMenu("Navigate") {
                Button("Record") {
                    NotificationCenter.default.post(name: .switchTab, object: AppTab.record)
                }
                .keyboardShortcut("1", modifiers: .command)

                Button("Stories") {
                    NotificationCenter.default.post(name: .switchTab, object: AppTab.stories)
                }
                .keyboardShortcut("2", modifiers: .command)
            }

            CommandMenu("Session") {
                Button("Transcribe Selected") {
                    NotificationCenter.default.post(name: .transcribeSelected, object: nil)
                }
                .keyboardShortcut("t", modifiers: .command)

                Button("Generate Memoir") {
                    NotificationCenter.default.post(name: .generateMemoirSelected, object: nil)
                }
                .keyboardShortcut("m", modifiers: .command)

                Button("View Memoir") {
                    NotificationCenter.default.post(name: .viewMemoirSelected, object: nil)
                }
                .keyboardShortcut(.return, modifiers: .command)
            }
        }

        Settings {
            SettingsView()
        }
    }
}

extension Notification.Name {
    static let switchTab             = Notification.Name("ember.switchTab")
    static let toggleRecording       = Notification.Name("ember.toggleRecording")
    static let stopRecording         = Notification.Name("ember.stopRecording")
    static let transcribeSelected    = Notification.Name("ember.transcribeSelected")
    static let generateMemoirSelected = Notification.Name("ember.generateMemoirSelected")
    static let viewMemoirSelected    = Notification.Name("ember.viewMemoirSelected")
}
