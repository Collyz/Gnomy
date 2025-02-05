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
        getAudio(&backgroundMusicPlayer)
    }
    
    // MARK: Gets the audio file and makes sure the audio isn't nil
    func getAudio(_ musicPlayer: inout AVAudioPlayer?) {
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
    
    func playBgMusic() {
        if backgroundMusicPlayer != nil {
            if !backgroundMusicPlayer!.isPlaying {
                backgroundMusicPlayer!.play()
            }
        }
    }
    
    func pauseBgMusic() {
        if backgroundMusicPlayer != nil {
            if backgroundMusicPlayer!.isPlaying {
                backgroundMusicPlayer!.pause()
            }
        }
    }
    
    func setVolume(_ value: Float) {
        if backgroundMusicPlayer != nil {
            if backgroundMusicPlayer!.isPlaying {
                backgroundMusicPlayer!.volume = value
            }
        }
    }
    
    func getVolume() -> Float {
        return backgroundMusicPlayer!.volume
    }
}
