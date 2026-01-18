import SpriteKit
import SwiftUI

struct LevelPlayView: View {
    @EnvironmentObject var appState: AppState
    let level: Level

    @State private var scene: GameScene?
    @State private var loadError: String?
    @State private var isLoading = false
    @State private var completedStars: Int?
    @State private var levelStartTime: Date?
    @State private var completionResult: LevelProgressResponse?
    @State private var isSubmitting = false

    var body: some View {
        Group {
            if let scene {
                ZStack {
                    SpriteView(scene: scene)
                        .ignoresSafeArea(edges: .all)
                    
                    if let completedStars {
                        LevelCompleteOverlay(
                            stars: completedStars,
                            score: completionResult?.score,
                            isSubmitting: isSubmitting,
                            onGoToMenu: {
                                self.completedStars = nil
                            }
                        )
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
                VStack(spacing: 16) {
                    ProgressView()
                        .tint(.white)
                    Text("Loading level...")
                        .foregroundColor(.white.opacity(0.7))
                }
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
        
        // Ensure skin is loaded before starting level
        if appState.equippedSkinImage == nil && !appState.shopItems.isEmpty {
            print("🎮 [LevelPlayView] Skin not loaded, attempting to load...")
            await appState.loadEquippedSkinImage()
        }

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
            
            // Record start time for time tracking
            levelStartTime = Date()
            
            // Log skin info
            print("🎮 [LevelPlayView] Creating GameScene for level \(level.id)")
            print("🎮 [LevelPlayView] equippedSkinImage: \(appState.equippedSkinImage != nil ? "loaded (\(appState.equippedSkinImage!.size))" : "nil")")
            print("🎮 [LevelPlayView] equippedSkinId: '\(appState.equippedSkinId)'")
            
            // Create scene with equipped skin image
            scene = GameScene(
                level: definition,
                levelNumber: level.id,
                skinImage: appState.equippedSkinImage
            )
            scene?.onLevelComplete = { stars in
                Task { @MainActor in
                    await handleLevelComplete(stars: stars)
                }
            }
        } catch {
            loadError = error.localizedDescription
        }

        isLoading = false
    }
    
    @MainActor
    private func handleLevelComplete(stars: Int) async {
        // Calculate time taken
        let timeToPassMs: Int
        if let startTime = levelStartTime {
            let elapsed = Date().timeIntervalSince(startTime)
            timeToPassMs = Int(elapsed * 1000)
        } else {
            timeToPassMs = 60000 // Default to 60 seconds if start time wasn't recorded
        }
        
        // Show stars immediately
        completedStars = stars
        
        // Submit to backend
        isSubmitting = true
        if let result = await appState.completeLevel(
            levelNumber: level.id,
            timeToPassMs: timeToPassMs,
            stars: stars
        ) {
            completionResult = result
        }
        isSubmitting = false
    }
}

private struct LevelCompleteOverlay: View {
    let stars: Int
    let score: Int?
    let isSubmitting: Bool
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
                
                // Show score if available
                if let score = score {
                    Text("Score: \(score)")
                        .font(.title2.weight(.semibold))
                        .foregroundColor(.white.opacity(0.9))
                } else if isSubmitting {
                    HStack(spacing: 8) {
                        ProgressView()
                            .tint(.white)
                        Text("Saving...")
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                
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
                .disabled(isSubmitting)
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
