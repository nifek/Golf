import AVFoundation
import Combine
import Foundation

/// Manages background music and sound effects for the app
final class AudioManager: ObservableObject {
    static let shared = AudioManager()
    
    // MARK: - Audio Players
    private var musicPlayer: AVAudioPlayer?
    private var soundEffectPlayers: [String: AVAudioPlayer] = [:]
    
    // MARK: - Settings (bound to AppState)
    @Published var isMusicEnabled: Bool = true {
        didSet {
            if isMusicEnabled {
                musicPlayer?.play()
            } else {
                musicPlayer?.pause()
            }
        }
    }
    
    @Published var isSoundEnabled: Bool = true
    
    // MARK: - Music Types
    enum MusicType: String {
        case menu = "menu_music"
        case game = "game_music"
    }
    
    // MARK: - Sound Effect Types
    enum SoundEffect: String {
        case wallHit = "wall_hit"
        case levelComplete = "level_complete"
        case ballStroke = "ball_stroke"
    }
    
    // MARK: - Current State
    private var currentMusicType: MusicType?
    
    private init() {
        setupAudioSession()
        preloadSoundEffects()
    }
    
    // MARK: - Setup
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("❌ [AudioManager] Failed to setup audio session: \(error)")
        }
    }
    
    private func preloadSoundEffects() {
        // Preload all sound effects for faster playback
        for effect in [SoundEffect.wallHit, .levelComplete, .ballStroke] {
            if let url = Bundle.main.url(forResource: effect.rawValue, withExtension: "wav") {
                do {
                    let player = try AVAudioPlayer(contentsOf: url)
                    player.prepareToPlay()
                    soundEffectPlayers[effect.rawValue] = player
                    print("✅ [AudioManager] Preloaded sound effect: \(effect.rawValue)")
                } catch {
                    print("⚠️ [AudioManager] Could not preload \(effect.rawValue): \(error)")
                }
            } else {
                print("⚠️ [AudioManager] Sound file not found: \(effect.rawValue).wav")
            }
        }
    }
    
    // MARK: - Music Control
    
    /// Play background music of the specified type
    func playMusic(_ type: MusicType, loop: Bool = true) {
        // Don't restart if already playing the same music
        if currentMusicType == type && musicPlayer?.isPlaying == true {
            return
        }
        
        stopMusic()
        
        guard let url = Bundle.main.url(forResource: type.rawValue, withExtension: "wav") else {
            print("⚠️ [AudioManager] Music file not found: \(type.rawValue).wav")
            return
        }
        
        do {
            musicPlayer = try AVAudioPlayer(contentsOf: url)
            musicPlayer?.numberOfLoops = loop ? -1 : 0 // -1 = infinite loop
            musicPlayer?.volume = 0.5
            currentMusicType = type
            
            if isMusicEnabled {
                musicPlayer?.play()
                print("🎵 [AudioManager] Playing music: \(type.rawValue)")
            }
        } catch {
            print("❌ [AudioManager] Failed to play music: \(error)")
        }
    }
    
    /// Stop the current background music
    func stopMusic() {
        musicPlayer?.stop()
        musicPlayer = nil
        currentMusicType = nil
    }
    
    /// Pause the current background music
    func pauseMusic() {
        musicPlayer?.pause()
    }
    
    /// Resume the current background music
    func resumeMusic() {
        if isMusicEnabled {
            musicPlayer?.play()
        }
    }
    
    /// Fade out music over a duration
    func fadeOutMusic(duration: TimeInterval = 1.0, completion: (() -> Void)? = nil) {
        guard let player = musicPlayer else {
            completion?()
            return
        }
        
        let originalVolume = player.volume
        let fadeSteps = 20
        let stepDuration = duration / Double(fadeSteps)
        let volumeStep = originalVolume / Float(fadeSteps)
        
        for step in 0..<fadeSteps {
            DispatchQueue.main.asyncAfter(deadline: .now() + stepDuration * Double(step)) {
                player.volume = originalVolume - volumeStep * Float(step + 1)
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            self?.stopMusic()
            completion?()
        }
    }
    
    // MARK: - Sound Effects
    
    /// Play a sound effect
    func playSound(_ effect: SoundEffect) {
        guard isSoundEnabled else { return }
        
        // Use preloaded player if available
        if let player = soundEffectPlayers[effect.rawValue] {
            player.currentTime = 0
            player.play()
            return
        }
        
        // Fallback: load and play
        guard let url = Bundle.main.url(forResource: effect.rawValue, withExtension: "wav") else {
            print("⚠️ [AudioManager] Sound file not found: \(effect.rawValue).wav")
            return
        }
        
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.play()
            // Cache for future use
            soundEffectPlayers[effect.rawValue] = player
        } catch {
            print("❌ [AudioManager] Failed to play sound: \(error)")
        }
    }
    
    // MARK: - Sync with AppState
    
    func syncWithAppState(musicEnabled: Bool, soundEnabled: Bool) {
        self.isMusicEnabled = musicEnabled
        self.isSoundEnabled = soundEnabled
    }
}
