import SpriteKit
import SwiftUI

// MARK: - Disable Back Swipe Gesture Helper
struct DisableSwipeBackGesture: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> DisableSwipeBackViewController {
        DisableSwipeBackViewController()
    }
    
    func updateUIViewController(_ uiViewController: DisableSwipeBackViewController, context: Context) {}
}

class DisableSwipeBackViewController: UIViewController {
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
    }
}

struct LevelPlayView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    let level: Level

    @State private var scene: GameScene?
    @State private var loadError: String?
    @State private var isLoading = false
    @State private var completedStars: Int?
    @State private var levelStartTime: Date?
    @State private var completionResult: LevelProgressResponse?
    @State private var isSubmitting = false
    @State private var showMenuSheet = false
    @State private var currentStrokes: Int = 0

    var body: some View {
        Group {
            if let scene {
                ZStack {
                    SpriteView(scene: scene)
                        .ignoresSafeArea(edges: .all)
                    
                    // HUD overlay (menu button + level indicator + strokes)
                    if completedStars == nil {
                        VStack {
                            HStack(alignment: .center, spacing: 12) {
                                // Menu button
                                Button {
                                    showMenuSheet = true
                                } label: {
                                    Image(systemName: "line.3.horizontal")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.white)
                                        .frame(width: 40, height: 40)
                                        .background(
                                            Circle()
                                                .fill(Color.black.opacity(0.5))
                                        )
                                }
                                
                                // Level indicator
                                Text("Level \(level.id)")
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        Capsule()
                                            .fill(Color.black.opacity(0.5))
                                    )
                                
                                Spacer()
                                
                                // Strokes indicator (same style as level)
                                HStack(spacing: 4) {
                                    Image(systemName: "figure.golf")
                                        .font(.system(size: 14, weight: .semibold))
                                    Text("\(currentStrokes)")
                                        .font(.system(size: 16, weight: .bold, design: .rounded))
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(Color.black.opacity(0.5))
                                )
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 54)
                            
                            Spacer()
                        }
                    }
                    
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
                .background(DisableSwipeBackGesture())
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
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
        .task {
            await loadSceneIfNeeded()
        }
        .onAppear {
            // Switch to game music
            AudioManager.shared.playMusic(.game)
        }
        .onDisappear {
            // Switch back to menu music
            AudioManager.shared.playMusic(.menu)
        }
        .sheet(isPresented: $showMenuSheet) {
            GameMenuSheet(
                levelId: level.id,
                onRetry: {
                    showMenuSheet = false
                    retryLevel()
                },
                onExit: {
                    showMenuSheet = false
                    dismiss()
                }
            )
            .presentationDetents([.height(280)])
            .presentationDragIndicator(.visible)
        }
    }
    
    private func retryLevel() {
        scene = nil
        currentStrokes = 0
        completedStars = nil
        completionResult = nil
        Task {
            await loadSceneIfNeeded(force: true)
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
            
            // Create scene with equipped skin image (no levelNumber to avoid duplicate label)
            let newScene = GameScene(
                level: definition,
                levelNumber: nil,
                skinImage: appState.equippedSkinImage
            )
            newScene.onLevelComplete = { stars in
                Task { @MainActor in
                    await handleLevelComplete(stars: stars)
                }
            }
            newScene.onStrokesChanged = { strokes in
                Task { @MainActor in
                    currentStrokes = strokes
                }
            }
            scene = newScene
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

// MARK: - Game Menu Sheet
private struct GameMenuSheet: View {
    let levelId: Int
    let onRetry: () -> Void
    let onExit: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            // Title
            Text("Level \(levelId)")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
                .padding(.top, 8)
            
            Text("Paused")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Divider()
                .padding(.horizontal)
            
            // Buttons
            VStack(spacing: 12) {
                Button {
                    onRetry()
                } label: {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                        Text("Retry")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Theme.accent)
                    )
                }
                
                Button {
                    onExit()
                } label: {
                    HStack {
                        Image(systemName: "xmark.circle")
                        Text("Exit Level")
                    }
                    .font(.headline)
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.red, lineWidth: 2)
                    )
                }
            }
            .padding(.horizontal, 24)
            
            Spacer()
        }
        .padding(.top, 16)
    }
}

// MARK: - Level Complete Overlay
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
