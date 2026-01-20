import SwiftUI

struct LevelsView: View {
    @EnvironmentObject private var appState: AppState
    @State private var showAudioSettings = false

    var body: some View {
        Group {
            if appState.isLoadingLevels {
                VStack(spacing: 12) {
                    ProgressView()
                        .tint(.white)
                    Text("Loading progress...")
                        .foregroundColor(.white.opacity(0.7))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Theme.background)
            } else {
                List {
                    Section(header: listHeader) {
                        ForEach(appState.levels) { level in
                            NavigationLink(destination: LevelPlayView(level: level)) {
                                LevelRow(level: level)
                            }
                            .disabled(level.isLocked || level.resourceName == nil)
                            .listRowBackground(Theme.surface.opacity(0.4))
                            .opacity(level.isLocked ? 0.6 : 1)
                        }
                    }
                }
                .scrollContentBackground(.hidden)
                .background(Theme.background)
            }
        }
        .navigationTitle("Levels")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showAudioSettings = true
                } label: {
                    Image(systemName: "gearshape.fill")
                        .foregroundColor(.white)
                }
            }
        }
        .task {
            await appState.loadLevelProgress()
        }
        .refreshable {
            await appState.loadLevelProgress()
        }
        .sheet(isPresented: $showAudioSettings) {
            AudioSettingsSheet()
                .environmentObject(appState)
                .presentationDetents([.height(300)])
                .presentationDragIndicator(.visible)
        }
    }

    private var listHeader: some View {
        EmptyView()
    }
}

// MARK: - Audio Settings Sheet
private struct AudioSettingsSheet: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Music Toggle
                HStack {
                    HStack(spacing: 12) {
                        Image(systemName: "music.note")
                            .font(.title2)
                            .foregroundColor(Theme.accent)
                            .frame(width: 32)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Music")
                                .font(.headline)
                            Text("Background music")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: $appState.musicEnabled)
                        .labelsHidden()
                        .tint(Theme.accent)
                        .onChange(of: appState.musicEnabled) { _, newValue in
                            AudioManager.shared.isMusicEnabled = newValue
                        }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                )
                
                // Sound Effects Toggle
                HStack {
                    HStack(spacing: 12) {
                        Image(systemName: "speaker.wave.2")
                            .font(.title2)
                            .foregroundColor(Theme.accent)
                            .frame(width: 32)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Sound Effects")
                                .font(.headline)
                            Text("Ball hits and level complete")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: $appState.soundEffectsEnabled)
                        .labelsHidden()
                        .tint(Theme.accent)
                        .onChange(of: appState.soundEffectsEnabled) { _, newValue in
                            AudioManager.shared.isSoundEnabled = newValue
                        }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                )
                
                Spacer()
            }
            .padding()
            .navigationTitle("Audio Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

private struct LevelRow: View {
    let level: Level
    
    private var formattedTime: String? {
        guard let timeMs = level.bestTimeMs else { return nil }
        let seconds = Double(timeMs) / 1000.0
        if seconds < 60 {
            return String(format: "%.1fs", seconds)
        } else {
            let minutes = Int(seconds) / 60
            let remainingSeconds = seconds.truncatingRemainder(dividingBy: 60)
            return String(format: "%d:%04.1f", minutes, remainingSeconds)
        }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    ForEach(0..<3, id: \.self) { idx in
                        Image(systemName: idx < level.stars ? "star.fill" : "star")
                            .foregroundColor(Theme.gold)
                    }
                    
                    if let score = level.bestScore {
                        Text("•")
                            .foregroundColor(.white.opacity(0.5))
                        Text("\(score) pts")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                
                Text(level.name)
                    .font(.headline)
                    .foregroundColor(.white)
                
                HStack(spacing: 8) {
                    Text(level.difficulty)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                    
                    if let time = formattedTime {
                        Text("•")
                            .foregroundColor(.white.opacity(0.5))
                        HStack(spacing: 2) {
                            Image(systemName: "clock")
                                .font(.caption2)
                            Text(time)
                                .font(.caption)
                        }
                        .foregroundColor(.white.opacity(0.6))
                    }
                }
            }
            Spacer()
            if level.isLocked {
                Image(systemName: "lock.fill").foregroundColor(.white.opacity(0.7))
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Theme.card)
                    .frame(width: 64, height: 64)
                    .overlay(Image(systemName: "flag.fill").foregroundColor(.white))
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Theme.card.opacity(0.8))
        )
    }
}
