import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

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
                HStack {
                    Image(systemName: "music.note")
                        .foregroundColor(Theme.accent)
                        .frame(width: 24)
                    Toggle("Music", isOn: $appState.musicEnabled)
                        .onChange(of: appState.musicEnabled) { _, newValue in
                            AudioManager.shared.isMusicEnabled = newValue
                        }
                }
                
                HStack {
                    Image(systemName: "speaker.wave.2")
                        .foregroundColor(Theme.accent)
                        .frame(width: 24)
                    Toggle("Sound Effects", isOn: $appState.soundEffectsEnabled)
                        .onChange(of: appState.soundEffectsEnabled) { _, newValue in
                            AudioManager.shared.isSoundEnabled = newValue
                        }
                }
            }
            .tint(Theme.accent)
            .listRowBackground(Theme.card.opacity(0.85))

            Section {
                Button(role: .destructive) {
                    handleLogout()
                } label: {
                    Label("Logout", systemImage: "rectangle.portrait.and.arrow.right")
                }
            }
            .listRowBackground(Theme.card.opacity(0.85))
        }
        .scrollContentBackground(.hidden)
        .background(Theme.background)
        .navigationTitle("Settings")
    }
    
    private func handleLogout() {
        dismiss()
        appState.logout()
    }
}


