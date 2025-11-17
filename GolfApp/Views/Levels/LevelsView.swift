import SwiftUI

struct LevelsView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
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
        .navigationTitle("Levels")
    }

    private var listHeader: some View {
        EmptyView()
    }
}

private struct LevelRow: View {
    let level: Level
    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    ForEach(0..<3, id: \.self) { idx in
                        Image(systemName: idx < level.stars ? "star.fill" : "star")
                            .foregroundColor(Theme.gold)
                    }
                }
                Text(level.name)
                    .font(.headline)
                    .foregroundColor(.white)
                Text(level.difficulty)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
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


