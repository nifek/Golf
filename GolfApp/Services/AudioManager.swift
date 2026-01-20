import AVFoundation
import Combine
import Foundation
final class AudioManager: ObservableObject {
    static let shared = AudioManager()
    
    private var musicPlayer: AVAudioPlayer?
    private var soundEffectPlayers: [String: AVAudioPlayer] = [:]
    
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
    
    enum MusicType: String {
        case menu = "menu_music"
        case game = "game_music"
    }
    
    enum SoundEffect: String {
        case wallHit = "wall_hit"
        case levelComplete = "level_complete"
        case ballStroke = "ball_stroke"
    }
    
    private var currentMusicType: MusicType?
    
    private init() {
        setupAudioSession()
        preloadSoundEffects()
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("[AudioManager] Failed to setup audio session: \(error)")
        }
    }
    
    private func preloadSoundEffects() {
        for effect in [SoundEffect.wallHit, .levelComplete, .ballStroke] {
            if let url = Bundle.main.url(forResource: effect.rawValue, withExtension: "wav") {
                do {
                    let player = try AVAudioPlayer(contentsOf: url)
                    player.prepareToPlay()
                    soundEffectPlayers[effect.rawValue] = player
                    print("[AudioManager] Preloaded sound effect: \(effect.rawValue)")
                } catch {
                    print("[AudioManager] Could not preload \(effect.rawValue): \(error)")
                }
            } else {
                print("[AudioManager] Sound file not found: \(effect.rawValue).wav")
            }
        }
    }
    
    func playMusic(_ type: MusicType, loop: Bool = true) {
        if currentMusicType == type && musicPlayer?.isPlaying == true {
            return
        }
        
        stopMusic()
        
        guard let url = Bundle.main.url(forResource: type.rawValue, withExtension: "wav") else {
            print("[AudioManager] Music file not found: \(type.rawValue).wav")
            return
        }
        
        do {
            musicPlayer = try AVAudioPlayer(contentsOf: url)
            musicPlayer?.numberOfLoops = loop ? -1 : 0
            musicPlayer?.volume = 0.5
            currentMusicType = type
            
            if isMusicEnabled {
                musicPlayer?.play()
                print("[AudioManager] Playing music: \(type.rawValue)")
            }
        } catch {
            print("[AudioManager] Failed to play music: \(error)")
        }
    }
    
    func stopMusic() {
        musicPlayer?.stop()
        musicPlayer = nil
        currentMusicType = nil
    }
    
    func pauseMusic() {
        musicPlayer?.pause()
    }
    
    func resumeMusic() {
        if isMusicEnabled {
            musicPlayer?.play()
        }
    }
    
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
    
    func playSound(_ effect: SoundEffect) {
        guard isSoundEnabled else { return }
        
        if let player = soundEffectPlayers[effect.rawValue] {
            player.currentTime = 0
            player.play()
            return
        }
        
        guard let url = Bundle.main.url(forResource: effect.rawValue, withExtension: "wav") else {
            print("[AudioManager] Sound file not found: \(effect.rawValue).wav")
            return
        }
        
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.play()
            soundEffectPlayers[effect.rawValue] = player
        } catch {
            print("[AudioManager] Failed to play sound: \(error)")
        }
    }
    
    func syncWithAppState(musicEnabled: Bool, soundEnabled: Bool) {
        self.isMusicEnabled = musicEnabled
        self.isSoundEnabled = soundEnabled
    }
}
