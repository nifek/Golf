import SpriteKit
import SwiftUI

struct LevelPlayView: View {
    @EnvironmentObject var appState: AppState
    let level: Level

    @State private var scene: GameScene?
    @State private var loadError: String?
    @State private var isLoading = false

    var body: some View {
        Group {
            if let scene {
                SpriteView(scene: scene)
                    .ignoresSafeArea(edges: .all)
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
        .navigationTitle(level.name)
        .navigationBarTitleDisplayMode(.inline)
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
            scene = GameScene(level: definition)
            scene?.onLevelComplete = { stars in
                Task { @MainActor in
                    appState.updateStars(for: level.id, stars: stars)
                }
            }
        } catch {
            loadError = error.localizedDescription
        }

        isLoading = false
    }
}


