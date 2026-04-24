//
//  AudioManager.swift
//  EYEVO
//

import Foundation
import AVFoundation
import Combine

final class AudioManager: ObservableObject {

    static let shared = AudioManager()

    // MARK: - Persistent Toggle

    private static let toggleKey = "eyevo_audio_enabled"

    @Published var isEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isEnabled, forKey: Self.toggleKey)
        }
    }

    // MARK: - Audio Engine

    private let synthesizer = AVSpeechSynthesizer()
    private var audioPlayer: AVAudioPlayer?

    // MARK: - Init

    private init() {

        self.isEnabled =
            UserDefaults.standard.object(forKey: Self.toggleKey) as? Bool ?? true

        configureAudioSession()
    }

    // MARK: - Configure Audio Session

    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .playback,
                mode: .spokenAudio,
                options: [.duckOthers]
            )
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("⚠️ Audio session configuration failed:", error)
        }
    }

    // MARK: - Speech

    func speak(_ text: String) {

        guard isEnabled else { return }

        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.5
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0

        synthesizer.speak(utterance)
    }

    // MARK: - Beep

    func playBeep() {

        guard isEnabled else { return }

        guard let url = Bundle.main.url(forResource: "beep", withExtension: "mp3") else {
            print("⚠️ Beep file not found")
            return
        }

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
        } catch {
            print("⚠️ Beep playback error:", error)
        }
    }

    // MARK: - Stop All Audio

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        audioPlayer?.stop()
    }
}
