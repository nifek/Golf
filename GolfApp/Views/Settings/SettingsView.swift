import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        Form {
            Section(header: Text("Profile")) {
                HStack(spacing: 12) {
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .frame(width: 56, height: 56)
                        .foregroundColor(.white)
                    Text(appState.currentUser?.username ?? "")
                        .foregroundColor(.white)
                }
                .listRowBackground(Theme.card.opacity(0.85))
            }

            Section(header: Text("Audio")) {
                Toggle("Music", isOn: $appState.musicEnabled)
                Toggle("Sound effects", isOn: $appState.soundEffectsEnabled)
            }
            .tint(Theme.card)
            .listRowBackground(Theme.card.opacity(0.85))

            Section {
                Button(role: .destructive) { appState.logout() } label: {
                    Label("Logout", systemImage: "rectangle.portrait.and.arrow.right")
                }
            }
            .listRowBackground(Theme.card.opacity(0.85))
        }
        .scrollContentBackground(.hidden)
        .background(Theme.background)
        .navigationTitle("Settings")
    }
}


