import Foundation
import AVFoundation
import Combine // ObservableObjectを使うために必要

// ▼▼▼【修正】ObservableObjectプロトコルに準拠させる ▼▼▼
class SoundManager: ObservableObject {
    static let shared = SoundManager()
    private var audioPlayer: AVAudioPlayer?
    
    // AppStorageを使うと、設定が自動的にUserDefaultsに保存・読み込みされる
    @Published var isSoundEnabled: Bool = UserDefaults.standard.object(forKey: "isSoundEnabled") as? Bool ?? true {
        didSet {
            // 値が変更されたら、UserDefaultsに保存する
            UserDefaults.standard.set(isSoundEnabled, forKey: "isSoundEnabled")
        }
    }
    @Published var isMusicEnabled: Bool = UserDefaults.standard.object(forKey: "isMusicEnabled") as? Bool ?? false {
        didSet {
            UserDefaults.standard.set(isMusicEnabled, forKey: "isMusicEnabled")
        }
    }

    private init() {} // シングルトンを保証するためにprivateにする

    func playSound(named soundName: String) {
        guard isSoundEnabled else { return }
        
        guard let url = Bundle.main.url(forResource: soundName, withExtension: nil) else {
            print("Could not find sound file: \(soundName)")
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.play()
        } catch {
            print("Error playing sound: \(error.localizedDescription)")
        }
    }
}
