//
//  MusicPlayer.swift
//  Gnomy
//
//  Created by Mohammed Mowla on 1/5/25.
//
import AVFoundation
class MusicPlayer {
    private var backgroundMusicPlayer: AVAudioPlayer? = nil
    
    init() {
        configureAudioSession()
        getAudio(&backgroundMusicPlayer)
    }
    
    
    // MARK: Gets the audio file and makes sure the audio isn't nil
    public func getAudio(_ musicPlayer: inout AVAudioPlayer?) {
        guard let musicURL = Bundle.main.url(forResource: "bg_sound_1", withExtension: "wav") else {
            print("music file not found")
            return
        }
        
        do {
            musicPlayer = try AVAudioPlayer(contentsOf: musicURL)
            musicPlayer!.numberOfLoops = -1 // infinite loop
            musicPlayer!.prepareToPlay()
            musicPlayer!.volume = 0.5
        } catch {
            print("failed to initialize AVAudioPlayer: \(error.localizedDescription)")
        }
    }
    
    
    public func playBgMusic() {
        if backgroundMusicPlayer != nil {
            if !backgroundMusicPlayer!.isPlaying {
                backgroundMusicPlayer!.play()
            }
        }
    }
    
    public func pauseBgMusic() {
        if backgroundMusicPlayer != nil {
            if backgroundMusicPlayer!.isPlaying {
                backgroundMusicPlayer!.pause()
            }
        }
    }
    
    public func setVolume(_ value: Float) {
        if backgroundMusicPlayer != nil {
            if backgroundMusicPlayer!.isPlaying {
                backgroundMusicPlayer!.volume = value
            }
        }
    }
    
    public func getVolume() -> Float {
        return backgroundMusicPlayer!.volume
    }
    
    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .ambient,
                mode: .default,
                options: [.mixWithOthers]
            )
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set audio session category: \(error.localizedDescription)")
        }
    }
}
