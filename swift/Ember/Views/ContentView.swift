import SwiftUI

enum AppTab: String, CaseIterable {
    case record = "Record"
    case stories = "Stories"

    var icon: String {
        switch self {
        case .record: return "mic.fill"
        case .stories: return "books.vertical.fill"
        }
    }
}

struct ContentView: View {
    @State private var selectedTab: AppTab = .record

    var body: some View {
        HStack(spacing: 0) {
            // Sidebar
            VStack(alignment: .leading, spacing: 4) {
                // Brand
                VStack(alignment: .leading, spacing: 4) {
                    Text("Ember")
                        .font(.system(size: 22, weight: .semibold, design: .serif))
                        .foregroundColor(EmberTheme.inkBrown)
                    Text("Memory keeper")
                        .font(.system(size: 11))
                        .foregroundColor(EmberTheme.warmGray)
                        .italic()
                }
                .padding(.horizontal, 16)
                .padding(.top, 24)
                .padding(.bottom, 20)

                Divider()
                    .padding(.horizontal, 8)
                    .padding(.bottom, 8)

                ForEach(AppTab.allCases, id: \.self) { tab in
                    SidebarButton(tab: tab, isSelected: selectedTab == tab) {
                        selectedTab = tab
                    }
                }

                Spacer()
            }
            .frame(width: 180)
            .background(Color.white.opacity(0.35))

            Divider()

            Group {
                switch selectedTab {
                case .record:
                    RecordingView()
                case .stories:
                    SessionsListView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(EmberTheme.backgroundGradient)
        .frame(minWidth: 720, minHeight: 560)
        .onReceive(NotificationCenter.default.publisher(for: .switchTab)) { note in
            if let tab = note.object as? AppTab { selectedTab = tab }
        }
    }
}

struct SidebarButton: View {
    let tab: AppTab
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: tab.icon)
                    .font(.system(size: 15))
                    .frame(width: 20)
                Text(tab.rawValue)
                    .font(.system(size: 14, weight: isSelected ? .semibold : .regular, design: .serif))
                Spacer()
            }
            .foregroundColor(isSelected ? EmberTheme.amber : EmberTheme.warmGray)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? EmberTheme.amber.opacity(0.12) : Color.clear)
            )
            .padding(.horizontal, 8)
        }
        .buttonStyle(.plain)
    }
}
