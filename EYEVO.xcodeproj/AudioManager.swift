//
//  AudioManager.swift
//  EYEVO
//
//  Created by Krishnam Nimmala on 1/20/26.
//

import Foundation
import AVFoundation
import AudioToolbox

final class AudioManager: NSObject {
    static let shared = AudioManager()
    private var audioPlayer: AVAudioPlayer?
    private var sessionConfigured = false

    private override init() {
        super.init()
    }

    func configureSessionIfNeeded() {
        guard !sessionConfigured else { return }
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
            sessionConfigured = true
            print("[AudioManager] session configured")
        } catch {
            print("[AudioManager] session configuration failed: \(error)")
        }
    }

    func playSound(named name: String, ext: String = "wav") {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.configureSessionIfNeeded()

            guard let url = Bundle.main.url(forResource: name, withExtension: ext) else {
                print("[AudioManager] resource not found: \(name).\(ext) — falling back to system sound")
                // Fallback: play a system click sound (works in Simulator/Device)
                // 1104 is the standard iOS 'Tock' click — if unavailable, this is best-effort.
                AudioServicesPlaySystemSound(1104)
                return
            }

            do {
                self.audioPlayer = try AVAudioPlayer(contentsOf: url)
                self.audioPlayer?.prepareToPlay()
                self.audioPlayer?.play()
                print("[AudioManager] playing \(name).\(ext)")
            } catch {
                print("[AudioManager] failed to play \(name): \(error) — falling back to system sound")
                AudioServicesPlaySystemSound(1104)
            }
        }
    }
}
