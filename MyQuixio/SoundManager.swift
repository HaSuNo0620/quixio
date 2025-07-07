// MARK: - SoundManager.swift

import AVFoundation

class SoundManager {
    
    static let shared = SoundManager()
    
    private var audioPlayer: AVAudioPlayer?

    func playSound(named soundName: String) {
        // ファイル名と拡張子を分離
        let components = soundName.components(separatedBy: ".")
        guard components.count == 2,
              let url = Bundle.main.url(forResource: components[0], withExtension: components[1]) else {
            print("Error: Sound file '\(soundName)' not found.")
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.play()
        } catch let error {
            print("Error playing sound: \(error.localizedDescription)")
        }
    }
}
