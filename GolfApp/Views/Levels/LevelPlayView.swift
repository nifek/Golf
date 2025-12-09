import SpriteKit
import SwiftUI

struct LevelPlayView: View {
    @EnvironmentObject var appState: AppState
    let level: Level

    @State private var scene: GameScene?
    @State private var loadError: String?
    @State private var isLoading = false
    @State private var completedStars: Int?

    var body: some View {
        Group {
            if let scene {
                ZStack {
                    SpriteView(scene: scene)
                        .ignoresSafeArea(edges: .all)
                    
                    if let completedStars {
                        LevelCompleteOverlay(stars: completedStars, onDismiss: {
                            self.completedStars = nil
                        }, onGoToMenu: {
                            self.completedStars = nil
                        })
                    }
                }
            } else if let loadError {
                VStack(spacing: 16) {
                    Text("Unable to load level")
                        .font(.headline)
                        .foregroundColor(.white)
                    Text(loadError)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white.opacity(0.8))
                    Button("Try Again") {
                        Task {
                            await loadSceneIfNeeded(force: true)
                        }
                    }
                    .buttonStyle(FilledButtonStyle())
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Theme.background.ignoresSafeArea())
            } else {
                ProgressView()
                    .tint(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Theme.background.ignoresSafeArea())
            }
        }
        .navigationTitle("Level \(level.id)")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(completedStars != nil)
        .task {
            await loadSceneIfNeeded()
        }
    }

    @MainActor
    private func loadSceneIfNeeded(force: Bool = false) async {
        guard !isLoading else { return }
        if scene != nil && !force { return }
        guard let resourceName = level.resourceName, !resourceName.isEmpty else {
            loadError = "This level is missing a linked JSON file."
            return
        }

        isLoading = true
        loadError = nil

        do {
            let definition = try await withCheckedThrowingContinuation { continuation in
                DispatchQueue.global(qos: .userInitiated).async {
                    do {
                        let definition = try LevelLibrary().loadDefinition(named: resourceName)
                        continuation.resume(returning: definition)
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
            }
            scene = GameScene(level: definition, levelNumber: level.id)
            scene?.onLevelComplete = { stars in
                Task { @MainActor in
                    appState.updateStars(for: level.id, stars: stars)
                    completedStars = stars
                }
            }
        } catch {
            loadError = error.localizedDescription
        }

        isLoading = false
    }
}

private struct LevelCompleteOverlay: View {
    let stars: Int
    let onDismiss: () -> Void
    let onGoToMenu: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Text("Level Complete!")
                    .font(.system(.largeTitle, design: .rounded).weight(.bold))
                    .foregroundColor(.white)
                
                HStack(spacing: 16) {
                    ForEach(0..<3, id: \.self) { idx in
                        Image(systemName: idx < stars ? "star.fill" : "star")
                            .font(.system(size: 48))
                            .foregroundColor(Theme.gold)
                            .scaleEffect(idx < stars ? 1.2 : 1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.6).delay(Double(idx) * 0.1), value: stars)
                    }
                }
                .padding(.vertical, 8)
                
                VStack(spacing: 12) {
                    Button("Go to Menu") {
                        onGoToMenu()
                        // Dismiss twice to go back to menu (LevelPlayView -> LevelsView -> MainMenuView)
                        Task { @MainActor in
                            dismiss()
                            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                            dismiss()
                        }
                    }
                    .buttonStyle(FilledButtonStyle())
                    .frame(width: 200)
                    
                    Button("Continue") {
                        onDismiss()
                    }
                    .buttonStyle(FilledButtonStyle(color: Theme.surface))
                    .frame(width: 200)
                }
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Theme.surface)
                    .shadow(color: Theme.shadow, radius: 20, x: 0, y: 10)
            )
            .padding(40)
        }
    }
}


